/**
 * @description Class for managing Grant and Scholarship quotas for Offers.
 * Offers treats grants and scholarships as the same, hence this class
 * handles both.
 * @group Offers
 */
public inherited sharing class OfferGrantScholarshipQuotaService {

    private QuoteLinesSelector quoteLinesSelector;
    private Dao productDao;

    /**
     * @description Constructor for defining dependencies
     * @param quoteLinesSelector The QuoteLinesSelector dependency
     * @param productDao The data access object dependency for Product2
     */
    public OfferGrantScholarshipQuotaService(QuoteLinesSelector quoteLinesSelector, Dao productDao) {
        this.quoteLinesSelector = quoteLinesSelector;
        this.productDao = productDao;
    }

    /**
     * @description Updates the grant/scholarship quota based on the 
     * quote/quote line
     * @param quoteWithOldQuoteByIds The quotes (with their old quote) where 
     * scholarships/grants quotas should be updated for
     */
    public void updateQuota(Map<Id, QuoteWithOldQuote> quoteWithOldQuoteByIds) {
        
        List<SBQQ__QuoteLine__c> quoteLines = 
            quoteLinesSelector.selectByIdWithQuoteLines(quoteWithOldQuoteByIds.keySet());
        Map<Id, Product2> productById = new Map<Id, Product2>();
        QuotaUpdateStrategyFactory factory = new QuotaUpdateStrategyFactory();

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (isQuoteLineCappedGrantOrScholarship(quoteLine)) {
                QuoteWithOldQuote quoteWithOldQuote = 
                    quoteWithOldQuoteByIds.get(quoteLine.SBQQ__Quote__c);

                QuotaUpdateStrategy quotaUpdateStrategy = 
                    factory.getStrategy(QuoteWithOldQuote);

                /*
                For performance reasons, the grant/scholarship quotas values 
                are already queried as part of quote line (via relationships)
                However, to ensure the quota values are correctly updated when 
                there is more than 1 quote/quote line with the same grant/
                scholarship, the first time the quota values are queried, they 
                are storied and changes are maintained in productById
                E.g. Any, there are two quotelines for the same grant,
                it should deduct 2 instead of getting the quota values from the 
                quote line query which would then not account for the extra 
                deduction required        
                */
                if (productById.containsKey(quoteLine.SBQQ__Product__c)) {
                    productById.put(
                        quoteLine.SBQQ__Product__c, 
                        quotaUpdateStrategy.updateQuota(
                            productById.get(quoteLine.SBQQ__Product__c)
                        )
                    );
                } else {
                    Product2 queriedProduct = new Product2(
                        id = quoteLine.SBQQ__Product__c,
                        Quota_Accepted__c = quoteLine.SBQQ__Product__r.Quota_Accepted__c,
                        Quota_Assigned__c = quoteLine.SBQQ__Product__r.Quota_Assigned__c
                    );
                    productById.put(
                        quoteLine.SBQQ__Product__c, 
                        quotaUpdateStrategy.updateQuota(queriedProduct)
                    );
                }
            }
        }

        if(!productById.isEmpty()){
            productDao.updateRecords(productById.values());
        }

    }

    /**
     * @description A value object for new and old quote
     */
    public class QuoteWithOldQuote {

        private SBQQ__Quote__c currentQuote;
        private SBQQ__Quote__c oldQuote;

        /**
         * @description Constructor for depending values for the value object
         * The quote id of the current quote and old quote must match otherwise 
         * an IllegalArgumentException is thrown.
         * @param currentQuote The current quote
         * @param oldQuote The od quote (as in the state of the current quote before the transaction)
         */
        public QuoteWithOldQuote(SBQQ__Quote__c currentQuote, SBQQ__Quote__c oldQuote) {
            if (currentQuote.Id != oldQuote.Id) {
                throw new IllegalArgumentException('The new and old quote record ids do not match.');
            }
            this.currentQuote = currentQuote;
            this.oldQuote = oldQuote;
        }

        /**
         * @description Returns the current quote
         */
        public SBQQ__Quote__c getCurrentQuote() {
            return this.currentQuote;
        }

        /**
         * @description Returns the old quote
         */
        public SBQQ__Quote__c getOldQuote() {
            return this.oldQuote;
        }
    }

    private boolean isQuoteLineCappedGrantOrScholarship(SBQQ__QuoteLine__c quoteLine) {
        if((quoteLine.SBQQ__ProductFamily__c == 'Grant' 
                || quoteLine.SBQQ__ProductFamily__c == 'Scholarship') 
                && quoteLine.SBQQ__Product__r.Type__c == 'Capped') {
            return true;
        }
        return false;
    }

    private interface QuotaUpdateStrategy {
        Product2 updateQuota(Product2 product);
    }

    private class QuoteSignedQuotaStrategy implements QuotaUpdateStrategy {

        public Product2 updateQuota(Product2 product) {
            Product2 updatedProduct = new Product2();
            updatedProduct.Id = product.Id;
            updatedProduct.Quota_Accepted__c = product.Quota_Accepted__c + 1;
            updatedProduct.Quota_Assigned__c = product.Quota_Assigned__c - 1;
            return updatedProduct;
        }

    }

    private class QuoteTerminatedBeforeSignQuotaStrategy implements QuotaUpdateStrategy {
        
        public Product2 updateQuota(Product2 product) {
            Product2 updatedProduct = new Product2();
            updatedProduct.Id = product.Id;
            updatedProduct.Quota_Assigned__c = product.Quota_Assigned__c - 1;
            return updatedProduct;
        }

    }

    private class QuoteDeferredAfterSigningQuotaStrategy implements QuotaUpdateStrategy {
        
        public Product2 updateQuota(Product2 product) {
            Product2 updatedProduct = new Product2();
            updatedProduct.Id = product.Id;
            updatedProduct.Quota_Accepted__c = product.Quota_Accepted__c - 1;
            return updatedProduct;
        }

    }

    private class QuoteDeferredBeforeSigningQuotaStrategy implements QuotaUpdateStrategy {
        
        public Product2 updateQuota(Product2 product) {
            Product2 updatedProduct = new Product2();
            updatedProduct.Id = product.Id;
            updatedProduct.Quota_Assigned__c = product.Quota_Assigned__c - 1;
            return updatedProduct;
        }

    }

    private class QuotaUpdateStrategyFactory {

        public QuotaUpdateStrategy getStrategy(QuoteWithOldQuote quoteWithOldQuote) {
            SBQQ__Quote__c quote = quoteWithOldQuote.getCurrentQuote();
            SBQQ__Quote__c oldQuote = quoteWithOldQuote.getOldQuote();
            if (quote.SBQQ__Status__c == 'Signed') {
                return new QuoteSignedQuotaStrategy();
            } else if (quote.SBQQ__Status__c == 'Rejected' 
                    || quote.SBQQ__Status__c == 'Cancelled' 
                    || quote.SBQQ__Status__c == 'Expired and regenerated' 
                    || quote.SBQQ__Status__c == 'Expired') {
                return new QuoteTerminatedBeforeSignQuotaStrategy();
            } else if (quote.SBQQ__Status__c == 'Deferred' 
                    && oldQuote.SBQQ__Status__c == 'Signed') {
                return new QuoteDeferredAfterSigningQuotaStrategy();
            } else if (quote.SBQQ__Status__c == 'Deferred' 
                    && oldQuote.SBQQ__Status__c != 'Signed') {
                return new QuoteDeferredBeforeSigningQuotaStrategy();
            } else {
                throw new IllegalArgumentException('No matching strategy found for quote.');
            }
        }

    }
}