/**
 * @description       : Test class for SystemSettingWrapper
 * @author            : Nick Guia
 * @group             : Commons
 * @last modified on  : 02-08-2022
 * @last modified by  : NG
**/
@isTest(isParallel=true)
private class SystemSettingWrapper_Test {

    /**
     * @description validate that class parses the JSON to the provided Apex class
     */
    @isTest
    static void shouldParseJsonToClass() {
        //GIVEN
        SystemSettingWrapper.ChannelBypassType chType; //expected return
        System_Settings__mdt sysSetting = new System_Settings__mdt(
            DataType__c = 'JSON',
            Feature__c = 'CHANNEL_BYPASS_TYPE',
            Key__C = 'ADDSTNAME',
            Value__c = '{ "key" : "ADDSTNAME", "field" : "Street_Name__c", "channelSObject" : "Address__c" }'
        );

        //WHEN
        Test.startTest();

        chType = (SystemSettingWrapper.ChannelBypassType) SystemSettingWrapper.parse(sysSetting, SystemSettingWrapper.ChannelBypassType.class);

        Test.stopTest();

        //THEN
        System.assertEquals('ADDSTNAME', chType.key, 'Unexpected value for key');
        System.assertEquals('Street_Name__c', chType.field, 'Unexpected value for field');
        System.assertEquals('Address__c', chType.channelSObject, 'Unexpected value for channelSObject');
    }

    /**
     * @description should not parse system settings whose data type is not JSON
     */
    @isTest
    static void shouldNotParseNonJson() {
        //GIVEN
        SystemSettingWrapper.ChannelBypassType chType; //expected return
        System_Settings__mdt sysSetting = new System_Settings__mdt(
            DataType__c = 'String',
            Feature__c = 'CHANNEL_BYPASS_TYPE',
            Key__C = 'ADDSTNAME',
            Value__c = 'RANDOM STRING'
        );
        Boolean isError = false;

        //WHEN
        Test.startTest();

        try {
            chType = (SystemSettingWrapper.ChannelBypassType) SystemSettingWrapper.parse(sysSetting, SystemSettingWrapper.ChannelBypassType.class);
        } catch (Exception e) {
            isError = true;
        }
        

        Test.stopTest();

        //THEN
        System.assert(isError, 'Should not attempt to parse non-JSON values');
    }
}