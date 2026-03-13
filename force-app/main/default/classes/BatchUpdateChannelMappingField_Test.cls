/*******************************************************************************
* @author       Angelo Rivera
* @date         15/06/2018
* @description  Test Class for BatchUpdateChannelMappingField
* @revision    	02/05/2019 - Initial Version
*******************************************************************************/
@isTest(isParallel=true)
private class BatchUpdateChannelMappingField_Test {
    @isTest static void test_BatchOnly() {
        // Implement test code
        List<Case> lstCase = TestHelper.webToCaseForms(10);
        insert lstCase;
        System.debug('### lstCase.size: ' + lstCase.size());

        Test.startTest();
        BatchUpdateChannelMappingField obj = new BatchUpdateChannelMappingField();
        obj.strQuery='SELECT Id, Channel_Mapping__c, Origin FROM Case WHERE RecordType.Name = \'Standard Enquiry\' ';
        DataBase.executeBatch(obj,200);
        Test.stopTest();

        Case cseRec = [Select Id, CreatedDate, LastModifiedDate from Case where Id =: lstCase[0].Id];

        System.assert(cseRec.CreatedDate !=  cseRec.LastModifiedDate ,'Assertion Failed');
    }
}