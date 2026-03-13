/**
 * @author       : Sachin Shetty
 * @date         : 17-08-2025
 * @group        : Test Class
 * @description  : Test Class for EDQPhoneNumberDAO
 * @revision
 * 		17-08-2025	Sachin Shetty	Created
**/
@IsTest(isParallel=true)
public class EDQPhoneNumberDAO_Test {
	@IsTest
    static void testPhoneNumberResponseWithDefaults() {
        // GIVEN - A blank PhoneNumberResponse with default constructors
        EDQPhoneNumberDAO.PhoneNumberResponse response = new EDQPhoneNumberDAO.PhoneNumberResponse();
        response.result = new EDQPhoneNumberDAO.PhoneNumberResult();
        response.metadata = new EDQPhoneNumberDAO.PhoneNumberMetadata();
        response.metadata.phone_detail = new EDQPhoneNumberDAO.PhoneDetail();

        // WHEN - Assign values to fields
        response.result.validated_phone_number = '+61412345678';
        response.result.formatted_phone_number = '(0412) 345 678';
        response.result.phone_type = 'Mobile';
        response.result.confidence = 'Valid';
        response.result.ported_date = '2025-01-01';
        response.result.disposable_number = 'No';

        response.metadata.phone_detail.original_operator_name = 'Optus';
        response.metadata.phone_detail.original_network_status = 'Active';
        response.metadata.phone_detail.original_home_network_identity = '12345';
        response.metadata.phone_detail.original_country_prefix = '+61';
        response.metadata.phone_detail.original_country_name = 'Australia';
        response.metadata.phone_detail.original_country_iso = 'AU';
        response.metadata.phone_detail.operator_name = 'Telstra';
        response.metadata.phone_detail.network_status = 'Inactive';
        response.metadata.phone_detail.home_network_identity = '67890';
        response.metadata.phone_detail.country_prefix = '+61';
        response.metadata.phone_detail.country_name = 'Australia';
        response.metadata.phone_detail.country_iso = 'AU';
        response.metadata.phone_detail.is_ported = 'Yes';
        response.metadata.phone_detail.cache_value_days = '5';
        response.metadata.phone_detail.date_cached = '2025-08-18';
        response.metadata.phone_detail.email_to_sms_address = 'sms@test.com';
        response.metadata.phone_detail.email_to_mms_address = 'mms@test.com';

        // THEN - Verify values are correctly assigned
        Assert.areEqual('+61412345678', response.result.validated_phone_number);
        Assert.areEqual('Mobile', response.result.phone_type);
        Assert.areEqual('Valid', response.result.confidence);
        Assert.areEqual('Optus', response.metadata.phone_detail.original_operator_name);
        Assert.areEqual('Telstra', response.metadata.phone_detail.operator_name);
        Assert.areEqual('Australia', response.metadata.phone_detail.country_name);
        Assert.areEqual('Yes', response.metadata.phone_detail.is_ported);
        Assert.areEqual('sms@test.com', response.metadata.phone_detail.email_to_sms_address);
    }
}