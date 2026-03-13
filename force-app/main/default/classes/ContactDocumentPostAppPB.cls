/*******************************************************************************
    * @author       Shalini Mendu
    * @date         31.Jul.2019
    * @description  This is invoked from a Process builder on Contact document object post application
    * submission
    * @revision
*******************************************************************************/
public class ContactDocumentPostAppPB {
   /*******************************************************************************
   * @author       Shalini Mendu
   * @date         10.Jul.2019
   * @description  Invocable method from Contact Document Post Application Submission
   * to fire an Apex scheduler to submit documents post application submission
   * @revision
   *******************************************************************************/
    @InvocableMethod
    public static void QueueFileToSend(List<Id> contactDocIds)
    {
        SendContentDocQueuable sdq = new SendContentDocQueuable(contactDocIds);
        Id jobId = System.enqueueJob(sdq);
    }
}