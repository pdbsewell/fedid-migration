/*******************************************************************************
* @author       Russell Cadapan
* @date         29/05/2019
* @group        TriggerHandlers
* @description  Trigger Handler for Pending Service Routing Object
* @revision     1.0
*               2.0 - APRivera - Change framework and object references
*               14/12/24 - Moved to nebular logging
*******************************************************************************/
public class PendingServiceRoutingTriggerHandler {

    /**
    * @author Angelo Rivera
    * @date 05.09.19
    * @description Inner Class - inserts enquiry
    * @revision 05.09.19 - Initial Create <br/>
    */
    public class LiveChatRoutingEngine extends TriggerAbstract {
        private Set<Id> setWorkItemIds = new Set<Id>();
        public override void process(SObject record) {
            PendingServiceRouting psr = (PendingServiceRouting)record;
            if(psr.WorkItemId.getSobjectType().getDescribe().getName() == 'LiveChatTranscript' && !psr.IsTransfer){
                records.add(psr);
                setWorkItemIds.add(psr.WorkItemId);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
			try {
                if(!records.isEmpty()){
                    MonashChat365Services.routeChatUsingSkills(setWorkItemIds, records);
                }
            } catch (Exception ex) {
                nebula.Logger.exception(ex.getMessage(),ex);
            } finally {
                nebula.Logger.saveLog();
            }
        }
    }

}