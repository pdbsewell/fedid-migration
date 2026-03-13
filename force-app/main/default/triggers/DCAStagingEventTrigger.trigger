/**
 * @description       : DCAStaging (Platform) Event trigger
 * @author            : Sheeba
 * @group             : Trigger
 * @last modified on  : 2022-05-26
 * @last modified by  : Sachin Shetty
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.1   2022-05-26   Sachin Shetty   Refactored to use the right framework
**/
trigger DCAStagingEventTrigger on DCAStagingEvent__e (after insert) {

    // register trigger handler
    PlatformEventTrigger triggerHandler = new PlatformEventTrigger();
    triggerHandler.registerHandler(DCAStagingEventTriggerHandler.class).run();
}