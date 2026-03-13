/**
 * @File Name          : AsyncProcessTriggerHandler_Test.cls
 * @Description        : Test class for AsyncProcessTriggerHandler.cls
 * @Author             : Nick Guia
 * @Group              : Commons
 * 
 * 14/06/2024 - Martin Cadman - Added an assert on event publishing
 **/
@isTest(isParallel=true)
private class AsyncProcessTriggerHandler_Test {

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
		Async_Process__e ap = new Async_Process__e (
			Process_Name__c = 'EmailServices.CalculatePrimary',
			Parameter__c = payload.serialize()
			);

		Test.startTest();
        EventBus.publish(ap);
        Test.getEventBus().deliver();
        
        EventBusSubscriber[] subscribers = queryBus('Async_Process__e');
        for (EventBusSubscriber sub : subscribers) { 
            Assert.areEqual('AsyncProcessTrigger', sub.Name);
        }        
        Test.stopTest();
	}
   
    static List<EventBusSubscriber> queryBus(String ibdObject) {
        List<EventBusSubscriber> bus = new List<EventBusSubscriber>();
        try {
            bus = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic=:ibdObject];
        } catch(Exception e) {
            return new List<EventBusSubscriber>();
        }
        return bus;
    }
}