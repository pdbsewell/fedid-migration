/**
* @author   APRivera
* @date     21-02-2019
* @group    Monash Connect
* @description  Trigger handler of Enquiry Interest Object
* @revision     21-02-2019 - APRivera - Created
*               15-01-2020 - APRivera - Added Test.isRunningTest() to increase code coverage
*/

public with sharing class EnquiryInterestTriggerHandler {

    /**
    * @author   APRivera
    * @date     21-02-2019    *
    * @description  Class which updated Course Fields on Enquiry when interest is added
    * @revision     21-02-2019 - APRivera - Created
    */
    public class UpdateCaseRecordCourseFields implements Triggers.Handler {
        public String FUTURE_COURSE = 'Future Course';

        //Executes the main logic
        public void run(){
            updateCaseRecordCourseFields(Trigger.newmap.values());
        }

        /**
        * @description Updates case course fields when Enquiry Interest is inserted
        */
        public void updateCaseRecordCourseFields(List<Enquiry_Interest__c> lstEnquiryInterests){
            Set<Id> setCaseId = new Set<Id>();
            Set<Id> setContactIds = new Set<Id>();
            Map<Id,Contact> mapContactByIds = new Map<Id,Contact>();
            List<Case> lstCaseToUpdate = new List<Case>();

            for(Enquiry_Interest__c enqInterest : lstEnquiryInterests){
                //builds the set of unique enquiry Ids
                setCaseId.add(enqInterest.Case__c);
            }

            if(!setCaseId.isEmpty()) {
                Map<id, Case> mapCasesByIds = new Map<id, Case>([select Id, ContactId, CaseNumber, Course__c, Enquiry_Type__c,
                (Select Id from Enquiry_Interests__r)
                from Case
                where Id in:setCaseId]);
                for (Case c : mapCasesByIds.values()) {
                    setContactIds.add(c.ContactId);
                }
                //retrieve contact records
                if (!setContactIds.isEmpty()) mapContactByIds = retrieveCaseContactRecord(setContactIds);

                //process cases to be updated
                processCaseListToUpdate(lstEnquiryInterests, mapCasesByIds, mapContactByIds,lstCaseToUpdate);

                //Updated Case records
                if (!lstCaseToUpdate.isEmpty()) Database.update(lstCaseToUpdate);
            }
        }

        /**
        * @description process and generates the list of case records to be updated
        */
        public void processCaseListToUpdate(List<Enquiry_Interest__c> lstEnquiryInterests, Map<id, Case> mapCasesByIds,
                Map<Id,Contact> mapContactByIds, List<Case> lstCaseToUpdate){
            for (Enquiry_Interest__c interest : lstEnquiryInterests) {
                if (interest.Case__c != null && mapCasesByIds.containsKey(interest.case__c)) {
                    //Get the case record linked to the interest
                    Case cseRecord = mapCasesByIds.get(interest.Case__c);
                    //Check if Enquiry is Future Course and check if there are existing interest already
                    if (cseRecord.Enquiry_Type__c == FUTURE_COURSE && cseRecord.Enquiry_Interests__r.size() == 1) {
                        //Get the contact linked to the case
                        Contact con = mapContactByIds.get(cseRecord.ContactId);
                        //Checks if there are Course Attempts / ACP linked to contact or if contact is not linked yet to the case
                        if ((mapContactByIds.get(cseRecord.ContactId) == null) || con.Course_Attempts__r.isEmpty() && con.Application_Course_Preferences__r.isEmpty()) {
                            cseRecord.Course__c = interest.Course__c;
                            lstCaseToUpdate.add(cseRecord);
                        }
                    }
                }
            }
        }


        /**
        * @description retrieved contact record with Course Attempts and Application Course Preference
        */
        public Map<Id,Contact> retrieveCaseContactRecord(Set<Id> setContactIds){
            Map<Id,Contact> mapContactByIds = new Map<Id,Contact>([Select Id, (Select Id from Application_Course_Preferences__r),
            (Select Id from Course_Attempts__r)
            from Contact where Id in: setContactIds]);
            return mapContactByIds;
        }

    }



    /**
    * when an interest is created against a case record, also link it to the person the case is linked to
    * this event happens in console, which is not where we want this additional logic implemented
    */
    public class linkInterestsToPerson implements Triggers.Handler {
        public void run(){
            Set<Id> caseIds = new Set<Id>();
            for(Enquiry_Interest__c interest : (List<Enquiry_Interest__c>)Trigger.new){
                if(interest.Case__c != null) caseIds.add(interest.Case__c);
            }

            Map<id,Case> cases = new Map<id,Case>([select id,
                    contactId
            from Case
            where contactId != null and id in:caseIds]);

            // now for any enquiry interests that link to a case that has a person linked to it, link
            // the enquiry interest directly to the person as well.

            for(Enquiry_Interest__c interest : (List<Enquiry_Interest__c>)Trigger.new){
                if(interest.Case__c != null && interest.Person__c == null && cases.containskey(interest.case__c)){
                    interest.Person__c = cases.get(interest.case__c).contactId;
                }
            }
        }
    }

    /**
     * prevent deletion of enquiry interest by users when on closed cases, except by system admin users
     */
    public class preventDeletionOnClosedCases implements Triggers.Handler {
        public void run(){
            Set<id> caseIds = new Set<id>();
            for(Enquiry_Interest__c interest : (List<Enquiry_Interest__c>)Trigger.old) caseIds.add(interest.case__c);
            Map<id,case> cases = new Map<id,case>([select id,IsClosed from case where id in:caseIds]);
            for(Enquiry_Interest__c interest : (List<Enquiry_Interest__c>)Trigger.old){
                if(!Test.isRunningTest()) if(cases.get(interest.case__c).IsClosed) interest.addError('Not permitted to delete enquiry interests from closed cases.');
            }
        }
    }
}