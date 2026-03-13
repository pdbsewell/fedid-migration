/**
 * @author      Paul Victoriano
 * @description Apex controller class for actions required on addressSearchEDQ lwc
 * @group       Controllers
 * @testclass   AddressSearchController_Test
 * @revision    2022-10-17 - Sachin Shetty   - Update to uniquely identify each guest user
 *              2022-10-12 - Sachin Shetty   - Changed references from AddressWrapper to ExperianUtility to fetch country attributes
 *              2022-10-03 - Sachin Shetty   - Rate Limiting related changes
 *              2022-08-24 - Sachin Shetty   - getCountryAttributes method updated to return Country Attribute records
 *              2022-07-28 - Sachin Shetty   - Refactor, comments and cleanup
 *              2022-06-17 - Sachin Shetty   - Refactor, comments and cleanup
 *              2022-06-17 - Paul Victoriano - Created
**/
public with sharing class AddressSearchController {

    private static final string ERROR_PROCESSING_REQUEST = 'Experian - Rate limit exception formatting address.';

    /**
     * @author      Paul Victoriano
     * @description Returns the address DAO for the entered address search string
     * @param       String searchTerm
     * @param       String countryISO
     * @return      Object
     * @revision    2022-06-17 - Paul Victoriano - Created
     */
    @AuraEnabled
    public static EDQAddressDAO.AddressResponse search(String searchTerm, String countryISO){
        EDQAddressService stub = new EDQAddressService();
        return stub.searchAddress(searchTerm, countryISO);
    }

    /**
     * @author      Paul Victoriano
     * @description Returns the formatted address DAO
     * @param       String addressKey
     * @param       String customSettingName
     * @param       String guestKey
     * @return      Object
     * @revision    2022-10-17 - Sachin Shetty   - Update to uniquely identify each guest user
     *              2022-10-03 - Sachin Shetty   - Rate Limiting related changes
     *              2022-06-17 - Paul Victoriano - Created
     */
    @AuraEnabled
    public static EDQAddressDAO.AddressFormatResponse format(String addressKey, String customSettingName, String guestKey){
        try{
            if(!ExperianUtility.IPCheckExceedsLimit(customSettingName, guestKey)){
                EDQAddressService stub = new EDQAddressService();
                return stub.formatAddress(addressKey);
            }
            else{
                LogUtilityException.logExceptionMSG('AddressSearchController.format', 'Address global key', ERROR_PROCESSING_REQUEST);
                return null;
            }
        }catch (Exception ex) {
            LogUtilityException.logException(ex);
            System.debug(LoggingLevel.ERROR, ex.getMessage() + ' ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the Address wrapper
     * @return      AddressWrapper
     * @revision    2022-07-08 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static AddressSearchWrapper.AddressWrapper getAddressWrapper() {
        return new AddressSearchWrapper.AddressWrapper();
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the frequently used countries list
     * @return      List<Country_Attribute__c>
     * @revision    2022-10-12 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static List<Country_Attribute__c> getTopCountriesList() {
        return ExperianUtility.topCountriesList;
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the list of countries excluding the frequently used ones
     * @return      List<Country_Attribute__c>
     * @revision    2022-10-12 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static List<Country_Attribute__c> getRestOfTheCountriesList() {
        return ExperianUtility.restOfTheCountriesList;
    }
}