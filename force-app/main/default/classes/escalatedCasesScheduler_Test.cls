/**********************************************************************************************************
* @author       Anterey Custodio
* @date         13.Feb.2017         
* @description  Test Class for escalatedCasesScheduler
***********************************************************************************************************/
@isTest(isParallel=true)
public class escalatedCasesScheduler_Test {
    private static Case caseRecord;
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         13.Feb.2017          
    * @description  create sample cases
    * @revision     
    *******************************************************************************/
    static testMethod void createTestData() {
        TestHelper.calabrioSetUp();
        //HR Record Type
        Id HR_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HR').getRecordTypeId();
        
        caseRecord = new Case();
        caseRecord.IsEscalated = false;
        caseRecord.Case_Was_Escalated__c = false;
        caseRecord.RecordTypeId = HR_RecTypeId;
        insert caseRecord;
    }
    
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         13.Feb.2017          
    * @description  test the schedulable class
    * @revision     
    *******************************************************************************/
    static testMethod void test_ScheduleApex() {
        //create sample case
        createTestData();
        caseRecord.IsEscalated = true;
        update caseRecord;
        //assert if the case is not yet set to true
        System.assert(!caseRecord.Case_Was_Escalated__c);
        
        Test.startTest();
            
            //schedule the class
            escalatedCasesScheduler schedulableClass = new escalatedCasesScheduler();
            String sch = '0 0 23 * * ?'; 
            system.schedule('Test escalatedCasesScheduler', sch, schedulableClass); 
        
        Test.stopTest();
        
        //assert if the class has run and updated the case
        System.assertEquals(caseRecord.Id, [SELECT Id FROM Case WHERE Case_Was_Escalated__c = true].Id);
    }
}