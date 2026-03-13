/**********************************************************************************************************
* @author       Anterey Custodio
* @date         13.Feb.2017         
* @description  There is a known issue in Salesforce where workflows do not fire on Escalation Rules.
*                   In order to fix this we have to replicate the scheduled apex class 'escalatedCasesScheduler'
*                   in HR Prod which checks for escalated HR cases and flags a custom field 'Case was escalated'
*                   which in turn fires the workflows.
*                   (Ref = https://success.salesforce.com/ideaView?id=08730000000a8g9AAA)*
* @author       Ven Vairavan
* @date         8.Jan.2017         
* @description  Added for Standard Enquiry
* @revision     VVairavan, 05.Sept.2019 - Removed Standard Enquiry
***********************************************************************************************************/
global class escalatedCasesScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        List<Case> casesToUpdate = new List<Case>();        
        
        //add this to the SOQL to only run on HR Record Types
        Id HR_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HR').getRecordTypeId();
         
        casesToUpdate = [   SELECT  Id, IsEscalated, Case_Was_Escalated__c 
                            FROM    Case 
                            WHERE   Case_Was_Escalated__c = false 
                                AND IsEscalated = true 
                                AND RecordTypeId = : HR_RecTypeId ];
        
        //update the Case_Was_Escalated__c field and set it to true
        For(Case c:casesToUpdate){         
            c.Case_Was_Escalated__c = true;
        }
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }        
        
    }
}