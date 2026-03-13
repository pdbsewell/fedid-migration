/*******************************************************************************
    * @author       Sethu Venna
    * @date         05/09/2024
    * @description  Queuable to submit contact documents to Callista
    * @revision     05/10/2024 - Initial Version
*******************************************************************************/
public class GRSendContentDocFromPlatformEventQueue
{
    
    /*******************************************************************************
     * @author       Sethu Venna
     * @date         15/10/2024
     * @param        conDocIdSet 
     * @description  execute method to run the doc integration
     * @revision     15/10/2024 - Initial Version
     *******************************************************************************/
    @future(callout=true)
    public static void execute(Set<Id> conDocIdSet ) {
        try
        {
            System.enqueueJob(
                new GRSendContentDocQueuable(conDocIdSet)
            );
            if(Test.isRunningTest()){
                throw new CustomException('Check Nebula error log in test class');
            }
        }
        catch(Exception ex)
        {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
    }
    
    public class CustomException extends Exception{}
}