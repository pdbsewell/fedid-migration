/**@description       : Find a country record in the country attribute object
 * @author            : Martin Cadman
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2022-10-14   Martin Cadman   Initial basic version
 * 1.1   2022-10-27   Martin Cadman   Change the cache key from a raw name to a hash value, including a CA prefix to aid uniqueness
 * 1.2   2022-12-03   Martin Cadman   Some unsophisticated attempts to close the gap between the country values supplied and UniCRM data. 
 *                                    Included shortname as well as 4 other fields on country attribute to the SOQL as alternative identifiers.
 *                                    Added the stripping of multiple spaces, lead 'the' and digitals from the ocuntry name.   
 * 1.3  2022-02-16      Ken McGuire   Refactored for consolidation of services.
 * 20.3.2023	Ken McGuire - country of birth replace ISO with SAAC
**/
public without sharing class CountryServices {

    // Constants to denote the various standard country name list types 
   public static final String FORMAT_ISO = 'Country__c';
   public static final String FORMAT_SAAC = 'Callista_Country__c';
   public static final String FORMAT_SHORT = 'ShortName__c';

   private static final String FIELD_VALUE = 'value';
   @testVisible
   private static final String FIELD_LABEL = 'label';
   private static final String EMPTY_STRING = '';
   @testVisible
   private static final String EMPTY_OPTION = 'choose one...';
   
   private static Set<String> validFormats {
       get { 
           if (validFormats == null) validFormats = new Set<String>{FORMAT_ISO,FORMAT_SAAC,FORMAT_SHORT};
           return validFormats;
       }
       private set;     
   }
       
   /*
    * @description : converts a country name or country code in any format to a country name of a specified format
    * @parameter sourceCountry : the name or numeric code of the country to find 
    * @parameter listType : the format to convert the name into
    * @returns : the country name in the desired format 
    **/
   public static String getCountryName(String sourceCountry, String format) {
       if (formatInvalid(format)) return null;
       return getCountryName(searchCountryCached(sourceCountry),format);
   }
   
   /*
    * @description : Obtains a list of country options for use in UX picklists
    * @parameter format : the desired format for the country names
    * @returns : a list of lables and values for use by UX picklists
    **/
      public static List<Map<String,String>> getCountryAttributeOptions(String format, boolean includeEmptyOption) {
       if (formatInvalid(format)) return null;

       List<Map<String,String>>  options = new List<Map<String,String>>();
       
       if (includeEmptyOption) options.add(getEmptyOption());
       
       Map<String,Id> uniqueList = loadCountryAttributeList(format); 
       for(String currentCountry : uniqueList.keySet()) {
           // add country option
           options.add(new Map<String,String>{FIELD_LABEL => currentCountry, FIELD_VALUE => uniqueList.get(currentCountry)});            
       }
       return options;
   }
   
    /*
    * @description : Obtain a matching country record Id 
    * for a country name or numeric country code of any supported format
    * @parameter sourceCountry : the name of the country to find 
    * @returns : the country attribute record matching a country name 
    **/
    public static Id getCountryId(String sourceCountry) {
        Country_Attribute__c country =  searchCountryCached(sourceCountry);
        return country == null ? null : country.id;
    }

   /*
    * @description : Obtain a matching country record Id 
    * for a country name or numeric country code of a specified format
    * @parameter sourceCountry : the name of the country to find 
    * @parameter listType : the format to convert the name into
    * @returns : the country attribute record matching a country name 
    **/
    public static Id getCountryId(String sourceCountry, String format) {
        if (String.isBlank(sourceCountry) || String.isBlank(format)) return null;
        
        Country_Attribute__c country =  searchCountryCached(sourceCountry);
        return country == null || String.isBlank((String)country.get(format)) ? null : country.id;
    }

    /*
    * @description : Obtain a matching country attribute record 
    * for a country name or numeric country code of any supported format
    * @parameter sourceCountry : the name of the country to find 
    * @returns : the country attribute record matching a country name 
    **/
   public static Country_Attribute__c getCountry(String sourceCountry) {
       return searchCountryCached(sourceCountry);
   }

   private static Map<String,String> getEmptyOption() {
       return new Map<String, String>{FIELD_VALUE => EMPTY_STRING, FIELD_LABEL => EMPTY_OPTION};
   }
    
   /*
    * @description : obtains the country name of a specified format from a country attribute record
    * @parameter countryAttribute : the country attribute record to obtain the country name from 
    * @parameter format : the format of the country name to return
    * @returns : the country name in the desired format 
    **/
   public static String getCountryName(Country_Attribute__c countryAttribute, String format) {
       
       If(countryAttribute == null || String.isBlank(format)) return null;
       
       return (String)countryAttribute.get(format);

     }
   
   /*
    * @description : System Cached method of obtaining a matching country attribute record 
    * for a country name or numeric country code of any supported format
    * @parameter sourceCountry : the name of the country to find 
    * @returns : the country attribute record matching a country name 
    **/
   private static Country_Attribute__c searchCountryCached(String sourceCountry){
       Country_Attribute__c eCountry;
       if (String.isEmpty(sourceCountry)) return null;
       
       String sc = String.escapeSingleQuotes(SourceCountry);
       
       String cacheKey = getCacheKey(sc);
       
       try {
           // obtain record from cache
           if (Cache.Org.getName() != null) {
               // Cache in use
               eCountry = (Country_Attribute__c)Cache.Org.get(cacheKey);
               if (eCountry == null) {
                   // query db
                   eCountry = searchCountry(sc);
                   if (eCountry != null) {
                       // Cache result
                       Cache.Org.put(cacheKey, eCountry);
                   }                            
               }
           }
           else {
               // Cache not in use - query db
               eCountry = searchCountry(sc);
           }
       } catch (Cache.Org.OrgCacheException cex) { // no default Org cache defined on the platform
           logUtilityException.LogException (cex);
           eCountry = searchCountry(sc);
       } catch (Exception ex) {
           logUtilityException.LogException (ex, sc);
       }
                    
       return eCountry;
   }
   
   
   /*
    * @description : queries the country attribute table for the first matching 
    * country attribute record for a country name or numeric country code of any supported format
    * @parameter sourceCountry : the name of the country to find 
    * @returns : the country attribute record matching a country name 
    **/
   private static Country_Attribute__c searchCountry(String sourceCountry) {
       
       if (String.isBlank(sourceCountry)) return null;
       
       SObject[] eCountries = Database.query(buildCountryNameQueryString(sourceCountry.trim()));
       
       return eCountries.size() == 0  ? null : (Country_Attribute__c) eCountries[0];
   }
       
   /*
    * @description : builds a query to return the first matching country attribute table record 
    * for a country name or numeric country code of any supported format
    * @parameter safeValueToFind : a query safe string containing the name or numeric code of the country to find 
    * @returns : the country attribute record matching the country name or code
    **/
   // TODO: Convert to use the CRMUtility for SOQL execution
   private static string buildCountryNameQueryString(String safeValueToFind) {
        String queryString = 'SELECT id, name, Callista_Code__c, Callista_Country__c, Country__c, GTE_Risk_Rating__c,ISO_Alpha_2__c, ISO_Alpha_3__c, Numeric_Country_Code__c,ShortName__c, State_Name__c, Alt_Name_1__c, Alt_Name_2__c, Alt_Code__c'
           +' FROM Country_Attribute__c'
           + ' WHERE active_ind__c = true';
       if (safeValueToFind.isNumeric()) {
           queryString += ' AND ('
           + 'Alt_Code__c like \''+safeValueToFind+'\''
           +' OR Callista_Code__c like \''+safeValueToFind+'\''
           +' OR Numeric_Country_Code__c like \''+safeValueToFind+'\')';
       } else {
            String countryNameToFind =  stripString(safeValueToFind);
            queryString += ' AND ('
            + 'Alt_Code__c like \''+countryNameToFind+'\''
            +' OR Callista_Country__c like \''+countryNameToFind+'\''
            +' OR TOLABEL(Callista_Country__c) like \''+countryNameToFind+'\''
            +' OR Country__c like \''+countryNameToFind+'\''
            +' OR TOLABEL(Country__c) like \''+countryNameToFind+'\''
            +' OR ISO_Alpha_3__c like \''+countryNameToFind+'\''
            +' OR ISO_Alpha_2__c like \''+countryNameToFind+'\''
            +' OR Alt_Name_1__c like \''+countryNameToFind+'\''  // unicrm only field
            +' OR Alt_Name_2__c like \''+countryNameToFind+'\''  // unicrm only field
            +' OR State_Name__c like \''+countryNameToFind+'\''  // unicrm only field
            +' OR ShortName__c like \''+countryNameToFind+'\''
            +' OR Name like \''+countryNameToFind+'\')';
       }
       queryString += 'ORDER BY Name'  // For the UK, this will Select England as the SACC
               +' LIMIT 1';
       
       return queryString;
   }
   

   /*
    * @description : reutrns a full list of country names and associated country attribute record ID for a specified format
    * @parameter format : the format for the country list of names
    * @returns : a list of country attribute records for the desired format 
    **/
   private static Map<String,Id> loadCountryAttributeList(String format) {
       Map<String,Id> uniqueMap = new Map<String,Id>();
       for (SOBject currentCountry:  Database.query(buildCountryListQueryString(format))) {
           uniqueMap.put((String)currentCountry.get(format),currentCountry.id);
       }
       return uniqueMap;
   }
    
   /*
    * @description : builds a query to return  a complete list of country attribute records with a desired format
    * @parameter format : the format to return from the query
    * @returns : a query to obtain a list of country attribute records for the desired format 
    **/
    private static string buildCountryListQueryString(String  format) {
           return 'SELECT id,'+format 
           +' FROM Country_Attribute__c'
           + ' WHERE '+format+' != null'   
           + ' ORDER BY ' + format;
    }
   
   /*
    * @description : strips a string of numeric values and leading 'The'
    * @parameter stringToStrip : the string to strip
    * @returns : a string which has been stripped of the offending characters.
    **/
    private static String stripString(String stringToStrip) {
    String strippedString = stringToStrip?.replaceAll('[\\d.]', '').trim(); // Removes all numbers and .'s
    strippedString = strippedString?.replaceFirst('^The\\s|^THE\\s', '').trim(); // Removes leading 'The'
    strippedString = strippedString?.replaceAll('\\s\\s', ' ').trim(); // Removes multiple spaces
    return strippedString;
 }


   /*
    * @description : creates a key for storing search strings in cache
    * @parameter searchString : the search string
    * @returns : a cache key.
    **/
   private static String getCacheKey(String searchString) {
          return  String.valueOf('CA' + searchString.hashCode()).replace('-','X');
   }

    /*
    * @description : determins whether the specified format is valid
    * @parameter : format - the format to check
    * @returns : true if the format is not valid.
    **/
   private static Boolean formatInvalid(String format) {
       return validFormats.contains(format)==false;
   }    
}