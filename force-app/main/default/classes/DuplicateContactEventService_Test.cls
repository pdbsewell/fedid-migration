/**
 * @description       : Test class to verify DuplicateContactEventService
 * @author            : Sheeba T
 * @group             : Test class
 * @last modified on  : 2022-02-10
 * @last modified by  : Sheeba T
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   2022-02-10   Sheeba   Initial Version 
**/
@isTest
public class DuplicateContactEventService_Test {
    @testSetup
    static void setup() {
        // Primary contact
        Contact con1 = new Contact(
                FirstName = 'Controller',
                LastName = 'Test',
                Email = 'Controller.Test_testonly@email.com',
                Personal_Email__c = 'Controller.Test_testonly@email.com',
                MobilePhone = '0423470137',
                Monash_Email_Address__c = 'Controller.Test@student.monash.edu',
                Contact_Profile__c = 'Alumni,Alumni No Degree,Donor',
                BirthDate = Date.valueOf('1991-12-12'),
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId()
        );
        // Duplicate contact
        Contact con2 = new Contact(
                FirstName = 'Controller',
                LastName = 'Test',
                Email = 'Controller.Test_testonly@email.com',
                Personal_Email__c = 'Controller.Test_testonly@email.com',
                MobilePhone = '0423470137',
                Monash_Email_Address__c = 'Controller.Test@student.monash.edu',
                BirthDate = Date.valueOf('1991-12-12'),
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId()
        );
        List<Contact> cons = new List<Contact> {
                con1, con2
        };
        insert cons;
        // Primary user
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name='Customer Community General User' Limit 1];
        Profile baseProf = [SELECT Id FROM Profile WHERE Name='Base Profile' Limit 1];
        User user1 = new User(
                UserName = con1.Email + math.random(),
                FirstName = con1.FirstName,
                LastName = con1.LastName,
                Alias = 'prim' + String.valueOf(math.random()).substring(0,4),
                email = con1.Email,
                ContactId = con1.Id,
                ProfileId = portalProfile.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = 'a' + String.valueOf(math.rint(math.random()*1000000)).substring(0,6),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                IsActive = true
        );
        // Duplicate user
        User user2 = new User(
                UserName = con2.Email + math.random(),
                FirstName = con2.FirstName,
                LastName = con2.LastName,
                Alias = 'dupl' + String.valueOf(math.random()).substring(0,4),
                email = 'Controller.Test@guerilla.com',
                ContactId = con2.Id,
                ProfileId = portalProfile.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = 'b' + String.valueOf(math.rint(math.random()*1000000)).substring(0,6),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                MonashObjectId__c = 'zzzzzzzz-1111-zzzz-11zz11-zzzzzzzzzzzz',
                IsActive = true
        );
        User nonAdminUsr = new User(
                UserName = 'nonadminuser@test.com' + math.random(),
                FirstName = 'NonAdmin',
                LastName = 'MonashUser',
                Alias = 'nonA' + String.valueOf(math.random()).substring(0,4),
                email = 'nonadminuser@test.com',
                ProfileId = baseProf.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = 'nx' + String.valueOf(math.random()).substring(0,6),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                MonashObjectId__c = 'xxxxxxxx-1111',
                IsActive = true
        );
        List<User> users = new List<User> {
                user1, user2, nonAdminUsr
        };
        insert users;
        // list of primary user community accesses
        List<PermissionSetAssignment> communityAccesses = new List<PermissionSetAssignment>{
            // primary user community access
            // create alumni permission set/community access
            new PermissionSetAssignment(
                AssigneeId = users[0].Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Customer_Community_My_Application' LIMIT 1].Id
            ) ,
            // duplicate user community access
            // create my.app permission set/community access
            new PermissionSetAssignment(
                AssigneeId = users[1].Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Alumni_Portal_Permission_Set' LIMIT 1].Id
            ) 
        };
        UserServices.InsertSobjectsQueueable insertQueuable = new UserServices.InsertSobjectsQueueable(communityAccesses, false); // do not fail all records if a particular item fails
        Id jobId = System.enqueueJob(insertQueuable);
        // Contact points
        List<Phone__c> conPoints = new List<Phone__c> {
                new Phone__c(
                        Contact__c = con1.id,
                        Name = '0411111111',
                        Type__c = 'Mobile',
                        Classification__c = 'Private'
                ),
                new Phone__c(
                        Contact__c = con2.id,
                        Name = '0425345759',
                        Type__c = 'Mobile',
                        Classification__c = 'Private'
                )
        };
        insert conPoints;
        // Lead
        List<Lead> leads = new List<Lead> {
                new Lead(
                        Contact__c = con2.id,
                        LastName =con2.LastName,
                        Company='Monash University',
                        Active_Lead_Contact_Id__c = con2.id,
                        Status = 'Open')
        };
        insert leads;

        // Create a custom setting record for DuplicateRecordSet filters    	
        DuplicateConAutomationSetting__c csobj = new DuplicateConAutomationSetting__c ();
        csobj.duplicateRuleName__c = [SELECT MasterLabel 
                                        FROM DuplicateRule 
                                        WHERE DeveloperName = 
                        'Contact_Perfect_Match' LIMIT 1].MasterLabel;
        csobj.LastModDays__c = 2;
        csobj.queryLimit__c = 2;
        csobj.Name = 'DuplicateContactSetting';               
        insert csobj;

        // Create a custom setting record for PlatformEvent control settings
        PlatformEventControl__c pcobj = new PlatformEventControl__c ();
        pcobj.Duplicate_Contact_Event__c = 1;
        pcobj.Default__c = 1;                
        insert pcobj;

        DuplicateRule rule = [SELECT id FROM DuplicateRule 
                                WHERE DeveloperName = 'Contact_Perfect_Match' LIMIT 1];
                                
        DuplicateRecordSet drs = new DuplicateRecordSet(
            duplicateRuleId = rule.id
        );
        insert drs;

        List<DuplicateRecordItem> items = new List<DuplicateRecordItem>();
        for ( Contact c : cons ) {
            items.add( new DuplicateRecordItem(
                duplicateRecordSetId = drs.id,
                recordId = c.id
            ));
        }
        insert items;
    }
  
    @isTest
    public static void duplicateContactAutomationTest(){

        
        Test.startTest();
        DuplicateContactEventService.publishEvents();
        Test.stopTest();
        EmailTemplate et = [SELECT Id, IsActive FROM EmailTemplate WHERE DeveloperName = 'Contact_Merge_Notification' LIMIT 1];
        if(et != null && et.IsActive){
            //Limits.getEmailInvokations asserts to be 0 even if invoked in the same context. Hence the static variable emailLimitsUsed is used instead.
            System.assertEquals(1, DuplicateRecordSetService.emailLimitsUsed, 'Merge notification email not sent!');
        }
        List<DuplicateRecordSet> testdrs = [Select id, recordCount from DuplicateRecordSet];
        System.assert(testdrs[0].recordCount != 1, 'Incorrect record count for Duplicate record set');
        //Test.getEventBus().deliver() to deliver test event messages multiple times for sequencial processing of different merge and post merge methods. 
        Test.getEventBus().deliver();
        testdrs = [Select id, recordCount from DuplicateRecordSet];
        System.assert(testdrs[0].recordCount != 1, 'Incorrect record count for Duplicate record set');
        //At this point, event message for contact merge is dispatched and hence record cound in duplicate record set is expected to be 1.
        Test.getEventBus().deliver();
        testdrs = [Select id, recordCount from DuplicateRecordSet];
        System.assert(testdrs[0].recordCount == 1, 'Incorrect record count for Duplicate record set');
    }

    @isTest
    public static void duplicateContactAutomationPersonIdTest(){

        // Primary contact
        Contact con1 = new Contact(
                FirstName = 'Controller1',
                LastName = 'Test1',
                Email = 'Controller1.Test_testonly@email.com',
                Personal_Email__c = 'Controller1.Test_testonly@email.com',
                Person_ID_unique__c = '12345',
                MobilePhone = '0423470139',
                Monash_Email_Address__c = 'Controller1.Test@student.monash.edu',
                Contact_Profile__c = 'Alumni,Alumni No Degree,Donor',
                BirthDate = Date.valueOf('1991-11-12'),
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId()
        );
        // Duplicate contact
        Contact con2 = new Contact(
                FirstName = 'Controller1',
                LastName = 'Test1',
                Email = 'Controller1.Test_testonly@email.com',
                Personal_Email__c = 'Controller1.Test_testonly@email.com',
                Person_ID_unique__c = '12346',
                MobilePhone = '0423470139',
                Monash_Email_Address__c = 'Controller.Test@student.monash.edu',
                BirthDate = Date.valueOf('1991-11-12'),
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId()
        );
        List<Contact> cons = new List<Contact> {
                con1, con2
        };
        insert cons;
        DuplicateRule rule = [SELECT id FROM DuplicateRule 
                                WHERE DeveloperName = 'Contact_Perfect_Match' LIMIT 1];
                                
        DuplicateRecordSet drs = new DuplicateRecordSet(
            duplicateRuleId = rule.id
        );
        insert drs;

        List<DuplicateRecordItem> items = new List<DuplicateRecordItem>();
        for ( Contact c : cons ) {
            items.add( new DuplicateRecordItem(
                duplicateRecordSetId = drs.id,
                recordId = c.id
            ));
        }
        insert items;
        Test.startTest();
        DuplicateContactEventService.publishEvents();
        Test.stopTest();
        List<DuplicateRecordSet> testdrs = [Select id, recordCount from DuplicateRecordSet where id =: drs.id];
        System.assert(testdrs[0].recordCount != 1, 'Contacts with different person ids incorrectly merged');
    }

    @isTest
    // When the 'Use_Process_Flag_On_DRS__c' checkbox in custom setting is checked but none of the
    // DRS records have 'Process' field checked, then none of the DRS records are returned
    public static void test_UseProcessFlag_NoRecordsProcessed(){

        // Given
        DuplicateConAutomationSetting__c csobj =  [SELECT Use_Process_Flag_On_DRS__c, LastModDays__c, queryLimit__c
                                        FROM DuplicateConAutomationSetting__c 
                                        WHERE Name = 'DuplicateContactSetting' LIMIT 1];
        csobj.Use_Process_Flag_On_DRS__c = true;             
        update csobj;

        // When
        Test.startTest();
            DuplicateContactEventService.publishEvents();
        Test.stopTest();

        // Then
        List<DuplicateRecordSet> drsRecords = [SELECT Id, recordCount FROM DuplicateRecordSet];
        System.assertEquals(2, drsRecords.get(0).recordCount, 'DuplicateRecordSet should not have been processed, Incorrect record count for Duplicate record set');
    }

    @isTest
    // When the 'Use_Process_Flag_On_DRS__c' checkbox in custom setting is checked, only the
    // DRS record with 'Process' field checked is processed
    public static void test_UseProcessFlag_SelectedRecordProcessed(){

        // Given
        // DRS record marked for processing
        DuplicateRecordSet firstdrs = [SELECT Id, Process__c FROM DuplicateRecordSet LIMIT 1];
        firstdrs.Process__c = true;
        update firstdrs;

        // Primary contact
        Contact con1 = new Contact(
                FirstName = 'Controller 2',
                LastName = 'Test 2',
                Email = 'Controller2.Test_testonly@email.com',
                Personal_Email__c = 'Controller2.Test_testonly@email.com',
                MobilePhone = '0423470132',
                Monash_Email_Address__c = 'Controller2.Test@student.monash.edu',
                Contact_Profile__c = 'Alumni,Alumni No Degree,Donor',
                BirthDate = Date.valueOf('1991-12-12'),
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId()
        );
        // Duplicate contact
        Contact con2 = new Contact(
                FirstName = 'Controller 2',
                LastName = 'Test 2',
                Email = 'Controller2.Test_testonly@email.com',
                Personal_Email__c = 'Controller2.Test_testonly@email.com',
                MobilePhone = '0423470132',
                Monash_Email_Address__c = 'Controller2.Test@student.monash.edu',
                BirthDate = Date.valueOf('1991-12-12'),
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId()
        );
        List<Contact> cons = new List<Contact> {
                con1, con2
        };
        insert cons;

        // Primary user
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name='Customer Community General User' Limit 1];
        Profile baseProf = [SELECT Id FROM Profile WHERE Name='Base Profile' Limit 1];
        User user1 = new User(
                UserName = con1.Email + math.random(),
                FirstName = con1.FirstName,
                LastName = con1.LastName,
                Alias = 'prim' + String.valueOf(math.random()).substring(0,4),
                email = con1.Email,
                ContactId = con1.Id,
                ProfileId = portalProfile.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = 'a' + String.valueOf(math.rint(math.random()*1000000)).substring(0,6),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                IsActive = true
        );
        // Duplicate user
        User user2 = new User(
                UserName = con2.Email + math.random(),
                FirstName = con2.FirstName,
                LastName = con2.LastName,
                Alias = 'dupl' + String.valueOf(math.random()).substring(0,4),
                email = 'Controller2.Test@guerilla.com',
                ContactId = con2.Id,
                ProfileId = portalProfile.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = 'b' + String.valueOf(math.rint(math.random()*1000000)).substring(0,6),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                MonashObjectId__c = 'zzzzzzzz-1111-zzzz-11zz11-zzzzzzzzzzzy',
                IsActive = true
        );
        List<User> users = new List<User> {
                user1, user2
        };
        insert users;

        DuplicateRule rule = [SELECT id FROM DuplicateRule WHERE DeveloperName = 'Contact_Perfect_Match' LIMIT 1];
        
        // This DRS is not marked for processing
        DuplicateRecordSet seconddrs = new DuplicateRecordSet(
            duplicateRuleId = rule.id
        );
        insert seconddrs;

        List<DuplicateRecordItem> items = new List<DuplicateRecordItem>();
        for ( Contact c : cons ) {
            items.add( new DuplicateRecordItem(
                duplicateRecordSetId = seconddrs.id,
                recordId = c.id
            ));
        }
        insert items;

        DuplicateConAutomationSetting__c csobj =  [SELECT Use_Process_Flag_On_DRS__c
                                        FROM DuplicateConAutomationSetting__c 
                                        WHERE Name = 'DuplicateContactSetting' LIMIT 1];
        csobj.Use_Process_Flag_On_DRS__c = true;             
        update csobj;

        // When
        Test.startTest();
            DuplicateContactEventService.publishEvents();
        Test.stopTest();

        // Then
        List<DuplicateRecordSet> testdrs1 = [SELECT Id, recordCount FROM DuplicateRecordSet WHERE Id = :firstdrs.Id];
        System.assertEquals(2, testdrs1.get(0).recordCount, 'Incorrect record count for Duplicate record set');

        //Test.getEventBus().deliver() to deliver test event messages multiple times for sequencial processing of different merge and post merge methods.
        Test.getEventBus().deliver();
        testdrs1 = [SELECT Id, recordCount FROM DuplicateRecordSet WHERE Id = :firstdrs.Id];
        System.assertEquals(2, testdrs1.get(0).recordCount, 'Incorrect record count for Duplicate record set');

        //At this point, event message for contact merge is dispatched and hence record count on processed duplicate record set is expected to be 1.
        Test.getEventBus().deliver();
        List<DuplicateRecordSet> testdrsRecords = [SELECT Id, recordCount FROM DuplicateRecordSet WHERE Id IN (:firstdrs.Id, :seconddrs.Id)];
        for(DuplicateRecordSet testdrsRecord : testdrsRecords){
            if(testdrsRecord.Id == firstdrs.Id){
                // Processed DRS record
                System.assertEquals(1, testdrsRecord.recordCount, 'Incorrect record count for Duplicate record set');
            }
            if(testdrsRecord.Id == seconddrs.Id){
                // Unprocessed DRS record
                System.assertEquals(2, testdrsRecord.recordCount, 'Incorrect record count for Duplicate record set');
            }
        }
    }
}