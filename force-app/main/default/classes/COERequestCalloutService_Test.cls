/**
* @description       : Test Class -  COERequestCalloutService_Test
* @author            : seeva.singh@monash.edu
* @group             : 
* Modifications Log
* Ver   Date         Author          Modification
* 1.0   2023-03-04 - Seeva Singh     - Initial Creation
* 1.1   2025-02-25 - Matthew Maramot - EPCP-4204 Updated API version + Assert methods
**/
@IsTest(IsParallel=true)
public class COERequestCalloutService_Test {
/**
* @description Testing call out request
* @author seeva.singh@monash.edu | 04-03-2023 
**/
    @isTest
    public static void sendCalloutTest(){

        //Create MIX_RPA_Settings
        MonConTestDataFactory.createSObject(new MIX_RPA_Settings__c(), true);
        
        //GIVEN: We have a callout ready to be sent
        String json = '{'+
            '   \"itemData\": {'+
            '       \"Name\" : \"DMC.COE.PrePrismProcessQueue\",'+
            '       \"SpecificContent\" : {'+
            '           \"uniCRMCaseID\" : \"5003000000D8cuIQAA\",'+
            '	    \"uniCRMEnquiryID \" : \"73233344\",'+
            '           \"personID\" : \"32437110\",'+
            '           \"CoEReason\" : \"TRANSFER\",'+
            '              \"monashConnectOfficerEmail\" : \"agent@monash.edu\"'+
            ' \"DiscontinCourseCode\" : \"0079\",'+
            '       },'+
            '       \"Reference\" : \"5003000000D8cuIQAA\" '+
            '   }'+
            '}';
        
        //WHEN: the callout is made to MIX
        Test.startTest();
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                               'Complete',
                                                               '{\n' +
                                                               '  "queueDefinitionId": 625,\n' +
                                                               '  "referenceKey": "57ae5735-449c-4c08-bd96-9aa7b050a327",\n' +
                                                               '  "referenceId": "20202020D6000",\n' +
                                                               '  "message": "Request submitted."\n' +
                                                               '}',
                                                               null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        String response = COERequestCalloutService.sendCallout(json);
        Test.stopTest();

        //THEN: A successful response is received
        Assert.areEqual('COE request sent to Callista for processing.', response);
    }

/**
* @description Testing call out request - failed
* @author seeva.singh@monash.edu | 04-03-2023 
**/
    @isTest
    public static void sendCalloutFailedTest(){
        //Create MIX_RPA_Settings
        MonConTestDataFactory.createSObject(new MIX_RPA_Settings__c(), true);
        
        //GIVEN: We have a callout ready to be sent
        String json = '{'+
            '   \"itemData\": {'+
            '       \"Name\" : \"DMC.COE.PrePrismProcessQueue\",'+
            '       \"SpecificContent\" : {'+
            '           \"uniCRMCaseID\" : \"5003000000D8cuIQAA\",'+
            '	    \"uniCRMEnquiryID \" : \"73233344\",'+
            '           \"personID\" : \"32437110\",'+
            '           \"CoEReason\" : \"TRANSFER\",'+
            '              \"monashConnectOfficerEmail\" : \"agent@monash.edu\"'+
            ' \"DiscontinCourseCode\" : \"0079\",'+
            '       },'+
            '       \"Reference\" : \"5003000000D8cuIQAA\" '+
            '   }'+
            '}';
        
        //WHEN: the callout is made to MIX
        Test.startTest();
        SingleRequestMock fakeResponse = new SingleRequestMock(400,
                                                               'Failed',
                                                               '{\n' +
                                                               '  "queueDefinitionId": 1147,\n' +
                                                               '  "referenceKey": "7b2cc06e-2d84-4ef3-b57c-5886e3630fae",\n' +
                                                               '  "referenceId": "5003000000D8cuIQAA",\n' +
                                                               '  "message": "Request submitted."\n' +
                                                               '}',
                                                               null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        String response = COERequestCalloutService.sendCallout(json);
        Test.stopTest();

        //THEN: A failed response is received
        Assert.areEqual('Request Failed.', response);
    }
}