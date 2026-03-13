/*
 * @description     Contains all test for  UnitSetAttemptServices
 *
 **/ 
@isTest(isParallel=true)
public class UnitSetAttemptServices_Test {

    @testSetup
    static void testDataSetup() {
        // Create test contact
        Contact iContact = new Contact();
        iContact.Person_Id_unique__c = '98765432';
        iContact.LastName = 'USALastname';
        iContact.FirstName = 'USAFirstname';
        iContact.SAP_Staff_Id__c = 'NoDupRules'; // this will filter the contact out of the most of the duplicate rules
        insert icontact;
        
        // Create test course         
        Course__c iCourse = new Course__c(Name='USACourseName', Course_Code__c = 'USACourseName_1', Version__c='1',Type__c = 'Course-All', Status__c='Active');
        insert iCourse;
        Course__c iUnitSet = new Course__c(Name='USAUnitSetName', Course_Code__c = 'USAUnitSetName_1', Version__c='1',Type__c = 'Unit Set', Status__c='Active');
        insert iUnitSet;

         // Create test course Attempt         
        Course_Attempt__c iCourseAttempt = new Course_Attempt__c();
        iCourseAttempt.Name = iContact.Person_Id_unique__c + '/USACourseName';
        iCourseAttempt.Contact__c = iContact.Id;
        iCourseAttempt.Course__c = iCourse.Id;
        String caCourseAttemptId = iContact.Person_Id_unique__c + '_USACourseName';
        iCourseAttempt.Callista_External_Id__c = caCourseAttemptId;
        insert iCourseAttempt;
    }
    
	@isTest
	static void test_populateUnitSetAttemptName() {
        Contact con = [SELECT Id, Person_ID__c FROM Contact LIMIT 1];
        Course_Attempt__c ca = [SELECT Id, Course_Code__c FROM Course_Attempt__c LIMIT 1];

        //create test unit attempt
        Unit_Set_Attempt__c usa = new Unit_Set_Attempt__c(Person_ID__c = con.Person_ID__c, Course_Code__c = ca.Course_Code__c, course_attempt__c = ca.id , Code__c = 'USAUnitSetName', version__c = '1');

        Test.startTest();
            insert usa;
            usa = [SELECT Id, Name, Person_ID__c, Course_Code__c, Code__c, deleted_on_source__c
                    FROM Unit_Set_Attempt__c
                   WHERE Id = :usa.Id
                   LIMIT 1];
            String uniqueName = UnitSetAttemptServices.getUniqueName(usa);
        Test.stopTest();

        String expected = usa.Person_ID__c + '/' + 
                          usa.Course_Code__c + '/' + 
                          usa.Code__c;
        Assert.areEqual(expected, uniqueName);
    }
    
    @isTest
	static void test_populateDeleteName() {
        Contact con = [SELECT Id, Person_ID__c FROM Contact LIMIT 1];
        Course_Attempt__c ca = [SELECT Id, Course_Code__c FROM Course_Attempt__c LIMIT 1];

        //create test unit attempt
        Unit_Set_Attempt__c usa = new Unit_Set_Attempt__c(Person_ID__c = con.Person_ID__c, Course_Code__c = ca.Course_Code__c, course_attempt__c = ca.id , Code__c = 'USAUnitSetName', version__c = '1');
		insert usa;
        
        usa.deleted_on_source__c = true;

        Test.startTest();
            update usa;
            usa = [SELECT Id, Name, Person_ID__c, Course_Code__c, Code__c, deleted_on_source__c
                    FROM Unit_Set_Attempt__c
                   WHERE Id = :usa.Id
                   LIMIT 1];
            String uniqueName = UnitSetAttemptServices.getUniqueName(usa);
        Test.stopTest();

        String expected = '[Pending Delete] ' + usa.Person_ID__c + '/' + 
                          usa.Course_Code__c + '/' + 
                          usa.Code__c;
        Assert.areEqual(expected, uniqueName);    
    }
}