/**
 * @File Name          : QuotesSelectorTest.cls
 * @Description        : Test class for QuotesSelector class
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : 
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 12/17/2019, 8:38:38 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    12/17/2019   jasmin.rudio@monash.edu     Initial Version
**/
@isTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object - SBQQ__Quote__c*/
public with sharing class QuotesSelector_Test {
    
    private static final String ENVELOP_ID_1 = 'e1420cb6-7172-4e39-acca-45888ad4e461';
    private static final String ENVELOP_ID_2 = 'e1420cb6-7172-4e39-acca-45888ad4e462';

    @testSetup
    static void makeData(){
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Status__c='Published',
                Sub_Status__c='In QA Review',
                Primary_DocuSign_Envelop_Id__c=ENVELOP_ID_1
            ),false);
        quotes.add(quote1);

        SBQQ__Quote__c quote2 = (SBQQ__Quote__c)TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Status__c='Published',
                Sub_Status__c='In QA Review',
                Primary_DocuSign_Envelop_Id__c=ENVELOP_ID_2
            ),false);
        quotes.add(quote2);

        insert quotes;

    }

    @isTest
    private static void quoteSelector(){
        Test.startTest();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);
        Account acc1 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);
        Contact contact1 = (Contact)TestDataFactory.createSObject(new Contact(FirstName='Test', Lastname='Con1',AccountId = acc1.Id, Birthdate = Date.today(),Country_of_Residence__c='INDIA'), true);
        SBQQ.TriggerControl.disable();
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc1.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact1.Id,SBQQ__Status__c='Published',Sub_Status__c='In QA Review'),true);

        
            QuotesSelector selector = new QuotesSelector();
            List<SBQQ__Quote__c> selectById = selector.selectById(new Set<Id>{quote1.Id});
            List<SBQQ__Quote__c> selectQuoteById = selector.selectQuoteById(new Set<String>{quote1.Id});
            List<SBQQ__Quote__c> selectQuoteByContactOwner = selector.selectQuoteByContactOwner(contact1.Id, UserInfo.getUserId());
            selector.getHealthOptions(quote1.Id, false);
            selector.selectQuoteByWithPagination(contact1.Id, UserInfo.getUserId(), 1, 0);
            
        Test.stopTest();

        Assert.isTrue(selectById != null);
        Assert.isTrue(selectQuoteById != null);
        Assert.isTrue(selectQuoteById != null);
        Assert.isTrue(quote1 != null);

    }

    @isTest
    static void shouldBeAbleToSetOverridePerm() {
        try {
            QuotesSelector selector = new QuotesSelector(true);
            Assert.areNotEqual(null, selector.getSObjectType(), 
            'Expected getSObjectType to return a value');
            Assert.isTrue(true, 'Expected to be able to override permission');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expected to be able to override permission');
        }
    }

    @isTest
    static void shouldReturnSObjectType() {
        QuotesSelector selector = new QuotesSelector();
        Assert.areNotEqual(null, selector.getSObjectType(), 
            'Expected getSObjectType to return a value');
    }

    @isTest
    static void shouldReturnEmptyListWhenEnvelopIdDoesNotExist() {
        QuotesSelector selector = new QuotesSelector();
        List<SBQQ__Quote__c> result = 
            selector.selectQuotesByPrimaryDocuSignEnvelopId('doesnotexist');
        Assert.areEqual(new List<SBQQ__Quote__c>(), result, 
            'Expected empty list of quotes as primary envelop Id does not ' 
            + 'exist in the system');
    }

    @isTest
    static void shouldReturnEmptyListWhenEnvelopIdsDoesNotExist() {
        Set<String> envelopIdsThatDoNotExist = new Set<String>{
            'doesnotexist0', 'doesnotexist1', 'doesnotexist2', 'doesnotexist3',
            'doesnotexist4', 'doesnotexist5'
        };
        QuotesSelector selector = new QuotesSelector();
        List<SBQQ__Quote__c> result = 
            selector.selectQuotesByPrimaryDocuSignEnvelopId(envelopIdsThatDoNotExist);
        Assert.areEqual(new List<SBQQ__Quote__c>(), result, 
            'Expected empty list of quotes as primary envelop Ids does not ' 
            + 'exist in the system');
    }

    @isTest
    static void shouldReturnEmptyMapWhenEnvelopIdsDoesNotExist() {
        Set<String> envelopIdsThatDoNotExist = new Set<String>{
            'doesnotexist0', 'doesnotexist1', 'doesnotexist2', 'doesnotexist3',
            'doesnotexist4', 'doesnotexist5'
        };
        QuotesSelector selector = new QuotesSelector();
        Map<String, SBQQ__Quote__c> result = 
            selector.selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId(envelopIdsThatDoNotExist);
        Assert.areEqual(0, result.size(), 
            'Expected empty map of quotes as primary envelop Ids does not ' 
            + 'exist in the system');
    }

    @isTest 
    static void test_selectByIdMap(){
        new QuotesSelector().selectByIdMap(new Set<String>());
    }

    /**
     * @author          Vishal Gupta
     * @description     fetch the quote with quote line by Id  
     * @revision        7/2/2025 - Initial Version
     */
    @isTest
    private static void quoteWithQuoteLineSelector(){
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id, Person_ID_unique__c FROM Contact WHERE id =: applicant.contactId];
        c.Person_ID_unique__c = '2346193';
        update c;
        //create Academic Org unit account
        Account testAcademicOrg = new Account(Name = 'test Academic Org unit', Callista_Org_Unit_Code__c='TEST123');
        insert testAcademicOrg;
        //create faculty account
        Account testFaculty = new Account(Name = 'test faculty', Callista_Org_Unit_Code__c='TEST12398', Monash_AM_Start_Date__c=Date.Today(), RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Faculty'][0].Id);
        insert testFaculty;

        //create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        insert app;
        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.Faculty__c = testFaculty.Id;
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        //create Application_Course_Preference__c
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        coursePreference.Academic_Org_Unit__c = testAcademicOrg.Id;
        coursePreference.GradRes_Callista_Id__c = '5234725';
        insert coursePreference;

        Opportunity oppty = new Opportunity(Name = 'test', StageName = 'New Offer', CloseDate = date.today().addDays(3), Application_Course_Preference__c = coursePreference.Id,
                            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Graduate_Research_Offer').getRecordTypeId(), Research_Offer_Type__c = 'Scholarship Offer');
        insert oppty;

        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();
        
        //Given, there are quotes in linked to the opportunity with GR scholarship offer
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppty.Id),true);

        Test.startTest();
            QuotesSelector selector = new QuotesSelector();
            //When, we query the quotes
            List<SBQQ__Quote__c> selectById = selector.selectQuoteAndLineItemsById(new Set<String>{quote1.Id});            
        Test.stopTest();
        //Then, it should return the quote records
        Assert.isNotNull(selectById, 'quotes found');

    }
}