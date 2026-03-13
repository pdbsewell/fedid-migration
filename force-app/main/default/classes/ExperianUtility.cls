/**
 * @author      Sachin Shetty
 * @description Utility class providing general utility methods to Experian components
 *              Access modifier is 'without sharing' so that all users(authenticated and unauthenticated) 
 *              have access to the Country_Attribute__c object
 * @group       Controllers
 * @testclass   ExperianUtility_Test
 * @revision    2022-10-17 - Sachin Shetty - IPCheckExceedsLimit updated to uniquely identify each guest user
 *              2022-10-12 - Sachin Shetty - Moved country select related code to utility class
 *              2022-10-03 - Sachin Shetty - Created
**/
public without sharing class ExperianUtility {

    /**
     * @author      Sachin Shetty
     * @description Setting used to control certain features of Experian data validation
     * @param       na
     * @return      EDQ_Settings__c instance
     * @revision    2022-08-12 - Sachin Shetty - Created
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
     * @description Static reference to countries Monash has it's campuses in
     * @param       na
     * @return      List<String>
     * @revision    2022-08-12 - Sachin Shetty - Created
     */
    public static List<String> topCountries {
        get {
            if (topCountries == null) {
                String countries = EDQSettings.Top_Countries__c;
                topCountries = !String.isBlank(countries)
                                ? countries.split(',')
                                : new List<String>();
            }
            return topCountries;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the country attributes required for the selection of Country
     * @return      List<Country_Attribute__c>
     * @revision    2022-10-12 - Sachin Shetty - Created
     */
    public static List<Country_Attribute__c> getAllCountries() {
        Set<String> uniqueOptions = new Set<String>();
        List<Country_Attribute__c> allCountries = new List<Country_Attribute__c>();

        try{
            for (Country_Attribute__c objCountry : [
                    SELECT ISO_Alpha_2__c, ISO_Alpha_3__c, Country__c
                    FROM Country_Attribute__c
                    WHERE Country__c != NULL AND ISO_Alpha_2__c != NULL AND ISO_Alpha_3__c != NULL
                    ORDER BY Name ASC
            ]) {
                // add option if its not added yet on the unique set of string
                if(!uniqueOptions.contains(objCountry.Country__c)){
                    allCountries.add(objCountry);
                }

                // add the country name on the unique set
                uniqueOptions.add(objCountry.Country__c);
            }
        }   
        catch(Exception e){
            LogUtilityException.logException(e);
            throw e;
        }
        return allCountries;
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the country attributes required for the selection of Country
     * @return      List<Country_Attribute__c>
     * @revision    2022-10-12 - Sachin Shetty - Created
     */
    public static List<Country_Attribute__c> allCountries{
        get {
            if (allCountries == null) {
                allCountries = getAllCountries();
            }
            return allCountries;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the frequently used countries list based on those mentioned in the EDQSettings custom settings
     * @return      List<Country_Attribute__c>
     * @revision    2022-10-12 - Sachin Shetty - Created
     */
    public static List<Country_Attribute__c> topCountriesList{
        get {
            if (topCountriesList == null) {
                topCountriesList = new List<Country_Attribute__c>();
                for(Country_Attribute__c objCountry : allCountries){
                    if(topCountries.contains(objCountry.Country__c.toUpperCase())){
                        topCountriesList.add(objCountry);
                    }
                }
            }
            return topCountriesList;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the list of countries excluding the frequently used ones
     * @return      List<Country_Attribute__c>
     * @revision    2022-10-12 - Sachin Shetty - Created
     */
    public static List<Country_Attribute__c> restOfTheCountriesList{
        get {
            if (restOfTheCountriesList == null) {
                restOfTheCountriesList = new List<Country_Attribute__c>();
                for(Country_Attribute__c objCountry : allCountries){
                    if(!topCountries.contains(objCountry.Country__c.toUpperCase())){
                        restOfTheCountriesList.add(objCountry);
                    }
                }
            }
            return restOfTheCountriesList;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the minimum seconds between invocations from the custom setting
     * @param       String customSettingName
     * @return      Integer
     * @revision    2022-10-03 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static Integer getMinimumSecondsBetweenInvocations(String customSettingName){
        IP_Rate_Limit_Settings__c settings = IP_Rate_Limit_Settings__c.getValues(customSettingName);
        Integer minSecondsBetweenInvocations = 0;
        minSecondsBetweenInvocations = (settings == null || settings.Min_Secs_Between_Invocations__c == null)
                                        ? 0
                                        : (Integer) settings.Min_Secs_Between_Invocations__c;
        return minSecondsBetweenInvocations;
    }

    /**
     * @author      Sachin Shetty
     * @description Check IP limit.
     * @param       String customSettingName
     * @param       String guestKey
     * @return      Boolean
     * @revision    2022-10-17 - Sachin Shetty - Update to uniquely identify each guest user
     *              2022-10-03 - Sachin Shetty - Created
     */
    public static Boolean IPCheckExceedsLimit(String customSettingName, String guestKey){
        String rateLimitKey = (Auth.CommunitiesUtil.isGuestUser() == true) ? guestKey : UserInfo.getUserId();
        IP_RateLimitUtility rateLimit = new IP_RateLimitUtility(customSettingName, rateLimitKey);
        return rateLimit.exceedsRateLimit();
    }
}