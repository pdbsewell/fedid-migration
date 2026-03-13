/**
 * @description       : Test class for ChannelEventUtility.cls
 *
 * Date         Author          Modification
 * 2024-07-01   Martin Cadman   Support for EC relationship transform
 * 2024-06-13   Martin Cadman   Moved to Assert. Added Emergency Contact test and coverage.
 * 2021-07-16   P.Victoriano    Fixed Null Pointer exception [EPCP-1419]
 * 2020-10-14   Stefan Scheit   Copied from ContactPointUtility, increased code coverage
 * 2020-05-04   JM Mapanao      Added logic to populate Contact Point's Source__c field to 'Callista' when Channel__c.Source_System__c equals to 'callista'
 * 2019-08-04   Paul Victoriano Initial Version
 * 
 **/
@isTest(isParallel = true)
private class ChannelEventUtility_Test {

    static Contact contactRecord {
        get; set;
    }

    @testSetup 
    static void setupData() {
        //Enable Roll up / down and break up
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        cs.Enable_Roll_Up__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        
        // Switch on mobile phone formatting.
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Format_Mobile__c = true;
        fs.Process_Emergency_Contacts__c = true;
        insert fs;
        
    }

    @isTest
    static void validate_channelContactInsert() {
        // GIVEN: Set up Channel Record
        String sChannel = '{"Source_System__c":"callista","City__c":"Melbourne","Country__c":"Australia","Deleted_In_Source__c":false,"Email__c":"ptest@email.com.test","IsDeleted":false,"Is_Processed__c":false,"Mobile_Phone__c":"0456787652","Phone_2__c":"0456787652","Phone__c":"0456787652","Post_Code__c":"3000","Primary__c":false,"Rollup_Rank__c":40.00,"Start_Date__c":"2019-04-03","State__c":"VIC","Street__c":"1 Collins Street","Type__c":"HOME","attributes":{"type":"Channel__c"}}';
        Channel__c ch = (Channel__c)JSON.deserialize(sChannel, Channel__c.class);
        //WHEN: A channel record is inserted
        Test.startTest();
        setupDataManual();
        ch.Contact__c = contactRecord.Id;
        insert ch;
        Assert.isNotNull(ch.Id, 'Error inserting Channel Record');
        Test.stopTest();
        // THEN: Address was broken up successfully
        Address__c addressCheck = [SELECT Street_Name__c FROM Address__c WHERE Contact__c = :contactRecord.Id AND Street_Name__c = :ch.Street__c LIMIT 1];
        Assert.areEqual(ch.Street__c, addressCheck.Street_Name__c, 'Error on Channel Break up Address');
        // THEN: Email was broken up successfully
        Email__c emailCheck = [SELECT Name FROM Email__c WHERE Contact__c = :contactRecord.Id AND Name = :ch.Email__c LIMIT 1];
        Assert.areEqual(ch.Email__c, emailCheck.Name, 'Error on Channel Break up Email');
        // THEN: Phone TODO
    }

    @isTest
    static void validate_channelContactUpsert() {
        //Set up Channel Record
        String sChannel = '{"City__c":"Melbourne","Country__c":"Australia","Deleted_In_Source__c":false,"Email__c":"ptest@email.com.test","IsDeleted":false,"Is_Processed__c":false,"Mobile_Phone__c":"0456787652","Phone_2__c":"0456787652","Phone__c":"0456787652","Post_Code__c":"3000","Primary__c":false,"Rollup_Rank__c":40.00,"Start_Date__c":"2019-04-03","State__c":"VIC","Street__c":"1 Collins Street","Type__c":"HOME","attributes":{"type":"Channel__c"}}';
        Channel__c ch = (Channel__c)JSON.deserialize(sChannel, Channel__c.class);
        setupDataManual();
        ch.Contact__c = contactRecord.Id;
        insert ch;
        Assert.isNotNull(ch.Id, 'Error inserting Channel Record');
        //
        Test.startTest();
        //When
        ch.Email__c = 'ptestupdate@test.com';
        update ch;
        Assert.isNotNull(ch.Id, 'Error inserting Channel Record');
        Test.stopTest();
        //Then
        Contact recCheck = [SELECT Personal_Email__c, Phone, MobilePhone, Email, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
                            FROM Contact
                            WHERE Id = :contactRecord.Id LIMIT 1];
        Assert.areEqual(ch.Email__c,
                            recCheck.Personal_Email__c,
                            'Error on Channel Break up Email');
        //System.assertEquals(ch.Phone__c,recCheck.Phone,'Error on Channel Break up Phone');
        Assert.areEqual(ch.Street__c,
                        recCheck.MailingStreet,
                        'Error on Channel Break up Address');
    }

    @isTest
    static void validate_massChannelContact() {
        List<Channel__c> channelUpdates = new List<Channel__c>();
        //Set up Channel Record
        String sChannel = '{"City__c":"Melbourne","Country__c":"Australia","Mobile_Phone__c":"0456787653","Phone_2__c":"0456787652","Phone__c":"0456787651","Post_Code__c":"3000","Primary__c":false,"Rollup_Rank__c":40.00,"Start_Date__c":"2019-04-03","State__c":"VIC","Street__c":"1 Collins Street","Type__c":"HOME","attributes":{"type":"Channel__c"}}';
        Channel__c ch = (Channel__c)JSON.deserialize(sChannel, Channel__c.class);
        setupDataManual();
        for (Integer ix = 0; ix < 10; ix++) {
            ch.Email__c = String.format('test{0}@test.com', new LIST<String> {'' + ix});
            ch.Contact__c = contactRecord.Id;
            channelUpdates.add(ch.clone());
        }
        //
        Test.startTest();
        //When
        insert channelUpdates;
        Test.getEventBus().deliver();
        Test.stopTest();
        //Then
        Assert.isNotNull(channelUpdates, 'Error Mass Insert');
        Assert.areEqual(channelUpdates.size(),[select count() from channel__c where contact__c = :contactRecord.Id]);
    }

    /**
     * quick test coverage for MIM
     */
    @isTest
    static void validate_findNewContactPointChannel() {
        setupDataManual();
        Channel__c primaryChannel = TestHelper.createChannel(contactRecord);
        insert primaryChannel;
        // WHEN: the channel is processed
        Test.startTest();
        Test.getEventBus().deliver();
        // AND: another (same data) channel is processed
        Channel__c newChannel = TestHelper.createChannel(contactRecord);
        newChannel.Deleted_In_Source__c = true;
        insert newChannel;
        Test.getEventBus().deliver();
        // AND: the primary is recalculated
        String channelField = String.valueOf(Channel__c.sobjectType.fields.Address_Key__c);
        Set<String> channelFieldNames = new Set<String> {
            channelField
        };
        // Name, Contact__c are expected in the method that follows
        List<Sobject> sobjList = [SELECT Id, Name, Contact__c, Street_Name__c, City__c, State__c, Country2__c FROM Address__c WHERE Contact__c = :contactRecord.Id];
        ChannelEventUtility.findNewContactPointChannel(sobjList, channelFieldNames);
        Test.stopTest();
    }

    /**
     * Evaluate address key generation
     */
    @isTest 
    static void validate_RetrieveChannelAddresskey() {
        // GIVEN: an address record
        Address__c addr = new Address__c();
        addr.Street_Name__c = '100 Bourke St';
        addr.City__c = 'Melbourne';
        addr.State__c = 'Victoria';
        addr.Country2__c = 'Australia';
        // WHEN: obtaining the address key
        Test.startTest();
        String testString = ChannelEventUtility.retrieveChannelAddresskey(addr);
        Test.stopTest();
        // THEN: address key was returned
        Assert.isTrue(String.isNotBlank(testString),'Address key was not generated, it is empty.');
        Assert.isTrue(testString.contains(addr.City__c),'Address key does not contain the city as part of it.');
    }

    /**
     * @description byPassAddressByMetadata Test for Bypass
     * @author pvic0002
     */
    @isTest
    static void validate_byPassAddressByMetadata() {
        Test.startTest();
        // GIVEN: an address record
        Boolean isIncluded = true;
        Address__c addr = new Address__c();
        addr.Street_Name__c = 'ADDRESS INSERTED FOR TCSI 2021 REPORTING';
        addr.City__c = 'PLEASE UPDATE TO SHOW CORRECT OS-HOME';
        addr.State__c = 'ADDRESS';
        addr.Country2__c = 'Australia';
        // WHEN: checking if address is excluded
        ChannelEventUtility evtUtil = new ChannelEventUtility(new Set<Id>(),new Set<Id>());
        // STEP1: Retrieve Metadata mapping
        evtUtil.retrieveChannelByPass();
        // STEP2: Perform validation
        isIncluded = evtUtil.breakDownBypass(addr,'Address__c');
        // THEN: expected address is excluded
        Assert.isFalse(isIncluded, 'Address was not excluded.');
        Test.stopTest();
    }
    
    @isTest
    /*
     * GIVEN
     *    A emergency contact channel
     * WHEN
     *    The channel is inserted
     * THEN
     *    An emergency contact is created and linked to the channel contact and channel itself
     **/
    static void validate_EmergencyContact() {
        // Mapped channel data 
        String sChannel = '{"City__c":"Melbourne","Country__c":"Australia","Email__c":"ectest@email.com.test","Mobile_Phone__c":"0456787111","Phone__c":"0456787222","Fullname__c":"Greg Test","Relationship_unverified__c":"Brother","Relationship__c":"Brother","Type__c":"EMERCONT","attributes":{"type":"Channel__c"}}';
        Channel__c aChannel = (Channel__c)JSON.deserialize(sChannel, Channel__c.class);
		setupDataManual();
        aChannel.Contact__c = contactRecord.Id;

        test.startTest();
        insert aChannel;
        Test.getEventBus().deliver();
        test.stopTest();

        channel__c retChannel = [select id, type__c, Relationship__c, fullname__c, country__c, contact__c from channel__c where id = :aChannel.id];
        Assert.areEqual(retChannel.type__c,'EMERCONT'); // Confirms insert
        
        Emergency_contact__c ec = [select id, channel__c, contact__c, relationship__c, emergency_contact_name__c, country__c from emergency_contact__c where channel__c = :retchannel.id][0];
        Assert.areEqual(retChannel.Relationship__c.toLowerCase(), ec.relationship__c.toLowerCase());
        Assert.areEqual(retChannel.fullname__c, ec.emergency_contact_name__c);
        Assert.areEqual(retChannel.country__c, ec.country__c);
        Assert.areEqual(retChannel.contact__c, ec.contact__c); // linked corectly
    }

    /**
     * Set up data manually
     */
    private static void setupDataManual() {
        contactRecord = new Contact();
        contactRecord.Title = 'OAM';
        contactRecord.Salutation = 'Mr.';
        contactRecord.FirstName = 'testFirstName';
        contactRecord.MiddleName = 'testMiddleName';
        contactRecord.LastName = 'testLastName';
        contactRecord.Suffix = 'testSuffix';
        contactRecord.Person_ID_unique__c = '12345678';
        insert contactRecord;
    }
}