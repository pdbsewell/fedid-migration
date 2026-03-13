/**
* @description Queueable class to update ACP from'Contact Document : AI : Release ACP On Hold' Flow
* @author      Sravani Naramsetti
* @date        08/07/2025
* @group       Admissions
*/
public class UpdateACPFromFlowQueueable implements Queueable{
    List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
    public UpdateACPFromFlowQueueable(List<Application_Course_Preference__c> acpList){
        this.acpList.addAll(acpList);
    }
    public void execute(QueueableContext qc){
        try{
            update acpList;
        }catch(Exception ex){
            Nebula.Logger.error('UpdateACPFromFlowQueueable.execute', ex);
            Nebula.Logger.saveLog();
        }
    }
}