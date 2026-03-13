/**
* @author Angelo Rivera
* @date 07.01.2020
* @group Test Class
* @description  Test Class to test the functionality of CaseTriggerHandlerV2
* @revision     APRivera, 07.January.2019 - Created <br/>
*               Martin Cadman - 13/11/2023 - Removed Enquiry Age History references
* 15/03/2024 - Mac Domingo   - EPCP-3307 Change integration endpoint for Mule 4
* 17-06-2024      Inderpal Dhanoa - Added OCR Sync MCT-404
* 17-07-2024      Inderpal Dhanoa - Enq sync Logic MCT-442
**/

@isTest//(isParallel=false) System.DmlException: first error: APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
private class CaseTriggerHandlerV2_Test {

    final static Id MONASH_CURRENT_QUEUE_ID  = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Monash_Connect_Current_Student' LIMIT 1].Id;

    @testSetup
    static void setup() {
        //Populate custom settings
        MonConTestDataFactory.createSObject(new RecordTypes_Allowed_on_CaseTrigger__c(), true);
        MonConTestDataFactory.createSObject(new Environment_Settings__c(), true);
        MonConTestDataFactory.createSObject(new CalabrioIntegration__c(), true);
        //Create test course
        MonConTestDataFactory.createSObject(new Course__c(), true);
        //Create test contact to associate the enquiry with
        MonConTestDataFactory.createSObject(new Contact(), true);
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        String random = String.valueOf(System.currentTimeMillis());
        Profile intgMonashForms = [SELECT Id FROM Profile WHERE name = 'Integration - Monash Forms'];
        UserRole eSoltn = [SELECT Id FROM UserRole WHERE Name = 'eSolutions'];
        PermissionSet integrationUser = [SELECT Id, name FROM PermissionSet WHERE name = 'Validate_Retention_Enquiry'];

        User userIntgForms = (User)TestDataFactory.createSObject(new User(ProfileId = intgMonashForms.Id, UserRoleId = eSoltn.id, 
                                                                                    Username = random + 'testingAgentUser2@monash.edu', isActive = true,
                                                                            Alias = 'test_ao', Email='test_ao2@monash.edu',EmailEncodingKey='UTF-8',
                                                                            Firstname='Firstname' + random, Lastname='Lastname' + random, LanguageLocaleKey='en_US',
                                                                            LocaleSidKey='en_US', TimeZoneSidKey='Australia/Sydney'), false);
        System.runAs(thisUser) {
            Database.insert(userIntgForms);
	        userIntgForms = [SELECT Id, username, isActive FROM User WHERE UserName like '%testingAgentUser2%' ORDER BY CreatedDate DESC LIMIT 1];
            
            TestDataFactory.createSObject(new PermissionSetAssignment(AssigneeId=userIntgForms.Id,
                                                                                                        PermissionSetId=integrationUser.Id),true);
        }

    }
    
    @isTest  //.. scenario 1
    public static void testupdateAccountforKnownToMonashContact1(){
        // GIVEN
        Account oAccount = new Account();
        oAccount.Name = 'Monash University';
        oAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();
        insert oAccount;
        
        Contact oContact = new Contact();
        oContact.FirstName = 'Test'+CommonUtilityERDA.generateRandomString(5);
        oContact.LastName = 'KnownToMonash-AccountLinking';
        oContact.Email = CommonUtilityERDA.generateRandomString(5) + 'ktm@enquiries.edu';
        oContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId();
        insert oContact;
        
        Case oCase = new Case ();
        oCase.Subject = 'Set Account For Enquiry';
        oCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MRO').getRecordTypeId();
        insert oCase;
        // WHEN
        oCase.ContactId = oContact.Id;
        Test.startTest();
        update oCase;
        Test.stopTest();
        // THEN
        Case updatedCase = [SELECT Id, AccountId, ContactId, RecordTypeId FROM Case WHERE Subject = 'Set Account For Enquiry' LIMIT 1];
        //.. Verify if account is not a Monash(default Account)
        Assert.areNotEqual(oAccount.Id, updatedCase.AccountId, 'Account is not a Monash University');
    }
    
    @isTest  //.. scenario 2
    public static void testupdateAccountforKnownToMonashContact2(){
        // GIVEN
        Account oAccount = new Account();
        oAccount.Name = 'Monash University';
        oAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();
        insert oAccount;
        
        Contact oContact = new Contact();
        oContact.FirstName = 'Test'+CommonUtilityERDA.generateRandomString(5);
        oContact.LastName = 'KnownToMonash-AccountLinking2';
        oContact.Email = CommonUtilityERDA.generateRandomString(5) + 'ktm@monash.edu';
        oContact.SAP_Staff_Id__c = CommonUtilityERDA.generateRandomString(15) + 'KTM';
        oContact.Authcate__c  = CommonUtilityERDA.generateRandomString(15) + 'KTM';
        oContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId();
        insert oContact;
        
        Case oCase = new Case ();
        oCase.Subject = 'Set Account For Enquiry';
        oCase.Description = 'Question.'+CommonUtilityERDA.generateRandomString(5);
        oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MRO').getRecordTypeId();
        insert oCase;
        
        // WHEN
        oCase.ContactId = oContact.Id;
        Test.startTest();
        update oCase;
        Test.stopTest();
        
        // THEN
        Case updatedCase = [SELECT Id, AccountId, ContactId, RecordTypeId FROM Case WHERE Subject = 'Set Account For Enquiry' LIMIT 1];
        //.. Verify if Account is Set to Monash.
        Assert.areNotEqual(updatedCase.AccountId, null, 'Account is a Monash University');
    }

    @IsTest
    static void testAssociateContactToPostApplicationEnquiries() {
        Test.startTest();
        Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact());
        con.Person_ID_unique__c ='213786327';
        insert con;

        Application__c application = (Application__c)MonConTestDataFactory.createSObject(new Application__c());
        application.Applicant__c = con.Id;
        insert application;

        Application_Course_Preference__c appCrsPref = (Application_Course_Preference__c)MonConTestDataFactory.createSObject(new Application_Course_Preference__c());
        appCrsPref.Application__c = application.Id;
        insert appCrsPref;

        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.RecordTypeId = StudRecCaseServices.POST_APPLICATION_RECTYPEID;
        cse.Monash_Student_Form_ID__c = '213786327';
        cse.Monash_Application_ID__c = '123456789';
        insert cse;
        Test.stopTest();

        Case c = [SELECT ContactId FROM Case LIMIT 1];
        System.assertNotEquals(null, c.ContactId);
    }


    @IsTest
    static void testDefaultMonashCollegeEnquiryType() {
        RecordTypes_Allowed_on_CaseTrigger__c rec = new RecordTypes_Allowed_on_CaseTrigger__c(Name='Professional Year Enquiry', API_Name__c ='Professional Year Enquiry');
        insert rec;
        Contact con = [SELECT Id FROM Contact];
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        Test.startTest();
        cse.RecordTypeId = MonashCollegeCaseServices.PROFESSIONALYEAR_RECTYPEID;
        cse.Enquiry_Type__c = null;
        cse.ContactId = con.Id;
        insert cse;
        Test.stopTest();
        Case c = [SELECT Id, ContactId FROM Case LIMIT 1];
        System.assertNotEquals(null, c.ContactId);
    }


    @IsTest
    static void testPrepopulateCategory() {
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        Test.startTest();
        cse.RecordTypeId = SEBSCaseServices.SEBS_RECTYPEID;
        cse.Category_3__c = 'Make Up Class';
        cse.Origin = CaseUtilities.ORIGIN_WEB;
        cse.Category_1__c = null;
        cse.Category_2__c = null;
        insert cse;
        Test.stopTest();
        Case c = [SELECT Id, Category_2__c FROM Case LIMIT 1];
        System.assertNotEquals(null, c.Category_2__c);
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
        Contact con = [SELECT Id FROM Contact];

        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.Course_Code__c = 'MARK1234_1';
        cse.Course_Specialisation__c = 'MARK1234';
        cse.Managing_Faculty__c = 'Law';
        cse.Course_Linked__c = false;
        cse.ContactId = con.Id;
        insert cse;
        Test.stopTest();

        Case c = [SELECT Id, Course__c, ContactId FROM  Case LIMIT 1];
        System.assertNotEquals(null, c.ContactId);
    }

    @IsTest
    static void testBehavior1() {
        Test.startTest();
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.Course_Code__c = 'MARK1234_1';
        cse.Course_Specialisation__c = 'MARK1234';
        cse.Managing_Faculty__c = 'Law';
        cse.Course_Linked__c = false;
        insert cse;

        cse.OwnerId = MONASH_CURRENT_QUEUE_ID ;
        cse.First_Response_Date_Time__c = System.now();
        cse.Status = 'Solved';
        update cse;
        Test.stopTest();

        Case c = [SELECT Id, Course__c, ContactId FROM  Case LIMIT 1];
        System.assertNotEquals(null, c.ContactId);
    }

    @IsTest
    static void testBehavior4() {
        Test.startTest();
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.Course_Code__c = 'MARK1234_1';
        cse.Course_Specialisation__c = 'MARK1234';
        cse.Managing_Faculty__c = 'Law';
        cse.Course_Linked__c = false;
        insert cse;

        Contact con = (Contact) MonConTestDataFactory.createSObject(new Contact());
        con.Person_ID_unique__c = '1223432';

        cse.OwnerId = UserInfo.getUserId();
        cse.Status = 'Open';
        cse.ContactId = con.Id;
        update cse;

        cse.Status = 'Solved';
        update cse;
        Test.stopTest();

        Case c = [SELECT Id, Status FROM  Case LIMIT 1];
        Assert.areEqual('Solved', c.Status, 'Status set correctly');
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
        Assert.areEqual(null, c.AccountId, 'Case default on new case is correct');
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
        Assert.areEqual(null, cseRec.AccountId, 'Case field mapping to contacts are correct');
    }

    @IsTest
    static void testAssociateContactToMonashCollegeEnquiries() {
        RecordTypes_Allowed_on_CaseTrigger__c rec = new RecordTypes_Allowed_on_CaseTrigger__c(Name='Professional Year Enquiry', API_Name__c ='Professional Year Enquiry');
        insert rec;

        Test.startTest();
        Contact c = [Select Id, Copy_from_Enquiry__c from Contact LIMIT 1];
        c.Copy_from_Enquiry__c = true;
        update c;
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.RecordTypeId = MonashCollegeCaseServices.PROFESSIONALYEAR_RECTYPEID;
        insert cse;
        Test.stopTest();
        Case cseRec = [SELECT Id, AccountId FROM Case];
        System.assertNotEquals(null, cseRec.AccountId);
    }

    /**
     * @description Test method to check OCR Creation upon Weightage change
     */
    @IsTest
    private static void testLinkOCRToMCEnquiry() {
        
        User userIntgFormsUser = [SELECT Id, username, isActive FROM User WHERE UserName like '%testingAgentUser2@monash.edu%' LIMIT 1];
        Case enqMonCOn;
        Campaign campaign = (Campaign)TestDataFactory.createSObject(new Campaign( Name = 'JRG Campaign Test', EndDate = Date.Today(), Type ='JRG',
                                        RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Advisory').getRecordTypeId()), true);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Salutation = 'Mr',FirstName = 'First',LastName = 'Last',
                                                                            Person_ID_unique__c = '123456',Email = 'test@test.com'), true);
                                                                            
        Id enqMonConRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();

        enqMonCOn = (Case)TestDataFactory.createSObject(new Case(Subject = 'MOn COn Support Enquiry', OwnerId = userIntgFormsUser.Id, campaign__c = campaign.Id, ContactId = contact.Id, Enquiry_Type__c = 'JRG', Alias__c ='123456-test',
                                                                    Priority = 'Low', Description = 'Rich Desc TEST', RecordTypeId = enqMonConRecTypeId), true);
        
        System.runAs(userIntgFormsUser) {            
            //GIVEN: An Enquiry linked to Retention already exists
            enqMonCOn = [SELECT Id,Weightage__c FROM Case WHERE Id = :enqMonCOn.Id];
            Test.startTest();
            //WHEN: An Enquiry weightage is changed by Integration User
            enqMonCOn.Weightage__c = 10 + Integer.valueOf(Label.JRGWeightageCriteria);
            update enqMonCOn;
            Test.stopTest();
        }        
        // THEN: A linked OCR record is created
        List<Outbound_Call_Result__c> linkedOCR = [SELECT Id, Client_Question__c FROM Outbound_Call_Result__c WHERE Case__c = :enqMonCOn.Id];
        Assert.areEqual(linkedOCR.size(), 1, 'OCR records did not get created');
        Assert.areEqual(linkedOCR[0].Client_Question__c, 'Rich Desc TEST', 'OCR records did not get mapped for Rich Description');
    }

    /**
     * @description Test method to check Enquiry updation upon Enquiry Type change
     */
    @IsTest
    private static void testLinkCourseWhenContactLinksRule3() {
        Contact cont = (Contact)TestDataFactory.createSObject(new Contact(Salutation = 'Mr',FirstName = 'First',LastName = 'Last',
                                                                            Person_ID_unique__c = '123456',Email = 'test@test.com'), true);
                                                                            
        Id enqMonConRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
        //Course Data
        Course__c course1 = (Course__c)TestDataFactory.createSObject(new Course__c(Name = 'Z9999', Course_Code__c = 'Z9999_1', Version__c = '1', Type__c = 'Course-All', Level__c = 'UG', Managing_Faculty__c = 'Faculty of Science', Title__c = 'Engines and Motors'), true); //Faculty__c=orgUnit.id,
        // Course Attempt added
        Course_Attempt__c courseAttmpt1 = (Course_Attempt__c)TestDataFactory.createSObject(new Course_Attempt__c(Name = 'Not formatted', Contact__c = cont.Id, course__c = course1.Id, Campus__c = 'Caulfield', Course_Attempt_Status__c = 'Completed'), true);
        Contact updateStudent = new Contact(Id = cont.Id, Primary_Course_Attempt__c = courseAttmpt1.Id);
        update updateStudent;
        Case enqMonCOn = (Case)TestDataFactory.createSObject(new Case(Subject = 'Test Method LinkCourseWhenContactLinks MOn COn Enquiry', ContactId = updateStudent.Id, Managing_Faculty__c = 'Monash College',Enquiry_Type__c = 'Career Connect', Alias__c ='123456-test',
                                                            Priority = 'Low', RecordTypeId = enqMonConRecTypeId), true);
        
         //GIVEN: An Enquiry linked to Managing Faculty already exists
         enqMonCOn = [SELECT Id, Enquiry_Type__c, Managing_Faculty__c FROM Case WHERE Subject = 'Test Method LinkCourseWhenContactLinks MOn COn Enquiry' ORDER BY CreatedDate DESC LIMIT 1 ];
         Test.startTest();
         //WHEN: An Enquiry Type is changed by User
         enqMonCOn.Managing_Faculty__c = '';
         enqMonCOn.Enquiry_Type__c = 'Course Advice';
         update enqMonCOn;
         Test.stopTest();
        // THEN: The Enquiry is updated
        List<Case> updtdEnq = [SELECT Id, Managing_Faculty__c, Contact.Primary_Course_Attempt__r.Course_Managing_Faculty__c FROM Case WHERE Id = :enqMonCOn.Id];
        Assert.areEqual(updtdEnq[0].Managing_Faculty__c, updtdEnq[0].Contact.Primary_Course_Attempt__r.Course_Managing_Faculty__c, 'LinkCourseWhenContactLinks records did not get updated');
    }


    @IsTest
    static void testMgeDefaultValuesIncludeAttachmentOnEmailToFaculty() {
        RecordTypes_Allowed_on_CaseTrigger__c rec = new RecordTypes_Allowed_on_CaseTrigger__c(Name='MGRO Enquiry', API_Name__c ='MGRO Enquiry');
        insert rec;
        Test.startTest();
        Contact c = [Select Id, Copy_from_Enquiry__c from Contact LIMIT 1];
        c.Copy_from_Enquiry__c = true;
        update c;
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.RecordTypeId = MGECaseServices.MGE_RECTYPEID;
        cse.Origin = CaseUtilities.ORIGIN_WEB_RDR;
        insert cse;
        Test.stopTest();
        Case cseRec = [SELECT Id, AccountId FROM Case];
        Assert.areNotEqual(null, cseRec.AccountId, 'Case defaults are set');
    }

    // Tests and covers the following methods:
    // runSOSLToLinkContactToCase; splitContactName
    // setRecordTypeIdUsingCaseType
    // setDefaultsOnNewCases
    // clearAccountFieldOnContactChange
    // copyMappedFieldsToCaseContact
    @IsTest
    static void testCheckDefaultsSet() {
        //Retrieve a monsh connect user to test with
        String monashConnectRole = '%' + Label.Monash_Connect + '%';
        User monashConnectUser = [SELECT Id, UserRole.Name FROM User
                                         WHERE UserRole.Name LIKE :monashConnectRole
                                         AND IsActive = TRUE
                                          AND Profile.Name = 'Base Profile'
                                                  AND UserRole.Name != NULL LIMIT 1];

        monashConnectUser.Queue__c = UserServices.CURRENT_STUDENT;
        monashConnectUser.Enquiry_Role__c = CaseUtilities.ORIGIN_PHONE;
        monashConnectUser.My_Information_LastUpdate__c = System.today() - 1;
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
        Assert.areEqual(null, c.AccountId, 'Case defaults are set');
    }


    @IsTest
    static void testCloneEmailAttachmentToContactDocumentUsingCases() {
        Test.startTest();
        Contact c = [Select Id, Copy_from_Enquiry__c from Contact LIMIT 1];
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.RecordTypeId = AdmissionsCaseServices.ADMISSIONS_RECTYPEID;
        cse.ContactId = c.Id;
        insert cse;
        Test.stopTest();
        Case cseRec = [SELECT Id, AccountId FROM Case];
        Assert.areNotEqual(null, cseRec.AccountId, 'Case not linked to Account');
    }

    @IsTest
    static void testCreateLinkEntitlementToCase() {
        Test.startTest();
        Contact c = [Select Id, Copy_from_Enquiry__c from Contact LIMIT 1];
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.ContactId = c.Id;
        cse.Origin = 'Web - Online Form';
        insert cse;
        Test.stopTest();
        Case cseRec = [SELECT Id, AccountId FROM Case];
        Assert.areNotEqual(null, cseRec.AccountId, 'Case not linked');
    }
    
    /*
     * @author:     ayush.agrawal@monash.edu
     * @date:       2021-11-11
     */
    @isTest
    static void testGenerateUuidIfMissing() {
        List<Case> cases = new List<Case>();
        
        Case c = new Case();
        cases.add(c);
        
        insert cases;
        
        Test.startTest();
        
        c = [SELECT Id, UUID__c FROM Case LIMIT 1];
        
        Test.stopTest();
        
        Assert.areNotEqual(null, c.UUID__c, 'GenerateUuidIfMissing is not working.');
    }

/*    @isTest
    public static void testCaseOwnershipUpdate(){
       //..Testing Case Merege SS-71
        Contact oContact = new Contact();
        oContact.FirstName = 'Test'+CommonUtilityERDA.generateRandomString(5);
        oContact.LastName = 'MergeEnquiries'+CommonUtilityERDA.generateRandomString(5);
        oContact.Email = CommonUtilityERDA.generateRandomString(5) + 'merge@enquiries.edu';
        insert oContact;
        
        Case oCase1 = new Case ();
        oCase1.ContactId = oContact.Id;
        oCase1.Subject = 'MergedCase';
        oCase1.Description = 'MergedCase - Question.'+CommonUtilityERDA.generateRandomString(5);
        insert oCase1;
        
        Test.startTest();
        oCase1.Status = 'Merged';
        update oCase1;
        Test.stopTest();
        
        Case oMasterCase = [SELECT Id,Description FROM Case WHERE Subject = 'MergedCase'];
        System.assert(oMasterCase.Description.contains('MergedCase'), 'Enquiries are merged.');
    }

*/
    private static Map<Id,CaseTeamMember> getDoiCtms(Case[] cases, Id caseTeamRoleId) {
        Map<Id, CaseTeamMember> ctms = new Map<Id, CaseTeamMember>();
        for(CaseTeamMember ctm :[
            SELECT ParentId, MemberId, TeamRole.Name FROM CaseTeamMember
            WHERE ParentId IN :cases AND TeamRoleId = :caseTeamRoleId
        ]) {
            ctms.put(ctm.ParentId, ctm);
        }
        return ctms;
    }

    @IsTest
    static void testDoiRetainFirstOwner() {
        User[] users = [SELECT Id FROM User WHERE IsActive = TRUE AND Profile.UserType = 'Standard' LIMIT 2];
        User firstOwner = users[0];
        User otherOwner = users[1];

        String doiRoleName = new CaseTriggerHandlerV2.DoiRetainFirstOwner().doiCTM;
        Id ctrId = [SELECT Id FROM CaseTeamRole WHERE Name = :doiRoleName].Id;
        Id doiQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'HR_Declaration_of_Interest'].Id;

        // ownership, user > user
        Case case1 = new Case(
            RecordTypeId = MonConCaseServices.m_recTypeDevelpNameRecId.get('Declaration_of_Interest'),
            Enquiry_Type__c = 'HR DOI Submission',
            Origin = 'Web - Monash Forms',
            OwnerId = firstOwner.Id,
            Status = 'Open'
        );
        // ownership, queue > user
        Case case2 = case1.clone();
        case2.OwnerId = doiQueueId;
        Case[] cases = new Case[]{case1, case2};

        Test.startTest();
        // case1 should get a CTM, case2 should not
        insert cases;

        Map<Id,CaseTeamMember> ctmResults1 = getDoiCtms(cases, ctrId);

        // case1 should not change, case1 should get a CTM
        update new Case[]{
            new Case(Id = case1.Id, OwnerId = otherOwner.Id),
            new Case(Id = case2.Id, OwnerId = firstOwner.Id)
        };

        Map<Id,CaseTeamMember> ctmResults2 = getDoiCtms(cases, ctrId);

        // case1 & case2 no change
        update new Case(Id = case2.Id, OwnerId = otherOwner.Id);
        Test.stopTest();

        Map<Id,CaseTeamMember> ctmResults3 = getDoiCtms(cases, ctrId);

        // verify case1 initial assignment
        Assert.areEqual(1, ctmResults1.size());
        Assert.isTrue(ctmResults1.containsKey(case1.Id));
        Assert.areEqual(firstOwner.Id, ctmResults1.get(case1.Id).MemberId, 'Case 1 gets reassigned');
        Assert.areEqual(doiRoleName, ctmResults1.get(case1.Id).TeamRole.Name, 'Case 1 gets assigned to a case team');

        // verify case2 initial assignment, case1 no change
        Assert.areEqual(2, ctmResults2.size());
        Assert.isTrue(ctmResults2.containsKey(case1.Id));
        Assert.isTrue(ctmResults2.containsKey(case2.Id));
        Assert.areEqual(firstOwner.Id, ctmResults2.get(case2.Id).MemberId, 'Case 2 gets reassigned');
        Assert.areEqual(doiRoleName, ctmResults2.get(case2.Id).TeamRole.Name, 'Case 2 gets assigned to case teams');

        // verify case1 & case2 no change
        Assert.areEqual(2, ctmResults3.size(), 'Case 1 and Case 2 has no change');
        Assert.isTrue(ctmResults3.containsKey(case1.Id));
        Assert.isTrue(ctmResults3.containsKey(case2.Id));
    }

    @IsTest
    public static void testSetLatestTransferredDate() {
        Case cse = new Case(
            Subject = 'TestCase For Transferred Date',
            Latest_Transferred_Date__c = Datetime.now().addDays(-3),
            RecordTypeId = MonConCaseServices.SPECON_RECTYPEID
        );
        insert cse;

        User newOwner = [SELECT Id FROM User WHERE IsActive = TRUE AND Profile.UserType = 'Standard' LIMIT 1];
        cse.OwnerId = newOwner.Id;

        Datetime preUpdate = Datetime.now();
        // sometimes the time set via the DML below is a few milliseconds before the time set here ¯\_(ツ)_/¯

        Test.startTest();
        update cse;
        Test.stopTest();

        Case result = [SELECT Id, Latest_Transferred_Date__c FROM Case WHERE Id = :cse.Id];
        Assert.isTrue(
            Math.abs(result.Latest_Transferred_Date__c.getTime() - preUpdate.getTime()) < 10000,
            result.Latest_Transferred_Date__c.getTime() + ' should be >= ' + preUpdate.getTime()
        );
    }
    /*
    * @description Test method to check if Agency is being associated with APNG Enquiries
    */
    @IsTest
    static void testAssociateAgencyToAPNGEnquiries() {  
        // Custom Setting setup
        TriggerCommon.disableTrigger('Account');
        Account testaccount = new Account(name='Monash University Global',recordtypeid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId());
        insert testaccount;
		TriggerCommon.enableTrigger('Account');
        
        Global_Monash_Account__c cusSet = new Global_Monash_Account__c();
        cusSet.id__c= string.valueOf(testaccount.Id);
        Insert cusSet;
        // GIVEN
        // A Valid Agent        
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
        AgentPortalTestDataFactory apTDF = new AgentPortalTestDataFactory();
        System.runAs(portalUser.testUser) {
            // A Valid Applicant
            TriggerCommon.disableTrigger('Contact');
            Contact applicant = apTDF.createApplicantContact();
            applicant.Person_ID_unique__c = '987654321';
            insert applicant;
            TriggerCommon.enableTrigger('Contact');
            // A Valid Application
            Application__c application = apTDF.createApplication(applicant.id);
            application.Agent_Org_Unit_Code__c = portalUser.acc.Callista_Org_Unit_Code__c;
            insert application;
            TriggerCommon.disableTrigger('Application_Course_Preference__c');
            Application_Course_Preference__c acp = apTDF.createACP(application.id);
            insert acp;
            TriggerCommon.enableTrigger('Application_Course_Preference__c');
            
            Test.startTest();
                // WHEN
                // An Enquiry is created
                Case enquiry = apTDF.createAgentEnquiry(applicant, portalUser.con, acp);
                insert enquiry;
            Test.stopTest();
            // THEN
            // External Stakeholder field is populated with the linked ACP's Application's Agency
            enquiry = [SELECT External_stakeholder__c, External_stakeholder_Email__c FROM Case WHERE id = :enquiry.Id LIMIT 1];
            Assert.areEqual(portalUser.acc.id, enquiry.External_stakeholder__c, 'Populating External Stakeholder failed');
            // External Stakeholder email field is populated with Creating Agent's email (Contact Email)
            Assert.areEqual(portalUser.con.email.toLowerCase(), enquiry.External_stakeholder_Email__c.toLowerCase(), 'Populating External Stakeholder Email failed');
        }
    }
    /*
    * @description Test method to check if Summary file is created for APNG Enquiries
    */
    @IsTest
    @SuppressWarnings('PMD.EmptyCatchBlock')
    static void testCreateSummaryFileForAPNGEnquiries() {  
        //set mock response
        IntegrationSettings_SubmitApplication__c is = new IntegrationSettings_SubmitApplication__c();
        is.Base_Url__c = 'https://mix-dev.monash.edu';
        is.Path__c = '/la/v1/admissions/applications';
        is.Method__c = 'POST';
        is.Header_ClientId__c = 'c8411f0ca73a4ae6a0c7081a1336630f';
        is.Header_ClientSecret__c = 'cd2d5b9e26fa4999A33FF6A7F12D65AD';
        is.Header_ContentType__c = 'application/json';
        is.Mock_Endpoint_Applications__c = 'http://monash.getsandbox.com/la/v1/admissions/applications';
        is.Enable_Mock__c = false;
        is.Timeout__c = '12000';
        insert is;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('StudFirst_SubmitEnquirySummaryMockResp');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        // GIVEN
        TriggerCommon.disableTrigger('Account');
        Account testaccount = new Account(name='Monash University Global',recordtypeid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId());
        insert testaccount;
        TriggerCommon.enableTrigger('Account');

        Global_Monash_Account__c cusSet = new Global_Monash_Account__c();
        cusSet.id__c= string.valueOf(testaccount.Id);
        Insert cusSet;
        
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
        AgentPortalTestDataFactory apTDF = new AgentPortalTestDataFactory();
        System.runAs(portalUser.testUser) {
            // WHEN
            TriggerCommon.disableTrigger('Contact');
            Contact applicant = apTDF.createApplicantContact();
            applicant.Person_ID_unique__c = '987654321';
            insert applicant;
            TriggerCommon.enableTrigger('Contact');

            Application__c application = apTDF.createApplication(applicant.id);
            application.Agent_Org_Unit_Code__c = portalUser.acc.Callista_Org_Unit_Code__c;
            application.Callista_Applicant_Id__c = '987654321';
            insert application;
            
    		TriggerCommon.disableTrigger('Application_Course_Preference__c');
            Application_Course_Preference__c acp = apTDF.createACP(application.id);
            insert acp;
			TriggerCommon.enableTrigger('Application_Course_Preference__c');
            
            Test.startTest();
                Case enquiry = apTDF.createAgentEnquiry(applicant, portalUser.con, acp); // Rec Type = Admissions, Status = Open
                enquiry.Summary__c = '___SUMMARY___';
                try {            
                    insert enquiry;
                } catch(Exception ex) {}
            Test.stopTest();
            // THEN
            // Test if a summary file is generated 
            enquiry = [SELECT CaseNumber FROM Case WHERE id = :enquiry.Id LIMIT 1];
            Attachment summaryFile = [select id, Name FROM Attachment WHERE parentId = :enquiry.Id limit 1];
            Assert.areEqual(summaryFile.Name, enquiry.CaseNumber+'_Summary', 'Creating summary file failed');
        }
    }

    @isTest
    static void testDeleteCaseWithContactOrAccount() {
        Contact con = new Contact(
            LastName = 'Doe',
            FirstName = 'John'
        );
        insert con;

        // GIVEN: Cases with Archive Date and Purge Date
        Case testCase = new Case(
            Subject = 'Test Case',
            Archive_Date__c = Date.today(),
            Purge_Date__c = Date.today().addDays(30), 
            ContactId = con.Id
        );
        insert testCase;

        //Run as Admin, only admins will do the archiving
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];

        System.runAs(adminUser) {
            //Start the archiving policy
            Test.startTest();
            //WHEN The case is deleted
            delete testCase;
            Test.stopTest();
        }

        // THEN: Verify that Archive_Activity__c records are created
        Integer numArchiveActivities = [SELECT COUNT() FROM Archive_Audit__c];
        Assert.areEqual(1, numArchiveActivities, 'Expected one Archive_Audit__c record to be created');
    }

    @isTest
    static void testDeleteCaseNotRelatedToContactOrAccount() {
        // GIVEN: Cases with Archive Date and Purge Date
        Case testCase = new Case(
            Subject = 'Test Case',
            Archive_Date__c = Date.today()            
        );
        insert testCase;

        //Run as Admin, only admins will do the archiving
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];

        System.runAs(adminUser) {
            //Start the archiving policy
            Test.startTest();
            //WHEN The case is deleted
            delete testCase;
            Test.stopTest();
        }
        // THEN: Verify that Archive_Activity__c records are not created
        Integer numArchiveActivities = [SELECT COUNT() FROM Archive_Audit__c];
        Assert.areEqual(0, numArchiveActivities, 'Expected no Archive Audit records to be created');
    }

}