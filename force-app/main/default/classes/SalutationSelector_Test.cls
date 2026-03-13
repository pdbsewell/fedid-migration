/**
 * @description       : test class for SalutationSelector
 * @author            : Mac Domingo
 * @last modified on  : 24-07-2023
 * @last modified by  : NMac Domingo
**/
@isTest
private  class SalutationSelector_Test {

    /**
     * @description : test the Salutation query by passing a contact Id. 
    */ 
    @isTest
    static void test_selectByConstituentsId() {

        // Create test data
        Contact con = new Contact(LastName = 'Test', Email = 'testdev@gmail.com');
        insert con;
        
        // Create salutation record
        ucinn_ascendv2__Salutation__c salutation = new ucinn_ascendv2__Salutation__c();
        salutation.ucinn_ascendv2__Contact__c = con.Id;
        // Set other required fields
        
        Test.startTest();
        
        // Insert salutation record
        insert salutation;
        
        // Call the method being tested
        SalutationSelector selector = new SalutationSelector();
        List<ucinn_ascendv2__Salutation__c> resultList = selector.selectByConstituentId(new Set<Id>{con.Id});
        
        // Assert that the result list is not null and has at least one element
        System.assertNotEquals(null, resultList, 'Result list should not be null');
        System.assertNotEquals(0, resultList.size(), 'Result list should have at least one element');
        
        Test.stopTest();
    }

    
}