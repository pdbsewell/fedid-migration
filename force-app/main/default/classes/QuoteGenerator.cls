/**
* @author David Browaeys
* @date 21/10/2019
* @group SF Offer
* @description This class allow the generation of a CPQ quote from opportunity
* @example
* //create from opportunity
* Boolean result = new QuoteService.QuoteGenerator(opps[0]).execute();
* //update quote and add products
* QuoteService.QuoteGenerator = new QuoteService.QuoteGenerator(quoteId)
*     .loadQuote()
*     .loadProduct(product1)
*     .loadProduct(product2)
*     .addProductsToQuote()
*     .calculate(QuoteCreationCallback.class.toString())
*/
public without sharing class QuoteGenerator {
    /********VARIABLES**********/
    public Boolean manualISCAEdit = false;
    @TestVisible private Opportunity opp;
    @TestVisible private SBQQ__Quote__c quote;
    @TestVisible private OpportunityLineItem[] lines;
    private Associated_Clause__c[] manualClauses;
    private String currencyIsoCode;
    private String quoteId;
    private Boolean requiredReview = false;
    private CPQ_ApiDataModels.QuoteModel quoteModel;
    private Map<String,CPQ_ApiDataModels.ProductModel> productModels;
    private Map<String,CPQ_ApiDataModels.ProductModel> bundles;
    Map<String,CPQ_ApiDataModels.FeatureModel> bundleFeatures; 
    /********CONSTRUCTORS**********/
    public QuoteGenerator(Opportunity opp){
        this.opp = opp;
        this.lines = opp.OpportunityLineItems;
        this.manualClauses = opp.Associated_Clauses__r;
        this.productModels = new Map<String,CPQ_ApiDataModels.ProductModel>();
        this.bundles = new Map<String,CPQ_ApiDataModels.ProductModel>();
        this.bundleFeatures = new Map<String,CPQ_ApiDataModels.FeatureModel>();
        this.currencyIsoCode = Userinfo.isMultiCurrencyOrganization() ? String.valueOf(opp.get('CurrencyIsoCode')) : UserInfo.getDefaultCurrency();
    }
    /********PUBLIC**********/
    /**
    * @description kick off the whole quote generation process which consist in create quote, load products, add products, final calculate
    * @author David Browaeys 
    * @return Boolean true if quote was successfully created and product added
    * @example 
    * Boolean result = new QuoteService.QuoteGenerator(opps[0]).execute();
    **/
    public Boolean execute(){
        try{
            createQuote();
            loadQuote();
            addOpportunityProducts();
            OpportunityLineItem oppProduct = [SELECT Application_Course_Preference__r.Application__r.Campus_Location__c, Application_Course_Preference__r.Course_Offering__r.Location_Code__c 
                                                FROM OpportunityLineItem 
                                                WHERE id = :this.lines[0].id LIMIT 1];
              if ((this.opp.Onshore_MU_Transfer__c == false && this.opp.Offer_Category__c != Constants.OPP_OFFERCATEGORY_DOMESTIC_OFFER && this.opp.Offer_Category__c != Constants.OPP_OFFERCATEGORY_DOMESTIC_DEFERRAL) //SFTG-1988-Skipping creation of OSHC record for Deferals
                && (oppProduct.Application_Course_Preference__r.Application__r.Campus_Location__c != Constants.MONASH_ABROAD_CAMPUS_LOCATION_ONLINE) //SFTG-1963 Filter out Virtual courses (campus Location='Online') from being added with HealthBundles
                && (oppProduct.Application_Course_Preference__r.Course_Offering__r.Location_Code__c != Constants.LOCATION_ONLINE_A)) { 
                    addHealthBundle();
            }
            addProductsToQuote();
            saveQuote();
            updateQuoteLinesFromOpportunityProducts();
            syncExtraQuoteLineFields();
            addManualClauses();
            saveQuote();
            calculate(QuoteCreationCallback.class.toString());
            return true;
        }catch(Exception err){ //log event for unexpected exception
            LogUtilityException.logException(err, opp);

            if(this.quote != null){
                // Update opportunity stage when errors               
                Opportunity opp = new Opportunity();
                opp.Id = this.quote.SBQQ__Opportunity2__c;
                opp.StageName = 'Specialist Review';
                opp.NextStep = '';
                update opp;
                
                // Update Quote substatus, Error log and assign the quote to the technical error queue                  
                this.quote = QuoteService.sendQuoteToTechQueue(this.quote.Id, 'Technical error creating the quote. ' + err.getMessage());
                update this.quote;
            }
            //update quote with error message
        }
        return false;
    }

    public QuoteGenerator addHealthBundle()
    {
        String defaultProduct = Constants.DEFAULT_PRODUCT_BUNHEALTH;

        if(defaultProduct == null)
        {
            throw new LogUtilityException('Custom metadata - missing: CPQ Settings Default Health Product');
        }
        if(string.isBlank(defaultProduct))
        {
            return this;
        }
        Set<string> externalIds = new Set<string>{ defaultProduct };
        Map<string,Product2> products = new ProductsSelector().selectProductByExternalId(externalIds, Product2.External_ID__c);
        
        if(products.values().size() == 0){
            throw new LogUtilityException('Bad value: CPQ Settings Default Health Product');
        } else {
            loadProduct(products.values()[0].Id);
            CPQ_ApiDataModels.ProductModel healthPM =  productModels.get(products.values()[0].Id);
            this.quote.recalculateFormulas();
            setConfigurationAttrFromsObject(this.quote,healthPM);
            healthPM.configuration.configurationData.put('Health_Cover_Type__c', 'SINGLE');
            return this;

        }
    }
    /**
    * @description this method load cpq quote model from cpq api
    * @author David Browaeys 
    * @return void
    * @example 
    * QuoteService.QuoteGenerator = new QuoteService.QuoteGenerator(quoteId)
    *     .loadQuote()
    *     .loadProduct(product1)
    *     .addProductsToQuote()
    *     .calculate(QuoteCreationCallback.class.toString())
    **/
    public QuoteGenerator loadQuote(){
        if (this.quoteId == null){
            throw new CPQ_ApiService.CPQException('Quote id is required!');
        }
        quoteModel = CPQ_APIService.getQuote(quoteId);
        this.currencyIsoCode = Userinfo.isMultiCurrencyOrganization() ? String.valueOf(quoteModel.record.get('CurrencyIsoCode')) : UserInfo.getDefaultCurrency();
        return this;
    }
    /**
    * @description this method retrieve cpq product model from cpq api
    * @author David Browaeys
    * @param productId id of the product
    * @return QuoteGenerator instance of the class
    * @example 
    * QuoteService.QuoteGenerator = new QuoteService.QuoteGenerator(quoteId)
    *     .loadQuote()
    *     .loadProduct(product1)
    *     .addProductsToQuote()
    *     .calculate(QuoteCreationCallback.class.toString())
    */
    public QuoteGenerator loadProduct(String productId) {
        if (productId == null){
            throw new CPQ_ApiService.CPQException('Product Id is required!');
        }
        CPQ_ApiDataModels.ProductModel pm = CPQ_APIService.loadProduct(productId,this.quoteModel.record.SBQQ__PricebookId__c,this.currencyIsoCode);
        productModels.put(productId, pm);
        return this;
    }
    /**
    * @description this method add all product models to cpq quote through cpq api and save quote
    * @author David Browaeys
    * @return QuoteGenerator instance of the class
    * QuoteService.QuoteGenerator = new QuoteService.QuoteGenerator(quoteId)
    *     .loadQuote()
    *     .loadProduct(product1)
    *     .addProductsToQuote()
    *     .calculate(QuoteCreationCallback.class.toString()) 
    */
    public QuoteGenerator addProductsToQuote() {
        this.quoteModel = CPQ_APIService.addProducts(this.quoteModel, this.productModels.values());
        this.quoteModel.record.SBQQ__Status__c = 'In Review';
        this.quoteModel.record.Sub_Status__c = 'Products Added';
        this.quoteModel.record.Calculate_API_Request_Time__c = Datetime.now();
        this.quoteModel.record.Products_Added_TimeStamp__c = Datetime.now();
        this.quoteModel.record.Calculate_API_Response_Time__c = null;

        return this;
    }
    /**
    * @description This method add any associated manual clause to quote
    * @author David Browaeys
    * @return QuoteGenerator instance of the class
    */
    public QuoteGenerator addManualClauses(){
        if (this.manualClauses != null && this.manualClauses.isEmpty() == false){
            System.debug('#### Manual Clause : '+  this.manualClauses);
            Boolean result = new OfferManualClauseService(this.manualClauses, this.quoteModel.record, this.quoteModel.quoteLines)
                            .execute()
                            .commitAll();
            if (result == false){
                this.quoteModel.record.Clauses_Review_Required__c = true;
            }
        }
        return this;
    }
    /**
    * @description this method save quote model
    * @author David Browaeys
    * @return QuoteGenerator instance of the class
    */
    public QuoteGenerator saveQuote(){
        this.quoteModel = CPQ_APIService.save(this.quoteModel);
        return this;
    }
    /**
    * @description this method add all product models to cpq quote through cpq api and save quote
    * @author David Browaeys
    * @param className name of the callback class
    * @return QuoteGenerator instance of the class
    * QuoteService.QuoteGenerator = new QuoteService.QuoteGenerator(quoteId)
    *     .loadQuote()
    *     .loadProduct(product1)
    *     .addProductsToQuote()
    *     .calculate(QuoteCreationCallback.class.toString()) 
    */
    public QuoteGenerator calculate(String className){
        CPQ_APIService.calculate(this.quoteModel, className);
        return this;
    }
    /********PRIVATE**********/
    /**
    * @description create quote object from opportunity using normal dml (no cpq), then load quote model using cpq api
    * @author David Browaeys
    * @return void
    **/
    @TestVisible private void createQuote(){
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            Bulk_Data_Processing__c = this.opp.Bulk_Data_Processing__c,
            Bulk_Job_ID__c = this.opp.Bulk_Job_ID__c,
            In_Shadow__c = this.opp.In_Shadow__c,
            SBQQ__SalesRep__c = this.opp.OwnerId,
            OwnerId = this.opp.OwnerId,
            currencyIsoCode = this.opp.currencyIsoCode, 
            SBQQ__PricebookId__c = this.opp.Pricebook2Id, 
            SBQQ__PrimaryContact__c  = this.opp.PrimaryContact__c, 
            SBQQ__Account__c  = this.opp.AccountId, 
            SBQQ__Opportunity2__c = this.opp.Id,
            SBQQ__Partner__c = this.opp.Agent_Account__c,
            SBQQ__EndDate__c = this.opp.Offer_End_Date__c,
            SBQQ__StartDate__c = this.opp.Offer_Start_Date__c,
            SBQQ__ExpirationDate__c = this.opp.CloseDate,
            Offer_Type__c = this.opp.Offer_Type__c,
            Visa_End_Date__c = this.opp.Visa_End_Date__c,
            Visa_Start_Date__c = this.opp.Visa_Start_Date__c,
            SBQQ__Source__c	= this.opp.SBQQ__PrimaryQuote__c,
            SBQQ__Type__c = (this.opp.SBQQ__PrimaryQuote__c != null ? 'Re-Quote' : 'Quote'),
            Expiry_Status__c = 'Active Offer',
            Product_Status__c = 'Active Products',
            SBQQ__Status__c = 'New',
            Sub_Status__c = 'In Progress',
            Offer_Creation_TimeStamp__c =  Datetime.now(),
            Category__c = 'ISCA Deposit',
            Product_Search_Filter__c = 'Offer',
            Is_Current_MU_Student__c = this.opp.Is_Current_MU_Student__c,
            Agent_Email__c = this.opp.Agent_Account__c != null ? this.opp.Agent_Account__r.Email__c : null,
            Manual_ISCA_Edit_Required__c = manualISCAEdit
        );

        SBQQ.TriggerControl.disable();
        insert q;
        SBQQ.TriggerControl.enable();
        this.quote = q;
        this.quoteId = q.Id;
    }
    /**
    * @description Loop through opportunity line item and convert to a product calling cpq api
    * @author David Browaeys | 10/21/2019 
    * @return void
    **/
    @TestVisible private void addOpportunityProducts(){
        for (OpportunityLineItem oli : this.lines){
            //handle bundle linked to master product
            // if (product.Required_Manual_Review__c == true){
            // requiredReview = true;
            // }
            if (oli.PricebookEntry.Product2.Product_Bundle__c != null){
                string uniqueKey = oli.Application_Course_Preference__c + ':' + oli.PricebookEntry.Product2.Product_Bundle__c;
                string bundleKey = oli.PricebookEntry.Product2.Product_Bundle__c;
                loadProductBundle(uniqueKey, bundleKey, oli.PricebookEntry.Product2Id);
                setConfigurationAttrFromOpportunityProducts(oli, productModels.get(uniqueKey +':'+ oli.PricebookEntry.Product2Id));
            }
            loadProduct(oli.PricebookEntry.Product2Id);
        }
    }
    /**
    * @description 
    * @author David Browaeys
    * @param bundleId id of the product bunde(i.e.: Monash University)
    * @param productId id of the product master(i.e.: Bachelor of Marketing)
    * @return cpq product model
    */
    @TestVisible private void loadProductBundle(String uniqueKey, String bundleId, String productId){
        if (bundleid == null) { 
            return;
        }
        CPQ_ApiDataModels.ProductModel pm = CPQ_APIService.loadProduct(bundleId,quoteModel.record.SBQQ__PricebookId__c,currencyIsoCode);
        //get dynamic product feature linked to bundle
        getDynamicBundleFeature(bundleId,pm);
        productModels.put(uniqueKey +':'+ productId, pm);
    }
    /**
    * @description This method retrieve the dynamic feature for the product bundle
    * @author David Browaeys
    * @param bundleId id of the product bunde(i.e.: Monash University)
    * @param pm product model to retrieve dynamic feature from
    * @return void
    */
    @TestVisible private void getDynamicBundleFeature(String bundleId, CPQ_ApiDataModels.ProductModel pm){
        if (pm.features != null && pm.features.isEmpty() == false){
            for (CPQ_ApiDataModels.FeatureModel f :  pm.features){
                if (f.record.SBQQ__OptionSelectionMethod__c == 'Dynamic'){    //conditions TBC, maybe need to add extra such as Name == 'BUNDLE_FEATURE'
                    bundleFeatures.put(bundleId, f);
                    break;
                }
            }
        }
    }
    /**
    * @description this method set product option details of product bundle from an opportunity product based on list of configuration attributes
    * @author David Browaeys
    * @param oli opportunity product to copy details from
    * @param pm product model of product bundle 
    * @return void
    */
    @TestVisible private void setConfigurationAttrFromOpportunityProducts(OpportunityLineItem oli, CPQ_ApiDataModels.ProductModel pm){
        if (pm.configuration != null && pm.configuration.configurationData != null){ 
            for (CPQ_ApiDataModels.ConfigAttributeModel f :  pm.configurationAttributes){
                if (oli.get(f.targetFieldName) != null){
                    pm.configuration.configurationData.put(f.targetFieldName, String.valueOf(oli.get(f.targetFieldName)));
                    //extends logic to support number, date etc
                }
            }
        }
    }
    @TestVisible private void setConfigurationAttrFromsObject(sObject sobj, CPQ_ApiDataModels.ProductModel pm){
        if (pm.configuration != null && pm.configuration.configurationData != null)
        { 
            Map<string,Schema.sObjectField> sobjFields = sobj.getSobjectType().getDescribe().fields.getMap();
            for (CPQ_ApiDataModels.ConfigAttributeModel f :  pm.configurationAttributes){
                Boolean hasField = sobjFields.keySet().contains(f.targetFieldName.toLowerCase());
                if(hasField)
                {
                    if (sobj.get(f.targetFieldName) != null)
                    {
                        pm.configuration.configurationData.put(f.targetFieldName,     sobj.get(f.targetFieldName ) ) ;
                    }
                }
            }
        }
    }   
    /**
    * @description Get quote line by product bundle and/or acp
    * @author David Browaeys
    * @return Map<String,CPQ_ApiDataModels.QuoteLineModel>
    */     
    @TestVisible private Map<String,CPQ_ApiDataModels.QuoteLineModel> getQuoteLineByProducts(){
        Map<String,CPQ_ApiDataModels.QuoteLineModel> tmp = new Map<String,CPQ_ApiDataModels.QuoteLineModel>();
        for (CPQ_ApiDataModels.QuoteLineModel m : this.quoteModel.lineItems){
            if (m.record.Application_Course_Preference__c != null && bundleFeatures.get(m.record.SBQQ__Product__c) != null){
                tmp.put(m.record.Application_Course_Preference__c + ':' + m.record.SBQQ__Product__c,m);
            }else{
                tmp.put(m.record.SBQQ__Product__c,m);
            }
        }
        return tmp;
    }
    /**
    * @description Link Course Quote Line to Bundle Quote Line base on ACP.
    * @author David Browaeys
    * @return void
    */
    @TestVisible private void updateQuoteLinesFromOpportunityProducts(){
        Map<String,CPQ_ApiDataModels.QuoteLineModel> quoteLineByProducts = getQuoteLineByProducts();
        //link master product with quote line of product bundle
        for (OpportunityLineItem oli : this.lines){
            if (oli.PricebookEntry.Product2.Product_Bundle__c != null){
                CPQ_ApiDataModels.QuoteLineModel ql = quoteLineByProducts.get(oli.PricebookEntry.Product2Id);

                String bundleId = oli.PricebookEntry.Product2.Product_Bundle__c;
                if (bundleId != null){
                    if (bundleFeatures.get(bundleId) != null){
                        ql.record.SBQQ__DynamicOptionId__c = bundleFeatures.get(bundleId).record.Id+':'+ql.record.SBQQ__Product__c;
                    }
                    if (oli.Application_Course_Preference__c != null && quoteLineByProducts.get(oli.Application_Course_Preference__c +':'+ bundleId) != null){
                        CPQ_ApiDataModels.QuoteLineModel bql = quoteLineByProducts.get(oli.Application_Course_Preference__c +':'+ bundleId);
                        ql.record.SBQQ__RequiredBy__c = bql.record.Id;
                        ql.record.Application_Course_Preference__c = bql.record.Application_Course_Preference__c;
                    }
                }
            }
        }
    }
    /**
    * @description Sync any additional fields between opportunity line to quote line for acp product.
    * @author David Browaeys
    * @return void
    */
    @TestVisible private void syncExtraQuoteLineFields(){
        //sync extra fields
        for (CPQ_ApiDataModels.QuoteLineModel ql : this.quoteModel.lineItems){
            for (OpportunityLineItem oli : this.lines){
                if (oli.Application_Course_Preference__c != null && oli.Application_Course_Preference__c == ql.record.Application_Course_Preference__c){
                    ql.record.Override_Start_Date__c = oli.Override_Start_Date__c;
                    ql.record.Override_End_Date__c = oli.Override_End_Date__c;
                    ql.record.Override_Duration__c = oli.Override_Duration__c;
                    ql.record.Override_Duration_With_RPL__c = oli.Override_Duration_With_RPL__c;
                    ql.record.Additional_Clause_Notes__c = oli.Additional_Clause_Notes__c;
                    ql.record.Additional_Bahasa_Clause_Notes__c = oli.Additional_Bahasa_Clause_Notes__c;
                    break;
                }else if (oli.PricebookEntry.Product2Id == ql.record.SBQQ__Product__c 
                            && oli.PricebookEntry.Product2.Expiry_days__c != null
                            && Constants.GRANT_SCHOLARSHIP_PRODUCT_FAMILIES.contains(ql.record.SBQQ__ProductFamily__c) == true) { 
                    ql.record.Expiry_Date__c = Date.today().addDays(oli.PricebookEntry.Product2.Expiry_days__c.intValue());
                }
            }
        }
    }
    // used for regenerate
    public Id getQuoteId()
    {
        return this.quote.Id;
    }
}