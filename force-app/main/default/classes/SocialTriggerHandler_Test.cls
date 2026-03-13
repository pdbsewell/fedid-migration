@isTest(isParallel=true)
private class SocialTriggerHandler_Test {
    static Contact contactRecord {get; set;}
    static Social__c socialRecord {get;set;}

    static testMethod void primaryToggleTest() {
        //Given
        setupDataManual();
        socialRecord = new Social__c();
        socialRecord.Name = 'Facebook 1';
        socialRecord.Contact__c = contactRecord.Id;
        socialRecord.Classification__c = 'Private';
        socialRecord.Start_Date__c = Date.today();
        socialRecord.Type__c = 'Facebook';
        socialRecord.Is_Primary__c = true;
        insert socialRecord;
        System.assertNotEquals(null, socialRecord.Id, 'Name Record Insert Failed');
        Test.startTest();
        //When - New Primary is Inserted
        Social__c sNew = new Social__c();
        sNew.Name = 'Facebook 2';
        sNew.Contact__c = contactRecord.Id;
        sNew.Classification__c = 'Private';
        sNew.Start_Date__c = Date.today();
        sNew.Type__c = 'Facebook';
        sNew.Is_Primary__c = true;
        insert sNew;
        Test.stopTest();
        //Then - Test if Primary is toggled on the last Primary Record
        System.assertEquals(1,
        [SELECT count() FROM Social__c WHERE Id = :socialRecord.Id AND Is_Primary__c = false],
            'Failed Primary Update');
    }
    static testMethod void primaryToggleUpdateTest() {
        //Given
        setupDataManual();
        socialRecord = new Social__c();
        socialRecord.Name = 'Facebook 1';
        socialRecord.Contact__c = contactRecord.Id;
        socialRecord.Classification__c = 'Private';
        socialRecord.Start_Date__c = Date.today();
        socialRecord.Type__c = 'Facebook';
        socialRecord.Is_Primary__c = true;
        insert socialRecord;
        System.assertNotEquals(null, socialRecord.Id, 'Name Record Insert Failed');
        Social__c sNew = new Social__c();
        sNew.Name = 'Facebook 2';
        sNew.Contact__c = contactRecord.Id;
        sNew.Classification__c = 'Private';
        sNew.Start_Date__c = Date.today();
        sNew.Type__c = 'Facebook';
        sNew.Is_Primary__c = false;
        insert sNew;
        Test.startTest();
        //When - New Primary is Inserted
        sNew.Is_Primary__c = true;
        update sNew;
        Test.stopTest();
        //Then - Test if Primary is toggled on the last Primary Record
        System.assertEquals(1,
        [SELECT count() FROM Social__c WHERE Id = :socialRecord.Id AND Is_Primary__c = false],
            'Failed Primary Update');
    }
    /**
     * GIVEN User create new Social__c record WHERE Start_Date__c > TODAY AND Is_Active__c = TRUE
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    static testMethod void toggleIsActive_Scenario1() {
        //Given
        setupDataManual();
        Social__c sNew = new Social__c();
        sNew.Contact__c = contactRecord.Id;
        sNew.Classification__c = 'Private';
        sNew.Type__c = 'Facebook';
        sNew.Is_Primary__c = false;
        sNew.Start_Date__c = Date.today().addDays(5);
        sNew.Is_Active__c = true;

        Test.startTest();
        insert sNew;
        Test.stopTest();

        System.assertEquals(false, [SELECT Is_Active__c FROM Social__c WHERE Id =: sNew.Id].Is_Active__c);
    }
    /**
     * GIVEN User create new Name__c record WHERE Start_Date__c = TODAY AND Is_Active__c = FALSE
     * WHEN User click Save
     * THEN set Is_Active__c to TRUE
     */
    static testMethod void toggleIsActive_Scenario2() {
        //Given
        setupDataManual();
        Social__c sNew = new Social__c();
        sNew.Contact__c = contactRecord.Id;
        sNew.Classification__c = 'Private';
        sNew.Type__c = 'Facebook';
        sNew.Is_Primary__c = false;
        sNew.Start_Date__c = Date.today();
        sNew.Is_Active__c = false;

        Test.startTest();
        insert sNew;
        Test.stopTest();

        System.assertEquals(true, [SELECT Is_Active__c FROM Social__c WHERE Id =: sNew.Id].Is_Active__c);
    }
    /**
     * GIVEN User create new Name__c record WHERE End_Date__c < TODAY AND Is_Active__c = true
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    static testMethod void toggleIsActive_Scenario3() {
        //Given
        setupDataManual();
        Social__c sNew = new Social__c();
        sNew.Contact__c = contactRecord.Id;
        sNew.Classification__c = 'Private';
        sNew.Type__c = 'Facebook';
        sNew.Is_Primary__c = false;
        sNew.Start_Date__c = Date.today().addDays(-5);
        sNew.End_Date__c = Date.today().addDays(-3);
        sNew.Is_Active__c = false;

        Test.startTest();
        insert sNew;
        Test.stopTest();

        System.assertEquals(false, [SELECT Is_Active__c FROM Social__c WHERE Id =: sNew.Id].Is_Active__c);
    }
    static testMethod void toggleIsActive_Scenario4() {
        //Given
        setupDataManual();
        Social__c sNew = new Social__c();
        sNew.Contact__c = contactRecord.Id;
        sNew.Classification__c = 'Private';
        sNew.Type__c = 'Facebook';
        sNew.Is_Primary__c = false;
        sNew.Start_Date__c = Date.today().addDays(-5);
        sNew.End_Date__c = Date.today().addDays(-3);
        sNew.Is_Active__c = false;
        insert sNew;

        Test.startTest();
        Social__c socialToUpdate = [SELECT Start_Date__c FROM Social__c WHERE Id =: sNew.Id];
        socialToUpdate.Start_Date__c = Date.today().addDays(-6);
        update socialToUpdate;
        Test.stopTest();

        System.assertEquals(false, [SELECT Is_Active__c FROM Social__c WHERE Id =: sNew.Id].Is_Active__c);
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

        insert contactRecord;
        System.assertNotEquals(null, contactRecord.Id, 'Contact Record Insert Failed');
    }
}