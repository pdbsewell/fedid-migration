/**
* @author Angelo Rivera
* @date 05.09.19
* @group TriggerHandlers
* @description Chat365LogTrigger Handler
* @revision 05.09.19 - Initial Create
            17 March 2020 - Cartick Sub - Link Contacts
            01 September 2020 - Included survey link to Chat 365 Log
*/

public class Chat365LogTriggerHandler {

    /**
    * @author Angelo Rivera
    * @date 05.09.19
    * @description Inner Class - inserts enquiry
    * @revision 05.09.19 - Initial Create <br/>
    * @         01.09.20 - Included survey link to Chat 365 Log <br/>
    */
    public class InsertChatBotSurvey extends TriggerAbstract {
        public set<Id> setLogIds = new Set<Id>();
        public override void process(SObject record, SObject oldRec) {
            Chat_365_Log__c newChatLog = (Chat_365_Log__c)record;
            Chat_365_Log__c oldChatLog = (Chat_365_Log__c)oldRec;

            if(newChatLog.Feedback_Comment__c != null && (newChatLog.Feedback_Comment__c != oldChatLog.Feedback_Comment__c)) {
                records.add(newChatLog);
                setLogIds.add(newChatLog.Id);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            try {
                if(!records.isEmpty()){
                    Map<Id, Chat_365_Log__c> mapChat365LogById = new Map<Id, Chat_365_Log__c>();

                    for(Chat_365_Log__c chLog :  [SELECT Id, Feedback_Comment__c, Feedback_Rating__c, Bot_Name__c,
                                                    (SELECT Id, ContactId FROM Enquiries__r ORDER BY CreatedDate DESC LIMIT 1) FROM Chat_365_Log__c WHERE Id IN: setLogIds]){
                        mapChat365LogById.put(chLog.Id, chLog);
                    }

                    if(!mapChat365LogById.isEmpty()){
                        List<Survey__c> lstSurveys = new List<Survey__c>();
                        for(Chat_365_Log__c chat365Log : mapChat365LogById.values()){
                            Survey__c newSurvey = new Survey__c();

                            if(!chat365Log.Enquiries__r.isEmpty()){
                                newSurvey.Enquiry__c = chat365Log.Enquiries__r.get(0).Id;
                                if(chat365Log.Enquiries__r.get(0).ContactId != null){
                                    newSurvey.Contact__c = chat365Log.Enquiries__r.get(0).ContactId;
                                }
                            }

                            newSurvey.RecordTypeId = MonashChat365Services.CHATBOTSURVEY_RECTYPEID;
                            newSurvey.Comments__c = chat365Log.Feedback_Comment__c;
                            newSurvey.Chat_Bot__c = chat365Log.Bot_Name__c;
                            newSurvey.How_satisfied__c = Integer.valueOf(chat365Log.Feedback_Rating__c);
                            newSurvey.Chat_365_Log__c = chat365Log.Id;

                            lstSurveys.add(newSurvey);
                        }
                        System.debug(LoggingLevel.DEBUG,'!@# SURVEY:  ' + lstSurveys);

                        if(!lstSurveys.isEmpty()) Database.insert(lstSurveys);
                        System.debug(LoggingLevel.DEBUG,'!@# Survey Inserted!' + lstSurveys);

                    }
                }
            } catch(Exception e) {
                ExLog.add('Chat365LogTriggerHandler','Survey__c','InsertChatBotSurvey', e);
            }
            LogUtilityException.getLimits();
        }
    }

    /**
    @author Cartick Sub
    @date 17 March 2020
    @group TriggerHandlers
    @description - Inner class to link Contacts based on matched Id fields
    @revision Initial version - 17 March 2020
    **/
    public class LinkContact extends TriggerAbstract {

        // Used to match Chat 365 Logs with Contacts
        private Set<String> setMatchIds = new Set<String>();

        /**
        @description Overrides parent class method for record insert.
        @param record The inserted Chat 365 Log record being processed under the trigger
        @revision Initial version 17 March 2020
        **/
        public override void process(SObject record) {

            Chat_365_Log__c logRecord = (Chat_365_Log__c)record;
            // Only process inserted Chat 365 Logs with Id Numbers, otherwise they cannot be linked to Contacts
            if (String.isNotBlank(logRecord.Id_Number__c)) {
                setMatchIds.add(logRecord.Id_Number__c);
                records.add(logRecord);
            }
        }

        /**
        @description Overrides parent class method for record update.
        @param record The updated Chat 365 Log record being processed under the trigger
        @revision Initial version 17 March 2020
        **/
        public override void process(SObject newRec, SObject oldRec) {

            // Process updated Chat 365 Logs if Id Number or Account Type were changed
            Chat_365_Log__c newLogRecord = (Chat_365_Log__c)newRec;
            Chat_365_Log__c oldLogRecord = (Chat_365_Log__c)oldRec;
            if (newLogRecord.Id_Number__c != oldLogRecord.Id_Number__c || newLogRecord.Account_Type__c != oldLogRecord.Account_Type__c) {
                records.add(newRec);
                
                if (String.isNotBlank(newLogRecord.Id_Number__c)) {
                    setMatchIds.add(newLogRecord.Id_Number__c);
                }
            }
        }

        /**
        @description Overrides parent class method.
        @revision Initial version 17 March 2020
        **/
        public override void execute() {

            if (!records.isEmpty()) {

                // Build maps of student and staff Contacts
                Map<String, Id> studentContactMap = buildStudentContactMap();
                Map<String, Id> staffContactMap = buildStaffContactMap();

                for (SObject record : records) {
                    Chat_365_Log__c logRecord = (Chat_365_Log__c)record;

                    // Unlink Contact if updated Chat 365 Log has no Id Number
                    if (String.isBlank(logRecord.Id_Number__c) && logRecord.Contact__c != null) {
                        ((Chat_365_Log__c)record).Contact__c = null;

                    // If Chat 365 Log has an Id Number, link Contact based on Account Type
                    } else if (String.isNotBlank(logRecord.Id_Number__c)) {

                        // Student Account Type
                        if (logRecord.Account_Type__c == 1) {
                            // Check if any student Contact has a Person Id which matches the log Id Number
                            if (studentContactMap.containsKey(logRecord.Id_Number__c)) {
                                // If so, link the Contact to the log
                                ((Chat_365_Log__c)record).Contact__c = studentContactMap.get(logRecord.Id_Number__c);
                            } else {
                                ((Chat_365_Log__c)record).Contact__c = null;
                            }

                        // Staff Account Type
                        } else if (logRecord.Account_Type__c == 2) {
                            // Check if any staff Contact has a SAP Staff Id which matches the log Id Number
                            if (staffContactMap.containsKey(logRecord.Id_Number__c)) {
                                // If so, link the Contact to the log
                                ((Chat_365_Log__c)record).Contact__c = staffContactMap.get(logRecord.Id_Number__c);
                            } else {
                                ((Chat_365_Log__c)record).Contact__c = null;
                            }
                        // For any other Account Type, unlink any Contact
                        } else {
                            if (logRecord.Contact__c != null) {
                                ((Chat_365_Log__c)record).Contact__c = null;
                            }
                        }
                    }
                }
            }
        }

        /**
        @description A helper method which retrieves from the database Contacts with matching Person Ids
        @return A map where the key is the Contact Person Id and the value is the Contact Id
        @revision Initial version - 17 March 2020
        **/
        private Map<String,Id> buildStudentContactMap() {
            Map<String, Id> studentContactMap = new Map<String, Id>();
            List<Contact> listStudentContacts = new List<Contact>();
            listStudentContacts = [SELECT Id, Person_ID_unique__c FROM Contact WHERE Person_ID_unique__c IN :setMatchIds];
            for (Contact studentContactRecord : listStudentContacts) {
                studentContactMap.put(studentContactRecord.Person_ID_unique__c, studentContactRecord.Id);
            }
            return studentContactMap;
        }

        /**
        @description A helper method which retrieves from the database Contacts with matching SAP Staff Ids
        @return A map where the key is the Contact SAP Staff Id and the value is the Contact Id
        @revision Initial version - 17 March 2020
        **/
        private Map<String,Id> buildStaffContactMap() {
            Map<String, Id> staffContactMap = new Map<String, Id>();
            List<Contact> listStaffContacts = new List<Contact>();
            listStaffContacts = [SELECT Id, SAP_Staff_Id__c FROM Contact WHERE SAP_Staff_Id__c IN :setMatchIds];
            for (Contact staffContactRecord : listStaffContacts) {
                staffContactMap.put(staffContactRecord.SAP_Staff_Id__c, staffContactRecord.Id);
            }
            return staffContactMap;
        }
    }
}