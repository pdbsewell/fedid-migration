/**
 * Created by smen0015 on 11/11/2019.
 @revision: 6/2/2020 - SFTN-479-ACP Updates failing on English Test Scores
 @revision: 8/07/2025 - EPCP-4493 PB Migration to Flow
*/
@isTest(isParallel=true)
private class EnglishTestScoreInterface_Test {
    @TestSetup
    public static void testDataSetup()
    {
        // Create country
        Country_Attribute__c ca = new Country_Attribute__c(Name = 'AUSTRALIA');
        insert ca;

        // Create applicant
        Contact applicant = StudFirst_TestHelper.createApplicant();
        applicant.Person_ID_unique__c = '12312312';
        insert applicant;

        // Create application
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        application.Callista_Applicant_Id__c = '0030k000001tbfEAAQ';
        insert application;

        Work_Experience__c workExperience = StudFirst_TestHelper.createWorkExperience(applicant);
        insert workExperience;

        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        // Create Course Preferences
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(application, applicant, courseOffering, course);
        insert coursePreference;

        Qualification__c englishTestQ = StudFirst_TestHelper.createEnglishTest();
        englishTestQ.Sub_score_Type__c = 'Listening;Reading;Speaking;Writing;Test of Written English';
        insert englishTestQ;

        Contact_Qualification__c cq = StudFirst_TestHelper.createContactQualification(applicant, englishTestQ ,'English Test');
        insert cq;

        Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c(Contact_Qualification__c = cq.Id,Application__c=application.Id);
        insert aqp;

        coursePreference.Admission_Application_Number__c = 432333;
        update coursePreference;

    }

    @isTest
    static void testEnglishScore()
    {
        Boolean completed;

        //GIVEN: We have an English Test Score to sync against Callista
        EnglishTestScoreAPIMock mock = new EnglishTestScoreAPIMock();

        //WHEN: The callout is made
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, mock);
            Id cqId=  [SELECT ID FROM Contact_Qualification__c WHERE CONTACT__r.Person_ID_unique__c = '12312312' ].Id;
            EnglishTestScoreInterface.fireOutboundRequest( new List<Id>{cqId});
            completed = true;
        }
        catch(Exception ex){
            completed = false;
        }
        Test.stopTest();

        //THEN: Callout is successfully initiated
        Assert.isTrue(completed, 'expected fireOutboundRequest to complete without issues');
    }
    
    @isTest
    static void testEnglishScoreWithoutPersonID()
    {
        //GIVEN: We have an English Test Score (No Person Id) to sync against Callista
        EnglishTestScoreAPIMock mock = new EnglishTestScoreAPIMock();
        
        //WHEN: An update occurs to trigger the sync
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        Contact c = [SELECT ID,Person_ID_unique__c FROM Contact WHERE Person_ID_unique__c = '12312312'];
        c.Person_ID_unique__c = null;
        update c;

        Id idd=  [SELECT ID FROM Contact_Qualification__c WHERE CONTACT__r.Person_ID_unique__c = null ].Id;
        String cqId = String.valueOf(idd);
        EnglishTestScoreInterface eTest = new EnglishTestScoreInterface (cqId);
        Test.stopTest();

        //THEN: PersonId on EnglishTestScoreInterface is also null
        Assert.areEqual(null, eTest.personId, 'expected PersonId on EnglishTestScoreInterface to be null'); 
    }

    @IsTest
    static void test_convertDate() {
        //GIVEN: We have a date to convert
        Date myDate = Date.newInstance(1985, 2, 2);
        
        //WHEN: We apply the date conversion
        Test.startTest();
        String formattedDate = EnglishTestScoreInterface.convertDate(myDate);
        Test.stopTest();

        //THEN: It is correctly formatted
        Assert.areEqual('1985-02-02', formattedDate,' Date conversion not correct');
    }
}