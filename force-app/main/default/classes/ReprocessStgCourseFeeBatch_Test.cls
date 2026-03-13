/**
 * @description       : Test class for ReprocessStgCourseFeeBatch.cls
 * @author            : Kristian Vegerano
 * @group             : Batch
 * @last modified on  : 2022-05-16
 * @last modified by  : Kristian Vegerano
 * Modifications Log 
 * Date         Author                  Modification
 * 2022-05-16   Kristian Vegerano       Initial Version
 */
@isTest(isParallel=false) // due to schedule evaluations
private class ReprocessStgCourseFeeBatch_Test {

    @testSetup 
    static void setup() {
        //insert OrgUnitBundleMapping__c
        Test.loadData(OrgUnitBundleMapping__c.sObjectType, 'OrgUnitBundleMappingDataTest');
        //update std price book
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;        

        //add product bundles
        Product2[] bundles = new Product2[0];
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false));
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
        //unit set - monash english
        courses.add((Course__c)TestDataFactory.createSObject(new Course__c(), 'TestDataFactorySettings.MonashEnglishUnitSetDefaults', false));
        insert courses;
        
        TestDataFactory.createSObject(new Course_Duration__c(Pricebook__c = pricebook.Id), true);        

        // test stg course fee
        Stg_Course_Fee__c fee = (Stg_Course_Fee__c) TestDataFactory.createSObject(new Stg_Course_Fee__c(Unit_Set_Code__c = null, Currency__c = 'AUD', Unit_Set_Version__c = null), 'TestDataFactorySettings.MarketingStgCourseFeeDefaults', false);
        fee.Sync_Status__c = 'SYNC';
        insert fee;
    }

    /**
     * Test Scenario:
     * Stg Course Fee with a sync status is already SYNC
     * The pricebook entry regenerated would have its unit price same as the stg course fee's base_total_course_fee__c
     */
    @isTest
    static void test_ReprocessStgCourseFeeBatch_Execute() {        
        // GIVEN: a stg course fee
        Stg_Course_Fee__c fee = [SELECT Id, Base_Total_Course_Fee__c, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c LIMIT 1];
        
        // WHEN: the batch is run to re-evaluate the 'is student' flag (on Contact)
        Test.startTest();
        Database.executeBatch(new ReprocessStgCourseFeeBatch());
        Test.stopTest();

        // THEN: the pricebook entry's is stg course fee's base total course fee
        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Pricebook2.isStandard = false LIMIT 1];
        System.assert(pbe != null && pbe.UnitPrice == fee.Base_Total_Course_Fee__c, 'Pricebook Entry is created successully and unit price should be set with Course Deposit Amount.');
    }

    /**
     * Test Scenario:
     * Stg Course Fee with a sync status is already SYNC
     * The pricebook entry regenerated would have its unit price same as the stg course fee's base_total_course_fee__c with queries
     */
    @isTest
    static void test_ReprocessStgCourseFeeBatchWithQuery_Execute() {        
        // GIVEN: a stg course fee
        Stg_Course_Fee__c fee = [SELECT Id, Base_Total_Course_Fee__c, Sync_Status__c, Sync_Message__c FROM Stg_Course_Fee__c LIMIT 1];
        
        // WHEN: the batch is run to re-evaluate the 'is student' flag (on Contact)
        Test.startTest();
        Database.executeBatch(new ReprocessStgCourseFeeBatch('SELECT Id FROM Stg_Course_Fee__c ORDER BY Fee_Band_Code_Year__c ASC'));
        Test.stopTest();

        // THEN: the pricebook entry's is stg course fee's base total course fee
        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Pricebook2.isStandard = false LIMIT 1];
        System.assert(pbe != null && pbe.UnitPrice == fee.Base_Total_Course_Fee__c, 'Pricebook Entry is created successully and unit price should be set with Course Deposit Amount.');
    }

    @isTest
    static void testReprocessStgCourseFeeBatch_ScheduleAndUnSchedule() {
        Exception testException = null;
        // GIVEN: batch job is defined 
        ReprocessStgCourseFeeBatch myBatch = new ReprocessStgCourseFeeBatch();
        Test.StartTest();
        // WHEN: job is scheduled
        try{
            myBatch.schedule();
        } catch (Exception exc) {
            testException = exc;
        }
        // THEN: no exception is expected
        System.assert(null==testException, 'An exception occured when scheduling the batch job.');
        
        // WHEN: job is unscheduled
        try{
            myBatch.unschedule();
        } catch (Exception exc) {
            testException = exc;
        }
        // THEN: 
        System.assert(null==testException, 'An exception occured when unscheduling the batch job.');
        Test.stopTest();
    }
}