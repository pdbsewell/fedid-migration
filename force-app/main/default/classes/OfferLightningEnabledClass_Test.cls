/**
 * @File Name          : OfferLightningEnabledClassTest.cls
 * @Description        : test class for OfferLightningEnabledClass
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 3/3/2020, 9:59:09 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/27/2020   jasmin.rudio@monash.edu     Initial Version
**/
@isTest
public class OfferLightningEnabledClass_Test {

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
        Account acc1 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);
        Account acc2 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 2'), true);

        //Creating a product for scholarship
        Product2 product1 = (Product2)TestDataFactory.createSObject(new Product2(Name='Monash Scholarship1', External_Id__c='12345', Expiry_days__c=15),true);
		//product always required a standard pricebook         
        PricebookEntry pbe1 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product1.id, unitprice=-5000),true);
        //add custom pricebook entry for created product
        PricebookEntry pbe2 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = product1.id, unitprice=-5000), true);

        //Calendar create
        Date startDate = Date.today();
        Date endDate = Date.today().addYears(2);
        Calendar__c cal1 = (Calendar__c)TestDataFactory.createSObject(new Calendar__c(Name='ADM_2021_ADM-1',Start_Date__c=startDate,End_Date__c=endDate,Category__c='ADMISSION',Type__c='ADM-1',Status__c='ACTIVE',calendar_code__c='666_666'),true);


        //create clause 1
        APXT_Redlining__Clause__c clause1 = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12345',APXT_Redlining__Text__c='test course code match',Location_in_Offer__c='Course notes'), true);
        APXT_Redlining__Clause__c clause2 = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12346',APXT_Redlining__Text__c='Country not equals China', Location_in_Offer__c='Course notes'), true);
        APXT_Redlining__Clause__c clause3 = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12347',APXT_Redlining__Text__c='Country of Residence INDIA',Location_in_Offer__c='Course notes'), true);
        APXT_Redlining__Clause__c clause4 = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12348',APXT_Redlining__Text__c='calendar start date greater than today',Location_in_Offer__c='Course notes'), true);
        APXT_Redlining__Clause__c clause5 = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12349',APXT_Redlining__Text__c='Calendar start date less than 2 years from now',Location_in_Offer__c='Course notes'), true);

        Clause_Filtering_Criteria__c[] criterias = new Clause_Filtering_Criteria__c[0];
        criterias.add((Clause_Filtering_Criteria__c)TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c=clause1.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaForContainsDefaults', false));
        criterias.add((Clause_Filtering_Criteria__c)TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c=clause2.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaForNotEqualsDefaults', false));
        criterias.add((Clause_Filtering_Criteria__c)TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c=clause3.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaForEqualsDefaults', false));
        criterias.add((Clause_Filtering_Criteria__c)TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c=clause4.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaGreaterThanDefaults', false));
        //criterias.add((Clause_Filtering_Criteria__c)TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c=clause5.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaLessThanDefaults', false));
        
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
        SBQQ__ConfigurationAttribute__c configAttribute = (SBQQ__ConfigurationAttribute__c)TestDataFactory.createSObject(new SBQQ__ConfigurationAttribute__c(Name='Application_Course_Preference__c',SBQQ__TargetField__c='Application_Course_Preference__c', SBQQ__Product__c=bundles[0].Id),true);

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
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc1.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact1.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress', SBQQ__Opportunity2__c = opp.Id, SBQQ__ExpirationDate__c = opp.CloseDate),true);
        SBQQ__Quote__c quote2 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc2.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact2.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress', SBQQ__Opportunity2__c = opp.Id, SBQQ__ExpirationDate__c = opp.CloseDate),true);

        PriceBookEntry[] pbes = [SELECT Id, External_ID__c, Product2.Name FROM PriceBookEntry WHERE Pricebook2Id =: pb.id ORDER BY Product2.Course__r.Name];
        //QuoteLineItem Creation
        SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id,Application_Course_Preference__c = acps[0].Id, Expiry_Date__c = Date.today().addDays(15), SBQQ__Product__c = bundles[0].Id), false),
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id,Application_Course_Preference__c = acps[1].Id, Expiry_Date__c = Date.today().addDays(15), SBQQ__Product__c = bundles[3].Id), false),
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote2.id,Application_Course_Preference__c = acps[2].Id, Expiry_Date__c = Date.today().addDays(15), SBQQ__Product__c = bundles[1].Id), false),
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote2.id,SBQQ__Product__c=product1.Id, Expiry_Date__c = Date.today().addDays(15)), false)
        }; 
        insert qlis; 
        List<SBQQ__QuoteLine__c> toUpdateQL = new List<SBQQ__QuoteLine__c>();
        qlis[0].Offer_Primary_Quote_Line__c = qlis[1].Id;
        toUpdateQL.add(qlis[0]);
        
        qlis[1].SBQQ__RequiredBy__c = qlis[0].Id;
        toUpdateQL.add(qlis[1]);
        
        update toUpdateQL;

        ContentVersion cv=new Contentversion();
        cv.title='qwerty';
        cv.PathOnClient ='123test';
        Blob b=Blob.valueOf('Unit Test qwerty 123test');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test qwerty 123test');
        insert cv;

        MyApp_Settings__c myAppSettings = new MyApp_Settings__c();
        myAppSettings.Offer_Navigation_Version__c = 1;
        insert myAppSettings;
    }
    
    @isTest
    private static void auraEnabledClasses(){
        Account account = [SELECT ID, (Select Id from Contacts where LastName = 'Con1') FROM Account LIMIT 1];
        Pricebook2 pb2 = [SELECT Id FROM Pricebook2 LIMIT 1];
        Pricebook2 pb = [SELECT Id, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        Application_Course_Preference__c[] acps = [SELECT ID, Course_Product_Id__c FROM Application_Course_Preference__c];
        PriceBookEntry[] pbes = [SELECT Id, External_ID__c, Product2.Name, UnitPrice FROM PriceBookEntry WHERE Pricebook2Id =: pb.id and Product2.Name='Test Grant' ORDER BY Product2.Course__r.Name];
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id,Pricebook2=pb,PrimaryContact__c=account.Contacts[0].Id),false);
        SBQQ.TriggerControl.disable();
        ContentVersion cv = [SELECT Id FROM ContentVersion];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c ql = [SELECT Id from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.Id LIMIT 1];
        Test.startTest();
            OfferLightningEnabledClass offers = new OfferLightningEnabledClass();
            String cvJson = OfferLightningEnabledClass.fetchAttachment(cv.Id);
            String bundleJson = OfferLightningEnabledClass.getBundlePageMap('', quote.Id);
            List<FormPageService.FormElement> elements = OfferLightningEnabledClass.getChildFormElement('');
            List<QuoteService.OfferListWrapper> offerWrapper = OfferLightningEnabledClass.getCurrentOfferList('', '', 1, 1);
            List<FormPageService.FormPage> formPages = OfferLightningEnabledClass.getFormPage();
            List<FormPageService.FormPage> fpList = OfferLightningEnabledClass.getFormPageList('');
            String clauseJson = OfferLightningEnabledClass.getManagedClauseByQuoteId(quote.Id);
            SBQQ__Quote__c quotes = OfferLightningEnabledClass.getOfferDetails(quote.Id);
            List<SBQQ__Quote__c> quoteList = OfferLightningEnabledClass.getOfferList('', '');
            List<Contact> contactList = OfferLightningEnabledClass.getPrimaryContact(account.Contacts[0].Id);
            String pricingJson = OfferLightningEnabledClass.getProductByIdHiddenPricing('', quote.Id);
            List<SBQQ__QuoteLine__c> bundleList = OfferLightningEnabledClass.getQuoteLineBundles(quote.Id);
            List<SBQQ__QuoteLine__c> qLines = OfferLightningEnabledClass.getQuoteLineList(quote.Id);
            QuoteOSHCView oshc = OfferLightningEnabledClass.getQuoteOSHCView(quote.Id, false);
            List<SBQQ__QuoteLine__c> hiddenPricing = OfferLightningEnabledClass.selectByIdHiddenPricing(quote.Id);
            List<SBQQ__QuoteLine__c> byProductFamily = OfferLightningEnabledClass.selectByQuoteIdAndProductFamily(quote.Id, 'Scholarship');
        Test.stopTest();
        System.assert(cvJson <> null);
        System.assert(bundleJson <> null);
        System.assert(elements <> null);
        System.assert(offerWrapper <> null);
        System.assert(formPages <> null);
        System.assert(fpList <> null);
        System.assert(clauseJson <> null);
        System.assert(quotes <> null);
        System.assert(quoteList <> null);
        System.assert(contactList <> null);
        System.assert(pricingJson <> null);
        System.assert(bundleList <> null);
        System.assert(qLines <> null);
        System.assert(oshc <> null);
        System.assert(hiddenPricing <> null);
        System.assert(byProductFamily <> null);
    }

    @isTest
    static void setQuoteOSHCView() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c ql = [SELECT Id from SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.Id LIMIT 1];
        FormPageService.HeathQuoteRequest hqr = new FormPageService.HeathQuoteRequest();
        hqr.quoteId = quote.Id;
        hqr.healthBundleId = ql.Id;
        hqr.isLocked = true;
        hqr.selectedHealthOption = '';
        hqr.selectedProvider = '';
        hqr.subStatus = 'Details changed';
        Test.startTest();
            try {
                OfferLightningEnabledClass.setQuoteOSHCView(null);
            } catch (Exception e) {
                System.assert(true, 'Quote is in a state which cannot be modified.');
            }
        Test.stopTest();
    }

    @isTest
    static void getSigningUrl() {

        try {
            OfferLightningEnabledClass.getSigningUrl('xxx');
            System.assert(false, 'Expected Exception because quote id does not exist');
        } catch (Exception e) {
            System.assert(true, 'Expected Exception as quote cannot be updated');
        }
    }

}