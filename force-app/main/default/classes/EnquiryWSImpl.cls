/**
 * @Class              : EnquiryWSImpl.cls
 * @Description        : Webservice class for handling enquiries from VerifyMeWeb 
 * @Author             : Idhanoa
 * @Group              : MOnash COnnect
 * @Revision           : 2024-05-03     Idhanoa   Created 
 * 1.1                 : 2024-08-09     Idhanoa   MCT - 482
 */
public inherited sharing class EnquiryWSImpl {
    @TestVisible
    private static String VERIFY_ME = 'VerifyMe';
    private static String ENQUIRY_STATUS = 'Open'; // Enquiry Status
    private static String CATG_LEVEL1_MPASS = 'M-Pass'; // Catg Level 1 for MPASS
    private static String PRIORITY_MED = 'Medium'; // Priority Type
    private static String MPASS_QUEUE_DEV_NAME = 'MPass_Card_Office';    // record type (developer name) used for Queue Mpass
    private static String STD_ENQ_RECTYPE_DEV_NAME = 'Monash_Connect_Enquiry';    // record type (developer name) used for Queue Mpass
    private static String ENQ_TYPE_NON_COURSE = 'Non Course';    // Enquiry Type picklist value 'Non Course'
    private static String ENQ_TYPE_CURRNT_COURSE = 'Current Course';    // Enquiry Type picklist value 'Current Course'

      /**
     * @description clas to handle payload for Endpoint '/v2/EnquiryWS'
     */
    public virtual class HandlePost extends RESTlib_Handler {
        /**
         * @description validation rules for this endpoint.
         * @throws RESTlib_Ex.InvalidRequestException
         */        
        public override void validate(RESTlib_Payload.Request req) {
            // typecast to your request payload to access the properties 
            EnquiryWSPayload.GetRequest reqObj = (EnquiryWSPayload.GetRequest) req;
            if(String.ValueOf(reqObj.enquiry.operationName) != EnquiryWSImpl.VERIFY_ME) {
                //throw an exception if the param "operationName" does not have "VerifyMe"
                throw new RESTlib_Ex.InvalidRequestException('Invalid null request');
            }
        }
        /**
         * @description The method process the payload to initiate a Verify me Enquiry 
         * related contact records 
         * based on the payload parameter
         */
        public override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            EnquiryWSPayload.GetRequest processReqObj = (EnquiryWSPayload.GetRequest) reqObj;
            EnquiryWSPayload.GetResponse processRespObj = (EnquiryWSPayload.GetResponse) responseObj;
            processVerifyMeEnquiry(processRespObj, processReqObj);
            return processRespObj;
        }
        /**
         * @description The method process the payload to generate a Verify me Enquiry 
         * related contact records 
         * based on the payload parameter
         */
        @TestVisible
        private void processVerifyMeEnquiry(EnquiryWSPayload.GetResponse processRespObj , EnquiryWSPayload.GetRequest processReqObj) {
            String s_Reference_SAPStaffId, s_Reference_PersonId, s_Name, s_Email, s_JourneyRefNumbr, s_description, reason;
            processRespObj.responseType = VERIFY_ME;
            processRespObj.outcome = 'Error';
            List<EnquiryWSPayload.CDM_Value> cdmValues;
            for(EnquiryWSPayload.CDM_Reference ref : processReqObj.enquiry.references){
                cdmValues = ref.value;
                switch on ref.key.toLowerCase() {
                    when  'reference_sapstaffid' {
                        s_Reference_SAPStaffId = cdmValues[0].id;
                    }
                    when 'reference_personid'{
                        s_Reference_PersonId = cdmValues[0].id;
                    }
                    when  'name' {
                        s_Name = cdmValues[0].id;
                    }
                    when  'email' {
                        s_Email = cdmValues[0].id;
                    }
                    when  'journey_reference_number' {
                        s_JourneyRefNumbr = cdmValues[0].id;
                    }
                    when  'reason' {
                        reason = cdmValues[0].id;
                    }
                }
            }
            // Create an Enquiry 
            Case verifyMeEnq = new Case();
            List<Contact> linkedCon = new List<Contact>();
            s_description = (String.isBlank(s_Name) ? '' : ('Name : ' + s_Name + '\n')) + (String.isBlank(s_Email) ? '' : ('Email : ' + s_Email + '\n')) + (String.isBlank(s_JourneyRefNumbr) ? '' : ('Journey Reference Number : ' + s_JourneyRefNumbr + '\n')) + (String.isBlank(reason) ? '' : ('Referral Reason : ' + reason )); 
            verifyMeEnq.Status = ENQUIRY_STATUS;
            verifyMeEnq.RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND DeveloperName = :STD_ENQ_RECTYPE_DEV_NAME].Id;
            verifyMeEnq.OwnerId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :MPASS_QUEUE_DEV_NAME].Id;
            verifyMeEnq.Origin = VERIFY_ME;
            verifyMeEnq.Category_Level_1__c = CATG_LEVEL1_MPASS;
            verifyMeEnq.Priority = PRIORITY_MED;
            verifyMeEnq.Bypass_Case_Assignment__c = true;
            verifyMeEnq.Description = s_description;  
            String[] s_dateToday = String.ValueOf(Date.today()).split(' ');
            linkedCon = fetchContact(s_Reference_SAPStaffId, s_Reference_PersonId);
            if(linkedCon.isEmpty()){
                verifyMeEnq.Subject = 'VerifyMe referral - [' + s_dateToday[0] +']';
            }else{
                String s_linkedId = String.isNotBlank(s_Reference_SAPStaffId) ? s_Reference_SAPStaffId : s_Reference_PersonId;
                verifyMeEnq.Subject = s_linkedId + ' - VerifyMe referral - [' + s_dateToday[0] +']';
                verifyMeEnq.ContactId = linkedCon[0].Id;
                verifyMeEnq.Enquiry_Type__c =  linkedCon[0].SAP_Staff_Id__c == s_Reference_SAPStaffId ? ENQ_TYPE_NON_COURSE : ENQ_TYPE_CURRNT_COURSE;
            }
            insert verifyMeEnq;
            processRespObj.Description = 'case-' + [SELECT casenumber FROM Case WHERE Id = :verifyMeEnq.Id].casenumber;
            processRespObj.outcome = 'Success';
        }

        /**
         * @description The method to fetch the linked COntact 
         * @param Staff Id
         * @Param Student ID
         * related contact records based on the payload parameter
         */
        private List<Contact> fetchContact(String s_Reference_SAPStaffId, String s_Reference_PersonId){
            // If both ID's are provided then do not link a COntact, the COntact linking part is more manual for now
            List<Contact> conList = new List<Contact>();
            String sSOQL = 'SELECT Id, SAP_Staff_Id__c, Person_ID_unique__c FROM Contact ';
            // Only Staff ID provided, no Student ID
            if(String.isNotBlank(s_Reference_SAPStaffId) && String.isBlank(s_Reference_PersonId)){
                sSOQL += ' WHERE SAP_Staff_Id__c =\'' + s_Reference_SAPStaffId + '\'' + ' ORDER BY CreatedDate DESC';
                conList = Database.query(sSOQL);
            }
            // Only Student ID provided, no Staff ID
            if(String.isNotBlank(s_Reference_PersonId) && String.isBlank(s_Reference_SAPStaffId)){
                sSOQL += ' WHERE Person_ID_unique__c =\'' + s_Reference_PersonId + '\''  + ' ORDER BY CreatedDate DESC';
                conList = Database.query(sSOQL);
            }
            return conList;
        }
    }
}