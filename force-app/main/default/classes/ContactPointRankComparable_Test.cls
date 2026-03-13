/**
 * @description       : Test class for ContactPointRankComparable
 * @author            : Nick Guia
 * @group             : Person 360
 * @last modified on  : 12-09-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class ContactPointRankComparable_Test {

    /**
     * @description constructor must throw a ContactPointRankComparableException when
     * provided with a null argument
     */
    @isTest
    static void shouldThrowAnExceptionWithNullArgument() {

        // GIVEN
        SObject nullArgument;

        Test.startTest();

        // WHEN
        try {
            ContactPointRankComparable comparable = new ContactPointRankComparable(nullArgument);
            Assert.fail('Unable to throw an exception when initialising with a null argument');
        } catch(ContactPointRankComparable.ContactPointRankComparableException e) {
            // THEN
            Assert.isTrue(true); // expected
        } catch(Exception e) {
            Assert.fail('An unexpected exception occurred');
        }

        Test.stopTest();

    }

    /**
     * @description try to confuse the comparable class by comparing different sobject types
     */
    @isTest
    static void shouldThrowAnExceptionWhenComparingDifferentSObjects() {

        // GIVEN
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '20'
            }
        );
        Email__c email1 = new Email__c(Id = fflib_IDGenerator.generate(Email__c.SObjectType));

        List<ContactPointRankComparable> comparableList = new List<ContactPointRankComparable>{
            new ContactPointRankComparable(address1),
            new ContactPointRankComparable(email1)
        };

        Test.startTest();

        // WHEN
        try {
            comparableList.sort();
            Assert.fail('Unable to throw an exception when initialising with a null argument');
        } catch(ContactPointRankComparable.ContactPointRankComparableDeveloperException e) {
            // THEN
            Assert.isTrue(true); // expected
        } catch(Exception e) {
            Assert.fail('An unexpected exception occurred');
        }

        Test.stopTest();

    }

    /**
     * @description constructor must throw a ContactPointRankComparableException when
     * provided with an argument with a non-integer roll up rank
     */
    @isTest
    static void shouldThrowAnExceptionWithNonIntegerRank() {
        
        // GIVEN

        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '20invalidInteger'
            }
        );

        Test.startTest();

        // WHEN
        try {
            ContactPointRankComparable comparable = new ContactPointRankComparable(address1);
            Assert.fail('Unable to throw an exception when initialising with a null argument');
        } catch(ContactPointRankComparable.ContactPointRankComparableException e) {
            // THEN
            Assert.isTrue(true); // expected
        } catch(Exception e) {
            Assert.fail('An unexpected exception occurred');
        }

        Test.stopTest();
    }

    /**
     * @description test the rules around sorting contact points based on their rank:
     *  - highest rank gets to index 0
     *  - lower rank gets to index 1
     *  - lowest rank gets to index 2
     *  - null rank gets the highest index
     */
    @isTest
    static void shouldCompare() {
        // GIVEN

        // highest rank
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '100'
            }
        );

        // lower rank
        Address__c address2 = new Address__c();
        address2 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address2,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '20'
            }
        );

        // 0 rank
        Address__c address3 = new Address__c();
        address3 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address3,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '0'
            }
        );

        // null rank
        Address__c address4 = new Address__c();
        address4 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address4,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => null
            }
        );
        
        // add in random order
        List<ContactPointRankComparable> comparableList = new List<ContactPointRankComparable>{
            new ContactPointRankComparable(address3),
            new ContactPointRankComparable(address1),
            new ContactPointRankComparable(address4),
            new ContactPointRankComparable(address2)
        };

        Test.startTest();

        // WHEN
        comparableList.sort();

        Test.stopTest();

        // THEN
        Assert.areEqual(address1.Id, comparableList[0].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(address2.Id, comparableList[1].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(address3.Id, comparableList[2].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(address4.Id, comparableList[3].compareFrom.Id, 'Unexpected sort order');
    }

    /**
     * @description compare null checks: 
     *  -   not null vs null returns -1 (current value wins)
     *  -   null vs not null returns 1 (new value wins)
     *  -   both null returns 0 (equal)
     */
    @isTest
    static void shouldCompareNullChecks() {
        
        // GIVEN

        // dummy sobject to initialise
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '20'
            }
        );

        ContactPointRankComparable comparable = new ContactPointRankComparable(address1);

        Integer notNullVsNullExpected = -1;
        Integer nullVsNotNullExpected = 1;
        Integer bothNullExpected = 0;

        Integer notNullVsNullActual;
        Integer nullVsNotNullActual;
        Integer bothNullActual;

        Test.startTest();

        // WHEN
        notNullVsNullActual = comparable.rule1(20, null);
        nullVsNotNullActual = comparable.rule1(null, 20);
        bothNullActual = comparable.rule1(null, null);

        Test.stopTest();

        // THEN
        Assert.areEqual(notNullVsNullExpected, notNullVsNullActual, 'Unexpected return value when comparing non-null rank vs null rank');
        Assert.areEqual(nullVsNotNullExpected, nullVsNotNullActual, 'Unexpected return value when comparing null rank vs non-null rank');
        Assert.areEqual(bothNullExpected, bothNullActual, 'Unexpected return value when comparing null ranks');
    }

    /**
     * @description compare rank values: 
     *  -   Equal returns 0
     *  -   greater than returns -1 (current value wins)
     *  -   less than returns 1 (new value wins)
     */
    @isTest
    static void shouldCompareRanks() {

        // GIVEN

        // dummy sobject to initialise
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '20'
            }
        );

        ContactPointRankComparable comparable = new ContactPointRankComparable(address1);

        Integer equalExpected = 0;
        Integer greaterThanExpected = -1;
        Integer lessThanExpected = 1;

        Integer equalActual;
        Integer greaterThanActual;
        Integer lessThanActual;

        Test.startTest();

        // WHEN
        equalActual = comparable.rule2(20, 20);
        greaterThanActual = comparable.rule2(50, 20);
        lessThanActual = comparable.rule2(30, 70);

        Test.stopTest();

        // THEN
        Assert.areEqual(equalExpected, equalActual, 'Unexpected return value when comparing equal ranks');
        Assert.areEqual(greaterThanExpected, greaterThanActual, 'Unexpected return value with a "greater than" rank');
        Assert.areEqual(lessThanExpected, lessThanActual, 'Unexpected return value with a "less than" rank');
    }
}