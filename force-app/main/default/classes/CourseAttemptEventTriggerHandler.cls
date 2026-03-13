/**
 * @description       : Trigger handler class for Course_Attempt_Event__e platform events.
 * @author            : Martin Cadman
 * @group             : Trigger Handler
 * @last modified on  : 2020-10-15
 * @last modified by  : Martin Cadman
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-10-15   Martin Cadman   Initial Version, copied from ContactPointEventTriggerHandler
**/
public class CourseAttemptEventTriggerHandler implements PlatformEventTrigger.HandlerExtended {

	@TestVisible
	private Map<String, List<AsyncProcessPayload> > processMap;

    public CourseAttemptEventTriggerHandler() {
        this.processMap = new Map<String, List<AsyncProcessPayload>>();
    }

    public void process(SObject rec) {
        Course_Attempt_Event__e ap = (Course_Attempt_Event__e) rec;
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