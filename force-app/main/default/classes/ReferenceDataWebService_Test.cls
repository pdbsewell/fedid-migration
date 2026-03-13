@isTest(isParallel=false)
public with sharing class ReferenceDataWebService_Test {
    @TestSetup
    static void makeData(){
        AgentPortalServices_Test.makeData();
    }
    @isTest
    private static void residencyStatus_PositiveTest() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.params.put('requestType','residencystatus');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        User usr = [SELECT id FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        System.runAs(usr){
            ReferenceDataWebService.getReferenceData();
        }

        res = RestContext.response;
        System.assert(res.responseBody.toString().contains('DOM-AUS'), 'ReferenceData :: residencystatus failed' );
    }
    @isTest
    private static void residencyStatus_NegativeTest() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        // req.params.put('requestType','residencystatus');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        User usr = [SELECT id FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        System.runAs(usr){
            ReferenceDataWebService.getReferenceData();
        }

        res = RestContext.response;
        System.assert(res.responseBody.toString().contains('Request Type not set'), 'ReferenceData :: residencystatus validation failed' );
    }
}