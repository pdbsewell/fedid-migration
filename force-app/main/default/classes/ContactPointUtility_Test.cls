/**
 * @description       : Test class for ContactPointUtility
 * @author            : Nick Guia
 * @last modified on  : 19-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class ContactPointUtility_Test {

    /**
    * @description Should get the lookup Id of the related contact point of a CPA
    *   based on the Type. This assumes that the right lookup field is populated based
    *   on the CPA's Type__c field.
    * @author Nick Guia | 13-07-2023 
    **/
    @isTest
    static void shouldGetContactPointIdFromSupportedCPA() {

        // GIVEN
        Id mockAddressId = fflib_IDGenerator.generate(Address__c.SObjectType);
        Contact_Point_Affiliation__c cpa = new Contact_Point_Affiliation__c();

        // mock read-only fields
        cpa = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
                cpa,
				Contact_Point_Affiliation__c.class,
				new Map<SObjectField, Object>{
                    Contact_Point_Affiliation__c.Type__c => 'Address',
                    Contact_Point_Affiliation__c.Address__c => mockAddressId
                }
		);
        
        Id resultCPId;

        Test.startTest();

        // WHEN
        resultCPId = ContactPointUtility.getContactPointIdFromCPA(cpa);

        Test.stopTest();

        // THEN
        Assert.areEqual(mockAddressId, resultCPId, 'Unexpected Contact Point ID');
    }

    /**
    * @description test if a ContactPointUtility.ContactPointUtilityException is thrown
    *   when the utility method receives an unrecognised Type.
    * @author Nick Guia | 13-07-2023 
    **/
    @isTest
    static void shouldThrowAnErrorWhenGetContactPointIdWithUnsupportedSObject() {

        // GIVEN
        Id mockAddressId = fflib_IDGenerator.generate(Address__c.SObjectType);
        Contact_Point_Affiliation__c cpa = new Contact_Point_Affiliation__c();

        // mock read-only fields
        cpa = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
                cpa,
				Contact_Point_Affiliation__c.class,
				new Map<SObjectField, Object>{
                    Contact_Point_Affiliation__c.Type__c => 'Invalid',
                    Contact_Point_Affiliation__c.Address__c => mockAddressId
                }
		);
        
        Id resultCPId;

        Test.startTest();

        // WHEN
        try {
            resultCPId = ContactPointUtility.getContactPointIdFromCPA(cpa);
            Assert.fail('Expected to throw an error with invalid CPA type');
        } catch(ContactPointUtility.ContactPointUtilityException utilEx) {
            // THEN
            Assert.isTrue(true);
        } catch(Exception ex) {
            Assert.fail('Caught an unexpected exception type');
        }
        
        Test.stopTest();
    }

    /**
    * @description test if getContactPointSObjectKey is able to return the 
    *   expected set of Keys.
    * @author Nick Guia | 13-07-2023 
    **/
    @isTest
    static void shouldReturnSObjectKeySet() {

        // GIVEN
        Id mockContactId = fflib_IDGenerator.generate(Contact.SObjectType);
        Address__c cp = new Address__c();
        cp.Contact__c = mockContactId;
        cp.Street_Name__c = 'Collins St';
        cp.City__c = 'Melbourne';
        cp.State__c = 'VIC';
        cp.Post_Code__c = '3000';
        cp.Country2__c = 'Australia';
        
        SObject sObjIns = cp; // convert to an sobject just for lesser ambiguity

        Set<String> cpKeySet;

        Test.startTest();

        // WHEN
        cpKeySet = ContactPointUtility.getContactPointSObjectKey(sObjIns);

        Test.stopTest();

        // THEN
        Assert.isTrue(cpKeySet.contains(String.valueOf(cp.Contact__c).toLowerCase()), 'Expected Contact__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(sanitizeAddressKey(cp.Street_Name__c)),'Expected Street_Name__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(sanitizeAddressKey(cp.City__c)), 'Expected City__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(sanitizeAddressKey(cp.State__c)), 'Expected State__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(sanitizeAddressKey(cp.Post_Code__c)), 'Expected Post_Code__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(sanitizeAddressKey(cp.Country2__c)), 'Expected Country2__c to be part of the key');
    }

    /**
    * @description test if the method returns the expected keyset for Phone__c
    * @author Nick Guia | 13-07-2023 
    **/
    @isTest
    static void shouldReturnPhoneKeySet() {

        // GIVEN
        Id mockContactId = fflib_IDGenerator.generate(Contact.SObjectType);
        Phone__c cp = new Phone__c();
        cp.Contact__c = mockContactId;
        cp.Type__c = 'Mobile';
        cp.Name = '+61 497000000';

        Set<String> cpKeySet;

        Test.startTest();

        // WHEN
        cpKeySet = ContactPointUtility.getContactPointKey(cp);

        Test.stopTest();

        // THEN
        Assert.isTrue(cpKeySet.contains(cp.Contact__c), 'Expected Contact__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(cp.Type__c), 'Expected Type__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(cp.Name.replaceAll('[^0-9]','')), 'Expected Name to be part of the key');

        // interim test - make sure hash key is the same as current state
        // once the trigger handler keyset generation has been migrated to the new utility class, this can be removed
        String utilityHash = Person360Helper.generatePerson360Key(cpKeySet);
        new PhoneTriggerHandler.PopulateHash().process(cp);
        String handlerHash = cp.Key_UID__c;
        Assert.areEqual(handlerHash, utilityHash, 'New hash does not match the current state!');
    }

    /**
    * @description test if the method returns the expected keyset for Email__c
    * @author Nick Guia | 13-07-2023 
    **/
    @isTest
    static void shouldReturnEmailKeySet() {

        // GIVEN
        Id mockContactId = fflib_IDGenerator.generate(Contact.SObjectType);
        Email__c cp = new Email__c();
        cp.Contact__c = mockContactId;
        cp.Name = 'test.test@monash.edu';

        Set<String> cpKeySet;

        Test.startTest();

        // WHEN
        cpKeySet = ContactPointUtility.getContactPointKey(cp);

        Test.stopTest();

        // THEN
        Assert.isTrue(cpKeySet.contains(cp.Contact__c), 'Expected Contact__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(cp.Name), 'Expected Name to be part of the key');

        // interim test - make sure hash key is the same as current state
        // once the trigger handler keyset generation has been migrated to the new utility class, this can be removed
        String utilityHash = Person360Helper.generatePerson360Key(cpKeySet);
        new EmailTriggerHandler.PopulateHash().process(cp);
        String handlerHash = cp.Key_UID__c;
        Assert.areEqual(handlerHash, utilityHash, 'New hash does not match the current state!');
    }

    /**
    * @description test if the method returns the expected keyset for Name__c
    * @author Nick Guia | 13-07-2023 
    **/
    @isTest
    static void shouldReturnNameKeySet() {

        // GIVEN
        Id mockContactId = fflib_IDGenerator.generate(Contact.SObjectType);
        Name__c cp = new Name__c();
        cp.Contact__c = mockContactId;

        cp.Salutation__c = 'Mr';
        cp.Prefix__c = 'Brother';
        cp.First_Name__c = 'Contact';
        cp.Middle_Name__c = 'Point';
        cp.Last_Name__c = 'Utility';
        cp.Suffix__c = 'Jr';
        // type should be null

        String defaultType = (String) Schema.Name__c.Type__c.getDescribe().getDefaultValue();
        String fullName = NameServices.generateFullName(cp);
		cp.Type__c = defaultType;
        
        Set<String> cpKeySet;

        Test.startTest();

        // WHEN
        cpKeySet = ContactPointUtility.getContactPointKey(cp);
        String nameUID = NameServices.generateKeyUID(cp);

        Test.stopTest();

        // THEN
        Assert.isTrue(cpKeySet.contains(cp.Contact__c), 'Expected Contact__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(defaultType.toLowercase()), 'Expected Type__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(fullName.toLowercase()), 'Expected Full Name to be part of the key');

        // interim test - make sure hash key is the same as current state
        // once the trigger handler keyset generation has been migrated to the new utility class, this can be removed
        String utilityHash = Person360Helper.generatePerson360Key(cpKeySet);
        new NameTriggerHandler.PopulateHash().process(cp);

        String handlerHash = cp.Key_UID__c;
        Assert.areEqual(handlerHash, utilityHash, 'New hash does not match the current state!');
        Assert.areEqual(handlerHash, nameUID, 'Hash key generated using NameServices should match CPA result');
    }

    /**
    * @description test if the method returns the expected keyset for Address__c
    * @author Nick Guia | 13-07-2023 
    **/
    @isTest
    static void shouldReturnAddressKeySet() {

        // GIVEN
        Id mockContactId = fflib_IDGenerator.generate(Contact.SObjectType);
        Address__c cp = new Address__c();
        cp.Contact__c = mockContactId;
        cp.Street_Name__c = 'Collins St';
        cp.City__c = 'Melbourne';
        cp.State__c = 'VIC';
        cp.Post_Code__c = '3000';
        cp.Country2__c = 'Australia';

        Set<String> cpKeySet;

        Test.startTest();

        // WHEN
        cpKeySet = ContactPointUtility.getContactPointKey(cp);

        Test.stopTest();

        // THEN
        Assert.isTrue(cpKeySet.contains(String.valueOf(cp.Contact__c).toLowerCase()), 'Expected Contact__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(sanitizeAddressKey(cp.Street_Name__c)),'Expected Street_Name__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(sanitizeAddressKey(cp.City__c)), 'Expected City__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(sanitizeAddressKey(cp.State__c)), 'Expected State__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(sanitizeAddressKey(cp.Post_Code__c)), 'Expected Post_Code__c to be part of the key');
        Assert.isTrue(cpKeySet.contains(sanitizeAddressKey(cp.Country2__c)), 'Expected Country2__c to be part of the key');

        // interim test - make sure hash key is the same as current state
        // once the trigger handler keyset generation has been migrated to the new utility class, this can be removed
        String utilityHash = Person360Helper.generatePerson360Key(cpKeySet);
        new AddressTriggerHandler.PopulateHash().process(cp);
        String handlerHash = cp.Key_UID__c;
        Assert.areEqual(handlerHash, utilityHash, 'New hash does not match the current state!');
    }

    private static String sanitizeAddressKey(String inpStr) {
        return inpStr?.toLowerCase().replaceAll('[^a-zA-Z0-9]','');
    }

    /**
    * @description test if the method returns the expected Composite Key for Affiliation__c :
    *   Contact ID + Account ID + RecordTypeId
    * @author Nick Guia | 20-07-2023 
    **/
    @isTest
    static void shouldReturnAffiliationCompositeKey() {
        // GIVEN
        Affiliation__c rec = new Affiliation__c();
        rec.Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType);
        rec.Account__c = fflib_IDGenerator.generate(Account.SObjectType);
        rec.Contact__c = fflib_IDGenerator.generate(Contact.SObjectType);
        rec.RecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByDeveloperName()
                            .get('Applicant')
                            .getRecordTypeId();

        String expectedKey = ''+rec.Contact__c+rec.Account__c+rec.RecordTypeId;
        String key;

        Test.startTest();

        // WHEN
        key = ContactPointUtility.getAffiliationKey(rec);

        Test.stopTest();

        // THEN
        Assert.areEqual(expectedKey, key, 'Unexpected Composite Key from Affiliation');
    }

    /**
    * @description test if the method returns the expected Sharing Composite Key for Affiliation__c :
    *   Contact ID + Account ID
    * @author Nick Guia | 20-07-2023 
    **/
    @isTest
    static void shouldReturnAffiliationSharingKey() {
        // GIVEN
        Affiliation__c rec = new Affiliation__c();
        rec.Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType);
        rec.Account__c = fflib_IDGenerator.generate(Account.SObjectType);
        rec.Contact__c = fflib_IDGenerator.generate(Contact.SObjectType);
        rec.RecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByDeveloperName()
                            .get('Applicant')
                            .getRecordTypeId();

        String expectedKey = ''+rec.Contact__c+rec.Account__c;
        String key;

        Test.startTest();

        // WHEN
        key = ContactPointUtility.getAffiliationSharingKey(rec);

        Test.stopTest();

        // THEN
        Assert.areEqual(expectedKey, key, 'Unexpected Sharing Composite Key from Affiliation');
    }

    /**
    * @description test if the method returns the expected keyset for Contact_Point_Affiliation__c
    * @author Nick Guia | 20-07-2023 
    **/
    @isTest
    static void shouldReturnCPAKey() {
        // GIVEN
        Contact_Point_Affiliation__c rec = new Contact_Point_Affiliation__c();
        rec = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
                rec,
				Contact_Point_Affiliation__c.class,
				new Map<SObjectField, Object>{
                    Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                    Contact_Point_Affiliation__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                    Contact_Point_Affiliation__c.Affiliation__c => fflib_IDGenerator.generate(Affiliation__c.SObjectType),
                    Contact_Point_Affiliation__c.Type__c => 'Email',
                    Contact_Point_Affiliation__c.Email__c => fflib_IDGenerator.generate(Email__c.SObjectType)

                }
		);

        String key;

        Test.startTest();

        // WHEN
        key = ContactPointUtility.getContactPointAffiliationKey(rec);

        Test.stopTest();

        // THEN
        Assert.isTrue(key.contains(rec.Affiliation__c), 'Expected Contact__c to be part of the key');
        Assert.isTrue(key.contains(rec.Email__c), 'Expected Email__c to be part of the key');
    }

    /**
    * @description test if the method returns the related contact point lookup Id from CPA
    * @author Nick Guia | 20-07-2023 
    **/
    @isTest
    static void shouldReturnRelatedEmailAPINameFromCPA() {
        // GIVEN
        Contact_Point_Affiliation__c rec = new Contact_Point_Affiliation__c();
        rec = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
                rec,
				Contact_Point_Affiliation__c.class,
				new Map<SObjectField, Object>{
                    Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                    Contact_Point_Affiliation__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                    Contact_Point_Affiliation__c.Affiliation__c => fflib_IDGenerator.generate(Affiliation__c.SObjectType),
                    Contact_Point_Affiliation__c.Type__c => 'Email',
                    Contact_Point_Affiliation__c.Email__c => fflib_IDGenerator.generate(Email__c.SObjectType)

                }
		);

        String contactPointField;

        Test.startTest();

        // WHEN
        contactPointField = ContactPointUtility.getContactPointLookupFieldFromCPA(rec);

        Test.stopTest();

        // THEN
        Assert.areEqual('Email__c', contactPointField, 'Unexpected contact point field API name returned by the Utility class');
    }

    /**
    * @description test if the method returns the related contact point lookup Id from CPA
    * @author Nick Guia | 20-07-2023 
    **/
    @isTest
    static void shouldReturnRelatedPhoneAPINameFromCPA() {
        // GIVEN
        Contact_Point_Affiliation__c rec = new Contact_Point_Affiliation__c();
        rec = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
                rec,
				Contact_Point_Affiliation__c.class,
				new Map<SObjectField, Object>{
                    Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                    Contact_Point_Affiliation__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                    Contact_Point_Affiliation__c.Affiliation__c => fflib_IDGenerator.generate(Affiliation__c.SObjectType),
                    Contact_Point_Affiliation__c.Type__c => 'Phone',
                    Contact_Point_Affiliation__c.Phone__c => fflib_IDGenerator.generate(Phone__c.SObjectType)

                }
		);

        String contactPointField;

        Test.startTest();

        // WHEN
        contactPointField = ContactPointUtility.getContactPointLookupFieldFromCPA(rec);

        Test.stopTest();

        // THEN
        Assert.areEqual('Phone__c', contactPointField, 'Unexpected contact point field API name returned by the Utility class');
    }
}