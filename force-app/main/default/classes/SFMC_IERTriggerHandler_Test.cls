/**
 * @author       : Ibrahim Rumi
 * @date         : 03-07-2023
 * @group        : SFMC
 * @description  : test class for SFMC_IERTriggerHandler
 **/
@IsTest(isParallel = true)
private class SFMC_IERTriggerHandler_Test {

    @TestSetup
    static void setup() {

        //create business unit
        et4ae5__Business_Unit__c bu = new et4ae5__Business_Unit__c(
            Name = 'Test',
            et4ae5__Business_Unit_ID__c = '1234567',
            et4ae5__Enabled__c = true
        );

        insert bu;

        //create configuration
        et4ae5__Configuration__c conf = new et4ae5__Configuration__c(
            et4ae5__Username__c = 'test@monash.edu'
        );

        insert conf;

        //create email send
        et4ae5__SendDefinition__c emailSend = new et4ae5__SendDefinition__c(
            et4ae5__Business_Unit__c = bu.id
        );

        insert emailSend;

        //add IER util defaults on custom settings
        et4ae5__ET4AE_Config__c config = new et4ae5__ET4AE_Config__c(
            IER_Util_Key__c = 'a1b2c3d4e5f6g7h8',
            IER_Util_URL__c = 'https://at.monash.edu/EmailPreview'
        );

        insert config;
    }

    /**
     * @description bulk test generation of encrypted view online URL when IERs are inserted
     **/
    @isTest
    static void testGenerateEncryptViewURL() {

        et4ae5__SendDefinition__c emailSend = [SELECT id FROM et4ae5__SendDefinition__c LIMIT 1];
        List < et4ae5__IndividualEmailResult__c > ierList = new List < et4ae5__IndividualEmailResult__c > ();
        
        //given
        for (Integer i = 1; i < 200; i++) {
            et4ae5__IndividualEmailResult__c ier = new et4ae5__IndividualEmailResult__c(
                et4ae5__SendDefinition__c = emailSend.id,
                et4ae5__JobId__c = String.valueof(i)
            );
            ierList.add(ier);
        }

        //when
        Test.startTest();
            insert ierList;
        Test.stopTest();
        
        //then
        Map <id, et4ae5__IndividualEmailResult__c> updatedIer = new map <id, et4ae5__IndividualEmailResult__c> ([SELECT id, et4ae5__JobId__c, View_Email_Copy_Online__c FROM et4ae5__IndividualEmailResult__c]);
        for (et4ae5__IndividualEmailResult__c ierupd: updatedIer.values()) {
            if (String.isEmpty(ierupd.View_Email_Copy_Online__c)) {
                updatedIer.remove(ierupd.Id);
            }
        }
        Assert.areEqual(updatedIer.size(), ierList.size(), 'View Email Copy Online has not been populated correctly');
    }
}