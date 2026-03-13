/*******************************************************************************
* @author       J.Mapanao
* @date         23.JAN.2020        
* @description  Sibling test class for asc_TriggerController.cls
* @revision     23.JAN.2020 - J.Mapanao - Initial Created
*******************************************************************************/
@isTest(isParallel=true)
private class asc_TriggerController_Test {
    static testMethod void test_asc_TriggerController() {
        
        Test.startTest();
        asc_TriggerController handler = new asc_TriggerController();
        System.assert(handler != null, 'ERROR: asc_TriggerController is null');
        Test.stopTest();
        
    }
}