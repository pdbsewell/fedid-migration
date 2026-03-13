/**
* @author Seeva
* @date 22.07.2023
*
* @group Duplicate Management
*
* @description Service class providing features needed for Admissions Duplicate Management
*
* @revision  22.07.2023 - Seeva: Initial Create
*/
public class AdmissionDupCheckServices {
    static final String DUPLICATE_PERFECT_MATCH_NAME = 'Contact_Perfect_Match';
    static final String DUPLICATE_PARTIAL_MATCH_NAME = 'Contact_Potential_Match';
    static final String DUPLICATE_LOOSE_MATCH_NAME = 'Contact_Loose_Match';
    
    static final String taskDupCheckRequired = 'Required';
    static final String taskDupCheckNotRequired = 'Not Required';
    static final String taskDupCheckCompleted = 'Completed';
    
    // THIS METHOD GETS CALLED POST CONTACT MERGE TO HANDLE POST MERGE ACTIVITES 
    public class PerformContactPointRehash implements IPlatformEventInvocable {
        
        private Set<Id> ContactIDs = new Set<Id>();
        
        public void execute(List<AsyncProcessPayload> payload) {
            try {
                initialize(payload);
                run();
            } catch(Exception e) {
                LogUtilityException.logException(e, this.ContactIDs);
            } finally {
                LogUtilityException.getLimits();
            }
        }
        
        private void initialize(List<AsyncProcessPayload> payloads) {
            if(payloads != null) {
                for(AsyncProcessPayload payload : payloads) {
                    //first, cast the get return of List<Object> into List<Id>
                    List<Object> objList = (List<Object>) payload.get('contactId');
                    //then, instantiate a Set out of it
                    for(Object io : objList) {
                        //parse object to ID
                        this.ContactIDs.add(Id.valueOf(io.toString()));
                    }
                }
            }
        }        
        
        public void run() {
            BaseClass.ResultSet rs = new ContactMergePerson360(this.ContactIDs).mergePerson360();
            LogUtilityException.logCommitRecords(rs);
        }
    }

    /*
    * This runs when application status goes to "Submission in hold" then this code looks for perfect match contact 
    * If the perfect match record does not have any user associated then the merge happens immediately
    * Else the potential matches are displayed on Application page for business users to decide which records to merge 
    */
    public class PerformMatchAndMerge implements IPlatformEventInvocable {
        private Set<Id> appIDs = new Set<Id>();
        public void execute(List<AsyncProcessPayload> payload) {
            try {
                initialize(payload);
                run();
            } catch(Exception e) {
                LogUtilityException.logException(e, this.appIDs);
            } finally {
                LogUtilityException.getLimits();
            }
        }
        
        private void initialize(List<AsyncProcessPayload> payloads) {
            if(payloads != null) {
                for(AsyncProcessPayload payload : payloads) {
                    //first, cast the get return of List<Object> into List<Id>
                    List<Object> objList = (List<Object>) payload.get('appId');
                    //then, instantiate a Set out of it
                    for(Object io : objList) {
                        //parse object to ID
                        this.appIDs.add(Id.valueOf(io.toString()));
                    }
                }
            }
        }    
        public void run() {
            List<Application__c> appsToUpdate = new List<Application__c>();			
            for (Application__c appInLoop : [
                SELECT Applicant__c, Applicant__r.Id, Applicant__r.Previous_Monash_ID__c, Applicant__r.Email,
                Applicant__r.Personal_Email__c, Applicant__r.Monash_Email_Address__c, Task_Duplicate_Check__c
                FROM Application__c
                WHERE Id IN :this.appIDs
            ]) {
                //SEEVA - ADDING ALL THE CONTACT IN TO SET
                Set<Id> appsContactIdSet = new Set<Id>();
                if (String.isNotBlank(appInLoop.Applicant__r.Id)) {
                    appsContactIdSet.ADD(appInLoop.Applicant__r.Id);
                }
                //END
                
                Boolean hasPotentialMatch = false;
                Set<Id> potentialDuplicateContactIds = new Set<Id>();
                
                // set dup check task status to a default of 'not required' to start with
                Application__c appToUpdate = new Application__c(
                    Id = appInLoop.Id
                );
                
                // Find if there are Perfect Match result
                Set<Id> perfectMatchContactIds = new Set<Id>();
                Set<Id> perfectMatchContactIdsUsingPlatformMethod = new Set<Id>();
                
                //SEEVA - TO FIND DUPLICATE CONTACTS BASED ON PERFECT MATCHING RULE
                perfectMatchContactIds = AdmissionsDupCheckHelper.findDuplicateContacts(new Set<Id>{appInLoop.Applicant__r.Id}, DUPLICATE_PERFECT_MATCH_NAME);
                if (!perfectMatchContactIds.isEmpty()) {
                    // Invoke code for Perfect Match Merge
                    AdmissionsDupCheckHelper helper = new AdmissionsDupCheckHelper();
                    helper.init(appInLoop.Applicant__r.Id, perfectMatchContactIds);
                }
                // Find if there are Potential Match and/or Loose Match and/or email search and/or person id match
                List<Contact> contactList = ContactMergeHelper.getContacts(null, null, null, null,appsContactIdSet);
                potentialDuplicateContactIds = AdmissionsDupCheckHelper.findPotentialDuplicateContacts(contactList.get(0));
                if (!potentialDuplicateContactIds.isEmpty()) {
                    hasPotentialMatch = true;
                }
                // Update App record's status to 'Sent for Submission' to trigger off existing process
                if (!perfectMatchContactIds.isEmpty() && !hasPotentialMatch) {
                    appToUpdate.Task_Duplicate_Check__c = taskDupCheckCompleted;
                    appToUpdate.Status__c = MyApplicationUtilities.APP_SENT_FOR_SUBMIT_STATUS;
                } else if ((!perfectMatchContactIds.isEmpty() && hasPotentialMatch) || (perfectMatchContactIds.isEmpty() && hasPotentialMatch)) {
                    appToUpdate.Task_Duplicate_Check__c = taskDupCheckRequired;
                } else {
                    appToUpdate.Task_Duplicate_Check__c = taskDupCheckNotRequired;
                    appToUpdate.Status__c = MyApplicationUtilities.APP_SENT_FOR_SUBMIT_STATUS;
                }
                appsToUpdate.add(appToUpdate);
                /************** END ************/
            }
            //Commit records to database
            List<Database.SaveResult> srList = Database.update(appsToUpdate, false);
            logExceptions(srList);
            
        }
        private void logExceptions(List<Database.SaveResult> srList) {
            if(srList != null && !srList.isEmpty()) {
                for(Database.SaveResult iSr : srList) {
                    if(!iSr.isSuccess()) { 
                        Database.Error err = iSr.getErrors()[0]; //get first instance of error
                        LogUtilityException.logExceptionMSG(
                            'AdmissionsDupCheckServices.PerformMatchAndMerge', 
                            iSr.getId(), 
                            'Status Code : ' + err.getStatusCode() + ' Message : ' + err.getMessage());
                    }
                }
            }
        }        
    }
}