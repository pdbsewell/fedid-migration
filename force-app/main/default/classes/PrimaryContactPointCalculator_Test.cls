/**
 * @description       : Test class for PrimaryContactPointCalculator
 * @author            : Nick Guia
 * @group             : Person 360
 * @last modified on  : 12-09-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class PrimaryContactPointCalculator_Test {
    
    private class TestPrimaryContactPointCalculator extends PrimaryContactPointCalculator {

        @TestVisible
        private Boolean isPrioritisedPrimaryInvoked = false;
        @TestVisible
        private Boolean isCalculatePrimaryInvoked = false;

        public TestPrimaryContactPointCalculator(List<SObject> cpList, Boolean isStudent) {
            super(cpList, isStudent);
        }

        // this test will use AddressComparable as an example
        protected override ContactPointComparable createContactPointComparable(SObject contactPoint) {
            return new AddressComparable((Address__c) contactPoint);
        }

        protected override void maybeSetPrimaryByPrioritisedAttributes() {
            this.isPrioritisedPrimaryInvoked = true;
        }
    
        protected override void calculatePrimary() {
            this.isCalculatePrimaryInvoked = true;
        }
    }

    /**
     * @description constructor call should throw an exception when provided with an empty list
     */
    @isTest
    static void shouldThrowAnExceptionWithEmptyConstructorArgument() {

        // GIVEN
        List<SObject> emptyList = new List<SObject>();

        Test.startTest();

        // WHEN
        try {
            TestPrimaryContactPointCalculator calculator = new TestPrimaryContactPointCalculator(emptyList, false);
            Assert.fail('Unable to throw a PrimaryContactPointCalculatorException with an empty list');
        } catch(PrimaryContactPointCalculator.PrimaryContactPointCalculatorException e) {
            // THEN
            Assert.isTrue(true);
        } catch (Exception e) {
            Assert.fail('A different exception was thrown when constructing with an empty list');
        }

        Test.stopTest();
    }

    /**
     * @description constructor call should throw an exception when provided with a null list
     */
    @isTest
    static void shouldThrowAnExceptionWithNullConstructorArgument() {

        // GIVEN
        List<SObject> nullList;

        Test.startTest();

        // WHEN
        try {
            TestPrimaryContactPointCalculator calculator = new TestPrimaryContactPointCalculator(nullList, false);
            Assert.fail('Unable to throw a PrimaryContactPointCalculatorException with an empty list');
        } catch(PrimaryContactPointCalculator.PrimaryContactPointCalculatorException e) {
            // THEN
            Assert.isTrue(true);
        } catch (Exception e) {
            Assert.fail('A different exception was thrown when constructing with an empty list');
        }

        Test.stopTest();
    }

    /**
     * @description verify that shouldSortContactPoints method updates the shouldSort variable
     */
    @isTest
    static void shouldUpdateShouldSortContactPoints() {

        // GIVEN
        TestPrimaryContactPointCalculator calculator;

        Test.startTest();

        // WHEN
        calculator = new TestPrimaryContactPointCalculator(
            new List<Email__c>{ new Email__c() }, 
            false
        );
        calculator.shouldSortContactPoints(true);


        Test.stopTest();

        // THEN
        Assert.isTrue(calculator.shouldSort, 'unable to set shouldSort to true');
    }

    /**
     * @description verify that setAllPrimaryToFalse untoggles any primary contact points
     */
    @isTest
    static void shouldSetAllPrimaryToFalse() {

        // GIVEN

        // a Monash address, which is typically the primary
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => true
            }
        );
        
        Address__c address2 = new Address__c();
        address2 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address2,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => false
            }
        );
        
        Address__c address3 = new Address__c();
        address3 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address3,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => false
            }
        );

        TestPrimaryContactPointCalculator calculator;

        Test.startTest();

        // WHEN
        calculator = new TestPrimaryContactPointCalculator(
            new List<Address__c>{ address1, address2, address3 }, 
            false
        );
        calculator.setAllPrimaryToFalse();


        Test.stopTest();
        
        // THEN
        Assert.isFalse(address1.Is_Primary__c, 'Unable to set all primary to false');
        Assert.isFalse(address2.Is_Primary__c, 'Unable to set all primary to false');
        Assert.isFalse(address3.Is_Primary__c, 'Unable to set all primary to false');
    }

    /**
     * @description create a List<ContactPointComparable> when asked to also sort the records
     * before finding the new primary
     */
    @isTest
    static void shouldCreateASortableList() {

        // GIVEN

        // a Monash address, which is typically the primary
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => true
            }
        );
        
        Address__c address2 = new Address__c();
        address2 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address2,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => false
            }
        );
        
        Address__c address3 = new Address__c();
        address3 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address3,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => false
            }
        );

        TestPrimaryContactPointCalculator calculator = new TestPrimaryContactPointCalculator(
            new List<Address__c>{ address1, address2, address3 }, 
            false
        );
        List<ContactPointComparable> sortableList;

        Test.startTest();

        sortableList = calculator.createSortableList();


        Test.stopTest();
        // THEN
        Assert.isTrue(sortableList != null, 'Unable to create a sortable list');
        Assert.isTrue(!sortableList.isEmpty(), 'Unable to create a sortable list');
        Assert.areEqual(3, sortableList.size(), 'Sortable list size does not match with the number of SObject input');
    }

    /**
     * @description in this test, we create 1 callista address, 1 non-callista address, and 1 blank source
     * in order to test the combination of different scenarios. We should only expect to accommodate for 
     * Callista-sourced contact points to be added in the ContactPointRankComparable list.
     */
    @isTest
    static void shouldAddRollupRankSortableList() {

        // GIVEN

        // callista address
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
        
        // blank source
        Address__c address2 = new Address__c();
        address2 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address2,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => '',
                Address__c.Callista_rollup_rank__c => '80'
            }
        );
        
        // non-callista source
        Address__c address3 = new Address__c();
        address3 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address3,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Contact supplied',
                Address__c.Callista_rollup_rank__c => '80'
            }
        );

        TestPrimaryContactPointCalculator calculator = new TestPrimaryContactPointCalculator(
            new List<Address__c>{ address1, address2, address3 }, 
            false
        );

        Test.startTest();

        // WHEN
        calculator.addRollupRankSortableList(address1);
        calculator.addRollupRankSortableList(address2);
        calculator.addRollupRankSortableList(address3);

        Test.stopTest();

        // THEN
        Assert.areEqual(1, calculator.rankComparableList.size(), 'Invalid number of records added to the comparable list');
    }

    /**
     * @description should return a null SObject if we attempt to get highest roll up rank
     * from a list of non-callista contact points
     */
    @isTest
    static void getHighestRollupRankShouldReturnNullIfComparableListIsEmpty() {

        // GIVEN

        // non-callista address
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Contact supplied'
            }
        );

        TestPrimaryContactPointCalculator calculator = new TestPrimaryContactPointCalculator(
            new List<Address__c>{ address1 }, 
            false
        );

        SObject highestRollUp;

        Test.startTest();

        // WHEN
        calculator.addRollupRankSortableList(address1);
        highestRollUp = calculator.getHighestRollupRank();

        Test.stopTest();

        // THEN
        Assert.isNull(highestRollUp, 'Invalid non-null value after sorting an empty comparable list');
    }

    /**
     * @description should return a non-null SObject if we attempt to get highest roll up rank
     * from a list of non-callista and callista contact points
     */
    @isTest
    static void getHighestRollupRankShouldReturnNonNullIfComparableListIsNotEmpty() {

        // GIVEN

        // non-callista address
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Contact supplied'
            }
        );

        // non-callista address
        Address__c address2 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address2,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Source__c => 'Callista'
            }
        );

        TestPrimaryContactPointCalculator calculator = new TestPrimaryContactPointCalculator(
            new List<Address__c>{ address1, address2 }, 
            false
        );

        SObject highestRollUp;

        Test.startTest();

        // WHEN
        calculator.addRollupRankSortableList(address1);
        calculator.addRollupRankSortableList(address2);
        highestRollUp = calculator.getHighestRollupRank();

        Test.stopTest();

        // THEN
        Assert.isNotNull(highestRollUp, 'Invalid null value after sorting by roll up rank');
    }

    /**
     * @description getRecordsFromSortedList should return the same list as the input (but sorted)
     */
    @isTest
    static void shouldGetRecordsFromSortableList() {

        // GIVEN

        // a Monash address, which is typically the primary
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => true
            }
        );
        
        Address__c address2 = new Address__c();
        address2 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address2,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => false
            }
        );
        
        Address__c address3 = new Address__c();
        address3 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address3,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => false
            }
        );

        TestPrimaryContactPointCalculator calculator = new TestPrimaryContactPointCalculator(
            new List<Address__c>{ address1, address2, address3 }, 
            false
        );
        List<ContactPointComparable> sortableList = calculator.createSortableList();
        sortableList.sort();
        List<SObject> sortableListSObjects;


        Test.startTest();

        // WHEN
        sortableListSObjects = calculator.getRecordsFromSortedList(sortableList);


        Test.stopTest();
        // THEN
        Assert.isTrue(sortableListSObjects != null, 'Unable to get records from the sortable list');
        Assert.isTrue(!sortableListSObjects.isEmpty(), 'Unable to get records from the sortable list');
        Assert.areEqual(3, sortableListSObjects.size(), 'Sortable list size does not match with the number of SObject input');
    }

    /**
     * @description verify that the execute method invokes all the necessary class methods
     * to calculate for the primary. The maybeSetPrimaryByPrioritisedAttributes() and calculatePrimary() 
     * were 'stubbed' as part of the TestPrimaryContactPointCalculator to verify method invocation during execute()
     */
    @isTest
    static void shouldExecuteMethods() {

        // GIVEN

        // a Monash address, which is typically the primary
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => true
            }
        );
        
        Address__c address2 = new Address__c();
        address2 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address2,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => false
            }
        );
        
        Address__c address3 = new Address__c();
        address3 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address3,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => false
            }
        );

        TestPrimaryContactPointCalculator calculator;
        Baseclass bc;


        Test.startTest();

        // WHEN
        calculator = new TestPrimaryContactPointCalculator(
            new List<Address__c>{ address1, address2, address3 }, 
            false
        );
        calculator.shouldSortContactPoints(true);
        calculator.setBaseClass(new BaseClass(
            new List<Schema.sObjectType>{ Address__c.SObjectType }
        ));
        calculator.execute();
        bc = calculator.getBaseClass();


        Test.stopTest();

        // THEN
        
        // verify that sortContactPoints was invoked
        Assert.isTrue(calculator.comparableList != null, 'Unable to invoke sortContactPoints()');
        // verify that maybeSetPrimaryByPrioritisedAttributes was invoked
        Assert.isTrue(calculator.isPrioritisedPrimaryInvoked, 'Unable to invoke maybeSetPrimaryByPrioritisedAttributes()');
        // verify that calculatePrimary was invoked
        Assert.isTrue(calculator.isCalculatePrimaryInvoked, 'Unable to invoke calculatePrimary()');
        // verify that Baseclass is not null
        Assert.isTrue(bc != null, 'Unexpected null Base Class');
    }

    /**
     * @description Should update the Is_Primary__c flag to true and store
     * the primary record within the class instance
     */
    @isTest
    static void shouldSetPrimary() {

        // GIVEN
        Address__c address = new Address__c();
        address = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Is_Primary__c => false
            }
        );

        TestPrimaryContactPointCalculator calculator;
        SObject calculatorPrimary;

        Test.startTest();

        // WHEN
        calculator = new TestPrimaryContactPointCalculator(
            new List<Address__c>{ address }, 
            false
        );
        calculator.setPrimary(address);
        calculatorPrimary = calculator.getPrimary();


        Test.stopTest();

        Assert.isNotNull(calculatorPrimary, 'Unable to store new primary within the class instance');
        Assert.areEqual(true, address.Is_Primary__c, 'Unable to set primary');
        Assert.areEqual(address.Id, calculatorPrimary.Id, 'Invalid primary store within the class instance');
    }
}