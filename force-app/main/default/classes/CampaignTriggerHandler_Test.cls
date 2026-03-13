/*
 * @author			Ayush Agrawal (ayush.agrawal@monash.edu)
 * @description		This test class tests CampaignServices apex class.
 * @group           SRA (Student Recruitment and Admission)
 * @revision
 *  20.May.2020     - EPBBS-1252 Ayush Agrawal (ayush.agrawal@monash.edu) - Added testGenerateReplyToForRetentionCampaigns.
 *  21.July.2020    - EPBBS-1330 Nick Guia - Added test coverage for Event Campaigns
 *  20.October.2020 - EPBBS-1551 Ibrahim Rumi - Added UpdateEventStatusTest and UpdateEventActiveFlagTest
 *  21.March.2021   - PENGAGE-1710 Steffi added testcampaignWithCompany
 *  09.June.2021    - EPBBS-1970 Aref Samad -Modified  bulkLinkEventCampaignInsertTest for Test Cover of new field in Event Internal_Name__c
 *  21.June.2021    - Set isParallel = false to reduce test data locking contention and intermittent test class failure
 *  24-Aug-2021     - Aref Samad  - added test methods campaignInsertWithEventGroupTest & campaignUpdateWithEventGroupTest
 *                      for EPBBS-2083 Link Event Group to Parent Campaign
 *  13-10-2021      - Ibrahim Rumi 	-Additional Asserts on formEventLinkTest method 
 */
@isTest(isParallel=true)
public class CampaignTriggerHandler_Test {
     
	@testSetup
    static void setup() {
    	Contact contactOne = new Contact();
        contactOne.LastName = 'LastName';
        contactOne.Person_ID_unique__c = '1';

        TriggerCommon.disableTrigger('Contact');
        insert contactOne;
        TriggerCommon.enableTrigger('Contact');

        List<Campaign> campaigns = new List<Campaign>();

        Campaign campaignOne = new Campaign();
        campaignOne.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Outbound_Call')?.getRecordTypeId();
        campaignOne.CampaignMemberRecordTypeId = Schema.SObjectType.campaignmember.getRecordTypeInfosByDeveloperName().get('Outbound_Call')?.getRecordTypeId();
        campaignOne.Name = 'Post App Campaign';
        campaignOne.Type = 'International Post App';
        campaignOne.StartDate = Date.today();
        campaignOne.Prevent_Deletion__c = true;
        campaigns.add(campaignOne);
 
        Campaign campaignTwo = new Campaign();
        campaignTwo.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ERDA_Guest_List')?.getRecordTypeId();
        campaignTwo.Name = 'Name';
        campaignTwo.Prevent_Deletion__c = true;
        campaigns.add(campaignTwo);

        Campaign campaignThree = new Campaign();
        campaignThree.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Volunteers_Campaign')?.getRecordTypeId();
        campaignThree.Name = 'Name';
        campaignThree.Prevent_Deletion__c = true;
        campaigns.add(campaignThree);

        Campaign campaignFour = new Campaign();
        campaignFour.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Outbound_Call')?.getRecordTypeId();
        campaignFour.CampaignMemberRecordTypeId = Schema.SObjectType.campaignmember.getRecordTypeInfosByDeveloperName().get('Outbound_Call')?.getRecordTypeId();
        campaignFour.Name = 'Pre App Campaign';
        campaignFour.Type = 'International Pre App';
        campaignFour.StartDate = Date.today();
        campaignFour.Prevent_Deletion__c = true;
        campaigns.add(campaignFour);

        TriggerCommon.disableTrigger('Campaign');
        insert campaigns;
        TriggerCommon.enableTrigger('Campaign');

        List<conference360__Event_Group__c> newEventGroups=new List<conference360__Event_Group__c>();

        conference360__Event_Group__c eventGroup1 = new conference360__Event_Group__c(Name = 'Event Group 1');
        newEventGroups.add(eventGroup1);

        conference360__Event_Group__c eventGroup2 = new conference360__Event_Group__c(Name = 'Event Group 2');
        newEventGroups.add(eventGroup2);
		
        TriggerCommon.disableTrigger('conference360__Event_Group__c');
        insert newEventGroups;
        TriggerCommon.enableTrigger('conference360__Event_Group__c');
    }

    static testMethod void testDeletePrevention(){
        List<Campaign> campaigns = [SELECT Id, Prevent_Deletion__c FROM Campaign WHERE Prevent_Deletion__c = true limit 1];

        id campId = campaigns[0].Id;
        try {
            delete campaigns;
        } catch(Exception e) {}

        System.assertEquals(campaigns.size(),
                            [SELECT count() FROM Campaign WHERE id =: campId],
                            'Campaigns should not have been deleted.');


        for(Campaign c : campaigns) {
            c.Prevent_Deletion__c = false;
        }

        update campaigns;

        delete campaigns;

        System.assertEquals(0,
                            [SELECT count() FROM Campaign WHERE id =: campId],
                            'Campaigns should have been deleted.');
    }
    
        /**
     * @description On create of new Campaign, if the record type is Event and
     * conference360__Event__c is not blank, we update the related Event with
     * the Campaign ID (conference360__Campaign__c) to force a 1 to 1 relationship
     */
    @isTest
    static void bulkLinkEventCampaignInsertTest() { 
        //switch off auto create campaign so Events won't be linked to a campaign yet
        conference360__Blackthorn_Events_Settings__c settings = new conference360__Blackthorn_Events_Settings__c();
        settings.Disable_Auto_Create_Campaign__c = true;
        insert settings;
        
		id eventRecType = CampaignServices.EVENT_RECTYPE;

        //create blackthorn events
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(150);
        
        TriggerCommon.disableTrigger('conference360__Event__c');
        insert btEventList;
        TriggerCommon.enableTrigger('conference360__Event__c');
        
        Map<Id, conference360__Event__c> btEventMap = new Map<Id, conference360__Event__c>(btEventList);

        //create campaigns
        List<Campaign> campList = TestHelper.createEventCampaigns(150, btEventMap.values());

        Test.startTest();

        insert campList;

        Test.stopTest();

        //query processed campaigns
        List<Campaign> processedCampaigns = [SELECT Id,Name,Public_Display_Name__c, conference360__Event__c
                                             FROM Campaign
                                             WHERE RecordTypeId = :eventRecType
                                             LIMIT 200];
        //query processed events
        Map<Id, conference360__Event__c> processedBtEventMap = new Map<Id, conference360__Event__c>(
            [SELECT Id, conference360__Campaign__c
                    FROM conference360__Event__c
                    WHERE Id IN :btEventMap.keySet()
                    LIMIT 200]
        );
        for(Campaign iCamp : processedCampaigns) {
            System.assert(iCamp.conference360__Event__c != null,
                          'No Event record linked to the Campaign, please fix the test setup records'
                         );
            conference360__Event__c event = processedBtEventMap.get(iCamp.conference360__Event__c);
            System.assertEquals(iCamp.Id, event.conference360__Campaign__c, 'Unable to link Event to Campaign');

            conference360__Event__c eventRecord=btEventMap.get(iCamp.conference360__Event__c);
            System.assertEquals(iCamp.Name, eventRecord.Internal_Name__c, 'Unable to map Event Internal name to Campaign Name');
            System.assertEquals(iCamp.Public_Display_Name__c, eventRecord.Name, 'Unable to map Event name to Campaign Display Name');
        }
    }
    
/**
     * @description
     * - if campaign event was updated to something else,  update the related event with the new Campaign ID
     * - if campaign event was removed, unlink the event from the campaign
     */
    @isTest
	static void formEventLinkTest() {
        //create blackthorn events
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(2);
        TriggerCommon.disableTrigger('conference360__Event__c');
        insert btEventList;
        TriggerCommon.enableTrigger('conference360__Event__c');

		id eventRecType = CampaignServices.EVENT_RECTYPE;
        
        //convert to map
        Map<Id, conference360__Event__c> btMap = new Map<Id,conference360__Event__c>(btEventList);

        //create campaigns
        List<Campaign> campList = TestHelper.createEventCampaigns(2, btEventList);
        TriggerCommon.disableTrigger('Campaign');
        insert campList;
        TriggerCommon.enableTrigger('Campaign');

        Campaign upCamp = campList[0];

        Test.startTest();

        //update campaign's event
        upCamp.conference360__Event__c = btEventList[1].Id;
        update upCamp;

        Test.stopTest();
		Id eventToUnlink = btEventList[0].Id;
        
        Map<Id, conference360__Event__c> processedBtEventMap = new Map<Id, conference360__Event__c>(
            [SELECT Id, conference360__Campaign__c
            FROM conference360__Event__c
            WHERE Id IN :btMap.keySet()]);

        //query processed campaigns
        List<Campaign> processedCampaigns = [SELECT Id, conference360__Event__c
                                    FROM Campaign
                                    WHERE RecordTypeId = :eventRecType];

        //check if the campaign lookup is removed from the event
        if(processedBtEventMap.containskey(eventToUnlink)){
            System.assert(processedBtEventMap.get(eventToUnlink).conference360__Campaign__c == null,'Unable to unlink previously linked event from campaign');
        }

        for(Campaign iCamp : processedCampaigns) {
            //check if this was the campaign we updated
            if(iCamp.Id == upCamp.Id) {
                System.assert(
                    iCamp.conference360__Event__c != null,
                    'Update unsuccessful. No Event record linked to the Campaign'
                );
                conference360__Event__c event = processedBtEventMap.get(iCamp.conference360__Event__c);
                System.assertEquals(iCamp.Id, event.conference360__Campaign__c, 'Failed to link back Event to Campaign');
            } else {
                //make sure that the other campaign had the event lookup field removed since it got linked to a different campaign
                System.assert(
                    iCamp.conference360__Event__c == null,
                    'Unable to unlink Event from previous campaign'
                );
            }
        }
    }

    /**
     * @description Campaign Member statuses within an "Event" Campaign
     *  should be in the expectedStatuses
     */
    @isTest
    static void updateEventMemberStatusesTest() {

        //given
        Set<String> expectedStatuses = new Set<String>();
        for(Campaign_Member_Status__mdt iMdt : [SELECT MasterLabel, Has_Responded__c, Is_Default__c
                                                FROM Campaign_Member_Status__mdt WHERE Campaign_Record_Type__c = 'Event'])
        {
            expectedStatuses.add(iMdt.MasterLabel);
        }
        Campaign testCampaign = TestHelper.createEventCampaigns(1, new List<conference360__Event__c>())[0];

        Test.startTest();

        //when
        insert testCampaign;

        Test.stopTest();

        //then
        List<CampaignMemberStatus> cmStatusList = [SELECT Id, Label
                                                FROM CampaignMemberStatus
                                                WHERE CampaignId = :testCampaign.Id];
        System.assert(!cmStatusList.isEmpty(), 'Unable to generate new Campaign Member Statuses');
        for(CampaignMemberStatus iStat : cmStatusList) {
            System.assert(expectedStatuses.contains(iStat.Label), 'Unexpected Campaign Member status for Event type : ' + iStat.Label);
        }
    }
    
    /**
     * @description Status updates to Campaign should modify the status of Event registration status
     */
    @isTest
    static void UpdateEventStatusTest() {

        //create blackthorn events
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        btEventList[0].conference360__Status__c = 'Active';
        insert btEventList;

        //create campaigns
        List<Campaign> campList = TestHelper.createEventCampaigns(1, btEventList);
        insert campList;

        System.assert(campList[0].id != null);

        Campaign upCamp = new Campaign();
        upCamp.id = campList[0].id;
        upCamp.Status = 'Cancelled';

        Test.startTest();

        //when
        update upCamp;

        Test.stopTest();

        List<conference360__Event__c> btUpdatedEventList = new List<conference360__Event__c>([SELECT id,conference360__Status__c
                                                                                              FROM conference360__Event__c WHERE
                                                                                              id =: btEventList[0].id ]);
        System.assertEquals('Canceled',btUpdatedEventList[0].conference360__Status__c,'Event Status is not updated');


    }

    /**
     * @description updates to Campaign active flag should be based on mapping available in the metadata
     */
    @isTest
    static void UpdateEventActiveFlagTest() {

        //create blackthorn events
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        btEventList[0].conference360__Status__c = 'Active';
        insert btEventList;

        //create campaigns
        List<Campaign> campList = TestHelper.createEventCampaigns(1, btEventList);
        insert campList;

        System.assert(campList[0].id != null);

        Campaign upCamp = new Campaign();
        upCamp.id = campList[0].id;
        upCamp.Status = 'In Progress';
        upCamp.isActive = false;
        Test.startTest();

        //when
        update upCamp;

        Test.stopTest();

        List<campaign> btUpdatedCampaignList = new List<campaign>([SELECT id,isactive
                                                                   FROM campaign WHERE
                                                                   id =: campList[0].id ]);
        System.assertEquals(true,btUpdatedCampaignList[0].isactive,'Campaign Active flag is false');


    }
     /**@description On test UpdateCompanyCampaignAppeal
     * If the record type is Appeal  and Company field is updated
     **/
    @isTest
    static void testcampaignWithCompany() {
        Id monashRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();

        Account acc = new Account(Name='testingAccountMonash;',RecordTypeId= monashRecordTypeId);
        insert acc;

        Alumni_Community_User_Access__c AlumniSetting = new Alumni_Community_User_Access__c();
        AlumniSetting.Id__c =acc.Id;
        insert AlumniSetting;
		System.assertNotEquals(null, AlumniSetting.Id__c);
		Id recId =Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Appeal').getRecordTypeId();
        List<Campaign> campaigns = new List<Campaign>();
	    Campaign campaignSix = new Campaign();
		campaignSix.RecordTypeId = recId;
        campaignSix.Name = 'TestingCampaign';
        campaignSix.Company__c = AlumniSetting.Id__c;
        campaigns.add(campaignSix);
        insert campaigns;
        System.assertNotEquals(null, campaigns[0].Company__c);
    }
}