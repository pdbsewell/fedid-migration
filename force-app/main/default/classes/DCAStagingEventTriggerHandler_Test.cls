/**
 * @description       : Test class for trigger handler class for DCAStagingEvent__e platform events.
 * @author            : Sachin Shetty
 * @group             : Test
 * @last modified on  : 2022-06-09
 * @last modified by  : Sachin Shetty
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2022-06-09   Sachin Shetty   Initial Version
**/
@isTest
public class DCAStagingEventTriggerHandler_Test {
    
    @IsTest
	static void testDispatchEvent() {

        // Given
        List<Contact> contacts = new List<Contact>{
            new Contact(
                FirstName = 'John',
                LastName = 'Doe'
            ),
            new Contact(
                FirstName = 'Jane',
                LastName = 'Doe'
            )
        };
        insert contacts;
        Set<Id> contactIds = (new Map<Id, Contact>(contacts)).keySet();

		List<DCAStagingEvent__e> stagingEvents = new List<DCAStagingEvent__e>{
            new DCAStagingEvent__e(
                primaryContactId__c = contacts.get(0).Id
            ),
            new DCAStagingEvent__e(
                primaryContactId__c = contacts.get(1).Id
            )
        };

        // When
		Test.startTest();
		    EventBus.publish(stagingEvents);
		Test.stopTest();

        List<DCAStaging__c> stagingRecords = [SELECT bulkProcessed__c,primaryContactId__c FROM DCAStaging__c];

        //Then
        System.assertEquals(2, stagingRecords.size(), 'Incorrect number of records created');
        for(DCAStaging__c stagingRecord : stagingRecords){
            System.assertEquals(true, stagingRecord.bulkProcessed__c, 'Incorrect value in bulkProcessed');
            System.assert(contactIds.contains(stagingRecord.primaryContactId__c) , 'Incorrect value in primaryContactId');
        }
    }
}