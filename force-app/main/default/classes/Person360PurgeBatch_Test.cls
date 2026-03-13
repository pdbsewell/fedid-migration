/**
 * @description     Test class for Person360PurgeBatch.cls
 * @author          J.Mapanao
 * @date            20.APR.2020
 * 
 * @revision
 *                  20.APR.2020 - J.Mapanao - Initial Created
 */
@isTest(isParallel=false) // due to schedule evaluations
private class Person360PurgeBatch_Test {

    @testSetup static void setupData() {
        //Enable Roll up / down and break up
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.EnableChannelBreakUp__c = false;
        upsert cs;
    }

    static testMethod void testDeleteContact() {
        List<Contact> contactList = new List<Contact>();

        // Create test contact data
        for(Integer i = 0 ; i < 25 ; i++) {
            Contact tempContact = createContactStub();
            tempContact.FirstName = 'TestFirstName' + i;
            tempContact.MiddleName = 'TestMiddleName' + i;
            tempContact.LastName = 'TestLastName' + i;
            tempContact.Person_ID_unique__c = 'UniquePID' + i;
            contactList.add(tempContact);
        }
        insert contactList;
        List<Contact> queryAllContacts = [
            SELECT Id, FirstName, MiddleName, LastName,
                    (SELECT Id FROM Addresses__r),
                    (SELECT Id FROM Phones__r),
                    (SELECT Id FROM Emails__r)
            FROM Contact
            WHERE Id IN: contactList
        ];
        for (Contact con : queryAllContacts) {
            System.assertNotEquals(null, con.Addresses__r);
            System.assertNotEquals(null, con.Phones__r);
            System.assertNotEquals(null, con.Emails__r);
        }

        // Update some of the test contact data
        // and set Deleted_In_Source__c = true
        List<Contact> contactsToDeleteByBatch = new List<Contact>();
        for (Integer i = 7 ; i < 15 ; i++) {
            Contact tempContact = new Contact(
                Id = queryAllContacts[i].Id,
                Deleted_In_Source__c = true
            );
            contactsToDeleteByBatch.add(tempContact);
        }
        update contactsToDeleteByBatch;
        Test.startTest();
        Database.executeBatch(new Person360PurgeBatch());
        Test.stopTest();
        
        LogUtilityException.debug('Person360PurgeBatch finished.');
        List<Contact> contactsLeft = [SELECT Id FROM Contact];
        System.assertEquals(17, contactsLeft.size(), 'ERROR... Some of the contacts not been deleted.');
    }

    /**
     * Make sure the Person360PurgeBatch.cls batch apex will pick up
     * and delete all Address__c records WHERE Is_Deleted__c = true
     */
    static testMethod void testDeleteAddress() {
        List<Contact> contactList = new List<Contact>();

        // Create test data for contact records and its contact points
        // like Address, Email, and Phone (via contact trigger rolldown)
        for(Integer i = 0 ; i < 15 ; i++) {
            Contact tempContact = createContactStub();
            tempContact.FirstName = 'TestFirstName' + i;
            tempContact.MiddleName = 'TestMiddleName' + i;
            tempContact.LastName = 'TestLastName' + i;
            tempContact.Person_ID_unique__c = 'UniquePID' + i;
            contactList.add(tempContact);
        }
        insert contactList;
        List<Contact> queryAllContacts = [
            SELECT Id, FirstName, MiddleName, LastName,
                    (SELECT Id FROM Addresses__r),
                    (SELECT Id FROM Phones__r),
                    (SELECT Id FROM Emails__r)
            FROM Contact
            WHERE Id IN: contactList
        ];
        for (Contact con : queryAllContacts) {
            System.assertNotEquals(null, con.Addresses__r);
            System.assertNotEquals(null, con.Phones__r);
            System.assertNotEquals(null, con.Emails__r);
        }

        // Create test data of Channel
        List<Channel__c> channels = new List<Channel__c>();
        for (Contact con : queryAllContacts) {
            channels.add(
                new Channel__c(
                    City__c = 'Melbourne',
                    Country__c = 'Australia',
                    Deleted_In_Source__c = true,
                    Email__c = 'ptest@monash.edu.test',
                    Is_Processed__c = false,
                    Mobile_Phone__c = '0456787652',
                    Phone_2__c = '0456787652',
                    Phone__c = '0456787652',
                    Post_Code__c = '3000',
                    Start_Date__c = Date.today().addDays(-150),
                    State__c = 'VIC',
                    Street__c = '1 Collins Street',
                    Type__c = 'HOME',
                    Contact__c = con.Id
                )
            );
        }
        insert channels;

        List<Address__c> addressList = new List<Address__c>();
        for (Channel__c channel : channels) {
            addressList.add(
                new Address__c(
                    Contact__c = channel.Contact__c,
                    Street_Name__c = channel.Street__c,
                    City__c = channel.City__c,
                    State__c = channel.State__c,
                    Post_Code__c = channel.Post_Code__c,
                    Country2__c = channel.Country__c,
                    Start_Date__c = channel.Start_Date__c,
                    End_Date__c = null,
                    Is_Active__c = false,
                    Is_Primary__c = false,
                    Classification__c = 'Private',
                    Source__c = 'Undefined',
                    Is_Deleted__c = true,
                    Channel__c = channel.Id
                )
            );
        }
        TriggerCommon.disableTrigger('Address__c');
        insert addressList;
        TriggerCommon.enableTrigger('Address__c');

        Test.startTest();
        Database.executeBatch(new Person360PurgeBatch(1));
        Test.stopTest();
        List<Address__c> checkAddressList = [SELECT Id FROM Address__c WHERE Is_Deleted__c = true];
        System.assertEquals(0, checkAddressList.size(), 'ERROR... Addresses where Is_Deleted__c = true not deleted.');
    }

    /**
     * Make sure the Person360PurgeBatch.cls batch apex will pick up
     * and delete all Phone__c records WHERE Is_Deleted__c = true
     */
    static testMethod void testDeletePhone() {
        List<Contact> contactList = new List<Contact>();

        // Create test data for contact records and its contact points
        // like Address, Email, and Phone (via contact trigger rolldown)
        for(Integer i = 0 ; i < 15 ; i++) {
            Contact tempContact = createContactStub();
            tempContact.FirstName = 'TestFirstName' + i;
            tempContact.MiddleName = 'TestMiddleName' + i;
            tempContact.LastName = 'TestLastName' + i;
            tempContact.Person_ID_unique__c = 'UniquePID' + i;
            contactList.add(tempContact);
        }
        insert contactList;
        List<Contact> queryAllContacts = [
            SELECT Id, FirstName, MiddleName, LastName,
                    (SELECT Id FROM Addresses__r),
                    (SELECT Id FROM Phones__r),
                    (SELECT Id FROM Emails__r)
            FROM Contact
            WHERE Id IN: contactList
        ];
        for (Contact con : queryAllContacts) {
            System.assertNotEquals(null, con.Addresses__r);
            System.assertNotEquals(null, con.Phones__r);
            System.assertNotEquals(null, con.Emails__r);
        }

        // Create test data of Channel
        List<Channel__c> channels = new List<Channel__c>();
        for (Contact con : queryAllContacts) {
            channels.add(
                new Channel__c(
                    City__c = 'Melbourne',
                    Country__c = 'Australia',
                    Deleted_In_Source__c = true,
                    Email__c = 'ptest@monash.edu.test',
                    Is_Processed__c = false,
                    Mobile_Phone__c = '0456787652',
                    Phone_2__c = '0456787652',
                    Phone__c = '0456787652',
                    Post_Code__c = '3000',
                    Start_Date__c = Date.today().addDays(-150),
                    State__c = 'VIC',
                    Street__c = '1 Collins Street',
                    Type__c = 'HOME',
                    Contact__c = con.Id
                )
            );
        }
        insert channels;

        List<Phone__c> phoneList = new List<Phone__c>();
        for (Channel__c channel : channels) {
            phoneList.add(
                new Phone__c(
                    Name = String.valueOf(channel.Mobile_Phone__c),
                    Contact__c = channel.Contact__c,
                    Start_Date__c = channel.Start_Date__c,
                    End_Date__c = null,
                    Classification__c = 'Private',
                    Source__c = 'Undefined',
                    Is_Primary__c = false,
                    Is_Active__c = false,
                    Is_Deleted__c = true,
                    Channel__c = channel.Id
                )
            );
        }
        TriggerCommon.disableTrigger('Phone__c');
        insert phoneList;
        TriggerCommon.enableTrigger('Phone__c');

        Test.startTest();
        Database.executeBatch(new Person360PurgeBatch(2));
        Test.stopTest();
        List<Phone__c> checkPhoneList = [SELECT Id FROM Phone__c WHERE Is_Deleted__c = true];
        System.assertEquals(0, checkPhoneList.size(), 'ERROR... Phones where Is_Deleted__c = true not deleted.');
    }

    /**
     * Make sure the Person360PurgeBatch.cls batch apex will pick up
     * and delete all Email__c records WHERE Is_Deleted__c = true
     */
    static testMethod void testDeleteEmail() {
        List<Contact> contactList = new List<Contact>();

        // Create test data for contact records and its contact points
        // like Address, Email, and Phone (via contact trigger rolldown)
        for(Integer i = 0 ; i < 15 ; i++) {
            Contact tempContact = createContactStub();
            tempContact.FirstName = 'TestFirstName' + i;
            tempContact.MiddleName = 'TestMiddleName' + i;
            tempContact.LastName = 'TestLastName' + i;
            tempContact.Person_ID_unique__c = 'UniquePID' + i;
            contactList.add(tempContact);
        }
        insert contactList;
        List<Contact> queryAllContacts = [
            SELECT Id, FirstName, MiddleName, LastName,
                    (SELECT Id FROM Addresses__r),
                    (SELECT Id FROM Phones__r),
                    (SELECT Id FROM Emails__r)
            FROM Contact
            WHERE Id IN: contactList
        ];
        for (Contact con : queryAllContacts) {
            System.assertNotEquals(null, con.Addresses__r);
            System.assertNotEquals(null, con.Phones__r);
            System.assertNotEquals(null, con.Emails__r);
        }

        // Create test data of Channel
        List<Channel__c> channels = new List<Channel__c>();
        for (Contact con : queryAllContacts) {
            channels.add(
                new Channel__c(
                    City__c = 'Melbourne',
                    Country__c = 'Australia',
                    Deleted_In_Source__c = true,
                    Email__c = 'ptest@monash.edu.test',
                    Is_Processed__c = false,
                    Mobile_Phone__c = '0456787652',
                    Phone_2__c = '0456787652',
                    Phone__c = '0456787652',
                    Post_Code__c = '3000',
                    Start_Date__c = Date.today().addDays(-150),
                    State__c = 'VIC',
                    Street__c = '1 Collins Street',
                    Type__c = 'HOME',
                    Contact__c = con.Id
                )
            );
        }
        insert channels;

        List<Email__c> emailList = new List<Email__c>();
        for (Channel__c channel : channels) {
            emailList.add(
                new Email__c(
                    Name = channel.Email__c,
                    Contact__c = channel.Contact__c,
                    Start_Date__c = channel.Start_Date__c,
                    End_Date__c = null,
                    Classification__c = 'Private',
                    Source__c = 'Undefined',
                    Is_Primary__c = false,
                    Is_Active__c = false,
                    Is_Deleted__c = true,
                    Channel__c = channel.Id
                )
            );
        }
        TriggerCommon.disableTrigger('Email__c');
        insert emailList;
        TriggerCommon.enableTrigger('Email__c');

        Test.startTest();
        Database.executeBatch(new Person360PurgeBatch(3));
        Test.stopTest();
        List<Email__c> checkEmailList = [SELECT Id FROM Email__c WHERE Is_Deleted__c = true];
        System.assertEquals(0, checkEmailList.size(), 'ERROR... Emails where Is_Deleted__c = true not deleted.');
    }

    static testmethod void testPerson360Purge_ScheduleAndUnSchedule() {
        Person360PurgeBatch myBatch = new Person360PurgeBatch();
        myBatch.schedule();
        Test.StartTest();
        myBatch.unschedule();
        Test.stopTest();
    }

    /**
     * Set up data manually
     */
    private static Contact createContactStub() {

        Contact temp_Contact = new Contact();
        temp_Contact.Birthdate = Date.today().addYears(- 20);
        temp_Contact.Citizenship__c = 'INTERNATIONAL';
        temp_Contact.Citizenship_Code__c = '4';
        temp_Contact.Residency_Status__c = 'Australian Permanent Resident';
        temp_Contact.Email = 'test@test.com';
        temp_Contact.Personal_Email__c = 'test@test.com';
        temp_Contact.Monash_Email_Address__c = 'test@test.com';
        temp_Contact.Business_Email_Address__c = 'test@test.com';
        temp_Contact.Title = 'OAM';
        temp_Contact.Salutation = 'Mr.';
        temp_Contact.FirstName = 'testFirstName';
        temp_Contact.MiddleName = 'testMiddleName';
        temp_Contact.LastName = 'testLastName';
        temp_Contact.Suffix = 'testSuffix';
        temp_Contact.Gender__c = 'None';
        temp_Contact.Phone = '+61390008000';
        temp_Contact.MobilePhone = '+61400111222';
        temp_Contact.HomePhone = '+61390008001';
        temp_Contact.OtherPhone = '+61390008002';
        temp_Contact.AssistantPhone = '+61390008003';
        temp_Contact.Fax = '+61390008999';
        temp_Contact.MailingStreet = '350 Bourke Street';
        temp_Contact.MailingCity = 'Melbourne';
        temp_Contact.MailingState = 'Victoria';
        temp_Contact.MailingPostalCode = '3000';
        temp_Contact.MailingCountry = 'Australia';
        temp_Contact.OtherStreet = '111 Bourke Street';
        temp_Contact.OtherCity = 'Melbourne';
        temp_Contact.OtherState = 'Victoria';
        temp_Contact.OtherPostalCode = '3000';
        temp_Contact.OtherCountry = 'Australia';

        return temp_Contact;
    }
}