/**
 * @description   Channel Event Trigger Handler
 * Modifications Log 
 * Date         Author            Modification
 * 2020-10-14   Stefan Scheit     Moved from ContactPointTriggerHandler
 * 2019-07-04   Paul Victoriano   Initial Version
**/
public class ChannelEventTriggerHandler implements PlatformEventTrigger.HandlerExtended {
    @TestVisible
    private Set<Id> contactIds {get; set;}
    @TestVisible
    private Set<Id> channelIds {get; set;}
    @TestVisible
    private Map<Id,Channel_Event__e> channelEventMap = new Map<Id,Channel_Event__e>();

    //
    public ChannelEventTriggerHandler() {
        channelIds = new Set<Id>();
        contactIds = new Set<Id>();
        channelEventMap = new Map<Id, Channel_Event__e>();
    }

    /**
     * Collects Contact and Channel Record Ids
     * @param  rec Channel_Event__e record
     */
    public void process(SObject rec) {
        Channel_Event__e record = (Channel_Event__e)rec;
        if (String.isNotBlank(record.Contact_Id__c) && String.isNotBlank(record.Channel_Id__c)) {
            contactIds.add(record.Contact_Id__c);
            channelIds.add(record.Channel_Id__c);
            channelEventMap.put(record.Channel_Id__c,record);
        }
    }

    /**
     * Process Contact Point Records
     */
    public void execute() {
        try {
            ChannelEventUtility util = new ChannelEventUtility(contactIds, channelIds);
            util.setContactPoint(channelEventMap);
            util.execute();
        } catch (Exception ex) {
            nebula.logger.error(ex.getMessage(), ex);
        } finally {
            nebula.logger.saveLog();
        }
    }
}