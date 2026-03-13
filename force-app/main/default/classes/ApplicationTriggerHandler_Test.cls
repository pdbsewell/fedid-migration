/**
 * @description Test class for ApplicationTriggerHandler
 * @author      Nick guia
 * @date        FEB.23.2024
 * @last modified on  : 22-08-2024
 * @last modified by  : rajesh.punjabi@monash.edu
                        - created new test class method for 'RunACPQueueRouting'
 * @revision - On 08-08-2025 - By Sravani Naramsetty - 
 *             Added: Test methods updateApplicationStatusOnContQual_Test and updateApplicationStatusOnWrkExp_Test methods
 *             to test updateApplicationStatusOnContQual and updateApplicationStatusOnWrkExp methods in ApplicationTriggerHandler class
 */
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION : DML operations aren't permitted on this type of object: User
private class ApplicationTriggerHandler_Test {

    private static String AGENCY_ORG_UNIT_CODE = 'APP_TEST';

    @TestSetup
    static void makeData() {

        AgentPortalTestDataFactory factory = new AgentPortalTestDataFactory();

        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');
        TriggerCommon.disableTrigger('Application__c');
        TriggerCommon.disableTrigger('Application_Course_Preference__c');

        Country_Attribute__c auCountry = factory.createCountryAttribute(BDPConstants.AUSTRALIA_CALLISTA_CODE, 'AUSTRALIA');
        insert auCountry;

        // delegator agency for testing delegation
        Account agency = factory.createAgencyAccount(auCountry);
        agency.Callista_Org_Unit_Code__c = AGENCY_ORG_UNIT_CODE;
        insert agency;

        Contact branchMgr = factory.createAgentContact(agency);
        branchMgr.Agency_Contact_Roles__c = 'Branch Manager';
        insert branchMgr;

        // use runAs to avoid DML exception
        System.runAs(new User(Id = UserInfo.getUserId())) {
            User bmUser = factory.createAgentUser(branchMgr);
            insert bmUser;

            PermissionSetAssignment psa = factory.createAgentPermissionSetAssignment(bmUser);
            insert psa;
        }

        new AgentPortalTestDataBuilder.Application().build();

        Account facultyAccount = AssessmentsTestDataFactory.createFacultyAccount();
        insert facultyAccount;

        Contact applicant = AssessmentsTestDataFactory.createApplicant();
        insert applicant;

        Application__c application = AssessmentsTestDataFactory.createInternationalApplication('CAID-1239090', applicant.Id);
        application.Assessment_Status__c = 'Required';
        insert application;
        
        Application__c applicationSingleACP = AssessmentsTestDataFactory.createInternationalApplication('CAID-1239098', applicant.Id);
        applicationSingleACP.Assessment_Status__c = 'Required';
        insert applicationSingleACP;
        
        Application__c applicationDom = AssessmentsTestDataFactory.createDomesticApplication('CAID-1239091', applicant.Id);
        applicationDom.Assessment_Status__c = 'Required';
        insert applicationDom;

        Course__c busEcoCourse = AssessmentsTestDataFactory.createCourse(facultyAccount, 'Faculty of Business and Economics');
        insert busEcoCourse;
        
        Course__c mufyCourse = AssessmentsTestDataFactory.createCourse(facultyAccount, 'Monash University Foundation Year MUFY');
        insert mufyCourse;
        
        Course__c mcdCourse = AssessmentsTestDataFactory.createCourse(facultyAccount, 'Monash College Diplomas');
        insert mcdCourse;
        
        Course__c muelcCourse = AssessmentsTestDataFactory.createCourse(facultyAccount, 'Monash University English Language Centre');
        insert muelcCourse;
       
        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
        TriggerCommon.enableTrigger('Application__c');
        TriggerCommon.enableTrigger('Application_Course_Preference__c');
    }

    /**
     * @description should populate fields to track the first time
     * that an Agent sends the application to the applicant for review
     */
    @isTest
    static void shouldTrackAgentAndApplicantRevision() {

        // GIVEN
        Application__c app = [SELECT Id, Status__c, Agent_Edits_After_Applicant_Acceptance__c, Sent_to_student_for_review_Timestamp__c
                            FROM Application__c 
                            WHERE Status__c = :AgentPortalConstants.APP_CREATE_STATUS
                            LIMIT 1];
        
        Test.startTest();

        // WHEN
        app.Status__c = AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT;
        app.Sent_to_student_for_review_Timestamp__c = Datetime.now();
        update app;

        Test.stopTest();

        // THEN
        app = [SELECT Id, Status__c, Agent_Edits_After_Applicant_Acceptance__c, Sent_to_student_for_review_Timestamp__c
                FROM Application__c 
                WHERE Id = :app.Id
                LIMIT 1];

        Assert.isTrue(app.Agent_Edits_After_Applicant_Acceptance__c, 'Did not track Agent edits after an Applicant acceptance');
        Assert.isNotNull(app.Sent_to_student_for_review_Timestamp__c, 'Unable to capture timestamp of sending application to applicant');
    }

    /**
     * @description when an Application is linked to an Applicant
     * with an existing MyApp user, once the Application status
     * is updated to 'Sent Draft Application to Applicant',
     * The MyApp_User_Status__c must be updated to 'Existing User'
     * Subsequently, a queueable job would update it to 'Provisioned'
     * once a MyApp user has been successful provisioned
     */
    @isTest
    static void shouldPopulateMyAppUserStatusForExistingUser() {

        // GIVEN
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');
        TriggerCommon.disableTrigger('Application__c');
        TriggerCommon.disableTrigger('Application_Course_Preference__c');

        // enable applicant as myapp user, so there's an existing
        AgentPortalTestDataBuilder.Application appBuilder = new AgentPortalTestDataBuilder.Application()
            .build()
            .enableMyAppUser();

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
        TriggerCommon.enableTrigger('Application__c');
        TriggerCommon.enableTrigger('Application_Course_Preference__c');

        Test.startTest();

        // WHEN
        appBuilder.app.Status__c = AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT;
        update appBuilder.app;

        Test.stopTest();

        // THEN
        Application__c result = [SELECT Id, MyApp_User_Status__c
                                FROM Application__c
                                WHERE Id = :appBuilder.app.Id
                                LIMIT 1];
        Assert.areEqual('Provisioned', result.MyApp_User_Status__c, 'Unable to update MyApp User Status for existing User');
    }

    /**
     * @description when an Application is linked to an Applicant
     * without an existing MyApp user, once the Application status
     * is updated to 'Sent Draft Application to Applicant',
     * The MyApp_User_Status__c must be updated to 'In Progress'.
     * Subsequently, a queueable job would update it to 'Provisioned'
     * once a MyApp user has been successful provisioned
     */
    @isTest
    static void shouldPopulateMyAppUserStatusForNewUser() {

        // GIVEN
        Application__c app = [SELECT Id, Status__c
                            FROM Application__c 
                            WHERE Status__c = :AgentPortalConstants.APP_CREATE_STATUS
                            LIMIT 1];
        
        Test.startTest();

        // WHEN
        app.Status__c = AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT;
        update app;

        Test.stopTest();

        // THEN
        Application__c result = [SELECT Id, MyApp_User_Status__c
                                FROM Application__c
                                WHERE Id = :app.Id
                                LIMIT 1];
        Assert.areEqual('Provisioned', result.MyApp_User_Status__c, 'Unable to update MyApp User Status for existing User');
    }

    /**
     * @description when an Agent updates an Application to 
     * AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT,
     * the system should elevate the applicant's contact record into
     * a myApp user so that the Applicant can review their Application
     */
    @isTest
    static void shouldEnableMyAppAccessForNonExistingUser() {

        // GIVEN
        Application__c app = [SELECT Id, Status__c, Applicant__c
                            FROM Application__c 
                            WHERE Status__c = :AgentPortalConstants.APP_CREATE_STATUS
                            LIMIT 1];
        
        Test.startTest();

        // WHEN
        app.Status__c = AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT;
        update app;

        Test.stopTest();

        // THEN
        User myAppUser =  [SELECT Id, ContactId 
                            FROM User 
                            WHERE Profile.Name = 'Customer Community General User'
                            AND IsActive = TRUE
                            AND ContactId = :app.Applicant__c
                            LIMIT 1];

        Assert.isNotNull(myAppUser, 'Unable to elevate applicant to a MyApp User');
    }

    /**
     * @description when an Agent updates an Application to 
     * AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT,
     * the system would attempt to elevate the applicant's contact record into
     * a myApp user. However, there may be chances that a duplicate username already exists
     * in the system, and that the Application requires a merge to happen first.
     * This test simulates that by setting Task_Duplicate_Check__c to 'Required' then
     * updating it to 'Completed'
     */
    @isTest
    static void shouldEnableMyAppAccessAfterCompletingMerge() {

        // GIVEN
        Application__c app = [SELECT Id, Status__c, Applicant__c, Task_Duplicate_Check__c, Duplicate_Check_Outcome__c
                            FROM Application__c 
                            WHERE Status__c = :AgentPortalConstants.APP_CREATE_STATUS
                            LIMIT 1];
        // setup the Application to already be in SEND_DRAFT_APPLICATION_TO_APPLICANT
        app.Status__c = AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT;
        // but requiring a merge
        app.Task_Duplicate_Check__c = 'Required';

        TriggerCommon.disableTrigger('Application__c');
        update app;
        TriggerCommon.enableTrigger('Application__c');

        Test.startTest();

        // WHEN
        app.Task_Duplicate_Check__c = 'Completed';
        app.Duplicate_Check_Outcome__c = 'Merged Successfully';
        update app;

        Test.stopTest();

        // THEN

        // the Applicant should have been elevated to a myApp user
        User myAppUser = [SELECT Id 
                        FROM User
                        WHERE ContactId = :app.Applicant__c
                        LIMIT 1];
        Assert.isNotnull(myAppUser, 'Unable to elevate applicant to a MyApp User');
    }

    /**
     * @description 
     * GIVEN An Application from Agent Portal
     * WHEN the Application reaches "Sent for Submission" status
     * AND Delegator Org Unit Code is not blank (meaning a Delegator was nominated by a Delegate Agency),
     * THEN update the Agency field of the Application to the Account of the Delegator Org Unit Code
     */
    @isTest
    static void shouldDelegateApplicationBeforeSubmit() {

        // GIVEN : setup data

        // get setup application
        Application__c app = [SELECT Id, Status__c, Source_System__c, Agent__c, Agent_Org_Unit_Code__c, Delegator_Org_Unit_Code__c
                            FROM Application__c
                            WHERE Source_System__c = 'AgentPortal'
                            LIMIT 1];
        // delegator agency
        Id agencyRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                                    .get('Agency')
                                    .getRecordTypeId();
        Account expectedDelegator = [SELECT Id, Callista_Org_Unit_Code__c,
                                        (SELECT Id FROM Contacts WHERE Agency_Contact_Roles__c INCLUDES ('Branch Manager'))
                                    FROM Account
                                    WHERE RecordTypeId = :agencyRecTypeId
                                    AND Callista_Org_Unit_Code__c = :AGENCY_ORG_UNIT_CODE
                                    LIMIT 1];
        Assert.isTrue(!expectedDelegator.Contacts.isEmpty(), 'Delegator Agency does not have a Branch Manager');
        Contact bm = expectedDelegator.Contacts[0];
        User bmUser = [SELECT Id FROM User WHERE ContactId = :bm.Id LIMIT 1];

        Test.startTest();

        // WHEN : Application Status is changed to Sent for Submission and a Delegator Org Unit Code is present
        app.Status__c = MyApplicationUtilities.APP_SENT_FOR_SUBMIT_STATUS;
        app.Delegator_Org_Unit_Code__c = expectedDelegator.Callista_Org_Unit_Code__c;
        update app;

        Test.stopTest();

        // THEN : An Agency transfer should take place and the Application Owner should be the new Agency's BM
        Application__c updatedApp = [SELECT Id, Status__c, Source_System__c, Agent__c, Agent_Org_Unit_Code__c, 
                                        Delegator_Org_Unit_Code__c, OwnerId
                                    FROM Application__c
                                    WHERE Id = :app.Id
                                    LIMIT 1];
        Assert.areEqual(expectedDelegator.Id, updatedApp.Agent__c, 'Unable to delegate Agency');
        Assert.areEqual(expectedDelegator.Callista_Org_Unit_Code__c, updatedApp.Agent_Org_Unit_Code__c, 'Unable to delegate Agency');
        Assert.areEqual(bmUser.Id, updatedApp.OwnerId, 'Unable to transfer ownership to new Agency BM');
    }

    /**
    * @description Standard ACP routing.
    * @author Jitender Padda 
    * GIVEN An Application with ACPS is created
    * WHEN the Application reaches "Submitted" status
    * THEN ACPs are routed to correct queue for assessment
    **/
    @isTest
    static void runACPQueueRouting_Test() {

        // GIVEN: Two ACPs - BUSECO INT (AUSAID-PG) & BUSECO DOM (PG-CSP)
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
        Course__c busEcoCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Faculty of Business and Economics'];

        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'AUSAID-PG', 'CLAYTON', 'IN', null,'1'));
        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'PG-CSP', 'CLAYTON', 'IN', 'B6024','2'));

        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        insert acpList;
        acpList = [SELECT Managing_Faculty__c, Admission_Category__c, Attendance_Mode__c, Location_Code__c FROM Application_Course_Preference__c WHERE Application__c=:application.Id];
        TriggerCommon.enableTrigger('Application_Course_Preference__c');
        List<Queue_Routing_Rule_Condition__c> conditions = new List<Queue_Routing_Rule_Condition__c>();
        List<Map<String, String>> conditionsData = new List<Map<String, String>>();
        Queue_Routing_Rule__c rule;

        // GIVEN: ACP Queue Routing rule for BusEco International
        rule = AssessmentsTestHelper.createRule('Central Admissions BUSECO - INTERNATIONAL', 1, 'CENTRAL_ADMISSIONS_BUSECO', true);
        insert rule;

        AssessmentsTestHelper.addCondition(conditionsData, 'Managing_Faculty__c', 'EQUALS', 'Faculty of Business and Economics');
        AssessmentsTestHelper.addCondition(conditionsData, 'Admission_Category__c', 'EQUALS', 'AUSAID-PG; AUSAID-UG; UG-IS; PG-IS');
        AssessmentsTestHelper.addCondition(conditionsData, 'Attendance_Mode__c', 'NOT EQUAL TO', 'EX; MM; OL');
        AssessmentsTestHelper.addCondition(conditionsData, 'Location_Code__c', 'NOT EQUAL TO', 'MALAYSIA; INDONESIA');

        AssessmentsTestHelper.createConditions(rule.Id, conditionsData, conditions);
        insert conditions;
        
        Test.startTest();
        // WHEN: Application is Submitted
        application.Status__c='Submitted';
        update application;
        Test.stopTest();

        //THEN: BUSECO INT (AUSAID-PG) is routed to BusEco Queue
        Group busEcoQueue = [SELECT Id FROM Group WHERE DeveloperName = :rule.Queue__c];
        System.assertEquals([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'AUSAID-PG'].OwnerId, busEcoQueue.Id);

        //THEN: BUSECO DOM (PG-CSP) is routed to Unallocated Queue
        Group unallocatedQueue = [SELECT Id FROM Group WHERE DeveloperName = :'Unallocated_ACP_Queue'];
        Assert.areNotEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'PG-CSP'].OwnerId, unallocatedQueue.Id);
    }

    /**
    * @description RunAs scenarion for PMD Rules
    * @author rajesh.punjabi@monash.edu | 22-08-2024 
    **/
    @isTest
    static void runACPQueueRoutingRunAs_Test() {

        // GIVEN: Two ACPs - BUSECO INT (AUSAID-PG) & BUSECO DOM (PG-CSP)
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
        Course__c busEcoCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Faculty of Business and Economics'];

        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'AUSAID-PG', 'CLAYTON', 'IN', null,'1'));
        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'PG-CSP', 'CLAYTON', 'IN', 'B6024','2'));

        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        insert acpList;
        acpList = [SELECT Managing_Faculty__c, Admission_Category__c, Attendance_Mode__c, Location_Code__c FROM Application_Course_Preference__c WHERE Application__c=:application.Id];
        TriggerCommon.enableTrigger('Application_Course_Preference__c');
        List<Queue_Routing_Rule_Condition__c> conditions = new List<Queue_Routing_Rule_Condition__c>();
        List<Map<String, String>> conditionsData = new List<Map<String, String>>();
        Queue_Routing_Rule__c rule;

        // GIVEN: ACP Queue Routing rule for BusEco International
        rule = AssessmentsTestHelper.createRule('Central Admissions BUSECO - INTERNATIONAL', 1, 'CENTRAL_ADMISSIONS_BUSECO', true);
        insert rule;

        AssessmentsTestHelper.addCondition(conditionsData, 'Managing_Faculty__c', 'EQUALS', 'Faculty of Business and Economics');
        AssessmentsTestHelper.addCondition(conditionsData, 'Admission_Category__c', 'EQUALS', 'AUSAID-PG; AUSAID-UG; UG-IS; PG-IS');
        AssessmentsTestHelper.addCondition(conditionsData, 'Attendance_Mode__c', 'NOT EQUAL TO', 'EX; MM; OL');
        AssessmentsTestHelper.addCondition(conditionsData, 'Location_Code__c', 'NOT EQUAL TO', 'MALAYSIA; INDONESIA');

        AssessmentsTestHelper.createConditions(rule.Id, conditionsData, conditions);
        insert conditions;
        
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];

        Test.startTest();

        System.runAs(u) {
            // WHEN: Application is Submitted
            application.Status__c='Submitted';
            update application;
        }
        
        Test.stopTest();

        //THEN: BUSECO INT (AUSAID-PG) is routed to BusEco Queue
        Group busEcoQueue = [SELECT Id FROM Group WHERE DeveloperName = :rule.Queue__c];
        Assert.areEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'AUSAID-PG'].OwnerId, busEcoQueue.Id);

        //THEN: BUSECO DOM (PG-CSP) is routed to Unallocated Queue
        Group unallocatedQueue = [SELECT Id FROM Group WHERE DeveloperName = :'Unallocated_ACP_Queue'];
        Assert.areNotEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'PG-CSP'].OwnerId, unallocatedQueue.Id);
    }


    /**
    * @description Test Monash College Courses
    * @author rajesh.punjabi@monash.edu | 22-08-2024 
    * GIVEN An Application with ACPS is created
    * WHEN the Application reaches "Submitted" status
    * THEN ACPs are routed to correct queue for assessment
    **/
    @isTest
    static void runACPQueueRoutingCollege_Test() {

        // GIVEN: Two ACPs - MCD and MUFY
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
        Course__c mufyCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Monash University Foundation Year MUFY'];
        Course__c mcdCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Monash College Diplomas'];

        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, mufyCourse.Id, 'AUSAID-PG', 'CLAYTON', 'IN', null,'1'));
        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, mcdCourse.Id, 'PG-CSP', 'CLAYTON', 'IN', 'B6024','2'));

        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        insert acpList;
        acpList = [SELECT Managing_Faculty__c, Admission_Category__c, Attendance_Mode__c, Location_Code__c FROM Application_Course_Preference__c WHERE Application__c=:application.Id];
        TriggerCommon.enableTrigger('Application_Course_Preference__c');
        
        Test.startTest();
        // WHEN: Application is Submitted
        application.Status__c='Submitted';
        update application;
        Test.stopTest();

        //THEN: ACP not routed to Unallocated Queue
        Group unallocatedQueue = [SELECT Id FROM Group WHERE DeveloperName = :'Unallocated_ACP_Queue'];
        Assert.areNotEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'PG-CSP'].OwnerId, unallocatedQueue.Id);
    }
    
    /**
    * @description Monash College Courses Negative Test
    * @author rajesh.punjabi@monash.edu | 22-08-2024 
    * GIVEN An Application with ACPS is created
    * WHEN the Application reaches "Submitted" status
    * THEN ACPs are routed to correct queue for assessment
    **/

    @isTest
    static void runACPQueueRoutingCollegeNeg_Test() {

        // GIVEN: Two ACPs - MCD and MUFY
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
        Course__c mufyCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Monash University English Language Centre'];
        Course__c mcdCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Monash College Diplomas'];

        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, mufyCourse.Id, 'AUSAID-PG', 'CLAYTON', 'IN', null,'1'));
        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, mcdCourse.Id, 'DEEP-IS', 'CLAYTON', 'IN', 'B6024','2'));

        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        insert acpList;
        acpList = [SELECT Managing_Faculty__c, Admission_Category__c, Attendance_Mode__c, Location_Code__c FROM Application_Course_Preference__c WHERE Application__c=:application.Id];
        TriggerCommon.enableTrigger('Application_Course_Preference__c');
	   
        Test.startTest();
        // WHEN: Application is Submitted
        application.Status__c='Submitted';
        update application;
        Test.stopTest();

        //THEN: ACP not routed to Unallocated Queue
        Group unallocatedQueue = [SELECT Id FROM Group WHERE DeveloperName = :'Unallocated_ACP_Queue'];
        Assert.areEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'DEEP-IS'].OwnerId, unallocatedQueue.Id);
    }
    
    /**
    * @description Monash College Courses English Courses Test
    * @author rajesh.punjabi@monash.edu | 22-08-2024 
    * GIVEN An Application with ACPS is created
    * WHEN the Application reaches "Submitted" status
    * THEN ACPs are routed to correct queue for assessment
    **/

    @isTest
    static void runACPQueueRoutingCollegeEnglish_Test() {

        // GIVEN: Two ACPs - MCD and Enlgish
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
        Course__c mufyCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Monash University English Language Centre'];

        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, mufyCourse.Id, 'MC-STEM-AU', 'CLAYTON', 'IN', null,'1'));
        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, mufyCourse.Id, 'MON-COL-IS', 'CLAYTON', 'IN', null,'2'));
        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        insert acpList;
        acpList = [SELECT Managing_Faculty__c, Admission_Category__c, Attendance_Mode__c, Location_Code__c FROM Application_Course_Preference__c WHERE Application__c=:application.Id];
        TriggerCommon.enableTrigger('Application_Course_Preference__c');
	   
        Test.startTest();
        // WHEN: Application is Submitted
        application.Status__c='Submitted';
        update application;
        Test.stopTest();

        //THEN: ACP routed to Unallocated Queue
        Group unallocatedQueue = [SELECT Id FROM Group WHERE DeveloperName = :'Unallocated_ACP_Queue'];
        Assert.areEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'MON-COL-IS'].OwnerId, unallocatedQueue.Id);
    }
    
    /**
    * @description Domestic Application
    * @author rajesh.punjabi@monash.edu | 22-08-2024 
    * GIVEN An Application with ACPS is created
    * WHEN the Application reaches "Submitted" status
    * THEN ACPs are routed to correct queue for assessment 
    **/
    @isTest
    static void runACPQueueRoutingDomestic_Test() {

        // GIVEN: Two ACPs - BUSECO INT (AUSAID-PG) & BUSECO DOM (PG-CSP)
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239091' LIMIT 1][0];
        Course__c busEcoCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Faculty of Business and Economics'];

        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'AUSAID-PG', 'CLAYTON', 'IN', null,'1'));
        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'PG-CSP', 'CLAYTON', 'IN', 'B6024','2'));

        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        insert acpList;
        acpList = [SELECT Managing_Faculty__c, Admission_Category__c, Attendance_Mode__c, Location_Code__c FROM Application_Course_Preference__c WHERE Application__c=:application.Id];
        TriggerCommon.enableTrigger('Application_Course_Preference__c');   
        
        Test.startTest();
        // WHEN: Application is Submitted
        application.Status__c='Submitted';
        update application;
        Test.stopTest();

        //THEN: ACP not routed to Unallocated Queue
        Group unallocatedQueue = [SELECT Id FROM Group WHERE DeveloperName = :'Unallocated_ACP_Queue'];
        Assert.areNotEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'PG-CSP'].OwnerId, unallocatedQueue.Id);
    }
       
    /**
    * @description Single ACP
    * @author rajesh.punjabi@monash.edu | 22-08-2024
    * GIVEN An Application with ACPS is created
    * WHEN the Application reaches "Submitted" status
    * THEN ACPs are routed to correct queue for assessment 
    **/
    @isTest
    static void runACPQueueRoutingSingleACP_Test() {

        // GIVEN: One ACP - BUSECO INT (AUSAID-PG)
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239098' LIMIT 1][0];
        Course__c busEcoCourse = [SELECT Id FROM Course__c WHERE Faculty_Description__c = 'Faculty of Business and Economics'];

        acpList.add(AssessmentsTestDataFactory.createACP(application.Id, busEcoCourse.Id, 'AUSAID-PG', 'CLAYTON', 'IN', null,'1'));

        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        insert acpList;
        acpList = [SELECT Managing_Faculty__c, Admission_Category__c, Attendance_Mode__c, Location_Code__c FROM Application_Course_Preference__c WHERE Application__c=:application.Id];
        TriggerCommon.enableTrigger('Application_Course_Preference__c');   
  
        Test.startTest();
        // WHEN: Application is Submitted
        application.Status__c='Submitted';
        update application;
        Test.stopTest();

        //THEN: ACP routed to Unallocated Queue
        Group unallocatedQueue = [SELECT Id FROM Group WHERE DeveloperName = :'Unallocated_ACP_Queue'];
        Assert.areEqual([SELECT OwnerId FROM Application_Course_Preference__c WHERE Admission_Category__c = 'AUSAID-PG'].OwnerId, unallocatedQueue.Id);
    }
    
    /**
    * @description Update Application Status on Contact Qualification
    * @author sravani.naramsetti@monash.edu | 18-07-2025
    * GIVEN An Application which has Application Qualification Provided record
    * WHEN the Application changes status
    * THEN Application Status on Contact Qualification is updated
    **/
    @isTest
    static void updateApplicationStatusOnContQual_Test() {

        // GIVEN: Application has AQP record
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239098' LIMIT 1][0];
		Contact applicant = [Select id from Contact LIMIT 1];
        //create qualification
        Qualification__c qual = StudFirst_TestHelper.createQualification('custom qual');
        insert qual;
        //create contact qualification
        Contact_Qualification__c cqual = StudFirst_TestHelper.createContactQualification(applicant, qual, 'Secondary Education');
        insert cqual;
        //create application qualification provided
        Application_Qualification_Provided__c aqp = StudFirst_TestHelper.createAppQualProvided(application.Id, cqual.Id);
        insert aqp;
 
  
        Test.startTest();
        // WHEN: Application status is changed
        application.Status__c='Submitted';
        update application;
        Test.stopTest();

        //THEN: Application Status on Contact Qualification is updated
        Contact_Qualification__c cq = [SELECT Id, Application_Status__c FROM Contact_Qualification__c LIMIT 1];
        Assert.areEqual(cq.Application_Status__c, 'Submitted');
    }
    
    /**
    * @description Update Application Status on Work Experience
    * @author sravani.naramsetti@monash.edu | 30-07-2025
    * GIVEN An Application which has Application Work Experience Provided record
    * WHEN the Application changes status
    * THEN Application Status on Work Experience is updated
    **/
    @isTest
    static void updateApplicationStatusOnWrkExp_Test() {

        // GIVEN: Application has AQP record
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239098' LIMIT 1][0];
		Contact applicant = [Select id from Contact LIMIT 1];
        //create work experience
        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = applicant.Id;
        insert workExpRecord;
        //create application work experience provided
        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = application.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord; 
  
        Test.startTest();
        // WHEN: Application status is changed
        application.Status__c='Review';
        update application;
        Test.stopTest();

        //THEN: Application Status on Contact Qualification is updated
        Work_Experience__c we = [SELECT Id, Application_Status__c FROM Work_Experience__c LIMIT 1];
        Assert.areEqual(we.Application_Status__c, 'Review');
    }
    
        /**
    * @description Update Application Status on Work Experience
    * @author sravani.naramsetti@monash.edu | 30-07-2025
    * GIVEN An Application which has Application Work Experience Provided record which is shared
    * WHEN the Application changes status
    * THEN Application Status on Work Experience is updated
    **/
    @isTest
    static void updateApplicationStatusOnWrkExp1_Test() {

        // GIVEN: Application has AQP record
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239098' LIMIT 1][0];
		Application__c application1 = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
		Contact applicant = [Select id from Contact LIMIT 1];
        //create work experience
        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = applicant.Id;
        insert workExpRecord;
        //create application work experience provided
        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = application.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord; 
        
        //create application work experience provided
        Application_Work_Experience_Provided__c aweRecord1 = new Application_Work_Experience_Provided__c();
        aweRecord1.Application__c = application1.Id;
        aweRecord1.Work_Experience__c = workExpRecord.Id;
        insert aweRecord1; 
  
        Test.startTest();
        // WHEN: Application status is changed
        application.Status__c='Submitted';
        update application;
        application1.Status__c='Review';
        update application1;
        
        Test.stopTest();

        //THEN: Application Status on Contact Qualification is updated
        Work_Experience__c we = [SELECT Id, Application_Status__c FROM Work_Experience__c LIMIT 1];
        Assert.areEqual(we.Application_Status__c, 'Submitted');
    }
    
            /**
    * @description Update Application Status on Work Experience
    * @author sravani.naramsetti@monash.edu | 30-07-2025
    * GIVEN An Application which has Application Work Experience Provided record which is shared
    * WHEN the Application changes status
    * THEN Application Status on Work Experience is updated
    **/
    @isTest
    static void updateApplicationStatusOnWrkExp2_Test() {

        // GIVEN: Application has AQP record
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239098' LIMIT 1][0];
		Application__c application1 = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
		Contact applicant = [Select id from Contact LIMIT 1];
        //create work experience
        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = applicant.Id;
        insert workExpRecord;
        //create application work experience provided
        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = application.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord; 
        
        //create application work experience provided
        Application_Work_Experience_Provided__c aweRecord1 = new Application_Work_Experience_Provided__c();
        aweRecord1.Application__c = application1.Id;
        aweRecord1.Work_Experience__c = workExpRecord.Id;
        insert aweRecord1; 
  
        Test.startTest();
        // WHEN: Application status is changed
        application.Status__c='Review';
        update application;
        application1.Status__c='Submitted';
        update application1;
        
        Test.stopTest();

        //THEN: Application Status on Contact Qualification is updated
        Work_Experience__c we = [SELECT Id, Application_Status__c FROM Work_Experience__c LIMIT 1];
        Assert.areEqual(we.Application_Status__c, 'Submitted');
    }
}