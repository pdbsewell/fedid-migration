/**
 * @author	        AP.Rivera
 * @description     This class implements methods invoked from CampaignMemberServices.
 * @group           Test Class
 * @revision        30/08/2017  Nick Guia   - added test coverage for qualifyCreateSubscriptionMember <br/>
 *                  27/06/2018  Nick Guia   - removed all reference to Subscription_List__c and Subscripton_Member__c (for deletion) <br/>
 *                  15/07/2018  APRivera    - Added test coverage for processMonTrackCampaignMembers <br/>
 *                  11/12/2019  APRivera    - Deprecated unused test methods and updated the rest to fix Mixed DML error. <br/>
 *                  12/08/2021  ASamad      - Added test coverage for UpdateNumberOfAttendees (EPBBS-2129) <br/>
 *          	    SEP.13.2024 Inderpal Dhanoa - Sync TimeZone(MCT-490)
 * 					31/10/2024	Rumi		- Fixed erroring assert statements in UpdateNumberOfAttendees test method
**/
@isTest// (isParallel=true)  In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
private class CampaignMemberServices_Test {

    @TestSetup
	static void setup(){
        List<Contact> conList = TestHelper.createProspectiveStudentContact(2);
        insert conList;

		//create Campaigns
		List<Campaign> campaignList = new List<Campaign>{
            new Campaign (
                Name = 'Monash Info and Events for Prospective Students',
                Channel_Type__c = 'Email;SMS',
                RecordTypeId = CampaignServices.SUB_LIST_RECTYPE
            ),
            new Campaign (
                Name = 'Market research participation',
                Channel_Type__c = 'Email;SMS',
                RecordTypeId = CampaignServices.SUB_LIST_RECTYPE
            ),
            new Campaign (
                Name = 'Open Day',
                Channel_Type__c = 'Email;SMS',
                RecordTypeId = CampaignServices.SUB_LIST_RECTYPE
            ),
            new Campaign(
                Name = 'Test Event Campaign',
                RecordTypeId = CampaignServices.EVENT_RECTYPE,
                IsActive = true,
                CampaignMemberRecordTypeId = CampaignMemberServices.RECORDTYPE_EVENT_ATTENDEE
            )
        };
		//insert campaigns
        insert campaignList;

        //add contacts to campaigns
        List<CampaignMember> cmList = new List<CampaignMember>();
        for(Contact iCon : conList) {
            cmList.add(new CampaignMember(
                CampaignId = campaignList[0].Id,
                ContactId = iCon.Id
            ));
            cmList.add(new CampaignMember(
                CampaignId = campaignList[1].Id,
                ContactId = iCon.Id
            ));
            cmList.add(new CampaignMember(
                CampaignId = campaignList[2].Id,
                ContactId = iCon.Id
            ));
        }
        insert cmList;

         //create Relationship Settings
         bt_stripe__Relationship_Settings__c relSetting = TestHelper.createBTRelationshipSetting();
         insert relSetting;

         //create event settings
         conference360__Event_Settings__c eventSettings = new conference360__Event_Settings__c(
             Name = 'BTAttendeeTriggerHandler_Test_event_settings',
             conference360__Relationship_Settings__c  = relSetting.id
         );
         insert eventSettings;


         //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        for(conference360__Event__c event:btEventList){
            event.conference360__Event_Settings__c = eventSettings.id;
        }
        insert btEventList;

         //create blackthorn event item
        conference360__Event_Item__c  eventItem = new conference360__Event_Item__c(
            conference360__Item_Name__c  = 'Primary Attendee',
            conference360__Type__c  = 'Main event ticket',
            conference360__Minimum_Quantity__c  = 1,
            conference360__Maximum_Quantity__c  = 1,
            conference360__Event__c = btEventList[0].Id
        );
        insert eventItem;

          //create blackthorn event item
        conference360__Event_Item__c  eventItemOther = new conference360__Event_Item__c(
            conference360__Item_Name__c  = 'Other Attendee',
            conference360__Type__c  = 'Other',
            conference360__Minimum_Quantity__c  = 0,
            conference360__Maximum_Quantity__c  = 10,
            conference360__Event__c = btEventList[0].Id
        );
        insert eventItemOther;

         //create blackthorn event attendee group
        conference360__Attendee_Group__c attendee_Group = new conference360__Attendee_Group__c(
            Name = 'BTAttendeeTriggerHandler_Test_Attendee_group'
        );
        insert attendee_Group;
	}

    @IsTest
    public static void setPureCloudTimeZoneTest(){
        Id genericRecordTypeId = Schema.SObjectType.CampaignMember.getRecordTypeInfosByName().get('Generic').getRecordTypeId();
        Id retentionRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Retention').getRecordTypeId();
        
        Campaign camp1 = (Campaign)TestDataFactory.createSObject(new Campaign(Name='setPureCloudTimeZone Test', IsActive=true, recordTypeId = retentionRecordTypeId, 
                                                                            CampaignMemberRecordTypeId = genericRecordTypeId), true);
        

        Contact cont1 = (Contact)TestDataFactory.createSObject(new Contact(LastName='Smith1', FirstName='John1', Email='test1@test1.com'), true);

        Test.startTest();
        TestDataFactory.createSObject(new CampaignMember(CampaignId = camp1.Id, ContactId = cont1.Id), true); 

        List<CampaignMember> cmp = [SELECT Id, RecordType.DeveloperName, purecloud__Time_Zone__c FROM CampaignMember WHERE Campaign.Name ='setPureCloudTimeZone Test' ORDER BY CreatedDate DESC LIMIT 1];
        Assert.areEqual(cmp[0].purecloud__Time_Zone__c, 'Australia/Sydney (+11:00)', 'Not synced setPureCloudTimeZone');
    }

    static testMethod void updateMonTrackCampaignMembers(){
        Id cmpRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('MonTrack').getRecordTypeId();
        Id taskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('MonTrack').getRecordTypeId();

        Test.startTest();
        List<Contact> lstCont = new List<Contact>();
        lstCont.add(new Contact(LastName='TestCon1'));
        lstCont.add(new Contact(LastName='TestCon2'));
        insert lstCont;

        Campaign cmp = new Campaign(Name='Semester 1 - Round 1', IsActive=true, RecordTypeId = cmpRecordTypeId);
        insert cmp;

        User u = TestHelper.ssaUser();
        List<CampaignMember> lstCmpMember = new List<CampaignMember>{
                new CampaignMember(CampaignId = cmp.Id, SSA__c = UserInfo.getUserId(), ContactId = lstCont.get(0).Id),
                new CampaignMember(CampaignId = cmp.Id, SSA__c = u.Id, ContactId = lstCont.get(1).Id)
        };
        insert  lstCmpMember;

        List<Task> lstTasks = [Select Id,Status, Offer_Status__c from Task where RecordTypeId =: taskRecordTypeId];
        System.assertEquals(lstTasks.size(), 2);

        CampaignMember cmpMember = lstCmpMember.get(1);
        cmpMember.SSA__c = UserInfo.getUserId();
        update cmpMember;
        Test.stopTest();

        List<Task> lstMonTrackTasks = [Select ownerId from Task where OwnerId =: UserInfo.getUserId()];
        System.assertEquals(lstMonTrackTasks.size(), 2);
    }

    static testMethod void deleteMonTrackCampaignMembers(){
        Id cmpRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('MonTrack').getRecordTypeId();
        Id taskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('MonTrack').getRecordTypeId();

        Test.startTest();
        List<Contact> lstCont = new List<Contact>();
        lstCont.add(new Contact(LastName='TestCon1'));
        lstCont.add(new Contact(LastName='TestCon2'));
        insert lstCont;

        Campaign cmp = new Campaign(Name='Semester 1 - Round 1', IsActive=true, RecordTypeId = cmpRecordTypeId);
        insert cmp;

        User u = TestHelper.ssaUser();
        List<CampaignMember> lstCmpMember = new List<CampaignMember>{
                new CampaignMember(CampaignId = cmp.Id, SSA__c = UserInfo.getUserId(), ContactId = lstCont.get(0).Id),
                new CampaignMember(CampaignId = cmp.Id, SSA__c = u.Id, ContactId = lstCont.get(1).Id)
        };
        insert  lstCmpMember;

        List<Task> lstTasks = [Select Id,Status, Offer_Status__c from Task where RecordTypeId =: taskRecordTypeId];
        System.assertEquals(lstTasks.size(), 2);

        CampaignMember cmpMember = lstCmpMember.get(1);
        delete cmpMember;
        Test.stopTest();

        List<Task> lstMonTrackTasks = [Select ownerId from Task where OwnerId =: UserInfo.getUserId()];
        System.assertEquals(lstMonTrackTasks.size(), 1);

    }

    static testMethod void populateEmailToFieldTest() {
        List<Contact> contactRecordList = BMS_TestDataHelper.buildSampleContacts();
        insert contactRecordList;

        EmailTemplate template = BMS_TestDataHelper.buildTemplate();

        Campaign massEmail = BMS_TestDataHelper.buildSampleCRMMassEmail(template.Name);
        massEmail.Batch_Finished__c = true;
        insert massEmail;

        CampaignMember campMem = new CampaignMember();
        campMem.ContactId = contactRecordList[0].Id;
        campMem.CampaignId = massEmail.Id;
        campMem.Status = 'Ready to Send';
        insert campMem;
    }

    /**
     * @description test the unsubscribe function being used in Lightning Component
     * this requires the specifically named setup campaigns in test setup
     */
    @isTest
	static void unsubscribeServiceTest() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
            CampaignMemberServices.CampaignUnsubPayload payload =
                new CampaignMemberServices.CampaignUnsubPayload();
            payload.contactId = con.Id;
            payload.isMieUnsub = true;
            payload.isMrUnsub = true;
            payload.isOpenDayUnsub = true;
            payload.source = 'test class';
            payload.reason = 'test class';

            CampaignMemberServices.unsubscribeService(JSON.serialize(payload));
        Test.stopTest();

        List<CampaignMember> cmList = [SELECT Id, Active__c FROM CampaignMember WHERE ContactId = :con.Id];

        for(CampaignMember iCm : cmList) {
            System.assert(!iCm.Active__c, 'Failed to unsubscribe from Campaign');
        }
    }

    /**
     * @description test function call for subscribing into
     *  Email marketing subscription Lists
     */
    @isTest
    static void shouldSubscribeToEmailMarketing() {

        //given

        Campaign subList;
        Campaign eventCamp;
        for(Campaign iCamp : [SELECT Id, Channel_Type__c, RecordTypeId FROM Campaign]) {
            if(iCamp.RecordTypeId == CampaignServices.EVENT_RECTYPE) {
                eventCamp = iCamp;
            } else if(iCamp.RecordTypeId == CampaignServices.SUB_LIST_RECTYPE) {
                subList = iCamp;
            }
        }

        List<Contact> conList = [SELECT Id FROM Contact LIMIT 2];
        CampaignMember cm1 = new CampaignMember(CampaignId = subList.Id, ContactId = conList[0].Id);
        CampaignMember cm2 = new CampaignMember(CampaignId = eventCamp.Id, ContactId = conList[1].Id);

        Test.startTest();

        //when

        //with subscription source as a string
        cm1 = CampaignMemberServices.subscribeToEmail(subList, cm1, 'Web');
        //with subscription source as a campaign
        cm2 = CampaignMemberServices.subscribeToEmail(subList, cm2, eventCamp.Id);

        Test.stopTest();

        //then

        System.assertEquals('Web', cm1.Email_Subscription_Source__c, 'Unexpected email subscription source');
        System.assertEquals(true, cm1.ChannelEmail__c, 'Unable to activate Email channel subscription');
        System.assertEquals(true, cm1.Active__c, 'Unable to activate CampaignMember');
        System.assert(cm1.Email_Subscribed_Date__c != null, 'Unable to set subscribed date');

        System.assertEquals('Campaign', cm2.Email_Subscription_Source__c, 'Unexpected email subscription source');
        System.assertEquals(eventCamp.Id, cm2.Email_Subscription_Source_Campaign__c, 'Unexpected email subscription source campaign');
        System.assertEquals(true, cm2.ChannelEmail__c, 'Unable to activate Email channel subscription');
        System.assertEquals(true, cm2.Active__c, 'Unable to activate CampaignMember');
        System.assert(cm2.Email_Subscribed_Date__c != null, 'Unable to set subscribed date');
    }

    /**
     * @description test function call for subscribing into
     *  SMS marketing subscription Lists
     */
    @isTest
    static void shouldSubscribeToSMSMarketing() {

        //given

        Campaign subList;
        Campaign eventCamp;
        for(Campaign iCamp : [SELECT Id, Channel_Type__c, RecordTypeId FROM Campaign]) {
            if(iCamp.RecordTypeId == CampaignServices.EVENT_RECTYPE) {
                eventCamp = iCamp;
            } else if(iCamp.RecordTypeId == CampaignServices.SUB_LIST_RECTYPE) {
                subList = iCamp;
            }
        }

        List<Contact> conList = [SELECT Id FROM Contact LIMIT 2];
        CampaignMember cm1 = new CampaignMember(CampaignId = subList.Id, ContactId = conList[0].Id);
        CampaignMember cm2 = new CampaignMember(CampaignId = eventCamp.Id, ContactId = conList[1].Id);

        Test.startTest();

        //when

        //with subscription source as a string
        cm1 = CampaignMemberServices.subscribeToSMS(subList, cm1, 'Web');
        //with subscription source as a campaign
        cm2 = CampaignMemberServices.subscribeToSMS(subList, cm2, eventCamp.Id);

        Test.stopTest();

        //then

        System.assertEquals('Web', cm1.SMS_Subscription_Source__c, 'Unexpected email subscription source');
        System.assertEquals(true, cm1.ChannelSMS__c, 'Unable to activate Email channel subscription');
        System.assertEquals(true, cm1.Active__c, 'Unable to activate CampaignMember');
        System.assert(cm1.SMS_Subscribed_Date__c != null, 'Unable to set subscribed date');


        System.assertEquals('Campaign', cm2.SMS_Subscription_Source__c, 'Unexpected email subscription source');
        System.assertEquals(eventCamp.Id, cm2.SMS_Subscription_Source_Campaign__c, 'Unexpected email subscription source campaign');
        System.assertEquals(true, cm2.ChannelSMS__c, 'Unable to activate Email channel subscription');
        System.assertEquals(true, cm2.Active__c, 'Unable to activate CampaignMember');
        System.assert(cm2.SMS_Subscribed_Date__c != null, 'Unable to set subscribed date');
    }

   /**
     * @author Aref Samad
     * @desciription Added test coverage for UpdateNumberOfAttendees (EPBBS-2129) for Primary
     */
    @isTest
    static void updateNumberOfAttendeesForPrimaryTest() {

        //given

        List<conference360__Event__c> btEventList=[Select Id from conference360__Event__c];

        List<conference360__Attendee_Group__c> btEventGroupList=[Select Id from conference360__Attendee_Group__c];

        List<conference360__Event_Item__c> primaryEventItemList=[Select Id from conference360__Event_Item__c where conference360__Event__c=:btEventList[0].Id and conference360__Type__c  = 'Main event ticket'];
        List<conference360__Event_Item__c> otherEventItemList=[Select Id from conference360__Event_Item__c where conference360__Event__c=:btEventList[0].Id and conference360__Type__c  = 'Other'];

        List<Contact> conList = [SELECT Id FROM Contact];

        List<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendee(btEventList[0].Id, 10);

        for(conference360__Attendee__c attendee:attendeeList)
        {
            attendee.conference360__Attendee_Group__c=btEventGroupList[0].Id;
            attendee.conference360__Contact__c=null;
            attendee.conference360__Event_Item__c=otherEventItemList[0].Id;
        }

        attendeeList[0].conference360__Contact__c=conList[0].Id;
        attendeeList[0].conference360__Event_Item__c=primaryEventItemList[0].Id;

        insert attendeeList;

        List<Campaign> eventCampList=[SELECT Id, Channel_Type__c, RecordTypeId FROM Campaign where RecordTypeId=:CampaignServices.EVENT_RECTYPE];

        Test.startTest();

        //when

        CampaignMember cm2 = new CampaignMember(CampaignId = eventCampList[0].Id, ContactId = conList[0].Id,conference360__Attendee__c=attendeeList[0].Id);
        insert cm2;

        Test.stopTest();

        //then
        List<CampaignMember> campaignMemberList=[Select Id, Number_of_Attendees__c from CampaignMember where RecordTypeId=:CampaignMemberServices.RECORDTYPE_EVENT_ATTENDEE];

        Assert.isTrue(campaignMemberList.size()>0,'campaignMemberList is empty');
        Assert.areEqual(10,campaignMemberList[0].Number_of_Attendees__c,'number of attendees shows lesser value than expected');

    }

     /**
     * @author           Aref Samad
     * @desciription     Added test coverage for UpdateNumberOfAttendees (EPBBS-2129) for Non Primary
     */
    @isTest
    static void updateNumberOfAttendeesForNonPrimaryTest() {

        //given

        List<conference360__Event__c> btEventList=[Select Id from conference360__Event__c];

        List<conference360__Attendee_Group__c> btEventGroupList=[Select Id from conference360__Attendee_Group__c];

        List<conference360__Event_Item__c> otherEventItemList=[Select Id from conference360__Event_Item__c where conference360__Event__c=:btEventList[0].Id and conference360__Type__c  = 'Other'];

        List<Contact> conList = [SELECT Id FROM Contact];

        List<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendee(btEventList[0].Id, 2);

        for(conference360__Attendee__c attendee:attendeeList)
        {
            attendee.conference360__Attendee_Group__c=btEventGroupList[0].Id;
            attendee.conference360__Contact__c=null;
            attendee.conference360__Event_Item__c=otherEventItemList[0].Id;
        }

        attendeeList[0].conference360__Contact__c=conList[0].Id;

        insert attendeeList;

        List<Campaign> eventCampList=[SELECT Id, Channel_Type__c, RecordTypeId FROM Campaign where RecordTypeId=:CampaignServices.EVENT_RECTYPE];

        Test.startTest();

        //when

        CampaignMember cm2 = new CampaignMember(CampaignId = eventCampList[0].Id, ContactId = conList[0].Id,conference360__Attendee__c=attendeeList[0].Id);
        insert cm2;

        Test.stopTest();

        //then
        List<CampaignMember> memberList=[Select Id, Number_of_Attendees__c from CampaignMember where RecordTypeId=:CampaignMemberServices.RECORDTYPE_EVENT_ATTENDEE];

        Assert.isTrue(memberList.size()>0,'campaignMemberList is empty');
        Assert.areEqual(1,memberList[0].Number_of_Attendees__c,'number of attendees shows lesser value than expected');

    }
}