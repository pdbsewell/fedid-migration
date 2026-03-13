/**
 * @author      Inderpal Dhanoa
 * @description Test Class for EnquiryWS
 * @group       Test Class
 * @revision    2024-05-09 - Inderpal Dhanoa - Created
 * 1.1          2024-08-09 - Inderpal Dhanoa - MCT-482
 **/
@isTest(isParallel=true)
public class EnquiryWSImpl_Test {
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
    * @description  Test method for processVerifyMeEnquiry
    *******************************************************************************/
    @isTest
    static void processVerifyMeEnquiryTest() {
        // Given: the Reuqest exists
        EnquiryWSPayload.GetResponse processRespObj = new EnquiryWSPayload.GetResponse();
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
        EnquiryWSPayload.CDM_Value objCDMValReason = new EnquiryWSPayload.CDM_Value();
        objCDMValReason.id = 'Test Reason';

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

        EnquiryWSPayload.CDM_Reference objCDMRefReason = new EnquiryWSPayload.CDM_Reference();
        objCDMRefReason.key = 'Reason';
        objCDMRefReason.value = new List<EnquiryWSPayload.CDM_Value>{objCDMValReason};

        objCDMEnquiry.operationName = 'Test operationName';
        objCDMEnquiry.categoryLevel1 = 'Test categoryLevel1';
        objCDMEnquiry.categoryLevel2 = 'Test categoryLevel2';
        objCDMEnquiry.subject = 'Test subject';
        objCDMEnquiry.content = 'Test content';
        objCDMEnquiry.origin = 'Test origin';
        objCDMEnquiry.recordtypeDeveloperName = 'Standard';
        objCDMEnquiry.type = 'Test ENq Type';
        objCDMEnquiry.references = new List<EnquiryWSPayload.CDM_Reference> {objCDMRefRef, objCDMRefName, objCDMRefEmail, objCDMRefLink, objCDMRefReason};

        processReqObj.enquiry = objCDMEnquiry;
        
        // When: the method is invoked
        Test.startTest();
            EnquiryWSImpl.HandlePost obj = new EnquiryWSImpl.HandlePost();
            obj.processVerifyMeEnquiry(processRespObj, processReqObj);
        Test.stopTest();

        // Then: A VerifyMe Enquiry is created 
        List<Case> l_enq = [SELECT Id, Description, contact.Person_ID_unique__c FROM Case WHERE COntact.Person_ID_unique__c = '123456789'];
        Assert.areEqual(l_enq[0].contact.Person_ID_unique__c, '123456789');
        String descrptn = l_enq[0].Description;
        Assert.isTrue(descrptn.contains('Test Reason'), 'ProcessVerifyMeEnquiryTest Reason field not mapped');
    }
}