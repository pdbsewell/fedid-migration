/*******************************************************************************
* @author       Trent
* @description  Helper class for PaymentGatewayController and other waiver code related logic

* @change History:
* @revision     Shalini - Refactoring code - 18/10/2018
* @revision     Shalini - Adding logic for 'Expired' waiver codes - 04/01/2019
* @revision     K Liew  - Refactoring CreditCard class from being defined inline
                        inCreditCardController over to this class - 21/02/2019
* @revision     Suman   - Changed WU seviceid label property to custom setting
* @revision     Ken McGuire - handle mononymous name
* @revision     15.MAR.2024 Ven Vairavan > Update Mule4 endpoints.
* @revision     22.Oct.2024 Girish P > DANO-281: Add admission payment maintenance config.
                21.Jul.2025 M.Domingo: Changed the exception and debugging to Nebula logger framework
*******************************************************************************/
public class PaymentUtils {
    public final static String CALLISTA_FEE_WAIVER_MAINTENANCE_CONFIG = 'CallistaFeeWaiverNotAvailable';
    public final static String CALLISTA_META_STATUS {get{return 'Under Maintenance';}}
    @testVisible
	public static Admissions_Settings__mdt admissionsMaintenanceMDT {
		get {
			try {
				return admissionsMaintenanceMDT!=null
                        ?admissionsMaintenanceMDT
                        :[
                        SELECT id, DeveloperName, Status__c, Messages__c, Configs__c
                            FROM Admissions_Settings__mdt
                            WHERE DeveloperName = :CALLISTA_FEE_WAIVER_MAINTENANCE_CONFIG 
                            limit 1
                    ];
			} catch (Exception e) {
                Nebula.Logger.error('CALLISTA_FEE_WAIVER_MAINTENANCE_CONFIG does not exists').addTag('PaymentUtils');
                Nebula.Logger.savelog();
				return null;
			}
		}
		set;
	}
    /**
     * @author Trent De Laney
     * @date 21 Feb 2019 at 10:27:57 am
     * @group Struct Class
     * @description Used to handle information coming from the UI easier and move around between objects and Chargent
     */
    public class CreditCard{
        //Suppressed the PropertyNamingConvention as this will affect changes in other classes referencing this which we do not want to change at the moment.  
        @SuppressWarnings('PMD.EmptyStatementBlock')
        public CreditCard(){
            //Default constructor for serialization
        }
        @SuppressWarnings('PMD.PropertyNamingConventions')
        public String CardNumber {get; set;}
        public String CardHolderName {get; set;}
        public String ExpiryDate {get; set;}
        public String CCV {get; set;}
        public String CardType {get; set;}
    }

    /****************************************************************
   WU Request Class
   *****************************************************************/
    public class WURequest {
        private String buyerId { get; set; }
        @testVisible
        private String firstName { get; set; }
        @testVisible
        private String lastName { get; set; }
        private String email { get; set; }
        private String amount { get; set; }
        private String phone { get; set; }
        private String country { get; set; }
        private String serviceId { get; set; }
        private String SalesforceId { get; set; }

        //Base Url to be submitted to
        private String requestBaseUrl { get; set; }
        private String clientId { get; set; }

        public WURequest() {
            initialiseGateway();
        }

        //Constructor
        public WURequest(String buyerId, String name, String email, String amount, String phone, String country) {
            this.buyerId = buyerId;
            string[] names = name.split(' ');
            this.firstName = names[0];
            this.lastName = names[names.size()-1];
            this.email = email;
            this.amount = amount;
            this.phone = phone;
            this.country = country;

            initialiseGateway();
        }

        //Gets the URLs from Custom Settings
        private void initialiseGateway() {
            Western_Union_Config__c c = [
                    SELECT wu.Base_Url__c, wu.Callback_Url__c, wu.ClientId__c, wu.ServiceId__c
                    FROM Western_Union_Config__c wu LIMIT 1
            ];
            if (c != null) {
                if (c.Base_Url__c != null && c.ClientId__c != null && c.ServiceId__c != null) {
                    requestBaseUrl = c.Base_Url__c;
                    clientId = c.ClientId__c;
                    serviceId = c.ServiceId__c;
                } else {
                    Nebula.Logger.debug('Core Western Union configuration not set');
                    Nebula.Logger.saveLog();
                }
            }
        }

        //Checks the population/validity of a request before it is send back to the client
        public Boolean ValidateRequest() {
            //Check for Custom Fields
            return false;
        }

        //Constructs Request
        public string AssembleUrl() {
            string request = requestBaseUrl +
                    '?clientId=' + clientId +
                    '&buyer.id=' + buyerId +
                    '&buyer.firstName=' + firstName +
                    '&buyer.lastName=' + lastName +
                    '&buyer.email=' + Email +
                    '&service1.id=' + serviceId +
                   // '&service1.amount=' + '100.00'; 14/2/19 MUM defect
                    '&service1.amount=' + amount;
            //'&customField=' + Phone +
            //'&customField=' + SalesforceId;

            return request;
        }
    }

    //Response from the Calista Gateway
    public class WavierCodeResponse {
        string type;
        string code;
        Boolean redeemed;
        PeriodOfValidity periodOfValidity;
        //Constructor

    }
    public  class PeriodOfValidity{
        Date startDate;
        Date endDate;
        Boolean isValid;

    }

    /**
    * @author Trent De Laney
    * @date 31 Jul 2018 at 11:12:12 am
    * @group API Concretes
    * @description Used to capture the response from the Waiver code redeem request to Mix
    */
    public class WavierCodeRedeemResponse {
        public string type;
        public string code;
        public string validatedDate;
        public Boolean redeemed;

    }



    /**
    * @author Trent De Laney
    * @date 31 Jul 2018 at 11:08:11 am
    * @group API Concretes
    * @description Used to deinfe the request which is sent to the MIX Api for Wavier Code redemption
    */
    public class WaiverCodeRedeemRequest {
        ApplicationRequest application;

        public WaiverCodeRedeemRequest(ApplicationRequest a) {
            application = a;
        }
    }

    /**
    * @author Trent De Laney
    * @date 31 Jul 2018 at 11:07:29 am
    * @group API Concretes
    * @description Used for serialization to the MIX Api
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

    /**
    * @author Trent De Laney
    * @date 31 Jul 2018 at 11:05:50 am
    * @group API Concretes
    * @description Used to capture the high level error response from the Mix API
    */
    public class ErrorResponse {
        public string message;
        public ErrorMessageResponse errorDetails;
        /*
        public ErrorResponse(string ms, ErrorMessageResponse err) {
            message = ms;
            errorDetails = err;
        }*/
    }

    /**
    * @author Trent De Laney
    * @date 31 Jul 2018 at 11:03:19 am
    * @group API Concretes
    * @description Used to capture message responses as part of the Error Response Class
    */
    public class ErrorMessageResponse {
        public string message;
        /*
        public ErrorMessageResponse(string ms) {
            message = ms;
        }*/
    }

    /**
     * Gets the Mix Configuration from the Custom Settings Obeject
     * @author Trent De Laney
     * @date 31 Jul 2018 at 10:54:33 am
     * @return MIX_API_Config__c config
     * TODO - refactor further ?/
     */
    public static List<MIX_API_Config__c> GetMixConfiguration() {
        List<MIX_API_Config__c> cfgList = [
                SELECT c.Base_Url__c, c.Client_Id__c, c.Client_Secret__c
                FROM MIX_API_Config__c c
                WHERE c.Base_Url__c != NULL AND c.Client_Id__c != NULL AND c.Client_Secret__c != NULL
                LIMIT 1
        ];
        return cfgList;
    }

    //Build the request
     @SuppressWarnings('PMD.CognitiveComplexity ')
    public static String ValidateWaiverCode(String wavierCode, String appId, Boolean checkOnly) {

        String request = '/la/admissions/v1/feeWaiveCodes/';
        List<MIX_API_Config__c> cfgList = GetMixConfiguration();

        if (cfgList != null && cfgList.size() > 0) {
            //Create Request
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            //Setting Config
            String apiCall = cfgList[0].Base_Url__c + request + wavierCode;
            Nebula.Logger.debug('apiCall==' + apiCall);
            Nebula.Logger.saveLog();
            req.setEndpoint(apiCall);
            req.setMethod('GET');
            //Set headers
            req.setHeader('client_id', cfgList[0].Client_Id__c);
            req.setHeader('client_secret', cfgList[0].Client_Secret__c);

            //Call API
            HttpResponse res = null;
           
            if (!Test.isRunningTest()) {
                try {
                    res = h.send(req);
                }catch(Exception exc)
                {
                    Nebula.Logger.error('PaymentUtils.ValidateWaiverCode', exc);
                    Nebula.Logger.saveLog();
                }
            }else
            {
                Nebula.Logger.debug('*** dummy response from ValidateWaiverCode');
                Nebula.Logger.saveLog();
                res = new HttpResponse();
                res.setBody('{"type":"waiver","code":"123","redeemed":false,"periodOfValidity": {"startDate": "2018-08-15","endDate": "2019-08-18","isValid": true}}');
            }
            Nebula.Logger.debug('res======' + res+'body=='+res.getBody());
            Nebula.Logger.saveLog();
            JSONParser parser = JSON.createParser(res.getBody());
            Application__c app = [
                    SELECT a.Id, a.Fee_Waiver_Code__c, a.Fee_Payment_Mode__c
                    FROM Application__c a
                    WHERE a.Id = :appId
            ];
            //Check for errors
            if (res!=null && res.getBody()!=null && res.getBody().contains('errorDetails')) {
                app.Fee_Waiver_Code__c = wavierCode;
                update app;
                //Error - Invalid code
                return 'Error';
            } else {
                WavierCodeResponse r = (WavierCodeResponse) parser.readValueAs(WavierCodeResponse.class);
                Nebula.Logger.debug('WaiverCodeResponse r=='+r);
                Nebula.Logger.saveLog();
                app.Fee_Waiver_Code__c = r.code;
                update app;

                Boolean crmRedeemCodeAvailable = redeemCodeAvailable(wavierCode);

                // Return Redeemed if it has been Redeemed on Callista or on CRM

                if (r.redeemed==false && crmRedeemCodeAvailable && !r.PeriodOfValidity.isValid ) {
                    return 'Expired';
                }

                if (r.redeemed || !crmRedeemCodeAvailable ) {
                    return 'Redeemed';
                }

                return r.code;
            }
        }

        return 'SystemError';
    }

    public static void updateCRMRedeemCode(String wavierCode, String appId)
    {
        Application__c app = [
                SELECT a.Id, a.Name, a.Fee_Waiver_Code__c, a.Fee_Payment_Mode__c
                FROM Application__c a
                WHERE a.Id = :appId
        ];
        try{
            if (app != null) {
                app.Fee_Waiver_Code__c = wavierCode;
                app.Fee_Waiver_Redeemed__c = wavierCode;
                app.Fee_Amount__c = 0;
                update app;
            }
        }
        catch(Exception ex){
            Nebula.Logger.error('PaymentUtils.updateCRMRedeemCode', ex);
            Nebula.Logger.saveLog();
        }
            
    }
    public static String RedeemWaiverCode(String wavierCode, String appId, Integer smsApplicantId, Integer smsApplicationId) {
        String request = '/la/admissions/v1/feeWaiveCodes/';
        List<MIX_API_Config__c> cfgList = GetMixConfiguration();

        if (cfgList != null && cfgList.size() > 0) {
            //Create Request
            Http h = new Http();
            HttpRequest req = new HttpRequest();

            String apiCall = cfgList[0].Base_Url__c + request + wavierCode + '/redeem';
            req.setEndpoint(apiCall);
            req.setMethod('POST');
            //Set headers
            req.setHeader('client_id', cfgList[0].Client_Id__c);
            req.setHeader('client_secret', cfgList[0].Client_Secret__c);
            req.setHeader('Content-Type', 'application/json');

            ApplicationRequest ar = new ApplicationRequest(smsApplicantId, smsApplicationId, null);
            WaiverCodeRedeemRequest wcr = new WaiverCodeRedeemRequest(ar);
            String body = JSON.serialize(wcr);
            req.setBody(body);
            HttpResponse res = null;

                if (!Test.isRunningTest())
                    res = h.send(req);
                else {
                    res = new HttpResponse();
                    res.setBody('{"type":"waiver","code":"123","redeemed":true}');
                }
           
            //Call API
           // HttpResponse res = h.send(req);
            JSONParser parser = JSON.createParser(res.getBody());

            if (res.getBody().contains('errorDetails')) {
                //Error
                ErrorResponse err = (ErrorResponse) parser.readValueAs(ErrorResponse.class);
                return 'ERROR'+err.errorDetails.message;
            } else {
                WavierCodeRedeemResponse r = (WavierCodeRedeemResponse) parser.readValueAs(WavierCodeRedeemResponse.class);
                nebula.Logger.debug('r=='+r);     
                Nebula.Logger.saveLog();            
                return r.code;
            }
        }
        return 'Error';
    }

    public static Boolean redeemCodeAvailable(String wavierCode)
    {
        List<Application__c> appRedeemList = [
                SELECT a.Id, a.Fee_Waiver_Redeemed__c
                FROM Application__c a
                WHERE Fee_Waiver_Redeemed__c  = :wavierCode
        ];

        if(appRedeemList.size()>0)
            return false;
        else
            return true;
    }
}