/*******************************************************************************
* @author:      Shalini Mendu
* @date:        12.Feb.2020
* @description: Test coverage for ObdLOIEnglishInterface
* @revision: 
*******************************************************************************/
@isTest(isParallel=true)
private class ObdLOIEnglishInterface_Test {
    @isTest
    static void testLOIEnglishScore()
    {
        Test.startTest();
      
        Contact applicant = StudFirst_TestHelper.createApplicant();
        applicant.Person_ID_unique__c = '12345678';
        
        insert applicant;

        // Create application
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        application.Callista_Applicant_Id__c = '0030k000001tbfEAAQ';
        application.English_Entry_Mode__c ='Country of secondary schooling / graduation';
        application.Meets_Minimum_English__c = 'Yes';
        insert application;

        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        // Create Course Preferences
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(application, applicant, courseOffering, course);
        insert coursePreference;

        application.Meets_Minimum_English__c = 'No';
        update application;
        
        ObdLOIEnglishInterface intf = new ObdLOIEnglishInterface (application.Id,application.English_Entry_Mode__c, application.Meets_Minimum_English__c);
        
        Test.stopTest();
        
        System.assert( intf.jsonRequest!=null,   'Test unsuccessful');
    }
    
    @isTest
    static void testLOIEnglishScoreWithoutPersonID()
    {
        Test.startTest();
       
        Contact applicant = StudFirst_TestHelper.createApplicant();
        applicant.Person_ID_unique__c = null;
        insert applicant;

        // Create application
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        application.Callista_Applicant_Id__c = '0030k000001tbfEAAQ';
        application.English_Entry_Mode__c ='Country of secondary schooling / graduation';
        application.Meets_Minimum_English__c = 'No';

        insert application;

        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        // Create Course Preferences
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(application, applicant, courseOffering, course);
        insert coursePreference;
        
        application.Meets_Minimum_English__c = 'Yes';
        update application;


        ObdLOIEnglishInterface.fireOutboundRequest( application.Id, 'English Language Instruction in secondary school', 'Yes');
        Test.stopTest();

       System.assertEquals([SELECT Applicant__r.Person_ID_unique__c FROM APPLICATION__c WHERE ID=:application.Id].Applicant__r.Person_ID_unique__c, null);

    }

}