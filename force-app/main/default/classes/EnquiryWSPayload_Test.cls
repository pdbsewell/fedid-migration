/**
 * @author      Inderpal Dhanoa
 * @description Test Class for EnquiryWSPayload
 * @group       Test Class
 * @revision    2024-05-09 - Inderpal Dhanoa - Created
 **/
@isTest(isParallel=true)
public class EnquiryWSPayload_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         2024-05-09
    * @description  Test getRequest
    *******************************************************************************/
    @isTest
    static void getRequest_Test() {
        // Given: the object is created
        EnquiryWSPayload.GetRequest processReqObj = new EnquiryWSPayload.GetRequest();
        EnquiryWSPayload.CDM_Enquiry objCDMEnquiry = new EnquiryWSPayload.CDM_Enquiry();
        EnquiryWSPayload.CDM_Value objCDMValRef = new EnquiryWSPayload.CDM_Value();
        objCDMValRef.id = '123456789';
        EnquiryWSPayload.CDM_Reference objCDMRefRef = new EnquiryWSPayload.CDM_Reference();
        objCDMRefRef.key = 'reference_sapstaffid';
        objCDMRefRef.value = new List<EnquiryWSPayload.CDM_Value>{objCDMValRef};
        objCDMEnquiry.operationName = 'Test operationName';
        objCDMEnquiry.categoryLevel1 = 'Test categoryLevel1';
        objCDMEnquiry.categoryLevel2 = 'Test categoryLevel2';
        objCDMEnquiry.subject = 'Test subject';
        objCDMEnquiry.content = 'Test content';
        objCDMEnquiry.origin = 'Test origin';
        objCDMEnquiry.recordtypeDeveloperName = 'Standard';
        objCDMEnquiry.type = 'Test ENq Type';
        objCDMEnquiry.references = new List<EnquiryWSPayload.CDM_Reference> {objCDMRefRef};    
        
        
        Test.startTest();
         // When: the method is accessed
         processReqObj.enquiry = objCDMEnquiry;
        Test.stopTest();
        // Then: A Payload sub class is accessed 
        Assert.areEqual(processReqObj.enquiry.categoryLevel1, 'Test categoryLevel1'); 
        
    }
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         2024-05-09
    * @description  Test getResponse
    *******************************************************************************/
    @isTest
    static void getResponse_Test() {
        // Given: the object is created
        EnquiryWSPayload.GetResponse processRespObj = new EnquiryWSPayload.GetResponse();
        processRespObj.responseType = 'VerifyMe';
        
        Test.startTest();
         // When: the method is accessed
         processRespObj.outcome = 'Success';
        Test.stopTest();
        // Then: A Payload sub class is accessed
        Assert.areEqual(processRespObj.responseType, 'VerifyMe', 'Response creation fails');
        
    }
}