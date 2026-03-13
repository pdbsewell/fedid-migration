/**
 * @description       : Email Redirection (Platform) Event trigger
 * @author            : Matthew Maramot
 * @group             : Trigger
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2024-03-22   Matthew Maramot Creation of trigger
**/
trigger EmailRedirectionEventTrigger on Email_Redirection_Event__e (after insert) {

    // register trigger handler
    PlatformEventTrigger triggerHandler = new PlatformEventTrigger();
    triggerHandler.registerHandler(EmailRedirectionEventTriggerHandler.class).run();
}