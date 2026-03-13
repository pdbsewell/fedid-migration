/**
 * @author          PwC
 * @description     This class contains unit tests for validating the behavior of ContactServices methods. These methods are part of the testing 
 *                  framework implemented throughout UniCRM and will be part of future code optimization.
 * @revision        07/07/2020 - KL - Removing parallel test execution as it disrupts merge null v.s. non-null comparison
 *                               feature due to known behaviour, see https://trailblazer.salesforce.com/ideaView?id=0873A000000lGvtQAE
 *                  10/10/2019 - Update test testUpdateFieldsBirthdate for new formatting of Birthdate_Dup__c field      
 *                  16/04/2019 - K Liew - Added test for ContactServices.composeDecomposeBirthDeceasedDates
 *                  10/07/2018 - Kristian Vegerano - Test for IT account disabled logic added
 *                  13/03/2018 - Stefan Scheit - Added test for ContactServices.addContactAccounts
 *                  12/12/2020 - Martin Cadman - Updated class names for togggle is student logic
 *                  05/04/2021 - Vinothraja    - Added SyncPartnerUser Logic
 *                  01/04/2022 - Tom Gangemi   - Preferred First Name changes
 *                  18/11/2022 - Inderpal D    - Platform Event changes for PENGAGE-2573
 *                  22/07/2023 - Martin Cadman - Added muting rolldown option for RT
 *                  17/04/2024 - Martin Cadman - started move to the assert class
 *                  17/04/2024 - Martin Cadman - Added an SAP sourced contact test class
 * 
 */
@isTest(isParallel=false) // As per note in revisions.
private class ContactServices_Test{
    
    /**
     * Test method validating a Contact with an empty/null Account lookup creates a new Account of type Individual.
     * Additionally, the Account owner is set to the Contact owner id.
     */
    @isTest
    static void testAddContactAccounts() {
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(Firstname='FName', Lastname=testLastname);
        
        // run test
        Test.startTest();
        insert testContact;
        Test.stopTest();
        
        testContact = [SELECT id, OwnerId, AccountId, Account.OwnerId, first_name__c, Lastname, Last_name__c FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.isNotNull(testContact.id, 'Test contact has not been inserted successfully');
        Assert.areEqual(testLastname, testContact.lastname, 'Lastname was not inserted correctly');
        Assert.areEqual(testLastname, testContact.last_name__c, 'Legal last name was not defaulted  correctly');        
        Assert.areEqual ('FName', testContact.first_name__c, 'Legal first name was not defaulted correctly');
        
        // validate account owner is equal to contact owner
        Assert.areEqual(testContact.OwnerId, testContact.Account.OwnerId, 'Owner of contact and account is not the same');
        
        // validate account record type is of type individual
        Account testAccount = [SELECT id, RecordType.developerName FROM Account WHERE id = :testContact.AccountId];
        Assert.areEqual(AccountServices.ACCOUNT_INDIVIDUAL_TYPE, testAccount.RecordType.developerName, 'Account record type is not Individual');
    }

    /**
    * Test preferred name rolling down and back up when Contact is mononymous
    */
    @isTest
    static void setMonoPFNRollDownUp() {
        Contact con = new Contact(LastName='Karen Seva Nakuladeva', First_Name__c='', Preferred_Name__c = 'Karen');

        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        Test.startTest();
        insert con;
        Test.getEventBus().deliver();
        TriggerCommon.enableTrigger('Contact');


        Contact result = [
            SELECT FirstName, First_Name__c, Preferred_Name__c, LastName FROM Contact WHERE Id = :con.Id
        ];

        Assert.isNull(result.First_Name__c);
        Assert.areEqual('Karen', result.Preferred_Name__c);
        Assert.areEqual(con.LastName, result.LastName);
        Assert.areEqual(con.Preferred_Name__c, result.FirstName);

        con.Salutation = 'Ms'; // any update to fire the trigger
		update con;		
        
        Test.stopTest();

        Contact Updateresult = [
            SELECT FirstName, First_Name__c, Preferred_Name__c, LastName FROM Contact WHERE Id = :con.Id
        ];

        // The trigger should not have changed anything
        Assert.isNull(Updateresult.First_Name__c);
        Assert.areEqual('Karen', updateResult.Preferred_Name__c);
        Assert.areEqual(con.LastName, updateResult.LastName);
        Assert.areEqual(con.Preferred_Name__c, updateResult.FirstName);
        
    }

    
    /**
     * Test preferred name rolling down and back up
     */
    @isTest
    static void setPreferredNameRollDownUp() {
        Contact con = new Contact(LastName='Hyman', First_Name__c='Jeffrey');

        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        Test.startTest();
        insert con;
        Test.getEventBus().deliver();
        TriggerCommon.enableTrigger('Contact');

        Contact insertResult = [
            SELECT FirstName, First_Name__c, Preferred_Name__c, LastName FROM Contact WHERE Id = :con.Id
        ];

        con.Preferred_Name__c = 'JoeyPFN';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact updateResult = [
            SELECT FirstName, First_Name__c, Preferred_Name__c, LastName FROM Contact WHERE Id = :con.Id
        ];

        Assert.areEqual(con.First_Name__c, insertResult.First_Name__c);
        Assert.areEqual(con.First_Name__c, insertResult.FirstName);
        Assert.isNull(insertResult.Preferred_Name__c);

        Assert.areEqual(con.First_Name__c, updateResult.First_Name__c);
        Assert.areEqual('JoeyPFN', updateResult.Preferred_Name__c);
        Assert.areEqual(con.LastName, updateResult.LastName);
        Assert.areEqual(updateResult.Preferred_Name__c, updateResult.FirstName);
    }

	@isTest
    /* Ensure that name changes to the standard name fields are honored for staff records even when the legal custom fields are used in roll down.
     * 
     *  GIVEN a SAP contact 
     *  WHEN an update to the lastname is made
     *  THEN the new lastname should replace the legal lastname and rolldown/rollup
     * 
     */ 
    static void SAPRollDownUp() {
        TriggerCommon.enableTrigger('Contact');        
        
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        upsert cs;
        
        //Create the contact with initial values
        Contact con = new Contact(LastName='Jones', Firstname='Helen Sally', salutation='MS', Preferred_Name__c = 'Sally', source__c='SAP');
        
        Test.startTest();
        insert con;
        
        // Emulate a change in lastname from SAP, re-asserting the firstname
        con.LastName = 'Davidson';
        con.FirstName = 'Helen Sally';
        update con; 
        
        Test.stopTest();
        
        Contact insertResult = [SELECT FirstName, First_Name__c, Preferred_Name__c, LastName, last_name__c, salutation, Salutation_ERDA__c FROM Contact WHERE Id = :con.Id];
        
        Assert.areEqual(con.LastName.toLowerCase(), insertResult.Last_Name__c.toLowerCase(), 'Lastname & legal last name and should be the same'); // contactServices updateFields
        Assert.areEqual(con.salutation.toLowerCase(), insertResult.Salutation_ERDA__c.toLowerCase(), 'Title and prefix should be the same'); // contactServices updateFields
        Assert.areEqual(con.Preferred_Name__c.toLowerCase(), insertResult.firstname.toLowerCase(),'Preferred first name has not rolled up'); 
    }
    
    /**
     * Test clearing preferred name rolls down and back up correctly
     */
    @isTest
    static void clearPreferredNameRollDownUp() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        final String pfn = 'Jeff';
        Contact con = new Contact(
            LastName='Hyman', First_Name__c='Jeffrey', Preferred_Name__c=pfn
        );

        Test.startTest();
        insert con;
        Test.getEventBus().deliver();
        TriggerCommon.enableTrigger('Contact'); // re-enable trigger that is disabled in PerformRollUp.run()

        Contact insertResult = [
            SELECT FirstName, First_Name__c, Preferred_Name__c, LastName FROM Contact WHERE Id = :con.Id
        ];

        con.Preferred_Name__c = null;
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact updateResult = [
            SELECT FirstName, First_Name__c, Preferred_Name__c, LastName FROM Contact WHERE Id = :con.Id
        ];
        Name__c nameResult = [SELECT Preferred_First_Name__c FROM Name__c WHERE Contact__c = :con.Id];

        Assert.areEqual(con.First_Name__c, insertResult.First_Name__c);
        Assert.areEqual(pfn, insertResult.FirstName);
        Assert.areEqual(pfn, insertResult.Preferred_Name__c, 'PFN should have persisted on Contact');

        Assert.isNull(nameResult.Preferred_First_Name__c, 'PFN should be cleared on Name__c');
        Assert.areEqual(con.First_Name__c, updateResult.First_Name__c);
        Assert.isNull(updateResult.Preferred_Name__c, 'PFN should remain cleared on Contact');
        Assert.areEqual(con.LastName, updateResult.LastName);
        Assert.areEqual(updateResult.First_Name__c, updateResult.FirstName);
    }

    @IsTest
    static void rollDownUserMuting() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = true;
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        Contact con1 = new Contact(
            LastName='Bardeen', First_Name__c='John'
        );
        Contact con2 = new Contact(
            LastName='Brattain', First_Name__c='Walter', MiddleName='Houser'
        );

        Test.startTest();
        insert con1;
        TriggerCommon.enableTrigger('Contact');

        Name__c result1 = [
            SELECT First_Name__c, Last_Name__c FROM Name__c WHERE Contact__c = :con1.Id
        ];
        Assert.areEqual(con1.First_Name__c, result1.First_Name__c);

        cs.Name_Roll_Down_Bypass__c = UserInfo.getUserName();
        upsert cs;

        // With muting, contact should not create a rolldown
        insert con2;
        Name__c[] result2 = [
            SELECT Id FROM Name__c WHERE Contact__c = :con2.Id
        ];
        Assert.areEqual(0, result2.size());
    }

    
    /*
     * It is possible to disable rolldown for record types.
     * 
     * The test confirms that no Name__c record is created for a non_student record typ when that is specified in the ctmd.
     */
    @IsTest
    static void rollDownUserMuting2() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
		cs.Record_Type_Roll_Down_Bypass__c = 'Non_Student';
        cs.Run_Roll_Up_Asynchronously__c = true;
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        Contact con1 = new Contact (
            LastName='Patekh', First_Name__c='Stephen'
        );

        Test.startTest();
        insert con1;
        TriggerCommon.enableTrigger('Contact');

        list<Name__c> result1 = [SELECT First_Name__c, Last_Name__c, contact__r.Record_Type_Developer_Name__c FROM Name__c WHERE Contact__c = :con1.Id];
        Assert.areEqual(0, result1.size());
    }
    
    /**
    * confirm that on new contact insertion, if no account provided a new Individual Account is established
    * test bulk insert including duplicate contact names
    * test deletion performs cleanup
    */
    @isTest
    static void basicIndividualInsertionAndDeletion() {
        list<Contact> testContacts = TestHelper.createOrphanContactRecords(10);
        
        Test.startTest();
        insert testContacts;
        Assert.areEqual(testContacts.size(),
                            [select COUNT() from Account where RecordTypeId =:CommonServices.RecordTypeId('Account', AccountServices.ACCOUNT_INDIVIDUAL_TYPE)],
                            'incorrect number of accounts with record type individual created');
        /*delete TestContacts;
        Assert.areEqual(0,
                            [select COUNT() from Account where RecordTypeId =:CommonServices.RecordTypeId('Account',AccountServices.ACCOUNT_INDIVIDUAL_TYPE)],
                            'incorrect number of accounts with rtype individual remain after deletion');*/
        Test.stopTest();
    } 
    
    /**
    * confirm that on new contact insertion, if error during insertion error handled correctly.
    * test bulk insert including duplicate contact names
    * test deletion handles error correctly
    */
    @isTest
    static  void basicIndividualInsertionAndDeletionErrorHandling() {
        list<Contact> testContacts = TestHelper.createOrphanContactRecords(10);
        LogUtilityException.setupError('accountInsert'); // induces a one off error condition within the logic being tested, this is controlled from ContactServices.addContactAccounts() method
        
        Test.startTest();
        Database.SaveResult[] saveResults = Database.insert(TestContacts, false); // provide for partial inserts in bulk
        Assert.areEqual(testContacts.size()-1,
                            [select COUNT() from Contact],
                            'incorrect number of contacts inserted');
        Assert.areEqual(testContacts.size() - 1,
                            [select COUNT() from Account where RecordTypeId =:CommonServices.RecordTypeId('Account',AccountServices.ACCOUNT_INDIVIDUAL_TYPE)],
                            'incorrect number of accounts with rtype individual created');
        
        LogUtilityException.setupError('accountDelete'); // induces a one off error condition within the logic being tested
        Assert.areEqual(true,LogUtilityException.throwError('accountDelete'));
        Assert.areEqual(false,LogUtilityException.throwError('accountDelete'));
        LogUtilityException.setupError('accountDelete');
        
        List<Contact> contactsToDelete = new List<Contact>([select id from Contact]); // refresh list for next test
        delete contactsToDelete;
        Test.stopTest();
    }
    
    @isTest
    static void verifyMultipleEmailAddressBehaviour(){
        
        list<Contact> testContacts = TestHelper.createOrphanContactRecords(1);
        
        // prep for test use cases
        for(Contact testRecord : testContacts){
            testRecord.Applicant_Email_Address__c = '';
            testRecord.Monash_Email_Address__c = '';
        }
        insert testContacts;
        
        Test.startTest();
                            
        testContacts = TestHelper.retrieveContactRecords(); // pull in the updated records for further testing
        for(integer recCount = 0; recCount < testContacts.size(); recCount++) 
            testContacts[recCount].Email = String.valueOf(recCount) + 'nonmonash@somedomain.com.au';
        update testContacts;
        
        for(contact c : [select id,Email_Addresses__c from Contact]) {
            Assert.isNotNull(c.Email_Addresses__c,'Expected all contact records to have email address history field set');
        } 
        /*
        // test deletion of contacts - should also have accounts removed
        Set<id> accountIds = new Set<Id>();
        for(contact c : testContacts) {
            accountIds.add(c.accountId);
        }
        delete testContacts;
        */
        Test.stopTest();
        /*Assert.areEqual(0, [select count() from Account where id in:accountIds], 'should not be any accounts left');*/        
    }

     /*
     * @author      Stefan Scheit
     * @description Validate logic of setting birthdate text field to the correct value
     * @revision    16/10/2018 - Stefan Scheit - Initial version
     */
    @isTest
    static void testUpdateFields() {
        // Given
        list<Contact> testContacts  =  TestHelper.createOrphanContactRecords(2);
        Contact con1 = testContacts[0];
        Contact con2 = testContacts[1];
        // When birthdate is set
        con1.Birthdate = Datetime.newInstance(2019,07,10).date();
        con1.mobilePhone = '+61 (40) 1717-956';
        con2.Birthdate = null;
        con2.ucinn_ascendv2__Lifetime_Fundraising__c = 10;
        con2.contact_profile__c='Alumni;Future Student (Dom) [FSD]';
        con2.Other_Given_Name__c = 'John';
        Test.startTest();
        upsert new List<Contact>{con1, con2};
        con1 = [select id, MobilePhone, MobilePhone_Dup__c, Birthdate_Dup__c, Other_Given_Name__c, MiddleName from Contact where id=:con1.Id LIMIT 1];
        con2 = [select id,contact_profile__c, Birthdate_Dup__c, Other_Given_Name__c,MiddleName from Contact where id=:con2.Id LIMIT 1];
        Test.stopTest();
        // Then birthdate_dup__c field is populated correctly and null value is handled
        Assert.isNotNull(con1.Birthdate_Dup__c);
        Assert.areEqual('20190710', con1.Birthdate_Dup__c, 'Date transformation for field [Birthdate_Dup__c] is incorrect.');
        Assert.isNull(con2.Birthdate_Dup__c, 'The value of the field [Birthdate_Dup__c] is not null as expected.');
        Assert.areEqual(True, con2.contact_profile__c.split(';').contains('Donor'), 'ContactProfile updated with value donor');
        Assert.areEqual(con2.MiddleName, 'John','Keep other given name in sync with middle name');
        Assert.areEqual(con1.mobilephone.replaceAll('[^0-9]',''), con1.mobilephone_dup__c, 'Date transformation for field [MobilePhone_Dup__c] is incorrect.');
     }

     /*
     * @author      Shalini Mendu
     * @description Validate populating Previous_Monash_ID__c when Person_ID_unique__c is populated
     * @revision    28/04/2022
     */
     @isTest
    static void testUpdatePreviousMonashId() {
        // Create contact
        list<Contact> testContacts  =  TestHelper.createOrphanContactRecords(1);
        Contact con = testContacts[0];
        Test.startTest();
        insert con;
         // Update Person_ID_unique__c
        con.Person_ID_unique__c = '32821948';
        update con;
        con = [select id, Previous_Monash_ID__c, Previously_Studied_at_Monash__c from Contact where id=:con.Id LIMIT 1];
        Test.stopTest();
        Assert.areEqual(con.Previous_Monash_ID__c, '32821948','Previous Monash Id should have been assigned');
        Assert.areEqual(con.Previously_Studied_at_Monash__c, true,'Previous Studies at Monash should be true');
     }
    /*
     * Test method to capture whether email opt out from case transfers to Contact
     * @revision    13/03/2018 - Stefan Scheit - Added asserts for Contact result and Test.startTest() and Test.stopTest()
     */
    @isTest
    static void checkFieldMappingLogic(){
        // test contact records
        list<Contact> testContacts = TestHelper.createOrphanContactRecords(1);
        testContacts[0].HasOptedOutOfEmail = false;
        testContacts[0].Country_of_Residence__c = 'AU';
        insert testContacts;
        Assert.isNotNull(testContacts[0].id,'Contacts did not insert as expected');
        
        // now create a case with mappings to pass to contact
        Test.startTest();
        case c = new case(contactId = testContacts[0].id,
                          supplied_Email_Opt_out__c = true,
                          Supplied_Country_of_Residence__c = 'NZ');
        ContactServices.copyMappedFieldsToCaseContacts(new list<case>{ c });
        Test.stopTest();
        contact contactResult = [select id,HasOptedOutOfEmail,Country_of_Residence__c from contact where id =:testContacts[0].id limit 1];
        Assert.areEqual(contactResult.HasOptedOutOfEmail, c.supplied_Email_Opt_out__c, 'Case.supplied_Email_Opt_out__c is not transferred to Contact.HasOptedOutOfEmail');
    }    
    
    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         10/07/2018
    * @description  tests the automated deactivation of users
    * @revision     
    *******************************************************************************/
    @isTest
    static void testITAccountDisabled(){
        Environment_Settings__c envSettings = new Environment_Settings__c();
        envSettings.Deactivate_User_Delay_Days__c = 14;
        insert envSettings;
        
        List<Contact> contactList = TestHelper.createOrphanContactRecords(1);
        
        //Retrieve FederationIdentifier of the logged in user
        User loggedinUser = [SELECT Id, FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId()];
        
        for(Contact contactRec : contactList){
            contactRec.Authcate__c = loggedinUser.FederationIdentifier;
            contactRec.IT_account_disabled__c = false;
        }
        insert contactList;
        
        Test.startTest();
            //Deactivate contact
            for(Contact contactRec : contactList){
                contactRec.IT_account_disabled__c = true;
            }
            update contactList;
        Test.stopTest();
    }
    
    /*******************************************************************************
    * @author       Stefan Scheit
    * @date         29/01/2019
    * @description  Tests the mapping of a changed Contact.Authcate__c attribute value to User.federationIdentifier attribute.
                    This only applies to community users as their User is linked to Contact via User.ContactId.
    * @revision     
    *******************************************************************************/
    @isTest
    public static void testMapMonashIdToUser() {
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        //Create community user's account owner
        UserRole internalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User accountOwner = new User(
            UserRoleId = internalRole.Id,
            ProfileId = internalProfile.Id,
            Username = random + 'testing@monash.edu',
            Alias = 'test_ao',
            Email='test_ao@monash.edu',
            EmailEncodingKey='UTF-8',
            Firstname='Firstname' + random,
            Lastname='Lastname' + random,
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='Australia/Sydney'
        );
        System.runAs(thisUser) {
            Database.insert(accountOwner);
        }
        
        // Create account record
        Account act = new Account(
            Name='TestAccount' + random,
            OwnerId = accountOwner.id
        );
        Database.insert(act);
        
        // Create contact
        Contact communityContact = new Contact(
            FirstName = 'Firstname' + random,
            Lastname = 'Lastname' + random,
            AccountId = act.Id,
            Email = 'test_cc@monash.edu'
        );
        Database.insert(communityContact);
        
        //Create Community User
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON LIMIT 1];
        User communityUser = new User(
            UserName = random + communityContact.Email,
            FirstName = communityContact.FirstName,
            LastName = communityContact.LastName,
            Alias = 'test_cu',
            CommunityNickname = 'test_cu' + random,
            email = communityContact.Email,
            ContactId = communityContact.Id,
            ProfileId = communityProfile.Id,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );
        System.runAs(thisUser) {
            Database.insert(communityUser);
        }

        // update user record
        Test.startTest();
        communityContact.Authcate__c = 'aaaa0001';
        communityContact.FirstName = 'FName';
        communityContact.LastName = 'LName';
        Database.update(communityContact);
		Test.getEventBus().deliver();
        Test.stopTest(); // executes queueable
        User result = [SELECT FirstName, LastName, FederationIdentifier FROM User WHERE Id = :communityUser.Id LIMIT 1];
        Assert.areEqual(communityContact.Authcate__c, result.FederationIdentifier, 'Change of Contact.Authcate__c was not applied to User.FederationIdentifier');
        Assert.areEqual(communityContact.FirstName, result.FirstName);
        Assert.areEqual(communityContact.LastName, result.LastName);
    }

    /*******************************************************************************
    * @author       K Liew
    * @date         16/04/2019
    * @description  test the decomposing and composing of birth date deceased date fields
    *               into individual date component fields (day / month / year)
    * @revision     
    *******************************************************************************/
    @isTest
    static void testComposeDecomposeBirthAndDeceasedDates() {
        // create contact record with birthdate, check that it's decomposed into consituent / component fields
        Contact testCon = new Contact(
                                    FirstName = 'Sco', 
                                    LastName = 'Mo',
                                    Birthdate = date.newInstance(1999, 09, 09),
                                    Deceased_Date__c = date.newInstance(2009, 09, 09),
                                    Deceased_Source__c = 'Other');
        insert testCon;

        Contact resultCon = [SELECT Birthdate, Birth_Day__c, Birth_Month__c, Birth_Year__c, Deceased__c, Deceased_Date_Day__c, Deceased_Date_Month__c, Deceased_Date_Year__c, Deceased_Date__c FROM Contact WHERE Id=:testCon.Id];
        Assert.areEqual('09', resultCon.Birth_Day__c);
        Assert.areEqual('09', resultCon.Birth_Month__c);
        Assert.areEqual('1999', resultCon.Birth_Year__c);
        Assert.areEqual('09', resultCon.Deceased_Date_Day__c);
        Assert.areEqual('09', resultCon.Deceased_Date_Month__c);
        Assert.areEqual('2009', resultCon.Deceased_Date_Year__c);
        Assert.areEqual(true, resultCon.Deceased__c);

        testCon.Birth_Day__c = null;
        testCon.Deceased_Date_Day__c = null;
        update testCon;

        resultCon = [SELECT Birthdate, Birth_Day__c, Birth_Month__c, Birth_Year__c, Deceased__c, Deceased_Date_Day__c, Deceased_Date_Month__c, Deceased_Date_Year__c, Deceased_Date__c FROM Contact WHERE Id=:testCon.Id];
        Assert.isNull(resultCon.Birthdate);

        Contact testCon2 = new Contact(
                                    FirstName = 'Tony', 
                                    LastName = 'Sepository',
                                    Birth_Day__c = '01',
                                    Birth_Month__c = '01',
                                    Birth_Year__c = '2000',
                                    Deceased_Date_Day__c = '12',
                                    Deceased_Date_Month__c = '12',
                                    Deceased_Date_Year__c = '2099',
                                    Deceased_Source__c='Email'
                                    );
        insert testCon2;

        Contact resultCon2 = [SELECT Birthdate, Birth_Day__c, Birth_Month__c, Birth_Year__c, Deceased__c, Deceased_Date_Day__c, Deceased_Date_Month__c, Deceased_Date_Year__c, Deceased_Date__c FROM Contact WHERE Id=:testCon2.Id];
        Assert.areEqual(date.newInstance(2000, 1, 1), resultCon2.Birthdate);
        Assert.areEqual(date.newInstance(2099, 12, 12), resultCon2.Deceased_Date__c);

        testCon2.Birthdate = date.newInstance(2000, 12, 12);
        testCon2.Deceased_Date__c = date.newInstance(2099, 8, 8);
        update testCon2;

        resultCon2 = [SELECT Birthdate, Birth_Day__c, Birth_Month__c, Birth_Year__c, Deceased__c, Deceased_Date_Day__c, Deceased_Date_Month__c, Deceased_Date_Year__c, Deceased_Date__c FROM Contact WHERE Id=:testCon2.Id];
        Assert.areEqual('2000', resultCon2.Birth_Year__c);
        Assert.areEqual('12', resultCon2.Birth_Month__c);
        Assert.areEqual('12', resultCon2.Birth_Day__c);
        Assert.areEqual('2099', resultCon2.Deceased_Date_Year__c);
        Assert.areEqual('08', resultCon2.Deceased_Date_Month__c);
        Assert.areEqual('08', resultCon2.Deceased_Date_Day__c);

        testCon2.Birthdate = null;
        testCon2.Deceased_Date__c = null;
        update testCon2;

        resultCon2 = [SELECT Birthdate, Birth_Day__c, Birth_Month__c, Birth_Year__c, Deceased__c, Deceased_Date_Day__c, Deceased_Date_Month__c, Deceased_Date_Year__c, Deceased_Date__c FROM Contact WHERE Id=:testCon2.Id];
        Assert.isNull(resultCon2.Birth_Year__c);
        Assert.isNull(resultCon2.Birth_Month__c);
        Assert.isNull(resultCon2.Birth_Day__c);
        Assert.areEqual('2099', resultCon2.Deceased_Date_Year__c);
        Assert.areEqual('12', resultCon2.Deceased_Date_Month__c);
        Assert.areEqual('12', resultCon2.Deceased_Date_Day__c);

        testCon2.Birth_Day__c = '03';
        testCon2.Birth_Month__c = '03';
        testCon2.Birth_Year__c = '2008';
        testCon2.Deceased_Date_Year__c = '2088';
        testCon2.Deceased_Date_Month__c = '03';
        testCon2.Deceased_Date_Day__c = '03';
        testCon2.Deceased_Source__c = 'Other';
        update testCon2;

        resultCon2 = [SELECT Birthdate, Birth_Day__c, Birth_Month__c, Birth_Year__c, Deceased__c, Deceased_Date_Day__c, Deceased_Date_Month__c, Deceased_Date_Year__c, Deceased_Date__c FROM Contact WHERE Id=:testCon2.Id];
        Assert.areEqual(date.newInstance(2008, 3, 3), resultCon2.Birthdate);
        Assert.areEqual(date.newInstance(2088, 3, 3), resultCon2.Deceased_Date__c);
        Assert.areEqual(true, resultCon2.Deceased__c);

    }
    
    @isTest
    static void test_invokeReCalculateContactPrimaryContactPoints() {
        //Enable Roll up / down and break up
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        cs.Enable_Roll_Up__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        
        // Switch on id tracking
        Environment_Settings__c es = new Environment_Settings__c();
        es.Track_CRM_Ids__c = true;
        insert es;
        
        List<Contact> contactToInsertList = new List<Contact>();
        Contact contactSurviving = createContact();
        contactToInsertList.add(contactSurviving);
        
        Contact contactVictim1 = new Contact(
            Salutation = 'Dr',
            LastName = 'TestLastNameVictim1',
            FirstName = 'TestFirstNameVictim1',
            Birthdate = Date.today().addYears(- 22),
            Email = 'testEmailMonashVictim1@monash.edu',
            Personal_Email__c = 'testEmailPersonnalVictim1@gmail.com',
            Business_Email_Address__c = 'testEmailBusinessVictim1@gmail.com',
            Monash_Email_Address__c = 'testEmailMonashVictim1@monash.edu',
            Phone = '+61481699111',
            MobilePhone = '+61481699222',
            HomePhone = '+61481699333',
            OtherPhone = '+61481699444',
            AssistantPhone = '+61481699555',
            Fax = '+61481699666',
            MailingStreet = '400 Bourke Street',
            MailingCity = 'Melbourne',
            MailingState = 'Victoria',
            MailingPostalCode = '3000',
            MailingCountry = 'Australia',
            OtherStreet = '222 Bourke Street',
            OtherCity = 'Melbourne',
            OtherState = 'Victoria',
            OtherPostalCode = '3000',
            OtherCountry = 'Australia',
            previous_crm_ids__c = 'C-00000001' // this means the contact has been previously merged. Improves code coverage.
        );
        contactToInsertList.add(contactVictim1);

        // insert contact records
        insert contactToInsertList;

        Set<Id> contactIds = new Set<Id>();
        for (Contact con : contactToInsertList) {
            Assert.areNotEqual(null, con.Id, 'Contact Record Insert Failed');
            contactIds.add(con.Id);
        }
        List<Contact> queriedContacts = [SELECT Id FROM Contact WHERE Id IN: contactIds];

        TaskDupCheckHelper taskDupCheckHelperHandler = new TaskDupCheckHelper();
        taskDupCheckHelperHandler.init(contactToInsertList[0].Id, new Set<Id>{contactToInsertList[1].Id});

        queriedContacts = [SELECT Id FROM Contact WHERE Id IN: contactIds];
        Assert.areEqual(1, queriedContacts.size(), 'The expected number of contact, which is one (1), not met. Contact Merge was not successful.');
        
        Test.startTest();
        ContactServices.invokeReCalculateContactPrimaryContactPoints(new Set<Id>{queriedContacts[0].Id});
        Test.getEventBus().deliver();
        Test.stopTest();

        queriedContacts = [SELECT Id, crm_id__c, previous_crm_ids__c, lastmodifieddate_api__c, lastmodifiedby_api__c, first_name__c, last_name__c FROM Contact WHERE Id IN: contactIds];
        Assert.isNotNull(queriedContacts[0].previous_crm_ids__c, 'Previous CRM Id not retained.');
        
        List<Address__c> addresses = new List<Address__c>([SELECT Id FROM Address__c]);
        Assert.isNotNull(addresses, 'No address contact point.');

        List<Name__c> names = new List<Name__c>([SELECT Id FROM Name__c]);
        Assert.isNotNull(names, 'No names contact point.');
        
        List<Phone__c> phones = new List<Phone__c>([SELECT Id FROM Phone__c]);
        Assert.isNotNull(phones, 'No phone contact point.');

        List<Email__c> emails = new List<Email__c>([SELECT Id FROM Email__c]);
        Assert.isNotNull(emails, 'No email contact point.');
    }

    @isTest
    static void test_rePopulateHashFoAllContactPoints_withNoErrorReturn() {
        //Enable Roll up / down and break up
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        cs.Enable_Roll_Up__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;
        List<Contact> contactToInsertList = new List<Contact>();
        Contact contactSurviving = createContact();
        contactToInsertList.add(contactSurviving);
        
        Contact contactVictim1 = new Contact(
            Salutation_ERDA__c = 'Dr',
            LastName = 'TestLastNameVictim1',
            FirstName = 'TestFirstNameVictim1',
            Birthdate = Date.today().addYears(- 22),
            Email = 'testEmailMonashVictim1@monash.edu',
            Personal_Email__c = 'testEmailPersonnalVictim1@gmail.com',
            Business_Email_Address__c = 'testEmailBusinessVictim1@gmail.com',
            Monash_Email_Address__c = 'testEmailMonashVictim1@monash.edu',
            Phone = '+61481699111',
            MobilePhone = '+61481699222',
            HomePhone = '+61481699333',
            OtherPhone = '+61481699444',
            AssistantPhone = '+61481699555',
            Fax = '+61481699666',
            MailingStreet = '400 Bourke Street',
            MailingCity = 'Melbourne',
            MailingState = 'Victoria',
            MailingPostalCode = '3000',
            MailingCountry = 'Australia',
            OtherStreet = '222 Bourke Street',
            OtherCity = 'Melbourne',
            OtherState = 'Victoria',
            OtherPostalCode = '3000',
            OtherCountry = 'Australia'
        );
        contactToInsertList.add(contactVictim1);

        // insert contact records
        insert contactToInsertList;

        Set<Id> contactIds = new Set<Id>();
        for (Contact con : contactToInsertList) {
            Assert.isNotNull(con.Id, 'Contact Record Insert Failed');
            contactIds.add(con.Id);
        }
        
        // Initiate the Contact Merging
        TaskDupCheckHelper taskDupCheckHelperHandler = new TaskDupCheckHelper();
        taskDupCheckHelperHandler.init(contactToInsertList[0].Id, new Set<Id>{contactToInsertList[1].Id});
        
        ContactServices.RePopulateHashFoAllContactPointsWrapper result = new ContactServices.RePopulateHashFoAllContactPointsWrapper();

        Test.startTest();
        List<Contact> queriedContacts = new List<Contact>([SELECT Id FROM Contact WHERE Id IN: contactIds]);
        Assert.areEqual(1, queriedContacts.size(), 'Expected number of contact, which is one (1), not met. Contact Merge was not successful.');
        Test.getEventBus().deliver();
        result = ContactServices.rePopulateHashFoAllContactPoints(new Set<Id>{queriedContacts[0].Id});
        Test.stopTest();

        Integer counter = 0;
        if (result.vsrList != null && !result.vsrList.isEmpty()) {
            for (Database.SaveResult sr : result.vsrList) {
                if (!sr.isSuccess()) {
                    counter++;
                }
            }
        }
        Assert.areEqual(counter, 0, 'Expected return no duplicate error not met.');
    }
    
    @isTest
    static void test_rePopulateHashFoAllContactPoints_withErrorReturn() {
        //Enable Roll up / down and break up
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        cs.Enable_Roll_Up__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;

        List<Contact> contactToInsertList = new List<Contact>();
        Contact contactSurviving = createContact();
        contactToInsertList.add(contactSurviving);
        
        Contact contactVictim1 = new Contact(
            Salutation = 'Dr',
            LastName = 'TestLastNameVictim1',
            FirstName = 'TestFirstNameVictim1',
            Birthdate = Date.today().addYears(- 22),
            Email = 'testEmailMonashVictim1@monash.edu',
            Personal_Email__c = 'testEmailPersonnalVictim1@gmail.com',
            Business_Email_Address__c = 'testEmailBusinessVictim1@gmail.com',
            Monash_Email_Address__c = 'test@monash.edu',
            Phone = '+61481599111',
            MobilePhone = '+61481599222',
            HomePhone = '+61481699333',
            OtherPhone = '+61481699444',
            AssistantPhone = '+61481699555',
            Fax = '+61481699666',
            MailingStreet = '350 Bourke Street',
            MailingCity = 'Melbourne',
            MailingState = 'Victoria',
            MailingPostalCode = '3000',
            MailingCountry = 'Australia',
            OtherStreet = '222 Bourke Street',
            OtherCity = 'Melbourne',
            OtherState = 'Victoria',
            OtherPostalCode = '3000',
            OtherCountry = 'Australia'
        );
        contactToInsertList.add(contactVictim1);

        // insert contact records
        insert contactToInsertList;

        Set<Id> contactIds = new Set<Id>();
        for (Contact con : contactToInsertList) {
            Assert.isNotNull(con.Id, 'Contact Record Insert Failed');
            contactIds.add(con.Id);
        }

        // Initiate the Contact Merging
        TaskDupCheckHelper taskDupCheckHelperHandler = new TaskDupCheckHelper();
        taskDupCheckHelperHandler.init(contactToInsertList[0].Id, new Set<Id>{contactToInsertList[1].Id});
        
        ContactServices.RePopulateHashFoAllContactPointsWrapper result = new ContactServices.RePopulateHashFoAllContactPointsWrapper();

        Test.startTest();
        List<Contact> queriedContacts = new List<Contact>([SELECT Id FROM Contact WHERE Id IN: contactIds]);
        Assert.areEqual(1, queriedContacts.size(), 'Expected number of contact, which is one (1), not met. Contact Merge was not successful.');
        Test.getEventBus().deliver();
        result = ContactServices.rePopulateHashFoAllContactPoints(new Set<Id>{queriedContacts[0].Id});
        Test.stopTest();

        Integer counter = 0;
        if (result.vsrList != null && !result.vsrList.isEmpty()) {
            for (Database.SaveResult sr : result.vsrList) {
                if (!sr.isSuccess()) {
                    counter++;
                }
            }
        }
        Assert.isTrue(counter > 0, 'Expected return is duplicate record error not met.');
    }

    @isTest
    static void test_InvalidIdProvided() {
        //Enable Roll up / down and break up
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        cs.Enable_Roll_Up__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;

        List<Contact> contactToInsertList = new List<Contact>();
        Contact con = createContact();
        contactToInsertList.add(con);
        insert contactToInsertList;

        List<Account> accounts = new List<Account>([SELECT Id FROM Account]);
        Assert.areEqual(1, accounts.size(), 'Error: No Account created.');

        Test.startTest();
        Boolean hasError = false;
        try {
            ContactServices.invokeReCalculateContactPrimaryContactPoints(new Set<Id>{accounts[0].Id});
        } catch (Exception ex) {
            hasError = true;
        }
        Assert.isTrue(hasError, 'Expected with error not met.');
        Test.stopTest();
    }

  
    /*
     * Not explicitly testing the queueable class as it is design to execute post merge.
	 */
    @isTest
    static void basicmerge() {
        list<Contact> testContacts = TestHelper.createOrphanContactRecords(2);
        
        Test.startTest();
        insert testContacts;
        database.merge(testContacts[0],testContacts[1]);
        Test.stopTest();
        
        Contact c = [select id, lastmodifiedby_api__c from contact where id = :testContacts[0].id];
        Assert.areEqual('Merged at', c.lastmodifiedby_api__c.substring(0,9) ,'Merged contact not updated');
    } 

    
    /**
     * Set up data manually
     */
    private static Contact createContact() {
        Contact contactRecord = new Contact();
        contactRecord.Person_ID_unique__c = '12345';
        contactRecord.Birthdate = Date.today().addYears(- 20);
        contactRecord.Citizenship__c = 'INTERNATIONAL';
        contactRecord.Citizenship_Code__c = '4';
        contactRecord.Residency_Status__c = 'Australian Permanent Resident';
        contactRecord.Email = 'test@test.com';
        contactRecord.Personal_Email__c = 'test@test.com';
        contactRecord.Monash_Email_Address__c = 'test@monash.edu';
        contactRecord.Business_Email_Address__c = 'test@test.com';
        contactRecord.Title = 'OAM';
        contactRecord.Salutation = 'Mr';
        contactRecord.FirstName = 'testFirstName';
        contactRecord.MiddleName = 'testMiddleName';
        contactRecord.LastName = 'testLastName';
        contactRecord.Suffix = 'testSuffix';
        contactRecord.Gender__c = 'None';
        contactRecord.Phone = '+61481599111';
        contactRecord.MobilePhone = '+61481599222';
        contactRecord.HomePhone = '+61481599333';
        contactRecord.OtherPhone = '+61481599444';
        contactRecord.AssistantPhone = '+61481599555';
        contactRecord.Fax = '+61481599666';
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

    /**
     * @author      Kristian Vegerano
     * @description Tests populating contact's Record_Type_Developer_Name__c field
     * @revision    03/02/2021 - Kristian Vegerano - Created
     */
    @isTest
    public static void testRecordTypeDeveloperNamePopulated() {
        //Start test
        Test.startTest();

        Contact testContact = new Contact(LastName = 'TestContact');
        insert testContact;

        Test.stopTest();

        Assert.isNotNull([SELECT Id, Record_Type_Developer_Name__c FROM Contact WHERE Id = :testContact.Id].Record_Type_Developer_Name__c);
    }
    /**
    * @author      Vinothraja
    * @description Tests SyncPartnerUser method
    *              Test updates Contact
    *              Validates that the Associated Partner Portal User automatically have its details updated
    * @revision    05/04/2021 - Vinothraja - Created
    */
    @isTest
    static void test_SyncPartnerUser() {
        User partnerUser = StudFirst_TestHelper.createContactAndPartnerPortalUser();
        Contact testContact = [SELECT id, LastName FROM Contact WHERE id =:partnerUser.contactId LIMIT 1];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runas(thisUser) {
            Test.startTest();
            testContact.LastName = 'TestLastComm';
            testContact.Citizenship_Code__c = '1';
            Database.update(testContact);
			Test.getEventBus().deliver();
            Test.stopTest();
        }
        //Start assertion - check that the partner portal user is updated
        Assert.areEqual('TestLastComm', [SELECT Id, LastName FROM User WHERE contactid =: testContact.Id LIMIT 1].LastName);
    }
    /**
    * @author      Russell Cadapan
    * @description Tests CheckAddressSource method
    *
    *              GIVEN a contact with MailingAddress/OtherAddress sourced from Experian
    *              WHEN inserted/updated in the system
    *              THEN the system should map the verification status correctly
    * @revision    05/04/2021 - Russell Cadapan - Created
    */
    @isTest
    static void CheckAddressSource_OnInsert_Test(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        // GIVEN: A contact is supplied Mailing Address
        Contact newContact = new Contact();
        newContact.FirstName = 'Zoe';
        newContact.LastName = 'Pearson';

        newContact.MailingStreet = '700 Blackburn Rd';
        newContact.MailingCity = 'Notting Hill';
        newContact.MailingState = 'VIC';
        newContact.MailingPostalCode = '3168';
        newContact.MailingCountry = 'Australia';

        // AND the Mailing Address is sourced from Experian
        newContact.Mailing_Address_DPID__c = '000001';
        newContact.Mailing_Address_Verification_Status__c = 'Verified match';
        newContact.Mailing_Address_Verification_Source__c = 'Experian';

        // AND the Other Address (For Business use) is supplied
        newContact.OtherStreet = '710 Blackburn Rd';
        newContact.OtherCity = 'Notting Hill';
        newContact.OtherState = 'VIC';
        newContact.OtherPostalCode = '3168';
        newContact.OtherCountry = 'Australia';

        // AND the Mailing Address is sourced from Experian
        newContact.Other_Address_DPID__c = '000001';
        newContact.Other_Address_Verification_Status__c = 'Verified match';
        newContact.Other_Address_Verification_Source__c = 'Experian';

        // WHEN the record is inserted into the system
        Test.startTest();
            insert newContact;
        Test.stopTest();

        // THEN both Mailing/Business address should be rolled down correspondingly with the verification fields
        List<Contact> insertedContact = [SELECT Id,
                                            Mailing_Address_Verification_Source__c,
                                            Other_Address_Verification_Source__c,
                                            Mailing_Address_DPID__c,
                                            Other_Address_DPID__c,
                                            Mailing_Address_Verification_Status__c,
                                            Other_Address_Verification_Status__c,
                                            (SELECT Id, Classification__c, Verification_Status__c, DPID__c, Source__c FROM Addresses__r)
                                        FROM Contact WHERE Id =: newContact.Id];

        // one contact created
        Assert.areEqual(1, insertedContact.size());

        // contact has two address records
        Assert.areEqual(2, insertedContact[0].Addresses__r.size());

        // for each address record
        for(Address__c address: insertedContact[0].Addresses__r){
            // for private address
            if(address.Classification__c == 'Private') {
                Assert.areEqual('Undefined', insertedContact[0].Mailing_Address_Verification_Source__c);
                Assert.areEqual(address.DPID__c, insertedContact[0].Mailing_Address_DPID__c);
                Assert.areEqual(address.Verification_Status__c, insertedContact[0].Mailing_Address_Verification_Status__c);
            }
            // for business address
            else if(address.Classification__c == 'Business'){
                Assert.areEqual('Undefined', insertedContact[0].Other_Address_Verification_Source__c);
                Assert.areEqual(address.DPID__c, insertedContact[0].Other_Address_DPID__c);
                Assert.areEqual(address.Verification_Status__c, insertedContact[0].Other_Address_Verification_Status__c);
            }
        }
    }
    /**
    * @author      Russell Cadapan
    * @description Tests CheckAddressSource method
    *
    *              GIVEN a contact with MailingAddress/OtherAddress sourced from Experian
    *              WHEN inserted/updated in the system
    *              THEN the system should map the verification status correctly
    * @revision    05/04/2021 - Russell Cadapan - Created
    */
    @isTest
    static void CheckAddressSource_OnUpdate_Test(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        cs.Enable_Roll_Up__c = true;
        upsert cs;

        // GIVEN: A contact is supplied Mailing Address
        Contact newContact = new Contact();
        newContact.FirstName = 'Zoe';
        newContact.LastName = 'Pearson';

        newContact.MailingStreet = '700 Blackburn Rd';
        newContact.MailingCity = 'Notting Hill';
        newContact.MailingState = 'VIC';
        newContact.MailingPostalCode = '3168';
        newContact.MailingCountry = 'Australia';

        // AND the Mailing Address is sourced from Experian
        newContact.Mailing_Address_DPID__c = '000001';
        newContact.Mailing_Address_Verification_Status__c = 'Verified match';
        newContact.Mailing_Address_Verification_Source__c = 'Experian';

        // AND the Other Address (For Business use) is supplied
        newContact.OtherStreet = '710 Blackburn Rd';
        newContact.OtherCity = 'Notting Hill';
        newContact.OtherState = 'VIC';
        newContact.OtherPostalCode = '3168';
        newContact.OtherCountry = 'Australia';

        // AND the Mailing Address is sourced from Experian
        newContact.Other_Address_DPID__c = '000001';
        newContact.Other_Address_Verification_Status__c = 'Verified match';
        newContact.Other_Address_Verification_Source__c = 'Experian';
        insert newContact;

        Test.startTest();
        // WHEN the mailing address and/or business address is updated
        newContact.MailingStreet = '701 Blackburn Rd';
        newContact.OtherStreet = '711 Blackburn Rd';
        newContact.Mailing_Address_Verification_Source__c = 'Undefined';
        newContact.Other_Address_Verification_Source__c = 'Undefined';
        update newContact;

        // AND update it back to an existing address
        newContact.MailingStreet = '700 Blackburn Rd';
        newContact.OtherStreet = '710 Blackburn Rd';
        newContact.Mailing_Address_Verification_Source__c = 'Undefined';
        newContact.Other_Address_Verification_Source__c = 'Undefined';
        update newContact;
        Test.stopTest();

        // THEN the system must be able to preserve the existing address's verification status even if the source of the address is Undefined.
        List<Contact> insertedContact = [SELECT Id,
                Mailing_Address_Verification_Source__c,
                Other_Address_Verification_Source__c,
                Mailing_Address_DPID__c,
                Other_Address_DPID__c,
                Mailing_Address_Verification_Status__c,
                Other_Address_Verification_Status__c,
        (SELECT Id, Classification__c, Verification_Status__c, DPID__c, Source__c, Is_Primary__c FROM Addresses__r)
        FROM Contact WHERE Id =: newContact.Id];

        Assert.areEqual(4, insertedContact[0].Addresses__r.size());
        // for each address record
        for(Address__c address: insertedContact[0].Addresses__r){
            if(address.Is_Primary__c) {
                Assert.areEqual('Undefined', insertedContact[0].Mailing_Address_Verification_Source__c);
                Assert.areEqual(address.DPID__c, insertedContact[0].Mailing_Address_DPID__c);
                Assert.areEqual(address.Verification_Status__c, insertedContact[0].Mailing_Address_Verification_Status__c);
            }
        }
    }
    /**
    * @author      Russell Cadapan
    * @description Tests CheckPhoneSource method
    *
    *              GIVEN a contact with Phone/Mobile Phone sourced from Experian
    *              WHEN inserted/updated in the system
    *              THEN the system should map the verification status correctly
    * @revision    05/04/2021 - Russell Cadapan - Created
    */
    @isTest
    static void CheckPhoneSource_OnInsert_Test(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        // GIVEN: A contact is supplied Phone and Mobile Phone
        Contact newContact = new Contact();
        newContact.FirstName = 'Zoe';
        newContact.LastName = 'Pearson';

        // AND the Phone is sourced from Experian
        newContact.Phone = '0223470137';
        newContact.Phone_Verification_Source__c = 'Experian';
        newContact.Phone_Verification_Status__c = 'Verified';

        // AND the Mobile Phone is sourced from Experian
        newContact.MobilePhone = '042347137';
        newCOntact.Mobile_Phone_Verification_Source__c = 'Experian';
        newContact.Mobile_Verification_Status__c = 'Verified';

        // WHEN the contact is inserted to the system
        Test.startTest();
            insert newContact;
        Test.stopTest();

        // THEN both Phones should be rolled down correspondingly with the verification fields

        List<Contact> insertedContact = [SELECT Id, Phone_Verification_Status__c, Mobile_Verification_Status__c, Phone_Verification_Source__c, Mobile_Phone_Verification_Source__c, (SELECT Id, Verification_Status__c, Source__c FROM Phones__r) FROM Contact WHERE Id =: newContact.Id];
        Assert.areEqual(1, insertedContact.size());
        Assert.areEqual(2, insertedContact[0].Phones__r.size());
        Assert.areEqual('Verified', insertedContact[0].Phone_Verification_Status__c);
        Assert.areEqual('Verified', insertedContact[0].Mobile_Verification_Status__c);
        Assert.areEqual('Undefined', insertedContact[0].Mobile_Phone_Verification_Source__c);
        Assert.areEqual('Undefined', insertedContact[0].Phone_Verification_Source__c);

        for(Phone__c phone: insertedContact[0].Phones__r){
            Assert.areEqual('Verified',phone.Verification_Status__c);
            Assert.areEqual('Third party provided',phone.Source__c);
        }
    } 
    
    /**
    * @author      Russell Cadapan
    * @description Tests CheckPhoneSource method
    *
    *              GIVEN a contact with Phone/Mobile Phone sourced from Experian
    *              WHEN inserted/updated in the system
    *              THEN the system should map the verification status correctly
    * @revision    05/04/2021 - Russell Cadapan - Created
    */
    @isTest
    static void CheckPhoneSource_OnUpdate_Test(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        // GIVEN: A contact is supplied Phone and Mobile Phone
        Contact newContact = new Contact();
        newContact.FirstName = 'Zoe';
        newContact.LastName = 'Pearson';

        // AND the Phone is sourced from Experian
        newContact.Phone = '0223470137';
        newContact.Phone_Verification_Source__c = 'Experian';
        newContact.Phone_Verification_Status__c = 'Verified';

        // AND the Mobile Phone is sourced from Experian
        newContact.MobilePhone = '0423470137';
        newCOntact.Mobile_Phone_Verification_Source__c = 'Experian';
        newContact.Mobile_Verification_Status__c = 'Verified';
        insert newContact;

        Test.startTest();
        // WHEN the contact is updated with new phone/mobile phones
        newContact.Phone = '0223470138';
        newContact.MobilePhone = '0423470138';
        newContact.Phone_Verification_Source__c = 'Undefined';
        newCOntact.Mobile_Phone_Verification_Source__c = 'Undefined';
        update newContact;

        // AND phones are reverted back to existing ones
        newContact.Phone = '0223470137';
        newContact.MobilePhone = '0423470137';
        newContact.Phone_Verification_Source__c = 'Undefined';
        newCOntact.Mobile_Phone_Verification_Source__c = 'Undefined';
        update newContact;
        Test.stopTest();

        // THEN the system must be able to preserve the existing address's verification status even if the source of the address is Undefined.
        List<Contact> insertedContact = [SELECT Id, Phone, MobilePhone, Phone_Verification_Status__c, Mobile_Verification_Status__c, Phone_Verification_Source__c, Mobile_Phone_Verification_Source__c, (SELECT Id, Name, Is_Primary__c, Type__c, Verification_Status__c, Source__c FROM Phones__r WHERE Name IN ('0223470137','0423470137')) FROM Contact WHERE Id =: newContact.Id];
        Assert.areEqual(1, insertedContact.size());
        Assert.areEqual(2, insertedContact[0].Phones__r.size());
        Assert.areEqual('0223470137',insertedContact[0].Phone);
        Assert.areEqual('0423470137',insertedContact[0].MobilePhone);
        for(Phone__c phone: insertedContact[0].Phones__r){
                Assert.areEqual('Verified',phone.Verification_Status__c);
                Assert.areEqual('Third party provided',phone.Source__c);
        }
    }
    /**
    * @author      Russell Cadapan
    * @description Tests CheckEmailSource method
    *
    *              GIVEN a contact with Email sourced from Experian
    *              WHEN inserted/updated in the system
    *              THEN the system should map the verification status correctly
    * @revision    05/04/2021 - Russell Cadapan - Created
    */
    @isTest
    static void CheckEmailSource_OnInsert_Test(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        // GIVEN: A contact is supplied Email
        Contact newContact = new Contact();
        newContact.FirstName = 'Zoe';
        newContact.LastName = 'Pearson';
        newContact.Personal_Email__c = 'zoe.person_test@testonly.com';
        // AND the Email is sourced from Experian
        newContact.Personal_Email_Verification_Status__c = 'Verified';
        newContact.Email_Verification_Source__c = 'Experian';


        Test.startTest();
            insert newContact;
        Test.stopTest();

        // THEN the email should be rolled down correspondingly with the verification fields
        List<Contact> insertedContact = [SELECT Id, Email, Personal_Email__c, Email_Verification_Source__c, Personal_Email_Verification_Status__c, (SELECT Id, Name, Is_Primary__c, Classification__c, Verification_Status__c, Source__c FROM Emails__r) FROM Contact WHERE Id =: newContact.Id];
        Assert.areEqual(1, insertedContact.size());
        Assert.areEqual(1, insertedContact[0].Emails__r.size());
        Assert.areEqual('Verified', insertedContact[0].Personal_Email_Verification_Status__c);
        Assert.areEqual('Undefined', insertedContact[0].Email_Verification_Source__c);
    }
    /**
   * @author      Russell Cadapan
   * @description Tests CheckEmailSource method
   *
   *              GIVEN a contact with Email sourced from Experian
   *              WHEN inserted/updated in the system
   *              THEN the system should map the verification status correctly
   * @revision    05/04/2021 - Russell Cadapan - Created
   */
    @isTest
    static void CheckEmailSource_OnUpdate_Test(){
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        upsert cs;

        // GIVEN: A contact is supplied Email
        Contact newContact = new Contact();
        newContact.FirstName = 'Zoe';
        newContact.LastName = 'Pearson';
        newContact.Personal_Email__c = 'zoe.person_test@testonly.com';
        // AND the Email is sourced from Experian
        newContact.Personal_Email_Verification_Status__c = 'Verified';
        newContact.Email_Verification_Source__c = 'Experian';
        insert newContact;


        Test.startTest();
        newContact.Personal_Email__c = 'zoe.person_test_new@testonly.com';
        newContact.Email_Verification_Source__c = 'Undefined';
        update newContact;

        newContact.Personal_Email__c = 'zoe.person_test@testonly.com';
        newContact.Email_Verification_Source__c = 'Undefined';
        update newContact;
        Test.stopTest();

        // THEN the system must be able to preserve the existing address's verification status even if the source of the address is Undefined.
        List<Contact> insertedContact = [SELECT Id, Email, Personal_Email__c, Email_Verification_Source__c, Personal_Email_Verification_Status__c, (SELECT Id, Name, Is_Primary__c, Classification__c, Verification_Status__c, Source__c FROM Emails__r WHERE Name IN ('zoe.person_test@testonly.com')) FROM Contact WHERE Id =: newContact.Id];
        Assert.areEqual(1, insertedContact.size());
        Assert.areEqual(1, insertedContact[0].Emails__r.size());
        Assert.areEqual('Verified', insertedContact[0].Emails__r[0].Verification_Status__c);
        Assert.areEqual('Third party provided', insertedContact[0].Emails__r[0].Source__c);
    }
/**
     * @author      Seeva Singh
     * @description Tests Create an account and changes its record type from household to agency and then back to household 
     * @revision    15/05/2023 - Seeva Singh - Created
     */
    @isTest
    public static void testPopulateAccountRecordTypeNameOnContact() {
        Id householdRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household_Account').getRecordTypeId();
		Id schoolRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('School').getRecordTypeId();

        //Start test
        Test.startTest();
            Account testHHAccount = new Account(Name = 'Test Household Account', RecordTypeId = householdRecordTypeId);
            insert testHHAccount;
            Id hhAccId = testHHAccount.Id;

            Contact testContact = new Contact(LastName = 'Test Contact', AccountId = hhAccId);
            insert testContact;
            Assert.areEqual('Household_Account',[SELECT Id, Account_Record_Type_Name__c FROM Contact WHERE AccountId = :hhAccId].Account_Record_Type_Name__c, 'Expected the Account Record Type Name to be Household_Account');
            
            Account testSchoolAccount = new Account(Name = 'Test School Account', RecordTypeId = schoolRecordTypeId);
            insert testSchoolAccount;
            Id schoolAccId = testSchoolAccount.Id;
            
            testContact = [SELECT Id, Account_Record_Type_Name__c FROM Contact WHERE AccountId = :hhAccId];
            testContact.AccountId = schoolAccId;
            update testContact;
        //Stop test
        Test.stopTest();
        Assert.areEqual('School',[SELECT Id, Account_Record_Type_Name__c FROM Contact WHERE LastName = 'Test Contact'].Account_Record_Type_Name__c, 'Expected the Account Record Type Name to be School');
    }
    
      /**
    * @author      Shalini Mendu
    * @description Tests validation on Principal Agent/Branch Manager re-assignment to an 
    *              Agent under the same account by asserting the validation
                   for Contact create.
    * @revision    05/05/2023 - Created
    */
    @isTest
    static void testValidateReassignAgencyRolesonContactCreate() {

        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
        Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
        Country__c = 'Australia');
        insert australia;
        Id agentRecType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Agency_Contact').getRecordTypeId(); 

        Account acc=  new Account(Name = 'TestAgencyNZ',
        Phone = '12345',
        Email__c = 'test@agency.com',
        Website = 'www.test-agency-1.com',
        Street__c = '123 testing st',
        City__c = 'Melbourne',
        Country_Lookup__c = australia.Id,
        State__c = 'VIC',
        Post_Code__c = '3000',
        ShippingStreet = '123 testing st',
        ShippingCity = 'Melbourne',
        ShippingState = 'VIC',
        ShippingPostalCode = '3000',
        ShippingCountry = 'New Zealand',
        Monash_AM_Web_Status__c = true,
        Callista_Org_Unit_Code__c = 'TESTNZ',
        Monash_AM_Campus__c = 'Australia',
        RecordTypeId = AccountUtility.ACCOUNT_AGENCY_REC_TYPE,
        Status__c = 'Appointed');
        insert acc;
        Test.startTest();
        Contact testContact = new Contact(RecordTypeId=agentRecType, FirstName = 'John', LastName = 'Doe', AccountId = acc.Id, Email = 'TestEmail@testemail.com',Agency_contact_roles__c='Principal Agent;Branch Manager');
        insert testContact;
        try{
            Contact testContactWithPARole = new Contact(RecordTypeId=agentRecType, FirstName = 'Johny ', LastName = 'Lever', AccountId = acc.Id, Email = 'johnylevert@email.com',Agency_contact_roles__c='Principal Agent');
            insert testContactWithPARole;
        }catch(Exception e)
        {
            Assert.isTrue(e.getMessage().contains('Please first demote John Doe with Principal Agent role'));
        }
        try{
            Contact testContactWithBMRole = new Contact(RecordTypeId=agentRecType, FirstName = 'Jenny', LastName = 'Lever', AccountId = acc.Id, Email = 'jennylevert@email.com',Agency_contact_roles__c='Branch Manager');
            insert testContactWithBMRole;
        }catch(Exception e)
        {

            Assert.isTrue(e.getMessage().contains('Please first demote John Doe with Branch Manager role'));
        }

 
       Test.stopTest();
       Assert.isTrue( [Select Agency_contact_roles__c from Contact][0].Agency_contact_roles__c.contains('Principal Agent'));
       Assert.isTrue( [Select Agency_contact_roles__c from Contact][0].Agency_contact_roles__c.contains('Branch Manager'));

    }

     /**
    * @author      Shalini Mendu
    * @description Tests  re-assignment of partner role when Agency_contact_roles is updated
                   for Contact Update .
    * @revision    05/05/2023 - Created
    */
    @isTest
    static void testReassignAgencyRolesonContactUpdate() {
      Map<String, Object> resultsMap = new Map<String, Object>();

        Id agentRecType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Agency_Contact').getRecordTypeId(); 
        Id agencyRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency').getRecordTypeId(); 
      
        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                  Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                  Country__c = 'Australia');
                                                                  insert australia;
       
        Account testAccount = new Account(Name = 'TestAgencyAU',
        Phone = '12345',
        Email__c = 'test@agency.com',
        Website = 'www.test-agency-1.com',
        Street__c = '123 testing st',
        City__c = 'Melbourne',
        State__c = 'VIC',
        Post_Code__c = '3000',
        Country_Lookup__c = australia.Id,
        ShippingStreet = '123 testing st',
        ShippingCity = 'Melbourne',
        ShippingState = 'VIC',
        ShippingPostalCode = '3000',
        ShippingCountry = 'Australia',
        Monash_AM_Web_Status__c = true,
        Callista_Org_Unit_Code__c = 'TESTAU',
        Monash_AM_Campus__c = 'Australia',
        RecordTypeId = AccountUtility.ACCOUNT_AGENCY_REC_TYPE,
        Status__c = 'Appointed');  
        insert testAccount;
        testAccount.IsPartner =true;
        update testAccount;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            List<UserRole> urList = new List<UserRole>();
            urList.add(new UserRole( PortalAccountId = testAccount.Id, portalType = 'Partner' ));
            urList.add(new UserRole(PortalAccountId = testAccount.Id, portalType = 'Partner'));
            insert urList;
         }
         String agencyroles = 'Counsellor;Branch Manager';
         Contact testContact = new Contact(RecordTypeId=agentRecType ,Agency_Contact_Roles__c=agencyroles, FirstName = 'TestAgentFirstName', LastName = 'TestAgentLastName', AccountId = testAccount.Id, Email = 'testagentEmail@testemail.com');
         insert testContact;
         String testUsername = String.valueOf(Math.random()) + 'testapemail@testapemail.com';
         String userDetails = '{"isPartnerActive": true,"agencyContactRoles":"Counsellor;Delegated Admin","accountId":"' + testAccount.Id + '","PartnerAccountId":"' + testAccount.Id + '", "ContactId":"' + testContact.Id + '","FirstName":"TestAgentFirstName","MiddleName":"TestAgentMiddleName","LastName":"TestAgentLastName","Email":"testagentEmail@testemail.com","Username":"' + testUsername + '"}';
         Test.startTest();
         System.runAs(thisUser) {
             resultsMap = ExperienceAuthenticationServices.buildAndGenerateAgentUser(userDetails);
             testContact.Agency_Contact_Roles__c = 'Counsellor';
        	 update testContact;
         }
         Test.stopTest();
         //Start assertion
         Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
         User usr = [SELECT id, IsPrmSuperUser,Username,IsActive,Profile.Name FROM User where contactId=:testContact.Id LIMIT 1];
        List<UserRole> uroleList = [Select id,name from UserRole where Id in (select UserRoleId from User  where Id=:usr.Id)];
        Assert.areEqual('TestAgencyAU Partner User',uroleList[0].Name);
        }
       
     /**
     * @description testToProperCase Test method to validate that names are changed from all uppercase to propercase
     */
    @IsTest
    private static void testToProperCase() {
        // GIVEN: input names come as all uppercase
        List<String> testNamesInput = new List<String>{'papa smurf','VAN HEUSEN', 'VAN DER AALST', 'lin-ye', 'O\'HENRY', 'LIN-\'OH', '\'NGO', 'NGO\'', 'MCDONALD', '-', '--', '', 'McDonald' };
		final List<String> testNamesOutput = new List<String>{'Papa Smurf','Van Heusen', 'Van Der Aalst', 'Lin-Ye', 'O\'Henry', 'Lin-\'Oh', '\'Ngo', 'Ngo\'', 'Mcdonald', '-', '--', '', 'McDonald' };

        // WHEN: the name is processed
        Test.startTest();
        for(Integer i=0; i<testNamesInput.size(); i++) {
            testNamesInput[i] = contactServices.toProperCase(testNamesInput[i]);
        // THEN: the names are formatted to what's expected
            Assert.isTrue(testNamesInput[i].equals(testNamesOutput[i]), 'The name was not changed to proper case as expected ['+ testNamesInput[i] + '] [' + testNamesOutput[i] +']');
        }
        Test.stopTest();
    }
}