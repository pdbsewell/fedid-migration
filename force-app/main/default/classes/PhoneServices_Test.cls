/* 
 * Phone Services test classes
 */ 
@isTest(isParallel=true)
public class PhoneServices_Test {

    static Contact contactRecord {get; set;}
    static PhoneServices.PhoneFormatCustomMetadataWrapper AustraliaFormat = new PhoneServices.PhoneFormatCustomMetadataWrapper(
        '+61',
        '^(?=.{10,})^((?:\\+|00|0011|\\+00|\\+0011)?61)?(0?[4])(\\d{8})$'
    );
    static PhoneServices.PhoneFormatCustomMetadataWrapper ChinaFormat = new PhoneServices.PhoneFormatCustomMetadataWrapper(
        '+86',
        '^(?=.{13,})^((?:\\+|00|0011|\\+00|\\+0011)?86)(0?1)(\\d{10})$'
    );
    
    @testSetup 
    static void setupData(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;
        
        // Switch on mobile phone formatting.
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Format_Mobile__c = true;
        insert fs;
    }
    
    
    @isTest
    static void validateStudent() {

        String contactStr = '{"Person_ID_unique__c":"12345555","FirstName":"Eddy","LastName":"Test","Is_Student__c" : true,"mobilephone":"0401111000"}';
        Contact contactRecord = (Contact)JSON.deserialize(contactStr, Contact.class);
        insert contactRecord;
        Assert.isNotNull(contactRecord.Id, 'Contact Record Insert Failed');

        Test.startTest();
        List<Channel__c> chanlst = new List<Channel__c>();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Street__c = '55 Collin St',
                Post_Code__c = '3000',
                State__c = 'Vic',
                City__c = 'Melbourne',
                Country__c = 'Australia',
                Source_System__c = 'Callista',
                Mobile_Phone__c = '0401111111',
                Start_Date__c = Date.today()-720
            )
        ); 

        chanlst.add(
            new Channel__c(
                type__c = 'OS-POSTAL',
                Contact__c = contactRecord.id,
                Street__c = '55 Collin St',
                Post_Code__c = '3000',
                State__c = 'Vic',
                City__c = 'Melbourne',
                Country__c = 'Australia',
                Source_System__c = 'Callista',
                Mobile_Phone__c = '0401111222',
                Start_Date__c = Date.today()-360
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // A channel breakup should have happened
        // Personal emails from channels will be ignored
        List<phone__c> phoneList = [SELECT Id, name, source__c, start_date__c FROM phone__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = TRUE];
        Assert.areEqual(1, phoneList.size());
        Assert.areEqual( chanlst[0].Source_System__c,phoneList[0].Source__c); 
        Assert.areEqual( Date.today()-720, phoneList[0].start_date__c); // callista phone with the lowest ranking
    }


    /**
     * Scenario:
     * GIVEN A new phone created by Automated Process
     * WHEN new phone record inserted manually as primary
     * THEN it will not roll up in corresponding phone fields
     * when there is already existing primary set by user
     */
    @isTest
    static void validatePrimaryNonStudent() {

        // Given
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        setupDataManual();
        Test.getEventBus().deliver();

        Phone__c phone = new Phone__c(
            Contact__c = contactRecord.Id,
            Start_Date__c = Date.today(),
            Is_Primary__c = true,
            Is_Active__c = true,
            Classification__c = 'Private',
            Name = '+61390008005',
            Source__c = 'Undefined',
            Type__c = 'Mobile'
        );
        insert phone;
        Test.getEventBus().deliver();

        // When
        Test.startTest();
            List<Channel__c> channelList = new List<Channel__c>();
            channelList.add(
                new Channel__c(
                    type__c = 'POSTAL',
                    Contact__c = contactRecord.id,
                    Phone__c = '+61390008006'
                )
            ); 
            insert channelList;
            Test.getEventBus().deliver();
        Test.stopTest();

        // Then
        Contact con = [SELECT Id,Phone,MobilePhone,HomePhone,OtherPhone,Fax FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('+61390008005', con.Phone, 'Expected Phone value should be +61390008005');
        Assert.areEqual('+61390008005', con.MobilePhone, 'Expected MobilePhone value should be +61390008005');
        Assert.areEqual('+61390008006', con.HomePhone, 'Expected HomePhone value should be +61390008006');
        Assert.areEqual('+61390008002', con.OtherPhone, 'Expected OtherPhone value should be +61390008002');
        Assert.areEqual('+61390008999', con.Fax, 'Expected Fax value should be +61390008999');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new phone record inserted manually as primary
     * AND no callista record exists
     * THEN roll up the latest greatest
     */
    @isTest
    static void validatePrimaryStudent() {

        // Given
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        setupDataManual();
        contactRecord.Is_Student__c = true;
        update contactRecord;

        // When
        Test.startTest();
            List<Channel__c> chanlst = new List<Channel__c>();
            chanlst.add(
                new Channel__c(
                    type__c = 'POSTAL',
                    Contact__c = contactRecord.id,
                    Mobile_Phone__c = '+61390008006'
                )
            ); 
            insert chanlst;
            Test.getEventBus().deliver();
        Test.stopTest();

        // Then
        Contact con = [SELECT Id,Phone,MobilePhone,HomePhone,OtherPhone,Fax FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('+61390008006', con.Phone, 'Expected Phone value should be +61390008006');
        Assert.areEqual('+61390008006', con.MobilePhone, 'Expected MobilePhone value should be +61390008006');
        Assert.areEqual('+61390008001', con.HomePhone, 'Expected HomePhone value should be +61390008001');
        Assert.areEqual('+61390008002', con.OtherPhone, 'Expected OtherPhone value should be +61390008002');
        Assert.areEqual('+61390008999', con.Fax, 'Expected Fax value should be +61390008999');
    }

    // The phone number is stripped of non-numeric characters when the key set is formed.
    @isTest
    static void validateBuildPhoneKeySet() {
	
        // Given
        String testPhone = '+61 401-717-956';
		String testLastname = 'Lastname ' + String.valueOf(System.now());
        Id testContactId = fflib_IDGenerator.generate(Contact.SObjectType);

        // When
        Test.startTest();
            Set<String> keySet = phoneServices.buildPhoneKeySet(testContactId,'Mobile', testPhone);
        Test.stopTest();
        List<String> keyList = new List<String>(keySet);

        // Then
        Assert.areEqual(3, keyList.size());
        Assert.areEqual(testPhone.replaceAll('[^0-9]',''), keyList.get(2));        
    }

    // The phone number is stripped of non-numeric characters when the key set is formed.
    @isTest
    static void validateBuildPhoneKeySetPhoneRecordInput() {

        // Given
        Phone__c phone = new Phone__c(
            Contact__c = fflib_IDGenerator.generate(Contact.SObjectType),
            Name = '+61390008005',
            Type__c = 'Mobile'
        );

        // When
        Test.startTest();
            Set<String> keySet = phoneServices.buildPhoneKeySet(phone);
        Test.stopTest();
        List<String> keyList = new List<String>(keySet);

        // Then
        Assert.areEqual(3,keyList.size());
        Assert.areEqual(phone.Name.replaceAll('[^0-9]',''), keyList.get(2));
    }
    
    @isTest
    static void validateFormatPhone() {

        // Given
		String phone = '+(61) 04-01-777-432';

		Test.startTest();
            // When       
            Feature_Switch__c customSetting = Feature_Switch__c.getInstance();
            customSetting.Format_Mobile__c = false;
            upsert customSetting;
            
            // Then unformatted
            Assert.areEqual(phone, phoneServices.formatPhone(phone));

            // When
            customSetting.Format_Mobile__c = true;
            upsert customSetting;

            // Then
            //formatted
            Assert.areEqual('+61 401777432', phoneServices.formatPhone(phone));
		Test.stopTest();
    }

    @isTest
    static void validateFormatPhoneNullInput() {

        // Given
        String phoneNumber = null;

        // When
        Test.startTest();
            String formattedPhoneNumber = PhoneServices.formatPhone(phoneNumber);
        Test.stopTest();

        // Then
        Assert.areEqual('', formattedPhoneNumber , 'Error, should have returned empty string');
    }

    @isTest
    static void validateMatchPatternAndFormatNumberSuccess() {

        // Given
		String phoneNumber = '+(61) 04-01-777-432';
        String cleansedNumber = phoneNumber.replaceAll('[^0-9]', '');

        Map<String, String> phoneFormatDataByCountry = new Map<String, String>{
            'Australia' => JSON.serialize(AustraliaFormat)
        };

        // When
		Test.startTest();
            PhoneServices.formatPhoneWrapper fpw = PhoneServices.matchPatternAndFormatNumber(phoneFormatDataByCountry, cleansedNumber, phoneNumber);
        Test.stopTest();

        // Then
        Assert.areEqual('+61 401777432', fpw.phoneNumber, 'Error formatting phone number');
        Assert.areEqual('+61', fpw.CountryCode, 'Error retriving country code');
    }

    @isTest
    static void validateMatchPatternAndFormatNumberChooseRightFormat() {

        // Given
		String phoneNumber = '+(61) 04-01-777-432';

        String cleansedNumber = phoneNumber.replaceAll('[^0-9]', '');

        Map<String, String> phoneFormatDataByCountry = new Map<String, String>{
            'Australia' => JSON.serialize(AustraliaFormat),
            'China' => JSON.serialize(ChinaFormat)
        };

        // When
		Test.startTest();
            String formattedNumber = PhoneServices.matchPatternAndFormatNumber(phoneFormatDataByCountry, cleansedNumber, phoneNumber).phoneNumber;
        Test.stopTest();

        // Then
        Assert.areEqual('+61 401777432', formattedNumber, 'The correct format was not chosen to format the phone number');		
    }

    @isTest
    static void validateMatchPatternAndFormatNumberFormatInfoNotPresent() {

        // Given
		String phoneNumber = '+(91) 99-76-396-342'; // Indian phone number as input

        String cleansedNumber = phoneNumber.replaceAll('[^0-9]', '');

        Map<String, String> phoneFormatDataByCountry = new Map<String, String>{ // India format data not present
            'Australia' => JSON.serialize(AustraliaFormat),
            'China' => JSON.serialize(ChinaFormat)
        };

        // When
		Test.startTest();
            String result = PhoneServices.matchPatternAndFormatNumber(phoneFormatDataByCountry, cleansedNumber, phoneNumber).phoneNumber;
        Test.stopTest();

        // Then
        Assert.areEqual(phoneNumber, result, 'The phone number should not have been formatted as the related formatting information is missing.');		
    }

    @isTest
    static void validateGetPhoneNumberFormatParams() {

        // Given
        // When
        Test.startTest();
            Map<String, String> formatsCustomMetadata = PhoneServices.getPhoneNumberFormatParams();
        Test.stopTest();

        // Then
        system.assertNotEquals(null, formatsCustomMetadata.keySet() , 'Missing Custom Metadata in System_Settings__mdt with the feature PHONE_NUMBER_FORMAT');
    }

    @isTest
    static void validateRawFormatPhoneSuccess() {

        // Given
        String phoneNumber = '+(61) 04-01-777-432';

        // When
        Test.startTest();
            String rawFormattedPhoneNumber = PhoneServices.rawFormatPhone(phoneNumber);
        Test.stopTest();

        // Then
        Assert.areEqual('61401777432', rawFormattedPhoneNumber , 'Incorrectly formatted phone number');
    }

    @isTest
    static void validateRawFormatPhoneNullInput() {

        // Given
        String phoneNumber = null;

        // When
        Test.startTest();
            String rawFormattedPhoneNumber = PhoneServices.rawFormatPhone(phoneNumber);
        Test.stopTest();

        // Then
        Assert.areEqual('', rawFormattedPhoneNumber , 'Should have returned empty string');
    }

    /**
     * @description Set up data manually
     */
    private static void setupDataManual() {
        contactRecord = new Contact(
            Person_ID_unique__c = '12345',
            Birthdate = Date.today().addYears(- 20),
            Citizenship__c = 'INTERNATIONAL',
            Citizenship_Code__c = '4',
            Residency_Status__c = 'Australian Permanent Resident',
            Email = 'test@test.com',
            Monash_Email_Address__c = 'test@test.com',
            Salutation = 'Mr.',
            FirstName = 'testFirstName',
            LastName = 'testLastName',
            Gender__c = 'None',
            MobilePhone = '+61400111222', // this will be reformatted
            HomePhone = '+61390008001',
            OtherPhone = '+61390008002',
            AssistantPhone = '+61390008003',
            Fax = '+61390008999'
        );
        insert contactRecord;
        Assert.isNotNull(contactRecord.Id, 'Contact Record Insert Failed');
    }

    @isTest
    static void validate_RetrieveMFAVerifiedPhone(){
        setupDataManual();
        List<Contact> lstCon = [SELECT id FROM Contact LIMIT 1];
        Phone__c phoneRecord = new Phone__c (
            contact__c = lstCon[0].id,
            Classification__c = 'Private',
            Is_Active__c = true,
            Is_Deleted__c = false,
            Is_Primary__c = false,
            Name = '+61 400555222',
            Source__c = 'Contact supplied',
            Type__c = 'Mobile', 
            Verification_Status__c = 'Verified by MFA'
        );
        insert phoneRecord;
        Test.startTest();
            String mfaVerifiedPhone = PhoneServices.retrieveMFAVerifiedPhone(lstCon[0].id);
        Test.stopTest();
        Assert.areEqual('+61 400555222', mfaVerifiedPhone, 'MFA verified Phone no retreival failed');        
    }
}