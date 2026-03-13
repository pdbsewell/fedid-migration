/**
 * This class contains unit tests for validating the behavior of TaskServices methods
 * these methods are part of the testing framework implemented throughout UniCRM
 *  @REVISIONS:
 *  15/07/2018  APRivera    - Added test coverage for processDuplicateWrapUpTasks
 *  15/07/2018  APRivera    - Added test coverage for completeMonTrackCampaignMemberStatus
 *  21/06/2019  APRivera    - Added test coverage for LinkCorrectCaseToCTICallLog
 *  24/06/2021 IDhanoa      - Added test coverage for ValidateContactReportTask ENGAGEIE-677 
 *  18/10/2021 IDhanoa      - Added test coverage for ValidateContactReportTask ENGAGEIE-1004 
 */
@isTest//(isParallel=true)  Insert failed,first error: APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on User
private class TaskServices_Test {
    @testSetup
    static void setup() {
        // Create MC Agent
        String mcProfile = [SELECT Id FROM Profile WHERE Name = 'Base Profile' LIMIT 1].Id;
        String mcRole = [SELECT Id FROM UserRole WHERE Name = 'Monash Connect Future Officer' LIMIT 1].Id;
        Integer rnd = Integer.valueOf(Math.random()*9999);

        TestDataFactory.createSObject(new User(Alias = String.valueOf(rnd)+ 'usr',
            Email = String.valueOf(rnd) +'testuser@mctestingmonash.edu',
            EmailEncodingKey = 'UTF-8',
            LastName = 'MCTestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_GB',
            ProfileId = mcProfile,
            TimeZoneSidKey = 'Australia/Sydney',
            UserName = String.valueOf(rnd) +'testuser@mctestingmonash.edu',
            UserRoleId = mcRole), true);
    }

    /*******************************************************************************
    * @author       APRivera
    * @date         21.Jun.2019
    * @description  tests the inner class LinkCorrectCaseToCTICallLog from TaskServices
    * @revision     9/12/2024 - Matthew Maramot added check that Monash Connect users are excluded
    *******************************************************************************/
    static testMethod void testContactCaseTaskLink(){
        // GIVEN: MC Agent and Test Contact with an enquiry
        // Test Contact
        List<Contact> testContacts = TestHelper.createStudentContacts(1, null);
        insert testContacts;

        // Enquiry
        Id monConRecTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Case'
                                AND DeveloperName = 'Monash_Connect_Enquiry' LIMIT 1].Id;
        Case caseRecord = new Case(RecordTypeId=monConRecTypeId,Subject='CTI test', ContactId=testContacts[0].Id);
        insert caseRecord;
 
        // WHEN: A call task is inserted relating to a Contact with an Enquiry
        List<Task> testTasks = new List<Task>();
        Test.startTest();
            Task t = new Task(CallType = 'Inbound',
                    CallInitiatedTime__c = '21/06/2019, 09:20:31',
                    CallAnsweredTime__c = '21/06/2019, 09:20:50',
                    CallObject = '123456',
                    Subject = 'test',
                    WhoId = testContacts[0].Id);
            testTasks.add(t);

            User mcUser = [SELECT Id, UserRoleId, UserRole.Name FROM User WHERE LastName = 'MCTestUser'];
            Task tMC = new Task(CallType = 'Inbound',
                    CallInitiatedTime__c = '21/06/2019, 09:20:31',
                    CallAnsweredTime__c = '21/06/2019, 09:20:50',
                    CallObject = '123456',
                    Subject = 'test',
                    WhoId = testContacts[0].Id,
                    OwnerId = mcUser.Id);
            testTasks.add(tMC);
            insert testTasks;
        Test.stopTest();

        // Task relating to non-mc agent should link to the case
        Task tsk = [SELECT Id, OwnerId, Owner.UserRoleId, WhatId FROM Task WHERE Id =: t.Id];
        Assert.areEqual(tsk.WhatId, [SELECT Id FROM Case].Id, 'Expected Task to link to Case belonging to Contact');

        //Task relating to mc agent should not link to the case
        Task tskMC = [SELECT Id, OwnerId, WhatId FROM Task WHERE Id =: tMC.Id];
        Assert.areEqual(tskMC.WhatId, null, 'Expected Task to not link to Case as owner is Monash Connect role');
    }
	
    static testMethod void testMapping(){
        TestHelper.calabrioSetUp();
        List<Contact_to_Task_Field_Mapping__mdt> fieldMappings = 
                new List<Contact_to_Task_Field_Mapping__mdt>([ SELECT Id, 
                                                                      Contact_field_API_name__c, 
                                                                      Task_field_API_name__c,
                                                              		  Task_Record_Type__c
            														  FROM Contact_to_Task_Field_Mapping__mdt 
                                                             		  where Task_Record_Type__c = 'Montrack' and
                                                             		  Contact_field_API_name__c = 'LastName']);
        system.assert(!fieldMappings.isEmpty(),'No field mappings to test with');
        
        List<Contact> testContacts = TestHelper.createStudentContacts(1, null);
        insert testContacts;
        
        id taskRecordType = [select id from RecordType where SObjectType = 'Task' and DeveloperName = 'Montrack' limit 1].id;
        
        Task t = new task(recordtypeId = taskRecordType,
                            Offer_Status__c = 'Not Started',
                         subject = 'test',
                         whoId = testContacts[0].id,
                         last_name__c = '');
        insert t;
        system.assertEquals(testContacts[0].lastname,
                           [select last_name__c from task where id =:t.id limit 1].last_name__c,
                           'last name didnt map to task as expected');
        
        
        TaskServices.updateTaskRecords(new list<task>{ t });
        
        TaskServices.deleteTaskRecords(new list<task>{ t });
    }

    static testMethod  void test_deleteUpdateCallOutcomeOfCompletedTasks(){
        Id cmpRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('MonTrack').getRecordTypeId();

        List<Contact> lstCont = new List<Contact>();
        lstCont = TestHelper.createOrphanContactRecords(2);
        insert lstCont;

        Campaign cmp = new Campaign(Name='Semester 1 - Round 1',
                IsActive=true, RecordTypeId = cmpRecordTypeId);
        insert cmp;

        CampaignMember cmpMember = new CampaignMember(
                CampaignId = cmp.Id, SSA__c = UserInfo.getUserId(), ContactId = lstCont.get(0).Id
        );
        insert  cmpMember;

        List<Task> lstTasks = [Select Id,Status, Offer_Status__c from Task
                                where WhatId =: cmp.Id order by CreatedDate ASC];
        Assert.areEqual(lstTasks.size(), 1, 'Expected task to be found');

        Task tsk = lstTasks.get(0);
        tsk.Offer_Status__c = 'No Answer';
        update tsk;

        List<Task> lstTasksUpdated = [Select Id,Status, Offer_Status__c from Task
                                        where WhatId =: cmp.Id order by CreatedDate ASC];
        Assert.areEqual(lstTasksUpdated.size(), 2, 'Expected second task to be found');

        Test.startTest();
            Task tskToUpdate = lstTasks.get(0);
            tskToUpdate.Offer_Status__c = 'Not Enrolled';
            update tskToUpdate;
        Test.stopTest();

        List<Task> lstTasksRemaining = [Select Id,Status, Offer_Status__c from Task where WhatId =: cmp.Id];
        Assert.areNotEqual(0, lstTasksRemaining.size(),'Expected no task remaining');
    }

    static testMethod void test_completeMonTrackCampaignMemberStatus(){
        Id cmpRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('MonTrack').getRecordTypeId();

        List<Contact> lstCont = new List<Contact>();
        lstCont = TestHelper.createOrphanContactRecords(2);
        insert lstCont;

        Campaign cmp = new Campaign(Name='Semester 1 - Round 1',
                IsActive=true, RecordTypeId = cmpRecordTypeId);
        insert cmp;

        CampaignMember cmpMember = new CampaignMember(
            CampaignId = cmp.Id, SSA__c = UserInfo.getUserId(), ContactId = lstCont.get(0).Id
        );
        insert  cmpMember;

        List<Task> lstTasks = [Select Id,Status, Offer_Status__c from Task where WhatId =: cmp.Id];
        Assert.areEqual(lstTasks.size(), 1, 'Expected task to be found');

        Test.startTest();
            Task tsk = lstTasks.get(0);
            tsk.Status = 'Completed';
            tsk.Offer_Status__c = 'Not Enrolled';
            update tsk;
        Test.stopTest();

        List<CampaignMember> lstRtrvdCampaignMember = [Select Id, Status from CampaignMember];
        Assert.areEqual(lstRtrvdCampaignMember.size(), 1, 'Expected Campaign Member to be found');

    }

    static testMethod void test_processDuplicateWrapUpTasks() {

        Case tstCase = new Case( SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@mutesting.edu',
                                Type = 'Phone',
                                Case_type__c = '',
                                ContactId = null,
                                AccountId = null,
                                Course_code__c = '0',
                                Channel_Mapping__c = 'MonCon Phone');
        insert tstCase;

        List<Task> tstLstTasks = TestHelper.createTasks(1, null, tstCase.Id);
        tstLstTasks[0].Type = 'Wrap Up';
        tstLstTasks[0].Subject = 'Wrap Up Task';
        insert tstLstTasks;

        List<Case> tstListCaseRecord = [SELECT Id,Last_Updated_By__c,
                        (SELECT Id, CreatedDate, ActivityDate, Description FROM Tasks  
                              WHERE Type = 'Wrap Up' ORDER BY CreatedDate DESC)
                        FROM Case
                        WHERE Id =: tstCase.Id];

        Assert.areEqual(1, tstListCaseRecord[0].Tasks.size(), 'Expected Task to be found');

        Test.startTest();
            tstCase.Status = 'Solved';
            update tstCase;
        Test.stopTest();

        List<Case> tstListCaseRecordAfter = [SELECT Id,Last_Updated_By__c,
                        (SELECT Id, CreatedDate, ActivityDate, Description FROM Tasks  
                              WHERE Type = 'Wrap Up' ORDER BY CreatedDate DESC)
                        FROM Case
                        WHERE Id =: tstCase.Id];

        Assert.areEqual(tstListCaseRecordAfter[0].Tasks.size(), 1, 'Expected Task to be found after case is solved');
        Boolean result = tstListCaseRecordAfter[0].Tasks[0].Description.contains('Enquiry Status: Solved');
        Assert.areEqual(result, true, 'Expected status to be solved');
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         28.Jul.2017        
    * @description  tests the Invocable method that sends emails to agent when 
                                        certain criteria was met
    * @revision     
    *******************************************************************************/
    static testMethod void test_sendEmailToAgent() {
        //create data
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        //create a community user
        communityUserRec = StudFirst_TestHelper.createCommunityUser();
        //create required records
        createSampleData(communityUserRec.ContactId, 'Draft', 'TEST-STATUS', true);
        
        Test.startTest();

        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                     'Complete',
                                                     '{"success":true,"message":"Message has been successfully submitted"}',
                                                     null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                ContactId = null,
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Notify_Agent__c = true,
                                Application_Course_Preference__c = coursePrefA.Id );
        insert caseRec;

        Assert.areEqual(caseRec.Notify_Agent__c, true, 'Notify Agent should be set to true');
        Assert.areEqual(caseRec.RecordTypeId, admissionsRecType, 'Record Type should be Admissions');

        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu'); 
        insert emlMsg;

        Assert.areEqual(caseRec.Id, emlMsg.ParentId, 'Email Message ParentId should be the Case created');

        Task taskRec = new Task(    Description = 'Additional To: testmonash@monash.edu\nCC: \nBCC: \nAttachment: att.docx\n\nSubject: dummy email\nBody:\nsdlfkajsldfarwerwdrf\n\nref:_00D0kCnIP._5000kguvP:ref',
                                    WhatId = caseRec.Id, 
                                    Subject = 'Welcome',
                                    Type = 'Internal Email' );
        insert taskRec;

        Assert.areEqual(taskRec.WhatId, caseRec.Id, 'No Task created');

        //make sure there's no error on the request
        Assert.areEqual(0, [SELECT  COUNT()
                                FROM    Exception_Log__c 
                                WHERE   Source_Type__c = 'StudFirst_CRMToAPQueueable' ], 'Expected no error on request');
        
        Test.stopTest();
    }

    private static Application__c appRecord;
    private static User communityUserRec;
    private static Contact contactRec;
    private static Application_Course_Preference__c coursePrefA;
    private static Application_Course_Preference__c coursePrefB;
    private static Course_Offering__c courseOfferingRec;
    private static Course_Offering__c courseOfferingRecNoUnit;

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         1.Aug.2017        
    * @description  creates sample data
    * @revision     26.Mar.2020 KL: removing use of field "Agent_Email__c"
    *******************************************************************************/
    static void createSampleData (String contactId, String status, String outcome, Boolean addCourse) {
        //create a new draft application
        appRecord = StudFirst_TestHelper.createApplication(contactId);
        appRecord.OwnerId = communityUserRec.Id;
        appRecord.Status__c = status;
        // appRecord.Agent_Email__c = 'agentEmail@agents.com';
        insert appRecord;

        contactRec = [SELECT Id FROM Contact WHERE Id =: contactId];
        contactRec.Residency_Status__c = 'DOM-AUS';
        update contactRec;

        //Tertiary institution & qualification
        Institution__c tertInsRec = StudFirst_TestHelper.createTertiaryInstitution();
        insert tertInsRec;

        Callista_Outcome_Status__c outcomeStatus = StudFirst_TestHelper.createOutcomeStatus();
        insert outcomeStatus;

        Contact_Qualification__c conQualRec = new Contact_Qualification__c();
        conQualRec.Country__c = 'Australia';
        conQualRec.First_Year_Enrolled__c = String.valueOf(date.today().year()-4);
        conQualRec.Last_Year_Enrolled__c = String.valueOf(date.today().year());
        conQualRec.Other_Qualification__c = 'Certificate III';
        conQualRec.Institution_Code__c = tertInsRec.Institution_Code__c;
        conQualRec.Institution_Name__c = tertInsRec.Institution_Name__c;
        conQualRec.Status__c = 'CURRENTLY STUDYING';
        conQualRec.Contact__c = contactRec.Id;
        conQualRec.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert conQualRec;

        Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
        aqpRecord.Application__c = appRecord.Id;
        aqpRecord.Contact_Qualification__c = conQualRec.Id;
        insert aqpRecord;

        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = contactRec.Id;
        insert workExpRecord;

        Contact_Document__c contactDocu = new Contact_Document__c();
        contactDocu = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        insert contactDocu;

        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = appRecord.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord;

        Course__c courseRec = StudFirst_TestHelper.createCourse();
        insert courseRec;

        courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec);
        insert courseOfferingRec;

        courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec);
        insert courseOfferingRecNoUnit;

        if(addCourse){
            coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
            coursePrefA.Outcome_Status__c = outcome;
            coursePrefA.Offer_Response_Status__c = outcome;
            coursePrefA.Preference_Number__c = '1';
            insert coursePrefA;

            coursePrefB = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRecNoUnit, courseRec);
            coursePrefB.Outcome_Status__c = outcome;
            coursePrefB.Offer_Response_Status__c = outcome;
            coursePrefB.Preference_Number__c = '2';
            insert coursePrefB;
        }
    }
	
	/******************************************************************************* 
    * @author       IDhanoa
    * @date         18.Oct.2021
    * @description  tests the inner class ValidateContactReportTask from TaskServices
    * @revision     
    *******************************************************************************/
	static testMethod void testValidateContactReportTask(){
        
        String adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        String enterpProfileId = [SELECT Id FROM Profile WHERE Name = 'Enterprise Base Profile' LIMIT 1].Id;
        String roleId = [SELECT Name FROM UserRole where name like 'External Relations, Development and Alumni (ERDA)' LIMIT 1].Id;
        List<User> l_relUsers = new lIst<User>();
        Integer rnd = Integer.valueOf(Math.random()*9999);
        User admin = new User( Alias = String.valueOf(rnd)+ 'usr',
                    Email = String.valueOf(rnd) +'testuser1@mutesting.edu',
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'TestingUser',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_GB',
                    ProfileId = adminProfileId,
                    TimeZoneSidKey = 'Australia/Sydney',
                    UserName = String.valueOf(rnd) +'testuser1@mutesting.edu',
                    UserRoleId = roleId);

        User enterpUser = new User( Alias = String.valueOf(rnd)+ 'usr',
                    Email = String.valueOf(rnd) +'testuser2@mutesting.edu',
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'TestingUser',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_GB',
                    ProfileId = enterpProfileId,
                    TimeZoneSidKey = 'Australia/Sydney',
                    UserName = String.valueOf(rnd) +'testuser2@mutesting.edu',
                    UserRoleId = roleId);
        l_relUsers.add(admin);
        l_relUsers.add(enterpUser);
        insert l_relUsers;

        enterpUser = [SELECT Id FROM USER WHERE UserName like '%testuser2@mutesting.edu%' LIMIT 1];
		
		// GIVEN: An Enterprise User is present
        system.runAs(enterpUser){
            Account accountRecord = new Account(name ='AccountTest', RecordTypeId = AccountUtility.ACCOUNT_EXTERNAL_ORG_REC_TYPE) ;
            insert accountRecord;

            Contact testContact = new Contact(LastName = 'TestApplicant', MailingCountry = 'Australia');
            insert testContact;
			
			Test.starttest();

            ucinn_ascendv2__Contact_Report__c conRep = new ucinn_ascendv2__Contact_Report__c();
            conRep.ucinn_ascendv2__Contact__c = testContact.Id;
            conRep.ucinn_ascendv2__Contact_Method__c = 'Phone';
            conRep.ucinn_ascendv2__Description__c = 'Test';
            conRep.ucinn_ascendv2__Contact_Report_Body__c = 'test';
            conRep.ucinn_ascendv2__Date__c = date.today() - 5;
            insert conRep;

            Task linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep.Id LIMIT 1];
            Assert.areEqual(linkedTask.Description, null, 'Expected description to be null');

			// WHEN: Method is invoked to update the Task
            linkedTask.Description = 'temp Desc';
			
			
			// THEN: Exception occured.
            try{
                update linkedTask;
            }catch(Exception ex){
                String validationError = Label.ContactReportTaskValidation;
                Boolean expectedExceptionThrown =  ex.getMessage().contains(validationError) ? true : false;
                Assert.areEqual(expectedExceptionThrown, true, 'Expected exception to occur'); 
            }
        } 

        admin = [SELECT Id FROM USER WHERE UserName like '%testuser1@mutesting.edu%' LIMIT 1];

		// GIVEN: An Admin User is present
        system.runAs(admin){
            ucinn_ascendv2__Contact_Report__c conRep1 = [SELECT Id FROM ucinn_ascendv2__Contact_Report__c WHERE ucinn_ascendv2__Contact_Method__c = 'Phone' LIMIT 1]; 

			// WHEN: Method is invoked to update the Task
            Task linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep1.Id LIMIT 1];
            linkedTask.Description = 'temp Desc';

            update linkedTask;
			
			Test.stopTest();
			
			// THEN: Exception not occured.
            linkedTask = [SELECT Id, Description FROM TASK WHERE Contact_Report__c = :conRep1.Id LIMIT 1];
            Assert.areEqual(linkedTask.Description, 'temp Desc', 'Description not as expected');
        } 
    }
    
    /*
     * @author:			ayush.agrawal@monash.edu
     * @date:			28-09-2020
     * @description:	This method tests for roll-up(count) of tasks with record type 'Call Log - Default' to Case.
     */
    static testMethod void testRollUpCallCountToCase() {
        Case c = new Case();
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
        c.Subject = 'RollUpCallCountToCase';
        insert c;
        
        Task t = new Task();
        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Call_Log_Default').getRecordTypeId();
        t.WhatId = c.Id;
        insert t;
        
        t.Call_Back_Date_Time__c  = System.now();
        update t;
        
        Test.startTest();
        
        Case caseToCheck = [SELECT Number_of_Calls__c FROM Case WHERE Subject = 'RollUpCallCountToCase' LIMIT 1];
        
        Test.stopTest();
        
        System.assertEquals(1, caseToCheck.Number_of_Calls__c, 'Roll-up logic for call log count not working.');
    }
	
    @isTest
    private static void testAddCaseTeam() {
        Id mgroUserId = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE Assignee.isActive = TRUE AND PermissionSet.Name = 'Monash_Graduate_Research_Office_Staff_PSG'
            LIMIT 1
        ][0].AssigneeId;

        System.runAs(new User(Id=mgroUserId)) {
            // GIVEN - new enquiry
            Case case1 = (Case) TestDataFactory.createSObject(
                new Case(Subject = 'Case 1'),
                'MGROTestHelper.CaseDefaults'
            );
            Case case2 = (Case) TestDataFactory.createSObject(
                new Case(Subject = 'Case 2'),
                'MGROTestHelper.CaseDefaults'
            );

            TriggerCommon.disableTrigger('Case');
            insert new List<Case>{ case1, case2 };

            // WHEN - task created under enquiry is assigned to a mgro queue 
            Task admissionsTask = (Task) TestDataFactory.createSObject(new Task());
            admissionsTask.WhatId = case1.Id;
            admissionsTask.OwnerId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'MGRO Admissions'].Id;

            Task bookingsTask = (Task) TestDataFactory.createSObject(new Task());
            bookingsTask.WhatId = case2.Id;

            Test.startTest();
            insert new List<Task>{ admissionsTask, bookingsTask };

            case1 = [
                SELECT Id, (SELECT Id, TeamTemplate.Name FROM TeamTemplateRecords)
                FROM Case
                WHERE Subject = 'Case 1'
            ];

            // THEN - case team mgro is added since it is assigned to mgro queue 
            Assert.areEqual(true, case1.TeamTemplateRecords.size() == 1, 'Expected case team to be added');
            Assert.areEqual('MGRO', case1.TeamTemplateRecords[0].TeamTemplate.Name, 'Expected case team to be with MGRO');

            // GIVEN - new enquiry
            case2 = [
                SELECT Id, (SELECT Id, TeamTemplate.Name FROM TeamTemplateRecords)
                FROM Case
                WHERE Subject = 'Case 2'
            ];

            // WHEN - no case team added initially since not assigned to a queue
            Assert.areEqual(true, case2.TeamTemplateRecords.size() == 0, 'Expected no Case Team as not assigned to queue');

            bookingsTask.OwnerId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'MGRO Bookings'].Id;
            update bookingsTask;
            Test.stopTest();

            case2 = [
                SELECT Id, (SELECT Id, TeamTemplate.Name FROM TeamTemplateRecords)
                FROM Case
                WHERE Subject = 'Case 2'
            ];

            // THEN - case team mgro is added when changed to mgro queue
            Assert.areEqual(true, case2.TeamTemplateRecords.size() == 1, 'Expected Case team to be found');
            Assert.areEqual('MGRO', case2.TeamTemplateRecords[0].TeamTemplate.Name, 'Expected Case team to be with MGRO');
            
        }
    }

    /******************************************************************************* 
    * @author       Sethu Venna
    * @date         28/01/2025
    * @description  GIVEN A Task is created for Admission
                    WHEN the related to Id is linked to ACP
                    THEN copy the WhatId to ApplicationCoursePreference__c look up
    * @revision     created 28/01/2025 Sethu Venna
    *******************************************************************************/
	static testMethod void testCopyACPId(){
        
        Contact newContact = new Contact();
        newContact.FirstName = 'FN in testCopyACPId';
        newContact.LastName = 'LN in testCopyACPId';
        insert newContact;

        Application__c app = new Application__c();
        app.Applicant__c = newContact.id;
        app.Callista_Applicant_Id__c = 'testApp1';
        app.Status__c = 'Sent for Submission';
        insert app;

        Application_Course_Preference__c acp = new Application_Course_Preference__c();
        acp.Application__c = app.id;
        insert acp;

        Task t = new Task();
        t.WhoId = newContact.Id;
        t.WhatId = acp.Id;
        t.Subject = 'Call';
        insert t; 

        Assert.areEqual(
            t.WhatId,
            [SELECT Id, Application_Course_Preference__c FROM Task WHERE Id = :t.Id][0].Application_Course_Preference__c,
            'Expecting what id to be copied across'
        );

        t.WhatId = app.Id;
        update t; 

        Assert.areNotEqual(
            t.WhatId,
            [SELECT Id, Application_Course_Preference__c FROM Task WHERE Id = :t.Id][0].Application_Course_Preference__c,
            'Expecting what id not to be copied across'
        );

        t.WhatId = acp.Id;
        update t; 

        Assert.areEqual(
            t.WhatId,
            [SELECT Id, Application_Course_Preference__c FROM Task WHERE Id = :t.Id][0].Application_Course_Preference__c,
            'Expecting what id to be copied across'
        );
    }

    /******************************************************************************* 
    * @author       Sethu Venna
    * @date         28/01/2025
    * @description  GIVEN A Task is created for Admission
                    WHEN the related to Id is linked to ACP
                    THEN copy the WhatId to ApplicationCoursePreference__c look up
    * @revision     created 28/01/2025 Sethu Venna
    *******************************************************************************/
	static testMethod void testCopyTaskType(){
        
        Contact newContact = new Contact();
        newContact.FirstName = 'FN in testCopyACPId';
        newContact.LastName = 'LN in testCopyACPId';
        insert newContact;

        Task t = new Task();
        t.WhoId = newContact.Id;
        t.Type = 'Call';
        t.Subject = 'Call';
        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Admissions').getRecordTypeId();
        insert t; 

        Assert.areEqual(
            t.Type,
            [SELECT Id, Type__c FROM Task WHERE Id = :t.Id][0].Type__c,
            'Expecting Type__c to be copied across'
        );

        t.Type__c = 'Genuine Student';
        update t; 

        Assert.areEqual(
            t.Type__c,
            [SELECT Id, Type FROM Task WHERE Id = :t.Id][0].Type,
            'Expecting Type to be copied across'
        );
    }
}