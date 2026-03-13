/**
 * @description TotalContractValueCorrector_Test
 * @author Shalini Mendu
 * @date 12/05/2022
 **/
@isTest
public with sharing class TotalContractValueCorrector_Test {
    @testSetup 
       static void setup() {
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
        //Test Total contract value correct batch
        @isTest
        static void testTotalContractValueCorrectBatch()
        {
            Account account = [SELECT ID FROM Account LIMIT 1];
            Pricebook2 pb = [SELECT Id, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
            Application__c app = [SELECT id, Campus_Location__c from Application__c LIMIT 1];
            app.Campus_Location__c = Constants.MONASH_ABROAD_CAMPUS_LOCATION_ONLINE;
            update app;
            Application_Course_Preference__c[] acps = [SELECT ID FROM Application_Course_Preference__c ORDER BY Course__r.Name LIMIT 2];
            PriceBookEntry[] pbes = [SELECT Id, External_ID__c, Product2.Name FROM PriceBookEntry WHERE Pricebook2Id =: pb.id ORDER BY Product2.Course__r.Name];
            System.debug(pbes);
            //Opportunity Creation,
    
            Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=account.Id, Pricebook2Id=pb.id),true);

            SBQQ__Quote__c q = new SBQQ__Quote__c(
                    SBQQ__PricebookId__c = Test.getStandardPricebookId(),
                    SBQQ__EndDate__c = Date.today().addMonths(2),
                    SBQQ__StartDate__c = Date.today().addMonths(1),
                    SBQQ__Type__c = 'Quote',
                    Expiry_Status__c = 'Active Offer',
                    Product_Status__c = 'Active Products',
                    SBQQ__Status__c = 'In Review',
                    Sub_Status__c = 'In Progress',
                    Category__c = 'ISCA Deposit',
                    Product_Search_Filter__c = 'Offer',
                    SBQQ__Opportunity2__c = opp.Id
                );
                SBQQ.TriggerControl.disable();
                insert q;
                SBQQ.TriggerControl.enable();
    
            Test.startTest();

            Database.executeBatch(new TotalContractValueCorrector('Quote', 'Re-Quote', null), 5);
            Test.stopTest();
            System.assertEquals('Re-Quote', [select SBQQ__Type__c,SBQQ__Uncalculated__c from SBQQ__Quote__c where Category__c = 'ISCA Deposit'].SBQQ__Type__c);
        }
    
  
}