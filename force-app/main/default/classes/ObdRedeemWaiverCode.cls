/**
 * @author Shalini Mendu
 * @date 15 Jul 2019
 * @group Integration
 * @description Trigger asynchronous job to fire Fee waiver redemption for a submitted application
 * @revision     Modified by Shalini Mendu for SFTD-573 on 12.May.2020 
 * @revision     15.MAR.2024 VV > Update Mule4 endpoints.
 */
public with sharing class ObdRedeemWaiverCode {
    private  static String  FEE_WAIVER_REQUEST_URL =  '/la/admissions/v1/feeWaiveCodes/';


    /*******************************************************************************
   * @author       Shalini Mendu
   * @date         16.Jul.2019
   * @description
   ***************************************************************************/
    @Future(Callout = true)
    public static void redeemCode(String appId) {
       Application__c app = StudFirst_SubmitApplicationHelper.getApplicationById(appId);
       Integer callistaApplicationId = Integer.valueOf(app.Callista_Application_Id__c);
       Integer callistaApplicantId = Integer.valueOf(app.Callista_Applicant_Id__c);
       String waiverCode = app.Fee_Waiver_Code__c;
       List<MIX_API_Config__c> cfgList = getMixAPIConfig();
        System.debug('cfgList=='+cfgList);
       if (cfgList != null && cfgList.size() > 0) {
           //Create Request
           Http h = new Http();
           HttpRequest req = new HttpRequest();
           String apiCall = cfgList[0].Base_Url__c + FEE_WAIVER_REQUEST_URL + waiverCode + '/redeem';
           req.setEndpoint(apiCall);
           req.setMethod('POST');
           req.setHeader('client_id', cfgList[0].Client_Id__c);
           req.setHeader('client_secret', cfgList[0].Client_Secret__c);
           req.setHeader('Content-Type', 'application/json');
           ApplicationRequest ar = new ApplicationRequest(callistaApplicantId, callistaApplicationId, null);
           RedeemWaiverCodeRequest wcr = new RedeemWaiverCodeRequest(ar);
           String body = JSON.serialize(wcr);
           System.debug('body=='+body);
           req.setBody(body);
           HttpResponse res = null;

           if (!Test.isRunningTest())
               res = h.send(req);
           else {
               res = new HttpResponse();
               res.setBody('{"type":"waiver","code":"1234567SD","redeemed":true}');
           }

           JSONParser parser = JSON.createParser(res.getBody());

           if (res.getBody().contains('errorDetails')) {
               RedeemWaiverError err = (RedeemWaiverError) parser.readValueAs(RedeemWaiverError.class);
               ExLog.add('Error Redeeming Fee waiver code', 'ObdRedeemWaiverCode', 'execute', err.errorDetails.message);
           } else {
               RedeemWavierCodeResponse r = (RedeemWavierCodeResponse) parser.readValueAs(RedeemWavierCodeResponse.class);
               System.debug(' code response=='+r);
               app.Fee_Waiver_Code__c = r.code;
               app.Fee_Waiver_Redeemed__c = r.code;
               app.Fee_Payment__c = true;
               if(app.Source_System__c =='my.app')
               {
                    app.Fee_Amount__c = 0;
               }
               update app;

           }
       }
   }

       /*******************************************************************************
       * @author       Shalini Mendu
       * @date         16.Jul.2019
       * @description Wrapper for Redeem waiver web call request
       ***************************************************************************/
        public class RedeemWaiverCodeRequest {
            ApplicationRequest application;
            public RedeemWaiverCodeRequest(ApplicationRequest a) {
                application = a;
            }

        }
    /**
      * @author       Shalini Mendu
       * @date         16.Jul.2019
       * @description Wrapper for Redeem waiver web call request
    */
    public class ApplicationRequest {
        Integer applicantId;
        Integer applicationNumber;
        String personId;

        public ApplicationRequest(Integer smsApplicantId, Integer appNum, String pId) {
            applicantId = smsApplicantId;
            applicationNumber = appNum;
            personId = pId;
        }
    }
        /*******************************************************************************
        * @author       Shalini Mendu
        * @date         16.Jul.2019
        * @description Wrapper for Redeem waiver error
        ***************************************************************************/
        public class RedeemWaiverError
        {
            public String message{get;set;}
            public RedeemWaiverErrorDetails errorDetails{get;set;}
        }
        public class RedeemWaiverErrorDetails
        {
            public String message{get;set;}
        }

        /*******************************************************************************
        * @author       Shalini Mendu
        * @date         16.Jul.2019
        * @description Wrapper for Redeem waiver web call response
        ***************************************************************************/
        public class RedeemWavierCodeResponse {
            public string type;
            public string code;
        }

        /*******************************************************************************
        * @author       Shalini Mendu
        * @date         16.Jul.2019
        * @description  Get MIX API config from the custom settings
        ***************************************************************************/
        public static List<MIX_API_Config__c> getMixAPIConfig() {
            List<MIX_API_Config__c> cfgList = [
                    SELECT c.Base_Url__c, c.Client_Id__c, c.Client_Secret__c
                    FROM MIX_API_Config__c c
                    WHERE c.Base_Url__c != NULL AND c.Client_Id__c != NULL AND c.Client_Secret__c != NULL
                    LIMIT 1
            ];
            return cfgList;
        }

}