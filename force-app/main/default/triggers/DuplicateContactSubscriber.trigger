trigger DuplicateContactSubscriber on Duplicate_Contact_Event__e (after insert) {
    // register trigger handler
    PlatformEventTrigger triggerHandler = new PlatformEventTrigger();
    triggerHandler.registerHandler(DuplicateContactEventTriggerHandler.class).run();
}