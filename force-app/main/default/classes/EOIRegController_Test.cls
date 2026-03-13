/**
@author Shalini Mendu
@date 22 June 2018
@group Professional Development
@description Sibling test class for EOIRegController
@revision 22 April 2021 - Cartick Sub - PRODEV-683 - Improve tests
**/

@isTest
public class EOIRegController_Test {
    
    /**
    @description Validates that an Applicant can successfully submit an EOI for a Course Offering
    @revision 22 April 2021 - Cartick Sub - PRODEV-683 - Add assertions
    **/
    @isTest
    public static void validateRegisterApplicant() {
        
        // Create Course Offering in which Applicant is interested
        Course__c course = PDTestHelper.createCourse();
        Course_Offering__c co = PDTestHelper.createCourseOfferingForCourse(course);
        Course_Offering__c coRec = [SELECT Id, Name FROM Course_Offering__c];

        // Set up sample EOI form input
        String salutation = 'Mr';
        String firstName = 'Daniel';
        String lastName = 'Pitt';
        String jtitle = 'General manager';
        String organisation = 'Monash';
        String phone = '0414614234';
        String email = 'danielpitt@gmail.com';
        String hearfrom = 'Internet';
        
        Test.startTest();
        List<String> results = EOIRegController.register(salutation,  firstName,  lastName, jtitle,  organisation, phone,   email,  hearfrom, coRec.Name);
        Test.stopTest();

        // Check that the registration successfully created an Enquiry, Application and Contact
        System.assert(String.isNotBlank(results[0]), 'Enquiry not created');
        System.assert(String.isNotBlank(results[1]), 'Application not created'); 
        System.assert(String.isNotBlank(results[2]), 'Contact not created'); 

    }

    /** 
    @description Validates that the EOI form can successfully retrieve Contact Salutation picklist option labels
    @revision 22 April 2021 - Cartick Sub - PRODEV-683 - Add assertions
    **/
    @isTest
    public static void validateRetrieveSalutations() {
        
        Test.startTest();
        List<String> salutationResults = EOIRegController.retrieveSalutations();
        Test.stopTest();

        // Confirm that some labels were retrieved
        System.assert(!salutationResults.isEmpty(), 'Contact Salutation picklist option labels not retrieved');
    }

    /** 
    @description Validates that the EOI form can successfully retrieve Enquiry Heard About From picklist option labels
    @revision 22 April 2021 - Cartick Sub - PRODEV-683 - Add assertions
    **/
    @isTest
    public static void validateRetrieveHeardFrom() {
        
        Test.startTest();
        List<String> heardFromResults = EOIRegController.retrieveHeardFrom();
        Test.stopTest();

        // Confirm that some labels were retrieved
        System.assert(!heardFromResults.isEmpty(), 'Enquiry \'Heard About From\' picklist option labels not retrieved');
    }
}