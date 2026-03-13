/**
* @author Angelo Rivera
* @date 07.01.2020
* @group Test Class
* @description  Test Class to test the functionality of CaseServicesV2
* @revision     APRivera, 07.January.2019 - Created <br/>
* @revision     IDhanoa, 19.May.2021 - Added new test method for syncEnquiryOrganisationAndEnquiry
                Kristian Vegerano - 30/11/2021 - Added test for - SFTG-2351 add rule condition such that if the selected is do not exclude then the rule is not grouped to any role
                Martin Cadman     - 13/11/2023 - Removed Enquiry Age History references
*/

@isTest //(isParallel=true) CaseServicesV2_Test.testSyncEnquiryOrganisationAndEnquiry Test.getStandardPricebookId() cannot be called from parallel
private class CaseServicesV2_Test {
	final static Id monashCurrentQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Monash_Connect_Current_Student' LIMIT 1].Id;
	final static Id srPostApplicationQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Student_Rec_Enquiries_Post_Application' LIMIT 1].Id;

	@testSetup
	static void setup(){
		//Populate custom settings
		MonConTestDataFactory.createSObject(new RecordTypes_Allowed_on_CaseTrigger__c(), true);
		MonConTestDataFactory.createSObject(new Environment_Settings__c(), true);
		MonConTestDataFactory.createSObject(new CalabrioIntegration__c(), true);
		//Create test course
		MonConTestDataFactory.createSObject(new Course__c(), true);
		//Create test contact to associate the enquiry with
		MonConTestDataFactory.createSObject(new Contact(), true);
	}

	// Tests and covers the following methods:
		// mapCourseCode; retrieveCourseInfo
		// maintainLastQueueOwner
		// checkForAndLinkToContacts
	    // linkContactToInboundCase (with matching contact)
		// getMapExistingContactsByEmailAddress
	    // transferEnquiryOwnership; processTransferEnquiryOwnership (User to Queue)
	    // checkCaseIfCreatedNow
		// addCourseInterests
		// setEnquiryOrigin
		// updateCaseBusinessWaitingTime
		// clearAccountFieldOnContactChange
	@IsTest
	static void testBehavior() {
		Test.startTest();
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
		cse.Course_Code__c = 'MARK1234_1';
		cse.Course_Specialisation__c = 'MARK1234';
		insert cse;

		cse.OwnerId = monashCurrentQueueId;
		cse.First_Response_Date_Time__c = System.now();
		cse.Status = 'Solved';
		update cse;

		cse.OwnerId = UserInfo.getUserId();
		cse.Status = 'Open';
		update cse;

		Test.stopTest();

		Case c = [SELECT Id, Course__c, ContactId FROM  Case WHERE Id =: cse.Id];
		System.assertNotEquals(null, c.Course__c);
		System.assertNotEquals(null, c.ContactId);
	}

    /*
	 * @author  	    Kristian Vegerano
	 * @date            30.Nov.2021      
	 * @description     Tests that SR queues always trigger the record type change
	 */
    @isTest
	static void testSRPostApplicationBehavior() {
		Test.startTest();
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
		cse.Course_Code__c = 'MARK1234_1';
		cse.Course_Specialisation__c = 'MARK1234';
		insert cse;

		cse.OwnerId = srPostApplicationQueueId;
		cse.First_Response_Date_Time__c = System.now();
		cse.Status = 'Solved';
		update cse;

		cse.OwnerId = UserInfo.getUserId();
		cse.Status = 'Open';
		update cse;

		Test.stopTest();

		Case c = [SELECT Id, Course__c, ContactId FROM  Case WHERE Id =: cse.Id];
		System.assertNotEquals(null, c.Course__c);
		System.assertNotEquals(null, c.ContactId);
	}

	// Tests and covers the following methods:
		// runSOSLToLinkContactToCase; splitContactName
		// setRecordTypeIdUsingCaseType
		// setDefaultsOnNewCases
		// clearAccountFieldOnContactChange
		// copyMappedFieldsToCaseContact
	@IsTest
	static void testBehavior2() {
		//Retrieve a monsh connect user to test with
		String monashConnectRole = '%' + Label.Monash_Connect + '%';
		User monashConnectUser = [SELECT Id, UserRole.Name FROM User
									WHERE UserRole.Name LIKE :monashConnectRole
									AND IsActive = TRUE
									AND Profile.Name = 'Base Profile'
									AND UserRole.Name != NULL LIMIT 1];

		monashConnectUser.Queue__c = UserServices.CURRENT_STUDENT;
		monashConnectUser.Enquiry_Role__c = CaseUtilities.ORIGIN_PHONE;
		monashConnectUser.My_Information_LastUpdate__c = System.today();
		monashConnectUser.Default_Enquiry_Record_Type__c = 'Standard Enquiry';
		update monashConnectUser;
		
		System.runAs(monashConnectUser) {
			Test.startTest();
			Case cse = (Case) MonConTestDataFactory.createSObject(new Case());
			cse.SuppliedEmail = 'test@test.com';
			cse.SuppliedName = 'Test Student';
			cse.Case_Type__c = 'Standard Enquiry';
			insert cse;
			Test.stopTest();
		}
		Case c = [SELECT Id, AccountId FROM  Case];
		System.assertEquals(null, c.AccountId);
	}
	
	@IsTest
    static void testSyncEnquiryOrganisationAndEnquiry() {
        
        Test.startTest();
        RecordType recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'External_Organisation' LIMIT 1][0];
        
		Account acct0 = new Account(Name='Acct0', RecordTypeId = recType.Id);
        insert acct0;

        Account acct1 = new Account(Name='Acct1', RecordTypeId = recType.Id);
        insert acct1;

		Account acct2 = new Account(Name='Acct2', RecordTypeId = recType.Id);
        insert acct2;

        recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Enterprise' LIMIT 1][0];
        // GIVEN: An oppty are associated to it
        Opportunity oppty1 = new Opportunity();
        oppty1.AccountId = acct1.Id;
        oppty1.RecordTypeId = recType.Id;
        oppty1.Name = 'Oppty1';
        oppty1.Amount = 1.00;
        oppty1.CloseDate = Date.today()+1;
        oppty1.StageName = 'Open';
        insert oppty1;

		Opportunity oppty2 = new Opportunity();
        oppty2.AccountId = acct2.Id;
        oppty2.RecordTypeId = recType.Id;
        oppty2.Name = 'Oppty2';
        oppty2.Amount = 1.00;
        oppty2.CloseDate = Date.today()+1;
        oppty2.StageName = 'Open';
        insert oppty2;

		String admissionsRecType = CommonServices.recordTypeId('Case', 'Enterprise');
        Case caseRec = new  Case(SuppliedName = 'testName',
								SuppliedPhone = '0400000000',
								SuppliedEmail = 'testformEmail@monash.edu',
								AccountId = acct0.Id,
								Opportunity__c = oppty1.Id,
								RecordTypeId = admissionsRecType );
		insert caseRec;

        List<Enquiry_Organisations__c> result = [SELECT Id, Account__c, Enquiry__c FROM Enquiry_Organisations__c];
        system.assertEquals(result.size(),1);

        caseRec.Opportunity__c = oppty2.Id;
        update caseRec;

        result = [SELECT Id, Account__c, Enquiry__c FROM Enquiry_Organisations__c];
        system.assertEquals(result.size(),2);

        Test.stopTest();
    }

	// Tests and covers the following methods:
		// copyMappedFieldsToCaseContact
	@IsTest
	static void testBehavior3() {
		Test.startTest();
		Contact c = [Select Id, Copy_from_Enquiry__c from Contact LIMIT 1];
		c.Copy_from_Enquiry__c = true;
		update c;
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case(), true);
		cse.ContactId = null;
		update cse;
		Test.stopTest();
		Case cseRec = [SELECT Id, AccountId FROM Case];
		System.assertEquals(null, cseRec.AccountId);
	}
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			19-03-2021
	 */
    static testMethod void testMapCategoryLevelsForPostApplicationCases() {
        // Case
        Id postApplicationCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Application_Enquiry').getRecordTypeId();
        
        Case case_1 = new Case();
        case_1.Enquiry_Summary__c = 'Details Regarding Offer';
        case_1.RecordTypeId = postApplicationCaseRecordTypeId;
        insert case_1;
        
        Test.startTest();
        
        Case c = [SELECT Id, Category_Level_1__c, Category_Level_2__c FROM Case LIMIT 1];
        
        Test.stopTest();
        
        System.assertEquals('Offer', c.Category_Level_1__c, 'mapCategoryLevelsForPostApplicationCases is not working.');
        System.assertEquals('Offer Details', c.Category_Level_2__c, 'mapCategoryLevelsForPostApplicationCases is not working.');
    }
	
	/*
	 * @author:			inderpal.dhanoa@monash.edu
	 * @date:			27-07-2021
	 * @description:	Creating Enquiry then updating the Outcome to Approved.
	 */
	@IsTest
    static void testSyncApproverRejecter() {
                
        // Contact
        Contact con = new Contact();
        con.LastName = 'LastName';
        insert con;
        
        // Case
        Id enterpCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
        
		Test.startTest();

        Case case_1 = new Case();
        case_1.ContactId = con.Id;
        case_1.RecordTypeId = enterpCaseRecordTypeId;
        insert case_1;  
		
		case_1.MonashCollege_Outcome__c = 'Approved';
		update case_1;
        
        Test.stopTest();
        
		List<Case> casesToCheck = [SELECT Id, Approver__c,Date_Of_Approval__c FROM Case];

		system.assertEquals(casesToCheck[0].Approver__c , UserInfo.getUserId());
		system.assertEquals(casesToCheck[0].Date_Of_Approval__c , Date.today());
        
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			24-03-2021
	 */
    static testMethod void testMapOriginToOtherValuesForPostApplicationCases() {
        // Case
        Id postApplicationCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Application_Enquiry').getRecordTypeId();
        
        List<Case> cases = new List<Case>();
        
        Case case_1 = new Case();
        case_1.Origin = 'scenquiries@monash.edu';
        case_1.RecordTypeId = postApplicationCaseRecordTypeId;
        cases.add(case_1);
        
        Case case_2 = new Case();
        case_2.Origin = 'adm-keyagent@monash.edu';
        case_2.RecordTypeId = postApplicationCaseRecordTypeId;
        cases.add(case_2);
        
        Case case_3 = new Case();
        case_3.Origin = 'latereg@monash.edu';
        case_3.RecordTypeId = postApplicationCaseRecordTypeId;
        cases.add(case_3);
        
        Case case_4 = new Case();
        case_4.Origin = 'lateregresponse@monash.edu';
        case_4.RecordTypeId = postApplicationCaseRecordTypeId;
        cases.add(case_4);
        
        insert cases;
        
        Test.startTest();
        
        case_1 = [SELECT Id, Category_Level_1__c, Enquiry_Type__c FROM Case WHERE Id = :case_1.Id];
        case_2 = [SELECT Id, Category_Level_1__c, Enquiry_Type__c FROM Case WHERE Id = :case_2.Id];
        case_3 = [SELECT Id, Category_Level_1__c, Enquiry_Type__c FROM Case WHERE Id = :case_3.Id];
        case_4 = [SELECT Id, Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c FROM Case WHERE Id = :case_4.Id];
        
        Test.stopTest();
        
        System.assertEquals('Application', case_1.Category_Level_1__c, 'mapOriginToOtherValuesForPostApplicationCases is not working.');
        System.assertEquals('Post Application', case_1.Enquiry_Type__c, 'mapOriginToOtherValuesForPostApplicationCases is not working.');
        
        System.assertEquals('Application', case_2.Category_Level_1__c, 'mapOriginToOtherValuesForPostApplicationCases is not working.');
        System.assertEquals('Key Agent - International', case_2.Enquiry_Type__c, 'mapOriginToOtherValuesForPostApplicationCases is not working.');
        
        System.assertEquals('Application', case_3.Category_Level_1__c, 'mapOriginToOtherValuesForPostApplicationCases is not working.');
        System.assertEquals('Late Registration - International', case_3.Enquiry_Type__c, 'mapOriginToOtherValuesForPostApplicationCases is not working.');
        
        System.assertEquals('Enrolment', case_4.Category_Level_1__c, 'mapOriginToOtherValuesForPostApplicationCases is not working.');
        System.assertEquals('Late Enrolment - MCPL', case_4.Category_Level_2__c, 'mapOriginToOtherValuesForPostApplicationCases is not working.');
        System.assertEquals('Late Registration - Response', case_4.Enquiry_Type__c, 'mapOriginToOtherValuesForPostApplicationCases is not working.');
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			24-03-2021
	 */
    static testMethod void testMapOriginToEnquiryTypeForMonashCollege() {
        // Case
        Case case_1 = new Case();
        case_1.Origin = 'Email - enquiries@monashcollege.edu.au';
        insert case_1;
        
        Test.startTest();
        
        case_1 = [SELECT Id, Enquiry_Type__c FROM Case WHERE Id = :case_1.Id];
        
        Test.stopTest();
        
        System.assertEquals('Future Course', case_1.Enquiry_Type__c, 'mapOriginToEnquiryTypeForMonashCollege is not working.');
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			24-03-2021
	 */
    static testMethod void testSetPriorityForInsuranceCases() {
        // Case
        Id insuranceCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Enquiry').getRecordTypeId();
        
        Case case_1 = new Case();
        case_1.RecordTypeId = insuranceCaseRecordTypeId;
        case_1.SuppliedEmail = 'noreply@csnet.com.au';
        insert case_1;
        
        Test.startTest();
        
        case_1 = [SELECT Id, Priority FROM Case WHERE Id = :case_1.Id];
        
        Test.stopTest();
        
        System.assertEquals('High', case_1.Priority, 'setPriorityForInsuranceCases is not working.');
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			24-03-2021
	 */
    static testMethod void testMapOriginToOtherValuesForStandardCases() {
        // Case
        Id standardCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
        
        List<Case> cases = new List<Case>();
        
        Case case_1 = new Case();
        case_1.Origin = 'Email - fee.extensions@monash.edu';
        case_1.RecordTypeId = standardCaseRecordTypeId;
        cases.add(case_1);
        
        Case case_2 = new Case();
        case_2.Origin = 'Email - law-clinicalplacement@monash.edu';
        case_2.RecordTypeId = standardCaseRecordTypeId;
        cases.add(case_2);
        
        Case case_3 = new Case();
        case_3.Origin = 'Email - Learning Adviser';
        case_3.RecordTypeId = standardCaseRecordTypeId;
        cases.add(case_3);
        
        Case case_4 = new Case();
        case_4.Origin = 'Email - COE';
        case_4.RecordTypeId = standardCaseRecordTypeId;
        cases.add(case_4);
        
        insert cases;
        
        Test.startTest();
        
        case_1 = [SELECT Id, Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c FROM Case WHERE Id = :case_1.Id];
        case_2 = [SELECT Id, Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c FROM Case WHERE Id = :case_2.Id];
        case_3 = [SELECT Id, Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c FROM Case WHERE Id = :case_3.Id];
        case_4 = [SELECT Id, Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c, Student_Type__c FROM Case WHERE Id = :case_4.Id];
        
        Test.stopTest();
        
        System.assertEquals('Fees & Financial Matters', case_1.Category_Level_1__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        System.assertEquals('Fee Extension', case_1.Category_Level_2__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        System.assertEquals('Current Course', case_1.Enquiry_Type__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        
        System.assertEquals('Professional Experience', case_2.Category_Level_1__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        System.assertEquals('Pre-placement', case_2.Category_Level_2__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        System.assertEquals('Current Course', case_2.Enquiry_Type__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        
        System.assertEquals('Student Advice', case_3.Category_Level_1__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        System.assertEquals('General Advice/Support', case_3.Category_Level_2__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        System.assertEquals('Learning Advice', case_3.Enquiry_Type__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        
        System.assertEquals('International Visa', case_4.Category_Level_1__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        System.assertEquals('COE', case_4.Category_Level_2__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        System.assertEquals('Current Course', case_4.Enquiry_Type__c, 'mapOriginToOtherValuesForStandardCases is not working.');
        System.assertEquals('International', case_4.Student_Type__c, 'mapOriginToOtherValuesForStandardCases is not working.');
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			24-03-2021
	 */
    static testMethod void testMapOriginToOtherValuesForHRCases() {
        // Case
        List<Case> cases = new List<Case>();
        
        Case case_1 = new Case();
        case_1.Origin = 'Web - myDevelopment Staff';
        case_1.Sub_Category__c = 'myDevelopment - Navigation';
        cases.add(case_1);
        
        Case case_2 = new Case();
        case_2.Origin = 'Web - myDevelopment Staff';
        case_2.Sub_Category__c = 'myDevelopment';
        cases.add(case_2);
        
        Case case_3 = new Case();
        case_3.Origin = 'Web - myDevelopment Staff';
        case_3.Sub_Category__c = 'myDevelopment - Business Process';
        cases.add(case_3);
        
        Case case_4 = new Case();
        case_4.Origin = 'Web - myDevelopment Staff';
        case_4.Sub_Category__c = 'Learning Activity';
        cases.add(case_4);
        
        insert cases;
        
        Test.startTest();
        
        case_1 = [SELECT Id, Category__c, Tier_Level__c FROM Case WHERE Id = :case_1.Id];
        case_2 = [SELECT Id, Category__c, Tier_Level__c FROM Case WHERE Id = :case_2.Id];
        case_3 = [SELECT Id, Category__c, Tier_Level__c FROM Case WHERE Id = :case_3.Id];
        case_4 = [SELECT Id, Category__c, Tier_Level__c FROM Case WHERE Id = :case_4.Id];
        
        Test.stopTest();
        
        System.assertEquals('HR System', case_1.Category__c, 'mapOriginToOtherValuesForHRCases is not working.');
        System.assertEquals('Tier 1 - Monash Connect', case_1.Tier_Level__c, 'mapOriginToOtherValuesForHRCases is not working.');
        
        System.assertEquals('Feedback', case_2.Category__c, 'mapOriginToOtherValuesForHRCases is not working.');
        System.assertEquals('Tier 1 - Monash Connect', case_2.Tier_Level__c, 'mapOriginToOtherValuesForHRCases is not working.');
        
        System.assertEquals('Policy & Procedure', case_3.Category__c, 'mapOriginToOtherValuesForHRCases is not working.');
        System.assertEquals('Tier 1 - Monash Connect', case_3.Tier_Level__c, 'mapOriginToOtherValuesForHRCases is not working.');
        
        System.assertEquals('Staff Development', case_4.Category__c, 'mapOriginToOtherValuesForHRCases is not working.');
        System.assertEquals('Tier 3 - CoE', case_4.Tier_Level__c, 'mapOriginToOtherValuesForHRCases is not working.');
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			13-04-2021
	 */
    @isTest
    static void testMapCourseLinkingFieldsForMonashForms() {
        // Contact
        Contact contact_1 = new Contact();
        contact_1.LastName = 'Last Name';
        insert contact_1;
        
        // Course
        Course__c course_1 = new Course__c();
        course_1.Name = 'Name';
        course_1.Type__c = 'Course-All';
        insert course_1;
        
        // Course Attempt
        Course_Attempt__c courseAttempt_1 = new Course_Attempt__c();
        courseAttempt_1.Attendance_Mode__c = 'IN';
        courseAttempt_1.Contact__c = contact_1.Id;
        courseAttempt_1.Course__c = course_1.Id;
        insert courseAttempt_1;
        
        // Case
        Case case_1 = new Case();
        case_1.Course_Attempt__c = courseAttempt_1.Id;
        case_1.Origin = 'Web - Monash Forms';
        insert case_1;
        
        Test.startTest();
        
        case_1 = [SELECT Id, Attendance_Mode__c FROM Case WHERE Id = :case_1.Id];
        
        Test.stopTest();
        
        System.assertEquals(courseAttempt_1.Attendance_Mode__c, case_1.Attendance_Mode__c, 'mapCourseLinkingFieldsForMonashForms is not working.');
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @description:	Check the default values on Case when Academic Progress Assessment records are created.
	 * @group:			Student Admin
	 */
    @isTest
    static void testSetDefaultsForAcademicProgressAssessment() {
        // Contact
        Contact contact_1 = new Contact();
        contact_1.LastName = 'Last Name';
        contact_1.Person_ID_unique__c = '10000001';
        insert contact_1;
        
        // Campaign
        Campaign campaign_1 = new Campaign();
        campaign_1.Name = 'AP - 2021 - First - Final';
        campaign_1.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Advisory').getRecordTypeId();
        insert campaign_1;
        
        // Case
        Case case_1 = new Case();
        case_1.Campaign__c = campaign_1.Id;
        case_1.Category_Level_1__c = '1-3';
        case_1.ContactId = contact_1.Id;
        case_1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Academic_Progress_Assessment').getRecordTypeId();
        insert case_1;
        
        Test.startTest();
        
        Group unassignedQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Academic_Progress_Assessment_Unassigned' AND Type = 'Queue' LIMIT 1];
        
        case_1 = [SELECT Id, Category_Level_1__c, Enquiry_Type__c, Origin, OwnerId, Priority, Subject, UUID__c FROM Case WHERE Id = :case_1.Id];
        
        Test.stopTest();
        
        System.assertEquals('AP 1-3', case_1.Category_Level_1__c, 'testSetDefaultsForAcademicProgressAssessment is not working.');
        System.assertEquals('Risk Level 3', case_1.Enquiry_Type__c, 'testSetDefaultsForAcademicProgressAssessment is not working.');
        System.assertEquals('My Academic Progress Response', case_1.Origin, 'testSetDefaultsForAcademicProgressAssessment is not working.');
        System.assertEquals(unassignedQueue.Id, case_1.OwnerId, 'testSetDefaultsForAcademicProgressAssessment is not working.');
        System.assertEquals(null, case_1.Priority, 'testSetDefaultsForAcademicProgressAssessment is not working.');
        System.assertEquals('10000001 - AP - 2021 - First - Final', case_1.Subject, 'testSetDefaultsForAcademicProgressAssessment is not working.');
        System.assertEquals(true, Uuid.isValid(case_1.UUID__c), 'testSetDefaultsForAcademicProgressAssessment is not working.');
    }

    @IsTest
    static void testFormSubmissionRelatedCasesDataProvider() {
        Case cse1 = (Case)TestDataFactory.createSObject(new Case());
        cse1.Form_Submission_ID__c = '7131';
        Case cse2 = cse1.clone();
        Case cse3 = cse1.clone();
        Case cse4 = cse1.clone();
        cse4.Form_Submission_ID__c = null;
        Case[] cases = new Case[]{cse1, cse2, cse3, cse4};
        TriggerCommon.disableTrigger('Case');
        insert cases;

        Test.startTest();
        CaseServicesV2.FormSubmissionRelatedCasesDataProvider dp = new CaseServicesV2.FormSubmissionRelatedCasesDataProvider();
        List<ApexRelatedListController.Record> results1 = dp.getRecords(cse1.Id);
        List<ApexRelatedListController.Record> results2 = dp.getRecords(cse4.Id);
        Test.stopTest();

        Assert.areEqual(2, results1.size());
        Assert.areNotEqual(results1[0].id, results1[1].id);
        for(ApexRelatedListController.Record r : results1) {
            Assert.isTrue(r.id == cse2.Id || r.id == cse3.Id);
        }
        Assert.areEqual(0, results2.size());
    }
    
}