/**
 * @author Nick Guia
 * @date 09-07-2020
 * @group Event Management
 * @description Test class for BTEventTriggerHandler
 * @revision rumi.rumi@monash.edu EPBBS-1551 added method cancelCampaignStatusTest and activeCampaignStatusTest to test event status change
  *          2021-06-09 -    Aref Samad     -Test Cover for EPBBS-1970 added new field in Event Internal_Name__c
 *                                          and also update to map campaign Name and campaign display name remains mapped with Event Name
 *                                          added new test methods updateCampusNameTest and updateCampusNameWithBlankTest
 *           13-10-2021 -  Ibrahim Rumi 	-Additional Asserts on formCampaignLinkTest method 
 *           11-11-2021    Mairaj Haider    -EPBBS-2262 Store maze map details in Location object and copy it to Event object
 *           12-02-2022    RANAND           -EPBBS-2030 Capture Winning Affiliation on Event
 *           2022-02-11    Ibrahim Rumi     -EPBBS-2387 UpdateSessionStatus() to auto cancel related sessions when event is cancelled
 *           2022-06-21    Ibrahim Rumi     -EPBBS-2750 AutoCreateEventItem() to auto create event items on approval submission
 *           2023-08-05    RANAND           -EPBBS-3285 Test Event Camnpaign update from Event
 */
@isTest(isParallel=true)
private class BTEventTriggerHandler_Test {

    @TestSetup
    static void setup() {
        //create blackthorn settings
		conference360__Blackthorn_Events_Settings__c settings = new conference360__Blackthorn_Events_Settings__c();
		settings.Disable_Auto_Create_Campaign__c = false;
		insert settings;
        
        Schema.Location location = (Schema.Location)TestDataFactory.createSObject(new Schema.Location(), false);
        location.Name = 'Moonash Campus';
        location.LocationType = 'Monash Campus';
        location.City__c = 'Melbourne';
        location.Street__c = 'Bourke Street';
        location.Postal_Code__c = '3000';
        location.State_Province__c = 'VIC';
        location.Country__c = 'Australia';
        insert location;
    }

    /**
     * @description test auto creation of campaign from new Events.
     *  The resulting campaign must be linked with the source Event.
     */
    @isTest
    static void createCampaignTest() {
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);

        Test.startTest();

        insert btEventList;

        Test.stopTest();

        List<Campaign> campList = [SELECT Id,Name,Public_Display_Name__c, conference360__Event__c
                                          FROM Campaign];
        System.assert(!campList.isEmpty(), 'Unable to auto-create Campaigns from Event');
        Campaign camp = campList[0];
        System.assertEquals(btEventList[0].Id, camp.conference360__Event__c, 'Unable to successfully link Event with Campaign');
        System.assertEquals(btEventList[0].Internal_Name__c, camp.Name, 'Unable to successfully map Event Internal Name with Campaign Name');
        System.assertEquals(btEventList[0].Name, camp.Public_Display_Name__c, 'Unable to successfully map Event Name with Campaign Display Name');
    }

    /**
     * @description Test when an existing Event is currently linked to a Campaign,
     * but was updated to something else. The new linked campaign should be linked back
     * to the event and the previously linked campaign should be unlinked
     */
    @isTest
    static void formCampaignLinkTest() {
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(2);
        insert btEventList;

        //convert to map
        Map<Id, conference360__Event__c> btMap = new Map<Id,conference360__Event__c>(btEventList);

        //create campaigns
        List<Campaign> campList = TestHelper.createEventCampaigns(2, btEventList);
        insert campList; //on campaign insert BT Events would have been linked back to campaigns
        Map<Id, Campaign> campMap = new Map<Id, Campaign>(campList);

        conference360__Event__c upEvent = btEventList[0];

        Test.startTest();

        //change the linked campaign
        upEvent.conference360__Campaign__c = campList[1].Id;
        update upEvent;

        Test.stopTest();
        Id campaignToUnlink = campList[0].Id;

        campMap = new Map<Id, Campaign>([SELECT Id, conference360__Event__c
                                        FROM Campaign
                                        WHERE Id IN : campMap.keySet()]);
        if(campMap.containskey(campaignToUnlink)){
            System.assert(campMap.get(campaignToUnlink).conference360__Event__c == null,'Unable to unlink previously linked event from campaign');
        }

        for(conference360__Event__c iEvent : [SELECT Id, conference360__Campaign__c
                                            FROM conference360__Event__c
                                            WHERE Id IN :btMap.keySet()])
        {
            if(iEvent.Id == upEvent.Id) {
                Campaign campRec = campMap.get(iEvent.conference360__Campaign__c);
                System.assert(campRec != null, 'Invalid Campaign linked to this Event');
                System.assertEquals(iEvent.Id, campRec.conference360__Event__c, 'Campaign record was not linked back to the Event');
            } else {
                System.assert(iEvent.conference360__Campaign__c == null, 'Unable to unlink previously Campaign from Event');
            }
        }
    }

     /**
     * @author Ibrahim Rumi
     * @description test cancellation of campaign when event is cancelled.
     */
    @isTest
    static void cancelCampaignStatusTest() {
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
		btEventList[0].conference360__Status__c = 'Active';
        insert btEventList;

        btEventList[0].conference360__Status__c = 'Canceled';

        Test.startTest();

        update btEventList;

        Test.stopTest();

        List<Campaign> campList = [SELECT Id, conference360__Event__c,Status,isActive
                                FROM Campaign where RecordTypeId = :CampaignServices.EVENT_RECTYPE];
        Campaign camp = campList[0];
        System.assertEquals(camp.Status, 'Cancelled');
        System.assertEquals(camp.isActive, false);

    }

    /**
     * @author Ibrahim Rumi
     * @description test activation of campaign when event is active.
     */
    @isTest
    static void activeCampaignStatusTest() {
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
		btEventList[0].conference360__Status__c = 'Canceled';
        insert btEventList;

        btEventList[0].conference360__Status__c = 'Active';
        Test.startTest();

        update btEventList;

        Test.stopTest();

        List<Campaign> campList = [SELECT Id, conference360__Event__c,Status,isActive
                                FROM Campaign where RecordTypeId = :CampaignServices.EVENT_RECTYPE];
        Campaign camp = campList[0];
        System.assertEquals(camp.Status, 'In Progress');
        System.assertEquals(camp.isActive, true);

    }

     /**
     * @author Aref Samad
     * @description test update campus name if event interal name changes.
     */
    @isTest
    static void updateCampusNameTest() {
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        btEventList[0].Internal_Name__c = 'Internal Name 1';
        insert btEventList;

        btEventList[0].Internal_Name__c = 'Internal Name 2';

        Test.startTest();

        update btEventList;

        Test.stopTest();
        List<Campaign> campList = [SELECT Id,Name
                                          FROM Campaign WHERE RecordTypeId = :CampaignServices.EVENT_RECTYPE];
        Campaign camp = campList[0];
        System.assertEquals('Internal Name 2',camp.Name);

    }

    /**
     * @author Aref Samad
     * @description test update campus name with Event Name if event interal name is blank.
     */
    @isTest
    static void updateCampusNameWithBlankTest() {
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        btEventList[0].Name = 'Name 1';
        btEventList[0].Internal_Name__c = 'Internal Name 1';
        insert btEventList;

        btEventList[0].Internal_Name__c = '';

        Test.startTest();

        update btEventList;

        Test.stopTest();
        List<Campaign> campList = [SELECT Id,Name
                                          FROM Campaign WHERE RecordTypeId = :CampaignServices.EVENT_RECTYPE];
        Campaign camp = campList[0];
        System.assertEquals('Name 1',camp.Name);

    }

        /**
     * @author Mairaj Haider
     * @description Location details should be copied to Event object from Location object when location is addded to Event
     */
    @isTest
    static void copyLocationAddressFieldsWhenLocationAddedToEvent() {

        //GIVEN
        Schema.Location location = [SELECT Id, City__c, Street__c, Postal_Code__c, State_Province__c, Country__c  from Location LIMIT 1];
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        btEventList[0].Location__c = location.Id;

        //WHEN
        Test.startTest();
        insert btEventList; 
        Test.stopTest();

        //THEN
        List<conference360__Event__c> eventList = [SELECT Id,  conference360__Venue_Street__c, conference360__Venue_City__c, conference360__Venue_Postal_Code__c, conference360__Venue_State_Province__c, conference360__Venue_Country__c
                                FROM conference360__Event__c
                                WHERE Id = :btEventList[0].Id];

        System.assertEquals(eventList[0].conference360__Venue_Street__c, location.Street__c, 'Event Street not matching with Location Street');
        System.assertEquals(eventList[0].conference360__Venue_City__c, location.City__c, 'Event City not matching with Location City');
        System.assertEquals(eventList[0].conference360__Venue_Postal_Code__c, location.Postal_Code__c, 'Event Postal Code not matching with Location Postal Code');
        System.assertEquals(eventList[0].conference360__Venue_State_Province__c, location.State_Province__c, 'Event State not matching with Location State');
        System.assertEquals(eventList[0].conference360__Venue_Country__c, location.Country__c, 'Event Country not matching with Location Country');
    }

    /**
     * @author Mairaj Haider
     * @description Location details should be deleted from Event object when location is deleted from Event
     */
    @isTest
    static void copyLocationAddressFieldsWhenLocationDeletedOnEvent() {

        //GIVEN
        Schema.Location location = [SELECT Id, City__c, Street__c, Postal_Code__c, State_Province__c, Country__c  from Location LIMIT 1];
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        btEventList[0].Location__c = location.Id;

        //WHEN
        Test.startTest();
        insert btEventList; 
        btEventList[0].Location__c = null;
        update btEventList;
        Test.stopTest();

        //THEN
        List<conference360__Event__c> eventList = [SELECT Id,  conference360__Venue_Street__c, conference360__Venue_City__c, conference360__Venue_Postal_Code__c, conference360__Venue_State_Province__c, conference360__Venue_Country__c
                                FROM conference360__Event__c
                                WHERE Id = :btEventList[0].Id];

        System.assertEquals(eventList[0].conference360__Venue_Street__c, null, 'Event Street not matching with Location Street');
        System.assertEquals(eventList[0].conference360__Venue_City__c, null, 'Event City not matching with Location City');
        System.assertEquals(eventList[0].conference360__Venue_Postal_Code__c, null, 'Event Postal Code not matching with Location Postal Code');
        System.assertEquals(eventList[0].conference360__Venue_State_Province__c, null, 'Event State not matching with Location State');
        System.assertEquals(eventList[0].conference360__Venue_Country__c, null, 'Event Country not matching with Location Country');
    }

    /**
     * @author Mairaj Haider
     * @description Updates Event Attendee status to Attended
     */
    @isTest
    static void sessionStatus_Updated_To_Cancelled_Successfully(){
        //given
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);     
        insert btEventList;

        TriggerCommon.disableTrigger('conference360__Session__c');
        conference360__Session__c session = new conference360__Session__c();
        session.Name = 'Test One';
        session.Category__c = 'In-person';
        session.conference360__Status__c = 'Active';
        session.conference360__Event__c = btEventList[0].Id;
        insert session;
        TriggerCommon.enableTrigger('conference360__Session__c');
        
        //when
        btEventList[0].conference360__Status__c = 'Canceled';
        Test.startTest();
        update btEventList;
        Test.stopTest();

        //then
        conference360__Session__c updatedSession = [SELECT Id,conference360__Status__c from conference360__Session__c LIMIT 1 ];        
        System.AssertEquals(updatedSession.conference360__Status__c, 'Canceled', 'Update session attendee status to canceled'); 
    }
    /**
     * @description Populate Winning Affiliation as Prospective Student and Industry on Event
     */
    @isTest
    static void IdentifyWinningAffiliationTestforIndustryAndPS() {

        //GIVEN
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        List<conference360__Event__c> eventList;
        //Add 2 audience types
        String audTypePS = String.join(new List<String>{
                            BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT,
                            BTAudienceTypeAnalyser.EVENT_AUDIENCE_INDUSTRY
                        }, ';');
        String audTypeIndustry = String.join(new List<String>{
                            BTAudienceTypeAnalyser.EVENT_AUDIENCE_ALUMNI,
                            BTAudienceTypeAnalyser.EVENT_AUDIENCE_INDUSTRY
                        }, ';');
		btEventList[0].Audience_Type__c = audTypePS;
        //WHEN
        Test.startTest();
        insert btEventList; 
        eventList = [SELECT Id, Winning_Affiliation__c 
                                FROM conference360__Event__c
                                WHERE Id = :btEventList[0].Id];
        System.assertEquals(eventList[0].Winning_Affiliation__c, BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT ,
                            'Winning Affiliation is Prospective Student');
        btEventList[0].Audience_Type__c = audTypeIndustry;
        update btEventList;
        Test.stopTest();

        //THEN
        eventList = [SELECT Id, Winning_Affiliation__c 
                                FROM conference360__Event__c
                                WHERE Id = :btEventList[0].Id];

        System.assertEquals(eventList[0].Winning_Affiliation__c, BTAudienceTypeAnalyser.EVENT_AUDIENCE_INDUSTRY , 'Winning Affiliation is Industry');
    }
    /*
     * @description		EPBBS-2570 Test Cascaded Event fields from Event Group
     */
    @isTest()
    static void testEventCreationwithGroupTest(){
        //Create a new Event Settings form record
        conference360__Event_Settings__c btEventSettings = TestHelper.createEventSettings(1)[0];
        insert btEventSettings;
        
        Test.startTest();
        //Create new Campaigns with Cascaded fields populated
        Campaign newCamp = new Campaign(Name='Test campaign 1',
                                          Public_Display_Name__c='test campaign 1',
                                          RecordTypeId = CampaignServices.EVENT_RECTYPE,
                                          IsActive=true,
                                          Type ='Parent',
                                          UI_Experience__c ='Oak (Tabbed)',
                                          Custom_CSS_Url__c ='www.test.com.au',
                                          Event_Settings__c = btEventSettings.Id
                                         );
        insert newCamp;
        
        //Create Event Group with Campaign populated
        conference360__Event_Group__c eventGroup1 = new conference360__Event_Group__c(Name = 'Event Group 1',Parent_Campaign__c=newCamp.Id);
        insert eventGroup1;
        
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.conference360__Event_Group__c = eventGroup1.Id;
        insert btEvent;
        Test.stopTest();
        
        conference360__Event_Group__c evGroupCascaded = [SELECT Id, conference360__Event_Settings__c, 
                                                         conference360__UI_Experience__c,
                                                         conference360__Custom_CSS_Url__c,
                                                         Form_Pre_Registration__c, Form_Post_Registration__c 
                                                         FROM conference360__Event_Group__c 
                                                         WHERE Name = 'Event Group 1' 
                                                         LIMIT 1];
        
        conference360__Event__c evCascaded = [SELECT Id, conference360__Event_Settings__c, 
                                                         conference360__UI_Experience__c,
                                                         conference360__Custom_CSS_Url__c   
                                                         FROM conference360__Event__c 
                                                         WHERE conference360__Event_Group__c =: evGroupCascaded.Id 
                                                         LIMIT 1];
          
        System.assertEquals(evGroupCascaded.conference360__Custom_CSS_Url__c, evCascaded.conference360__Custom_CSS_Url__c);

    }
    
    /**
     * @author Ibrahim Rumi
     * @description test auto creation of event item on approval submission
     */
    @isTest
    static void createEventItemOnApprovalSubmissionTest() {
    	//given
    	
        conference360__Event_Settings__c btEventSettings = TestHelper.createEventSettings(1)[0];
        btEventSettings.conference360__Campaign_Member_Attended_Status__c=BTAttendeeServices.ATTN_STATUS_ATTENDED;
        btEventSettings.conference360__Campaign_Member_Registered_Status__c=BTAttendeeServices.REG_STATUS_REGISTERED;
        btEventSettings.conference360__Default__c = TRUE; //making this default makes your Events use this settings without explicitly linking them
        btEventSettings.Automate_Event_Item_Creation__c = true;
        
        insert btEventSettings;

        
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
		
		btEventList[0].Approval_Stage__c = 'Draft';     
        btEventList[0].conference360__Attendee_Limit__c = 50;
        
        btEventList[0].conference360__Event_Settings__c = btEventSettings.id;
        
        insert btEventList;
        
        //when
        btEventList[0].Approval_Stage__c = 'Pending Approval';
        
        Test.startTest();
        
        Update btEventList;
        
        Test.stopTest();
        
        //then
        List<conference360__Event_item__c> eventitemlist = [SELECT id FROM conference360__Event_item__c WHERE conference360__Event__c =: btEventList[0].Id AND
                                                           conference360__Item_Name__c = 'Primary'];
        
        system.assert(eventitemlist.size()>0, 'event item not created');
        
    }
    /**
     * @description validatePermissionAndEventStatusUpdate method test
     */
    @isTest
    static void validatePermissionAndEventStatusUpdate_test() {

        //GIVEN
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        List<conference360__Event__c> eventList;
        insert btEventList; 

        try{
            //When
            Test.startTest();
            btEventList[0].Approval_Stage__c = 'Approved';
            btEventList[0].conference360__Event_End_Date__c = Date.today()-1;
            update btEventList[0];
            Test.stopTest();
        }
        catch(Exception ex){
            //THEN
            Assert.isTrue(ex.getMessage().contains('Only users with the custom permission "BT | Can edit approved events" should be able to modify an approved Event'));
        }

    }
    /*
     * @description		EPBBS-3285 Test Cascaded Event fields from Event to Event Campaign
     */
    @isTest()
    static void testEventCampaignUpdateonEventChange(){
        //GIVEN - Event with necessary details and associated Event campaign has already been pressent in system
        Test.startTest();
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        insert btEventList;
        conference360__Event__c btEvent = btEventList[0];
        //WHEN - Cascade related fields are updated on Event 
        btEvent.Audience_Type__c= 'Student';
        btEvent.conference360__Custom_CSS_Url__c = 'www.teststyle.com';
        update btEvent;
        Test.stopTest();

        //THEN - The associated Campaign's field should also get updated
        Campaign objCamp = [SELECT Audience_Type__c, Custom_CSS_Url__c FROM Campaign WHERE Type = 'Sibling' AND conference360__Event__c =: btEvent.Id];
        Assert.areEqual(btEvent.Audience_Type__c, objCamp.Audience_Type__c);
        Assert.areEqual(btEvent.conference360__Custom_CSS_Url__c, objCamp.Custom_CSS_Url__c);

    }
}