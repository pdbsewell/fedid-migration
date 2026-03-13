/**
@author Various
@date Unknown
@group Tests
@description Sibling test class for ApplicationCoursePreferenceServices
@revision Cartick Sub - 22 April 2021 - PRODEV-678 - Add test method to validate ACP defaults for Professional Development
          Cartick Sub - 2 June 2021 - PRODEV-690 - Add test method to validate ACP faculty CC email population for Professional Development
 17.04.2023 Ken McGuire: Changed Comments__c (255 characters) to LongComments__c (4000 characters)
 25.02.2024 Martin Cadman: Added initial check of calendar sequence numbers
**/

@isTest
public with sharing class ApplicationCoursePreferenceServices_Test {
    @testSetup
    public static void setup() {
        Feature_Switch__c fs = Feature_Switch__c.getInstance();
        fs.Align_ACP_Owner__c = true;
        upsert fs;
        
        List<SystemDataOwnersSetting__c> DataOwnerList = new List<SystemDataOwnersSetting__c>();

        SystemDataOwnersSetting__c accountDataOwner = new SystemDataOwnersSetting__c();
        accountDataOwner.Name = 'Account System Data Owner';
        accountDataOwner.FederationId__c = 'randomacc123';
        accountDataOwner.object__c = 'Account'; 
        DataOwnerList.add(accountDataOwner);
        SystemDataOwnersSetting__c contactDataOwner = new SystemDataOwnersSetting__c();
        contactDataOwner.Name = 'Contact System Data Owner';
        contactDataOwner.FederationId__c = 'randomacc345';
        contactDataOwner.object__c = 'Contact';
        DataOwnerList.add(contactDataOwner);
        SystemDataOwnersSetting__c systemownerDetail = new SystemDataOwnersSetting__c();
        systemownerDetail.Name = 'SystemOwnerDetail';
        systemownerDetail.ValidRecordTypes__c = 'applicant';
        systemownerDetail.ByPassUser__c = '0012A00000abcde';
        DataOwnerList.add(systemownerDetail);
        insert DataOwnerList;

        Agent_Onboarding_Settings__c setting = new Agent_Onboarding_Settings__c(Role_RT_Developer_Name__c = 'Agency_Contact_Role');
        insert setting;

        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');
        TriggerCommon.disableTrigger('Application__c');

        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                  Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                  Country__c = 'Australia');
        insert australia;

        Account testAgency = new Account(Name = 'TestAgencyAccount', Callista_Org_Unit_Code__c = 'TSTAG', Monash_AM_Campus__c = 'Australia', Status__c = 'Appointed', City__c = 'Perth', Country_Lookup__c = australia.id, Post_Code__c = '2170', Email__c = 'Agent@TestAgencyAccount.com.domain', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency').getRecordTypeId());
        insert testAgency;

        Id agentRecType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Agency_Contact').getRecordTypeId(); 

        Contact testAgentCon = new Contact(RecordTypeId = agentRecType, FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAgency.Id
                                        , Email = 'TestEmail@testemail.com', Agency_Contact_Roles__c = 'Branch Manager; Delegated Admin; Counsellor');
        insert testAgentCon;
            
        //Insert custom settings for Bypass_Mute_Request__c
        Bypass_Mute_Request__c bmr = Bypass_Mute_Request__c.getOrgDefaults();
        bmr.Enable_LogUtility_Debug__c = true;
        bmr.Enable_LogUtility_ShowLimits__c = true;
        upsert bmr;
        
        List<List_of_Values__c> lovs = new List<List_of_Values__c>();

        // Documentation Status - PENDING
        List_of_Values__c lov_1 = new List_of_Values__c ();
        lov_1.System_Code__c = 'PENDING';
        lov_1.Type__c = 'ADM_DOC_STATUS';
        lov_1.Value__c = 'PENDING';
        lovs.add(lov_1);

        // Entry Qualification Status - PENDING
        List_of_Values__c lov_2 = new List_of_Values__c ();
        lov_2.System_Code__c = 'PENDING';
        lov_2.Type__c = 'ADM_ENTRY_QUAL_STATUS';
        lov_2.Value__c = 'PENDING';
        lovs.add(lov_2);

        // Outcome Status - IN-PROGRES
        List_of_Values__c lov_3 = new List_of_Values__c ();
        lov_3.System_Code__c = 'PENDING';
        lov_3.Type__c = 'ADM_OUTCOME_STATUS';
        lov_3.Value__c = 'IN-PROGRES';
        lovs.add(lov_3);
        
        // Documentation Status - INCOMPLETE
        List_of_Values__c lov_4 = new List_of_Values__c ();
        lov_4.System_Code__c = 'INCOMPLETE';
        lov_4.Type__c = 'ADM_DOC_STATUS';
        lov_4.Value__c = 'INCOMPLETE';
        lovs.add(lov_4);
        
        // Outcome Status - APP-WDRWN
        List_of_Values__c lov_5 = new List_of_Values__c ();
        lov_5.System_Code__c = 'REJECTED';
        lov_5.Type__c = 'ADM_DOC_STATUS';
        lov_5.Value__c = 'APP-WDRWN';
        lovs.add(lov_5);

        insert lovs;

        // Reference data - Calendar
        Calendar__c cal = new Calendar__c();
        cal.Calendar_Code__c = '1111_1111';
        cal.type__c = 'ADM-0';
        cal.Sequence_Number__c = 1111;
        cal.Sequence_Number_Year__c = 1111;
        cal.name = 'ADM_2021_ADM-0';
        insert cal;

        // Reference data - Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.name = 'E6001';
        course.Course_Code__c = 'E6001_1';
        course.Version__c = '1';
        Course.Type__c = 'Short_Course';
        insert course;
        
        // Reference data - Course Offering
        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course_Code__c = 'E6001';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-CSP';
        courseOffering.Academic_CI_Sequence_Number__c = 1111;
        courseOffering.Admission_CI_Sequence_Number__c = 1111;
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Unit_Set_Code__c = null;
        courseOffering.Unit_Set_Version__c = null;
        courseOffering.Admission_Calendar_Description__c = 'CrOf0';
        courseOfferings.add(courseOffering);
        
        Course_Offering__c courseOffering_1 = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering_1.Course_Code__c = 'E6001';
        courseOffering_1.Course_Version_Number__c = 1;
        courseOffering_1.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering_1.Location_Code__c = 'CLAYTON';
        courseOffering_1.Attendance_Type__c = 'FT';
        courseOffering_1.Attendance_Mode__c = 'IN';
        courseOffering_1.Admission_Category__c = 'UG-CSP';
        courseOffering_1.Academic_CI_Sequence_Number__c = 1111;
        courseOffering_1.Admission_CI_Sequence_Number__c = 1111;
        courseOffering_1.Unit_Set_Code__c = null;
        courseOffering_1.Unit_Set_Version__c = null;
        courseOffering_1.Citizenship_type__c = 'INT-TEP';
        courseOffering_1.Admission_Calendar_Description__c = 'CrOf1';
        courseOfferings.add(courseOffering_1);
        
        Course_Offering__c courseOffering_2 = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering_2.Course_Code__c = 'E6001';
        courseOffering_2.Course_Version_Number__c = 1;
        courseOffering_2.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering_2.Location_Code__c = 'CLAYTON';
        courseOffering_2.Attendance_Type__c = 'FT';
        courseOffering_2.Attendance_Mode__c = 'EX';
        courseOffering_2.Admission_Category__c = 'UG-CSP';
        courseOffering_2.Academic_CI_Sequence_Number__c = 1111;
        courseOffering_2.Admission_CI_Sequence_Number__c = 1111;
        courseOffering_2.Unit_Set_Code__c = null;
        courseOffering_2.Unit_Set_Version__c = null;
        courseOffering_2.Citizenship_type__c = 'INT-TEP';
        courseOffering_2.Admission_Calendar_Description__c = 'CrOf2';
        courseOfferings.add(courseOffering_2);
        
        insert courseOfferings;
        
        List<Application_Course_Preference__c> acps = new List<Application_Course_Preference__c>();

        Contact con = StudFirst_TestHelper.createInternationalApplicant();
        insert con;
        Application__c application = new Application__c();
        application.Applicant__c = con.Id;
        application.Campus_Location__c = null;
        application.Visa_Type__c = null;
        application.Australian_Immigration_Office_Issued__c = null;
        application.Visa_Number__c = null;
        application.Passport_Number__c = null;
        application.Visa_Start_Date__c = null;
        application.Visa_End_Date__c = null;
        application.Refused_entry_visa_to_any_country__c = null;
        application.Breached_visa_condition__c = null;
        application.Medical_health_prevent_visa__c = null;
        application.Protection_visa_in_any_country__c = null;
        application.Convicted_of_crime_offence__c = null;
        application.HasDisabilities__c = 'Yes';
        application.Agent_Org_Unit_Code__c = 'TSTAG';
        // application.Residency_Status__c = 'DOM-AUS';
        insert application;

        Application_Course_Preference__c acp_1 = new Application_Course_Preference__c();
        acp_1.Callista_Unique_Key_AP__c = 'ACP-1';
        acp_1.Documentation_Status_LOV__c = lov_1.Id;
        acp_1.Entry_Qualification_Status_LOV__c = lov_2.Id;
        acp_1.Outcome_Status_LOV__c = lov_3.Id;
        acp_1.Application__c = application.Id;
        // The following is only to cover submitApprovalProcess.
        acp_1.Status__c = 'Registered - Pending Approval';
        acp_1.Course_Offering__c = courseOffering_1.Id;
        acp_1.Run_Queue_Routing__c = false;
        acps.add(acp_1);
        
        Application_Course_Preference__c acp_2 = new Application_Course_Preference__c();
        acp_2.Callista_Unique_Key_AP__c = 'ACP-2';
        acp_2.Documentation_Status_LOV__c = lov_4.Id;
        acp_2.Entry_Qualification_Status_LOV__c = lov_2.Id;
        acp_2.Outcome_Status_LOV__c = lov_3.Id;
        acp_2.Course_Offering__c = courseOffering_2.Id;
        acps.add(acp_2);
        
        Application_Course_Preference__c acp_3 = new Application_Course_Preference__c();
        acp_3.Callista_Unique_Key_AP__c = 'ACP-3';
        acp_3.Entry_Qualification_Status_LOV__c = lov_2.Id;
        acp_3.Outcome_Status_LOV__c = lov_5.Id;
        acps.add(acp_3);
        
        insert acps;
        Application__c testOESApp = StudFirst_TestHelper.createApplication(con);
        testOESApp.Source_System__c = 'OES';
        insert testOESApp;

        Application_Course_Preference__c oesACP = new Application_Course_Preference__c();
        oesACP.Callista_Unique_Key_AP__c = 'TestOESACP';
        oesACP.Application__c = testOESApp.Id;
        insert oesACP;

        TriggerCommon.enableTrigger('Application__c');
        //TriggerCommon.enableTrigger('Application_Course_Preference__c');
        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');

        // Create records for Professional Development related test methods
        Course__c testCourse = PDTestHelper.createCourse();
        //..Course_Offering__c testCO = 
        PDTestHelper.createCourseOfferingForCourse(testCourse);
        //.. Contact testContact = 
        PDTestHelper.createContact2('Travis', 'PD-Test', 'travis.pd-test@test.com');
    }
    
    /**
    @author Martin Cadman
    @description Check some specific PD related ACP Attributes
    @revision 22 April 2021 - Cartick Sub - Move PD record creation to setup method for re-use by other test methods
    **/
    @istest
    static void createPDACP() {

        //bypass flows
        Bypass_Mute_Request__c bmr = [SELECT ID,Bypass_All_Flows__c FROM Bypass_Mute_Request__c WHERE Bypass_All_Flows__c = false LIMIT 1];
        bmr.Bypass_All_Flows__c = true;
        update bmr;
       
        // Retrieve PD records from database
        List<Course__c> courses = [SELECT Id, Name FROM Course__c WHERE Type__c = 'Short_Course'];
        List<Course_Offering__c> cofs = [SELECT Id, Name, Course__c FROM Course_Offering__c WHERE Course__r.Type__c = 'Short_Course'];
        Course__c course = courses[0];
        Course_Offering__c cof = cofs[0];
        Test.startTest();

        Application_Course_Preference__c acp = new Application_Course_Preference__c();
        acp.Course__c = course.Id;
        acp.Course_Offering__c = cof.id;
        
        insert acp;
        acp.LongComments__c = 'Testing';
        update acp;

        Test.stopTest();
        Application_Course_Preference__c acpCheck = [SELECT Name, ACP_ID__c FROM Application_Course_Preference__c WHERE Id = :acp.id];
        Assert.areEqual(acpCheck.Name, acpCheck.ACP_ID__c, 'PD ACPs names should be the same as the acp_id');
    }
    
    /**
    @author Cartick Sub
    @description For PD ACPs, validates if faculty and course type are correctly set accordingly to corresponding values from parent Course
    @revision
    **/
    @isTest
    public static void validatePDACPDefaults() {
        
        // Retrieve PD records from database
        List<Course__c> testCourses = [SELECT Id, Name, Managing_Faculty__c FROM Course__c WHERE Type__c = 'Short_Course'];
        List<Course_Offering__c> testCOs = [SELECT Id, Name, Course__c FROM Course_Offering__c WHERE Course__r.Type__c = 'Short_Course'];
        List<Contact> testContacts = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE LastName = 'PD-Test'];
            
        Test.startTest();
        //bypass flows
        Bypass_Mute_Request__c bmr = [SELECT ID,Bypass_All_Flows__c FROM Bypass_Mute_Request__c WHERE Bypass_All_Flows__c = false LIMIT 1];
        bmr.Bypass_All_Flows__c = true;
        update bmr;
               
        // Insert ACP
        Application_Course_Preference__c testACP = new Application_Course_Preference__c(
            Applicant__c = testContacts[0].Id,
            Course_Offering__c = testCOs[0].Id,
            Status__c = 'Registered - Not Paid'
        );

        insert testACP;

        Test.stopTest();

        // Verify that ACP was correctly updated in the database
        List<Application_Course_Preference__c> ACPsFromDB = [SELECT Id, Name, Course_Type_Text__c, Managing_Faculty_Text__c FROM Application_Course_Preference__c WHERE Id = :testACP.Id];
        Assert.areEqual('Short_Course', ACPsFromDB[0].Course_Type_Text__c, 'Course Type not set');
        Assert.areEqual(testCourses[0].Managing_Faculty__c, ACPsFromDB[0].Managing_Faculty_Text__c,'Managing Faculty not set');
    }

    /**
    @author Cartick Sub
    @description For PD ACPs, validates if the Faculty_Student_Email_CC__c is correctly set according to the related custom metadata type record
    @revision
    **/
    @isTest
    public static void validatePDACPFacultyEmailCC() {
        // Retrieve PD records from database
        List<Course__c> testCourses = [SELECT Id, Name, Managing_Faculty__c FROM Course__c WHERE Type__c = 'Short_Course'];
        List<Course_Offering__c> testCO = [SELECT Id, Name, Course__c FROM Course_Offering__c WHERE Course__r.Type__c = 'Short_Course'];
        List<Contact> testContacts = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE LastName = 'PD-Test'];
            
        Test.startTest();
        //bypass flows
        Bypass_Mute_Request__c bmr = [SELECT ID,Bypass_All_Flows__c FROM Bypass_Mute_Request__c WHERE Bypass_All_Flows__c = false LIMIT 1];
        bmr.Bypass_All_Flows__c = true;
        update bmr;
               
        // Insert ACP
        Application_Course_Preference__c testACP = new Application_Course_Preference__c(
            Applicant__c = testContacts[0].Id,
            Course_Offering__c = testCO[0].Id,
            Managing_Faculty_Text__c = 'Faculty of Education',
            Status__c = 'Registered - Invoice not processed'
        );

        insert testACP;

        Test.stopTest();
        
        // Verify that ACP was correctly updated in the database
        List<Application_Course_Preference__c> ACPFromDB = [SELECT Id, Name, Faculty_Student_Email_CC__c, Managing_Faculty_Text__c FROM Application_Course_Preference__c WHERE Id = :testACP.Id];
        List<Faculty_Custom_Data__mdt> facultyCMDT = [SELECT Managing_Faculty__c, Faculty_Student_Email_CC__c FROM Faculty_Custom_Data__mdt WHERE Managing_Faculty__c = :ACPFromDB[0].Managing_Faculty_Text__c];
        Assert.areEqual(facultyCMDT[0].Faculty_Student_Email_CC__c, ACPFromDB[0].Faculty_Student_Email_CC__c, 'Faculty CC email not set');
    }

    /*
     * @author          Ayush Agrawal (ayush.agrawal@monash.edu)
     * @description     EPBBS-1011 -> https://confluence.apps.monash.edu/display/EPBBS/New+Course+Admission+Status+Rules
     * 
     * 07/02/2024 - Martin Cadman SFTG-3722 - Added initial change to ensure the sequence number field were populated correctly on insert
     *                                        They should align with the course offering until after submission
     */
    @istest
    static void testGenerateCourseAdmissionStatus() {
        List<Application_Course_Preference__c> acps = [SELECT
                                                       Callista_Unique_Key_AP__c,
                                                       Course_Admission_Status__c,
                                                       course_offering__c,
                                                       Original_Course_Offering__c,
                                                       Academic_CI_Sequence_Number__c,
                                                       Admission_CI_Sequence_Number__c,
                                                       course_offering__r.Academic_CI_Sequence_Number__c,
                                                       course_offering__r.Admission_CI_Sequence_Number__c,
                                                       calendar_code__c,
                                                       calendar_code__r.Sequence_Number__c,
                                                       calendar_code__r.Sequence_Number_year__c 
                                                       FROM Application_Course_Preference__c
                                                       WHERE
                                                       Callista_Unique_Key_AP__c IN ('ACP-1', 'ACP-2', 'ACP-3')];

        for(Application_Course_Preference__c acp : acps) {
            if(acp.Callista_Unique_Key_AP__c == 'ACP-1') {
                Assert.areEqual('In Progress - Faculty', acp.Course_Admission_Status__c);
                Assert.areEqual(acp.course_offering__c, acp.Original_Course_Offering__c, 'Original Course offering not set');
                Assert.areEqual(acp.course_offering__r.Academic_CI_Sequence_Number__c, acp.Academic_CI_Sequence_Number__c, 'Academic CI Sequence number mismatch');
                Assert.areEqual(acp.course_offering__r.Admission_CI_Sequence_Number__c, acp.Admission_CI_Sequence_Number__c, 'Admission CI Sequence number mismatch');
            } else if(acp.Callista_Unique_Key_AP__c == 'ACP-2') {
                Assert.areEqual('Pending', acp.Course_Admission_Status__c);
            } else if(acp.Callista_Unique_Key_AP__c == 'ACP-3') {
                Assert.areEqual('App Withdrawn', acp.Course_Admission_Status__c);
            }
        }
    }

    /*
     * @author       Shalini Mendu
     * @date         14/07/2019
     * @description  tests the API integration wih Online Credit (SF-986)
     * @revision     Ayush Agrawal - Deployment fix for the release PI19.6.3.1
     * @revision     Shalini Mendu - Changing the assert value
     * @revision     Ayush Agrawal (ayush.agrawal@monash.edu) - EPBBS-984
     */
    @istest
    static  void testCopyCourseOfferings() {
        Map<String, Id> mapOfCourseOfferingAttendanceModeToCourseOfferingId = new Map<String, Id>();
        
        for(Course_Offering__c co : [SELECT Id, Attendance_Mode__c FROM Course_Offering__c]) {
            mapOfCourseOfferingAttendanceModeToCourseOfferingId.put(co.Attendance_Mode__c, co.Id);
        }

        List<Application_Course_Preference__c> acps = [SELECT Id, Attendance_Mode__c, Course_Offering__c, Callista_Unique_Key_AP__c FROM Application_Course_Preference__c];

        Assert.areEqual('IN', [SELECT Attendance_Mode__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-1' LIMIT 1].Attendance_Mode__c);
        Assert.areEqual('EX', [SELECT Attendance_Mode__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-2' LIMIT 1].Attendance_Mode__c);
        Assert.areEqual(null, [SELECT Attendance_Mode__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-3' LIMIT 1].Attendance_Mode__c);

        Test.startTest();
        
        for(Application_Course_Preference__c acp : acps) {
            if(acp.Callista_Unique_Key_AP__c == 'ACP-1') {
                acp.Deferred_Course_Offering__c =  acp.Course_Offering__c;
                acp.Course_Offering__c = mapOfCourseOfferingAttendanceModeToCourseOfferingId.get('EX');
            } else if(acp.Callista_Unique_Key_AP__c == 'ACP-2') {
                acp.Deferred_Course_Offering__c =  acp.Course_Offering__c;
                acp.Course_Offering__c = mapOfCourseOfferingAttendanceModeToCourseOfferingId.get('IN');
            }
        }
        
        update acps;

        Assert.areEqual('EX', [SELECT Attendance_Mode__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-1' LIMIT 1].Attendance_Mode__c);
        Assert.areEqual('IN', [SELECT Attendance_Mode__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-2' LIMIT 1].Attendance_Mode__c);
        Assert.areEqual(null, [SELECT Attendance_Mode__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-3' LIMIT 1].Attendance_Mode__c);

        Assert.areEqual('CrOf1', [SELECT Deferred_Commencement_Period__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-1' LIMIT 1].Deferred_Commencement_Period__c);
        Assert.areEqual('CrOf2', [SELECT Deferred_Commencement_Period__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-2' LIMIT 1].Deferred_Commencement_Period__c);
        
        Test.stopTest();
    }
    
    /*
     * @author       Shalini Mendu
     * @date         2020
     * @description  Tests posting English Test results to callsita
     * @revision     05/05/2022 - Shalini Mendu - Fixing SOQL 101 error
     */
    @istest
    static void testEnglishTestResults()
    {
        Test.startTest();
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Person_ID_unique__c = '12345678';
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Qualification__c qual4 = StudFirst_TestHelper.createQualification('English');
        insert qual4;

        Course__c crs = StudFirst_TestHelper.createCourse();
        insert crs;

        Course_Offering__c off = StudFirst_TestHelper.createCourseOffering(crs);
        off.Hecs_Payment_Option__c ='hec1';
        insert off;

        Contact_Qualification__c contactQualification4 = StudFirst_TestHelper.createContactQualification(c, qual4, 'English Test');
        insert contactQualification4;
        contactQualification4.Listening__c = '9';
        update contactQualification4;

        Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
        aqpRecord.Application__c = app.Id;
        aqpRecord.Contact_Qualification__c = contactQualification4.Id;
        insert aqpRecord;
        //bypass flows
        Bypass_Mute_Request__c bmr = [SELECT ID,Bypass_All_Flows__c FROM Bypass_Mute_Request__c WHERE Bypass_All_Flows__c = false LIMIT 1];
        bmr.Bypass_All_Flows__c = true;
        update bmr;
               
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, off, crs);
        insert acp;

        acp.Admission_Application_Number__c = 123456;
        update acp;

        EnglishTestScoreInterface.fireOutboundRequest(new List<Id>{contactQualification4.Id});
        Test.stopTest();
    }

    /*
     * @author       Shalini Mendu
     * @date         14/03/2022
     * @description  Enable LOI for CCT application records SFTG-2461
     */
    @istest
    static void testLOIEnglishBDPTest()
    {
        //bypass flows, triggers
        Bypass_Mute_Request__c bmr = [SELECT ID,Bypass_All_Flows__c FROM Bypass_Mute_Request__c WHERE Bypass_All_Flows__c = false LIMIT 1];
        bmr.Bypass_All_Flows__c = true;
        bmr.Bypass_All_Triggers__c = true;
        update bmr;
        
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Person_ID_unique__c = '12345678';
        insert c;

        Application__c aa = StudFirst_TestHelper.createApplication(c);
        aa.Source_System__c = 'CCT';
        aa.Residency_Status__c = 'INTRNTNL';
        aa.English_Entry_Mode__c =  'English Language Instruction in secondary school / university';
        aa.Meets_Minimum_English__c = 'YES';
        insert aa;

        Course__c crs = StudFirst_TestHelper.createCourse();
        insert crs;

        Course_Offering__c off = StudFirst_TestHelper.createCourseOffering(crs);
        off.Hecs_Payment_Option__c ='hec1';
        insert off;
        Test.startTest(); 
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(aa, c, off, crs);
        insert acp;

        acp.Admission_Application_Number__c = 123456;

        ObdACPImplementation_Mock mock = new ObdACPImplementation_Mock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        update acp;
        Test.stopTest();
   
        List<Application_Course_Preference__c> acpList1 =  [select id,name,Conditions_Must_Be_Satisfied__c,Callista_Sync_Successful__c from Application_Course_Preference__c where Admission_Application_Number__c = 123456];
        Assert.areEqual(false , acpList1[0].Callista_Sync_Successful__c);

    }

    @istest
    static void testAssignApplicationResidencyStatus() {
       Test.startTest();
   
       Application_Course_Preference__c acp =  [Select id, name from Application_Course_Preference__c where Callista_Unique_Key_AP__c ='ACP-1' LIMIT 1];
       acp.Unit_Set_Code__c = 'MM00000';
       update acp;
       Assert.areEqual('INT-TEP', [SELECT Application__r.Residency_Status__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-1' LIMIT 1].Application__r.Residency_Status__c);
       Test.stopTest();
        
    }

    @istest
    static void testSelectACPOfferedByApplicantIdErrorFreeExecution() {
        Test.startTest();
        
        ApplicationCoursePreferenceServices.selectACPOfferedByApplicantId(null);
        
        Test.stopTest();
    }

    /** 
     * @author      Kristian Vegerano
     * @date        02/11/2021
     * @description Tests to ensure applications for Malaysia campus and Study Type of Study Abroad will fetch ACP records to show on the Offer wizard
     */
    @istest
    static void testSelectACPOfferedByApplicantIdForMalaysiaMonashAbroad() {
        //Initialize variables
        //.. Set<Id> applicationIds = new Set<Id>();
        List<Application_Course_Preference__c> testAcpList = new List<Application_Course_Preference__c>();

        List<Application__c> appList = [SELECT Id,Campus_Location__c FROM Application__c LIMIT 1];
        for(Application__c app :appList){
            app.Campus_Location__c = 'Malaysia';
            app.Type_of_Study__c = Constants.MONASH_ABROAD_SA_STUDY_TYPE;
        }
        update appList;
   
        //Start test process
        Test.startTest();
            testAcpList.addAll(ApplicationCoursePreferenceServices.selectACPOfferedByApplicantId(appList[0].Id));
        Test.stopTest();

        //Start assertion
        Assert.areEqual(0, testAcpList.size());
    }

    @istest
    static void testFireCallistaOutbound() {
       List<Application_Course_Preference__c> acpList =  [select id,name,Conditions_Must_Be_Satisfied__c from Application_Course_Preference__c limit 1];
       acpList[0].Conditions_Must_Be_Satisfied__c = true;
       acpList[0].Offer_Date__c = Date.today();
       Test.startTest();
       ObdACPImplementation_Mock mock = new ObdACPImplementation_Mock();
       mock.responseCode = 200;
       Test.setMock(HttpCalloutMock.class, mock);
           update acpList;
       Test.stopTest();
       List<Application_Course_Preference__c> acpList1 =  [select id,name,Conditions_Must_Be_Satisfied__c,Callista_Sync_Successful__c from Application_Course_Preference__c where id in :acpList];
       Assert.areEqual(false , acpList1[0].Callista_Sync_Successful__c);
    }
    
   
    /*
     * @author       Kristian Vegerano
     * @date         14/04/2022
     * @description  Tests retrieving fee category mapping
     */
    @istest
    static  void test_retrievefeeCategoryMappings() {
        Map<String, List<String>> feeCategoryMapping = new Map<String, List<String>>();
        
        Test.startTest();
            feeCategoryMapping = ApplicationCoursePreferenceServices.retrievefeeCategoryMappings();
        Test.stopTest();
        
        // tests that each of the fee category pricebook mapping's pricebooks are on the map returned by the function
        for(Fee_Category_Pricebook_Mapping__mdt mapping : [SELECT DeveloperName, Pricebook_External_ID__c FROM Fee_Category_Pricebook_Mapping__mdt]){
            Assert.areEqual(true, feeCategoryMapping.containsKey(mapping.Pricebook_External_ID__c));
        }
    }

   /**
    * @description 
    * @author rajesh.punjabi@monash.edu | 31-10-2024 
    **/
    @istest
    static void testRunACPQueueRouting(){
        //bypass triggers
        Bypass_Mute_Request__c bmr = [SELECT ID,Bypass_All_Flows__c FROM Bypass_Mute_Request__c WHERE Bypass_All_Flows__c = false LIMIT 1];
        bmr.Bypass_All_Triggers__c = true;
        update bmr;
        // GIVEN : Get ACP and Application record and update with required values.
        Application_Course_Preference__c acp = [SELECT Id, Application__c, Run_Queue_Routing__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-1'];
        Application__c application = [SELECT Id, Status__c FROM Application__c WHERE Id =: acp.Application__c];

        application.Status__c = 'Submitted';
        update application;
		//bypass triggers reverse
        Bypass_Mute_Request__c bmr1 = [SELECT ID,Bypass_All_Flows__c FROM Bypass_Mute_Request__c WHERE Bypass_All_Flows__c = false LIMIT 1];
        bmr1.Bypass_All_Triggers__c = false;
        update bmr1;
        // WHEN : Update ACP Run_Queue_Routing__c to true.
        Test.startTest();
            acp.Run_Queue_Routing__c = true;
            update acp;
        Test.stopTest();

        // THEN : Validate if Run_Queue_Routing__c flag is set false.
        Application_Course_Preference__c acpUpdated = [SELECT Id, Run_Queue_Routing__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-1'];
        Assert.areEqual(false, acpUpdated.Run_Queue_Routing__c, 'Run Queue Routing flag revereted to false');
    }

    /**
    * @description 
    * @author rajesh.punjabi@monash.edu | 10-01-2025
    **/
    @istest
    static void testUpdateReleaseFlag(){
        
        // GIVEN : Get ACP record and update with required values.
        Application_Course_Preference__c acp = [SELECT Id, Workflow_Status__c, Release_Reason__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-1'];
         // WHEN : Update ACP Assessment status to 'On Hold'.
        Test.startTest();
        acp.Workflow_Status__c = 'Released';
        acp.Release_Reason__c = 'Test Reason';
        update acp;
        Test.stopTest();

        // THEN : Validate if ACP is released.
        Application_Course_Preference__c acpUpdated = [SELECT Id, Workflow_Status__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-1'];
        Assert.areEqual('Released', acpUpdated.Workflow_Status__c, 'Workflow Status is updated to Released.');
    }
    
    /**
    * @description 
    * @author Davey Yu | 26-02-2025
    **/
    @istest
    static void testACPRegisteredPendingApproval(){
        
        // GIVEN : Get ACP Record Status is set Registered - Pending Approval
        Application_Course_Preference__c acp = [SELECT Id, Managing_Faculty_Text__c, PaymentCheckURL__c, Assessment_Status__c, Released__c, Release_Reason__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-1'];
        acp.Status__c = 'Registered - Pending Approval';
        acp.Managing_Faculty_Text__c  = 'Faculty of Education';
        acp.PaymentCheckURL__c = 'https';
        Test.startTest();
        //WHEN : ACP record is Updated
        update acp;
        Test.stopTest();

        // THEN : Validate if ACP is updated.
        Application_Course_Preference__c acpUpdated = [SELECT Id, Status__c FROM Application_Course_Preference__c WHERE Callista_Unique_Key_AP__c = 'ACP-1'];
        Assert.areEqual('Registered - Pending Approval', acpUpdated.Status__c,'Succesfully Update the Status');
    }

    /**
    * @description retry the hdr integration test
    * @author Vishal gupta | 29-05-2025
    **/
    @istest
    static void testRetryHDRIntegration(){
        Test.startTest();
        Application__c app = [SELECT Id, Status__c, Type_Of_Study__c from Application__c LIMIT 1];
        app.Status__c = 'Submitted';
        app.Type_Of_Study__c = 'Graduate Research';
        update app;
        // GIVEN : There is a GR Application
        Application_Course_Preference__c acp = [SELECT Id, Sync_In_Progress__c, GradRes_Callista_Id__c FROM Application_Course_Preference__c WHERE Application__c = :app.Id];
        //WHEN : ACP record is Updated with Sync in progress is true
        acp.Sync_In_Progress__c = true;
        update acp;
        Test.stopTest();
        // THEN : the GRSendApplicationToCallistaQueuable is scheduled to send the application to callista.
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType, CreatedDate, CompletedDate, NumberOfErrors, JobItemsProcessed, TotalJobItems 
                                    FROM AsyncApexJob 
                                    WHERE ApexClass.Name = 'GRSendApplicationToCallistaQueuable' ];
        Assert.areEqual(false, jobs.isEmpty(),'Succesfully scheduled the job');                             
    }
}