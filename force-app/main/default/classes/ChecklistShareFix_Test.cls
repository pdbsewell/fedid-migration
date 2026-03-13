/**
 * Created by trentdelaney on 14/7/20.
 */
@IsTest
public with sharing class ChecklistShareFix_Test {

    public static String CONTACT_NAME = 'ChecklistShareFix';

    @TestSetup
    public static void setup(){
        Contact c = StudFirst_TestHelper.createApplicant();
        c.First_Name__c = CONTACT_NAME;
        insert c;

        //Create test Create application
        Application__c testApplication = StudFirst_TestHelper.createApplication(c.Id);
        insert testApplication;

        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        insert testCourse;

        //Create test Offering
        Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
        insert testOffering;

        //Create test ACP
        Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, c, testOffering, testCourse);
        testACP.Preference_Number__c = '1';
        insert testACP;



        //Create test course prerequisite
        List<Course_Specific_Document__c> courseSpecificDocumentList = new List<Course_Specific_Document__c>();
        // add course related prerequisite
        courseSpecificDocumentList.add(new Course_Specific_Document__c(Name = 'Course Prerequisite',
                                                              IsActive__c = true,
                                                              Course__c = testCourse.Id,
                                                              Instruction__c = 'Test Course Instruction'));
        // add faculty related prerequisite
        courseSpecificDocumentList.add(new Course_Specific_Document__c(Name = 'Faculty Prerequisite',
                                                              IsActive__c = true,
                                                              Faculty_Name__c = 'Faculty of Art, Design and Architecture',
                                                              Instruction__c = 'Test Faculty Instruction'));
        insert courseSpecificDocumentList;

        //Submit the application
        testApplication.Status__c = 'Submitted';
        testApplication.Residency_Status__c = 'DOM-AUS';
        update testApplication;
    }

    @IsTest
    public static void testChecklistFix(){
        List<Document_Checklist__c> checklists;
        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{testApplication.id});
        rulesDocChecklistEngine.evaluateRules('Application Assessment');

        //Retrieve checklist items
        checklists = rulesDocChecklistEngine.resultChecklistItemsMap.get(testApplication.id).values();
        List<User> users = [SELECT Id, Username FROM User WHERE Username LIKE 'autoproc%'];
        for (Document_Checklist__c checklist : checklists) {
            checklists[0].OwnerId = users[0].Id;
        }
        insert checklists;

        ChecklistShareFix checkFix = new ChecklistShareFix();

        Test.startTest();
        ID batchprocessid = Database.executeBatch(checkFix, 100);
        Test.stopTest();

        List<Document_Checklist__c> checklists2 = [SELECT Id, OwnerId FROM Document_Checklist__c WHERE Application__r.Applicant__r.First_Name__c = :CONTACT_NAME];
        Assert.isNotNull(batchprocessid, 'Batch process not started');        
        Assert.areNotEqual(checklists2[0].OwnerId, users[0].Id, 'Unable to reassign from auto proc');        
    }
}