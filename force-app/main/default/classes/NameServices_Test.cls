/**
 * @author       Monash University
 * @date         23/01/2020        
 * @description  Sibling test class for NameServices.cls
 * @revision     23.01/2020 - J.Mapanao - Initial Created
 */
@isTest(isParallel=true)
private class NameServices_Test {

    static Contact contactRecord {get; set;}
    static Name__c nameRecord {get; set;}

    @IsTest 
    static void validateFindPrimary() {
        Name__c n1 = new Name__c(First_Name__c='StudentName1',Start_Date__c=Date.today().addDays(-5), Type__c='Student Name');
        Name__c n2 = new Name__c(First_Name__c='CommonName1',Start_Date__c=Date.today().addDays(0), Type__c='Common Name');
        Name__c n3 = new Name__c(First_Name__c='CommonName2',Start_Date__c=Date.today().addDays(-1), Type__c='Common Name');
        Name__c n4 = new Name__c(First_Name__c='StudentName2',Start_Date__c=Date.today().addDays(-3), Type__c='Student Name');
        Name__c[] names = new Name__c[]{n1,n2,n3, n4};

        // Test
        Name__c studentPrimary = NameServices.findPrimary(names, true);
        Name__c commonPrimary = NameServices.findPrimary(names, false);

        // Assert
        Assert.areEqual(n4, studentPrimary, 'most recent student name record should be primary for student');
        Assert.areEqual(n2, commonPrimary, 'most recent record should be primary');
    }

    @isTest
    static void validategenerateKeyUID() {
        setupDataManual();
        Test.startTest();
        String keyUID = NameServices.generateKeyUID(nameRecord);
        
        Set<String> cpKeySet = ContactPointUtility.getContactPointKey(nameRecord);
        String utilityHash = Person360Helper.generatePerson360Key(cpKeySet);
        
        Assert.isTrue(String.isNotBlank(keyUID), 'ERROR: keyUID is blank. NameServices.generateKeyUID did not work!');
        Assert.areEqual(keyUID, utilityHash, 'NameServices and ContactPointUtility should generated the same UID');

        Test.stopTest();
    }

    @isTest
    static void validategenerateFullName() {
        setupDataManual();
        Test.startTest();
        String fullName = NameServices.generateFullName(nameRecord);
        Assert.isTrue(String.isNotBlank(fullName), 'ERROR: keyUID is blank. NameServices.generateFullName did not work!');
        Test.stopTest();
    }

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

        nameRecord = new Name__c(
            Contact__c = contactRecord.Id,
            First_Name__c = 'testFirstName',
            Middle_Name__c = 'testMiddleName',
            Last_Name__c = 'TestLastName',
            Salutation__c = 'Mr',
            Type__c = 'Common'
        );
        insert nameRecord;
        Assert.isNotNull(nameRecord.Id, 'Name Record Insert Failed');
    }
}