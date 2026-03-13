/**
 * @description       : ContactDocumentTriggerHandler test class
 * @author            : Vishal Gupta
 * @group             : Test
 * @Last Modified By  : 
 * @Last Modified On  : 28/05/2025
 * @version           : Modifications Log
 * Date           Author              Modification
 * 28/05/2025     Vishal Gupta        Initial Version
**/
@isTest(isParallel=true)
private class ContactDocumentTriggerHandler_Test {
    
    @testSetup static void setup() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id, Person_ID_unique__c FROM Contact WHERE id =: applicant.contactId];
        c.Person_ID_unique__c = '2346193';
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

        //create contact document
        List<Contact_Document__c> conDocList = new List<Contact_Document__c>();
        for(Integer count = 0; count < 50; count++) {
            Contact_Document__c conDoc = new Contact_Document__c();
            conDoc.Contact__c = c.id;
            conDoc.Application__c = app.Id;
            conDoc.Document_Type__c = 'PARENT_GUARDIAN';
            conDoc.Filename__c = 'testdoc';
            conDoc.Has_API_Response__c = true;
            conDocList.add(conDoc);
        }        
        insert conDocList;
    }  
    
	/*******************************************************************************
	* @description 	test the retry Application Document Integration
    * @author Vishal Gupta
    * date 28/5/2025
	*******************************************************************************/
	@isTest
    private static void testRetryGRDocumentSyncToCallista() {
        //Given, there are a GR application documents in the system
        List<Contact_Document__c> lstDocs = [SELECT Id FROM Contact_Document__c];

        Test.startTest();
        for(Contact_Document__c cs : lstDocs) {
            cs.Sync_In_Progress__c = true;
        }
        //When, we try to update the sync field on the contact document
        update lstDocs;
        Test.StopTest();
        //Then, System should published the Platform Event to enable document callout
        Assert.isNotNull(
            [SELECT Name, Position, Retries, LastError 
                FROM EventBusSubscriber 
                WHERE Topic='Async_Process__e'
            ],
            'Platform Events are published to enable document callout'
        );
    }
}