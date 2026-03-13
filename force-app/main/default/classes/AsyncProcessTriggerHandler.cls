/**
 * @File Name          : AsyncProcessTriggerHandler.cls
 * @Description        : Trigger handler for AsyncProcessTrigger
 * @Author             : Nick Guia
 * @Group              : Commons
 * @Revision
 *  FEB.13.2020     Nick Guia   - Moved to PlatformEventTrigger pattern
 **/
public class AsyncProcessTriggerHandler implements PlatformEventTrigger.HandlerExtended {

	@TestVisible
	private Map<String, List<AsyncProcessPayload> > processMap;

    public AsyncProcessTriggerHandler() {
        this.processMap = new Map<String, List<AsyncProcessPayload>>();
    }

    public void process(SObject rec) {
        Async_Process__e ap = (Async_Process__e) rec;
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
            } catch(Exception ex) {
                LogUtilityException.logException(ex, JSON.serializePretty(rec));
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
        } catch(Exception ex) {
            LogUtilityException.logException(ex, JSON.serializePretty(payloads));
        }
    }
}