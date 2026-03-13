/**
 * @description       : Trigger handler class for Contact_Point__e platform events.
 * @author            : Stefan Scheit
 * @group             : Trigger Handler
 * @last modified on  : 2020-10-15
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-10-15   Stefan Scheit   Initial Version, copied from AsyncProcessTriggerHandler 
**/
public class ContactPointEventTriggerHandler implements PlatformEventTrigger.HandlerExtended {

	@TestVisible
	private Map<String, List<AsyncProcessPayload> > processMap;

    public ContactPointEventTriggerHandler() {
        this.processMap = new Map<String, List<AsyncProcessPayload>>();
    }

    public void process(SObject rec) {
        Contact_Point_Event__e ap = (Contact_Point_Event__e) rec;
        List<AsyncProcessPayload> payloads = this.processMap.get(ap.Process_Name__c);

        //instantiate a new payload for this process if it doesn't exist yet
        if(payloads == null) {
            payloads = new List<AsyncProcessPayload>();
        }

        //if a parameter is provided, consolidate the payload for all similar processes
        if(String.isNotBlank(ap.Parameter__c)) {
            try {
                //get current record's payload and add it to the payload of the mapped process
                AsyncProcessPayload newPayload = AsyncProcessPayload.deserialize(ap.Parameter__c);
                payloads.add(newPayload);
            } catch(Exception e) {
                LogUtilityException.logException(e, JSON.serializePretty(rec));
            }
        }

        //map updated process and payload
        this.processMap.put(ap.Process_Name__c, payloads);
    }

    public void execute() {
        if(!this.processMap.isEmpty()) {
            for(String key : processMap.keySet()) {
                //run each process, and provide the payload
                runProcess(key, processMap.get(key));
            }
        }
    }

    private void runProcess(String processName, List<AsyncProcessPayload> payloads) {
        try {
            //instantiate class, then invoke
            IPlatformEventInvocable invoker = (IPlatformEventInvocable) Type.forName(processName).newInstance();
            invoker.execute(payloads);
        } catch(Exception e) {
            LogUtilityException.logException(e, JSON.serializePretty(payloads));
        }
    }
}