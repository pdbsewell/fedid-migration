/**
* @description       : Test Class -  CourseDisconCalloutService_Test
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* Modifications Log
* Ver   Date         Author          Modification
* 1.0   2022-06-28 - Rajesh Punjabi  - Initial Creation
* 1.1   2025-02-25 - Matthew Maramot - EPCP-4204 Updated API version + Assert methods
**/

@isTest
public class CourseDisconCalloutService_Test {
/**
* @description Testing call out request
* @author rajesh.punjabi@monash.edu | 07-06-2022 
**/
    @isTest
    public static void sendCalloutTest(){
        //Create MIX_RPA_Settings
        MonConTestDataFactory.createSObject(new MIX_RPA_Settings__c(), true);

        //GIVEN: We have a callout ready to be sent
        String json = '{'+
            '   \"itemData\": {'+
            '       \"Name\" : \"DMC.CourseDiscontinuation\",'+
            '       \"SpecificContent\" : {'+
            '           \"uniCRMCaseID\" : \"5004a000007kND99vvM\",'+
            '	    \"uniCRMEnquiryNo\" : \"07734353\",'+
            '           \"personID\" : \"32437110\",'+
            '           \"CourseCode\" : \"A200\",'+
            '  \"DiscontinDate\" : \"12/03/2022\",'+
            ' \"DiscontinReason\" : \"46\",'+
            '  \"SubmissionDate\" : \"12/03/2022\",'+
            '              \"MonashConnectOfficerName\" : \"John Thomas\"'+
            '       },'+
            '       \"Reference\" : \"5004a000007kND99vvM\" '+
            '   }'+
            '}';
        
        //WHEN: the callout is made to MIX
        Test.startTest();
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                               'Complete',
                                                               '{\n' +
                                                               '  "queueDefinitionId": 625,\n' +
                                                               '  "referenceKey": "57ae5735-449c-4c08-bd96-9aa7b050a327",\n' +
                                                               '  "referenceId": "20202020-D6000",\n' +
                                                               '  "message": "Request submitted."\n' +
                                                               '}',
                                                               null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        String response = CourseDisconCalloutService.sendCallout(json);
        Test.stopTest();

        //THEN: A successful response is received
        Assert.areEqual('Approved course discontinuation request sent to Callista for processing.', response);
    }

/**
* @description Testing call out request - failed
* @author rajesh.punjabi@monash.edu | 07-06-2022 
**/
    @isTest
    public static void sendCalloutFailedTest(){
        //Create MIX_RPA_Settings
        MonConTestDataFactory.createSObject(new MIX_RPA_Settings__c(), true);

        //GIVEN: We have a callout ready to be sent
        String json = '{'+
            '   \"itemData\": {'+
            '       \"Name\" : \"DMC.CourseDiscontinuation\",'+
            '       \"SpecificContent\" : {'+
            '           \"uniCRMCaseID\" : \"5004a000007kND99vvM\",'+
            '	    \"uniCRMEnquiryNo\" : \"07734353\",'+
            '           \"personID\" : \"32437110\",'+
            '           \"CourseCode\" : \"A200\",'+
            '  \"DiscontinDate\" : \"12/03/2022\",'+
            ' \"DiscontinReason\" : \"46\",'+
            '  \"SubmissionDate\" : \"12/03/2022\",'+
            '              \"MonashConnectOfficerName\" : \"John Thomas\"'+
            '       },'+
            '       \"Reference\" : \"5004a000007kND99vvM\" '+
            '   }'+
            '}';
        
        //WHEN: the callout is made to MIX
        Test.startTest();
        SingleRequestMock fakeResponse = new SingleRequestMock(400,
                                                               'Failed',
                                                               '{\n' +
                                                               '  "queueDefinitionId": 625,\n' +
                                                               '  "referenceKey": "57ae5735-449c-4c08-bd96-9aa7b050a327",\n' +
                                                               '  "referenceId": "20202020-D6000",\n' +
                                                               '  "message": "Request submitted."\n' +
                                                               '}',
                                                               null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        String response = CourseDisconCalloutService.sendCallout(json);
        Test.stopTest();

        //THEN: A failed response is received
        Assert.areEqual('Request Failed.', response);
    }
}