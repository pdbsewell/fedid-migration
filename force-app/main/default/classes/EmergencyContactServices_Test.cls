/*
 * @description Emergency Contact Test Class
 * 
 * 01-06-2024 Martin Cadman - Inital build
 * 14-06-2024 Martin Cadman - Added channel mapping check
 * 01-07-2024 Martin Cadman - Support for EC relationship transform
 * 
 */
@isTest
(seeAllData=false isParallel=true)
public class EmergencyContactServices_Test {

    @testSetup
    public static void createTestData() {
        
        // Allow phone values to be formatted
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Format_Mobile__c = true;
		fs.Process_Emergency_Contacts__c = true;
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
        
        // A parent contact to hand EC record from
    	Contact aContact = new Contact (lastname='Smith');
        insert aContact;
            
        // An existing EC to check updates against
        Emergency_Contact__c aEC = new Emergency_Contact__c (Contact__c = aContact.id, first_name__c='Greg', relationship__c='Sibling',mobile_phone__c='03 9999 5555', active_from__c=date.today()-7);
		insert aEC;            
    }



   /*
    * @description An emergency contact should be created when an EMERCONT channel is upserted.
    * Channel Breakup must be enabled
    * 
    * GIVEN
    * 	A channel is created
    * WHEN
    * 	The channel is a valid EMERCONT record 
    * THEN
    *   An Emergency contact is created
    */
    @isTest
    public static void validate_ChannelMapping() {
        Contact aContact = [select id from Contact limit 1];
     
        // Given
        String sChannel = '{"City__c":"Melbourne","Country__c":"Australia","Email__c":"ectest@email.com.test","Mobile_Phone__c":"0456787111","Phone__c":"0456787222","Fullname__c":"Greg Test","Relationship_unverified__c":"BROTHER","Relationship__c":"BROTHER","Type__c":"EMERCONT","attributes":{"type":"Channel__c"}}';
        Channel__c aChannel = (Channel__c)JSON.deserialize(sChannel, Channel__c.class);
		aChannel.Contact__c = aContact.id;
			
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
    
   /*
    * @description 
    * GIVEN
    * 	An emergency contact record
    * WHEN
    * 	a name field is in all upper or lower case
    * THEN
    *   the name field will be corrected
    */
    @isTest
    public static void validate_Name() {
        Contact aContact = [select id from Contact limit 1];
     
		Emergency_Contact__c aEC = new Emergency_Contact__c (Contact__c = aContact.id, first_name__c='SALLY', last_name__c='smith', relationship__c='SISTER',mobile_phone__c='0401717666');

        test.startTest();
        insert aEC;
        test.stopTest();

        // Check the case correction has taken place
		aEC = [select id, first_name__c, last_name__c, relationship__c from Emergency_Contact__c where id = :aEC.id];
        Assert.isTrue(aEC.First_Name__c.equals('Sally'));
        Assert.isTrue(aEC.Last_Name__c.equals('Smith'));
        Assert.isTrue(aEC.relationship__c.equals('Sister'));
    }

   /*
    * @description 
    * GIVEN
    * 	An emergency contact record
    * WHEN
    * 	Phone formating is enabled and a phone number is on the record
    * THEN
    *   Standard phone formatting will occur
    */
    @isTest
    public static void validate_Phone() {
        Contact aContact = [select id from Contact limit 1];
		Emergency_Contact__c aEC = new Emergency_Contact__c (Contact__c = aContact.id, first_name__c='SALLY', last_name__c='SMITH', relationship__c='Sister',mobile_phone__c='0401717666', alternate_phone__c='(03) 9 5555-6666');

        test.startTest();
        insert aEC;
        test.stopTest();

        // Check the mobile formatting has taken place
		aEC = [select id, mobile_phone__c, alternate_phone__c from Emergency_Contact__c where id = :aEC.id];
        Assert.areEqual('+61 401717666', aEC.Mobile_Phone__c);    // formatted number
        Assert.areEqual('03 9 55556666', aEC.alternate_phone__c); //tidied number
    }
    
   /*
    * @description 
    * GIVEN
    * 	An existing emergency contact record
    * WHEN
    * 	Key fields are changed
    * THEN
    *   A new UID is generated (name & relationship field changes)
    *   The new phone is formatted
    */
    @isTest
    public static void validate_UpdateChange() {
		Emergency_Contact__c aEC = [select id, first_name__c, last_name__c, key_UID__c, alternate_phone__c, relationship__c from Emergency_Contact__c limit 1];
        String orginalKey = aEC.Key_UID__c;

        test.startTest();
        aEC.Last_Name__c = 'Jackson';
        aEC.alternate_phone__c = '0491777432';
        aEC.relationship__c = 'Brother-in-law';
        update aEC;
        test.stopTest();

        aEC = [select id, key_UID__c, alternate_phone__c from Emergency_Contact__c where id = :aEC.id];
        Assert.areNotEqual(orginalKey, aEC.Key_UID__c,'The unique key has not been updated after the first name changed');
        Assert.areEqual('+61 491777432',  aEC.Alternate_Phone__c);
    }
    
   /*
    * @description 
    * GIVEN
    * 	An active emergency contact
    * WHEN
    * 	an active to date is added (in the past)
    * THEN
    *   The formula field become inactive
    */
    @isTest
    public static void validate_ActiveStatus() {
		Emergency_Contact__c aEC = [select id, active__c, active_from__c, active_to__c from Emergency_Contact__c limit 1];
		Assert.isTrue(aEC.active__c);
        
        test.startTest();
        aEC.active_to__c = date.today()-1; // set the date to yesterday
        update aEC;
        test.stopTest();

        aEC = [select id, active__c from Emergency_Contact__c where id = :aEC.id];
        Assert.isFalse(aEC.active__c);
    }
}