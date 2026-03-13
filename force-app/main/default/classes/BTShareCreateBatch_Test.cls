/**
 * @description  : Test class for BTShareCreateBatch
 * @author       : Ibrahim Rumi
 * @group        : Event Management
 * @date         : 30-08-2021
 * @revision 
 * Ver   Date         Author         Modification
 * 1.0   05-10-2021   Ibrahim Rumi   New Test Method to test sharing of guest records
**/
@isTest(isParallel=true)
public class BTShareCreateBatch_Test {

    @TestSetup
    public static void makedata(){
	
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        for(conference360__Event__c event:btEventList){
            event.conference360__Event_End_Date__c = Date.Today().addDays(10);
            event.conference360__Event_End_Time__c = Time.newInstance(1, 0, 0, 0);
        }
        TriggerCommon.disableTrigger('conference360__Event__c');
        insert btEventList;
        TriggerCommon.enableTrigger('conference360__Event__c');
        
        //create blackthorn event attendee group
       	conference360__Attendee_Group__c attendee_Group = new conference360__Attendee_Group__c(
        	Name = 'BTAttendeeTriggerHandler_Test_Attendee_group'
        );
        insert attendee_Group;
        
        //create blackthorn event items
        List<conference360__Event_Item__c> btEventItems = new List<conference360__Event_Item__c>();
        conference360__Event_Item__c  eventItem = new conference360__Event_Item__c(
        	conference360__Item_Name__c  = 'Primary Attendee',
            conference360__Type__c  = 'Main event ticket',
            conference360__Minimum_Quantity__c  = 1,
            conference360__Maximum_Quantity__c  = 1,
            conference360__Event__c = btEventList[0].Id
        );
        btEventItems.add(eventItem);
        
        conference360__Event_Item__c  eventItemGuest = new conference360__Event_Item__c(
            conference360__Item_Name__c  = 'Guest Attendee',
            conference360__Type__c  = 'Guest',
            conference360__Minimum_Quantity__c  = 0,
            conference360__Maximum_Quantity__c  = 10,
            conference360__Event__c = btEventList[0].Id
        );
        btEventItems.add(eventItemGuest);
        insert btEventItems;
        
        //create blackthorn attendee
        List<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendee(btEventList[0].Id, 2);
        TriggerCommon.disableTrigger('conference360__Attendee__c');
		for(Integer i = 0; i < 2; i++) {
        	conference360__Attendee__c att = attendeeList[i];
            att.conference360__Attendee_Group__c = attendee_Group.Id;
            att.conference360__Event_Item__c = btEventItems[i].Id;
        }
        insert attendeeList;
        TriggerCommon.enableTrigger('conference360__Attendee__c');
        
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        System.runAs(thisUser) {
            //create Test users with Base Profile
            TestHelper.createTestUsers('Base Profile', 2);
        }
    }
    
    /*
     * Test batch class to create sharing records for the event
     */
    @isTest
    public static void staffShareCreateBatchTest(){
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1];
        set<Id> userset = new set<Id>{u.Id};
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
       	Map<Id,set<Id>>userSetByEventMap = new Map<Id,set<Id>>();
        userSetByEventMap.put(eve.id,userset);
        
        Test.startTest();
        	Database.executeBatch(new BTShareCreateBatch(userSetByEventMap));
		Test.stopTest();
        
        List<conference360__Event__share> evesharerec = [SELECT parentid FROM conference360__Event__share
                                             WHERE parentid =: eve.Id AND UserOrGroupId =: u.Id];
        System.assert(evesharerec.size() > 0);
    }
    
     /*
     * Test batch class to create sharing records for event with Guest Attendees
     */
    @isTest
    public static void staffShareCreateBatchWithGuestAttendeesTest(){
        
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        List<conference360__Attendee__c> attendeeList = [SELECT id FROM conference360__Attendee__c WHERE conference360__Event__c =:eve.Id];
        
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1];
        set<Id> userset = new set<Id>{u.Id};
       	Map<Id,set<Id>>userSetByEventMap = new Map<Id,set<Id>>();
        userSetByEventMap.put(eve.id,userset);
        
        Test.startTest();
        	Database.executeBatch(new BTShareCreateBatch(userSetByEventMap));
		Test.stopTest();
        
        List<conference360__Attendee__share> attShareRec = [SELECT parentid FROM conference360__Attendee__share
                                             WHERE parentid IN: attendeeList AND UserOrGroupId =: u.Id];
        System.assertEquals(1,attShareRec.size(),'non primary attendee also shared');
    }
}