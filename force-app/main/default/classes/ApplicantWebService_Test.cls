@isTest(isParallel=true)
public with sharing class ApplicantWebService_Test {
    @TestSetup
    static void makeData(){
        AgentPortalServices_Test.makeData();
    }
    @isTest
    private static void testHandleCreateApplicant_Positive() {
        String reqBody = '{ "applicant" : { "lastName": "Chirunga", "firstName": "Anesu", "hasMononymousName": false, "previousMonashId": "", "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "1996-10-09", "email": [ { "type": "Personal", "email": "andrew@mail.com" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ] } }';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
            ApplicantWebService.handleCreateApplicant();
        Test.stopTest();
        Assert.isFalse([SELECT id FROM Contact WHERE LastName = 'Chirunga']?.isEmpty(), 'Create Applicant failed' );
    }
    @isTest
    private static void testHandleCreateApplicant_Negative() {
        String reqBody = '{ "applicant" : { "lastName": "", "firstName": "Anesu", "hasMononymousName": false, "previousMonashId": "", "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "1996-10-09", "email": [ { "type": "Personal", "email": "andrew@mail.com" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ] } }';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
            ApplicantWebService.handleCreateApplicant();
        Test.stopTest();

        res = RestContext.response;
        Assert.isTrue(res.responseBody.toString().contains(AgentPortalConstants.ERROR_MSG_PREFIX), 'Create Applicant Negative scenario failed' );
    }
    @isTest(seeAllData = false)
    private static void testhandleGetApplicantDetails_Positive() {
        Contact con = new Contact(Last_name__c = 'Chirunga', First_Name__c = 'Anesu', Birthdate =  Date.valueOf('1996-10-09'), personal_email__c = 'anesu.chiranga@getnada.com', mobilePhone = '123456788');

        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        Test.startTest();
        System.runAs(u) {
            con = AgentPortalServices.createApplicant(con, UserInfo.getUserId());
            req.params.put('crmContactId', con.crm_id__c);
            ApplicantWebService.handleGetApplicantDetails();
        }
        Test.stopTest();

        res = RestContext.response;
        Assert.isTrue(res.responseBody.toString().contains(con.crm_id__c), 'Get Applicant Details by ContactID failed' );
    }
    @isTest
    private static void testhandleGetApplicantDetails_Negative() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.params.put('crmContactId', 'crmid');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
            ApplicantWebService.handleGetApplicantDetails();
        Test.stopTest();

        res = RestContext.response;
        Assert.isTrue(res.responseBody.toString().contains('No applicant found'), 'Get Applicant Details by ContactID - Negative scenario failed' );
    }
    @isTest
    private static void testHandleUpdateApplicant_Positive() {
        Contact applicantOne = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Applicant', Personal_email__c = 'test456@getnad.com', BirthDate = Date.valueOf('2002-02-01'));
        insert applicantOne;
        String reqBody = '{ "lastName": "Chirunga", "firstName": "Anesu", "hasMononymousName": false, "contactId": "' + applicantOne.id + '", "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "1996-10-09", "email": [ { "type": "Personal", "email": "andrew@mail.com" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ], "address" : [ { "type" : "Postal", "street" : "12 mansfield place", "city" : "mansfield", "state" : "QLD", "country" : "Australia", "postalCode" : "4155" }, { "type" : "Other", "street" : "12 mansfield place", "city" : "mansfield", "state" : "QLD", "country" : "Australia", "postalCode" : "4155" } ] }';

        RestRequest req = new RestRequest();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        User usr = [SELECT id, Username, ContactId, contact.AccountId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        Application__c appPositive = new Application__c (Applicant__c = applicantOne.id, Agent__c = usr.Contact.AccountId, Status__c =  'Draft', Source_System__c = 'AgentPortal', Residency_Status__c = 'INTRNTNL');
        System.runAs(usr){
            appPositive = (Application__c) AgentPortalServices.createApplication(appPositive, '123@abc.com', '345');
            ApplicantWebService.handleUpdateApplicant();
        }
        Test.stopTest();
        Assert.isFalse([SELECT id FROM Contact WHERE Last_Name__c = 'Chirunga']?.isEmpty(), 'Update Applicant failed' );
    }
    @isTest
    private static void testHandleUpdateApplicant_Negative() {
        Contact applicantOne = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Applicant', Personal_email__c = 'test456@getnad.com', BirthDate = Date.valueOf('2002-02-01'));
        insert applicantOne;
        String reqBody = '{ "lastName": "", "firstName": "Anesu", "hasMononymousName": false, "previousMonashId": "", "isPreviousMonashStudent": false, "previousName": "", "dateOfBirth": "1996-10-09", "email": [ { "type": "Personal", "email": "andrew@mail.com" } ], "phone": [ { "type": "Mobile", "phoneNumber": "0430724282" }, { "type": "Home", "phoneNumber": "0312345670" } ], "address" : [ { "type" : "Postal", "street" : "12 mansfield place", "city" : "mansfield", "state" : "QLD", "country" : "Australia", "postalCode" : "4155" }, { "type" : "Other", "street" : "12 mansfield place", "city" : "mansfield", "state" : "QLD", "country" : "Australia", "postalCode" : "4155" } ] } ';

        RestRequest req = new RestRequest();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
            ApplicantWebService.handleUpdateApplicant();
        Test.stopTest();

        res = RestContext.response;
        Assert.isTrue(res.responseBody.toString().contains(AgentPortalConstants.ERROR_MSG_PREFIX), 'Update Applicant Negative scenario failed' );
    }
    @isTest
    private static void testHandleSearchApplicants() {
        Contact con = new Contact(Last_name__c = 'Chirunga', First_Name__c = 'Anesu', Birthdate =  Date.valueOf('1996-10-09'), Personal_email__c = 'anesu.chiranga@getnada.com', MobilePhone = '123456789');

        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.params.put('applicantName', 'Ane');
        req.params.put('pageSize', '10');
        req.params.put('pageOffset', '0');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        Test.startTest();
        System.runAs(u) {
            AgentPortalServices.createApplicant(con, UserInfo.getUserId());
            ApplicantWebService.handleGetApplicantDetails();
        }
        Test.stopTest();

        res = RestContext.response;
        Assert.isTrue(res.responseBody.toString().contains('Chirunga'), 'Search Applicants - failed' );
    }
}