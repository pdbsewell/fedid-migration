/**
 * @description Trigger handler class for Application.
 *  This class is initially created in prep of migrating the Application trigger to the bindExtended framework
 *  and for class naming uniformity.
 * @author Nick Guia
 * @date FEB.20.2024
 * @revision - On 08-08-2025 - By Sravani Naramsetty - 
 *             Added: UpdateApplicationStatusOnContactQual and UpdateApplicationStatusOnWorkExp methods
 *             to capture Application Status on Contact Qualification and Work Experience object when Status is changed on Application
 */
public with sharing class ApplicationTriggerHandler {

    /**
     * @description populate fields that track the potential recursion of 
     *  Agent send to Applicant > Applicant reverts back to Agent > and so on...
     *  (moved from AgentPortalPayload to centralise the logic)
     */
    public class TrackAgentAndApplicantRevision extends TriggerAbstract {

        @TestVisible
        private AgentPortalApplicationService service {
            get {
                if(service == null) {
                    service = new AgentPortalApplicationService();
                }
                return service;
            }
            set;
        }

        public override void process(SObject record, SObject oldrecord) {

            Application__c newApp = (Application__c) record;
            Application__c oldApp = (Application__c) oldrecord;

            if(newApp.Status__c != oldApp.Status__c && 
                newApp.Status__c == AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT)
            {
                service.populateRevisionFields(newApp);
            }
        }
    }

    /**
     * @description 
     */
    public class PopulateMyAppUserStatus extends TriggerAbstract {

        @TestVisible
        private Map<Id, List<Application__c>> applicationListByContactId = new Map<Id, List<Application__c>>();

        public override void process(SObject record, SObject oldrecord) {

            Application__c newApp = (Application__c) record;
            Application__c oldApp = (Application__c) oldrecord;

            /**
             * If Source system is AgentPortal or Hybrid AND
             * If Status is SEND_DRAFT_APPLICATION_TO_APPLICANT
             */
            if((newApp.Source_System__c == AgentPortalConstants.APP_CREATE_SOURCE || newApp.Source_System__c == 'Hybrid') &&
                newApp.Status__c == AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT) 
            {
                if(
                    /**
                     * Status field was updated AND
                     * MyApp User hasn't been provisioned yet for the Applicant
                     */
                    (newApp.Status__c != oldApp.Status__c && newApp.MyApp_User_Status__c != 'Provisioned') ||
                    /**
                     * OR a Contact Merge was done
                     */
                    (newApp.Task_Duplicate_Check__c != oldApp.Task_Duplicate_Check__c &&
                     newApp.Task_Duplicate_Check__c == 'Completed' &&
                     newApp.Duplicate_Check_Outcome__c == 'Merged Successfully')
                ) {
                    List<Application__c> appList = applicationListByContactId.get(newApp.Applicant__c);
                    if(appList == null) {
                        appList = new List<Application__c>();
                    }
                    appList.add(newApp);
                    applicationListByContactId.put(newApp.Applicant__c, appList);
                }
            } 
        }

        /**
        * @description execute trigger
        * @author
        **/
        public override void execute() {
            if(!applicationListByContactId.isEmpty()) {

                /**
                 * check if an active User exists for the Contact (Applicant).
                 * Assumes that any active experience user assigned with a myapp profile
                 * already has the necessary permission sets and does not require
                 * to be provided one.
                 */ 
                Map<Id, User> myAppUserByContactId = new Map<Id, User>();

                for(User iUser : [SELECT Id, ContactId 
                                FROM User 
                                WHERE Profile.Name = 'Customer Community General User'
                                AND IsActive = TRUE
                                AND ContactId IN :applicationListByContactId.keySet()])
                {
                    myAppUserByContactId.put(iUser.ContactId, iUser);
                }

                // update MyApp User Status field
                for(Id iContactId : applicationListByContactId.keySet()) {

                    User myAppUser = myAppUserByContactId.get(iContactId);

                    for(Application__c iApp : applicationListByContactId.get(iContactId)) {

                        // if an active myapp user already exists
                        if(myAppUser != null) {
                            // means ready to go
                            iApp.MyApp_User_Status__c = 'Existing User';
                        } else {
                            // means requiring user provisioning
                            iApp.MyApp_User_Status__c = 'In Progress';
                        }
                    }
                }
            }
        }
    }

    /**
     * @description Enable my.app access for Agent portal and Hybrid source applicants
     */
    public class EnableMyAppAccess extends TriggerAbstract {

        public override void process(SObject record, SObject oldrecord) {

            Application__c newApp = (Application__c) record;
            Application__c oldApp = (Application__c) oldrecord;

            /**
             * filter by event :
             * for AgentPortal and Hybrid Applications,
             * 
             * if MyApp_User_Status__c is updated to 'In Progress' or 'Existing User'
             */
            if((newApp.Source_System__c == AgentPortalConstants.APP_CREATE_SOURCE || newApp.Source_System__c == 'Hybrid') && 
                newApp.Agent__c != null && newApp.Applicant__c != null &&
                (
                    oldApp.MyApp_User_Status__c != newApp.MyApp_User_Status__c && 
                    (newApp.MyApp_User_Status__c == 'In Progress' || newApp.MyApp_User_Status__c == 'Existing User'))
                )
            {
                records.add(record);
            }
        }

        /**
        * @description execute trigger
        * @author
        **/
        public override void execute() {
            if(!records.isEmpty()) {
                MyAppUserProvisioning.ProvisionUserQueueable provUserQueueable = 
                    new MyAppUserProvisioning.ProvisionUserQueueable((List<Application__c>) records);
                System.enqueueJob(provUserQueueable);
            }
        }
    }

    /**
     * @description When Application from Agent Portal reaches "Sent for Submission" status
     * AND Delegator Org Unit Code is not blank (meaning a Delegator was nominated by a Delegate Agency),
     * then update the Agency field of the Application to the Account of the Delegator Org Unit Code
     * i.e. Agency Transfer
     */
    public class DelegateApplicationBeforeSubmit extends TriggerAbstract {

        @TestVisible
        private Set<String> delegatorExternalIds = new Set<String>();

        public override void process(SObject record, SObject oldrecord) {

            Application__c newApp = (Application__c) record;
            Application__c oldApp = (Application__c) oldrecord;

            /**
             * filter field changes :
             *  invoke when Status field changed
             */
            if(newApp.Status__c != oldApp.Status__c) {

                /**
                 * filter field values :
                 *  invoke when 
                 *  - source system is Agent Portal
                 *  - Status is Sent for Submission
                 *  - delegator org unit code has a value
                 */
                if(newApp.Source_System__c == AgentPortalConstants.APP_CREATE_SOURCE && 
                    newApp.Status__c == MyApplicationUtilities.APP_SENT_FOR_SUBMIT_STATUS &&
                    String.isNotBlank(newApp.Delegator_Org_Unit_Code__c))
                {
                    records.add(newApp);
                    delegatorExternalIds.add(newApp.Delegator_Org_Unit_Code__c);
                }
            }
        }

        /**
        * @description Execute Trigger
        * @author
        **/
        public override void execute() {
            if(!records.isEmpty() && !delegatorExternalIds.isEmpty()) {
                try {
                    new AgentPortalApplicationService().delegateApplication((List<Application__c>) records, this.delegatorExternalIds);
                } catch(Exception e) {
                    Nebula.Logger.error('An unexpected error occurred while trying to delegate Applications', e)
                                .addTag('Agency Delegation');
                }
                Nebula.Logger.saveLog();
            }
        }
    }

    /**
     * @description  Routes the ACP to the correct queue for Assessment (if taps are enabled for all ACPs)
     * This class is initially created in prep of migrating the Application trigger to the bindExtended framework
     * and for class naming uniformity.
     * @author       Jitender Padda
     * @date         Jun.2024
     * @modifiedby	 @rajeshpunjabi 19-July-2024
     * @modifiedby	 Sravani Naramsetti 01-Aug-2024
     * @modifiedby	 @rajeshpunjabi 08-Aug-2024 - Added logic for Monash College Courses.
     */
    public class RunACPQueueRouting extends TriggerAbstract {
        Set<String> setMonashColledgeCourses = new Set<String>{
            'Monash University Foundation Year MUFY',
            'Monash College Diplomas',
            'Monash University English Language Centre'
        };

        public override void process(SObject record, SObject oldRec) {
            Application__c newApp = (Application__c) record;
            Application__c oldApp = (Application__c) oldRec;

            if (
                ((oldApp.Status__c != 'Submitted' &&
                newApp.Status__c == 'Submitted') ||
                (oldApp.Rerun_Initial_ACP_Routing__c == false &&
                newApp.Rerun_Initial_ACP_Routing__c == true)) &&
                newApp.Assessment_Status__c == 'Required'
            ) {
                records.add(newApp);
            }
        }

        /**
         * @description execute trigger
         * @author
         **/
        public override void execute() {
            List<Application_Course_Preference__c> lstACPtoProcess;

            if (!records.isEmpty()) {
                lstACPtoProcess = new List<Application_Course_Preference__c>();

                try {
                    List<Application_Course_Preference__c> lstACPs = getACPList(
                        new Map<Id, Application__c>((List<Application__c>) records).keySet()
                    );
                    //.. Create Map of App id and List of ACPs with SORT BY Preference Number
                    Map<Id, List<Application_Course_Preference__c>> mapAppIdACP = new Map<Id, List<Application_Course_Preference__c>>();
                    //.. Create Map of AppId and Boolean to store if Monash College course exists
                    Set<Id> appIdWithMCCSet = new Set<Id>();

                    for (Application_Course_Preference__c acp : lstACPs) {
                        List<Application_Course_Preference__c> acpList;

                        if (mapAppIdACP.containsKey(acp.Application__c)) {
                            acpList = mapAppIdACP.get(acp.Application__c);
                        } else {
                            acpList = new List<Application_Course_Preference__c>();
                        }

                        acpList.add(acp);

                        mapAppIdACP.put(acp.Application__c, acpList);

                        if (isMCDCourse(acp)) {
                            appIdWithMCCSet.add(acp.Application__c);
                        }
                    }

                    for (Id appId : mapAppIdACP.keySet()) {
                        List<Application_Course_Preference__c> lstACPsRetrieved = mapAppIdACP.get(appId);
                        //.. when ACP size is 1
                        if (lstACPsRetrieved.size() == 1) {
                            lstACPtoProcess.add(lstACPsRetrieved[0]);
                        }
                        //.. when ACP size is more than 1
                        else {
                            //.. Is Monash College Cour=rse
                            if (appIdWithMCCSet.contains(appId)) {
                                //.. First preference is not English Course
                                if (
                                    lstACPsRetrieved[0].Managing_Faculty__c !=
                                    'Monash University English Language Centre'
                                ) {
                                    lstACPtoProcess.add(lstACPsRetrieved[0]);
                                }
                                //.. First preference is English Course
                                else {
                                    lstACPtoProcess.add(lstACPsRetrieved[1]);
                                }
                            }
                            //.. Not Monash College Course
                            else {
                                lstACPtoProcess.add(lstACPsRetrieved[0]);
                            }
                        }
                    }

                    if (!lstACPtoProcess.isEmpty()) {
                        List<Async_Process__e> evtList = new List<Async_Process__e>();
                        for(Application_Course_Preference__c acp : lstACPtoProcess) {
                            AsyncProcessPayload payload = new AsyncProcessPayload();
                            payload.put ('acpId', acp.Id);
                            Async_Process__e evt = new Async_Process__e (
                                Process_Name__c = 'ACPQueueRoutingPlatformEventHandler',
                                Parameter__c = payload.serialize()
                            );
                            evtList.add(evt);
                        }
                        if(!evtList.isEmpty()) {
                            EventBus.publish(evtList);
                        }
                    }
                } catch (Exception ex) {
                    Nebula.Logger.error('ApplicationHandler.RunACPQueueRouting', ex);
                    Nebula.Logger.saveLog();
                }
            }
        }

        /**
         * @description Faculty is monash college.
         * @author rajesh.punjabi@monash.edu | 08-08-2024
         * @param oACP
         * @return Boolean
         **/
        private Boolean isMCDCourse(Application_Course_Preference__c oACP) {
            return (setMonashColledgeCourses.contains(oACP.Managing_Faculty__c));
        }

        /**
         * @description
         * @author Jitender Padda | 07-2024
         * @param setAppIds
         * @return List<Application_Course_Preference__c>
         **/
        private List<Application_Course_Preference__c> getACPList(Set<Id> setAppIds) {
            return [
                SELECT
                    Id,
                    Managing_Faculty__c,
                    Admission_Category__c,
                    Location_Code__c,
                    Attendance_Mode__c,
                    Course_Code__c,
                    OwnerId,
                    Citizenship_Classification__c,
                    Preference_Number__c,
                    Application__c
                FROM Application_Course_Preference__c
                WHERE Application__c IN :setAppIds
                WITH SYSTEM_MODE
                ORDER BY Preference_Number__c ASC NULLS LAST
            ];
        }
    }
        
     /**
     * @description When Application Status is changed update it on Contact Qualification
     */
    public class UpdateApplicationStatusOnContactQual extends TriggerAbstract {

        public override void process(SObject record, SObject oldrecord) {

            Application__c newApp = (Application__c) record;
            Application__c oldApp = (Application__c) oldrecord;

            /**
             * invoke when Status field changed
             */
            if(newApp.Status__c != oldApp.Status__c){
                if(newApp.Status__c != oldApp.Status__c){
                    records.add(newApp);
                }
            }
        }

        /**
        * @description Execute Trigger
        * @author
        **/
        public override void execute() {
            if(!records.isEmpty()) {
                try {
                    Map<Id,String> appIdStatus = new Map<Id,String>();
                    Set<String> updatedAppIds = new Set<String>();
                    for(Application__c app: (List<Application__c>)records){
                        appIdStatus.put(app.Id,app.Status__c);
                        updatedAppIds.add(app.Id);
                    }
                    List<Application_Qualification_Provided__c > appQualList=new List<Application_Qualification_Provided__c >();
                    appQualList =[Select id, Contact_Qualification__c, Contact_Qualification__r.Application_Status__c, Application__c, Application__r.Status__c from Application_Qualification_Provided__c where Application__c IN: updatedAppIds];
                    if(!appQualList.isEmpty()){
                        List<Contact_Qualification__c> contQualList=new List<Contact_Qualification__c>();
                        Set<Id> contQualIds=new Set<Id>();
                        Map<Id,String> contQualAppStat=new Map<Id,String>();
                        Map<Id,Id> contQualAppId=new Map<Id,Id>();
                        for(Application_Qualification_Provided__c awep:appQualList){
                            contQualIds.add(awep.Contact_Qualification__c);
                            contQualAppStat.put(awep.Contact_Qualification__c,awep.Contact_Qualification__r.Application_Status__c);
                            contQualAppId.put(awep.Contact_Qualification__c,awep.Application__c);
                        }
                        List<Application_Qualification_Provided__c > appContQual=new List<Application_Qualification_Provided__c >();
                        Map<Id,Integer> contQualCountMap=new Map<Id,Integer>();
                        appContQual =[Select id, Contact_Qualification__c, Application__c, Application__r.Status__c from Application_Qualification_Provided__c where Contact_Qualification__c IN: contQualIds];
                        for(Application_Qualification_Provided__c acq1:appContQual){
                            if(contQualCountMap.containsKey(acq1.Contact_Qualification__c)){
                                contQualCountMap.put(acq1.Contact_Qualification__c,contQualCountMap.get(acq1.Contact_Qualification__c)+1);
                            }else{
                                contQualCountMap.put(acq1.Contact_Qualification__c,1);
                            }
                        }
                        List<Contact_Qualification__c> cQList=new List<Contact_Qualification__c>();
                        for(Id cntQulId:contQualIds){
                            if(contQualCountMap.get(cntQulId)!=null && (contQualCountMap.get(cntQulId)==1 || (contQualCountMap.get(cntQulId)>1 && contQualAppStat.get(cntQulId) != 'Submitted' && appIdStatus.get(contQualAppId.get(cntQulId))!='Draft' && appIdStatus.get(contQualAppId.get(cntQulId))!='Sent Draft Application to Applicant' && appIdStatus.get(contQualAppId.get(cntQulId))!='Applicant Declaration Accepted'
                                                                                                           && appIdStatus.get(contQualAppId.get(cntQulId))!='Data Validation Ready' && appIdStatus.get(contQualAppId.get(cntQulId))!='Failed Data validation'))){
                                Contact_Qualification__c cq=new Contact_Qualification__c();
                                cq.Id=cntQulId;
                                cq.Application_Status__c=appIdStatus.get(contQualAppId.get(cntQulId));
                                cQList.add(cq);
                            }
                        }
                        if(!cQList.isEmpty()){
                            update cQList;
                        }
                    }
                } catch(Exception e) {
                    Nebula.Logger.error('An unexpected error occurred while trying to update App Status on Contact Qualification', e)
                                .addTag('Contact Qualification');
                }
                Nebula.Logger.saveLog();
            }
        }
    }
    
    /**
     * @description When Application Status is changed update it on Work Experience
     */
    public class UpdateApplicationStatusOnWorkExp extends TriggerAbstract {

        public override void process(SObject record, SObject oldrecord) {

            Application__c newApp = (Application__c) record;
            Application__c oldApp = (Application__c) oldrecord;

            /**
             * invoke when Status field changed
             */
            if(newApp.Status__c != oldApp.Status__c){
                if(newApp.Status__c != oldApp.Status__c){
                    records.add(newApp);
                }
            }
        }

        /**
        * @description Execute Trigger
        * @author
        **/
        public override void execute() {
            if(!records.isEmpty()) {
                try {
                    Map<Id,String> appIdStatus = new Map<Id,String>();
                    Set<String> updatedAppIds = new Set<String>();
                    for(Application__c app: (List<Application__c>)records){
                        appIdStatus.put(app.Id,app.Status__c);
                        updatedAppIds.add(app.Id);
                    }
                    List<Application_Work_Experience_Provided__c > appWorkExpList=new List<Application_Work_Experience_Provided__c >();
                    appWorkExpList =[Select id, Work_Experience__c, Work_Experience__r.Application_Status__c, Application__c, Application__r.Status__c from Application_Work_Experience_Provided__c where Application__c IN: updatedAppIds];
                    if(!appWorkExpList.isEmpty()){
                        List<Work_Experience__c> workExpList=new List<Work_Experience__c>();
                        Set<Id> workExpIds=new Set<Id>();
                        Map<Id,String> workExpAppStat=new Map<Id,String>();
                        Map<Id,Id> workExpAppId=new Map<Id,Id>();
                        for(Application_Work_Experience_Provided__c awep:appWorkExpList){
                            workExpIds.add(awep.Work_Experience__c);
                            workExpAppStat.put(awep.Work_Experience__c,awep.Work_Experience__r.Application_Status__c);
                            workExpAppId.put(awep.Work_Experience__c,awep.Application__c);
                        }
                        List<Application_Work_Experience_Provided__c > appWorkExp=new List<Application_Work_Experience_Provided__c >();
                        Map<Id,Integer> workExpCountMap=new Map<Id,Integer>();
                        appWorkExp =[Select id, Work_Experience__c, Application__c, Application__r.Status__c from Application_Work_Experience_Provided__c where Work_Experience__c IN: workExpIds];
                        for(Application_Work_Experience_Provided__c awep1:appWorkExp){
                            if(workExpCountMap.containsKey(awep1.Work_Experience__c)){
                                workExpCountMap.put(awep1.Work_Experience__c,workExpCountMap.get(awep1.Work_Experience__c)+1);
                            }else{
                                workExpCountMap.put(awep1.Work_Experience__c,1);
                            }
                        }
                        List<Work_Experience__c> wEList=new List<Work_Experience__c>();
                        for(Id wrkExpId:workExpIds){
                            if(workExpCountMap.get(wrkExpId)!=null && (workExpCountMap.get(wrkExpId)==1 || (workExpCountMap.get(wrkExpId)>1 && workExpAppStat.get(wrkExpId) != 'Submitted' && appIdStatus.get(workExpAppId.get(wrkExpId))!='Draft' && appIdStatus.get(workExpAppId.get(wrkExpId))!='Sent Draft Application to Applicant' && appIdStatus.get(workExpAppId.get(wrkExpId))!='Applicant Declaration Accepted'
                                                                                                           && appIdStatus.get(workExpAppId.get(wrkExpId))!='Data Validation Ready' && appIdStatus.get(workExpAppId.get(wrkExpId))!='Failed Data validation'))){
                                Work_Experience__c we=new Work_Experience__c();
                                we.Id=wrkExpId;
                                we.Application_Status__c=appIdStatus.get(workExpAppId.get(wrkExpId));
                                wEList.add(we);
                            }
                        }
                        if(!wEList.isEmpty()){
                            update wEList;
                        }
                    }
                } catch(Exception e) {
                    Nebula.Logger.error('An unexpected error occurred while trying to update App Status on Work Experience', e)
                                .addTag('Work Experience');
                }
                Nebula.Logger.saveLog();
            }
        }
    }
}