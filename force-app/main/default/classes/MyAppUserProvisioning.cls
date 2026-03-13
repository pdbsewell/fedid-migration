/**
 * @description class encapsulating queueable classes required to fully provision
 * a MyApp User. I opted to create an entirely new class instead of reusing the existing
 * UserServices Queueable or ExperienceAuthenticationServices classes for the following reasons:
 *  1. The existing methods in ExperienceAuthenticationServices isn't designed for bulk operations
 *  2. Anticipating the arrival of 'User Access Policies' (currently Beta), then we may have to deprecate this at some point.
 *     Having an entirely independent class allows for an easier cutover.
 *  3. The requirement requires a subsequent update to an application when user creation fails
 * 
 * NB: class needs to run in without sharing to bypass User record access.
 * This is mainly for APNG requirements where Agents (external users) may not have access to query
 * user record for the system to validate if they exist or not.
 * 
 * @author  Nick Guia
 * @date    FEB.05.2024
 * @group   Admissions
 */
public without sharing class MyAppUserProvisioning {
    /**
     * @description used to asynchronously generate a user record for MyApp
     * based on Application records
     */
    public class ProvisionUserQueueable implements Queueable {

        @TestVisible
        private ApplicationService.MyAppUserWrapper userCollection;
        @TestVisible
        private Map<Id, List<Application__c>> appListByContactIdMap;
        @TestVisible
        private Set<Id> appIdDupeCheckRequired = new Set<Id>();
        @TestVisible
        private Set<Id> appIdSuccessfulProvisioning = new Set<Id>();

        public ProvisionUserQueueable(List<Application__c> appList) {
            /**
             * first, create a map of contact => List<Application> (one to many)
             * this is required so we'll know later which Application records require an update in case of user creation failure.
             */
            appListByContactIdMap = new Map<Id, List<Application__c>>();
            for(Application__c iApp : appList) {
                if(iApp.Applicant__c != null) {
                    List<Application__c> conApplicationList = appListByContactIdMap.get(iApp.Applicant__c);
                    if(conApplicationList == null) {
                        conApplicationList = new List<Application__c>();
                    }
                    conApplicationList.add(iApp);
                    appListByContactIdMap.put(iApp.Applicant__c, conApplicationList);
                }
            }
            /**
             * then, prepare the user collection (both existing and new).
             * The existing users are required later on to provisioning necessary access.
             */
            this.userCollection = new ApplicationService().createMyAppUserFromApplication(appList);
        }
        public void execute(QueueableContext context) {
            // get the collection of existing users
            List<User> myAppUserList = (this.userCollection.existingUserList != null) ? this.userCollection.existingUserList : new List<User>();
            // commit new users
            List<User> newUsers = commitNewUsers(this.userCollection.newUserList);
            // combine with the list of existing users so we can provision permissions
            myAppUserList.addAll(newUsers);
            // assign necessary permissions
            provisionAccess(myAppUserList);
            // update back Application on user provisioning status
            publishApplicationUpdate();
            // publish all logs
            Nebula.Logger.saveLog();
        }
        /**
         * @description commit any new users that don't exist yet
         * @return `List<User>`
         */
        @TestVisible
        private List<User> commitNewUsers(List<User> newUserList) {

            List<User> createdUsers = new List<User>();

            if(newUserList != null && !newUserList.isEmpty()) {

                // do a partial commit of the users that don't exist yet.
                List<Database.SaveResult> srList = Database.insert(newUserList, false);
                for(Integer i = 0; i < srList.size(); i++) {

                    Database.SaveResult iSr = srList[i];
                    List<Application__c> conAppList = this.appListByContactIdMap.get(newUserList[i].ContactId);

                    if(iSr.isSuccess()) {
                        // collect successfully created users
                        createdUsers.add(newUserList[i]);
                        // update Applications that successfully provisioned MyApp user
                        if(conAppList != null) {
                            this.appIdSuccessfulProvisioning.addAll(new Map<Id, Application__c>(conAppList).keySet());
                        }
                    } else {
                        /**
                         * since applicant user provisioning is a critical step for us, we want
                         * to make sure that any genuine error is raised
                         */
                        for(Database.Error iError : iSr.getErrors()) {
                            if(iError.getMessage().contains('Duplicate Username')) {
                                /**
                                 * if user creation fails due to an existing duplicate (e.g. if the user is linked to another contact)
                                 * then update the Application record
                                 */
                                if(conAppList != null) {
                                    this.appIdDupeCheckRequired.addAll(new Map<Id, Application__c>(conAppList).keySet());
                                }
                                Nebula.Logger.warn(
                                    'Unable to create user because a duplicate username already exists. Updating the related Application to Pending Merge', 
                                    newUserList[i]);
                            } else {
                                Nebula.Logger.error(iError.getMessage(), newUserList[i]);
                            }
                        }
                    }
                }
            }
            return createdUsers;
        }

        /**
         * @description publish the platform event that updates the Applications that require deduping
         * @param appIdsToBeUpdated 
         */
        @TestVisible
        private void publishApplicationUpdate() {
            if(!this.appIdDupeCheckRequired.isEmpty() || !this.appIdSuccessfulProvisioning.isEmpty()) {
                AsyncProcessPayload payload = new AsyncProcessPayload();
                payload.put ('appIdDupeCheckRequired', this.appIdDupeCheckRequired);
                payload.put ('appIdSuccessfulProvisioning', this.appIdSuccessfulProvisioning);

                Async_Process__e ap = new Async_Process__e(
                    Process_Name__c = 'MyAppUserProvisioning.UpdateApplicationsPostUserProvisioning',
                    Parameter__c = payload.serialize()
                );
                EventBus.publish(ap);
            }
        }

        /**
         * @description assign the necessary access required for myApp users
         * @param myAppusers 
         */
        @TestVisible
        private List<PermissionSetAssignment> provisionAccess(List<User> myAppusers) {

            List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
            List<PermissionSetAssignment> createdPsaList = new List<PermissionSetAssignment>();
            Map<Id, User> myAppUserMap = new Map<Id, User>();
            
            if(myAppUsers != null && !myAppUsers.isEmpty()) {

                for(User iUser : myAppusers) {

                    // create a PSG assignment
                    psaList.add(
                        new PermissionSetAssignment(
                            PermissionSetGroupId = MyApplicationUtilities.MYAPP_USER_PSG.Id,
                            AssigneeId = iUser.Id
                    ));

                    // create a PS assignment - required to trigger the welcome email
                    psaList.add(
                        new PermissionSetAssignment(
                            PermissionSetId = MyApplicationUtilities.MYAPP_USER_PS.Id,
                            AssigneeId = iUser.Id
                    ));

                    myAppUserMap.put(iUser.Id, iUser);
                }

                if(!psaList.isEmpty()) {
                    // do a partial commit to allow duplicates to simply fail rather than spending resources to check first
                    List<Database.SaveResult> srList = Database.insert(psaList, false);
                    for(Integer i = 0; i < srList.size(); i++) {

                        Database.SaveResult iSr = srList[i];
                        User iUSer = myAppUserMap.get(psaList[i].AssigneeId);
                        List<Application__c> conAppList = this.appListByContactIdMap.get(iUSer.ContactId);

                        if(!iSr.isSuccess()) {
                            /**
                             * since applicant user provisioning is a critical step for us, we want
                             * to make sure that any genuine error is raised (e.g. non-duplicate permissions error)
                             */
                            for(Database.Error iError : iSr.getErrors()) {
                                if(!iError.getMessage().contains('Duplicate PermissionSetAssignment')) {
                                    Nebula.Logger.error(iError.getMessage(), psaList[i]);
                                } else {
                                    // duplicate PSA error means successful provisioning
                                    if(conAppList != null) {
                                        this.appIdSuccessfulProvisioning.addAll(new Map<Id, Application__c>(conAppList).keySet());
                                    }
                                }
                            }
                        } else {
                            createdPsaList.add(psaList[i]);
                            if(conAppList != null) {
                                this.appIdSuccessfulProvisioning.addAll(new Map<Id, Application__c>(conAppList).keySet());
                            }
                        }
                    }
                }
            }
            return createdPsaList;
        }
        // for unit testing private methods
        @SuppressWarnings('PMD.EmptyStatementBlock')
        @TestVisible
        private ProvisionUserQueueable(){ }
    }
    /**
     * @description Async Process (due to Application being a non-setup object)
     * that updates the Application to flag that they require Contact merging before
     * a user can be provisioned for the applicant
     */
    public class UpdateApplicationsPostUserProvisioning implements IPlatformEventInvocable {
        
        @TestVisible
        private Set<Id> appIdDupeCheckRequired;
        @TestVisible
        private Set<Id> appIdSuccessfulProvisioning;

        public void execute(List<AsyncProcessPayload> payload) {
            init(payload);
            updateApplications();
        }

        @TestVisible
        private void init(List<AsyncProcessPayload> payload) {

            this.appIdDupeCheckRequired = new Set<Id>();
            this.appIdSuccessfulProvisioning = new Set<Id>();

            for(AsyncProcessPayload iPayload : payload) {

                for(Object io : (List<Object>) iPayload.get('appIdDupeCheckRequired')) {
                    //parse object to ID
                    this.appIdDupeCheckRequired.add(Id.valueOf(io.toString()));
                }

                for(Object io : (List<Object>) iPayload.get('appIdSuccessfulProvisioning')) {
                    //parse object to ID
                    this.appIdSuccessfulProvisioning.add(Id.valueOf(io.toString()));
                }
            }
        }

        /**
         * @description update Application records to indicate whether
         * a duplicate merge is required, or if user provisioning is successful
         */
        @TestVisible
        private void updateApplications() {

            List<Application__c> appList = new List<Application__c>();

            if(!this.appIdDupeCheckRequired.isEmpty()) {
                for(Id iAppId : this.appIdDupeCheckRequired) {
                    appList.add(updateApplicationForContactMerge(iAppId));
                }
            }

            if(!this.appIdSuccessfulProvisioning.isEmpty()) {
                for(Id iAppId : this.appIdSuccessfulProvisioning) {
                    appList.add(updateApplicationWithSuccessfulUserProvisioning(iAppId));
                }
            }

            if(!appList.isEmpty()) {
                try {
                    update appList;
                } catch(Exception ex) {
                    Nebula.Logger.error(
                        'Unable to update Applications during MyApp user provisioning',
                        appList,
                        ex
                    );
                }
            }
        }

        /**
         * @description updates the necessary fields in the application to surface
         * the admissions contact merge component on the UI and indicate that a contact
         * merge is required before the application can proceed.
         */
        @TestVisible
        private Application__c updateApplicationForContactMerge(Id applicationId) {
            return new Application__c(
                Id = applicationId,
                Task_Duplicate_Check__c = 'Required',
                MyApp_User_Status__c = 'Pending Contact Merge'
            );
        }

        /**
         * @description update an Application to indicate that MyApp user provisioning is successful
         */
        @TestVisible
        private Application__c updateApplicationWithSuccessfulUserProvisioning(Id applicationId) {
            return new Application__c(
                Id = applicationId,
                MyApp_User_Status__c = 'Provisioned'
            );
        }
    }
}