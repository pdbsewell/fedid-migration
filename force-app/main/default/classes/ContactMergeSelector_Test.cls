/**
 * @description       : test class for ContactMergeSelector
 * @author            : Nick Guia
 * @last modified on  : 09-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class ContactMergeSelector_Test {

    private static final String AFFILIATION_RECORD_TYPE = 'Applicant';

    @TestSetup
    static void makeData() {

        // mute triggers
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('Name__c');
        TriggerCommon.disableTrigger('Email__c');
        TriggerCommon.disableTrigger('Phone__c');
        TriggerCommon.disableTrigger('Address__c');

        Contact con = new Contact(FirstName = 'ContactMerge', LastName = 'SelectorTest');
        Person360TestDataFactory factory = new Person360TestDataFactory(false); // don't mock since we need to query

        // create an Account
        Account agency = factory.createAgencyAccount();
        insert agency;

        // create a P360 instance
        Person360 p360 = factory.createPerson360(con, agency);
        BaseClass bc = new Person360BuilderDirector().resolveDependencies(p360).getBaseClass();

        // commit
        Boolean isSuccess = bc.commitRecords();
        System.assert(isSuccess, 'Unable to insert Person360');

        // re-enable triggers
	    TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('Name__c');
        TriggerCommon.enableTrigger('Email__c');
        TriggerCommon.enableTrigger('Phone__c');
        TriggerCommon.enableTrigger('Address__c');
    }

    /**
     * @description test querying contacts
     */
    @isTest
    static void shouldReturnContacts() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        Map<Id, Contact> resultMap;
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id> { con.Id });

        Test.startTest();

        // WHEN
        resultMap = selector.selectContacts();

        Test.stopTest();

        // THEN 
        Assert.isNotNull(resultMap, 'Unable to query Contact records');
        Assert.isTrue(!resultMap.isEmpty(), 'Contact query returned 0 records');
    }

    /**
    * @description test querying affiliations related to the contact
    * @author Nick Guia | 17-07-2023 
    **/
    @isTest
    static void shouldReturnAffiliation() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        List<Affiliation__c> resultList;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultList = selector.selectAffiliations();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultList, 'Unable to query Affiliation records');
        Assert.isTrue(!resultList.isEmpty(), 'Affiliation query returned 0 records');
    }

    /**
    * @description test querying affiliations with a specific record type
    * @author Nick Guia | 17-07-2023 
    **/
    @isTest
    static void shouldReturnAffiliationWithRecordType() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');
        Id affRecTypeId = Schema.SObjectType.Affiliation__c
                            .getRecordTypeInfosByDeveloperName()
                            .get('Applicant')
                            .getRecordTypeId();

        List<Affiliation__c> resultList;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultList = selector.selectAffiliations(AFFILIATION_RECORD_TYPE);

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultList, 'Unable to query Affiliation records');
        Assert.isTrue(!resultList.isEmpty(), 'Affiliation query returned 0 records');
        for(Affiliation__c rec : resultList) {
            Assert.areEqual(affRecTypeId, rec.RecordTypeId, 'Invalid Affiliation Record Type from query');
        }
    }

    /**
    * @description test querying names related to the contact record
    * @author Nick Guia | 17-07-2023 
    **/
    @isTest
    static void shouldReturnNames() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        List<Name__c> resultList;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultList = selector.selectNames();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultList, 'Unable to query Name records');
        Assert.isTrue(!resultList.isEmpty(), 'Name query returned 0 records');
    }

    /**
    * @description test querying phones related to the contact record
    * @author Nick Guia | 17-07-2023 
    **/
    @isTest
    static void shouldReturnPhones() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        List<Phone__c> resultList;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultList = selector.selectPhones();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultList, 'Unable to query Phone records');
        Assert.isTrue(!resultList.isEmpty(), 'Phone query returned 0 records');
    }

    /**
    * @description test querying addresses related to the contact record
    * @author Nick Guia | 17-07-2023 
    **/
    @isTest
    static void shouldReturnAddresses() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        List<Address__c> resultList;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultList = selector.selectAddresses();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultList, 'Unable to query Address records');
        Assert.isTrue(!resultList.isEmpty(), 'Address query returned 0 records');
    }

    /**
    * @description test querying emails related to the contact record
    * @author Nick Guia | 17-07-2023 
    **/
    @isTest
    static void shouldReturnEmails() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        List<Email__c> resultList;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultList = selector.selectEmails();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultList, 'Unable to query Email records');
        Assert.isTrue(!resultList.isEmpty(), 'Email query returned 0 records');
    }

    /**
    * @description test querying CPAs related to the contact record
    * @author Nick Guia | 17-07-2023 
    **/
    @isTest
    static void shouldReturnContactPointAffiliations() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');
        Set<String> expectedTypes = new Set<String>{
            'Phone',
            'Email',
            'Address'
        };

        List<Contact_Point_Affiliation__c> resultList;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultList = selector.selectCPAs();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultList, 'Unable to query Contact Point Affiliation records');
        Assert.isTrue(!resultList.isEmpty(), 'Contact Point Affiliation query returned 0 records');

        for(Contact_Point_Affiliation__c cpa : resultList) {
            Assert.isTrue(expectedTypes.contains(cpa.Type__c), 'Unexpected CPA Type : ' + cpa.Type__c);
        }
    }

    /**
    * @description test if the method returns a map  of affiliation, filtered by record type
    *   and grouped by parent contact
    **/
    @isTest
    static void shouldReturnAffiliationFilteredByRecordTypeGroupedByContactId() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');
        Id affRecTypeId = Schema.SObjectType.Affiliation__c
                            .getRecordTypeInfosByDeveloperName()
                            .get('Applicant')
                            .getRecordTypeId();

        Map<Id, List<Affiliation__c>> affiliationsByContactId;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        affiliationsByContactId = selector.selectAffiliationsGroupedByContactId(AFFILIATION_RECORD_TYPE);

        Test.stopTest();

        // THEN
        Assert.isNotNull(affiliationsByContactId, 'Unable to query Affiliation records');
        Assert.isTrue(!affiliationsByContactId.isEmpty(), 'Affiliation query returned 0 records');
        Assert.areEqual(1, affiliationsByContactId.size(), 'Unexpected map size from query');
        Assert.isTrue(affiliationsByContactId.containsKey(con.Id), 'Parent contact Id not found in the map');

        for(Affiliation__c rec : affiliationsByContactId.get(con.Id)) {
            Assert.areEqual(affRecTypeId, rec.RecordTypeId, 'Invalid record type from query result');
        }
    }

    /**
    * @description test if the method returns a map of affiliation grouped by parent contact
    **/
    @isTest
    static void shouldReturnAffiliationGroupedByContactId() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        Map<Id, List<Affiliation__c>> affiliationsByContactId;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        affiliationsByContactId = selector.selectAffiliationsGroupedByContactId();

        Test.stopTest();

        // THEN
        Assert.isNotNull(affiliationsByContactId, 'Unable to query Affiliation records');
        Assert.isTrue(!affiliationsByContactId.isEmpty(), 'Affiliation query returned 0 records');
        Assert.areEqual(1, affiliationsByContactId.size(), 'Unexpected map size from query');
        Assert.isTrue(affiliationsByContactId.containsKey(con.Id), 'Parent contact Id not found in the map');
    }

    /**
    * @description test if the method returns a map of Names grouped by parent contact
    **/
    @isTest
    static void shouldReturnNamesGroupedByContactId() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        Map<Id, List<Name__c>> resultMapByContactId;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultMapByContactId = selector.selectNamesGroupedByContactId();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultMapByContactId, 'Unable to query Name records');
        Assert.isTrue(!resultMapByContactId.isEmpty(), 'Name query returned 0 records');
        Assert.areEqual(1, resultMapByContactId.size(), 'Unexpected map size from query');
        Assert.isTrue(resultMapByContactId.containsKey(con.Id), 'Parent contact Id not found in the map');
    }

    /**
    * @description test if the method returns a map of Phones grouped by parent contact
    **/
    @isTest
    static void shouldReturnPhonesGroupedByContactId() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        Map<Id, List<Phone__c>> resultMapByContactId;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultMapByContactId = selector.selectPhonesGroupedByContactId();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultMapByContactId, 'Unable to query Phone records');
        Assert.isTrue(!resultMapByContactId.isEmpty(), 'Phone query returned 0 records');
        Assert.areEqual(1, resultMapByContactId.size(), 'Unexpected map size from query');
        Assert.isTrue(resultMapByContactId.containsKey(con.Id), 'Parent contact Id not found in the map');
    }

    /**
    * @description test if the method returns a map of Addresses grouped by parent contact
    **/
    @isTest
    static void shouldReturnAddressesGroupedByContactId() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        Map<Id, List<Address__c>> resultMapByContactId;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultMapByContactId = selector.selectAddressesGroupedByContactId();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultMapByContactId, 'Unable to query Address records');
        Assert.isTrue(!resultMapByContactId.isEmpty(), 'Address query returned 0 records');
        Assert.areEqual(1, resultMapByContactId.size(), 'Unexpected map size from query');
        Assert.isTrue(resultMapByContactId.containsKey(con.Id), 'Parent contact Id not found in the map');
    }

    /**
    * @description test if the method returns a map of Emails grouped by parent contact
    **/
    @isTest
    static void shouldReturnEmailsGroupedByContactId() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        Map<Id, List<Email__c>> resultMapByContactId;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultMapByContactId = selector.selectEmailsGroupedByContactId();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultMapByContactId, 'Unable to query Email records');
        Assert.isTrue(!resultMapByContactId.isEmpty(), 'Email query returned 0 records');
        Assert.areEqual(1, resultMapByContactId.size(), 'Unexpected map size from query');
        Assert.isTrue(resultMapByContactId.containsKey(con.Id), 'Parent contact Id not found in the map');
    }

    /**
    * @description test if the method returns a map of CPAs grouped by parent contact
    **/
    @isTest
    static void shouldReturnCPAsGroupedByContactId() {

        // GIVEN
        Contact con = [SELECT Id FROM Contact
                        WHERE FirstName = 'ContactMerge'
                        AND LastNAme = 'SelectorTest'
                        LIMIT 1];
        Assert.isNotNull(con, 'No contact records found!');

        Map<Id, List<Contact_Point_Affiliation__c>> resultMapByContactId;

        Test.startTest();

        // WHEN
        ContactMergeSelector selector = new ContactMergeSelector(new Set<Id>{con.Id});
        resultMapByContactId = selector.selectCPAsGroupedByContactId();

        Test.stopTest();

        // THEN
        Assert.isNotNull(resultMapByContactId, 'Unable to query CPA records');
        Assert.isTrue(!resultMapByContactId.isEmpty(), 'CPA query returned 0 records');
        Assert.areEqual(1, resultMapByContactId.size(), 'Unexpected map size from query');
        Assert.isTrue(resultMapByContactId.containsKey(con.Id), 'Parent contact Id not found in the map');
    }
}