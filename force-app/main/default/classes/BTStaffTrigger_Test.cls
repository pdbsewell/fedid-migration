/**
 * @author Ibrahim Rumi
 * @date 30-08-2021
 * @group Event Management
 * @description Test class for BTStaffTrigger
 **/
@IsTest(isParallel=true)
public class BTStaffTrigger_Test {

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
     * test logic when new staff is created
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
     * test logic when new staff is updated
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
     * test logic when new staff is deleted
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
        System.assert(staffList.size() ==0);
    }

}