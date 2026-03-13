@isTest
public with sharing class QuoteGenerator_Test {

    @testSetup static void setup() {
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
     
        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12345',APXT_Redlining__Text__c='test course code match'), true);
        
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
    }
    /**
    * @author Mathew Jose
    * @date 25/10/2019
    * @group SF Offer
    * @description Test method to test generation of a CPQ quote from opportunity using the CPQ API
    **/
    @isTest
    private static void generateQuote(){
        Test.startTest();
        Account account = [SELECT ID FROM Account LIMIT 1];
        Pricebook2 pb = [SELECT Id, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        Application_Course_Preference__c[] acps = [SELECT ID FROM Application_Course_Preference__c ORDER BY Course__r.Name LIMIT 2];
        PriceBookEntry[] pbes = [SELECT Id, External_ID__c, Product2.Name FROM PriceBookEntry WHERE Pricebook2Id =: pb.id ORDER BY Product2.Course__r.Name];
        System.debug(pbes);
        //Opportunity Creation,
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id,Pricebook2Id=pb.id),true);
                
        //OpportunityLineItem Creation
        OpportunityLineItem[] olis = new OpportunityLineItem[]{
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[0].id, Application_Course_Preference__c = acps[0].Id), false),
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[1].id,Application_Course_Preference__c = acps[1].Id), false)
        };
        insert olis;
        opp.StageName = 'Processing Offer';
        opp.NextStep = 'Generate Offer';
        update opp;  
        Test.getEventBus().deliver();
        
        
        Test.stopTest();
    }

    /**
    * @author Vinothraja
    * @date 12/05/2021
    * @description SFTG-1963 Test method to test bypassing of OSHC Quotelineitems for Online Courses
    **/
    @isTest
    private static void generateQuoteWithoutOSHC() {
        Test.startTest();
        Account account = [SELECT ID FROM Account LIMIT 1];
        Pricebook2 pb = [SELECT Id, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        Application__c app = [SELECT id, Campus_Location__c from Application__c LIMIT 1];
        app.Campus_Location__c = Constants.MONASH_ABROAD_CAMPUS_LOCATION_ONLINE;
        update app;
        Application_Course_Preference__c[] acps = [SELECT ID FROM Application_Course_Preference__c ORDER BY Course__r.Name LIMIT 2];
        PriceBookEntry[] pbes = [SELECT Id, External_ID__c, Product2.Name FROM PriceBookEntry WHERE Pricebook2Id =: pb.id ORDER BY Product2.Course__r.Name];
        System.debug(pbes);
        //Opportunity Creation,
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id,Pricebook2Id=pb.id),true);

        //OpportunityLineItem Creation
        OpportunityLineItem[] olis = new OpportunityLineItem[] {
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[0].id, Application_Course_Preference__c = acps[0].Id), false),
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[1].id, Application_Course_Preference__c = acps[1].Id), false)
        };
        insert olis;
        opp.StageName = 'Processing Offer';
        opp.NextStep = 'Generate Offer';
        update opp;
        Test.getEventBus().deliver();
        new QuoteGenerator(opp).execute();       
        Test.stopTest();
        System.assertEquals(0, [SELECT count(id)
                            FROM sbqq__quoteline__c
                            WHERE sbqq__quote__c
                            IN (SELECT sbqq__primaryquote__c FROM opportunity WHERE id = :opp.id)
                            AND SBQQ__ProductFamily__c = 'OSHC'][0].get('expr0') );

      
    }

    /**
    * @author Kristian Vegerano
    * @date 07/07/2021
    * @description Test method to test generation of a domestic CPQ quote from opportunity using the CPQ API
    **/
    @isTest
    private static void generateDomesticQuote(){
        Test.startTest();

        // setup application to domestic
        Application__c app = [SELECT id, Campus_Location__c from Application__c LIMIT 1];
        app.Campus_Location__c = Constants.CAMPUS_LOCATION_AUS;
        app.Residency_Status__c = Constants.RESIDENCY_STATUS_LOCATION_AUS_DOM;
        update app;

       

        Account account = [SELECT ID FROM Account LIMIT 1];
        Pricebook2 pb = [SELECT Id, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        Application_Course_Preference__c[] acps = [SELECT ID, Application__c FROM Application_Course_Preference__c ORDER BY Course__r.Name LIMIT 2];
        PriceBookEntry[] pbes = [SELECT Id, External_ID__c, Product2.Name FROM PriceBookEntry WHERE Pricebook2Id =: pb.id ORDER BY Product2.Course__r.Name];
        //Opportunity Creation,
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id,Pricebook2Id=pb.id),true);
                
        //OpportunityLineItem Creation
        OpportunityLineItem[] olis = new OpportunityLineItem[]{
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[0].id, Application_Course_Preference__c = acps[0].Id), false),
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[1].id, Application_Course_Preference__c = acps[1].Id), false)
        };
        insert olis;
        opp.StageName = 'Processing Offer';
        opp.NextStep = 'Generate Offer';
        update opp;  
        Test.getEventBus().deliver();
        
        Test.stopTest();
        System.assertEquals('AUD',[Select currencyIsoCode from Opportunity where AccountId =:account.Id][0].currencyIsoCode);
    }

    /**
     * @author Kristian Vegerano
     * @date 14/04/2022
     * @description Tests that avenu offers does not include OSHC line items on the generated quote
     */
    @isTest
    private static void generateAvenuQuoteWithoutOSHC() {
        // given an application for course offering with location for ONLINE-A
        Account account = [SELECT ID FROM Account LIMIT 1];
        Pricebook2 pb = [SELECT Id, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        Application__c app = [SELECT id, Campus_Location__c from Application__c LIMIT 1];
        Application_Course_Preference__c[] acps = [SELECT ID FROM Application_Course_Preference__c ORDER BY Course__r.Name LIMIT 2];
        PriceBookEntry[] pbes = [SELECT Id, External_ID__c, Product2.Name FROM PriceBookEntry WHERE Pricebook2Id =: pb.id ORDER BY Product2.Course__r.Name];

        List<Course_Offering__c> l_courseOfferings = new List<Course_Offering__c>();
        for(Course_Offering__c item_courseOffering : [SELECT Id FROM Course_Offering__c]){
            item_courseOffering.Location_Code__c = Constants.LOCATION_ONLINE_A;
            l_courseOfferings.add(item_courseOffering);
        }
        if(!l_courseOfferings.isEmpty()){
            update l_courseOfferings;
        }

        // when offer / opportunity generation
        Test.startTest();
        // opportunity Creation
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id,Pricebook2Id=pb.id),true);

        // opportunity line item creation
        OpportunityLineItem[] olis = new OpportunityLineItem[] {
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[0].id, Application_Course_Preference__c = acps[0].Id), false),
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId=opp.id,PricebookEntryId= pbes[1].id, Application_Course_Preference__c = acps[1].Id), false)
        };
        insert olis;
        opp.StageName = 'Processing Offer';
        opp.NextStep = 'Generate Offer';
        update opp;
        Test.getEventBus().deliver();
        new QuoteGenerator(opp).execute();       
        Test.stopTest();

        // then there should be no OSHC line items against the opportunity
        System.assertEquals(0, [SELECT count(id)
                            FROM sbqq__quoteline__c
                            WHERE sbqq__quote__c
                            IN (SELECT sbqq__primaryquote__c FROM opportunity WHERE id = :opp.id)
                            AND SBQQ__ProductFamily__c = 'OSHC'][0].get('expr0') );      
    }
}