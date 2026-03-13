/**
 * @description       : Test class for ContactMergeBaseClass_Test
 * @author            : Nick Guia
 * @last modified on  : 15-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class ContactMergeBaseClass_Test {

    /**
     * @description test registering 2 records with unique keys.
     * The class should be able to map them correctly
     */
    @isTest
    static void shouldRegisterUniqueExternalId() {

        // GIVEN
        Affiliation__c rec1 = new Affiliation__c(
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Contact__c = fflib_IDGenerator.generate(Contact.SObjectType),
            Account__c = fflib_IDGenerator.generate(Account.SObjectType),
            Composite_Key__c = 'qwerty1' // can be anything unique
        );

        // let's try to break it
        Affiliation__c rec2 = new Affiliation__c(
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Contact__c = fflib_IDGenerator.generate(Contact.SObjectType),
            Account__c = fflib_IDGenerator.generate(Account.SObjectType),
            Composite_Key__c = 'qwerty2' // can be anything unique
        );

        ContactMergeBaseClass cmbc;

        Test.startTest();

        // WHEN
        cmbc = new ContactMergeBaseClass();
        cmbc.registerRecord(rec1, rec1.Composite_Key__c);
        cmbc.registerRecord(rec2, rec2.Composite_Key__c);

        Test.stopTest();

        // THEN
        Assert.isTrue(cmbc.extIdRegister.containsKey(Affiliation__c.SObjectType), 'Unable to register record');

        Map<String, ContactMergeBaseClass.SObjectRegister> regMap = cmbc.extIdRegister.get(Affiliation__c.SObjectType);
        Assert.isTrue(regMap.containsKey(rec1.Composite_Key__c), 'Unable to register record');

        ContactMergeBaseClass.SObjectRegister reg1 = regMap.get(rec1.Composite_Key__c);
        Assert.areEqual(rec1.Id, reg1.record.Id, 'Wrong record mapped against the unique key');

        ContactMergeBaseClass.SObjectRegister reg2 = regMap.get(rec2.Composite_Key__c);
        Assert.areEqual(rec2.Id, reg2.record.Id, 'Wrong record mapped against the unique key');
    }

    /**
     * @description ensures that the base class pops (soft deletes) the registered duplicate record
     */
    @isTest
    static void shouldPopDuplicateKeys() {

        // GIVEN
        Affiliation__c rec1 = new Affiliation__c(
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Contact__c = fflib_IDGenerator.generate(Contact.SObjectType),
            Account__c = fflib_IDGenerator.generate(Account.SObjectType),
            Start_Date__c = Date.today(),
            Composite_Key__c = 'qwerty1' // can be anything unique
        );

        // let's try to break it
        Affiliation__c rec2 = new Affiliation__c(
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Contact__c = fflib_IDGenerator.generate(Contact.SObjectType),
            Account__c = fflib_IDGenerator.generate(Account.SObjectType),
            Start_Date__c = Date.today(),
            Composite_Key__c = 'qwerty1' // should be a duplicate key
        );

        ContactMergeBaseClass cmbc = new ContactMergeBaseClass().deleteDuplicateOnRegister(true);
        cmbc.registerRecord(rec1, rec1.Composite_Key__c);

        Test.startTest();

        // WHEN
        cmbc.registerRecord(rec2, rec2.Composite_Key__c);

        Test.stopTest();

        // THEN
        Map<String, ContactMergeBaseClass.SObjectRegister> regMap = cmbc.extIdRegister.get(Affiliation__c.SObjectType);

        ContactMergeBaseClass.SObjectRegister reg1 = regMap.get(rec1.Composite_Key__c);
        Assert.areEqual(rec1.Id, reg1.record.Id, 'Unable to retain first registered record');

        ContactMergeBaseClass.SObjectRegister reg2 = regMap.get(rec2.Composite_Key__c);
        Assert.areNotEqual(rec2.Id, reg2.record.Id, 'Unable to pop duplicate record');
    }

    /**
     * @description ensures that the base class first merges the field values of the duplicate record before popping
     */
    @isTest
    static void shouldMergeFieldsOfDuplicateAffiliations() {

        // GIVEN
        Affiliation__c rec1 = new Affiliation__c(
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Contact__c = fflib_IDGenerator.generate(Contact.SObjectType),
            Account__c = fflib_IDGenerator.generate(Account.SObjectType),
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(5), // losing field
            Composite_Key__c = 'qwerty1' // can be anything unique
        );

        // let's try to break it
        Affiliation__c rec2 = new Affiliation__c(
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Contact__c = fflib_IDGenerator.generate(Contact.SObjectType),
            Account__c = fflib_IDGenerator.generate(Account.SObjectType),
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(10), // surviving field
            Composite_Key__c = 'qwerty1' // should be a duplicate key
        );

        ContactMergeBaseClass cmbc = new ContactMergeBaseClass().deleteDuplicateOnRegister(true);
        cmbc.registerRecord(rec1, rec1.Composite_Key__c);

        Test.startTest();

        // WHEN
        cmbc.registerRecord(rec2, rec2.Composite_Key__c);

        Test.stopTest();

        // THEN
        Map<String, ContactMergeBaseClass.SObjectRegister> regMap = cmbc.extIdRegister.get(Affiliation__c.SObjectType);

        ContactMergeBaseClass.SObjectRegister reg1 = regMap.get(rec1.Composite_Key__c);
        Assert.areEqual(rec1.Id, reg1.record.Id, 'Unable to retain first registered record');
        Assert.areEqual(rec2.End_Date__c, (Date) reg1.record.get('End_Date__c'), 'Unable to merge Affiliation fields');

        ContactMergeBaseClass.SObjectRegister reg2 = regMap.get(rec2.Composite_Key__c);
        Assert.areNotEqual(rec2.Id, reg2.record.Id, 'Unable to pop duplicate record');
    }

    /**
     * @description ensures that the base class pulls (retrieves) the registered record
     */
    @isTest
    static void shouldPullRecordByKey() {

        /// GIVEN
        Affiliation__c rec1 = new Affiliation__c(
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Contact__c = fflib_IDGenerator.generate(Contact.SObjectType),
            Account__c = fflib_IDGenerator.generate(Account.SObjectType),
            Composite_Key__c = 'qwerty1' // can be anything unique
        );
        ContactMergeBaseClass cmbc = new ContactMergeBaseClass();
        cmbc.registerRecord(rec1, rec1.Composite_Key__c);

        SObject pullResult;

        Test.startTest();

        // WHEN
        pullResult = cmbc.pull(Affiliation__c.SObjectType, rec1.Composite_Key__c);

        Test.stopTest();

        // THEN
        Assert.isNotNull(pullResult, 'Unable to pull registered record');
    }

    /**
     * @description ensures that the class throws an Exception when provided with a null external ID
     */
    @isTest
    static void shouldThrowADeveloperExceptionWithNullExternalId() {
        
        /// GIVEN
        Affiliation__c rec1 = new Affiliation__c(
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Contact__c = fflib_IDGenerator.generate(Contact.SObjectType),
            Account__c = fflib_IDGenerator.generate(Account.SObjectType),
            Composite_Key__c = 'qwerty1' // can be anything unique
        );

        ContactMergeBaseClass cmbc = new ContactMergeBaseClass();

        Test.startTest();

        // WHEN
        try {
            cmbc.registerRecord(rec1, null);
            Assert.fail('Uncaught Exception on null external ID');
        } catch(ContactMergeBaseClass.ContactMergeBaseClassDeveloperException e) {
            // THEN
            Assert.isTrue(true); // expected
        } catch(Exception e) {
            Assert.fail('Uncaught Exception on null external ID : '+ e.getMessage());
        }

        Test.stopTest();
    }

    /**
     * test if you are able to pull (unique) records that were stored in the registry
     * using a unique external ID
     */
    @isTest
    static void shouldPullSObjectByExternalId() {
        // GIVEN
        ContactMergeBaseClass cmbc = new ContactMergeBaseClass();
        String extId = 'anyExternalIdUnique';
        Phone__c rec = new Phone__c(Id = fflib_IDGenerator.generate(Phone__c.SObjectType));
        ContactMergeBaseClass.SObjectRegister reg = new ContactMergeBaseClass.SObjectRegister(rec, extId);

        cmbc.extIdRegister.put(
            Phone__c.SObjectType,
            new Map<String, ContactMergeBaseClass.SObjectRegister> { extId => reg }
        );
        Phone__c pullResult;

        Test.startTest();

        // WHEN
        pullResult = (Phone__c) cmbc.pull(Phone__c.SObjectType, extId);

        Test.stopTest();

        // THEN
        Assert.areEqual(rec.Id, pullResult.Id, 'Unable to pull the right record using external Id');
    }

    /**
     * test if you are able to pull records of the same SObject Type that were stored in the registry
     */
    @isTest
    static void shouldPullSObjectListBySObjectType() {
        // GIVEN
        ContactMergeBaseClass cmbc = new ContactMergeBaseClass();

        String extId1 = 'anyExternalIdUnique1';
        Phone__c rec1 = new Phone__c(Id = fflib_IDGenerator.generate(Phone__c.SObjectType));
        ContactMergeBaseClass.SObjectRegister reg1 = new ContactMergeBaseClass.SObjectRegister(rec1, extId1);

        String extId2 = 'anyExternalIdUnique2';
        Phone__c rec2 = new Phone__c(Id = fflib_IDGenerator.generate(Phone__c.SObjectType));
        ContactMergeBaseClass.SObjectRegister reg2 = new ContactMergeBaseClass.SObjectRegister(rec2, extId2);

        cmbc.extIdRegister.put(
            Phone__c.SObjectType,
            new Map<String, ContactMergeBaseClass.SObjectRegister> { extId1 => reg1,  extId2 => reg2 }
        );

        List<Phone__c> pullResult;

        Test.startTest();

        // WHEN
        pullResult = (List<Phone__c>) cmbc.pull(Phone__c.SObjectType);

        Test.stopTest();

        // THEN
        Assert.areEqual(2, pullResult.size(), 'Invalid number of records in the registry');
    }
}