/**
 * @author      Kristian Vegerano
 * @description Selector class for country attribute object processes
 * @group       Selectors
 * @revision    31/05/2019 - Kristian Vegerano - Created
 * @revision    2/08/2022 - Ken McGuire - SFTG-2700
 * @revision    28/11/2023 - Peter Sewell - Added method to check if country is supported by SFDC SMS
 */
public without sharing class CountriesSelector extends BaseSelector {
    /**
     * Constructors
     */
	public CountriesSelector() {
	    super(false);
	}
	
    public CountriesSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      Kristian Vegerano
     * @date        17/05/2019
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return Country_Attribute__c.sObjectType;
	}
    
	/**
     * @author      Kristian Vegerano
     * @date        17/05/2019
     * @description Query countries by ids
     */
    public List<Country_Attribute__c> selectById(Set<Id> idSet) {
		return (List<Country_Attribute__c>) selectSObjectsById(idSet);
	}
	
	/**
     * @author      Kristian Vegerano
     * @date        17/05/2019
     * @description Query countries by names
     */
    public List<Country_Attribute__c> selectByName(Set<String> namesSet) {
        assertIsAccessible();
        
        String queryString = String.format('SELECT {0} FROM {1} WHERE Name IN :namesSet ORDER BY {2}', 
		                                   new List<String>{getFieldListString(),
                                                            getSObjectName(),
                                                            getOrderBy()});
		return Database.query(queryString);
	}

    
    /**
     * @author      Ken McGuire
     * @date        1/08/2022
     * @description Query countries by names
     */
    public List<Country_Attribute__c> selectAll() {
        assertIsAccessible();
        
        String queryString = String.format('SELECT {0} FROM {1} ORDER BY {2}', 
		                                   new List<String>{getFieldListString(),
                                                            getSObjectName(),
                                                            getOrderBy()});
		return Database.query(queryString);
	}
    
    public static List<Country_Attribute__c> validCountryList() {
        Map<String,Country_Attribute__c> validCountryMap = new Map<String,Country_Attribute__c>();
            for(Country_Attribute__c country : new CountriesSelector(true).selectAll()) {
                if (isApplicable(country)) {
                	validCountryMap.put(getKey(country),country);
                }
            }
        return validCountryMap.values();
    }
     // returns a unique key for country attribute 
    private static string getKey(Country_Attribute__c country) {
        return country.ShortName__c + country.NumericPhoneCode__c;
    }
    
     /**
     * @author      Ken McGuire
     * @description Determines if a country should be displayed to the user
     * @param       the country attribute 
     * @return      true if the country should be displayed
     * @revision    08/01/2022 - Ken McGuire - Created
     */
    private static boolean isApplicable(Country_Attribute__c country) {
        return country.Blocked__c == false && !String.isEmpty(country.ShortName__c) && !String.isEmpty(country.NumericPhoneCode__c);
    }

    /**
     * @author      Peter Sewell
     * @description Determines if a country phone code is NOT supported by Salesforce SMS service
     * @param       the country code. Can be supplied with or without leading + 
     * @return      true if the country phone code is not suported by SFDC SMS service
     * @revision    27-NOV-23 - Peter Sewell - Created
     */
    public boolean isSfdcSmsUnsupported(String countryCode) {
        
        if (String.isBlank(countryCode)) {
            return false;
        }

        // Remove leading + if present
        if (countryCode.startsWith('+')) {
            countryCode = countryCode.substring(1);
        }

        // Check SFDC unsupported country flag for the country corresponding to this phone code

        String queryString = String.format('SELECT {0} FROM {1} WHERE NumericPhoneCode__c = :countryCode ORDER BY {2}', 
		                                   new List<String>{getFieldListString(),
                                                            getSObjectName(),
                                                            getOrderBy()});

        // Unsupported country code ? 
        // Note where multiple countries share the same country code 
        // then return true if *any* of them is flagged as unsupported
        for (Country_Attribute__c country : Database.Query(queryString)) {
            if (country.SFDC_SMS_Unsupported__c == true) {
                return true; // Unsupported country code
            }
        }

        // Supported country
        return false;
    }

    /**
     * @author      Vishal Gupta
     * @date        21/03/2025
     * @description Query countries by names
     */
    public List<Country_Attribute__c> selectAllCountries() {
        assertIsAccessible();
        
        String queryString = String.format('SELECT {0} FROM {1} WHERE ShortName__c != NULL AND NumericPhoneCode__c != NULL ORDER BY {2}', 
		                                   new List<String>{getFieldListString(),
                                                            getSObjectName(),
                                                            getOrderBy()});
        Map<String,Country_Attribute__c> validCountryMap = new Map<String,Country_Attribute__c>();
        for(Country_Attribute__c ca: Database.query(queryString)) {
            validCountryMap.put(getKey(ca),ca);
        }                                                 
		return validCountryMap.values();
	}

    /**
     * @author      Vishal Gupta
     * @description Determines if a country is NOT sacntioned by Salesforce 
     * @param       the country code. Can be supplied with or without leading + 
     * @return      true if country is sacntioned by Salesforce
     * @revision    21-Mar-25 - Peter Sewell - Created
     */
    public boolean isSanctionedBySFDC(String countryCode) {
        
        if (String.isBlank(countryCode)) {
            return false;
        }

        // Remove leading + if present
        if (countryCode.startsWith('+')) {
            countryCode = countryCode.substring(1);
        }

        // Check SFDC unsupported country flag for the country corresponding to this phone code
        String queryString = String.format('SELECT {0} FROM {1} WHERE NumericPhoneCode__c = :countryCode AND Sanctioned_by_Salesforce__c = TRUE ORDER BY {2}', 
		                                   new List<String>{getFieldListString(),
                                                            getSObjectName(),
                                                            getOrderBy()});

        if(Database.query(queryString).size() > 0) {
            return true;
        } else {
            return false;
        }
    }
}