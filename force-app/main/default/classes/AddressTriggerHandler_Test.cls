/**
 * @description Address Trigger Handler Test
 *
 * @author P.Victoriano
 * @date 03/14/19
 *
 *
 * @revision
 *   2019-03-14 - P.Victoriano - link to EPCP-112
 *   2020-06-15 - J.Mapanao - Added EvaluateIfCanSetPrimary
 *   2020-06-25 - Stefan Scheit - Removed logic to populate/format Address__c.Name (as it's been changed to auto-number a while back)
 * 
 **/
@isTest(isParallel=true)
private class AddressTriggerHandler_Test {
    static Contact contactRecord {get; set;}
    static Address__c addressRecord {get; set;}

    /**
     * @description Configure features switches
     */ 
    @testSetup
    static void setupData(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;
    }
    
    /**
     * @description The latest start dated address should be primary
     */ 
    @isTest
    static void validate_primaryToggle() {
        //Given
        setupDataManual();

        Test.startTest();

        addressRecord = new Address__c();
        addressRecord.Contact__c = contactRecord.Id;
        addressRecord.Street_Name__c = '222 Bourke Street';
        addressRecord.City__c = 'Melbourne';
        addressRecord.State__c = 'Victoria';
        addressRecord.Country2__c = 'Australia';
        addressRecord.Start_Date__c = Date.today()-1;
        addressRecord.Classification__c = 'Private';
        addressRecord.Type__c = 'Billing';
        addressRecord.Is_Primary__c = true;
        insert addressRecord;
        Assert.isNotNull(addressRecord.Id, 'Address Record Insert Failed');
        Test.getEventBus().deliver();

        //When - New Primary is Inserted
        Address__c addNew = new Address__c();
        addNew.Contact__c = contactRecord.Id;
        addNew.Street_Name__c = '321 Ferntree Gully Rd';
        addNew.City__c = 'Mount Waverley';
        addNew.State__c = 'Victoria';
        addNew.Country2__c = 'Australia';
        addNew.Start_Date__c = Date.today();
        addNew.Classification__c = 'Private';
        addNew.Type__c = 'Billing';
        addNew.Is_Primary__c = true; // This will be honoured as this address is more recent
        insert addNew;
        Assert.isNotNull(addNew.Id, 'Address Record Insert Failed');
        Test.getEventBus().deliver();
        Test.stopTest();

        //Then - Test if Primary is toggled on the last Primary Record
        Assert.areEqual(1, [SELECT count() FROM Address__c WHERE Id = :addressRecord.Id AND Is_Primary__c = false], 'Original address should no longer be primary');
    }
    
    /**
     * @description The latest start dated address should be primary
     */ 
    @isTest
    static void validate_primaryToggleUpdate() {
        //Given
        setupDataManual();

        Test.startTest();
        addressRecord = new Address__c();
        addressRecord.Contact__c = contactRecord.Id;
        addressRecord.Street_Name__c = '222 Bourke Street';
        addressRecord.City__c = 'Melbourne';
        addressRecord.State__c = 'Victoria';
        addressRecord.Country2__c = 'Australia';
        addressRecord.Start_Date__c = Date.today();
        addressRecord.Classification__c = 'Private';
        addressRecord.Type__c = 'Billing';
        addressRecord.Is_Primary__c = true;
        insert addressRecord;
        Assert.isNotNull(addressRecord.Id, 'Address Record Insert Failed');
        Test.getEventBus().deliver();
        
        Address__c addNew = new Address__c();
        addNew.Contact__c = contactRecord.Id;
        addNew.Street_Name__c = '321 Ferntree Gully Rd';
        addNew.City__c = 'Mount Waverley';
        addNew.State__c = 'Victoria';
        addNew.Country2__c = 'Australia';
        addNew.Start_Date__c = Date.today();
        addNew.Classification__c = 'Private';
        addNew.Type__c = 'Billing';
        addNew.Is_Primary__c = false; // This should be recalculated
        insert addNew;
        Assert.isNotNull(addNew.Id, 'Address Record Insert Failed');

        Test.getEventBus().deliver();
        Test.stopTest();
        
        //Then - Test if Primary is toggled on the last Primary Record
        Assert.areEqual(1, [SELECT count() FROM Address__c WHERE Id = :addressRecord.Id AND Is_Primary__c = false], 'Original address should no longer be primary');
    }
    
    /**
     * @description GIVEN User create new Address__c record WHERE Start_Date__c > TODAY AND Is_Active__c = TRUE
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    @isTest
    static void validate_toggleIsActiveScenario1() {
        //Given
        setupDataManual();
        Address__c address = new Address__c();
        address.Contact__c = contactRecord.Id;
        address.Street_Name__c = 'Test Street Name 001';
        address.City__c = 'Melbourne 001';
        address.State__c = 'Victoria';
        address.Post_Code__c = '3000';
        address.Country2__c = 'Australia';
        address.Start_Date__c = Date.today().addDays(5);
        address.Is_Active__c = true;
        address.Classification__c = 'Private';

        Test.startTest();
        insert address;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.isFalse([SELECT Is_Active__c FROM Address__c WHERE Id =: address.Id].Is_Active__c,'Address record should be inactive');
    }

    /**
     * GIVEN User create new Address__c record WHERE Start_Date__c = TODAY AND Is_Active__c = FALSE
     * WHEN User click Save
     * THEN set Is_Active__c to TRUE
     */
    @isTest
    static void validate_toggleIsActiveScenario2() {
        //Given
        setupDataManual();
        Address__c address = new Address__c();
        address.Contact__c = contactRecord.Id;
        address.Street_Name__c = 'Test Street Name 002';
        address.City__c = 'Melbourne 002';
        address.State__c = 'Victoria';
        address.Post_Code__c = '3000';
        address.Country2__c = 'Australia';
        address.Start_Date__c = Date.today();
        address.Is_Active__c = false;
        address.Classification__c = 'Private';

        Test.startTest();
        insert address;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.isTrue([SELECT Is_Active__c FROM Address__c WHERE Id =: address.Id].Is_Active__c,'Address record should be active');
    }
    /**
     * GIVEN User create new Address__c record WHERE End_Date__c < TODAY AND Is_Active__c = true
     * WHEN User click Save
     * THEN set Is_Active__c to FALSE
     */
    @isTest
    static void validate_toggleIsActiveScenario3() {
        //Given
        setupDataManual();
        Address__c address = new Address__c();
        address.Contact__c = contactRecord.Id;
        address.Street_Name__c = 'Test Street Name 002';
        address.City__c = 'Melbourne 002';
        address.State__c = 'Victoria';
        address.Post_Code__c = '3000';
        address.Country2__c = 'Australia';
        address.Start_Date__c = Date.today().addDays(-5);
        address.End_Date__c = Date.today().addDays(-3);
        address.Is_Active__c = true;
        address.Classification__c = 'Private';

        Test.startTest();
        insert address;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.isFalse([SELECT Is_Active__c FROM Address__c WHERE Id =: address.Id].Is_Active__c,'Address record should be inactive');
    }
    
    @isTest
    static void validate_toggleIsActiveScenario4() {
        //Given
        setupDataManual();
        Address__c address = new Address__c();
        address.Contact__c = contactRecord.Id;
        address.Street_Name__c = 'Test Street Name 002';
        address.City__c = 'Melbourne 002';
        address.State__c = 'Victoria';
        address.Post_Code__c = '3000';
        address.Country2__c = 'Australia';
        address.Start_Date__c = Date.today().addDays(-4);
        address.End_Date__c = Date.today().addDays(-3);
        address.Is_Active__c = true;
        address.Classification__c = 'Private';
        insert address;

        Test.startTest();
        Address__c addressToUpdate = [SELECT Start_Date__c FROM Address__c WHERE Id =: address.Id];
        addressToUpdate.Start_Date__c = Date.today().addDays(-5);
        update addressToUpdate;
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.isFalse([SELECT Is_Active__c FROM Address__c WHERE Id =: address.Id].Is_Active__c,'Address record should be inactive');
    }
    
    /**
     * Scenario:
     * GIVEN A User login to UniCRM
     * AND search for a contact record
     * AND contact record is not student
     * WHEN new address record inserted manually as primary
     * THEN it will roll up in Mailing Address fields
     */
    @isTest
    static void validate_rollupNewPrimaryAddress() {
        setupDataManual();
        Address__c addRess = new Address__c();
        addRess.Contact__c = contactRecord.Id;
        addRess.Start_Date__c = Date.today();
        addRess.Is_Primary__c = true;
        addRess.Is_Active__c = true;
        addRess.Source__c = 'Undefined';
        addRess.Type__c = 'Physical';
        addRess.Classification__c = 'Private';
        addRess.Street_Name__c = '120 Collins Street';
        addRess.City__c = 'Melbourne';
        addRess.State__c = 'Victoria';
        addRess.Post_Code__c = '3000';
        addRess.Country2__c = 'Australia';

        Test.startTest();
        insert addRess;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact con = [SELECT Id,MailingStreet,OtherStreet FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('120 Collins Street', con.MailingStreet, 'Expected new primary address record will roll up and will be stored in Mailing Address fields not met');
        Assert.areEqual('111 Bourke Street', con.OtherStreet, 'Expected OtherStreet should be 111 Bourke Street');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new address record inserted manually as primary
     * AND no callista record exists
     * THEN roll up the latest start date
     */
    @isTest
    static void validate_rollupPrimaryStartDate() {
        setupDataManual();
        contactRecord.Is_Student__c = true;
        update contactRecord;
        List<Channel__c> chanlst = new List<Channel__c>();
        Test.startTest();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Street__c = '55 Collin St',
                Post_Code__c = '3000',
                State__c = 'Vic',
                City__c = 'Melbourne',
                Country__c = 'Australia'
            )
        ); 
        
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        
        Contact con = [SELECT Id,MailingStreet,HomePhone FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('55 Collin St', con.MailingStreet, 'Expected new primary address record will roll up and will be stored in Mailing Address fields not met');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new address record inserted manually as primary
     * AND there is callista record exists
     * THEN roll up the latest greatest
     */
    @isTest
    static void validate_rollupCallistaAddress() {
        setupDataManual();
        contactRecord.Is_Student__c = true;
        update contactRecord;
        List<Channel__c> chanlst = new List<Channel__c>();
        Test.startTest();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Street__c = '55 Collin St',
                Post_Code__c = '3000',
                State__c = 'Vic',
                City__c = 'Melbourne',
                Country__c = 'Australia',
                Source_System__c = 'Callista'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,MailingStreet,HomePhone FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('55 Collin St', con.MailingStreet, 'Expected new primary address record will roll up and will be stored in Mailing Address fields not met');
    }

    /**
     * For students, such an update (setting end date, or marking the the contact point inactive) remains blocked, i.e. no change.
     * Scenario:
     * GIVEN Contact is a student
     * WHEN User end dated a Callista address contact point with parent active channel
     * THEN it will revert back the callista address contact point from parent active channel details
     */
    @isTest
    static void validate_protectCallistaAddress() {
        setupDataManual();
        contactRecord.Is_Student__c = true;
        update contactRecord;
        List<Channel__c> chanlst = new List<Channel__c>();
        Test.startTest();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Street__c = '55 Collin St',
                Post_Code__c = '3000',
                State__c = 'Vic',
                City__c = 'Melbourne',
                Country__c = 'Australia',
                Source_System__c = 'Callista',
                Start_Date__c = Date.today()
            )
        ); 
        
        insert chanlst;
        Test.getEventBus().deliver();
        List<Address__c> addressList = [SELECT Id, Name, Street_Name__c, End_Date__c, Channel__c FROM Address__c WHERE Contact__r.Id =: contactRecord.Id AND Street_Name__c  = '55 Collin St'];
        Assert.areEqual(1, addressList.size());
        Assert.isNull(addressList[0].End_Date__c, 'Expected End Date of address with channel is null');
        addressList[0].End_Date__c = Date.today();
        update addressList;
        Test.stopTest();
        
        List<Address__c> updatedAddressList = [SELECT Id, Name, Street_Name__c, End_Date__c, Channel__c FROM Address__c WHERE Contact__r.Id =: contactRecord.Id AND Street_Name__c  = '55 Collin St'];
        Assert.areEqual(1, updatedAddressList.size());
        Assert.isNull(updatedAddressList[0].End_Date__c, 'Expected End Date of address with channel is null');
    }

    /**
     * A contact point of a non-student with source=Callista can be end-dated (by a user) and 
     * remains end-dated despite an active Channel (lookup) record, i.e. the email remains active in the Channel record.
     * Scenario:
     * GIVEN Contact is non-student
     * WHEN User end dated a Callista address contact point with parent active channel
     * THEN allow end dating the callista address contact point
     */
    @isTest
    static void validate_endDateCallistaAddress() {
        setupDataManual();
        List<Channel__c> chanlst = new List<Channel__c>();

        Test.startTest();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Street__c = '55 Collin St',
                Post_Code__c = '3000',
                State__c = 'Vic',
                City__c = 'Melbourne',
                Country__c = 'Australia',
                Source_System__c = 'Callista',
                Start_Date__c = Date.today()
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        List<Address__c> addressList = [SELECT Id, Name, Street_Name__c, End_Date__c, Channel__c FROM Address__c WHERE Contact__r.Id =: contactRecord.Id AND Street_Name__c  = '55 Collin St'];
        Assert.areEqual(1, addressList.size());
        Assert.isNull(addressList[0].End_Date__c, 'Expected End Date of address with channel is null');
        addressList[0].End_Date__c = Date.today();
        update addressList;
        Test.stopTest();
        
        List<Address__c> updatedAddressList = [SELECT Id, Name, Street_Name__c, End_Date__c, Channel__c FROM Address__c WHERE Contact__r.Id =: contactRecord.Id AND Street_Name__c  = '55 Collin St'];
        Assert.areEqual(1, updatedAddressList.size());
        Assert.areEqual(Date.today(), updatedAddressList[0].End_Date__c, 'Expect callista address to be end dated');
    }

    /**
     * Test the Address Key UID generation logic
     * Scenario:
     * GIVEN different address records with different street name values
     * WHEN the dml runs, the keys will be generated by the trigger logic
     * THEN comparing them with assert statements to make sure the trigger logic is correct
     */
    @IsTest
    private static void validate_addressKeyGeneration() {
        setupDataManual();
        Address__c genericAddress = new Address__c();
        genericAddress.Contact__c = contactRecord.Id;
        genericAddress.Start_Date__c = Date.today();
        genericAddress.Is_Primary__c = true;
        genericAddress.Is_Active__c = true;
        genericAddress.Source__c = 'Undefined';
        genericAddress.Type__c = 'Physical';
        genericAddress.Classification__c = 'Private';
        genericAddress.City__c = 'Melbourne';
        genericAddress.State__c = 'Victoria';
        genericAddress.Post_Code__c = '3000';
        genericAddress.Country2__c = 'Australia';

        final String standardStreetLine = '1 Test Street';
        final String allUpperStreetLine = '1 TEST STREET';
        final String dirtyStreetLine = '1 Test   Street,#*&(@(*&';
        final String differentStreetLine = '1 Real Street';

        Address__c standardAdd = genericAddress.clone(false,true);
        Address__c upperAdd = genericAddress.clone(false,true);
        Address__c dirtyAdd = genericAddress.clone(false,true);
        Address__c differentAdd = genericAddress.clone(false,true);

        standardAdd.Street_Name__c = standardStreetLine;
        upperAdd.Street_Name__c = allUpperStreetLine;
        dirtyAdd.Street_Name__c = dirtyStreetLine;
        differentAdd.Street_Name__c = differentStreetLine;

        AddressTriggerHandler.PopulateHash handler = new AddressTriggerHandler.PopulateHash();
        Assert.areEqual(handler.generateAddressKey(standardAdd), handler.generateAddressKey(upperAdd), 'Key generation should be case in-sensitive, failed assertion due to casing affected the outcome');
        Assert.areEqual(handler.generateAddressKey(standardAdd), handler.generateAddressKey(dirtyAdd), 'Key generation should be ignoring non-alphanumeric characters, failed assertion due to special characters affected the outcome');
        Assert.areNotEqual(handler.generateAddressKey(differentAdd), handler.generateAddressKey(standardAdd), 'Key generated based on different address field values should produce different key values');
        Assert.areNotEqual(handler.generateAddressKey(differentAdd), handler.generateAddressKey(upperAdd), 'Key generated based on different address field values should produce different key values');
        Assert.areNotEqual(handler.generateAddressKey(differentAdd), handler.generateAddressKey(dirtyAdd), 'Key generated based on different address field values should produce different key values');

        Map<String,Address__c> addressMap = new Map<String,Address__c>();

        addressMap.put(standardAdd.Street_Name__c, standardAdd);
        addressMap.put(upperAdd.Street_Name__c, upperAdd);
        addressMap.put(dirtyAdd.Street_Name__c, dirtyAdd);
        addressMap.put(differentAdd.Street_Name__c, differentAdd);

        Exception exp;
        try {
            insert addressMap.values();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp, 'Expecting an exception occurred, did not happen');
        Assert.isTrue(exp.getTypeName().containsIgnoreCase('DmlException'), 'Exception thrown not the expected type');
        Assert.isTrue(exp.getMessage().containsIgnoreCase('DUPLICATE_VALUE'), 'Exception message not expected');
    }

    /**
     * Set up data manually
     */
    private static void setupDataManual() {
        contactRecord = new Contact();
        contactRecord.Person_ID_unique__c = '12345';
        contactRecord.Birthdate = Date.today().addYears(- 20);
        contactRecord.Citizenship__c = 'INTERNATIONAL';
        contactRecord.Citizenship_Code__c = '4';
        contactRecord.Residency_Status__c = 'Australian Permanent Resident';
        contactRecord.Email = 'test@test.com';
        contactRecord.Personal_Email__c = 'test@test.com';
        contactRecord.Monash_Email_Address__c = 'test@test.com';
        contactRecord.Business_Email_Address__c = 'test@test.com';
        contactRecord.Title = 'OAM';
        contactRecord.Salutation = 'Mr.';
        contactRecord.FirstName = 'testFirstName';
        contactRecord.MiddleName = 'testMiddleName';
        contactRecord.LastName = 'testLastName';
        contactRecord.Suffix = 'testSuffix';
        contactRecord.Gender__c = 'None';
        contactRecord.Phone = '+61390008000';
        contactRecord.MobilePhone = '+61400111222';
        contactRecord.HomePhone = '+61390008001';
        contactRecord.OtherPhone = '+61390008002';
        contactRecord.AssistantPhone = '+61390008003';
        contactRecord.Fax = '+61390008999';
        contactRecord.MailingStreet = '350 Bourke Street';
        contactRecord.MailingCity = 'Melbourne';
        contactRecord.MailingState = 'Victoria';
        contactRecord.MailingPostalCode = '3000';
        contactRecord.MailingCountry = 'Australia';
        contactRecord.OtherStreet = '111 Bourke Street';
        contactRecord.OtherCity = 'Melbourne';
        contactRecord.OtherState = 'Victoria';
        contactRecord.OtherPostalCode = '3000';
        contactRecord.OtherCountry = 'Australia';

        insert contactRecord;
        Assert.isNotNull(contactRecord.Id, 'Contact Record Insert Failed');
    }
}