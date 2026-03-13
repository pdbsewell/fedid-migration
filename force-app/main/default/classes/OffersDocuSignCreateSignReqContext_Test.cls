/**
 * @description Test class for OffersDocuSignCreateSignReqContext
 */
@isTest(isParallel=true)
public class OffersDocuSignCreateSignReqContext_Test {

    @isTest
    static void shouldGetQuoteIdValuesCorrectly() {

        // A quote id string value
        // This data does not exist and is only used for the 
        // purposes of unit testing
        // This removes the need to construct quote test data
        // with database operations
        Id quoteId = String.valueOf('a9L5P00000000ekUAA');

        OffersDocuSignCreateSignReqContext context = 
            new OffersDocuSignCreateSignReqContext(quoteId);
        System.assertEquals(quoteId, context.getQuoteId(), 
            'Expected getQuoteId to return quoteId previous provided in the constructor');
    }

    @isTest
    static void shouldGetAndSetEnvelopIdCorrectly() {
        String envelopId = 'c8839145-c5c2-48b0-a00e-56e01384076c';

        OffersDocuSignCreateSignReqContext context = 
            new OffersDocuSignCreateSignReqContext();
        context.setEnvelopId(envelopId);
        System.assertEquals(envelopId, context.getEnvelopId(), 
            'Expected getEnvelopId to match envelop Id provided in setEnvelopId');
    }

    @isTest
    static void shouldGetAndSetDocuSignAccountIdCorrectly() {
        String accountId = '6a6b498e-b3d8-4d1b-ade2-68ca24f09b10';
        OffersDocuSignCreateSignReqContext context = 
            new OffersDocuSignCreateSignReqContext();
        context.setDocuSignAccountId(accountId);
        System.assertEquals(accountId, 
            context.getDocuSignAccountId(), 
            'Expected getDocuSignAccountId to match account Id provided in setDocuSignAccountId'
        );
    }

    @isTest
    static void shouldSetAndGetApplicantSignerCorrectly() {
        String applicantName = 'Summer Smith';
        String applicantEmail = 'test@test.com';
        OffersDocuSignCreateSignReqContext context = 
            new OffersDocuSignCreateSignReqContext();
        OffersDocuSignCreateSignReqContext.Signer applicantSigner = 
            new OffersDocuSignCreateSignReqContext.Signer(applicantName, 
                applicantEmail);
        applicantSigner.setUserId('abc123');
        context.setApplicantSigner(applicantSigner);

        OffersDocuSignCreateSignReqContext.Signer signerFromGetter = 
            context.getApplicantSigner();
        System.assertEquals(applicantName, signerFromGetter.getName(), 
            'ApplicantSigner getter and setter not returning matching results');
        System.assertEquals(applicantEmail, signerFromGetter.getEmail(), 
            'ApplicantSigner getter and setter not returning matching results');
        System.assertEquals('abc123', signerFromGetter.getUserId(), 
            'ApplicantSigner userId does not match');
    }

    @isTest
    static void shouldSetAndGetGuardianSignerCorrectly() {
        String guardianName = 'Beth Smith';
        String guardianEmail = 'test@test.com';
        OffersDocuSignCreateSignReqContext context = 
            new OffersDocuSignCreateSignReqContext();
        OffersDocuSignCreateSignReqContext.Signer guardianSigner = 
            new OffersDocuSignCreateSignReqContext.Signer(guardianName, guardianEmail);
        context.setGuardianSigner(guardianSigner);

        OffersDocuSignCreateSignReqContext.Signer signerFromGetter = 
            context.getGuardianSigner();
        System.assertEquals(guardianName, signerFromGetter.getName(), 
            'GuardianSigner getter and setter not returning matching results');
        System.assertEquals(guardianEmail, signerFromGetter.getEmail(), 
            'GuardianSigner getter and setter not returning matching results');
    }

}