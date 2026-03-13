/**
* @author Jasmin Joy Rudio
* @description Apex test class for FormPageService class
* @group SF Offers
*
**/
@isTest
public with sharing class FormPageService_Test {

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

        Product2[] bundles = new Product2[0];
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.HealthCoverBundleDefaults', false));
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
        insert courses;
        
        TestDataFactory.createSObject(new Course_Duration__c(Pricebook__c = pb.Id), true);

        insert new Stg_Course_Fee__c[]{
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,false),
            (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Course_Status__c = 'ACTIVE'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false)
        };
        //Application Creation
        Application__c app = (Application__c)TestDataFactory.createSObject(new Application__c(Applicant__c = contact.Id), true);

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
                        Application__c = app.Id), false),
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                       Course__c = courses[2].Id, 
                        Course_Code__c = courses[2].Name,
                        Course_Version_Number__c = Double.valueOf(courses[2].Version__c),
                        Course_Code_Unique__c = courses[2].Course_Code__c,
                        Unit_Set__c = courses[3].Id, 
                        Unit_Set_Code__c = courses[3].Name, 
                        Unit_Set_Version__c = Double.valueOf(courses[3].Version__c),
                        Application__c = app.Id), false)
        };
        insert acps;

        MyApp_Settings__c myAppSettings = new MyApp_Settings__c();
        myAppSettings.Offer_Navigation_Version__c = 1;
        insert myAppSettings;
    }

    @isTest
    private static void getFormPage(){
        /*Form_Page__c page = (Form_Page__c)TestDataFactory.createSObject( new Form_Page__c(Name='Cover Letter', API_Name__c='coverletter',
                                                                        Display_Order__c=1), true);
        Form_Element__c element = (Form_Element__c)TestDataFactory.createSObject( new Form_Element__c(Name='Offer Details', API_Name__c='offerdetails',
                                                                        Sort_Order__c=1, Form_Page__c=page.Id), true);
        Form_Element__c childElement = (Form_Element__c)TestDataFactory.createSObject( new Form_Element__c(Name='Offer English Bundle', API_Name__c='English Course',
                                                                        Sort_Order__c=1, Form_Page__c=page.Id, Parent_Element__c = element.Id), true);                                                                        
        */
        FormElement__mdt element = [SELECT Id FROM FormElement__mdt WHERE API_Name__c = 'offer-details-1' LIMIT 1];
        Test.startTest();
            List<FormPageService.FormPage> pageList = FormPageService.getFormPage();
            List<FormPageService.FormPage> singlePage = FormPageService.getFormPageList('coverletter');
            List<FormPageService.FormElement> childFormElements = FormPageService.getChildFormElement(element.Id);
        Test.stopTest();
        
        System.assert(pageList.size() > 0);
        System.assert(singlePage.size() > 0);
        System.assert(childFormElements.size() > 0);
    }    

    @isTest
    private static void getBundleProducts(){
    
        Account account = [SELECT ID FROM Account LIMIT 1];
        Pricebook2 pb = [SELECT Id, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        Contact contact = [SELECT Id FROM Contact Limit 1];
        Application_Course_Preference__c[] acps = [SELECT ID FROM Application_Course_Preference__c ORDER BY Course__r.Name LIMIT 2];
        PriceBookEntry[] pbes = [SELECT Id, External_ID__c, Product2.Name FROM PriceBookEntry WHERE Pricebook2Id =: pb.id ORDER BY Product2.Course__r.Name];
        System.debug(pbes);
        List<Product2> bundles = [SELECT Id FROM Product2];
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
        SBQQ.TriggerControl.disable();
        //Creating a product for scholarship
        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(External_Id__c='12345',APXT_Redlining__Text__c='test course code match'), true);
        Product2 product1 = (Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashGrantScholarshipDefaults', false);
        product1.Clause__c = clause.Id;
        insert product1;
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=account.Id,SBQQ__PricebookId__c=pb.id,
                                                                SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress',
                                                                SBQQ__Opportunity2__c = opp.Id, SBQQ__ExpirationDate__c = opp.CloseDate),true);
        
        //QuoteLineItem Creation
        SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id,Application_Course_Preference__c = acps[0].Id, Expiry_Date__c = Date.today().addDays(15), SBQQ__Product__c = bundles[0].Id), false),
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id,Application_Course_Preference__c = acps[1].Id, Expiry_Date__c = Date.today().addDays(15), SBQQ__Product__c = bundles[1].Id), false),
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.id,SBQQ__Product__c=product1.Id, Expiry_Date__c = Date.today().addDays(15)), false)
        }; 
        insert qlis; 

        Test.startTest();
            /*Form_Page__c page = (Form_Page__c)TestDataFactory.createSObject( new Form_Page__c(Name='Cover Letter', API_Name__c='coverletter',
                                                                            Display_Order__c=1), true);
            Form_Element__c element = (Form_Element__c)TestDataFactory.createSObject( new Form_Element__c(Name='Offer Details', API_Name__c='offerdetails',
                                                                            Sort_Order__c=1, Form_Page__c=page.Id), true);
            Form_Element__c childElement = (Form_Element__c)TestDataFactory.createSObject( new Form_Element__c(Name='Offer English Bundle', API_Name__c='English Course',
                                                                        Sort_Order__c=1, Form_Page__c=page.Id, Parent_Element__c = element.Id), true);                                                                        
            */
            Contact con = [SELECT Id FROM Contact LIMIT 1];
            
            FormElement__mdt element = [SELECT Id FROM FormElement__mdt WHERE API_Name__c = 'offer-details-1' LIMIT 1];
            SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, SBQQ__PrimaryContact__c FROM SBQQ__Quote__c WHERE Id = :quote1.Id LIMIT 1];
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Name, SBQQ__ProductFamily__c, SBQQ__Product__c, SBQQ__Quote__c
                                                FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote1.Id];
            List<Contact> primaryContact = FormPageService.getPrimaryContact(con.Id);
            String productBundle = FormPageService.getBundlePageMap(element.Id, quote.Id);
            String productSummary = FormPageService.getProductByIdHiddenPricing(element.Id, quote.Id);
        Test.stopTest();
        System.assert(primaryContact != null);
        System.assert(productBundle != null);
    }

    @isTest
    private static void shouldSucceedWhenOptionStringInput()
    {
        FormPageService.Option opt = new FormPageService.Option('good', 'value');
        system.assert(true);
    }
    @isTest
    private static void shouldIllegalArgumentExceptionWhenOptionNullInput()
    {
        try {
            FormPageService.Option opt = new FormPageService.Option(null, 'value');

        } catch(IllegalArgumentException ex)
        {
            system.assert(true);
            return;
        }
        system.assert(false);
 
    }
    @isTest
    private static void shouldSucceedWhenPriceOptionStringInput()
    {
        FormPageService.PriceOption prOPt = new FormPageService.PriceOption('good', 'value', 1.45, 'description');
        system.assert(true);
    }
    @isTest
    private static void shouldIllegalArgumentExceptionWhenPriceOptionNullInput()
    {
        try {
            FormPageService.PriceOption prOpt = new FormPageService.PriceOption(null, 'value', null, 'description');

        } catch(IllegalArgumentException ex)
        {
            system.assert(true);
            return;
        }
        system.assert(false);

    }
    
}