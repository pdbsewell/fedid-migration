/**
* @author Angelo Rivera
* @date 29.May.2019
* @group Test Class
* @description  This class contains unit tests for validating the behavior of EmailMessageServices methods
 *              these methods are part of the testing framework implemented throughout UniCRM
* @revision     APRivera, 01.Jan.2020, Increased code coverage <br/>
* @revision     25/07/2022 - Matthew Maramot updated to consider header email threading
* @revision     23/01/2024 - Tom Gangemi - SA-2507 - added testMatchOnStatus and cleanup
*/

@isTest(isParallel=true)
private class EmailMessageServices_Test {

    @TestSetup
    static void setup() {
        Environment_Settings__c environmentSettings = Environment_Settings__c.getOrgDefaults();
        environmentSettings.Reopen_Enquiry_Rule_Active__c = true;
        insert environmentSettings;
    }

    /**
     * Test executeEnquiryReopenRules without using EmailMessageTrigger
     */
    @IsTest static void testExecuteEnquiryReopenRules() {
        Case enq1 = TestHelper.webToCaseForms(1)[0];
        RecordTypeInfo rti = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MonCon_Support');
        enq1.RecordTypeId = rti.recordTypeId;
        enq1.Status = 'Solved';
        Case enq2 = enq1.clone();
        enq2.Status = 'Pending Investigation';
        enq2.OwnerId = UserInfo.getUserId();
        Case[] enqs = new Case[]{enq1, enq2};
        TriggerCommon.disableTrigger('Case');
        insert enqs;
        TriggerCommon.enableTrigger('Case');

        Reopen_Enquiry_Rule__mdt rule = new Reopen_Enquiry_Rule__mdt(
            MasterLabel = 'TestRule',
            DeveloperName = 'TestRule',
            Active__c = true,
            Applied_to_Record_Type__c = rti.name,
            Within_Calendar_Days__c = 30,
            Reopen_Enquiry__c = true,
            Assign_to_Queue__c = 'Monash Connect Course Advice',
            Original_Enquiry_Status__c = 'Reopened',
            Assign_Original_as_Parent_Enquiry__c = true
        );
        EmailMessageServices.mockedReopenRules = new Reopen_Enquiry_Rule__mdt[]{rule};

        // Create an email message for each enquiry
        EmailMessage[] messages = new EmailMessage[0];
        for(Case enq : enqs) {
            messages.add(new EmailMessage(
                ParentId = enq.Id,
                FromAddress = 'testfrom@testmonash.edu',
                FromName = 'testSender',
                Subject = 'testSubject',
                TextBody = 'test body',
                ToAddress = 'ask.monash@monash.edu;scenquiries@monash.edu',
                Incoming = true
            ));
        }
        messages.add(messages[0].clone()); // add a third test handling of multiple messages per enquiry

        // Act - Should match and reopen enq1, but not enq2
        EmailMessageServices.executeEnquiryReopenRules(messages);

        // Assert
        Map<Id, Case> results = new Map<Id, Case>([SELECT Status, Reopened__c, OwnerId, Owner.Name FROM Case]);
        Group queue = [SELECT Name FROM Group WHERE Type = 'Queue' AND Name = :rule.Assign_to_Queue__c LIMIT 1];

        // Validate enquiry reopened and getting assigned to queue
        Case enq1Result = results.get(enq1.Id);
        Assert.isTrue(enq1Result.Reopened__c, 'enq1 should have been reopened');
        Assert.areEqual('Reopened', enq1Result.Status);
        Assert.areEqual(queue.Id, enq1Result.OwnerId, 'enq1 should have been assigned to queue'); // error can be due to a change of Transfer_Enquiry_Rule__mdt

        // Validate enquiry did not changed
        Case enq2Result = results.get(enq2.Id);
        Assert.isFalse(enq2Result.Reopened__c, 'enq2 should not have been reopened');
        Assert.areEqual('Pending Investigation', enq2Result.Status);

        // Arrange - create a new rule that will match enq2
        Reopen_Enquiry_Rule__mdt rule2 = rule.clone();
        rule2.Assign_to_Queue__c = null;
        rule2.Included_Non_Closed_Status__c = enq2.Status;
        rule2.Match_on_Non_Closed_Status__c = true;
        EmailMessageServices.mockedReopenRules.add(rule2);

        // Act - Should match and reopen enq2
        EmailMessageServices.executeEnquiryReopenRules(new EmailMessage[]{messages[1]});

        // Assert
        Case enq2Result2 = [SELECT Status, OwnerId, Reopened__c FROM Case WHERE Id = :enq2.Id];
        Assert.isTrue(enq2Result2.Reopened__c, 'enq2 should have been reopened');
        Assert.areEqual('Reopened', enq2Result2.Status);
        Assert.areEqual(enq2.OwnerId, enq2Result2.OwnerId, 'Unexpected owner for enq2');
    }

    @IsTest static void testReopenAsClone() {
        Contact cont = new Contact(LastName = 'TestLastName', Email = 'reopenTest1@example.com');
        insert cont;

        Case enq = TestHelper.webToCaseForms(1)[0];
        enq.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Standard Enquiry').getRecordTypeId();
        enq.Status = 'Solved';
        insert enq;

        Reopen_Enquiry_Rule__mdt rule = new Reopen_Enquiry_Rule__mdt(
            MasterLabel = 'TestRule',
            DeveloperName = 'TestRule',
            Active__c = true,
            Applied_to_Record_Type__c = 'Standard Enquiry',
            Within_Calendar_Days__c = 30,
            Reopen_Enquiry__c = false,
            Assign_to_Queue__c = 'Student Rec Enquiries (Pre-Application)',
            New_Enquiry_Status__c = 'Open',
            Assign_Original_as_Parent_Enquiry__c = true
        );
        EmailMessageServices.mockedReopenRules = new Reopen_Enquiry_Rule__mdt[]{rule};

        //Testing when a customer sent a reply ta an already closed enquiry within 30 days
        Test.startTest();
        EmailMessage em = new EmailMessage(
            ParentId = enq.Id,
            FromAddress = 'testfrom@testmonash.edu',
            FromName = 'testSender',
            Subject = 'testSubject',
            TextBody = 'test body',
            ToAddress = 'ask.monash@monash.edu;scenquiries@monash.edu',
            Headers = 'References: <' + enq.Id + '@sfdc.net>',
            Incoming = true
        );
        insert em;
        Test.stopTest();

        Map<Id, Case> results = new Map<Id, Case>([SELECT ParentId, Status FROM Case]);
        Assert.areEqual(2, results.size());
        Case origEnq = results.remove(enq.Id);
        Case newEnq = results.values()[0];

        Assert.areEqual('Solved', origEnq.Status);
        Assert.areEqual('Open', newEnq.Status);
        Assert.areEqual(origEnq.Id, newEnq.ParentId);
    }

    @IsTest static void testReopenRuleMatching() {
        Reopen_Enquiry_Rule__mdt rule1 = new Reopen_Enquiry_Rule__mdt(
            MasterLabel = 'Test Standard',
            DeveloperName = 'Test_Standard',
            Active__c = true,
            Applied_to_Record_Type__c = 'Standard Enquiry',
            Applied_to_Enquiry_Type__c = 'Course Advice',
            Included_Non_Closed_Status__c = 'Pending Investigation;Awaiting Customer Feedback',
            Reopen_Enquiry__c = true,
            Original_Enquiry_Status__c = 'Reopened',
            Within_Calendar_Days__c = 30,
            Match_on_Non_Closed_Status__c = true
        );
        Reopen_Enquiry_Rule__mdt rule2 = new Reopen_Enquiry_Rule__mdt(
            MasterLabel = 'Test SpecCon',
            DeveloperName = 'Test_SpecCon',
            Active__c = true,
            Applied_to_Record_Type__c = 'Special Consideration',
            Reopen_Enquiry__c = true,
            Original_Enquiry_Status__c = 'Reopened',
            Within_Calendar_Days__c = 30
        );
        EmailMessageServices.mockedReopenRules = new Reopen_Enquiry_Rule__mdt[]{rule1, rule2};

        Map<String, EmailMessageServices.ReopenRuleLookup[]> ruleLookups =
            EmailMessageServices.createReopenRuleLookups(EmailMessageServices.mockedReopenRules);

        String c1Json = '{"RecordType":{"Name":"Standard Enquiry"},"Enquiry_Type__c" : "Course Advice", "IsClosed": true}';
        String c2Json = '{"RecordType":{"Name":"Standard Enquiry"},"Enquiry_Type__c" : "Course Advice", "IsClosed": false}';
        Case c1 = (Case)JSON.deserialize(c1Json, Case.class);
        c1.Status = 'Closed';
        Case c2 = (Case)JSON.deserialize(c2Json, Case.class);
        c2.Status = 'Awaiting Customer Feedback';

        // Act
        Reopen_Enquiry_Rule__mdt c1Rule = EmailMessageServices.findBestReopenRule(ruleLookups, c1);
        Reopen_Enquiry_Rule__mdt c2Rule = EmailMessageServices.findBestReopenRule(ruleLookups, c2);

        // Assert
        Assert.isNull(c1Rule, 'Case 1 should not have found a rule');
        Assert.areEqual(rule1.DeveloperName, c2Rule.DeveloperName, 'Case 2 should have matched rule 1');
    }

    @IsTest static void confirmEmailMapping(){
        TestHelper.calabrioSetUp();

        List<Contact> testContacts = TestHelper.createStudentContacts(2, null);

        insert testContacts;

        Set<Id> testContactIds = new Set<Id>();
        for(Contact testContact : testContacts) testContactIds.add(testContact.Id);
        //Anterey Custodio, 23.Jan.2017 - added recordtype to sample data
        RecordTypes_Allowed_on_CaseTrigger__c recTypesAllowed = new RecordTypes_Allowed_on_CaseTrigger__c();
        recTypesAllowed.Name = 'Standard Enquiry';
        recTypesAllowed.API_Name__c = 'Standard Enquiry';
        insert recTypesAllowed;

        QueueList__c queueListRec = new QueueList__c();
        queueListRec.Name = 'Schools Engagement';
        queueListRec.Retain_Owner__c = true;
        insert queueListRec;

        String enquiryRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Standard Enquiry').getRecordTypeId();
        List<case> cases = new List<case>();
        for(integer i=0; i<2; i++){
            cases.add(new case(SuppliedName = 'testName',
                    SuppliedPhone = '0400000000',
                    SuppliedEmail = 'testformEmail@monash.edu',
                    Type = 'Web',
                    Origin = 'Email - System',
                    Case_type__c = 'Standard Enquiry',
                    ContactId = null,
                    AccountId = null,
                    Course_code__c = '0',
                    Status = 'Closed',
                    RecordTypeId = enquiryRecordType,
                    Case_Queue_Name__c = 'Schools Engagement'));
        }

        insert cases;
        cases[0].Origin = 'Email'; // telephony forces default to phone. need to use update
        cases[1].Origin = 'Email - System'; // telephony forces default to phone. need to use update

        Test.startTest();

        update cases;
        Case cas = [SELECT Case_Reference__c,IsClosed FROM Case WHERE Id =:cases[0].Id];
        List<EmailMessage> em1 = new List<EmailMessage>();
		List<EmailMessage> em2 = new List<EmailMessage>();

        For(Case c : cases) {
			// Email with MessageIdentifier linked to case
			em1.add(new EmailMessage(ParentId = cas.Id,
					FromAddress = 'testfrom@testmonash.edu',
					FromName = 'testSender',
					Subject = 'testSubject',
					TextBody = 'test body',
					MessageIdentifier = '<'+cas.Id + '@sfdc.net>',
					ToAddress = 'testEndpoint@monash.edu'
					));
		}
		insert em1;
        Assert.areEqual(0, EmailMessageServices.reopenRulesRunCount);

        // Creating email header values
		List<String> em2HeaderList = new List<String>{
            'In-Reply-To: <' + cas.Id + '@sfdc.net>',
            'References: <' + cas.Id + '@sfdc.net>'
        };

        // Two incoming emails both linked to cas
        em2.add(new EmailMessage(
            FromAddress = 'testfrom@testmonash.edu',
            FromName = 'testSender',
            Subject = 'testSubject',
            TextBody = 'test body',
            Headers = String.join(em2HeaderList, '\n'),
            ToAddress = 'testEndpoint@monash.edu',
            Incoming = true
        ));
        em2.add(em2.get(0).clone());

        insert em2;
        Assert.areEqual(1, EmailMessageServices.reopenRulesRunCount);

        Test.stopTest();

        system.assertEquals(false,[select id,IsClosed from case where id =:cases[0].id limit 1].IsClosed,'inbound should have opened case'); // non system
        system.assertEquals(true,[select id,IsClosed from case where id =:cases[1].id limit 1].IsClosed,'inbound should not have reopened case'); // system
        cas= [select id,Case_Reference__c,IsClosed from case where id =:cases[1].id limit 1];

        EmailMessage em3 = new EmailMessage(ParentId = cas.id,
                FromAddress = 'testfrom@testmonash.edu',
                FromName = 'testSender',
                HTMLBody = 'test',
                Subject = 'testSubject',
                TextBody = 'test body',
                MessageIdentifier = '<'+cas.id + '@sfdc.net>',
                ToAddress = 'testEndpoint@monash.edu'
                );
        insert em3;
        Assert.areEqual(1, EmailMessageServices.reopenRulesRunCount);

        // Creating email header values
        List<String> headerList = new List<String>();
		headerList.add('In-Reply-To: <' + cas.id + '@sfdc.net>');
		headerList.add('References: <' + cas.id + '@sfdc.net>');

		// Incoming email 
		EmailMessage em4 = new EmailMessage(FromAddress = 'testfrom@testmonash.edu',
				FromName = 'testSender',
				HTMLBody = 'test',
				Subject = 'testSubject',
				TextBody = 'test body',
				Headers = String.join(headerList, '\n'),
				ToAddress = 'testEndpoint@monash.edu',
				Incoming = true);
		insert em4;
        Assert.areEqual(2, EmailMessageServices.reopenRulesRunCount);

        system.assertEquals(false,[select id,IsClosed from case where id =:cases[1].id limit 1].IsClosed,'inbound should have opened case'); // system 2nd inbound email
        Set<id> caseIds = new Set<id>();
    }

    /**
     * @updated by      Kristian Vegerano
     * @description     Testing legacy reopening for HR - from In Progress to Updated after email received
     *                  Splitted from original method testHREnquiries
     * @revision        25/07/2022 - Matthew Maramot updated to consider header email threading
     */
    @IsTest static void testHREnquiriesInProgressToUpdated(){
        Contact testContact = new Contact(LastName = 'TestLastName', Email = 'testfrom@testmonash.edu');
        insert testContact;

        List<Case> caseList = TestHelper.webToCaseForms(1);
        System.assertEquals(caseList.size(), 1);

        caseList[0].status = 'In Progress';
        caseList[0].recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HR').getRecordTypeId();
        caseList[0].Channel__c = 'Email';
        insert caseList;

        User systemAdmin =  [SELECT Id FROM User WHERE Name = 'System Admin'];
        Test.startTest();
        EmailMessage msg;
		EmailMessage msg2;
        system.runAs(systemAdmin) {
            msg = new EmailMessage(ParentId = caseList[0].id,
                    FromAddress = 'testfrom@testmonash.edu',
                    FromName = 'testSender',
                    Subject = 'testSubject',
                    TextBody = 'test body',
                    MessageIdentifier = '<'+caseList[0].id + '@sfdc.net>',
                    ToAddress = 'hr@monash.edu');
            insert msg;
            Assert.areEqual(0, EmailMessageServices.reopenRulesRunCount);

            // Creating email header values
			List<String> headerList = new List<String>();
			headerList.add('In-Reply-To: <' + caseList[0].id + '@sfdc.net>');
			headerList.add('References: <' + caseList[0].id + '@sfdc.net>');

			// Incoming email 
			msg2 = new EmailMessage(FromAddress = 'testfrom@testmonash.edu',
					FromName = 'testSender',
					Subject = 'testSubject',
					TextBody = 'test body',
					Headers = String.join(headerList, '\n'),
					ToAddress = 'hr@monash.edu',
					Incoming = true);
			insert msg2;
            Assert.areEqual(1, EmailMessageServices.reopenRulesRunCount);
        }
        Test.stopTest();

        Case c = [select id, status from case where id = :caseList[0].Id];
        system.assertEquals('Updated', c.status, 'status should be Updated' );
    }

    /**
     * @updated by      Kristian Vegerano
     * @description     Testing legacy reopening for HR - from Closed to Reopened after email received
     *                  Splitted from original method testHREnquiries
     * @revision        25/07/2022 - Matthew Maramot updated to consider header email threading
     */
    @IsTest static void testHREnquiriesClosedToReopened() {
        Contact testContact = new Contact(LastName = 'TestLastName', Email = 'testfrom@testmonash.edu');
        insert testContact;

        Case testParentEnquiry = new Case();
        insert testParentEnquiry;

        List<Case> caseList = TestHelper.webToCaseForms(1);
        System.assertEquals(caseList.size(), 1);

        //Retrieve HR Queue
        Group generalHR;
        for(Group loopGroup : [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'General_HR']){
            generalHR = loopGroup;
        }

        //Assign the enquiry to hr queue
        caseList[0].parentId = testParentEnquiry.Id;
        caseList[0].ownerId = generalHR.Id;
        caseList[0].status = 'Closed';
        caseList[0].recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HR').getRecordTypeId();
        caseList[0].Channel__c = 'Email';
        insert caseList;

        User systemAdmin =  [SELECT Id FROM User WHERE Name = 'System Admin'];
        Test.startTest();
        EmailMessage msg;
        EmailMessage msg2;
        system.runAs(systemAdmin) {
            msg = new EmailMessage(ParentId = caseList[0].id,
                    FromAddress = 'testfrom@testmonash.edu',
                    FromName = 'testSender',
                    Subject = 'testSubject',
                    TextBody = 'test body',
                    MessageIdentifier = '<'+caseList[0].id + '@sfdc.net>',
                    ToAddress = 'hr@monash.edu');
            insert msg;
            Assert.areEqual(0, EmailMessageServices.reopenRulesRunCount);

            // Creating email header values
			List<String> headerList = new List<String>();
			headerList.add('In-Reply-To: <' + caseList[0].id + '@sfdc.net>');
			headerList.add('References: <' + caseList[0].id + '@sfdc.net>');
			
			// Incoming email 
			msg2 = new EmailMessage(FromAddress = 'testfrom@testmonash.edu',
					FromName = 'testSender',
					Subject = 'testSubject',
					TextBody = 'test body',
					Headers = String.join(headerList, '\n'),
					ToAddress = 'hr@monash.edu',
					Incoming = true);
			insert msg2;
            Assert.areEqual(1, EmailMessageServices.reopenRulesRunCount);
        }
        Test.stopTest();

        Case c = [select id, status from case where id = :caseList[0].Id];
        system.assertEquals('Reopened', c.status, 'enquiry should have re-opened');
    }


    private static Reopen_Enquiry_Rule__mdt createHrRule() {
        return new Reopen_Enquiry_Rule__mdt(
            MasterLabel = 'Test Rule',
            DeveloperName = 'Test_Rule',
            Active__c = true,
            Applied_to_Record_Type__c = 'HR',
            Use_Assignment_Rules__c = true,
            Reopen_Enquiry__c = true,
            Create_Internal_Case_Comment__c = true,
            Assign_Original_as_Parent_Enquiry__c = true,
            Original_Enquiry_Status__c = 'Reopened',
            Within_Calendar_Days__c = 30,
            Use_EmailToCase_Mapping__c = true,
            Original_Enquiry_Priority__c = 'High'
        );
    }
    /**
     * @author             Kristian Vegerano
     * @description        Testing reopening standard enquiry within 30 days
     */
    @IsTest static void testReopenWithinDays() {
        Contact cont = new Contact(LastName = 'TestLastName', Email = 'testfrom@testmonash.edu');
        insert cont;

        Id hrRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('HR').getRecordTypeId();

        //Create a test enquiry
        Case enquiry = TestHelper.webToCaseForms(1)[0];
        enquiry.RecordTypeId = hrRtId;
        enquiry.Status = 'Solved'; // Close the enquiry
        insert enquiry;

        EmailMessageServices.mockedReopenRules = new Reopen_Enquiry_Rule__mdt[]{createHrRule()};

        //Testing when a customer sent a reply ta an already closed enquiry within 30 days
        Test.startTest();
        EmailMessage testIncomingEmail = new EmailMessage(
            ParentId = enquiry.Id,
            FromAddress = 'testfrom@testmonash.edu',
            FromName = 'testSender',
            Subject = 'testSubject',
            TextBody = 'test body',
            ToAddress = 'ask.monash@monash.edu;scenquiries@monash.edu',
            Headers = 'References: <' + enquiry.Id + '@sfdc.net>',
            Incoming = true
        );
        // Act
        insert testIncomingEmail;
        Test.stopTest();

        // Assert
        Assert.areEqual(1, EmailMessageServices.reopenRulesRunCount);

        Case result = [SELECT Status, Reopened__c FROM Case WHERE Id = :enquiry.Id];
        Assert.areEqual('Reopened', result.Status);
        Assert.isTrue(result.Reopened__c);
    }

    /**
     * @author             Kristian Vegerano
     * @description        Testing reopening standard enquiry after 30 day cutoff
     */
    @IsTest static void testReopenOutsideDays() {
        Contact cont = new Contact(LastName = 'TestLastName', Email = 'testfrom@testmonash.edu');
        insert cont;

        Group generalHRQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'General_HR' LIMIT 1];
        Id hrRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('HR').getRecordTypeId();

        //Create a test enquiry
        Case enquiry = TestHelper.webToCaseForms(1)[0];
        enquiry.RecordTypeId = hrRtId;
        enquiry.Status = 'Solved';
        enquiry.CreatedDate = Datetime.now().addDays(-32);
        enquiry.ClosedDate = Datetime.now().addDays(-31);
        enquiry.OwnerId = generalHRQueue.Id;
        enquiry.Latest_Unassigned_Queue_OwnerId__c = generalHRQueue.Id;
        insert enquiry;

        EmailMessageServices.mockedReopenRules = new Reopen_Enquiry_Rule__mdt[]{createHrRule()};

        //Testing when a customer sent a reply ta an already closed enquiry within 30 days
        Test.startTest();
        EmailMessage testIncomingEmail = new EmailMessage(
            ParentId = enquiry.Id,
            FromAddress = 'testfrom@testmonash.edu',
            FromName = 'testSender',
            Subject = 'testSubject',
            TextBody = 'test body',
            ToAddress = 'ask.monash@monash.edu',
            Headers = 'References: <' + enquiry.Id + '@sfdc.net>',
            Incoming = true
        );
        // Act
        insert testIncomingEmail;
        Test.stopTest();

        // Assert
        Assert.areEqual(1, EmailMessageServices.reopenRulesRunCount);

        Case result = [SELECT Status FROM Case WHERE Id = :enquiry.Id];
        Assert.areEqual(enquiry.Status, result.Status);
    }

    /**
     * @author                      Kristian Vegerano
     * @description                 Testing of pushing email message html body pushed to parent enquiry's rich_description__c field
     */
    @IsTest static void testPushEmailHtmlBodyToRichDescription(){
        //Create a test enquiry
        Case testEnquiry = TestHelper.webToCaseForms(1)[0];
        testEnquiry.createdDate = System.TODAY().addDays(-32);
        testEnquiry.closedDate = System.TODAY().addDays(-31);
        insert testEnquiry;

        //Testing when a customer sent a reply ta an already closed enquiry within 30 days
        Test.startTest();
        EmailMessage testIncomingEmail = new EmailMessage(ParentId = testEnquiry.id,
                FromAddress = 'testfrom@testmonash.edu',
                FromName = 'testSender',
                Subject = 'testSubject',
                TextBody = 'test body',
                HtmlBody = 'test html body',
                ToAddress = 'ask.monash@monash.edu',
                Incoming = true);
        insert testIncomingEmail;
        Test.stopTest();

        //Assert that the html body has been populated correctly
        System.assertEquals(testIncomingEmail.HtmlBody, [SELECT Id, Status, Rich_Description__c FROM Case WHERE Id = :testEnquiry.Id].Rich_Description__c,'html body of email does not match rich description in case');
    }

    /**
     * @author          Kristian Vegerano
     * @description     Tests enquiry's email redirection rules when incoming email is from internal sender
     * @revision        25/07/2022 - Matthew Maramot updated to consider header email threading
     */
    @IsTest static void testEmailMessageInsideRedirectionRule(){
        EmailRoutingAddress testRoutingAddress = new EmailRoutingAddress(Id = fflib_IDGenerator.generate(EmailRoutingAddress.SObjectType),
																			Address = 'disabilitysupportservices@test-monash.edu');
		EmailMessageUtility.testEmailRoutingAddressMap = new Map<Id, EmailRoutingAddress>{testRoutingAddress.Id => testRoutingAddress};

        //Create new rule to be tested
        List<Redirection_Enquiry_Rule__mdt> testRulesList = new List<Redirection_Enquiry_Rule__mdt>();
        testRulesList.add(new Redirection_Enquiry_Rule__mdt(MasterLabel = 'TestRedirectionRule',
                DeveloperName = 'TestRedirectionRule',
                Active__c = true,
                Clear_Related_Contact__c = false,
                From_Enquiry_Record_Type__c = 'Admissions',
                Redirected_Origin__c = 'Email - Disability Support Services',
                Redirected_Queue__c = 'DSS_Enquiries',
                Redirected_Status__c = 'Open',
                Redirected_Student_Type__c = '',
                Target_Email_Address__c = 'disabilitysupportservices@',
                Target_Enquiry_Record_Type__c = 'DSS_Enquiry'));

        //Insert email messages
        Map<Id, EmailMessage> testEmailMap = new Map<Id, EmailMessage>();

        //Retrieve Redirection Queues
        Map<Id, Group> queueMap = new Map<Id, Group>();
        for(Group loopGroup : EmailMessageUtility.retrieveEmailRedirectionQueueMap(testRulesList).values()){
            queueMap.put(loopGroup.Id, loopGroup);
        }

        //Create a test enquiry
        List<Case> caseList = new List<Case>();
        for(Redirection_Enquiry_Rule__mdt loopRule : testRulesList){
            Case testCase = TestHelper.webToCaseForms(1)[0];
            testCase.createdDate = System.TODAY().addDays(-32);
            testCase.closedDate = System.TODAY().addDays(-31);
            testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(loopRule.From_Enquiry_Record_Type__c).getRecordTypeId();

            caseList.add(testCase);
        }
        insert caseList;

        //Test redirecting enquiries
        Test.startTest();
        List<EmailMessage> messageidEmails = new List<EmailMessage>();
		for(Case cas : caseList){
			messageidEmails.add(new EmailMessage( ParentId = cas.id,
					FromAddress = 'testfrom@testmonash.edu',
					FromName = 'testSender',
					Subject = 'testSubject',
					TextBody = 'test body',
                    HTMLBody = 'HTML body',
					MessageIdentifier = '<'+cas.id + '@sfdc.net>',
					ToAddress = 'testEndpoint@monash.edu'
					));
		}
		insert messageidEmails;

        Integer counter = 0;
        for(Redirection_Enquiry_Rule__mdt loopRule : testRulesList){
            // Creating email header values
			List<String> headerList = new List<String>();
			headerList.add('In-Reply-To: <' + caseList[counter].id + '@sfdc.net>');
			headerList.add('References: <' + caseList[counter].id + '@sfdc.net>');

            testEmailMap.put(caseList[counter].id, new EmailMessage(FromAddress = 'testfrom@f.e.testmonash.edu',
                    FromName = 'testSender',
                    Subject = 'testSubject',
                    TextBody = 'test body ',
                    HtmlBody = 'test html body ',
                    MessageIdentifier = 'testIdValue' + caseList[counter].id,
                    Headers = String.join(headerList, '\n'),
                    ToAddress = loopRule.Target_Email_Address__c + 'test-monash.edu',
                    EmailRoutingAddressId = testRoutingAddress.Id,
                    Incoming = true));
            counter = counter + 1;
        }

        if(testEmailMap.size() > 0){
            insert testEmailMap.values();
        }
        Test.stopTest();

        //Re-query emailmessages size when the incoming email is sent from outside
        //Original email is redirected
        System.assertEquals(2, [SELECT Id, ParentId FROM EmailMessage].size(), 'Number of email message is mismatched than expected.');
    }

    /**
     * @author          Kristian Vegerano
     * @description     Tests enquiry's email redirection rules when incoming email is from outside sender
     * @revision        25/07/2022 - Matthew Maramot updated to consider header email threading
     */
    @isTest
    static void testEmailMessageOutsideRedirectionRule(){
        EmailRoutingAddress testRoutingAddress = new EmailRoutingAddress(Id = fflib_IDGenerator.generate(EmailRoutingAddress.SObjectType),
																			Address = 'disabilitysupportservices@test-monash.edu');
		EmailMessageUtility.testEmailRoutingAddressMap = new Map<Id, EmailRoutingAddress>{testRoutingAddress.Id => testRoutingAddress};
        
        //Create new rule to be tested
        List<Redirection_Enquiry_Rule__mdt> testRulesList = new List<Redirection_Enquiry_Rule__mdt>();
        testRulesList.add(new Redirection_Enquiry_Rule__mdt(MasterLabel = 'TestRedirectionRule',
                DeveloperName = 'TestRedirectionRule',
                Active__c = true,
                Clear_Related_Contact__c = false,
                From_Enquiry_Record_Type__c = 'Admissions',
                Redirected_Origin__c = 'Email - Disability Support Services',
                Redirected_Queue__c = 'DSS_Enquiries',
                Redirected_Status__c = 'Open',
                Redirected_Student_Type__c = '',
                Target_Email_Address__c = 'disabilitysupportservices@',
                Target_Enquiry_Record_Type__c = 'DSS_Enquiry'));

        //Insert email messages
        Map<Id, EmailMessage> testEmailMap = new Map<Id, EmailMessage>();

        //Retrieve Redirection Queues
        Map<Id, Group> queueMap = new Map<Id, Group>();
        for(Group loopGroup : EmailMessageUtility.retrieveEmailRedirectionQueueMap(testRulesList).values()){
            queueMap.put(loopGroup.Id, loopGroup);
        }

        //Create a test enquiry
        List<Case> caseList = new List<Case>();
        for(Redirection_Enquiry_Rule__mdt loopRule : testRulesList){
            Case testCase = TestHelper.webToCaseForms(1)[0];
            testCase.createdDate = System.TODAY().addDays(-32);
            testCase.closedDate = System.TODAY().addDays(-31);
            testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(loopRule.From_Enquiry_Record_Type__c).getRecordTypeId();

            caseList.add(testCase);
        }
        insert caseList;

        List<EmailMessage> messageidEmails = new List<EmailMessage>();
		for(Case cas : caseList){
			messageidEmails.add(new EmailMessage( ParentId = cas.id,
					FromAddress = 'testfrom@testmonash.edu',
					FromName = 'testSender',
					Subject = 'testSubject',
					TextBody = 'test body',
					MessageIdentifier = '<'+cas.id + '@sfdc.net>',
					ToAddress = 'testEndpoint@monash.edu'
					));
		}
		insert messageidEmails;

        //Test redirecting enquiries
        Test.startTest();
        Integer counter = 0;
        for(Redirection_Enquiry_Rule__mdt loopRule : testRulesList){
            // Creating email header values
			List<String> headerList = new List<String>();
			headerList.add('In-Reply-To: <' + caseList[counter].id + '@sfdc.net>');
			headerList.add('References: <' + caseList[counter].id + '@sfdc.net>');

            testEmailMap.put(caseList[counter].id, new EmailMessage(FromAddress = 'testfrom@testmonash.edu',
                    FromName = 'testSender',
                    Subject = 'testSubject',
                    TextBody = 'test body ',
                    HtmlBody = 'test html body ',
                    MessageIdentifier = 'testIdValue' + caseList[counter].id,
                    Headers = String.join(headerList, '\n'),
                    ToAddress = loopRule.Target_Email_Address__c + 'test-monash.edu',
                    EmailRoutingAddressId = testRoutingAddress.Id,
                    Incoming = true));
            counter = counter + 1;
        }

        if(testEmailMap.size() > 0){
            insert testEmailMap.values();
        }
        Test.stopTest();

        //Re-query emailmessages size when the incoming email is sent from outside
        //Original email is retained to the original enquiry
        System.assertEquals(3, [SELECT Id, ParentId FROM EmailMessage].size(), 'Number of email message is mismatched than expected.');
    }

    @isTest
    static void testExecuteEnquiryReopenRulesTrigger() {
        //Create new rule to be tested
        List<Redirection_Enquiry_Rule__mdt> testRulesList = new List<Redirection_Enquiry_Rule__mdt>();
        testRulesList.add(new Redirection_Enquiry_Rule__mdt(MasterLabel = 'TestRedirectionRule',
                DeveloperName = 'TestRedirectionRule',
                Active__c = true,
                Clear_Related_Contact__c = false,
                From_Enquiry_Record_Type__c = 'Admissions',
                Redirected_Origin__c = 'Email - Disability Support Services',
                Redirected_Queue__c = 'DSS_Enquiries',
                Redirected_Status__c = 'Open',
                Redirected_Student_Type__c = '',
                Target_Email_Address__c = 'disabilitysupportservices@',
                Target_Enquiry_Record_Type__c = 'DSS_Enquiry'));

        //Insert email messages
        Map<Id, EmailMessage> testEmailMap = new Map<Id, EmailMessage>();

        //Retrieve Redirection Queues
        Map<Id, Group> queueMap = new Map<Id, Group>();
        for(Group loopGroup : EmailMessageUtility.retrieveEmailRedirectionQueueMap(testRulesList).values()){
            queueMap.put(loopGroup.Id, loopGroup);
        }

        //Create a test enquiry
        List<Case> caseList = new List<Case>();
        Case testCase = TestHelper.webToCaseForms(1)[0];
        testCase.createdDate = System.TODAY().addDays(-32);
        testCase.closedDate = System.TODAY().addDays(-31);
        testCase.RecordTypeId = StudRecCaseServices.POST_APPLICATION_RECTYPEID;
        testCase.Latest_Unassigned_Queue_OwnerId__c = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'General_HR'].Id;
        caseList.add(testCase);
        insert caseList;

        //Test redirecting enquiries
        Test.startTest();
        List<EmailMessage> messageidEmails = new List<EmailMessage>();
		for(Case cas : caseList){
			messageidEmails.add(new EmailMessage( ParentId = cas.id,
					FromAddress = 'testfrom@testmonash.edu',
					FromName = 'testSender',
					Subject = 'testSubject',
					TextBody = 'test body',
					MessageIdentifier = '<'+cas.id + '@sfdc.net>',
					ToAddress = 'testEndpoint@monash.edu'
					));
		}
		insert messageidEmails;

        Integer counter = 0;
        for(Redirection_Enquiry_Rule__mdt loopRule : testRulesList){
            // Creating email header values
			List<String> headerList = new List<String>();
			headerList.add('In-Reply-To: <' + caseList[counter].id + '@sfdc.net>');
			headerList.add('References: <' + caseList[counter].id + '@sfdc.net>');

            testEmailMap.put(caseList[counter].id, new EmailMessage(FromAddress = 'testfrom@f.e.testmonash.edu',
                    FromName = 'testSender',
                    Subject = 'testSubject',
                    TextBody = 'test body ',
                    HtmlBody = 'test html body ',
                    Headers = String.join(headerList, '\n'),
                    ToAddress = loopRule.Target_Email_Address__c + 'test.com',
                    Incoming = true));
            counter = counter + 1;
        }

        if(testEmailMap.size() > 0){
            insert testEmailMap.values();
        }
        Test.stopTest();

        //Re-query emailmessages size when the incoming email is sent from outside
        //Original email is redirected
        System.assertEquals(2, [SELECT Id, ParentId FROM EmailMessage].size(), 'Number of email message is mismatched than expected.');
    }
}