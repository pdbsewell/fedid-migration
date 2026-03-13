/**
 * @author Nick Guia
 * @date 18-08-2020
 * @group Event Management
 * @description Test class for BTAttendeeTriggerHandler.
 * @revision
  *   04.11.2020  Ibrahim Rumi    - EPBBS-1375 added method cancelRegistrationRelatedAttendee to handle cancellation of event registration by attendees
 *   12.04.2021  Ibrahim Rumi    - EPBBS-1856 added method AutoRegisterAttendee to auto change the status from pending to registered
 *   30.05.2021  Ibrahim Rumi    - EPBBS-1888 Deleting CancelRegistrationRelatedAttendee and AutoRegisterWaitlistedAttendee classes from handler.
 *   30.05.2021  Ibrahim Rumi    - EPBBS-1888 added method registrationStatusHandler_Test to test registrationStatusHandler
 *   18.08.2021  Aref Samad    - EPBBS-2087 Number Reg - Check In - add test mothod checkinGroupAttendeeHandler_Test for Check in Guest Attendees in
                                 attendee group when Primary attendee checked in
 *   18.10.2021  Ibrahim Rumi    - EPBBS-2183 test Share newly inserted Attendee with existing event Staff
 **/
@IsTest(isParallel=true)
private class BTAttendeeTriggerHandler_Test {

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
        conference360__Event_Item__c  eventItemGuest = new conference360__Event_Item__c(
            conference360__Item_Name__c  = 'Guest Attendee',
            conference360__Type__c  = 'Guest',
            conference360__Minimum_Quantity__c  = 0,
            conference360__Maximum_Quantity__c  = 10,
            conference360__Event__c = btEventList[0].Id
        );
        insert eventItemGuest;

        //create blackthorn event attendee group
       	conference360__Attendee_Group__c attendee_Group = new conference360__Attendee_Group__c(
        	Name = 'BTAttendeeTriggerHandler_Test_Attendee_group'
        );
        insert attendee_Group;

        //create Marketing Campaigns and custom setting
        Campaign mie = new Campaign();
        mie.Name = 'The Monash Info and Events for Prospective Students';
        mie.RecordTypeId = CampaignServices.SUB_LIST_RECTYPE;
        mie.Channel_Type__c = 'SMS;Email';
        mie.IsActive = true;

        Campaign mr = new Campaign();
        mr.Name = 'The Market research participation';
        mr.RecordTypeId = CampaignServices.SUB_LIST_RECTYPE;
        mr.Channel_Type__c = 'SMS;Email';
        mr.IsActive = true;

        List<Campaign> campList = new List<Campaign>();
        campList.add(mie);
        campList.add(mr);
        insert campList;

        Marketing_Subscription_List__c setting = new Marketing_Subscription_List__c();
        setting.MIE__c = mie.Id;
        setting.MR__c = mr.Id;
        insert setting;

        //create test user
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        System.runAs(thisUser) {
            //create Test users with Base Profile
            TestHelper.createTestUsers('Base Profile', 1);
        }
        
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        
        //create event staff
        TriggerCommon.disableTrigger('conference360__Staff__c');
        List<Conference360__Staff__c> stafflist = new List<Conference360__Staff__c>(); 
            Conference360__Staff__c staff = new conference360__Staff__c(conference360__User__c=u.Id,conference360__Event__c=btEventList[0].Id);
            stafflist.add(staff);
        Insert stafflist;
        TriggerCommon.enableTrigger('conference360__Staff__c');
    }

    /**
     * @description should be able to link new Attendees against existing Contact
     * using their key details : FN, LN, Email.
     */
    @isTest
    static void shouldLinkAttendeeToContact() {
        //given
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
        att.conference360__First_Name2__c = 'BTAttendeeTriggerHandler_Test';
        att.conference360__Last_Name2__c = 'test1';
        att.conference360__Email2__c = 'test@test.org';

        Test.startTest();

        //when
        insert att;

        Test.stopTest();

        //then
        att = [SELECT Id, conference360__Contact__c
            FROM conference360__Attendee__c
            WHERE Id = :att.Id
            LIMIT 1];
        System.assertEquals(existingCon.Id, att.conference360__Contact__c, 'attendee unable to match against existing contact');
    }

    /**
     * @description when an attendee registers for an event, and opts-in
     *  to marketing emails
     */
    @isTest
    static void shouldSubscribeToMarketingOnInsert() {

        //given
        Contact con = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];
        conference360__Event__c evRec = [SELECT Id FROM conference360__Event__c LIMIT 1];
        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(evRec.Id, 1)[0];
        attendee = matchWithContactDetails(attendee, con);
        attendee.conference360__Contact__c = con.Id;
        attendee.Marketing_Subscription_Opt_in__c = true; //opt-in to marketing emails

        Test.startTest();

        //when
        insert attendee;

        Test.stopTest();

        //then

        //due to error : INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
        //when platform events create campaign members in test class,
        //this cannot be asserted
        //ideally :
        //campaign members must have been created
        // Set<Id> subListIds = CommonUtilities.MARKETING_SUB_LISTS;
        // List<CampaignMember> subMembers = [SELECT Id
        //                                     FROM CampaignMember
        //                                     WHERE ContactId = :con.Id
        //                                     AND CampaignId IN :subListIds];
        // System.assert(!subMembers.isEmpty(), 'Unable to create subscription members');
    }

    /**
     * @description Subscribes the Contact linked to the Attendee if consent was provided.
     */
    @isTest
    static void shouldSubscribeToMarketingOnUpdate() {

        //given
        Contact con = [SELECT id, FirstName, LastName, Email FROM Contact LIMIT 1];
        conference360__Event__c evRec = [SELECT Id FROM conference360__Event__c LIMIT 1];
        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(evRec.Id, 1)[0];
        attendee = matchWithContactDetails(attendee, con);
        attendee.Marketing_Subscription_Opt_in__c = false; //opt-in to marketing emails
        insert attendee;

        Test.startTest();

        //when
        attendee.Marketing_Subscription_Opt_in__c = true;
        update attendee;

        Test.stopTest();

        //then

        //due to error : INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
        //when platform events create campaign members in test class,
        //this cannot be asserted
        //ideally :
        //campaign members must have been created
        // Set<Id> subListIds = CommonUtilities.MARKETING_SUB_LISTS;
        // List<CampaignMember> subMembers = [SELECT Id
        //                                     FROM CampaignMember
        //                                     WHERE ContactId = :con.Id
        //                                     AND CampaignId IN :subListIds];
        // System.assert(!subMembers.isEmpty(), 'Unable to create subscription members');
    }


    /**
     * @Author Ibrahim Rumi
     * @description Check registrationStatusHandler
     */
    @isTest
    static void registrationStatusHandler_Test() {

        conference360__Event__c btEvent = [SELECT Id,conference360__Event_Settings__c
                                        FROM conference360__Event__c
                                        LIMIT 1];
        conference360__Event_Settings__c btEventSetting = [SELECT Id, Skip_Pending_for_Waitlisting__c
            											   FROM conference360__Event_Settings__c
             											   WHERE Id =: btEvent.conference360__Event_Settings__c LIMIT 1];
        btEventSetting.Skip_Pending_for_Waitlisting__c = true;
        update btEventSetting;

        conference360__Attendee__c att = TestHelper.createBlackthornAttendeeWithMatchingContacts(btEvent.Id, 1)[0];
        //should match setup contact
        att.conference360__Registration_Status__c = 'Waitlisted - Pending';
        insert att;
        att.conference360__Registration_Status__c = 'Pending';

        //when
        Test.startTest();

        update att;
        //then
        Test.stopTest();
        conference360__Attendee__c updatedAttendee = [SELECT id, conference360__Registration_Status__c FROM conference360__Attendee__c
                                                      LIMIT 1];
        system.assertEquals('Registered', updatedAttendee.conference360__Registration_Status__c, 'Registration status not updated');
    }

    /**
     * @Author Ibrahim Rumi
     * @description ensures attendee details matches the contact
     *  so they can be linked together via matching rules
     */
    private static conference360__Attendee__c matchWithContactDetails(conference360__Attendee__c at, Contact con) {
        //make sure details match against contact record, so they can be linked
        at.conference360__First_Name2__c = con.FirstName;
        at.conference360__Last_Name2__c = con.LastName;
        at.conference360__Email2__c = con.Email;
        return at;
    }

    /**
     * @Author Aref Samad
     * @description EPBBS-2087 Number Reg - Check In - Check in Guest Attendees in attendee group when Primary attendee checked in
     */
    @isTest
    static void checkinGroupAttendeeHandler_Test() {

        //given

        List<conference360__Event__c> btEventList=[Select Id from conference360__Event__c];

        List<conference360__Attendee_Group__c> btEventGroupList=[Select Id from conference360__Attendee_Group__c];

        List<conference360__Event_Item__c> primaryEventItemList=[Select Id from conference360__Event_Item__c where conference360__Event__c=:btEventList[0].Id and conference360__Type__c  = 'Main event ticket'];
        List<conference360__Event_Item__c> guestEventItemList=[Select Id from conference360__Event_Item__c where conference360__Event__c=:btEventList[0].Id and conference360__Type__c  = 'Guest'];

        List<Contact> conList = [SELECT Id FROM Contact];

        List<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendee(btEventList[0].Id, 10);

       for(conference360__Attendee__c attendee:attendeeList)
        {
            attendee.conference360__Attendee_Group__c=btEventGroupList[0].Id;
            attendee.conference360__Contact__c=null;
            attendee.conference360__Attendance_Status__c='Pending';
            attendee.conference360__Event_Item__c=guestEventItemList[0].Id;
            attendee.conference360__Registration_Status__c=BTAttendeeServices.REG_STATUS_REGISTERED;
        }

        attendeeList[0].conference360__Contact__c=conList[0].Id;
        attendeeList[0].conference360__Event_Item__c=primaryEventItemList[0].Id;

        insert attendeeList;


        Test.startTest();

        //when
        attendeeList[0].conference360__Attendance_Status__c=BTAttendeeServices.ATTN_STATUS_ATTENDED;
        update attendeeList[0];

        Test.stopTest();

        //then
        List<conference360__Attendee__c> attendUpdatedList=[SELECT Id From conference360__Attendee__c
        WHERE conference360__Attendee_Group__c =:btEventGroupList[0].Id
        AND conference360__Attendance_Status__c=:BTAttendeeServices.ATTN_STATUS_ATTENDED];

        System.assertEquals(10,attendUpdatedList.size());
    }

        //@description EPBBS-2183 Test Sharing Attendee records with event staff
        @isTest
        static void ShareAttendeeToEventStaffTest(){
            //given
            conference360__Event__c evRec = [Select Id from conference360__Event__c][0];
            
            
            //when
            Test.startTest();
            conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(evRec.Id, 1)[0];
            Insert attendee;
            Test.stopTest();
            //then
            List<conference360__Attendee__c>attendeeList = [SELECT id FROM conference360__Attendee__c WHERE conference360__Event__c =:evRec.Id];
            List<conference360__Attendee__share> attendeeShareUpdated = [SELECT parentId FROM conference360__Attendee__share WHERE parentId =:attendeeList[0].Id
                                                                         AND RowCause = 'BT_Mobile_Check_in_App__c'];
            system.assert(attendeeShareUpdated.size()>0);
        }

        /*
     * @description test if waitlisted attendee's registration status is canceled 
     */
    @isTest
    static void checkDuplicateAttendee_Should_Throw_Error(){
        //given
        conference360__Event__c btEvent = [SELECT Id,conference360__Event_Settings__c
                                        FROM conference360__Event__c
                                        LIMIT 1];
        
        List<conference360__Attendee__c> attlist = TestHelper.createBlackthornAttendeeWithMatchingContacts(btEvent.Id, 1);
        
        for(conference360__Attendee__c att: attlist){
            att.conference360__Registration_Status__c = 'Registered';
        }
		insert attlist;
        
        conference360__Event_Settings__c eventSettings = [SELECT Id FROM conference360__Event_Settings__c LIMIT 1];
        eventSettings.Validate_Attendee_Registration__c = true;
        update eventSettings;
        
        List<conference360__Attendee__c> newAttendeeList = new List <conference360__Attendee__c>();
        conference360__Attendee__c newAttendee = new conference360__Attendee__c();
        newattendee.conference360__Event__c = attlist[0].conference360__Event__c;
        newattendee.conference360__Contact__c = attlist[0].conference360__Contact__c;
        newattendee.conference360__Registration_Status__c = 'Registered';
        newAttendeeList.add(newattendee);
        
        Test.startTest();
        Boolean exceptionThrown = false;
        Exception errorMessage;
        
        //when
        try{
            insert newAttendeeList;
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage = e;
        }
        Test.stopTest();
        
        //THEN
        Boolean expectedExceptionThrown =  (errorMessage.getMessage().contains('Attendee already registered to event')) ? true : false; 
        System.AssertEquals(true, expectedExceptionThrown, errorMessage.getMessage()); 
    }

}