/**
* @author Angelo Rivera
* @date 29.May.2019
* @group Test Class
* @description  Test Class to test the functionality of MonConCaseServices
* @revision     APRivera, 29.May.2019 - Created <br/>
*               APRivera, 20.January.2019 - Increased Code Coverage <br/>
*               APRivera, 15.February.2021 - Updated <br/>
*/

@isTest(isParallel=true)
private class EnquiryCourseInformationCC_Test {
    @testSetup
    static void setupTestData(){
        Contact testContact = TestHelper.createOrphanContactRecords(1)[0];
        testContact.Birthdate = Date.newInstance(1975, 1, 1);
        testContact.Person_Id_unique__c = String.valueOf(12345);
        insert testContact;

        Case testCase = new Case(Subject = 'TestSubject', ContactId = testContact.Id);
        insert testCase;

        Course__c testCourse = new Course__c(Name = 'TestCourse', Managing_Faculty__c = 'TestFaculty', Type__c='Course-All');
        insert testCourse;


        Course_Attempt__c ca = new Course_Attempt__c(Name='Test', Course__c=testCourse.id, Course_Attempt_Status__c='Enrolled', Attendance_Type__c='FT', Attendance_Mode__c='IN', Location__c='Clayton',
                Contact__c = testContact.id);
        insert ca;
    }

    @IsTest
    static void testBehavior() {
        Case c = [Select Id, ContactId from case LIMIT 1];
        Course_Attempt__c ca = [SELECT Id, Course_Attempt_Status__c FROM Course_Attempt__c LIMIT 1];
        Course__c crs = [Select Id, Managing_Faculty__c, Name from Course__c LIMIT 1];

        Test.startTest();
        EnquiryCourseInformationCC.retrieveStudentInformation(c.ContactId);
        Case cse = new Case();
        EnquiryCourseInformationCC.unlinkCourse(c.Id);

        EnquiryCourseInformationCC.linkCourse(c.Id, crs.Id, crs.Name, ca.Id, ca.Course_Attempt_Status__c);

        EnquiryCourseInformationCC.goToCourse(crs.Id, crs.Name);
        Test.stopTest();
    }


    // Test AutoLinkToCase Method
    @IsTest
    static void testAutoLinkToCase() {
        Test.startTest();
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
        Course__c crs = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);
        Course_Attempt__c ca = (Course_Attempt__c)MonConTestDataFactory.createSObject(new Course_Attempt__c());
        ca.Course__c = crs.Id;
        ca.Contact__c = testContact.Id;
        insert ca;

        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.Course_Linked__c = false;
        cse.Managing_Faculty__c = 'Engineering';
        insert cse;

        cse.ContactId = testContact.Id;
        update cse;

        EnquiryCourseInformationCC.getContactDetails(testContact.Id);
        EnquiryCourseInformationCC.autoLinkToCase(cse.Id);
        Map<String, List<Course_Attempt__c>> mapCourseAttemptsByStatus = new Map<String, List<Course_Attempt__c>>();
        mapCourseAttemptsByStatus = EnquiryCourseInformationCC.buildMapCourseAttemptsByStatus(EnquiryCourseInformationCC.contactRecord);

        EnquiryCourseInformationCC.updateCaseLinkCourse(cse, mapCourseAttemptsByStatus, new Course_Attempt__c());

        Test.stopTest();
        System.assertNotEquals(null, [SELECT Course__c FROM Case WHERE Id =: cse.Id]);
    }
}