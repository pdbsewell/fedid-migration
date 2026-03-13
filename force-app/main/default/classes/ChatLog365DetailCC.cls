/**
* @author Angelo Rivera
* @date 05.09.19
* @group TriggerHandlers
* @description Controller Class of ChatBotTranscriptComponent
* @revision 05.09.19 - APRivera - Initial Create <br/>
*           20.12.19 - APRivera - Renamed Class <br/>
*/
public class ChatLog365DetailCC {
    
    @AuraEnabled
    public static List<wrapChatLogs> getChatbotTranscript(String recordId) {
        List<wrapChatLogs> wrapList = new List<wrapChatLogs>();
        List<Chat_365_Log__c> chatLog = new List<Chat_365_Log__c>();
        Id idRecord = (Id)recordId;
        try{
            string caseid ;
            if(String.valueOf(idRecord.getSobjectType()) == 'LiveChatTranscript'){ // LiveChatTranscript record page
                List<LiveChatTranscript> chatTranscript = [SELECT Id, ChatKey, CaseId FROM LiveChatTranscript WHERE Id =: recordId LIMIT 1];
                caseid = chatTranscript[0].CaseId;
                chatLog = [SELECT Id, Chat_Key__c, (SELECT Id, CreatedDate, CaseNumber FROM Enquiries__r ORDER BY CreatedDate DESC)
                FROM Chat_365_Log__c WHERE Chat_Key__c=: chatTranscript[0].ChatKey LIMIT 1];
                if(!chatLog.isEmpty()){
                    wrapList = getAllChatLogDetails(chatLog[0], chatTranscript[0]);
				}
                for(wrapChatLogs wrapObj : wrapList) {
					wrapObj.caseID =caseid;
        		}
            }else if(String.valueOf(idRecord.getSobjectType()) == 'Case'){ // Case record page
                Case cse = [SELECT Id, CreatedDate, CaseNumber, Chat_365_Log__c FROM Case WHERE Id =: recordId];
                if(cse.Chat_365_Log__c != null){
                    chatLog = [SELECT Id, Chat_Key__c, (SELECT Id, CreatedDate, CaseNumber FROM Enquiries__r ORDER BY CreatedDate DESC)
                    FROM Chat_365_Log__c WHERE Id =: cse.Chat_365_Log__c LIMIT 1];
                    wrapList = getAllChatLogDetails(chatLog[0], cse);
                }
            }else{ // Chat 365 Log record page
                chatLog = [SELECT Id, Chat_Key__c, (SELECT Id, CreatedDate, CaseNumber FROM Enquiries__r ORDER BY CreatedDate DESC)
                FROM Chat_365_Log__c WHERE Id =: recordId LIMIT 1];
                wrapList = getAllChatLogDetails(chatLog[0], chatLog[0]);
            }
        }
        catch(Exception e){
            return null;
        }
        return wrapList;
    }
    @AuraEnabled
    public static List<wrapChatLogs> getAllChatLogDetails(Chat_365_Log__c chat365Log, SObject record) {
        Datetime cStartDate;
        Datetime cEndDate;
        Boolean isChatlog = false;
        Boolean hasMultipleEnquiries = false;
        List<wrapChatLogs> chatDetailList = new List<wrapChatLogs>();
        Case cse = new Case();
        Chat_365_Log__c clog = chat365Log;
        Id recordId = clog.Id;

        if(String.valueOf(record.getSObjectType()) == 'Case'){
            cse = (Case)record;
        }else if(String.valueOf(record.getSObjectType()) == 'LiveChatTranscript'){
            LiveChatTranscript lct = (LiveChatTranscript)record;
            if(lct.CaseId != null) cse = [SELECT  Id, CreatedDate, CaseNumber, Chat_365_Log__c FROM Case WHERE Id =: lct.CaseId];
        }else{
            isChatlog = true;
        }
        if(!isChatlog){
            if(clog.Enquiries__r.size() > 1){
                hasMultipleEnquiries=true;
                Integer x=0;
                Integer listIndex;
                for(Case c : clog.Enquiries__r){
                    if(c.Id == cse.Id){
                        cEndDate = c.CreatedDate;
                        listIndex=x;
                        break;
                    }
                    x++;
                }
                if((listIndex+1) == clog.Enquiries__r.size()){ // First Created Case
                    hasMultipleEnquiries = false;
                }else{
                    cStartDate = clog.Enquiries__r.get(listIndex+1).CreatedDate;
                }
            }else{
                cStartDate = clog.Enquiries__r.get(0).CreatedDate;
            }
        }

        String strQuery = 'SELECT Id, Request__c, Response__c,Chat_365_Log__c, CreatedDate, Intent__c, Intent_Name__c, Subject__c, Topic__c, Description__c FROM Chat_365_Log_Detail__c ';
        strQuery += 'WHERE Chat_365_Log__c =: recordId ';
        if(!isChatlog && hasMultipleEnquiries) strQuery += 'AND CreatedDate >: cStartDate AND CreatedDate <=: cEndDate ';
        if(!isChatlog && !hasMultipleEnquiries) strQuery += 'AND CreatedDate <=: cEndDate ';
        strQuery += 'ORDER BY CreatedDate ASC';

        List<Chat_365_Log_Detail__c> chatLogDetailList = Database.query(strQuery);
        if(!chatLogDetailList.isEmpty()){
            for(Chat_365_Log_Detail__c chatDetail : chatLogDetailList) {
                chatDetailList.add(new wrapChatLogs(chatDetail));
            }
            
            return chatDetailList;
        }
        
        return new List<wrapChatLogs>();
    }

    public class wrapChatLogs {
        @AuraEnabled
        public string response { get; set; }
        @AuraEnabled
        public string request { get; set; }
        @AuraEnabled
        public dateTime createdDate { get; set; }
        @AuraEnabled
        public string timeFormated { get; set; }   
        @AuraEnabled
        public string chat365Log { get; set; }
        @AuraEnabled
        public string caseID { get; set; }
        
        public wrapChatLogs(Chat_365_Log_Detail__c chatDetail ) {

            this.response = chatDetail.Response__c;
            this.request = chatDetail.Request__c;
            this.createdDate = chatDetail.createdDate;
            this.chat365Log  = chatDetail.Chat_365_Log__c;
            if (chatDetail.createdDate != null) {
                this.timeFormated = chatDetail.createdDate.format('h:mm a');
            }
        }
    }
}