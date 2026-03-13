/**
 * @File Name          : Person360ToggleIsActiveHelper_Test.cls
 * @Description        : Coverage test class for Person360ToggleIsActiveHelper.cls. For actual scenarios refer to EmailTriggerHandler_Test.cls
 * @Author             : Nick Guia
 * @Group              : Test Class
 **/
@isTest(isParallel=true)
private class Person360ToggleIsActiveHelper_Test {

    static Contact contactRecord {get; set;}

    /**
	 * @description Set up Data
	 */
    @testSetup static void setupData(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;
    }

    /**
	 * @description 
	 */
    @isTest
    static void startDateTest() {
        // GIVEN: contact record exists
        setupDataManual();

        // WHEN: email record is inserted
        Email__c email = new Email__c();
        email.Contact__c = contactRecord.Id;
        email.Start_Date__c = Date.today();
        email.Is_Primary__c = true;
        email.Name = 'test@test.com';
        email.Classification__c = 'Private';
        email.Source__c = 'Undefined';

        Test.startTest();
        insert email;
        Test.getEventBus().deliver();
        Triggers.clearAllBypasses();

        email = [select start_date__c from email__c where id = :email.id];
        
        // THEN: start date is correctly set
        Assert.areEqual(Date.today(), email.Start_Date__c, 'Default Start Date Today Failed');
        Test.stopTest();
    }
    
    /**
	 * @description 
	 */
    @isTest
    static void afterUpdateTest() {
        // GIVEN: contact record exists
        setupDataManual();

        // GIVEN: email exists for the contact
        Email__c email = new Email__c();
        email.Contact__c = contactRecord.Id;
        email.Start_Date__c = Date.today();
        email.Is_Primary__c = false;
        email.Name = 'test@test.com';
        email.Classification__c = 'Private';
        email.Source__c = 'Undefined';
		insert email;
        
        // WHEN: email is set to primary
        Test.startTest();
        Triggers.clearAllBypasses();
        email.Is_Primary__c = true;
        update email;
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // THEN: email record should be (only) primary
        Assert.areEqual(1, [SELECT COUNT() FROM Email__c WHERE Is_Primary__c = true], 'One Primary Email per contact failed.');
        
    }
    /**
     * @description
     * GIVEN User create new Email__c record WHERE Start_Date__c > TODAY AND Is_Active__c = TRUE
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    @isTest
    static void toggleIsActive_Scenario1() {
        // GIVEN: contact record
        setupDataManual();
        
        // WHEN: email record is inserted
        Email__c email01 = new Email__c();
        email01.Contact__c = contactRecord.Id;
        email01.Start_Date__c = Date.today().addDays(5);
        email01.End_Date__c = Date.today().addDays(10);
        email01.Is_Primary__c = false;
        email01.Name = 'testemail1@test.com';
        email01.Classification__c = 'Private';
        email01.Source__c = 'Undefined';
        email01.Is_Active__c = true;

        
        Test.startTest();
        insert email01;
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // THEN: email is not marked as active
        email01 = [SELECT Is_Active__c, End_Date__c FROM Email__c WHERE Id =: email01.Id LIMIT 1];
        Assert.areEqual(false, email01.Is_Active__c, 'Email is not set as inactive.');
        Assert.areEqual(Date.today().addDays(10), email01.End_Date__c, 'End date is not set as expected.');
    }
    
    /**
     * @description
     * GIVEN User create new Email__c record WHERE Start_Date__c = TODAY AND Is_Active__c = FALSE
     * WHEN User click Save
     * THEN set Is_Active__c to TRUE
     */
    @isTest
    static void toggleIsActive_Scenario2() {
        // GIVEN: contact record
        setupDataManual();
        
        // WHEN: email record is inserted
        Email__c email02 = new Email__c();
        email02.Contact__c = contactRecord.Id;
        email02.Start_Date__c = Date.today();
        email02.Is_Primary__c = false;
        email02.Name = 'testemail2@test.com';
        email02.Classification__c = 'Private';
        email02.Source__c = 'Undefined';
        email02.Is_Active__c = false;

        Test.startTest();
        insert email02;
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // THEN: email is marked as active
        Assert.areEqual(true, [SELECT Is_Active__c FROM Email__c WHERE Id =: email02.Id].Is_Active__c);
    }
    
    /**
     * @description
     * GIVEN User create new Email__c record WHERE End_Date__c < TODAY AND Is_Active__c = true
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    @isTest
    static void toggleIsActive_Scenario3() {
        // GIVEN: contact record
        setupDataManual();
        
        // WHEN: email record is inserted
        Email__c email03 = new Email__c();
        email03.Contact__c = contactRecord.Id;
        email03.Start_Date__c = Date.today().addDays(-5);
        email03.End_Date__c = Date.today().addDays(-3);
        email03.Is_Primary__c = false;
        email03.Name = 'testemail3@test.com';
        email03.Classification__c = 'Private';
        email03.Source__c = 'Undefined';
        email03.Is_Active__c = true;

        Test.startTest();
        insert email03;
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // THEN: email is not active (anymore)
        Assert.areEqual(false, [SELECT Is_Active__c FROM Email__c WHERE Id =: email03.Id].Is_Active__c);
    }
    
    /**
     * @description
     * GIVEN User create new Email__c record WHERE Start_Date__c < TODAY (and changed) AND End_Date__c < TODAY AND Is_Active__c = true
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    @isTest
    static void toggleIsActive_Scenario4() {
        // GIVEN: contact record
        setupDataManual();
        
        // GIVEN: email record is marked as active
        Email__c email04 = new Email__c();
        email04.Contact__c = contactRecord.Id;
        email04.Start_Date__c = Date.today().addDays(-5);
        email04.End_Date__c = Date.today().addDays(-3);
        email04.Is_Primary__c = false;
        email04.Name = 'testemail3@test.com';
        email04.Classification__c = 'Private';
        email04.Source__c = 'Undefined';
        email04.Is_Active__c = true;
        insert email04;

        // WHEN: email record is updated
        Test.startTest();
        Email__c emailToUpdate = [SELECT Start_Date__c FROM Email__c WHERE Id =: email04.Id];
        emailToUpdate.Start_Date__c = Date.today().addDays(-6);
        update emailToUpdate;
        Test.getEventBus().deliver();
        Test.stopTest();

        // THEN: email is not active (anymore)
        Assert.areEqual(false, [SELECT Is_Active__c FROM Email__c WHERE Id =: email04.Id].Is_Active__c);
    }
    
    /**
     * @description
     * GIVEN User create new Email__c record WHERE Is_Deleted__c = true AND Is_Active__c = true
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    @isTest
    static void toggleIsActive_Scenario5() {
        // GIVEN: contact record
        setupDataManual();
        
        // WHEN: email record is inserted
        Email__c email05 = new Email__c();
        email05.Is_Active__c = true;
        email05.Is_Deleted__c = true;
        email05.Contact__c = contactRecord.Id;
        email05.Start_Date__c = Date.today().addDays(-5);
        email05.Is_Primary__c = false;
        email05.Name = 'testemail3@test.com';
        email05.Classification__c = 'Private';
        email05.Source__c = 'Undefined';
        
        Test.startTest();
        insert email05;
        Test.stopTest();
        
        // THEN: email is not active (anymore)
        email05 = [SELECT Is_Active__c, End_Date__c FROM Email__c WHERE Id =: email05.Id LIMIT 1];
        Assert.areEqual(false, email05.Is_Active__c, 'Email record was not set to inactive.');
    }
    
    /**
     * @description
     * GIVEN User create new Email__c record WHERE Unreachable__c = true AND Is_Active__c = true
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    @isTest
    static void toggleIsActive_Scenario6() {
        // GIVEN: contact record
        setupDataManual();
        
        // WHEN: email record is inserted
        Email__c email06 = new Email__c();
        email06.Is_Active__c = true;
        email06.Unreachable__c = true;
        email06.Unreachable_Reason__c = 'Other'; // required as per validation rule
        email06.Contact__c = contactRecord.Id;
        email06.Start_Date__c = Date.today().addDays(-5);
        email06.End_Date__c = Date.today().addDays(10);
        email06.Is_Primary__c = false;
        email06.Name = 'testemail3@test.com';
        email06.Classification__c = 'Private';
        email06.Source__c = 'Undefined';
        
        Test.startTest();
        insert email06;
        Test.stopTest();
        
        // THEN: email is not active (anymore)
        email06 = [SELECT Is_Active__c, End_Date__c FROM Email__c WHERE Id =: email06.Id LIMIT 1];
        Assert.areEqual(false, email06.Is_Active__c, 'Email record was not set to inactive.');
    }
    
    /**
     * @description
     */
    @isTest
    static void toggleIsActive_Scenario7() {
        // GIVEN: contact record
        setupDataManual();
        
        // GIVEN: an email is created
        Email__c email07 = new Email__c();
        email07.Contact__c = contactRecord.Id;
        email07.Is_Primary__c = true;
        email07.Name = 'testemail7@test.com';
        email07.Classification__c = 'Private';
        email07.Source__c = 'Undefined';
        insert email07;

		// WHEN: It is manually set to inactive        
        Test.startTest();
        email07.Is_Active__c = false;
        update email07;
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // THEN: email has an end date added
        email07 = [SELECT Is_Active__c, End_Date__c FROM Email__c WHERE Id =: email07.Id LIMIT 1];
        Assert.areEqual(date.today(), email07.end_date__c);
        Assert.isFalse(email07.Is_Active__c);
    }
    
    /**
     * @description
     */
    @isTest
    static void  findNewPrimary_Scenario1() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        upsert cs;
        //Given
        setupDataManual();
        Email__c email = new Email__c();
        email.Contact__c = contactRecord.Id;
        email.Start_Date__c = Date.today();
        email.Is_Primary__c = true;
        email.Name = 'test2@test.com';
        email.Classification__c = 'Private';
        email.Source__c = 'Undefined';

        insert email;

        Test.startTest();
        
        delete email;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Email__c WHERE Contact__r.Id =: contactRecord.Id AND Is_Primary__c = true], 'Setting new primary failed');
    }
    
    /**
     * @description
     * GIVEN A User login to UniCRM
     * AND search for a contact record
     * AND contact record is not student
     * WHEN new email record inserted manually as primary
     * THEN it will roll up in corresponding email fields
     */
    @isTest
    static void emailRecordTest1() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        setupDataManual();
        Email__c email = new Email__c();
        email.Contact__c = contactRecord.Id;
        email.Start_Date__c = Date.today();
        email.Is_Primary__c = true;
        email.Name = 'test@personal2.com';
        email.Classification__c = 'Private';
        email.Source__c = 'Undefined';
        Test.startTest();
        insert email;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Personal_Email__c,Email,Monash_Email_Address__c,Business_Email_Address__c FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('test@personal2.com', con.Personal_Email__c, 'Expected Personal_Email__c value shoudld be test@personal2.com');
        Assert.areEqual('test@personal2.com', con.Email, 'Expected Email value shoudld be test@personal2.com as it is the latest greatest');
        Assert.areEqual('test@monash.edu', con.Monash_Email_Address__c, 'Expected Monash_Email_Address__c value shoudld be test@monash.edu');
        Assert.areEqual('test@business.com', con.Business_Email_Address__c, 'Expected Business_Email_Address__c value shoudld be test@business.com');
    }

    /**
     * @description Additional data set up
     */
    private static void setupDataManual() {
        contactRecord = new Contact();
        contactRecord.Person_ID_unique__c = '12345';
        contactRecord.Birthdate = Date.today().addYears(- 20);
        contactRecord.Citizenship__c = 'INTERNATIONAL';
        contactRecord.Citizenship_Code__c = '4';
        contactRecord.Residency_Status__c = 'Australian Permanent Resident';
        contactRecord.Email = 'test@personal1.com';
        contactRecord.Personal_Email__c = 'test@personal1.com';
        contactRecord.Monash_Email_Address__c = 'test@monash.edu';
        contactRecord.Business_Email_Address__c = 'test@business.com';
        contactRecord.Salutation = 'Mr.';
        /*contactRecord.Title*/
        contactRecord.FirstName = 'testFirstName';
        contactRecord.LastName = 'testLastName';
        contactRecord.Gender__c = 'None';
        contactRecord.Phone = '+61390008000';
        contactRecord.MobilePhone = '+61400111222';
        contactRecord.HomePhone = '+61390008001';
        contactRecord.OtherPhone = '+61390008002';
        contactRecord.AssistantPhone = '+61390008003';
        contactRecord.Fax = '+61390008999';
        insert contactRecord;
        Assert.isNotNull(contactRecord.Id, 'Contact Record Insert Failed');
    }
}