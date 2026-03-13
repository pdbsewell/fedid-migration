@isTest
public class CourseFeeTriggerHandler_Test {
    @testSetup static void setup() {
        //Course Creation
       	Course__c course = (Course__c)TestDataFactory.createSObject(new Course__c(), true);
        // Instantiate the Pricebook2 record first, setting the Id
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;
        Pricebook2 pricebook = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(), true);
        //add product bundles
        Product2[] bundles = new Product2[0];
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false));
        insert bundles;
    }
    @isTest static void test_createCourseFee_success(){
        Pricebook2 pb = [SELECT ID FROM Pricebook2 WHERE External_ID__c = 'AU_INT'];
        Course__c course = [SELECT ID, Name, Course_Code__c, Version__c FROM Course__c WHERE Name = 'MARK1234' LIMIT 1];
        Test.startTest();
        Course_Fee__c fee = (Course_Fee__c)TestDataFactory.createSObject(new Course_Fee__c(Course__c = course.Id, pricebook__c = pb.Id), true);
        Product2[] products = [SELECT Id, External_ID__c FROM Product2 WHERE Course__c = :course.Id];
        System.assert(products != null && products.isEmpty() == false,'Course Fee creation generate a product successfully.');
        System.assert(products[0].External_ID__c == course.Name + '_' + course.Name, 'Product External ID is a combination of course code and unit set separated by underscore.');
        fee.Course_Deposit_Amount__c = 100;
        update fee;
        Test.stopTest();
    }
    @isTest static void test_createCourseFeeWithoutUnitSet_success(){
        Pricebook2 pb = [SELECT ID FROM Pricebook2 WHERE External_ID__c = 'AU_INT'];
        Course__c course = [SELECT ID, Name, Course_Code__c, Version__c FROM Course__c WHERE Name = 'MARK1234' LIMIT 1];
        Test.startTest();
        Course_Fee__c fee = (Course_Fee__c)TestDataFactory.createSObject(new Course_Fee__c(Course__c = course.Id, Pricebook__c = pb.Id), false);
        fee.Unit_Set_Code__c = null;
        insert fee;
        Product2[] products = [SELECT Id, External_ID__c FROM Product2 WHERE Course__c = :course.Id];
        System.assert(products != null && products.isEmpty() == false,'Course Fee creation generate a product successfully.');
        System.assert(products[0].External_ID__c == course.Name, 'Product External ID is a only course code as there is no unit set.');
        Test.stopTest();
    }
    @isTest static void test_createCourseFee_error_nofeecatgory(){
        Course__c course = [SELECT ID FROM Course__c WHERE Name =  'MARK1234' LIMIT 1];
        Test.startTest();
        try{
            Course_Fee__c fee = (Course_Fee__c)TestDataFactory.createSObject(new Course_Fee__c(Course__c = course.Id, Fee_Category__c = 'hjsger'), true);            
            System.assert(false,'Generation of product from course fee should have failed as fee catgory doesn\'t have a matching mapping');
        }catch(Exception e){
            System.assert(true,'Generation of product from course fee failed as fee catgory doesn\'t have a matching mapping');
        }
        Test.stopTest();
    }  
    
    @isTest static void test_createCourseFee_error_dml(){
        Pricebook2 pb = [SELECT ID FROM Pricebook2 WHERE External_ID__c = 'AU_INT'];
        Course__c course = [SELECT ID, Name, Course_Code__c, Version__c FROM Course__c WHERE Name = 'MARK1234' LIMIT 1];
        Course_Fee__c fee = (Course_Fee__c)TestDataFactory.createSObject(new Course_Fee__c(Course__c = course.Id,   CurrencyIsoCode = 'AUD', Pricebook__c = pb.Id), false);
        Test.startTest();

        CourseFeeTriggerHandler.ProductSync handler = new CourseFeeTriggerHandler.ProductSync();
        handler.process(fee);
        String key = fee.Course_Code__c + (fee.Unit_Set_Code__c != null ? ('_' + fee.Unit_Set_Code__c) : '');
        handler.errorsByCourseFee.put(key,'This is error 1');
        handler.errorsByCourseFee.put(key+'_'+fee.Fee_Category__c,'This is error 2');
        //fake error on product
        Product2 fakeProduct = new Product2(External_ID__c = key, CurrencyIsoCode = 'AUD');
        Database.UpsertResult[] results = Database.upsert(new Product2[]{fakeProduct}, Product2.External_ID__c, false);
        handler.handleErrors(results[0].getErrors(), fakeProduct, 'Product2', 'Course Fee Tests');
        //execute all
        handler.execute();
        System.assert(fee.Sync_Message__c != Constants.COURSEFEE_SYNCCOMPLETED,'something went wrong in the insert');
        Test.stopTest();
    }
    @isTest static void test_createProductOption(){
        SBQQ__ProductOption__c option = CourseFeeTriggerHandler.createProductOption('hello:world');
        System.assert(option.SBQQ__ConfiguredSKU__r.External_Id__c == 'hello', 'Config product');
        System.assert(option.SBQQ__OptionalSKU__r.External_Id__c == 'world', 'Option product');
    }
    @isTest static void test_ProductOption_error(){
        Pricebook2 pb = [SELECT ID FROM Pricebook2 WHERE External_ID__c = 'AU_INT'];
        Course__c course = [SELECT ID, Name, Course_Code__c, Version__c FROM Course__c WHERE Name = 'MARK1234' LIMIT 1];
        Test.startTest();
        try{
            Course_Fee__c fee = (Course_Fee__c)TestDataFactory.createSObject(new Course_Fee__c(Course__c = course.Id, pricebook__c = pb.Id,Product_Options__c = 'hello_world:foo_bar'), true);
            insert fee;
            System.assert(false, 'Should have thrown an exception ');
        }catch(Exception e){
            System.assert(true, 'hello_world:foo_bar is not a valid product option');
        }
        Test.stopTest();
    }
     /**
     * @author Shalini Mendu
     * @date 02/11/2021
     * @description Tests that the standard/custom pricebook entries are correctly created on coursefee processing
     */
    @isTest static void test_createCourseMIFeeCategory(){
        Pricebook2 pricebook2 = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(), 'TestDataFactorySettings.IndonesiaPricebook2Defaults', true);
        TestDataFactory.createSObject(new Course_Duration__c(Pricebook__c = pricebook2.Id), true);
      
        Pricebook2 pb = [SELECT ID FROM Pricebook2 WHERE External_ID__c = 'MI_DOM'];
        Course__c course = [SELECT ID, Name, Course_Code__c, Version__c FROM Course__c WHERE Name = 'MARK1234' LIMIT 1];
      
        Course_Fee__c fee = (Course_Fee__c)TestDataFactory.createSObject(new Course_Fee__c(Course__c = course.Id, CurrencyIsoCode='IDR',Base_Total_Course_Fee__c=20000, pricebook__c = pb.Id), true);
        Product2[] products = [SELECT Id, External_ID__c FROM Product2 WHERE Course__c = :course.Id];
        System.assert(products != null && products.isEmpty() == false,'Course Fee creation generate a product successfully.');
        System.assert(products[0].External_ID__c == course.Name + '_' + course.Name, 'Product External ID is a combination of course code and unit set separated by underscore.');
        Test.startTest();
        fee.Course_Deposit_Amount__c = 100;
        update fee;
        Test.stopTest();

        System.assertEquals([select id,name,CurrencyIsoCode,Pricebook2.name from PricebookEntry where Pricebook2.name='Standard Price Book'].size(),1);
        System.assertEquals([select id,name,CurrencyIsoCode,Pricebook2.name from PricebookEntry where Pricebook2.name='Indonesia Domestic'].size(),1);
        System.assertEquals([select id,name,CurrencyIsoCode,Pricebook2.name,Unitprice from PricebookEntry where Pricebook2.name='Indonesia Domestic'].Unitprice, 20000);

    }
}