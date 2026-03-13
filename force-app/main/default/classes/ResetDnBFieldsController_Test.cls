/**
 * @author         Inderpal Dhanoa
 * @description     Test class for ResetDnBFieldsController logic
 * @Last Modified By  : Sachin Shetty
 * @Last Modified On  : 2024-04-17
 * @version           : Modifications Log
 * Date           Author              Modification
 * 2020-09-05     Inderpal Dhanoa     Initial Version
 * 2024-04-17     Sachin Shetty       Update to point to DBConnect fields
 */
@isTest(isParallel=true)
private class ResetDnBFieldsController_Test {

    @TestSetup
    static void setupData() {
        Account acc = (Account)TestDataFactory.createSObject(new Account(DBC_DUNS_Number__c = 'testEntry', BillingCity = 'testCity'), true);
    }

    @isTest
    static void testInvalidDonor() {
        List<Account> dunsAcc = [SELECT Id,BillingCity,DBC_DUNS_Number__c FROM Account WHERE DBC_DUNS_Number__c = 'testEntry'];
        // given: DUNS Account exists 
        Test.startTest();
            // when: Method initiated
            ResetDnBFieldsController.clearFields(dunsAcc[0].Id);
        Test.stopTest();
        // then: fields reset
        dunsAcc = [SELECT Id,BillingCity,DBC_DUNS_Number__c FROM Account WHERE Id = :dunsAcc[0].Id];
        Assert.isNull(dunsAcc[0].DBC_DUNS_Number__c, 'DUNS number field should be null');
        Assert.isNull(dunsAcc[0].BillingCity, 'Billing City field should be null');
    }
}