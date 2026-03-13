/**
 * @description       : Test class for CommonServices
 * @author            : Angelo Rivera
 * @group             : Test
 * @last modified on  : 2020-10-16
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.1   2020-10-16   Stefan Scheit   Updated checkMethods() to validate account record type method
 * 1.0   2017-01-30   Angelo Rivera   Initial Version
**/
@isTest(isParallel=true)
private class CommonServices_Test {

    @isTest static void checkMethods(){
        String accountRecordTypeDeveloperName = [SELECT id, developerName FROM RecordType WHERE SobjectType = 'Account' LIMIT 1].developerName;

        System.assertNotEquals(null,
                CommonServices.recordTypeId('Account', accountRecordTypeDeveloperName),
                'should not have returned null');

        System.assertEquals(null,
                CommonServices.orgWideAddressId('nonExistantOrgWideEmail'),
                'should have returned null');
        System.assertNotEquals(null,
                CommonServices.orgWideAddressId(CommonServices.ORGWIDE_ADDRESS_MONASH),
                'should not have returned null');

        boolean retrieveSandbox = CommonServices.isSandbox;
        System.assertNotEquals(null, retrieveSandbox);

        Map<Id,String> mapQueue = CommonServices.mapQueue('Case');
        System.assertNotEquals(null, mapQueue);
    }
}