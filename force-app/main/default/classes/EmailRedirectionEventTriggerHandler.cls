/**
 * @description       : Email Redirection Event Trigger Handler.
 * @author            : Matthew Maramot
 * @group             : Trigger Handler
**/
public with sharing class EmailRedirectionEventTriggerHandler implements PlatformEventTrigger.HandlerExtended {
    @TestVisible
	private List<Email_Redirection_Event__e> EmailRedirectionEvents = new List<Email_Redirection_Event__e>();

    public EmailRedirectionEventTriggerHandler() {
        EmailRedirectionEvents = new List<Email_Redirection_Event__e>();
    }

    /**
     * @param  record Email_Redirection_Event__e record
     */
    public void process(SObject record) {
        EmailRedirectionEvents.add((Email_Redirection_Event__e)record);
    }

    /**
     * Process Email Redirection Event Records
     */
    public void execute() {
        //Start Processing
        try {
            if(EmailRedirectionEvents.size() > 0){
                EmailRedirectionEventUtility.processEmailRedirectionEvent(EmailRedirectionEvents);
            }
        } catch (Exception error) {
            Nebula.Logger.error(error.getMessage(), error);
        }
        Nebula.Logger.saveLog();
    }
}