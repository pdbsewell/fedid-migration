/*******************************************************************************
* @author		Vishal Gupta
* @date         14/10/2024    
* @description  Test Class for GRApplicationJSONMapper Class
* @revision     14/10/2024 - Initial Version
*******************************************************************************/
@isTest(isParallel = true)
public class GRApplicationJSONMapper_Test {

    @TestSetup
    static void makeData() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        //create agent account
        Account testAgency = new Account(Name = 'test agency', Status__c='Appointed', Callista_Org_Unit_Code__c='CRM-AGENT');
        insert testAgency;
        //create Academic Org unit account
        Account testAcademicOrg = new Account(Name = 'test Academic Org unit', Callista_Org_Unit_Code__c='TEST123');
        insert testAcademicOrg;
        //create faculty account
        Account testFaculty = new Account(Name = 'test faculty', Callista_Org_Unit_Code__c='TEST12398', Monash_AM_Start_Date__c=Date.Today(), RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Faculty'][0].Id);
        insert testFaculty;

        //create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        app.Agent__c = testAgency.Id;
        app.Applied_For_Permanent_Residency__c = true;
        insert app;
        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.Faculty__c = testFaculty.Id;
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;
        
        Calendar__c cal = new Calendar__c();
        cal.Calendar_Code__c = '1111_1111';
        cal.type__c = 'ADM-RES1';
        cal.name = 'ADM_2025_ADM-RES1';
        cal.Sequence_Number__c = 1111;
        cal.Sequence_Number_Year__c = 1111;
        insert cal;

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
        coursePreference.Employment_Days__c = 'Mon;Tue';
        coursePreference.Employment_Hours__c = 20;
        coursePreference.Calendar_Code__c = cal.Id;
        coursePreference.Scholarship_Calendar__c = cal.Id;
        insert coursePreference;

        //create Contact_Qualification__c
        Map<Id, RecordType> qualifficationType = new Map<Id, RecordType>([SELECT Id FROM RecordType WHERE sObjectType = 'Contact_Qualification__c']);
        List<Contact_Qualification__c> lstCQ = new List<Contact_Qualification__c>();
        for(Id recordTypeId : qualifficationType.keyset()) {
            Contact_Qualification__c cq = new Contact_Qualification__c();
            cq.Contact__c = applicant.ContactId;
            cq.RecordTypeId = recordTypeId;
            lstCQ.add(cq);
        }
                
        insert lstCQ;

        // create the apq
        List<Application_Qualification_Provided__c> lstAqp = new List<Application_Qualification_Provided__c>();
        for(Contact_Qualification__c contQual : lstCQ) {
            Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
            aqp.Contact_Qualification__c = contQual.Id;
            aqp.Application__c = app.Id;
            lstAqp.add(aqp);
        }
        
        insert lstAqp;

        //create contact document
        Contact_Document__c conDoc = new Contact_Document__c();
        conDoc.Contact__c = c.id;
        conDoc.Application__c = app.Id;
        conDoc.Document_Type__c = 'PARENT_GUARDIAN';
        conDoc.Filename__c = 'testdoc';
        insert conDoc;

    }
    /**
     * @author          Vishal Gupta
     * @description     for sending application data to callista 
     * @revision        14/10/2024 - Initial Version
     */
    @isTest static void testApplicationSendToCallistaJSONMapper() {
       
        //Given, GR application is submitted from my.app
        Application__c app = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        Application_Course_Preference__c acpInfo;
        GRApplicationJSON reqJson = new GRApplicationJSON();
        List<Contact> applicantData = new ContactsSelector().selectById(new Set<Id>{app.Applicant__c});
        List<Application__c> applicationData = new ApplicationsSelector().selectByIdWithParentDetailsAndDocuments(new Set<Id>{app.Id});
        List<Contact_Qualification__c> qualificationData = new ContactQualificationsSelector().selectQualificationsWithDocumentsByApplicationId(new Set<Id>{app.Id});
        Test.startTest();
        //when, we pass the Application data to GRApplicationJSONMapper
        if(!applicantData.isEmpty() && !applicationData.isEmpty()) {
            Contact contactInfo = applicantData[0];
            Application__c applicationInfo = applicationData[0];
            List<Application_Course_Preference__c> lstACP = new ApplicationCoursePreferenceSelector().selectByApplicationIdWithParentDetails(new Set<Id>{app.Id});
            if(!lstACP.isEmpty()) {
                acpInfo = lstACP[0];
            }
            GRApplicationJSON.Applicant grApplicant = new GRApplicationJSON.Applicant();
            grApplicant.smsContactId = applicationInfo.Callista_Student_Id__c;
            if(String.isBlank(contactInfo.Previous_Monash_ID__c)){
                grApplicant.previousMonashId = contactInfo.Previous_Monash_ID__c;
            }

            if(applicationInfo.Applied_For_Permanent_Residency__c) {
                //visa details
                grApplicant.visa = GRApplicationJSONMapper.getVisaInfo(applicationInfo);
            }
            //applicant additional details
            grApplicant.additionalDetails = GRApplicationJSONMapper.getApplicantAdditionalDetails(contactInfo);

            //qualification details
            grApplicant.qualifications = GRApplicationJSONMapper.getApplicantQualificationDetails(qualificationData);

            reqJson.applicant = grApplicant;

            GRApplicationJSON.Application grApplication = new GRApplicationJSON.Application();
            grApplication.smsApplicationId = applicationInfo.Callista_Application_Id__c;
            grApplication.applicationType = new GRApplicationJSON.ApplicationType('HDR');
            grApplication.hdrApplicationDetails = GRApplicationJSONMapper.getHDRApplicationDetails(applicationInfo, acpInfo);
            grapplication.courseDetail = GRApplicationJSONMapper.getCourseDetails(applicationInfo, acpInfo);
            reqJson.application = grApplication;                
        }
        
        Test.stopTest();
        //Then, the JSON Mapper should form the JSON structure need to be send to callista
        Assert.areNotEqual(NULL, reqJson, 'JSON Structure shoould be formed accordingly');
        Assert.areNotEqual(NULL, reqJson.applicant, 'applicant data should come under the json');
        Assert.areNotEqual(NULL, reqJson.application, 'application data should come under the json');
    }
    
}