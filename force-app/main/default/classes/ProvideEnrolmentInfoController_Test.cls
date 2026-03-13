/**
* @author Inderpal Dhanoa
* @date 10.Feb.2024
* @group Test Class
* @description  Test Class to test the functionality of Provide Enrolment Info
*/
@IsTest (isParallel=true) 
public with sharing class ProvideEnrolmentInfoController_Test {
    @testSetup static void setup() {
        // Create Contact
        Contact relStudent = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'FirstStudentName ProvideEnrolment', Campus__c = 'Caulfield' ,LastName ='LastName', Email = 'FirstStudentName3456@test.com'), true);

        // Create Enquiry
        Case relEnq = (Case)TestDataFactory.createSObject(new Case(ContactId = relStudent.Id, Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
        Category_Level_2__c = 'Welfare meetings', Enquiry_Type__c = 'Current Course', Details__c = 'Test Details',Category_Level_1__c = 'Under 18s'), true);
        
    }

    @isTest static void testSubmitEnquiryDetails() {
        // GIVEN : The Enquiry exists
        Case testEnq = [SELECT Id, Rich_Description__c FROM Case WHERE Contact.FirstName='FirstStudentName ProvideEnrolment' ORDER By CreatedDate DESC LIMIT 1];
        // WHEN : Update the Rich_Description__c field
        Test.startTest();
        ProvideEnrolmentInfoController.submitEnquiryDetails('Test Details', 'Faculty of Arts', 'Unit discontinuation', '111', 'Test Details', String.valueOf(testEnq.Id));
        Test.stopTest();
        
        // THEN: The Rich Desc field will be updated
        testEnq = [SELECT Id, Rich_Description__c FROM Case WHERE Contact.FirstName='FirstStudentName ProvideEnrolment'  ORDER By CreatedDate DESC LIMIT 1];
        system.assertEquals(String.valueOf(Label.MC_Enrolment_Details), testEnq.Rich_Description__c, 'UPdate failed error');
    }

    @isTest static void testRetrieveEnquiryDetails() {
        // GIVEN : The Enquiry exists
        Case testEnq = [SELECT Id, Rich_Description__c FROM Case WHERE Contact.FirstName='FirstStudentName ProvideEnrolment' ORDER By CreatedDate DESC LIMIT 1];
        // WHEN : Retrieve Enquiry
        Test.startTest();
        ProvideEnrolmentInfoController.EnquiryWrapper obj = ProvideEnrolmentInfoController.retrieveEnquiryDetails(String.valueOf(testEnq.Id));
        Test.stopTest();
        
        // THEN: The deatils 
        testEnq = [SELECT Id, Details__c FROM Case WHERE Contact.FirstName='FirstStudentName ProvideEnrolment'  ORDER By CreatedDate DESC LIMIT 1];
        system.assertEquals('Test Details', obj.details, 'UPdate failed error');
    }
}