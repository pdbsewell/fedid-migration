/**
 * @author          inderpal.dhanoa@monash.edu
 * @description		MCT-508 Enquiry auto-close management for GeneSys Enquiries
 * @date            Aug.2024
 * @group			Monash Connect
 * Revision
 * 1.1   04.09.2024   Idhanoa     test Class for Flow - Terminate Genesys CloudRouting
*/
@isTest(IsParallel=true)
public class Case_AU_Termnte_Genesys_Cloud_Routing_FT {
    @testSetup
    static void setup() {
        // Contact creation
        Contact relStudent = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'FirstStudentName', Campus__c = 'Caulfield' ,LastName ='LastName', Email = 'FirstStudentName@test.com'), true);

        // Create Enquiry
        Case relEnq = (Case)TestDataFactory.createSObject(new Case(ContactId = relStudent.Id, Subject = 'TEST LivePersonLinkedEnquiries_FT',Status = 'Open', 
                                                                    RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
                                                                    Bypass_Case_Assignment__c = true,  Category_Level_2__c = 'Welfare meetings', 
                                                                    Enquiry_Type__c = 'Current Course', Category_Level_1__c = 'Under 18s'), true); //OwnerId = futurequeueId,
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/07/2024
    * @description  Test Method for Flow Enquiry Terminate Genesys CloudRouting  
    * @revision     1.0
    *******************************************************************************/
    @isTest
    static void test_Case_AU_Terminate_Genesys_Cloud_Routing_Flow() {
        // GIVEN : When the LP record exists
        Case genEnq = [SELECT Id, OwnerId FROM CASE WHERE Subject = 'TEST LivePersonLinkedEnquiries_FT' ORDER BY CreatedDate DESC LIMIT 1];
        Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Monash Connect Current Student'].Id;
        
        Test.startTest();
        //WHEN : the Enq record is updated
        genEnq.OwnerId = queueId;
        update genEnq;
        Test.stopTest();
        // THEN: The Routing record is created
        List<purecloud__PureCloud_Routing_Request__c> linkedRoutingReq = [SELECT Id, purecloud__Salesforce_Object_ID__c FROM purecloud__PureCloud_Routing_Request__c 
                                                                              WHERE purecloud__Salesforce_Object_ID__c = :genEnq.Id ORDER BY CreatedDate DESC];
        Assert.areEqual(linkedRoutingReq.size(), 1, 'Expected value missing');
    }
}