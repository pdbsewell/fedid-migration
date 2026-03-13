@IsTest(isParallel=true)
public class CallistaNotesController_Test {
    @testSetup
    static void setup() {
        Account facultyAccount = AssessmentsTestDataFactory.createFacultyAccount();
        insert facultyAccount;

        Contact applicant = AssessmentsTestDataFactory.createApplicant();
        insert applicant;

        Application__c application = AssessmentsTestDataFactory.createDomesticApplication('CAID-1239090', applicant.Id);
        insert application;

        Course__c masterOfSocialWork = AssessmentsTestDataFactory.createCourse(
            facultyAccount,
            'Faculty of Medicine, Nursing and Health Sciences'
        );
        insert masterOfSocialWork;

        Application_Course_Preference__c acp = AssessmentsTestDataFactory.createACP(
            application.Id,
            masterOfSocialWork.Id,
            'AUSAID-PG',
            'CLAYTON',
            'IN',
            'M6012',
            '1'
        );
        acp.Applicant__c = applicant.Id;
        insert acp;
        
        // Create Task for ACP
        RecordType taskrecType=[Select id from RecordType where SObjectType='Task' AND DeveloperName = 'Admissions'];
        Task tsk=new Task();
        tsk.Status ='In progress';
        tsk.RecordTypeId=taskrecType.Id;
        tsk.WhatId=acp.Id;
        tsk.Type='Genuine Temporary Entrant';
        tsk.Application_Course_Preference__c = acp.id;       
        insert tsk; 
    }

    /**
     * @description Test fetching notes from Callista for Contact
     */
    @IsTest
    static void testGetNotesForContact() {
        String mockResponse = '{"notes": [{"noteType": "CENTRAL", "text": "Test note", "updateOn": "2024-11-21T11:31:53"}]}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        // GIVEN : an applicant
        Contact con = [SELECT Id, Person_Id__c, Person_ID_unique__c FROM Contact];

        Test.startTest();
        // WHEN : Callista Notes controller is called with contact Id
        CallistaNotesController.CallistaNotesDataProvider dataProvider = new CallistaNotesController.CallistaNotesDataProvider();
        List<ApexRelatedListController.Record> notes = dataProvider.getRecords(con.Id);
        Test.stopTest();

        // THEN: note from Callista should be returned
        Assert.areEqual(1, notes.size(), 'There should be 1 note.');
        Assert.areEqual('Test note', notes[0].values[0].value, 'Note text should match.');
    }

    /**
     * @description Test fetching notes from Callista for ACP
     */
    @IsTest
    static void testGetNotesForACP() {
        // GIVEN : an ACP
        Application_Course_Preference__c acp = [
            SELECT Id, Applicant__r.Person_Id__c
            FROM Application_Course_Preference__c
            LIMIT 1
        ];

        acp.Callista_Unique_Key_ADM__c = '33072043-1-S6005-2';
        update acp;

        // mock API Responses
        String mockResponsePerson =
            '{' +
            '"notes": [{' +
            '"type": "personNote",' +
            '"admissionApplicationId": null,' +
            '"noteType": "AUTHINFO",' +
            '"typeDescription": "STUDENT AUTHORISED CONTACT FOR RELEASE OF INFORMATION",' +
            '"updateBy": "JPAD0005",' +
            '"updateOn": "2024-11-25T11:31:53",' +
            '"text": "AUTHINFO Test",' +
            '"portalApplicationID": null' +
            '}]' +
            '}';
        String mockResponseACAI =
            '{' +
            '"acaiNotes": [{' +
            '"type": "acaiNote",' +
            '"admissionApplicationId": "33072043-1-S6005-2",' +
            '"noteType": "SCHOLARSHP",' +
            '"typeDescription": "APPLICATION COURSE NOTE",' +
            '"updateBy": "JPAD0005",' +
            '"updateOn": "2024-11-21T11:54:14",' +
            '"text": "Deferral form received for the Grad Cert Business Law (09/06/06).",' +
            '"portalApplicationID": "1297856-S6005-2"' +
            '}]' +
            '}';

        AssessmentsTestHelper.MultiMockHttpResGenerator multiMock = new AssessmentsTestHelper.MultiMockHttpResGenerator();
        String endpointBase = 'callout:SMSServices_Mix_API/la/student-services/v2/students/';
        multiMock.addRequestMock(
            endpointBase + acp.Applicant__r.Person_Id__c + '/personNotes',
            new AssessmentsTestHelper.MockHttpResGenerator(mockResponsePerson, 200)
        );
        multiMock.addRequestMock(
            endpointBase + acp.Applicant__r.Person_Id__c + '/acaiNotes',
            new AssessmentsTestHelper.MockHttpResGenerator(mockResponseACAI, 200)
        );

        Test.setMock(HttpCalloutMock.class, multiMock);

        Test.startTest();
        // WHEN : Callista Notes controller is called with acp Id
        CallistaNotesController.CallistaNotesDataProvider dataProvider = new CallistaNotesController.CallistaNotesDataProvider();
        List<ApexRelatedListController.Record> notes = dataProvider.getRecords(acp.Id);
        Test.stopTest();

        // THEN: person note is returned
        Assert.areEqual(2, notes.size());
        Assert.areEqual('AUTHINFO', notes[0].title);
        Assert.areEqual('AUTHINFO Test', notes[0].values[0].value);
        // THEN: acai note is returned
        Assert.areEqual('SCHOLARSHP', notes[1].title);
        Assert.areEqual(
            'Deferral form received for the Grad Cert Business Law (09/06/06).',
            notes[1].values[0].value
        );
    }
    
    /**
     * @description Test fetching notes from Callista for ACP
     */
    @IsTest
    static void testGetNotesForACPFromTask() {
        // GIVEN : an ACP
        Application_Course_Preference__c acp = [
            SELECT Id, Applicant__r.Person_Id__c
            FROM Application_Course_Preference__c
            LIMIT 1
        ];

        acp.Callista_Unique_Key_ADM__c = '33072043-1-S6005-2';
        update acp;
        
        Task tsk = [
            SELECT Id, Application_Course_Preference__r.Applicant__r.Person_Id__c
            FROM Task
            LIMIT 1
        ];


        // mock API Responses
        String mockResponsePerson =
            '{' +
            '"notes": [{' +
            '"type": "personNote",' +
            '"admissionApplicationId": null,' +
            '"noteType": "AUTHINFO",' +
            '"typeDescription": "STUDENT AUTHORISED CONTACT FOR RELEASE OF INFORMATION",' +
            '"updateBy": "JPAD0005",' +
            '"updateOn": "2024-11-25T11:31:53",' +
            '"text": "AUTHINFO Test",' +
            '"portalApplicationID": null' +
            '}]' +
            '}';
        String mockResponseACAI =
            '{' +
            '"acaiNotes": [{' +
            '"type": "acaiNote",' +
            '"admissionApplicationId": "33072043-1-S6005-2",' +
            '"noteType": "SCHOLARSHP",' +
            '"typeDescription": "APPLICATION COURSE NOTE",' +
            '"updateBy": "JPAD0005",' +
            '"updateOn": "2024-11-21T11:54:14",' +
            '"text": "Deferral form received for the Grad Cert Business Law (09/06/06).",' +
            '"portalApplicationID": "1297856-S6005-2"' +
            '}]' +
            '}';

        AssessmentsTestHelper.MultiMockHttpResGenerator multiMock = new AssessmentsTestHelper.MultiMockHttpResGenerator();
        String endpointBase = 'callout:SMSServices_Mix_API/la/student-services/v2/students/';
        multiMock.addRequestMock(
            endpointBase + tsk.Application_Course_Preference__r.Applicant__r.Person_Id__c + '/personNotes',
            new AssessmentsTestHelper.MockHttpResGenerator(mockResponsePerson, 200)
        );
        multiMock.addRequestMock(
            endpointBase + tsk.Application_Course_Preference__r.Applicant__r.Person_Id__c + '/acaiNotes',
            new AssessmentsTestHelper.MockHttpResGenerator(mockResponseACAI, 200)
        );

        Test.setMock(HttpCalloutMock.class, multiMock);

        Test.startTest();
        // WHEN : Callista Notes controller is called with acp Id
        CallistaNotesController.CallistaNotesDataProvider dataProvider = new CallistaNotesController.CallistaNotesDataProvider();
        List<ApexRelatedListController.Record> notes = dataProvider.getRecords(tsk.Id);
        Test.stopTest();

        // THEN: person note is returned
        Assert.areEqual(2, notes.size());
        Assert.areEqual('AUTHINFO', notes[0].title);
        Assert.areEqual('AUTHINFO Test', notes[0].values[0].value);
        // THEN: acai note is returned
        Assert.areEqual('SCHOLARSHP', notes[1].title);
        Assert.areEqual(
            'Deferral form received for the Grad Cert Business Law (09/06/06).',
            notes[1].values[0].value
        );
    }


    /**
     * @description Test exception for fetching notes from Callista 
     *              for Contact
     */
    @IsTest
    static void testGetNotesForContactException() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        con.Person_ID_unique__c = null;
        update con;

        Test.startTest();
        try {
            CallistaNotesController.CallistaNotesDataProvider dataProvider = new CallistaNotesController.CallistaNotesDataProvider();
            dataProvider.getRecords(con.Id);
        } catch (Exception ex) {
            Assert.areEqual('Callista Person Id not found', ex.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Test exception for fetching notes from Callista
     *              for ACP
     */
    @IsTest
    static void testGetNotesForACPException() {
        Application_Course_Preference__c acp = [
            SELECT Id, Applicant__r.Person_ID_unique__c
            FROM Application_Course_Preference__c
            LIMIT 1
        ];
        acp.Applicant__r.Person_ID_unique__c = null;
        update acp.Applicant__r;

        Test.startTest();
        try {
            CallistaNotesController.CallistaNotesDataProvider dataProvider = new CallistaNotesController.CallistaNotesDataProvider();
            dataProvider.getRecords(acp.Id);
        } catch (Exception ex) {
            Assert.areEqual('Callista Person Id not found', ex.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Test no notes from Callista for Contact
     */
    @IsTest
    static void testGetNotesForContactNoRecords() {
        String mockResponse = '{"notes": []}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        try {
            CallistaNotesController.CallistaNotesDataProvider dataProvider = new CallistaNotesController.CallistaNotesDataProvider();
            dataProvider.getRecords(con.Id);
        } catch (Exception ex) {
            Assert.areEqual('No previous assessment notes available', ex.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Test no notes from Callista for ACP
     */
    @IsTest
    static void testGetNotesForACPNoRecords() {
        // GIVEN : an ACP
        Application_Course_Preference__c acp = [
            SELECT Id, Applicant__r.Person_Id__c
            FROM Application_Course_Preference__c
            LIMIT 1
        ];

        acp.Callista_Unique_Key_ADM__c = '33072043-1-S6005-2';
        update acp;

        // mock API Responses
        String mockResponsePerson = '{"notes": []}' ;
        String mockResponseACAI = '{"acaiNotes": []}' ;

        AssessmentsTestHelper.MultiMockHttpResGenerator multiMock = new AssessmentsTestHelper.MultiMockHttpResGenerator();
        String endpointBase = 'callout:SMSServices_Mix_API/la/student-services/v2/students/';
        multiMock.addRequestMock(
            endpointBase + acp.Applicant__r.Person_Id__c + '/personNotes',
            new AssessmentsTestHelper.MockHttpResGenerator(mockResponsePerson, 200)
        );
        multiMock.addRequestMock(
            endpointBase + acp.Applicant__r.Person_Id__c + '/acaiNotes',
            new AssessmentsTestHelper.MockHttpResGenerator(mockResponseACAI, 200)
        );

        Test.setMock(HttpCalloutMock.class, multiMock);


        Test.startTest();
        try {
            CallistaNotesController.CallistaNotesDataProvider dataProvider = new CallistaNotesController.CallistaNotesDataProvider();
            dataProvider.getRecords(acp.Id);
        } catch (Exception ex) {
            Assert.areEqual('No previous assessment notes available', ex.getMessage());
        }
        Test.stopTest();
    }
}