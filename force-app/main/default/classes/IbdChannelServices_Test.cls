/**
 * @author          Stefan Scheit
 * @description     Class to test platform event processing for Channel__c objects
 * @history         04/03/2018 - Stefan Scheit - Externalised the InbChannelEventHandlerTest classes from InbEventTest
 *                  16/03/2018 - Gabriel Ludik - Added Test method for OS-HOME country should = line 4 (SF-1028)
 *                  21/03/2018 - Stefan Scheit - Added test for email containing characters: +.-_
 *                  11/10/2018 - Shalini Mendu - Added methods to simulate multiple events and reproduce duplicateIds
 *                  22/02/2019 - Martin Cadman - Specific tests for Stubbed contacts
 *                  02/03/2020 - Stefan Scheit - Added test for email-only channels
 *                  01/08/2022 - Nick Guia     - removed unused reference to Platform_Event_Integration__mdt
 *                  01/06/2025 - Martin Cadman - Moved to Assert class
 *                  01/07/2025 - Martin Cadman - Emergency Contact test added, including relationship transformation
 *                  21/11/2025 - Martin Cadman - Graduation Aplication end date test added
 */
@isTest(isParallel=true)
public class IbdChannelServices_Test {
  
    /*
     * @description Test specific data setup
     */
    @TestSetup
    public static void setup() {
        triggerCommon.disableTrigger('Contact');

        insert new Country_Attribute__c(
			name = 'Zimbabwe'
			, Callista_Code__c = '9232'
            , Callista_Country__c = 'Zimbabwe' 
            , Country__c = 'Zimbabwe' 
            , GTE_Risk_Rating__c = '2'
            , ISO_Alpha_2__c = 'ZW'
            , ISO_Alpha_3__c = 'ZWE'
            , Numeric_Country_Code__c = '716'
        );

        insert new Country_Attribute__c(
            name = 'Hong Kong (Sar Of China)'
            , Callista_Code__c = '6102'
            , Callista_Country__c = 'Hong Kong (SAR of China)' 
            , Country__c = 'Hong Kong' 
            , GTE_Risk_Rating__c = '1'
            , ISO_Alpha_2__c = 'HK'
            , ISO_Alpha_3__c = 'HKG'
            , Numeric_Country_Code__c = '852'
        );
        
        // One of the China records
        insert new Country_Attribute__c(
			name = 'China (Excl Sars And Taiwan Prov)'
			, Callista_Code__c = '6101'
            , Callista_Country__c = 'China (Excludes Sars And Taiwan Province)'
            , Country__c = 'China'
            , GTE_Risk_Rating__c = '1'
            , ISO_Alpha_2__c = 'CN'
            , ISO_Alpha_3__c = 'CHN'
            , ShortName__c = 'PR CHINA'
            , State_Name__c = 'Peoples Repubic of China'
            , ALT_Name_1__c = 'China (Excludes Sars Taiwan Province)'
            , ALT_Name_2__c = 'China (Excludes Sars  Taiwan Province)'
            , Numeric_Country_Code__c = '156'
        );
        
        // Allow phone values to be formatted
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Format_Mobile__c = true;
        fs.Process_Emergency_Contacts__c = true;
        fs.EndDateGraduationChannels__c = true;
        insert fs;
        
        //Enable Channel break up
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        
        PlatformEventControl__c pec = new PlatformEventControl__c();
        pec.channel_event__c = 20;
        pec.Async_Process__c = 20;
        pec.Contact_Point_Event__c = 20;
        insert pec;   

    }

    /*
     * @description  Test method for mapping of EMERCONT channel type from Callista 
     * WHEN - a EMERCONT channel is received
     * GIVEN - the mandatory fields are populated
     * THEN - the relationship and full name fields should be mapped correctly
     * 
     * This is not testing the creation of any resulting EC record, just the channel staging record
     */
    @isTest
    public static void validate_EmergencyContactMapping() {
        Contact new2C = new Contact(Person_ID_unique__c='30000123', LastName='Simons', FirstName='Jenny');
        insert new2C;

        IbdChannel__e insertChannel = new IbdChannel__e(Event_Type__c='INSERT',
                                                        Last_Modified_Datetime__c=date.today(),
                                                        Last_Modified_By__c='TEST.API.USER',
                                                        Address_Type__c='EMERCONT',
                                                        Start_Date__c=Date.today() ,
                                                        Previous_Start_Date__c=Date.today() ,
                                                        Address_Line_1__c='Sally Simons',
                                                        Address_Line_2__c='Mum and Dad',
                                                        Address_Line_3__c='24 Lycong St',
                                                        Address_Line_5__c='Hong Kong (Sar Of China)', // test some options
                                                        OS_Post_Code__c='3153',
                                                        Email__c='so-m.e_one+30@something.com',
                                                        Phone__c='03 8888 5555',
                                                        Mobile_Phone__c='0455 555 555',
                                                        Person_ID__c='30000123'
                                                       );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertChannel);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        

        List<Channel__c> ch = [SELECT Id, Line_1__c, Line_2__c, Line_3__c, relationship__c, relationship_unverified__c, Fullname__c, street__c, country__c
                               from Channel__c];
        Assert.areEqual(1, ch.size());
        
		// Demonstrates different field mapping for EMERCONT records
        Assert.areEqual(ch[0].Line_1__c, ch[0].Fullname__c);
        Assert.areEqual(ch[0].Line_2__c, ch[0].relationship_unverified__c);
        Assert.areEqual('Parent', ch[0].relationship__c); // No transforms yet
        Assert.areEqual(ch[0].Line_3__c, ch[0].street__c);
        Assert.areEqual(countryServices.getCountryName('Hong Kong', CountryServices.FORMAT_ISO), ch[0].country__c);
    }

    /*
     * @description Handle the situation when a delete event is recieved for a record we don't have
     * WHEN - A delete event is sent
     * GIVEN - the target record doesn't exist
     * THEN - nothing bad happens
     */
    @isTest
    public static void validate_EmergencyContactDeleteWithoutCreate() {
        Contact new2C = new Contact(Person_ID_unique__c='30000123', LastName='Simons', FirstName='Jenny');
        insert new2C;
        
        // Try and delete something that isn't here
        IbdChannel__e insertChannel = new IbdChannel__e(Event_Type__c='DELETE',
                                                        Last_Modified_Datetime__c=date.today(),
                                                        Address_Type__c='EMERCONT',
                                                        Start_Date__c=Date.today() ,
                                                        Person_ID__c='30000123'
                                                       );
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertChannel);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        List<Channel__c> ch = [SELECT Id, Line_1__c, Line_2__c, Line_3__c, relationship__c, relationship_unverified__c, Fullname__c, street__c, country__c
                               from Channel__c];
        Assert.areEqual(0, ch.size());
    }
    
    /*
     * @description Delete a record
     * WHEN - a channel is in place
     * GIVEN - a delete event is sent
     * THEN - the delete flag should be set to true
     */
    @isTest
    public static void validate_EmergencyContactDeleteAfterCreate() {
        Contact new2C = new Contact(Person_ID_unique__c='30000555', LastName='Simons', FirstName='Jenny');
        insert new2C;

        IbdChannel__e insertChannel = new IbdChannel__e(Event_Type__c='INSERT',
                                                        Last_Modified_Datetime__c=date.today(),
                                                        Last_Modified_By__c='TEST.API.USER',
                                                        Address_Type__c='EMERCONT',
                                                        Start_Date__c=Date.today() ,
                                                        Previous_Start_Date__c=Date.today() ,
                                                        Address_Line_1__c='Sally Simons',
                                                        Address_Line_2__c='Mum and Dad',
                                                        Address_Line_3__c='24 Lycong St',
                                                        Address_Line_5__c='Hong Kong (Sar Of China)', // test some options
                                                        OS_Post_Code__c='3153',
                                                        Email__c='so-m.e_one+30@something.com',
                                                        Phone__c='03 8888 5555',
                                                        Mobile_Phone__c='0455 555 555',
                                                        Person_ID__c='30000555'
                                                       );

        Test.startTest();
        Database.SaveResult src = EventBus.publish(insertChannel);
        Test.getEventBus().deliver();
        list<channel__c> ch = [select id, Type__c, Start_Date__c, Person_ID__c, Unique_Id__c,  deleted_in_source__c, is_active__c from channel__c where person_id__c = '30000555' and type__c = 'EMERCONT'];
        Assert.areEqual(1, ch.size(),'Original channel was not created');
        
        insertChannel = new IbdChannel__e(Event_Type__c='DELETE',
                                          Last_Modified_Datetime__c=date.today(),
                                          Address_Type__c='EMERCONT',
                                          Start_Date__c=Date.today() ,
                                          Person_ID__c='30000555'
                                         );
        src = EventBus.publish(insertChannel);
        Test.getEventBus().deliver();
        Test.stopTest();

        ch = [SELECT Id from Channel__c where deleted_in_source__c = true];
        Assert.areEqual(1, ch.size(),'Channel was not marked for deletion');
    }
    
    
    /*
     * @description 
     * WHEN - a graduation application channel is in place
     * GIVEN - a new GA channel is received
     * THEN - the existing GS channel should be end dated and the new one active - requires the feature switch to be enabled
     *  
     */
    @isTest
	public static void validate_graduationApp() {
        Contact contact = new Contact(Person_ID_unique__c='30030011',LastName='Student',FirstName='Graduate');
        insert contact;
        
        IbdChannel__e chEvent = new IbdChannel__e(Event_Type__c='INSERT',
                                             Last_Modified_Datetime__c = datetime.newInstance(2024, 11, 23, 09, 00, 00),
                                             Last_Modified_By__c = 'TEST.API.USER',
                                             Address_Type__c = 'GRADUATION-APPL',
                                             Start_Date__c = Date.today()-10,
                                             Email__c = 'gs@test.com',
                                             Person_ID__c = '30030011'
                                            );
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(chEvent);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());

        // Change the start date to create a new key
        chEvent = new IbdChannel__e(Event_Type__c='INSERT',
                                    Last_Modified_Datetime__c = datetime.newInstance(2024, 11, 23, 09, 00, 00),
                                    Last_Modified_By__c = 'TEST.API.USER',
                                    Address_Type__c = 'GRADUATION-APPL',
                                    Start_Date__c = Date.today(),
                                    Email__c = 'gs@test.com',
                                    Person_ID__c = '30030011'
                                   );        
        sr = EventBus.publish(chEvent);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Second event could not be published. Errors: ' + sr.getErrors());

        Test.stopTest();        
        
        List<Channel__c> chList = [SELECT Id, Start_Date__c,End_Date__c, email__c
                                 FROM Channel__c 
                                WHERE Contact__r.Person_Id_unique__c='30030011' order by start_date__c];
        
        Assert.areEqual(2, chList.size());

        Channel__c c1 = chList[0];
        Channel__c c2 = chList[1];

        Assert.areEqual(c1.start_date__c, Date.today()-10); // Original start date is untouched       
        Assert.areEqual(c1.end_date__c, Date.today(), 'The original channel should be end-dated'); // Original channel is inactive
        Assert.isNull(c2.end_date__c, 'The new channel should be active'); // New channel is active
        
    }
    
    /*
     * @description Test method for mapping of POSTAL channel type from Callista 
     */
    @isTest
	public static void validate_insertChannelEvent() {
        
        Contact new2C = new Contact(Person_ID_unique__c='22345678',LastName='User',FirstName='Test');
        insert new2C;
        
        IbdChannel__e insertChannel = new IbdChannel__e(Event_Type__c='INSERT',
                                                        Last_Modified_Datetime__c=datetime.newInstance(2017, 7, 1, 09, 00, 00),
                                                        Last_Modified_By__c='TEST.API.USER',
                                                        Address_Type__c='POSTAL',
                                                        Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        End_Date__c=Date.newInstance(2017,07,03),
                                                        Previous_Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        Address_Line_1__c='12 Apple Rd',
                                                        Address_Line_2__c='Bayswater',
                                                        Address_Line_3__c='ACT',
                                                        Address_Line_4__c='Line4',
                                                        Address_Line_5__c='Line5',
                                                        State__c='ACT', // --> taken from Address_Line_3__c for POSTAL
                                                        AU_Post_Code__c='3153',
                                                        Email__c='so-m.e_one+30@something.com',
                                                        Phone__c='03 8888 5555',
                                                        Phone_2__c='03 8888 5556',
                                                        Mobile_Phone__c='0455 555 555',
                                                        Person_ID__c='22345678'
                                                       );
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertChannel);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        List<Channel__c> ch = [SELECT Id, Deleted_In_Source__c,Last_Modified_By_API__c,Last_Modified_Date_API__c,Source_System__c,Start_Date__c,End_Date__c,
                                      Contact__r.Id,Contact__r.Person_Id_unique__c,Type__c,Line_1__c,Line_2__c,Line_3__c,Line_4__c,Line_5__c,
                                      Street__c,City__c,State__c,Country__c,Post_Code__c,AU_Post_Code__c,Email__c,Phone__c,Phone_2__c,Mobile_Phone__c
                               from Channel__c 
                               where Contact__r.Person_Id_unique__c='22345678'];
        
        Assert.areEqual(1, ch.size());
        if(ch.size() == 1) {
            Channel__c validateChannel = ch.get(0);
            
            // not dependent on address type
            Assert.areEqual(insertChannel.Event_Type__c=='DELETE', validateChannel.Deleted_In_Source__c, 'Channel__c.Deleted_In_Source__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Last_Modified_By__c, validateChannel.Last_Modified_By_API__c, 'Channel__c.Last_Modified_By_API__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Last_Modified_Datetime__c, validateChannel.Last_Modified_Date_API__c, 'Channel__c.Last_Modified_Date_API__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Source_System__c, validateChannel.Source_System__c, 'Channel__c.Source_System__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Start_Date__c, validateChannel.Start_Date__c, 'Channel__c.Start_Date__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.End_Date__c, validateChannel.End_Date__c, 'Channel__c.End_Date__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Person_ID__c, validateChannel.Contact__r.Person_Id_unique__c, 'Channel__c.Contact__r.Person_Id_unique__c does not equal to the expected value.');

            Assert.areEqual(insertChannel.Phone__c, validateChannel.Phone__c, 'Channel__c.Phone__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Phone_2__c, validateChannel.Phone_2__c, 'Channel__c.Phone_2__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Mobile_Phone__c, validateChannel.Mobile_Phone__c, 'Channel__c.Mobile_Phone__c does not equal to the expected value.');
            // insertChannel.Home_Phone__c is not mapped anywere
            // 
            // dependent on address type
            Assert.areEqual(insertChannel.Address_Type__c, validateChannel.Type__c, 'Channel__c.Type__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_1__c, validateChannel.Line_1__c, 'Channel__c.Line_1__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_1__c, validateChannel.Street__c, 'Channel__c.Street__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_2__c, validateChannel.Line_2__c, 'Channel__c.Line_2__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_2__c, validateChannel.City__c, 'Channel__c.City__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_3__c, validateChannel.Line_3__c, 'Channel__c.Line_3__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_3__c, validateChannel.State__c, 'Channel__c.State__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_4__c, validateChannel.Line_4__c, 'Channel__c.Line_4__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_5__c, validateChannel.Line_5__c, 'Channel__c.Line_5__c does not equal to the expected value.');
            Assert.areEqual('Australia', validateChannel.Country__c, 'Channel__c.Country__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.AU_Post_Code__c, validateChannel.Post_Code__c, 'Channel__c.Post_Code__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.AU_Post_Code__c, validateChannel.AU_Post_Code__c, 'Channel__c.AU_Post_Code__c does not equal to the expected value.');
        }
    }
    
    /*
     * @description  Test method for mapping of OS-HOME address type for foreign country 
     * Gabriel Ludik - 16/03/2018 - OS-HOME country should = line 4 (SF-1028)
     */
    @isTest
    public static void validate_InsertOSChannel() {
        
        Contact new2C = new Contact(Person_ID_unique__c='22345678',LastName='User',FirstName='Test');
        insert new2C;
        
        IbdChannel__e insertChannel = new IbdChannel__e(Event_Type__c='INSERT',
                                                        Last_Modified_Datetime__c=datetime.newInstance(2017, 7, 1, 09, 00, 00),
                                                        Last_Modified_By__c='TEST.API.USER',
                                                        Address_Type__c='OS-HOME',
                                                        Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        End_Date__c=Date.newInstance(2017,07,03),
                                                        Previous_Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        Address_Line_1__c='12 Apple Rd',
                                                        Address_Line_2__c='HARARE',
                                                        Address_Line_3__c='HARARE',
                                                        Address_Line_4__c='Invalid but contains CHINA', // should map to china
                                                        Address_Line_5__c='',
                                                        State__c='', // --> taken from Address_Line_3__c for POSTAL
                                                        OS_Post_Code__c = '8010',
                                                        Email__c='someone@something.com',
                                                        Phone__c='03 8888 5555',
                                                        Phone_2__c='03 8888 5556',
                                                        Mobile_Phone__c='0455 555 555',
                                                        Person_ID__c='22345678'
                                                       );
        
        Test.startTest();
        
        Database.SaveResult sr = EventBus.publish(insertChannel);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        List<Channel__c> ch = [SELECT Id, Deleted_In_Source__c,Last_Modified_By_API__c,Last_Modified_Date_API__c,Source_System__c,Start_Date__c,End_Date__c,
                                      Contact__r.Id,Contact__r.Person_Id_unique__c,Type__c,Line_1__c,Line_2__c,Line_3__c,Line_4__c,Line_5__c,
                                      Street__c,City__c,State__c,Country__c,Post_Code__c,AU_Post_Code__c,Email__c,Phone__c,Phone_2__c,Mobile_Phone__c
                               from Channel__c 
                               where Contact__r.Person_Id_unique__c='22345678'];
        
        Assert.areEqual(1, ch.size());
        if(ch.size() == 1) {
            Channel__c validateChannel = ch.get(0);
            Assert.areEqual(insertChannel.Address_Type__c, validateChannel.Type__c, 'Channel__c.Type__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_1__c, validateChannel.Street__c, 'Channel__c.Street__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_2__c, validateChannel.City__c, 'Channel__c.City__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_3__c, validateChannel.State__c, 'Channel__c.State__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.Address_Line_4__c, validateChannel.Line_4__c, 'Channel__c.Line_4__c does not equal to the expected value.');
            Assert.areEqual('CHINA', validateChannel.country__c.touppercase() , 'Channel__c.Country__c does not equal to the expected value.');
            Assert.areEqual(insertChannel.OS_Post_Code__c, validateChannel.Post_Code__c, 'Channel__c.Post_Code__c does not equal to the expected value.');
        }
    }
    
    /*
     * @description Test method to validate that AP-Email and GRADUATION-APPL do not default the country which would result in the creation of an Address__c record.
     */
    @isTest
    public static void validate_InsertEmailOnlyChannels() {
        // GIVEN a contact exists
        Contact newContact = new Contact(Person_ID_unique__c='00000006',LastName='User',FirstName='Test');
        insert newContact;
        
        // WHEN insert a new channel of type AP-EMAIL or GRADUATION-APPL
        IbdChannel__e apemailChannel = new IbdChannel__e(Event_Type__c='INSERT',
                                                        Last_Modified_Datetime__c=datetime.newInstance(2017, 7, 1, 09, 00, 00),
                                                        Last_Modified_By__c='TEST.API.USER',
                                                        Address_Type__c='AP-EMAIL',
                                                        Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        Email__c='ap-email@something.com',
                                                        Person_ID__c=newContact.Person_ID_unique__c
                                                       );
        IbdChannel__e graduationapplChannel = new IbdChannel__e(Event_Type__c='INSERT',
                                                        Last_Modified_Datetime__c=datetime.newInstance(2017, 7, 1, 09, 00, 00),
                                                        Last_Modified_By__c='TEST.API.USER',
                                                        Address_Type__c='GRADUATION-APPL',
                                                        Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        Email__c='graduation-appl@something.com',
                                                        Person_ID__c=newContact.Person_ID_unique__c
                                                       );
        
        // THEN there shouldn't be a country defaulted for the address (country field)
        Test.startTest();
        List<Database.SaveResult> sr = EventBus.publish(new List<IbdChannel__e>{apemailChannel, graduationapplChannel});
        Test.getEventBus().deliver();
        Assert.isTrue(sr[0].isSuccess(), 'Event could not be published. Errors: ' + sr[0].getErrors());
        Test.stopTest();
        for (Channel__c iChannel : [SELECT Id, Contact__r.Id, Contact__r.Person_ID__c,Email__c,Country__c, Type__c FROM Channel__c WHERE Contact__r.Person_ID__c = :newContact.Person_ID_unique__c]) {
            Assert.isTrue(String.isBlank(iChannel.Country__c), 'The country was set for a channel of type ['+ iChannel.Type__c +']');
        }
    }
    
    /*
     * @description Update a channel record via the inbound event
     */
    @isTest
    public static void validate_UpdateChannelEvent() {
        
        Contact newC = new Contact(Person_ID_unique__c='00000007',LastName='User',FirstName='Test');
        insert newC;
        
        Channel__c newCh = new Channel__c(Type__c='POSTAL-EXT',
                                          Contact__c=newC.Id,
                                          Start_Date__c=Date.newInstance(2015, 10, 01),
                                          Email__c='someone@something.com',
                                          Last_Modified_Date_API__c=datetime.newInstance(2017, 7, 1, 9, 00, 00),
										  Person_ID__c='00000007',
										  unique_id__c = '00000007_POSTAL-EXT_20151001'
                                         );
        insert newCh;
        
        IbdChannel__e updateChannel = new IbdChannel__e(Event_Type__c='UPDATE',
                                                        Last_Modified_Datetime__c=datetime.newInstance(2017, 7, 1, 10, 00, 00),
                                                        Last_Modified_By__c='PV',
                                                        Address_Type__c='POSTAL-EXT',
                                                        Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        End_Date__c=Date.newInstance(2021,07,03),
                                                        Previous_Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        Address_Line_1__c='12 Apple St',
                                                        Address_Line_3__c='Melbourne',
                                                        Address_Line_4__c='VIC',
                                                        AU_Post_Code__c='3153',
                                                        Email__c='someone1@something.com',
                                                        Mobile_Phone__c='0455 555 555',
                                                        Person_ID__c='00000007'
                                                       );
        
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(updateChannel);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        List<Channel__c> ch = [SELECT unique_id__c, Type__c, Start_Date__c, End_Date__c, Line_1__c, Line_2__c, Line_3__c, Line_4__c, Post_Code__c, Email__c, Mobile_Phone__c, Person_ID__c from Channel__c where Contact__r.Person_ID__c='00000007'];
        Assert.areEqual(1, ch.size());
        Assert.areEqual('someone1@something.com', ch[0].Email__c);
    }
    
    /*
     * @description Supply an invalid email address via the event (Callista data is often invalid)
     */
    @isTest
    public static void testUpdateBadEmailChannelEvent() {
        Test.startTest();
        
        Contact new2C = new Contact(Person_ID_unique__c='33335678',LastName='User',FirstName='Test');
        insert new2C;
       
        IbdChannel__e insertChannel = new IbdChannel__e(Event_Type__c='INSERT',
                                                        Last_Modified_Datetime__c=datetime.newInstance(2017, 7, 1, 10, 00, 00),
                                                        Last_Modified_By__c='PV',
                                                        Address_Type__c='POSTAL',
                                                        Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        End_Date__c=Date.newInstance(2017,07,03),
                                                        Previous_Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        Address_Line_1__c='12 Apple St',
                                                        Address_Line_2__c='Bayswater',
                                                        Address_Line_3__c='VIC',
                                                        AU_Post_Code__c='3153',
                                                        Email__c='someone.something.com',
                                                        Mobile_Phone__c='0455 555 555',
                                                        Person_ID__c='33335678'
                                                       );
        
        Database.SaveResult sr = EventBus.publish(insertChannel);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        List<Channel__c> ch = [SELECT Email__c, Email_Unverified__c from Channel__c where Contact__r.Person_ID__c='33335678'];

        Assert.areEqual(1, ch.size());
        if(ch.size() == 1) {
            Assert.isNull(ch[0].Email__c);
            Assert.areEqual('someone.something.com', ch[0].Email_Unverified__c);
        }
    }
    
    /*
     * @description Changing the start date will create a new record
     */
    @isTest
    public static void validate_BadStartDateChange() {
        
        Contact new2C = new Contact(Person_ID_unique__c='00000010',LastName='User',FirstName='Test');
        insert new2C;
        
        Channel__c newCh = new Channel__c(Type__c='OS-POSTAL',
                                          Contact__c=new2C.Id,
                                          Start_Date__c=Date.newInstance(2015, 10, 01),
                                          End_Date__c=Date.newInstance(2017,07,03),
                                          Email__c='someone@something.com',
                                          Last_Modified_Date_API__c=datetime.newInstance(2017, 7, 1, 9, 00, 00)
                                         );
        insert newCh;
        
        IbdChannel__e updSDChannel = new IbdChannel__e(Event_Type__c='UPDATE',
                                                       Last_Modified_Datetime__c=datetime.newInstance(2017, 7, 1, 10, 00, 00),
                                                       Last_Modified_By__c='PV',
                                                       Address_Type__c='OS-POSTAL',
                                                       Start_Date__c=Date.newInstance(2015, 10, 03),
                                                       End_Date__c=Date.newInstance(2017,07,03),
                                                       Previous_Start_Date__c=Date.newInstance(2015, 09, 01),
                                                       Address_Line_1__c='12 Apple Rd',
                                                       Address_Line_2__c='Bayswater',
                                                       Address_Line_3__c='VIC',
                                                       Address_Line_4__c='P.R. CHINA',
                                                       AU_Post_Code__c='3153',
                                                       Email__c='someone2@something.com',
                                                       Mobile_Phone__c='0455 555 555',
                                                       Person_ID__c='00000010'
                                                      );
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(updSDChannel);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        List<Channel__c> ch = [SELECT Id, Contact__r.Id, Contact__r.Person_ID__c,Email__c,Start_Date__c from Channel__c where Contact__r.Person_ID__c='00000010'];
        Assert.areEqual(2, ch.size());
        
    }

    /*
     * @description  Validate a channel of type delete results in field 'Deleted_In_Source__c' set to true
     */
    @isTest
    public static void validate_ChannelDelete() {
        Contact new2C = new Contact(Person_ID_unique__c='00000011',LastName='User',FirstName='Test');
        insert new2C;
        new2C = [SELECT id from Contact where Person_ID_unique__c='00000011'];
        
        Channel__c newCh = new Channel__c(Contact__c=new2C.Id,
                                          Last_Modified_Date_API__c=datetime.newInstance(2017, 7, 1, 9, 00, 00),
                                          Type__c='OS-POSTAL',
                                          Start_Date__c=Date.newInstance(2015, 10, 01),
                                          End_Date__c=Date.newInstance(2017,07,03),
                                          Email__c='someone@something.com',
                                          unique_id__c = '00000011_OS-POSTAL_20151001'
                                         );
        insert newCh;
        IbdChannel__e delChannel = new IbdChannel__e(Event_Type__c='DELETE',
                                                     Person_ID__c='00000011',
                                                     Last_Modified_Datetime__c=datetime.newInstance(2017, 7, 1, 10, 00, 00),
                                                     Address_Type__c='OS-POSTAL',
                                                     Start_Date__c=Date.newInstance(2015, 10, 01)
                                                    );
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(delChannel);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        List<Channel__c> ch = [SELECT Id, Contact__r.Id, Contact__r.Person_ID__c,Email__c,Start_Date__c,Deleted_In_Source__c from Channel__c where Contact__r.Person_ID__c='00000011'];
        Assert.areEqual(1, ch.size());
        if(ch.size() == 1) {
            Assert.isTrue(ch[0].Deleted_In_Source__c);
        }
    }
    
    /*
     * @description Channel update
     */ 
    @isTest
    public static void validate_UpdateFieldsChannelEvent() {
        
        Contact new2C = new Contact(Person_ID_unique__c='12121212',LastName='User',FirstName='Test');
        insert new2C;
        
        Channel__c newCh = new Channel__c(Type__c='POSTAL',
                                          Contact__c=new2C.Id,
                                          Start_Date__c=Date.newInstance(2015, 10, 01),
                                          Email__c='someone@something.com',
                                          Last_Modified_Date_API__c=datetime.newInstance(2017, 7, 1, 9, 00, 00),
                                          Person_ID__c='12121212',
                                          unique_id__c = '12121212_POSTAL_20151001'
                                         );
        insert newCh;
        
        IbdChannel__e updateChannel = new IbdChannel__e(Event_Type__c='UPDATE',
                                                        Last_Modified_Datetime__c=datetime.newInstance(2017, 7, 1, 10, 00, 00),
                                                        Address_Type__c='POSTAL',
                                                        Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        Previous_Start_Date__c=Date.newInstance(2015, 10, 01),
                                                        Address_Line_4__c='XXX',
                                                        Address_Line_5__c='XXX',
                                                        OS_Post_Code__c='3153',
                                                        Phone__c='5555555',
                                                        Phone_2__c='5555555',
                                                        Person_ID__c='12121212',
                                                        Source_System__c='callista'
                                                       );
        
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(updateChannel);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        List<Channel__c> ch2 = [SELECT Id, Contact__r.Id, Contact__r.Person_ID__c,phone__c from Channel__c where Contact__r.Person_ID__c='12121212' and Type__c='POSTAL'];
        
        Assert.areEqual(1, ch2.size());
        if(ch2.size() == 1) {
            Assert.areEqual('5555555', ch2[0].phone__c);
        }   
    }
    
    /*
     * @description Send multiple records in a batch
     */ 
    @isTest
    public static void validate_InsertChannelEventBulk() {
      List<Contact>  conlist = new List<Contact>();
         Contact newContactA = new Contact(LastName = 'User',
                Last_Name__c = 'User1',
                FirstName = 'Insert',
                First_Name__c = 'Insert',
                LastModifiedDate_API__c = datetime.newInstance(2017, 7, 1, 09, 00, 00),
                Gender__c = 'M',
              //  Person_ID_unique__c = '00000040', //No match
                Birthdate = Date.newInstance(1995, 12, 14)
              //  email = 'someone2@something1.com'
        );
        conlist.add(newContactA);
         Contact newContactB = new Contact(LastName = 'User',
                Last_Name__c = 'User2',
                FirstName = 'Insert',
                First_Name__c = 'Insert',
                LastModifiedDate_API__c = datetime.newInstance(2017, 7, 1, 09, 00, 00),
                Gender__c = 'M',
                Person_ID_unique__c = '00000041', //No match
                Birthdate = Date.newInstance(1995, 12, 14)
              //  email = 'someone2@something2.com'
        );
        conlist.add(newContactB);
         Contact newContactC = new Contact(LastName = 'User',
                Last_Name__c = 'User3',
                FirstName = 'Insert',
                First_Name__c = 'Insert',
                LastModifiedDate_API__c = datetime.newInstance(2017, 7, 1, 09, 00, 00),
                Gender__c = 'M',
               // Person_ID_unique__c = '00000042', //No match
                Birthdate = Date.newInstance(1995, 12, 14)
              //  email = 'someone2@something3.com'
        );
        conlist.add(newContactC);
         Contact newContactD = new Contact(LastName = 'User',
                Last_Name__c = 'User4',
                FirstName = 'Insert',
                First_Name__c = 'Insert',
                LastModifiedDate_API__c = datetime.newInstance(2017, 7, 1, 09, 00, 00),
                Gender__c = 'M',
               Person_ID_unique__c = '00000043', //No match
                Birthdate = Date.newInstance(1995, 12, 14)
             //   email = 'someone2@something4.com'
        );
        conlist.add(newContactD);
         Contact newContactE = new Contact(LastName = 'User',
                Last_Name__c = 'User5',
                FirstName = 'Insert',
                First_Name__c = 'Insert',
                LastModifiedDate_API__c = datetime.newInstance(2017, 7, 1, 09, 00, 00),
                Gender__c = 'M',
                Person_ID_unique__c = '00000044', //No match
                Birthdate = Date.newInstance(1995, 12, 14)
               // email = 'someone2@something5.com'
        );
        conlist.add(newContactE);
        insert conlist;
        
        List<Application__c> appList = new LIst<Application__c>();
       Application__c appA = new Application__c(Applicant__c=newContactA.Id,Callista_Applicant_Id__c= '11111');
       appList.add(appA);
       Application__c appB = new Application__c(Applicant__c=newContactB.Id,Callista_Applicant_Id__c= '11113');
       appList.add(appB);
       Application__c appC = new Application__c(Applicant__c=newContactC.Id,Callista_Applicant_Id__c= '11115');
       appList.add(appC);
       Application__c appD = new Application__c(Applicant__c=newContactD.Id,Callista_Applicant_Id__c= '11117');
       appList.add(appD);
       Application__c appE = new Application__c(Applicant__c=newContactE.Id,Callista_Applicant_Id__c= '11119');
       appList.add(appE);
       insert appList;
       
         IbdChannel__e updSDChannelB1 = new IbdChannel__e(Event_Type__c = 'UPDATE',
                Last_Modified_Datetime__c = datetime.newInstance(2017, 7, 1, 10, 00, 00),
                Last_Modified_By__c = 'PV',
                Address_Type__c = 'POSTAL',
                Start_Date__c = Date.newInstance(2015, 10, 03),
                End_Date__c = Date.newInstance(2017, 07, 03),
                Previous_Start_Date__c =Date.newInstance(2015, 10, 03),
                Address_Line_1__c = '12 Apple ROAD',
                Address_Line_2__c = 'Bayswater',
                Address_Line_3__c = 'VIC',
                AU_Post_Code__c = '3153',
                Email__c = 'someone2@something1.com',
                Mobile_Phone__c = '0455 555 555',
                Person_ID__c = '00000060',//matching Person_ID__c  from the contact created
                Applicant_IDs__c = '11111;11112'
        );
        IbdChannel__e updSDChannelB2 = new IbdChannel__e(Event_Type__c = 'UPDATE',
                Last_Modified_Datetime__c = datetime.newInstance(2017, 7, 1, 10, 00, 00),
                Last_Modified_By__c = 'PV',
                Address_Type__c = 'POSTAL',
                Start_Date__c = Date.newInstance(2015, 10, 03),
                End_Date__c = Date.newInstance(2017, 07, 03),
                Previous_Start_Date__c =Date.newInstance(2015, 10, 03),
                Address_Line_1__c = '12 Apple ROAD',
                Address_Line_2__c = 'Bayswater',
                Address_Line_3__c = 'VIC',
                AU_Post_Code__c = '3154',
                Email__c = 'someone2@something2.com',
                Mobile_Phone__c = '0455 555 555',
                Person_ID__c = '00000061',//matching Person_ID__c  from the contact created
                Applicant_IDs__c = '11113;11114'
        );
        IbdChannel__e updSDChannelB3 = new IbdChannel__e(Event_Type__c = 'UPDATE',
                Last_Modified_Datetime__c = datetime.newInstance(2017, 7, 1, 10, 00, 00),
                Last_Modified_By__c = 'PV',
                Address_Type__c = 'POSTAL',
                Start_Date__c = Date.newInstance(2015, 10, 03),
                End_Date__c = Date.newInstance(2017, 07, 03),
                Previous_Start_Date__c =Date.newInstance(2015, 10, 03),
                Address_Line_1__c = '12 Apple ROAD',
                Address_Line_2__c = 'Bayswater',
                Address_Line_3__c = 'VIC',
                AU_Post_Code__c = '3154',
                Email__c = 'someone2@something3.com',
                Mobile_Phone__c = '0455 555 555',
                Person_ID__c = '00000062',//matching Person_ID__c  from the contact created
                Applicant_IDs__c = '11115;11116'
        );
        IbdChannel__e updSDChannelB4 = new IbdChannel__e(Event_Type__c = 'UPDATE',
                Last_Modified_Datetime__c = datetime.newInstance(2017, 7, 1, 10, 00, 00),
                Last_Modified_By__c = 'PV',
                Address_Type__c = 'POSTAL',
                Start_Date__c = Date.newInstance(2015, 10, 03),
                End_Date__c = Date.newInstance(2017, 07, 03),
                Previous_Start_Date__c =Date.newInstance(2015, 10, 03),
                Address_Line_1__c = '12 Apple ROAD',
                Address_Line_2__c = 'Bayswater',
                Address_Line_3__c = 'VIC',
                AU_Post_Code__c = '3154',
                Email__c = 'someone2@something4.com',
                Mobile_Phone__c = '0455 555 555',
                Person_ID__c = '00000063',//matching Person_ID__c  from the contact created
                Applicant_IDs__c = '11117;11118'
        );
        IbdChannel__e updSDChannelB5 = new IbdChannel__e(Event_Type__c = 'UPDATE',
                Last_Modified_Datetime__c = datetime.newInstance(2017, 7, 1, 10, 00, 00),
                Last_Modified_By__c = 'PV',
                Address_Type__c = 'POSTAL',
                Start_Date__c = Date.newInstance(2015, 10, 03),
                End_Date__c = Date.newInstance(2017, 07, 03),
                Previous_Start_Date__c =Date.newInstance(2015, 10, 03),
                Address_Line_1__c = '12 Apple ROAD',
                Address_Line_2__c = 'Bayswater',
                Address_Line_3__c = 'VIC',
                AU_Post_Code__c = '3154',
                Email__c = 'someone2@something5.com',
                Mobile_Phone__c = '0455 555 555',
                Person_ID__c = '00000064',//matching Person_ID__c  from the contact created
                Applicant_IDs__c = '11119;111110'
        );
               
      
        // send events
        Test.startTest();
            Database.SaveResult sr = EventBus.publish(updSDChannelB1);
        	Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
            sr = EventBus.publish(updSDChannelB2);
        	Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
            sr = EventBus.publish(updSDChannelB3);
        	Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
            sr = EventBus.publish(updSDChannelB4);
    	    Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
            sr = EventBus.publish(updSDChannelB5);
	        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
	        Test.getEventBus().deliver();
	        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();

        List<Channel__c> ch = [SELECT Id, Contact__r.Id, Contact__r.Person_ID__c,Email__c,Start_Date__c,AU_Post_Code__c, Contact__r.Email from Channel__c];
        Assert.isTrue(ch[0].Contact__r.Id != ch[1].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[0].Contact__r.Id != ch[2].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[0].Contact__r.Id != ch[3].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[0].Contact__r.Id != ch[4].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[1].Contact__r.Id != ch[0].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[1].Contact__r.Id != ch[2].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[1].Contact__r.Id != ch[3].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[1].Contact__r.Id != ch[4].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[2].Contact__r.Id != ch[0].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[2].Contact__r.Id != ch[1].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[2].Contact__r.Id != ch[3].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[2].Contact__r.Id != ch[4].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[3].Contact__r.Id != ch[0].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[3].Contact__r.Id != ch[1].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[3].Contact__r.Id != ch[2].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[3].Contact__r.Id != ch[4].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[4].Contact__r.Id != ch[0].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[4].Contact__r.Id != ch[1].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[4].Contact__r.Id != ch[2].Contact__r.Id, 'contact lookups match');
        Assert.isTrue(ch[4].Contact__r.Id != ch[3].Contact__r.Id, 'contact lookups match');
        
     }
    
   /*
	* @description Insert a Channel with no available Contact, and re-delivery it, to test the rety expection handling.
	*/ 
    @isTest
    public static void testRetry() {

        IbdChannel__e che = new IbdChannel__e(Event_Type__c='INSERT',
                                              Last_Modified_Datetime__c=datetime.newInstance(2017, 7, 1, 10, 00, 00),
                                              Address_Type__c='OS-HOME',
                                              Start_Date__c=Date.newInstance(2015, 11, 01),
                                              Previous_Start_Date__c=Date.newInstance(2015, 10, 01),
                                              Address_Line_4__c='South India',
                                              OS_Post_Code__c='3153',
                                              Phone__c='5555555',
                                              Phone_2__c='5555555',
                                              Person_ID__c='00000077',
                                              Source_System__c='callista'
                                             );

        Test.startTest();
        Database.SaveResult SR = EventBus.publish(che);
        Test.getEventBus().deliver();
 			
        for(Integer i=0;i<2 ;i++) {                      
            EventBusSubscriber[] subscribers = queryBus('IbdChannel__e');
            // Get info about all subscribers to the event
            for (EventBusSubscriber sub : subscribers) { 
				if (sub.Name == 'IbdChannelTrigger') {
	                Assert.areEqual(i+1, sub.Retries);
                }
            }

            // Deliver the retried event
            Test.getEventBus().deliver();
        }

        Test.stopTest();
    }
    
    /*
     * @description A fudge to get around having SOQL in a loop
     */ 
    public static List<EventBusSubscriber> queryBus(String ibdObject) {
        List<EventBusSubscriber> bus = new List<EventBusSubscriber>();
        try {
            bus = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic=:ibdObject];
        } catch(Exception e) {
            return new List<EventBusSubscriber>();
        }
        return bus;
    }
}