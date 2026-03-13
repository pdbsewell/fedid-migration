/**
* @author Angelo Rivera
* @date 29.May.2019
* @group Test Class
* @description  Test Class to test the functionality of MonConCaseServices
* @revision     APRivera, 29.May.2019 - Created <br/>
*               APRivera, 20.December.2019 - Increase Coverage <br/>
*               Martin C, 13/11/2023 - Removed all enquiry age history references<br/>
*               IDhanoa ,  13/06/2024  - Added OCR creation Logic MCT-404 <br/>
*               IDhanoa ,  13/06/2024  - Added Managing Faculty Logic MCT-442 <br/>
*/

@isTest(isParallel=true)
private class MonConCaseServices_Test {
    final static Id MONASH_CURRENT_QUEUEID = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Monash_Connect_Current_Student' LIMIT 1].Id;
    final static Id STANDARD_ENQUIRY_ID = MonConCaseServices.MONCON_RECTYPEID;

    @testSetup
    static void setup(){
        //Populate custom settings
        MonConTestDataFactory.createSObject(new RecordTypes_Allowed_on_CaseTrigger__c(), true);
        MonConTestDataFactory.createSObject(new Environment_Settings__c(), true);
    }

    /**
     * @description Test method to check OCR Creation
     */
    @IsTest
    static void syncOCRWithEnquiryTest() {
        Contact cont = (Contact)TestDataFactory.createSObject(new Contact(Salutation = 'Mr',FirstName = 'First',LastName = 'Last',
                                                                            Person_ID_unique__c = '123456',Email = 'test@test.com'), true);

        Id enqMonConRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
        Date campEndDate = Date.today();
        Campaign jrgCamp = (Campaign)TestDataFactory.createSObject(new Campaign(Name = 'Test Camp JRG', EndDate = campEndDate.addDays(15)), true);

        Case enqMonCOn = (Case)TestDataFactory.createSObject(new Case(Subject = 'MOn COn Support Enquiry', Campaign__c = jrgCamp.Id, Description = 'Rich Desc TEST',ContactId = cont.Id, Enquiry_Type__c = 'JRG', Alias__c ='123456-test',
        Risk_Category__c = '', RecordTypeId = enqMonConRecTypeId), true);

        //Run as Admin as it will be executed in Without Sharing mode
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];

        System.runAs(adminUser) {
            //GIVEN: An Enquiry linked to Retention already exists
            Test.startTest();
            //WHEN: An Enquiry weightage is changed by Integration User
            MonConCaseServices.syncOCRWithEnquiry(new Set<String>{String.valueOf(enqMonCOn.Id) + '@@@Client_Question@@@'+'45'+'@@@Client_Question@@@'+enqMonCOn.Description});
            Test.stopTest();
        }
        // THEN: A linked OCR record is created
        List<Outbound_Call_Result__c> linkedOCR = [SELECT Id, Client_Question__c FROM Outbound_Call_Result__c WHERE Case__c = :enqMonCOn.Id];
        Assert.areEqual(linkedOCR.size(), 1, 'OCR records did not get created');
        Assert.areEqual(linkedOCR[0].Client_Question__c, 'Rich Desc TEST', 'OCR records did not get mapped for Rich Description');
    } 


    /**
     * @description Test method to get Dependent PicklistValues Via Dependent Field API
     */
    @IsTest
    static void getDependentPicklistValuesViaDependentFieldApiTest() {
                        
        //GIVEN: A Controllling picklist field value already exists
        String objectName = 'Case';
        String dependentField = 'Managing_Faculty__c' ; //Define dependent picklist value
        Schema.sObjectField dependToken = Schema.getGlobalDescribe().get( objectName ).getDescribe().fields.getMap().get( dependentField );
        //Run as Admin as it will be executed in Without Sharing mode
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];
        MonConCaseServices.FieldDependencyWrapper obj;
        System.runAs(adminUser) {
            Test.startTest();
            //WHEN: A dependent picklist value with values should exist
            obj = MonConCaseServices.getDependentPicklistValuesViaDependentFieldAPI(dependToken);
            Test.stopTest();
        }
        
        Map<String, List<String>> controllingFieldDepndntField = obj.fieldDependencyMap;
        // THEN: there is a map created holding the Controlling and dependent picklist value
        Assert.areNotEqual(0, controllingFieldDepndntField.size(), 'There are no mapping values');       
    }

    @IsTest
    static void testWebtoCaseOwnerAssignment(){
        //GIVEN : Test contact to associate the enquiry with
        MonConTestDataFactory.createSObject(new Contact(), true);

        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.SuppliedEmail = 'testEmail@test.edu';
        insert cse;

        Case cse1 = (Case)MonConTestDataFactory.createSObject(new Case());
        cse1.SuppliedEmail = 'testEmail2@test.edu';
        insert cse1;

        List<Case> lstCases = new List<Case>();
        lstCases.add(cse);
        lstCases.add(cse1);
         //Run as Admin as it will be executed in Without Sharing mode
         User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];
        System.runAs(adminUser) {
            //WHEN: The Owner assignment is initiated
            Test.startTest();
            MonConCaseServices.WebtoCaseOwnerAssignment(lstCases);
            Test.stopTest();
        }
        
        //THEN: The User type is updated
        Case c = [SELECT User_Type__c FROM Case where Id=:cse1.Id];
        System.assertEquals('Guest', c.User_Type__c);
    }

    @IsTest
    static void testCreateAndLinkEntitlement(){
        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);

        //Start test
        Test.startTest();
        List<Case> enquiryList = new List<Case>();
        for(Integer counter = 0; counter < 1; counter++){
            enquiryList.add(new Case(Subject = 'Testing SLA',
                    OwnerId = MONASH_CURRENT_QUEUEID,
                    ContactId = testContact.Id,
                    RecordTypeId = STANDARD_ENQUIRY_ID,
                    Origin = 'Web - Online Form'));
        }

        //Commit enquiry creation
        insert enquiryList;

        Case cse = [Select SLA_Breach_DateTime__c from Case];
        cse.SLA_Breach_DateTime__c = System.Now();
        update cse;

        Test.stopTest();

        //Retrieve entitlement Id on Case
        Case c = [SELECT Id, EntitlementId, AccountId, SLA_Breach_DateTime__c FROM Case];
        //Check if entitlement is linked to case
        System.assert(c.EntitlementId == [SELECT Id FROM Entitlement WHERE AccountId =: c.AccountId].Id);
        //Test SLA auto complete milestone
        System.assert([SELECT Id,CommentBody FROM CaseComment WHERE ParentId =: c.Id].CommentBody != null);
    }

    @IsTest
    static void testLinkCourseWhenContactLinks(){
        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);

        Course__c crse = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);

        List<Course_Attempt__c> lstCourseAttempts = new List<Course_Attempt__c>();
        lstCourseAttempts = TestHelper.createCourseAttempts(2, testContact.Id, crse.Id);
        lstCourseAttempts.get(0).Location__c = 'Clayton';
        lstCourseAttempts.get(1).Location__c = 'Clayton';
        lstCourseAttempts.get(1).Course_Attempt_Status__c = 'Completed';
        insert lstCourseAttempts;

        //Start test
        Test.startTest();
        List<Case> enquiryList = new List<Case>();
        for(Integer counter = 0; counter < 1; counter++){
            enquiryList.add(new Case(Subject = 'Testing Course Linking',
                    Managing_Faculty__c = 'FACULTY OF LAW',
                    Course_Linked__c = false,
                    OwnerId = MONASH_CURRENT_QUEUEID,
                    ContactId = testContact.Id,
                    RecordTypeId = STANDARD_ENQUIRY_ID,
                    Origin = 'Web - Online Form'));
        }
        //Commit enquiry creation
        insert enquiryList;
        Test.stopTest();

        //Retrieve case
        Case c = [SELECT Id, Course__c FROM Case];
        //Check if course is updated on case
        System.assert(c.Course__c == crse.Id);
    }

    @IsTest
    static void testLinkCourseWhenContactChanges(){
        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
        Contact testContact1 = (Contact)MonConTestDataFactory.createSObject(new Contact());
        testContact1.Person_ID_unique__c = '12345679';
        insert testContact1;

        Course__c crse = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);

        List<Course_Attempt__c> lstCourseAttempts = new List<Course_Attempt__c>();
        lstCourseAttempts = TestHelper.createCourseAttempts(2, testContact1.Id, crse.Id);
        lstCourseAttempts.get(0).Location__c = 'Clayton';
        lstCourseAttempts.get(1).Location__c = 'Clayton';
        lstCourseAttempts.get(1).Course_Attempt_Status__c = 'Completed';
        insert lstCourseAttempts;

        //Start test
        Test.startTest();
        List<Case> enquiryList = new List<Case>();
        for(Integer counter = 0; counter < 1; counter++){
            enquiryList.add(new Case(Subject = 'Testing Course Linking',
                    Managing_Faculty__c = 'FACULTY OF LAW',
                    Course_Linked__c = false,
                    OwnerId = MONASH_CURRENT_QUEUEID,
                    ContactId = testContact.Id,
                    RecordTypeId = STANDARD_ENQUIRY_ID,
                    Origin = 'Web - Online Form'));
        }
        //Commit enquiry creation
        insert enquiryList;
        Case c = enquiryList.get(0);
        c.ContactId = testContact1.Id;
        update c;

        Test.stopTest();

        //Retrieve case
        Case cse = [SELECT Id, Course__c FROM Case];
        //Check course is updated on Case
        System.assert(cse.Course__c == crse.Id);
    }

    @IsTest
    static void testUnlinkCourseWhenContactIsRemoved(){
        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);

        Course__c crse = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);

        List<Course_Attempt__c> lstCourseAttempts = new List<Course_Attempt__c>();
        lstCourseAttempts = TestHelper.createCourseAttempts(2, testContact.Id, crse.Id);
        lstCourseAttempts.get(0).Location__c = 'Clayton';
        lstCourseAttempts.get(1).Location__c = 'Clayton';
        lstCourseAttempts.get(1).Course_Attempt_Status__c = 'Completed';
        insert lstCourseAttempts;

        //Start test
        Test.startTest();
        List<Case> enquiryList = new List<Case>();
        for(Integer counter = 0; counter < 1; counter++){
            enquiryList.add(new Case(Subject = 'Testing Course Linking',
                    Managing_Faculty__c = 'FACULTY OF LAW',
                    Course_Linked__c = false,
                    OwnerId = MONASH_CURRENT_QUEUEID,
                    ContactId = testContact.Id,
                    RecordTypeId = STANDARD_ENQUIRY_ID,
                    Origin = 'Web - Online Form'));
        }
        //Commit enquiry creation
        insert enquiryList;
        Case c = enquiryList.get(0);
        c.ContactId = null;
        update c;
        Test.stopTest();

        //Retrieve case
        Case cse = [SELECT Id, Course__c FROM Case];
        //Check if course is cleared on case
        System.assert(cse.Course__c == null);
    }

    @IsTest
    static void testvalidateFutureCourseEnquiriesBeforeClosing(){
        //Retrieve a monsh connect user to test with
        String monashConnectRole = '%' + Label.Monash_Connect + '%';
        User monashConnectUser = [SELECT Id, UserRole.Name FROM User
                                    WHERE UserRole.Name LIKE :monashConnectRole AND IsActive = TRUE
                                        AND Profile.Name = 'Base Profile' AND UserRole.Name != NULL LIMIT 1];

        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
        Contact testContact1 = (Contact)MonConTestDataFactory.createSObject(new Contact());
        testContact1.Person_ID_unique__c = '12345679';
        insert testContact1;

        Course__c crse = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);

        Test.startTest();
            Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
            cse.ContactId = testContact.Id;
            cse.ownerId = monashConnectUser.Id;
            insert cse;

            Case cse1 = (Case)MonConTestDataFactory.createSObject(new Case());
            cse1.ContactId = testContact1.Id;
            cse1.ownerId = monashConnectUser.Id;
            insert cse1;

            Course_Attempt__c crsAttempt = (Course_Attempt__c)MonConTestDataFactory.createSObject(new Course_Attempt__c());
            crsAttempt.Course__c = crse.Id;
            crsAttempt.Contact__c = testContact.Id;
            insert crsAttempt;

        System.runAs(monashConnectUser) {
            cse.Enquiry_Type__c = 'Future Course';
            cse.Category_Level_1__c = 'Application';
            cse.Category_Level_2__c = 'Application Fee';
            cse.Status = Label.Solved;
            update cse;

            cse1.Enquiry_Type__c = 'Future Course';
            cse1.Category_Level_1__c = 'Application';
            cse1.Category_Level_2__c = 'Application Fee';
            cse1.Status = Label.Solved;
            update cse1;
        }
        Test.stopTest();

        Case c = [SELECT Id, Enquiry_Type__c FROM Case].get(0);
        System.assertEquals('Future Course',c.Enquiry_Type__c);
    }



}