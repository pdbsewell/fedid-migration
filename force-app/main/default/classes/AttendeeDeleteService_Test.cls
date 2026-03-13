/**
 * @author Ibrahim Rumi
 * @date 04-07-2023
 * @group Event Management
 * @description Test class for AttendeeDeleteService
 **/
@istest(isParallel=true)
public class AttendeeDeleteService_Test {

     @TestSetup
    static void setup() {
       //create environment settings
        Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Contact_Loose_Match_Duplicate_Rule_Name__c = 'Contact_Loose_Match';
        insert envSettings;

        //create Relationship Settings
        bt_stripe__Relationship_Settings__c relSetting = TestHelper.createBTRelationshipSetting();
        insert relSetting;

        //create event settings
        conference360__Event_Settings__c eventSettings = new conference360__Event_Settings__c(
        	Name = 'BTAttendeeTriggerHandler_Test_event_settings',
            conference360__Relationship_Settings__c  = relSetting.id
        );
        insert eventSettings;

        //create blackthorn settings
		conference360__Blackthorn_Events_Settings__c settings = new conference360__Blackthorn_Events_Settings__c();
        settings.Disable_Auto_Create_Campaign__c = false;
        settings.Custom_Attende_Matching_Threshold__c = 40;
        insert settings;

        //create contact
        Contact con = new Contact(
            FirstName = 'BTAttendeeTriggerHandler_Test',
            LastName = 'test1',
            Email = 'test@test.org'
        );
        insert con;

        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        for(conference360__Event__c event:btEventList){
            event.conference360__Event_Settings__c = eventSettings.id;
        }
        TriggerCommon.disableTrigger('conference360__Event__c');
        insert btEventList;
        TriggerCommon.enableTrigger('conference360__Event__c');
    }
    
    /**
     * @description test method to test delete attendees
     */
    @isTest
    static void testdeleteAttendees() {
        
        //given
        List<List<conference360__attendee__c>> listAttendeesList = new List<List<conference360__attendee__c>>();
        List<conference360__Attendee__c> attList = new List<conference360__Attendee__c>();
        conference360__Event__c btEvent = [SELECT Id
                                        FROM conference360__Event__c
                                        LIMIT 1];
        Contact existingCon = [SELECT Id
                            FROM Contact
                            WHERE FirstName = 'BTAttendeeTriggerHandler_Test' AND
                            LastName = 'test1' AND
                            Email = 'test@test.org'
                            LIMIT 1];
        
        conference360__Attendee__c att = TestHelper.createBlackthornAttendee(btEvent.Id, 1)[0];
        //should match setup contact
        att.conference360__Contact__c = existingCon.id;
        attList.add(att);
        
        TriggerCommon.disableTrigger('conference360__Attendee__c');
        insert attList;
        TriggerCommon.enableTrigger('conference360__Attendee__c');
        
        listAttendeesList.add(attList);
        
        //when
        Test.startTest();
        	AttendeeDeleteService.deleteTestRecords(listAttendeesList);
        Test.stopTest();
        
        //then
		List<conference360__Attendee__c> updatedAttList = [SELECT Id, conference360__Contact__c
                                                            FROM conference360__Attendee__c
                                                            WHERE conference360__Contact__c = :existingCon.Id];   
        
        Assert.areEqual(updatedAttList.size(), 0, 'attendee has not been deleted');
    }
    
    /**
     * @description test method to test when a linked acciunt has multiple contacts
     */
    @isTest
    static void errorTestMultipleContactOnAccount() {
    
        //given
        List<conference360__Attendee__c> attList = new List<conference360__Attendee__c>();
        conference360__Event__c btEvent = [SELECT Id
                                        FROM conference360__Event__c
                                        LIMIT 1];
        Contact existingCon = [SELECT Id,accountid
                            FROM Contact
                            WHERE FirstName = 'BTAttendeeTriggerHandler_Test' AND
                            LastName = 'test1' AND
                            Email = 'test@test.org'
                            LIMIT 1];
        
        Contact con2 = new Contact(
            FirstName = 'BTAttendeeTriggerHandler_Test1',
            LastName = 'test1',
            Email = 'test1@test.org',
            accountid = existingCon.accountid
        );
        TriggerCommon.disableTrigger('Contact');
        insert con2;
        TriggerCommon.enableTrigger('Contact');
        
        conference360__Attendee__c att1 = TestHelper.createBlackthornAttendee(btEvent.Id, 1)[0];
        //should match setup contact
        att1.conference360__Contact__c = existingCon.id;
        
        conference360__Attendee__c att2 = TestHelper.createBlackthornAttendee(btEvent.Id, 1)[0];
        //should match setup contact
        att2.conference360__Contact__c = con2.id;
        
        attList.add(att1);
        attList.add(att2);
        
        TriggerCommon.disableTrigger('conference360__Attendee__c');
        insert attList;
        TriggerCommon.enableTrigger('conference360__Attendee__c');
        
        //when
        Test.startTest();
        	String result = AttendeeDeleteService.cascadeDeleteRecords(attList);
        Test.stopTest();
        
        //then
        Assert.areEqual(result,AttendeeDeleteService.MULTI_CON_SAME_ACC_ERRMSG,'expected error message not returned');
        
        List<conference360__Attendee__c> updatedAttList = [SELECT id FROM conference360__Attendee__c WHERE conference360__Event__c =: btEvent.id];
        
        Assert.areEqual(attList.size(),2,'expected attendees not available');
        
    }
    
    /**
     * @description test method to test when empty list of list attendees is passed from the flow
     */
    @isTest
    static void testDeleteEmptyAttendeeList() {
        //given
        List<List<conference360__attendee__c>> listAttendeesList = new List<List<conference360__attendee__c>>();
        
        //when
        Test.startTest();
        	List<String> resultList = AttendeeDeleteService.deleteTestRecords(listAttendeesList);
        Test.stopTest();
        
        //then
        Assert.areEqual(resultList[0],AttendeeDeleteService.NO_ATT_TO_DEL_MSG,'expected error message not returned');
    }
    
    /**
     * @description test method when an inner list is empty 
     */
    @isTest
    static void testDeleteChildEmptyAttendeeList() {
        //given
        List<List<conference360__attendee__c>> listAttendeesList = new List<List<conference360__attendee__c>>();
        List<conference360__attendee__c>attList = new List<conference360__attendee__c>();
        List<conference360__attendee__c>attList1 = new List<conference360__attendee__c>();
		
        listAttendeesList.add(attList);
        listAttendeesList.add(attList1);
        
        //when
        Test.startTest();
        	List<String> resultList = AttendeeDeleteService.deleteTestRecords(listAttendeesList);
        Test.stopTest();
        
        //then
        Assert.areEqual(resultList[0],AttendeeDeleteService.NO_ATT_TO_DEL_MSG,'expected error message not returned');
    }
    
    /**
     * @description test method to handle exception
     */
    @isTest
    static void testExceptionHandling() {
        //given
        List<conference360__attendee__c>attList;
        
        //when
        Test.startTest();
        	String result = AttendeeDeleteService.cascadeDeleteRecords(attList);
        Test.stopTest();
        
        //then
        Assert.areEqual(result,AttendeeDeleteService.ERROR_IN_DELETION_MSG,'expected error message not returned');
    }
}