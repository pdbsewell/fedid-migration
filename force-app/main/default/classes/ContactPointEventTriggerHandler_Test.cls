/**
 * @description       : Test class for trigger handler class for Contact_Point__e platform events.
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2020-10-15
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-10-15   Stefan Scheit   Initial Version, copied from AsyncProcessTriggerHandler_Test
**/
@isTest(isParallel=true)
private class ContactPointEventTriggerHandler_Test {

	@TestSetup
	static void setup() {
		List<Contact> conList = TestHelper.createProspectiveStudentContact(1);
		insert conList;
	}

	@IsTest
	static void testDispatch() {
		Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 100]);
		Set<Id> conIdSet = conMap.keySet();

		AsyncProcessPayload payload = new AsyncProcessPayload();
		payload.put('contactIds', conIdSet);
		Contact_Point_Event__e ap = new Contact_Point_Event__e (
			Process_Name__c = 'EmailServices.CalculatePrimary',
			Parameter__c = payload.serialize()
			);

		Test.startTest();
		EventBus.publish(ap);
		Test.stopTest();
	}

	@IsTest
	static void testDispatchNegative() {
		Contact_Point_Event__e ap = new Contact_Point_Event__e (
			Process_Name__c = 'EmailServices.CalculatePrimary',
			Parameter__c = 'randomcharacter3456789sgwgg'
			);

		Test.startTest();
		EventBus.publish(ap);
		Test.stopTest();
    }
}