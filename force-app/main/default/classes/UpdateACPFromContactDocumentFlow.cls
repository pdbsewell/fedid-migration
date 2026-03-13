/**
* @description Controller class to update ACP from'Contact Document : AI : Release ACP On Hold' Flow
* @author      Sravani Naramsetti
* @date        08/07/2025
* @group       Admissions
*/
global class UpdateACPFromContactDocumentFlow {
    /**
     * @description Method to update ACP and call queueable class
     * @param  List<List<Application_Course_Preference__c>> acpList
     */
    @InvocableMethod
    global static void processRecords(List<List<Application_Course_Preference__c>> acpList) {
        if(acpList!=null && !acpList.isEmpty()){
            System.enqueueJob(new UpdateACPFromFlowQueueable(acpList[0]));
        }
    }
}