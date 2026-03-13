/**
 * @author      Sachin Shetty
 * @description Wrapper class for Email validation response from Experian
 *              For more info, refer https://docs.experianaperture.io/email-validation/experian-email-validation-v2/api-reference/api-specification/#/Email%20Validation/post_email_validate_v2
 * @group       Wrapper
 * @testclass   EDQEmailService_Test
 * @revision    2022-08-26 - Sachin Shetty - Created
**/
public with sharing class EDQEmailDAO {
    //Request
    public class EmailRequest {
        @AuraEnabled
        public String email {get; set;}

        public EmailRequest(String email) {
            this.email = email;
        }
    }

    //Response
    public class EmailResponse {
        @AuraEnabled
        public EmailResult result {get; set;}

        @AuraEnabled
        public EmailMetadata metadata {get; set;}
    }

    public class EmailResult {
        @AuraEnabled
        public String email {get; set;}

        @AuraEnabled
        public String confidence {get; set;}

        @AuraEnabled
        public String verbose_output {get; set;}

        @AuraEnabled
        public List<String> did_you_mean {get; set;}
    }

    public class EmailMetadata {
        @AuraEnabled
		public DomainDetail domain_detail {get; set;}
	}

    public class DomainDetail {
        @AuraEnabled
        public String type {get; set;}
	}
}