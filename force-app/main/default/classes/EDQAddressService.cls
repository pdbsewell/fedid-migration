/**
 * @author      Paul Victoriano
 * @description Service class for retrieving and formatting address
 * @group       Services
 * @testclass   EDQAddressService_Test
 * @revision    2022-06-17 - Paul Victoriano - Created
 *              2022-06-17 - Sachin Shetty   - Refactor, comments and cleanup
 *              2022-08-24 - Sachin Shetty   - Handle Experian Service Unavailable
 *              2022-11-28 - Sachin Shetty   - Update to capture address at granular level
**/
public with sharing class EDQAddressService {

    public final string ADDRESS_SEARCH_NOT_AUTHORIZED_MESSAGE = 'Experian address search authentication failed.';
    public final string ADDRESS_SEARCH_UNSUCCESSFUL_MESSAGE = 'Experian address search unsuccessful';
    public final string ADDRESS_FORMAT_NOT_AUTHORIZED_MESSAGE = 'Experian address format authentication failed.';
    public final string ADDRESS_FORMAT_UNSUCCESSFUL_MESSAGE = 'Experian address format unsuccessful.';
    public final string EXPERIAN_CREDITS_INSUFFICIENT = 'Invalid authentication token or insufficient Experian credits';
    public final string EXPERIAN_SERVICE_UNAVAILABLE = 'Experian service unavailable';
    public final string RESPONSE_FROM_MESSAGE = 'response from Experian';
    public final string RESPONSE_STATUS_CODE_MESSAGE = 'Response status code';

    /**
     * @author      Sachin Shetty
     * @description Setting used to control certain features of Experian data validation
     * @param       na
     * @return      EDQ_Settings__c instance
     * @revision    2022-06-30 - Sachin Shetty - Created
     */
    public static EDQ_Settings__c EDQSettings {
        get {
            if (EDQSettings == null) {
                // look in custom setting
                EDQSettings = EDQ_Settings__c.getOrgDefaults();
            }
            return EDQSettings;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description Static reference to number of suggestions a search request should return
     * @param       na
     * @return      Integer
     * @revision    2022-06-30 - Sachin Shetty - Created
     */
    public static Integer maxSuggestions {
        get {
            if (maxSuggestions == null) {
                // if setting is not present, make default 7
                maxSuggestions = (Integer) (EDQSettings != null
                                ? EDQSettings.Max_Address_Suggestions__c != null 
                                    ? EDQSettings.Max_Address_Suggestions__c 
                                    : 7
                                : 7);
            }
            return maxSuggestions;
        } set;
    }

    /**
     * @author      Paul Victoriano
     * @description Callout to Experian with the address search string and returns possible matches
     * @param       String searchTerm
     * @param       String countryISO
     * @return      Object
     * @revision    2022-06-17 - Paul Victoriano - Created
     *              2022-08-24 - Sachin Shetty   - Handle Experian service unavailable
     */
    public EDQAddressDAO.AddressResponse searchAddress(String addressStr, String countryISO) {
        
        EDQAddressDAO.AddressRequest reqDAO = new EDQAddressDAO.AddressRequest(addressStr);
        reqDAO.country_iso = countryISO;
        reqDAO.max_suggestions = maxSuggestions;

        String jbodyReq = JSON.serializePretty(reqDAO);
        //
        HttpRequest req = new HttpRequest();
        //Path address/search/v1
        req.setEndpoint('callout:EDQService/address/search/v1');
        req.setMethod('POST');
        req.setBody(jbodyReq);
        req.setHeader('Auth-Token','{!$Credential.Password}');
        req.setHeader('Reference-Id','searchAddress:'+UserInfo.getUserId());
        req.setHeader('Timeout-Seconds','10');
        req.setHeader('Content-Type','application/json');

        EDQAddressDAO.AddressResponse addressSearchResult = null;
        try{
            Http http = new Http();
            HTTPResponse response = http.send(req);
            String resultString = response.getBody();            
            addressSearchResult = (EDQAddressDAO.AddressResponse)JSON.deserialize(resultString, EDQAddressDAO.AddressResponse.class);
            EDQAddressDAO.AddrResult result = new EDQAddressDAO.AddrResult();

            if(Label.Mock_Experian_Service_Unavailable == 'true' || Label.Mock_Insufficient_Experian_Credits == 'true'){
                EDQAddressDAO.AddrResult blankResult = new EDQAddressDAO.AddrResult();
                blankResult.more_results_available = false;
                blankResult.confidence = '';
                addressSearchResult.result = blankResult;
                if(Label.Mock_Experian_Service_Unavailable == 'true'){
                    addressSearchResult.result.confidence = 'Service Unavailable';
                    response.setStatusCode(503);
                }
                if(Label.Mock_Insufficient_Experian_Credits == 'true'){
                    addressSearchResult.result.confidence = 'Forbidden';
                    response.setStatusCode(403);
                }
            }

            switch on response.getStatusCode() {
                when 200 { // indicates success response
                    addressSearchResult = (EDQAddressDAO.AddressResponse)JSON.deserialize(resultString, EDQAddressDAO.AddressResponse.class);
                }
                when 401 { // indicates invalid authorization
                    LogUtilityException.logExceptionMSG('EDQAddressService.searchAddress' ,'Endpoint: \n' + req.getEndpoint(), ADDRESS_SEARCH_NOT_AUTHORIZED_MESSAGE);
                    throw new EDQUnauthorizedAccessException(ADDRESS_SEARCH_NOT_AUTHORIZED_MESSAGE);
                }
                when 403 { // indicates insufficient Experian credits
                    addressSearchResult.result = result;
                    addressSearchResult.result.confidence = 'Forbidden';
                    LogUtilityException.logExceptionMSG('EDQAddressService.searchAddress' ,'Endpoint: \n' + req.getEndpoint(), EXPERIAN_CREDITS_INSUFFICIENT);
                }
                when 503 { // indicates Experian service unavailable
                    addressSearchResult.result = result;
                    addressSearchResult.result.confidence = 'Service Unavailable';
                    LogUtilityException.logExceptionMSG('EDQAddressService.searchAddress' ,'Endpoint: \n' + req.getEndpoint(), EXPERIAN_SERVICE_UNAVAILABLE);
                }
                when else {
                    throw new EDQUnauthorizedAccessException(ADDRESS_SEARCH_UNSUCCESSFUL_MESSAGE + ' for address : ' + addressStr + ' and country : '+ countryISO
                                + '. ' + RESPONSE_STATUS_CODE_MESSAGE + ': ' + String.valueOf(response.getStatusCode())
                                + ', ' + RESPONSE_FROM_MESSAGE + ': ' + response.getBody());
                }
            }
        }
        catch (Exception e){
            LogUtilityException.logException(e,'EDQAddressService.searchAddress');
            LogUtilityException.throwMSG(e.getMessage());
        }
        return addressSearchResult;
    }

    /**
     * @author      Paul Victoriano
     * @description Callout to Experian with the address key and returns formatted address
     * @param       String searchTerm
     * @return      Object
     * @revision    2022-06-17 - Paul Victoriano - Created
     *              2022-08-24 - Sachin Shetty   - Handle Experian service unavailable
     *              2022-11-28 - Sachin Shetty   - Update to capture address at granular level
     */
    public EDQAddressDAO.AddressFormatResponse formatAddress(String addressKey) {
        HttpRequest req = new HttpRequest();
        //Path address/format/v1/
        req.setEndpoint('callout:EDQService/address/format/v1/'+addressKey);
        req.setMethod('GET');
        req.setHeader('Auth-Token','{!$Credential.Password}');
        req.setHeader('Reference-Id','formatAddress:'+UserInfo.getUserId());
        req.setHeader('Add-Metadata','true');
        req.setHeader('Add-Components','true');
        req.setHeader('Timeout-Seconds','10');
        req.setHeader('Content-Type','application/json');

        EDQAddressDAO.AddressFormatResponse formattedAddress = null;
        try{
            Http http = new Http();
            HTTPResponse response = http.send(req);
            String resultString = response.getBody();
            formattedAddress = (EDQAddressDAO.AddressFormatResponse)JSON.deserialize(resultString, EDQAddressDAO.AddressFormatResponse.class);
            EDQAddressDAO.AddFormResult result = new EDQAddressDAO.AddFormResult();

            switch on response.getStatusCode() {
                when 200 { // indicates success response
                    formattedAddress = (EDQAddressDAO.AddressFormatResponse)JSON.deserialize(resultString, EDQAddressDAO.AddressFormatResponse.class);
                }
                when 401 { // indicates invalid authorization
                    LogUtilityException.logExceptionMSG('EDQAddressService.formatAddress' ,'Endpoint: \n' + req.getEndpoint(), ADDRESS_FORMAT_NOT_AUTHORIZED_MESSAGE);
                    throw new EDQUnauthorizedAccessException(ADDRESS_FORMAT_NOT_AUTHORIZED_MESSAGE);
                }
                when 403 { // indicates insufficient Experian credits
                    formattedAddress.result = result;
                    formattedAddress.result.confidence = 'Forbidden';
                    LogUtilityException.logExceptionMSG('EDQAddressService.formatAddress' ,'Endpoint: \n' + req.getEndpoint(), EXPERIAN_CREDITS_INSUFFICIENT);
                }
                when 503 { // indicates Experian service unavailable
                    formattedAddress.result = result;
                    formattedAddress.result.confidence = 'Service Unavailable';
                    LogUtilityException.logExceptionMSG('EDQAddressService.formatAddress' ,'Endpoint: \n' + req.getEndpoint(), EXPERIAN_SERVICE_UNAVAILABLE);
                }
                when else {
                    throw new EDQUnauthorizedAccessException(ADDRESS_FORMAT_UNSUCCESSFUL_MESSAGE +
                                + ' ' + RESPONSE_STATUS_CODE_MESSAGE + ': ' + String.valueOf(response.getStatusCode()) 
                                + ', ' + RESPONSE_FROM_MESSAGE + ': ' + response.getBody());
                }
            }
        }
        catch (Exception e){
            LogUtilityException.logException(e,'EDQAddressService.formatAddress');
        }

        return formattedAddress;
    }

    /**
     * @author      Sachin Shetty
     * @description Retrieve country_attribute record for the supplied country string
     * @param       String country
     * @return      Country record
     * @revision    2023-12-19 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static Country_Attribute__c retrieveCountryRecord(String country) {
        return CountryServices.getCountry(country);
    }

    public class EDQUnauthorizedAccessException extends Exception {}
}