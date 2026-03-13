/**
 * @author      Vishal Gupta
 * @description test class for MyAppWithoutSharingController
 * @group       My App Community Services
 * @created on  12/09/2024
 */
//APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User
@isTest(isParallel=false)
private class MyAppWithoutSharingController_Test {
    /*
    * @description Data Setup
    */    
    @TestSetup
    static void makeData(){
        // insert test records
    	Contact c = new Contact();
        String fName = 'Test';
        String lName = 'Surname';
        c.FirstName = fName;
        c.LastName = lName;   
        c.email = 'test@invalid.edu';     
        insert c;
    }
    /**
     * @author      vishal gupta
     * @description Tests getting any data without sharing setting applied
     *
	 * GIVEN the student has applied for the my application from student portal
     * WHEN they are logged in and applied for a course application and application is created
     * THEN they can search for the application
     */
    @isTest
    public static void testGetSearchResults()
    {
        // create community user
        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        insert app;
        Test.startTest();
        System.runAs(applicant) {
            List<String> fieldsToReturn = new List<String>{'Id', 'Name'};
            String objectAPIName = 'Application__c';
            List<String> whereFields = new List<String>{'Id'};
            List<String> whereValues = new List<String>{app.Id};
            List<String> optionalWhereFields = new List<String>();
            List<String> searchFields = new List<String>();
            String searchText = '';
            List<Object> lst = MyAppWithoutSharingController.getSearchResults(fieldsToReturn, objectAPIName, whereFields, whereValues, optionalWhereFields, searchFields, searchText);
            Assert.areEqual(lst.size(), 1);
        }

        Test.stopTest();
    }

    /*
    * @description Tests scenario with NOT and LIKE comparisons in the WHERE Clause, while Querying
    * 
    * GIVEN when user search for a contact record
    * WHEN they type in NOT and LIKE comparisons
    * THEN then should successfully search for a contact
    */
    @isTest 
    public static void Test_getSearchResults_NOTLIKEScenario()
    {   
    	// Testing both NOT and LIKE symbols
        String[] fieldsToReturn = new String[]{'FirstName', 'LastName'};
        String objectApiName = 'Contact';
        String[] whereFields = new String[]{'FirstName', 'IsDeleted', 'Salutation','!%email'};
        String[] whereValues = new String[]{'Test', 'false', 'Mr.', 'invalid'};
        String[] optionalWhereFields = new String[]{'AccountId', 'Salutation'};
	    String[] searchFields = new String[]{'LastName', 'FirstName'};
        String searchText = 'Surname';
        User applicant = StudFirst_TestHelper.createCommunityUser();
        System.runAs(applicant) {
            Test.startTest();
            List<Object> listResults = MyAppWithoutSharingController.getSearchResults(fieldsToReturn,
                objectAPIName,
                whereFields,
                whereValues,
                optionalWhereFields,
                searchFields,
                searchText);
            Test.stopTest();
            Assert.areEqual(listResults.size(), 0);
        }
        
    }

    /*
    * @description Tests scenario with only LIKE comparison in the WHERE Clause, while Querying
    * 
    * GIVEN when user search for a contact record
    * WHEN they type in like scenarios
    * THEN there should search results
    */
    @isTest 
    public static void Test_getSearchResults_LIKEScenario()
    {           
        // Testing LIKE Symbol
        String[] fieldsToReturn = new String[]{'FirstName', 'LastName'};
        String objectApiName = 'Contact';
        String[] whereFields = new String[]{'%email'};
        String[] whereValues = new String[]{'invalid'};
        String[] optionalWhereFields = new String[]{'AccountId', 'Salutation'};
	    String[] searchFields = new String[]{'LastName', 'FirstName'};
        String searchText = 'Surname';
        User applicant = StudFirst_TestHelper.createCommunityUser();
        System.runAs(applicant) {
            Test.startTest();
            List<Object> listResults = MyAppWithoutSharingController.getSearchResults(fieldsToReturn,
                objectAPIName,
                whereFields,
                whereValues,
                optionalWhereFields,
                searchFields,
                searchText);
            Test.stopTest();
            Assert.areEqual(listResults.size(), 1);
        }
        
    }

    @isTest
    /**
     * @author      vishal gupta
     * @description Tests updating application for Graduate Research without sharing setting applied
     *
	 * GIVEN the student has applied for the my application from student portal
     * WHEN they are logged in and applied for a course application and application is created
     * THEN they can create and update qualification   
	 */
     
    public static void testUpdateContactQualification()
    {
        // create community user
        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        insert app;
        Test.startTest();
        System.runAs(applicant) {
            app.Type_of_Study__c = 'Coursework';
            MyAppWithoutSharingController.updateApplication(app);
            
            
        }

        Test.stopTest();
        Application__c appUpdated = [SELECT Type_of_Study__c FROM Application__c WHERE Id = :app.Id]; 
        Assert.areEqual(appUpdated.Type_of_Study__c, 'Coursework');
    }

    @isTest
    /**
     * @author      vishal gupta
     * @description Tests deleting the existing contact qualifications and 
     *              getting the course master data for Grad Research steps
     * 
     * GIVEN the student has applied for the my application from student portal
     * WHEN they are logged in and applied for a course application and application is created
     * THEN they can delete the contact qualification
     */
    public static void testGRStepReform()
    {
        // create community user
        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        List<RecordType> recTypes = [SELECT Id, Name, sObjectType
                                    FROM        RecordType
                                    WHERE       sObjectType = 'Contact_Qualification__c'
                                    AND Name = 'Music'
                                    ];

        RecordType rt = recTypes[0];
        
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        app.Applicant_Agent__c = 'Yes';
        app.Agent_Staff_Email__c = 'testagentemail@test.com';
        insert app;

        Contact_Qualification__c cq = new Contact_Qualification__c();
        cq.Contact__c = applicant.ContactId;
        cq.RecordTypeId = rt.Id;
        insert cq;

        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.Name = 'TestCourseCode';
        insert course;

        // offering
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Course_Code__c = 'TestCourseCode';
        insert offering;

        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, offering, course);
        acp.Course_Code__c = 'TestCourseCode';
        insert acp;
        List<Course_Master__c> cms = new List<Course_Master__c>();
        for(Course_Master__c cm : [SELECT Course_Code__c, GradRes_Application_Requirement__c FROM Course_Master__c]) {
            cm.GradRes_Application_Requirement__c = 'Publications';
            cms.add(cm);
        }
        update cms;
        
        Test.startTest();
        System.runAs(applicant) {
            List<String> stepsToReturn = MyAppWithoutSharingController.getGradResearchStepsAndDeleteContactQualification(app.Id);
            Assert.areEqual(stepsToReturn.contains('Publications'), true);

            Application__c application = [SELECT Applicant_Agent__c FROM Application__c WHERE Id=:app.Id];
            Assert.areEqual(application.Applicant_Agent__c, null);
        }

        Test.stopTest();
        
    }

}