/**
 * @description       : Test class for ContactMergeP360Director
 * @author            : Nick Guia
 * @last modified on  : 23-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class ContactMergeP360Director_Test {

    private static Contact contact1;

    static {
        contact1 = new Contact(
            Id = fflib_IDGenerator.generate(Contact.SObjectType),
            FirstName = 'ContactMerge', 
            LastName = 'P360Director_Test',
            Original_Id__c = 'contact1'
        );
    }

    /**
     * Test Affiliation survivorship. The surviving Affiliation should have a unique Composite_Key__c,
     * and the order by which the P360 instance was added should be respected to take precedence
     */
    @isTest
    static void shouldResolveAffiliations() {

        // GIVEN
        Affiliation__c affInstance1 = new Affiliation__c( // survivor
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType), 
            Composite_Key__c = 'Agency1'
        );
        Affiliation__c affInstance2 = new Affiliation__c( // non-survivor
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType), 
            Composite_Key__c = 'Agency1'
        ); 
        Affiliation__c affInstance3 = new Affiliation__c( // survivor
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Composite_Key__c = 'Agency2'
        );

        // create a person 360 instance per affiliation
        Person360 person1 = new Person360( 
                                    new ContactMergePerson360.ContactMergePerson360Builder(contact1)
                                        .withAffiliation(affInstance1)
                                );
        Person360 person2 = new Person360(
                                    new ContactMergePerson360.ContactMergePerson360Builder(contact1)
                                        .withAffiliation(affInstance2)
                                );
        Person360 person3 = new Person360(
                                    new ContactMergePerson360.ContactMergePerson360Builder(contact1)
                                        .withAffiliation(affInstance3)
                                );

        ContactMergeP360Director director;

        Test.startTest();

        // WHEN
        director = new ContactMergeP360Director();
        director.resolveAffiliations(new List<Person360>{ person1, person2, person3 });

        Test.stopTest();

        // THEN

        ContactMergeBaseClass cmbc = (ContactMergeBaseClass) director.getBaseClass();

        Map<String, ContactMergeBaseClass.SObjectRegister> regMap = cmbc.extIdRegister.get(Affiliation__c.SObjectType);
        Assert.areEqual(2, regMap.size(), 'Unexpected number of surviving Affiliations');

        // validate that affInstance2 does not survive and that the class respects the order for survivorship
        ContactMergeBaseClass.SObjectRegister reg1 = regMap.get(affInstance1.Composite_Key__c);
        Assert.areEqual(affInstance1.Id, reg1.record.Id, 'Unexpected surviving record');

        ContactMergeBaseClass.SObjectRegister reg2 = regMap.get(affInstance3.Composite_Key__c);
        Assert.areEqual(affInstance3.Id, reg2.record.Id, 'Unexpected surviving record');
    }

    /**
     * Test Contact Point survivorship. The surviving record should have a unique Key_UID__c,
     * and the order by which the P360 instance was added should be respected to take precedence
     */
    @isTest
    static void shouldResolveContactPoints() {

        // GIVEN
        Email__c emailRec1 = new Email__c( // survivor
            Id = fflib_IDGenerator.generate(Email__c.SObjectType), 
            Key_UID__c = 'GreenEmail@gmail.com'
        );
        Email__c emailRec2 = new Email__c( // non-survivor
            Id = fflib_IDGenerator.generate(Email__c.SObjectType), 
            Key_UID__c = 'GreenEmail@gmail.com'
        );
        Email__c emailRec3 = new Email__c( // survivor
            Id = fflib_IDGenerator.generate(Email__c.SObjectType), 
            Key_UID__c = 'RedEmail@monash.edu'
        );
        Phone__c phoneRec1 = new Phone__c( // survivor
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType), 
            Key_UID__c = 'phoneKey1'
        );
        Phone__c phoneRec2 = new Phone__c( // non-survivor
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType), 
            Key_UID__c = 'phoneKey1'
        );
        Phone__c phoneRec3 = new Phone__c( // survivor
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType), 
            Key_UID__c = 'phoneKey2'
        );

        List<SObject> person1ContactPoints = new List<SObject>{ emailRec1, emailRec3, phoneRec1 };
        List<SObject> person2ContactPoints = new List<SObject>{ emailRec2, phoneRec2, phoneRec3 };

        // create a person 360 instance per affiliation
        Person360 person1 = new Person360(
                                    new ContactMergePerson360.ContactMergePerson360Builder(contact1)
                                        .withContactPoints(person1ContactPoints)
                                );
        Person360 person2 = new Person360(
                                new ContactMergePerson360.ContactMergePerson360Builder(contact1)
                                    .withContactPoints(person2ContactPoints)
                                );

        ContactMergeP360Director director;

        Test.startTest();

        // WHEN
        director = new ContactMergeP360Director();
        director.resolveContactPoints(new List<Person360>{ person1, person2 });

        Test.stopTest();

        // THEN
        ContactMergeBaseClass cmbc = (ContactMergeBaseClass) director.getBaseClass();
        Map<String, ContactMergeBaseClass.SObjectRegister> emailMap = cmbc.extIdRegister.get(Email__c.SObjectType);
        Map<String, ContactMergeBaseClass.SObjectRegister> phoneMap = cmbc.extIdRegister.get(Phone__c.SObjectType);
        // verify number of surviving records
        Assert.areEqual(2, emailMap.size(), 'Unexpected number of surviving Email records');
        Assert.areEqual(2, phoneMap.size(), 'Unexpected number of surviving Phone records');
        // verify surviving Emails
        Assert.areEqual(emailRec1.Id, emailMap.get(emailRec1.Key_UID__c).record.Id, 'Unexpected surviving record');
        Assert.areEqual(emailRec3.Id, emailMap.get(emailRec3.Key_UID__c).record.Id, 'Unexpected surviving record');
        // verify surviving Phones
        Assert.areEqual(phoneRec1.Id, phoneMap.get(phoneRec1.Key_UID__c).record.Id, 'Unexpected surviving record');
        Assert.areEqual(phoneRec3.Id, phoneMap.get(phoneRec3.Key_UID__c).record.Id, 'Unexpected surviving record');
    }

    /**
     * tests both resolveDependencies and resolveContactPointAffiliations
     * since resolveContactPointAffiliations is dependent on steps:
     *  1 - resolveAffiliations()
     *  2 - resolveContactPoints()
     * This is due to the chaching nature of the keys to resolve the reparenting
     */
    @isTest
    static void shouldResolveDependencies() {

        // GIVEN
        Affiliation__c affiliationAgency1 = new Affiliation__c( // survivor
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType), 
            Composite_Key__c = 'Agency1'
        );
        Affiliation__c affiliationAgencyDupe1 = new Affiliation__c( // non-survivor
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType), 
            Composite_Key__c = 'Agency1'
        );
        Affiliation__c affiliationAgency2 = new Affiliation__c( // survivor
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Composite_Key__c = 'Agency2'
        );

        // create emails
        Email__c greenEmail = new Email__c( // survivor
            Id = fflib_IDGenerator.generate(Email__c.SObjectType), 
            Key_UID__c = 'GreenEmail@gmail.com'
        );
        Email__c redEmail = new Email__c( // survivor
            Id = fflib_IDGenerator.generate(Email__c.SObjectType), 
            Key_UID__c = 'RedEmail@gmail.com'
        );
        Email__c yellowEmail = new Email__c( // survivor
            Id = fflib_IDGenerator.generate(Email__c.SObjectType), 
            Key_UID__c = 'YellowEmail@gmail.com'
        );

        // create phones
        Phone__c phoneRec1 = new Phone__c( // survivor
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType), 
            Key_UID__c = '0411111222'
        );
        Phone__c phoneRec2 = new Phone__c( // survivor
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType), 
            Key_UID__c = '039525000'
        );
        Phone__c phoneRec3 = new Phone__c( // survivor
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType), 
            Key_UID__c = '0411111444'
        );
        Phone__c phoneRec4 = new Phone__c( // survivor
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType), 
            Key_UID__c = '0411111555'
        );
        Phone__c phoneRec5 = new Phone__c( // survivor
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType), 
            Key_UID__c = '039525999'
        );

        // create addresses
        Address__c melbourne = new Address__c ( // survivor
            Id = fflib_IDGenerator.generate(Address__c.SObjectType),
            Key_UID__c = 'Melbourne'
        );
        Address__c sydney = new Address__c ( // survivor
            Id = fflib_IDGenerator.generate(Address__c.SObjectType),
            Key_UID__c = 'Sydney'
        );

        // agency1 => phoneRec1
        Contact_Point_Affiliation__c agency1Phone1 = new Contact_Point_Affiliation__c(); // survivor
        agency1Phone1 = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            agency1Phone1,
            Contact_Point_Affiliation__c.class,
            new Map<SObjectField, Object> {
                Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                Contact_Point_Affiliation__c.Type__c => 'Phone',
                Contact_Point_Affiliation__c.Affiliation__c => affiliationAgency1.Id,
                Contact_Point_Affiliation__c.Contact__c => contact1.Id,
                Contact_Point_Affiliation__c.Phone__c => phoneRec1.Id
            }
        );
        
        // agency1 => greenEmail
        Contact_Point_Affiliation__c agency1GreenEmail = new Contact_Point_Affiliation__c(); // survivor
        agency1GreenEmail = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            agency1GreenEmail,
            Contact_Point_Affiliation__c.class,
            new Map<SObjectField, Object> {
                Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                Contact_Point_Affiliation__c.Type__c => 'Email',
                Contact_Point_Affiliation__c.Affiliation__c => affiliationAgency1.Id,
                Contact_Point_Affiliation__c.Contact__c => contact1.Id,
                Contact_Point_Affiliation__c.Email__c => greenEmail.Id
            }
        );
        
        // duplicate agency 1 => phoneRec4
        Contact_Point_Affiliation__c agencyDupe1Phone4 = new Contact_Point_Affiliation__c(); // survivor; will become agency1 => phoneRec4
        agencyDupe1Phone4 = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            agencyDupe1Phone4,
            Contact_Point_Affiliation__c.class,
            new Map<SObjectField, Object> {
                Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                Contact_Point_Affiliation__c.Type__c => 'Phone',
                Contact_Point_Affiliation__c.Affiliation__c => affiliationAgencyDupe1.Id,
                Contact_Point_Affiliation__c.Contact__c => contact1.Id,
                Contact_Point_Affiliation__c.Phone__c => phoneRec4.Id
            }
        );
        
        // agency 2 => yellowEmail
        Contact_Point_Affiliation__c agency2YellowEmail = new Contact_Point_Affiliation__c(); // survivor
        agency2YellowEmail = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            agency2YellowEmail,
            Contact_Point_Affiliation__c.class,
            new Map<SObjectField, Object> {
                Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                Contact_Point_Affiliation__c.Type__c => 'Email',
                Contact_Point_Affiliation__c.Affiliation__c => affiliationAgency2.Id,
                Contact_Point_Affiliation__c.Contact__c => contact1.Id,
                Contact_Point_Affiliation__c.Email__c => yellowEmail.Id
            }
        );
        
        // agency 2 => melbourne
        Contact_Point_Affiliation__c agency2Melbourne = new Contact_Point_Affiliation__c(); // survivor
        agency2Melbourne = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            agency2Melbourne,
            Contact_Point_Affiliation__c.class,
            new Map<SObjectField, Object> {
                Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                Contact_Point_Affiliation__c.Type__c => 'Address',
                Contact_Point_Affiliation__c.Affiliation__c => affiliationAgency2.Id,
                Contact_Point_Affiliation__c.Contact__c => contact1.Id,
                Contact_Point_Affiliation__c.Address__c => melbourne.Id
            }
        );

        // create a person 360 instance per affiliation
        
        ContactMergePerson360.ContactMergePerson360Builder builder1 = new ContactMergePerson360.ContactMergePerson360Builder(contact1);
        builder1.withAffiliation(affiliationAgency1);
        builder1.withContactPoint(greenEmail)
            .withContactPoint(redEmail)
            .withContactPoint(phoneRec1)
            .withContactPoint(phoneRec2)
            .withContactPointAffiliation(agency1Phone1, 'Phone__c')
            .withContactPointAffiliation(agency1GreenEmail, 'Email__c');
        Person360 person1 = new Person360(builder1);

        ContactMergePerson360.ContactMergePerson360Builder builder2 = new ContactMergePerson360.ContactMergePerson360Builder(contact1);
        builder2.withAffiliation(affiliationAgencyDupe1);
        builder2.withContactPoint(yellowEmail)
            .withContactPoint(phoneRec3)
            .withContactPoint(phoneRec4)
            .withContactPoint(phoneRec5)
            .withContactPoint(melbourne)
            .withContactPoint(sydney)
            .withContactPointAffiliation(agencyDupe1Phone4, 'Phone__c');
        Person360 person2 = new Person360(builder2);

        ContactMergePerson360.ContactMergePerson360Builder builder3 = new ContactMergePerson360.ContactMergePerson360Builder(contact1);
        builder3.withAffiliation(affiliationAgency2);
        builder3.withContactPoint(yellowEmail)
            .withContactPoint(melbourne)
            .withContactPointAffiliation(agency2YellowEmail, 'Email__c')
            .withContactPointAffiliation(agency2Melbourne, 'Address__c');
        Person360 person3 = new Person360(builder3);

        ContactMergeP360Director director;

        Test.startTest();

        // WHEN
        director = new ContactMergeP360Director();
        director.resolveDependencies(new List<Person360>{ person1, person2, person3 });

        Test.stopTest();

        // THEN
        ContactMergeBaseClass cmbc = (ContactMergeBaseClass) director.getBaseClass();
        Map<String, ContactMergeBaseClass.SObjectRegister> affMap = cmbc.extIdRegister.get(Affiliation__c.SObjectType);
        Map<String, ContactMergeBaseClass.SObjectRegister> emailMap = cmbc.extIdRegister.get(Email__c.SObjectType);
        Map<String, ContactMergeBaseClass.SObjectRegister> phoneMap = cmbc.extIdRegister.get(Phone__c.SObjectType);
        Map<String, ContactMergeBaseClass.SObjectRegister> addressMap = cmbc.extIdRegister.get(Address__c.SObjectType);
        Map<String, ContactMergeBaseClass.SObjectRegister> cpaMap = cmbc.extIdRegister.get(Contact_Point_Affiliation__c.SObjectType);

        Assert.areEqual(2, affMap.size(), 'Unexpected number of surviving Affiliation');
        Assert.areEqual(3, emailMap.size(), 'Unexpected number of surviving Emails');
        Assert.areEqual(5, phoneMap.size(), 'Unexpected number of surviving Phones');
        Assert.areEqual(2, addressMap.size(), 'Unexpected number of surviving Phones');
        Assert.areEqual(5, cpaMap.size(), 'Unexpected number of surviving CPAs');

        for(String key : cpaMap.keySet()) {
            
            Contact_Point_Affiliation__c cpa = (Contact_Point_Affiliation__c) cpaMap.get(key).record;

            if(cpa.Id == agencyDupe1Phone4.Id) {
                Assert.areEqual(affiliationAgency1.Id, cpa.Affiliation__c, 'Unable to reparent CPA to the surviving affiliation');
            }
        }
    }

    /**
     * test that registerSObject should throw a developer exception when trying to resolve
     * dependencies and registering unique SObjects but haven't got a calculated external ID yet
     */
    @isTest
    static void shouldThrownAnExceptionWhenRegisteringSObjectWithNullExternalId() {
        // GIVEN
        Email__c emailRec = new Email__c(); // any contact point
        ContactMergeP360Director director = new ContactMergeP360Director();

        Test.startTest();
        
        // WHEN
        try {
            director.registerSObject(emailRec, null);
            Assert.fail('Unable to throw an exception when registering an SObject with null external ID');
        } catch(ContactMergeP360Director.ContactMergeP360DirectorDeveloperException e) {
            // THEN
            Assert.isTrue(true);
        }
    
        Test.stopTest();
    }

    /**
     * test that the calculatePrimaryContactPoints method calculates the primary
     * of unique contact points that were already registered in the baseclass.
     * This test stubs the ContactMergeBaseClass.pull() method to set up
     * the records to be recalculated
     */
    @isTest
    static void shouldCalculatePrimaryContactPoints() {

        // GIVEN

        // setup Email pull result
        Email__c email1 = new Email__c();
        email1 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email1,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => Date.today(),
                Email__c.CreatedDate => System.now(),
                Email__c.Classification__c => 'Monash',
                Email__c.Primary_set_by__c => 'autoproc',
                Email__c.Is_Primary__c => true
            }
        );
        
        // a (currently) non-primary business email but was set as primary by a user
        Email__c email2 = new Email__c();
        email2 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email2,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate,
                Email__c.Classification__c => 'Business',
                Email__c.Primary_set_by__c => 'user',
                Email__c.Is_Primary__c => false
            }
        );
        
        // add another email to the mix
        Email__c email3 = new Email__c();
        email3 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email3,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate,
                Email__c.Classification__c => 'Private',
                Email__c.Is_Primary__c => false
            }
        );

        // setup phone pull result

        // a mobile phone, this was the best primary yesterday
        Phone__c phone1 = new Phone__c();
        phone1 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone1,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Phone__c.Start_Date__c => Date.today().addDays(-1),
                Phone__c.CreatedDate => System.now(),
                Phone__c.Type__c => 'Mobile',
                Phone__c.Is_Primary__c => true
            }
        );
        
        // another mobile phone. not yet a primary, but was created today, so should be the new one
        Phone__c phone2 = new Phone__c();
        phone2 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone2,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Phone__c.Start_Date__c => Date.today(),
                Phone__c.CreatedDate => System.now(),
                Phone__c.Type__c => 'Mobile',
                Phone__c.Is_Primary__c => false
            }
        );
        
        // add another phone to the mix
        Phone__c phone3 = new Phone__c();
        phone3 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone3,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Phone__c.Start_Date__c => Date.today(),
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Landline',
                Phone__c.Is_Primary__c => false
            }
        );

        // a Monash address, which is typically the primary for students
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Address__c.Start_Date__c => Date.today(),
                Address__c.CreatedDate => System.now(),
                Address__c.Classification__c => 'Monash',
                Address__c.Primary_set_by__c => 'autoproc',
                Address__c.Is_Primary__c => true
            }
        );
        
        // a (currently) non-primary business address but was set as primary by a user
        Address__c address2 = new Address__c();
        address2 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address2,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Address__c.Start_Date__c => address1.Start_Date__c,
                Address__c.CreatedDate => address1.CreatedDate,
                Address__c.Classification__c => 'Business',
                Address__c.Primary_set_by__c => 'user',
                Address__c.Is_Primary__c => false
            }
        );
        
        // add another address to the mix
        Address__c address3 = new Address__c();
        address3 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address3,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Address__c.Start_Date__c => address1.Start_Date__c,
                Address__c.CreatedDate => address1.CreatedDate,
                Address__c.Classification__c => 'Private',
                Address__c.Is_Primary__c => false
            }
        );

        // This was the best primary yesterday
        Name__c name1 = new Name__c();
        name1 = (Name__c) fflib_ApexMocksUtils.setReadOnlyFields(
            name1,
            Name__c.class,
            new Map<SObjectField, Object> {
                Name__c.Id => fflib_IDGenerator.generate(Name__c.SObjectType),
                Name__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Name__c.Start_Date__c => Date.today().addDays(-1),
                Name__c.CreatedDate => System.now(),
                Name__c.Type__c => 'Common',
                Name__c.Is_Primary__c => true
            }
        );
        
        // Not yet a primary, but is a Student Name, so should be the new one
        Name__c name2 = new Name__c();
        name2 = (Name__c) fflib_ApexMocksUtils.setReadOnlyFields(
            name2,
            Name__c.class,
            new Map<SObjectField, Object> {
                Name__c.Id => fflib_IDGenerator.generate(Name__c.SObjectType),
                Name__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Name__c.Start_Date__c => Date.today(),
                Name__c.CreatedDate => System.now(),
                Name__c.Type__c => 'Student Name',
                Name__c.Is_Primary__c => false
            }
        );

        List<Email__c> emailPullResult = new List<Email__c> { email1, email2, email3 };
        List<Phone__c> phonePullResult = new List<Phone__c> { phone1, phone2, phone3 };
        List<Address__c> addressPullResult = new List<Address__c> { address1, address2, address3 };
        List<Name__c> namePullResult = new List<Name__c> { name1, name2 };
        
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ContactMergeBaseClass mockBc = (ContactMergeBaseClass) mocks.mock(ContactMergeBaseClass.class);

        mocks.startStubbing(); // stubbing start
        
        mocks.when(mockBc.pull(Phone__c.SObjectType)).thenReturn(phonePullResult);
        mocks.when(mockBc.pull(Email__c.SObjectType)).thenReturn(emailPullResult);
        mocks.when(mockBc.pull(Address__c.SObjectType)).thenReturn(addressPullResult);
        mocks.when(mockBc.pull(Name__c.SObjectType)).thenReturn(namePullResult);

        mocks.stopStubbing(); // stubbing end

        ContactMergeP360Director director = new ContactMergeP360Director(mockBc); // inject mock

        Test.startTest();

        // WHEN
        director.calculatePrimaryContactPoints(true);

        Test.stopTest();

        // THEN

        // EMAIL - user-override should be the new primary
        Assert.areEqual(true, email2.Is_Primary__c, 'Unable to set new primary'); 
        // PHONE - new mobile should be the new primary
        Assert.areEqual(true, phone2.Is_Primary__c, 'Unable to set new primary');
        // ADDRESS - user-override should be the new primary
        Assert.areEqual(true, address2.Is_Primary__c, 'Unable to set new primary'); 
        // Name - student name should be the new primary
        Assert.areEqual(true, name2.Is_Primary__c, 'Unable to set new primary'); 
    }
}