/**
 * Created by bmistry on 19/12/19.
 */

@IsTest
public with sharing class EnglishTestScoreRequest_Test {
    @IsTest
    static void test_AssignEnglishTestScorePropertyValues() {
        EnglishTestScoreRequest request = new EnglishTestScoreRequest();
        System.assert(request != null, 'Unable to create the EnglishTestScore Request');

        request.resultType = 'TestResult Type';
        request.achievedDate = String.valueOf(Date.today());
        request.comments = 'Test Score Comment';
        request.completed = true;
        request.expiryDate = String.valueOf(Date.today());
        request.grade = 'First Class';
        request.overallScore = 8;
        request.plannedDate  = String.valueOf(Date.today());
        request.testType = 'Online';
        request.verificationStatus = 'Test';
        request.type = 'Englist Score';

        EnglishTestScoreRequest.coursePreferences coursePreference = new EnglishTestScoreRequest.coursePreferences();
        System.assert(coursePreference != null, 'Unable to create the EnglishTestScoreRequest.coursePreferences');
        coursePreference.type = 'Test Course';
        coursePreference.courseCode = 'Test CourseCode';
        coursePreference.admissionApplNumber = 12345;

        EnglishTestScoreRequest.applications application = new EnglishTestScoreRequest.applications();
        System.assert(application != null, 'Unable to create the EnglishTestScoreRequest.applications');
        application.type = 'INT';
        List<EnglishTestScoreRequest.coursePreferences> corsePreferences = new List<EnglishTestScoreRequest.coursePreferences>{coursePreference};
        application.coursePreferences = corsePreferences;
        System.assert(application.coursePreferences.get(0) != null, 'No Course Preferences Found For EnglishTestScore');


        EnglishTestScoreRequest.subscores subscores = new EnglishTestScoreRequest.subscores();
        subscores.type = 'Test SubScore Type';
        subscores.score = 'Test Score';
        subscores.scoreType = 'English';
        System.assert(subscores != null, 'Unable to create the EnglishTestScoreRequest.subscores');


    }
}