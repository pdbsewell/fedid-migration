/**
 * @author       : Ibrahim Rumi
 * @date         : 03-07-2023
 * @group        : SFMC
 * @description  : test class for ier utility
 **/
@IsTest(isParallel = true)
private class SFMC_IERUtility_Test {

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
     * @description test generateEmailPreviewUrl method for correct generation of View_Email_Copy_Online__c field
     **/
    @isTest
    static void generateEmailPreviewUrl_Test() {

        et4ae5__SendDefinition__c emailSend = [SELECT id FROM et4ae5__SendDefinition__c LIMIT 1];
        List < et4ae5__IndividualEmailResult__c > ierList = new List < et4ae5__IndividualEmailResult__c > ();
        
        //given
        et4ae5__IndividualEmailResult__c ier = new et4ae5__IndividualEmailResult__c(
            et4ae5__SendDefinition__c = emailSend.id,
            et4ae5__JobId__c = '123445'
        );

        String ierStr = SFMC_IERUtility.generateEmailPreviewUrl(ier);

        //when
        Test.startTest();
            insert ier;
        Test.stopTest();

        //then
        et4ae5__IndividualEmailResult__c updatedIer = [SELECT id, et4ae5__JobId__c, View_Email_Copy_Online__c FROM et4ae5__IndividualEmailResult__c LIMIT 1];


        Assert.areEqual(ierStr, updatedIer.View_Email_Copy_Online__c, 'View Email Copy Online has not been populated correctly');
    }

    /**
     * @description test generateJWT method for the generated JWT
     **/
    @isTest
    static void generateJWT_Test() {

        et4ae5__SendDefinition__c emailSend = [SELECT id FROM et4ae5__SendDefinition__c LIMIT 1];
        List < et4ae5__IndividualEmailResult__c > ierList = new List < et4ae5__IndividualEmailResult__c > ();
        
        //given
        et4ae5__IndividualEmailResult__c ier = new et4ae5__IndividualEmailResult__c(
            et4ae5__SendDefinition__c = emailSend.id,
            et4ae5__JobId__c = '123445'
        );

        String ierStr = SFMC_IERUtility.generateJWT(ier);
        //when
        Test.startTest();
            insert ier;
        Test.stopTest();

        //then
        et4ae5__IndividualEmailResult__c updatedIer = [SELECT id, et4ae5__JobId__c, View_Email_Copy_Online__c FROM et4ae5__IndividualEmailResult__c LIMIT 1];

        String jwtStr = updatedIer.View_Email_Copy_Online__c.substringAfter('?id=');
        Assert.areEqual(ierStr, jwtStr, 'View Email Copy Online has not been populated correctly');
    }

    /**
     * @description test encode method for the string returned after encoding
     **/
    @isTest
    static void testencode() {

        //given
        Blob nonEmptyBlob = Blob.valueOf('Test Blob');

        // base64 encoded value of 'Test Blob'
        String expectedEncodedStr = 'VGVzdCBCbG9i';

        //when
        Test.startTest();
        string actualEncodedStr = SFMC_IERUtility.encode(nonEmptyBlob);
        Test.stopTest();

        //then
        Assert.areEqual(expectedEncodedStr, actualEncodedStr, 'encoding does not return the expected string');
    }

    /**
     * @description test GenerateEncodedJWT method for the encoded JWT
     **/
    @isTest
    static void testGenerateEncodedJWT() {

        //given
        String encodedHeader = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
        String encodedPayload = 'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlRlc3QgY29udGFjdCJ9'; // Example encoded payload
        String encodedSignature = 'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'; // Example encoded signature

        String expectedEncodedJWT = EncodingUtil.base64Encode(Blob.valueOf('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlRlc3QgY29udGFjdCJ9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c')); // Expected encoded JWT

        //when
        Test.startTest();
            String actualEncodedJWT = SFMC_IERUtility.generateEncodedJWT(encodedHeader, encodedPayload, encodedSignature);
        Test.stopTest();

        //then
        Assert.areEqual(expectedEncodedJWT, actualEncodedJWT, 'generateEncodedJWT method does not return the expected encoded jwt');

    }

    /**
     * @description test generateEncodedSignature method for the encoded signature
     **/
    @isTest
    static void testgenerateEncodedSignature() {

        //given
        String encodedHeader = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
        String encodedPayload = 'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlRlc3QgY29udGFjdCJ9';
        String key = String.valueof(SFMC_IERUtility.defaultSettings.get('IER_Util_Key__c'));
        String expectedEncodedSignature = 'VzmKsHif75AbdoEjF2oM97T3_j42AfWXBImRG3bLzAA';

        //when
        Test.startTest();
            String actualEncodedSignature = SFMC_IERUtility.generateEncodedSignature(encodedHeader, encodedPayload, key);
        Test.stopTest();

        //then
        Assert.areEqual(expectedEncodedSignature, actualEncodedSignature, 'generateEncodedSignature method does not return the expected encoded signature');

    }

    /**
     * @description test generateEncodedIERPayload method for the encoded payload
     **/
    @isTest
    static void testgenerateEncodedIERPayload() {

        //given
        et4ae5__IndividualEmailResult__c ier = new et4ae5__IndividualEmailResult__c(
            et4ae5__JobId__c = '123445',
            et4ae5__SubscriberId__c = '123445',
            et4ae5__ListId__c = '145',
            et4ae5__BatchId__c = '1'
        );
        String expectedEncodedPayload = 'eyJzdWJJZCI6IjEyMzQ0NSIsImxpc3RJZCI6IjE0NSIsImpvYmlkIjoiMTIzNDQ1IiwiYmF0Y2hJZCI6IjEifQ';

        //when
        Test.startTest();
            String actualEncodedPayload = SFMC_IERUtility.generateEncodedIERPayload(ier);
        Test.stopTest();

        //then
        Assert.areEqual(expectedEncodedPayload, actualEncodedPayload, 'generateEncodedIERPayload method does not return the expected encoded payload');
    }

    /**
     * @description test toJson method for the generated JSON
     **/
    @isTest
    static void testToJson() {

        //given
        et4ae5__IndividualEmailResult__c ier = new et4ae5__IndividualEmailResult__c(
            et4ae5__JobId__c = '123445',
            et4ae5__SubscriberId__c = '123445',
            et4ae5__ListId__c = '145',
            et4ae5__BatchId__c = '1'
        );

        SFMC_IERUtility.IERWrapper wrapIER = new SFMC_IERUtility.IERWrapper(ier);

        String expectedJson = '{"subId":"123445","listId":"145","jobid":"123445","batchId":"1"}';

        //when
        Test.startTest();
        String actualJson = SFMC_IERUtility.toJson(wrapIER);
        Test.stopTest();

        //then
        Assert.areEqual(expectedJson, actualJson, 'toJson method does not return the expected serialized json');
    }
}