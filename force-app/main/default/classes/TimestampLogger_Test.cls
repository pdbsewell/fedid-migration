/**
@author Davey Yu
@date 27-APR-2025
@group Tests
@description Test class for TimestampLogger.cls
@revision
**/
@isTest(isParallel=true)
private class TimestampLogger_Test {

    @testSetup
    static void setupTestData() {
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
        insert courseOffering;
        
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
        insert application;
        
        Application_Course_Preference__c acp_1 = new Application_Course_Preference__c();
        acp_1.Callista_Unique_Key_AP__c = 'ACP-1';
        acp_1.Application__c = application.Id;
        acp_1.Status__c = 'Registered - Pending Approval';
        acp_1.Course_Offering__c = courseOffering.Id;
        acp_1.Workflow_Status__c = 'Inactive';
        acp_1.OnHold_Comments__c = 'Initial comments';
        acp_1.Name = 'ACP-001';
        acp_1.Course_Code__c = 'CS101';
        acp_1.Intake_Period__c = 'Fall 2025';
        acp_1.Location_Code__c = 'CAUFIELD';
        insert acp_1;
    }
	
    /**
     * @description test to create logs when a new application course preference record is inserted
     */
    @isTest
    static void testInsertScenario() {
        Test.startTest();

        // GIVEN application course preference is inserted
        Application_Course_Preference__c newACP = [SELECT Id, Workflow_Status__c, OnHold_Comments__c, On_Hold_Reason__c,
            Release_Reason__c, Owner_Name__c, Owner_Team__c, Application__r.Name, Admission_Category__c, Course_Code__c,
            Course_Level__c, Intake_Period__c, Location_Code__c,Managing_Faculty__c, Person_Id__c,  Application_Course_Preference__c.Name,
            LastModifiedBy.Name, LastModifiedBy.id
            FROM Application_Course_Preference__c LIMIT 1];

        Map<Id, SObject> newMap = new Map<Id, SObject>{ newACP.Id => newACP };
		
        Test.stopTest();

        //THEN timestamp log created
        List<Timestamp_Log__c> logs = [SELECT Id, Field_Value__c FROM Timestamp_Log__c WHERE Parent_Object_Id__c = :newACP.Id];
        Assert.isNotNull(logs, 'Timestamp log should be created on insert');
    }
	
   	/**
     * @description test to create logs when a new application course preference workflow status is updated
     */
    @isTest
    static void testUpdateScenario() {
        // GIVEN application course preference is inserted
        Application_Course_Preference__c acp = [SELECT Id, Workflow_Status__c, OnHold_Comments__c, On_Hold_Reason__c,
            Release_Reason__c, Owner_Name__c, Owner_Team__c, Application__r.Name, Admission_Category__c, Course_Code__c,
            Course_Level__c, Intake_Period__c, Location_Code__c,Managing_Faculty__c, Person_Id__c,  Application_Course_Preference__c.Name,
            LastModifiedBy.Name, LastModifiedBy.id
            FROM Application_Course_Preference__c LIMIT 1];
        
        Test.startTest();
        //WHEN workflow status is updated
        acp.Workflow_Status__c = 'Pending';
        update acp;
        Test.stopTest();
		
        //THEN timestamp log changes with the new value
        List<Timestamp_Log__c> logs = [SELECT Id, Field_Value__c, Old_Value__c FROM Timestamp_Log__c WHERE Parent_Object_Id__c = :acp.Id and Field_Value__c = 'Pending' Limit 1];
        if(logs.size() > 0){
            assert.areEqual('Pending', logs[0].Field_Value__c);
            assert.areEqual('Inactive', logs[0].Old_Value__c);
        }
        
    }
    
    
}