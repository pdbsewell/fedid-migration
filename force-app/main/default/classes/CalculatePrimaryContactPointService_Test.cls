/**
 * @description       : test class for CalculatePrimaryContactPointService
 * @author            : Nick Guia
 * @last modified on  : 23-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class CalculatePrimaryContactPointService_Test {

    /**
     * test that calculatePrimaryAddress processes the input and returns the primary record
     */
    @isTest
    static void shouldCalculatePrimaryAddress() {

        // GIVEN

        // create addresses
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

        CalculatePrimaryContactPointService.Input param = new CalculatePrimaryContactPointService.Input(true);
        param.shouldSort = true;
        param.addressList= new List<Address__c> { address1, address2 };
        Address__c primaryAddress;

        Test.startTest();
        
        // WHEN
        primaryAddress = new CalculatePrimaryContactPointService().calculatePrimaryAddress(param);

        Test.stopTest();

        // THEN
        Assert.isNotNull(primaryAddress, 'Unexpected null value result from calculating primary address');
        Assert.areEqual(address2.Id, primaryAddress.Id, 'Unexpected result from calculating primary address');
    }

    /**
     * test that calculatePrimaryPhone processes the input and returns the primary record
     */
    @isTest
    static void shouldCalculatePrimaryPhone() {

        // GIVEN

        // create phones
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

        CalculatePrimaryContactPointService.Input param = new CalculatePrimaryContactPointService.Input(true);
        param.shouldSort = true;
        param.phoneList = new List<Phone__c> { phone1, phone2 };
        Phone__c primaryPhone;

        Test.startTest();
        
        // WHEN
        primaryPhone = new CalculatePrimaryContactPointService().calculatePrimaryPhone(param);

        Test.stopTest();

        // THEN
        Assert.isNotNull(primaryPhone, 'Unexpected null value result from calculating primary phone');
        Assert.areEqual(phone2.Id, primaryPhone.Id, 'Unexpected result from calculating primary Phone');
    }

    /**
     * test that calculatePrimaryEmail processes the input and returns the primary record
     */
    @isTest
    static void shouldCalculatePrimaryEmail() {

        // create emails
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

        CalculatePrimaryContactPointService.Input param = new CalculatePrimaryContactPointService.Input(true);
        param.shouldSort = true;
        param.emailList = new List<Email__c> { email1, email2 };
        Email__c primaryEmail;

        Test.startTest();
        
        // WHEN
        primaryEmail = new CalculatePrimaryContactPointService().calculatePrimaryEmail(param);

        Test.stopTest();

        // THEN
        Assert.isNotNull(primaryEmail, 'Unexpected null value result from calculating primary email');
        Assert.areEqual(email2.Id, primaryEmail.Id, 'Unexpected result from calculating primary Email');
    }

    /**
     * test that calculatePrimaryName processes the input and returns the primary record
     */
    @isTest
    static void shouldCalculatePrimaryName() {

        // create names
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

        CalculatePrimaryContactPointService.Input param = new CalculatePrimaryContactPointService.Input(true);
        param.shouldSort = true;
        param.nameList = new List<Name__c> { name1, name2 };
        Name__c primaryName;

        Test.startTest();
        
        // WHEN
        primaryName = new CalculatePrimaryContactPointService().calculateprimaryName(param);

        Test.stopTest();

        // THEN
        Assert.isNotNull(primaryName, 'Unexpected null value result from calculating primary email');
        Assert.areEqual(name2.Id, primaryName.Id, 'Unexpected result from calculating primary Email');
    }

    /**
     * test if the calculate method throws an exception when given a null argument
     */
    @isTest
    static void shouldThrownAnExceptionWithNullArgument() {

        // GIVEN
        CalculatePrimaryContactPointService.Input param = null;

        Test.startTest();

        // WHEN
        try {
            CalculatePrimaryContactPointService service = new CalculatePrimaryContactPointService();
            service.calculate(param);
            Assert.fail('Unable to throw an exception when provided a null parameter');
        } catch(CalculatePrimaryContactPointService.CalculatePrimaryContactPointServiceException e) {
            // THEN
            Assert.isTrue(true);
        } catch(Exception e) {
            Assert.fail('An unexpected type of Exception occurred');
        }

        Test.stopTest();
    }

    /**
     * test that the calculate method runs all primary calculations
     */
    @isTest
    static void shouldExecuteAllPrimaryCalculation() {

        // GIVEN

        // create a BaseClass
        BaseClass bc = new BaseClass(new List<Schema.SObjectType> {
            Address__c.SObjectType,
            Email__c.SObjectType,
            Phone__c.SObjectType,
            Name__c.SObjectType
        });
        
        // create emails
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

        // create phones
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

        // create addresses
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
        // create names
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

        CalculatePrimaryContactPointService.Output output;

        Test.startTest();

        // WHEN
        CalculatePrimaryContactPointService.Input param = new CalculatePrimaryContactPointService.Input(true);
        param.shouldSort = true;
        param.emailList = new List<Email__c> { email1, email2 };
        param.phoneList = new List<Phone__c> { phone1, phone2 };
        param.addressList= new List<Address__c> { address1, address2 };
        param.nameList = new List<Name__c> { name1, name2 };
        param.bc = bc;

        output = new CalculatePrimaryContactPointService().calculate(param);

        Test.stopTest();

        // THEN
        Assert.isNotNull(output.primaryAddress, 'Unexpected null value result from calculating primary Address');
        Assert.isNotNull(output.addressList, 'Unexpected null value result from calculating primary Address');

        Assert.isNotNull(output.primaryPhone, 'Unexpected null value result from calculating primary Phone');
        Assert.isNotNull(output.phoneList, 'Unexpected null value result from calculating primary Phone');

        Assert.isNotNull(output.primaryEmail, 'Unexpected null value result from calculating primary Email');
        Assert.isNotNull(output.emailList, 'Unexpected null value result from calculating primary Email');
        
        Assert.isNotNull(output.primaryName, 'Unexpected null value result from calculating primary Name');
        Assert.isNotNull(output.nameList, 'Unexpected null value result from calculating primary Name');
        
        Assert.isNotNull(output.bc, 'Unexpected null value of BaseClass');
    }
}