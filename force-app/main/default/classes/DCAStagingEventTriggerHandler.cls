/**
 * @description       : DCAStaging Event Trigger Handler.
 * @author            : Sachin Shetty
 * @group             : Trigger Handler
**/
public with sharing class DCAStagingEventTriggerHandler implements PlatformEventTrigger.HandlerExtended {
    @TestVisible
	private List<DCAStagingEvent__e> DCAStagingEvents = new List<DCAStagingEvent__e>();

    public DCAStagingEventTriggerHandler() {
        DCAStagingEvents = new List<DCAStagingEvent__e>();
    }

    /**
     * @param  record DCAStagingEvent__e record
     */
    public void process(SObject record) {
        DCAStagingEvents.add((DCAStagingEvent__e)record);
    }

    /**
     * Process DCAStaging Event Records
     */
    public void execute() {
        //Start Processing
        try {
            DCAStagingEventUtility.processStagingEvents(DCAStagingEvents);
        } catch (Exception e) {
            LogUtilityException.logException(e, 'DCAStagingEventTriggerHandler');
        }
    }
}