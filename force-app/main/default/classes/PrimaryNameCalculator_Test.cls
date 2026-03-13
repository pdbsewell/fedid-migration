/**
 * @description       : Test class for PrimaryNameCalculator
 * @author            : Nick Guia
 * @last modified on  : 23-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class PrimaryNameCalculator_Test {
    /**
     * @description simulate the scenario of a 'user-override' primary based on the Primary_set_by__c
     * field. The expectation here is that the calculator should first untoggle the current primary,
     * and set the new one based on the first record that it finds with Primary_set_by__c = 'user'
     */
    @isTest
    static void shouldSetPrimaryByUserOverride() {

        // GIVEN

        // primary Name
        Name__c name1 = new Name__c();
        name1 = (Name__c) fflib_ApexMocksUtils.setReadOnlyFields(
            name1,
            Name__c.class,
            new Map<SObjectField, Object> {
                Name__c.Id => fflib_IDGenerator.generate(Name__c.SObjectType),
                Name__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Name__c.Start_Date__c => Date.today(),
                Name__c.CreatedDate => System.now(),
                Name__c.Type__c => 'Common',
                Name__c.Primary_set_by__c => 'autoproc',
                Name__c.Is_Primary__c => true
            }
        );
        
        // a (currently) non-primary Name but was set as primary by a user
        Name__c name2 = new Name__c();
        name2 = (Name__c) fflib_ApexMocksUtils.setReadOnlyFields(
            name2,
            Name__c.class,
            new Map<SObjectField, Object> {
                Name__c.Id => fflib_IDGenerator.generate(Name__c.SObjectType),
                Name__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Name__c.Start_Date__c => name1.Start_Date__c,
                Name__c.CreatedDate => name1.CreatedDate,
                Name__c.Type__c => 'Common',
                Name__c.Primary_set_by__c => 'user',
                Name__c.Is_Primary__c => false
            }
        );

        Map<Id, Name__c> nameMapResult;


        Test.startTest();

        // WHEN
        PrimaryNameCalculator calculator = new PrimaryNameCalculator(
            new List<Name__c>{ name1, name2 },
            true
        );
        nameMapResult = new Map<Id, Name__c>((List<Name__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // Primary_set_by__c => 'autoproc', should not be the primary anymore
        Assert.areEqual(false, nameMapResult.get(name1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // user-override should be the new primary
        Assert.areEqual(true, nameMapResult.get(name2.Id).Is_Primary__c, 'Unable to set new primary'); 
    }

    /**
     * @description test if the calculator sets the Student Name type as primary
     * if there are no user-overridden primaries
     */
    @isTest
    static void shouldSetPrimaryByRollupRank() {

        // GIVEN

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
        
        // add another name to the mix
        Name__c name3 = new Name__c();
        name3 = (Name__c) fflib_ApexMocksUtils.setReadOnlyFields(
            name3,
            Name__c.class,
            new Map<SObjectField, Object> {
                Name__c.Id => fflib_IDGenerator.generate(Name__c.SObjectType),
                Name__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Name__c.Start_Date__c => Date.today(),
                Name__c.CreatedDate => name1.CreatedDate,
                Name__c.Type__c => 'Common',
                Name__c.Is_Primary__c => false
            }
        );

        // add another name to the mix
        Name__c name4 = new Name__c();
        name4 = (Name__c) fflib_ApexMocksUtils.setReadOnlyFields(
            name4,
            Name__c.class,
            new Map<SObjectField, Object> {
                Name__c.Id => fflib_IDGenerator.generate(Name__c.SObjectType),
                Name__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Name__c.Start_Date__c => Date.today(),
                Name__c.CreatedDate => name1.CreatedDate,
                Name__c.Type__c => 'Common',
                Name__c.Is_Primary__c => false
            }
        );

        Map<Id, Name__c> nameMapResult;

        Test.startTest();

        // WHEN
        PrimaryNameCalculator calculator = new PrimaryNameCalculator(
            new List<Name__c>{ name1, name2, name3, name4 },
            true
        );
        nameMapResult = new Map<Id, Name__c>((List<Name__c>) calculator.execute());

        Test.stopTest();

        // THEN

        // old mobile should not be primary anymore
        Assert.areEqual(false, nameMapResult.get(name1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // new mobile should be the new primary
        Assert.areEqual(true, nameMapResult.get(name2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // there should not be any other primary
        Assert.areEqual(false, nameMapResult.get(name3.Id).Is_Primary__c, 'Unable to set new primary'); 
        // there should not be any other primary
        Assert.areEqual(false, nameMapResult.get(name4.Id).Is_Primary__c, 'Unable to set new primary'); 
    }
}