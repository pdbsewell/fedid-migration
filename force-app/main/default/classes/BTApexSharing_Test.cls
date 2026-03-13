/**
 * @description  : Helper class to process ApexSharing
 * @author       : Ibrahim Rumi
 * @group        : Event Management
 * @date         : 27-08-2021
 * @revision
 * Ver   Date         Author         Modification
 * 1.0   05-10-2021   Ibrahim Rumi   Modification of all test methods to call BTApexSharing with constructor
**/
@IsTest(isParallel=true)
public class BTApexSharing_Test {

    @TestSetup
    static void makeData(){
 
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(2);
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
        
    }

    /*
     * test setting share record
     */
    @isTest()
    static void processIndividualStaffShareTest(){
        //given
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];

        user u = [SELECT id FROM user where lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
       
        Test.startTest();
        
        BTApexSharing btShare = new BTApexSharing();
        btShare.setshareRecord(eve, conference360__Event__share.sObjectType, u.Id, 'BT_Mobile_Check_in_App__c', 'Read');
        btShare.processSharing();
        
        Test.stopTest();
        
        List<conference360__Event__share> eveShare= [SELECT parentid FROM conference360__Event__share WHERE parentid =: eve.Id];
        system.assert(eveShare.size() > 0);
     
    }
    
    /*
     * test setting share records
     */
    @isTest()
    static void processBulkStaffShareTest(){
        //given
        List<conference360__Event__c> eveList = [SELECT id FROM conference360__Event__c];
        
        user u = [SELECT id FROM user where lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        
        Test.startTest();
        
       	BTApexSharing btShare = new BTApexSharing();
        btShare.setshareRecords(eveList, conference360__Event__share.sObjectType, u.Id, 'BT_Mobile_Check_in_App__c', 'Read');
        btShare.processSharing();
        
        Test.stopTest();
        
        List<conference360__Event__share> eveShare= [SELECT parentid FROM conference360__Event__share WHERE parentid IN: eveList];
        system.assert(eveShare.size() > 0);
     
    }
    
    /*
     * negative test setting share record with invalid sharing reason
     */
    @isTest()
    static void processStaffShareNegative_Test(){
        //given
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        
        user u = [SELECT id FROM user where lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        BTApexSharing btShare = new BTApexSharing();
        
        Test.startTest();
        
        btShare.setshareRecord(eve, conference360__Event__share.sObjectType, u.Id, 'Test', 'Read');
        btShare.processSharing();
        
        Test.stopTest();

        // assert 
        System.AssertEquals(1, [SELECT count() FROM Exception_Log__c], 'Did not receive the expected number of Exception Logs to be created'); 
        
    }
}