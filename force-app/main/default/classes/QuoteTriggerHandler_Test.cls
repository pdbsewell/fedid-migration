@isTest
public class QuoteTriggerHandler_Test {
    
    @testSetup static void setup() {

        //Account Creation
        Account acc1 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);

        //Contact Creation
        Contact contact1 = (Contact)TestDataFactory.createSObject(new Contact(
            AccountId = acc1.Id,
            Email='contact1@email.com',
            Firstname='firstname',
            LastName='lastname'
        ), true);

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc1.Id,Pricebook2Id = Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15)),true);
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc1.Id,SBQQ__PricebookId__c = Test.getStandardPricebookId(), SBQQ__PrimaryContact__c=contact1.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress',SBQQ__Opportunity2__c=opp.Id,SBQQ__ExpirationDate__c = opp.CloseDate, SBQQ__Primary__c = true),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id), true);       
    }
    
    @isTest 
    static void test_ClauseGeneration(){
        Test.startTest();
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, Template_Type__c,
                                   Sub_Status__c, SBQQ__PrimaryContact__c
                                   FROM SBQQ__Quote__c];
        
        SBQQ__Quote__c oldQuote = quotes[0];
        oldQuote.clone(false,true,false,false);

        QuoteTriggerHandler.ClauseGeneration handler = new QuoteTriggerHandler.ClauseGeneration();
        
        Quote_Event__e quoteEvent1 = new Quote_Event__e(Quote_Id__c=oldQuote.Id);
        Database.SaveResult sr = EventBus.publish(quoteEvent1);   
        
        // Verify that the publish was successful
        Assert.isTrue(sr.isSuccess());
        
        // Deliver the test event before Test.stopTest()
        Test.getEventBus().deliver(); 
        
        handler.process(quoteEvent1);
        handler.execute();
        Test.stopTest();
    }
    
    @isTest 
    static void test_QuoteLineTransform(){
        Test.startTest();
        QuoteTriggerHandler.lockUserCreation = true;
        
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, SBQQ__Opportunity2__c,
                                   Sub_Status__c, SBQQ__PrimaryContact__c,Template_Type__c
                                   FROM SBQQ__Quote__c];
        
        SBQQ__Quote__c oldQuote = quotes[0];
        
        SBQQ__Quote__c newQuote = oldQuote.clone(true,true,false,false);
        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_IN_REVIEW;
        newQuote.Sub_Status__c = Constants.QUOTE_SUBSTATUS_QAPREVIEW;
        
        QuoteTriggerHandler.QuoteLineTransform handler2 = new QuoteTriggerHandler.QuoteLineTransform();
        handler2.process(newQuote,oldQuote);   
        handler2.execute();
        
        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_PUBLISHED;
        newQuote.Sub_Status__c = '';
        handler2.process(newQuote,oldQuote);        
        handler2.execute();
        Assert.isFalse(handler2.publishedQuotes.isEmpty(), 'Quote should go for QuoteService.assignCCUserPermSet');
        
        oldQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_IN_REVIEW;        
        oldQuote.Sub_Status__c = Constants.QUOTE_PRICE_CALCULATED;
        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_IN_REVIEW;  
        newQuote.Sub_Status__c = Constants.QUOTE_SUBSTATUS_QAPREVIEW; 
        
        handler2.process(newQuote,oldQuote);
        handler2.execute();
        Assert.isFalse(handler2.impactedQuotes.isEmpty(), 'Quote should go to QuoteLineService.processPublishedQuoteLines');
        
        QuoteTriggerHandler.skipDocumentCheckList = true;
        oldQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_PUBLISHED;        
        oldQuote.Sub_Status__c = '';        
        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_SIGNED;        
        newQuote.Sub_Status__c = Constants.QUOTE_SUBSTATUS_OFFER_SIGNED_RECIPIENT1;
        handler2.process(newQuote,oldQuote);
        handler2.execute();   
        Assert.isFalse(handler2.signedOpportunityIds.isEmpty(), 'Oppty should go for document checklist');
        Test.stopTest();
    }
    /*
    * Tests whether Monash Abroad Opportunities are excluded from Acceptance Checklist rules
    */
    @isTest
    static void test_QuoteLineTransform_MonashAbroadOpportunities() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;

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
        TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Application_Course_Preference__c',SBQQ__TargetField__c='Application_Course_Preference__c', SBQQ__Product__c=bundles[0].Id),true);
        TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Health_Cover_Duration__c',SBQQ__TargetField__c='Health_Cover_Duration__c', SBQQ__Product__c=bundles[2].Id),true);

        //Product Feature Creation
        TestDataFactory.createSObject(new SBQQ__ProductFeature__c(SBQQ__ConfiguredSKU__c=bundles[0].Id,SBQQ__Number__c=1),true);

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
        
        
        TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12345',APXT_Redlining__Text__c='test course code match'), true);
        
        TestDataFactory.createSObject(new Course_Duration__c(Pricebook__c = pb.Id), true);

        insert new Stg_Course_Fee__c[]{
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,false),
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false)
        };

        //Create Partner ACcount
        Account partnerAcc = (Account)TestDataFactory.createSObject(new Account(Email__c = 'partner@monash.edu'), true);
        //Application Creation
        Application__c app = (Application__c)TestDataFactory.createSObject(new Application__c(Applicant__c = contact.Id, Agent__c=partnerAcc.Id, Type_of_study__c='Study Abroad'), true);

        //ACP Creation
        Application_Course_Preference__c[] acp =  new Application_Course_Preference__c[]{
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
        insert acp;
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc.Id,Pricebook2Id = Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15)),true);
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c = Test.getStandardPricebookId(), SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress',SBQQ__Opportunity2__c=opp.Id,SBQQ__ExpirationDate__c = opp.CloseDate, SBQQ__Primary__c = true),true);
        SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Expiry_Date__c = Date.today().addDays(15), Application_Course_Preference__c = acp[0].id), false)
        }; 
        insert qlis; 

        QuoteTriggerHandler.lockUserCreation = true;        
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, SBQQ__Opportunity2__c,Template_Type__c,
                                   Sub_Status__c, SBQQ__PrimaryContact__c
                                   FROM SBQQ__Quote__c WHERE id = :quote1.id];
        SBQQ__Quote__c newQuote = quotes[0];
        SBQQ__Quote__c oldQuote = newQuote.clone(true,true,false,false);
        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_SIGNED;
        
        QuoteTriggerHandler.QuoteLineTransform handler2 = new QuoteTriggerHandler.QuoteLineTransform();
        Test.startTest();
            handler2.process(newQuote,oldQuote);   
            handler2.execute();
        Test.stopTest();
        Assert.isTrue(handler2.signedOpportunityIds.isEmpty(), 'Monash Abroad Opportunities not filtered from processing for Acceptance Checklist!');
    }    
    @isTest 
    static void test_QuoteStatusUpdates(){
        Test.startTest();
        QuoteTriggerHandler.lockUserCreation = true;
        
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, Sub_Status__c, SBQQ__PrimaryContact__c, 
                                   Product_Status__c, Sub_status_changed_on__c, Contact_Access__c,
                                   SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c,
                                   SBQQ__ExpirationDate__c, In_Technical_Error__c,
                                   SBQQ__EndDate__c, SBQQ__StartDate__c, Managing_Faculty__c,
                                   Offer_Type__c, Expiry_Status__c, Offer_Status_Date__c,
                                   Visa_Start_Date__c, Visa_End_Date__c,Template_Type__c,
                                   Primary_DocuSign_Envelop_Id__c, Docusign_Expiry_Time__c, OpportunityStage__c, SBQQ__Primary__c
                                   FROM SBQQ__Quote__c];
        
        SBQQ__Quote__c oldQuote = quotes[0];
        
        SBQQ__Quote__c newQuote = oldQuote.clone(true,true,false,false);
		
        QuoteTriggerHandler.QuoteStatusUpdates handler2 = new QuoteTriggerHandler.QuoteStatusUpdates();   
        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_IN_REVIEW;
        newQuote.Sub_Status__c = 'Pricing Completed'; 
        newQuote.SBQQ__Primary__c = true;  
        handler2.process(newQuote,oldQuote);   
        handler2.execute();
        Assert.isNotNull(newQuote.Pricing_Completed_TimeStamp__c, 'Pricing_Completed_TimeStamp__c must be populated.');
        
        QuoteTriggerHandler.QuoteStatusUpdates handler3 = new QuoteTriggerHandler.QuoteStatusUpdates();   
        newQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_IN_REVIEW;
        newQuote.Sub_Status__c = 'Business request review'; 
        newQuote.SBQQ__Primary__c = true;  
        handler3.process(newQuote,oldQuote);   
        handler3.execute();
        Assert.areEqual(newQuote.OwnerId,QuoteService.businessQueue[0].Id, 'Quote is assigned to queue.');

        QuoteTriggerHandler.QuoteStatusUpdates handler4 = new QuoteTriggerHandler.QuoteStatusUpdates();      
        newQuote.SBQQ__Status__c = 'Approved';
        newQuote.SBQQ__Opportunity2__c = '0064Y000002B2t0QAC';
        newQuote.Sub_Status__c = '';   
        handler4.process(newQuote,oldQuote);   
        Assert.isFalse(handler4.opportunities.isEmpty(), 'Opportunity update to In Review');

        QuoteTriggerHandler.QuoteStatusUpdates handler5 = new QuoteTriggerHandler.QuoteStatusUpdates();    
        newQuote.SBQQ__PrimaryContact__c = '0034Y00000310h3QAA';
        newQuote.SBQQ__Status__c = 'Published';
        newQuote.Sub_Status__c = '';       
        handler5.process(newQuote,oldQuote);   
        Assert.areEqual(newQuote.Contact_Access__c,newQuote.SBQQ__PrimaryContact__c, 'Contact Access shouild be populated');   
    }

    @isTest 
    static void test_QuoteStatusUpdatesRejected(){
        Test.startTest();
        QuoteTriggerHandler.lockUserCreation = true;
        
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, Sub_Status__c, SBQQ__PrimaryContact__c, 
                                   Product_Status__c, Sub_status_changed_on__c, Contact_Access__c,
                                   SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c,
                                   SBQQ__ExpirationDate__c, In_Technical_Error__c,
                                   SBQQ__EndDate__c, SBQQ__StartDate__c,Template_Type__c,
                                   Offer_Type__c, Expiry_Status__c, Offer_Status_Date__c,
                                   Visa_Start_Date__c, Visa_End_Date__c,
                                   Primary_DocuSign_Envelop_Id__c, Docusign_Expiry_Time__c, OpportunityStage__c, SBQQ__Primary__c
                                   FROM SBQQ__Quote__c];
        
        SBQQ__Quote__c oldQuote = quotes[0];
        
        SBQQ__Quote__c newQuote = oldQuote.clone(true,true,false,false);
        
        QuoteTriggerHandler.QuoteStatusUpdates handler7 = new QuoteTriggerHandler.QuoteStatusUpdates();    
        oldQuote.SBQQ__Status__c = 'Published';
        oldQuote.Sub_Status__c = '';
        
        newQuote.SBQQ__Status__c = 'Rejected';
        newQuote.Sub_Status__c = '';  
        newQuote.Primary_DocuSign_Envelop_Id__c = '1234567890';
        newQuote.Docusign_Expiry_Time__c = null;
        
        handler7.process(newQuote,oldQuote);   
        handler7.execute();
        Assert.isFalse(handler7.quoteForQuotaRecalc.isEmpty(), 'Quote to go for quota product recalc.');
                      
        Test.stopTest();         
    }

    @isTest 
    static void test_QuoteHandleExpiryDate(){
        Test.startTest();
        QuoteTriggerHandler.lockUserCreation = true;
        
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, Sub_Status__c, SBQQ__PrimaryContact__c, 
                                   Product_Status__c, Sub_status_changed_on__c, Contact_Access__c,
                                   SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c,
                                   SBQQ__ExpirationDate__c, In_Technical_Error__c,
                                   SBQQ__EndDate__c, SBQQ__StartDate__c,Template_Type__c,
                                   Offer_Type__c, Expiry_Status__c, Offer_Status_Date__c,
                                   Visa_Start_Date__c, Visa_End_Date__c,
                                   Primary_DocuSign_Envelop_Id__c, Docusign_Expiry_Time__c, OpportunityStage__c, SBQQ__Primary__c
                                   FROM SBQQ__Quote__c];
        
        SBQQ__Quote__c oldQuote = quotes[0];
        
        SBQQ__Quote__c newQuote = oldQuote.clone(true,true,false,false);
        
        QuoteTriggerHandler.QuoteStatusUpdates handler8 = new QuoteTriggerHandler.QuoteStatusUpdates();   
        newQuote.SBQQ__PrimaryContact__c = '0034Y00000310h3QAA';
        newQuote.SBQQ__Status__c = 'Published';
        newQuote.Sub_Status__c = '';      
        newQuote.SBQQ__Primary__c = true;          
        newQuote.SBQQ__ExpirationDate__c = Date.today().addDays(-15);
        handler8.process(newQuote,oldQuote);   
        handler8.execute();
        
        Assert.areEqual(newQuote.SBQQ__Status__c,'Expired');
                      
        Test.stopTest();         
    }


    @isTest
    static void shouldNotFireExpiryQueueableForReCalcWhenNoDocuSignEnvId() {
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, Sub_Status__c, SBQQ__PrimaryContact__c, 
            Product_Status__c, Sub_status_changed_on__c, Contact_Access__c,
            SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c,
            SBQQ__ExpirationDate__c, In_Technical_Error__c,
            SBQQ__EndDate__c, SBQQ__StartDate__c, Managing_Faculty__c,Template_Type__c,
            Offer_Type__c, Expiry_Status__c, Offer_Status_Date__c,
            Visa_Start_Date__c, Visa_End_Date__c,
            Primary_DocuSign_Envelop_Id__c, Docusign_Expiry_Time__c, OpportunityStage__c, SBQQ__Primary__c
            FROM SBQQ__Quote__c];

        SBQQ__Quote__c oldQuote = quotes[0];
        
        SBQQ__Quote__c newQuote = oldQuote.clone(true,true,false,false);

           
        newQuote.SBQQ__Opportunity2__c = FakeRecordIdGenerator.generateId(
            Opportunity.getSObjectType()
        );
        newQuote.SBQQ__Status__c = 'Expired and regenerated';
        newQuote.Sub_Status__c = '';   
        newQuote.Product_Status__c = 'Grant expired';
        newQuote.SBQQ__Primary__c = true;
        newQuote.Primary_DocuSign_Envelop_Id__c = '';
        
        Test.startTest();
        QuoteTriggerHandler.QuoteStatusUpdates handler = new QuoteTriggerHandler.QuoteStatusUpdates(); 
        handler.process(newQuote,oldQuote); 
        handler.execute();
        Assert.areEqual(0, Limits.getQueueableJobs(), 
            'Expected no queueable job as there is no docusign evelop Id generated.'
        );        
        Test.stopTest();        
    }

    @isTest
    static void shouldFireExpiryQueueableOnExpiryWhenDocuSignEnvIdExists() {
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, Sub_Status__c, SBQQ__PrimaryContact__c, 
            Product_Status__c, Sub_status_changed_on__c, Contact_Access__c,
            SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c,
            SBQQ__ExpirationDate__c, In_Technical_Error__c,
            SBQQ__EndDate__c, SBQQ__StartDate__c, Managing_Faculty__c,Template_Type__c,
            Offer_Type__c, Expiry_Status__c, Offer_Status_Date__c,
            Visa_Start_Date__c, Visa_End_Date__c,
            Primary_DocuSign_Envelop_Id__c, Docusign_Expiry_Time__c, OpportunityStage__c, SBQQ__Primary__c
            FROM SBQQ__Quote__c];

        SBQQ__Quote__c oldQuote = quotes[0];
        
        SBQQ__Quote__c newQuote = oldQuote.clone(true,true,false,false);

        
        newQuote.SBQQ__Status__c = 'Expired and regenerated';
        newQuote.SBQQ__Primary__c = true;
        newQuote.Primary_DocuSign_Envelop_Id__c = '123-abc';
        
        Test.startTest();
        QuoteTriggerHandler.QuoteStatusUpdates handler = new QuoteTriggerHandler.QuoteStatusUpdates(); 
        handler.process(newQuote,oldQuote); 
        handler.handleClosedLost(newQuote);
        Assert.areEqual(1, Limits.getQueueableJobs(), 
            'Expected 1 queueable job as queueable should be executed to expiry the offer in DocuSign.'
        );        
        Test.stopTest();        
    }

    public void testQuoteErrorLog(){
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, Sub_Status__c, SBQQ__PrimaryContact__c, 
            Product_Status__c, Sub_status_changed_on__c, Contact_Access__c,
            SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c,
            SBQQ__ExpirationDate__c, In_Technical_Error__c,
            SBQQ__EndDate__c, SBQQ__StartDate__c, Managing_Faculty__c,
            Offer_Type__c, Expiry_Status__c, Offer_Status_Date__c,
            Visa_Start_Date__c, Visa_End_Date__c,Template_Type__c,
            Primary_DocuSign_Envelop_Id__c, Docusign_Expiry_Time__c, OpportunityStage__c, SBQQ__Primary__c
            FROM SBQQ__Quote__c LIMIT 1];

        SBQQ__Quote__c oldQuote = quotes[0];
        
        SBQQ__Quote__c newQuote = oldQuote.clone(true,true,false,false);

        newQuote.Error_Log__c = 'This is a test';

        QuoteTriggerHandler.OfferLogHandler handler = new QuoteTriggerHandler.OfferLogHandler();
        handler.process(newQuote,oldQuote); 
        handler.execute();
        Assert.isFalse(handler.logs.isEmpty(), 'Offer log inserted successfully.');
    }

    @isTest
    private static void testQuoteOpptySync(){
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;

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
        TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Application_Course_Preference__c',SBQQ__TargetField__c='Application_Course_Preference__c', SBQQ__Product__c=bundles[0].Id),true);
        TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Health_Cover_Duration__c',SBQQ__TargetField__c='Health_Cover_Duration__c', SBQQ__Product__c=bundles[2].Id),true);

        //Product Feature Creation
        TestDataFactory.createSObject(new SBQQ__ProductFeature__c(SBQQ__ConfiguredSKU__c=bundles[0].Id,SBQQ__Number__c=1),true);

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
        
        
        TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12345',APXT_Redlining__Text__c='test course code match'), true);
        
        TestDataFactory.createSObject(new Course_Duration__c(Pricebook__c = pb.Id), true);

        insert new Stg_Course_Fee__c[]{
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,false),
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false)
        };

        //Create Partner ACcount
        Account partnerAcc = (Account)TestDataFactory.createSObject(new Account(Email__c = 'partner@monash.edu'), true);
        //Application Creation
        Application__c app = (Application__c)TestDataFactory.createSObject(new Application__c(Applicant__c = contact.Id, Agent__c=partnerAcc.Id, Type_of_study__c='Study Abroad'), true);
         //Create LOV
         List<List_of_Values__c> lovList = new List<List_of_Values__c>{
            new List_of_Values__c(
                Unique_Key__c = 'OFFER-G-CO',
                Value__c = 'SATISFIED',
                System_Code__c = 'COND-OFFER'
                
            )};
        upsert lovList;
        
        List<List_of_Values__c> lovListret = [select System_Code__c from List_of_Values__c limit 1];
        //ACP Creation
        Application_Course_Preference__c[] acp =  new Application_Course_Preference__c[]{
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
                        Outcome_Status__c= lovListret[0].System_Code__c,
                        Application__c = app.Id), false)
        };
        insert acp;

        Product2 product1 = (Product2)TestDataFactory.createSObject(new Product2(Name='Monash Scholarship1', External_Id__c='12345', Expiry_days__c=15),true);

        PricebookEntry pbe1 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product1.id, unitprice= 5000),true);

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc.Id,Pricebook2Id = Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15)),true);
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc.Id,SBQQ__PricebookId__c = Test.getStandardPricebookId(), SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress',SBQQ__Opportunity2__c=opp.Id,SBQQ__ExpirationDate__c = opp.CloseDate, SBQQ__Primary__c = true),true);
        SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id, Expiry_Date__c = Date.today().addDays(15), Application_Course_Preference__c = acp[0].id, SBQQ__Quantity__c = 1, SBQQ__PricebookEntryId__c = pbe1.id), false)
        }; 
        insert qlis; 

        QuoteTriggerHandler.lockUserCreation = true;        
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, SBQQ__Opportunity2__c,Template_Type__c,
                                   Sub_Status__c, SBQQ__PrimaryContact__c
                                   FROM SBQQ__Quote__c WHERE id = :quote1.id];
        SBQQ__Quote__c newQuote = quotes[0];
        SBQQ__Quote__c oldQuote = newQuote.clone(true,true,false,false);
        newQuote.Sub_Status__c = Constants.QUOTE_PRICE_CALCULATED;
        oldQuote.Sub_Status__c = 'Products Added';

        QuoteTriggerHandler.QuoteOpptySync handler2 = new QuoteTriggerHandler.QuoteOpptySync();
        Test.startTest();
            handler2.process(newQuote,oldQuote);   
            handler2.execute();
        Test.stopTest();
        Assert.isFalse(handler2.syncedOpptyLineItems.isEmpty(), 'Opportunities not synced with Quotes after Pricing Completed!');
    }

    /*******************************************************************************
	* @description 	manual accept/reject the offer and close the opportunity test
    * @author Vishal Gupta
    * date 12/5/2025
	*******************************************************************************/
	@isTest
    private static void testGRScholarshipOfferAccepted() {
        Test.startTest();
        GRScholarshipOfferResponseServiceMock mock = new GRScholarshipOfferResponseServiceMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id, Person_ID_unique__c FROM Contact WHERE id =: applicant.contactId];
        
        //create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        insert app;
        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        Calendar__c cal = new Calendar__c();
        cal.Calendar_Code__c = '1111_1111';
        cal.type__c = 'ADM-RES1';
        cal.name = 'ADM_2025_ADM-RES1';
        cal.Sequence_Number__c = 1111;
        cal.Sequence_Number_Year__c = 1111;
        insert cal;
        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course_Code__c = 'E6001';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-CSP';
        courseOffering.Academic_CI_Sequence_Number__c = 1111;
        courseOffering.Admission_CI_Sequence_Number__c = 1111;
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Unit_Set_Code__c = null;
        courseOffering.Unit_Set_Version__c = null;
        courseOffering.Admission_Calendar_Description__c = 'CrOf0';
        insert courseOffering;

        //create Application_Course_Preference__c
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        coursePreference.Callista_Unique_Key_AP__c = 'ACP-1';
        coursePreference.Graduate_Research_Application_Type__c = 'Scholarship';
        insert coursePreference;

        Opportunity oppty = new Opportunity(Name = 'test', StageName = 'New Offer', CloseDate = date.today().addDays(3), PrimaryContact__c = c.Id, Application_Course_Preference__c = coursePreference.Id,
                            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Graduate_Research_Offer').getRecordTypeId(), Research_Offer_Type__c = 'Scholarship Offer');
        insert oppty;
        
        TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppty.Id),true);

        // given : the GR Scholarship offer is there which needs to be accepted/rejected
        SBQQ__Quote__c quote = [SELECT ID, SBQQ__Status__c, SBQQ__Opportunity2__c,Template_Type__c,
                                   Sub_Status__c, SBQQ__PrimaryContact__c
                                   FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :oppty.id LIMIT 1];
        // when : the offer is accepted
        quote.Is_GR_Offer__c = true;
        quote.SBQQ__Status__c = 'Accepted';
        update quote;
        // then : the opportunity should stage should be set as Closed Won
        Opportunity oppAfterUpdate = [SELECT Id, StageName FROM Opportunity WHERE Id =:oppty.Id];
        Assert.areEqual(oppAfterUpdate.StageName, 'Closed Won', 'opportunity is closed');
        Test.StopTest();
    }

    /*******************************************************************************
	* @description 	manual accept/reject the offer and close the opportunity test
    * @author Vishal Gupta
    * date 12/5/2025
	*******************************************************************************/
	@isTest
    private static void testGRScholarshipOfferDeclined() {
        Test.startTest();
        GRScholarshipOfferResponseServiceMock mock = new GRScholarshipOfferResponseServiceMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id, Person_ID_unique__c FROM Contact WHERE id =: applicant.contactId];
        
        //create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        insert app;
        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        Calendar__c cal = new Calendar__c();
        cal.Calendar_Code__c = '1111_1111';
        cal.type__c = 'ADM-RES1';
        cal.name = 'ADM_2025_ADM-RES1';
        cal.Sequence_Number__c = 1111;
        cal.Sequence_Number_Year__c = 1111;
        insert cal;
        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course_Code__c = 'E6001';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-CSP';
        courseOffering.Academic_CI_Sequence_Number__c = 1111;
        courseOffering.Admission_CI_Sequence_Number__c = 1111;
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Unit_Set_Code__c = null;
        courseOffering.Unit_Set_Version__c = null;
        courseOffering.Admission_Calendar_Description__c = 'CrOf0';
        insert courseOffering;

        //create Application_Course_Preference__c
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        coursePreference.Callista_Unique_Key_AP__c = 'ACP-1';
        coursePreference.Graduate_Research_Application_Type__c = 'Scholarship';
        insert coursePreference;

        Opportunity oppty = new Opportunity(Name = 'test', StageName = 'New Offer', CloseDate = date.today().addDays(3), PrimaryContact__c = c.Id, Application_Course_Preference__c = coursePreference.Id,
                            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Graduate_Research_Offer').getRecordTypeId(), Research_Offer_Type__c = 'Scholarship Offer');
        insert oppty;
        
        TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppty.Id),true);

        // given : the GR Scholarship offer is there which needs to be accepted/rejected
        SBQQ__Quote__c quote = [SELECT ID, SBQQ__Status__c, SBQQ__Opportunity2__c,Template_Type__c,
                                   Sub_Status__c, SBQQ__PrimaryContact__c
                                   FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :oppty.id LIMIT 1];
        // when : the offer is Rejected
        quote.Is_GR_Offer__c = true;
        quote.SBQQ__Status__c = 'Declined';
        quote.Decline_Reason__c = 'Declined';
        update quote;
        // then : the opportunity should stage should be set as Canceled/Rejected
        Opportunity oppAfterUpdate = [SELECT Id, StageName FROM Opportunity WHERE Id =:oppty.Id];
        Assert.areEqual(oppAfterUpdate.StageName, 'Canceled/Rejected', 'opportunity is closed');
        Test.StopTest();
    }
}