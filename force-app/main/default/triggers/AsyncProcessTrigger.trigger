/**
 * @File Name          : AsyncProcessTrigger.trigger
 * @Description        : Trigger for Async_Process__e Platform Event
 * @Author             : Nick Guia
 * @Group              : Commons
 * @Revision
 *  FEB.13.2020     Nick Guia   - Moved to PlatformEventTrigger pattern
**/
trigger AsyncProcessTrigger on Async_Process__e (after insert) {

    PlatformEventTrigger trig = new PlatformEventTrigger();

    trig.registerHandler(AsyncProcessTriggerHandler.class.getName())
    .run();
}