/**
 * @File Name          : BatchApexErrorHandler.cls
 * @Description        : Trigger handler for BatchApexErrorTrigger
 * @Author             : PVictoriano
 * @Group              : Commons
 **/
public without sharing class BatchApexErrorHandler implements PlatformEventTrigger.HandlerExtended {
    @TestVisible
    List<BatchApexErrorEvent> events;
    @TestVisible
    Set<Id> asyncApexJobIds;
    public BatchApexErrorHandler() {
        events = new List<BatchApexErrorEvent>();
        asyncApexJobIds = new Set<Id>();
    }

    /**
     * @description process records
     */
    public void process(SObject rec) {
        BatchApexErrorEvent evt = (BatchApexErrorEvent)rec;
        events.add(evt);
        asyncApexJobIds.add(evt.AsyncApexJobId);
    }

    /**
     * @description execute processing for LogEvents
     */
    public void execute() {
        if (asyncApexJobIds.isEmpty() == false) {
            //Retrieve Batch Class Names
            Map<Id,AsyncApexJob> jobs = new Map<Id,AsyncApexJob>(
                (List<AsyncApexJob>)DBManager.getInstance().
                soqlQuery([SELECT Id, ApexClass.Name FROM AsyncApexJob WHERE Id IN: asyncApexJobIds])
            );
            //
            for (BatchApexErrorEvent evt:events) {
                //For BatchJobs
                if (jobs.containsKey(evt.AsyncApexJobId)) {
                    AsyncApexJob ajob = jobs.get(evt.AsyncApexJobId);
                    String jobname = ajob?.ApexClass?.Name;
                    if (String.isNotBlank(evt.JobScope)) {
                        for (String item : evt.JobScope.split(',')) {
                            //Create LogEvent
                            LogUtilityException.addLogEvent(
                                createBatchLogs(evt, item, jobname)
                                );
                        }
                    }
                }
            }
            LogUtilityException.publishAll();
        }
    }

    /**
     * @description createBatchLogs Creates custom logs for BatchApexErrorEvents
     */
    @TestVisible
    private LogEvent__e createBatchLogs(BatchApexErrorEvent evt, String ajob, String item) {
        LogEvent__e nLog = new LogEvent__e();
        nLog.CurrentUser__c = evt.AsyncApexJobId;
        nLog.Stack__c = evt.StackTrace;
        nLog.Message__c = evt.Message;
        nLog.Type__c = evt.ExceptionType;
        nLog.Priority__c = 'ERROR';
        nLog.Input__c = String.format('Phase:{0}\n Job:{1}\n RequestId:{2}\n Record Id:{3}', new List<String> {evt.Phase, ajob, evt.RequestId, item});
        return nLog;
    }
}