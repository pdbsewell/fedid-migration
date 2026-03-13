/**
 * @description Trigger logic for Name__c object
 * 
 */
@isTest(isParallel=true)
private class NameTriggerHandler_Test {
    static Contact contactRecord {get; set;}
    static Name__c nameRecord {get; set;}

    /**
     * @descritpion Set up Data
     */
    @testSetup
    static void setupData() {
        Person360Muting__c mute = Person360Muting__c.getOrgDefaults();
        mute.Enable_Roll_Up__c = true;
        mute.Run_Roll_Up_Asynchronously__c = true;
        upsert mute;
    }

    /*
     * @description Various stress tests
     */
    @isTest
    static void nameNameFieldTest() {
        setupDataManual();
        Test.startTest();
        nameRecord = new Name__c();
        nameRecord.Contact__c = contactRecord.Id;
        nameRecord.First_Name__c = 'testFirstName';
        nameRecord.Middle_Name__c = 'testMiddleName';
        nameRecord.Last_Name__c = 'TestLastName';
        nameRecord.Salutation__c = 'Mr.';
        nameRecord.type__c = 'Common';

        insert nameRecord;
        Test.getEventBus().deliver();
        Assert.isNotNull(nameRecord.Id, 'Name Record Insert Failed');
        String fullName = Person360Helper.formatName(nameRecord.First_Name__c, nameRecord.Middle_Name__c, nameRecord.Last_Name__c);
        List<Name__c> lNames = [SELECT Id, Name FROM Name__c WHERE Id = : nameRecord.Id];
        Assert.areNotEqual(fullName, lNames.get(0).Name, 'Name__c.Name concatenation failed');
        Test.stopTest();

        // Test before update event
        nameRecord.Last_Name__c = 'TestMore80CharactersTestMore80CharactersTestMore80CharactersTestMore80Characters';
        update nameRecord;
        String updatedFullName = Person360Helper.formatName(nameRecord.First_Name__c, nameRecord.Middle_Name__c, nameRecord.Last_Name__c);
        List<Name__c> updatedNames = [SELECT Id, Name FROM Name__c WHERE Id = : nameRecord.Id];
        Assert.areNotEqual(updatedFullName, updatedNames.get(0).Name, 'Name__c.Name concatenation failed');
    }
    
    /*
     * @description If the first name contains a middlename, split it up
     * InitialiseFields method test
     */
    @isTest
    static void validateMiddleNameHandling() {
        setupDataManual();
        nameRecord = new Name__c();
        nameRecord.Contact__c = contactRecord.Id;
        nameRecord.First_Name__c = 'testFirstName testMiddleName';
        nameRecord.Last_Name__c = 'TestLastName';
        nameRecord.Salutation__c = 'Mr.';
        nameRecord.prefix__c = 'Mr';
        nameRecord.type__c = 'Common';

        Test.startTest();
        insert nameRecord;
        Test.getEventBus().deliver();
        Assert.isNotNull(nameRecord.Id, 'Name Record Insert Failed');
        Test.stopTest();
        
        Name__c n = [SELECT Id, first_name__c, middle_name__c, Salutation__c, prefix__c FROM Name__c WHERE Id = : nameRecord.Id];
        Assert.areEqual('testFirstName', n.first_name__c, 'First name field may still contain middle name');
        Assert.areEqual('testMiddleName', n.middle_name__c, 'Middle name should have been sourced from the first name');
        Assert.areEqual('Mr', n.Salutation__c, 'The . should have been removed from the salutation');
        Assert.areEqual('Mr', n.prefix__c, 'The . should have been removed from the prefix');
    }

    /*
     * @Description Ensure primary flag is handled correctly
     */
    @isTest
    static void primaryToggleTest() {
        //Given
        setupDataManual();
        NameTriggerHandler.maintainUserPrimary = false; 

        nameRecord = new Name__c();
        nameRecord.Contact__c = contactRecord.Id;
        nameRecord.First_Name__c = 'testFirstName';
        nameRecord.Middle_Name__c = 'testMiddleName';
        nameRecord.Last_Name__c = 'TestLastName';
        nameRecord.Salutation__c = 'Mr.';
        nameRecord.Type__c = 'Common';
        nameRecord.Is_Primary__c = true;
        insert nameRecord;

        Test.startTest();
        //When - New Primary is Inserted
        //Note we loose the original middlename
        Name__c nameNew = new Name__c();
        nameNew.Contact__c = contactRecord.Id;
        nameNew.First_Name__c = 'testFirstNameNew testMiddleNameNew';
        nameNew.Last_Name__c = 'TestLastNameNew';
        nameNew.Salutation__c = 'Mr.';
        nameNew.Is_Primary__c = true;
        nameNew.Type__c = 'Common';
        insert nameNew;
        Test.stopTest();

        //Then - Test if Primary is toggled on the last Primary Record
        Name__c result = [SELECT Is_Primary__c, Is_Active__c FROM Name__c WHERE Id = :nameRecord.Id];
        Assert.isFalse(result.Is_Primary__c, 'Primary should have been set to false');
    }


    /*
     * @Description test the primary flag behaviour
     */
    @isTest
    static void primaryToggleUpdateTest() {
        //Given
        setupDataManual();
        NameTriggerHandler.maintainUserPrimary = false; 
        nameRecord = new Name__c();
        nameRecord.Contact__c = contactRecord.Id;
        nameRecord.First_Name__c = 'testFirstName';
        nameRecord.Middle_Name__c = 'testMiddleName';
        nameRecord.Last_Name__c = 'TestLastName';
        nameRecord.Salutation__c = 'Mr.';
        nameRecord.Type__c = 'Common';
        nameRecord.Is_Primary__c = true;
        insert nameRecord;

        Name__c nameNew = new Name__c();
        nameNew.Contact__c = contactRecord.Id;
        nameNew.First_Name__c = 'testFirstNameNew';
        nameNew.Middle_Name__c = 'testMiddleNameNew';
        nameNew.Last_Name__c = 'TestLastNameNew';
        nameNew.Salutation__c = 'Mr.';
        nameNew.Type__c = 'Common';
        nameNew.Is_Primary__c = false;
        insert nameNew;
        Test.startTest();
        //When - New Primary is Inserted
        nameNew.Is_Primary__c = true;
        update nameNew;
        Test.getEventBus().deliver();
        Test.stopTest();
        //Then - Test if Primary is toggled on the last Primary Record
        Assert.areEqual(1,
                            [SELECT count() FROM Name__c WHERE Id = :nameNew.Id AND Is_Primary__c = true],
                            'Failed to set primary on new Name record');
        //Then - Test if Primary is toggled off on the old name record
        System.Assert.areEqual(1,
                            [SELECT count() FROM Name__c WHERE Id = :nameRecord.Id AND Is_Primary__c = false],
                            'Failed to set primary to false on old Name record');
    }

    /*
     * @Description Primary set by a user won't be overridden by automated process
     */
    @isTest 
    static void testManuallySetPrimary() {
        TriggerCommon.disableTrigger('Contact');
        Contact cont = createContact();
        cont.Is_Student__c = false;
        insert cont;
        TriggerCommon.enableTrigger('Contact');

        NameTriggerHandler.maintainUserPrimary = true; // Feature needs to be enabled - it's off by default

        nameRecord = new Name__c();
        nameRecord.Contact__c = contactRecord.Id;
        nameRecord.First_Name__c = 'Elem';
        nameRecord.Last_Name__c = 'Ayo';
        nameRecord.Salutation__c = 'Mr.';
        nameRecord.Type__c = 'Common';
        nameRecord.Is_Primary__c = true;
        nameRecord.Is_Active__c = true;
        insert nameRecord;

        Test.startTest();
        Name__c sysName = nameRecord.clone();
        sysName.Last_Name__c = 'Paulson';
        sysName.Is_Primary__c = false;
        User automatedUser = [SELECT Id FROM User WHERE Username LIKE :Person360Helper.automatedProcessUserName+'%' LIMIT 1];
        System.runAs(automatedUser) {
            // insert as automated process user
            insert sysName;
        }
        Test.stopTest();

        Name__c[] results = [SELECT Is_Primary__c, Is_Active__c, Primary_set_by__c, CreatedDate FROM Name__c];
        Assert.areEqual(2, results.size());
        for(Name__c n :results) {
            if(n.Id == sysName.Id) {
                System.assertEquals(false, n.Is_Primary__c);
            } else if(n.Id == nameRecord.Id) {
                Assert.isTrue(n.Is_Primary__c);
            } else {
                Assert.isFalse(false, 'Unexpected Name__c record');
            }
        }
    }

    /**
     * @description 
     * GIVEN User create new Name__c record WHERE Start_Date__c > TODAY AND Is_Active__c = TRUE
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    @isTest
    static void toggleIsActive_Scenario1() {
        //Given
        setupDataManual();
        Name__c name01 = new Name__c();
        name01.Contact__c = contactRecord.Id;
        name01.Salutation__c = 'Mr.';
        name01.First_Name__c = 'TestFirstName001';
        name01.Middle_Name__c = 'TestMiddleName001';
        name01.Last_Name__c = 'TestLastName001';
        name01.Type__c = 'Common';
        name01.Start_Date__c = Date.today().addDays(5);
        name01.Is_Active__c = true;

        Test.startTest();
        insert name01;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.isFalse([SELECT Is_Active__c FROM Name__c WHERE Id =: name01.Id].Is_Active__c);
    }
    
    /**
     * @description 
     * GIVEN User create new Name__c record WHERE Start_Date__c = TODAY AND Is_Active__c = FALSE
     * WHEN User click Save
     * THEN set Is_Active__c to TRUE
     */
    @isTest
    static void toggleIsActive_Scenario2() {
        //Given
        setupDataManual();
        Name__c name02 = new Name__c();
        name02.Contact__c = contactRecord.Id;
        name02.Salutation__c = 'Mr.';
        name02.First_Name__c = 'TestFirstName002';
        name02.Middle_Name__c = 'TestMiddleName002';
        name02.Last_Name__c = 'TestLastName002';
        name02.Start_Date__c = Date.today();
        name02.Is_Active__c = false;
		name02.type__c = 'Common';
        
        Test.startTest();
        insert name02;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.isTrue([SELECT Is_Active__c FROM Name__c WHERE Id =: name02.Id].Is_Active__c);
    }
    
    /**
     * @description 
     * GIVEN User create new Name__c record WHERE End_Date__c < TODAY AND Is_Active__c = true
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    @isTest
    static void toggleIsActive_Scenario3() {
        //Given
        setupDataManual();
        Name__c name03 = new Name__c();
        name03.Contact__c = contactRecord.Id;
        name03.Salutation__c = 'Mr.';
        name03.First_Name__c = 'TestFirstName003';
        name03.Middle_Name__c = 'TestMiddleName003';
        name03.Last_Name__c = 'TestLastName003';
        name03.Start_Date__c = Date.today().addDays(-5);
        name03.End_Date__c = Date.today().addDays(-3);
        name03.Is_Active__c = true;
        name03.type__c = 'Common';

        Test.startTest();
        insert name03;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.isFalse([SELECT Is_Active__c FROM Name__c WHERE Id =: name03.Id].Is_Active__c);
    }

    /**
     * @description Is active flag check
	 */
    @isTest
    static void toggleIsActive_Scenario4() {
        //Given
        setupDataManual();
        Name__c name03 = new Name__c();
        name03.Contact__c = contactRecord.Id;
        name03.Salutation__c = 'Mr.';
        name03.First_Name__c = 'TestFirstName003';
        name03.Middle_Name__c = 'TestMiddleName003';
        name03.Last_Name__c = 'TestLastName003';
        name03.Start_Date__c = Date.today().addDays(-5);
        name03.End_Date__c = Date.today().addDays(-3);
        name03.Is_Active__c = true;
        name03.type__c = 'Common';
        insert name03;

        Test.startTest();
        Name__c nameToUpdate = [SELECT Start_Date__c FROM Name__c WHERE Id =: name03.Id];
        nameToUpdate.Start_Date__c = Date.today().addDays(-6);
        update nameToUpdate;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.isFalse([SELECT Is_Active__c FROM Name__c WHERE Id =: name03.Id].Is_Active__c);
    }
    
    /**
     * @description Check primary calculation
	 */
    @isTest
    static void findNewPrimary_Scenario5() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        upsert cs;
        //Given
        setupDataManual();
        Name__c name03 = new Name__c();
        name03.Contact__c = contactRecord.Id;
        name03.Salutation__c = 'Mr.';
        name03.First_Name__c = 'TestFirstName003';
        name03.Middle_Name__c = 'TestMiddleName003';
        name03.Last_Name__c = 'TestLastName003';
        name03.Start_Date__c = Date.today().addDays(-5);
        name03.End_Date__c = Date.today().addDays(-3);
        name03.Is_Active__c = true;
        name03.type__c = 'Common';
        insert name03;

        Test.startTest();
        List<Name__c> names = [SELECT Id FROM Name__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = true];
        Assert.isTrue(names.size() > 0);
        delete names;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Name__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = true], 'Setting new primary failed');
    }
    
    
    /**
     * @description 
     * GIVEN A name record is created
     * WHEN no firstname is supplied
     * THEN the mono name flag is set (note this is not rolled up)
     */
    @isTest
    static void validate_mononame() {
        //Given
        setupDataManual();
        Name__c n = new Name__c();
        n.Contact__c = contactRecord.Id;
        n.Last_Name__c = 'Madonna';
        n.Start_Date__c = Date.today();
        n.Is_Active__c = true;
        n.type__c = 'Common';

        Test.startTest();
        insert n;
        Test.getEventBus().deliver();
        Test.stopTest();

        Name__c[] nl = [SELECT id, Is_Mononymous_Name__c FROM Name__c WHERE Id =:n.Id];
        Assert.areEqual (1,nl.size(),'A mono name record is expected');
        Assert.isTrue (nl[0].Is_Mononymous_Name__c);
    }
    
    /**
     * @description 
     * GIVEN A User login to UniCRM
     * AND search for a contact record
     * AND contact record is not student or a student
     * WHEN new name record inserted manually as primary
     * THEN it will roll up in corresponding name fields
     */
    @isTest
    static void nameRecordTest1() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        setupDataManual();
        NameTriggerHandler.maintainUserPrimary = false; 
        Test.getEventBus().deliver();

        Name__c name = new Name__c();
        name.Contact__c = contactRecord.Id;
        name.Start_Date__c = Date.today();
        name.Is_Primary__c = true;
        name.Is_Active__c = true;
        name.Source__c = 'Undefined';
        name.Salutation__c = 'Mr.';
        name.Type__c = 'Other name';
        name.First_Name__c = 'FName';
        name.Last_Name__c = 'LName';
        name.Middle_Name__c = 'MName';
        name.Prefix__c = 'P';
        name.Suffix__c = 'S';
        name.type__c = 'Common';

        Test.startTest();
        insert name;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,FirstName,LastName FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('FName', con.FirstName, 'Expected FirstName value shoudld be FName');
        Assert.areEqual('LName', con.LastName, 'Expected LastName value should be LName');
    }

    /**
     * @description Set up data manually
     * @return A populated contact record for testing
     */
    private static Contact createContact() {
        contactRecord = new Contact();
        contactRecord.Person_ID_unique__c = '12345';
        contactRecord.Birthdate = Date.today().addYears(- 20);
        contactRecord.Citizenship__c = 'INTERNATIONAL';
        contactRecord.Citizenship_Code__c = '4';
        contactRecord.Residency_Status__c = 'Australian Permanent Resident';
        contactRecord.Email = 'test@test.com';
        contactRecord.Personal_Email__c = 'test@test.com';
        contactRecord.Monash_Email_Address__c = 'test@test.com';
        contactRecord.Business_Email_Address__c = 'test@test.com';
        contactRecord.Title = 'OAM';
        contactRecord.Salutation = 'Mr.';
        contactRecord.FirstName = 'testFirstName';
        contactRecord.MiddleName = 'testMiddleName';
        contactRecord.LastName = 'testLastName';
        contactRecord.Suffix = 'testSuffix';
        contactRecord.Gender__c = 'None';
        contactRecord.Phone = '+61390008000';
        contactRecord.MobilePhone = '+61400111222';
        contactRecord.HomePhone = '+61390008001';
        contactRecord.OtherPhone = '+61390008002';
        contactRecord.AssistantPhone = '+61390008003';
        contactRecord.Fax = '+61390008999';
        contactRecord.MailingStreet = '350 Bourke Street';
        contactRecord.MailingCity = 'Melbourne';
        contactRecord.MailingState = 'Victoria';
        contactRecord.MailingPostalCode = '3000';
        contactRecord.MailingCountry = 'Australia';
        contactRecord.OtherStreet = '111 Bourke Street';
        contactRecord.OtherCity = 'Melbourne';
        contactRecord.OtherState = 'Victoria';
        contactRecord.OtherPostalCode = '3000';
        contactRecord.OtherCountry = 'Australia';
        return contactRecord;
    }

    /**
     * @description Set up data manually
     */
    private static void setupDataManual() {
        contactRecord = createContact();
        insert contactRecord;
        Assert.isNotNull(contactRecord.Id, 'Contact Record Insert Failed');
    }
}