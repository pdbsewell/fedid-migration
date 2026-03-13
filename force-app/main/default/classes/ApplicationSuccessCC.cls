/*******************************************************************************
* @author       Ant Custodio
* @date         7.Apr.2017         
* @description  controller class for ApplicationSuccess.cmp
* @revision     
 * 19/07/2023 enhanced security
*******************************************************************************/
public without sharing class ApplicationSuccessCC {
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  retrieves the application using the URL parameters
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Application__c retrieveApplication (String applicationId) {
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT ContactId, Profile.Name FROM User WHERE Id = :currentUserId];
        Boolean isCommunityUser = currentUser.Profile.Name == 'Customer Community General User';

    	Application__c applicationRecord = isCommunityUser ? getApplicationRecord(applicationId,currentUser.contactId) :  getApplicationRecord(applicationId); 

        return applicationRecord;
    }

    
        /**
        @author       Ant Ken McGuire
         @date        24.7.2023 
        Retrieves a single Application record based on the provided applicationId and applicant (contact).
        @param applicationId (String) The unique identifier of the Application record to retrieve.
        @param applicantId (String) The unique identifier of the applicant associated with the Application record.
        @return Application__c The Application record that corresponds to the provided applicationId. Returns null if no matching record is found.
        */

        private static Application__c getApplicationRecord(String applicationId, String applicantId) {
            return [SELECT Id, Name, Status__c FROM Application__c WHERE Id =: applicationId and  Applicant__c = :applicantId LIMIT 1];

        }

        /**
        @author       Ant Ken McGuire
         @date        24.7.2023 
        Retrieves a single Application record based on the provided applicationId
        @param applicationId (String) The unique identifier of the Application record to retrieve.
        @return Application__c The Application record that corresponds to the provided applicationId. Returns null if no matching record is found.
        */

        private static Application__c getApplicationRecord(String applicationId) {
            return [SELECT Id, Name, Status__c FROM Application__c WHERE Id =: applicationId  LIMIT 1 ];

        }

}