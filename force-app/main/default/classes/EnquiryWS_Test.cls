/**
 * @author      Inderpal Dhanoa
 * @description Test Class for EnquiryWS
 * @group       Test Class
 * @revision    2024-05-09 - Inderpal Dhanoa - Created
 **/
@isTest(isParallel=true)
public class EnquiryWS_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         2024-05-09
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {
        Contact cont = (Contact)TestDataFactory.createSObject(new Contact(Salutation = 'Mr',FirstName = 'First',LastName = 'Last',
                                                                            Email = 'test@test.com',
                                                                            Person_ID_unique__c = '123456789'), true);
    }
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         2024-05-09
    * @description  Test method for handleEnquiry
    *******************************************************************************/
    @isTest
    static void handleEnquiry_Test() {
        //Initialize Variables
        EnquiryWSPayload.GetRequest processReqObj = new EnquiryWSPayload.GetRequest();
        EnquiryWSPayload.CDM_Enquiry objCDMEnquiry = new EnquiryWSPayload.CDM_Enquiry();
        EnquiryWSPayload.CDM_Value objCDMValRef = new EnquiryWSPayload.CDM_Value();
        objCDMValRef.id = '123456789';
        EnquiryWSPayload.CDM_Value objCDMValName = new EnquiryWSPayload.CDM_Value();
        objCDMValName.id = 'Nisha';
        EnquiryWSPayload.CDM_Value objCDMValEmail = new EnquiryWSPayload.CDM_Value();
        objCDMValEmail.id = 'email@monash.edu';
        EnquiryWSPayload.CDM_Value objCDMValLink = new EnquiryWSPayload.CDM_Value();
        objCDMValLink.id = 'https://sydney.idscan.cloud/idscanapp';
        EnquiryWSPayload.CDM_Reference objCDMRefRef = new EnquiryWSPayload.CDM_Reference();
        objCDMRefRef.key = 'reference_personid';
        objCDMRefRef.value = new List<EnquiryWSPayload.CDM_Value>{objCDMValRef};
        EnquiryWSPayload.CDM_Reference objCDMRefName = new EnquiryWSPayload.CDM_Reference();
        objCDMRefName.key = 'Name';
        objCDMRefName.value = new List<EnquiryWSPayload.CDM_Value>{objCDMValName};
        EnquiryWSPayload.CDM_Reference objCDMRefEmail = new EnquiryWSPayload.CDM_Reference();
        objCDMRefEmail.key = 'Email';
        objCDMRefEmail.value = new List<EnquiryWSPayload.CDM_Value>{objCDMValEmail};
        EnquiryWSPayload.CDM_Reference objCDMRefLink = new EnquiryWSPayload.CDM_Reference();
        objCDMRefLink.key = 'Journey_Reference_Number';
        objCDMRefLink.value = new List<EnquiryWSPayload.CDM_Value>{objCDMValLink};
        objCDMEnquiry.operationName = 'VerifyMe';
        objCDMEnquiry.categoryLevel1 = 'Test categoryLevel1';
        objCDMEnquiry.categoryLevel2 = 'Test categoryLevel2';
        objCDMEnquiry.subject = 'Test subject';
        objCDMEnquiry.content = 'Test content';
        objCDMEnquiry.origin = 'Test origin';
        objCDMEnquiry.recordtypeDeveloperName = 'Standard';
        objCDMEnquiry.Type = 'Test ENq Type';
        objCDMEnquiry.references = new List<EnquiryWSPayload.CDM_Reference> {objCDMRefRef, objCDMRefName, objCDMRefEmail, objCDMRefLink};
        processReqObj.enquiry = objCDMEnquiry;
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
 
        //Setup endpoint
        req.requestURI = '/services/apexrest/v2/EnquiryWS';
        
        //Setup action
        req.httpMethod = 'POST';
        //Set Payload
        req.requestBody = Blob.valueOf(JSON.serialize(processReqObj));
        
        //Setup callout
        RestContext.request = req;
        RestContext.response = res;
        // Given: Payload is invoked
        Test.setMock(HttpCalloutMock.class, new EnquiryWS_Test.EnquiryWSResMock());
        // When: method is invoked
        Test.startTest();
            EnquiryWS.handleEnquiry();
        Test.stopTest();
        // Then: ENquiry is created
        List<Case> l_enq = [SELECT Id FROM Case WHERE COntact.Person_ID_unique__c = '123456789'];
        Assert.areEqual(1, l_enq.size(), 'Verify Me Enquiry not created');
    }
        /**
     * @author                      Inderpal Dhanoa
     * @created                     2024-05-09
     * @description                 Test Mock for EnquiryWS
     */
    public class EnquiryWSResMock implements HttpCalloutMock {
        /**
         * @author                      Inderpal Dhanoa
         * @created                     2024-05-09
         * @description                 Test Response when EnquiryWS has been called
         */
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"success":true,"responseType":"VerifyMe","outcome":"Success"}');
            response.setStatusCode(200);
            return response;
        }
    }
}