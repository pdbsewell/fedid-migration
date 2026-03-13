/**
 * @description       : Test Class for ChannelEventTriggerHandler
 * Modifications Log 
 * Date         Author          Modification
 * 2020-10-14   Stefan Scheit   Moved from ContactPointTriggerHandler_Test
 * 2020-10-14   Angelo Riviera  Update with test logic
 * 2020-01-21   Paul Victoriano Initial Version
**/

@isTest(isParallel=true)
private class ChannelEventTriggerHandler_Test {

    static Contact contactRecord {get; set;}

    @testSetup static void setupData() {
        //Enable Roll up / down and break up
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        cs.Enable_Roll_Up__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        
        PlatformEventControl__c pec = new PlatformEventControl__c();
        pec.channel_event__c = 20;
        pec.Async_Process__c = 20;
        pec.Contact_Point_Event__c = 20;
        insert pec;        
    }

	/**
     * @author Paul Victoriano
     */
    @isTest
	static void validate_Behavior() {
		Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact(),true);
		Channel__c channel = new Channel__c(Type__c='Home', Contact__c=con.Id);
		Test.startTest();
		insert channel;
		Test.stopTest();
		Assert.isNotNull([SELECT Id FROM Channel__c]);
	}

    /**
     * @author Paul Victoriano
     */
    @isTest
    static void validate_channelContactUpsert() {
        Database.SaveResult[] srs;
        //Given - Setup Contact Data
        setupDataManual();
        //Set up Channel Record
        String sChannel = '{"City__c":"Melbourne","Country__c":"Australia","Deleted_In_Source__c":false,"Email__c":"ptest@monash.edu.test","IsDeleted":false,"Is_Processed__c":false,"Mobile_Phone__c":"0456787652","Phone_2__c":"0456787652","Phone__c":"0456787652","Post_Code__c":"3000","Primary__c":false,"Rollup_Rank__c":40.00,"Start_Date__c":"2019-04-03","State__c":"VIC","Street__c":"1 Collins Street","Type__c":"HOME","attributes":{"type":"Channel__c"}}';
        Channel__c ch = (Channel__c)JSON.deserialize(sChannel, Channel__c.class);
        ch.Contact__c = contactRecord.Id;
        insert ch;
        System.assertNotEquals(null, ch.Id, 'Error inserting Channel Record');
        Test.startTest();
        srs = EventBus.publish(
        new List<Channel_Event__e> {
            new Channel_Event__e(
                Contact_Id__c=ch.Contact__c,
                Channel_Id__c=ch.Id)
        }
              );
        Test.getEventBus().deliver();
        Test.stopTest();
        
        Assert.isTrue(srs[0].isSuccess(),'Platform Event Dispatch Failed');
    }

    /**
     * @author Paul Victoriano
     * masschannelContactTest Bulk test of Channel Insert
     */
    @isTest
    static void validate_massChannelInsert() {
        List<Channel__c> channelUpdates = new List<Channel__c>();
        //Given - Setup Contact Data
        setupDataManual();
        //Set up Channel Record
        String sChannel = '{"City__c":"Melbourne","Country__c":"Australia","Deleted_In_Source__c":false,"Email__c":"ptest@monash.edu.test","IsDeleted":false,"Is_Processed__c":false,"Mobile_Phone__c":"0456787652","Phone_2__c":"0456787652","Phone__c":"0456787652","Post_Code__c":"3000","Primary__c":false,"Rollup_Rank__c":40.00,"Start_Date__c":"2019-04-03","State__c":"VIC","Street__c":"1 Collins Street","Type__c":"HOME","attributes":{"type":"Channel__c"}}';
        Channel__c ch = (Channel__c)JSON.deserialize(sChannel, Channel__c.class);
        for (Integer ix = 0; ix < 200; ix++) {
            ch.Email__c = String.format('test{0}@test.com', new LIST<String> {'' + ix});
            ch.Contact__c = contactRecord.Id;
            channelUpdates.add(ch.clone());
        }
        Test.startTest();
        //When
        insert channelUpdates;
        Test.getEventBus().deliver();
        Test.stopTest();
        //Then
        Assert.isNotNull(channelUpdates, 'Error Mass Insert');
    }
    
    /**
     * @author Paul Victoriano
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
        contactRecord.Person_ID_unique__c = '12345';
        insert contactRecord;
        
        Assert.isNotNull(contactRecord.Id, 'Contact Record Insert Failed');
    }
}