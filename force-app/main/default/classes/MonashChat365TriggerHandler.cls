/**
* @author Angelo Rivera
* @date 05.09.19
* @group TriggerHandlers
* @description Trigger handler for MonashChat365Trigger - Monash Chat 365 functionality
* @revision 05.09.19 - Initial Create <br/>
*           19.08.20 - Additional logic on transcript update event <br/>
*/

public without sharing class MonashChat365TriggerHandler {

    /**
    * @author Angelo Rivera
    * @date 05.09.19
    * @description Inner Class - Updates LiveChatTranscript values when status changes to In Progress
    * @revision 05.09.19 - Initial Create <br/>
    */
    public class CheckStatusUpdatesOnLiveChatTranscript extends TriggerAbstract {
        public Set<String> setChatKeys = new Set<String>();
        public override void process(SObject record, SObject oldRec){
            LiveChatTranscript newChatTranscript = (LiveChatTranscript)record;
            LiveChatTranscript oldChatTranscript = (LiveChatTranscript)oldRec;
            if((oldChatTranscript.Status != newChatTranscript.Status) && newChatTranscript.Status == 'InProgress'){
                records.add(newChatTranscript);
                setChatKeys.add(newChatTranscript.ChatKey);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            try {
                if(!records.isEmpty()) {
                    MonashChat365Services.checkStatusUpdatesOnLiveChatTranscript(records,setChatKeys,true);
                }
            } catch (Exception ex) {
                    nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }

    /**
    * @author Angelo Rivera
    * @date 18.08.20
    * @description Inner Class - Updates Chat 365 Log object when Chat Transcript is updated
    * @revision 18.08.20 - Initial Create <br/>
    */
    public class UpdateChat365Log extends TriggerAbstract{
        public override void process(SObject record, SObject oldRec){
            LiveChatTranscript newChatTranscript = (LiveChatTranscript)record;
            LiveChatTranscript oldChatTranscript = (LiveChatTranscript)oldRec;
            if((oldChatTranscript.VTAC_Number__c != newChatTranscript.VTAC_Number__c) && newChatTranscript.Chat_365_Log__c != null){
                records.add(newChatTranscript);
            }
        }
        public override void execute() {
            //Checks if there are records to be processed
            try {
                if(!records.isEmpty()){
                    MonashChat365Services.updateChat365LogOnChatTranscriptUpdate(records);
                }
            } catch (Exception ex) {
                    nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }

        }
    }
}