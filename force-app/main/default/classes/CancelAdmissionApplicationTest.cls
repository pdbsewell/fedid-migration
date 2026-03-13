@isTest
public class CancelAdmissionApplicationTest {
    TestMethod
    private static void cancelApplication()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
            
        System.runAs(applicant)
        {
            // create application
            Application__c application = StudFirst_TestHelper.createApplication(c.Id);
            insert application;
    
            // Course
            Course__c course = StudFirst_TestHelper.createCourse();
            insert course;
    
            // offering
            Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
            insert offering;
    
            // create ACP
            Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
            insert acp;
            
            // create Cd
            Contact_Document__c cd = StudFirst_TestHelper.createContactDocument(c.Id);
            insert cd;
            
            // create Qualification
            Qualification__c qual = StudFirst_TestHelper.createQualification('English');
            insert qual;
            
            // Create Contact Qualifications
            Contact_Qualification__c contactQual = StudFirst_TestHelper.createContactQualification(c, qual, 'English Test');
            insert contactQual;
            
            Application_Qualification_Provided__c appQualProvided = StudFirst_TestHelper.createAppQualProvided(application.id, contactQual.id);
            insert appQualProvided;
            /*
            List<ContentDocument> fileList = [SELECT id FROM ContentDocument];
            System.assertEquals(0, fileList.size(), 'fileList is not deleted');
            
            
            // Create a file
            ContentDocument file = FileUploadController_Test.createTestDocument(true);
            String docTypeValue = FileUploadController_Test.getDocumentTypeValue(0);
            String docSubType = '';
            String comments = 'testing some comments ';
            Map<String, Object> mapResults = FileUploadController.saveFileAndContactDocument(file.Id, c.Id, application.Id, docTypeValue, docSubType, comments);
            */
        
            List<application__c> appList = [SELECT id FROM application__c where applicant__c = :c.id];
            System.assertEquals(1, appList.size(), '1) appList is not created');
            
            List<Application_Course_Preference__c> acpList = [SELECT id FROM Application_Course_Preference__c where applicant__c = :c.id];
            System.assertEquals(1, acpList.size(), '1) acpList is not created');
            
            List<Contact_Qualification__c> conQualList = [SELECT id FROM Contact_Qualification__c where contact__c = :c.id];
            System.assertEquals(1, conQualList.size(), '1) conQualList is not created');
            
            List<Contact_Document__c> conDocList = [SELECT id FROM Contact_Document__c where contact__c = :c.id];
            System.assertEquals(1, conDocList.size(), '1) conDocList is not created');
            
            Test.startTest();
            // Cancel the application
            appHomeDraftCC.cancelApplication(application);
            Test.stopTest();
            // Process builder will run and will delete the apps and acps and contact children
            
            appList = [SELECT id FROM application__c where applicant__c = :c.id];
            System.assertEquals(0, appList.size(), '2) appList is not deleted');
            
            acpList = [SELECT id FROM Application_Course_Preference__c where applicant__c = :c.id];
            System.assertEquals(0, acpList.size(), '2) acpList is not deleted');
            
            conQualList = [SELECT id FROM Contact_Qualification__c where contact__c = :c.id];
            System.assertEquals(0, conQualList.size(), '2) conQualList is not deleted');
        }
    }
}