/**
 * @description Test class for OffersSignersRequiredHandler
 */
@isTest(isParallel=true)
public class OffersSignersRequiredHandler_Test {

    private enum QuoteSelectorScenario {
        APPLICANT_EMAIL_MISSING, 
        APPLICANT_FIRST_NAME_MISSING, 
        APPLICANT_LAST_NAME_MISSING,
        APPLICANT_FIRST_NAME_MISSING_MONONAME,
        APPLICANT_OVER_18,
        APPLICANT_UNDER_18,
        APPLICANT_UNDER_18_GUARDIAN_FIRST_NAME_MISSING,
        APPLICANT_UNDER_18_GUARDIAN_LAST_NAME_MISSING,
        APPLICANT_UNDER_18_GUARDIAN_EMAIL_MISSING,
        APPLICANT_UNDER_18_GUARDIAN_EMAIL_PROVIDED_FALSE
    }

    /**
     * @description Test scenario where Applicant last name is missing.
     */
    @isTest
    static void shouldThrowExceptionBecauseLastNameIsMissing() {
        try {
            OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();

            OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
            signersRequiredHandler.quotesSelector =  
                (QuotesSelector) Test.createStub(QuotesSelector.class, 
                new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_LAST_NAME_MISSING));
            signersRequiredHandler.handle(context);
            System.assert(false, 'Expected IllegalArgumentException as last name is missing');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException due to missing last name');
        } catch (Exception e) {
            System.assert(false, 'Expected IllegalArgumentException instead of Exception.');
        }
    }

    /**
     * @description Test scenario where Applicant first name is missing.
     */
    @isTest
    static void shouldThrowExceptionBecauseFirstNameIsMissing() {
        try {
            OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
            OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
            signersRequiredHandler.quotesSelector =  
                (QuotesSelector) Test.createStub(QuotesSelector.class, 
                new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_FIRST_NAME_MISSING));
            signersRequiredHandler.handle(context);
            System.assert(false, 'Expected IllegalArgumentException as first name is missing');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException due to missing first name');
        } catch (Exception e) {
            System.assert(false, 'Expected IllegalArgumentException instead of Exception.');
        }
    }

    /**
     * @description Test scenario where Applicant first name is missing, but is a Mononymous name
     */
    @isTest
    static void shouldNotThrowExceptionBecauseFirstNameIsMissing() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
        signersRequiredHandler.quotesSelector =  
            (QuotesSelector) Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_FIRST_NAME_MISSING_MONONAME));
        signersRequiredHandler.over18GenerateOffersEnvelopHandler = 
            new OffersDocuSignCreateSignatureHandlerStub();
        signersRequiredHandler.handle(context);
        System.assertNotEquals(null, context.getApplicantSigner().getName(), 
            'Expected name to be set when Applicant has a Mononymous name');
    }

    /**
     * @description Test scenario where Applicant email is missing.
     */
    @isTest
    static void shouldThrowExceptionBecauseEmailIsMissing() {
        try {
            OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
            OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
            signersRequiredHandler.quotesSelector =  
                (QuotesSelector) Test.createStub(QuotesSelector.class, 
                new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_EMAIL_MISSING));
            signersRequiredHandler.handle(context);
            System.assert(false, 'Expected IllegalArgumentException as email is missing');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException due to missing email');
        } catch (Exception e) {
            System.assert(false, 'Expected IllegalArgumentException instead of Exception.');
        }
    }

    @isTest
    static void shouldNotSetGuardianDetailsWhenApplicantIsOver18() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
        
        signersRequiredHandler.quotesSelector =  
            (QuotesSelector)Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_OVER_18));
        
        signersRequiredHandler.over18GenerateOffersEnvelopHandler = 
            new OffersDocuSignCreateSignatureHandlerStub();
        
        signersRequiredHandler.handle(context);

        System.assertEquals(null, context.getGuardianSigner(), 
            'Expected no guardian to be set because applicant is over 18 and does not require a guardian to sign');
    }

    @isTest
    static void shouldSetApplicantDetailsWhenApplicantIsOver18() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
        
        signersRequiredHandler.quotesSelector =  
            (QuotesSelector)Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_OVER_18));
        
        signersRequiredHandler.over18GenerateOffersEnvelopHandler = 
            new OffersDocuSignCreateSignatureHandlerStub();
        
        signersRequiredHandler.handle(context);

        System.assertNotEquals(null, context.getApplicantSigner(), 
            'Expected applicant to be set when applicant is over 18');
    }

    @isTest
    static void shouldSetApplicantDetailsWhenApplicantIsUnder18() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
        
        signersRequiredHandler.quotesSelector =  
            (QuotesSelector)Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_UNDER_18));

        signersRequiredHandler.under18GenerateOffersEnvelopHandler = 
            new OffersDocuSignCreateSignatureHandlerStub();
        
        signersRequiredHandler.handle(context);

        System.assertNotEquals(null, context.getApplicantSigner(), 
            'Expected applicant to be set when applicant is under 18');
    }

    @isTest
    static void shouldSetGuardianDetailsWhenApplicantIsUnder18() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
        
        signersRequiredHandler.quotesSelector =  
            (QuotesSelector)Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_UNDER_18));

        signersRequiredHandler.under18GenerateOffersEnvelopHandler = 
            new OffersDocuSignCreateSignatureHandlerStub();
        
        signersRequiredHandler.handle(context);

        System.assertNotEquals(null, context.getGuardianSigner(), 
            'Expected guardian details to be set when applicant is under 18');
    }

    @isTest
    static void shouldThrowExceptionWhenApplicantIsUnder18AndGuardianFirstNameIsMissing() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
        
        signersRequiredHandler.quotesSelector =  
            (QuotesSelector)Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_UNDER_18_GUARDIAN_FIRST_NAME_MISSING));
        
        signersRequiredHandler.under18GenerateOffersEnvelopHandler = 
            new OffersDocuSignCreateSignatureHandlerStub();

        try {
            signersRequiredHandler.handle(context);
            System.assert(false, 
                'Expected IllegalArgumentException because guardian first name is missing');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException instead of Exception as guardian first name is missing');
        }
    }

    @isTest
    static void shouldThrowExceptionWhenApplicantIsUnder18AndGuardianLastNameIsMissing() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
        
        signersRequiredHandler.quotesSelector =  
            (QuotesSelector)Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_UNDER_18_GUARDIAN_LAST_NAME_MISSING));
        
        signersRequiredHandler.under18GenerateOffersEnvelopHandler = 
            new OffersDocuSignCreateSignatureHandlerStub();

        try {
            signersRequiredHandler.handle(context);
            System.assert(false, 
                'Expected IllegalArgumentException because guardian last name is missing');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException instead of Exception as guardian last name is missing');
        }
    }

    @isTest
    static void shouldThrowExceptionWhenApplicantIsUnder18AndGuardianEmailIsMissing() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        OffersSignersRequiredHandler signersRequiredHandler = new OffersSignersRequiredHandler();
        
        signersRequiredHandler.quotesSelector =  
            (QuotesSelector)Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.APPLICANT_UNDER_18_GUARDIAN_EMAIL_MISSING));
        
        signersRequiredHandler.under18GenerateOffersEnvelopHandler = 
            new OffersDocuSignCreateSignatureHandlerStub();

        try {
            signersRequiredHandler.handle(context);
            System.assert(false, 
                'Expected IllegalArgumentException because guardian email is missing');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException instead of Exception as guardian email is missing');
        }
    }

    private class QuotesSelectorStub implements System.StubProvider {

        private QuoteSelectorScenario scenario;

        public QuotesSelectorStub(QuoteSelectorScenario scenario) {
            this.scenario = scenario;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
            Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
            List<Object> listOfArgs) {

            /**
             * JSON Sobject deserialization is used to avoid dml 
             * operations with creating a quote that relates to a 
             * contact.
             * The alternative would be to insert a contact and then 
             * insert a quote which would require a lot of work and 
             * slow down the unit test methods due to database operations
             * to create and rollback during the unit test run. 
             */
            switch on scenario {
                when APPLICANT_LAST_NAME_MISSING {
                    String applicantLastNameMissingQuoteJson = 
                        '{"attributes":{"type":"SBQQ__Quote__c"}, "Email__c":"test@test.com", "Contact_Firstname__c": "John", "SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"First_Name__c":"Black","Last_Name__c":"","Is_Mononymous_Name__c":false}}';
                    SBQQ__Quote__c applicantLastNameMissingQuote = 
                        (SBQQ__Quote__c) JSON.deserialize(applicantLastNameMissingQuoteJson, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{applicantLastNameMissingQuote};
                }
                when APPLICANT_FIRST_NAME_MISSING {
                    String applicantFirstNameMissingQuoteJson = 
                        '{"attributes":{"type":"SBQQ__Quote__c"}, "Email__c":"test@test.com", "Contact_Lastname__c": "Smith", "SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"First_Name__c":"","Last_Name__c":"Adam","Is_Mononymous_Name__c":false}}';
                    SBQQ__Quote__c applicantFirstNameMissingQuote = 
                        (SBQQ__Quote__c) JSON.deserialize(applicantFirstNameMissingQuoteJson, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{applicantFirstNameMissingQuote};
                }
                when APPLICANT_FIRST_NAME_MISSING_MONONAME {
                    String applicantFirstNameMissingQuoteJson = 
                        '{"attributes":{"type":"SBQQ__Quote__c"}, "Email__c":"test@test.com", "Contact_Lastname__c": "Smith", "SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"First_Name__c":"","Last_Name__c":"Adam","Is_Mononymous_Name__c":true}}';
                    SBQQ__Quote__c applicantFirstNameMissingQuote = 
                        (SBQQ__Quote__c) JSON.deserialize(applicantFirstNameMissingQuoteJson, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{applicantFirstNameMissingQuote};
                }
                when APPLICANT_EMAIL_MISSING {
                    String applicantEmailMissingQuoteJson = 
                        '{"attributes":{"type":"SBQQ__Quote__c"}, "Email__c":"", "Contact_Firstname__c": "John", "Contact_Lastname__c": "Smith", "SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"Last_Name__c":"Adam","First_Name__c":"Black","Is_Mononymous_Name__c":false}}';
                    SBQQ__Quote__c applicantEmailMissingQuote = 
                        (SBQQ__Quote__c) JSON.deserialize(applicantEmailMissingQuoteJson, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{applicantEmailMissingQuote};
                }
                when APPLICANT_OVER_18 {
                    String applicantOver18Json = 
                        '{"attributes":{"type":"SBQQ__Quote__c"},"Email__c":"test@test.com","Contact_Firstname__c":"John","Contact_Lastname__c":"Oldman","SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"Last_Name__c":"Adam","First_Name__c":"Black","Is_Mononymous_Name__c":false,"Under_18__c":false}}';
                    SBQQ__Quote__c applicantOver18Quote = 
                        (SBQQ__Quote__c) JSON.deserialize(applicantOver18Json, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{applicantOver18Quote};
                } 
                when APPLICANT_UNDER_18 {
                    String applicantUnder18Json = 
                        '{"attributes":{"type":"SBQQ__Quote__c"},"Email__c":"test@test.com","Contact_Firstname__c":"Jane","Contact_Lastname__c":"Young","Guardian_First_Name__c":"Thor", "Guardian_Last_Name__c":"Smith", "Guardian_Email__c": "guardian@test.com", "Guardian_Email_Provided__c": true,"SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"Last_Name__c":"Adam","First_Name__c":"Black","Is_Mononymous_Name__c":false,"Under_18__c":true}}';
                    SBQQ__Quote__c applicantUnder18Quote = 
                        (SBQQ__Quote__c) JSON.deserialize(applicantUnder18Json, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{applicantUnder18Quote};
                }
                when APPLICANT_UNDER_18_GUARDIAN_FIRST_NAME_MISSING {
                    String applicantUnder18NoGuardianFirstNameJson = 
                        '{"attributes":{"type":"SBQQ__Quote__c"},"Email__c":"test@test.com","Contact_Firstname__c":"Jane","Contact_Lastname__c":"Young","Guardian_First_Name__c":"", "Guardian_Last_Name__c":"Smith", "Guardian_Email__c": "guardian@test.com", "Guardian_Email_Provided__c": true,"SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"Last_Name__c":"Adam","First_Name__c":"Black","Is_Mononymous_Name__c":false,"Under_18__c":true}}';
                    SBQQ__Quote__c applicantUnder18NoGuardianFirstNameQuote = 
                        (SBQQ__Quote__c) JSON.deserialize(applicantUnder18NoGuardianFirstNameJson, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{applicantUnder18NoGuardianFirstNameQuote};
                }
                when APPLICANT_UNDER_18_GUARDIAN_LAST_NAME_MISSING {
                    String applicantUnder18NoGuardianLastNameJson = 
                        '{"attributes":{"type":"SBQQ__Quote__c"},"Email__c":"test@test.com","Contact_Firstname__c":"Jane","Contact_Lastname__c":"Young","Guardian_First_Name__c":"Sarah", "Guardian_Last_Name__c":"", "Guardian_Email__c": "guardian@test.com", "Guardian_Email_Provided__c": true,"SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"Last_Name__c":"Adam","First_Name__c":"Black","Is_Mononymous_Name__c":false,"Under_18__c":true}}';
                    SBQQ__Quote__c applicantUnder18NoGuardianLastNameQuote = 
                        (SBQQ__Quote__c) JSON.deserialize(applicantUnder18NoGuardianLastNameJson, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{applicantUnder18NoGuardianLastNameQuote};
                }
                when APPLICANT_UNDER_18_GUARDIAN_EMAIL_MISSING {
                    String applicantUnder18NoGuardianEmailJson = 
                        '{"attributes":{"type":"SBQQ__Quote__c"},"Email__c":"test@test.com","Contact_Firstname__c":"Jane","Contact_Lastname__c":"Young","Guardian_First_Name__c":"Sarah", "Guardian_Last_Name__c":"Brown", "Guardian_Email__c": "", "Guardian_Email_Provided__c": true,"SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"Last_Name__c":"Adam","First_Name__c":"Black","Is_Mononymous_Name__c":false,"Under_18__c":true}}';
                    SBQQ__Quote__c applicantUnder18NoGuardianEmailQuote = 
                        (SBQQ__Quote__c) JSON.deserialize(applicantUnder18NoGuardianEmailJson, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{applicantUnder18NoGuardianEmailQuote};
                }
                when APPLICANT_UNDER_18_GUARDIAN_EMAIL_PROVIDED_FALSE {
                    String applicantUnder18GuardianEmailProvidedFalseJson = 
                        '{"attributes":{"type":"SBQQ__Quote__c"},"Email__c":"test@test.com","Contact_Firstname__c":"Jane","Contact_Lastname__c":"Young","Guardian_First_Name__c":"Morris", "Guardian_Last_Name__c":"Brown", "Guardian_Email__c": "test@test.com", "Guardian_Email_Provided__c": false,"SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"Last_Name__c":"Adam","First_Name__c":"Black","Is_Mononymous_Name__c":false,"Under_18__c":true}}';
                    SBQQ__Quote__c applicantUnder18GuardianEmailProvidedFalseQuote = 
                        (SBQQ__Quote__c) JSON.deserialize(applicantUnder18GuardianEmailProvidedFalseJson, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{applicantUnder18GuardianEmailProvidedFalseQuote};
                }
            }
            return null;
        }
    }

}