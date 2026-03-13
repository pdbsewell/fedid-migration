/**
 * @author          inderpal.dhanoa@monash.edu
 * @description		MCT-425 LivePerson Enquiry routing
 * @date            Jul.2024
 * @group			Monash COnnect
 * Revision
 * 1.1   31.07.2024   Idhanoa     test Class for Flow - Case : AU : Genesys Cloud Routing for Case Update
*/
@isTest(IsParallel=true)
public with sharing class Case_AI_Genesys_Cloud_Routing_FT {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         31/07/2024
    * @description  Test Method for Flow Case_AU_GenesysCloudRtngforCaseUpdate_Flow  
    * @revision     1.0
    *******************************************************************************/
    @isTest
    static void test_Case_AI_Genesys_Cloud_Routing_Flow() {

        // Contact creation
        Contact relStudent = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'FirstStudentName', Campus__c = 'Caulfield' ,LastName ='LastName', Email = 'FirstStudentName@test.com'), true);

        Id monConCurrentQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Monash_Connect_Current_Student'].Id;

        //GIVEN: The pre-defined genesy enabled Queues should be created 
        Test.startTest();
        //WHEN: The Enquiry is created for one of the Genesys enabled Queues
        Case routingEnq = (Case)TestDataFactory.createSObject(new Case(ContactId = relStudent.Id, Subject = 'TEST LivePersonLinkedEnquiries_FT',Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
        OwnerId = monConCurrentQueue, Category_Level_2__c = 'Welfare meetings', Enquiry_Type__c = 'Current Course', Category_Level_1__c = 'Under 18s'), true);
        Test.stopTest();

        //THEN: A GeneSys Routing Entry record is created
        List<purecloud__PureCloud_Routing_Request__c> routingEntry = [SELECT Id, purecloud__Salesforce_Object_ID__c 
                                                                        FROM purecloud__PureCloud_Routing_Request__c 
                                                                        WHERE purecloud__Salesforce_Object_ID__c = :routingEnq.Id];
        Assert.areEqual(routingEntry.size(), 1, 'Routing ENtry not created for Flow : Case_AI_Genesys_Cloud_Routing');
    }
}