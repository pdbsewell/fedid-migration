/**
 * @description       : Test class for PrimaryPhoneCalculator
 * @author            : Nick Guia
 * @last modified on  : 03-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class PrimaryPhoneCalculator_Test {

    /**
     * @description simulate the scenario of a 'user-override' primary based on the Primary_set_by__c
     * field. The expectation here is that the calculator should first untoggle the current primary,
     * and set the new one based on the first record that it finds with Primary_set_by__c = 'user'
     */
    @isTest
    static void shouldSetPrimaryByUserOverride() {

        // GIVEN

        // a mobile phone, which is typically the primary
        Phone__c phone1 = new Phone__c();
        phone1 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone1,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Phone__c.Start_Date__c => Date.today(),
                Phone__c.CreatedDate => System.now(),
                Phone__c.Type__c => 'Mobile',
                Phone__c.Primary_set_by__c => 'autoproc',
                Phone__c.Is_Primary__c => true
            }
        );
        
        // a (currently) non-primary phone but was set as primary by a user
        Phone__c phone2 = new Phone__c();
        phone2 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone2,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Other',
                Phone__c.Primary_set_by__c => 'user',
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
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Landline',
                Phone__c.Is_Primary__c => false
            }
        );

        Map<Id, Phone__c> phoneMapResult;


        Test.startTest();

        // WHEN
        PrimaryPhoneCalculator calculator = new PrimaryPhoneCalculator(
            new List<Phone__c>{ phone1, phone2, phone3 },
            true
        );
        phoneMapResult = new Map<Id, Phone__c>((List<Phone__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // mobile should not be primary anymore
        Assert.areEqual(false, phoneMapResult.get(phone1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // user-override should be the new primary
        Assert.areEqual(true, phoneMapResult.get(phone2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // there should not be any other primary
        Assert.areEqual(false, phoneMapResult.get(phone3.Id).Is_Primary__c, 'Unable to set new primary'); 
    }

    /**
     * @description simulate the scenario of a 'user-override' primary based on the Primary_set_by__c
     * field. In this scenario, there will be multiple phone records with Primary_set_by__c = 'user'.
     * In this case, we will be relying on the sorting of the list through the PhoneComparable.cls
     */
    @isTest
    static void shouldSetPrimaryByUserWithMultiple() {

        // GIVEN

        // a mobile phone, which is typically the primary
        Phone__c phone1 = new Phone__c();
        phone1 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone1,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Phone__c.Start_Date__c => Date.today(),
                Phone__c.CreatedDate => System.now(),
                Phone__c.Type__c => 'Mobile',
                Phone__c.Primary_set_by__c => 'autoproc',
                Phone__c.Is_Primary__c => true
            }
        );
        
        // a (currently) non-primary phone but was set as primary by a user
        Phone__c phone2 = new Phone__c();
        phone2 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone2,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Other',
                Phone__c.Primary_set_by__c => 'user',
                Phone__c.Is_Primary__c => false
            }
        );
        
        // add another primary set by a user record, but has a higher Type ranking than the previous one
        Phone__c phone3 = new Phone__c();
        phone3 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone3,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Landline',
                Phone__c.Primary_set_by__c => 'user',
                Phone__c.Is_Primary__c => false
            }
        );

        // add another phone to the mix
        Phone__c phone4 = new Phone__c();
        phone4 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone4,
            Phone__c.class,
            new Map<SObjectField, Object> {
                Phone__c.Id => fflib_IDGenerator.generate(Phone__c.SObjectType),
                Phone__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Phone__c.Start_Date__c => phone1.Start_Date__c,
                Phone__c.CreatedDate => phone1.CreatedDate,
                Phone__c.Type__c => 'Landline',
                Phone__c.Is_Primary__c => false
            }
        );

        Map<Id, Phone__c> phoneMapResult;

        Test.startTest();

        // WHEN
        PrimaryPhoneCalculator calculator = new PrimaryPhoneCalculator(
            new List<Phone__c>{ phone1, phone2, phone3, phone4 },
            true
        );
        calculator.shouldSortContactPoints(true); // sort first since we didn't use a query with ORDER BY
        phoneMapResult = new Map<Id, Phone__c>((List<Phone__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // mobile should not be primary anymore
        Assert.areEqual(false, phoneMapResult.get(phone1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // user-override should not be the new primary, given the lower ranking Type
        Assert.areEqual(false, phoneMapResult.get(phone2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // user-override should with Type = 'Landline' should be the new primary, given the higher ranking Type
        Assert.areEqual(true, phoneMapResult.get(phone3.Id).Is_Primary__c, 'Unable to set new primary'); 
        // there should not be any other primary
        Assert.areEqual(false, phoneMapResult.get(phone4.Id).Is_Primary__c, 'Unable to set new primary'); 
    }

    /**
     * @description test if the calculator sets the latest Phone as primary
     * if there are no user-overridden primaries
     */
    @isTest
    static void shouldSetPrimaryByLatestGreatestIfNoUserOverride() {

        // GIVEN

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

        // add another phone to the mix
        Phone__c phone4 = new Phone__c();
        phone4 = (Phone__c) fflib_ApexMocksUtils.setReadOnlyFields(
            phone4,
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

        Map<Id, Phone__c> phoneMapResult;

        Test.startTest();

        // WHEN
        PrimaryPhoneCalculator calculator = new PrimaryPhoneCalculator(
            new List<Phone__c>{ phone1, phone2, phone3, phone4 },
            true
        );
        calculator.shouldSortContactPoints(true); // sort first since we didn't use a query with ORDER BY
        phoneMapResult = new Map<Id, Phone__c>((List<Phone__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // old mobile should not be primary anymore
        Assert.areEqual(false, phoneMapResult.get(phone1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // new mobile should be the new primary
        Assert.areEqual(true, phoneMapResult.get(phone2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // there should not be any other primary
        Assert.areEqual(false, phoneMapResult.get(phone3.Id).Is_Primary__c, 'Unable to set new primary'); 
        // there should not be any other primary
        Assert.areEqual(false, phoneMapResult.get(phone4.Id).Is_Primary__c, 'Unable to set new primary'); 
    }
}