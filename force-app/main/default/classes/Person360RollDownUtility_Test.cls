/**
 * @description Utility Test Class to RollDown Contact details to Email, Phone, Address & Name
 **/
@isTest(isParallel=true)
private class Person360RollDownUtility_Test {
    static Contact contactRecord {get; set;}

    /**
     * @description Set features switches
     */
    @testSetup 
    static void setupData(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        upsert cs;
    }

    /**
     * @description Test basic rolldown and splitting Contact.First_Name__c into Name__c.First_Name__c and Name__c.Middle_Name__c
     */
    @IsTest 
    static void nameTest() {
        Contact cont = createContact();
        cont.First_Name__c = 'Christopher Julius';
        cont.LastName = 'Rock';
        cont.Preferred_Name__c = 'Chris';
        cont.Email = cont.FirstName + cont.LastName + '@example.com';

        Test.startTest();
        insert cont; // do rolldown
        Test.stopTest();
        Assert.isTrue(
            NameTriggerHandler.AllocatePrimaryRecordRunCount < 3,
            'NameTriggerHandler.AllocatePrimaryRecord ran too many times'
        );

        // Validate that only 1 Name record has been generated
        List<Name__c> result = [
            SELECT Is_Primary__c, Type__c, First_Name__c, Middle_Name__c, Last_Name__c, Preferred_First_Name__c
            FROM Name__c WHERE Contact__r.Id =: contactRecord.Id
        ];
        Assert.areEqual(1, result.size(), 'More than 1 Name record has been generated!');
        Assert.isTrue(result[0].Is_Primary__c, 'Inserted Name record is not primary');
        Assert.areEqual('Christopher', result[0].First_Name__c);
        Assert.areEqual('Julius', result[0].Middle_Name__c);
        Assert.areEqual(cont.LastName, result[0].Last_Name__c);
        Assert.areEqual(cont.Preferred_Name__c, result[0].Preferred_First_Name__c);
    }

    /**
     *  @description Rolldown the name fields from a contact, creating a new name__c record.
     * 	Change the name__c start date (back in time)
     * 	Update the contact name field, creating a new name__c via rolldown, with todays date as the start date. This should make it primary.
     * 	Revert the name back to the original and add a preferred first name. The original name__c will be updated.
     */
    @IsTest
    static void nameStartDate() {
        
        // Which fields are configured for rolldown? These are the only ones we need to update.
        
        Person_360_Mapping__mdt fnameMapping = [select ContactSourceField__c
                               from Person_360_Mapping__mdt
                               where RollDirection__c in ('Down','Both')
                               and RollDownSObject__r.QualifiedApiName = 'Name__c'
                               and ContactSourceField__c like 'First%' limit 1];

        Person_360_Mapping__mdt lnameMapping = [select ContactSourceField__c
                               from Person_360_Mapping__mdt
                               where RollDirection__c in ('Down','Both')
                               and RollDownSObject__r.QualifiedApiName = 'Name__c'
                               and ContactSourceField__c like 'Last%' limit 1];
        
        
        Contact cont = createContact();

        //.. GIVEN .. An updated contact with a 'old' name contact point
        cont.put(fnameMapping.ContactSourceField__c,'Jayda');
        cont.put(lnameMapping.ContactSourceField__c,'Guy');

        Test.startTest();
        insert cont;
        
        Name__c name01 = [SELECT Id FROM Name__c];
        name01.Start_Date__c = Date.today().addDays(-1);
        update name01;
       
        cont.put(lnameMapping.ContactSourceField__c,'G');
        update cont; // Will roll-down to a new Name__c
        
        List<Name__c> result01 = [
            SELECT Start_Date__c, Last_Name__c FROM Name__c WHERE Contact__c = :cont.Id ORDER BY Start_Date__c DESC
        ];

        //.. WHEN .. The values are reverted and a PFN is added        
        cont.Preferred_Name__c = 'Foo';
        cont.put(lnameMapping.ContactSourceField__c,'Guy');
        update cont; // Will roll-down to original Name__c

        List<Name__c> result02 = [
            SELECT Start_Date__c, Last_Name__c, Preferred_First_Name__c FROM Name__c WHERE Contact__c = :cont.Id ORDER BY Start_Date__c DESC
        ];
        Test.stopTest();
        
        //.. THEN .. The original name will have the preferred firstname and the new name will todays as the start date
        Assert.areEqual(2, result01.size());
        Assert.areNotEqual(result01[0].Start_Date__c, result01[1].Start_Date__c);
        Assert.areEqual('G', result01[0].Last_Name__c);
        Assert.areEqual('Guy', result01[1].Last_Name__c);

        Assert.areEqual(2, result02.size());
        Assert.areEqual(name01.Start_Date__c, result02[1].Start_Date__c);
    }

    /**
     * @description Test rolldown of Preferred_Name__c
     */
    @IsTest
    static void preferredFirstNameTest() {
        Contact cont = createContact();
        cont.Preferred_Name__c = 'Pfn';

        Test.startTest();
        insert cont; // do rolldown

        // Validate initial rolldown
        Name__c[] nameResults1 = [
            SELECT First_Name__c, Last_Name__c, Preferred_First_Name__c, Middle_Name__c
            FROM Name__c
        ];

        Contact ca = [select first_name__c, last_name__c from contact where id = :cont.id];
        
        Assert.areEqual(1, nameResults1.size());
        Assert.areEqual(cont.FirstName, nameResults1[0].First_Name__c);
        Assert.areEqual(cont.LastName, nameResults1[0].Last_Name__c);
        Assert.areEqual(cont.Preferred_Name__c, nameResults1[0].Preferred_First_Name__c);
        Assert.areEqual(cont.MiddleName, nameResults1[0].Middle_Name__c);

        // Clear PFN
        cont.Preferred_Name__c = null;
        update cont; // do rolldown
        Test.stopTest();

        // Validate clearing of PFN and that rolldown updated existing Name__c
        Name__c nameResults2 = [SELECT First_Name__c, Middle_Name__c, Preferred_First_Name__c
            					  FROM Name__c WHERE Id = :nameResults1[0].Id];

        Assert.areEqual(cont.FirstName, nameResults2.First_Name__c);
        Assert.areEqual(cont.MiddleName, nameResults2.Middle_Name__c);
        Assert.areEqual(cont.Preferred_Name__c, nameResults2.Preferred_First_Name__c);
    }

    /**
     * @description Test rolldown of Preferred_Name__c for MUM Staff Contact
     */
    @IsTest
    static void preferredFirstNameMUMStaffTest() {

        //GIVEN - a MUM Staff Contact
        Contact cont = TestHelper.createStaffContacts(1)[0];
        cont.First_Name__c = 'John Jack';
        cont.Preferred_Name__c = 'John Jack Monash';
        cont.LastName = 'Monash';
        cont.Personnel_Area_Code__c='MY01';

        Test.startTest();
        //WHEN - is inserted
        insert cont; // do rolldown

        Name__c[] nameResults1 = [
            SELECT First_Name__c, Last_Name__c, Preferred_First_Name__c, Middle_Name__c
            FROM Name__c
        ];

        //THEN - Name details are rolled down except for PFN
        Assert.areEqual(1, nameResults1.size());
        Assert.areEqual('Jack', nameResults1[0].Middle_Name__c);
        Assert.areEqual('John', nameResults1[0].First_Name__c);
        Assert.areEqual(cont.LastName, nameResults1[0].Last_Name__c);
        Assert.areEqual(null, nameResults1[0].Preferred_First_Name__c); // ignored for MUM Staff contact
    }

    /**
     * @description Validate the number of email addresses that have rolled down and that Monash emails are dealt with correctly
     */
    @isTest
    static void emailRecordTest() {
        setupDataManual();
        //Pre set Contact Data
        Test.startTest();

        // Validate that only 4 Email records has been generated (Email, Personal_Email__c, Monash_Email_Address__c, Business_Email_Address__c)
        List<Email__c> lemails = [SELECT Id, Name FROM Email__c WHERE Contact__r.Id =: contactRecord.Id];
        Assert.areEqual(4, lemails.size(), 'Failed! Expected is 4 emails records!');

        //TriggerCommon.enableTrigger('Contact');
        Contact conRec = [SELECT Id, Personal_Email__c FROM Contact WHERE Id =: contactRecord.Id];
        conRec.Monash_Email_Address__c = 'test001email@test.com';
        update conRec;
        Test.stopTest();

        // Validate that only 5 Email records in total (4 existing records from above + due to update in Contact.Email)
        List<Email__c> lemailsFromUpdate = [SELECT Id, Name FROM Email__c];
        Assert.areEqual(5, lemailsFromUpdate.size(), 'Failed! Expected is 5 emails records!');
    }

    /**
     * @description Validate the number of phone numbers that have rolled down
     */
    @isTest
    static void phoneRecordTest() {
        Test.startTest();
        setupDataManual();
        Test.stopTest();

        // Validate that only 6 Phone records has been generated (Phone, MobilePhone, HomePhone, OtherPhone, AssistantPhone, Fax)
        List<Phone__c> lphones = [SELECT Id, Name FROM Phone__c WHERE Contact__r.Id =: contactRecord.Id];
        Assert.areEqual(6, lphones.size(), 'Failed! Expected is 6 phone records!');
    }

    
    /**
     * @description Validate the number of addresses that have rolled down - Mailing and Other
     */
    @isTest
    static void addressRecordTest() {
        Test.startTest();
        setupDataManual();
        Test.stopTest();

        // Validate that only 2 Address records has been generated (Mailing Address, Other Address)
        List<Address__c> laddress = [SELECT Id, Name FROM Address__c WHERE Contact__r.Id =: contactRecord.Id];
        Assert.areEqual(2, laddress.size(), 'Failed! Expected is 2 address records!');
    }

    /**
     *  @description Validate that Roll Down does not remove the End Date from Contact Point records
    */
    @IsTest
    static void preserveEndDateTest() {
        //GIVEN: We have a contact with previous Contact Points that have been End Dated
        setupDataManual();

        //End dated Name
        Name__c name = new Name__c();
        name.Contact__c = contactRecord.Id;
        name.Start_Date__c = Date.today().addDays(-2);
        name.End_Date__c = Date.today().addDays(-1);
        name.Is_Primary__c = false;
        name.Is_Active__c = false;
        name.Source__c = 'Undefined';
        name.First_Name__c = 'FName';
        name.Last_Name__c = 'LName';
        name.type__c = 'Common';
        insert name;

        //End dated Email
        Email__c email = new Email__c();
        email.Contact__c = contactRecord.Id;
        email.Start_Date__c = Date.today().addDays(-2);
        email.End_Date__c = Date.today().addDays(-1);
        email.Is_Primary__c = false;
        email.Is_Active__c = false;
        email.Source__c = 'Undefined';
        email.Name = 'testemail@gmailtesting.com';
        email.Classification__c = 'Private';
        insert email;

        //End dated Phone
        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today().addDays(-2);
        phone.End_Date__c = Date.today().addDays(-1);
        phone.Is_Primary__c = false;
        phone.Is_Active__c = false;
        phone.Source__c = 'Undefined';
        phone.Name = '+61 400000000';
        phone.Type__c = 'Mobile';
        phone.Classification__c = 'Private';
        insert phone;

        //End dated Address
        Address__c address = new Address__c();
        address.Contact__c = contactRecord.Id;
        address.Start_Date__c = Date.today().addDays(-2); 
        address.End_Date__c = Date.today().addDays(1); //For Address, end date is preserved only if its a future date
        address.Is_Primary__c = false;
        address.Is_Active__c = false;
        address.Source__c = 'Undefined';
        address.Street_Name__c = '1';
        address.City__c = '2';
        address.State__c = '3';
        address.Post_Code__c = '4';
        address.Country2__c = '5';
        address.Type__c = 'Mailing';
        address.Classification__c = 'Private';
        insert address;

        //WHEN: We update the contact record to the end dated Contact Points
        Test.startTest();
        Contact testCont = [SELECT Id, First_Name__c, Last_Name__C FROM Contact WHERE Id =: contactRecord.Id];
        testCont.First_Name__c = 'FName';
        testCont.Last_Name__c = 'LName';
        testCont.Email = 'testemail@gmailtesting.com';
        testCont.Phone = '+61 400000000';
        testCont.MailingStreet = '1';
        testCont.MailingCity = '2';
        testCont.MailingState = '3';
        testCont.MailingPostalCode = '4';
        testCont.MailingCountry = '5';
        update testCont;
        Test.stopTest();

        //THEN: End date on Contact Point records should still be preserved
        Name__c insertedName = [SELECT Id, End_Date__c FROM Name__c WHERE Id =: name.Id];
        Email__c insertedEmail = [SELECT Id, End_Date__c FROM Email__c WHERE Id =: email.Id];
        Phone__c insertedPhone = [SELECT Id, End_Date__c FROM Phone__c WHERE Id =: phone.Id];
        Address__c insertedAddress = [SELECT Id, End_Date__c FROM Address__c WHERE Id =: address.Id];
        Assert.areEqual(insertedName.End_Date__c, name.End_Date__c, 'Name End Date was not preserved via rolldown');
        Assert.areEqual(insertedEmail.End_Date__c, email.End_Date__c, 'Email End Date was not preserved via rolldown');
        Assert.areEqual(insertedPhone.End_Date__c, phone.End_Date__c, 'Phone End Date was not preserved via rolldown');
        Assert.areEqual(insertedAddress.End_Date__c, address.End_Date__c, 'Address End Date was not preserved via rolldown');
    }

    /**
     * @description Helper method to create and save a Contact record
     */
    private static void setupDataManual() {
        contactRecord = createContact();
        insert contactRecord;
    }
    
    
    /**
     * @description Helper method to generate a Contact record
     * @return An instantiated Contact record
     */
    private static Contact createContact() {
        contactRecord = new Contact();
        contactRecord.Person_ID_unique__c = '12345';
        contactRecord.Birthdate = Date.today().addYears(- 20);
        contactRecord.Citizenship__c = 'INTERNATIONAL';
        contactRecord.Citizenship_Code__c = '4';
        contactRecord.Residency_Status__c = 'Australian Permanent Resident';
        contactRecord.Email = 'test1@test.com';
        contactRecord.Personal_Email__c = 'test2@test.com';
        contactRecord.Monash_Email_Address__c = 'test3@test.com';
        contactRecord.Business_Email_Address__c = 'test4@test.com';
        contactRecord.Title = 'OAM';
        contactRecord.Salutation = 'Mr';
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
        return contactRecord;
    }
}