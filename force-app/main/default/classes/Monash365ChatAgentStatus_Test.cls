/***********************************************************************
** Author: Inderpal Dhanoa
** Created Date: 13.MAY.2023
** Description: Test class for REST API service for Agent Portal availability
***********************************************************************/
@isTest(isParallel=true)
public with sharing class Monash365ChatAgentStatus_Test {
    /*******************************************************************************
    * @description: Invoke the GetAgentAvailabilityByTopic method and assert
    *               the outcome of that method.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest static void testGetAgentAvailabilityByTopic() {
        //Initialize Variables
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
         
        //Setup endpoint
        req.requestURI = '/services/apexrest/v1/MonashChat365Agent?topic=scholarships';
         
        //Setup action
        req.httpMethod = 'GET';
         
        //Setup callout
        RestContext.request = req;
        RestContext.response = res;

        // GIVEN: WHEN the endpoint is Setup
        Test.startTest();
        // THEN: WHEN the callout is made
        Monash365ChatAgentStatus.getAgentAvailabilityByTopic();
        Test.stopTest();

        //THEN: The response is validated
        Blob responseJSON = res.responseBody;

        //Test response
        System.assertEquals('False', responseJSON.toString());
    }
}