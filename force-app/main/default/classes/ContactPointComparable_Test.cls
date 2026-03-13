/**
 * @description       : Test class for ContactPointComparable
 * @author            : Nick Guia
 * @last modified on  : 01-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class ContactPointComparable_Test {

    public class TestContactPointComparable extends ContactPointComparable {

        // for this test, I picked Email__c as the contact point (can be anything otherwise)
        public TestContactPointComparable(Email__c rec) {
            super(rec);
        }
    }

    /**
     * @description should sort the list based on the latest start date
     */
    @isTest
    static void shouldSortByStartDate() {

        // GIVEN
        Email__c email1 = new Email__c(
            Id = fflib_IDGenerator.generate(Email__c.SObjectType),
            Start_Date__c = Date.today()
        );
        Email__c email2 = new Email__c(
            Id = fflib_IDGenerator.generate(Email__c.SObjectType),
            Start_Date__c = Date.today().addDays(-1)
        );
        Email__c email3 = new Email__c(
            Id = fflib_IDGenerator.generate(Email__c.SObjectType),
            Start_Date__c = Date.today().addDays(-2)
        );

        List<ContactPointComparable> comparableList;

        Test.startTest();

        // WHEN

        // add in an "unsorted" order
        comparableList = new List<ContactPointComparable>{
            new TestContactPointComparable(email2),
            new TestContactPointComparable(email3),
            new TestContactPointComparable(email1)
        };
        comparableList.sort();

        Test.stopTest();

        // THEN
        Assert.areEqual(email1.Id, comparableList[0].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(email2.Id, comparableList[1].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(email3.Id, comparableList[2].compareFrom.Id, 'Unexpected sort order');
    }

    /**
     * @description test sorting by created dates when all Start dates
     * are equal
     */
    @isTest
    static void shouldSortByCreatedDate() {

        // GIVEN

        // should all have the same start dates
        Email__c email1 = new Email__c();
        email1 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email1,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Start_Date__c => Date.today(),
                Email__c.CreatedDate => System.now()
            }
        );

        Email__c email2 = new Email__c();
        email2 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email2,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => System.now().addDays(-1)
            }
        );

        Email__c email3 = new Email__c();
        email3 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email3,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => System.now().addDays(-2)
            }
        );

        List<ContactPointComparable> comparableList;

        Test.startTest();

        // WHEN

        // add in an "unsorted" order
        comparableList = new List<ContactPointComparable>{
            new TestContactPointComparable(email3),
            new TestContactPointComparable(email1),
            new TestContactPointComparable(email2)
        };
        comparableList.sort();

        Test.stopTest();

        // THEN
        Assert.areEqual(email1.Id, comparableList[0].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(email2.Id, comparableList[1].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(email3.Id, comparableList[2].compareFrom.Id, 'Unexpected sort order');
    }

    /**
     * @description test sorting by Channel (null comparison) if all records have the same
     * Start date and Created date
     */
    @isTest
    static void shouldSortByChannel() {

        // should all have the same start dates and created dates
        Email__c email1 = new Email__c();
        email1 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email1,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Start_Date__c => Date.today(),
                Email__c.CreatedDate => System.now(),
                Email__c.Channel__c => fflib_IDGenerator.generate(Channel__c.SObjectType)
            }
        );

        Email__c email2 = new Email__c();
        email2 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email2,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate,
                Email__c.Channel__c => null
            }
        );

        Email__c email3 = new Email__c();
        email3 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email3,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate,
                Email__c.Channel__c => fflib_IDGenerator.generate(Channel__c.SObjectType)
            }
        );

        List<ContactPointComparable> comparableList;

        Test.startTest();

        // WHEN

        // add in an "unsorted" order
        comparableList = new List<ContactPointComparable>{
            new TestContactPointComparable(email2),
            new TestContactPointComparable(email3),
            new TestContactPointComparable(email1)
        };
        comparableList.sort();

        Test.stopTest();

        // THEN

        // email 1 and 3 should result as equal since they both have channels, but email 2 should be the last
        Assert.areEqual(email3.Id, comparableList[0].compareFrom.Id, 'Unexpected sort order'); // since email3 was added first
        Assert.areEqual(email1.Id, comparableList[1].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(email2.Id, comparableList[2].compareFrom.Id, 'Unexpected sort order');
    }

    /**
     * @description list is considered as sorted if all evaluations return as equal
     */
    @isTest
    static void shouldReturnAsIsWhenAllEvaluationsAreEqual() {

        // GIVEN

        // should all have the same start dates and Created dates, all channels must be null
        Email__c email1 = new Email__c();
        email1 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email1,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Start_Date__c => Date.today(),
                Email__c.CreatedDate => System.now()
            }
        );

        Email__c email2 = new Email__c();
        email2 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email2,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate
            }
        );

        Email__c email3 = new Email__c();
        email3 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email3,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate
            }
        );

        List<ContactPointComparable> comparableList;

        Test.startTest();

        // WHEN

        // add in an "unsorted" order
        comparableList = new List<ContactPointComparable>{
            new TestContactPointComparable(email3),
            new TestContactPointComparable(email2),
            new TestContactPointComparable(email1)
        };
        comparableList.sort();

        Test.stopTest();

        // THEN

        // list should remain as-is
        Assert.areEqual(email3.Id, comparableList[0].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(email2.Id, comparableList[1].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(email1.Id, comparableList[2].compareFrom.Id, 'Unexpected sort order');
        
    }

    /**
     * @description test if the comparable class throws an exception when attempting to sort
     * a list containing null sobjects
     */
    @isTest
    static void shouldThrowContactPointComparableExceptionWhenConstructingWithNullSObject() {

        // GIVEN 
        Email__c email = null;

        Test.startTest();

        // WHEN
        try {
            ContactPointComparable comparable = new TestContactPointComparable(email);
            Assert.fail('Did not throw an exception after constructing with a null sobject');
        } catch(ContactPointComparable.ContactPointComparableException e) {
            // THEN
            Assert.isTrue(true);
        } catch(Exception e) {
            Assert.fail('A different exception occurred : ' + e.getMessage());
        }

        Test.stopTest();
    }

    /**
     * @description test if the method returns 1 when the first
     * parameter is not null and the second is null
     */
    @isTest
    static void shouldReturnNegativeWhenFirstObjectIsNotNull() {

        // GIVEN
        DateTime dt1 = System.now();
        DateTime dt2 = null;

        Integer eval;

        Test.startTest();

        // WHEN
        ContactPointComparable comparable = new TestContactPointComparable(new Email__c()); // any sobject
        eval = comparable.compareNull(dt1, dt2);

        Test.stopTest();

        // THEN
        Assert.areEqual(-1, eval, 'Unexpected result on null evaluation');
    }

    /**
     * @description test if the method returns -1 when the first
     * parameter is null and the second is not null
     */
    @isTest
    static void shouldReturn1WhenFirstObjectIsNull() {

        // GIVEN
        DateTime dt1 = null;
        DateTime dt2 = System.now();

        Integer eval;

        Test.startTest();

        // WHEN
        ContactPointComparable comparable = new TestContactPointComparable(new Email__c()); // any sobject
        eval = comparable.compareNull(dt1, dt2);

        Test.stopTest();

        // THEN
        Assert.areEqual(1, eval, 'Unexpected result on null evaluation');
    }

    /**
     * @description test if the method returns 0 when both
     * parameters are null
     */
    @isTest
    static void shouldReturnZeroWhenBothObjectsAreNull() {

        // GIVEN
        DateTime dt1 = null;
        DateTime dt2 = null;

        Integer eval;

        Test.startTest();

        // WHEN
        ContactPointComparable comparable = new TestContactPointComparable(new Email__c()); // any sobject
        eval = comparable.compareNull(dt1, dt2);

        Test.stopTest();

        // THEN
        Assert.areEqual(0, eval, 'Unexpected result on null evaluation');
    }

    /**
     * @description test if the method returns 1 when the first parameter
     * is greater than the second, without checking for nulls
     */
    @isTest
    static void shouldReturnNegativeWhenFirstDateIsGreaterWithoutNullCheck() {

        // GIVEN
        DateTime dt1 = System.now();
        DateTime dt2 = System.now().addDays(-1);

        Integer eval;

        Test.startTest();

        // WHEN
        ContactPointComparable comparable = new TestContactPointComparable(new Email__c()); // any sobject
        eval = comparable.compareDateTime(dt1, dt2, false);

        Test.stopTest();

        // THEN
        Assert.areEqual(-1, eval, 'Unexpected result on DateTime evaluation');
    }
    
    /**
     * @description test if the method returns -1 when the first parameter
     * is less than the second, without checking for nulls
     */
    @isTest
    static void shouldReturn1WhenSecondDateIsGreaterWithoutNullCheck() {

        // GIVEN
        DateTime dt1 = System.now();
        DateTime dt2 = System.now().addDays(1);

        Integer eval;

        Test.startTest();

        // WHEN
        ContactPointComparable comparable = new TestContactPointComparable(new Email__c()); // any sobject
        eval = comparable.compareDateTime(dt1, dt2, false);

        Test.stopTest();

        // THEN
        Assert.areEqual(1, eval, 'Unexpected result on DateTime evaluation');
    }

    /**
     * @description test if the method returns 1 when the first parameter
     * is greater than the second, with null checking
     */
    @isTest
    static void shouldReturnNegativeWhenFirstDateIsGreaterWithNullCheck() {

        // GIVEN
        DateTime dt1 = System.now();
        DateTime dt2 = System.now().addDays(-1);

        Integer eval;

        Test.startTest();

        // WHEN
        ContactPointComparable comparable = new TestContactPointComparable(new Email__c()); // any sobject
        eval = comparable.compareDateTime(dt1, dt2, true);

        Test.stopTest();

        // THEN
        Assert.areEqual(-1, eval, 'Unexpected result on DateTime evaluation');
    }
    
    /**
     * @description test if the method returns -1 when the first parameter
     * is less than the second, with null checking
     */
    @isTest
    static void shouldReturn1WhenSecondDateIsGreaterWithNullCheck() {

        // GIVEN
        DateTime dt1 = System.now();
        DateTime dt2 = System.now().addDays(1);

        Integer eval;

        Test.startTest();

        // WHEN
        ContactPointComparable comparable = new TestContactPointComparable(new Email__c()); // any sobject
        eval = comparable.compareDateTime(dt1, dt2, true);

        Test.stopTest();

        // THEN
        Assert.areEqual(1, eval, 'Unexpected result on DateTime evaluation');
    }

    /**
     * @description test if the method returns 0 when the parameters are equal
     */
    @isTest
    static void shouldReturnZeroWhenEqual() {

        // GIVEN
        DateTime dt1 = System.now();
        DateTime dt2 = dt1;

        Integer eval;

        Test.startTest();

        // WHEN
        ContactPointComparable comparable = new TestContactPointComparable(new Email__c()); // any sobject
        eval = comparable.compareDateTime(dt1, dt2, true);

        Test.stopTest();

        // THEN
        Assert.areEqual(0, eval, 'Unexpected result on DateTime evaluation');
    }
}