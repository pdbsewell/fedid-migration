/**
* @author Angelo Rivera
* @date 29.May.2019
* @group Test Class
* @description  This class contains unit tests for validating the behavior of EmailMessageServices methods
 *              these methods are part of the testing framework implemented throughout UniCRM
* @revision     APRivera, 01.Jan.2020, Increased code coverage <br/>
*/

@isTest(isParallel=true)
private class EmailMessageUtility_Test {
	private static Application__c appRecord;
	private static User communityUserRec;
	private static Contact contactRec;
	private static Application_Course_Preference__c coursePrefA;
	private static Application_Course_Preference__c coursePrefB;
	private static Course_Offering__c courseOfferingRec;
	private static Course_Offering__c courseOfferingRecNoUnit;

	@testSetup
	static void setup() {
		Environment_Settings__c environmentSettings = Environment_Settings__c.getOrgDefaults();
		environmentSettings.Reopen_Enquiry_Rule_Active__c = true;
		insert environmentSettings;
	}

	static testMethod void confirmEmailMapping(){
		TestHelper.calabrioSetUp();

		List<Contact> testContacts = TestHelper.createStudentContacts(2, null);

		insert testContacts;

		system.assertEquals(2,[select COUNT() from Contact],'test contacts not inserted');

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
		case cas= [select id,Case_Reference__c,IsClosed from case where id =:cases[0].id limit 1];
		List<EmailMessage> em1 = new List<EmailMessage>();
		List<EmailMessage> em2 = new List<EmailMessage>();
		
		For(case c : cases) {		
			// Email with MessageIdentifier linked to case
			em1.add(new EmailMessage( ParentId = cas.id,
					FromAddress = 'testfrom@testmonash.edu',
					FromName = 'testSender',
					Subject = 'testSubject',
					TextBody = 'test body',
					MessageIdentifier = '<'+cas.id + '@sfdc.net>',
					ToAddress = 'testEndpoint@monash.edu'
					));
		}
		insert em1;

		// Creating email header values
		List<String> headerList = new List<String>();
		headerList.add('In-Reply-To: <' + cas.id + '@sfdc.net>');
		headerList.add('References: <' + cas.id + '@sfdc.net>');

		For(case c : cases) {		
			// Incoming email 
			em2.add(new EmailMessage(FromAddress = 'testfrom@testmonash.edu',
				FromName = 'testSender',
				Subject = 'testSubject',
				TextBody = 'test body',
				Headers = String.join(headerList, '\n'),
				ToAddress = 'testEndpoint@monash.edu',
				Incoming = true));
		}
		insert em2;
		
		Test.stopTest();

		system.assertEquals(false,[select id,IsClosed from case where id =:cases[0].id limit 1].IsClosed,'inbound should have opened case'); // non system
		system.assertEquals(true,[select id,IsClosed from case where id =:cases[1].id limit 1].IsClosed,'inbound should not have reopened case'); // system
		cas= [select id,Case_Reference__c,IsClosed from case where id =:cases[1].id limit 1];
		
		// Email with MessageIdentifier linked to case
		EmailMessage em3 = new EmailMessage(ParentId = cas.id,
				FromAddress = 'testfrom@testmonash.edu',
				FromName = 'testSender',
				HTMLBody = 'test',
				Subject = 'testSubject',
				TextBody = 'test body',
				MessageIdentifier = '<'+cas.id + '@sfdc.net>',
				ToAddress = 'testEndpoint@monash.edu');
		insert em3;

		// Creating email header values
		headerList = new List<String>();
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
		
		system.assertEquals(false,[select id,IsClosed from case where id =:cases[1].id limit 1].IsClosed,'inbound should have opened case'); // system 2nd inbound email
		Set<id> caseIds = new Set<id>();
	}

	/**
	 * @updated by      Kristian Vegerano
	 * @description     Testing legacy reopening for HR - from In Progress to Updated after email received
	 *                  Splitted from original method testHREnquiries
	 * @revision     	25/07/2022 - Matthew Maramot updated to consider header email threading
	 */
	static testMethod void testHREnquiriesInProgressToUpdated(){
		Contact testContact = new Contact(LastName = 'TestLastName',
				Email = 'testfrom@testmonash.edu');
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
			// Email with MessageIdentifier linked to case
			msg = new EmailMessage(ParentId = caseList[0].id,
					FromAddress = 'testfrom@testmonash.edu',
					FromName = 'testSender',
					Subject = 'testSubject',
					TextBody = 'test body',
					MessageIdentifier = '<'+caseList[0].id + '@sfdc.net>',
					ToAddress = 'hr@monash.edu',
					Incoming = true);
			insert msg;

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
		}
		Test.stopTest();

		Case c = [select id, status from case where id = :caseList[0].Id];
		system.assertEquals('Updated', c.status, 'status should be Updated');
	}

	/**
	 * @updated by      Kristian Vegerano
	 * @description     Testing legacy reopening for HR - from Closed to Reopened after email received
	 *                  Splitted from original method testHREnquiries
	 * @revision     	25/07/2022 - Matthew Maramot updated to consider header email threading
	 */
	static testMethod void testHREnquiriesClosedToReopened(){
		Contact testContact = new Contact(LastName = 'TestLastName',
				Email = 'testfrom@testmonash.edu');
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
			// Email with MessageIdentifier linked to case
			msg = new EmailMessage(ParentId = caseList[0].id,
					FromAddress = 'testfrom@testmonash.edu',
					FromName = 'testSender',
					Subject = 'testSubject',
					TextBody = 'test body',
					MessageIdentifier = '<'+caseList[0].id + '@sfdc.net>',
					ToAddress = 'hr@monash.edu',
					Incoming = true);
			insert msg;

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
		}
		Test.stopTest();

		Case c = [select id, status from case where id = :caseList[0].Id];
		system.assertEquals('Reopened', c.status, 'enquiry should have re-opened');
	}

	/**
	 * @author                      Kristian Vegerano
	 * @description                 Testing reopening standard enquiry within 30 days
	 */
	static TestMethod void testReopenWithinDays(){
		Contact testContact = new Contact(LastName = 'TestLastName',
				Email = 'testfrom@testmonash.edu');
		insert testContact;

		//Create a test enquiry
		Case testEnquiry = TestHelper.webToCaseForms(1)[0];
		insert testEnquiry;

		//Close the enquiry
		testEnquiry.status = 'Solved';
		update testEnquiry;

		//Testing when a customer sent a reply ta an already closed enquiry within 30 days
		Test.startTest();
		EmailMessage testIncomingEmail = new EmailMessage(ParentId = testEnquiry.id,
				FromAddress = 'testfrom@testmonash.edu',
				FromName = 'testSender',
				Subject = 'testSubject',
				TextBody = 'test body',
				ToAddress = 'ask.monash@monash.edu;scenquiries@monash.edu',
				Incoming = true);
		insert testIncomingEmail;
		Test.stopTest();
	}

	/**
	 * @author                      Kristian Vegerano
	 * @description                 Testing reopening standard enquiry within 30 days
	 */
	static TestMethod void testReopenOutsideDays(){
		Contact testContact = new Contact(LastName = 'TestLastName',
				Email = 'testfrom@testmonash.edu');
		insert testContact;

		Group generalHRQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'General_HR' LIMIT 1];
		RecordType hrRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'HR' AND SobjectType = 'Case'];

		//Create a test enquiry
		Case testEnquiry = TestHelper.webToCaseForms(1)[0];
		testEnquiry.RecordTypeId = hrRecordType.Id;
		testEnquiry.status = 'Solved';
		testEnquiry.createdDate = System.TODAY().addDays(-32);
		testEnquiry.closedDate = System.TODAY().addDays(-31);
		testEnquiry.ownerId = generalHRQueue.Id;
		testEnquiry.Latest_Unassigned_Queue_OwnerId__c = generalHRQueue.Id;
		insert testEnquiry;

		//Testing when a customer sent a reply ta an already closed enquiry within 30 days
		Test.startTest();
		EmailMessage testIncomingEmail = new EmailMessage(ParentId = testEnquiry.id,
				FromAddress = 'testfrom@testmonash.edu',
				FromName = 'testSender',
				Subject = 'testSubject',
				TextBody = 'test body',
				ToAddress = 'ask.monash@monash.edu',
				Incoming = true);
		insert testIncomingEmail;
		Test.stopTest();
	}

	/**
	 * @author                      Kristian Vegerano
	 * @description                 Testing of pushing email message html body pushed to parent enquiry's rich_description__c field
	 */
	static TestMethod void testPushEmailHtmlBodyToRichDescription(){
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
	 * @revision     	25/07/2022 - Matthew Maramot updated to consider header email threading
	 */
	@isTest
	static void testEmailMessageInsideRedirectionRule(){
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
	 * @revision     	25/07/2022 - Matthew Maramot updated to consider header email threading
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
					HTMLBody = 'test body',
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
	static void testExecuteEnquiryReopenRules(){
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

	
	@isTest
	static void testGetTargetEmailToRedirectionRuleMap(){

		//GIVEN: Redirection rule metadata exists

		Test.startTest();
		//WHEN: getTargetEmailToRedirectionRuleMap function is called
		Map<String, Redirection_Enquiry_Rule__mdt> targetEmailToRedirectionRuleMap = EmailMessageUtility.getTargetEmailToRedirectionRuleMap();
		Test.stopTest();

		//THEN: map fetches metadata and has records
		System.assertEquals(targetEmailToRedirectionRuleMap.size() > 0, true);
	}

	@isTest
	static void testGetEmailRoutingAddressMap(){

		//GIVEN: an existing email to case config exists
		EmailRoutingAddress testRoutingAddress = new EmailRoutingAddress(Id = fflib_IDGenerator.generate(EmailRoutingAddress.SObjectType),
																			Address = 'mgro-apply@test-monash.edu');
		EmailMessageUtility.testEmailRoutingAddressMap = new Map<Id, EmailRoutingAddress>{testRoutingAddress.Id => testRoutingAddress};

		Test.startTest();
		//WHEN: a new email message comes in via that Email Routing Address
		EmailMessage emailMsg = new EmailMessage(EmailRoutingAddressId = testRoutingAddress.Id);
		EmailRoutingAddress routingAddress = EmailMessageUtility.getEmailRoutingAddressMap(new List<EmailMessage> {emailMsg}).values()[0];
		Test.stopTest();

		//THEN: we should be able to retrieve the Email Routing Address Information
		//      to identify which email address the email message was sent to 
		System.assertEquals(testRoutingAddress.Id, routingAddress.Id);
		System.assertEquals(testRoutingAddress.Address, routingAddress.Address);
	}

	@isTest
	static void testCleanRoleAccountEmail(){
		
		//1. GIVEN: a monash test role account email
		String roleAccountEmail = 'c-mgro-apply@idmqat.monash.edu';

		//WHEN: it is passed to the clean Role Account function
		roleAccountEmail = EmailMessageUtility.cleanRoleAccountEmail(roleAccountEmail);

		//THEN: it should remove 'c-'
		System.assert(roleAccountEmail.contains('c-') == false);
		System.assert(roleAccountEmail == 'mgro-apply@');

		//2. GIVEN: a monash role account email setup in sandbox for testing
		roleAccountEmail = 'test.user+mgro-apply@monash.edu';

		//WHEN: it is passed to the clean Role Account function
		roleAccountEmail = EmailMessageUtility.cleanRoleAccountEmail(roleAccountEmail);

		//THEN: it should remove 'test.user'
		System.assert(roleAccountEmail.contains('test.user') == false);
		System.assert(roleAccountEmail == 'mgro-apply@');

		//3. GIVEN: a monash role account
		roleAccountEmail = 'mgro-apply@monash.edu';

		//WHEN: it is passed to the clean Role Account function
		roleAccountEmail = EmailMessageUtility.cleanRoleAccountEmail(roleAccountEmail);

		//THEN: it should remove '@monash.edu'
		System.assert(roleAccountEmail.contains('@monash.edu') == false);
		System.assert(roleAccountEmail == 'mgro-apply@');
	}

	/**
     * @author          Matthew Maramot
     * @description     Tests CaseCommentWrapper for EmailRedirection
     */
    @isTest
    static void caseCommentWrapperTest(){
        
		//GIVEN
        //We have original & cloned case requiring internal comments (as part of EmailRedirection)
        List<Case> caseList = new List<Case>();
        Case originalCase = TestHelper.webToCaseForms(1)[0];
        originalCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MGE_Enquiry').getRecordTypeId();
        caseList.add(originalCase);

        Case cloneCase = TestHelper.webToCaseForms(1)[0];
        cloneCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MRO').getRecordTypeId();
        caseList.add(cloneCase);
        insert caseList;

		//Create caseCommentWrappers
        CaseComment originalComment = new CaseComment(
            CommentBody = 'Original Comment',
            IsPublished = false
        );
        CaseComment cloneComment = new CaseComment(
                        CommentBody = 'Clone Comment',
                        IsPublished = false
        );

        List<EmailMessageUtility.caseCommentWrapper> caseCommentList = new List<EmailMessageUtility.caseCommentWrapper>();
        EmailMessageUtility.caseCommentWrapper originalWrapper = new EmailMessageUtility.caseCommentWrapper(originalCase, cloneCase, originalComment, 'original');
        EmailMessageUtility.caseCommentWrapper cloneWrapper = new EmailMessageUtility.caseCommentWrapper(originalCase, cloneCase, cloneComment, 'clone');
        caseCommentList.add(originalWrapper);
        caseCommentList.add(cloneWrapper);

		//WHEN - The original & clone cases have been inserted, run wrapper methods
        Test.startTest();

        //Query to access newly inserted case data (particularly case number)
        List<Case> updatedCloneCases= [SELECT Id, CaseNumber, RecordType.Name FROM Case WHERE Id = :cloneCase.Id LIMIT 1];
        List<CaseComment> allComments = new List<CaseComment>();

        for(EmailMessageUtility.caseCommentWrapper wrapper : caseCommentList){
            //Run wrapper methods to update CaseComment
            wrapper.updateCaseCommentParent();
            wrapper.applyMergeFields(updatedCloneCases[0]);
            allComments.add(wrapper.getCaseComment());
        }
        insert allComments;
        Test.stopTest();

		//THEN - Wrapper methods update each Case Comment
		Assert.areEqual(1, [SELECT Id, ParentId FROM CaseComment WHERE ParentId = :originalCase.Id].size(), 'Expected characters after first two'); 
		Assert.areEqual(1, [SELECT Id, ParentId FROM CaseComment WHERE ParentId = :cloneCase.Id].size(), 'Expected characters after first two'); 
    }
}