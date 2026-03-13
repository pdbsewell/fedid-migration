/**
 * @description Controller class for WUPaymentGateway lightning component
 * @author      Trent De Laney
 * @date        06/07/2018
 * @revision
 *  15/09/2018  Stefan Scheit   - Changed class to with sharing
 *  06/03/2023  Ken McGuire     - Added error logging.
 *  16/08/2023  SMendu          - Agentportal fee handling
 *  07/11/2023  Nick Guia       - Created PaymentGatewayControllerException
 *                              - deprecated getWaiverCode
 *                              - created getInitData()
 *  31/07/2024  APRivera        - Added fields to retrieve from application
 */
public with sharing class PaymentGatewayController {
    static Feature_Switch__c fs = Feature_Switch__c.getInstance();


    /**
     * @description fetches all data required on initialising the component. This is an attempt to improve
     * page load time of WUPaymentGateway component. The code logic that was initially being invoke remains untouched
     * to reduce the amount of testing required for an unrelated simple task. The entire class still needs to be revisited
     * as per code review notes
     * @author Nick Guia
     * @date 07/11/2023
     * @param applicationId
     * @return `InitData`
     * @throws AuraHandledException
     */
    @AuraEnabled
    public static InitData getInitData(Id applicationId) {

        InitData returnVal = new InitData();

        try {

            Application__c appRecord = [SELECT Id, Fee_Payment_Mode__c, Fee_Waiver_Code__c, Source_System__c, Campus_Location__c, Type_of_Study__c
                                        FROM Application__c 
                                        WHERE Id = :applicationId];
            
            // get fee amount
            returnVal.feeAmount = getFeeAmount(applicationId);

            // check if applicant is an international student
            returnVal.isInternationalStudent = internationalStudent(applicationId);

            // get waiver code
            returnVal.waiverCode = appRecord.Fee_Waiver_Code__c;

            // get fee payment mode
            returnVal.feePaymentMode = appRecord.Fee_Payment_Mode__c;

            // set processing fee amount label
            returnVal.processingFeeAmountLabel = getProcessingFeeAmountLabel(appRecord);

            // set source system
            returnVal.sourceSystem = appRecord.Source_System__c;
           
            // set campus location
            returnVal.campusLocation = appRecord.Campus_Location__c;
            // set study type
            returnVal.studyType = appRecord.Type_of_Study__c;
            // Get payment maintenance configs
            returnVal.paymentMaintenanceConfig = PaymentUtils.admissionsMaintenanceMDT;
        } catch (Exception e) {
            Nebula.logger.error(e.getMessage()+e.getStackTraceString(), new Application__c(Id=applicationId)).addTag('PaymentGatewayController');
            throw new AuraHandledException(e.getMessage());
        }finally{
            Nebula.logger.saveLog();
        }
        return returnVal;
    }
    
    /**
     * @description Build URL to PaymentGateway
     * @param appId 
     * @return String 
     * @revision
     */ 
    @AuraEnabled
    public static String GetRequest(string appId)
    {   
        try {
            Application__c app = [Select a.id, a.Applicant__c, a.Fee_Amount__c From Application__c a where a.id=:appId];
            if(app != null){
                Contact applicant = [Select c.id, c.ContactId__c, c.Name, c.Email, c.MobilePhone From Contact c where c.id = :app.Applicant__c];
                if(applicant != null){
                    //Country is blank at this point
                    String amountValue = String.valueOf(app.Fee_Amount__c.format());
                    PaymentUtils.WURequest wu = new PaymentUtils.WURequest(applicant.ContactId__c, applicant.Name, applicant.Email, amountValue, applicant.MobilePhone, '');
                    return wu.AssembleUrl();
                }
            }
        } catch(exception ex) {
            LogUtilityException.logException(ex,'PaymentGatewayController.GetRequest for app ' + appId);
        }
        return 'ERROR';
    }

    /**
     * @description updates the fee waiver code to null if payment mode is not 'Application Fee Waiver Code'
     * @param appId       
     * @param paymentType 
     */
    @AuraEnabled
    public static void savePaymentType(String appId, String paymentType) {
        try {
            Application__c app = [SELECT Id, Fee_Payment_Mode__c, Fee_Waiver_Code__c 
                                FROM Application__c 
                                WHERE Id = :appId];
            app.Fee_Payment_Mode__c = paymentType;

            if(app.Fee_Payment_Mode__c != 'Application Fee Waiver Code') {
                app.Fee_Waiver_Code__c = '';
            }
            
            update app; // NG: TODO - this should be moved within the if clause to prevent an unncessary DML 
        } catch(exception ex) {
            LogUtilityException.logException(ex,'PaymentGatewayController.savePaymentType for app ' + appId);
        }
    }
    /**
     * @description clears FeeWaiverCode from the front end
     * @param appId 
     * @revision
     */  
    @AuraEnabled
    public static void clearFeeWaiverCode(string appId) {
        try {
            Application__c app = [Select a.id, a.Fee_Waiver_Code__c From Application__c a where a.id = :appId];
            app.Fee_Waiver_Code__c = '';

            update app;
        } catch(exception ex) {
            LogUtilityException.logException(ex,'PaymentGatewayController.clearFeeWaiverCode for app ' + appId);
        }
    }



    /**
     * @description Find if the student is an international student
     * @param appId 
     * @return `Boolean`
     * @revision
     */   
    @AuraEnabled
    public static Boolean internationalStudent(String appId) {
        try {
            string type = MyApplicationUtilities.getCitizenshipTypeByAppId(appId);
            if(type == 'INTERNATIONAL'){
                return true;
            }
        }  catch(exception ex) {
            LogUtilityException.logException(ex,'PaymentGatewayController.internationalStudent for app ' + appId);
        }
        return false;
    }

    /****************************************************************
    MIX Integration Logic
    *****************************************************************/
     /**
     * @description  retrieves waiver code per Application for validation purposes
     * @param waiverCode 
     * @param appId 
     * @param checkOnly 
     * @return String
     */
    @AuraEnabled
    public static String WaiverCodeAvailiable(String waiverCode, String appId, Boolean checkOnly)
    {
        String code = PaymentUtils.ValidateWaiverCode(waiverCode, appId, checkOnly);
        return code;
    }
 
    @AuraEnabled
    public static string RedeemWaiverCode(string waiverCode, string appId)
    {
        string code = '';
        return code;

    }

    /**
     * @description retrieves the fee amount for the application
     * @param appId 
     * @return `Decimal`
     * @revision
     *  07/11/2023  Nick Guia   - removed repetitive query when checking payment type
     */
    @AuraEnabled
    public static Decimal GetFeeAmount(String appId) {

      Decimal appFee = 0;

          try {

            /**
             * NG 07/11/2023
             * TODO: This method needs to be revisited. It doesn't make sense to be (re)calculating the fees at the time of
             * retrieving the application. Fee calculation should be  centralised within the Application domain.
             */

            //First calculate the fee
            appReviewCC.determineFeeRule(appId);
            
            Application__c app = [SELECT Id, Fee_Amount__c, Source_System__c, Fee_Waiver_Code__c, Fee_Payment_Mode__c
                                FROM Application__c 
                                WHERE Id = :appid];

            if(app != null && app.Source_System__c != 'AgentPortal') {

                if(app.Fee_Amount__c == 0) {
                    savePaymentType( appId, 'NA');
                } else {
                    if(String.isBlank(app.Fee_Payment_Mode__c) || app.Fee_Payment_Mode__c == 'NA') {
                        // 2019-03-12 SFTM-351 K LIEW: This saves Western Union as payment method by default, existing logic that is
                        // contradictory to the new credit card logic, where CC is meant to be the default.
                        // savePaymentType( appId, 'Western Union');
                        savePaymentType( appId, 'Credit Card');
                    }
                }
                appFee = app.Fee_Amount__c;
            } else if(app != null && app.source_system__c == 'AgentPortal') {
                appFee = 0;
            }
        }  catch(exception ex) {
            LogUtilityException.logException(ex,'PaymentGatewayController.GetFeeAmount for app ' + appId);
        }
        
        return appFee;
    }

     /**
     * @description  retrieves payment type for the front end component
     * @param appId 
     * @return Application__c
     */
    @AuraEnabled
    public static Application__c getPaymentType(String appId)
    {
        
        Application__c app = [Select Id, Fee_Payment_Mode__c,Fee_Waiver_Code__c From Application__c a where Id = :appid];
       
        if(app != null){
            return app;
        }
        return null;
    }

    /**
     * @description  retrieves waiver code for an Application
     * @param appId 
     * @return String
     */
    @AuraEnabled
    public static String GetWaiverCode(string appId)
    {
        Application__c app = [Select a.Id, a.Fee_Amount__c, a.Fee_Waiver_Code__c From Application__c a where a.Id = :appid];
        if(app != null){
            return app.Fee_Waiver_Code__c;
        }
        return '';
    }

     /**
     * @description  Gets the Course Preferences from Salesforce for a given application
     * @param appId 
     * @return Application_Course_Preference__c`
     */
    @TestVisible
    private static Application_Course_Preference__c[] GetCoursePreferences(string appId){
        //Attendance_Mode__c
        Application_Course_Preference__c[] preferences = [SELECT p.Id, p.Application__c, p.Attendance_Mode__c
        FROM Application_Course_Preference__c p WHERE p.Application__c = :appId];
        return preferences;
    }

    /**
     * @description  Checks for valid course Preferences based on attendance Mode
     * @param appId 
     * @return Boolean`
     */
    @TestVisible
    private static Boolean CoursePreferenceFee(string appId){
        Application_Course_Preference__c[] prefs = GetCoursePreferences(appId);
        
        for (Application_Course_Preference__c p : prefs) {
           //Check all preferences for attendance mode
           if(p.Attendance_Mode__c == 'EX' || p.Attendance_Mode__c == 'MM'){
               return false;
           }
        }
        return false;
    }

    /**
     * @description  determines the Application Processing Fee Label to be used based on the
     *  Application's Campus Location. Typically relevant only when source system = Agent Portal
     * @param appRec 
     * @return `String`
     */
    @TestVisible
    private static String getProcessingFeeAmountLabel(Application__c appRec) {

        String processingFeeLabel;

        // TODO : determine behaviour if campus location = online or indonesia
        // currently, Agent Portal is not open to Online or Indonesia applications
        // but would be a good idea to have a fall-back label here.
        if(appRec.Campus_Location__c == 'Malaysia') {
            // Malaysia processing fee
            processingFeeLabel = Label.MY_APP_PROCESSING_FEE_MUM;
        } else {
            if(fs.Display_New_Application_Fee__c)
            {
                 // AU processing fee as default - show updated fee
                 processingFeeLabel = Label.MY_APP_UPDATED_FEE_MUA;
            }else{
                // AU processing fee as default
                processingFeeLabel = Label.MY_APP_PROCESSING_FEE_MUA;
            }
          
        }
        return processingFeeLabel;
    }
    
    public class InitData {
        /**
         * @description  Getter/setter for feeamount
         * @return Decimal
         */
        @AuraEnabled
        public Decimal feeAmount { get; set; }
        /**
         * @description  Getter/setter for whether the applicant is an international student
         * @return Boolean
         */
        @AuraEnabled
        public Boolean isInternationalStudent { get; set; }
        /**
         * @description  Getter/setter for waiverCode
         * @return String
         */
        @AuraEnabled
        public String waiverCode { get; set; }
        /**
         * @description  Getter/setter for payment mode of the fee
         * @return String
         */
        @AuraEnabled
        public String feePaymentMode { get; set; }
        /**
         * @description  Getter/setter for feeamountlabel
         * @return String
         */
        @AuraEnabled
        public String processingFeeAmountLabel { get; set; }
        /**
         * @description  Getter/setter for sourcesystem
         * @return String
         */
        @AuraEnabled
        public String sourceSystem { get; set; }
        /**
         * @description  Getter/setter for campusLocation
         * @return String
         */
        @AuraEnabled
        public String campusLocation { get; set; }
        /**
         * @description  Getter/setter for studyType
         * @return String
         */
        @AuraEnabled
        public String studyType { get; set; }
        @AuraEnabled
        public Object paymentMaintenanceConfig { get; set; }
    }
}