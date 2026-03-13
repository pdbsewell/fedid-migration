/**
 * @author      Sachin Shetty
 * @description Wrapper class to fetch email wrapper
 * @group       Wrapper
 * @testclass   EmailValidationWrapper_Test
 * @revision    2022-08-26 - Sachin Shetty - Created
**/
public with sharing class EmailValidationWrapper {

    // Source : https://docs.experianaperture.io/email-validation/experian-email-validation-v2/api-reference/confidence-level/
    public static final Map<String, Map<String, String>> verboseOutputDescriptionsByConfidence = new Map<String, Map<String, String>> {
        'verified' => new Map<String, String>{
            'verified' => 'The mailbox exists, is reachable, and is not known to be illegitimate or disposable.'
        },
        'undeliverable' => new Map<String, String>{
            'mailboxDisabled' => 'The mailbox is disabled.',
            'mailboxDoesNotExist' => 'The mailbox does not exist.',
            'mailboxFull' => 'The mailbox is full.',
            'syntaxFailure' => 'The syntax of the specified email address is incorrect.',
            'internationalCharactersUnsupported' => 'The domain does not support the use of international characters (e.g. á, é or ø).'
        },
        'unreachable' => new Map<String, String>{
            'unreachable' => 'The domain is not responding to validation requests or does not have any active mail servers.'
        },
        'illegitimate' => new Map<String, String>{
            'illegitimate' => 'Seed, spamtrap, black hole, technical role account or inactive domain.',
            'roleAccount' => 'Role accounts such as support, sales, info etc.',
            'typoDomain' => 'The domain of the email address you have provided was close to a common domain and, although it exists, it is highly unlikely to be correct.',
            'localPartSpamTrap' => 'Known local portions of the email address that may indicate spam traps.',
            'Profanity' => 'The email address contains profanity.'
        },
        'disposable' => new Map<String, String>{
            'disposable' => 'The domain is administered by a disposable email provider (e.g. Mailinator).'
        },
        'unknown' => new Map<String, String>{
            'unknown' => 'We were unable to conclusively verify or invalidate the email address.',
            'timeout' => 'The request timed out due to the host domain not responding in time.',
            'acceptAll' => 'The domain is accept-all, so the email address cannot be validated.',
            'relayDenied' => 'The result was validated at the incorrect mail exchanger.',
            'BLANK' => 'You are submitting requests at a faster rate than allowed by the email service providers for the domains you are checking.'
        },
        'forbidden' => new Map<String, String>{
            'forbidden' => 'Invalid authentication token or insufficient Experian credits.'
        },
        'service unavailable' => new Map<String, String>{
            'service unavailable' => 'Experian service currently unavailable.'
        }
    };

    /**
     * @author      Sachin Shetty
     * @description Setting used to control certain features of Experian data validation
     * @param       na
     * @return      EDQ_Settings__c instance
     * @revision    2022-08-31 - Sachin Shetty - Created
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
     * @description Static reference to show generic error message or actual validation message for email validation 
     * @param       na
     * @return      Boolean
     * @revision    2022-08-31 - Sachin Shetty - Created
     */
    public static Boolean showGenericErrorMessage {
        get {
            if (showGenericErrorMessage == null) {
                Boolean isShowGeneric = EDQSettings.Email_Validation_Show_Generic_Error__c;
                showGenericErrorMessage = isShowGeneric == null
                                        ? false 
                                        : isShowGeneric;
            }
            return showGenericErrorMessage;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description The email address wrapper used by the lwc
     * @revision    2022-08-26 - Sachin Shetty - Created
     */
    public class EmailWrapper {
        @AuraEnabled
        public String currentRecordId {get; set;}
        @AuraEnabled
        public String email {get; set;}
        @AuraEnabled
        public String confidence {get; set;}
        @AuraEnabled
        public String verboseOutput {get; set;}
        @AuraEnabled
        public List<String> didYouMean {get; set;}
        @AuraEnabled
        public String type {get; set;}

        // wrapper constructor
        public EmailWrapper(){
            this.currentRecordId = '';
            this.email = '';
            this.confidence = '';
            this.verboseOutput = '';
            this.didYouMean = new List<String>();
            this.type = '';
        }
    }
}