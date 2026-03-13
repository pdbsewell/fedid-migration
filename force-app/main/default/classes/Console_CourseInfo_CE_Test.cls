/**
* @author Angelo Rivera
* @date 05.09.19
* @group Test Class
* @description  Custom Controller Extension for use in custom service console component(s).<br/>
*               Specifically, the component that surfaces course and application information
* @revision     15/12/2019 - APRivera - removed references of API_ResultWrapper (API.Monash) <br/>
*/
@isTest(isParallel=true)
private class Console_CourseInfo_CE_Test {

    @testSetup
    static void setupTestData(){
        // if test data required, establish here
        TestHelper.calabrioSetUp();
        List<contact> contacts = TestHelper.createOrphanContactRecords(2);
        integer offset = 1;
        for(contact c : contacts) {
            c.birthdate = date.newInstance(1975,1,1);
            c.Person_Id_unique__c = String.valueOf(12345+offset);
            offset++;
        }
        insert contacts;
        system.assertNotEquals(null, contacts[0].id,'contacts didnt insert as expected');

        // add some person notes
        List<Person_Note__c> notes = new List<Person_note__c>();
        for(contact c : contacts) notes.add(new Person_note__c(contact__c = c.id, type__c = 'type', important__c = true, notes__c = 'test note'));
        insert notes;
        system.assertNotEquals(null, notes[0].id,'notes didnt insert as expected');

        List<Case> cases = TestHelper.webToCaseForms(2);
        cases[0].contactId = contacts[0].id;
        cases[0].Enquiry_Type__c = CaseServices.CURRENT_COURSE;
        cases[0].Course_code__c = '123';
        cases[0].Managing_Faculty__c = 'Arts';
        cases[0].Status = 'Open';
        cases[0].Course_Linked__c = false;

        cases[1].contactId = contacts[0].id;
        cases[1].Enquiry_Type__c = CaseServices.CURRENT_COURSE;
        cases[1].Course_code__c = 'COMPLETED';
        insert cases;

        // append some enquiry interests
        List<course__c> courses = TestHelper.createCourses(2);
        courses[0].name = '123445';
        insert courses;
        system.assertNotEquals(null, courses[0].id,'courses didnt insert as expected');

        List<Enquiry_Interest__c> interests = new List<Enquiry_Interest__c>();
        for(contact c : contacts){
            for(course__c course : courses){
                for(case cse : cases)
                    interests.add(new Enquiry_Interest__c(course__c = course.id, person__c = c.id, case__c = cse.id));
            }
        }

        insert interests;
        system.assertNotEquals(null, interests[0].id,'interests didnt insert as expected');

        Course__c testCourse = new Course__c(Name = 'TestCourse', Managing_Faculty__c = 'TestFaculty', Type__c='Course-All');
        insert testCourse;

        Application_Course_Preference__c acp = new Application_Course_Preference__c(Name='Test', Managing_Faculty_Text__c='TestFaculty', Course__c=testCourse.id, Course_Title__c='TestCourse', Course_Code__c='LC001', Outcome_Status__c='IN_PROGRESS',
                Offer_Response_Status__c='PENDING',Applicant__c=contacts[0].id);
        insert acp;

        Course_Attempt__c ca = new Course_Attempt__c(Name='Test', Course__c=testCourse.id, Course_Attempt_Status__c='Enrolled', Attendance_Type__c='FT', Attendance_Mode__c='IN', Location__c='Clayton',
                Contact__c = contacts[0].id);
        insert ca;

    }

    static testMethod void testCourseInfoLogic(){

        PageReference pg = Page.Console_courseInfo_v2;
        Test.setCurrentPage(pg);

        Case cse = [select id, Status, Managing_Faculty__c, Course_Linked__c from case where case.contact.Person_ID__c != null limit 1];
        ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);

        Console_CourseInfo_CE con = new Console_CourseInfo_CE(stdCase);

        Test.startTest();
        con.initalLoad();
        Boolean res = con.renderTable;
        con.unlinkFromCase();

        course__c crse = [select id,name from course__c where name = 'TestCourse' limit 1];
        con.courseIdSelected = crse.name + ':' + 'LC001';
        con.linkToCase();
        Test.stopTest();
        //System.assertNotEquals(cse.Managing_Faculty__c, null);
    }

    static testMethod void testCourseInfoLogic1(){

        PageReference pg = Page.Console_courseInfo_v2;
        Test.setCurrentPage(pg);

        Case cse = [select id, Course_code__c from case where case.contact.Person_ID__c != null and Course_code__c ='COMPLETED' limit 1];
        ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);

        Test.startTest();
        Console_CourseInfo_CE con = new Console_CourseInfo_CE(stdCase);
        con.initalLoad();

        course__c crse = [select id,name from course__c where name = '123445' limit 1];
        con.courseIdSelected = crse.name + ':' + 'COMPLETED';
        con.linkToCase();
        Test.stopTest();
        //System.assertNotEquals(cse.Course_code__c, null);
    }

}