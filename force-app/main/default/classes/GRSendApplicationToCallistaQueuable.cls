/*******************************************************************************
    * @author       Vishal Gupta
    * @date         14/10/2024
    * @description  Queuable to submit application to Callista
    * @revision     14/10/2024 - Initial Version
*******************************************************************************/
public class GRSendApplicationToCallistaQueuable implements Queueable, Database.AllowsCallouts
{
    private Id applicationId;
    private Id contactId;

    /*******************************************************************************
    * @author       Vishal Gupta
    * @date         14/10/2024
    * @description  constructor for the class
    * @param        applicationId
    * @param        contactId
    * @revision     14/10/2024 - Initial Version
    *******************************************************************************/
    public GRSendApplicationToCallistaQueuable(
        Id applicationId,
        Id contactId
    )
    {
        this.applicationId = applicationId;
        this.contactId = contactId;
    }
    /*******************************************************************************
    * @author       Vishal Gupta
    * @date         14/10/2024
    * @description  execute methiod to invoke callout
    * @param        context of the executable
    * @revision     14/10/2024 - Initial Version
    *******************************************************************************/
    public void execute(QueueableContext context) {
        try{
            GRSendApplicationToCallistaService applicationSendService = new GRSendApplicationToCallistaService(
                applicationId,
                contactId
            );
            applicationSendService.createRequestBody();
            applicationSendService.sendMessage();
            applicationSendService.handleResponse();
        }
        catch(Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
    }
}