/**
 * @description Context for passing data between OffersDocuSignCreateSignatureHandler handlers
 * @group Offers DocuSign Signature
 */
public with sharing class OffersDocuSignCreateSignReqContext {
    
    private Id quoteId;
    private Signer applicantSigner;
    private Signer guardianSigner;
    private String envelopId;
    private String docuSignAccountId;

    /**
     * @description Constructor with no parameter for unit testing purposes
     * This constructor can be used when unit tests stub/mock Quote data 
     * removing the need to use the constructor with quoteId
     */
    @testVisible
    private OffersDocuSignCreateSignReqContext() {
        System.debug('OffersDocuSignCreateSignReqContext constructor with no parameters');
    }     

    /**
     * @description Constructor which will also setup the quote
     * with the relevant data based on the quote Id
     * @param quoteId Id of the quote
     */
    public OffersDocuSignCreateSignReqContext(Id quoteId) {
        this.quoteId = quoteId;
    }

    public Id getQuoteId() {
        return quoteId;
    }

    public void setApplicantSigner(Signer applicantSigner) {
        this.applicantSigner = applicantSigner;
    }

    public Signer getApplicantSigner() {
        return this.applicantSigner;
    }

    public void setGuardianSigner(Signer guardianSigner) {
        this.guardianSigner = guardianSigner;
    }

    public Signer getGuardianSigner() {
        return this.guardianSigner;
    }

    public void setEnvelopId(String envelopId) {
        this.envelopId = envelopId;
    }

    public String getEnvelopId() {
        return this.envelopId;
    }

    public void setDocuSignAccountId(String accountId) {
        this.docuSignAccountId = accountId;
    }

    public String getDocuSignAccountId() {
        return this.docuSignAccountId;
    }

    /**
     * @description Signer details
     */
    public class Signer {
        private String email;
        private String name;
        private String userId;

        /**
         * @description Constructor for Signer, contains mandatory fields required
         * @param name Name of the signer
         * @param email Email of the signer
         */
        public Signer(String name, String email) {
            this.name = name;
            this.email = email;
        }
        
        /**
         * @description Optional setter for the user Id
         * @param userId The userId to be set that can be used in DocuSign
         */
        public void setUserId(String userId) {
            this.userId = userId;
        }

        /**
         * @description Returns signer name
         */
        public String getName() {
            return this.name;
        }

        /**
         * @description Returns signer email
         */
        public String getEmail() {
            return this.email;
        }

        /**
         * @description Returns signer userId
         */
        public String getUserId() {
            return this.userId;
        }

    }
}