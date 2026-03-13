/**
 * @description       : Trigger for Contact_Point_Event__e platform event
 * @author            : Stefan Scheit
 * @group             : Trigger
 * @last modified on  : 2020-10-22
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-10-14   Stefan Scheit   Initial Version, copied from AsyncProcessTrigger.trigger
**/
trigger ContactPointEventTrigger on Contact_Point_Event__e (after insert) {

    /* Encapsulated in the PlatformEventTrigger.run() method
    if (TriggerCommon.doNotRunTrigger('Contact_Point_Event__e')) {
        return;
    }
    */

    // register trigger handler
    PlatformEventTrigger triggerHandler = new PlatformEventTrigger();
    triggerHandler.registerHandler(ContactPointEventTriggerHandler.class).run();
}