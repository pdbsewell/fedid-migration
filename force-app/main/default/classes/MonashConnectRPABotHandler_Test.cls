@isTest(isParallel=true)
private with sharing class MonashConnectRPABotHandler_Test {

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         15.June.2023
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {
        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(Email='testcontact@test.com'), true);

        Case testCase = (Case)MonConTestDataFactory.createSObject(new Case(RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
                        Enquiry_Type__c = 'Current Course', Category_Level_1__c = 'International Visa', Category_Level_2__c = 'Change of Residency', ContactId = testContact.Id, Status = 'Opened'), true);
    }
    @IsTest
    static void UpdateEnquiryStatus_Test() {
        // GIVEN: A Case exists
        List<Case> l_linkedCase = [SELECT Id FROM Case WHERE Contact.Email = 'testcontact@test.com' ORDER BY CreatedDate DESC LIMIT 1];
        AsyncProcessPayload payload = new AsyncProcessPayload();
		payload.put('CaseId', l_linkedCase[0].Id);
        payload.put('CaseStatus', 'Failed');
        payload.put('CommentBody', 'This is a sample comment.');
		Async_Process__e ap = new Async_Process__e (
			Process_Name__c = 'MonashConnectRPABotHandler.UpdateEnquiryStatus',
			Parameter__c = payload.serialize()
		);
        EventBus.publish(ap);

		Test.startTest();
        // WHEN: A Platform Event is fired
		
        Test.getEventBus().deliver();
        
		Test.stopTest();
        // THEN: Case is updated and comment added
        l_linkedCase = [SELECT Id, Status FROM Case WHERE Contact.Email = 'testcontact@test.com' ORDER BY CreatedDate DESC LIMIT 1];
        system.assertEquals('Opened', l_linkedCase[0].Status);

        List<CaseComment> l_linkedCaseComment = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :l_linkedCase[0].Id ORDER BY CreatedDate DESC LIMIT 1];
        system.assertEquals('This is a sample comment.', l_linkedCaseComment[0].CommentBody);

    }
}