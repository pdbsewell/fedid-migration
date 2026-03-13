/*******************************************************************************
* @author		Vishal Gupta
* @date         12/02/2025    
* @description  Test Class for GRScholarshipOfferResponseService Class
* @revision     12/02/2025 - Initial Version
*******************************************************************************/
@isTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on these type of objects - Opportunity, SBQQ__Quote__c*/
public class GRScholarshipOfferResponseService_Test {

    @TestSetup
    static void makeData() {
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
        insert coursePreference;

        Opportunity oppty = new Opportunity(Name = 'test', StageName = 'New Offer', CloseDate = date.today().addDays(3), Application_Course_Preference__c = coursePreference.Id,
                            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Graduate_Research_Offer').getRecordTypeId(), Research_Offer_Type__c = 'Scholarship Offer');
        insert oppty;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppty.Id);
        insert quote;

    }
    /**
     * @author          Vishal Gupta
     * @description     for sending scholarship response data to callista 
     * @revision        12/02/2025 - Initial Version
     */
    @isTest static void testApplicationSendToCallistaService() {
        
        GRScholarshipOfferResponseServiceMock mock = new GRScholarshipOfferResponseServiceMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        //Given, there is an scholarship offer for a GR application
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('quoteId', quote.Id);
        payload.put('applicationId', 'test');
        payload.put('applicantId', 'test');
        payload.put('offerStatus', 'test');
        Map<String, Object> asyncMap = new Map<String, Object>{'args' => payload};    
        //When, offer response is captured from my.app and send to callista
        GRScholarshipOfferResponseService applicationSendService = new  GRScholarshipOfferResponseService(
            JSON.serialize(asyncMap)
        );
        applicationSendService.createRequestBody();
        applicationSendService.sendMessage();
        applicationSendService.handleResponse();
        Test.stopTest();
        //Then, the API request, response should be updated in Quote
        SBQQ__Quote__c quoteAfterUpdate = [SELECT Id, API_Request__c, API_Response__c FROM SBQQ__Quote__c LIMIT 1];
        Assert.areNotEqual(NULL, quoteAfterUpdate.API_Request__c, 'API_Request__c should be populated');
    }
    
    /**
     * @author          Vishal Gupta
     * @description     for sending scholarship response data to callista via platform event
     * @revision        12/02/2025 - Initial Version
     */
    @isTest static void testApplicationSendToCallistaServiceASyncProcess() {
        
        GRScholarshipOfferResponseServiceMock mock = new GRScholarshipOfferResponseServiceMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        //Given, there is an scholarship offer for a GR application
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        AsyncProcessPayload payload = new AsyncProcessPayload();
        payload.put ('quoteId', quote.Id);
        payload.put('applicationId', 'test');
        payload.put('applicantId', 'test');
        payload.put('offerStatus', 'test');
        //When, offer response is captured from my.app and send to callista
        Async_Process__e evt = new Async_Process__e (
            Process_Name__c = 'GRScholarshipOfferResponseService.GRScholarshipOfferResponseServiceCallout',
            Parameter__c = payload.serialize()
        );
        EventBus.publish(evt);
        Test.stopTest();
        //When, offer response is captured from my.app and send to callista
        List<EventBusSubscriber> lstEvent = [SELECT Name, Position, Retries, LastError 
                                                FROM EventBusSubscriber 
                                                WHERE Topic='Async_Process__e' AND Type='ApexTrigger'
                                                ];
        //Then: the platform event should be triggerd
        Assert.areNotEqual(true, lstEvent.isEmpty(), 'Async process is fired to trigger the scholarship request');
    }

    /**
     * @author          Vishal Gupta
     * @description     for sending scholarship response data to callista via future method
     * @revision        12/02/2025 - Initial Version
     */
    @isTest static void testApplicationSendToCallistaServiceFutureCallout() {
        
        GRScholarshipOfferResponseServiceMock mock = new GRScholarshipOfferResponseServiceMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        //Given, there is an scholarship offer for a GR application
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('quoteId', quote.Id);
        payload.put('applicationId', 'test');
        payload.put('applicantId', 'test');
        payload.put('offerStatus', 'test');
        Map<String, Object> asyncMap = new Map<String, Object>{'args' => payload};    
        //When, offer response is captured from my.app and send to callista
        GRScholarshipOfferResponseService.scholarshipCallout(JSON.serialize(asyncMap));
        Test.stopTest();
        //Then, the API request, response should be updated in Quote
        SBQQ__Quote__c quoteAfterUpdate = [SELECT Id, API_Request__c, API_Response__c FROM SBQQ__Quote__c LIMIT 1];
        Assert.areNotEqual(NULL, quoteAfterUpdate.API_Request__c, 'API_Request__c should be populated');
    }
}