/**
* @author Angelo Rivera
* @date 17.06.2020
* @group Trggers
* @description Trigger for Event
* @revision 17.06.2020 - Initial Create
*/

trigger EventTrigger on Event (before insert, after insert, after update ) {

    if (TriggerCommon.doNotRunTrigger('Event')) { return; }

    new Triggers()
            // Before Insert events
            .bindExtended(Triggers.Evnt.beforeinsert, new EventTriggerHandler.LinkEventToOutboundCall())

            // After Insert events
            .bindExtended(Triggers.Evnt.afterinsert, new EventTriggerHandler.UpdateOutboundCallOnEventInsert())

            // After update events
            .bindExtended(Triggers.Evnt.afterupdate, new EventTriggerHandler.UpdateOutboundCallOnEventUpdate())

            .execute();

    LogUtilityException.getLimits();
}