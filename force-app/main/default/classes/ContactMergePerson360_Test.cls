/**
 * @description       : Test class for ContactMergePerson360
 * @author            : Nick Guia
 * @last modified on  : 14-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class ContactMergePerson360_Test {

    private static Contact con;

    static {
        con = new Contact(
            Id = fflib_IDGenerator.generate(Contact.SObjectType),
            FirstName = 'ContactMerge', 
            LastName = 'Person360_Test',
            Is_Student__c = true
        );
    }

    
    /**
    * @description should set a specific Affiliation record type to merge
    * @author Nick Guia | 17-07-2023 
    **/
    @isTest
    static void shouldSetAffiliationRecordType() {

        // GIVEN
        String affiliationRecType = 'Applicant';
        ContactMergePerson360 contactMerge;

        Test.startTest();

        // WHEN
        contactMerge = new ContactMergePerson360(con.Id).byAffiliation(affiliationRecType);

        Test.stopTest();

        // THEN
        Assert.areEqual(affiliationRecType, contactMerge.affRecType, 'Unable to set target Affiliation record type!');

    }

    /**
    * @description should set shouldRecalculatePrimary
    **/
    @isTest
    static void shouldSetRecalculatePrimary() {

        // GIVEN
        Boolean shouldRecalculatePrimary = false;
        ContactMergePerson360 contactMerge;

        Test.startTest();

        // WHEN
        contactMerge = new ContactMergePerson360(con.Id).recalculatePrimaryContactPoints(shouldRecalculatePrimary);

        Test.stopTest();

        // THEN
        Assert.areEqual(shouldRecalculatePrimary, contactMerge.shouldRecalculatePrimary, 'Unable to set shouldRecalculatePrimary');

    }

    /**
    * @description
    *   - Test if the method is able to generate a map of contact ID => ContactMergePerson360DAO
    *   - each ContactMergePerson360DAO instance should contain all the Person360 records related to the contact
    *   - Stub the selector class and mock the IDs.
    *   - The ContactMergeP360 class attributes should match the size of the mocked results
    * @author Nick Guia | 17-07-2023 
    **/
    @isTest
    static void shouldBuildDAOMap() {

        // GIVEN

        // create a p360 instance
        Person360TestDataFactory factory = new Person360TestDataFactory(true);
        Person360 p360 = factory.createPerson360(con);
        
        // mock the selector class
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ContactMergeSelector mockContactMergeSelector = (ContactMergeSelector) mocks.mock(ContactMergeSelector.class);
        
        // result maps
        Map<Id, Contact> contactMap = new Map<Id, Contact> { con.Id => con };
        String affRecType = null;
        Map<Id, List<Affiliation__c>> affiliationsByContactId = new Map<Id, List<Affiliation__c>> { 
                con.Id => new List<Affiliation__c>{ p360.affRec } 
            };
        Map<Id, List<Name__c>> namesByContactId = new Map<Id, List<Name__c>> {
                con.Id => (List<Name__c>) p360.contactPointMap.get('Name__c')
            };
        Map<Id, List<Phone__c>> phonesByContactId = new Map<Id, List<Phone__c>> {
                con.Id => (List<Phone__c>) p360.contactPointMap.get('Phone__c')
            };
        Map<Id, List<Address__c>> addressesByContactId = new Map<Id, List<Address__c>> {
                con.Id => (List<Address__c>) p360.contactPointMap.get('Address__c')
            };
        Map<Id, List<Email__c>> emailByContactId = new Map<Id, List<Email__c>> {
                con.Id => (List<Email__c>) p360.contactPointMap.get('Email__c')
            };

        List<Contact_Point_Affiliation__c> cpaList = new List<Contact_Point_Affiliation__c>();
        // collect all CPAs per type
        for(String key : p360.cpaMap.keySet()) {
            cpaList.addAll(p360.cpaMap.get(key));
        }
        Map<Id, List<Contact_Point_Affiliation__c>> cpaByContactId =
            new Map<Id, List<Contact_Point_Affiliation__c>> { con.Id => cpaList };

        mocks.startStubbing(); // stubbing start

        mocks.when(mockContactMergeSelector.selectContacts()).thenReturn(contactMap);
        mocks.when(mockContactMergeSelector.selectAffiliationsGroupedByContactId(affRecType)).thenReturn(affiliationsByContactId);
        mocks.when(mockContactMergeSelector.selectNamesGroupedByContactId()).thenReturn(namesByContactId);
        mocks.when(mockContactMergeSelector.selectPhonesGroupedByContactId()).thenReturn(phonesByContactId);
        mocks.when(mockContactMergeSelector.selectAddressesGroupedByContactId()).thenReturn(addressesByContactId);
        mocks.when(mockContactMergeSelector.selectEmailsGroupedByContactId()).thenReturn(emailByContactId);
        mocks.when(mockContactMergeSelector.selectCPAsGroupedByContactId()).thenReturn(cpaByContactId);

        mocks.stopStubbing(); // stubbing end

        ContactMergePerson360 contactMerge = new ContactMergePerson360(new Set<Id> { con.Id }, mockContactMergeSelector, new ContactMergeP360Director());
        Map<Id, ContactMergePerson360.ContactMergePerson360DAO> daoMap;

        Test.startTest();

        // WHEN
        daoMap = contactMerge.buildDAOMap();

        Test.stopTest();

        // THEN

        // let's unpick the resulting structure of the DAO and make sure they're right
        Assert.isNotNull(daoMap, 'Unexpected null result from buildDAOMap()');
        Assert.areEqual(1, daoMap.size(), 'Unexpected number of contact IDs in the resulting DAO map');
        Assert.isTrue(daoMap.containsKey(con.Id), 'Set up contact not found in DAO map');

        ContactMergePerson360.ContactMergePerson360DAO dao = daoMap.get(con.Id);
        Assert.areEqual(affiliationsByContactId.get(con.Id).size(), dao.affiliationMap.size(), 'Unexpected number of affiliations stored in DAO');
        Assert.areEqual(namesByContactId.get(con.Id).size(), dao.contactPointMap.get('Name__c').size(), 'Unexpected number of Names stored in DAO');
        Assert.areEqual(phonesByContactId.get(con.Id).size(), dao.contactPointMap.get('Phone__c').size(), 'Unexpected number of Phones stored in DAO');
        Assert.areEqual(addressesByContactId.get(con.Id).size(), dao.contactPointMap.get('Address__c').size(), 'Unexpected number of Addresses stored in DAO');
        Assert.areEqual(emailByContactId.get(con.Id).size(), dao.contactPointMap.get('Email__c').size(), 'Unexpected number of Emails stored in DAO');
        Assert.areEqual(cpaList.size(), dao.cpaMapByAffiliationId.get(p360.affRec.Id).size(), 'Unexpected number of CPAs stored in DAO');
        Assert.areEqual(0, dao.p360List.size(), 'Unexpected number of P360 instances stored in DAO');
    }

    /**
    * @description test the generation P360 instances.
    *   The test will generate mock records for the P360, then we'll verify
    *   if the generated instance has the right structure and expected data.
    * @author Nick Guia | 17-07-2023 
    **/
    @isTest
    static void shouldBuildPerson360ListForDAO() {

        // GIVEN

        // create a ContactMergePerson360DAO without a List<Person360>
        String affiliationRecType = 'Applicant';
        Person360TestDataFactory factory = new Person360TestDataFactory(true);
        Person360 p360 = factory.createPerson360(con);
        
        Map<Id, Affiliation__c> affiliationResultMap = new Map<Id, Affiliation__c>{ p360.affRec.Id => p360.affRec };
        List<Contact_Point_Affiliation__c> cpaList = new List<Contact_Point_Affiliation__c>();
        for(List<Contact_Point_Affiliation__c> iCpaList : p360.cpaMap.values()) {
            cpaList.addAll(iCpaList);
        }

        Map<Id, List<Contact_Point_Affiliation__c>> cpaMapByAffiliationId = new Map<Id, List<Contact_Point_Affiliation__c>>{
            p360.affRec.Id => cpaList
        };

        ContactMergePerson360.ContactMergePerson360DAO dao = new ContactMergePerson360.ContactMergePerson360DAO(con.Id);
        dao.affiliationMap = affiliationResultMap;
        dao.contactPointMap = p360.contactPointMap;
        dao.cpaMapByAffiliationId = cpaMapByAffiliationId;
        
        ContactMergePerson360 contactMergeP360 = new ContactMergePerson360(p360.getContact().Id).byAffiliation(affiliationRecType);
        contactMergeP360.conMergeP360ByContactId.put(con.Id, dao);

        Map<Id, ContactMergePerson360.ContactMergePerson360DAO> daoMap;

        Test.startTest();

        // WHEN
        daoMap = contactMergeP360.buildPerson360ListForDAO(); // this will generate a List<Person360> within the DAO

        Test.stopTest();

        // THEN

        // verify the results
        Assert.isNotNull(daoMap, 'Unexpected null result from buildPerson360ListForDAO()');
        Assert.areEqual(1, daoMap.size(), 'Unexpected number of DAO instances');
        Assert.isTrue(daoMap.containsKey(con.Id));

        ContactMergePerson360.ContactMergePerson360DAO resultDAO = daoMap.get(con.Id);

        // the builder class auto generates +1 P360 instance by default to cater for scenarios
        // where the contact doesn't have any affiliations
        Assert.areEqual(2, resultDAO.p360List.size(), 'Unexpected number of Person 360 instances found!');
        
        // since the related processes are reliant on List ordering, assert them here
        // contactMergeP360List[0] is the (default) auto-created P360 without an afiiliation
        Person360 resultP360 = resultDAO.p360List[1];

        // affiliations
        Assert.areEqual(p360.affRec.Id, resultP360.affRec.Id, 'Unexpected Affiliation record found');
        // CPAs
        Assert.areEqual(p360.cpaMap.size()-1, resultP360.cpaMap.size(), 'Unexpected number of CPA records'); // minus Name contact point
        // Contact Points
        Assert.areEqual(p360.contactPointMap.size(), resultP360.contactPointMap.size(), 'Unexpected number of Contact Point records');
    }

    /**
     * test that buildContactMergeP360DAO would instantiate an instance of ContactMergePerson360DAO
     * for each contact ID
     */
    @isTest
    static void shouldBuildContactMergeP360DAO() {

        // GIVEN
        ContactMergePerson360 contactMergeP360 = new ContactMergePerson360(con.Id);
        Map<Id, ContactMergePerson360.ContactMergePerson360DAO> daoMap;

        Test.startTest();

        // WHEN
        daoMap = contactMergeP360.buildContactMergeP360DAO(new Set<Id>{ con.Id });

        Test.stopTest();

        Assert.isNotNull(daoMap, 'Unexpected null value from buildContactMergeP360DAO()');
        Assert.areEqual(1, daoMap.size(), 'Unexpected number of DAO instances found in the map');
        
        ContactMergePerson360.ContactMergePerson360DAO dao = daoMap.get(con.Id);
        Assert.areEqual(dao.con.Id, con.Id, 'Unexpected contact Id found in the DAO');
    }

    /**
     * @description ensure that ContactMergePerson360Builder will not auto generate
     * an Account record on constructor call. The super class does this by default and
     * is supposed to be overriden
     */
    @isTest
    static void builderShouldNotAutoGenerateAnAccount() {
        
        // GIVEN
        ContactMergePerson360.ContactMergePerson360Builder builder;

        Test.startTest();

        // WHEN
        builder = new ContactMergePerson360.ContactMergePerson360Builder(con);

        Test.stopTest();

        // THEN
        Assert.isNull(builder.accRec, 'Unexpected Account record generated on constructor call');
    }

    /**
     * @description ensure that CPAs are added in the builder
     */
    @isTest
    static void builderShouldAddContactPointAffiliation() {

        // GIVEN
        Contact_Point_Affiliation__c cpa = new Contact_Point_Affiliation__c();
        String cpDevName = 'Address__c';
        cpa = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            cpa,
            Contact_Point_Affiliation__c.class,
            new Map<SObjectField, Object> {
                Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                Contact_Point_Affiliation__c.Address__c => fflib_IDGenerator.generate(Address__c.SObjectType),
                Contact_Point_Affiliation__c.Type__c => cpDevName
            }
        );

        ContactMergePerson360.ContactMergePerson360Builder builder = new ContactMergePerson360.ContactMergePerson360Builder(con);

        Test.startTest();

        // WHEN
        builder.withContactPointAffiliation(cpa, cpDevName);

        Test.stopTest();

        // THEN
        Assert.isNotNull(builder.cpaMap.get(cpDevName), 'Unable to add CPA to the builder');
        Map<Id, Contact_Point_Affiliation__c> cpaTempMap = new Map<Id, Contact_Point_Affiliation__c>(builder.cpaMap.get(cpDevName));
        Assert.isTrue(cpaTempMap.containsKey(cpa.Id), 'Unable to add CPA to the builder');
    }

    /**
     * @description ensure that Contact Points are added in the builder
     */
    @isTest
    static void builderShouldAddContactPoints() {
        
        // GIVEN
        List<Address__c> addressList = new List<Address__c>{
            new Address__c(Id = fflib_IDGenerator.generate(Address__c.SObjectType)),
            new Address__c(Id = fflib_IDGenerator.generate(Address__c.SObjectType))
        };

        ContactMergePerson360.ContactMergePerson360Builder builder = new ContactMergePerson360.ContactMergePerson360Builder(con);

        Test.startTest();

        // WHEN
        builder.withContactPoints(addressList);

        Test.stopTest();

        // THEN
        Map<Id, Address__c> addressMap = new Map<Id, Address__c>((List<Address__c>)builder.contactPointMap.get('Address__c'));
        Assert.isTrue(addressMap.containsKey(addressList[0].Id), 'Unable to add contact point to the builder');
        Assert.isTrue(addressMap.containsKey(addressList[1].Id), 'Unable to add contact point to the builder');
    }

    /**
     * @description ensure that keys are generated based on related IDs.
     * only CPA should not have a unique external ID at this stage
     */
    @isTest
    static void builderShouldRecalculateKeys() {
        
        // GIVEN
        Affiliation__c affiliation = new Affiliation__c(
            Id = fflib_IDGenerator.generate(Affiliation__c.SObjectType),
            Contact__c = con.Id,
            Account__c = fflib_IDGenerator.generate(Account.SObjectType)
        );

        Phone__c contactPoint = new Phone__c(
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType),
            Contact__c = con.Id,
            Name = '+61 497000000',
            Classification__c = 'Private',
            Type__c = 'Mobile',
            Source__c = 'Contact supplied'
        );

        Contact_Point_Affiliation__c cpa = new Contact_Point_Affiliation__c();
        String cpDevName = 'Phone__c';
        cpa = (Contact_Point_Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            cpa,
            Contact_Point_Affiliation__c.class,
            new Map<SObjectField, Object> {
                Contact_Point_Affiliation__c.Id => fflib_IDGenerator.generate(Contact_Point_Affiliation__c.SObjectType),
                Contact_Point_Affiliation__c.Phone__c => contactPoint.Id,
                Contact_Point_Affiliation__c.Affiliation__c => affiliation.Id,
                Contact_Point_Affiliation__c.Contact__c => con.Id,
                Contact_Point_Affiliation__c.Type__c => cpDevName
            }
        );

        ContactMergePerson360.ContactMergePerson360Builder builder = new ContactMergePerson360.ContactMergePerson360Builder(con);
        builder.withAffiliation(affiliation);
        builder.withContactPoint(contactPoint);
        builder.withContactPointAffiliation(cpa, cpDevName);

        Test.startTest();

        // WHEN
        builder.recalculateKeys();

        Test.stopTest();

        // THEN
        Assert.isNotNull(builder.affRec.Composite_Key__c, 'Unable to generate new external ID for Affiliation');
        Assert.isNotNull(builder.contactPointMap.get(cpDevName)[0].get('Key_UID__c'), 'Unable to generate new external ID for Phone');
        Assert.isNull(builder.cpaMap.get(cpDevName)[0].Composite_Key__c, 'Contact Point Affiliation key should not be generated yet');
    }
}