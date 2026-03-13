/**
* @author Angelo Rivera
* @date 05.09.19
* @group TriggerHandlers
* @description Chat365LogDetailTrigger Handler
* @revision 05.09.19 - Initial Create <br/>
*           24.10.23 - Added new Logic for Live Person (MCT-278). <br/>
*/

public class Chat365LogDetailTriggerHandler {

    /**
    * @author Angelo Rivera
    * @date 05.09.19
    * @description Inner Class - inserts enquiry
    * @revision 05.09.19 - Initial Create <br/>
    */
    public class InsertEnquiry extends TriggerAbstract {
        private Set<Id> setChatLogIds = new Set<Id>();
        public override void process(SObject record) {
            Chat_365_Log_Detail__c logDetail = (Chat_365_Log_Detail__c)record;
            if(logDetail.Intent__c == 1 || logDetail.Intent__c == 4 || logDetail.Intent__c == 5 ){ // inserts enquiry if intent are (1) Submit Enquiry / (4) Chat Request - Agent is Online // (5) LivePerson Integration
                setChatLogIds.add(logDetail.Chat_365_Log__c);
                records.add(record);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                MonashChat365Services.insertEnquiry(setChatLogIds, records);
            }
            LogUtilityException.getLimits();
        }
    }
}