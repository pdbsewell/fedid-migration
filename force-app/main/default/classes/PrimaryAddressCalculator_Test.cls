/**
 * @description       : Test class for PrimaryAddressCalculator
 * @author            : Nick Guia
 * @last modified on  : 03-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class PrimaryAddressCalculator_Test {

    /**
     * @description simulate the scenario of a 'user-override' primary based on the Primary_set_by__c
     * field. The expectation here is that the calculator should first untoggle the current primary,
     * and set the new one based on the first record that it finds with Primary_set_by__c = 'user'
     */
    @isTest
    static void shouldSetPrimaryByUserOverride() {

        // GIVEN

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

        Map<Id, Address__c> addressMapResult;


        Test.startTest();

        // WHEN
        PrimaryAddressCalculator calculator = new PrimaryAddressCalculator(
            new List<Address__c>{ address1, address2, address3 },
            true
        );
        addressMapResult = new Map<Id, Address__c>((List<Address__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // monash address should not be primary anymore
        Assert.areEqual(false, addressMapResult.get(address1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // user-override should be the new primary
        Assert.areEqual(true, addressMapResult.get(address2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // there should not be any other primary
        Assert.areEqual(false, addressMapResult.get(address3.Id).Is_Primary__c, 'Unable to set new primary'); 
    }

    /**
     * @description If the contact is a current student, the Address with Source = Callista
     * and has the highest roll up rank will be the new primary
     */
    @isTest
    static void shouldSetHighestRollupRankAsPrimaryIfStudentAndNoOverrides() {

        // GIVEN

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
                Address__c.Is_Primary__c => true,
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '20'
            }
        );
        
        // a (currently) non-primary business email but was set as primary by a user
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
                Address__c.Primary_set_by__c => 'autoproc',
                Address__c.Is_Primary__c => false,
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '50'
            }
        );
        
        // will be the new primary
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
                Address__c.Primary_set_by__c => 'autoproc',
                Address__c.Is_Primary__c => false,
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '80'
            }
        );

        Map<Id, Address__c> addressMapResult;


        Test.startTest();

        // WHEN
        PrimaryAddressCalculator calculator = new PrimaryAddressCalculator(
            new List<Address__c>{ address1, address2, address3 },
            true
        );
        addressMapResult = new Map<Id, Address__c>((List<Address__c>)calculator.execute());

        Test.stopTest();

        // THEN
        
        // lower roll up rank should not be the new primary
        Assert.areEqual(false, addressMapResult.get(address1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // lower roll up rank should not be the new primary
        Assert.areEqual(false, addressMapResult.get(address2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // highest roll up rank should be the new primary
        Assert.areEqual(true, addressMapResult.get(address3.Id).Is_Primary__c, 'Unable to set new primary'); 
    }

    /**
     * @description If the contact is a current student, the Address with Source = Callista
     * and has the highest roll up rank will be the new primary. 0 rank should win against null values
     */
    @isTest
    static void shouldSetHighestRollupRankAsPrimaryAgainstNullValuesIfStudentAndNoOverrides() {

        // GIVEN

        // should be the new primary
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
                Address__c.Is_Primary__c => false,
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '20'
            }
        );
        
        // 0 rank, set to primary for testing purposes
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
                Address__c.Primary_set_by__c => 'autoproc',
                Address__c.Is_Primary__c => true,
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '00'
            }
        );
        
        // null rank
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
                Address__c.Primary_set_by__c => 'autoproc',
                Address__c.Is_Primary__c => false,
                Address__c.Source__c => 'Callista'
            }
        );

        Map<Id, Address__c> addressMapResult;


        Test.startTest();

        // WHEN
        PrimaryAddressCalculator calculator = new PrimaryAddressCalculator(
            new List<Address__c>{ address1, address2, address3 },
            true
        );
        addressMapResult = new Map<Id, Address__c>((List<Address__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // lower roll up rank should not be the new primary
        Assert.areEqual(true, addressMapResult.get(address1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // lower roll up rank should not be the new primary
        Assert.areEqual(false, addressMapResult.get(address2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // highest roll up rank should be the new primary
        Assert.areEqual(false, addressMapResult.get(address3.Id).Is_Primary__c, 'Unable to set new primary'); 
    }

    /**
     * @description If the contact is not a current student, the latest address
     * becomes the new primary
     */
    @isTest
    static void shouldSetLatestAddressAsPrimaryForNonStudentAndNoOverrides() {

        // GIVEN

        // a Monash address, which is typically the primary for students
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Address__c.Start_Date__c => Date.today().addDays(-5),
                Address__c.CreatedDate => System.now().addDays(-5),
                Address__c.Classification__c => 'Monash',
                Address__c.Primary_set_by__c => 'autoproc',
                Address__c.Is_Primary__c => true,
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '20'
            }
        );
        
        // latest-greatest address, will be the new primary
        Address__c address2 = new Address__c();
        address2 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address2,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Address__c.Start_Date__c => Date.today(),
                Address__c.CreatedDate => System.now(),
                Address__c.Classification__c => 'Business',
                Address__c.Primary_set_by__c => 'autoproc',
                Address__c.Is_Primary__c => false,
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '50'
            }
        );
        
        Address__c address3 = new Address__c();
        address3 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address3,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Address__c.Start_Date__c => Date.today().addDays(-2),
                Address__c.CreatedDate => System.now().addDays(-2),
                Address__c.Classification__c => 'Private',
                Address__c.Primary_set_by__c => 'autoproc',
                Address__c.Is_Primary__c => false,
                Address__c.Source__c => 'Callista',
                Address__c.Callista_rollup_rank__c => '80'
            }
        );

        Map<Id, Address__c> addressMapResult;


        Test.startTest();

        // WHEN
        PrimaryAddressCalculator calculator = new PrimaryAddressCalculator(
            new List<Address__c>{ address1, address2, address3 },
            false // not a current student
        );
        calculator.shouldSortContactPoints(true);
        addressMapResult = new Map<Id, Address__c>((List<Address__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // older address should not be the new primary
        Assert.areEqual(false, addressMapResult.get(address1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // latest address should be the new primary
        Assert.areEqual(true, addressMapResult.get(address2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // older address should not be the new primary
        Assert.areEqual(false, addressMapResult.get(address3.Id).Is_Primary__c, 'Unable to set new primary'); 
    }
}