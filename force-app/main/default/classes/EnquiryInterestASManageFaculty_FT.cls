/**
 * @description       : Test class for Enquiry Interest: AS : Manage Faculty Flow.
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 05-05-2025
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(isParallel=true)
private with sharing class EnquiryInterestASManageFaculty_FT {
    
    @isTest
    static void CopyCourseFacToManFac_Test(){
		
        // GIVEN : Create Contact and Case.
        Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
		Case oCase = (Case)MonConTestDataFactory.createSObject(new Case());
		oCase.ContactId = con.Id;
		oCase.Enquiry_Type__c = 'Future Course';
		insert oCase;
        
        //.. Create Course
        List<course__c> courses = TestHelper.createCourses(1);
        courses[0].name = '123445';
        courses[0].Managing_Faculty__c = 'Engineering';
        insert courses;

        //.. Create Enquiry Interest
        Enquiry_Interest__c enquiryInterest = (Enquiry_Interest__c)MonConTestDataFactory.createSObject(new Enquiry_Interest__c());
		enquiryInterest.Study_Area__c = 'Engineering';
		enquiryInterest.Course__c = courses[0].Id;
		enquiryInterest.Case__c = oCase.Id;
        
        // WHEN : insert Enquiry Interest record.
        Test.startTest();
		insert enquiryInterest;
        Test.stopTest();
        
        // THEN : Validate Managing Faculty is updated.
        Enquiry_Interest__c oEI = [SELECT Id, Managing_Faculty__c FROM Enquiry_Interest__c LIMIT 1];
        Assert.areNotEqual(oEI.Managing_Faculty__c, null, 'Managing Faculty field is updated');
    } 

    @isTest
    static void CopyFacultyPLToManFaculty_Test(){

        // GIVEN : Create Contact and Case.
        Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
		Case oCase = (Case)MonConTestDataFactory.createSObject(new Case());
		oCase.ContactId = con.Id;
		oCase.Enquiry_Type__c = 'Future Course';
		insert oCase;
        
        //.. Create Enquiry Interest
        Enquiry_Interest__c enquiryInterest = (Enquiry_Interest__c) MonConTestDataFactory.createSObject(new Enquiry_Interest__c());
		enquiryInterest.Faculty_PickList__c = 'Engineering';
		enquiryInterest.Study_Area__c = 'Engineering';
        enquiryInterest.Case__c = oCase.Id;
        
        // WHEN : insert Enquiry Interest record.
        Test.startTest();
		insert enquiryInterest;
        Test.stopTest();       
        
        // THEN : Validate Managing Faculty is updated.
        Enquiry_Interest__c oEI = [SELECT Id, Managing_Faculty__c FROM Enquiry_Interest__c LIMIT 1];
        Assert.areNotEqual(oEI.Managing_Faculty__c, null, 'Managing Faculty field is updated');
    } 
}