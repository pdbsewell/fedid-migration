/*******************************************************************************
* @author		Vishal Gupta
* @date         30/05/2025    
* @description  Test Class for GRScholarshipRoundPublishBatch Class
* @revision     30/05/2025 - Initial Version
*******************************************************************************/
@isTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on these type of object - Opportunity, SBQQ__Quote__c*/
public class GRScholarshipRoundPublishBatch_Test {

    @TestSetup
    static void makeData() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id, Email, Person_ID_unique__c FROM Contact WHERE id =: applicant.contactId];
        c.Person_ID_unique__c = '2346193';
        c.Email = 'test@test.au';
        update c;
        //create Academic Org unit account
        Account testAcademicOrg = new Account(Name = 'test Academic Org unit', Callista_Org_Unit_Code__c='TEST123');
        insert testAcademicOrg;
        //create faculty account
        Account testFaculty = new Account(Name = 'test faculty', Callista_Org_Unit_Code__c='TEST12398', Monash_AM_Start_Date__c=Date.Today(), RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Faculty'][0].Id);
        insert testFaculty;

        //create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        app.Campus_Location__c = 'Australia';
        app.Residency_Status__c = 'DOM-SUN';
        insert app;

        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.Faculty__c = testFaculty.Id;
        insert course;

        Calendar__c cal = new Calendar__c();
        cal.Calendar_Code__c = '1111_1111';
        cal.type__c = 'ADM-RES1';
        cal.name = 'ADM_2025_ADM-RES1';
        cal.Sequence_Number__c = 1111;
        cal.Sequence_Number_Year__c = 1111;
        insert cal;
        // Creare Course Offering
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

        Calendar_Dates__c cd = new Calendar_Dates__c(Name = 'HDR-SCH-OP', Calendar_Code__c = '11050_11078', Calendar_Date_Unique_Key__c = '11050_11078CRS-ASDRTSD', CalendarId__c = cal.Id, Date_Type_Description__c = 'OPENING DATE FOR GR', Date_Value__c = Date.today().addDays(-4) );
        insert cd;

        Calendar_Dates__c cd2 = new Calendar_Dates__c(Name = 'HDR-SCH-CL', Calendar_Code__c = '11050_13245', Calendar_Date_Unique_Key__c = '11050_11078CRS-123123', CalendarId__c = cal.Id, Date_Type_Description__c = 'CLOSING DATE FOR GR', Date_Value__c = Date.today().addDays(-1) );
        insert cd2;

        Calendar_Dates__c cd3 = new Calendar_Dates__c(Name = 'HDR-SCI-OP', Calendar_Code__c = '11050_14548', Calendar_Date_Unique_Key__c = '1105_1108CRS-ASDRTSD', CalendarId__c = cal.Id, Date_Type_Description__c = 'OPENING DATE FOR GR', Date_Value__c = Date.today().addDays(-4) );
        insert cd3;

        Calendar_Dates__c cd4 = new Calendar_Dates__c(Name = 'HDR-SCI-CL', Calendar_Code__c = '11050_324545', Calendar_Date_Unique_Key__c = '11050_11078C-123123', CalendarId__c = cal.Id, Date_Type_Description__c = 'CLOSING DATE FOR GR', Date_Value__c = Date.today().addDays(-1) );
        insert cd4;

        //create Application_Course_Preference__c
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        coursePreference.Academic_Org_Unit__c = testAcademicOrg.Id;
        coursePreference.Callista_Unique_Key_AP__c = 'ACP-1';
        coursePreference.Graduate_Research_Application_Type__c = 'Scholarship';
        coursePreference.GradRes_Callista_Id__c = 'testid';
        coursePreference.Scholarship_Calendar__c = cal.Id;
        insert coursePreference;

        Application_Course_Preference__c coursePreference2 = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        coursePreference2.Academic_Org_Unit__c = testAcademicOrg.Id;
        coursePreference2.Callista_Unique_Key_AP__c = 'ACP-2';
        coursePreference2.Graduate_Research_Application_Type__c = 'Scholarship';
        coursePreference2.GradRes_Callista_Id__c = 'testid2';
        coursePreference2.Scholarship_Calendar__c = cal.Id;
        insert coursePreference2;

        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        SBQQ.TriggerControl.disable();

        Opportunity oppty = new Opportunity(Name = 'test', StageName = 'New Offer', CloseDate = date.today().addDays(3), Application_Course_Preference__c = coursePreference.Id,
                            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Graduate_Research_Offer').getRecordTypeId(), Research_Offer_Type__c = 'Scholarship Offer');
        insert oppty;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppty.Id);
        insert quote;

        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, Scholarship_Value__c = 20000, 
                                                            Scholarship_Type__c = 'APA', Scholarship_Value_Year__c = 2025, 
                                                            Scholarship_Value_Range__c = '20000 to 30000', Additional_Clause_Notes__c = 'Conditions' );
        insert quoteLine1;
    }

    /**
     * @author          Vishal Gupta
     * @description     Publish the Scholarship Round for the selected calendar
     * @revision        30/5/2025 - Initial Version
     */
     @isTest static void testPublishScholarshipRound() {
        //Given, there is a Scholarship GR application in the system
        Calendar__c cal = [SELECT Published_Date_for_Inter_ScholarRound__c, Published_Date_for_Domes_ScholarRound__c FROM Calendar__c];
        Test.startTest();
        GRScholarshipRoundPublishBatch.GRScholarshipCalendarRound calendarRound = new GRScholarshipRoundPublishBatch.GRScholarshipCalendarRound(cal.Id, 'International');
        
        //When, We try to publish the scholarship calendar
        Database.executeBatch(new GRScholarshipRoundPublishBatch(cal.Id, 'International', new List<GRScholarshipRoundPublishBatch.GRScholarshipCalendarRound>{calendarRound}), 10);
        Test.stopTest();
        SBQQ__Quote__c quoteAfterUpdate = [SELECT SBQQ__Status__c FROM SBQQ__Quote__c WHERE SBQQ__LineItemCount__c > 0 Limit 1];
        //Then, all the application offers will get approved for that calendar
        Assert.areNotEqual(quoteAfterUpdate.SBQQ__Status__c, null);
    }
}