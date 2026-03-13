/*******************************************************************************
    * @author       Sethu Venna
    * @date         18/03/2025
    * @description  Queuable to submit ATAR scores to Callista
    * @revision     18/03/2025 - Initial Version
*******************************************************************************/
public class ATARIntegrationQueuable implements Finalizer, Queueable, Database.AllowsCallouts
{
    public static final String LOG_TAG = 'ATAR Integration';
    
    private Set<Contact_Qualification__c> conQualSet;
    private List<Contact_Qualification__c> conQualToUpdate = new List<Contact_Qualification__c>();

    /*******************************************************************************
    * @author       Sethu Venna
    * @date         05/09/2024
    * @description  constructor for the class
    * @param        conQualSet
    * @revision     05/10/2024 - Initial Version
    *******************************************************************************/
    public ATARIntegrationQueuable(
        Set<Contact_Qualification__c> conQualSet
    )
    {
        this.conQualSet = conQualSet;
    }
    /*******************************************************************************
    * @author       Sethu Venna
    * @date         18/03/2025
    * @description  execute methiod to invoke callout and update doc Id from Callista on Contact document record
    * @param        context of the executable
    * @revision     18/03/2025 - Initial Version
    *******************************************************************************/
    public void execute(QueueableContext context) {
        try {
            for(Contact_Qualification__c conQual : conQualSet) {
                ATARSendScoreToCallistaService atarCalloutService = new ATARSendScoreToCallistaService(
                    conQual
                );
                conQualSet.remove(conQual);
                atarCalloutService.createRequestBody();
                if(atarCalloutService.jsonRequest != null) {
                    atarCalloutService.sendMessage();
                    atarCalloutService.handleResponse();
                    Contact_Qualification__c cq = new Contact_Qualification__c(Id = conQual.Id);
                    cq.API_Request__c = JSON.serialize(atarCalloutService.jsonRequest);
                    cq.API_Response__c = JSON.serialize(atarCalloutService.getResponseBody());
                    cq.API_Callout_Successful__c = (atarCalloutService.httpResponseCode == 200) ? true : false;
                    cq.Retry_API_Callout__c = false;
                    conQualToUpdate.add(cq);
                }
                break;
            }
        }
        catch(Exception ex)
        {
            Nebula.Logger.error(ex.getMessage(), ex).addtag(LOG_TAG);
        }
        finally 
        {
            if(conQualSet.size() > 0) 
            {
                System.enqueueJob(
                    new ATARIntegrationQueuable(conQualSet)
                );
            }
            System.attachFinalizer(this);
            Nebula.Logger.saveLog();
        }
        
    }
    /*******************************************************************************
    * @author       Sethu Venna
    * @date         18/03/2025
    * @description  execute methiod to finalize and log exceptions
    * @param        context of the executable
    * @revision     18/03/2025 - Initial Version
    *******************************************************************************/
    public void execute(FinalizerContext context) {
        if(conQualToUpdate.size() > 0) 
        {
            TriggerCommon.disableTrigger('Contact_Qualification__c');
            update conQualToUpdate;
            TriggerCommon.enableTrigger('Contact_Qualification__c');
            for(Contact_Qualification__c conQual : conQualToUpdate) {
                Nebula.Logger.info('Successfully pushed contact qual to callista: '+conQual.Id).addtag(LOG_TAG);
            }
        }
        Nebula.Logger.saveLog();
    }

}