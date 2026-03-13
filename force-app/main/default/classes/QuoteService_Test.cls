/**
* @author Jasmin Joy Rudio
* @description Apex test class for QuoteService class
* @group SF Offers
*
**/
@isTest(isParallel = false)
public with sharing class QuoteService_Test {

    @testSetup static void setup() {
        TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');

        //insert OrgUnitBundleMapping__c
        Test.loadData(OrgUnitBundleMapping__c.sObjectType, 'OrgUnitBundleMappingDataTest');

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id), true);

        List<Product2> bundles = new List<Product2>();
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', false));
        insert bundles;
        
        //Add configuration attribute to the bundle.
        SBQQ__ConfigurationAttribute__c configAttribute = (SBQQ__ConfigurationAttribute__c)TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Application_Course_Preference__c',SBQQ__TargetField__c='Application_Course_Preference__c', SBQQ__Product__c=bundles[0].Id),true);
        SBQQ__ConfigurationAttribute__c configAttributeQuote = (SBQQ__ConfigurationAttribute__c)TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Health_Cover_Duration__c',SBQQ__TargetField__c='Health_Cover_Duration__c', SBQQ__Product__c=bundles[2].Id),true);

        //Product Feature Creation
        SBQQ__ProductFeature__c pf = (SBQQ__ProductFeature__c)TestDataFactory.createSObject(new SBQQ__ProductFeature__c(SBQQ__ConfiguredSKU__c=bundles[0].Id,SBQQ__Number__c=1),true);

        Course__c[] courses = new Course__c[0];
        //course marketing
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), false));
        //unit set marketing 
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.UnitSetDefaults', false));
        //course - monash english
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.MonashEnglishCourseDefaults', false));
        //unit set - monash english
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.MonashEnglishUnitSetDefaults', false));
        //unit set - scholarship
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.MonashGrantCoursDefaults', false));
        insert courses;
         //create clause 1
         APXT_Redlining__Clause__c clause1 = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12345',APXT_Redlining__Text__c='test course code match',Location_in_Offer__c='Course notes'), true);
         APXT_Redlining__Clause__c clause2 = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12346',APXT_Redlining__Text__c='Country not equals China', Location_in_Offer__c='Course notes'), true);
         APXT_Redlining__Clause__c clause3 = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12347',APXT_Redlining__Text__c='Country of Residence INDIA',Location_in_Offer__c='Course notes'), true);
         APXT_Redlining__Clause__c clause4 = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12348',APXT_Redlining__Text__c='calendar start date greater than today',Location_in_Offer__c='Course notes'), true);
 
         Clause_Filtering_Criteria__c[] criterias = new Clause_Filtering_Criteria__c[0];
         criterias.add((Clause_Filtering_Criteria__c)TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c=clause1.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaForContainsDefaults', false));
         criterias.add((Clause_Filtering_Criteria__c)TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c=clause2.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaForNotEqualsDefaults', false));
         criterias.add((Clause_Filtering_Criteria__c)TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c=clause3.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaForEqualsDefaults', false));
         criterias.add((Clause_Filtering_Criteria__c)TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c=clause4.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaGreaterThanDefaults', false));
         
         insert criterias;
         
        
        TestDataFactory.createSObject(new Course_Duration__c(Pricebook__c = pb.Id), true);

        insert new Stg_Course_Fee__c[]{
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,false),
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false)
        };

        //Create Partner ACcount
        Account partnerAcc = (Account)TestDataFactory.createSObject(new Account(Email__c = 'partner@monash.edu'), true);
        //Application Creation
        Application__c app = (Application__c)TestDataFactory.createSObject(new Application__c(Applicant__c = contact.Id, Agent__c=partnerAcc.Id), true);

        //ACP Creation
        insert new Application_Course_Preference__c[]{
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                        Course__c = courses[0].Id, 
                        Course_Code__c = courses[0].Name,
                        Course_Version_Number__c = integer.valueOf(courses[0].Version__c),
                        Course_Code_Unique__c = courses[0].Course_Code__c,
                        Unit_Set__c = courses[1].Id, 
                        Unit_Set_Code__c = courses[1].Name, 
                        Unit_Set_Version__c = integer.valueOf(courses[1].Version__c),
                        Application__c = app.Id), false),
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                       Course__c = courses[2].Id, 
                        Course_Code__c = courses[2].Name,
                        Course_Version_Number__c = integer.valueOf(courses[2].Version__c),
                        Course_Code_Unique__c = courses[2].Course_Code__c,
                        Unit_Set__c = courses[3].Id, 
                        Unit_Set_Code__c = courses[3].Name, 
                        Unit_Set_Version__c = integer.valueOf(courses[3].Version__c),
                        Application__c = app.Id), false),
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                       Course__c = courses[4].Id, 
                        Course_Code__c = courses[4].Name,
                        Course_Version_Number__c = integer.valueOf(courses[4].Version__c),
                        Course_Code_Unique__c = courses[4].Course_Code__c,
                        Unit_Set__c = courses[4].Id, 
                        Unit_Set_Code__c = courses[4].Name, 
                        Unit_Set_Version__c = integer.valueOf(courses[4].Version__c),
                        Application__c = app.Id), false)
                        
        };
        TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');

    }
    @isTest
    private static void test_syncOpportunityWithQuote(){
        Opportunity opp = QuoteService.syncOpportunityWithQuote(new SBQQ__Quote__c());
        System.assert(opp != null, 'Opportunity should be return from quote');
    }

    @isTest static void test_createQuoteEvent(){
        Quote_Event__e evt = QuoteService.createQuoteEvent(new SBQQ__Quote__c());
        System.assert(evt != null, 'Method should return a new event');
    }
    
    /**
    * @author Jasmin Joy Rudio
    * @date 20/11/2019
    * @group SF Offer
    * @description Test method to test re-generation of a Quote when a Grant/Scholarship product expired
    **/
    @isTest
    private static void reGenerateQuote(){
   
        Account account = [SELECT ID FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Pricebook2 pb = [SELECT Id, Name, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        APXT_Redlining__Clause__c clause = [SELECT Id FROM APXT_Redlining__Clause__c LIMIT 1];

        Product2 product = (Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashGrantScholarshipDefaults', false);
        product.Clause__c = clause.Id;
        insert product;//product always require a standard pricebook     
        PricebookEntry pbe1 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product.id),true);
        PricebookEntry pbe2 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = product.id), true);
        
        Application_Course_Preference__c[] acps = [SELECT ID, Course__r.Name, Course__c, Course_code__c, Course_Version_Number__c, Course_Code_Unique__c, application__c  FROM Application_Course_Preference__c ORDER BY Course__r.Name];
        Application_Course_Preference__c grantACP = [SELECT Id FROM Application_Course_Preference__c WHERE Course__r.Title__c = 'Scholarship'];
        PriceBookEntry[] pbes = [SELECT Id, Name, External_ID__c, Product2.Name FROM PriceBookEntry WHERE Pricebook2Id =: pb.id ORDER BY Product2.Course__r.Name];     
        //Opportunity Creation,
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id,Pricebook2Id=pb.id, CloseDate = Date.today().addDays(15)),true);
                
        //OpportunityLineItem Creation
        OpportunityLineItem[] olis = new OpportunityLineItem[]{
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[0].id, Application_Course_Preference__c = acps[0].Id), false),
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbe2.id,Application_Course_Preference__c = grantACP.Id), false)
        };
        insert olis;
        
        SBQQ.TriggerControl.disable();
        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=account.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=con.Id,SBQQ__Status__c='Published',
                                                                            Sub_Status__c='Preview Requested', SBQQ__Opportunity2__c = opp.Id, SBQQ__ExpirationDate__c = opp.CloseDate),true);
        //QuoteLineItem Creation
        SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.id,SBQQ__Product__c=product.Id, Expiry_Date__c = Date.today().addDays(15)), false)
        }; 
        insert qlis; 
        
        
        Test.startTest();
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Name, SBQQ__ProductFamily__c, Expiry_Date__c, SBQQ__Product__c,
                                                    SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__c
                                                    FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c =: opp.Id
                                                    AND SBQQ__ProductFamily__c = 'Scholarship'];
            if(quoteLines.isEmpty() == false){
                
                quoteLines.get(0).Expiry_Date__c = Date.today().addDays(-100);
                update quoteLines;
                QuoteService.getOfferDetails(quoteLines[0].SBQQ__Quote__c);
                QuoteService.getOfferList(con.Id, null);
                QuoteService.getCurrentOfferList(con.Id, UserInfo.getUserId(), 1, 0);
                
            }
            
        Test.stopTest();
        List<SBQQ__Quote__c> quoteList = new QuotesSelector().selectById(new Set<Id>{quote.Id});        
        System.assertEquals(quoteList[0].Expiry_Status__c, 'Expired in portal');
        System.assertEquals(quoteList[0].SBQQ__Status__c, 'Expired and regenerated');      
    }
    
    
    @isTest
    private static void regeneratePendingSignature(){
        Account account = [SELECT ID FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Pricebook2 pb = [SELECT Id, Name, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id,Pricebook2Id=pb.id, CloseDate = Date.today().addDays(15)),true);
        SBQQ.TriggerControl.disable();
        APXT_Redlining__Clause__c clause = [SELECT Id FROM APXT_Redlining__Clause__c LIMIT 1];
        Product2 product = (Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashGrantScholarshipDefaults', false);
        product.Clause__c = clause.Id;
        insert product;//product always require a standard pricebook     
        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=account.Id,SBQQ__PricebookId__c=pb.id,
                                                                                SBQQ__PrimaryContact__c=con.Id,SBQQ__Status__c='Pending signature',
                                                                                Sub_Status__c='Contract Created', SBQQ__Opportunity2__c = opp.Id,
                                                                                SBQQ__ExpirationDate__c = opp.CloseDate),true);
                    
        SBQQ__QuoteLine__c quoteLine  = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.id,SBQQ__Product__c=product.Id,
                                                                                        Expiry_Date__c = Date.today().addDays(15)), false);
        insert quoteLine;
        Test.startTest();
            SBQQ__QuoteLine__c ql = [SELECT Id, Name, SBQQ__ProductFamily__c, Expiry_Date__c, SBQQ__Product__c, SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__c
                                FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.Id AND SBQQ__ProductFamily__c = 'Scholarship' LIMIT 1];
            if(ql!= null){
                
                ql.Expiry_Date__c = Date.today().addDays(-100);
                update ql;
            }
            
        Test.stopTest();
        List<SBQQ__Quote__c> quoteList = new QuotesSelector().selectById(new Set<Id>{quote.Id});        
        System.assertEquals(quoteList[0].Expiry_Status__c, 'Expired in DocuSign');
        System.assertEquals(quoteList[0].SBQQ__Status__c, 'Expired and regenerated');   
    }
    
    @isTest
    private static void regenerateCreated(){
        Account account = [SELECT ID FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Pricebook2 pb = [SELECT Id, Name, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id,Pricebook2Id=pb.id, CloseDate = Date.today().addDays(15)),true);
        SBQQ.TriggerControl.disable();
        APXT_Redlining__Clause__c clause = [SELECT Id FROM APXT_Redlining__Clause__c LIMIT 1];
        Product2 product = (Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashGrantScholarshipDefaults', false);
        product.Clause__c = clause.Id;
        insert product;//product always require a standard pricebook     
        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=account.Id,SBQQ__PricebookId__c=pb.id,
                                                                                SBQQ__PrimaryContact__c=con.Id,SBQQ__Status__c='Created',
                                                                                Sub_Status__c='Preview Requested', SBQQ__Opportunity2__c = opp.Id,
                                                                                SBQQ__ExpirationDate__c = opp.CloseDate),true);
        SBQQ__QuoteLine__c quoteLine  =  (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.id,SBQQ__Product__c=product.Id,
                                                                                        Expiry_Date__c = Date.today().addDays(15)), false);
        insert quoteLine;                                                                                        
        Test.startTest();
            SBQQ__QuoteLine__c ql = [SELECT Id, Name, SBQQ__ProductFamily__c, Expiry_Date__c, SBQQ__Product__c, SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__c
                                FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.Id AND SBQQ__ProductFamily__c = 'Scholarship' LIMIT 1];
            if(ql!= null){
                
                ql.Expiry_Date__c = Date.today().addDays(-100);
                update ql;
            }
            
        Test.stopTest();
        List<SBQQ__Quote__c> quoteList = new QuotesSelector().selectById(new Set<Id>{quote.Id});        
        System.assertEquals(quoteList[0].Expiry_Status__c, 'Expired prior to publishing');
        System.assertEquals(quoteList[0].SBQQ__Status__c, 'Expired and regenerated');   
    }
    
	@IsTest 
	private static void test_assignQuoteToBusinessQueue(){
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        QuoteService.assignQuoteToBusinessQueue(quote);
        System.assert(quote.OwnerId != null, 'Quote Owner should be populated.');
    }
    @isTest 
    private static void shouldNotSetCalcCompleteWhenNoResponse()
    {
        insert new Offer_Setting__c(SetupOwnerId=UserInfo.getOrganizationId(), IS_SHADOW_PHASE__C = false);

        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(),true);

        Test.starttest();
            Boolean isComplete = QuoteService.quoteCalculationComplete(quote1.Id);
        Test.StopTest();
        system.assertEquals(false, isComplete, 'it should not be complete if api response time is field not set');

    }
    @isTest 
    private static void shouldSetCalcCompleteWhenApiResponsSet()
    {
        insert new Offer_Setting__c(SetupOwnerId=UserInfo.getOrganizationId(), IS_SHADOW_PHASE__C = false);
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c( Calculate_API_Response_Time__c = Datetime.now() ),true);

        Test.starttest();
            Boolean isComplete = QuoteService.quoteCalculationComplete(quote1.Id);
        Test.StopTest();
        system.assertEquals(true, isComplete, 'it should be complete if api response time is field set');

    }


    @IsTest
    private static void shouldOSHCViewAuraHandledExceptionWhenNullInput()
    {
        try {
            Test.startTest();
                QuoteService.getQuoteOSHCView(null, null);
            Test.stopTest();

        } catch(AuraHandledException ex)
        {
            system.assert(true, 'it should throw AuraHandledException when null input');
            return;

        }
        system.assert(false, 'it should throw AuraHandledException when null input');
    }
    @IsTest
    private static void shouldOSHCSucceedWhenValidInput()
    {
        List<Course__c> courseList = new List<Course__c>();
        for(Course__c loopCourse : [SELECT Id FROM Course__c]){
            loopCourse.Managing_Faculty__c = 'TestFaculty';
            courseList.add(loopCourse);
        }
        update courseList;

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(Name='International',External_ID__c = 'INTL'),true);

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id, FirstName = 'TestFN', LastName = 'TestLN', Email = 'test@test.com'), true);
        List<Product2> bundles = [Select Id from Product2];
        if(bundles.size() == 0)
        {
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.Product2Defaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', true));

        }
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthOptionDefaults', true));

        List<Application_Course_Preference__c> acps = [SELECT Id, Managing_Faculty__c FROM Application_Course_Preference__c ORDER BY Course__r.Name DESC];

        Opportunity testOpportunity = new Opportunity(Name = 'TestName',
                                                      AccountId=acc.Id, 
                                                      PrimaryContact__c = contact.Id, 
                                                      Pricebook2Id=pb.id, 
                                                      CloseDate = Date.today().addDays(15),
                                                      StageName = 'Publish');
        insert testOpportunity;

        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Published',Sub_Status__c='In QA Review', SBQQ__Opportunity2__c = testOpportunity.Id, SBQQ__ExpirationDate__c = testOpportunity.CloseDate),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[0].Id, SBQQ__Product__c = bundles[0].Id), true); // uniBundle
        SBQQ__QuoteLine__c oshcBundle = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[1].Id, SBQQ__Product__c = bundles[2].Id), true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[2].Id, SBQQ__Product__c = bundles[3].Id, SBQQ__RequiredBy__c = oshcBundle.Id, SBQQ__NetPrice__c = 1234.56 ), true); // oshcBundle
          
        testOpportunity.SBQQ__PrimaryQuote__c = quote1.Id;
        update testOpportunity;

        FormPageService.HeathQuoteRequest hqr = new FormPageService.HeathQuoteRequest();
        hqr.quoteId = quote1.Id;
        hqr.healthBundleId = null;
        hqr.selectedHealthOption = 'SINGLE';
        hqr.selectedProvider = 'Allianz';
        Test.startTest();
            QuoteService.setQuoteOSHCView(hqr);
        Test.stopTest();
    }

    @IsTest 
    private static void shouldsetOSHCViewAuraHandledExceptionWhenNullInput()
    {
        
        try {
            FormPageService.HeathQuoteRequest hqr = new FormPageService.HeathQuoteRequest();
            hqr.quoteId = null;
            hqr.healthBundleId = null;
            hqr.selectedHealthOption = 'SINGLE';
            Test.startTest();

                QuoteService.setQuoteOSHCView(hqr);
            Test.stopTest();

        } catch(AuraHandledException ex)
        {
            system.assert(true, 'it should throw AuraHandledException when null input');
            return;

        }
        system.assert(false, 'it should throw AuraHandledException when null input');
    }

    @IsTest 
    private static void shouldsetOSHCSucceedWhenValidInput()
    {
        List<Course__c> courseList = new List<Course__c>();
        for(Course__c loopCourse : [SELECT Id FROM Course__c]){
            loopCourse.Managing_Faculty__c = 'TestFaculty';
            courseList.add(loopCourse);
        }
        update courseList;

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(Name='International',External_ID__c = 'INTL'),true);

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id, FirstName = 'TestFN', LastName = 'TestLN', Email = 'test@test.com'), true);
        List<Product2> bundles = [Select Id from Product2];
        if(bundles.size() == 0)
        {
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.Product2Defaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', true));

        }
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthOptionDefaults', true));

        List<Application_Course_Preference__c> acps = [SELECT Id, Managing_Faculty__c FROM Application_Course_Preference__c ORDER BY Course__r.Name DESC];

        Opportunity testOpportunity = new Opportunity(Name = 'TestName',
                                                      AccountId=acc.Id, 
                                                      PrimaryContact__c = contact.Id, 
                                                      Pricebook2Id=pb.id, 
                                                      CloseDate = Date.today().addDays(15),
                                                      StageName = 'Publish');
        insert testOpportunity;

        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Published',Sub_Status__c='In QA Review', SBQQ__Opportunity2__c = testOpportunity.Id, SBQQ__ExpirationDate__c = testOpportunity.CloseDate),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[0].Id, SBQQ__Product__c = bundles[0].Id), true); // uniBundle
        SBQQ__QuoteLine__c oshcBundle = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[1].Id, SBQQ__Product__c = bundles[2].Id), true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[2].Id, SBQQ__Product__c = bundles[3].Id, SBQQ__RequiredBy__c = oshcBundle.Id, SBQQ__NetPrice__c = 1234.56 ), true); // oshcBundle
          
        testOpportunity.SBQQ__PrimaryQuote__c = quote1.Id;
        update testOpportunity;


        FormPageService.HeathQuoteRequest hqr = new FormPageService.HeathQuoteRequest();
        hqr.quoteId = quote1.Id;
        hqr.healthBundleId = null;
        hqr.selectedHealthOption = 'SINGLE';
        hqr.selectedProvider = 'Allianz';
        Test.startTest();
            QuoteService.setQuoteOSHCView(hqr);
        Test.stopTest();
        System.assert( [select Calculate_API_Request_Time__c from SBQQ__Quote__c where id=: quote1.Id].Calculate_API_Request_Time__c!=null );

    }    

    @IsTest 
    private static void shouldReturnFalseWhenQuoteNotPublished()
    {
         system.assertEquals(false, QuoteService.canRegenerate(Constants.QUOTE_STATUS_IN_REVIEW),  'it should return false when status is NOT published');
    }
    
    @IsTest
    private static void shouldReturnTrueWhenQuotePublished()
    {
         system.assertEquals(true, QuoteService.canRegenerate(Constants.QUOTE_STATUS_PUBLISHED),  'it should return true when status is published');

  
    }
    @IsTest 
    private static void shouldIllegalArgumentExceptionWhendoRegenNull()
    {
        try {
            QuoteService.doRegenerate(null);
        } catch(IllegalArgumentException ex)
        {
         system.assert(true, 'it should throw  IllegalArgumentException exception when null input');
         return;
            
        }
         system.assert(false, 'it should throw  IllegalArgumentException exception when null input');

    }
    @IsTest
    private static void shouldIllegalAuraHandledExceptionWhenDoRegenNotPublished()
    {
        try {
            SBQQ.TriggerControl.disable();
            SBQQ__Quote__c existingQuote = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Status__c=Constants.QUOTE_STATUS_IN_REVIEW),true);
            Test.startTest();

                QuoteService.doRegenerate(existingQuote.Id);
            Test.stopTest();
        } catch(AuraHandledException ex)
        {
            system.assert(true, 'it should throw  AuraHandledException when quote status is not published');
            return;

        }
        system.assert(false, 'it should throw  AuraHandledException when quote status is not published');
 
    }
    @IsTest 
    private static void shouldeturnQuoteIdWhenWhenDoRegenPublished()
    {
        insert new Offer_Setting__c(SetupOwnerId=UserInfo.getOrganizationId(), IS_SHADOW_PHASE__C = false);

        SBQQ.TriggerControl.disable();
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id), true);

        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId();
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(
            RecordTypeId = oppRecordTypeId,  AccountId=acc.Id,PrimaryContact__c=contact.Id
            ),true);

        SBQQ__Quote__c existingQuote = (SBQQ__Quote__c)TestDataFactory.createSObject(
            new SBQQ__Quote__c(SBQQ__Status__c=Constants.QUOTE_STATUS_PUBLISHED, SBQQ__Opportunity2__c = opp.Id ),true);
        Test.startTest();
        Id recordId = QuoteService.doRegenerate(existingQuote.Id);
        Test.stopTest();
        system.assertNotEquals(null, recordId, 'it should return a new quote id when the status is published'); 
    }

    @TestVisible 
    private static SBQQ__Quote__c constructQuoteWithHealthData()
    {
        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(Name='International',External_ID__c = 'INTL'),true);

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id), true);
        List<Product2> bundles = [Select Id from Product2 LIMIT 10];
        if(bundles.size() == 0)
        {
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', true));

        }
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthOptionDefaults', true));
        SBQQ.TriggerControl.disable();
        
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Published',Sub_Status__c='In QA Review'),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, SBQQ__Product__c = bundles[0].Id), true); // uniBundle
        SBQQ__QuoteLine__c oshcBundle = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, SBQQ__Product__c = bundles[2].Id), true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, SBQQ__Product__c = bundles[3].Id, SBQQ__RequiredBy__c = oshcBundle.Id, SBQQ__NetPrice__c = 1234.56 ), true); // oshcBundle
        
        return quote1;  
    }   

    @isTest 
    static void test_sendQuoteToTechQueue(){
        try {
            throw new IllegalArgumentException('This is a test');
        }catch(Exception e){
            SBQQ__Quote__c quote = QuoteService.sendQuoteToTechQueue(null, e.getMessage());
            System.assert(quote.Sub_Status__c == 'Offer creation/update error', '');
        }
    }    

    @isTest 
    static void test_UpdateManagingFaculty(){
        List<Course__c> courseList = new List<Course__c>();
        for(Course__c loopCourse : [SELECT Id FROM Course__c]){
            loopCourse.Managing_Faculty__c = 'TestFaculty';
            courseList.add(loopCourse);
        }
        update courseList;

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(Name='International',External_ID__c = 'INTL'),true);

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id), true);
        List<Product2> bundles = [Select Id from Product2];
        if(bundles.size() == 0)
        {
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.Product2Defaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', true));

        }
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthOptionDefaults', true));

        List<Application_Course_Preference__c> acps = [SELECT Id, Managing_Faculty__c FROM Application_Course_Preference__c ORDER BY Course__r.Name DESC];

        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Published',Sub_Status__c='In QA Review'),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[0].Id, SBQQ__Product__c = bundles[0].Id), true); // uniBundle
        SBQQ__QuoteLine__c oshcBundle = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[1].Id, SBQQ__Product__c = bundles[2].Id), true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[2].Id, SBQQ__Product__c = bundles[3].Id, SBQQ__RequiredBy__c = oshcBundle.Id, SBQQ__NetPrice__c = 1234.56 ), true); // oshcBundle
        
        //publish the quote
        Test.startTest();
            QuoteService.updateManagingFaculty(new List<SBQQ__Quote__c>{quote1});
        Test.stopTest();   
        
        System.assert(quote1.SBQQ__Status__c == 'Published', 'Quote should be published.');
    }

    @isTest 
    static void test_SendPublishEmailToApplicant(){
        TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');

        List<Course__c> courseList = new List<Course__c>();
        for(Course__c loopCourse : [SELECT Id FROM Course__c]){
            loopCourse.Managing_Faculty__c = 'TestFaculty';
            courseList.add(loopCourse);
        }
        update courseList;

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(Name='International',External_ID__c = 'INTL'),true);

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id, FirstName = 'TestFN', LastName = 'TestLN', Email = 'test@test.com'), true);
        List<Product2> bundles = [Select Id from Product2];
        if(bundles.size() == 0)
        {
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.Product2Defaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', true));

        }
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthOptionDefaults', true));

        List<Application_Course_Preference__c> acps = [SELECT Id, Managing_Faculty__c FROM Application_Course_Preference__c ORDER BY Course__r.Name DESC];

        Opportunity testOpportunity = new Opportunity(Name = 'TestName',
                                                      AccountId=acc.Id, 
                                                      PrimaryContact__c = contact.Id, 
                                                      Pricebook2Id=pb.id, 
                                                      CloseDate = Date.today().addDays(15),
                                                      StageName = 'Publish');
        insert testOpportunity;

        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Published',Sub_Status__c='In QA Review', SBQQ__Opportunity2__c = testOpportunity.Id, SBQQ__ExpirationDate__c = testOpportunity.CloseDate),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[0].Id, SBQQ__Product__c = bundles[0].Id), true); // uniBundle
        SBQQ__QuoteLine__c oshcBundle = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[1].Id, SBQQ__Product__c = bundles[2].Id), true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[2].Id, SBQQ__Product__c = bundles[3].Id, SBQQ__RequiredBy__c = oshcBundle.Id, SBQQ__NetPrice__c = 1234.56 ), true); // oshcBundle
          
        testOpportunity.SBQQ__PrimaryQuote__c = quote1.Id;
        update testOpportunity;
      
        //publish the quote
        //create my.app community user
        
        String random = String.valueOf(System.currentTimeMillis());
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON LIMIT 1];
        User communityUser = new User(
            UserName = random + contact.Email,
            FirstName = contact.FirstName,
            LastName = contact.LastName,
            Alias = 'test_cu',
            CommunityNickname = 'test_cu' + random,
            email = contact.Email,
            ContactId = contact.Id,
            ProfileId = communityProfile.Id,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );
        insert communityUser;
        //insert my.app permission set
        PermissionSet myAppPermSet = [SELECT Id FROM PermissionSet WHERE Name = :Constants.MYAPP_PERMSET_NAME LIMIT 1][0];
        UserServices.addPermSetToPortalUsers(new List<User>{communityUser}, new List<PermissionSet>{myAppPermSet}, true);

        //set quote map
        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
        quoteMap.put(contact.Id, quote1);

        //publish the quote
        Test.startTest();
            //initiate email sending test
            QuoteService.sendPublishEmailToApplicant(quoteMap);
        Test.stopTest();   
        
        System.assert(quote1.SBQQ__Status__c == 'Published', 'Quote should be published.');
        TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
    }

      /**
	 *  Sync Quote platform event testing
	 * @author Shalini Mendu
	 */
    @isTest
    public static void testSyncQuote(){
      
    
        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(Name='International',External_ID__c = 'INTL'),true);

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id, FirstName = 'TestFN', LastName = 'TestLN', Email = 'test@test.com'), true);
        List<Product2> bundles = [Select Id from Product2];
        if(bundles.size() == 0)
        {
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.Product2Defaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', true));

        }
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthOptionDefaults', true));

        List<Application_Course_Preference__c> acps = [SELECT Id, Managing_Faculty__c FROM Application_Course_Preference__c ORDER BY Course__r.Name DESC];

        Opportunity testOpportunity = new Opportunity(Name = 'TestName',
                                                      AccountId=acc.Id, 
                                                      PrimaryContact__c = contact.Id, 
                                                      Pricebook2Id=pb.id, 
                                                      CloseDate = Date.today().addDays(15),
                                                      StageName = 'Publish');
        insert testOpportunity;

        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Published',Sub_Status__c='In QA Review', SBQQ__Opportunity2__c = testOpportunity.Id, SBQQ__ExpirationDate__c = testOpportunity.CloseDate),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[0].Id, SBQQ__Product__c = bundles[0].Id), true); // uniBundle
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[1].Id, SBQQ__Product__c = bundles[2].Id), true); // oshcBundle
          
        testOpportunity.SBQQ__PrimaryQuote__c = quote1.Id;
        update testOpportunity;

        Test.startTest();
            testOpportunity.Nominated_Health_Cover__c = 'SINGLE';
            update testOpportunity;
        Test.stopTest();
       
        System.assert( [select Calculate_API_Request_Time__c from SBQQ__Quote__c where id=: quote1.Id].Calculate_API_Request_Time__c!=null );
        
    }

    /**
	 * Test portal user permission sets to be assigned with 2 ps(my.app, MFA)
	 * @author Shalini Mendu
	 */
    @isTest 
    static void test_AssignMYAppPermissionSets(){
        TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');

        List<Course__c> courseList = new List<Course__c>();
        for(Course__c loopCourse : [SELECT Id FROM Course__c]){
            loopCourse.Managing_Faculty__c = 'TestFaculty';
            courseList.add(loopCourse);
        }
        update courseList;

        // Pricebook2 standardPricebook = new Pricebook2(
        //     Id = Test.getStandardPricebookId(),
        //     IsActive = true,
        //     External_ID__c = 'STD'
        // );
        // update standardPricebook;

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(Name='International',External_ID__c = 'INTL'),true);

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id, FirstName = 'TestFN', LastName = 'TestLN', Email = 'test@test.com'), true);
        List<Product2> bundles = [Select Id from Product2];
        if(bundles.size() == 0)
        {
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.Product2Defaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', true));
            bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', true));

        }
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthOptionDefaults', true));

        List<Application_Course_Preference__c> acps = [SELECT Id, Managing_Faculty__c FROM Application_Course_Preference__c ORDER BY Course__r.Name DESC];

        Opportunity testOpportunity = new Opportunity(Name = 'TestName',
                                                      AccountId=acc.Id, 
                                                      PrimaryContact__c = contact.Id, 
                                                      Pricebook2Id=pb.id, 
                                                      CloseDate = Date.today().addDays(15),
                                                      StageName = 'Publish');
        insert testOpportunity;

        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Published',Sub_Status__c='In QA Review', SBQQ__Opportunity2__c = testOpportunity.Id, SBQQ__ExpirationDate__c = testOpportunity.CloseDate),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[0].Id, SBQQ__Product__c = bundles[0].Id), true); // unibundle
        SBQQ__QuoteLine__c oshcBundle = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[1].Id, SBQQ__Product__c = bundles[2].Id), true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Application_Course_Preference__c = acps[2].Id, SBQQ__Product__c = bundles[3].Id, SBQQ__RequiredBy__c = oshcBundle.Id, SBQQ__NetPrice__c = 1234.56 ), true); // oshcBundle
          
        testOpportunity.SBQQ__PrimaryQuote__c = quote1.Id;
        update testOpportunity;
      
        //publish the quote
        //create my.app community user
        
        String random = String.valueOf(System.currentTimeMillis());
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON LIMIT 1];
        User communityUser = new User(
            UserName = random + contact.Email,
            FirstName = contact.FirstName,
            LastName = contact.LastName,
            Alias = 'test_cu',
            CommunityNickname = 'test_cu' + random,
            email = contact.Email,
            ContactId = contact.Id,
            ProfileId = communityProfile.Id,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );
        insert communityUser;
        //set quote map
        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
        quoteMap.put(contact.Id, quote1);
    
        Test.startTest();
        //Assign My App/MFA permission sets
        QuoteService.assignCCUserPermSet(new List<SBQQ__Quote__c>{quoteMap.values()}, new Set<Id>{contact.Id});
        Test.stopTest();   
        List<PermissionSetAssignment> psList = [SELECT Id, AssigneeId, Assignee.ContactId, Assignee.LastLoginDate  
                                                        FROM PermissionSetAssignment 
                                                        WHERE Assignee.ContactId = :contact.Id
                                                            AND PermissionSet.Name In (:Constants.MYAPP_MFA_PERMSET_NAME, :Constants.MYAPP_PERMSET_NAME)];
       System.assert(psList.size() ==2 );
       TriggerCommon.enableTrigger('Country_Attribute__c');
       TriggerCommon.enableTrigger('Account');
       TriggerCommon.enableTrigger('Contact');
       TriggerCommon.enableTrigger('User');
    }
}