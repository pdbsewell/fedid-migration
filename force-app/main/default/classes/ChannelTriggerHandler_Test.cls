/**
 * @description       : Test class for ChannelTriggerHandler
 * Modifications Log 
 *
 * Date         Author          Modification
 * 13/06/2024   Martin Cadman   Emergency Contact validation added
 * 2020-10-14   Stefan Scheit   Copied from ChannelServices_Test, cosmetic updates.
 * 2019-12-17   Martin Cadman   Initial Version to capture Person360 logic.
 * 2019-07-04   Paul Victoriano Channel break-up logic via platform events.
**/
@isTest(isParallel=true)
private class ChannelTriggerHandler_Test {
    
    /*
    * @description Test data initialisation
    */
    @testSetup static void initialize() {
        // Ensure the channelbreakup is enabled so the ChannelTrigger will call the services class
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = false;
        cs.Enable_Roll_Up__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        
        // Create a channel parent contact
        Contact aContact = new Contact(Person_ID_unique__c='22245678', LastName='User', FirstName='Test');
        insert aContact;
        
        // Create a channel for later update
        Channel__c aChannel = new Channel__c(type__c='HOME', Contact__c=aContact.id, email__c='home@email.com.au', Mobile_Phone__c='0404010101');        
        insert aChannel;
    }
    
    /*
    * @description Insert a new channel directly
    */
    @isTest static void validate_insertChannel() {
        List<Channel__c> chanlst = new List<Channel__c>();
        List<Contact> aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245678'];
        Assert.areEqual(1, aContact.size(), 'One, and only one, contact should match this criteria');

        Test.startTest();
        
        chanlst.add(new Channel__c(type__c='OS-HOME', Contact__c=aContact[0].id, email__c='oshome@email.com.au', Mobile_Phone__c='0401843555'));        
        chanlst.add(new Channel__c(type__c='POSTAL', Contact__c=aContact[0].id, Street__c='55 Collin St', Post_Code__c='3000', State__c='Vic', City__c='Melbourne', email__c='postal@email.com.au', Country__c='Australia')); 
        insert chanlst;
        
        Test.stopTest();

        Assert.areEqual(1, [SELECT count() FROM Channel__c WHERE Email__c='oshome@email.com.au'], 'A matching channel was not found for oshome.');
        Assert.areEqual(1, [SELECT count() FROM Channel__c WHERE Email__c='postal@email.com.au'], 'A matching channel was not found for postal');
    }
    
    /*
     * @description Update an existing channel
     */
    @isTest static void testUpdateChannel() {
        List<Channel__c> chanlst = [SELECT ID, mobile_phone__c FROM Channel__c WHERE Type__c = 'HOME'];
        
        test.startTest();

        // The field being updated is the last in a large OR statement. By checking the last one, we extend the code coverage. ORs stop processing on the first TRUE.
        chanlst[0].is_processed__c = false;
        chanlst[0].mobile_phone__c = '5555777777';   
        update chanLst;
        
        test.stopTest();    
        Assert.areEqual(1, [SELECT count() FROM Channel__c WHERE mobile_phone__c = '5555777777'], 'An updated channel was not found.');
        
    }
    
   /*
    * Validate that both inserts and updates to a channel record are detected and an async event is triggered
    * 
    * WHEN
    * 	An emergency contact channel
    * GIVEN
    *   has a field update that does not influcence the unique key
    * THEN
    *   the update is also made on the emergency contact record
    */
    @isTest static void validate_EmergencyContact() {
        
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Process_Emergency_Contacts__c = true;
        insert fs;
        
        String sChannel = '{"City__c":"Melbourne","Country__c":"Australia","Email__c":"ectest@email.com.test","Mobile_Phone__c":"0456787111","Fullname__c":"Greg Test","Relationship__c":"BROTHER","Type__c":"EMERCONT","attributes":{"type":"Channel__c"}}';
        Channel__c aChannel = (Channel__c)JSON.deserialize(sChannel, Channel__c.class);
        Contact aContact = [SELECT id FROM Contact WHERE Person_ID_unique__c ='22245678'][0];
        aChannel.Contact__c = aContact.Id;

        test.startTest();
        // A channel is inserted and an emergency contact is created via an async process event
        insert aChannel;
        Test.getEventBus().deliver(); 

        // The channel is updated and reprocessed, and other event is triggered
        aChannel.Phone__c = '03 93525605';
        aChannel.is_processed__c = false;
		update aChannel;        
        Test.getEventBus().deliver();

        test.stopTest();

        channel__c resChannel = [select id, type__c, Relationship__c, fullname__c, Mobile_Phone__c, phone__c from channel__c where id = :aChannel.id][0];
        Assert.areEqual(resChannel.type__c,'EMERCONT');
        
        Emergency_contact__c ec = [select id, relationship__c, Alternate_Phone__c from emergency_contact__c where channel__c = :resChannel.id and contact__c = :aContact.id][0];
        Assert.areEqual(resChannel.Relationship__c.toLowercase() ,ec.relationship__c.toLowercase()); // standard field mapping in place
		Assert.areEqual(resChannel.phone__c ,ec.Alternate_Phone__c); // update succeeded
    }
    
}