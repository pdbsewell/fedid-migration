/**
 * @description       : Trigger handler class for Duplicate_Contact_Event__e platform events.
 * @author            : Sheeba T
 * @group             : Trigger Handler
 * @last modified on  : 2022-02-05
 * @last modified by  : Sheeba T
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   2022-02-05   Sheeba        Initial Version 
**/
public class DuplicateContactEventTriggerHandler implements PlatformEventTrigger.HandlerExtended {

	@TestVisible
	private Map<String, List<AsyncProcessPayload> > processMap;

    public DuplicateContactEventTriggerHandler() {
        this.processMap = new Map<String, List<AsyncProcessPayload>>();
    }

    public void process(SObject rec) {
        Duplicate_Contact_Event__e dc = (Duplicate_Contact_Event__e) rec;
        List<AsyncProcessPayload> payloads = this.processMap.get(dc.Process_Name__c);

        //instantiate a new payload for this process if it doesn't exist yet 
        if(payloads == null) {
            payloads = new List<AsyncProcessPayload>();
        }

        //if a parameter is provided, consolidate the payload for all similar processes
        if(String.isNotBlank(dc.Parameter__c)) {
            try {
                //get current record's payload and add it to the payload of the mapped process
                AsyncProcessPayload newPayload = AsyncProcessPayload.deserialize(dc.Parameter__c);
                payloads.add(newPayload);
            } catch(Exception e) {
                LogUtilityException.logException(e, JSON.serializePretty(rec));
            }
        }

        //map updated process and payload
        this.processMap.put(dc.Process_Name__c, payloads);
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