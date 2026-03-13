/**
 * @description Handler to get the required signers for an offer
 * @group Offers DocuSign Signature
 */
public inherited sharing class OffersSignersRequiredHandler implements OffersDocuSignCreateSignatureHandler {
    
    @testVisible
    private QuotesSelector quotesSelector;

    @testVisible
    private OffersDocuSignCreateSignatureHandler over18GenerateOffersEnvelopHandler;

    @testVisible 
    private OffersDocuSignCreateSignatureHandler under18GenerateOffersEnvelopHandler;

    public OffersSignersRequiredHandler() {
        this.quotesSelector = new QuotesSelector();
        this.over18GenerateOffersEnvelopHandler = new GenOver18OffersDocuSignEnvelopReq();
        this.under18GenerateOffersEnvelopHandler = new GenUnder18OffersDocuSignEnvelopReq();
    }

    /**
     * @description Handler which retrieves and constructs the required signers
     * These signers would be used for constructing the signer details required
     * for DocuSign create envelop
     * If no signers are found, so exception should probably get thrown (TODO)
     */
    public void handle(OffersDocuSignCreateSignReqContext context) {
        
        SBQQ__Quote__c quote = quotesSelector.selectQuoteById
            (new Set<String>{String.valueOf(context.getQuoteId())})[0];

        // Under 18 applicants require guardians to sign
        if (quote.SBQQ__PrimaryContact__r.Under_18__c && quote.Guardian_Email__c != null) {
            context.setApplicantSigner(this.constructApplicantSigner(quote));
            // Guardian that has to sign
            context.setGuardianSigner(this.constructGuardianSigner(quote));
            under18GenerateOffersEnvelopHandler.handle(context);
        } else {
            context.setApplicantSigner(this.constructApplicantSigner(quote));
            over18GenerateOffersEnvelopHandler.handle(context);
        }
    }

    private OffersDocuSignCreateSignReqContext.Signer constructApplicantSigner(SBQQ__Quote__c quote) {
        if (!validateQuoteDataForSigning(quote)) {
            throw new IllegalArgumentException(
                'DocuSign Signer requires: First Name, Last Name, Email. One or more values are missing');
        }
        OffersDocuSignCreateSignReqContext.Signer applicantSigner = 
            new OffersDocuSignCreateSignReqContext.Signer(
                getFullNameNameFromQuote(quote), quote.Email__c);
        applicantSigner.setUserId(quote.Id);
        return applicantSigner;
    }

    private OffersDocuSignCreateSignReqContext.Signer constructGuardianSigner(SBQQ__Quote__c quote) {
        
        if (String.isBlank(quote.Guardian_First_Name__c) || 
                String.isBlank(quote.Guardian_Last_Name__c) || 
                String.isBlank(quote.Guardian_Email__c)) {
            throw new IllegalArgumentException('The Guardian\'s signer requires First Name, Last Name, Email for DocuSign signing. One or more values are missing');
        }

        String guardianName = quote.Guardian_First_Name__c + ' ' 
            + quote.Guardian_Last_Name__c;
        return new OffersDocuSignCreateSignReqContext.Signer(
            guardianName, quote.Guardian_Email__c);
    }

    /**
     * @author Vinothraja 
     * @description Validates Quote Data - Name and Email are mandatory (handles mononymous names)
     * @date 16 Nov 2022 
     * @param SBQQ__Quote__c quote
     * @return boolean
    */
    public static boolean validateQuoteDataForSigning(SBQQ__Quote__c quote) {
        if (String.isBlank(quote.Email__c) || 
                (quote.SBQQ__PrimaryContact__r.Is_Mononymous_Name__c && String.isBlank(quote.SBQQ__PrimaryContact__r.Last_Name__c)) || 
                (!quote.SBQQ__PrimaryContact__r.Is_Mononymous_Name__c && (String.isBlank(quote.SBQQ__PrimaryContact__r.First_Name__c) || 
                String.isBlank(quote.SBQQ__PrimaryContact__r.Last_Name__c)))) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @author Vinothraja 
     * @description Handles mononymous names while generating the full name of the Signer
     * @date 16 Nov 2022 
     * @param SBQQ__Quote__c quote
     * @return String
    */
    public static String getFullNameNameFromQuote(SBQQ__Quote__c quote) {
        if (quote.SBQQ__PrimaryContact__r.Is_Mononymous_Name__c) {
            return quote.SBQQ__PrimaryContact__r.Last_Name__c;
        }
        return quote.SBQQ__PrimaryContact__r.First_Name__c + ' ' + quote.SBQQ__PrimaryContact__r.Last_Name__c;
    }

}