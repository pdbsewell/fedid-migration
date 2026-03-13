@isTest(isParallel=true)
private class PhoneTriggerHandler_Test {
    static Contact contactRecord {get; set;}

    /**
     * Set up Data
     * @return [description]
     */
    @testSetup static void setupData(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;

        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Format_Mobile__c = true;
        insert fs;
    }

    static testMethod void phoneTest() {
        setupDataManual();

        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
//        phone.Start_Date__c = Date.today();
        phone.Classification__c = 'Private';
        phone.Name = '0704777888';
        phone.Source__c = 'Undefined';

        Test.startTest();
        insert phone;
        Test.getEventBus().deliver();
        Triggers.clearAllBypasses();
        Test.stopTest();

        Phone__c insertedPhone = [select name, start_date__c, country_code__c from phone__c where id = :phone.id limit 1];
        System.assertEquals(Date.today(),insertedPhone.Start_Date__c,'Default Start Date Today Failed');
    }

    static testMethod void afterUpdateTest() {
        setupDataManual();

        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today();
        phone.Classification__c = 'Private';
        phone.Name = '+61390008999';
        phone.Source__c = 'Undefined';

        Test.startTest();
        insert phone;
        Triggers.clearAllBypasses();
        phone.Is_Primary__c = true;
        update phone;
        Test.getEventBus().deliver();
        System.assertEquals(1,[SELECT COUNT() FROM Phone__c WHERE Is_Primary__c = true AND Contact__r.Id =: contactRecord.Id],'One Primary Contact per contact failed.');
        Test.stopTest();
    }
    /**
     * GIVEN User create new Phone__c record WHERE Start_Date__c > TODAY AND Is_Active__c = TRUE
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    static testMethod void toggleIsActive_Scenario1() {
        //Given
        setupDataManual();
        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today().addDays(5);
        phone.Is_Active__c = true;
        phone.Classification__c = 'Private';
        phone.Name = '+61390008999';
        phone.Source__c = 'Undefined';

        Test.startTest();
        insert phone;
        Test.getEventBus().deliver();
        Test.stopTest();

        System.assertEquals(false, [SELECT Is_Active__c FROM Phone__c WHERE Id =: phone.Id].Is_Active__c);
    }
    /**
     * GIVEN User create new Phone__c record WHERE Start_Date__c = TODAY AND Is_Active__c = FALSE
     * WHEN User click Save
     * THEN set Is_Active__c to TRUE
     */
    static testMethod void toggleIsActive_Scenario2() {
        //Given
        setupDataManual();
        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today();
        phone.Is_Active__c = false;
        phone.Classification__c = 'Private';
        phone.Name = '+61390008999';
        phone.Source__c = 'Undefined';

        Test.startTest();
        insert phone;
        Test.getEventBus().deliver();
        Test.stopTest();

        System.assertEquals(true, [SELECT Is_Active__c FROM Phone__c WHERE Id =: phone.Id].Is_Active__c);
    }
    /**
     * GIVEN User create new Phone__c record WHERE End_Date__c < TODAY AND Is_Active__c = true
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    static testMethod void toggleIsActive_Scenario3() {
        //Given
        setupDataManual();
        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today().addDays(-5);
        phone.End_Date__c = Date.today().addDays(-3);
        phone.Is_Active__c = true;
        phone.Classification__c = 'Private';
        phone.Name = '+61390008999';
        phone.Source__c = 'Undefined';

        Test.startTest();
        insert phone;
        Test.getEventBus().deliver();
        Test.stopTest();

        System.assertEquals(false, [SELECT Is_Active__c FROM Phone__c WHERE Id =: phone.Id].Is_Active__c);
    }
    
    static testMethod void toggleIsActive_Scenario4() {
        //Given
        setupDataManual();
        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today().addDays(-5);
        phone.End_Date__c = Date.today().addDays(-3);
        phone.Is_Active__c = true;
        phone.Classification__c = 'Private';
        phone.Name = '+61390008999';
        phone.Source__c = 'Undefined';
        insert phone;

        Test.startTest();
        Phone__c phoneToUpdate = [SELECT Start_Date__c FROM Phone__c WHERE Id =: phone.Id];
        phoneToUpdate.Start_Date__c = Date.today().addDays(-6);
        update phoneToUpdate;
        Test.getEventBus().deliver();
        Test.stopTest();

        System.assertEquals(false, [SELECT Is_Active__c FROM Phone__c WHERE Id =: phone.Id].Is_Active__c);
    }
    
    static testMethod void findNewPrimary_Scenario5() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        upsert cs;
        //Given
        setupDataManual();
        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today().addDays(-5);
        phone.End_Date__c = Date.today().addDays(-3);
        phone.Is_Active__c = true;
        phone.Classification__c = 'Private';
        phone.Name = '+61390008988';
        phone.Source__c = 'Undefined';
        insert phone;

        Test.startTest();
        List<Phone__c> phones = [SELECT Id FROM Phone__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = true];
        System.assert(phones.size() > 0);
        delete phones;
        Test.getEventBus().deliver();
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Phone__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = true], 'Setting new primary failed');
    }
    /**
     * Scenario:
     * GIVEN A User login to UniCRM
     * AND search for a contact record
     * AND contact record is not student
     * WHEN new phone record inserted manually as primary
     * THEN it will roll up in corresponding Phone field
     */
    @isTest
    static void phoneRecordTest1() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        
        setupDataManual();
        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today();
        phone.Is_Primary__c = true;
        phone.Is_Active__c = true;
        phone.Classification__c = 'Private';
        phone.Name = '+61390008005';
        phone.Source__c = 'Undefined';
        phone.Type__c = 'Mobile';
        Test.startTest();
        insert phone;
        Test.getEventBus().deliver();
        Test.stopTest();
        
        Contact con = [SELECT Id,Phone,MobilePhone,HomePhone,OtherPhone,Fax FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        System.assertEquals('+61390008005', con.Phone, '##### Error! Expected Phone value should be +61390008005');
        System.assertEquals('+61390008005', con.MobilePhone, '##### Error! Expected MobilePhone value should be +61390008005');
        System.assertEquals('+61390008001', con.HomePhone, '##### Error! Expected HomePhone value should be +61390008001');
        System.assertEquals('+61390008002', con.OtherPhone, '##### Error! Expected OtherPhone value should be +61390008002');
        System.assertEquals('+61390008999', con.Fax, '##### Error! Expected Fax value should be +61390008999');
    }

    /**
     * Scenario:
     * GIVEN A new phone created by Automated Process
     * WHEN new phone record inserted manually as primary
     * THEN it will not roll up in corresponding phone fields
     * when there is already existing primary set by user
     */
    @isTest
    static void phoneRecordTest2() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        setupDataManual();
        Test.getEventBus().deliver();

        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today();
        phone.Is_Primary__c = true;
        phone.Is_Active__c = true;
        phone.Classification__c = 'Private';
        phone.Name = '+61390008005';
        phone.Source__c = 'Undefined';
        phone.Type__c = 'Mobile';
        insert phone;
        Test.getEventBus().deliver();

        Test.startTest();
        List<Channel__c> chanlst = new List<Channel__c>();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Phone__c = '+61390008006'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Phone,MobilePhone,HomePhone,OtherPhone,Fax FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        System.assertEquals('+61390008005', con.Phone, '##### Error! Expected Phone value should be +61390008005');
        System.assertEquals('+61390008005', con.MobilePhone, '##### Error! Expected MobilePhone value should be +61390008005');
        System.assertEquals('+61390008006', con.HomePhone, '##### Error! Expected HomePhone value should be +61390008006'); // Relies on metadata defintion of phone1 to be type landline
        System.assertEquals('+61390008002', con.OtherPhone, '##### Error! Expected OtherPhone value should be +61390008002');
        System.assertEquals('+61390008999', con.Fax, '##### Error! Expected Fax value should be +61390008999');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new phone record inserted manually as primary
     * AND no callista record exists
     * THEN roll up the latest greatest
     */
    @isTest
    static void phoneRecordTest3() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        setupDataManual();
        contactRecord.Is_Student__c = true;
        update contactRecord;
        Test.startTest();
        List<Channel__c> chanlst = new List<Channel__c>();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                mobile_Phone__c = '+61390008006'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Phone,MobilePhone,HomePhone,OtherPhone,Fax FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        System.assertEquals('+61390008006', con.Phone, '##### Error! Expected Phone value should be +61390008006');
        System.assertEquals('+61390008006', con.MobilePhone, '##### Error! Expected MobilePhone value should be +61390008006');
        System.assertEquals('+61390008001', con.HomePhone, '##### Error! Expected HomePhone value should be +61390008001');
        System.assertEquals('+61390008002', con.OtherPhone, '##### Error! Expected OtherPhone value should be +61390008002');
        System.assertEquals('+61390008999', con.Fax, '##### Error! Expected Fax value should be +61390008999');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new email record inserted manually as primary
     * AND there is callista record exists
     * THEN roll up the latest greatest
     */
    @isTest
    static void phoneRecordTest4() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        setupDataManual();
        contactRecord.Is_Student__c = true;
        update contactRecord;
        List<Channel__c> chanlst = new List<Channel__c>();
        Test.startTest();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Mobile_Phone__c = '+61390008006',
                Source_System__c = 'Callista'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Phone,MobilePhone,HomePhone,OtherPhone,Fax FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        System.assertEquals('+61390008006', con.Phone, '##### Error! Expected Phone value should be +61390008006');
        System.assertEquals('+61390008006', con.MobilePhone, '##### Error! Expected MobilePhone value should be +61390008006');
        System.assertEquals('+61390008001', con.HomePhone, '##### Error! Expected HomePhone value should be +61390008001');
        System.assertEquals('+61390008002', con.OtherPhone, '##### Error! Expected OtherPhone value should be +61390008002');
        System.assertEquals('+61390008999', con.Fax, '##### Error! Expected Fax value should be +61390008999');
    }

    /**
     * For students, such an update (setting end date, or marking the the contact point inactive) remains blocked, i.e. no change.
     * Scenario:
     * GIVEN Contact is a student
     * WHEN User end dated a Callista address contact point with parent active channel
     * THEN it will revert back the callista address contact point from parent active channel details
     */
    @isTest
    static void phoneRecordTest5() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        setupDataManual();
        contactRecord.Is_Student__c = true;
        update contactRecord;
        List<Channel__c> chanlst = new List<Channel__c>();
        Test.startTest();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Mobile_Phone__c = '+61301555123', // this will not be formatted
                Source_System__c = 'Callista'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        List<Phone__c> phones = [SELECT Id, Name, End_Date__c, Channel__c FROM Phone__c WHERE Contact__r.Id =: contactRecord.Id AND Name = '+61301555123'];
        System.assertEquals(1, phones.size());
        System.assertEquals(null, phones[0].End_Date__c, '##### Error! Expected End Date of phone with channel is null');
        phones[0].End_Date__c = Date.today();
        update phones;
        Test.stopTest();
        List<Phone__c> updatedPhones = [SELECT Id, Name, End_Date__c, Channel__c FROM Phone__c WHERE id = :phones[0].id];
        System.assertEquals(1, updatedPhones.size());
        System.assertEquals(null, updatedPhones[0].End_Date__c, '##### Error! Expected End Date of phone with channel is null');
    }

    /**
     * A contact point of a non-student with source=Callista can be end-dated (by a user) and 
     * remains end-dated despite an active Channel (lookup) record, i.e. the email remains active in the Channel record.
     * Scenario:
     * GIVEN Contact is non-student
     * WHEN User end dated a Callista address contact point with parent active channel
     * THEN allow end dating the callista address contact point
     */
    @isTest
    static void phoneRecordTest6() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        setupDataManual();
        List<Channel__c> chanlst = new List<Channel__c>();
        Test.startTest();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Mobile_Phone__c = '+61390008006',
                Source_System__c = 'Callista'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        List<Phone__c> phones = [SELECT Id, Name, End_Date__c, Channel__c FROM Phone__c WHERE Contact__r.Id =: contactRecord.Id AND Name = '+61390008006'];
        System.assertEquals(1, phones.size());
        System.assertEquals(null, phones[0].End_Date__c, '##### Error! Expected End Date of phone with channel is null');
        phones[0].End_Date__c = Date.today();
        update phones;
        Test.stopTest();
        List<Phone__c> updatedPhones = [SELECT Id, Name, End_Date__c, Channel__c FROM Phone__c WHERE Contact__r.Id =: contactRecord.Id AND Name = '+61390008006'];
        System.assertEquals(1, updatedPhones.size());
        System.assertEquals(Date.today(), updatedPhones[0].End_Date__c, '##### Error! Expected callista phone to be end dated.');
    }

    /**
     * Set up data manually
     */
    private static void setupDataManual() {
        contactRecord = new Contact();
        contactRecord.Person_ID_unique__c = '12345';
        contactRecord.Birthdate = Date.today().addYears(- 20);
        contactRecord.Citizenship__c = 'INTERNATIONAL';
        contactRecord.Citizenship_Code__c = '4';
        contactRecord.Residency_Status__c = 'Australian Permanent Resident';
        contactRecord.Email = 'test@test.com';
        contactRecord.Monash_Email_Address__c = 'test@test.com';
        contactRecord.Salutation = 'Mr.';
        /*contactRecord.Title*/
        contactRecord.FirstName = 'testFirstName';
        contactRecord.LastName = 'testLastName';
        contactRecord.Gender__c = 'None';
        contactRecord.MobilePhone = '+61400111222'; // this will be reformatted
        contactRecord.HomePhone = '+61390008001';
        contactRecord.OtherPhone = '+61390008002';
        contactRecord.AssistantPhone = '+61390008003';
        contactRecord.Fax = '+61390008999';
        insert contactRecord;
        System.assertNotEquals(null, contactRecord.Id, 'Contact Record Insert Failed');
    }
}