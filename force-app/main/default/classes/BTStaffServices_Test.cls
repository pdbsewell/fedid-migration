/**
 * @author Ibrahim Rumi
 * @date 30-08-2021
 * @group Event Management
 * @description Test class for BTStaffTriggerHandler
 * @revision
 * Ver   Date         Author         Modification
 * 1.0   04-10-2022   Ibrahim Rumi   added manageEventStaffForGroupTest and getExistingStaffRecordSet to test event group staff functionality
 **/
@isTest(isParallel=true)
public class BTStaffServices_Test {
@TestSetup
    public static void makedata(){

        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(2);
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
            TestHelper.createTestUsers('Base Profile', 2);
        }
        
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1];
        
        TriggerCommon.disableTrigger('conference360__Staff__c');
        List<Conference360__Staff__c> stafflist = new List<Conference360__Staff__c>(); 
        for(Integer i=0;i<btEventList.size();i++){
            Conference360__Staff__c staff = new conference360__Staff__c(conference360__User__c=u.Id,conference360__Event__c=btEventList[i].Id);
            stafflist.add(staff);
        }
        Insert stafflist;
        TriggerCommon.enableTrigger('conference360__Staff__c');

    }
    
    /*
     * Test Fetching child records of events
     */
    @isTest
    public static void getEventChildRecordsMapTest(){
        Set<id>eventIdSet = new Map<Id,conference360__Event__c>([select id FROM conference360__Event__c LIMIT 1]).keyset();
        map <Id,conference360__Event__c> eventmap = new map <Id,conference360__Event__c>();
        Test.startTest();
        	eventmap = new BTStaffServices().getEventChildRecordsMap(eventIdSet);
        Test.stopTest();
		System.assert(eventmap.size()>0);    
    }
    
    /*
     * Test Permission set group assignment
     */
    @isTest
    public static void existingPermSetGroupTest(){
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1];
        Id permissionSetGroupId = [SELECT id FROM PermissionSetGroup Where DeveloperName = 'Blackthorn_Check_In'][0]?.Id;
        Date expirydate = Date.Today().addDays(7); 
        
        PermissionSetAssignment psg = new PermissionSetAssignment();
        psg.AssigneeId = u.Id;
        psg.ExpirationDate = expirydate;
        psg.PermissionSetGroupId = permissionSetGroupId;
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        System.runAs(thisUser) {
        	insert psg;
        }
        
        Set<id> userset = new set<Id>{u.Id};
        Test.startTest();
        	BTStaffServices.autoExpiringPermissionSetGroupAssignment(userset);
        Test.stopTest();
        List<PermissionSetAssignment> psgList = [SELECT Id FROM PermissionSetAssignment WHERE assigneeId =: u.Id];
            System.assert(psgList.size()>0);
    }
    
    /*
     * Test Permission set group assignment based on event
     */
    @isTest
    public static void autoExpiringPermissionSetGroupAssignmentTest(){
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1];
        set<Id> userset = new set<Id>{u.Id};
            
        Test.startTest();
        	BTStaffServices.autoExpiringPermissionSetGroupAssignment(userset);
        Test.stopTest();
            List<PermissionSetAssignment> psgList = [SELECT Id FROM PermissionSetAssignment WHERE assigneeId =: u.Id];
            System.assert(psgList.size()>0);
    }
    
    /*
     * Test if user is an existing staff
     */
    @isTest
    public static void isExistingStaffTest(){
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1];
        List<Conference360__Staff__c> staffList = [SELECT id,Conference360__User__c FROM Conference360__Staff__c];
        
        Test.startTest();
        	Boolean isexisting = new BTStaffServices().isExistingStaff(u.Id,staffList);
        Test.stopTest();
        
        System.assertEquals(isexisting,true);
    }
    
    /*
     * Test fetching share info
     */
    @isTest
    public static void getShareInfoTest(){
        conference360__event__c eve = new conference360__event__c();
        conference360__attendee__c att = new conference360__attendee__c();
        
        BTStaffServices.shareObjectInfo eveShareInfo = new BTStaffservices().getShareInfo(eve);
        BTStaffServices.shareObjectInfo attendeeShareInfo = new BTStaffservices().getShareInfo(att);
        
        System.assertEquals(eveShareInfo.evntFilterField,'Id');
        System.assertEquals(attendeeShareInfo.evntFilterField,'conference360__event__c');
        
    }
    
    /*
     * Test Managing event staffs automatically when an Event Group is added/updated/deleted
     */
    @isTest
    public static void manageEventStaffForGroupTest(){
        //given
        //adding new event groups
        List<conference360__Event_Group__c> groups = new List<conference360__Event_Group__c>();
        groups.add(new conference360__Event_Group__c(Name='Event Group 1'));
        groups.add(new conference360__Event_Group__c(Name='Event Group 2'));
        insert groups;
        
        Set<Id> groupids = new set<Id>();
        groupids.add(groups[0].Id);
        groupids.add(groups[1].Id);
        
        //updating an event with an event group
        conference360__Event__c event = [SELECT id FROM conference360__Event__c][0];
        event.conference360__Event_Group__c = groups[0].Id;
        update event;
        
        List<User> users = [SELECT Id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 2];
        
        //creating new staff for event group
        list<conference360__Staff__c> staffList = new list<conference360__Staff__c>();
    	staffList.add(new conference360__Staff__c(Event_Group__c = groups[0].Id, conference360__User__c= users[0].Id));
        staffList.add(new conference360__Staff__c(Event_Group__c = groups[1].Id, conference360__User__c= users[0].Id));
        staffList.add(new conference360__Staff__c(Event_Group__c = groups[1].Id, conference360__User__c= users[1].Id));
        
        insert staffList;
        
        Test.startTest();
            new BTStaffServices().manageEventStaffForGroup(groupids);
        Test.stopTest();
        
        //assert
        //new staff has been added to the events related to the event groups
        List<conference360__Staff__c> updatedStaffList = [SELECT Id,conference360__Event__c, conference360__User__c, Event_Group_Staff_Id__c 
                                                          FROM conference360__Staff__c
                                                          WHERE conference360__Event__c =:event.Id];
        
        system.assert(updatedStaffList.size() > 0, 'Staff not updated');
    }
    
    
     /*
     * Test creating and returning a unique set of staff for Event/Event Group 
     */
    @isTest
    public static void getExistingStaffRecordSet(){
        //given
        //adding new event groups
        List<conference360__Event_Group__c> groups = new List<conference360__Event_Group__c>();
        groups.add(new conference360__Event_Group__c(Name='Event Group 1'));
        groups.add(new conference360__Event_Group__c(Name='Event Group 2'));
        insert groups;
        
        Set<Id> groupids = new set<Id>();
        groupids.add(groups[0].Id);
        groupids.add(groups[1].Id);
        
        List<User> users = [SELECT Id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 2];
        
        //adding new staff to event groups
        list<conference360__Staff__c> staffList = new list<conference360__Staff__c>();
    	staffList.add(new conference360__Staff__c(Event_Group__c = groups[0].Id, conference360__User__c= users[0].Id));
        insert staffList;
        
        //fetching evnts
        conference360__Event__c event = [SELECT id FROM conference360__Event__c][0];
        Set<Id>eventids = new set<Id>();
    	eventids.add(event.Id);
        
        Test.startTest();
        Set<String>staffStringSet= new BTStaffServices().getExistingStaffRecordSet(eventids,groupids);
        Test.stopTest();
        
        //assert
        //related staff is returned
        system.assert(staffStringSet.size() > 0, 'no staff returned');
    }
}