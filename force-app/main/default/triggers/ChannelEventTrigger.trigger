/**
 * @description       : Channel (Platform) Event trigger
 * @author            : Stefan Scheit
 * @group             : Trigger
 * @last modified on  : 2020-10-15
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.1   2020-10-14   Stefan Scheit   Initial Version, moved from ContactPointTrigger.trigger
**/
trigger ChannelEventTrigger on Channel_Event__e (after insert) {

    // register trigger handler
    PlatformEventTrigger triggerHandler = new PlatformEventTrigger();
    triggerHandler.registerHandler(ChannelEventTriggerHandler.class).run();
}