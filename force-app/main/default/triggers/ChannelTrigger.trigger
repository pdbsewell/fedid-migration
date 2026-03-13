/**
 * @description       : Channel trigger
 * @author            : Paul Victoriano
 * @group             : Trigger
 * @last modified on  : 2020-10-15
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-10-14   Paul Victoriano Initial Version
 * 1.1   2020-04-20   Martin Cadman   Removed logic for evaluating "last modified date" vs. "last modified date by api"
 * 1.1   2020-10-14   Stefan Scheit   Added 'do not trigger' switch (as per all other triggers)
**/
trigger ChannelTrigger on Channel__c (after insert, after update) {

    if (TriggerCommon.doNotRunTrigger('Channel__c')) {
        return;
    }

    if (Trigger.isAfter) {
        if (Person360Muting__c.getInstance().EnableChannelBreakUp__c) {
            new Triggers()
            .bindExtended(Triggers.Evnt.afterinsert, new ChannelTriggerHandler.DispatchChannelEvent())
            .bindExtended(Triggers.Evnt.afterupdate, new ChannelTriggerHandler.DispatchChannelEvent())
            .execute();
        }
    }
}