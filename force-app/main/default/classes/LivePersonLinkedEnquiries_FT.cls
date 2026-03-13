/**
 * @author          inderpal.dhanoa@monash.edu
 * @description		MCT-433 Enquiry auto-close management for Idle Enquiries (LivePerson)
 * @date            Jul.2022
 * @group			Student Administration
 * Revision
 * 1.1   11.06.2024   Idhanoa     test Class for Flow - Live Person Chat Transcript : AU : Sync linked Enquiries
*/
@isTest(IsParallel=true)
public class LivePersonLinkedEnquiries_FT {
    @testSetup
    static void setup() {
        // Contact creation
        Contact relStudent = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'FirstStudentName', Campus__c = 'Caulfield' ,LastName ='LastName', Email = 'FirstStudentName@test.com'), true);

        // Create Enquiry
        Case relEnq = (Case)TestDataFactory.createSObject(new Case(ContactId = relStudent.Id, Subject = 'TEST LivePersonLinkedEnquiries_FT',Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
                                    Category_Level_2__c = 'Welfare meetings', Enquiry_Type__c = 'Current Course', Category_Level_1__c = 'Under 18s'), true);

        //Create Live Chat 
        Live_Person_Chat_Transcript__c relLivePrsn = (Live_Person_Chat_Transcript__c)TestDataFactory.createSObject(new Live_Person_Chat_Transcript__c(Enquiry__c = relEnq.Id, 
                                    Ended_By__c = 'User'), true);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/07/2024
    * @description  Test Method for Flow Enquiry auto-close management for Idle Enquiries (LivePerson)  
    * @revision     1.0
    *******************************************************************************/
    @isTest
    static void test_LivePersonChatTranscriptAU_Sync_linked_Enquiries_Flow() {
        // GIVEN : When the LP record exists
        Live_Person_Chat_Transcript__c lp = [SELECT Id, Ended_By__c FROM Live_Person_Chat_Transcript__c 
                                            WHERE Enquiry__r.Subject = 'Test LivePersonLinkedEnquiries_FT' ORDER BY CreatedDate DESC LIMIT 1];
        lp.Ended_By__c = 'Auto-close';
        
        Test.startTest();
        //WHEN : the LP record is updated
        update lp;
        Test.stopTest();
        // THEN: The linked Enquiry field is updated
        Case linkedEnq = [SELECT Id, LivePerson_User_Auto_Closed__c FROM Case 
                                            WHERE Subject = 'Test LivePersonLinkedEnquiries_FT' ORDER BY CreatedDate DESC LIMIT 1];
        Assert.areEqual(linkedEnq.LivePerson_User_Auto_Closed__c, 'Auto-close', 'Expected value missing');
    }
}