/**
 * @author      Sachin Shetty
 * @description Test Class for AddressSearchWrapper
 * @group       Test Class
 * @revision    2022-10-12 - Sachin Shetty - Removed country attribute related test method
 *              2022-08-25 - Sachin Shetty - Created
 * */
@isTest(isParallel=true)
public class AddressSearchWrapper_Test {

    // Test just for code coverage, no logic in the code, just fetching the wrapper
    @isTest
    static void testGetAddressWrapper()
    {
        // Given
        // When
        AddressSearchWrapper.AddressWrapper addWrapper = AddressSearchController.getAddressWrapper();
        
        // Then
        System.assertNotEquals(null, addWrapper, 'Wrapper not returned');
    }
}