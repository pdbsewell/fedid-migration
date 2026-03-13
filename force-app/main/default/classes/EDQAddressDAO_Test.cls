/**
 * @author      Sachin Shetty
 * @description Test Class for EDQAddressDAO
 * @group       Test Class
 * @revision    2022-06-17 - Sachin Shetty - Created
**/
// This test just for code coverage. It's a wrapper, no logic to be tested.
@isTest(isParallel=true)
public class EDQAddressDAO_Test {

    @isTest
    static void testEDQAddressDAO() {
        // Given

        // When
        EDQAddressDAO.AddressRequest addressRequest = new EDQAddressDAO.AddressRequest();
        addressRequest.country_iso = 'AUS';
        addressRequest.max_suggestions = 7;
        EDQAddressDAO.AddressRequest addressRequestWithInput = new EDQAddressDAO.AddressRequest('Test');
        EDQAddressDAO.AddressResponse addressResponse = new EDQAddressDAO.AddressResponse();
        EDQAddressDAO.AddrResult addressResult = new EDQAddressDAO.AddrResult();
        EDQAddressDAO.AddressFormatResponse addressFormatResponse = new EDQAddressDAO.AddressFormatResponse();
        EDQAddressDAO.AddrSuggestions addressSuggestion = new EDQAddressDAO.AddrSuggestions();

        // Then
        System.assertNotEquals(null, addressRequest, 'Request wrapper not returned');
        System.assertNotEquals(null, addressRequestWithInput, 'Request wrapper with input not returned');
        System.assertNotEquals(null, addressResponse, 'Response wrapper not returned');
        System.assertNotEquals(null, addressResult, 'Result wrapper not returned');
        System.assertNotEquals(null, addressFormatResponse, 'Address Format response wrapper not returned');
        System.assertNotEquals(null, addressSuggestion, 'Address suggestion wrapper not returned');
    }
}