/*******************************************************************************
    * @author       Sethu Venna
    * @date         05/10/2024
    * @description  This is invoked from a Process builder on Contact document object post application
    * submission
    * @revision     05/10/2024 - Initial Version
    *               7/11/2024  - Updated the feature switch for Grad Research Integration
*******************************************************************************/
public class GRInvocablePostDocumentService {
    /*******************************************************************************
    * @author       Sethu Venna
    * @date         05/10/2024
    * @param        contactDocIdList
    * @description  Invocable method from Contact Document Post Application Submission
    * to fire an Apex scheduler to submit documents post application submission
    * @revision     05/10/2024 - Initial Version
    *               7/11/2024  - Updated the feature switch for Grad Research Integration
    *******************************************************************************/
     @InvocableMethod
     public static void queueFileToSend(List<Id> contactDocIdList)
     {
         try
         {
             Feature_Switch__c fs = Feature_Switch__c.getInstance();
             if(!fs.Graduate_Research_Integration__c) {
                 return;//execute the integration only if the feature switch is turned on
             }
             for(Id conDocId : contactDocIdList)
             {
                 AsyncProcessPayload payload = new AsyncProcessPayload();
                 payload.put ('conDocId', conDocId);
                 Async_Process__e evt = new Async_Process__e (
                     Process_Name__c = 'ApplicationService.GRSendDocToCallistaPlatformEventService',
                     Parameter__c = payload.serialize()
                 );
                 EventBus.publish(evt);
             }
         }
         catch(Exception ex)
         {
             Nebula.Logger.error(ex.getMessage(), ex);
         }
         Nebula.Logger.saveLog();
     }
 }