/**
 * @author      Sachin Shetty
 * @description Wrapper class to fetch address wrapper.
 * @group       Wrapper
 * @testclass   PhoneNumberValidationWrapper_Test
 * @revision    2022-10-12 - Sachin Shetty - Moved methods related to fecth country attribute to Experian Utility class
 *              2022-09-06 - Sachin Shetty - Support for generic validation message
 *              2022-08-12 - Sachin Shetty - Included confidence values and their descriptions. 
 *                                           Moved frequently used countries to custom settings.
 *              2022-08-03 - Sachin Shetty - Created
 *              
**/
public with sharing class PhoneNumberValidationWrapper {

    // Source : https://docs.experianaperture.io/phone-validation/experian-phone-validation/api-reference/confidence-level/
    public static final Map<String, String> confidenceLevelDescriptions = new Map<String, String> {
        'Verified' => 'Number format validated and number verified.',
        'Absent' => 'Number format validated and number verified via network lookup but not currently available (e.g. phone off, out of range).',
        'Teleservice not provisioned' => 'Number is assigned to a SIM card which is not allowed to make or receive telephone calls. Typically a “data only SIM”.',
        'Unverified' => 'Invalid number format supplied.',
        'Unknown' => 'Valid number format but not verified with network lookup.',
        'No coverage' => 'Unable to detect the live status for the telephone network.',
        'Dead' => 'Number has been confirmed to be dead by the network and will not receive calls or text messages.',
        'Service Unavailable' => 'Experian service currently unavailable.',
        'Forbidden' => 'Invalid authentication token or insufficient Experian credits.'
    };

    /**
     * @author      Sachin Shetty
     * @description Setting used to control certain features of Experian data validation
     * @param       na
     * @return      EDQ_Settings__c instance
     * @revision    2022-08-12 - Sachin Shetty - Created
     */
    public static EDQ_Settings__c EDQSettings {
        get {
            if (EDQSettings == null) {
                // look in custom setting
                EDQSettings = EDQ_Settings__c.getOrgDefaults();
            }
            return EDQSettings;
        } set;
    }
        
    /**
     * @author      Sachin Shetty
     * @description Static reference to show generic error message or actual validation message for phone number validation 
     * @param       na
     * @return      Boolean
     * @revision    2022-09-06 - Sachin Shetty - Created
     */
    public static Boolean showGenericErrorMessage {
        get {
            if (showGenericErrorMessage == null) {
                Boolean isShowGeneric = EDQSettings.Phone_Validation_Show_Generic_Error__c;
                showGenericErrorMessage = isShowGeneric == null
                                        ? false 
                                        : isShowGeneric;
            }
            return showGenericErrorMessage;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description The address split wrapper used by the lwc
     * @revision    2022-08-03 - Sachin Shetty - Created
     */
    public class PhoneNumberWrapper {
        @AuraEnabled
        public String currentRecordId {
            get; set;
        }
        @AuraEnabled
        public String confidence {
            get; set;
        }
        @AuraEnabled
        public String confidence_description {
            get; set;
        }
        @AuraEnabled
        public String entered_phone_number { // Raw phone number entered by user
            get; set;
        }
        @AuraEnabled
        public String formatted_phone_number {
            get; set;
        }
        @AuraEnabled
        public String unicrm_formatted_phone_number {
            get; set;
        }
        @AuraEnabled
        public String phone_type {
            get; set;
        }

        // wrapper constructor
        public PhoneNumberWrapper(){
            this.currentRecordId = '';
            this.confidence = '';
            this.confidence_description = '';
            this.formatted_phone_number = '';
            this.unicrm_formatted_phone_number = '';
            this.phone_type = '';
        }
    }
}