/**
* @author Angelo Rivera
* @date 05.09.19
* @group Monash Connect
* @description Trigger for PendingServiceRouting
* @revision 05.09.19 - Initial Create <br/>
*/
trigger PendingServiceRoutingTrigger on PendingServiceRouting (after insert) {

	if (TriggerCommon.doNotRunTrigger('PendingServiceRouting')) { return; }
    
    new Triggers()
        //After Insert Events
        .bindExtended(Triggers.Evnt.afterinsert, new PendingServiceRoutingTriggerHandler.LiveChatRoutingEngine())
        .execute();
}