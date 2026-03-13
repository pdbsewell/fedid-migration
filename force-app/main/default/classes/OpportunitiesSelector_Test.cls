/**
 * @description Test class for OpportunitiesSelector
 */
@isTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object - Opportunity*/
private class OpportunitiesSelector_Test {
    @TestSetup
    static void makeData() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
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
        insert coursePreference;

        Opportunity oppty = new Opportunity(Name = 'test', StageName = 'New Offer', CloseDate = date.today().addDays(3), Application_Course_Preference__c = coursePreference.Id,
                            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Graduate_Research_Offer').getRecordTypeId(), Research_Offer_Type__c = 'Scholarship Offer');
        insert oppty;
    }

    @isTest private static void test_selectById() {
        new OpportunitiesSelector(false).selectById(new Set<Id>());
        Assert.isTrue(true,'SQL "selectById" is good, not compilation error');
    }
    @isTest private static void test_selectByIdWithOpportunityLines(){
        new OpportunitiesSelector().selectByIdWithOpportunityLines(new Set<Id>());
        Assert.isTrue(true,'SQL "selectByIdWithOpportunityLines" is good, not compilation error');
    }
    @isTest private static void test_selectLatesByContactIdWithOpportunityLines(){
        new OpportunitiesSelector().selectLatesByContactIdWithOpportunityLines(new Set<String>(), new Set<String>{'Signed'});
        Assert.isTrue(true,'SQL "selectLatesByContactIdWithOpportunityLines" is good, not compilation error');
    }
    @isTest private static void test_getSObjectType(){
        Assert.isTrue(new OpportunitiesSelector().getSObjectType() == Opportunity.sObjectType,'Returned Opportunity type');
    }
    @isTest private static void test_selectByIdWithFullOfferAcceptanceDetails(){
        new OpportunitiesSelector().selectByIdWithFullOfferAcceptanceDetails(new Set<Id>());
        Assert.isTrue(true,'SQL "selectByIdWithFullOfferAcceptanceDetails" is good, not compilation error');
    }
    @isTest private static void test_selectByIdForOfferUpdate(){
        new OpportunitiesSelector().selectByIdForOfferUpdate(new Set<Id>());
        Assert.isTrue(true,'SQL "selectByIdForOfferUpdate" is good, not compilation error');
    }
    /**
     * @author          Vishal Gupta
     * @description     selecting the Opportunity based on Application Course Preference  
     * @revision        14/1/2025 - Initial Version
     */
    @isTest
    static void testSelectScholarshipOpportunityByACPId() {
        //Given, there is ACP exists in the system
        Application_Course_Preference__c acp = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];
        //When, we query the opportunities based on the acp id
        List<Opportunity> lstOpportunities = new OpportunitiesSelector().selectScholarshipOpportunityByACPId(new Set<ID>{acp.Id});
        //Then, it should return the related opportunities
        Assert.areEqual(lstOpportunities.size() > 0 , true, 'Retrieve opportunities based on ACP id');
    }
}