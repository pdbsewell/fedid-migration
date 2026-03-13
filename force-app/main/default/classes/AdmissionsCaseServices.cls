/**
 * @author Angelo Rivera
 * @description Service class of Case object for Monash Connect related functionality.
 * @revision    APRivera, 18.June.2019 - Created Admissions Service Class.
 *              KVegerano 26.May.2022  - added case creation with DML Options
 *              Ken McGuire 17 Aug 2022 - retired static country list for database table
 *              Ken McGuire 6/10/2022 - security uplift including XSS and Captcha
 *              Shalini M 5/01/2023 - Enhance MFA Enquiry page
 */
public  class AdmissionsCaseServices {

    public static Id ADMISSIONS_RECTYPEID {
        get {
            if(ADMISSIONS_RECTYPEID == null) ADMISSIONS_RECTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
            return ADMISSIONS_RECTYPEID;
        }
        set;
    }
    
   /**
     * @author      Ken McGuire
     * @description Provides a list of valid countries
     * @return      A list of valid Countries
     * @revision    17/08/2022 - Ken McGuire - Created
     */
    @AuraEnabled
    public static Map<String, Object> retrieveCountryList(){
      return new Map<String,Object>{'allCountries' => CountriesSelector.validCountryList()};
    }
    
     /**
     * @author      Ken McGuire
     * @date        6/10/2022
     * @description Commit record with the options to turn on/off - assignment rule - response rule - with captcha
     */
    @AuraEnabled
    public static void initiateCommitRecordWithCaptcha(String record, Boolean fireAssignmentRule, Boolean fireAutoResponseRule, String captchaToken) {
        Map<String,Object> validateResult = ExperienceAuthenticationServices.validateCaptchaToken(captchaToken);
        if (validateResult.size()>0) throw new AuraHandledException('Unable to submit your enquiry');
        initiateCommitRecord(record, fireAssignmentRule, fireAutoResponseRule);

    }

    /**
     * @author      Kristian Vegerano
     * @date        25.May.2022
     * @description Commit record with the options to turn on/off - assignment rule - response rule
     */
    @testVisible
    public static void initiateCommitRecord(String record, Boolean fireAssignmentRule, Boolean fireAutoResponseRule) {
        if (ExperienceAuthenticationServices.isUnsafe(record)) throw new AuraHandledException('Form contains illegal characters');
        // build dml option
        Database.DMLOptions dmo = new Database.DMLOptions();
        if(fireAssignmentRule){
            dmo.AssignmentRuleHeader.useDefaultRule = true;
        }
        if(fireAutoResponseRule){
            dmo.EmailHeader.triggerAutoResponseEmail = true;
        }

        // commit record
        Case recordInstance = (Case)JSON.deserialize(record, Case.class);
        String message = new AdmissionsCaseServices.ShareExceptionLog().retrieveMessageMatchingEmail(recordInstance.SuppliedEmail+'');
        recordInstance.Subject = 'My.App MFA Support Enquiry - '+message;
        recordInstance.Description += '\n Error encountered: '+ message;
        recordInstance.setOptions(dmo);
    
        Database.SaveResult committedRecord = Database.insert(recordInstance, dmo);
    }


   
    
    /**
         * @author   Shalini Mendu
         * Class without sharing to give access to my.app Site Guest user to Exception log records 
         * @revision   6/01/2023 - Created 
    */
    public without sharing class ShareExceptionLog
    {
        public ShareExceptionLog(){}
        /**
         * @author     Shalini Mendu
         * @date        6/01/2023
         * @param       email - Supplied email on the MFA enquiry page
         * @Return      String - Retrieved Message__C matching email from Exception_Log__c records
         * @Description Query to retrieve the latest Exception log record matching the supplied Email on the MFA enquiry page
         */
        public String retrieveMessageMatchingEmail(String email)
        {
            List<Exception_log__C> exList = [select id, Message__c from Exception_log__C where Function_name__C='ExperienceMFAServices' and CurrentUser__r.email=:email order by Createddate desc limit 1];
            if (exList.size()>0)
            {
                return exList[0].Message__c;
            }else {
                return 'No error Code';
            }
        }
    }

}