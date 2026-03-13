/**
 * @author Ibrahim Rumi
 * @date 30-08-2021
 * @group Event Management
 * @description Test class for BTSharePurgeBatch
 **/
@isTest(isParallel=true)
public class BTSharePurgeBatch_Test {
    
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
        
        //create blackthorn attendee
        List<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendee(btEventList[0].Id, 1);
        TriggerCommon.disableTrigger('conference360__Attendee__c');
		insert attendeeList;
        TriggerCommon.enableTrigger('conference360__Attendee__c');
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        System.runAs(thisUser) {
            //create Test users with Base Profile
            TestHelper.createTestUsers('Base Profile', 1);
        }
        
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1];
        
        Conference360__Staff__c staff = new conference360__Staff__c(conference360__User__c=u.Id,conference360__Event__c=btEventList[0].Id);
        
        Insert staff;
    }
    
    /*
    * Test batch class to delete sharing records for the event and related objects
    */
    @isTest
    public static void staffSharePurgeBatchTest(){
        
        
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1];
        set<Id> userset = new set<Id>{u.Id};
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
       	Map<Id,set<Id>>userSetByEventMap = new Map<Id,set<Id>>();
        userSetByEventMap.put(eve.id,userset);
        
        List<conference360__Event__share> sharerec = [SELECT parentid FROM conference360__Event__share
                                             WHERE parentid =: eve.Id AND UserOrGroupId =: u.Id];
        
        System.assert(sharerec.size() > 0);
        
        Test.startTest();
        
         	Database.executeBatch(new BTSharePurgeBatch(userSetByEventMap));
		Test.stopTest();
        
        List<conference360__Event__share> deletedsharerec = [SELECT parentid FROM conference360__Event__share
                                             WHERE parentid =: eve.Id AND UserOrGroupId =: u.Id];
        
        System.assert(deletedsharerec.size() == 0);
    }
}