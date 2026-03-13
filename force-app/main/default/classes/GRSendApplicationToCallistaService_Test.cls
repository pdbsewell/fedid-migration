/*******************************************************************************
* @author		Vishal Gupta
* @date         14/10/2024    
* @description  Test Class for GRSendApplicationToCallista Class
* @revision     14/10/2024 - Initial Version
*******************************************************************************/
@isTest(isParallel = true)
public class GRSendApplicationToCallistaService_Test {

    @TestSetup
    static void makeData() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        c.Person_ID_unique__c = '234324324';
        update c;
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

        //create Application_Course_Preference__c
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        coursePreference.Academic_Org_Unit__c = testAcademicOrg.Id;
        coursePreference.Employment_Days__c = 'Mon;Tue';
        coursePreference.Employment_Hours__c = 20;
        insert coursePreference;

        Country_Attribute__c ca = new Country_Attribute__c(Name = 'AUSTRALIA');
        insert ca;

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
    @isTest static void testApplicationSendToCallistaService() {
        
        GRSendApplicationToCallistaAPIMock mock = new GRSendApplicationToCallistaAPIMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        //Given, GR application is submitted from my.app
        Application__c app = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        Test.startTest();
        //When, the application is sent to callista
        GRSendApplicationToCallistaService applicationSendService = new GRSendApplicationToCallistaService(
            app.Id,
            app.Applicant__c
        );
        applicationSendService.createRequestBody();
        applicationSendService.sendMessage();
        applicationSendService.handleResponse();
        Test.stopTest();
        //Then, the API request, response and HDR Application Id should be updated in Application course preference
        Application_Course_Preference__c acp = [SELECT Last_sync_date_time__c FROM Application_Course_Preference__c LIMIT 1];
        Assert.areNotEqual(NULL, acp.Last_sync_date_time__c, 'Last_sync_date_time__c should be populated');
    }
    
}