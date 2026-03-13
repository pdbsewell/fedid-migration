/*******************************************************************************
* @author       J.Mapanao
* @date         23.JAN.2020        
* @description  Sibling test class for PageResult.cls
* @revision     23.JAN.2020 - J.Mapanao - Initial Created
*******************************************************************************/
@isTest(isParallel=true)
private class PageResult_Test {
    static testMethod void test_PageResult_Scene1() {
        
        Test.startTest();
        PageResult handler = new PageResult();
        System.assert(handler != null, 'ERROR: PageResult is null');
        Test.stopTest();
        
    }
}