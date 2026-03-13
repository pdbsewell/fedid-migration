/**
 * @author      Sachin Shetty
 * @description Test Class for DCAStatsAndMarkProcessBatch
 * @group       Test Class
 * @revision    2022-09-14 - Sachin Shetty - Created
**/
@isTest
public with sharing class DCAStatsAndMarkProcessBatch_Test {

    @testSetup
    static void setup() {
        // Primary contact
        Contact con1 = new Contact(
                FirstName = 'Batch',
                LastName = 'Test',
                Email = 'Batch.Test_testonly@email.com',
                Personal_Email__c = 'Batch.Test_testonly@email.com',
                MobilePhone = '0423470137',
                Monash_Email_Address__c = 'Batch.Test@student.monash.edu',
                Contact_Profile__c = 'Alumni,Alumni No Degree,Donor',
                BirthDate = Date.valueOf('1991-12-12'),
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId()
        );
        // Duplicate contact
        Contact con2 = new Contact(
                FirstName = 'Batch',
                LastName = 'Test',
                Email = 'Batch.Test_testonly@email.com',
                Personal_Email__c = 'Batch.Test_testonly@email.com',
                MobilePhone = '0423470137',
                Monash_Email_Address__c = 'Batch.Test@student.monash.edu',
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
                CommunityNickName = 'a' + String.valueOf(math.random()).substring(0,4),
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
                email = 'Batch.Test@guerilla.com',
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
            // create my.app permission set/community access
            new PermissionSetAssignment(
                AssigneeId = users[0].Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Customer_Community_My_Application' LIMIT 1].Id
            ) ,
            // duplicate user community access
            // create ask.monash permission set/community access
            new PermissionSetAssignment(
                AssigneeId = users[1].Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Customer_Community_Ask_Monash_Student' LIMIT 1].Id
            ) 
        };
        UserServices.InsertSobjectsQueueable insertQueuable = new UserServices.InsertSobjectsQueueable(communityAccesses, false); // do not fail all records if a particular item fails
        Id jobId = System.enqueueJob(insertQueuable);

        // Create a custom setting record for DuplicateRecordSet filters    	
        DuplicateConAutomationSetting__c csobj = new DuplicateConAutomationSetting__c ();
        csobj.duplicateRuleName__c = [SELECT MasterLabel 
                                        FROM DuplicateRule 
                                        WHERE DeveloperName = 'Contact_Perfect_Match' 
                                        LIMIT 1].MasterLabel;
        csobj.Name = 'DuplicateContactSetting';               
        insert csobj;

        // Create a custom setting record for PlatformEvent control settings
        PlatformEventControl__c pcobj = new PlatformEventControl__c();
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
    static void testBatchGetStats() {
                
        // When
        Test.startTest();        
            DCAStatsAndMarkProcessBatch bc = new DCAStatsAndMarkProcessBatch();
            Database.executeBatch(bc);        
        Test.stopTest();

        // Then
        List<DuplicateRecordSet> drsRecords = [SELECT Id, Process__c FROM DuplicateRecordSet];
        System.assertEquals(1, drsRecords.size(), 'Incorrect number of DRS records returned');
        System.assertEquals(false, drsRecords.get(0).Process__c, 'DRS record should not have been marked');
    }

    @isTest
    static void testBatchGetStatsAndMarkOnlySelectedDRS() {
        // Given
        // Primary contact
        Contact con1 = new Contact(
                FirstName = 'Batch 2',
                LastName = 'Test 2',
                Email = 'Batch2.Test_testonly@email.com',
                Personal_Email__c = 'Batch2.Test_testonly@email.com',
                MobilePhone = '0423470132',
                Monash_Email_Address__c = 'Batch2.Test@student.monash.edu',
                Contact_Profile__c = 'Alumni,Alumni No Degree,Donor',
                BirthDate = Date.valueOf('1991-12-12'),
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId()
        );
        // Duplicate contact
        Contact con2 = new Contact(
                FirstName = 'Batch 2',
                LastName = 'Test 2',
                Email = 'Batch2.Test_testonly@email.com',
                Personal_Email__c = 'Batch2.Test_testonly@email.com',
                MobilePhone = '0423470132',
                Monash_Email_Address__c = 'Batch2.Test@student.monash.edu',
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
                CommunityNickName = 'a' + String.valueOf(math.random()).substring(0,6),
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
                email = 'Batch2.Test@guerilla.com',
                ContactId = con2.Id,
                ProfileId = portalProfile.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = 'b' + String.valueOf(math.random()).substring(0,6),
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

        // Mark DRS records for processing with no community permissionsets
        DuplicateConAutomationSetting__c csobj =  [SELECT DRS_Categories_To_Be_Marked__c
                                                    FROM DuplicateConAutomationSetting__c 
                                                    WHERE Name = 'DuplicateContactSetting' LIMIT 1];
        csobj.DRS_Categories_To_Be_Marked__c = 'No Community Permissionset';             
        update csobj;

        // When
        Test.startTest();        
            DCAStatsAndMarkProcessBatch bc = new DCAStatsAndMarkProcessBatch();
            Database.executeBatch(bc);        
        Test.stopTest();

        // Then
        List<DuplicateRecordSet> drsRecords = [SELECT Id, Process__c FROM DuplicateRecordSet];
        System.assertEquals(2, drsRecords.size(), 'Incorrect number of DRS records returned');
        Map<Id, DuplicateRecordSet> mapdrsRecords = new Map<Id, DuplicateRecordSet>(drsRecords);

        Id firstDRSId = [SELECT duplicateRecordSetId FROM DuplicateRecordItem WHERE record.FirstName = 'Batch'].get(0).duplicateRecordSetId;
        Id secondDRSId = [SELECT duplicateRecordSetId FROM DuplicateRecordItem WHERE record.FirstName = 'Batch 2'].get(0).duplicateRecordSetId;

        // Check Process__c flag is not marked for DRS records with no my.app and ask.monash permission sets
        System.assertEquals(false ,mapdrsRecords.get(firstDRSId).Process__c, 'DRS record should have been marked');

        // Check Process__c flag is marked for DRS records with no community permission sets
        System.assertEquals(true ,mapdrsRecords.get(secondDRSId).Process__c, 'DRS record should not have been marked');
    }

    @isTest
    static void testBatchGetStatsAndMarkAllDRS() {
        // Given
        // Primary contact
        Contact con1 = new Contact(
                FirstName = 'Batch 2',
                LastName = 'Test 2',
                Email = 'Batch2.Test_testonly@email.com',
                Personal_Email__c = 'Batch2.Test_testonly@email.com',
                MobilePhone = '0423470132',
                Monash_Email_Address__c = 'Batch2.Test@student.monash.edu',
                BirthDate = Date.valueOf('1991-12-12'),
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId()
        );
        // Duplicate contact
        Contact con2 = new Contact(
                FirstName = 'Batch 2',
                LastName = 'Test 2',
                Email = 'Batch2.Test_testonly@email.com',
                Personal_Email__c = 'Batch2.Test_testonly@email.com',
                MobilePhone = '0423470132',
                Monash_Email_Address__c = 'Batch2.Test@student.monash.edu',
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
                email = 'Batch2.Test@guerilla.com',
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

        // Mark DRS records for processing with no community permissionsets
        DuplicateConAutomationSetting__c csobj =  [SELECT DRS_Categories_To_Be_Marked__c
                                                    FROM DuplicateConAutomationSetting__c 
                                                    WHERE Name = 'DuplicateContactSetting' LIMIT 1];
        csobj.DRS_Categories_To_Be_Marked__c = 'No Community Permissionset,MyApp and AskMonash Permissionset';             
        update csobj;

        // When
        Test.startTest();        
            DCAStatsAndMarkProcessBatch bc = new DCAStatsAndMarkProcessBatch();
            Database.executeBatch(bc);        
        Test.stopTest();

        // Then
        List<DuplicateRecordSet> drsRecords = [SELECT Id, Process__c FROM DuplicateRecordSet];
        System.assertEquals(2, drsRecords.size(), 'Incorrect number of DRS records returned');

        Map<Id, DuplicateRecordSet> mapdrsRecords = new Map<Id, DuplicateRecordSet>(drsRecords);

        
        Id firstDRSId = [SELECT duplicateRecordSetId FROM DuplicateRecordItem WHERE record.FirstName = 'Batch'].get(0).duplicateRecordSetId;
        Id secondDRSId = [SELECT duplicateRecordSetId FROM DuplicateRecordItem WHERE record.FirstName = 'Batch 2'].get(0).duplicateRecordSetId;

        System.assertEquals(true , mapdrsRecords.get(firstDRSId).Process__c, 'DRS record with no community permission sets should have been marked');
        System.assertEquals(true , mapdrsRecords.get(secondDRSId).Process__c, 'DRS record with my.app and ask.moansh community permission sets should have been marked');
    }
}