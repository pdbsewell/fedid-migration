/**
@author Cartick Sub
@date 17 September 2020
@group Trigger Handlers
@description Trigger handler class for Student Letter Logs
@revision Initial version - 17 September 2020
**/

public class StudentLetterLogTriggerHandler {

    /**
    @author Cartick Sub
    @date 17 September 2020
    @group TriggerHandlers
    @description Inner class to link a Student Letter Log to the same Contact as its parent Chat 365 Log
    @revision Initial version - 17 September 2020
    **/
    public class LinkContact extends TriggerAbstract {

        // Store parent Chat 365 Log Ids for later use to retrieve related Contacts
        private Set<Id> setChat365LogIds = new Set<Id>();

        /**
        @description Overrides parent class method for record insert
        @param record The inserted Student Letter Log record being processed under the trigger
        @revision Initial version 17 September 2020
        **/
        public override void process(SObject record) {

            Student_Letter_Log__c logRecord = (Student_Letter_Log__c)record;
            // Only process an inserted Student Letter Log with a parent Chat 365 Log; otherwise it cannot easily be linked to a Contact
            if (logRecord.Chat_365_Log__c != null) {
                setChat365LogIds.add(logRecord.Chat_365_Log__c);
                records.add(logRecord);
            }
        }

        /**
        @description Overrides parent class method
        @revision Initial version 17 September 2020
        **/
        public override void execute() {

            if (!records.isEmpty()) {

                // Build map of Contacts by Chat 365 Log
                Map<Id, Id> mapContactsbyChat365Log = buildMapContactsbyChat365Log();

                if (!mapContactsbyChat365Log.isEmpty()) { // Only process records if at least one has a parent Chat 365 Log with a linked Contact
                    for (SObject record : records) {
                        Student_Letter_Log__c logRecord = (Student_Letter_Log__c)record;
                        if (mapContactsbyChat365Log.containsKey(logRecord.Chat_365_Log__c)) {
                            logRecord.Contact__c = mapContactsbyChat365Log.get(logRecord.Chat_365_Log__c);
                        }
                    }
                }
            }
        }

        /**
        @description A helper method which builds a map of Contacts by Chat 365 Logs
        @return A map where the key is the Chat 365 Log Id and the value is the Contact Id
        @revision Initial version - 17 September 2020
        **/
        private Map<Id,Id> buildMapContactsbyChat365Log() {
            Map<Id, Id> returnMap = new Map<Id, Id>();
            List<Chat_365_Log__c> listChat365Logs = new List<Chat_365_Log__c>();
            
            // Retrieve from database all Chat 365 Logs for Student Letter Logs being inserted, only if they have a linked Contact
            listChat365Logs = [SELECT Id, Contact__c FROM Chat_365_Log__c WHERE Id IN :setChat365LogIds AND Contact__c != null];
            for (Chat_365_Log__c logRecord : listChat365Logs) {
                returnMap.put(logRecord.Id, logRecord.Contact__c);
            }
            return returnMap;
        }
    }

    /**
    @author Cartick Sub
    @date 17 September 2020
    @group TriggerHandlers
    @description Inner class to link a Student Letter Log to the latest Enquiry for its parent Chat 365 Log
    @revision Initial version - 17 September 2020
    **/
    public class LinkEnquiry extends TriggerAbstract {
        
        // Store parent Chat 365 Log Ids for later use to retrieve related Enquiries
        private Set<Id> setChat365LogIds = new Set<Id>();

        /**
        @description Overrides parent class method for record insert
        @param record The inserted Student Letter Log record being processed under the trigger
        @revision Initial version 17 September 2020
        **/
        public override void process(SObject record) {

            Student_Letter_Log__c logRecord = (Student_Letter_Log__c)record;
            // Only process an inserted Student Letter Log with a parent Chat 365 Log; otherwise it cannot easily be linked to an Enquiry
            if (logRecord.Chat_365_Log__c != null) {
                setChat365LogIds.add(logRecord.Chat_365_Log__c);
                records.add(logRecord);
            }
        }

        /**
        @description Overrides parent class method.
        @revision Initial version 17 September 2020
        **/
        public override void execute() {

            if (!records.isEmpty()) {

                // Build map of Enquiries by Chat 365 Log
                Map<Id, List<Id>> mapEnquiriesbyChat365Log = buildMapEnquiriesbyChat365Log();

                if (!mapEnquiriesbyChat365Log.isEmpty()) { // Only process records if at least one has a parent Chat 365 Log with a child Enquiry
                    for (SObject record : records) {
                        Student_Letter_Log__c logRecord = (Student_Letter_Log__c)record;
                        if (mapEnquiriesbyChat365Log.containsKey(logRecord.Chat_365_Log__c)) {
                            logRecord.Enquiry__c = mapEnquiriesbyChat365Log.get(logRecord.Chat_365_Log__c)[0]; // Use last created Enquiry
                        }
                    }
                }
            }
        }

        /**
        @description A helper method which builds a map of Enquiries by Chat 365 Logs
        @return A map where the key is the Chat 365 Log Id and the value is a list of the child Enquiry Ids
        @revision Initial version - 17 September 2020
        **/
        private Map<Id, List<Id>> buildMapEnquiriesbyChat365Log() {
            Map<Id, List<Id>> returnMap = new Map<Id, List<Id>>();
            List<Case> listEnquiries = new List<Case>();

            // Retrieve from database all child Enquiries of the Chat 365 Logs for the Student Letter Logs being inserted
            listEnquiries = [SELECT Id, Chat_365_Log__c, CreatedDate FROM Case WHERE Chat_365_Log__c IN :setChat365LogIds ORDER BY CreatedDate DESC];
            for (Case enquiryRecord : listEnquiries) {
                if (returnMap.containsKey(enquiryRecord.Chat_365_Log__c)) {
                    returnMap.get(enquiryRecord.Chat_365_Log__c).add(enquiryRecord.Id);
                } else {
                    returnMap.put(enquiryRecord.Chat_365_Log__c, new List<Id>{enquiryRecord.Id});
                }
            }
            return returnMap;
        }
    }

}