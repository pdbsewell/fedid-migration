/*******************************************************************************
* @author		Inderpal Dhanoa
* @date         21/08/2024    
* @description  test class for AlumniEnquiryHandler.cls
*******************************************************************************/
@IsTest(isParallel=true)
public with sharing class AlumniEnquiryHandler_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         21/11/2024
    * @description  Test Method for SubmitAlumniEnquiryCntlr createEnquiry Method  
    * @revision     1.0
    *******************************************************************************/
   @isTest 
   public static void createEnquiryTest(){
     
    //GIVEN: The Commmunity URL creates the Recd
    Test.startTest(); 
    //WHEN: The trigger is invoked 
    Alumni_Enquiry__c alumniEnq = new Alumni_Enquiry__c();
    alumniEnq.Description__c = 'test Descpr';
    alumniEnq.Enquiry_Type__c = 'Test Enq Type';
    alumniEnq.Rich_Description__c = 'test rich subject';
    alumniEnq.Subject__c = 'Alumni Portal Enquiry';
    alumniEnq.SuppliedEmail__c = 'yest@test.com';
    insert alumniEnq;

    Test.stopTest();
    // THEN: The Enquiry is created
    Case enq = [SELECT Id, Subject FROM Case 
                        WHERE Subject = 'Alumni Portal Enquiry'
                        AND SuppliedEmail = 'yest@test.com' 
                        AND RecordTypeId = :Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Alumni_Engagement').getRecordTypeId() 
                        ORDER BY CreatedDate DESC LIMIT 1];
    Assert.areEqual(enq.Subject, alumniEnq.Subject__c, 'Enquiry creation failed');
   }
}