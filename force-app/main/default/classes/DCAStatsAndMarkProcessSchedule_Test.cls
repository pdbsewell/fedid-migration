/**
 * @author      Sachin Shetty
 * @description Test Class for DCAStatsAndMarkProcessSchedule
 * @group       Test Class
 * @revision    2023-08-01 - Sachin Shetty - Created
**/

@isTest(isParallel=false) // cannot execute in parallel due to cronjobdetail object
private class DCAStatsAndMarkProcessSchedule_Test {
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
    
    @IsTest
    static void testSchedule() {
        String cronExpr = '0 0 1 * * ?';

        Test.startTest();
            // Schedule the test job
            String jobId = System.schedule('DCAStatsAndMarkProcessSchedule_Test', cronExpr, new DCAStatsAndMarkProcessSchedule());
        Test.stopTest();

        // Check schedulable is in the job list
        List<AsyncApexJob> jobsScheduled = [SELECT Id, ApexClassID, ApexClass.Name, Status, JobType FROM AsyncApexJob WHERE ApexClass.Name = 'DCAStatsAndMarkProcessSchedule' AND JobType = 'ScheduledApex'];
        
        Assert.areEqual(1,jobsScheduled.size(), 'Expecting one scheduled job');
    }
    
    @isTest
    static void testScheduleAndUnSchedule() {
        
        // GIVEN:
        DCAStatsAndMarkProcessSchedule myBatch = new DCAStatsAndMarkProcessSchedule();

        Test.StartTest();
        	String jobId = '';
        	List<CronTrigger> jobsScheduled = new List<CronTrigger>(); 
            try{
                // WHEN: job is scheduled
                jobId = myBatch.schedule();
                
                // THEN: 
                jobsScheduled = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        		Assert.areEqual(1,jobsScheduled.size(), 'Expecting one scheduled job'); 
            } catch (Exception e) {
                Assert.fail('An exception occured when scheduling the batch job : '+ e.getMessage());
            }
            
            try{
                // WHEN: job is unscheduled
                myBatch.unschedule();
            } catch (Exception e) {
                Assert.fail('An exception occured when unscheduling the batch job : '+ e.getMessage());
            }
        Test.stopTest();
        // THEN: 
        jobsScheduled = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(0,jobsScheduled.size(), 'Expecting no scheduled job');        

    }
}