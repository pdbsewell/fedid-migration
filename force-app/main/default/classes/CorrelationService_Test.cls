/**
 * @description      : Test class for CorrelationService
 * @author            : Angelo Rivera
 * @group             : Test Class
 * @last modified on  : 04-10-2021
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   21-10-2021 - Angelo Rivera - Initial Creation
**/

@IsTest(IsParallel=true)
private class CorrelationService_Test {

    @IsTest
    static void testCorrelationService() {

        Contact testContact = (Contact) MonConTestDataFactory.createSObject(new Contact(), true);

        // GIVEN a case is created/updated
        List<Case> lstCases = new List<Case>();
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Special_Consideration').getRecordTypeId();
        Case cse = new Case();
        cse.SuppliedEmail = 'testEmail@test.edu';
        cse.Enquiry_Type__c = 'Vaccinate Monash - Staff';
        cse.Category_Level_1__c = 'COVID-19 Vaccination Proof';
        cse.Category_Level_2__c = 'COVID Certificate';
        cse.RecordTypeId = caseRecType;
        cse.ContactId = testContact.Id;
        cse.Status = 'Solved';
        cse.Case_Outcome__c = 'Approved Vaccination Certificate';
        lstCases.add(cse);

        Test.startTest();
        // WHEN the condition to trigger a flow (which sends an event) are met
        insert lstCases;
        Test.getEventBus().deliver();

        // THEN a platform event is created
        EventBusSubscriber[] subscribers =  [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic='Obd_CAMS__e'];
        System.assertNotEquals(subscribers.size(), null);

        // Testing Inbound
        String ret = CorrelationService.updateData( lstCases.get(0).Id, 'Ok', 'Test Message');
        System.assertEquals(ret, 'Success');

        // Checking inbound message successfully updated Case
        Case c = [SELECT Id, Integration_Status__c FROM Case LIMIT 1];
        System.assertEquals(c.Integration_Status__c, 'Test Message');

        String ret1 = CorrelationService.updateData( null, 'Ok', 'test message');
        System.assertEquals(ret1, 'Error');

        String ret2 = CorrelationService.updateData( '0032O00000GL4AfQAL', 'Ok', 'test message');
        System.assertEquals(ret2, 'Error');

        Test.stopTest();
    }
}