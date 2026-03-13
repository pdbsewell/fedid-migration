/**
*
* @description Test class supporting ibdContactServiceV2.cls
* @revisions
* 20/03/2023 Ken McGuire - country of birth replace ISO with SAAC
* 26/04/2024 Martin Cadman - Added nebula logger check
* 26-04-2024 Martin Cadman - Moved to Assert class
* 23-08-2024 Martin Cadman - Added a USI mapping check
* 03-10-2024 Martin Cadman - Reorganised the firstname and lastname assignments in the field mapping section
*
*/
@isTest(isParallel=true)
public class IbdContactServicesV2_Test {
    
    /*
     * @description Test & reference data provisioning
     */
    @testSetup
    static void setupData(){
        
        // Turn on person360 Rollup and Down. Some tests do rely on this executing.
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Force_Rollup__c = false;
        cs.Enable_Force_Rolldown__c = false;
        cs.EnableChannelBreakUp__c = false;
        cs.Relax_Rollup_Bypass__c = false;
        cs.Record_Type_Roll_Down_Bypass__c = 'Agency_Contact';
        upsert cs;
        
        // Standard contact with Person ID (i.e. emulating a record created by this process)
        Contact c = new Contact (Firstname = 'Existing_One'
                                 , Lastname = 'Existing_One'
                                 , Person_ID_Unique__c = '10000000'
                                 , Birthdate=Date.newInstance(1990, 12, 14)
                                 , LastModifiedDate_API__c=datetime.newInstance(2017, 1, 1, 00, 00, 00)
                                 , Gender__c='M'
                                 , contact_profile__c = 'Alumni'
                                 , Deceased__c=false);
        insert c;
        
        // Create a valid Monash email address for contact
        Email__c e = new Email__c(name='alegitlookingaddr@monash.edu', contact__c = c.id, Source__c = 'Callista', classification__c = 'Monash');
        new EmailTriggerHandler.PopulateHash().process(e);
        insert e;
        e = new Email__c(name='secondemail@monash.edu', contact__c = c.id, Source__c = 'Callista', classification__c = 'Monash');
        new EmailTriggerHandler.PopulateHash().process(e);
        insert e;
        
        // Emulate my.app or agent api contact. No person id assigned.
        c = new Contact (Firstname = 'Existing_Two'
                         , Lastname = 'Existing_Two'
                         , Birthdate=Date.newInstance(1990, 12, 14)
                         , LastModifiedDate_API__c=datetime.newInstance(2017, 1, 1, 00, 00, 00)
                         , Gender__c='M'
                         , Salutation = 'MX'
                         , is_student__c = true
                         , vtac_id__c = 'UniqueVTAC'
                         , Deceased__c=false);
        insert c;

        // Assign application to contact above.
        Application__c a = new Application__c(applicant__c = c.id, callista_applicant_id__c = '7000001');
        insert a;    
        
        // Setup a puesdo role account contact, making sure that there is not middlename created
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agency Contact').getRecordTypeId();
        c = new Contact (Firstname = 'Agency'
                       , Lastname  = 'Role'
                       , email = 'role@agency.com'
                       , recordtypeid = recordTypeId
                       , Person_ID_unique__c = '30000001'
                       , Role_Account_Flag__c=true);
        insert c;
        
        c.FirstName = 'Agency firstname name with numbers 1234';
        c.LastName = 'Agency last name with numbers 1234';
        c.First_Name__c = c.FirstName;
        c.Last_Name__c = c.LastName;
        update c;
        
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.EndDateStudentNames__c = true;
        fs.AllowOutOfSyncEvents__c = false;
        insert fs;
    }
    
    /*
     * @description Inbound contact has a lot of fudge code to stop agency role contacts from being processed as if they are student records. I feel a refactor coming on...
     * - no rolldown should occur for name or email, based on the record type
     * - no name manipulation should occur for role account contacts, that is first name shouldn't be split up and numbers shouldn't be removed
     * 
     * Send an update for a role account contact and make sure the FN and LN remain direcly aligned with Callista - i.e. no P360 involvement
     **/
    @isTest
    static void validateNoRollforaRole() {
        Contact c = [select id, firstname, lastname,MiddleName, person_id_unique__c from contact where person_id_unique__c='30000001'];

        // Generate an update for a Role Account Contact
        IbdContact__e insertContact = generateEvent(1)[0];
        insertContact.first_name__c = c.firstname;
        insertContact.last_name__c = c.lastname;
        insertContact.Person_ID__c = c.Person_ID_unique__c;
        insertContact.Preferred_Name__c = null;

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'IbdContact event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();
        
        // Validate the Contact
        List<Contact> contacts = [
            SELECT ID, Person_ID__c, First_Name__c, FirstName, lastname, last_name__c, MiddleName
            FROM Contact WHERE Person_ID_unique__c=:insertContact.Person_ID__c
        ];
        
        Assert.isNull(contacts[0].middlename,'The middlename should remain blanks as the FN was not broken up');
        Assert.areEqual(contacts[0].firstname,c.firstname,'The firstname from the set up data should not have been changed as it is a role account');
        Assert.areEqual(contacts[0].lastname,c.lastname,'The lastname from the set up data should not have been changed as it is a role account');
    }
    
   /*
    * @description InsertContact - test conditions
    * - creates a new contact
    * - no middle name is specified
    * - a valid Monash email address is specified
    * - VTAC id is specified (random static field)
    * 
    * As well as determining that the Contact was correctly created, this method also 
    * - validates that the email rollup has occured
    * - validates that the name rolldown has occured
    */
    @isTest
    static void validateInsertContactWithoutPFN() {
        
        IbdContact__e insertContact = generateEvent(1)[0];
        insertContact.First_Name__c = 'Peter Gene';
        insertContact.Preferred_Name__c = null;
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'IbdContact event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        // Validate the Contact
        List<Contact> contacts = [
            SELECT ID, Person_ID__c, First_Name__c, FirstName, VTAC_ID__c, LastModifiedDate_API__c, MiddleName
            FROM Contact WHERE Person_ID_unique__c=:insertContact.Person_ID__c
        ];
        Assert.areEqual(1, contacts.size(), 'Expected number of contact records (1) not be found.');
        Assert.areEqual('Peter', contacts[0].FirstName, 'First name of contact was not as per event data');
        Assert.areEqual('Gene', contacts[0].MiddleName);
        Assert.areEqual(insertContact.First_Name__c, contacts[0].First_Name__c, 'First name of contact was not as per event data');
        Assert.areEqual(insertContact.VTAC_ID__c, contacts[0].VTAC_ID__c, 'VTAC ID of contact was not as per event data');
        Assert.areEqual(insertContact.Last_Modified_Date__c, Contacts[0].LastModifiedDate_API__c, 'Expected Contact.LastModifiedDate_API__c is not the same as the inbound contact platform event.');

        // Validate the Monash email address record exists and is also present on the Contact field (which is a person360Rollup function)
        List<Email__c> emails = new List<Email__c>(
            [SELECT Id, Name, Contact__c, Contact__r.Person_ID_unique__c, Contact__r.LastModifiedDate_API__c, Source__c
             FROM Email__c
             WHERE Classification__c = 'Monash'
             AND Contact__r.Person_ID_unique__c = :insertContact.Person_ID__c
             AND Name = :insertContact.Monash_Email__c]
        );
        Assert.areEqual(1, emails.size(), 'Expected number of monash email records (1) could not be found.');
        Assert.areEqual(insertContact.Monash_Email__c.tolowercase(), emails[0].Name, 'Expected monash email is not the same as the inbound contact platform event.');
        Assert.areEqual('Callista', emails[0].Source__c,'Expected source is not equal to Callista.');
    }

    /*
     * @description Preferred first name test
     */
    @IsTest
    static void validateInsertContactWithPFN() {

        IbdContact__e insertContact = generateEvent(1)[0];
        insertContact.First_Name__c = 'Enoch Malachi';
        insertContact.Last_Name__c = 'Thompson';
        insertContact.Preferred_Name__c = 'Nucky';

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact);
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'IbdContact event could not be published. Errors: ' + sr.getErrors());

        // Validate the Contact
        List<Contact> contactsResult = [
                SELECT Preferred_Name__c, FirstName, MiddleName, First_Name__c, VTAC_ID__c, LastModifiedDate_API__c
                FROM Contact WHERE Person_ID_unique__c = :insertContact.Person_ID__c
        ];
        Assert.areEqual(1, contactsResult.size(), 'Expected number of contact records (1) not be found.');
        Contact cResult = contactsResult[0];
        Assert.areEqual(insertContact.VTAC_ID__c, cResult.VTAC_ID__c, 'VTAC ID of contact was not as per event data');
        Assert.areEqual(insertContact.Last_Modified_Date__c, cResult.LastModifiedDate_API__c, 'Expected Contact.LastModifiedDate_API__c is not the same as the inbound contact platform event.');
        Assert.areEqual(insertContact.Preferred_Name__c, cResult.Preferred_Name__c);
        Assert.areEqual(insertContact.First_Name__c, cResult.First_Name__c);
        Assert.areEqual(insertContact.Preferred_Name__c, cResult.FirstName);
        Assert.isNull(cResult.MiddleName);

        List<Name__c> names = [
                SELECT Name, First_Name__c, Middle_Name__c, Last_Name__c, Preferred_First_Name__c, Type__c
                FROM Name__c WHERE Contact__c = :cResult.Id order by type__c
        ];
        Assert.areEqual(2, names.size());
        Assert.areEqual('Common', names[0].Type__c);
        Assert.areEqual('Enoch', names[0].First_Name__c);
        Assert.areEqual('Malachi', names[0].Middle_Name__c);
        Assert.areEqual(insertContact.Last_Name__c, names[0].Last_Name__c);
        Assert.areEqual(insertContact.Preferred_Name__c, names[0].Preferred_First_Name__c);
    }

    /*
     * @description Test a series of updates
     */
    @isTest
    static void validateTriple() {
        IbdContact__e insertEvent = new IbdContact__e();
        insertEvent.Source_System__c = 'callista';
        insertEvent.Event_Type__c = 'INSERT';
        insertEvent.Last_Modified_Date__c = Datetime.now();
        insertEvent.Last_Modified_By__c = 'UNITTEST';
        insertEvent.ESOS__c = false;
        insertEvent.Has_Arrived_In_Australia__c = false;
        insertEvent.DSS_Registered__c = false;
        insertEvent.Deceased__c = false;
        insertEvent.IT_account_disabled__c = false;
        insertEvent.Title__c = 'MS';
        insertEvent.First_Name__c = 'Maci Ann';
        insertEvent.Last_Name__c = 'Greaves';
        insertEvent.Person_ID__c = '88776657';
        insertEvent.USI__C = 'USI7654321';

        IbdContact__e update1Event = insertEvent.clone();
        update1Event.Event_Type__c = 'UPDATE';

        IbdContact__e update2Event = update1Event.clone();

        Test.startTest();
        EventBus.publish(insertEvent);
        Test.getEventBus().deliver();

        Contact cResult1 = [SELECT First_Name__c, FirstName, MiddleName, Last_Name__c, LastModifiedDate FROM Contact WHERE Person_ID_unique__c = :insertEvent.Person_ID__c];
        Name__c[] nameResult1 = [SELECT Type__c, First_Name__c, Middle_Name__c FROM Name__c WHERE Contact__c = :cResult1.Id order by type__c ];

        Assert.areEqual(2, nameResult1.size());
        Assert.areEqual('Maci', cResult1.FirstName);
        Assert.areEqual('Ann', cResult1.MiddleName);
        Assert.areEqual(insertEvent.First_Name__c, cResult1.First_Name__c);
        Assert.areEqual('Maci', nameResult1[0].First_Name__c);
        Assert.areEqual('Ann', nameResult1[0].Middle_Name__c);

        EventBus.publish(update1Event);
        Test.getEventBus().deliver();

        Contact cResult2 = [SELECT First_Name__c, FirstName, MiddleName, Last_Name__c, LastModifiedDate FROM Contact WHERE Person_ID_unique__c = :insertEvent.Person_ID__c];
        System.assertNotEquals(cResult1, cResult2, 'Contact did not update');
        Assert.areEqual(insertEvent.First_Name__c, cResult1.First_Name__c);
        Assert.areEqual('Maci', cResult1.FirstName);
        Assert.areEqual('Ann', cResult2.MiddleName);

        Map<Id,Name__c> nameResult2 = new Map<Id,Name__c>([SELECT Type__c, First_Name__c, Middle_Name__c FROM Name__c WHERE Contact__c = :cResult1.Id]);
        Assert.areEqual(2, nameResult2.size());
        Name__c commonNameR2 = nameResult2.remove(nameResult1[0].Id);
        Name__c studentNameR2 = nameResult2.values()[0];
        Assert.areEqual('Student name', studentNameR2.Type__c);
        Assert.areEqual('Maci', studentNameR2.First_Name__c);
        Assert.areEqual('Ann', studentNameR2.Middle_Name__c);
        Assert.areEqual('Common', commonNameR2.Type__c);
        Assert.areEqual('Ann', commonNameR2.Middle_Name__c);

        EventBus.publish(update2Event);
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact cResult3 = [SELECT USI__c, MiddleName, LastModifiedDate FROM Contact WHERE Person_ID_unique__c = :insertEvent.Person_ID__c];
        Assert.areNotEqual(cResult2, cResult3, 'Contact did not update');
        Assert.areEqual('Ann', cResult3.MiddleName);
        Name__c[] nameResult3 = [SELECT Id FROM Name__c WHERE Contact__c = :cResult1.Id];
        Assert.areEqual(2, nameResult3.size());
		Assert.areEqual(cResult3.USI__c,insertEvent.USI__C, 'Check the mapping of the USI');
    }

    /*
     * @description Test a series of updates including a preferred first name
     */
    @isTest
    static void validateTripleWithPFN() {
        IbdContact__e insertEvent = new IbdContact__e();
        insertEvent.Source_System__c = 'callista';
        insertEvent.Event_Type__c = 'INSERT';
        insertEvent.Last_Modified_Date__c = Datetime.now();
        insertEvent.Last_Modified_By__c = 'UNITTEST';
        insertEvent.ESOS__c = false;
        insertEvent.Has_Arrived_In_Australia__c = false;
        insertEvent.DSS_Registered__c = false;
        insertEvent.Deceased__c = false;
        insertEvent.IT_account_disabled__c = false;
        insertEvent.Title__c = 'MS';
        insertEvent.First_Name__c = 'Maci Ann';
        insertEvent.Last_Name__c = 'Greaves';
        insertEvent.Person_ID__c = '88776657';

        IbdContact__e update1Event = insertEvent.clone();
        update1Event.Event_Type__c = 'UPDATE';

        IbdContact__e update2Event = update1Event.clone();
        update2Event.Preferred_Name__c = 'Mace';

        Test.startTest();
        EventBus.publish(insertEvent);
        Test.getEventBus().deliver();

        Contact cResult1 = [SELECT FirstName, MiddleName, Last_Name__c, LastModifiedDate FROM Contact WHERE Person_ID_unique__c = :insertEvent.Person_ID__c];
        //Assert.areEqual('Ann', cResult1.MiddleName);
        Name__c[] nameResult1 = [SELECT Type__c, First_Name__c, Middle_Name__c FROM Name__c WHERE Contact__c = :cResult1.Id order by type__c];
        //Assert.areEqual(2, nameResult1.size());

        EventBus.publish(update1Event);
        Test.getEventBus().deliver();

        Contact cResult2 = [SELECT FirstName, MiddleName, Last_Name__c, LastModifiedDate FROM Contact WHERE Person_ID_unique__c = :insertEvent.Person_ID__c];
        Assert.areEqual('Ann', cResult2.MiddleName);

        Map<Id,Name__c> nameResult2 = new Map<Id,Name__c>([SELECT Type__c, First_Name__c, Middle_Name__c FROM Name__c WHERE Contact__c = :cResult1.Id]);
        Assert.areEqual(2, nameResult2.size());
        Name__c commonNameR2 = nameResult2.remove(nameResult1[0].Id);
        Name__c studentNameR2 = nameResult2.values()[0];
        Assert.areEqual('Student name', studentNameR2.Type__c);
        Assert.areEqual('Ann', studentNameR2.Middle_Name__c);
        Assert.areEqual('Common', commonNameR2.Type__c);
        Assert.areEqual('Ann', commonNameR2.Middle_Name__c);

        EventBus.publish(update2Event);
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact cResult3 = [SELECT FirstName, Preferred_Name__c, MiddleName, LastModifiedDate FROM Contact WHERE Person_ID_unique__c = :insertEvent.Person_ID__c];
        System.assertNotEquals(cResult2, cResult3, 'Contact did not update');
        Assert.areEqual(null, cResult3.MiddleName);
        Assert.areEqual(update2Event.Preferred_Name__c, cResult3.Preferred_Name__c);
        Assert.areEqual(update2Event.Preferred_Name__c, cResult3.FirstName);
        Name__c[] nameResult3 = [SELECT Id FROM Name__c WHERE Contact__c = :cResult1.Id];
        Assert.areEqual(2, nameResult3.size());
    }

    /*
     * @description Test a series of updates
     */
    @IsTest
    static void validateTwice() {
        IbdContact__e updateEvent1 = new IbdContact__e();
        updateEvent1.Source_System__c = 'callista';
        updateEvent1.Event_Type__c = 'UPDATE';
        updateEvent1.Last_Modified_Date__c = Datetime.now();
        updateEvent1.Last_Modified_By__c = 'UNITTEST';
        updateEvent1.Title__c = 'MS';
        updateEvent1.First_Name__c = 'Maci Ann';
        updateEvent1.Last_Name__c = 'Greaves';
        updateEvent1.Person_ID__c = '88776657';

        IbdContact__e updateEvent2 = updateEvent1.clone();

        EventBus.publish(updateEvent1);
        Test.getEventBus().deliver();

        EventBus.publish(updateEvent2);
        Test.getEventBus().deliver();

        Contact result = [
            SELECT Name, FirstName, Last_Name__c, First_Name__c, MiddleName
            FROM Contact WHERE Person_ID__c = :updateEvent1.Person_ID__c
        ];

        Assert.areEqual('Ann', result.MiddleName);
        Assert.areEqual('Maci', result.FirstName);
        Assert.areEqual(updateEvent1.First_Name__c, result.First_Name__c);
        Assert.areEqual(updateEvent1.First_Name__c + ' ' + updateEvent1.Last_Name__c, result.Name);

    }
    
    /*
     * @description updateContactviaPersonId - test conditions
     * - send an event for an exsiting person id
     * - monash email is not included in the event
     * 
     * Determine that the existing Contact was the record which was updated.
     * Check the existing monash email record is end dated
     */
    @isTest
    static void validateUpdateContactviaPersonId() {
        
        IbdContact__e insertContact = generateEvent(1)[0];
        insertContact.Event_Type__c = 'UPDATE'; // not actually required, insert would work as well
        insertContact.person_id__c = '10000000';
        insertContact.Monash_Email__c = null;
        
        List<Contact> contacts = [SELECT ID FROM Contact WHERE Person_ID_unique__c=:insertContact.person_id__c];
        Assert.areEqual(1, contacts.size(), 'Existing contact record not found.');
        
        List<Email__c> emails = new List<Email__c>([SELECT Id FROM Email__c WHERE Classification__c = 'Monash' 
                                                    AND Contact__r.Person_ID_unique__c = :insertContact.Person_ID__c 
                                                    AND end_date__c = null]);
        Assert.areEqual(2, emails.size(), 'Existing monash email record could not be found.');        
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'InbContact event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        // Validate the Contact
        contacts = [SELECT ID, Person_ID__c, Birthdate, LastModifiedDate_API__c FROM Contact WHERE Person_ID_unique__c=:insertContact.person_id__c];
        Assert.areEqual(1, contacts.size(), 'Expected number of contact records (1) not be found.');
        Assert.areEqual(insertContact.Birthdate__c, contacts[0].Birthdate, 'Contact birthdate has not been updated');
        Assert.areEqual(insertContact.Person_ID__c, contacts[0].Person_ID__c, 'Contact match was not made via applicant id');
        Assert.areEqual(insertContact.Last_Modified_Date__c, Contacts[0].LastModifiedDate_API__c, 'Expected Contact.LastModifiedDate_API__c is not the same as the inbound contact platform event.');
        
        // Validate the Monash email address record has been end dated
        emails = new List<Email__c>(
            [SELECT Id, Name, Contact__c, Contact__r.Person_ID_unique__c, Contact__r.LastModifiedDate_API__c, Source__c
             FROM Email__c
             WHERE Classification__c = 'Monash'
             AND Contact__r.Person_ID_unique__c = :insertContact.Person_ID__c
             AND end_date__c != null]
        );
        Assert.areEqual(2, emails.size(), 'Expected number of monash email records (2) could not be found.');        
    }
    
   /*
    * @description Validates that events with older api date are ignored.
    */
    @isTest
    static void validateUpdateOldContact() {
        
        List<IbdContact__e> insertContact = generateEvent(2);
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact[0]);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'InbContact event could not be published. Errors: ' + sr.getErrors());
        
        insertContact[1].Last_Modified_Date__c = insertContact[0].Last_Modified_Date__c.addDays(-1);
        insertContact[1].person_id__c = insertContact[0].person_id__c;
        insertContact[1].Event_Type__c = 'UPDATE';
        
        sr = EventBus.publish(insertContact[1]);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'InbContact update event could not be published. Errors: ' + sr.getErrors());
        
        Test.stopTest();        
        
        // Validate the Contact
        list<Contact> contacts = [SELECT ID, LastModifiedDate_API__c FROM Contact WHERE Person_ID_unique__c=:insertContact[0].person_id__c];
        Assert.areEqual(1, contacts.size(), 'Expected number of contact records (1) not be found.');
        Assert.areEqual(insertContact[0].Last_Modified_Date__c, Contacts[0].LastModifiedDate_API__c, 'Contact was updated despite being older.');

        List<Nebula__LogEntry__c> LogMsg = [select id from Nebula__LogEntry__c where Nebula__ApexClassName__c = 'IbdContactServicesV2' and Nebula__LoggingLevel__c = 'WARN'];
        Assert.areEqual(1, LogMsg.size(), 'A warning was expected');
    }
    
    
    /**
    * @description updateContactviaApplicant - test conditions
    * - if the event reference an Application id that belongs to a Contact that does not have person id assigned, update the Applications parent Contact
    * - requires an existing Contact with no person id with an Application with a known callista_applicant_id__c
    * 
    * A second update is attempted with the same applicant id but against a Contact that already has a Person Id assigned. In this case an exception is logged.
    **/
    @isTest
    static void validateUpdateContactviaApplicantId() {
        
        IbdContact__e insertContact = generateEvent(1)[0];
        insertContact.Applicant_IDs__c = '6000001;7000001'; // 2nd of these created in test setup
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'InbContact event could not be published. Errors: ' + sr.getErrors());
        
        // Validate the Contact
        List<Contact> contacts = [SELECT ID, Person_ID__c, VTAC_ID__c, LastModifiedDate_API__c FROM Contact WHERE VTAC_ID__c=:insertContact.vtac_id__c];
        Assert.areEqual(1, contacts.size(), 'Expected number of contact records (1) not be found.');
        Assert.areEqual(insertContact.Person_ID__c, contacts[0].Person_ID__c, 'Contact match was not made via applicant id');
        Assert.areEqual(insertContact.Last_Modified_Date__c, Contacts[0].LastModifiedDate_API__c, 'Expected Contact.LastModifiedDate_API__c is not the same as the inbound contact platform event.');
        
        // Creating new contact with person id and supplying an applicant id that belongs to another contact
        insertContact = generateEvent(1)[0];
        insertContact.Applicant_IDs__c = '7000001'; //  created in test setup
        
        sr = EventBus.publish(insertContact);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Inbound Contact event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        // An exception should have been raised, stopping the Person Id from being altered
        List<Nebula__LogEntry__c> LogMsg = [select id from Nebula__LogEntry__c where Nebula__ApexClassName__c = 'IbdContactServicesV2' and Nebula__LoggingLevel__c = 'ERROR'];
        Assert.areEqual(1, LogMsg.size(), 'An error was expected');
    }
    
    /**
    * @description insertComplexContact - test conditions
    * - event is for a new Contact
    * - a middlename is specfied in the firstname field
    * - invalid lastname , containing numbers
    * - monash email address is specified but is not a valid student email address
    * 
    * Validates that the monash emai address was not populated with the invalid email
    * Validates that the student name records was created with a middle name
    * Does not validate that the name rollup has occured.
    * Shalini Mendu - Updated this test method to cover not updating Country_Of_Birth__c value from the event 
    */
    @isTest
    static void validateInsertComplexContact() {
        
        IbdContact__e insertContact = generateEvent(1)[0];
        insertContact.Country_Of_Birth__c = 'Australia';
        insertContact.Monash_Email__c = 'notvalid@emailaddr.com';
        insertContact.first_name__c = 'Jenny Jones';
        insertContact.last_name__c = '1010 Jenk1010ins 1010'; // numbers should be removed, adds code coverage
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'InbContact event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        // THEN: The Contact exists
        List<Contact> contacts = [SELECT ID, Person_ID__c, lastname, VTAC_ID__c, LastModifiedDate_API__c, Country_Of_Birth__c,CountryOfBirth__c, monash_email_address__c FROM Contact WHERE Person_ID_unique__c=:insertContact.Person_ID__c];
        Assert.areEqual(1, contacts.size(), 'Expected number of contact records (1) not be found.');
        Assert.areEqual(insertContact.VTAC_ID__c, contacts[0].VTAC_ID__c, 'VTAC ID of contact was not as per event data');
        Assert.areEqual(insertContact.Last_Modified_Date__c, Contacts[0].LastModifiedDate_API__c, 'Expected Contact.LastModifiedDate_API__c is not the same as the inbound contact platform event.');
        Assert.isNull(Contacts[0].Country_Of_Birth__c, 'Expected Contact.Country_Of_Birth__c should not be overwritten.');
        Assert.isNull(Contacts[0].CountryOfBirth__c, 'Expected Contact.CountryOfBirth__c should not be overwritten.');
        Assert.areEqual('Jenkins', Contacts[0].lastname, 'Contact lastname has not been cleaned-up');
        
        // THEN: The Monash email address record exists and is also present on the Contact field (which is a person360Rollup function)
        List<Email__c> emails = new List<Email__c>(
            [SELECT Id, Name, Contact__c, Contact__r.Person_ID_unique__c, Contact__r.LastModifiedDate_API__c, Source__c
             FROM Email__c
             WHERE Classification__c = 'Monash'
             AND Contact__r.Person_ID_unique__c = :insertContact.Person_ID__c
             AND Name = :insertContact.Monash_Email__c]
        );
        Assert.areEqual(0, emails.size(), 'Expected number of monash email records (0) could not be found.');
        
    }
    
    /**
    * @description deleteExistingContact - test conditions
    * - event is for an existing Contact
    * 
    * Validates that the Contact is soft deleted
    */
    @isTest
    static void validateDeleteExistingContact() {
        
        IbdContact__e insertContact = generateEvent(1)[0];
        insertContact.Last_Name__c = null;
        insertContact.Event_Type__c = 'DELETE';
        insertContact.Person_ID__c = '10000000'; // created in test setup
        
        List<Contact> contacts = [SELECT ID, Person_ID__c, Birthdate, LastModifiedDate_API__c FROM Contact WHERE Person_ID_unique__c=:insertContact.person_id__c];
        Assert.areEqual(1, contacts.size(), 'Existing contact record not found.');
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'IbdContact event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        // Validate the contact
        contacts = [SELECT ID, deleted_in_source__c, LastModifiedDate_API__c FROM Contact WHERE Person_ID_unique__c=:insertContact.person_id__c];
        Assert.areEqual(1, contacts.size(), 'Expected number of contact records (1) not be found.');
        Assert.areEqual(true, contacts[0].deleted_in_source__c , 'Contact has not been soft deleted.');
        Assert.areEqual(insertContact.Last_Modified_Date__c, Contacts[0].LastModifiedDate_API__c, 'Expected Contact.LastModifiedDate_API__c is not the same as the inbound contact platform event.');
    }
    
    /**
    * @description deleteExistingContact - test conditions
    * - event is for an existing new Contact
    * 
    * Validates that the Contact is never created
    */
    @isTest
    static void validateDeleteNewContact() {
        
        IbdContact__e insertContact = generateEvent(1)[0];
        insertContact.Event_Type__c = 'DELETE';
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'IbdContact event could not be published. Errors: ' + sr.getErrors());
        Test.stopTest();        
        
        // The Contact wasn't created just for the sake of deleting it
        List<Contact> contacts = [SELECT ID, deleted_in_source__c, LastModifiedDate_API__c FROM Contact WHERE Person_ID_unique__c=:insertContact.Person_ID__c];
        Assert.areEqual(0, contacts.size(), 'Contact should not have been soft-deleted as it did not exist');
    }
    
    /**
    * @description nameCheck
    * Two common names should be created 
    * Two student names should be created but the first one should be end dated
    */
    @isTest
    static void validateNameCheck() {
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Force_Rolldown__c = true;
        upsert cs;

        list<IbdContact__e> insertContact = generateEvent(2);
        
        insertContact[1].person_id__c = insertContact[0].person_id__c; // emulate an update

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact[0]);
        Assert.isTrue(sr.isSuccess(), 'Contact event 1 could not be published. Errors: ' + sr.getErrors());
        Test.getEventBus().deliver();
        
        insertContact[1].first_name__c = insertContact[1].first_name__c + ' Sally';
        String personId = insertContact[1].Person_ID__c;
        sr = EventBus.publish(insertContact[1]);
        Assert.isTrue(sr.isSuccess(), 'Contact event 2 could not be published. Errors: ' + sr.getErrors());
        Test.getEventBus().deliver();
        Test.stopTest();        

        List<name__c> names = [SELECT Id, is_Primary__c,first_name__c, middle_name__c, last_name__c, type__c, start_date__c, end_date__c, lastmodifieddate, createddate 
                                //,contact__r.first_name__c, contact__r.last_name__c, contact__r.firstname, contact__r.middlename, contact__r.lastname 
                                FROM name__c 
                                WHERE contact__r.Person_ID_unique__c = :personId order by type__c, start_date__c, createdDate, id];

        Assert.areEqual(4, names.size(), 'Two common and two student records are expected');
        
    }
    
    /**
    * @description duplicateName
    */
    @isTest
    static void validateDuplicateName() {
        list<String> personIds = new list<String>();
        list<IbdContact__e> insertContact = generateEvent(1);
        insertContact[0].title__c = ''; 
        
        for (IbdContact__e e : insertContact){
            personIds.add(e.Person_ID__c);
        }
        
        Test.startTest();
        List<Database.SaveResult> sr = EventBus.publish(insertContact);
        Test.getEventBus().deliver();
        for (Database.SaveResult r : sr) {
            Assert.isTrue(r.isSuccess(), 'ibdContact event could not be published. Errors: ' + r.getErrors());
        }
        Test.stopTest();        
        
        List<name__c> names = [SELECT ID, type__c FROM name__c WHERE contact__r.Person_ID_unique__c in :personIds];
        Assert.areEqual(2, names.size(), 'Expected number of Name records (2) not be found.');
    }
    
    /**
    * @description Important to put the services class under some pressure.
    */
    @isTest
    static void validateBatchInsertContact() {
        list<String> personIds = new list<String>();
        list<IbdContact__e> insertContact = generateEvent(10);
        // throw in some variation
        insertContact[3].First_Name__c = '';
        insertContact[5].First_Name__c = 'Jenny Jones';
        insertContact[2].Monash_Email__c = null;
        
        for (IbdContact__e e : insertContact){
            personIds.add(e.Person_ID__c);
        }
        
        Test.startTest();
        List<Database.SaveResult> sr = EventBus.publish(insertContact);
        Test.getEventBus().deliver();
        for (Database.SaveResult r : sr) {
            Assert.isTrue(r.isSuccess(), 'Bulk ibdContact event could not be published. Errors: ' + r.getErrors());
        }
        Test.stopTest();        
        
        List<Contact> contacts = [SELECT ID FROM Contact WHERE Person_ID_unique__c in :personIds];
        Assert.areEqual(10, contacts.size(), 'Expected number of contact records (10) not be found.');
        
    }
    
    /**
    * @description testRetry
    * The platform event will retry a database.upsert in certain conditions. In order to test this, no lastname has been specified, forcing a database error.
    * There is specific code in the services class that allows the lack of a lastname to get to the point of database.upsert, as the event is otherwise rejected.
    */ 
    @isTest
    static void validateTestRetry() {
        IbdContact__e insertContact = generateEvent(1)[0];
        insertContact.Last_Name__c = '1010101010'; // these will be stripped out, causing a null lastname error. There is a specific handler for this.
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(insertContact);
        Assert.isTrue(sr.isSuccess(), 'IbdContact event could not be published. Errors: ' + sr.getErrors());
        Test.getEventBus().deliver();
        
        for(Integer i=0;i<1 ;i++) {                          
            // Get info about all subscribers to the event
            EventBusSubscriber[] subscribers = queryBus('IbdContact__e');
            
            for (EventBusSubscriber sub : subscribers) { 
                if (sub.Name == 'IbdContactTrigger') {
                    Assert.areEqual(i+1, sub.Retries);
                }
            }
            // Deliver the retried event
            Test.getEventBus().deliver();
        }
        
        Test.stopTest();
    }
    
    /**
    * @description Helper Method to get around the need for SOQL in a loop
    * @param ibdObject The event object type
    * @return Eventbus subscriber details
    */
    static List<EventBusSubscriber> queryBus(String ibdObject) {
        List<EventBusSubscriber> bus = new List<EventBusSubscriber>();
        try {
            bus = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic=:ibdObject];
        } catch(Exception e) {
            return new List<EventBusSubscriber>();
        }
        return bus;
    }    
    
    /**
    * @description Helper Method for the generation of Contact inbound events, with random attributes assigned if possible
    * @param numToGen Integer The number events to generate
    * @return A list of contact inbound events, ready for publishing
    */
    static List<ibdContact__e> generateEvent(Integer numToGen){
        List<ibdContact__e> eventBatch = new List<ibdContact__e>();
        ibdContact__e event;
        
        for (Integer i=0; i<numToGen; i++){
            event = new ibdContact__e();
            event.Event_Type__c='INSERT';
            event.Last_Modified_Date__c=datetime.now();
            event.Last_Modified_By__c='tester';
            event.Title__c='MS';
            event.Last_Name__c='Smith';
            event.First_Name__c='Jenny Ellen';
            event.Gender__c='F';
            event.Deceased__c=false;
            event.IT_account_disabled__c=false;
            event.Monash_Username__c='js000' + i; 
            event.Person_ID__c= String.valueOf(Integer.valueof(Math.random() * 10000001)).rightPad(8,'0');
            event.Country_Of_Birth__c='';
            event.Citizenship__c='Australia';
            event.Nationality__c='Australia';
            event.Monash_Email__c='js000' +i + '@monash.edu';
            event.Birthdate__c=Date.newInstance(1990 + Integer.valueof((Math.random() * 10)), Integer.valueof((Math.random() * 10)), Integer.valueof((Math.random() * 10)) );
            event.Source_System__c = 'callista';
            event.VTAC_ID__c = String.valueOf(4000000 + i) + 'XYZ';   
            event.Applicant_IDs__c = null;
            eventBatch.add(event);
        }
        return eventBatch;
    }
}