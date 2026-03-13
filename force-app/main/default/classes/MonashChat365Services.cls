/**
* @author Angelo Rivera
* @date 05.09.19
* @group Utility
* @description Service class for Monash Chat 365 Functionality
* @revision 05.09.19 - Initial Create <br/>
*           20.11.19 - Updated routing engine. <br/>
                       Skill Type is now populated by the actual Skill name in all incoming chat request. <br/>
*           26.11.19 - Added Enquiry defaults for Future Students. <br/>
*           26.11.19 - Added Link on Chat Transcript and Chat 365 Log. <br/>
*           26.03.20 - Included Logic for Library Chat Agents. <br/>
*           18.08.20 - Added field mapping from Chat 365 log to Chat Transcript for  Future Students. <br/>
*           07.09.20 - Removed default skill routing to General Skill if no skilled agent available. <br/>
*           12.05.23 - Added additional mapping for Monash Connect (MCT-58). <br/>
*           08.06.23 - Added additional mapping and moving Logic from Case catg Level 1 to Topic Name (MCT-95). <br/>
*           27.06.23 - Added methods for myapp chatbot.
*           26.06.23 - Added authentication Logic for Future Students (MCT-113). <br/>
*           24.10.23 - Added new Logic for Live Person (MCT-278). <br/>
*           24.10.23 - Added new Logic for Contact Creation (MCT-291). <br/>
*           24.12.24 - Moved to nebula logging
*           17/01/25 - Updated generateContactQuery so all contacts are not queried for an invalid chat record. Also added null checks for email lowercase calls.
*/

public without sharing class MonashChat365Services {

    public static Id CHATBOTSURVEY_RECTYPEID {
        get {
            if(CHATBOTSURVEY_RECTYPEID == null) CHATBOTSURVEY_RECTYPEID = Schema.SObjectType.Survey__c.getRecordTypeInfosByDeveloperName().get('Chatbot_Feedback').getRecordTypeId();
            return CHATBOTSURVEY_RECTYPEID;
        }
        set;
    }

    private static final String CHATBOT_SUBJECT = 'Chatbot - Escalation';
    private static final String CHATBOT_DESCRIPTION = 'Chatbot - Escalation';
    private static final String CASE_ENQUIRY_TYPE = 'Current Course';
    private static final String CASE_ENQUIRY_TYPE_FUTURE = 'Future Course';
    private static final String CASE_ENQUIRY_TYPE_NONCOURSE = 'Non Course';
    private static final String CASE_ORIGIN_LIVE_CHAT = 'Chatbot - Live Chat';
    private static final String CASE_ORIGIN_ONLINE = 'Chatbot - Online';
    private static final String CASE_ORIGIN_LIVE_PERSON = 'LivePerson - Messaging';
    private static final String CASE_ORIGIN_VTAC_LIVE_CHAT = 'Chatbot - VTAC Live Chat';
    private static final String CASE_ORIGIN_VTAC_ONLINE = 'Chatbot - VTAC Online';
    private static final String USER_STUDENT = 'Student';
    private static final String USER_STAFF = 'Staff';
    private static final String USER_NEITHER = 'Visitor';
    private static final String CAT_LEVEL1_ENR_FUT_CRS = 'Enrolment - Future Course';
    private static final String FUTURE_STUDENT = 'Future Student';
    private static final String LIBRARY = 'Library';
    private static final String SCHOLARSHIPS = 'Scholarships';
    private static final String VISA_COE = 'Visa/CoE';
    private static final String M_PASS = 'M-Pass';
    private static final String MC_MY_APP = 'MC my.app';
    private static final String STUDENT_REC_PRE_APP = 'Student rec pre-app';
    private static final String STUDENT_REC_POST_APP = 'Student rec post-app';
    private static final String EADMISSIONS = 'eAdmissions';
    private static final String FUTURE_DOMESTIC = 'Future Domestic';
    private static final String FUTURE_INTERNATIONAL = 'Future International';
    private static final String MGRO = 'MGRO';

    /*******************************************************************************************************
    * @description Updates Chat 365 Log object when ChatTranscript is updated.
    * @param List<LiveChatTranscript> lstChatTranscripts - List of ChatTranscript
    * @return void
    */
    public static void updateChat365LogOnChatTranscriptUpdate(List<LiveChatTranscript> lstChatTranscripts){
        Map<Id, String> mapVTACNumberByChat365LogIds = new Map<Id, String>();
        for(LiveChatTranscript chatTranscript : lstChatTranscripts){
            mapVTACNumberByChat365LogIds.put(chatTranscript.Chat_365_Log__c, chatTranscript.VTAC_Number__c);
        }

        if(!mapVTACNumberByChat365LogIds.isEmpty()){
            Map<Id, Chat_365_Log__c> mapChatLogsByIds = retrieveMapChatLogsByIds(mapVTACNumberByChat365LogIds.keySet());
            List<Chat_365_Log__c> lstChat365LogsToUpdate = new List<Chat_365_Log__c>();
            for(Chat_365_Log__c chat365Log : mapChatLogsByIds.values()){
                chat365Log.VTAC_Number__c = mapVTACNumberByChat365LogIds.get(chat365Log.Id);
                lstChat365LogsToUpdate.add(chat365Log);
            }

            try{
                if(!lstChat365LogsToUpdate.isEmpty()) update lstChat365LogsToUpdate;
            } catch(Exception e){
                ExLog.add('MonashChat365Services','Chat_365_Log__c','updateChat365LogOnChatTranscriptUpdate', e.getMessage());
                nebula.logger.exception(e.getMessage(),e);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }

    /*******************************************************************************************************
    * @description Checks status of ChatTranscript (In Progress) and updates fields such as Case, Contact and DialogFlow parameters
    * @param List<LiveChatTranscript> lstChatTranscripts - List of ChatTranscript
    * @param Set<String> setChatKeys - set of ChatTranscript ChatKeys
    * @param Boolean bInProgress - Boolean flag to identify records to be processed
    * @return void
    */
    public static void checkStatusUpdatesOnLiveChatTranscript(List<LiveChatTranscript> lstChatTranscripts, Set<String> setChatKeys, Boolean bInProgress){
        Map<String,LiveChatTranscript> mapChatTranscriptsByChatKey = new Map<String, LiveChatTranscript>();
        Map<String, Chat_365_Log__c> mapChatLogsByChatKey  = new Map<String, Chat_365_Log__c>(); // = retrieveMapChatLogsByChatKeys(setChatKeys);
        Set<Id> setChatLogIds = new Set<Id>();
        List<Chat_365_Log__c> lstChatLogs = [SELECT Id, First_Name__c, Last_Name__c, Email__c, Id_Number__c, Bot_Name__c, Chat_Key__c, Date_of_Birth__c,
                Subject__c, Description__c, Account_Type__c, Topic__c, Chat_Agent_Availability_Status__c, User_Authenticated__c,
                Is_Chat_Escalation__c, VTAC_Number__c, Get_Started_Step__c, Study_Area__c, Student_Type__c
                FROM Chat_365_Log__c WHERE Chat_Key__c IN: setChatKeys ];
        for(Chat_365_Log__c chatLog : lstChatLogs){
            String strChatkey = chatLog.Chat_Key__c.replace('-', '');
            mapChatLogsByChatKey.put(strChatkey, chatLog);
            setChatLogIds.add(chatLog.Id);
        }
        for(LiveChatTranscript newChatTranscript : lstChatTranscripts){
            String strChatkey = newChatTranscript.ChatKey.replace('-', '');
            mapChatTranscriptsByChatKey.put(strChatkey, newChatTranscript);
        }
        if(bInProgress){
            updateLiveChatTranscript(setChatLogIds, mapChatTranscriptsByChatKey.values(), mapChatLogsByChatKey);
        }
    }


    /*******************************************************************************************************
    * @description Updates field values of ChatTranscript, Links Case and contact to transcript.
    * @param Set<Id> setChatLogIds - Set Chat 365 Log Ids to be processed
    * @param List<LiveChatTranscript> lstValidChatList - List of LiveChatTranscript to be processed
    * @param Map<String, Chat_365_Log__c> mapChatLogsByChatKey - Map of Chat logs by ChatKey referenced from ChatTranscript ChatKeys
    * @return void
    */
    public static void updateLiveChatTranscript(Set<Id> setChatLogIds, List<LiveChatTranscript> lstValidChatList, Map<String, Chat_365_Log__c> mapChatLogsByChatKey){
        List<LiveChatTranscript> lstLiveChatTranscriptToUpdate = new List<LiveChatTranscript>();
        Map<Id, Case> mapCasesByChatLogId = new Map<Id, Case>();
        Map<Id, Case> mapCasesByIds = new Map<Id, Case>();
        List<Case> lstCases = new List<Case>();
        for(Chat_365_Log__c clogs : [SELECT Id, (SELECT Id, OwnerId, ContactId, Chat_365_Log__c, Category_Level_1__c FROM Enquiries__r ORDER BY CreatedDate DESC)
                                    FROM Chat_365_Log__c 
                                    WHERE Id IN: setChatLogIds ]){
            if(!clogs.Enquiries__r.isEmpty()) mapCasesByChatLogId.put(clogs.Id, clogs.Enquiries__r.get(0));
            mapCasesByIds.put(clogs.Enquiries__r.get(0).Id, clogs.Enquiries__r.get(0));
        }

        for(LiveChatTranscript lct : lstValidChatList){
            LiveChatTranscript newChat = new LiveChatTranscript(Id = lct.Id, ChatKey = lct.ChatKey);
            String strChatkey = newChat.ChatKey.replace('-', '');
            if(mapChatLogsByChatKey.containsKey(strChatkey)){
                Chat_365_Log__c chatLogRecord = mapChatLogsByChatKey.get(strChatkey);
                if(mapCasesByChatLogId.containsKey(chatLogRecord.Id)){
                    //Update the Case owner to Live Agent
                    Id caseId = mapCasesByChatLogId.get(chatLogRecord.Id).Id;
                    Case cse = mapCasesByIds.get(caseId);
                    cse.OwnerId = UserInfo.getUserId();
                    lstCases.add(cse);

                    newChat.CaseId = caseId;
                    newChat.ContactId = mapCasesByChatLogId.get(chatLogRecord.Id).ContactId;
                    newChat.ID_Number__c = chatLogRecord.Id_Number__c;
                    newChat.Email__c = chatLogRecord.Email__c;
                    newChat.First_Name__c = chatLogRecord.First_Name__c;
                    newChat.Last_Name__c = chatLogRecord.Last_Name__c;
                    newChat.Date_Of_Birth__c = String.valueOf(chatLogRecord.Date_of_Birth__c);
                    newChat.Account_Type__c = chatLogRecord.Account_Type__c == 1 ? USER_STUDENT : chatLogRecord.Account_Type__c == 2 ? USER_STAFF : USER_NEITHER;
                    newChat.VTAC_Number__c = chatLogRecord.VTAC_Number__c; // MC-1136 - APRivera - New field mapping for Future Students
                    if(chatLogRecord.User_Authenticated__c != null){
                        newChat.User_Authenticated__c = String.valueOf(chatLogRecord.User_Authenticated__c).toLowerCase() == 'yes' ? true : false;
                    }
                    newChat.Chat_365_Log__c = chatLogRecord.Id;
                    lstLiveChatTranscriptToUpdate.add(newChat);
                }
            }
        }
        try{
            if(!lstCases.isEmpty()) update lstCases;

            if(!lstLiveChatTranscriptToUpdate.isEmpty()) update lstLiveChatTranscriptToUpdate;
        } catch(Exception e){
            ExLog.add('MonashChat365 -update LiveChat Transcript','Case','MonashChat365Services - updateLiveChatTranscript', e.getMessage());
            nebula.logger.exception(e.getMessage(),e);
        } finally {
            nebula.logger.saveLog();
        }
}

    /*******************************************************************************************************
    * @description Retrieves Map of Case by Chat 365 Log Ids
    * @param Set<Id> setChatLogIds - Set of Chat 365 Log Ids to be processed
    * @return Map<Id, String> mapChatLogDetailTopicByChatLogId - Map of Topic by Chat 365 Log Ids
    */
    public static Map<Id, String> retrieveMapChatLogDetailTopicByChatLogId(Set<Id> setChatLogIds){
        Map<Id, String> mapChatLogDetailTopicByChatLogId = new Map<Id, String>();
        for(Chat_365_Log_Detail__c chatlogDetail : [SELECT Id, Topic__c, Chat_365_Log__c
                                                    FROM Chat_365_Log_Detail__c 
                                                    WHERE Chat_365_Log__c IN: setChatLogIds 
                                                    AND Intent__c = 4
                                                    ORDER By CreatedDate ASC]){
            if(String.isNotBlank(chatlogDetail.Topic__c)) mapChatLogDetailTopicByChatLogId.put(chatlogDetail.Chat_365_Log__c, chatlogDetail.Topic__c);
        }
        return mapChatLogDetailTopicByChatLogId;
    }


    /*******************************************************************************************************
    * @description Generates and Inserts new Enquiry
    * @param Set<Id> setChatLogIds - Set of Chat 365 Log Ids
    * @param List<Chat_365_Log_Detail__c> lstChatLogDetails - List of Chat 365 Log Details
    * @return void
    */
    public static void insertEnquiry(Set<Id> setChatLogIds, List<Chat_365_Log_Detail__c> lstChatLogDetails){
        if(!setChatLogIds.isEmpty()){
            Map<Id, Chat_365_Log_Detail__c> mapChatDetailsByChatLogIds = new Map<Id, Chat_365_Log_Detail__c>();
            Map<Id, Chat_365_Log__c> mapChatLogByIds = new Map<Id, Chat_365_Log__c>();
            Set<Id> setChatLogsToHaveEnquiry= new Set<Id>();
            for(Chat_365_Log_Detail__c logDetail : lstChatLogDetails){
                setChatLogsToHaveEnquiry.add(logDetail.Chat_365_Log__c);
                mapChatDetailsByChatLogIds.put(logDetail.Chat_365_Log__c, logDetail);
            }
            if(!setChatLogsToHaveEnquiry.isEmpty()){
                mapChatLogByIds = retrieveMapChatLogsByIds(setChatLogsToHaveEnquiry);
                if(!mapChatLogByIds.isEmpty()){
                    List<Case> lstNewCases = new List<Case>();
                    try{
                        generateCase(mapChatLogByIds, mapChatDetailsByChatLogIds, lstNewCases);
                        if(!lstNewCases.isEmpty()){
                            Database.insert(lstNewCases);
                        }
                    } catch(Exception e){
                        ExLog.add('MonashChat365 - Insert new enquiry','Case','MonashChat365Services - insertEnquiry', e.getMessage());
                        nebula.logger.exception(e.getMessage(),e);
                    } finally {
                        nebula.logger.saveLog();
                    }
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Generates New Case - Links Contact, sets owner and other default values
    * @param Map<Id, Chat_365_Log__c> mapChatLogByIds - map of Chat 365 Log by Ids
    * @param Map<Id, Chat_365_Log_Detail__c> mapChatDetailsByChatLogIds - map of Chat 365 Log Details by Chat 365 Log Ids
    * @param List<Case> lstNewCases - List of new cases to be generated
    * @return void
    */
    public static void generateCase(Map<Id, Chat_365_Log__c> mapChatLogByIds, Map<Id, Chat_365_Log_Detail__c> mapChatDetailsByChatLogIds,
            List<Case> lstNewCases) {
        try{
            Map<String, String> mapTopicToCaseCategory = getTopicCaseCategoryMapping();
            Map<String, Id> mapQueueIdByName = retrieveQueueIds();
            Map<String,Case> myAppCases = new Map<String,Case>();
            for(Chat_365_Log__c chatLog : mapChatLogByIds.values()){
                String strContactQuery = generateContactQuery(chatLog);
                Contact conRecord = getEnquiryContact(strContactQuery, chatLog);
                Chat_365_Log_Detail__c chatDetail = mapChatDetailsByChatLogIds.get(chatLog.Id);
                Case newCase = setCaseDefaults(chatLog, chatDetail, mapTopicToCaseCategory, mapQueueIdByName);
                newCase.ContactId = conRecord.Id;
                lstNewCases.add(newCase);
                if(chatLog.Bot_Name__c == 'MyApp') {
                    myAppCases.put(chatLog.Email__c,newCase);
                }
            }
            if (myAppCases.size()>0) {
                Map<String,String> emails = retrieveMessageMatchingEmails(myAppCases.keyset());
                for (String currentEmail : emails.keyset()) {
                    if (myAppCases.containsKey(currentEmail)) {
                        Case  cseRecord = myAppCases.get(currentEmail);
                        String error = emails.get(currentEmail);
                        cseRecord.Subject = !String.isBlank(cseRecord.Subject) ? cseRecord.Subject + ' - ' + error : error;
                    }
                }
            }
        } catch (exception ex) {
            nebula.logger.exception(ex.getMessage(),ex);
            throw ex;
        }
    }


    /*******************************************************************************************************
    * @description Sets Case Default values
    * @param Chat_365_Log__c chatLog - Chat 365 Log
    * @param Chat_365_Log_Detail__c chatDetail - Chat 365 Log Detail
    * @param Map<String, String> mapTopicToCaseCategory - Case_Category_Skill_Mapping__mdt
    * @return Case cseRecord
    */
    public static Case setCaseDefaults(Chat_365_Log__c chatLog, Chat_365_Log_Detail__c chatDetail,
            Map<String, String> mapTopicToCaseCategory, Map<String, Id> mapQueueIdByName){
        Case cseRecord = new Case();
        if(chatLog.Bot_Name__c == 'VTAC'){ // VTAC
            cseRecord.OwnerId = mapQueueIdByName.get('Monash_Connect_Future_Student');
            cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE_FUTURE;
            cseRecord.Origin = chatLog.Is_Chat_Escalation__c == 'Yes' ? CASE_ORIGIN_VTAC_LIVE_CHAT : CASE_ORIGIN_VTAC_ONLINE;
            cseRecord.Student_Type__c = chatLog.Student_Type__c;
            cseRecord.Subject = chatLog.VTAC_Number__c + ' - ' + chatLog.Get_Started_Step__c + ' - ' + chatLog.Study_Area__c;
            cseRecord.Category_Level_1__c = CAT_LEVEL1_ENR_FUT_CRS;
        } else{ //NON-VTAC
            cseRecord.Subject = !String.isBlank(chatDetail.Subject__c) ? chatDetail.Subject__c : CHATBOT_SUBJECT;
            if(chatDetail.Topic__c == FUTURE_STUDENT  || chatDetail.Topic__c == FUTURE_DOMESTIC || chatDetail.Topic__c == FUTURE_INTERNATIONAL){ // FUTURE - future students
                cseRecord.OwnerId = mapQueueIdByName.get('Monash_Connect_Future_Student');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE_FUTURE;
                if(!String.isBlank(chatLog.Course__c)){
                    cseRecord.Subject = !String.isBlank(chatDetail.Subject__c) ? chatDetail.Subject__c + ' - ' + chatLog.Course__c : CHATBOT_SUBJECT  + ' - ' + chatLog.Course__c;
                }
            } else if(chatDetail.Topic__c == LIBRARY){ // Library Bot - authenticated users and selected topic is library
                cseRecord.OwnerId = mapQueueIdByName.get('Library_Frontline_Services');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE;
            } else if(chatDetail.Topic__c == SCHOLARSHIPS){ // Library Bot - authenticated users and selected topic is Scholarship
                cseRecord.OwnerId = mapQueueIdByName.get('Monash_Connect_Current_Student');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE;
            }else if(chatDetail.Topic__c == VISA_COE){ // Library Bot - authenticated users and selected topic is Visa
                cseRecord.OwnerId = mapQueueIdByName.get('Monash_Connect_Current_Student');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE;
            }else if(chatDetail.Topic__c == M_PASS){ // Library Bot - authenticated users and selected topic is M Pass
                cseRecord.OwnerId = mapQueueIdByName.get('MPass_Card_Office');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE;
            }else if(chatDetail.Topic__c == MC_MY_APP){ // Library Bot - authenticated users and selected topic is MC My.App
                cseRecord.OwnerId = mapQueueIdByName.get('Monash_Connect_Future_Student');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE_FUTURE;
            }else if(chatDetail.Topic__c == STUDENT_REC_PRE_APP){ // Library Bot - authenticated users and selected topic is Pre App
                cseRecord.OwnerId = mapQueueIdByName.get('OFS_Enquiries');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE_FUTURE;
            }else if(chatDetail.Topic__c == STUDENT_REC_POST_APP){ // Library Bot - authenticated users and selected topic is Post - App
                cseRecord.OwnerId = mapQueueIdByName.get('Student_Rec_Enquiries_Post_Application');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE_FUTURE;
            }else if(chatDetail.Topic__c == EADMISSIONS){ // Library Bot - authenticated users and selected topic is EAdmissions
                cseRecord.OwnerId = mapQueueIdByName.get('eSolutions_Admissions');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE_FUTURE;
            }else if(chatDetail.Topic__c == FUTURE_DOMESTIC){ // Library Bot - authenticated users and selected topic is FUTURES DOMESTIC
                cseRecord.OwnerId = mapQueueIdByName.get('Monash_Connect_Future_Student');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE_FUTURE;
            }else if(chatDetail.Topic__c == FUTURE_INTERNATIONAL){ // Library Bot - authenticated users and selected topic is FUTURES INTERNATIONAL
                cseRecord.OwnerId = mapQueueIdByName.get('Monash_Connect_Future_Student');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE_FUTURE;
            }else if(chatDetail.Topic__c == MGRO){ // Library Bot - authenticated users and selected topic is MGRO
                cseRecord.OwnerId = mapQueueIdByName.get('MGE_Admissions');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE_FUTURE;
            }else{ // CURRENT - authenticated users, all other topic goes to here
                cseRecord.OwnerId = mapQueueIdByName.get('Monash_Connect_Current_Student');
                cseRecord.Enquiry_Type__c = CASE_ENQUIRY_TYPE;
            } 
            if(chatLog.User_Authenticated__c == 'No' && chatDetail.Topic__c != FUTURE_INTERNATIONAL && chatDetail.Topic__c != FUTURE_DOMESTIC){ // non-authenticated users, set the enquiry type to non course
                cseRecord.Enquiry_Type__c = chatDetail.Topic__c == FUTURE_STUDENT ? CASE_ENQUIRY_TYPE_FUTURE : CASE_ENQUIRY_TYPE_NONCOURSE;
            }
            cseRecord.Origin = chatDetail.Intent__c == 1 ? CASE_ORIGIN_ONLINE : (chatDetail.Intent__c == 5 ? CASE_ORIGIN_LIVE_PERSON : CASE_ORIGIN_LIVE_CHAT);
            cseRecord.Category_Level_1__c = mapTopicToCaseCategory.containsKey(chatDetail.Topic__c.toLowerCase()) ? mapTopicToCaseCategory.get(chatDetail.Topic__c.toLowerCase()) : '';
        }

        cseRecord.RecordTypeId = MonConCaseServices.MONCON_RECTYPEID;
        cseRecord.Student_Type__c = !String.isBlank(chatLog.Student_Type__c) ? chatLog.Student_Type__c : '';
        cseRecord.Description = !String.isBlank(chatDetail.Description__c) ? chatDetail.Description__c : CHATBOT_DESCRIPTION;
        cseRecord.SuppliedEmail = chatLog.Email__c;
        cseRecord.Supplied_First_Name__c = chatLog.First_Name__c;
        cseRecord.Supplied_Last_Name__c = chatLog.Last_Name__c;
        cseRecord.Chat_365_Log__c = chatLog.Id;
        if(chatLog.Bot_Name__c == 'MyApp') {
            if (chatLog.Date_of_Birth__c != null) {
                cseRecord.Supplied_Date_of_Birth__c = chatLog.Date_of_Birth__c;
            }
            cseRecord.SuppliedPhone = chatLog.Phone__c;
            if(!String.isBlank(chatLog.Course__c)){
                cseRecord.Subject = !String.isBlank(chatDetail.Subject__c) ? chatDetail.Subject__c + ' - ' + chatLog.Course__c : CHATBOT_SUBJECT  + ' - ' + chatLog.Course__c;
            }
        }
        return cseRecord;
    }


    /*******************************************************************************************************
    * @description Returns map of Chat 365 Log by Id
    * @param Set<Id> setChatLogIds - Set of Chat 365 Log Ids
    * @return Map<Id, Chat_365_Log__c> mapChatLogByIds - map of Chat 365 Log by Id
    */
    public static Map<Id, Chat_365_Log__c> retrieveMapChatLogsByIds(Set<Id> setChatLogIds){
        Map<Id, Chat_365_Log__c> mapChatLogByIds = new Map<Id, Chat_365_Log__c>();

        for(Chat_365_Log__c chatLog : [SELECT Id, First_Name__c, Last_Name__c, Email__c, Id_Number__c, Bot_Name__c, Chat_Key__c, Date_of_Birth__c,
                                                Subject__c, Description__c, Account_Type__c, Topic__c, Chat_Agent_Availability_Status__c, User_Authenticated__c,
                                                Is_Chat_Escalation__c, VTAC_Number__c, Get_Started_Step__c, Study_Area__c, Student_Type__c, Course__c,Phone__c
                                        FROM Chat_365_Log__c WHERE Id IN: setChatLogIds ]){
            mapChatLogByIds.put(chatLog.Id, chatLog);
        }
        return mapChatLogByIds;
    }


    /*******************************************************************************************************
    * @description Returns map of Chat 365 Log by Chat Keys
    * @param Set<String> setChatKeys - Set of Chat keys referenced from Chat Transcript ChatKeys
    * @return Map<String, Chat_365_Log__c> mapChatLogsByChatKey - map of Chat 365 Log by Chat Keys
    */
    public static Map<String, Chat_365_Log__c> retrieveMapChatLogsByChatKeys(Set<String> setChatKeys){
        Map<String, Chat_365_Log__c> mapChatLogsByChatKey = new Map<String, Chat_365_Log__c>();
        for(Chat_365_Log__c chatLog : [SELECT Id, First_Name__c, Last_Name__c, Email__c, Id_Number__c, Bot_Name__c, Chat_Key__c, Date_of_Birth__c,
                                                Subject__c, Description__c, Account_Type__c, Topic__c, Chat_Agent_Availability_Status__c, User_Authenticated__c,
                                                Is_Chat_Escalation__c, VTAC_Number__c, Get_Started_Step__c, Study_Area__c, Student_Type__c, Course__c,Phone__c
                                        FROM Chat_365_Log__c WHERE Chat_Key__c IN: setChatKeys ]){
            mapChatLogsByChatKey.put(chatLog.Chat_Key__c, chatLog);
        }
        return mapChatLogsByChatKey;
    }


    /*******************************************************************************************************
    * @description Generated Contact query
    * @param Chat_365_Log__c chatLog - Chat 365 Log Record
    * @return String strContactQuery - Contact Query
    */
    public static String generateContactQuery(Chat_365_Log__c chatLog){
        String strQuery = 'Select Id, Email, Personal_Email__c, Person_ID__c, SAP_Staff_Id__c, Monash_Email_Address__c from Contact ';
        String strQuerySuffix = '';
        String strChatLogEmail = '';
        Boolean hasEmail = false;
        Boolean hasId = false;
        Integer accountType = Integer.valueOf(chatLog.Account_Type__c); 
        
        if (accountType >= 1 && accountType <= 3) {} else {accountType=0;}
        if (!String.isBlank(chatLog.Id_Number__c)) {hasId = true;}
        if (!String.isBlank(chatLog.Email__c)) {
			strChatLogEmail = chatLog.Email__c.tolowercase(); // not strictly required
            hasEmail = true;
        }

        switch on accountType {
            when 1 {// Student
                if (hasId) {strQuerySuffix += 'Person_Id__c = \'' + chatLog.Id_Number__c + '\' ';}
                if (hasId && hasEmail) {strQuerySuffix += 'or ';}
                if (hasEmail) {strQuerySuffix += 'Monash_Email_Address__c = \'' + strChatLogEmail + '\' ';}
            }	
            when 2 {// Staff
                if (hasId) {strQuerySuffix += 'SAP_Staff_Id__c = \'' + chatLog.Id_Number__c + '\' ';}
                if (hasId && hasEmail) {strQuerySuffix += 'or ';}
                if (hasEmail) {strQuerySuffix += 'Monash_Email_Address__c = \'' + strChatLogEmail + '\' ';}
            }
            when 3 {// Visitor
				if (hasEmail) {
                    strQuerySuffix += 'Personal_Email__c = \'' + strChatLogEmail + '\' or Email =\'' + strChatLogEmail + '\' ';
                } 
            }
            when else {
                nebula.logger.warn('Invalid account type specified - 1, 2 or 3 expected.', chatLog);
				if (hasEmail) {
                    strQuerySuffix += 'Personal_Email__c = \'' + strChatLogEmail + '\' or Email =\'' + strChatLogEmail + '\' ';
                }
            }
        }
        
        If (!String.isBlank(strQuerySuffix)) {
	        strQuery += 'where ' + strQuerySuffix + 'order by createddate';
        } else {
            strQuery += 'limit 0'; // if the details are not correct, ensure we don't query all contacts
        }

        nebula.logger.debug(strQuery, chatLog);
        return strQuery;
    }


    /*******************************************************************************************************
    * @description Identifies the appropriate contact to be linked to the case
    * @param String strContactQuery - Contact query
    * @param Chat_365_Log__c chatLog - Chat 365 Log record
    * @return Contact contactToBeUsed - Contact to be linked to the case and ChatTranscript
    */
    public static Contact getEnquiryContact(String strContactQuery, Chat_365_Log__c chatLog){
        Map<String, Contact> mapContactIdsByPersonId = new Map<String, Contact>();
        Map<String, Contact> mapContactIdsByPersonalEmail = new Map<String, Contact>();
        Map<String, Contact> mapContactIdsByMonashEmail = new Map<String, Contact>();
        Map<String, Contact> mapContactIdsByStaffId = new Map<String, Contact>();
        Contact contactToBeUsed = new Contact();
        Boolean bContactMatched = false;

        // Retrieves and Generates contact mappings
        generateContactMaps(mapContactIdsByStaffId, mapContactIdsByPersonId, mapContactIdsByPersonalEmail, mapContactIdsByMonashEmail, strContactQuery, chatLog);

        // Search for and Choose the relevant Contact to be linked to case
        if(chatLog.Account_Type__c != 3){ // NOT Student or NOT Staff
            if(chatLog.Account_Type__c == 1){ // Student
                if(mapContactIdsByPersonId.containsKey(chatLog.Id_Number__c)){
                    contactToBeUsed = mapContactIdsByPersonId.get(chatLog.Id_Number__c);
                    bContactMatched = true;
                }
            }else{ // Staff
                if(mapContactIdsByStaffId.containsKey(chatLog.Id_Number__c)){
                    contactToBeUsed = mapContactIdsByStaffId.get(chatLog.Id_Number__c);
                    bContactMatched = true;
                }
            }
            if(!bContactMatched){
                if(mapContactIdsByMonashEmail.containsKey(chatLog.Email__c?.toLowerCase())){
                    contactToBeUsed = mapContactIdsByMonashEmail.get(chatLog.Email__c?.toLowerCase());
                    bContactMatched = true;
                }
            }
        }else if(chatLog.Email__c != null){  // Neither
            if(mapContactIdsByPersonalEmail.containsKey(chatLog.Email__c?.toLowerCase())){
                contactToBeUsed = mapContactIdsByPersonalEmail.get(chatLog.Email__c?.toLowerCase());
                bContactMatched = true;
            }
        }
        return contactToBeUsed;
    }


    /*******************************************************************************************************
    * @description Generats mapping of contacts by Staff Ids, by Email addresses and Student Ids
    * @param Map<String, Contact> mapContactIdsByStaffId - Map of Contact by Staff Id
    * @param Map<String, Contact> mapContactIdsByPersonId - Map of Contact by Person Id
    * @param Map<String, Contact> mapContactIdsByPersonalEmail - Map of Contact by Personal Email
    * @param Map<String, Contact> mapContactIdsByMonashEmail - Map of Contact by Monash Email address
    * @param String strContactQuery - Contact Query
    * @param Chat_365_Log__c chatLog - Chat 365 Log record
    * @return void
    */
    public static void generateContactMaps(Map<String, Contact> mapContactIdsByStaffId, Map<String, Contact> mapContactIdsByPersonId,
            Map<String, Contact> mapContactIdsByPersonalEmail, Map<String, Contact> mapContactIdsByMonashEmail,
            String strContactQuery, Chat_365_Log__c chatLog) {
                
        List<Contact> l_linkedCont = Database.query(strContactQuery);
        if(l_linkedCont.isEmpty()){
            // No Linked COntact exists create a fresh one based on the Chat Log fields
            l_linkedCont = new List<Contact>();
            l_linkedCont.add(createContact(chatLog));
        }
        for(Contact conRec : l_linkedCont){
            if(chatLog.Account_Type__c != 3){ // Student or Staff
                if(chatLog.Account_Type__c  == 1){ // Student
                    if(conRec.Person_ID__c != null){
                        mapContactIdsByPersonId.put(conRec.Person_ID__c, conRec);
                    }
                }else{
                    if(conRec.SAP_Staff_Id__c != null){
                        mapContactIdsByStaffId.put(conRec.SAP_Staff_Id__c.toLowerCase(), conRec);
                    }
                }
                if(conRec.Monash_Email_Address__c != null){
                    mapContactIdsByMonashEmail.put(conRec.Monash_Email_Address__c.toLowerCase(), conRec);
                }
            }else{
                if(conRec.Personal_Email__c != null){
                    mapContactIdsByPersonalEmail.put(conRec.Personal_Email__c.toLowerCase(), conRec);
                }else{
                    if(conRec.Email != null) mapContactIdsByPersonalEmail.put(conRec.Email.toLowerCase(), conRec);
                }
            }
        }
    }
    
    /*******************************************************************************************************
    * @description Generated Contact query
    * @param Chat_365_Log__c chatLog - Chat 365 Log Record
    * @return Contact
    */
    public static Contact createContact(Chat_365_Log__c chatLog){
        // Contact creation runs on the basis of Account_Type__c - 1 Student - 2 Student - 3 Neither 
        Contact newIncomingContact = new Contact();
        newIncomingContact.Email = chatLog.Email__c?.toLowerCase();
        newIncomingContact.Firstname = chatLog.First_Name__c;
        newIncomingContact.Lastname = chatLog.Last_Name__c;
        if(chatLog.Account_Type__c == 3){ // Neither
            newIncomingContact.Personal_Email__c = chatLog.Email__c?.toLowerCase();
        }else{
            if(String.isNotBlank(chatLog.Id_Number__c)){
                if(chatLog.Account_Type__c  == 1) newIncomingContact.Person_ID_unique__c = chatLog.Id_Number__c; // Student
                if(chatLog.Account_Type__c  == 2) newIncomingContact.SAP_Staff_Id__c = chatLog.Id_Number__c; // Staff
            }
            newIncomingContact.Monash_Email_Address__c = chatLog.Email__c?.toLowerCase();
        }
        // Assign the Rec Type - Non Student if Person_ID__c & SAP_Staff_Id__c are Blank
        if(String.isBlank(newIncomingContact.SAP_Staff_Id__c) && String.isBlank(newIncomingContact.Person_ID_unique__c )){
            newIncomingContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId(); 
        }else{
            newIncomingContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId(); 
        }
        insert newIncomingContact;
        return [SELECT Id, Email, Personal_Email__c, Person_ID__c, SAP_Staff_Id__c, Monash_Email_Address__c FROM Contact WHERE Id = :newIncomingContact.Id];
    }

    /*******************************************************************************************************
    * @description Returns Id of Queue by queue name
    * @param String strQueueName - Queue developer name
    * @return Queue Id
    */
    public static Map<String, Id> retrieveQueueIds(){
        Map<String, Id> mapQueueIdByName = new Map<String, Id>();
        for(Group grp : [SELECT Id, Name, DeveloperName FROM Group where Type = 'Queue'  
                        AND (DeveloperName like 'Monash_Connect_%_Student' OR DeveloperName = 'Library_Frontline_Services' 
                        OR DeveloperName like '%Pass%' OR DeveloperName like '%Solutions%' 
                        OR DeveloperName like '%OFS_Enquiries%' OR DeveloperName like '%Student_Rec_Enquiries_Post_Application%'
                        OR Developername  = 'MGE_Admissions')]){
            mapQueueIdByName.put(grp.DeveloperName, grp.Id);
        }
        return mapQueueIdByName;
    }


    /*******************************************************************************************************
    * @description Returns records from custom metadata - Case_Category_Skill_Mapping__mdt
    * @return Map<String, String> mapTopicToCaseCategory
    */
    public static Map<String, String> getCaseCategoryTopicMapping(){
        Map<String, String> mapSkillDevToTopic = new Map<String, String>();

        for(Case_Category_Skill_Mapping__mdt ccs: [SELECT Skill_Developer_Name__c, Topic__c FROM Case_Category_Skill_Mapping__mdt]){
            if(ccs.Skill_Developer_Name__c != null){
                mapSkillDevToTopic.put(ccs.Topic__c, ccs.Skill_Developer_Name__c);
            }
        }
        return mapSkillDevToTopic;
    }

    /*******************************************************************************************************
    * @description Returns records from custom metadata - Case_Category_Skill_Mapping__mdt
    * @return Map<String, String> mapTopicToCaseCategory
    */
    public static Map<String, String> getTopicCaseCategoryMapping(){
        Map<String, String> mapTopicToCaseCategory = new Map<String, String>();

        for(Case_Category_Skill_Mapping__mdt ccs: [SELECT Topic__c, Case_Category_Level_1__c FROM Case_Category_Skill_Mapping__mdt]){
            if(ccs.Topic__c != null){
                mapTopicToCaseCategory.put( String.valueOf(ccs.Topic__c).toLowerCase(),ccs.Case_Category_Level_1__c);
            }
        }
        return mapTopicToCaseCategory;
    }

    /*******************************************************************************************************
    * @description returns Map of ChatTranscript by ChatKeys
    * @param Set<Id> setWorkItemIds - Live Chat Transcript
    * @return Map<String, LiveChatTranscript> mapChatTranscriptsByChatKey - Map of ChatTranscript by ChatKeys
    */
    public static Map<String, LiveChatTranscript> getChatTranscriptsByChatKey(Set<Id> setWorkItemIds){
        Map<String, LiveChatTranscript> mapChatTranscriptsByChatKey = new Map<String, LiveChatTranscript>();

        for(LiveChatTranscript lct : [SELECT Id, ChatKey FROM LiveChatTranscript WHERE Id IN: setWorkItemIds]){
            if(lct.ChatKey!= null){
                mapChatTranscriptsByChatKey.put(lct.ChatKey, lct);
            }
        }
        return mapChatTranscriptsByChatKey;
    }

    /*******************************************************************************************************
    * @description Returns Map of Case Category Mapping Topic by LiveChatTranscript Ids
    * @param Set<Id> setWorkItemIds - set of LiveChatTranscript Id
    * @return Map<Id, String> mapChatLogDetailTopicByChatLogId - Map of Case by LiveChatTranscript Ids
    */
    public static Map<Id,String> getChatLogDetailTopic(Set<Id> setWorkItemIds){
        Map<String, LiveChatTranscript> mapChatTranscriptsByChatKey = new Map<String, LiveChatTranscript>();
        Map<String, Chat_365_Log__c> mapChatLogsByChatKey = new Map<String, Chat_365_Log__c>();
        Map<Id, String> mapChatLogDetailTopicByChatLogId = new Map<Id, String>();
        Set<Id> setChatLogIds = new Set<Id>();

        mapChatTranscriptsByChatKey = getChatTranscriptsByChatKey(setWorkItemIds);
        if(!mapChatTranscriptsByChatKey.isEmpty()) mapChatLogsByChatKey = retrieveMapChatLogsByChatKeys(mapChatTranscriptsByChatKey.keySet());
        if(!mapChatLogsByChatKey.isEmpty()){
            for(Chat_365_Log__c chatLog : mapChatLogsByChatKey.values()){
                setChatLogIds.add(chatLog.Id);
            }
            mapChatLogDetailTopicByChatLogId = retrieveMapChatLogDetailTopicByChatLogId(setChatLogIds);
            for(String strChatKey : mapChatTranscriptsByChatKey.keySet()){
                if(mapChatLogsByChatKey.containsKey(strChatkey)){
                    Id chatLogId = mapChatLogsByChatKey.get(strChatKey).Id;
                    mapChatLogDetailTopicByChatLogId.put(mapChatTranscriptsByChatKey.get(strChatKey).Id,mapChatLogDetailTopicByChatLogId.get(chatLogId));
                }
            }
        }
        return mapChatLogDetailTopicByChatLogId;
    }

    /*******************************************************************************************************
    * @description Routes Chat Request driven by Skills - mapped to case Category level 1
    * @param setWorkItemIds - set of LiveChatTranscript ids
    * @param newChatRequests - bulkified list Pending Service Routing records (Chat request)
    * @revision 07/09/2020 - APRivera - Removed the auto-routing to General Skill if no skilled agent available
    */
    public static void routeChatUsingSkills(Set<Id> setWorkItemIds, List<PendingServiceRouting> newChatRequests){
        Map<Id,String> mapChatLogDetailTopicByChatLogId = getChatLogDetailTopic(setWorkItemIds);
        // map of Skills by Name
        Map<String, Id> mapSkillsByDeveloperName = getSkillsByDeveloperName();
        // map of case category level 1 and the skill developer name
        Map<String, String> mapTopicBySkill = getCaseCategoryTopicMapping();
        // map of online agent per skill id
        List<SkillRequirement> listSkillRequirementForInsert = new List<SkillRequirement>();
        List<LiveChatTranscript> listLiveChatTranscriptForUpdate = new List<LiveChatTranscript>();
        Id skillsId;

        // iterate through the pending service items
        for(PendingServiceRouting psr: newChatRequests){
            // a flag to route the live chat to General Skill
            String strTopicType = '';
            // if the live chat has a corresponding case created
            if(mapChatLogDetailTopicByChatLogId.containsKey(psr.WorkItemId)){
                // related topic
                strTopicType = mapChatLogDetailTopicByChatLogId.get(psr.WorkItemId);

                // identify the skill required where the live chat should be routed to
                skillsId = getSkillId(mapTopicBySkill, mapSkillsByDeveloperName, strTopicType);
                //if(skillsId != '' || skillsId != null){
                listSkillRequirementForInsert.add(new SkillRequirement(SkillId = skillsId, RelatedRecordId = psr.Id));

                // update the Live Chat Transcript Skill Type (displayed in the omni channel panel)
                Map<Id, Skill> mapSkillsByIds  = getSkillsByIds();
                String skillType = mapSkillsByIds.containsKey(skillsId) ?  getSkillsByIds().get(skillsId).MasterLabel : null;
                listLiveChatTranscriptForUpdate.add(new LiveChatTranscript(Id = psr.WorkItemId, SkillId = skillsId, Skill_Type__c = skillType));
            }
        }

        try{
            if(!listLiveChatTranscriptForUpdate.isEmpty()){
                List<Database.SaveResult> updResult = database.update (listLiveChatTranscriptForUpdate,false);
                for (Database.SaveResult aResult : updResult) {
                    // If there are any errors log all of the results 
                    if (!aResult.isSuccess()) {
                        nebula.logger.warn('Error updating chat transcripts', listLiveChatTranscriptForUpdate);
                        break;
                    }
                }
            }

            if(!listSkillRequirementForInsert.isEmpty()){
                List<Database.SaveResult> insResult = database.insert (listSkillRequirementForInsert, false);
                for (Database.SaveResult aResult : insResult) {
                    // If there are any errors log all of the results 
                    if (!aResult.isSuccess()) {
                        nebula.logger.warn('Error inserting skills', listSkillRequirementForInsert);
                        break;
                    }
                }
            }
            
        } catch(Exception e){
            ExLog.add('MonashChat365 - routeChatUsingSkills','Case','routeChatUsingSkills', e.getMessage());
            nebula.logger.exception(e.getMessage(),e);
        } finally {
            nebula.logger.saveLog();
        }
    }

    /*******************************************************************************************************
    * @description Populates mapSkillsByDeveloperName
    * @param Map<String, String> mapCaseCategoryBySkill - Map of case by category Skill referenced from Case_Category_Skill_Mapping__mdt
    * @param Map<String, Id> mapSkillsByDeveloperName - Map of Skills by developer Name
    * @param String caseCategory - Case's Category Level 1
    * @return void
    */
    public static Id getSkillId(Map<String, String> mapTopicBySkill, Map<String, Id> mapSkillsByDeveloperName, String strTopicType){
        // if the case to skill mapping contains the case category
        if(mapTopicBySkill.containsKey(strTopicType)){
            // get the skill developer name
            String strSkillDevName = mapTopicBySkill.get(strTopicType);

            // if there is an existing skill with that developer name
            if(mapSkillsByDeveloperName.containsKey(strSkillDevName)){
                // return the skill id
                return mapSkillsByDeveloperName.get(strSkillDevName);
            }
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Returns Skills by developer name
    * @return the describe field result for the given field
    */
    public static Map<String, Id> getSkillsByDeveloperName(){
        // a map of Skill with Developername as identifier
        Map<String, Id> mapSkillsByDeveloperName = new Map<String, Id>();
        // get all the skills from the system and put it in the map
        for(Skill s: [SELECT Id, DeveloperName FROM Skill ]){
            mapSkillsByDeveloperName.put(s.DeveloperName, s.Id);
        }

        return mapSkillsByDeveloperName;
    }

    /*******************************************************************************************************
    * @description Returns Map of Skills by Id
    * @return the describe field result for the given field
    */
    public static Map<Id, Skill> getSkillsByIds(){
        Map<Id, Skill> mapSkillsByIds = new Map<Id, Skill>();
        // get all the skills from the system and put it in the map
        for(Skill s: [SELECT Id, DeveloperName, MasterLabel FROM Skill ]){
            mapSkillsByIds.put(s.Id, s);
        }
        return mapSkillsByIds;
    }

    /**

    Retrieves messages matching the given set of emails.
    @param emails The set of emails to match against.
    @return A map of email to corresponding message.

    MJC
    Old logging remains until I understand what & when this is doing it's thing
    */
    private Static Map<String,String> retrieveMessageMatchingEmails(Set<String> emails)
    {
        Map<String,String> logs = new  Map<String,String>();
        For (Exception_log__C currentLog : [select id, CurrentUser__r.email, Message__c 
             from Exception_log__C where Function_name__C='ExperienceMFAServices' 
             and CurrentUser__r.email in :emails 
             order by CurrentUser__r.email asc,  Createddate desc]) {
       		
            If (!logs.containsKey(currentLog.CurrentUser__r.email)) {
     			logs.put(currentLog.CurrentUser__r.email,currentLog.Message__c);
            }                                        
       	}
        return logs;
    }
}