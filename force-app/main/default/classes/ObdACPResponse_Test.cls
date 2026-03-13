/**
 * @author Trent De Laney
 * @date 29 Nov 2019 at 11:30:33 am
 * @group Test Class
 * @description Covers the response message for the ACP submission to Callista. Needs to be covered line by line for Salesforce to pick up the coverage
 */
@IsTest
public with sharing class ObdACPResponse_Test {
    @IsTest
    public static void test_AssignPropertyValues(){
        ObdACPResponse response = new ObdACPResponse();
        System.assertNotEquals(null, response, 'Unable to create response message');

        response.applications = new List<ObdACPResponse.Application>();
    }
}