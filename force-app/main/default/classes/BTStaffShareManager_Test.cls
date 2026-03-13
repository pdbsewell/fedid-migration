/**
 * @author Ibrahim Rumi
 * @date 30-08-2021
 * @group Event Management
 * @description Test class for BTStaffShareManager
 **/
@isTest(isParallel=true)
public class BTStaffShareManager_Test {
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
            TestHelper.createTestUsers('Base Profile', 2);
        }
        
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        
        TriggerCommon.disableTrigger('conference360__Staff__c');
        List<Conference360__Staff__c> stafflist = new List<Conference360__Staff__c>(); 
        for(Integer i=0;i<2;i++){
            Conference360__Staff__c staff = new conference360__Staff__c(conference360__User__c=u.Id,conference360__Event__c=btEventList[0].Id);
            stafflist.add(staff);
        }
        Insert stafflist;
        TriggerCommon.enableTrigger('conference360__Staff__c');

    }
    
    /*
     * test processing of new staff
     */
    @isTest
    public static void processStaffInsertTest(){
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        List<Conference360__Staff__c> staffList = [SELECT id,conference360__User__c,conference360__Event__c FROM conference360__Staff__c WHERE conference360__User__c=:u.Id];
        Test.startTest();
        	new BTStaffShareManager().processStaffInsert(staffList);
        Test.stopTest();
        
        List<conference360__Event__share> eveShare = [SELECT UserOrGroupId FROM conference360__Event__share WHERE UserOrGroupId =:u.Id];
        system.assert(eveShare.size()>0);
    }
    
    /*
     * test to validate existing users of an event
     */
    @isTest
    public static void validateStaffTest(){
        
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        Conference360__Staff__c staff = [SELECT id,conference360__User__c,conference360__Event__c FROM conference360__Staff__c WHERE conference360__User__c=:u.Id][0];
        
        Conference360__Staff__c duplicate_Staff = new Conference360__Staff__c(conference360__User__c = staff.conference360__User__c,conference360__Event__c = staff.conference360__Event__c);
        List<conference360__Staff__c> staffList = new List<conference360__Staff__c>{duplicate_Staff};
        Set<Id>eventIdSet = new Set<Id>{staff.conference360__Event__c};
        
        Boolean exceptionThrown = false;
        
        Try{
            Test.startTest();
            	new BTStaffShareManager().validateStaff(staffList);
            Test.stopTest();
        } catch (Exception e) {
        	
            exceptionThrown = true;

            // assert
            Boolean expectedExceptionThrown =  (e.getMessage().contains('The user is already an existing staff in the event')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
    }
    
    /*
     * test to validate staff deletion
     */
    @isTest
    public static void processStaffDeleteTest(){
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        List<Conference360__Staff__c> staffList = [SELECT id,conference360__User__c,conference360__Event__c FROM conference360__Staff__c WHERE conference360__User__c=:u.Id];
        Test.startTest();
        	new BTStaffShareManager().processStaffDelete(staffList);
        Test.stopTest();
    }
    
    /*
     * test to verify if the new user was assigned with a permission set
     */
    @isTest
    public static void asyncPermissionSetGroupAssignmentTest(){
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        Set<Id> userIdSet = new Set<Id>{u.Id};
        
        Test.startTest();
        	BTStaffShareManager.asyncPermissionSetGroupAssignment(userIdSet);
        Test.stopTest();
        
         List<PermissionSetAssignment> psgList = [SELECT Id FROM PermissionSetAssignment WHERE assigneeId =: u.Id];
         System.assert(psgList.size()>0);
        
    }
}