/**
 * @description       : Test class for AddressComparable
 * @author            : Nick Guia
 * @last modified on  : 03-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class AddressComparable_Test {

    /**
     * The only difference of this class from the ContactPointComparable base implementation
     * is that it wouldn't compare channels when start dates and created dates are the same.
     * If this is the case, it should return 0
     */
    @isTest
    static void shouldReturnZeroWhenStartDateAndCreatedDateAreEqual() {

        // GIVEN
        Address__c address1 = new Address__c();
        address1 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address1,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Channel__c => null, // null channel so we can verify
                Address__c.Start_Date__c => Date.today(),
                Address__c.CreatedDate => System.now()
            }
        );
        
        Address__c address2 = new Address__c();
        address2 = (Address__c) fflib_ApexMocksUtils.setReadOnlyFields(
            address2,
            Address__c.class,
            new Map<SObjectField, Object> {
                Address__c.Id => fflib_IDGenerator.generate(Address__c.SObjectType),
                Address__c.Channel__c => fflib_IDGenerator.generate(Channel__c.SObjectType), // add a channel so we can verify
                Address__c.Start_Date__c => address1.Start_Date__c,
                Address__c.CreatedDate => address1.CreatedDate
            }
        );

        Integer compareResult;
        
        Test.startTest();

        // WHEN
        AddressComparable comparable = new AddressComparable(address1);
        compareResult = comparable.runRuleChain(address1, address2);
        
        Test.stopTest();

        // THEN
        Assert.isNotNull(compareResult, 'Unexpected evaluation result');
        Assert.areEqual(0, compareResult, 'Unexpected evaluation result');
    }
}