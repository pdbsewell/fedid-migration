/**
* @author Jasmin Joy Rudio
* @description Apex test class for QuoteLineService class
* @group SF Offers
*
**/
@isTest(isParallel = false)
public with sharing class QuoteLineService_Test {

    @testSetup static void setup() {
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
        //insert OrgUnitBundleMapping__c
        Test.loadData(OrgUnitBundleMapping__c.sObjectType, 'OrgUnitBundleMappingDataTest');

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);

        //Account Creation
        Account acc1 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);
        Account acc2 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 2'), true);

        //Creating a product for scholarship
        Product2 product1 = (Product2)TestDataFactory.createSObject(new Product2(Name='Monash Scholarship1', Family = 'Scholarship', Description__c = 'Monash Scholarship1', Description = 'Monash Scholarship1', Type__c = 'Capped', Quota_Original__c = 5, Face_Value__c = 100, Value_Deductable__c = 50, External_Id__c='12345', Expiry_days__c=15),true);
		//product always required a standard pricebook         
        PricebookEntry pbe1 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product1.id, unitprice=-5000),true);
        //add custom pricebook entry for created product
        // PricebookEntry pbe2 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = product1.id, unitprice=-5000), true);

        //Calendar create
        Date startDate = Date.today();
        Date endDate = Date.today().addYears(2);
        
        Calendar__c cal1 = (Calendar__c)TestDataFactory.createSObject(new Calendar__c(Name='ADM_2021_ADM-1',Start_Date__c=startDate,End_Date__c=endDate,Category__c='ADMISSION',Type__c='ADM-1',Status__c='ACTIVE',calendar_code__c='666_666'),true);

        Calendar_Dates__c cd = new Calendar_Dates__c(Name = 'CRS-START', Calendar_Code__c = '11050_11078', Calendar_Date_Unique_Key__c = '11050_11078CRS-START1', CalendarId__c = cal1.Id, Date_Sequence_Nbr__c = 1, Date_Type_Description__c = 'COURSE START DATE FOR ADMISSION PERIODS', Date_Value__c = Date.today() );
        insert cd;

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

        date bday1 = date.newInstance(1983, 7, 15);
        date bday2 = date.newInstance(2005, 7, 15);
        //Contact Creation
        Contact contact1 = (Contact)TestDataFactory.createSObject(new Contact(FirstName='Test', Lastname='Con1',AccountId = acc1.Id, Birthdate = bday1,Country_of_Residence__c='INDIA'), true);
        Contact contact2 = (Contact)TestDataFactory.createSObject(new Contact(FirstName='Test', LastName='Con2',AccountId = acc2.Id, Birthdate = bday2,Country_of_Residence__c='CHILE'), true);

        Product2[] bundles = new Product2[0];
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.Product2Defaults', false));
        insert bundles;

        //Add configuration attribute to the bundle.
        // SBQQ__ConfigurationAttribute__c configAttribute = (SBQQ__ConfigurationAttribute__c)TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Application_Course_Preference__c',SBQQ__TargetField__c='Application_Course_Preference__c', SBQQ__Product__c=bundles[0].Id),true);

        // //Product Feature Creation
        // SBQQ__ProductFeature__c pf = (SBQQ__ProductFeature__c)TestDataFactory.createSObject(new SBQQ__ProductFeature__c(SBQQ__ConfiguredSKU__c=bundles[0].Id,SBQQ__Number__c=1),true);

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
        
        Map<String,Course_Offering__c> courseOfferings = new Map<String,Course_Offering__c>();

        for(Course__c c : courses){
            Course_Offering__c co = (Course_Offering__c) TestDataFactory.createSObject(new Course_Offering__c(Course_Code__c=c.Course_Code__c,Override_Duration__c=6,Override_Duration_Unit__c='Month'),false);
            courseOfferings.put(c.Course_Code__c,co);
        }
        insert courseOfferings.values();
        TestDataFactory.createSObject(new Course_Duration__c(Pricebook__c = pb.Id), true);

        insert new Stg_Course_Fee__c[]{
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,false),
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false)
        };
        //Application Creation
        Application__c app = (Application__c)TestDataFactory.createSObject(new Application__c(Applicant__c = contact1.Id), true);

        //ACP Creation
        Application_Course_Preference__c[] acps = new Application_Course_Preference__c[]{
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                        Course__c = courses[0].Id, 
                        Course_Code__c = courses[0].Name,
                        Course_Version_Number__c = Double.valueOf(courses[0].Version__c),
                        Course_Code_Unique__c = courses[0].Course_Code__c,
                        Unit_Set__c = courses[1].Id, 
                        Unit_Set_Code__c = courses[1].Name, 
                        Unit_Set_Version__c = Double.valueOf(courses[1].Version__c),
                        Application__c = app.Id,
                        Calendar_Code__c = cal1.Id,
                        Course_Offering__c=courseOfferings.get(courses[1].Course_Code__c).Id), false),
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                       Course__c = courses[2].Id, 
                        Course_Code__c = courses[2].Name,
                        Course_Version_Number__c = Double.valueOf(courses[2].Version__c),
                        Course_Code_Unique__c = courses[2].Course_Code__c,
                        Unit_Set__c = courses[3].Id, 
                        Unit_Set_Code__c = courses[3].Name, 
                        Unit_Set_Version__c = Double.valueOf(courses[3].Version__c),
                        Application__c = app.Id,
                        Calendar_Code__c = cal1.Id,
                        Course_Offering__c=courseOfferings.get(courses[2].Course_Code__c).Id), false),
                (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                       Course__c = courses[2].Id, 
                        Course_Code__c = courses[2].Name,
                        Course_Version_Number__c = Double.valueOf(courses[2].Version__c),
                        Course_Code_Unique__c = courses[2].Course_Code__c,
                        Unit_Set__c = courses[3].Id, 
                        Unit_Set_Code__c = courses[3].Name, 
                        Unit_Set_Version__c = Double.valueOf(courses[3].Version__c),
                        Application__c = app.Id,
                        Calendar_Code__c = cal1.Id,
                        Course_Offering__c=courseOfferings.get(courses[2].Course_Code__c).Id), false)                            
        };
        insert acps;
        SBQQ.TriggerControl.disable();
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc1.Id,Pricebook2Id=pb.id, CloseDate = Date.today().addDays(15)),true);
        Opportunity opp1 = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc1.Id,Pricebook2Id=Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15)),true);
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc1.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact1.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress', SBQQ__Opportunity2__c = opp.Id, SBQQ__ExpirationDate__c = opp.CloseDate),true);
        SBQQ__Quote__c quote2 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc2.Id,SBQQ__PricebookId__c=Test.getStandardPricebookId(),SBQQ__PrimaryContact__c=contact2.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress', SBQQ__Opportunity2__c = opp1.Id, SBQQ__ExpirationDate__c = opp.CloseDate),true);

        //QuoteLineItem Creation
        SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id,Application_Course_Preference__c = acps[0].Id, Expiry_Date__c = Date.today().addDays(15), SBQQ__Product__c = bundles[0].Id, SBQQ__Quantity__c = 1), false),
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id,Application_Course_Preference__c = acps[1].Id, Expiry_Date__c = Date.today().addDays(15), SBQQ__Product__c = bundles[3].Id, SBQQ__Quantity__c = 1), false),
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote2.id,Application_Course_Preference__c = acps[2].Id, Expiry_Date__c = Date.today().addDays(15), SBQQ__Product__c = bundles[1].Id, SBQQ__Quantity__c = 1), false),
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote2.id,SBQQ__Product__c=product1.Id, Expiry_Date__c = Date.today().addDays(10), SBQQ__Quantity__c = 1, SBQQ__PricebookEntryId__c = pbe1.id), false)
        }; 
        insert qlis; 
        List<SBQQ__QuoteLine__c> toUpdateQL = new List<SBQQ__QuoteLine__c>();
        qlis[0].Offer_Primary_Quote_Line__c = qlis[1].Id;
        toUpdateQL.add(qlis[0]);
        
        qlis[1].SBQQ__RequiredBy__c = qlis[0].Id;
        toUpdateQL.add(qlis[1]);
        
        update toUpdateQL;
        TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
    }
    
    @isTest
    private static void scholarshipExpiryTest(){ 
        Test.startTest();
            SBQQ__Quote__c quote = [SELECT Id,SBQQ__Status__c,Sub_Status__c,SBQQ__PrimaryContact__c,SBQQ__PrimaryContact__r.Country_of_Residence__c,
                                    SBQQ__Opportunity2__c,SBQQ__PrimaryContact__r.Under_18__c FROM SBQQ__Quote__c where SBQQ__PrimaryContact__r.Lastname='Con2' limit 1];
            QuoteTriggerHandler.lockUserCreation = true;
            quote.SBQQ__Status__c = 'Published';
            quote.Sub_Status__c = 'Pricing Completed';
            update quote;
            Test.getEventBus().deliver();        
        Test.stopTest();
        SBQQ__QuoteLine__c updatedQuoteLine = [Select Id, Expiry_Date__c, Published__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =: quote.Id AND SBQQ__Product__r.Name = 'Monash Scholarship1' limit 1];
        Assert.isTrue(updatedQuoteLine.Expiry_Date__c > Date.today().addDays(10),'Quote Line Expiry Date should be greater than 10 days.');
        Assert.areEqual(updatedQuoteLine.Published__c,true,'Quote Line should be marked as published.');
    } 


    @isTest
    private static void shouldRunStandardOfferSpecialization(){
        Test.startTest();
            Id quoteId = offerSpecialization('OfferSpecification');
            List<SBQQ__QuoteLine__c> childQL = [SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c, Offer_Primary_Quote_Line__c,
                                                (SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c, Offer_Primary_Quote_Line__c FROM Conga_Primary_Quote_Lines__r) 
                                                FROM  SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId AND Offer_Primary_Quote_Line__c != null];
        Test.stopTest();
        system.assertEquals(1, childQL.size(), 'it should modify quote lines');        
    }
     @isTest
    private static void shouldRunEnglishOfferSpecialization(){
        Test.startTest();
            Id quoteId = offerSpecialization('EnglishOfferSpecification');
            List<SBQQ__QuoteLine__c> childQL = [SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c, Offer_Primary_Quote_Line__c, Admin_Fee__c,
                                                (SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c  FROM Conga_Primary_Quote_Lines__r) 
                                                FROM  SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId AND Admin_Fee__c > 0];
        Test.stopTest();
        system.assertEquals(1, childQL.size(), 'it should modify quote lines');
        system.assertNotEquals(childQL[0].Admin_Fee__c, 0, 'it should modify admin fee'); 
    }
     @isTest
    private static void shouldRunDiplomaOfferSpecialization(){
        Test.startTest();
            Id quoteId = offerSpecialization('DiplomaOfferSpecification');
            List<SBQQ__QuoteLine__c> childQL = [SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c, Offer_Primary_Quote_Line__c,
                                                    (SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c FROM Conga_Primary_Quote_Lines__r) 
                                                    FROM  SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId AND Offer_Primary_Quote_Line__c != null];
            List<SBQQ__QuoteLine__c> optionQL = [SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c, Offer_Primary_Quote_Line__c, Offer_Option_Quote_Line__c,
                                                    (SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c FROM Conga_Primary_Quote_Lines__r) 
                                                    FROM  SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId AND Offer_Option_Quote_Line__c != null];
        Test.stopTest();
        system.assertEquals(1, optionQL.size(), 'it should modify quote optinal lines');        
        system.assertEquals(1, childQL.size(), 'it should modify quote primary lines');

    }  
    private static Id offerSpecialization(string SpecificationType){
        Account acct = (Account)TestDataFactory.createSObject( new Account(), true);
        Contact con = (Contact)TestDataFactory.createSObject( new Contact(AccountId=acct.Id), true);
        Product2 bundle = [SELECT Id FROM Product2 WHERE Family = 'Bundle' LIMIT 1];
        bundle.Document_Generation_Spec__c = SpecificationType ;
        update bundle;
        Product2 course = [SELECT Id FROM Product2 WHERE Family = 'Course' LIMIT 1];
  
        
        
        SBQQ.TriggerControl.disable();
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acct.Id,Pricebook2Id=Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15)),true);
        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject( new SBQQ__Quote__c(SBQQ__PrimaryContact__c=con.Id,SBQQ__Opportunity2__c = opp.Id), true);
        SBQQ__QuoteLine__c bundleQL = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.id,
                                                            Expiry_Date__c = Date.today().addDays(15), SBQQ__Product__c = bundle.Id), false);
        insert bundleQL;
        
        SBQQ__QuoteLine__c courseQL = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.id, 
                                                            Expiry_Date__c = Date.today().addDays(15), SBQQ__Product__c = course.Id,
                                                             SBQQ__ListPrice__c = 123,  SBQQ__SpecialPrice__c = 456, Net_Total_Tuition_Fee__c = 456, SBQQ__ProratedListPrice__c = 123, SBQQ__Quantity__c = 1, CreditPoints__c = 48                                             
                                                                                                              ), false);
        courseQL.SBQQ__RequiredBy__c = bundleQL.id;
        insert courseQL;
        
        if(SpecificationType == 'EnglishOfferSpecification')
        {
            Product2 adminFee = (Product2)TestDataFactory.createSObject(new Product2(Name='Admin Fee',Family='Admin Fee', External_Id__c='TEST_ADMIN_FEE'),true);
            TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = adminFee.id, unitprice=100),true);
            SBQQ__QuoteLine__c adminQL = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.id, SBQQ__Product__c = adminFee.Id, SBQQ__ListPrice__c = 100, SBQQ__NetPrice__c = 100, SBQQ__Quantity__c = 1, SBQQ__SpecialPrice__c = 100), false);
            adminQL.SBQQ__RequiredBy__c = bundleQL.id;
            insert adminQL;            
        } else if(SpecificationType == 'DiplomaOfferSpecification')
        {
            Product2 diplomaAddon = (Product2)TestDataFactory.createSObject(new Product2(Name='Sample Diplojma',Family='Course', External_Id__c='TEST_DIPLOMA_ADDON'),true);
            TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = diplomaAddon.id, unitprice=5000),true); // PBEDiploma
            SBQQ__QuoteLine__c diplomaQL = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.id, SBQQ__Product__c = diplomaAddon.Id,
                                             SBQQ__ListPrice__c = 123,  SBQQ__SpecialPrice__c = 456, Net_Total_Tuition_Fee__c = 456, SBQQ__ProratedListPrice__c = 123, SBQQ__Quantity__c = 1, CreditPoints__c = 48                                                                
                                                                                                                   ), false);
            diplomaQL.SBQQ__RequiredBy__c = courseQL.id;
            insert diplomaQL;
        }
          
        quote.SBQQ__Status__c = Constants.QUOTE_STATUS_IN_REVIEW;
        quote.Sub_Status__C =  Constants.QUOTE_PRICE_CALCULATED;
        update quote;
        quote.Sub_Status__c = 'Anything else';
        update quote;
        return quote.Id;
  
    }

    @isTest
    private static void getQuoteLineList(){        
        // GIVEN 
        // A valid quote
        List<SBQQ__Quote__c> quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 10];

        // WHEN 
        // The Quote lines are queried for
        Test.startTest();
            List<SBQQ__QuoteLine__c> qll = QuoteLineService.getQuoteLineList(quote.get(0).Id); 
            List<SBQQ__QuoteLine__c> qlb = QuoteLineService.getQuoteLineBundles(quote.get(0).Id);
        Test.stopTest();   

        // THEN
        // Quote lines are fetched
        Assert.isTrue(qll != null && qll.size() > 0, 'Quote Lines are not fetched properly');
        Assert.isTrue(qlb != null && qlb.size() > 0, 'Quote Lines are not fetched properly');
    }

    @isTest
    static void test_selectByIdHiddenPricing(){
        // GIVEN
        // A valid quote
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        // WHEN 
        // The Quote lines are queried for
        Test.startTest();
            List<SBQQ__QuoteLine__c> qll = QuoteLineService.selectByIdHiddenPricing(quote.Id);
        Test.stopTest();   

        // THEN
        // Quote lines are fetched
        Assert.isTrue(qll != null && qll.size() > 0, 'Quote Lines are not fetched properly');
    }

    @isTest 
    static void test_setQuoteLineExpiry(){
        // GIVEN
        // A valid quote
        Id quoteId = [SELECT SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Name = 'Monash Scholarship1' LIMIT 1][0].SBQQ__Quote__c;
        List<SBQQ__QuoteLine__c> quoteLines = new QuoteLinesSelector().selectByQuoteIdAndProductFamily(new Set<ID>{quoteId}, new String[]{'Scholarship'});

        // WHEN 
        // The Quote lines (10 days) are set with Expiry date of the associated Product (15 days)
        Test.startTest();
            QuoteLineService.setQuoteLineExpiry(new Set<ID>{quoteId},new String[]{'Scholarship'});
        Test.stopTest();   

        // THEN
        // Quote lines are populated with Expiry dates
        quoteLines = [SELECT ID, SBQQ__Quote__c, Expiry_Date__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Name = 'Monash Scholarship1' LIMIT 1];
        Date expiryDate = Date.today().addDays(15);
        Assert.isTrue(quoteLines != null && quoteLines[0].Expiry_Date__c == expiryDate, 'Quote Lines expiry date is not populated properly');
    }

    @isTest
    private static void testSyncQuoteAndOpptyLineItems() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__Account__r.Name='Test Accnt 2' LIMIT 1];
        // Opportunity has 0 Line Items
        List<OpportunityLineItem> lstOLI = new List<OpportunityLineItem> ();
        lstOLI = [SELECT id FROM OpportunityLineItem WHERE opportunityId = :quote.SBQQ__Opportunity2__c];

        // Quote has 1 Product, which is not a bundle or OSHC item
        Integer noOfQLI = [SELECT id 
                                FROM SBQQ__QuoteLine__c 
                                WHERE SBQQ__Quote__c = :quote.id 
                                    AND SBQQ__ProductFamily__c <> 'Bundle' 
                                    AND SBQQ__ProductCode__c <> 'BUNHEALTH']?.size();
        System.assertNotEquals(noOfQLI, lstOLI.size());
        Test.startTest();
            lstOLI = QuoteLineService.syncQuoteAndOpptyLineItems(null, quote.id);
        Test.stopTest();
        // Syncable 1 Line Item 
        System.assertEquals(noOfQLI, lstOLI.size(), 'Opportunity Products and QuoteLines are not synced');
    }
}