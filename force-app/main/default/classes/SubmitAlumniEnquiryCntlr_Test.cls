/*******************************************************************************
* @author		Inderpal Dhanoa
* @date         21/08/2024    
* @description  test class for SubmitAlumniEnquiryCntlr.cls
*******************************************************************************/
@IsTest(isParallel=true)
public with sharing class SubmitAlumniEnquiryCntlr_Test {

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         21/08/2024
    * @description  Test Method for SubmitAlumniEnquiryCntlr createEnquiry Method  
    * @revision     1.0
    *******************************************************************************/
   @isTest 
   public static void createEnquiryTest(){
     
    PORTAL_UCIN_Domain_Name__c setting = new PORTAL_UCIN_Domain_Name__c();
    setting.Domain_Name__c = 'Test Setting';
    setting.Portal_Domain_Name__c = 'test Setting';
    insert setting;
    //GIVEN: The Commmunity URL exists
    Test.startTest(); 
    //WHEN: The method is invoked 
    
    String result = SubmitAlumniEnquiryCntlr.createAlumniEnquiry('firstName', 'lastName', 'Alumni Portal Enquiry', 'test@test.com', 'details', 'plain details');

    Test.stopTest();
    // THEN: The Enquiry is created
    Case alumniEnq = [SELECT Id, CaseNumber FROM Case 
                        WHERE Subject = 'Alumni Portal Enquiry'
                        AND SuppliedEmail = 'test@test.com' 
                        AND RecordTypeId = :Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Alumni_Engagement').getRecordTypeId() 
                        ORDER BY CreatedDate DESC LIMIT 1];
    Assert.areEqual(alumniEnq.CaseNumber, result, 'Enquiry creation failed');
   }

    /**
     * @description Test method to check Send Code
     */
	@IsTest
    public static void testSendCode(){
        //GIVEN - Some Context Before Tests
        OneTimeTokenService.OneTimeTokenWrapper response;
        //WHEN - Behaviour to Test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OneTimeTokenServiceHTTPMock());
        response = OneTimeTokenService.sendOtp('test@test.com', 'email');
        

        //THEN - Response  is not NULL
        String result = SubmitAlumniEnquiryCntlr.sendCode('test@test.com', 'email');
        Test.stopTest();
        Assert.isNotNull(result, 'The send Code email is not generated');
    }

    /**
     * @description Test method to check Verify Code
     */
	@IsTest
    public static void testVerifyPassCode(){
        //GIVEN - Some Context Before Tests
        Map<String, String> donationFormParams = new Map<String, String>();
        donationFormParams.put('verificationSid', 'testVeriftcnid');
        donationFormParams.put('serviceSid', 'testSid');
        donationFormParams.put('emailSMS', 'email');
        donationFormParams.put('otpCode', '1234');
        
        OneTimeTokenService.OneTimeTokenWrapper response;
        //WHEN - Behaviour to Test
        
        Test.setMock(HttpCalloutMock.class, new OneTimeTokenServiceHTTPMock());
        response = OneTimeTokenService.sendOtp('test@test.com', 'email');
        // THEN - Response  is not NULL
        try{
            Test.startTest();

            SubmitAlumniEnquiryCntlr.verifyPassCode(donationFormParams);

            Test.stopTest();
        }catch(Exception ex){
            String exceptionMessage = ex.getMessage();
            Assert.isTrue(exceptionMessage.contains('Script-thrown exception'));
        }
    }

    //Mock Class
    public class OneTimeTokenServiceHTTPMock implements HttpCalloutMock {
        public Boolean validateResponse = false;
        public Boolean failResponse = false;
        public OneTimeTokenServiceHTTPMock(){}
        public OneTimeTokenServiceHTTPMock(Boolean isF, Boolean isResp){
            validateResponse = isResp;
            failResponse = isF;
        }
        //
        public HTTPResponse respond(HTTPRequest req) {
            LogUtilityException.debug('Endpoint:' + req.getEndpoint());
            LogUtilityException.debug('Body:' + req.getBody());
            LogUtilityException.debug('failResponse:' + failResponse);
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(jsonTOTPResponse(failResponse));
            res.setStatusCode(201);
            res.setBody(jsonTOTPResponse(failResponse));
            res.setStatus('success');
            if (validateResponse) {
                res.setBody(jsonValidateResponse(failResponse));
                res.setStatusCode(200);
                if (failResponse) {
                    res.setStatusCode(404);
                    res.setStatus('FAILED');
                }
            }
            return res;
        }

        private String jsonTOTPResponse(Boolean isFailed) {
            if (isFailed) {
                return '{"code": 60200, "message": "Invalid parameter `To`: +61000000000", "more_info": "https://www.twilio.com/docs/errors/60200", "status": 400}';
            } else {
                return '{"status":"pending","payee":null,"date_updated":"2022-11-29T06:18:48Z","send_code_attempts":[{"attempt_sid":"VL8679a725252e564eac859b48a6f1dbc9","channel":"sms","time":"2022-11-29T06:18:48.760Z"}],"account_sid":"AC1234566789","to":"+61123456789","amount":null,"valid":false,"lookup":{"carrier":null},"url":"https://verify.twilio.com/v2/Services/VA1234567/Verifications/VE1234567","sid":"VE1234567","date_created":"2022-11-29T06:18:48Z","service_sid":"VA1234567","channel":"sms"}';
            }
        }

        private String jsonValidateResponse(Boolean isFailed) {
            if (isFailed) {
                return '{"code": 20404, "message": "The requested resource /Services/VA1234567/VerificationCheck was not found", "more_info": "https://www.twilio.com/docs/errors/20404", "status": 404}';
            } else {
                return '{"status": "approved", "payee": null, "date_updated": "2022-11-29T07:00:15Z", "account_sid": "AC1234566789", "to": "+61123456789", "amount": null, "valid": true, "sid": "VE1234567", "date_created": "2022-11-29T06:59:05Z", "service_sid": "VA1234567", "channel": "sms"}';
            }
        }
    }
}