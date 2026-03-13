/*******************************************************************************
* @author       Davey Yu
* @date
* @description  Test class for StudyPreferenceServiceGR
* @revision  23.Sep.2024 - Davey Yu - MGRO-281 - Application Details 
*******************************************************************************/
@isTest(isParallel=false)//Due APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on the user object
public class StudyPreferenceServiceGR_Test {
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
	    testApplication.Graduate_Research_Application_Type__c = 'Admission and Scholarship';
        insert testApplication;
        
        //create faculties
        Account faculty = new Account();
        RecordType facultyRec = [Select id From RecordType where SObjectType = 'Account' and Name='Faculty'];
        faculty.name = 'Faculty of Arts Test';
        faculty.RecordTypeId = facultyRec.id;
        faculty.Graduate_Research_Available_Country__c = 'RSRCH-AUST';
        insert faculty;        
        
        //create faculties
        Account academicUnit = new Account();
        RecordType monashOrgRec = [Select id From RecordType where SObjectType = 'Account' and Name='Monash Organisation'];
        academicUnit.name = 'School of Sciences';
        academicUnit.ParentId = faculty.id;
        academicUnit.RecordTypeId = monashOrgRec.id;
        academicUnit.Graduate_Research_Available_Country__c = 'RSRCH-AUST_AOU';
        insert academicUnit;
        
        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        testCourse.Start_Date__c =  Date.today();
        testCourse.Faculty__c = faculty.id;
        testCourse.Level__c = 'HDR';
        insert testCourse;
        
         //create calendar
        Date dateToday = Date.Today();
        Calendar__c cal = new Calendar__c();
        cal.Name= 'ADM_2025_ADM-RES1';
        cal.Calendar_Code__c = '12005_12236';
        cal.Category__c = 'Admission';
        cal.Description__c = String.valueOf(dateToday.year())+' 2025 ADMISSION PERIOD FOR FIRST RESEARCH TEACHING PERIOD';
        cal.Status__c = 'Active';
        cal.Year__c = String.valueOf(Date.Today().addYears(1).year());
        cal.Start_Date__c = Date.Today();
        cal.End_Date__c = Date.Today().addYears(1);
        cal.Type__c = 'ADM-RES1';
        insert cal;
        
        
        //Create test Offering
        Course_Offering__c testOffering = new Course_Offering__c();
        testOffering.Course__c = testCourse.Id;
        testOffering.Academic_CI_Sequence_Number__c = 1;
        testOffering.Academic_Calendar_Type__c = '2019';
        testOffering.Admission_CI_Sequence_Number__c = 1;
        testOffering.Admission_Calendar_Type__c = 'ADM';
        testOffering.Attendance_Mode__c = 'SCG';
        testOffering.Attendance_Type__c = 'PT';
        testOffering.Course_Code__c =  'MM00000';
        testOffering.Course_Title__c = 'Master Of Something';
        testOffering.Course_Version_Number__c = 1;
        testOffering.Admission_Calendar_Description__c = 'July-2019';
        testOffering.Attendance_Mode_Description__c = 'On Campus';
        testOffering.Attendance_Type_Description__c = 'FULL TIME';
        testOffering.Citizenship_Type__c = 'DOM-AUS';
        testOffering.Location_Code__c = 'CLAYTON';
        testOffering.Type_of_Place_Description__c = 'Test type of place';
        testOffering.Type_of_Place_Code__c = 'PC001';
        testOffering.Unit_Set_Code__c =  'MM00000';
        testOffering.Unit_Set_Description__c = 'set description';
        testOffering.Active__c = true;
        testOffering.Mix_Unique_Id__c = AgentPortalTestDataFactory.util.generateRandomString(10);
        testOffering.Start_Date__c = Date.today();
        testOffering.Default_Admission_Category_Ind__c = true;
        testOffering.Portal_Available__c = true;
        testOffering.Course_Type_Group__c = 'HDR';
        testOffering.Calendar__c = cal.id;
        insert testOffering;
       
        //Create test ACP
        
        Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, testContact, testOffering, testCourse);
        testACP.Preference_Number__c = '1';
        testACP.Calendar_Code__c  = cal.Id;
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
        
       
        
        //create calendar dates
        //Domestic for addmission and scholarship
        List<Calendar_Dates__c> calDateList = new List<Calendar_Dates__c>();
        Calendar_Dates__c calDateDomesticOpenning = new Calendar_Dates__c();
        calDateDomesticOpenning.Name = 'HDR-SCH-OP';
        calDateDomesticOpenning.Date_Value__c = Date.Today().addDays(-2);
        calDateDomesticOpenning.Date_Sequence_Nbr__c= 1;
        calDateDomesticOpenning.Date_Type_Description__c = 'OPENING DATE OF A HDR SCHOLARSHIP ROUND FOR DOMESTIC';
        calDateDomesticOpenning.CalendarId__c = cal.id;
        calDateList.add(calDateDomesticOpenning);
        
        Calendar_Dates__c calDateDomesticClosing = new Calendar_Dates__c();
        calDateDomesticClosing.Name = 'HDR-SCH-CL';
        calDateDomesticClosing.Date_Value__c = Date.Today().addMonths(4);
        calDateDomesticClosing.Date_Sequence_Nbr__c= 1;
        calDateDomesticClosing.Date_Type_Description__c = 'CLOSING DATE OF A HDR SCHOLARSHIP ROUND FOR DOMESTIC';
        calDateDomesticClosing.CalendarId__c = cal.id;
        calDateList.add(calDateDomesticClosing);
        
         Calendar_Dates__c earliestPossibleCommDate = new Calendar_Dates__c();
        earliestPossibleCommDate.Name = 'HDR-CCM-EP';
        earliestPossibleCommDate.Date_Value__c = Date.Today().addMonths(-1);
        earliestPossibleCommDate.Date_Sequence_Nbr__c= 1;
        earliestPossibleCommDate.Date_Type_Description__c = 'EARLIEST POSSIBLE HDR CAND. COMMENCE DT WITH SCHOLARSHIP';
        earliestPossibleCommDate.CalendarId__c = cal.id;
        calDateList.add(earliestPossibleCommDate);
        
        Calendar_Dates__c calAdScholEarliest = new Calendar_Dates__c();
        calAdScholEarliest.Name = 'HDR-SCM-ET';
        calAdScholEarliest.Date_Value__c = Date.Today().addYears(1);
        calAdScholEarliest.Date_Sequence_Nbr__c= 1;
        calAdScholEarliest.Date_Type_Description__c = 'EARLIEST HDR CANDIDATURE COMMENCEMENT DATE WITH SCHOLARSHIP';
        calAdScholEarliest.CalendarId__c = cal.id;
        calDateList.add(calAdScholEarliest);
        
        Calendar_Dates__c calAdScholLatest = new Calendar_Dates__c();
        calAdScholLatest.Name = 'HDR-SCM-LT';
        calAdScholLatest.Date_Value__c = Date.Today().addYears(1).addMonths(6);
        calAdScholLatest.Date_Sequence_Nbr__c= 1;
        calAdScholLatest.Date_Type_Description__c = 'LATEST HDR CANDIDATURE COMMENCEMENT DATE WITH SCHOLARSHIP';
        calAdScholLatest.CalendarId__c = cal.id;
        calDateList.add(calAdScholLatest);
        
      
        Calendar_Dates__c calAdEarliest = new Calendar_Dates__c();
        calAdEarliest.Name = 'HDR-CCM-ET';
        calAdEarliest.Date_Value__c = Date.Today().addYears(1);
        calAdEarliest.Date_Sequence_Nbr__c= 1;
        calAdEarliest.Date_Type_Description__c = 'EARLEST HDR CANDIDATURE COMMENCEMENT DATE FOR CAND ONLY';
        calAdEarliest.CalendarId__c = cal.id;
        calDateList.add(calAdEarliest);
        
        
        Calendar_Dates__c calCandidatureEearliest = new Calendar_Dates__c();
        calCandidatureEearliest.Name = 'HDR-CCM-LT';
        calCandidatureEearliest.Date_Value__c = Date.Today().addYears(1).addMonths(6);
        calCandidatureEearliest.Date_Sequence_Nbr__c= 1;
        calCandidatureEearliest.Date_Type_Description__c = 'Latest HDR CANDIDATURE COMMENCEMENT DATE FOR CAND ONLY';
        calCandidatureEearliest.CalendarId__c = cal.id;
        calDateList.add(calCandidatureEearliest);
        
       
	
                
        insert calDateList; 
        
       
        
    }
    
        
    /**
     * @author      Davey Yu
     * @description Test submitting an application course preference for Graduate Research
     * @revision    03-OCT-2024 - Davey Yu - Created
     * 
     * GIVEN a new student is registered for my.app
     * WHEN student applied for admission only application
     * THEN should successfully create an application course preference
     *
     */
    @isTest
    static void test_getCandidatureCalendar()
    {
        //bypass flows
        Bypass_Mute_Request__c bm = new Bypass_Mute_Request__c();
        bm.Bypass_All_Flows__c = true;
        insert bm;
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        
        Test.startTest();
        
        
        System.runAs(applicant)
        {
            Id calId = StudyPreferenceServiceGR.getCalendarIdCandidature('DOM-AUS', Date.Today().addYears(1).addMonths(1));
            Assert.isNotNull(calId, 'Calendar Id not null');
        }
        Test.stopTest();    
        
    }
    
    /**
     * @author      Davey Yu
     * @description Test submitting an application course preference for Graduate Research
     * @revision    02-DEC-2024 - Davey Yu - Created
     * 
     * GIVEN a new student is registered for my.app
     * WHEN student applied for admission and scholarship only application outside of the scholarship rounds
     * THEN should successfully query the calendar based on the proposed commencement date
     *
     */
    @isTest
    static void test_searchHDRCourseBasedOnProposedDate()
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
        application.Type_of_Study__c = 'Graduate Research';
        application.Graduate_Research_Application_Type__c = 'Admission and Scholarship';
        insert application;
       	
        Id calId = null;
	

        Test.startTest();
        
        
        System.runAs(applicant)
        {
            Date proposedDate = Date.today().addYears(1).addMonths(1);
           	calId = StudyPreferenceServiceGR.getCalendarIdBasedOnCommencementDate(proposedDate);
            Assert.isNotNull(calId, 'Calendar id from scholarship rounds not null');
        }
        Test.stopTest();    
    }
    
    /**
     * @author      Davey Yu
     * @description Test submitting an application course preference for Graduate Research
     * @revision    03-OCT-2024 - Davey Yu - Created
     * 
     * GIVEN a new student is registered for my.app
     * WHEN student applied for admission and scholarship only application
     * THEN should successfully create an application course preference
     *
     */
    @isTest
    static void test_searchHDRCourseAdmissionScholarship()
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
        application.Type_of_Study__c = 'Graduate Research';
        application.Graduate_Research_Application_Type__c = 'Admission application only';
        insert application;

   
       	
        List<Map<String, String>> calendarIdResults;  
		List<Map<String, String>> facultyResults;  
       	List<Map<String, String>> academicUnitResults;  
        List<Map<String, String>> courseResults;  
        List<Map<String, String>> campusResults;  
        List<Map<String, String>> attendanceModeResults;  
        List<Map<String, String>> attendanceTypeResults; 
        Map<String, Object> addGRTACPResults;

      
        Test.startTest();
        
        
        System.runAs(applicant)
        {
           	calendarIdResults = StudyPreferenceServiceGR.getScholarshipRoundsValues('DOM-AUS', true, false);
            Map<String, String> calResult = calendarIdResults[0];
            String calResults = calResult.get('value');
            Assert.isNotNull(calResults, 'Calendar id from scholarship rounds not null');
            if(calResults != null){
                String calId = '';
                List<String> cals = calResults.split('=');
                calId = cals[0];
                
                
                facultyResults = StudyPreferenceServiceGR.getFacultyValues('Australia');
                Map<String, String> facultyResult = facultyResults[0];
                String facultyId = facultyResult.get('value');
                Assert.isNotNull(facultyId, 'Faculty id not null');
    
                academicUnitResults = StudyPreferenceServiceGR.getAcademicUnitValues(facultyId, 'Australia');
                Map<String, String> academicUnitResult = academicUnitResults[0];
                String academicUnit = academicUnitResult.get('value');
                Assert.isNotNull(academicUnit, 'Academic unit selected');
    
                courseResults = StudyPreferenceServiceGR.getHDRCourses(facultyId, calId, 'DOM-AUS', 'Australia');
                Map<String, String> courseResult = courseResults[0];
                String courseOffering = courseResult.get('value');
                Assert.isNotNull(courseOffering, 'Course record retrieved');
                
                campusResults = StudyPreferenceServiceGR.getCampusLocations(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'Australia');
                Map<String, String> campusResult = campusResults[0];
                String campus = campusResult.get('value');
                Assert.isNotNull(campus, 'Course record based on selected courses');
                
                attendanceModeResults = StudyPreferenceServiceGR.getAttendanceTypes(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'CLAYTON');
                Map<String, String> attendanceModeResult = attendanceModeResults[0];
                String attendanceMode = attendanceModeResult.get('value');
                Assert.isNotNull(attendanceMode, 'Attendace mode based on selected courses and campus');
    
                attendanceTypeResults = StudyPreferenceServiceGR.getAttendanceModes(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'CLAYTON', attendanceMode);
                Map<String, String> attendanceTypeResult = attendanceTypeResults[0];
                String attendanceType = attendanceTypeResult.get('value');
                Assert.isNotNull(attendanceType, 'Attendace type based on selected courses, campus and attendance mode');
    
                //add application
                addGRTACPResults =  StudyPreferenceServiceGR.addGRTACPs(null, application.id, calId, calId, Date.Today(), academicUnit, 
                                                                        'Test', true, true, Date.today(),
                                                                        'Test', 'MM00000=Master Of Something', 'CLAYTON', attendanceType, attendanceMode, facultyId, 'DOM-AUS', 'Test', true,  null, true, true, true, '');
               
                List<Application_Course_Preference__c> acpsResult = (List<Application_Course_Preference__c>) addGRTACPResults.get('acps');
            	Assert.isNotNull(acpsResult, 'Application Course Preference Added');
                
                //submit application
                application.status__c = 'Submitted';
                update application;
                
                //scholarship only application
                Application__c scholarshipApp = StudFirst_TestHelper.createApplication(c.Id);
                scholarshipApp.Type_of_Study__c = 'Graduate Research';
                scholarshipApp.Graduate_Research_Application_Type__c = 'Scholarship application only';
                scholarshipApp.Parent_Application__c =  application.id;
                insert scholarshipApp;
                
                Application_Course_Preference__c acp = [Select id, Course__c, Application__r.Parent_Application__c, Course_Offering__r.Course__c, Course_Offering__r.Course_Type_Group__c FROM Application_Course_Preference__c where Id =: acpsResult[0].id];
                
				
                // Course Attempt
                List<Course_Attempt__c> lstCourseAttempts = new List<Course_Attempt__c>();
                lstCourseAttempts = TestHelper.createCourseAttempts(1, c.Id, acp.Course_Offering__r.Course__c);
                lstCourseAttempts.get(0).Course_Attempt_Status__c = 'Enrolled';                
                lstCourseAttempts.get(0).Application_Course_Preference__c = acp.id;
                lstCourseAttempts.get(0).Campus_Country__c = 'AUSTRALIA';
                insert lstCourseAttempts;
                
                
                List<Map<String, Object>> courseAttempt = StudyPreferenceServiceGR.getCourseAttempts(c.id);
                Map<String, Object> courseAttemptDetail = StudyPreferenceServiceGR.getCourseAttemptsDetails(String.valueOf(courseAttempt[0].get('value')));
                Course_Attempt__c attempt = (Course_Attempt__c)courseAttemptDetail.get('CourseAttempts');
				
                //add application course preference
                Map<String, Object> addGRTACPResultsSch =  StudyPreferenceServiceGR.addGRTACPs(null, scholarshipApp.id, calId, calId, Date.Today(), academicUnit, 
                                                                        'Test', true, true, Date.today(),
                                                                        'Test', 'MM00000=Master Of Something', 'CLAYTON', attempt.Application_Course_Preference__r.Attendance_Type__c, attempt.Application_Course_Preference__r.Attendance_Mode__c, 
                                                                         attempt.Application_Course_Preference__r.Course_Offering__r.Faculty__c, 'DOM-AUS', 'Test', true,  scholarshipApp.Parent_Application__c, true, true, true, '');
                
                
                
                List<Application_Course_Preference__c> acpsResultSch = (List<Application_Course_Preference__c>) addGRTACPResultsSch.get('acps');
            	Assert.isNotNull(acpsResultSch, 'Application Course Preference Added For Scholarship Only Application');                
               
            }
        }
        Test.stopTest();    
    }

    /**
     * @author      Vishal Gupta
     * @description Test submitted duplicate scholarship application
     * 
     * GIVEN a new student is registered for my.app
     * WHEN student applied for admission application and they tried to appy again for same calendar
     * THEN should system should throw an error
     *
     */
    @isTest
    static void test_duplicateGRScholarship()
    {
        //bypass flows
        Bypass_Mute_Request__c bm = new Bypass_Mute_Request__c();
        bm.Bypass_All_Flows__c = true;
        insert bm;
        // GIVEN: a new student is registered for my.app
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        
        //WHEN: student applied for admission application
        Application__c application = StudFirst_TestHelper.createApplication(c.Id);
        application.Type_of_Study__c = 'Graduate Research';
        application.Graduate_Research_Application_Type__c = 'Admission and Scholarship';
        insert application;

        List<Map<String, String>> calendarIdResults;  
		List<Map<String, String>> facultyResults;  
       	List<Map<String, String>> academicUnitResults;  
        List<Map<String, String>> courseResults;  
        List<Map<String, String>> campusResults;  
        List<Map<String, String>> attendanceModeResults;  
        List<Map<String, String>> attendanceTypeResults; 
        Map<String, Object> addGRTACPResults;
      
        Test.startTest();
        
        System.runAs(applicant)
        {
           	calendarIdResults = StudyPreferenceServiceGR.getScholarshipRoundsValues('DOM-AUS', true, false);
            Map<String, String> calResult = calendarIdResults[0];
            String calResults = calResult.get('value');
            Assert.isNotNull(calResults, 'Calendar id from scholarship rounds not null');
            if(calResults != null){
                String calId = '';
                List<String> cals = calResults.split('=');
                calId = cals[0];
                
                facultyResults = StudyPreferenceServiceGR.getFacultyValues('Australia');
                Map<String, String> facultyResult = facultyResults[0];
                String facultyId = facultyResult.get('value');
                Assert.isNotNull(facultyId, 'Faculty id not null');
    
                academicUnitResults = StudyPreferenceServiceGR.getAcademicUnitValues(facultyId, 'Australia');
                Map<String, String> academicUnitResult = academicUnitResults[0];
                String academicUnit = academicUnitResult.get('value');
                Assert.isNotNull(academicUnit, 'Academic unit selected');
    
                courseResults = StudyPreferenceServiceGR.getHDRCourses(facultyId, calId, 'DOM-AUS', 'Australia');
                Map<String, String> courseResult = courseResults[0];
                String courseOffering = courseResult.get('value');
                Assert.isNotNull(courseOffering, 'Course record retrieved');
                
                campusResults = StudyPreferenceServiceGR.getCampusLocations(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'Australia');
                Map<String, String> campusResult = campusResults[0];
                String campus = campusResult.get('value');
                Assert.isNotNull(campus, 'Course record based on selected courses');
                
                attendanceModeResults = StudyPreferenceServiceGR.getAttendanceTypes(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'CLAYTON');
                Map<String, String> attendanceModeResult = attendanceModeResults[0];
                String attendanceMode = attendanceModeResult.get('value');
                Assert.isNotNull(attendanceMode, 'Attendace mode based on selected courses and campus');
    
                attendanceTypeResults = StudyPreferenceServiceGR.getAttendanceModes(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'CLAYTON', attendanceMode);
                Map<String, String> attendanceTypeResult = attendanceTypeResults[0];
                String attendanceType = attendanceTypeResult.get('value');
                Assert.isNotNull(attendanceType, 'Attendace type based on selected courses, campus and attendance mode');
    
                //add application
                addGRTACPResults =  StudyPreferenceServiceGR.addGRTACPs(null, application.id, calId, calId, Date.Today(), academicUnit, 
                                                                        'Test', true, true, Date.today(),
                                                                        'Test', 'MM00000=Master Of Something', 'CLAYTON', attendanceType, attendanceMode, facultyId, 'DOM-AUS', 'Test', true,  null, true, true, true, '');
               
                List<Application_Course_Preference__c> acpsResult = (List<Application_Course_Preference__c>) addGRTACPResults.get('acps');
            	Assert.isNotNull(acpsResult, 'Application Course Preference Added');
                
                //submit application
                application.status__c = 'Submitted';
                update application;
                
                //scholarship only application
                Application__c scholarshipApp = StudFirst_TestHelper.createApplication(c.Id);
                scholarshipApp.Type_of_Study__c = 'Graduate Research';
                scholarshipApp.Graduate_Research_Application_Type__c = 'Scholarship application only';
                scholarshipApp.Parent_Application__c =  application.id;
                insert scholarshipApp;
                
                Application_Course_Preference__c acp = [Select id, Course__c, Application__r.Parent_Application__c, Course_Offering__r.Course__c, Course_Offering__r.Course_Type_Group__c FROM Application_Course_Preference__c where Id =: acpsResult[0].id];
                
				
                // Course Attempt
                List<Course_Attempt__c> lstCourseAttempts = new List<Course_Attempt__c>();
                lstCourseAttempts = TestHelper.createCourseAttempts(1, c.Id, acp.Course_Offering__r.Course__c);
                lstCourseAttempts.get(0).Course_Attempt_Status__c = 'Enrolled';
                lstCourseAttempts.get(0).Application_Course_Preference__c = acp.id;
                lstCourseAttempts.get(0).Campus_Country__c = 'AUSTRALIA';
                insert lstCourseAttempts;
                
                
                List<Map<String, Object>> courseAttempt = StudyPreferenceServiceGR.getCourseAttempts(c.id);
                Map<String, Object> courseAttemptDetail = StudyPreferenceServiceGR.getCourseAttemptsDetails(String.valueOf(courseAttempt[0].get('value')));
                Course_Attempt__c attempt = (Course_Attempt__c)courseAttemptDetail.get('CourseAttempts');
				
                //and they tried to apply again for same calendar
                Map<String, Object> addGRTACPResultsSch =  StudyPreferenceServiceGR.addGRTACPs(null, scholarshipApp.id, calId, calId, Date.Today(), academicUnit, 
                                                                        'Test', true, true, Date.today(),
                                                                        'Test', 'MM00000=Master Of Something', 'CLAYTON', attempt.Application_Course_Preference__r.Attendance_Type__c, attempt.Application_Course_Preference__r.Attendance_Mode__c, 
                                                                         attempt.Application_Course_Preference__r.Course_Offering__r.Faculty__c, 'DOM-AUS', 'Test', true,  scholarshipApp.Parent_Application__c, true, true, true, '');
                
                String duplicateError = (String) addGRTACPResultsSch.get('error');             
                //Then: system should not allow them to add ACP
                Assert.areEqual(duplicateError, 'duplicate', 'duplicate application found');
            }
        }
        Test.stopTest();    
    }

    /**
     * @author      Vishal Gupta
     * @description Test submitted duplicate Admission with Scholarship
     * 
     * GIVEN a new student is registered for my.app
     * WHEN student applied for admission application and they tried to appy again for same calendar
     * THEN should system should throw an error
     *
     */
    @isTest
    static void test_duplicateApplicationScholarship()
    {
        //bypass flows
        Bypass_Mute_Request__c bm = new Bypass_Mute_Request__c();
        bm.Bypass_All_Flows__c = true;
        insert bm;
        // GIVEN: a new student is registered for my.app
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        
        // WHEN: student applied for Admission and Scholarship application
        Application__c application = StudFirst_TestHelper.createApplication(c.Id);
        application.Type_of_Study__c = 'Graduate Research';
        application.Graduate_Research_Application_Type__c = 'Admission and Scholarship';
        insert application;
       	
        List<Map<String, String>> calendarIdResults;  
		List<Map<String, String>> facultyResults;  
       	List<Map<String, String>> academicUnitResults;  
        List<Map<String, String>> courseResults;  
        List<Map<String, String>> campusResults;  
        List<Map<String, String>> attendanceModeResults;  
        List<Map<String, String>> attendanceTypeResults; 
        Map<String, Object> addGRTACPResults;
      
        Test.startTest();        
        
        System.runAs(applicant)
        {
           	calendarIdResults = StudyPreferenceServiceGR.getScholarshipRoundsValues('DOM-AUS', true, false);
            Map<String, String> calResult = calendarIdResults[0];
            String calResults = calResult.get('value');
            Assert.isNotNull(calResults, 'Calendar id from scholarship rounds not null');
            if(calResults != null){
                String calId = '';
                List<String> cals = calResults.split('=');
                calId = cals[0];
                
                
                facultyResults = StudyPreferenceServiceGR.getFacultyValues('Australia');
                Map<String, String> facultyResult = facultyResults[0];
                String facultyId = facultyResult.get('value');
                Assert.isNotNull(facultyId, 'Faculty id not null');
    
                academicUnitResults = StudyPreferenceServiceGR.getAcademicUnitValues(facultyId, 'Australia');
                Map<String, String> academicUnitResult = academicUnitResults[0];
                String academicUnit = academicUnitResult.get('value');
                Assert.isNotNull(academicUnit, 'Academic unit selected');
    
                courseResults = StudyPreferenceServiceGR.getHDRCourses(facultyId, calId, 'DOM-AUS', 'Australia');
                Map<String, String> courseResult = courseResults[0];
                String courseOffering = courseResult.get('value');
                Assert.isNotNull(courseOffering, 'Course record retrieved');
                
                campusResults = StudyPreferenceServiceGR.getCampusLocations(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'Australia');
                Map<String, String> campusResult = campusResults[0];
                String campus = campusResult.get('value');
                Assert.isNotNull(campus, 'Course record based on selected courses');
                
                attendanceModeResults = StudyPreferenceServiceGR.getAttendanceTypes(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'CLAYTON');
                Map<String, String> attendanceModeResult = attendanceModeResults[0];
                String attendanceMode = attendanceModeResult.get('value');
                Assert.isNotNull(attendanceMode, 'Attendace mode based on selected courses and campus');
    
                attendanceTypeResults = StudyPreferenceServiceGR.getAttendanceModes(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'CLAYTON', attendanceMode);
                Map<String, String> attendanceTypeResult = attendanceTypeResults[0];
                String attendanceType = attendanceTypeResult.get('value');
                Assert.isNotNull(attendanceType, 'Attendace type based on selected courses, campus and attendance mode');
    
                //add application
                addGRTACPResults =  StudyPreferenceServiceGR.addGRTACPs(null, application.id, calId, calId, Date.Today(), academicUnit, 
                                                                        'Test', true, true, Date.today(),
                                                                        'Test', 'MM00000=Master Of Something', 'CLAYTON', attendanceType, attendanceMode, facultyId, 'DOM-AUS', 'Test', true,  null, true, true, true, '');
               
                List<Application_Course_Preference__c> acpsResult = (List<Application_Course_Preference__c>) addGRTACPResults.get('acps');
            	Assert.isNotNull(acpsResult, 'Application Course Preference Added');
                
                //submit application
                application.status__c = 'Submitted';
                update application;
                
                //scholarship only application
                Application__c scholarshipApp = StudFirst_TestHelper.createApplication(c.Id);
                scholarshipApp.Type_of_Study__c = 'Graduate Research';
                scholarshipApp.Graduate_Research_Application_Type__c = 'Admission and Scholarship';
                scholarshipApp.Parent_Application__c =  application.id;
                insert scholarshipApp;
                
                Application_Course_Preference__c acp = [Select id, Course__c, Application__r.Parent_Application__c, Course_Offering__r.Course__c, Course_Offering__r.Course_Type_Group__c FROM Application_Course_Preference__c where Id =: acpsResult[0].id];
                
				
                // Course Attempt
                List<Course_Attempt__c> lstCourseAttempts = new List<Course_Attempt__c>();
                lstCourseAttempts = TestHelper.createCourseAttempts(1, c.Id, acp.Course_Offering__r.Course__c);
                lstCourseAttempts.get(0).Course_Attempt_Status__c = 'Enrolled';
                lstCourseAttempts.get(0).Application_Course_Preference__c = acp.id;
                lstCourseAttempts.get(0).Campus_Country__c = 'AUSTRALIA';
                insert lstCourseAttempts;
                
                
                List<Map<String, Object>> courseAttempt = StudyPreferenceServiceGR.getCourseAttempts(c.id);
                Map<String, Object> courseAttemptDetail = StudyPreferenceServiceGR.getCourseAttemptsDetails(String.valueOf(courseAttempt[0].get('value')));
                Course_Attempt__c attempt = (Course_Attempt__c)courseAttemptDetail.get('CourseAttempts');
				
                //and student tried to apply for Admission and Scholarship under the same calendar
                Map<String, Object> addGRTACPResultsSch =  StudyPreferenceServiceGR.addGRTACPs(null, scholarshipApp.id, calId, calId, Date.Today(), academicUnit, 
                                                                        'Test', true, true, Date.today(),
                                                                        'Test', 'MM00000=Master Of Something', 'CLAYTON', attempt.Application_Course_Preference__r.Attendance_Type__c, attempt.Application_Course_Preference__r.Attendance_Mode__c, 
                                                                         attempt.Application_Course_Preference__r.Course_Offering__r.Faculty__c, 'DOM-AUS', 'Test', true,  scholarshipApp.Parent_Application__c, true, true, true, '');
                                
                String duplicateError = (String) addGRTACPResultsSch.get('error');
                //Then: system should not allow them to add ACP             
                Assert.areEqual(duplicateError, 'duplicate', 'duplicate application found');
            }
        }
        Test.stopTest();    
    }
    
    /**
     * @author      Davey Yu
     * @description Test submitting an application course preference for Graduate Research
     * @revision    14-OCT-2024 - Davey Yu - Created
     * 
     * GIVEN a new student is registered for my.app
     * WHEN student applied for admission application only
     * THEN should successfully create an application course preference
     *
     */
    @isTest
    static void test_searchHDRCourseAdmissionOnly()
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
        application.Type_of_Study__c = 'Graduate Research';
        application.Graduate_Research_Application_Type__c = 'Admission application only';
        insert application;

		List<Map<String, String>> facultyResults;  
       	List<Map<String, String>> academicUnitResults;  
        List<Map<String, String>> courseResults;  
        List<Map<String, String>> campusResults;  
        List<Map<String, String>> attendanceModeResults;  
        List<Map<String, String>> attendanceTypeResults; 
        Map<String, Object> addGRTACPResults;

      
        Test.startTest();
        
        
        System.runAs(applicant)
        {
            
            Id calId = StudyPreferenceServiceGR.getCalendarIdCandidature('DOM-AUS', Date.Today());
            Assert.isNotNull(calId, 'Calendar id not null');
            if(calId != null){
                
                facultyResults = StudyPreferenceServiceGR.getFacultyValues('Australia');
                Map<String, String> facultyResult = facultyResults[0];
                String facultyId = facultyResult.get('value');
                Assert.isNotNull(facultyId, 'Faculty id not null');
    
                academicUnitResults = StudyPreferenceServiceGR.getAcademicUnitValues(facultyId, 'Australia');
                Map<String, String> academicUnitResult = academicUnitResults[0];
                String academicUnit = academicUnitResult.get('value');
                Assert.isNotNull(academicUnit, 'Academic unit selected');
    
                courseResults = StudyPreferenceServiceGR.getHDRCourses(facultyId, calId, 'DOM-AUS', 'Australia');
                Map<String, String> courseResult = courseResults[0];
                String courseOffering = courseResult.get('value');
                Assert.isNotNull(courseOffering, 'Course record retrieved');
                
                campusResults = StudyPreferenceServiceGR.getCampusLocations(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'Australia');
                Map<String, String> campusResult = campusResults[0];
                String campus = campusResult.get('value');
                Assert.isNotNull(campus, 'Course record based on selected courses');
                
                attendanceModeResults = StudyPreferenceServiceGR.getAttendanceTypes(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'CLAYTON');
                Map<String, String> attendanceModeResult = attendanceModeResults[0];
                String attendanceMode = attendanceModeResult.get('value');
                Assert.isNotNull(attendanceMode, 'Attendace mode based on selected courses and campus');
    
                attendanceTypeResults = StudyPreferenceServiceGR.getAttendanceModes(facultyId, calId, 'DOM-AUS', 'MM00000=Master Of Something', 'CLAYTON', attendanceMode);
                Map<String, String> attendanceTypeResult = attendanceTypeResults[0];
                String attendanceType = attendanceTypeResult.get('value');
                Assert.isNotNull(attendanceType, 'Attendace type based on selected courses, campus and attendance mode');
    
                //add application
                addGRTACPResults =  StudyPreferenceServiceGR.addGRTACPs(null, application.id, calId, calId, Date.Today(), academicUnit, 
                                                                        'Test', true, true, Date.today(),
                                                                        'Test', 'MM00000=Master Of Something', 'CLAYTON', attendanceType, attendanceMode, facultyId, 'DOM-AUS', 'Test', true, null, true, true, true, '');
                Application_Course_Preference__c acpRemove = [select id from Application_Course_Preference__c where Application__c =: application.id];
                StudyPreferenceServiceGR.removeACP(acpRemove.Id, application.Id);
            }
        }
        Test.stopTest();    
    }

     /**
     * @author      Davey Yu
     * @description Test submitting an application course preference for Graduate Research
     * @revision    03-OCT-2024 - Davey Yu - Created
     * 
     * GIVEN a student login to my.app
     * WHEN student already had submitted an application or has a draft application
     * THEN should successfully load an existing course preference on the application 
     *
     */
   	@isTest
    static void test_getCourseSearchInitLoad()
    {
        //bypass flows
        Bypass_Mute_Request__c bm = new Bypass_Mute_Request__c();
        bm.Bypass_All_Flows__c = true;
        insert bm;
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        
        Application__c application = [Select id, Residency_Status__c, Graduate_Research_Application_Type__c From Application__c where applicant__r.Person_ID_unique__c = '12345678SA'];
		Map<String, Object> mapResults;
        Test.startTest();
        System.runAs(applicant)
        {
            mapResults = StudyPreferenceServiceGR.getCourseSearchInitLoad(application.Id);
        }
        Test.stopTest();            
        // application
        Application__c appResult = (Application__c) mapResults.get(StudyPreferenceService.FIELD_APPLICATION);
        Assert.areEqual(application.Id, appResult.Id, 'Application Ids on load should match');
        
        // acps
        List<Application_Course_Preference__c> acps = (List<Application_Course_Preference__c>) mapResults.get(StudyPreferenceServiceGR.FIELD_ACPS);
        Assert.areEqual(1, acps.size(), '1 ACP should be created');

        // Application Created By - Profile
        Assert.areEqual(mapResults.get(StudyPreferenceServiceGR.FIELD_APPLICATION_CREATEDBY), [SELECT id, createdby.Profile.name FROM Application__c WHERE Id = :application.id LIMIT 1].createdby.Profile.name, 'CreatedBy Profiles should match');        
    }
    
    
}