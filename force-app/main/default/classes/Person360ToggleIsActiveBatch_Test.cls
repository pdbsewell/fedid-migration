/**
 * @description     Test class for Person360ToggleIsActiveBatch.cls
 * @author          
 * @date            <unknown>
 * 
 * @revision
 *                  21.APR.2020 - J.Mapanao - Update the failing test methods
 */
@isTest(isParallel=false)
private class Person360ToggleIsActiveBatch_Test {
    static Contact contactRecord {get; set;}

    @testSetup static void setupDataCS() {
        //Set up Custom Setting
        Environment_Settings__c cs = new Environment_Settings__c();
        cs.Contact_Merge_Max_Rerun__c = 1;
        cs.Contact_Merge_Max_Records__c = 200;
        cs.Contact_Merge_Job_Name__c = 'Contact Perfect%';
        cs.Batch_Size__c = 200;
        cs.Person360IsActiveClause__c = 'WHERE ((Start_Date__c = TODAY AND Is_Active__c = false) OR (Start_Date__c > TODAY AND Is_Active__c = true) OR (End_Date__c < TODAY AND Is_Active__c = true)) LIMIT 10000';
        cs.SetupOwnerId = UserInfo.getOrganizationId();
        insert cs;
    }

    static testMethod void batchTest_Address() {
        setupDataManual();
        List<Address__c> addresses = new List<Address__c>();
        
        // A Contact Point with an end date < today is to be set as inactive
        Address__c address01 = new Address__c();
        address01.Contact__c = contactRecord.Id;
        address01.Street_Name__c = 'Test Street Name 001';
        address01.City__c = 'Melbourne 001';
        address01.State__c = 'Victoria';
        address01.Post_Code__c = '3000';
        address01.Country2__c = 'Australia';
        address01.Start_Date__c = Date.today().addDays(-50);
        address01.End_Date__c = Date.today().addDays(-20);
        address01.Is_Active__c = true;
        address01.Classification__c = 'Private';
        address01.Is_Deleted__c = false;
        addresses.add(address01);
        
        // A Contact Point record with an start date < today AND a missing (or future) end date is to be set as active
        Address__c address02 = new Address__c();
        address02.Contact__c = contactRecord.Id;
        address02.Street_Name__c = 'Test Street Name 002';
        address02.City__c = 'Melbourne 002';
        address02.State__c = 'Victoria';
        address02.Post_Code__c = '3000';
        address02.Country2__c = 'Australia';
        address02.Start_Date__c = Date.today().addDays(-50);
        address02.End_Date__c = null;
        address02.Is_Active__c = false;
        address02.Classification__c = 'Private';
        address02.Is_Deleted__c = false;
        addresses.add(address02);

        // A Contact Point with an end date < today is to be set as inactive
        // but Is_Deleted__c = true
        // then batch job should not pick this and Is_Active__c should remain
        // as Person360PurgeBatch.cls will handle all records where Is_Deleted__c = true
        Address__c address03 = new Address__c();
        address03.Contact__c = contactRecord.Id;
        address03.Street_Name__c = 'Test Street Name 001';
        address03.City__c = 'Melbourne 001';
        address03.State__c = 'Victoria';
        address03.Post_Code__c = '3000';
        address03.Country2__c = 'Australia';
        address03.Start_Date__c = Date.today().addDays(-50);
        address03.End_Date__c = Date.today().addDays(-20);
        address03.Is_Active__c = true;
        address03.Classification__c = 'Private';
        address03.Is_Deleted__c = true;
        addresses.add(address03);

        TriggerCommon.disableTrigger('Address__c');
        insert addresses;
        TriggerCommon.enableTrigger('Address__c');
        
        Test.startTest();
        // Execute Batch
        Database.executeBatch(new Person360ToggleIsActiveBatch());
        Test.stopTest();

        System.assertEquals(false, [SELECT Is_Active__c FROM Address__c WHERE Id =: address01.Id].Is_Active__c);
        System.assertEquals(true, [SELECT Is_Active__c FROM Address__c WHERE Id =: address02.Id].Is_Active__c);
        System.assertEquals(true, [SELECT Is_Active__c FROM Address__c WHERE Id =: address03.Id].Is_Active__c);
    }

    static testMethod void batchTest_Email() {
        setupDataManual();
        List<Email__c> emails = new List<Email__c>();
        
        //A Contact Point with an end date < today is to be set as inactive
        Email__c email01 = new Email__c();
        email01.Contact__c = contactRecord.Id;
        email01.Start_Date__c = Date.today().addDays(-50);
        email01.End_Date__c = Date.today().addDays(-30);
        email01.Is_Primary__c = false;
        email01.Name = 'testemail1@test.com';
        email01.Classification__c = 'Private';
        email01.Source__c = 'Undefined';
        email01.Is_Active__c = true;
        email01.Is_Deleted__c = false;
        emails.add(email01);

        // A Contact Point record with an start date < today AND a missing (or future) end date is to be set as active
        Email__c email02 = new Email__c();
        email02.Contact__c = contactRecord.Id;
        email02.Start_Date__c = Date.today().addDays(-50);
        email02.End_Date__c = null;
        email02.Is_Primary__c = false;
        email02.Name = 'testemail2@test.com';
        email02.Classification__c = 'Private';
        email02.Source__c = 'Undefined';
        email02.Is_Active__c = false;
        email02.Is_Deleted__c = false;
        emails.add(email02);

        // A Contact Point with an end date < today is to be set as inactive
        // but Is_Deleted__c = true
        // then batch job should not pick this and Is_Active__c should remain
        // as Person360PurgeBatch.cls will handle all records where Is_Deleted__c = true
        Email__c email03 = new Email__c();
        email03.Contact__c = contactRecord.Id;
        email03.Start_Date__c = Date.today().addDays(-50);
        email03.End_Date__c = Date.today().addDays(-30);
        email03.Is_Primary__c = false;
        email03.Name = 'testemail3@test.com';
        email03.Classification__c = 'Private';
        email03.Source__c = 'Undefined';
        email03.Is_Active__c = true;
        email03.Is_Deleted__c = true;
        emails.add(email03);
        
        Test.startTest();
        TriggerCommon.disableTrigger('Email__c');
        insert emails;
        TriggerCommon.enableTrigger('Email__c');
        
        // Execute Batch
        Database.executeBatch(new Person360ToggleIsActiveBatch());
        Test.stopTest();
        
        System.assertEquals(false, [SELECT Is_Active__c FROM Email__c WHERE Id =: email01.Id].Is_Active__c);
        System.assertEquals(true, [SELECT Is_Active__c FROM Email__c WHERE Id =: email02.Id].Is_Active__c);
        System.assertEquals(true, [SELECT Is_Active__c FROM Email__c WHERE Id =: email03.Id].Is_Active__c);
    }

    static testMethod void batchTest_Name() {
        setupDataManual();
        List<Name__c> names = new List<Name__c>();
        
        //A Contact Point with an end date < today is to be set as inactive
        Name__c name01 = new Name__c();
        name01.Contact__c = contactRecord.Id;
        name01.Salutation__c = 'Mr.';
        name01.First_Name__c = 'TestFirstName001';
        name01.Middle_Name__c = 'TestMiddleName001';
        name01.Last_Name__c = 'TestLastName001';
        name01.Start_Date__c = Date.today().addDays(-50);
        name01.End_Date__c = Date.today().addDays(-30);
        name01.Is_Active__c = true;
        names.add(name01);

        // A Contact Point record with an start date < today AND a missing (or future) end date is to be set as active
        Name__c name02 = new Name__c();
        name02.Contact__c = contactRecord.Id;
        name02.Salutation__c = 'Mr.';
        name02.First_Name__c = 'TestFirstName002';
        name02.Middle_Name__c = 'TestMiddleName002';
        name02.Last_Name__c = 'TestLastName002';
        name02.Start_Date__c = Date.today().addDays(-50);
        name02.End_Date__c = null;
        name02.Is_Active__c = false;
        names.add(name02);
        
        Test.startTest();
        TriggerCommon.disableTrigger('Name__c');
        insert names;
        TriggerCommon.enableTrigger('Name__c');
        
        // Execute Batch
        Database.executeBatch(new Person360ToggleIsActiveBatch());
        Test.stopTest();

        System.assertEquals(false, [SELECT Is_Active__c FROM Name__c WHERE Id =: name01.Id].Is_Active__c);
        System.assertEquals(true, [SELECT Is_Active__c FROM Name__c WHERE Id =: name02.Id].Is_Active__c);
    }

    static testMethod void batchTest_Phone() {
        setupDataManual();
        List<Phone__c> phones = new List<Phone__c>();
        
        //A Contact Point with an end date < today is to be set as inactive
        Phone__c phone01 = new Phone__c(
            Name = '+61390008977',
            Contact__c = contactRecord.Id,
            Start_Date__c = Date.today().addDays(-50),
            End_Date__c =  Date.today().addDays(-30),
            Classification__c = 'Private',
            Source__c = 'Undefined',
            Is_Primary__c = false,
            Is_Active__c = true,
            Is_Deleted__c = false
        );
        phones.add(phone01);

        // A Contact Point record with an start date < today AND a missing (or future) end date is to be set as active
        Phone__c phone02 = new Phone__c(
            Name = '+61390008988',
            Contact__c = contactRecord.Id,
            Start_Date__c = Date.today().addDays(-50),
            End_Date__c = null,
            Classification__c = 'Private',
            Source__c = 'Undefined',
            Is_Primary__c = false,
            Is_Active__c = false,
            Is_Deleted__c = false
        );
        phones.add(phone02);

        // A Contact Point with an end date < today is to be set as inactive
        // but Is_Deleted__c = true
        // then batch job should not pick this and Is_Active__c should remain
        // as Person360PurgeBatch.cls will handle all records where Is_Deleted__c = true
        Phone__c phone03 = new Phone__c(
            Name = '+61390008999',
            Contact__c = contactRecord.Id,
            Start_Date__c = Date.today().addDays(-50),
            End_Date__c =  Date.today().addDays(-30),
            Classification__c = 'Private',
            Source__c = 'Undefined',
            Is_Primary__c = false,
            Is_Active__c = true,
            Is_Deleted__c = true
        );
        phones.add(phone03);
        
        Test.startTest();
        TriggerCommon.disableTrigger('Phone__c');
        insert phones;
        TriggerCommon.enableTrigger('Phone__c');
        
        // Execute Batch
        Database.executeBatch(new Person360ToggleIsActiveBatch());
        Test.stopTest();

        System.assertEquals(false, [SELECT Is_Active__c FROM Phone__c WHERE Id =: phone01.Id].Is_Active__c);
        System.assertEquals(true, [SELECT Is_Active__c FROM Phone__c WHERE Id =: phone02.Id].Is_Active__c);
        System.assertEquals(true, [SELECT Is_Active__c FROM Phone__c WHERE Id =: phone03.Id].Is_Active__c);
    }

    static testMethod void batchTest_Social() {
        setupDataManual();
        List<Social__c> socials = new List<Social__c>();
        
        //A Contact Point with an end date < today is to be set as inactive
        Social__c social01 = new Social__c(
            Name = 'Facebook 1',
            Type__c = 'Facebook',
            Contact__c = contactRecord.Id,
            Start_Date__c = Date.today().addDays(-50),
            End_Date__c =  Date.today().addDays(-30),
            Classification__c = 'Private',
            Is_Primary__c = false,
            Is_Active__c = true
        );
        socials.add(social01);

        // A Contact Point record with an start date < today AND a missing (or future) end date is to be set as active
        Social__c social02 = new Social__c(
            Name = 'Facebook 2',
            Type__c = 'Facebook',
            Contact__c = contactRecord.Id,
            Start_Date__c = Date.today().addDays(-50),
            End_Date__c =  null,
            Classification__c = 'Private',
            Is_Primary__c = false,
            Is_Active__c = false
        );
        socials.add(social02);
        
        Test.startTest();
        TriggerCommon.disableTrigger('Social__c');
        insert socials;
        TriggerCommon.enableTrigger('Social__c');
        
        // Execute Batch
        Database.executeBatch(new Person360ToggleIsActiveBatch());
        Test.stopTest();

        System.assertEquals(false, [SELECT Is_Active__c FROM Social__c WHERE Id =: social01.Id].Is_Active__c);
        System.assertEquals(true, [SELECT Is_Active__c FROM Social__c WHERE Id =: social02.Id].Is_Active__c);
    }

    static testmethod void testPerson360ToggleIsActiveBatchScheduler() {
        Person360ToggleIsActiveBatch myBatch = new Person360ToggleIsActiveBatch();
        myBatch.schedule();
        Test.StartTest();
        myBatch.unschedule();
        Test.stopTest();
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