/*******************************************************************************
* @author       Ryan Wilson
* @date         07.Apr.2017         
* @description  controller class for CoursePreference.cmp lightning component
* @revision     22/02/2019 (Stefan Scheit): Removed depdencency on LightingSelfRegisterController
				15/09/2018 (Stefan Scheit): Changed class to with sharing &  new testSetup method for community user setup (should move to StudFirst test helper, which is not in test context...) 
				24/8/2022 (Ken McGuire) Removed South Africa from Campus_Location__c picklist
*******************************************************************************/
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
private class CoursePreferenceCC_Test {
    private static Application__c appRecord;
    private static final String myUserName = 'CoursePreferenceCC_Test@mutesting.com';
    private static User communityUser;
    private static Contact contactRec;
    private static Application_Course_Preference__c coursePrefA;
    private static Application_Course_Preference__c coursePrefB;
    private static Course_Offering__c courseOfferingRec;
    private static Course_Offering__c courseOfferingRecNoUnit;

    @testSetup
    static void communityUserRecordSetup() {
        //Account
        Account accountRecord = new Account(name ='AccountTest');
        insert accountRecord;
        
        //Contact
        contactRec = new Contact();
        contactRec.FirstName = 'First';
        contactRec.LastName = 'Last';
        contactRec.Citizenship__c = 'INTERNATIONAL';
        contactRec.AccountId = accountRecord.Id ;
        contactRec.Residency_Status__c = 'INT-TEP';
        insert contactRec;
        
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;
        Integer rnd = Integer.valueOf(Math.random()*9999);
                
        User communityUserToCreate = new User(Alias = String.valueOf(rnd)+ 'usr',
                                         Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                                         EmailEncodingKey = 'UTF-8',
                                         LastName = 'TestingUser',
                                         LanguageLocaleKey = 'en_US',
                                         LocaleSidKey = 'en_GB',
                                         ProfileId = profileId,
                                         TimeZoneSidKey = 'Australia/Sydney',
                                         UserName = myUserName,
                                         ContactId = contactRec.Id,
                                         App_Salutation__c = '',
                                         App_Gender__c = '',
                                         App_Birthdate__c = null,
                                         App_Residency_Status__c = 'INT-TEP',
                                         Street = '',
                                         App_Address_Type__c = 'POSTAL');
        insert communityUserToCreate;
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) { // this is to run mixed DML (only allowed in future or runAs context)
    		try {
                PermissionSet myPermissionSetId = [SELECT Id, Name FROM permissionset WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME];
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = myPermissionSetId.Id, AssigneeId = communityUserToCreate.Id);
                insert psa;

                // Insertion of a Course_Offering__c.
                Course_Offering__c courseOfferingVar = new Course_Offering__c(
                Location_Code__c='Clayton',
                Course_Code__c='M00001',
                Course_Title__c='Master Of Something Something',
                Academic_Year__c=2018,
                Admission_Calendar_Type__c='ADM',
                Attendance_Mode__c='SCG',
                Attendance_Type__c='PT',
                Citizenship_Type__c='DOM-AUS',
                Course_Type__c='10',
                Faculty__c='Faculty of Law',
                Location__c='Clayton',
                Type_of_Place_Code__c ='PC001');
                insert courseOfferingVar;

            } catch (Exception ex) {
                System.debug('@@ex: '+ ex.getMessage());
                ExLog.add('CoursePreferernceCC_Test Class', 'CoursePreferernceCC_Test', 'test_createCommunityUser' , ex.getMessage());
            }
        }
    }
    
    @isTest
    static void test_getInitDataMalaysia()
    {
        //create a community user
        communityUser = [SELECT Id, ContactId FROM User WHERE username = :myUserName LIMIT 1];
        Contact conApplicant = [Select Id, Residency_Status__c FROM Contact where id =: communityUser.contactId];
        
        // create application
        Application__c app = StudFirst_TestHelper.createApplication(conApplicant);
        app.Campus_Location__c = 'Malaysia';
        insert app;
                
		Test.startTest();
        System.runAs(communityUser) {
			Map<String, Object> mapResults = CoursePreferenceCC.getInitData(app.Id);
            String appCampusLocation = (String) mapResults.get(CoursePreferenceCC.FIELD_APPLICATION_CAMPUS_LOCATION);
            System.assertEquals(app.Campus_Location__c, appCampusLocation);
        }
        Test.stopTest();
    }
    @isTest
    static void test_getInitDataSAfrica()
    {
        //create a community user
        communityUser = [SELECT Id, ContactId FROM User WHERE username = :myUserName LIMIT 1];
        Contact conApplicant = [Select Id, Residency_Status__c FROM Contact where id =: communityUser.contactId];
        
        // create application
        Application__c app = StudFirst_TestHelper.createApplication(conApplicant);
        app.Campus_Location__c = 'Malaysia';
        insert app;
                
		Test.startTest();
        System.runAs(communityUser) {
			Map<String, Object> mapResults = CoursePreferenceCC.getInitData(app.Id);
            String appLocation = (String) mapResults.get(CoursePreferenceCC.FIELD_APPLICATION_CAMPUS_LOCATION);
            System.assertEquals(app.Campus_Location__c, appLocation);
        }
        Test.stopTest();
    }
    
    @isTest
    static void test_getInitDataAus()
    {
        //create a community user
        communityUser = [SELECT Id, ContactId FROM User WHERE username = :myUserName LIMIT 1];
        Contact conApplicant = [Select Id, Residency_Status__c FROM Contact where id =: communityUser.contactId];
        
        // create application
        Application__c app = StudFirst_TestHelper.createApplication(conApplicant);
        app.Campus_Location__c = 'Australia';
        insert app;
                
		Test.startTest();
        System.runAs(communityUser) {
			Map<String, Object> mapResults = CoursePreferenceCC.getInitData(app.Id);
            String appLocation = (String) mapResults.get(CoursePreferenceCC.FIELD_APPLICATION_CAMPUS_LOCATION);
            System.assertEquals(app.Campus_Location__c, appLocation);
        }
        Test.stopTest();
    }
    
    @isTest 
    static void test_getCourseOfferingsAustralianCourseFail()
    {   
        //create a community user
        communityUser = [SELECT Id, ContactId FROM User WHERE username = :myUserName LIMIT 1];
        Contact conApplicant = [Select Id, Residency_Status__c FROM Contact where id =: communityUser.contactId];
                
        // create an Australian course
        Course__c courseRec = StudFirst_TestHelper.createCourse();        
        insert courseRec;

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(courseRec);
        courseOffering.Location_Code__c = 'Australia';
        courseOffering.Citizenship_Type__c = conApplicant.Residency_Status__c;
        insert courseOffering;           
        
		Test.startTest();
			System.runAs(communityUser) {
                String appCampusLocation = 'Malaysia';
                
                Map<String, Object> mapResults = CoursePreferenceCC.getCourseOfferings(courseRec.Title__c,
                                                                      '',
                                                                      '',
                                                                      '',
                                                                      '',
                                                                      20,
                                                                      0,
                                                                      appCampusLocation);

                
				List<Course_Offering__c> courseResults = (List<Course_Offering__c>) mapResults.get(CoursePreferenceCC.FIELD_COURSES);
                System.debug('CoursePreferenceCC_Test::test_getCourseOfferingsAustralianCourseFail:' + courseResults);
                System.assertEquals(0, courseResults.size());
            }
		Test.stopTest();   
    }
    
    @isTest 
    static void test_getCourseOfferingsAustralianCourse()
    {   
        //create a community user
        communityUser = [SELECT Id, ContactId FROM User WHERE username = :myUserName LIMIT 1];
        Contact conApplicant = [Select Id, Residency_Status__c FROM Contact where id =: communityUser.contactId];
                
        // create an Australian course
        Course__c courseRec = StudFirst_TestHelper.createCourse();        
        insert courseRec;

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(courseRec);
        courseOffering.Location_Code__c = 'Australia';
        courseOffering.Citizenship_Type__c = conApplicant.Residency_Status__c;
        insert courseOffering;        
        
		Test.startTest();
        System.runAs(communityUser) {
            String appCampusLocation = 'Australia';
            
            Map<String, Object> mapResults = CoursePreferenceCC.getCourseOfferings(courseRec.Course_Code__c,
                                                                                   '',
                                                                                   '',
                                                                                   '',
                                                                                   '',
                                                                                   20,
                                                                                   0,
                                                                                   appCampusLocation);
            
            
            List<Course_Offering__c> courseResults = (List<Course_Offering__c>) mapResults.get(CoursePreferenceCC.FIELD_COURSES);
            System.debug('CoursePreferenceCC_Test::test_getCourseOfferingsAustralianCourse: query = ' + mapResults.get(CoursePreferenceCC.FIELD_QUERY));
            System.debug('CoursePreferenceCC_Test::test_getCourseOfferingsAustralianCourse:' + courseResults);
            System.assertEquals(1, courseResults.size());
        }
		Test.stopTest();   
    }
    
        @isTest 
    static void test_getCourseOfferingsMalaysianCourse()
    {   
        //create a community user
        communityUser = [SELECT Id, ContactId FROM User WHERE username = :myUserName LIMIT 1];
        Contact conApplicant = [Select Id, Residency_Status__c FROM Contact where id =: communityUser.contactId];
                
        // create an Australian course
        Course__c courseRec = StudFirst_TestHelper.createCourse();        
        insert courseRec;

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(courseRec);
        courseOffering.Location_Code__c = 'Malaysia';
        courseOffering.Citizenship_Type__c = conApplicant.Residency_Status__c;
        insert courseOffering;        
        
		Test.startTest();
        System.runAs(communityUser) {
            String appCampusLocation = 'Malaysia';
            
            Map<String, Object> mapResults = CoursePreferenceCC.getCourseOfferings(courseRec.Course_Code__c,
                                                                                   '',
                                                                                   '',
                                                                                   '',
                                                                                   '',
                                                                                   20,
                                                                                   0,
                                                                                   appCampusLocation);
            
            
            List<Course_Offering__c> courseResults = (List<Course_Offering__c>) mapResults.get(CoursePreferenceCC.FIELD_COURSES);
            System.debug('CoursePreferenceCC_Test::test_getCourseOfferingsMalaysianCourse: query = ' + mapResults.get(CoursePreferenceCC.FIELD_QUERY));
            System.debug('CoursePreferenceCC_Test::test_getCourseOfferingsMalaysianCourse:' + courseResults);
            System.assertEquals(1, courseResults.size());
        }
		Test.stopTest();   
    }
    
            @isTest 
    static void test_getCourseOfferingsSouthAfricaCourse()
    {   
        //create a community user
        communityUser = [SELECT Id, ContactId FROM User WHERE username = :myUserName LIMIT 1];
        Contact conApplicant = [Select Id, Residency_Status__c FROM Contact where id =: communityUser.contactId];
                
        // create an Australian course
        Course__c courseRec = StudFirst_TestHelper.createCourse();        
        insert courseRec;

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(courseRec);
        courseOffering.Location_Code__c = 'SAfrica';
        courseOffering.Citizenship_Type__c = conApplicant.Residency_Status__c;
        insert courseOffering;        
        
		Test.startTest();
        System.runAs(communityUser) {
            String appCampusLocation = 'South Africa';
            
            Map<String, Object> mapResults = CoursePreferenceCC.getCourseOfferings(courseRec.Course_Code__c,
                                                                                   '',
                                                                                   '',
                                                                                   '',
                                                                                   '',
                                                                                   20,
                                                                                   0,
                                                                                   appCampusLocation);
            
            
            List<Course_Offering__c> courseResults = (List<Course_Offering__c>) mapResults.get(CoursePreferenceCC.FIELD_COURSES);
            System.debug('CoursePreferenceCC_Test::test_getCourseOfferingsSouthAfricaCourse: query = ' + mapResults.get(CoursePreferenceCC.FIELD_QUERY));
            System.debug('CoursePreferenceCC_Test::test_getCourseOfferingsSouthAfricaCourse:' + courseResults);
            System.assertEquals(1, courseResults.size());
        }
		Test.stopTest();   
    }
    
    @isTest 
    static void test_SearchCourse() {
        //create a community user
        communityUser = [SELECT Id, ContactId FROM User WHERE username = :myUserName LIMIT 1];
        System.assertNotEquals(null, communityUser.ContactId, 'Contact not found');

        //create required records
        createSampleData(communityUser.ContactId, 'Draft', 'TEST-STATUS', false);

        test.StartTest();
            //only run if there is a Domestic Applicant Profile User
            if (communityUser != null) {
                System.runAs(communityUser) {
                    CoursePreferenceCC coursePref = new CoursePreferenceCC();

                    List<String> attendanceType = CoursePreferenceCC.retrieveAttendanceType();
                    System.assert(!attendanceType.isEmpty());



                    List<String> location = CoursePreferenceCC.retrieveLocation('M00001');
                    System.assert(!location.isEmpty());

                    List<String> commencement = CoursePreferenceCC.retrieveCommencementPeriod('M00001');
                    System.assert(!commencement.isEmpty());

                    List<Course_Offering__c> courses = CoursePreferenceCC.findCourses('M00001', appRecord.Id, 'FULL TIME', 'CLAYTON', 'January-2019', 1, 1);

                    Integer coursesCount = CoursePreferenceCC.retrieveCoursesTotalRecord('M00001', appRecord.Id, 'FULL TIME', 'CLAYTON', 'January-2019');

                    List<Course_Offering__c> coursesWithUnits = CoursePreferenceCC.retrieveCoursesWithUnitSets('M00001', appRecord.Id, 'FULL TIME', 'CLAYTON', 'January-2019');

                    //List<String> strParamA = new List<String>();
                    //strParamA.add(courseOfferingRec.Id);

                    String strParamA = '["'+courseOfferingRecNoUnit.Id+'"]';
                    String strParamB = '["'+courseOfferingRec.Id+'"]';

                    List<Application_Course_Preference__c> insertedAppCourses = CoursePreferenceCC.addCourse(strParamA, strParamA, appRecord.Id);
                
                }
            }
        test.StopTest();
    }
    
    @isTest 
    static void test_ReorderCourse() {    

        //create required records
        communityUser = [SELECT Id, ContactId FROM User WHERE username = :myUserName LIMIT 1];
        createSampleData(communityUser.ContactId, 'Draft', 'TEST-STATUS', true);

        test.StartTest();
            //only run if there is a Domestic Applicant Profile User
            if (communityUser != null) {
                System.runAs(communityUser) {
                    CoursePreferenceCC coursePref = new CoursePreferenceCC();

                    List<Application_Course_Preference__c> reorderCourse = CoursePreferenceCC.reOrderAppCourses(coursePrefA.Id, 'down');
                    String returnValue = CoursePreferenceCC.deleteSelectedCourse(coursePrefB.Id, appRecord.Id);
                }
            }
        test.StopTest();
    }

    static void createSampleData (String contactId, String status, String outcome, Boolean addCourse) {
        communityUser = [SELECT Id, ContactId FROM User WHERE username = :myUserName LIMIT 1];
        //create a new draft application
        appRecord = StudFirst_TestHelper.createApplication(contactId);
        appRecord.OwnerId = communityUser.Id;
        appRecord.Status__c = status;
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
        system.debug('courseOfferingRec' + courseOfferingRec);

        courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec);
        insert courseOfferingRecNoUnit;
        system.debug('courseOfferingRecNoUnit' + courseOfferingRecNoUnit);

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
    
}