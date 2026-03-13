/*******************************************************************************
* @author       J.Mapanao
* @date         23.JAN.2020        
* @description  Sibling test class for asc_TriggerController.cls
* @revision     23.JAN.2020 - J.Mapanao - Initial Created
*******************************************************************************/
@isTest(isParallel=true)
private class EngageConstants_Test {
    static testMethod void test_EngageConstants_Scene1() {
        
        Test.startTest();
        EngageConstants handler = new EngageConstants();
        System.assert(handler != null, 'ERROR: EngageConstants is null');
        List<RecordType> engageRecordTypes = EngageConstants.INTERIM_RECORDTYPES;
        System.assert(!engageRecordTypes.isEmpty(), 'ERROR: engageRecordTypes is null');
        Test.stopTest();
        
    }
}