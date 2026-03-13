/**
 * @author Ibrahim Rumi
 * @date 30-08-2021
 * @group Event Management
 * @description Test class for BTEventShareDAO
 **/
@IsTest(isParallel=true)
public class BTEventShareDAO_Test {
	@TestSetup
    static void makeData(){

        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
         TriggerCommon.disableTrigger('conference360__Event__c');
        insert btEventList;
         TriggerCommon.enableTrigger('conference360__Event__c');

        //create blackthorn attendee
        List<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendee(btEventList[0].Id, 2);
         TriggerCommon.disableTrigger('conference360__Attendee__c');
		insert attendeeList;
        TriggerCommon.enableTrigger('conference360__Attendee__c');
        
    }
    
    /*
     * test of setting up event rec
     */
    @isTest
    public static void eventSetupTest(){
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        
        BTEventShareDAO dao = new BTEventShareDAO(eve);
        
        Test.startTest();
        	list<sObject> recsList = dao.getRecordsList('conference360__Event__c');
        Test.stopTest();
        System.assert(recsList.size()>0);
    }
    
    /*
     * test setting up child records
     */
    @isTest
    public static void attendeeSetupTest(){
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        List<conference360__attendee__c> attendeeList = [SELECT id FROM conference360__attendee__c];
        
        BTEventShareDAO dao = new BTEventShareDAO(eve)
            				 .setRelatedRecords(attendeeList);
        
        Test.startTest();	
        	list<sObject> recsList = dao.getRecordsList('conference360__attendee__c');
        Test.stopTest();
        System.assert(recsList.size()>0);
    }
    
    /*
     * negative test when records list is null
     */
    @isTest
    public static void recordseSetupNegativeTest(){
        conference360__Event__c eve = [SELECT id FROM conference360__Event__c][0];
        List<sObject> recsList;
        
       Boolean exceptionThrown = false;
        
        Try{
            
           BTEventShareDAO dao = new BTEventShareDAO(eve)
            				 .setRelatedRecords(recsList);
            
        } catch (Exception e) {
        	 
            exceptionThrown = true;

            // assert
            Boolean expectedExceptionThrown =  (e.getMessage().contains('sObject type is null')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
    }
}