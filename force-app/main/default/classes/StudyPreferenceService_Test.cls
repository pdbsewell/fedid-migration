/*******************************************************************************
* @author       Shalini Mendu
* @date
* @description  Test class for StudyPreferenceService
* @revision  12.Aug.2019 - Shalini Mendu - SFTN-148 updates & code comments
* @revision  29 Aug 2024 - Bgreenland - Fix for OES changes - clean up asserts and debugs
*******************************************************************************/
@isTest(isParallel=false)
public class StudyPreferenceService_Test {
    @testSetup static void setup() {
        List<List_of_Values__c> lstOfValues = new List<List_of_Values__c>();
        List_of_Values__c lov1 = new List_of_Values__c();
        lov1.Value__c = 'PENDING';
        lov1.Type__c =    'ADM_DOC_STATUS';
        lov1.System_Code_Description__c = 'DOCUMENTARY EVIDENCE NOT YET ASSESSED';
        lov1.System_Code__c = 'PENDING';
        lstOfValues.add(lov1);
        List_of_Values__c lov2 = new List_of_Values__c();
        lov2.Value__c = 'NOT-APPLIC';
        lov2.Type__c =    '  ADM_OFFER_DFRMNT_STATUS';
        lov2.System_Code_Description__c = 'DEFERRAL OF ADMISSION NOT ALLOWED';
        lov2.System_Code__c = 'NOT-APPLIC';
        lstOfValues.add(lov2);
        List_of_Values__c lov5 = new List_of_Values__c();
        lov5.Value__c = 'NOT-APPLIC';
        lov5.Type__c =    'ADM_OFFER_RESP_STATUS';
        lov5.System_Code_Description__c = 'RESPONSE TO OFFER NOT REQUIRED';
        lov5.System_Code__c = '  NOT-APPLIC';
        lov5.Government_Code__c = '6';
        lov5.Description__c = 'Applicant is not required to respond';
        lstOfValues.add(lov5);
        List_of_Values__c lov6 = new List_of_Values__c();
        lov6.Value__c = 'NOT-APPLIC';
        lov6.Type__c =    'ADM_CNDTNL_OFFER_STATUS';
        lov6.System_Code_Description__c = 'NO CONDITIONS ATTACHED TO OFFER';
        lov6.System_Code__c = 'NOT-APPLIC';
        lstOfValues.add(lov6);
        List_of_Values__c lov3 = new List_of_Values__c();
        lov3.Value__c = 'PENDING';
        lov3.Type__c =    'ADM_ENTRY_QUAL_STATUS';
        lov3.System_Code_Description__c = 'ENTRY QUALIFICATIONS YET TO BE DETERMINED';
        lov3.System_Code__c = 'PENDING';
        lstOfValues.add(lov3);
        List_of_Values__c lov4 = new List_of_Values__c();
        lov4.Value__c = 'AP-PROGRES';
        lov4.Type__c =    'ADM_OUTCOME_STATUS';
        lov4.System_Code_Description__c = 'APPLICATION UNDER CONSIDERATION';
        lov4.System_Code__c = 'AP-PROGRES';
        lstOfValues.add(lov4);
        insert lstOfValues;

        //Create community user
        User testApplicant = StudFirst_TestHelper.createCommunityUser();
    
        Contact testContact = [SELECT Id FROM Contact WHERE Id =: testApplicant.contactId];
        testContact.Person_ID_unique__c = '12345678SA';
        update testContact;

        //Create test Create application
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        testApplication.Type_of_Study__c ='Study Abroad';
        testApplication.Duration_of_Study__c ='1';
        testApplication.Applicant__c = testContact.Id;
        insert testApplication;



        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        testCourse.Start_Date__c =  Date.today();
        insert testCourse;

        //Create test Offering
        Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
        testOffering.Start_Date__c = Date.today();
        insert testOffering;
        //testOffering.Start_Date__c = Date.today();
        Calendar__c c = new Calendar__c(name = '2021-ADM-2', calendar_code__c = '666_666', Start_Date__c = Date.today(), Year__c ='2021', Type__c='ADM-2');
        insert c;
        //Create test ACP
        Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, testContact, testOffering, testCourse);
        testACP.Preference_Number__c = '1';
        testACP.Calendar_Code__c  = c.Id;
        insert testACP;

        Unit_Offering__c aUO = new Unit_Offering__c();
        
        aUO.Academic_Year__c = '2021';
        aUO.Active_Ind__c = true;
        aUO.Location__c = 'Clayton';
        aUO.Unit_Version__c = '1';
        aUO.Unit_Code__c = 'AAA1234';
        aUO.Calendar_Type__c = 'S0-1';
        aUO.Teaching_Period__c = 'S0-1';
        aUO.CI_Sequence_Number__c = '10001';
        aUO.Unit_Class__c = 'ON-CAMPUS';
        aUO.MA_Status__c='green';
        aUO.Start_date__c= Date.today();
        aUO.Unit_Mode__c='ON';
        aUO.Offered_Ind__c=TRUE;
        aUO.Active_Ind__c=TRUE ;
        aUO.SSF_Avail_Ind__c=TRUE;
        aUO.Calendar_Type__c = 'ADM-1';
        aUO.Location__c ='CLAYTON';
        aUO.Unit_Level__c ='1';
        aUO.Start_Date__c = Date.today();
        insert aUO;
        Unit_preference__c up = new Unit_preference__c(  Unit_Offering__c = aUO.Id,Preference_Number__c=1,Semester__c=1,Application_Course_Preference__c = testACP.Id);
        insert up;
        Unit_Offering__c aUO1 = new Unit_Offering__c();
        
        aUO1.Academic_Year__c = '2021';
        aUO1.Active_Ind__c = true;
        aUO1.Location__c = 'Clayton';
        aUO1.Unit_Version__c = '1';
        aUO1.Unit_Code__c = 'UnitABC';
        aUO1.Calendar_Type__c = 'S0-1';
        aUO1.Teaching_Period__c = 'S0-1';
        aUO1.CI_Sequence_Number__c = '10001';
        aUO1.Unit_Class__c = 'ON-CAMPUS';
        aUO1.MA_Status__c='green';
        aUO1.Start_date__c= Date.today();
        aUO1.Unit_Mode__c='COMPOSITE';
        aUO1.Offered_Ind__c=TRUE;
        aUO1.Active_Ind__c=TRUE ;
        aUO1.SSF_Avail_Ind__c=TRUE;
        aUO.Calendar_Type__c = 'ADM-1';
        aUO1.Location__c ='CLAYTON';
        aUO1.Unit_Level__c ='1';
        aUO1.Start_Date__c = Date.today();
        insert aUO1;


        Unit_preference__c up1 = new Unit_preference__c(  Unit_Offering__c = aUO1.Id,Preference_Number__c=1,Semester__c=1,Application_Course_Preference__c = testACP.Id);
        insert up1;
            
        

    }
    
	/*******************************************************************************
	* @author  		Shalini Mendu
	* @date         11.Mar.2021       
	* @description  Tests search of Unit offerings and create/remove/fetch of Unit preferences
                    for Monash Abroad application
	*******************************************************************************/
    @isTest
    public static void test_StudyAbroadExchangeImpl()
    {
        //bypass flows
        Bypass_Mute_Request__c bm = new Bypass_Mute_Request__c();
        bm.Bypass_All_Flows__c = true;
        insert bm;

        Contact con = [SELECT ID FROM CONTACT WHERE Person_ID_unique__c = '12345678SA'];
        User usr = [SELECT ID, name  FROM User WHERE ContactID = :con.Id];

        List<String>excludeid =new List<String>{'123'};
        Id appId = [Select Id from Application__c where Applicant__r.Person_ID_unique__c='12345678SA' limit 1].Id;
        Map<String, Object> addCrsMap = StudyPreferenceService.searchUnitOfferings(0,  appId, 'Study Abroad', null, 1, excludeid);
        Assert.areEqual(addCrsMap.size(),2 ,' It should have 2 items');
        Map<String, Object> picklistmap = StudyPreferenceService.searchUnitOfferingsForPicklist( appId, 'Study Abroad', 1, excludeid);
        Assert.areEqual(picklistmap.size(),2 ,' It should have 2 items');

        unit_offering__c uo = [select id,name from unit_offering__c where Unit_Code__c = 'AAA1234'];
        Map<String,Object> upMap = StudyPreferenceService.createUnitPreference( appId,  uo.Id);
        Assert.areEqual(upMap.size(),5 ,' It should have 5 items');
       System.runAs(usr)
        {
            Map<String,Object> upRemMap = StudyPreferenceService.removeUnitPreference(appId,  uo.Id);
            Assert.areEqual(((List<Unit_Preference__c>)upRemMap.get('UPList')).size(), 1, 'It should have only 1 item');
        }
        Map<String,Object> fetchMap = StudyPreferenceService.fetchUnitPreferences( appId);
        Assert.areEqual(fetchMap.size(),5 ,' It should have 5 items');

        StudyPreferenceService.updateStudyDuration( '2',  appId);
        Assert.areEqual('2', [select Duration_of_Study__c from Application__c where id=:appId].Duration_of_Study__c, 'The number of sems should be 2');
        List<Unit_Preference__c> upList = [SELECT ID,Preference_Number__c,Semester__c from Unit_Preference__c];
        Boolean ret = StudyPreferenceService.sortUPOrder(JSON.serialize(upList));
        Assert.areEqual(true, ret);
    }
    @isTest
    static void test_Pause()
    {
        Test.startTest();
        Map<String, Object> mapResults = StudyPreferenceService.PauseForScroll();

        Assert.areNotEqual(null, mapResults, 'Pause should return an empty map');
        Test.stopTest();
    }

    @isTest
    static void test_getCourseSearchInitLoad()
    {
        //bypass flows
        Bypass_Mute_Request__c bm = new Bypass_Mute_Request__c();
        bm.Bypass_All_Flows__c = true;
        insert bm;
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c application = StudFirst_TestHelper.createApplication(c.Id);
        insert application;

        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offering
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        insert offering;

        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
        insert acp;
		Map<String, Object> mapResults;
        Test.startTest();
        System.runAs(applicant)
        {
            mapResults = StudyPreferenceService.getCourseSearchInitLoad(application.Id);
        }
        Test.stopTest();            
        // application
        Application__c appResult = (Application__c) mapResults.get(StudyPreferenceService.FIELD_APPLICATION);
        Assert.areEqual(application.Id, appResult.Id, 'Application Ids on load should match');
        
        // acps
        List<Application_Course_Preference__c> acps = (List<Application_Course_Preference__c>) mapResults.get(StudyPreferenceService.FIELD_ACPS);
        Assert.areEqual(1, acps.size(), '1 ACP should be created');

        // Application Created By - Profile
        Assert.areEqual(mapResults.get(StudyPreferenceService.FIELD_APPLICATION_CREATEDBY), [SELECT id, createdby.Profile.name FROM Application__c WHERE Id = :application.id LIMIT 1].createdby.Profile.name, 'CreatedBy Profiles should match');        
    }


    @isTest
    static void test_searchCourses()
    {
        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offering
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Course_Title__c = 'Study Abroad - PG';
        offering.Course_Code__c = '7002';
        insert offering;

        String searchString = offering.Course_Title__c;
        String campusLocation = 'Australia';
        String citizenshipType = offering.Citizenship_Type__c;
        String studyType = 'Study Abroad';
        Test.startTest();
        List<Map<String, String>> malaysiaResults = StudyPreferenceService.searchCourses(searchString, 'Malaysia', citizenshipType, studyType);
        Assert.areEqual(0, malaysiaResults.size(), '0 Results should be returned, found '+ malaysiaResults.size());

        List<Map<String, String>> saResults = StudyPreferenceService.searchCourses(searchString, 'South Africa', citizenshipType, studyType);
        Assert.areEqual(0, saResults.size(), '0 Results should be returned, found '+ saResults.size());

        List<Map<String, String>> negativeStudentCourseList = StudyPreferenceService.searchCourses(searchString, campusLocation, citizenshipType, studyType);
        Assert.areEqual(0, negativeStudentCourseList.size(), '0 Result should be returned, found '+ negativeStudentCourseList.size());

        offering.Portal_Available__c = true;
        offering.Default_Admission_Category_Ind__c = true;
        update offering;

        List<Map<String, String>> positiveStudentCourseList = StudyPreferenceService.searchCourses(searchString, campusLocation, citizenshipType, studyType);
        Assert.areEqual(1, positiveStudentCourseList.size(), '1 Result should be returned, found '+ positiveStudentCourseList.size());

        Map<String, String> courseResult = positiveStudentCourseList[0];
        Assert.areEqual(offering.Course_Title__c, courseResult.get(StudyPreferenceService.FIELD_COURSE_TITLE), 'Course returned ' + courseResult);

        Test.stopTest();
    }


    @isTest
    static void test_searchCourseOfferingsByCourseCode()
    {

        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offering
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        insert offering;

        // no unit sets
        Course_Offering__c offeringNoUnitSet = StudFirst_TestHelper.createCourseOfferingNoUnitSet(course);
        insert offeringNoUnitSet;

        offering.Portal_Available__c = true;
        offering.Default_Admission_Category_Ind__c = true;
        update offering;

        offeringNoUnitSet.Portal_Available__c = true;
        offeringNoUnitSet.Default_Admission_Category_Ind__c = true;
        update offeringNoUnitSet;

        List<String> courseCodes = new List<String>();
        courseCodes.add(offering.Course_Code__c);
        courseCodes.add(offeringNoUnitSet.Course_Code__c);
        String campusLocation = 'Australia';
        String citizenshipType = offering.Citizenship_Type__c;

        Test.startTest();

        Map<String, Object> mapResults = StudyPreferenceService.searchCourseOfferingsByCourseCode(courseCodes, campusLocation, citizenshipType);

        List<Map<String, Object>> courseResults = (List<Map<String, Object>>) mapResults.get(StudyPreferenceService.FIELD_OFFERINGS_BY_COURSE_CODE);
        Assert.areEqual(2, courseResults.size(), '2 course sets should be returned, 1 with no unit set');
        Test.stopTest();
    }

    @isTest
    static void test_addACP()
    {
        //bypass flows
        Bypass_Mute_Request__c bm = new Bypass_Mute_Request__c();
        bm.Bypass_All_Flows__c = true;
        insert bm;
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();

        // List<PermissionSetAssignment> lstcurrentUserPerSet =    [   SELECT Id, PermissionSet.Name,AssigneeId
        // FROM PermissionSetAssignment
        // WHERE AssigneeId = :applicant.Id ];
        // for (PermissionSetAssignment psa: lstcurrentUserPerSet) {
        //     system.debug('##psa.PermissionSet.Name' + psa.PermissionSet.Name);
        // }
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c application = StudFirst_TestHelper.createApplication(c.Id);
        insert application;

        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        Course_Offering__c offeringNoUnitSet = StudFirst_TestHelper.createCourseOffering(course);
        List<Course_Offering__c> offeringsToInsert = new List<Course_Offering__c>();
        offeringsToInsert.add(offering);
        offeringsToInsert.add(offeringNoUnitSet);
        insert offeringsToInsert;

        List<Id> offeringIds = new List<Id>();
        offeringIds.add(offering.Id);
        offeringIds.add(offeringNoUnitSet.Id);

        // create ACPs
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
        Application_Course_Preference__c acpNoUnitSet = StudFirst_TestHelper.createCoursePreferences(application, c, offeringNoUnitSet, course);
        List<Application_Course_Preference__c> acpsToInsert = new List<Application_Course_Preference__c>();
        acpsToInsert.add(acp);
        acpsToInsert.add(acpNoUnitSet);
        insert acpsToInsert;

        Test.startTest();
        System.runAs(applicant)
        {
            Map<String, Object> mapResults = StudyPreferenceService.addACPs(offeringIds, application.Id);

            // application
            List<Application_Course_Preference__c> acpsResult = (List<Application_Course_Preference__c>) mapResults.get(StudyPreferenceService.FIELD_ACPS);
            Assert.areEqual(offeringIds.size() + acpsToInsert.size(), acpsResult.size(), 'All ACPS should have been added and returned, got ' + acpsResult.size());

        }
        Test.stopTest();
    }

    static User createDomesticUser()
    {
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

        Account accountRecord = new Account(name ='AccountTest') ;
        insert accountRecord;

        Contact contactRecord = new Contact();
        contactRecord.FirstName = 'First';
        contactRecord.LastName = 'Last';
        contactRecord.AccountId = accountRecord.Id;
        contactRecord.Residency_Status__c = 'DOM-AUS';
        insert contactRecord;

        Integer rnd = Integer.valueOf(Math.random()*9999);
        User userRec = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd) +'testuser@mutesting.edu',
                ContactId = contactRecord.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'INT-TEP',
                Street = '',
                App_Address_Type__c = 'POSTAL');
        insert userRec;

        /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
         * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = userRec.Id);
            insert psa;
        }
        return userRec;
    }

    @isTest
    static void test_addACP_Domestic()
    {
        //bypass flows
        Bypass_Mute_Request__c bm = new Bypass_Mute_Request__c();
        bm.Bypass_All_Flows__c = true;
        insert bm;
        // create community user
        User applicant = createDomesticUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c application = StudFirst_TestHelper.createApplication(c.Id);
        insert application;

        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        Course_Offering__c offering1 = StudFirst_TestHelper.createCourseOffering(course);
        Course_Offering__c offering2 = StudFirst_TestHelper.createCourseOffering(course);
        Course_Offering__c offering3 = StudFirst_TestHelper.createCourseOffering(course);
        List<Course_Offering__c> offerings = new List<Course_Offering__c>();
        offerings.add(offering1);
        offerings.add(offering2);
        offerings.add(offering3);
        insert offerings;

        List<Id> offeringIds = new List<Id>();
        offeringIds.add(offering1.Id);
        offeringIds.add(offering2.Id);
        offeringIds.add(offering3.Id);

        Test.startTest();
        System.runAs(applicant)
        {
            Map<String, Object> mapResults = StudyPreferenceService.addACPs(offeringIds, application.Id);

            // application
            List<Application_Course_Preference__c> acpsResult = (List<Application_Course_Preference__c>) mapResults.get(StudyPreferenceService.FIELD_ACPS);
            Assert.areEqual(offeringIds.size(), acpsResult.size(), 'All ACPS should have been added and returned, got ' + acpsResult.size());


            Application_Course_Preference__c acpRemove = acpsResult[0];
            Map<String, Object> mapRemove = StudyPreferenceService.removeACP(acpRemove.Id, application.Id);
            List<Application_Course_Preference__c> acpsRemove = (List<Application_Course_Preference__c>) mapRemove.get(StudyPreferenceService.FIELD_ACPS);
            Assert.areEqual(acpsResult.size() - 1, acpsRemove.size(), '1 ACP should have been removed, got ' + acpsRemove.size());
        }
        Test.stopTest();



    }

    @isTest
    static void test_reorderACP()
    {
        //bypass flows
        Bypass_Mute_Request__c bm = new Bypass_Mute_Request__c();
        bm.Bypass_All_Flows__c = true;
        insert bm;

        // create community user
        User applicant = createDomesticUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c application = StudFirst_TestHelper.createApplication(c.Id);
        insert application;

        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        Course_Offering__c offering1 = StudFirst_TestHelper.createCourseOffering(course);
        Course_Offering__c offering2 = StudFirst_TestHelper.createCourseOffering(course);
        Course_Offering__c offering3 = StudFirst_TestHelper.createCourseOffering(course);
        List<Course_Offering__c> offerings = new List<Course_Offering__c>();
        offerings.add(offering1);
        offerings.add(offering2);
        offerings.add(offering3);
        insert offerings;

        List<Id> offeringIds = new List<Id>();
        offeringIds.add(offering1.Id);
        offeringIds.add(offering2.Id);
        offeringIds.add(offering3.Id);


        Test.startTest();
        System.runAs(applicant)
        {

            Map<String, Object> mapResults = StudyPreferenceService.addACPs(offeringIds, application.Id);

            // acps created
            List<Application_Course_Preference__c> acpsResult = (List<Application_Course_Preference__c>) mapResults.get(StudyPreferenceService.FIELD_ACPS);
            Assert.areEqual(offeringIds.size(), acpsResult.size(), 'ACP numbers should not have changed, got ' +acpsResult.size());


            // move up
            Application_Course_Preference__c acp2 = acpsResult[1];
            String beforeUpOrder = acp2.Preference_Number__c;
            Map<String, Object> mapUp = StudyPreferenceService.updateACPOrder(acp2.Id, true, application.Id);
            List<Application_Course_Preference__c> upResult = (List<Application_Course_Preference__c>) mapUp.get(StudyPreferenceService.FIELD_ACPS);
            Application_Course_Preference__c acp2AfterUp = upResult[0];
            Assert.areEqual(acp2.Id, acp2AfterUp.Id, 'Item at 1 should now be at 0, ' + acp2AfterUp.Preference_Number__c);

            // move down
            Application_Course_Preference__c acp0 = acpsResult[0];
            String beforeDownOrder = acp0.Preference_Number__c;
            Map<String, Object> mapDown = StudyPreferenceService.updateACPOrder(acp0.Id, false, application.Id);
            List<Application_Course_Preference__c> downResult = (List<Application_Course_Preference__c>) mapDown.get(StudyPreferenceService.FIELD_ACPS);
            Application_Course_Preference__c acp0AfterDown = upResult[1];
            Assert.areEqual(acp0.Id, acp0AfterDown.Id, 'Item at 0 should now be at 1, ' + acp0AfterDown.Preference_Number__c);
        }
        Test.stopTest();
    }

    /*******************************************************************************
	* @author  		Vinothraja
	* @date         22.Apr.2021       
	* @description  Tests search of courses during Coursewokr applications  
                    don't return Study Abroad or Exchange courses
	*******************************************************************************/
    @isTest
    public static void test_searchCoursesForCoursework()
    {
        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Course_Title__c = 'Study Abroad - PG';
        offering.Portal_Available__c=true;
        offering.Default_Admission_Category_Ind__c= true;
        lstCourseOfferings.add(offering);

        offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Portal_Available__c=true;
        offering.Default_Admission_Category_Ind__c= true;
        offering.Course_Title__c = 'Exchange - PG';
        lstCourseOfferings.add(offering);

        offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Portal_Available__c=true;
        offering.Default_Admission_Category_Ind__c= true;
        offering.Course_Title__c = 'Diploma in Arts';
        lstCourseOfferings.add(offering);
        insert lstCourseOfferings;

        String searchString = '';
        String campusLocation = 'Australia';
        String citizenshipType = 'DOM-AUS';
        String studyType = 'Coursework';
        Test.startTest();
            //negative scenarios
            searchString = 'Study';
            List<Map<String, String>> studyAbroadResults = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);
            
            searchString = 'Exchange';
            List<Map<String, String>> exchangeResults = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);

            //positive scenario
            searchString = 'Dip';
            List<Map<String, String>> courseworkResults = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);
        Test.stopTest();
        Assert.areEqual(0, studyAbroadResults.size(), '0 Results should be returned, found '+ studyAbroadResults.size());
        Assert.areEqual(0, exchangeResults.size(), '0 Results should be returned, found '+ exchangeResults.size());
        Assert.areEqual(1, courseworkResults.size(), '1 Result should be returned, found '+ courseworkResults.size());
    }
    
    
    /*******************************************************************************
	* @author  		Davey Yu
	* @date         29-AUG-2024      
	* @description  Tests search for HDR courses during Coursework applications
                    don't return HDR courses
	*******************************************************************************/
    @isTest
    public static void test_searchCoursesForCourseworkWithHDR()
    {
        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;
       
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);

        offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Portal_Available__c=true;
        offering.Default_Admission_Category_Ind__c= true;
        offering.Course_Title__c = 'Diploma in Arts';
        offering.Course_Type_Group__c = 'HDR';
        lstCourseOfferings.add(offering);
        insert lstCourseOfferings;

        String searchString = '';
        String campusLocation = 'Australia';
        String citizenshipType = 'DOM-AUS';
        String studyType = 'Coursework';
        Test.startTest();
            //positive scenario
            searchString = 'Dip';
            List<Map<String, String>> courseworkResultsHDR = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);
        Test.stopTest();
        Assert.areEqual(0, courseworkResultsHDR.size(), '0 Result should be returned, found '+ courseworkResultsHDR.size());
    }

    /*
	 * @author  	    Kristian Vegerano
	 * @date            30.Nov.2021      
	 * @description     Tests that excluded location codes (indonesia) for australian location code isn't available
	 */
    @isTest
    public static void test_searchCoursesForCourseworkAustraliaIndo() {
        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Course_Title__c = 'TestTitle1';
        offering.Portal_Available__c = true;
        offering.Default_Admission_Category_Ind__c = true;
        offering.Location_Code__c = 'INDONESIA';
        lstCourseOfferings.add(offering);
        insert lstCourseOfferings;

        String searchString = '';
        String campusLocation = 'Australia';
        String citizenshipType = 'INTRNTNL';
        String studyType = 'Coursework';
        Test.startTest();
            //negative scenarios
            searchString = 'M00001';
            List<Map<String, String>> results = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);
        Test.stopTest();

        Assert.areEqual(0, results.size(), '0 Results should be returned, found '+ results.size());
    }

    /*
	 * @author  	    Kristian Vegerano
	 * @date            30.Nov.2021      
	 * @description     Tests that excluded location codes (MC-JAKARTA) for australian location code isn't available
	 */
    @isTest
    public static void test_searchCoursesForCourseworkAustraliaMCJakarta() {
        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Course_Title__c = 'TestTitle1';
        offering.Portal_Available__c = true;
        offering.Default_Admission_Category_Ind__c = true;
        offering.Location_Code__c = 'MC-JAKARTA';
        lstCourseOfferings.add(offering);
        insert lstCourseOfferings;

        String searchString = '';
        String campusLocation = 'Australia';
        String citizenshipType = 'INTRNTNL';
        String studyType = 'Coursework';
        Test.startTest();
            //negative scenarios
            searchString = 'M00001';
            List<Map<String, String>> results = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);
        Test.stopTest();

        Assert.areEqual(0, results.size(), '0 Results should be returned, found '+ results.size());
    }

    /*
	 * @author  	    Kristian Vegerano
	 * @date            30.Nov.2021      
	 * @description     Tests that excluded location codes (ONLINE) for australian location code isn't available
	 */
    @isTest
    public static void test_searchCoursesForCourseworkAustraliaOnline() {
        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Course_Title__c = 'TestTitle1';
        offering.Portal_Available__c = true;
        offering.Default_Admission_Category_Ind__c = true;
        offering.Location_Code__c = 'ONLINE';
        lstCourseOfferings.add(offering);
        insert lstCourseOfferings;

        String searchString = '';
        String campusLocation = 'Australia';
        String citizenshipType = 'INTRNTNL';
        String studyType = 'Coursework';
        Test.startTest();
            //negative scenarios
            searchString = 'M00001';
            List<Map<String, String>> results = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);
        Test.stopTest();

        Assert.areEqual(0, results.size(), '0 Results should be returned, found '+ results.size());
    }

    /*
	 * @author  	    Kristian Vegerano
	 * @date            30.Nov.2021      
	 * @description     Tests that excluded location codes (PRATO) for australian location code isn't available
	 */
    @isTest
    public static void test_searchCoursesForCourseworkAustraliaPrato() {
        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Course_Title__c = 'TestTitle1';
        offering.Portal_Available__c = true;
        offering.Default_Admission_Category_Ind__c = true;
        offering.Location_Code__c = 'PRATO';
        lstCourseOfferings.add(offering);
        insert lstCourseOfferings;

        String searchString = '';
        String campusLocation = 'Australia';
        String citizenshipType = 'INTRNTNL';
        String studyType = 'Coursework';
        Test.startTest();
            //negative scenarios
            searchString = 'M00001';
            List<Map<String, String>> results = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);
        Test.stopTest();

        Assert.areEqual(0, results.size(), '0 Results should be returned, found '+ results.size());
    }

    /*
	 * @author  	    Kristian Vegerano
	 * @date            30.Nov.2021      
	 * @description     Tests that excluded location codes (OS-SGP) for australian location code isn't available
	 */
    @isTest
    public static void test_searchCoursesForCourseworkAustraliaOSSGP() {
        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Course_Title__c = 'TestTitle1';
        offering.Portal_Available__c = true;
        offering.Default_Admission_Category_Ind__c = true;
        offering.Location_Code__c = 'OS-SGP';
        lstCourseOfferings.add(offering);
        insert lstCourseOfferings;

        String searchString = '';
        String campusLocation = 'Australia';
        String citizenshipType = 'INTRNTNL';
        String studyType = 'Coursework';
        Test.startTest();
            //negative scenarios
            searchString = 'M00001';
            List<Map<String, String>> results = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);
        Test.stopTest();

        Assert.areEqual(0, results.size(), '0 Results should be returned, found '+ results.size());
    }

    /*
	 * @author  	    Kristian Vegerano
	 * @date            30.Nov.2021      
	 * @description     Tests that excluded location codes (MUFY-SUN) for australian location code isn't available
	 */
    @isTest
    public static void test_searchCoursesForCourseworkAustraliaMUFYSUN() {
        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Course_Title__c = 'TestTitle1';
        offering.Portal_Available__c = true;
        offering.Default_Admission_Category_Ind__c = true;
        offering.Location_Code__c = 'MUFY-SUN';
        lstCourseOfferings.add(offering);
        insert lstCourseOfferings;

        String searchString = '';
        String campusLocation = 'Australia';
        String citizenshipType = 'INTRNTNL';
        String studyType = 'Coursework';
        Test.startTest();
            //negative scenarios
            searchString = 'M00001';
            List<Map<String, String>> results = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);
        Test.stopTest();

        Assert.areEqual(0, results.size(), '0 Results should be returned, found '+ results.size());
    }
    
    /*
	 * @author  	    Kristian Vegerano
	 * @date            21.Apr.2022    
	 * @description     Tests that excluded location codes (ONLINE-A) for australian location code isn't available
	 */
    @isTest
    public static void test_searchCoursesForCourseworkAustraliaOnlineA() {
        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offerings
        List<Course_Offering__c> lstCourseOfferings = new List<Course_Offering__c>();
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Course_Title__c = 'TestTitle1';
        offering.Portal_Available__c = true;
        offering.Default_Admission_Category_Ind__c = true;
        offering.Location_Code__c = 'ONLINE-A';
        lstCourseOfferings.add(offering);
        insert lstCourseOfferings;

        String searchString = '';
        String campusLocation = 'Australia';
        String citizenshipType = 'INTRNTNL';
        String studyType = 'Coursework';
        Test.startTest();
            //negative scenarios
            searchString = 'M00001';
            List<Map<String, String>> results = StudyPreferenceService.searchCourses(searchString, 'Australia', citizenshipType, studyType);
        Test.stopTest();

        Assert.areEqual(0, results.size(), '0 Results should be returned, found '+ results.size());
    }
}