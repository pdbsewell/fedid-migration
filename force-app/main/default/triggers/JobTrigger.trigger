/*******************************************************************************
* @author       Nitin Khandelwal
* @date         9.April.2018        
* @description  Trigger framework for job control object
* @revision     
*******************************************************************************/

trigger JobTrigger on Job_Control__c (after Update) {
    if (TriggerCommon.doNotRunTrigger('Job_Control__c')) { return; }
    JobTriggerHandler objHandler = new JobTriggerHandler();
    if(Trigger.isUpdate && Trigger.isAfter)
    {
        objHandler.onAfterUpdate(Trigger.New);
    }
}