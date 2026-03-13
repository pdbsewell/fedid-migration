/**
 * @description       : Test class for PrimaryEmailCalculator
 * @author            : Nick Guia
 * @last modified on  : 03-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class PrimaryEmailCalculator_Test {

    /**
     * @description simulate the scenario of a 'user-override' primary based on the Primary_set_by__c
     * field. The expectation here is that the calculator should first untoggle the current primary,
     * and set the new one based on the first record that it finds with Primary_set_by__c = 'user'
     */
    @isTest
    static void shouldSetPrimaryByUserOverride() {

        // GIVEN

        // a Monash email, which is typically the primary for students
        Email__c email1 = new Email__c();
        email1 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email1,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => Date.today(),
                Email__c.CreatedDate => System.now(),
                Email__c.Classification__c => 'Monash',
                Email__c.Primary_set_by__c => 'autoproc',
                Email__c.Is_Primary__c => true
            }
        );
        
        // a (currently) non-primary business email but was set as primary by a user
        Email__c email2 = new Email__c();
        email2 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email2,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate,
                Email__c.Classification__c => 'Business',
                Email__c.Primary_set_by__c => 'user',
                Email__c.Is_Primary__c => false
            }
        );
        
        // add another email to the mix
        Email__c email3 = new Email__c();
        email3 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email3,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate,
                Email__c.Classification__c => 'Private',
                Email__c.Is_Primary__c => false
            }
        );

        Map<Id, Email__c> emailMapResult;


        Test.startTest();

        // WHEN
        PrimaryEmailCalculator calculator = new PrimaryEmailCalculator(
            new List<Email__c>{ email1, email2, email3 },
            true
        );
        emailMapResult = new Map<Id, Email__c>((List<Email__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // monash email should not be primary anymore
        Assert.areEqual(false, emailMapResult.get(email1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // user-override should be the new primary
        Assert.areEqual(true, emailMapResult.get(email2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // there should not be any other primary
        Assert.areEqual(false, emailMapResult.get(email3.Id).Is_Primary__c, 'Unable to set new primary'); 
    }

    /**
     * @description if the contact is a current student, and there is no user-overriden-primary
     * always pick the monash email as the primary
     */
    @isTest
    static void shouldSetMonashEmailAsPrimaryforCurrentStudentWithoutUserOverrides() {

        // GIVEN

        // a Monash email, this should become the primary
        Email__c email1 = new Email__c();
        email1 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email1,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => Date.today(),
                Email__c.CreatedDate => System.now(),
                Email__c.Classification__c => 'Monash',
                Email__c.Primary_set_by__c => 'autoproc',
                Email__c.Is_Primary__c => false
            }
        );
        
        // a (currently) primary business email
        Email__c email2 = new Email__c();
        email2 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email2,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate,
                Email__c.Classification__c => 'Business',
                Email__c.Primary_set_by__c => 'autoproc',
                Email__c.Is_Primary__c => true
            }
        );
        
        // add another email to the mix
        Email__c email3 = new Email__c();
        email3 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email3,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate,
                Email__c.Classification__c => 'Private',
                Email__c.Is_Primary__c => false
            }
        );

        Map<Id, Email__c> emailMapResult;


        Test.startTest();

        // WHEN
        PrimaryEmailCalculator calculator = new PrimaryEmailCalculator(
            new List<Email__c>{ email1, email2, email3 },
            true
        );
        emailMapResult = new Map<Id, Email__c>((List<Email__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // monash email should not be the new primary anymore
        Assert.areEqual(true, emailMapResult.get(email1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // previous primary should not be anymore
        Assert.areEqual(false, emailMapResult.get(email2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // there should not be any other primary
        Assert.areEqual(false, emailMapResult.get(email3.Id).Is_Primary__c, 'Unable to set new primary'); 
    }

    /**
     * @description if the contact is not student, and there is no user-overriden-primary
     * pick the latest non-monash email as primary
     */
    @isTest
    static void shouldSetLatestNonMonashEmailAsPrimaryforNonStudentWithoutUserOverrides() {

        // GIVEN

        // a monash email
        Email__c email1 = new Email__c();
        email1 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email1,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => Date.today().addDays(-1),
                Email__c.CreatedDate => System.now().addDays(-1),
                Email__c.Classification__c => 'Monash',
                Email__c.Primary_set_by__c => 'autoproc',
                Email__c.Is_Primary__c => false
            }
        );
        
        // a (currently) primary business email
        Email__c email2 = new Email__c();
        email2 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email2,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => email1.Start_Date__c,
                Email__c.CreatedDate => email1.CreatedDate,
                Email__c.Classification__c => 'Business',
                Email__c.Primary_set_by__c => 'autoproc',
                Email__c.Is_Primary__c => true
            }
        );
        
        // latest non-monash email
        Email__c email3 = new Email__c();
        email3 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email3,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => Date.today(),
                Email__c.CreatedDate => System.now(),
                Email__c.Classification__c => 'Private',
                Email__c.Is_Primary__c => false
            }
        );

        // an older non-monash email
        Email__c email4 = new Email__c();
        email4 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email4,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => Date.today().addDays(-5),
                Email__c.CreatedDate => System.now().addDays(-5),
                Email__c.Classification__c => 'Private',
                Email__c.Is_Primary__c => false
            }
        );

        Map<Id, Email__c> emailMapResult;


        Test.startTest();

        // WHEN
        PrimaryEmailCalculator calculator = new PrimaryEmailCalculator(
            new List<Email__c>{ email1, email2, email3, email4 },
            false // non-student
        );
        calculator.shouldSortContactPoints(true); // sort first
        emailMapResult = new Map<Id, Email__c>((List<Email__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // monash email not be the new primary anymore
        Assert.areEqual(false, emailMapResult.get(email1.Id).Is_Primary__c, 'Unable to set new primary'); 
        // previous primary should not be anymore
        Assert.areEqual(false, emailMapResult.get(email2.Id).Is_Primary__c, 'Unable to set new primary'); 
        // latest non-monash email should be the new primary
        Assert.areEqual(true, emailMapResult.get(email3.Id).Is_Primary__c, 'Unable to set new primary'); 
        // there should not be any other primary
        Assert.areEqual(false, emailMapResult.get(email4.Id).Is_Primary__c, 'Unable to set new primary'); 
    }

    /**
     * @description if the contact is not student, no user-overriden-primary, and no non-monash emails
     * pick the latest monash email as primary
     */
    @isTest
    static void shouldSetMonashEmailAsPrimaryforNonStudentWithoutMonashEmailAndUserOverrides() {

        // GIVEN

        Email__c email1 = new Email__c();
        email1 = (Email__c) fflib_ApexMocksUtils.setReadOnlyFields(
            email1,
            Email__c.class,
            new Map<SObjectField, Object> {
                Email__c.Id => fflib_IDGenerator.generate(Email__c.SObjectType),
                Email__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Email__c.Start_Date__c => Date.today().addDays(-1),
                Email__c.CreatedDate => System.now().addDays(-1),
                Email__c.Classification__c => 'Monash',
                Email__c.Primary_set_by__c => 'autoproc',
                Email__c.Is_Primary__c => false
            }
        );

        Map<Id, Email__c> emailMapResult;


        Test.startTest();

        // WHEN
        PrimaryEmailCalculator calculator = new PrimaryEmailCalculator(
            new List<Email__c>{ email1 },
            false // non-student
        );
        emailMapResult = new Map<Id, Email__c>((List<Email__c>)calculator.execute());

        Test.stopTest();

        // THEN

        // monash email should be set to primary
        Assert.areEqual(true, emailMapResult.get(email1.Id).Is_Primary__c, 'Unable to set new primary'); 
    }
}