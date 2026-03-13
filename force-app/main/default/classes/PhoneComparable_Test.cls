/**
 * @description       : Test class for PhoneComparable
 * @author            : Nick Guia
 * @last modified on  : 01-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class PhoneComparable_Test {

    /**
     * @description should sort the list based on the latest start date
     */
    @isTest
    static void shouldSortByStartDate() {

        // GIVEN
        Phone__c phone1 = new Phone__c(
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType),
            Start_Date__c = Date.today()
        );
        Phone__c phone2 = new Phone__c(
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType),
            Start_Date__c = Date.today().addDays(-1)
        );
        Phone__c phone3 = new Phone__c(
            Id = fflib_IDGenerator.generate(Phone__c.SObjectType),
            Start_Date__c = Date.today().addDays(-2)
        );

        List<PhoneComparable> comparableList;

        Test.startTest();

        // WHEN

        // add in an "unsorted" order
        comparableList = new List<PhoneComparable>{
            new PhoneComparable(phone2),
            new PhoneComparable(phone3),
            new PhoneComparable(phone1)
        };
        comparableList.sort();

        Test.stopTest();

        // THEN
        Assert.areEqual(phone1.Id, comparableList[0].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(phone2.Id, comparableList[1].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(phone3.Id, comparableList[2].compareFrom.Id, 'Unexpected sort order');
    }

    /**
     * @description test sorting by created dates when all Start dates
     * are equal
     */
    @isTest
    static void shouldSortByCreatedDate() {

        // GIVEN

        // should all have the same start dates
        Phone__c phone1 = new Phone__c();
        phone1 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone1,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Start_Date__c => Date.today(),
                Phone__c.CreatedDate => System.now()
            }
        );

        Phone__c phone2 = new Phone__c();
        phone2 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone2,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => System.now().addDays(-1)
            }
        );

        Phone__c phone3 = new Phone__c();
        phone3 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone3,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => System.now().addDays(-2)
            }
        );

        List<PhoneComparable> comparableList;

        Test.startTest();

        // WHEN

        // add in an "unsorted" order
        comparableList = new List<PhoneComparable>{
            new PhoneComparable(phone3),
            new PhoneComparable(phone1),
            new PhoneComparable(phone2)
        };
        comparableList.sort();

        Test.stopTest();

        // THEN
        Assert.areEqual(phone1.Id, comparableList[0].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(phone2.Id, comparableList[1].compareFrom.Id, 'Unexpected sort order');
        Assert.areEqual(phone3.Id, comparableList[2].compareFrom.Id, 'Unexpected sort order');
    }

    /**
     * @description should sort the list based on the latest start date
     * Mobile is prioritised; otherwise Landline; otherwise, equal
     */
    @isTest
    static void shouldSortByType() {

        // should all have the same start dates and created dates
        Phone__c phone1 = new Phone__c();
        phone1 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone1,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Start_Date__c => Date.today(),
                Phone__c.CreatedDate => System.now(),
                Phone__c.Type__c => 'Landline'
            }
        );

        Phone__c phone2 = new Phone__c();
        phone2 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone2,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Other'
            }
        );

        Phone__c phone3 = new Phone__c();
        phone3 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone3,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Landline'
            }
        );

        Phone__c phone4 = new Phone__c();
        phone4 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone4,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Other'
            }
        );

        Phone__c phone5 = new Phone__c();
        phone5 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone5,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Mobile'
            }
        );

        Phone__c phone6 = new Phone__c();
        phone6 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone6,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Mobile'
            }
        );

        List<PhoneComparable> comparableList;

        Test.startTest();

        // WHEN
        comparableList = new List<PhoneComparable>{
            new PhoneComparable(phone1),
            new PhoneComparable(phone2),
            new PhoneComparable(phone3),
            new PhoneComparable(phone4),
            new PhoneComparable(phone5),
            new PhoneComparable(phone6)
        };
        comparableList.sort();

        Test.stopTest();

        // THEN
        Assert.areEqual(phone5.Id, comparableList[0].compareFrom.Id, 'Unexpected sort order'); // mobile comes first
        Assert.areEqual(phone6.Id, comparableList[1].compareFrom.Id, 'Unexpected sort order'); // second - another mobile (equal)

        Assert.areEqual(phone1.Id, comparableList[2].compareFrom.Id, 'Unexpected sort order'); // then, Landline
        Assert.areEqual(phone3.Id, comparableList[3].compareFrom.Id, 'Unexpected sort order'); // then, another Landline (equal)

        Assert.areEqual(phone2.Id, comparableList[4].compareFrom.Id, 'Unexpected sort order'); // then, first instance of 'Other'
        Assert.areEqual(phone4.Id, comparableList[5].compareFrom.Id, 'Unexpected sort order'); // then, second instance of 'Other'
    }
}