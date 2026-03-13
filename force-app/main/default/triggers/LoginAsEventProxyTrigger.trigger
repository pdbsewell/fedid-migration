/**
* @author Peter Sewell
* @date   16.01.2022
* @description Subscribed trigger to the LoginAsProxyEvent platform event
*
* @revision
* 16.01.2022 Peter Sewell - Initial version<br/>
*
**/
trigger LoginAsEventProxyTrigger on LoginAsEventProxy__e (after insert) {

    // register trigger handler
    PlatformEventTrigger triggerHandler = new PlatformEventTrigger();
    triggerHandler.registerHandler(LoginAsEventProxyTriggerHandler.class).run();
}