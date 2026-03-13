@isTest
public class StgCourseFeeHandler_Test {
	@testSetup static void setup() {
        //insert OrgUnitBundleMapping__c
        Test.loadData(OrgUnitBundleMapping__c.sObjectType, 'OrgUnitBundleMappingDataTest');
        //update std price book
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;
        
         //add COURSE duration
         Course_Duration__c[] coduration = new Course_Duration__c[0];
         coduration.add((Course_Duration__c)TestDataFactory.createSObject(new Course_Duration__c(), 'TestDataFactorySettings.CourseDurationDefaultsForBUNMEC', false));
           insert coduration;
        //add product bundles
        Product2[] bundles = new Product2[0];
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaultsBUNMEC', false));
        insert bundles;

        //create international pricebook "AU_INT"
        Pricebook2 pricebook = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(), true);
        Course__c[] courses = new Course__c[0];
        //course marketing
       	courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), false));
        //unit set marketing 
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.UnitSetDefaults', false));
        //course - monash english
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.MonashEnglishCourseDefaults', false));
        
        //course - monash english with BUNMEC product bundle
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.BUNMECMonashEnglishCourseDefaults', false));
    
        //unit set - monash english
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.MonashEnglishUnitSetDefaults', false));
        insert courses;
        
        TestDataFactory.createSObject(new Course_Duration__c(Pricebook__c = pricebook.Id), true);
        
    }

    
    @isTest static void test_monashEnglishFee_success(){
        Test.startTest();
        Stg_Course_Fee__c fee = (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,true);
        fee = [SELECT Id, Course_Deposit_Amount__c, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c WHERE Id = :fee.Id];
        System.assert(fee.Sync_Status__c == 'SYNC');
        
        fee.Course_Status__c = 'ACTIVE';
        fee.Sync_Status__c = 'NOT SYNC';
        update fee;

        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Pricebook2.isStandard = false LIMIT 1];
        System.assert(pbe != null && pbe.UnitPrice > 0 , 'Pricebook Entry is created successully.');
        Test.stopTest();

    }

    @isTest static void test_monashEnglishBUNMECBundleFee_success(){
        Test.startTest();
        Stg_Course_Fee__c fee = (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(),'TestDataFactorySettings.BUNMECMonashEnglishStgCourseFeeDefaults' ,true);
        fee = [SELECT Id, Course_Deposit_Amount__c, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c WHERE Id = :fee.Id];
        System.assert(fee.Sync_Status__c == 'SYNC');
        
        fee.Course_Status__c = 'ACTIVE';
        fee.Sync_Status__c = 'NOT SYNC';
        update fee;

        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Pricebook2.isStandard = false LIMIT 1];
        System.assert(pbe != null && pbe.UnitPrice > 0 , 'Pricebook Entry is created successully.');
        Test.stopTest();

    }
    @isTest static void test_monashEnglishFee_error_noduration(){
        Test.startTest();
        Course_Duration__c durationOverride = new Course_Duration__c(External_ID__c = '3626-MEB-AP-10');
        TestDataFactory.createSObject(durationOverride, false);
        durationOverride.Duration__c = null;
        insert durationOverride;
        
        Stg_Course_Fee__c fee = (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,true);
        fee = [SELECT Id, Course_Deposit_Amount__c, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c WHERE Id = :fee.Id];
        System.assert(fee.Sync_Status__c == 'ERROR', 'Duration override should not have a nil value');
    }
    @isTest static void test_marketingFeewithunitset_success(){
        Test.startTest();
        Stg_Course_Fee__c fee = (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,true);
        fee = [SELECT Id, Course_Deposit_Amount__c, Base_Total_Course_Fee__c,Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c WHERE Id = :fee.Id];
        System.assert(fee.Sync_Status__c == 'SYNC');
        
        fee.Course_Status__c = 'ACTIVE';
        fee.Sync_Status__c = 'NOT SYNC';
        update fee;

        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Pricebook2.isStandard = false LIMIT 1];
        System.assert(pbe != null && pbe.UnitPrice == fee.Base_Total_Course_Fee__c, 'Pricebook Entry is created successully and unit price should be set with Course Deposit Amount.');
        Test.stopTest();
    }
    @isTest static void test_marketingFee_success(){
        Test.startTest();
        Stg_Course_Fee__c fee = (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Unit_Set_Code__c = null,Currency__c='AUD',Unit_Set_Version__c = null),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,true);
        fee = [SELECT Id, Course_Deposit_Amount__c, Base_Total_Course_Fee__c,Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c WHERE Id = :fee.Id];
        System.assert(fee.Sync_Status__c == 'SYNC');
        fee.Course_Status__c = 'ACTIVE';
        fee.Sync_Status__c = 'NOT SYNC';
        update fee;

        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Pricebook2.isStandard = false LIMIT 1];

        System.assert(pbe != null && pbe.UnitPrice == fee.Base_Total_Course_Fee__c, 'Pricebook Entry is created successully and unit price should be set with Course Deposit Amount.');
        Test.stopTest();
    }
    @isTest static void test_error_noorgunit(){
        Test.startTest();
        Stg_Course_Fee__c fee = (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Responsible_Org_Unit_Code__c = null),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,true);
        fee = [SELECT Id, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c WHERE Id = :fee.Id];
        System.assert(fee.Sync_Status__c == 'ERROR');
        Test.stopTest();
    }
    @isTest static void test_invalidorgunit(){
        Test.startTest();
        Stg_Course_Fee__c fee = (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Responsible_Org_Unit_Code__c = 'HELLO',Currency__c='AUD'),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,true);
        fee = [SELECT Id, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c WHERE Id = :fee.Id];
        System.assert(fee.Sync_Status__c == 'ERROR');
        Test.stopTest();
    }
    @isTest static void test_error_nofeecategory(){
        Test.startTest();
        
        Stg_Course_Fee__c[] fees = new Stg_Course_Fee__c[0];
        fees.add((Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Fee_Category__c = 'HELLO1',Currency__c='AUD', Course_Version__c = '1', External_ID__c = 'TEST1'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false));
        fees.add((Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Fee_Category__c = 'HELLO3', Currency__c='AUD',Course_Version__c = '3', External_ID__c = 'TEST3'),'TestDataFactorySettings.MonashEnglishStgCourseFeeDefaults' ,false));
        insert fees;
        fees = [SELECT Id, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c LIMIT 4];

        System.assert(fees[0].Sync_Status__c == 'ERROR');
        System.assert(fees[1].Sync_Status__c == 'ERROR');
        Test.stopTest();
    }

    @isTest static void test_error_nocoursecode(){
        Test.startTest();
        
        Stg_Course_Fee__c[] fees = new Stg_Course_Fee__c[0];
        fees.add((Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Currency__c='AUD',Course_Code__c = 'HELLO2', Course_Version__c = '2', External_ID__c = 'TEST2'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false));
        fees.add((Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Currency__c='AUD',Course_Code__c = 'HELLO4', Course_Version__c = '4', External_ID__c = 'TEST4'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false));
        fees.add((Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Currency__c='AUD',Course_Code__c = 'HELLO5', Course_Version__c = '5', External_ID__c = 'TEST5'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false));
        insert fees;
        fees = [SELECT Id, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c LIMIT 4];

        System.assert(fees[0].Sync_Status__c == 'ERROR');
        System.assert(fees[0].Sync_Message__c.contains('Foreign key external ID'));
        System.assert(fees[1].Sync_Status__c == 'ERROR');
        System.assert(fees[1].Sync_Message__c.contains('Foreign key external ID'));
        System.assert(fees[2].Sync_Status__c == 'ERROR');
        System.assert(fees[2].Sync_Message__c.contains('Foreign key external ID'));
        Test.stopTest();
    }
    
    /**
     * @author Shalini Mendu
     * @date 02/11/2021
     * @description Tests to ensure Stg course fee for INDO offers is successful
     */
    @isTest static void test_MIfeecategory(){
        Pricebook2 pricebook2 = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(), 'TestDataFactorySettings.IndonesiaPricebook2Defaults', true);
        Test.startTest();
       
        Stg_Course_Fee__c[] fees = new Stg_Course_Fee__c[0];
        fees.add((Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Fee_Category__c = 'MI_DOM', Currency__c ='IDR',Course_Version__c = '1', External_ID__c = 'TEST1'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false));
        insert fees;
        fees = [SELECT Id, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c LIMIT 4];
        System.assert(fees[0].Sync_Status__c == 'SYNC');
        Test.stopTest();
    }

   /**
     * @author Shalini Mendu
     * @date 14/04/2022
     * @description Tests to ensure Stg course fee for Avenu offers is successful
     */
    @isTest static void test_Avenufeecategory(){
        Pricebook2 pricebook2 = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(), 'TestDataFactorySettings.AvenuPricebook2Defaults', true);
        Test.startTest();
       
        Stg_Course_Fee__c[] fees = new Stg_Course_Fee__c[0];
        fees.add((Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Fee_Category__c = 'OS_MO', Currency__c ='INR',Course_Version__c = '1', External_ID__c = 'TEST1'),'TestDataFactorySettings.MarketingStgCourseFeeDefaults' ,false));
        insert fees;
        fees = [SELECT Id, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c LIMIT 4];
        System.assert(fees[0].Sync_Status__c == 'SYNC');
        Test.stopTest();
    }
}