/**
* @author Ibrahim Rumi
* @date 29 09 2020
* @description Sibling test class for BTAttendeeServices
* @revision
*   04.11.2020  Ibrahim Rumi    - EPBBS-1375 added method cancelRelatedAttendeeRegistration to handle cancellation of event registration by attendees
*   12.04.2021  Ibrahim Rumi    - EPBBS-1856 added method AutoRegisterAttendee to auto change the status from pending to registered
*   21.06.2021  Aref Samad      - EPBBS-1909 coverage for Defect fix country of residency and citizenship mapping in contact
*                                 added method shouldMapContactFieldsWhenCreateAttendeePerson360
*   12-07-2021  Ibrahim Rumi    - EPBBS-2067 added method shouldExpireWaitlistedAttendee to expire waitlisting for an attendee
*   18.10.2021  Ibrahim Rumi    - EPBBS-2183 Share newly inserted Attendee with existing event Staff
*   17.01.2022  Ibrahim Rumi    - EPBBS-2379 testAttendeeCapacity,allowDuplicateAttendee_Test,checkBatchDuplicateAttendee,DuplicateAttendeeOnCreation_Test
								  methods to Validate capacity and duplicates during attendee registration
*   08-02-2022  Ibrahim Rumi    - EPBBS-2427 updated cancelRelatedAttendeeRegistration test method to use attendeegroupid to process group cancellation
**/
@isTest(isParallel=true)
public class BTAttendeeServices_test {
    /**
     * @description Inserts records required for test methods
     * @revision Initial version 25 June 2020
     */
    @testSetup
    static void setup(){
        //create Relationship Settings
        bt_stripe__Relationship_Settings__c relSetting = TestHelper.createBTRelationshipSetting();
        insert relSetting;

        //create blackthorn event settings to enable auto create campaign on event insert
        conference360__Blackthorn_Events_Settings__c settings = new conference360__Blackthorn_Events_Settings__c();
		settings.Disable_Auto_Create_Campaign__c = false;
        settings.Waitlist_Registration_Expiry_hours__c = 24;
        insert settings;

        //create event settings
        conference360__Event_Settings__c eventSettings = TestHelper.createEventSettings(1)[0];
            eventSettings.conference360__Relationship_Settings__c  = relSetting.id;
        insert eventSettings;

        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        for(conference360__Event__c event:btEventList){
            event.conference360__Event_Settings__c = eventSettings.id;
            event.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
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

        //create blackthorn event attendee group
       	conference360__Attendee_Group__c attendee_Group = new conference360__Attendee_Group__c(
        	Name = 'BTAttendeeTriggerHandler_Test_Attendee_group'
        );
        insert attendee_Group;

        list<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendeeWithMatchingContacts(btEventList[0].Id, 2);

        TriggerCommon.disableTrigger('conference360__Attendee__c');

        conference360__Attendee__c attendee1 = attendeeList[0];
        attendee1.conference360__Registration_Status__c = 'Registered';
        attendee1.conference360__Attendee_Group__c = attendee_Group.id;
        attendee1.conference360__Event_Item__c  = eventItem.id;
        attendee1.Country_of_Residence__c='AUSTRALIA';
        attendee1.Nationality__c='BRAZIL';

        conference360__Attendee__c attendee2 = attendeeList[1];
        attendee2.conference360__Email2__c = '';
        attendee2.conference360__Registration_Status__c = 'Registered';
        attendee2.conference360__Attendee_Group__c = attendee_Group.id;

        insert attendeeList;
        TriggerCommon.enableTrigger('conference360__Attendee__c');

        //create test user
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        System.runAs(thisUser) {
            //create Test users with Base Profile
            TestHelper.createTestUsers('Base Profile', 1);
        }
        
        user u = [select id FROM user WHERE lastname like '%TestingUser%' AND Profile.name = 'Base Profile' LIMIT 1][0];
        
        TriggerCommon.disableTrigger('conference360__Staff__c');
        List<Conference360__Staff__c> stafflist = new List<Conference360__Staff__c>(); 
            Conference360__Staff__c staff = new conference360__Staff__c(conference360__User__c=u.Id,conference360__Event__c=btEventList[0].Id);
            stafflist.add(staff);
        Insert stafflist;
        TriggerCommon.enableTrigger('conference360__Staff__c');
    }
    /**
     * @author Ibrahim Rumi
     * @description updates attendee status to cancelled
     */
    @isTest
    static void cancelRelatedAttendeeRegistration() {
        //given
        Set<Id> idSet = new Set<Id>();
        for(conference360__Attendee__c att: [SELECT Id,is_Primary_Registrant__c,conference360__Attendee_Group__c
                                             FROM conference360__Attendee__c
                                             WHERE is_Primary_Registrant__c = true 
                                             AND conference360__Attendee_Group__c != null LIMIT 1])
        {
       		idSet.add(att.conference360__Attendee_Group__c);
        }
        Test.startTest();

        //when
		List<conference360__Attendee__c> attendeeList = BTAttendeeServices.processAttendeeCancellation(idSet);

        Test.stopTest();
		//then
        for(conference360__Attendee__c att: attendeeList){
            Assert.areEqual(att.conference360__Registration_Status__c,'Canceled');
        }
    }

     /**
     * @author Ibrahim Rumi
     * @description exception test of processAttendeeWaitlisting method when dao is null
     */
    @isTest
    static void processAttendeeWaitlistingException_test() {

        BTEventAttendeeDAO dao;
        String Message;

        Test.startTest();
        Try{

        //when
        BTAttendeeServices.processAttendeeWaitlisting(dao);

        } catch(Exception e){

            Message = e.getMessage();

        }
        Test.stopTest();

        //then
        Assert.areEqual(Message, 'Invalid null parameter');
    }

     /**
     * @author Ibrahim Rumi
     * @description exception test of processAttendeeCancellation method when dao is null
     */
    @isTest
    static void processAttendeeCancellationException_test() {

        Set<Id> attendeeIds;
        String Message;

        Test.startTest();
        Try{

        //when
        BTAttendeeServices.processAttendeeCancellation(attendeeIds);

        } catch(Exception e){

            Message = e.getMessage();

        }
        Test.stopTest();

        //then
        Assert.areEqual(Message, 'Invalid null parameter');
    }

    /**
     * @author Ibrahim Rumi
     * @description Test If attendees are automatically registered when Skip Pending for waitlisting is set to true
    */
    @isTest
    static void SkipWaitlisting_Test() {

        //given
        conference360__Event_Settings__c eventSettings = [SELECT Id FROM conference360__Event_Settings__c LIMIT 1];
        eventSettings.Skip_Pending_for_Waitlisting__c = true;
        update eventSettings;

        List <conference360__Attendee__c> attlist = [SELECT Id,conference360__Event__c FROM conference360__Attendee__c LIMIT 1];
        BTEventAttendeeDAOHelper helper = new BTEventAttendeeDAOHelper(attlist);
		BTEventAttendeeDAO evtAttDAO = helper.generateEventAttendeeDAO()[0];

        Test.startTest();
		BTEventAttendeeDAO processedEvtAttDAO = BTAttendeeServices.processAttendeeWaitlisting(evtAttDAO);
        //when

        Test.stopTest();
		conference360__Attendee__c att = processedEvtAttDAO.getAttendee();
        //then
        Assert.areEqual('Registered',att.conference360__Registration_Status__c);
    }

    /**
     * @author Ibrahim Rumi
     * @description identifies are set with waitlist regitration expiry hours based on value provided in the event settings
     */
    @isTest
    static void waitlistRegistrationExpiryTest() {

        //given
        conference360__Event_Settings__c eventSettings = [SELECT Id FROM conference360__Event_Settings__c LIMIT 1];
        eventSettings.Waitlist_Registration_Expiry__c = 4;
        update eventSettings;

        List <conference360__Attendee__c> attlist = [SELECT Id,conference360__Event__c,Registration_status_reason__c FROM conference360__Attendee__c LIMIT 1];
        BTEventAttendeeDAOHelper helper = new BTEventAttendeeDAOHelper(attlist);
		BTEventAttendeeDAO evtAttDAO = helper.generateEventAttendeeDAO()[0];

        Test.startTest();
		BTEventAttendeeDAO processedEvtAttDAO = BTAttendeeServices.processAttendeeWaitlisting(evtAttDAO);
        //when

        Test.stopTest();
		conference360__Attendee__c att = processedEvtAttDAO.getAttendee();
        //then
        Assert.areEqual(BTAttendeeServices.REG_STATUS_REASON_PENDING_WL_REG,att.Registration_status_reason__c);
    }

    /**
     * @author Ibrahim Rumi
     * @description identifies are set with waitlist regitration expiry hours based on value provided in the blackthorn event setting custom setting
     */
    @isTest
    static void waitlistRegistrationExpiryUsingCustomSettingTest() {

        //given
        List <conference360__Attendee__c> attlist = [SELECT Id,conference360__Event__c,Registration_status_reason__c FROM conference360__Attendee__c LIMIT 1];
        BTEventAttendeeDAOHelper helper = new BTEventAttendeeDAOHelper(attlist);
		BTEventAttendeeDAO evtAttDAO = helper.generateEventAttendeeDAO()[0];

        Test.startTest();
		BTEventAttendeeDAO processedEvtAttDAO = BTAttendeeServices.processAttendeeWaitlisting(evtAttDAO);
        //when

        Test.stopTest();
		conference360__Attendee__c att = processedEvtAttDAO.getAttendee();
        //then
        Assert.areEqual(BTAttendeeServices.REG_STATUS_REASON_PENDING_WL_REG,att.Registration_status_reason__c);
    }


    /**
     * @description if "winning affiliation" of an event is Prospective Student,
     * This should create an SPS record
     */
    @isTest
    static void shouldCreateAttendeePerson360() {
        // given
        conference360__Event__c btEvent = [SELECT Id, Audience_Type__c, conference360__Campaign__c, Winning_Affiliation__c, Broad_Area_of_Interest_Update_Mode__c
                                            FROM conference360__Event__c
                                            LIMIT 1];
        String attendeeFields = new BTAttendeeSelector().getFieldListString();
        conference360__Attendee__c btAttendee = (conference360__Attendee__c) Database.query('SELECT ' + attendeeFields +' FROM conference360__Attendee__c LIMIT 1')[0];

        Contact con = [SELECT Id,FirstName, LastName, Email, Monash_Email_Address__c, Nationality__c,
                        Personal_Email__c, Birthdate, AccountId, Gender__c, Country_of_Residence__c,
                        Birth_year__c
                        FROM Contact
                        WHERE Id = :btAttendee.conference360__Contact__c
                        LIMIT 1];

        BTContactAttendeeDAO dao = new BTContactAttendeeDAO(con);
        dao.addEventAttendee(btEvent, btAttendee);

        Test.startTest();

        //when
        BTAttendeeServices service = new BTAttendeeServices();
        service.createAttendeePerson360(new List<BTContactAttendeeDAO> { dao });

        Test.stopTest();

        //then
        Staged_Prospective_Student__c sps = [SELECT Id
                                            FROM Staged_Prospective_Student__c
                                            WHERE Exploded_Target__c = :con.Id
                                            LIMIT 1];
        Assert.isTrue(sps != null, 'Unable to create SPS record from Attendee');
    }

    /**
     * @description if "winning affiliation" of an event is Prospective Student,
     * This should create an SPS record and map missing contact fields(Country_of_Residence__c & Nationality__c) appropriately
     */
    @isTest
    static void shouldMapContactFieldsWhenCreateAttendeePerson360() {
        // given
        conference360__Event__c btEvent = [SELECT Id, Audience_Type__c, conference360__Campaign__c, Winning_Affiliation__c, Broad_Area_of_Interest_Update_Mode__c
                                            FROM conference360__Event__c
                                            LIMIT 1];
        String attendeeFields = new BTAttendeeSelector().getFieldListString();
        conference360__Attendee__c btAttendee = (conference360__Attendee__c) Database.query('SELECT ' + attendeeFields +' FROM conference360__Attendee__c LIMIT 1')[0];

        Contact con = [SELECT Id,FirstName, LastName, Email, Monash_Email_Address__c, Nationality__c,
                    Personal_Email__c, Birthdate, AccountId, Gender__c, Country_of_Residence__c,
                    Birth_year__c
                    FROM Contact
                    WHERE Id = :btAttendee.conference360__Contact__c
                    LIMIT 1];

        BTContactAttendeeDAO dao = new BTContactAttendeeDAO(con);
        dao.addEventAttendee(btEvent, btAttendee);

        Test.startTest();

        //when
        BTAttendeeServices service = new BTAttendeeServices();
        service.createAttendeePerson360(new List<BTContactAttendeeDAO> { dao });

        Test.stopTest();

        //then
        Staged_Prospective_Student__c sps = [SELECT Id
                                            FROM Staged_Prospective_Student__c
                                            WHERE Exploded_Target__c = :con.Id
                                            LIMIT 1];
        Assert.isTrue(sps != null, 'Unable to create SPS record from Attendee');


        Contact conUpdated = [SELECT Id,Country_of_Residence__c,Nationality__c
                                FROM Contact
                                WHERE Id = :btAttendee.conference360__Contact__c];

        Assert.areEqual('AUSTRALIA',conUpdated.Country_of_Residence__c, 'Country of residency not mapped correctly');
        Assert.areEqual('BRAZIL',conUpdated.Nationality__c, 'Nationality not mapped correctly');

    }

   /*
     * @description test if waitlisted attendee's registration status is canceled 
     */
    @isTest
    static void shouldExpireWaitlistedAttendee(){
        //given
         
        List <conference360__Attendee__c> attlist = [SELECT Id,conference360__Event__c,Registration_status_reason__c,conference360__Registration_Status__c
                                                     FROM conference360__Attendee__c LIMIT 1];
        
        Test.startTest();

        //when
        BTAttendeeServices service = new BTAttendeeServices();
        List<conference360__Attendee__c> updatedAttendee = service.expireWaitlistedAttendee(attlist);
        
        Test.stopTest();
        
        //THEN
        
        Assert.areEqual(BTAttendeeServices.REG_STATUS_REASON_WL_Expired,updatedAttendee[0].Registration_status_reason__c, 'Registration status reason not updated');
        Assert.areEqual(BTAttendeeServices.REG_STATUS_CANCELLED,updatedAttendee[0].conference360__Registration_Status__c, 'Registration status not updated');
        
    }

    //@description test if the newly created attendee is shared with existing Event staff 
    @isTest
    static void testshareAttendeeToEventStaff(){
        //given
		Set<Id> eventidSet = new Set<Id>();
        Set<Id> attendeeidSet = new Set<Id>();
        List<conference360__Event__c> eventList = [Select id FROM conference360__Event__c Limit 1];
        eventidSet.add(eventList[0].Id);
        
        List<conference360__Attendee__c> attList = [SELECT id,conference360__Event__c FROM conference360__Attendee__c 
                                            WHERE conference360__Event__c IN:eventidSet];
        
        for(conference360__Attendee__c att: attList){
            attendeeidSet.add(att.Id);
        }
        
        List<conference360__Attendee__share> attendeeShare = [SELECT parentId FROM conference360__Attendee__share WHERE parentId In:attendeeidSet 
                                                              AND RowCause = 'BT_Mobile_Check_in_App__c'];
        Assert.isTrue(attendeeShare.size()==0);
        
        //when
        Test.startTest();
        new BTAttendeeServices().shareAttendeeToEventStaff(attList,eventidSet);
        Test.stopTest();
        
        //then
        List<conference360__Attendee__share> attendeeShareUpdated = [SELECT parentId FROM conference360__Attendee__share WHERE parentId In:attendeeidSet
                                                                     AND RowCause = 'BT_Mobile_Check_in_App__c'];
        Assert.isTrue(attendeeShareUpdated.size()>0);
    }

    /*
     * @description test duplicate attendee within Database 
     */
    @isTest
    static void validateDuplicateAttendee(){
        //given
        conference360__Event_Settings__c eventSettings = [SELECT Id FROM conference360__Event_Settings__c LIMIT 1];
        eventSettings.Validate_Attendee_Registration__c = true;
        update eventSettings;
        
        List <conference360__Attendee__c> attlist = [SELECT Id,conference360__Event__c, conference360__Contact__c
                                                     FROM conference360__Attendee__c LIMIT 1];
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
        Assert.areEqual(true, expectedExceptionThrown, errorMessage.getMessage()); 
    }
    
    /*
     * @description test duplicate wattendee within TRIGGER 
     */
    @isTest
    static void DuplicateAttendeeOnCreation_Test(){
        //given
        
        conference360__Event__c event = [Select id FROM conference360__Event__c Limit 1];
        conference360__Event_Settings__c eventSettings = [SELECT Id FROM conference360__Event_Settings__c LIMIT 1];
        eventSettings.Validate_Attendee_Registration__c = true;
        update eventSettings;
        
        list<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendeeWithMatchingContacts(event.Id, 3);

        conference360__Attendee__c attendee1 = attendeeList[0];
        attendee1.conference360__Registration_Status__c = 'Registered';

		conference360__Attendee__c attendee2 = attendeeList[1];
        attendee2.conference360__Contact__c = attendee1.conference360__Contact__c;
        attendee2.conference360__Registration_Status__c = 'Registered';
        
        conference360__Attendee__c attendee3 = attendeeList[2];
        attendee3.conference360__Registration_Status__c = 'Registered';

        Test.startTest();
        Boolean exceptionThrown = false;
        Exception errorMessage;
        
        //when
        try{
            insert attendeeList;
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage = e;
        }
        Test.stopTest();
        
        //THEN
        Boolean expectedExceptionThrown =  (errorMessage.getMessage().contains('Attendee already registered to event')) ? true : false; 
        Assert.areEqual(true, expectedExceptionThrown, errorMessage.getMessage()); 
    }
    
    /*
     * @description test if an attendee is registered for multiple events 
     */
    @isTest
    static void allowDuplicateAttendee_Test(){
        //given
        conference360__Event_Settings__c eventSettings = [SELECT Id FROM conference360__Event_Settings__c LIMIT 1];
        eventSettings.Validate_Attendee_Registration__c = true;
        update eventSettings;
        
        //when  
        Test.startTest();        
        List<conference360__Attendee__c> attendeesWithContactAndEvents =  TestHelper.createBlackthornAttendeeWithMultipleEvents(3);
        string contactId = attendeesWithContactAndEvents[0].conference360__Contact__c;
        insert attendeesWithContactAndEvents;
        Test.stopTest();
        
        //THEN
        List<conference360__Attendee__c> attendeeList = [SELECT conference360__Event__c, conference360__Contact__c FROM conference360__Attendee__c WHERE conference360__Contact__c =: contactId];
        Assert.areEqual(attendeeList.size(), 3, 'Successfully registered Attendee for multiple events'); 
    }
    
    /*
     * 
     */
    @isTest
    static void testAttendeeCapacity(){
        conference360__Event_Settings__c eventSettings = [SELECT Id FROM conference360__Event_Settings__c LIMIT 1];
        eventSettings.Validate_Attendee_Registration__c = true;
        update eventSettings;
        
    	conference360__Event__c event = [Select id FROM conference360__Event__c 
                                         WHERE conference360__Event_Settings__c =: eventSettings.id Limit 1];
            
        Integer capacity = 1;
        event.conference360__Attendee_Limit__c = capacity;
        
        Update event;
        
        list<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendeeWithMatchingContacts(event.Id, 2);

        conference360__Attendee__c attendee1 = attendeeList[0];
        attendee1.conference360__Registration_Status__c = 'Registered';
        
        conference360__Attendee__c attendee2 = attendeeList[1];
        attendee2.conference360__Registration_Status__c = 'Registered';

        Test.startTest();
        Boolean exceptionThrown = false;
        Exception errorMessage;
        
        //when
        try{
            insert attendeeList;
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage = e;
        }
        Test.stopTest();
        
        //THEN
        Boolean expectedExceptionThrown =  (errorMessage.getMessage().contains('Event has reached the total capacity')) ? true : false; 
        Assert.areEqual(true, expectedExceptionThrown, errorMessage.getMessage()); 
    }
}