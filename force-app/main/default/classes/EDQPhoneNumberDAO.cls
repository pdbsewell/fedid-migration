/**
 * @author      Sachin Shetty
 * @description Wrapper class for Phone number validation response from Experian
 *              For more info, refer https://docs.experianaperture.io/phone-validation/experian-phone-validation/api-reference/api-specification/#/Phone%20Validation/post_phone_validate_v2
 * @group       Wrapper
 * @revision    2022-08-03 - Sachin Shetty - Created
 * 				2025-17-08 - Sachin Shetty - Added Constructor
**/
public with sharing class EDQPhoneNumberDAO {

    // Response structure returned by Experian after a phone number is validated
    public class PhoneNumberResponse {
        @AuraEnabled
        public PhoneNumberResult result;
        @AuraEnabled
        public PhoneNumberMetadata metadata;
        
        // Default constructor
        public PhoneNumberResponse() {} //NOPMD
    }

    public class PhoneNumberResult {
        
        @AuraEnabled
        public String validated_phone_number;   //The validated phone number. Also includes the international country calling code. Note that this field is returned even if the phone number has a confidence status of "Invalid".

        @AuraEnabled
        public String formatted_phone_number;   //The phone number in the format you specified in "output_format".

        @AuraEnabled
        public String phone_type;               //The type of phone number. Possible values : https://docs.experianaperture.io/phone-validation/experian-phone-validation/api-reference/phone-type/

        @AuraEnabled
        public String confidence;               //The outcome (confidence level) of the validation. Possible values : https://docs.experianaperture.io/phone-validation/experian-phone-validation/api-reference/confidence-level/

        @AuraEnabled
        public String ported_date;              //The date that the phone number was last ported if the number has been ported to a different network other than the originally assigned network. This value would be returned if the get_ported_date boolean is set to true.

        @AuraEnabled
        public String disposable_number;        //Indicates whether the phone number is a disposable number based on lookup list of disposable numbers. If the number can be found in the lookup list, the value returned will be "Yes". Otherwise, the value returned will be "Unknown". This value would be returned if the get_disposable_number boolean is set to true.
        
        // Default constructor
        public PhoneNumberResult() {} //NOPMD
    }

    public class PhoneNumberMetadata {
        @AuraEnabled
		public PhoneDetail phone_detail;
        
        // Default constructor
        public PhoneNumberMetadata() {} //NOPMD
	}

    public class PhoneDetail {
        @AuraEnabled
		public String original_operator_name;
        @AuraEnabled
		public String original_network_status;
        @AuraEnabled
		public String original_home_network_identity;
        @AuraEnabled
		public String original_country_prefix;
        @AuraEnabled
		public String original_country_name;
        @AuraEnabled
		public String original_country_iso;
        @AuraEnabled
		public String operator_name;
        @AuraEnabled
		public String network_status;
        @AuraEnabled
		public String home_network_identity;
        @AuraEnabled
		public String country_prefix;
        @AuraEnabled
		public String country_name;
        @AuraEnabled
		public String country_iso;
        @AuraEnabled
		public String is_ported;
        @AuraEnabled
		public String cache_value_days;
        @AuraEnabled
		public String date_cached;
        @AuraEnabled
		public String email_to_sms_address;
        @AuraEnabled
		public String email_to_mms_address;
        
        // Default constructor
        public PhoneDetail() {} //NOPMD
	}
}