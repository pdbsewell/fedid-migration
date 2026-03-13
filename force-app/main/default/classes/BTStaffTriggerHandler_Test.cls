/**
 * @author Ibrahim Rumi
 * @date 30-08-2021
 * @group Event Management
 * @description Test class for BTStaffTriggerHandler
 **/
@IsTest(isParallel=true)
public class BTStaffTriggerHandler_Test {

    @TestSetup
    static void makeData(){

        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
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
        
    }
    
    /*
     * test validation of staff with no user
     */
    @isTest()
    static void validateNewStaffWithNoUser(){
        //given
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        user u = [SELECT id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        conference360__Staff__c staff = new conference360__Staff__c(conference360__Event__c = eve.Id);
        Boolean exceptionThrown = false;
        
        Try{
            
            Insert staff;
            
        } catch (Exception e) {
        	
            exceptionThrown = true;

            // assert
            Boolean expectedExceptionThrown =  (e.getMessage().contains('Event/Event Group and User is required to create a Staff')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
    }
    
     /*
     * validate staff update with no user
     */
    @isTest()
    static void validateStaffUpdateWithNoUser(){
        //given
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        user u = [SELECT id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        conference360__Staff__c staff = new conference360__Staff__c(conference360__Event__c = eve.Id,conference360__User__c = u.Id);
        
        Insert staff;
        
        staff.conference360__User__c = null;
        Boolean exceptionThrown = false;
        
        Try{
            
            Update staff;
            
        } catch (Exception e) {
        	
            exceptionThrown = true;

            // assert
            Boolean expectedExceptionThrown =  (e.getMessage().contains('Event/Event Group and User is required to create a Staff')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
    }
    
    /*
     * test validation of staff with already existing user within an event
     */
    @isTest()
    static void validateStaffWithDuplicateUser(){
        //given
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        user u = [SELECT id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        conference360__Staff__c staff = new conference360__Staff__c(conference360__Event__c = eve.Id,conference360__User__c = u.Id);
        Insert staff;
        
        conference360__Staff__c duplicate_Staff = new conference360__Staff__c(conference360__Event__c = eve.Id,conference360__User__c = u.Id);
        Boolean exceptionThrown = false;
        
        Try{
            
            Insert duplicate_Staff;
            
        } catch (Exception e) {
        	
            exceptionThrown = true;

            // assert
            Boolean expectedExceptionThrown =  (e.getMessage().contains('The user is already an existing staff in the event')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
    }
    
    /*
     * test successful creation of staff
     */
    @isTest()
    static void createStaff(){
        //given
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        
        user u = [SELECT id FROM user where lastname like '%TestingUser%' and Profile.name = 'Base Profile'][0];
        conference360__Staff__c staff = new conference360__Staff__c(conference360__Event__c = eve.Id,conference360__User__c = u.Id);
        
        Test.startTest();
        
        //When
        Insert staff;

        Test.stopTest();
        
        //THEN

        conference360__Staff__c staffrec = [SELECT id,conference360__Event__c,conference360__User__c FROM conference360__Staff__c Limit 1][0];

        System.assert(staffrec.Id!=null);
        System.assertEquals(staffrec.conference360__Event__c,eve.Id);
        System.assertEquals(staffrec.conference360__User__c,u.Id);


    }
    
    /*
     * test successful update of staff
     */
    @isTest()
    static void updateStaff(){
        //given
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        list<user> users = [SELECT id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 2];
        conference360__Staff__c staff = new conference360__Staff__c(conference360__Event__c = eve.Id,conference360__User__c = users[0].Id);
		Insert staff;
        
        staff.conference360__User__c = users[1].Id;
        
        Test.startTest();
        //When
        Update staff;

        Test.stopTest();

        //THEN

        conference360__Staff__c staffrec = [SELECT id,conference360__Event__c,conference360__User__c FROM conference360__Staff__c Limit 1][0];

        System.assert(staffrec.Id!=null);
        System.assertEquals(staffrec.conference360__Event__c,eve.Id);
        System.assertEquals(staffrec.conference360__User__c,users[1].Id);


    }
    
    /*
     * test successful creation of staff
     */
    @isTest()
    static void deleteStaff(){
        //given
        
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        list<user> users = [SELECT id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 2];
        conference360__Staff__c staff = new conference360__Staff__c(conference360__Event__c = eve.Id,conference360__User__c = users[0].Id);
		Insert staff;
        
        Test.startTest();
       	Delete staff;
        Test.stopTest();
        
        List<conference360__Staff__c> staffList = [SELECT id FROM conference360__Staff__c];
        
        system.assert(staffList.size() == 0);
        
    }
    /*
     * Test for events where EventGroupStaff is already available on associated EventGroup
     */
    @isTest()
    static void autoCreateEventStaffForNewEvents(){
        conference360__Event_Group__c eventGroup = new conference360__Event_Group__c(Name='Event Group 1');
        insert eventGroup;
        User user = [SELECT id FROM user where lastname like '%TestingUser%' and Profile.name = 'Base Profile'][0];
        conference360__Event__c event = [SELECT id FROM conference360__Event__c][0];
        event.conference360__Event_Group__c = eventGroup.Id;
        update event;
        Test.startTest();
            conference360__Staff__c evGroupStaff = new conference360__Staff__c(Event_Group__c = eventGroup.Id, conference360__User__c= user.Id);
            insert evGroupStaff;
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM conference360__Staff__c WHERE conference360__Event__c=:event.Id],'No Staff created');
    }
    /*
     * Test for events where EventGroup is changed on Event
     */
    @isTest()
    static void autoCreateEventStaffForUpdateEvents(){
        List<conference360__Event_Group__c> groups = new List<conference360__Event_Group__c>();
        groups.add(new conference360__Event_Group__c(Name='Event Group 1'));
        groups.add(new conference360__Event_Group__c(Name='Event Group 2'));
        insert groups;
        
        List<User> users = [SELECT Id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 2];
       
        conference360__Event__c event = [SELECT id FROM conference360__Event__c][0];
        event.conference360__Event_Group__c = groups[0].Id;
        update event;
        Test.startTest();
            conference360__Staff__c evGroupStaff = new conference360__Staff__c(Event_Group__c = groups[0].Id, conference360__User__c= users[0].Id);
            insert evGroupStaff;
            System.assertEquals(1, [SELECT COUNT() FROM conference360__Staff__c WHERE conference360__Event__c=:event.Id],'No Staff created');
            event.conference360__Event_Group__c = groups[1].Id;
            update event;
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM conference360__Staff__c WHERE conference360__Event__c=:event.Id],'No Staff created');
    }
    /*
     * Test for events where EventGroupStaff is already available on associated EventGroup and there is a change to Event Group
     */
    @isTest()
    static void autoCreateEventStaffForDeleteEventStaff(){
        List<conference360__Event_Group__c> groups = new List<conference360__Event_Group__c>();
        groups.add(new conference360__Event_Group__c(Name='Event Group 1'));
        groups.add(new conference360__Event_Group__c(Name='Event Group 2'));
        insert groups;
        
        List<User> users = [SELECT Id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 2];
       
        conference360__Staff__c evGroupStaff = new conference360__Staff__c(Event_Group__c = groups[0].Id, conference360__User__c= users[0].Id);
    	insert evGroupStaff;
        Test.startTest();
            conference360__Event__c event = [SELECT id FROM conference360__Event__c][0];
            event.conference360__Event_Group__c = groups[0].Id;
            update event;
            
            System.assertEquals(1, [SELECT COUNT() FROM conference360__Staff__c WHERE conference360__Event__c=:event.Id],'No Staff created');
        	delete evGroupStaff;
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM conference360__Staff__c WHERE conference360__Event__c=:event.Id],'Event Staff not deleted');
    }
    /*
     * Test duplicate staff creation on EventGroup
     */
    @isTest()
    static void autoCreateEventStaffDuplicate(){
        conference360__Event_Group__c eventGroup = new conference360__Event_Group__c(Name='Event Group 1');
        insert eventGroup;
        User user = [SELECT id FROM user where lastname like '%TestingUser%' and Profile.name = 'Base Profile'][0];
        conference360__Staff__c evGroupStaff = new conference360__Staff__c(Event_Group__c = eventGroup.Id, conference360__User__c= user.Id);
    	insert evGroupStaff;
        try{
            Test.startTest();
                conference360__Staff__c evGroupStaffDup = new conference360__Staff__c(Event_Group__c = eventGroup.Id, conference360__User__c= user.Id);
                insert evGroupStaffDup;
            Test.stopTest();
        }
        catch (Exception e) {           
            // assert
            Boolean expectedExceptionThrown =  (e.getMessage().contains('The user is already an existing staff in the event group')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
    }
    
}