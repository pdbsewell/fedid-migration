/**
 * @author      Sachin Shetty
 * @description Test Class for DCAStatsAndMarkProcessBatch
 * @group       Test Class
 * @revision    2024-06-14 - Sachin Shetty - Created
 * 				2024-10-03  Sachin Shetty   -   Update to control number of DRS records queried
**/
@isTest
public with sharing class ContactCopyController_Test {

    @testSetup
    static void setup() {

        Id studentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId();
        Id nonStudentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId();
        Id propectiveStudentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Prospective_Student').getRecordTypeId();
        
        // Primary contact 1
        Contact con1 = new Contact(
                FirstName = 'Firstname',
                LastName = 'Lastname1',
                Email = 'Firstname.Lastname1@email.com',
                Personal_Email__c = 'First1name.Lastname2@email.com',
                MobilePhone = '0423470137',
                RecordTypeId = studentRecordTypeId
        );
        // Duplicate contact 1
        Contact con2 = new Contact(
                FirstName = 'Firstname',
                LastName = 'Lastname1',
                Email = 'Firstname.Lastname1@email.com',
                Personal_Email__c = 'First1name.Lastname1@email.com',
                BirthDate = Date.valueOf('1991-12-12'),
                RecordTypeId = nonStudentRecordTypeId
        );
        // Primary contact 2
        Contact con3 = new Contact(
                FirstName = 'Firstname',
                LastName = 'Lastname2',
                Email = 'Firstname.Lastname2@email.com',
                Personal_Email__c = 'First2name.Lastname2@email.com',
                MobilePhone = '0423470127',
                RecordTypeId = nonStudentRecordTypeId
        );
        // Duplicate contact 2
        Contact con4 = new Contact(
                FirstName = 'Firstname',
                LastName = 'Lastname2',
                Email = 'Firstname.Lastname2@email.com',
                Personal_Email__c = 'First2name.Lastname2@email.com',
                BirthDate = Date.valueOf('1991-11-12'),
                Exclude_From_Merge__c = true,
                RecordTypeId = studentRecordTypeId
        );

        // Primary contact 3
        Contact con5 = new Contact(
                FirstName = 'Firstname',
                LastName = 'Lastname3',
                Email = 'Firstname.Lastname3@email.com',
                Personal_Email__c = 'First3name.Lastname3@email.com',
                MobilePhone = '0423410127',
                Person_ID_unique__c = '12345',
                RecordTypeId = nonStudentRecordTypeId
        );
        // Duplicate contact 3
        Contact con6 = new Contact(
                FirstName = 'Firstname',
                LastName = 'Lastname3',
                Email = 'Firstname.Lastname3@email.com',
                Personal_Email__c = 'First3name.Lastname3@email.com',
                BirthDate = Date.valueOf('1991-11-03'),
                Person_ID_unique__c = '123456',
                RecordTypeId = studentRecordTypeId
        );
        
        // Primary contact 4
        Contact con7 = new Contact(
                FirstName = 'Firstname',
                LastName = 'Lastname4',
                Email = 'Firstname.Lastname4@email.com',
                Personal_Email__c = 'First4name.Lastname4@email.com',
                MobilePhone = '0423410121',
                RecordTypeId = nonStudentRecordTypeId
        );
        // Duplicate contact 4
        Contact con8 = new Contact(
                FirstName = 'Firstname',
                LastName = 'Lastname4',
                Email = 'Firstname.Lastname4@email.com',
                Personal_Email__c = 'First4name.Lastname4@email.com',
                BirthDate = Date.valueOf('1971-11-03'),
                RecordTypeId = studentRecordTypeId
        );
        
        // Primary contact 5
        Contact con9 = new Contact(
                FirstName = 'Firstname',
                LastName = 'Lastname5',
                Email = 'Firstname.Lastname5@email.com',
                Personal_Email__c = 'First5name.Lastname5@email.com',
                MobilePhone = '0429410121',
            	Contact_Profile__c = 'Alumni'
        );
        // Duplicate contact 5
        Contact con10 = new Contact(
                FirstName = 'Firstname',
                LastName = 'Lastname5',
                Email = 'Firstname.Lastname5@email.com',
                Personal_Email__c = 'First5name.Lastname4@email.com',
                BirthDate = Date.valueOf('2001-11-03'),
                RecordTypeId = propectiveStudentRecordTypeId
        );
        List<Contact> cons = new List<Contact> {
                con1, con2, con3, con4, con5, con6, con7, con8, con9, con10
        };
        insert cons;

        // Contact points
        List<Phone__c> phoneRecord = new List<Phone__c> {
            new Phone__c(
                Contact__c = con1.id,
                Name = '0423470137',
                Type__c = 'Mobile',
                Classification__c = 'Private'
                )
        };
        insert phoneRecord;

        List<Email__c> emailRecord = new List<Email__c> {
            new Email__c(
                Contact__c = con2.id,
                Name = 'First1name.Lastname1@email.com',
                Classification__c = 'Private'
                )
        };
        insert emailRecord;

        // Create duplicate rule
        DuplicateRule rule = [SELECT id FROM DuplicateRule 
                                WHERE DeveloperName = 'Contact_Loose_Match' LIMIT 1];
          
        // Create duplicate record set records
        DuplicateRecordSet drs1 = new DuplicateRecordSet(
            duplicateRuleId = rule.id
        );
        DuplicateRecordSet drs2 = new DuplicateRecordSet(
            duplicateRuleId = rule.id
        );
        DuplicateRecordSet drs3 = new DuplicateRecordSet(
            duplicateRuleId = rule.id
        );
        DuplicateRecordSet drs4 = new DuplicateRecordSet(
            duplicateRuleId = rule.id
        );
        DuplicateRecordSet drs5 = new DuplicateRecordSet(
            duplicateRuleId = rule.id
        );
        List<DuplicateRecordSet> drsRecords = new List<DuplicateRecordSet> {
            drs1, drs2, drs3, drs4, drs5
        };
        insert drsRecords;

        // Create duplicate record item records
        List<DuplicateRecordItem> drsItems = new List<DuplicateRecordItem>{
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs1.id,
                    recordId = con1.id
                ),
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs1.id,
                    recordId = con2.id
                ),
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs2.id,
                    recordId = con3.id
                ),
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs2.id,
                    recordId = con4.id
                ),
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs3.id,
                    recordId = con5.id
                ),
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs3.id,
                    recordId = con6.id
                ),
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs4.id,
                    recordId = con7.id
                ),
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs4.id,
                    recordId = con8.id
                ),
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs5.id,
                    recordId = con9.id
                ),
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs5.id,
                    recordId = con10.id
                )
        };
        insert drsItems;
        
        // Create a custom setting record for DuplicateRecordSet filters    	
        DuplicateConAutomationSetting__c csobj = new DuplicateConAutomationSetting__c ();
        csobj.duplicateRuleName__c = [SELECT MasterLabel 
                                        FROM DuplicateRule 
                                        WHERE DeveloperName = 'Contact_Perfect_Match' 
                                        LIMIT 1].MasterLabel;
        csobj.Name = 'DuplicateContactSetting';
        csobj.MCC_SOQL_Limit__c = '100';
        insert csobj;
    }

    @isTest
    static void testretrieveDuplicateContactData() {
                
        // GIVEN : Duplicate contacts, duplicate rules, duplicate record items and duplicate record set records exists

        // WHEN : retrieveDuplicateContactData method is called
        Test.startTest();        
            List<ContactCopyController.Payload> payLoadData1 = (List<ContactCopyController.Payload>)ContactCopyController.retrieveDuplicateContactData('Contact Loose%','All', 10);
        	List<ContactCopyController.Payload> payLoadData2 = (List<ContactCopyController.Payload>)ContactCopyController.retrieveDuplicateContactData('Contact Loose%','Advancement', 10);
        	List<ContactCopyController.Payload> payLoadData3 = (List<ContactCopyController.Payload>)ContactCopyController.retrieveDuplicateContactData('Contact Loose%','Prospective Students', 10);
        Test.stopTest();

        // THEN : The result payload containing the duplicate contact records are returned
        //        Duplicate contacts with different Person Ids are ignored
        Assert.isNotNull(payLoadData1,'Null result returned');
        Assert.areEqual(4, payLoadData1.size(), '4 duplicate record set records were not returned');
        Assert.areEqual(2, payLoadData1.get(0).contactData.size(), '2 duplicate contacts were not returned');
        
        Assert.isNotNull(payLoadData2,'Null result returned');
        Assert.areEqual(1, payLoadData2.size(), '1 duplicate record set record was not returned');
        Assert.areEqual(2, payLoadData2.get(0).contactData.size(), '2 duplicate contacts were not returned');
        
        Assert.isNotNull(payLoadData3,'Null result returned');
        Assert.areEqual(1, payLoadData3.size(), '1 duplicate record set record was not returned');
        Assert.areEqual(2, payLoadData3.get(0).contactData.size(), '2 duplicate contacts were not returned');
    }

    @isTest
    static void testdeleteDRSAndUpdateContacts() {
                
        // GIVEN : Duplicate contacts, duplicate rules, duplicate record items and duplicate record set records exists
        Id studentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId();
        Id nonStudentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId();

        // Primary contact 1
        Contact con1 = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'John.Doe@email.com',
                Personal_Email__c = 'John.Doe@email.com',
                MobilePhone = '0423470144',
                RecordTypeId = nonStudentRecordTypeId
        );
        // Duplicate contact 1
        Contact con2 = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'John.Doe@email.com',
                Personal_Email__c = 'John.Doe@email.com',
                BirthDate = Date.valueOf('1991-02-12'),
                RecordTypeId = studentRecordTypeId
        );

        List<Contact> cons = new List<Contact> {
                con1, con2
        };
        insert cons;

        // Create duplicate rule
        DuplicateRule rule = [SELECT id FROM DuplicateRule 
                                WHERE DeveloperName = 'Contact_Loose_Match' LIMIT 1];
          
        // Create duplicate record set records
        DuplicateRecordSet drs1 = new DuplicateRecordSet(
            duplicateRuleId = rule.id
        );
        List<DuplicateRecordSet> drsRecords = new List<DuplicateRecordSet> {
            drs1
        };
        insert drsRecords;

        // Create duplicate record item records
        List<DuplicateRecordItem> drsItems = new List<DuplicateRecordItem>{
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs1.id,
                    recordId = con1.id
                ),
                new DuplicateRecordItem(
                    duplicateRecordSetId = drs1.id,
                    recordId = con2.id
                )
        };
        insert drsItems;


        // WHEN : MobilePhone on con2 is updated
        //        Email on con1 is updated
        //        deleteDRSAndUpdateContacts method is called
        con2.MobilePhone = '0423470666';
        con1.Email = 'first1name.lastnameclone@email.com';
        Test.startTest();
            ContactCopyController.deleteDRSAndUpdateContacts(new List<String>{drs1.Id}, new List<Contact>{con1, con2});      
        Test.stopTest();

        // THEN : The result payload containing the duplicate contact records are returned and contact records are updated
        Assert.areEqual(new List<DuplicateRecordSet>(), [SELECT Id FROM DuplicateRecordSet WHERE Id = :drs1.Id], 'DRS record was not deleted');
        Assert.areEqual(1, [SELECT Email FROM Contact WHERE Email = 'first1name.lastnameclone@email.com'].size(), 'Email was not updated');
        Assert.areEqual(1, [SELECT MobilePhone FROM Contact WHERE MobilePhone = '0423470666'].size(), 'Mobile was not updated');
    }
    
    @isTest
    static void testupdateContactPoints() {
                
        // GIVEN : Duplicate contacts, duplicate rules, duplicate record items and duplicate record set records exists
        Id studentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId();
        Id nonStudentRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId();

        // Primary contact 1
        Contact con1 = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'John.Doe@email.com',
                Personal_Email__c = 'John.Doe@email.com',
                MobilePhone = '0423470144',
                RecordTypeId = nonStudentRecordTypeId
        );
        // Duplicate contact 1
        Contact con2 = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'John.Doe@email.com',
                Personal_Email__c = 'John.Doe@email.com',
                BirthDate = Date.valueOf('1991-02-12'),
                RecordTypeId = studentRecordTypeId
        );

        List<Contact> cons = new List<Contact> {
                con1, con2
        };
        insert cons;
        
        insert new Phone__c(
            Contact__c = con2.id,
            Name = '0423470144',
            Type__c = 'Mobile',
            Classification__c = 'Private'
        );
        
        insert new Email__c(
            Contact__c = con1.id,
            Name = 'first1name.lastnameclone@email.com',
            Classification__c = 'Private'
        );

        // Contact points field values that needs to be updated with
        Date threeDaysBack = Date.today() - 3;
        List<Phone__c> phoneRecords = new List<Phone__c> {
            new Phone__c(
                Contact__c = con2.id,
                Name = '0423470144',
                Type__c = 'Mobile',
                Classification__c = 'Private',
                Start_Date__c = threeDaysBack,
                Verification_Status__c = 'Verified',
                Source__c = 'Third party provided'
            )
        };

        List<Email__c> emailRecords = new List<Email__c> {
            new Email__c(
                Contact__c = con1.id,
                Name = 'first1name.lastnameclone@email.com',
                Classification__c = 'Private',
                Start_Date__c = threeDaysBack,
                Verification_Status__c = 'Verified',
                Source__c = 'Third party provided'
            )
        };


        // WHEN : updateContactPoints method is called
        Test.startTest();
            ContactCopyController.updateContactPoints(phoneRecords, emailRecords);      
        Test.stopTest();

        Email__c updatedEmail = [SELECT Start_Date__c, Verification_Status__c, Source__c FROM Email__c WHERE Name = 'first1name.lastnameclone@email.com'];
        Phone__c updatedPhone = [SELECT Start_Date__c, Verification_Status__c, Source__c FROM Phone__c WHERE Name = '0423470144'];
        
        // THEN : The contact points are updated
        Assert.areEqual(threeDaysBack, updatedEmail.Start_Date__c, 'Email start date was not updated');
        Assert.areEqual('Verified', updatedEmail.Verification_Status__c, 'Email verification status was not updated');
        Assert.areEqual('Third party provided', updatedEmail.Source__c, 'Email status was not updated');
        
        Assert.areEqual(threeDaysBack, updatedPhone.Start_Date__c, 'Phone start date was not updated');
        Assert.areEqual('Verified', updatedPhone.Verification_Status__c, 'Phone verification status was not updated');
        Assert.areEqual('Third party provided', updatedPhone.Source__c, 'Phone status was not updated');
    }

    @isTest
    static void testfetchContactPointRecord() {
                
        // GIVEN : Duplicate contacts and contact points exist
        String mobileNumber = '0423470137';
        String email = 'First1name.Lastname1@email.com';

        List<Contact> mobileContacts = [SELECT Id FROM Contact WHERE MobilePhone = :mobileNumber];
        List<Contact> emailContacts = [SELECT Id FROM Contact WHERE Personal_Email__c = :email];

        // WHEN : fetchContactPointRecord method is called
        Test.startTest();        
            Phone__c phoneRecord = (Phone__c)ContactCopyController.fetchContactPointRecord(mobileNumber, mobileContacts.get(0).Id, 'Phone__c');
            Email__c emailRecord = (Email__c)ContactCopyController.fetchContactPointRecord(email, emailContacts.get(0).Id, 'Email__c');
            Phone__c nullPhoneRecord = (Phone__c)ContactCopyController.fetchContactPointRecord(null, mobileContacts.get(0).Id, 'Phone__c');
        Test.stopTest();

        // THEN : The phone and email records associated with the supplied contact Id are returned
        Assert.isNotNull(phoneRecord,'Phone record not returned');
        Assert.isNotNull(emailRecord,'Email record not returned');
        Assert.areEqual(mobileNumber, phoneRecord.Name, 'Expected '+mobileNumber+' to be returned');
        Assert.areEqual(email, emailRecord.Name, 'Expected '+email+' to be returned');
    }
}