/**
 * @author          J.Mapanao
 * @date			15/06/2020
 * @group			Test
 * @description     Class to test logic in Person360RollUpServices
 * @revision
 *                  15/10/2020 - Stefan Scheit - Replaced Async_Process__e with Contact_Point_Event__e
 * 					15/06/2020 - J.Mapanao - Initial version
 * 					01/04/2022 - Tom Gangemi - Add Preferred First Name changes
 *                  20/09/2024 - Martin Cadman - Added a call to performSynchronousRollUp (invokable)
 *                  09/10/2024 - Martin Cadman - 
 */
@isTest(isParallel=false) // In parallel Apex tests, DML operations aren't permitted on this type of object: User
private class Person360RollUpServices_Test {
    static Contact contactRecord {get; set;}

    /**
     * Set up Data
     * @return [description]
     */
    @testSetup static void setupData(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        cs.Enable_Force_Rollup__c = false;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;
        
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Format_Mobile__c = true;
        insert fs;
    }

    @IsTest
    static void rollupWithoutNameRecords() {
        Contact cont = createContact();
        TriggerCommon.disableTrigger('Contact');
        insert cont;
        Email__c emailCp = new Email__c(Contact__c = cont.Id, Name = 'person@example.com', Classification__c = 'Private');
        insert emailCp;
        TriggerCommon.enableTrigger('Contact');

        Test.startTest();
		Person360RollUpServices.performSynchronousRollUp(new list<Id>{cont.Id});
        //new Person360RollUpServices.PerformRollUp().run(new Set<String>{cont.Id}, new List<String>{'Name__c','Email__c'});
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT Id FROM Exception_Log__c WHERE Function_Name__c = 'Person360RollUpServices.PerformRollUp'].size(),
            'There should not be any rollup exceptions'
        );
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
    static void addressRecordTest1() {
        setupContactManually();
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
        Assert.areEqual('120 Collins Street', con.MailingStreet, 'Expected new primary address record will roll up and will be stored in Mailing Address fields not met.');
        Assert.areEqual('200 Exhibition Street', con.OtherStreet, 'Expected OtherStreet should be 200 Exhibition Street.');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new address record inserted manually as primary
     * AND no callista record exists
     * THEN roll up the latest greatest
     */
    @isTest
    static void addressRecordTest3() {
        setupContactManually();
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
        Assert.areEqual('55 Collin St', con.MailingStreet, 'Expected new primary address record will roll up and will be stored in Mailing Address fields not met.');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new address record inserted manually as primary
     * AND there is callista record exists
     * THEN roll up the latest greatest
     */
    @isTest
    static void addressRecordTest4() {
        setupContactManually();
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
        Assert.areEqual('55 Collin St', con.MailingStreet, 'Expected new primary address record will roll up and will be stored in Mailing Address fields not met.');
    }

    /**
     * Scenario:
     * GIVEN A User login to UniCRM
     * AND search for a contact record
     * AND contact record is not student
     * WHEN new email record inserted manually as primary
     * THEN it will roll up in corresponding email fields
     */
    @isTest
    static void emailRecordTest1() {
        setupContactManually();
        Email__c email = new Email__c();
        email.Contact__c = contactRecord.Id;
        email.Start_Date__c = Date.today();
        email.Is_Primary__c = true;
        email.Name = 'test@personal2.com';
        email.Classification__c = 'Private';
        email.Source__c = 'Undefined';
        Test.startTest();
        insert email;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Personal_Email__c,Email,Monash_Email_Address__c,Business_Email_Address__c FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('test@personal2.com', con.Personal_Email__c, 'Expected Personal_Email__c value shoudld be test@personal2.com');
        Assert.areEqual('test@personal2.com', con.Email, 'Expected Email value shoudld be test@personal2.com as it is the latest greatest');
        Assert.areEqual('test@monash.edu', con.Monash_Email_Address__c, 'Expected Monash_Email_Address__c value shoudld be test@monash.edu');
        Assert.areEqual('test@business.com', con.Business_Email_Address__c, 'Expected Business_Email_Address__c value shoudld be test@business.com');
    }

    /**
     * Scenario:
     * GIVEN A new email created by Automated Process
     * WHEN new email record inserted manually as primary
     * THEN it will not roll up in corresponding email fields
     * when there is already existing primary set by user
     */
    @isTest
    static void emailRecordTest2() {
        setupContactManually();

        Test.getEventBus().deliver();
        TriggerCommon.enableTrigger('Contact');

        Email__c email = new Email__c();
        email.Contact__c = contactRecord.Id;
        email.Start_Date__c = Date.today();
        email.Is_Primary__c = true;
        email.Name = 'test@personal2.com';
        email.Classification__c = 'Private';
        email.Source__c = 'Undefined';
        insert email;
        Test.getEventBus().deliver();
        TriggerCommon.enableTrigger('Contact');

        Test.startTest();
        List<Channel__c> chanlst = new List<Channel__c>();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Email__c = 'test@personal3.com'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Personal_Email__c,Email FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('test@personal3.com', con.Personal_Email__c, 'Expected Personal_Email__c value shoudld be test@personal3.com');
        Assert.areEqual('test@personal2.com', con.Email, 'Expected Email value shoudld be test@personal2.com as it is the latest greatest');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new email record inserted manually as primary
     * AND no callista record exists
     * THEN roll up the latest greatest
     */
    @isTest
    static void emailRecordTest3() {
        setupContactManually();
        contactRecord.Is_Student__c = true;
        update contactRecord;
        Test.startTest();
        List<Channel__c> chanlst = new List<Channel__c>();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Email__c = 'test@personal3.com'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Personal_Email__c,Email FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('test@personal3.com', con.Personal_Email__c, 'Expected new primary email record will roll up and will be stored in Email fields not met.');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new email record inserted manually as primary
     * AND there is callista record exists
     * THEN roll up the latest greatest
     */
    @isTest
    static void emailRecordTest4() {
        setupContactManually();
        contactRecord.Is_Student__c = true;
        update contactRecord;
        List<Channel__c> chanlst = new List<Channel__c>();
        Test.startTest();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Email__c = 'test@personal3.com',
                Source_System__c = 'Callista'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Personal_Email__c,email FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('test@personal3.com', con.Personal_Email__c, 'Expected new primary address record will roll up and will be stored in Email field not met.');
    }

    /**
     * Scenario:
     * GIVEN A User login to UniCRM
     * AND search for a contact record
     * AND contact record is not student or a student
     * WHEN new name record inserted manually as primary
     * THEN it will roll up in corresponding name fields
     */
    @isTest
    static void nameRecordTest1() {

        Contact c = createContact();
        c.First_Name__c = 'Legal First Name';
        insert c;
        Test.getEventBus().deliver(); // do rollup

        Assert.areEqual(c.First_Name__c, [SELECT First_Name__c FROM Contact WHERE Id = :c.Id].First_Name__c);
        Name__c name = new Name__c();
        name.Contact__c = c.Id;
        name.Start_Date__c = Date.today();
        name.Is_Primary__c = true;
        name.Is_Active__c = true;
        name.Source__c = 'Undefined';
        name.Salutation__c = 'Mr';
        name.Type__c = 'Other name';
        name.First_Name__c = 'New_LFN';
        name.Last_Name__c = 'LName';
        name.Middle_Name__c = 'MName';
        name.Prefix__c = 'P';
        name.Suffix__c = 'S';
        Test.startTest();
        insert name;
        Test.stopTest(); // do rollup (includes updating Account.Name)

        Contact result = [SELECT Account.Name, FirstName, LastName, First_Name__c FROM Contact WHERE Id = :c.Id];
        Assert.areEqual(c.First_Name__c, result.First_Name__c, 'Legal first name should not rollup');
        Assert.areEqual(name.First_Name__c, result.FirstName, 'FirstName should have updated');
        Assert.areEqual(name.Last_Name__c, result.LastName, 'LastName should have updated');
        Assert.areEqual(name.First_Name__c + ' ' + name.Last_Name__c, result.Account.Name);
    }

    @IsTest
    static void nameRecordPFNTest1() {
        Contact c = createContact();
        c.First_Name__c = 'Orig LFN';
        insert c;
        Test.getEventBus().deliver(); // do rollup

        // Setup - Set PFN
        Name__c name = new Name__c();
        name.Contact__c = c.Id;
        name.Start_Date__c = Date.today();
        name.Is_Primary__c = true;
        name.Is_Active__c = true;
        name.Source__c = 'Undefined';
        name.Salutation__c = 'Mr';
        name.Type__c = 'Other name';
        name.First_Name__c = 'LFName';
        name.Last_Name__c = 'LName';
        name.Middle_Name__c = 'MName';
        name.Preferred_First_Name__c = 'PFName';
        name.Prefix__c = 'P';
        name.Suffix__c = 'S';

        Test.startTest();

        insert name;
        Test.getEventBus().deliver(); // do rollup

        // Validate
        Contact result1 = [
            SELECT FirstName, First_Name__c, Preferred_Name__c, LastName, MiddleName, Salutation, Salutation_ERDA__c, Suffix
            FROM Contact WHERE Id = :c.Id
        ];
        Assert.areEqual(c.First_Name__c, result1.First_Name__c, 'LFN should be unchanged');
        Assert.areEqual(name.Preferred_First_Name__c, result1.Preferred_Name__c);
        Assert.areEqual(name.Preferred_First_Name__c, result1.FirstName, 'PFN should rollup to FN');
        Assert.areEqual(name.Last_Name__c, result1.LastName);
        Assert.areEqual(name.Salutation__c, result1.Salutation_ERDA__c);
        Assert.areEqual(name.Salutation__c, result1.Salutation);
        Assert.areEqual(name.Suffix__c, result1.Suffix);
        Assert.isNull(result1.MiddleName, 'Rollup of PFN should clear middlename');

        // Setup - Clear PFN
        Name__c nameWithoutPFN = name.clone(true);
        nameWithoutPFN.Preferred_First_Name__c = null;
        nameWithoutPFN.Last_Name__c = 'NewLName';
        nameWithoutPFN.Middle_Name__c = 'MName';
        nameWithoutPFN.Source__c = 'Callista';

        update nameWithoutPFN;
        Test.stopTest(); // do rollup

        // Validate
        Contact result2 = [
            SELECT FirstName, First_Name__c, Preferred_Name__c, LastName, MiddleName, Salutation, Salutation_ERDA__c
            FROM Contact WHERE Id = :c.Id
        ];
        Assert.areEqual(c.First_Name__c, result2.First_Name__c, 'LFN should be unchanged');
        Assert.areEqual(name.Preferred_First_Name__c, result2.Preferred_Name__c, 'PFN should be unchanged');
        Assert.areEqual(nameWithoutPFN.First_Name__c, result2.FirstName, 'FN should rollup to FN');
        Assert.areEqual(nameWithoutPFN.Last_Name__c, result2.LastName);
        Assert.areEqual(nameWithoutPFN.Salutation__c, result2.Salutation_ERDA__c);
        Assert.areEqual(nameWithoutPFN.Middle_Name__c, result2.MiddleName);
    }

    @isTest
    static void nameRecordTestForMUMStaff() {
        // GIVEN - Contact record 
        Contact c = TestHelper.createStaffContacts(1)[0];
        c.First_Name__c = 'Legal First Name';
        c.Personnel_Area_Code__c='MY01';
        insert c;
        Test.getEventBus().deliver(); // do rollup

        Name__c name = new Name__c();
        name.Contact__c = c.Id;
        name.Start_Date__c = Date.today();
        name.Is_Primary__c = true;
        name.Is_Active__c = true;
        name.Source__c = 'Undefined';
        name.Salutation__c = 'Mr';
        name.Type__c = 'Other name';
        name.First_Name__c = 'LFN01';
        name.Last_Name__c = 'LName';
        name.Middle_Name__c = 'MName';
        name.Preferred_First_Name__c = 'PFName';
        name.Prefix__c = 'P';
        name.Suffix__c = 'S';
        Test.startTest();

        // WHEN a name record is inserted
        insert name;
        Test.stopTest(); // do rollup

        // THEN - PFN should not rollup to FN
        Contact result1 = [
            SELECT FirstName, First_Name__c, Preferred_Name__c, LastName
            FROM Contact WHERE Id = :c.Id
        ];

        Assert.isNull(result1.Preferred_Name__c);
        Assert.areEqual(name.First_Name__c, result1.FirstName, 'PFN should not rollup to FN');
        Assert.areEqual(name.Last_Name__c, result1.LastName);
    }

    @IsTest
    static void nameRecordPFNSyncToUser() {
        // GIVEN - User & Contact record exists (same authcate)
        User user = TestHelper.createTestUsers('Standard User', 1)[0];
        user.FederationIdentifier = 'abc123';
        update user;

        System.runAs(new User(Id = UserInfo.getUserId())){
            Contact con = TestHelper.createStaffContacts(1)[0];
            con.Authcate__c = 'abc123';
            insert con;
            Test.getEventBus().deliver(); // do rollup

            // Setup - Set PFN
            Name__c name = new Name__c();
            name.Contact__c = con.Id;
            name.Start_Date__c = Date.today();
            name.Is_Primary__c = true;
            name.Is_Active__c = true;
            name.Source__c = 'Undefined';
            name.Salutation__c = 'Mr';
            name.Type__c = 'Other name';
            name.First_Name__c = 'LFName';
            name.Last_Name__c = 'LName';
            name.Middle_Name__c = 'MName';
            name.Preferred_First_Name__c = 'PFName';
            name.Prefix__c = 'P';
            name.Suffix__c = 'S';

            Test.startTest();

            //WHEN - name record is updated with a PFN
            insert name;
            Test.getEventBus().deliver(); // do rollup
            Test.stopTest();

            // THEN Staff user should also update to reflect the correct FirstName (PFN)
            user = [SELECT FirstName FROM User WHERE FederationIdentifier = 'abc123'];
            Assert.areEqual(name.Preferred_First_Name__c, user.FirstName);
        }
    }

    /**
     * Scenario:
     * GIVEN A User login to UniCRM
     * AND search for a contact record
     * AND contact record is not student
     * WHEN new phone record inserted manually as primary
     * THEN it will roll up in corresponding Phone field
     */
    @isTest
    static void phoneRecordTest1() {
        setupContactManually();
        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today();
        phone.Is_Primary__c = true;
        phone.Is_Active__c = true;
        phone.Classification__c = 'Private';
        phone.Name = '+61390008005';
        phone.Source__c = 'Undefined';
        phone.Type__c = 'Mobile';
        Test.startTest();
        insert phone;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Phone,MobilePhone,HomePhone,OtherPhone,Fax FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('+61390008005', con.Phone, 'Expected Phone value should be +61390008005');
        Assert.areEqual('+61390008005', con.MobilePhone, 'Expected MobilePhone value should be +61390008005');
        Assert.areEqual('+61390008001', con.HomePhone, 'Expected HomePhone value should be +61390008001');
        Assert.areEqual('+61390008002', con.OtherPhone, 'Expected OtherPhone value should be +61390008002');
        Assert.areEqual('+61390008999', con.Fax, 'Expected Fax value should be +61390008999');
    }

    /**
     * Scenario:
     * GIVEN A new phone created by Automated Process
     * WHEN new phone record inserted manually as primary
     * THEN it will not roll up in corresponding phone fields
     * when there is already existing primary set by user
     */
    @isTest
    static void phoneRecordTest2() {
        setupContactManually();
        Test.getEventBus().deliver();
        TriggerCommon.enableTrigger('Contact');

        Phone__c phone = new Phone__c();
        phone.Contact__c = contactRecord.Id;
        phone.Start_Date__c = Date.today();
        phone.Is_Primary__c = true;
        phone.Is_Active__c = true;
        phone.Classification__c = 'Private';
        phone.Name = '+61390008005';
        phone.Source__c = 'Undefined';
        phone.Type__c = 'Mobile';
        insert phone;

        TriggerCommon.enableTrigger('Contact');
        Test.startTest();
        List<Channel__c> chanlst = new List<Channel__c>();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Phone__c = '+61390008006'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Phone,MobilePhone,HomePhone,OtherPhone,Fax FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('+61390008005', con.Phone, 'Expected Phone value should be +61390008005');
        Assert.areEqual('+61390008005', con.MobilePhone, 'Expected MobilePhone value should be +61390008005');
        Assert.areEqual('+61390008006', con.HomePhone, 'Expected HomePhone value should be +61390008006');
        Assert.areEqual('+61390008002', con.OtherPhone, 'Expected OtherPhone value should be +61390008002');
        Assert.areEqual('+61390008999', con.Fax, 'Expected Fax value should be +61390008999');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new phone record inserted manually as primary
     * AND no callista record exists
     * THEN roll up the latest greatest
     */
    @isTest
    static void phoneRecordTest3() {
        setupContactManually();
        contactRecord.Is_Student__c = true;
        update contactRecord;
        Test.startTest();
        List<Channel__c> chanlst = new List<Channel__c>();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Phone__c = '+61390008006',
                Mobile_Phone__c = '0407111227'
                
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Phone,MobilePhone,HomePhone,OtherPhone,Fax FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('+61 407111227', con.Phone, 'Expected Phone value should be +61 407111227');
        Assert.areEqual('+61 407111227', con.MobilePhone, 'Expected MobilePhone value should be +61 407111227');
        Assert.areEqual('+61390008006', con.HomePhone, 'Expected HomePhone value should be +61390008006');
        Assert.areEqual('+61390008002', con.OtherPhone, 'Expected OtherPhone value should be +61390008002');
        Assert.areEqual('+61390008999', con.Fax, 'Expected Fax value should be +61390008999');
    }

    /**
     * Scenario:
     * GIVEN Contact is a student
     * WHEN new email record inserted manually as primary
     * AND there is callista record exists
     * THEN roll up the latest greatest
     */
    @isTest
    static void phoneRecordTest4() {
        setupContactManually();
        contactRecord.Is_Student__c = true;
        update contactRecord;
        List<Channel__c> chanlst = new List<Channel__c>();
        Test.startTest();
        chanlst.add(
            new Channel__c(
                type__c = 'POSTAL',
                Contact__c = contactRecord.id,
                Mobile_Phone__c = '+61390008006',
                Source_System__c = 'Callista'
            )
        ); 
        insert chanlst;
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [SELECT Id,Phone,MobilePhone,HomePhone,OtherPhone,Fax FROM Contact WHERE Id=:contactRecord.Id LIMIT 1];
        Assert.areEqual('+61390008006', con.Phone, 'Expected Phone value should be +61390008006');
        Assert.areEqual('+61390008006', con.MobilePhone, 'Expected MobilePhone value should be +61390008006');
        Assert.areEqual('+61390008001', con.HomePhone, 'Expected HomePhone value should be +61390008001');
        Assert.areEqual('+61390008002', con.OtherPhone, 'Expected OtherPhone value should be +61390008002');
        Assert.areEqual('+61390008999', con.Fax, 'Expected Fax value should be +61390008999');
    }

    @isTest
    static void testPEForAllCP() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;

        Contact contactRecord = createContact();
        contactRecord.Is_Student__c = true;
        insert contactRecord;
        Test.getEventBus().deliver();
        TriggerCommon.enableTrigger('Contact');

        Test.startTest();
        //String payloadKey = new Person360RollUpServices.PerformRollUp().payloadKey;
        List<Contact_Point_Event__e> eventList = new List<Contact_Point_Event__e>();
        // Async Process 1
        Person360RollUpServices.Person360RollUpServicesPayload prusPayloadVal1 = new Person360RollUpServices.Person360RollUpServicesPayload();
        prusPayloadVal1.contactId = contactRecord.Id;
        prusPayloadVal1.retryCount = 0;
        prusPayloadVal1.listOftargetObjectsToRollUp = new List<String>{'Address__c','Email__c'};
        AsyncProcessPayload payload1 = new AsyncProcessPayload();
        payload1.put(new Person360RollUpServices.PerformRollUp().payloadKey, prusPayloadVal1);
        Contact_Point_Event__e contactPointEvent1 = new Contact_Point_Event__e(
            Process_Name__c = 'Person360RollUpServices.PerformRollUp',
            Parameter__c = payload1.serialize()
        );
        eventList.add(contactPointEvent1);
        // Async Process 2
        Person360RollUpServices.Person360RollUpServicesPayload prusPayloadVal2 = new Person360RollUpServices.Person360RollUpServicesPayload();
        prusPayloadVal2.contactId = contactRecord.Id;
        prusPayloadVal2.retryCount = 0;
        prusPayloadVal2.listOftargetObjectsToRollUp = new List<String>{'Name__c','Phone__c'};
        AsyncProcessPayload payload2 = new AsyncProcessPayload();
        payload2.put(new Person360RollUpServices.PerformRollUp().payloadKey, prusPayloadVal2);
        Contact_Point_Event__e contactPointEvent2 = new Contact_Point_Event__e(
            Process_Name__c = 'Person360RollUpServices.PerformRollUp',
            Parameter__c = payload2.serialize()
        );
        eventList.add(contactPointEvent2);
        Eventbus.publish(eventList);
        Test.getEventBus().deliver();
        Test.stopTest();
        Contact con = [ SELECT Id,MailingStreet,OtherStreet,
                        Personal_Email__c,Email,Monash_Email_Address__c,Business_Email_Address__c,
                        FirstName,LastName,
                        Phone,MobilePhone,HomePhone,OtherPhone,Fax
                        FROM Contact WHERE Id=:contactRecord.Id LIMIT 1 ];
        Assert.areEqual('test@monash.edu', con.Email, 'Expected Email value shoudld be test@monash.edu.');
        Assert.areEqual('test@personal1.com', con.Personal_Email__c, 'Expected Personal_Email__c value shoudld be test@personal1.com.');
        Assert.areEqual('test@monash.edu', con.Monash_Email_Address__c, 'Expected Monash_Email_Address__c value shoudld be test@monash.edu.');
        Assert.areEqual('test@business.com', con.Business_Email_Address__c, 'Expected Business_Email_Address__c value shoudld be test@business.com.');
        Assert.areEqual('testFirstName', con.FirstName, 'Expected FirstName value shoudld be testFirstName.');
        Assert.areEqual('testLastName', con.LastName, 'Expected LastName value should be testLastName.');
        Assert.areEqual('+61 400111222', con.Phone, 'Expected Phone value should be +61 400111222');
        Assert.areEqual('+61 400111222', con.MobilePhone, 'Expected MobilePhone value should be +61 400111222.');
        Assert.areEqual('+61390008001', con.HomePhone, 'Expected HomePhone value should be +61390008001.');
        Assert.areEqual('+61390008002', con.OtherPhone, 'Expected OtherPhone value should be +61390008002.');
        Assert.areEqual('+61390008999', con.Fax, 'Expected Fax value should be +61390008999.');
    }

    /**
     * Set up data manually
     */
    private static void setupContactManually() {
        contactRecord = createContact();
        insert contactRecord;
    }

    private static Contact createContact() {
        Contact cont = new Contact();
        cont.Person_ID_unique__c = '12345';
        cont.Birthdate = Date.today().addYears(- 20);
        cont.Citizenship__c = 'INTERNATIONAL';
        cont.Citizenship_Code__c = '4';
        cont.Residency_Status__c = 'Australian Permanent Resident';
        cont.Email = 'test@personal1.com';
        cont.Personal_Email__c = 'test@personal1.com';
        cont.Monash_Email_Address__c = 'test@monash.edu';
        cont.Business_Email_Address__c = 'test@business.com';
        cont.Title = 'OAM';
        cont.Salutation = 'Mr';
        cont.FirstName = 'testFirstName';
        cont.MiddleName = 'testMiddleName';
        cont.LastName = 'testLastName';
        cont.Suffix = 'testSuffix';
        cont.Gender__c = 'None';
        //cont.Phone = '+61390008000';
        cont.MobilePhone = '+61400111222'; // This will be reformatted to conform with standard mobile template
        cont.HomePhone = '+61390008001';
        cont.OtherPhone = '+61390008002';
        cont.AssistantPhone = '+61390008003';
        cont.Fax = '+61390008999';
        cont.MailingStreet = '100 Bourke Street';
        cont.MailingCity = 'Melbourne';
        cont.MailingState = 'Victoria';
        cont.MailingPostalCode = '3000';
        cont.MailingCountry = 'Australia';
        cont.OtherStreet = '200 Exhibition Street';
        cont.OtherCity = 'Melbourne';
        cont.OtherState = 'Victoria';
        cont.OtherPostalCode = '3000';
        cont.OtherCountry = 'Australia';
        cont.Is_Student__c = false;
        return cont;
    }
    /**
     * Scenario:
     * GIVEN Contact has active contact points
     * WHEN any contact point is deactivated
     * AND there is NO other active contact point exists
     * THEN the roll must flush the contact points field in Contact object
     */
    @isTest
    static void flushingContactFields_WhenNoActiveRecords_OnRollUp() {
        // GIVEN a contact with active contact points
        setupContactManually();
        List<Contact> contactAndContactPoints = [SELECT Id, Email, Phone, MailingStreet, MailingCity, MailingPostalCode, MailingCountry, MailingState, OtherStreet, OtherCity, OtherPostalCode, OtherState, OtherCountry,
        (SELECT Id, Is_Active__c FROM Phones__r),
        (SELECT Id, Is_Active__c FROM Emails__r),
        (SELECT Id, Is_Active__c FROM Addresses__r) FROM Contact WHERE Person_ID_unique__c = '12345'];

        Assert.areEqual(contactAndContactPoints.size(), 1); // A contact exists

        Contact testContact = contactAndContactPoints[0];
        Assert.areEqual(5, testContact.Phones__r.size()); // 6 phone contact points exist
        Assert.areEqual(3, testContact.Emails__r.size()); // 4 email contact points exist
        Assert.areEqual(2, testContact.Addresses__r.size()); // 2 address contact points exist

        // WHEN any contact point is deactivated AND no other active contact point is found
        Test.startTest();
        for(Address__c address: testContact.Addresses__r){
            address.Is_Active__c = false;
        }

        for(Phone__c phone: testContact.Phones__r){
            phone.Is_Active__c = false;
        }

        for(Email__c email: testContact.Emails__r){
            email.Is_Active__c = false;
        }

        update testContact.Phones__r;
        update testContact.Emails__r;
		// Publishing the events before we update Address
		// This needs to be looked at
        update testContact.Addresses__r;
        Test.getEventBus().deliver();   

        Test.stopTest();

        // THEN the system should flush the contact point field in the Contact record
        List<Contact> testContactsAfterUpdate = [SELECT Id, Email, Phone, MailingStreet, MailingCity, MailingPostalCode, MailingCountry, MailingState, OtherStreet, OtherCity, OtherPostalCode, OtherState, OtherCountry,
                                                 (SELECT Id, Is_Active__c, end_date__c FROM Phones__r),
                                                 (SELECT Id, Is_Active__c, end_date__c FROM Emails__r),
                                                 (SELECT Id, Is_Active__c, end_date__c FROM Addresses__r)
                                                 FROM Contact WHERE Person_ID_unique__c = '12345'];

        Assert.areEqual(testContactsAfterUpdate.size(), 1); // A contact exists
        Contact testContactAfterUpdate = testContactsAfterUpdate[0];

        // assertion that the contact points field on the Contact are flushed
        Assert.areEqual(null, testContactAfterUpdate.Email);
        Assert.areEqual(null, testContactAfterUpdate.Phone);
        Assert.areEqual(null, testContactAfterUpdate.MailingStreet);
        Assert.areEqual(null, testContactAfterUpdate.MailingCity);
        Assert.areEqual(null, testContactAfterUpdate.MailingPostalCode);
        Assert.areEqual(null, testContactAfterUpdate.MailingCountry);
        Assert.areEqual(null, testContactAfterUpdate.MailingState);
        Assert.areEqual(null, testContactAfterUpdate.OtherStreet);
        Assert.areEqual(null, testContactAfterUpdate.OtherCity);
        Assert.areEqual(null, testContactAfterUpdate.OtherPostalCode);
        Assert.areEqual(null, testContactAfterUpdate.OtherState);
        Assert.areEqual(null, testContactAfterUpdate.OtherCountry);

    }
}