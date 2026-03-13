/**
 * @description Apex class containing Phone logic services
 *
 * @author R.Cadapan
 * @date JAN.22.2020
 *
 * @revision
 *          JUN.15.2020 - J.Mapanao - Added logic to not deselect primary when user previously selected manually
 *          AUG.08.2022 - Martin Cadman - Tactical addition of the mobile formatting feature for Australian Mobiles.
 *          AUG.18.2022 - Sachin Shetty - Addition of mobile formatting feature for more countries, driven via custom metadatatype
 *          OCT.18.2022 - Martin Cadman - Moved to using an active flag on the custom metadata defintion  
 *          NOV.29.2022 - Martin Cadman - Introduced a basic wrapper class to return country code as well as a formatted number
 *          NOV.30.2022 - Vinothraja    - Added method to retreive the MFA verified Phone no for a Contact
 *          FEB.14.2023 - Martin Cadman - Extended wrapper to include country name
 *
 **/
public class PhoneServices {

    static final String PHONE_NUMBER_FORMAT_CUSTOM_METADATATYPE_FEATURE = 'PHONE_NUMBER_FORMAT';
    static final String PHONE_NUMBER_STRING_FORMAT = '{0}{1}{2}'; // {0} - Country Code, {1} - Space, {2} - Rest of the mobile number
    private static final String SCENARIO = 'Analysis';
    private static final String TAG      = 'Phone Primary Analysis';
    private static String msgfmt = '[Active Student: {0}] [Override: {1}] [Class Selected: {2}] [Personal #: {3}] [Callista #: {4}] [Already Primary: {5}]';

    /**
     * Method to calculate Primary Phone for each Contact for every new record or an existing Phone record is updated
     */
    public static void calculatePrimary(Set<Id> contactIds) {
        List<SObject> recordsToUpdate = new List<SObject>();
        nebula.LogMessage logMsg;
        nebula.logger.setScenario(SCENARIO);

        /**
         * Try to find new Primary Phone for each Contact
         * by querying all their child Phone records, sorted by
         * LATEST Start Date, CreatedDate, type - type has been added to force Undefined to the bottom
         */
        for (Contact contact : [ SELECT Is_Student__c,
                                    (SELECT Is_Primary__c, Name, Primary_set_by__c, CreatedDate, Type__c, Classification__c, Start_Date__c, Callista_rollup_rank__c, Source__c
                                    FROM Phones__r
                                    WHERE Is_Deleted__c = FALSE AND Is_Active__c = TRUE
                                    ORDER BY Start_Date__c DESC, CreatedDate DESC, type__c)
                                FROM Contact
                                WHERE Id IN: contactIds]) {
            nebula.logger.fine('Calculating primary phone',contact).addTag(TAG);
            nebula.logger.fine('There are ' + contact.phones__r.size() + ' phones are under consideration',contact.phones__r).addTag(TAG);

            if (((contact.phones__r.size()==1) && (contact.phones__r[0].is_Primary__c)) 
            	|| (contact.phones__r.size()==0)) {
                break;
            }
                                    
            Boolean anyOtherPrimaryWhereSetByUser = false;
            List<Phone__c> allPhoneList = new List<Phone__c>();
            List<Person360RollUpServices.ContactPointRecord> callistaSourceCustomList = new List<Person360RollUpServices.ContactPointRecord>();
            List<Phone__c> nonCallistaList = new List<Phone__c>();
			Phone__c orRec; 
            
			for(Phone__c iPhone : contact.Phones__r) {
 		        if (iPhone.Is_Primary__c && iPhone.Primary_set_by__c == 'user') {
        	        anyOtherPrimaryWhereSetByUser = true;
                    orRec = iPhone;
                }
                
                allPhoneList.add(iPhone);
                if (iPhone.Source__c == 'Callista' && String.isNotBlank(iPhone.Callista_rollup_rank__c)) {
                    callistaSourceCustomList.add(new Person360RollUpServices.ContactPointRecord(iPhone.Callista_rollup_rank__c, iPhone));
                } else {
                    nonCallistaList.add(iPhone);
                }
            }
             
            Phone__c iPhone;
			if (contact.Is_Student__c == true) {                                        
                if (!callistaSourceCustomList.isEmpty()) {
                    if ( callistaSourceCustomList.size() > 1) {
                        callistaSourceCustomList.sort();
                    }
              		iPhone = (Phone__c) callistaSourceCustomList[0].record;
                    logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No',anyOtherPrimaryWhereSetByUser==True?'Yes':'No','Callista lowest rank (' + iphone.type__c + ')' ,''+nonCallistaList.size(),''+callistaSourceCustomList.size(),iPhone.is_primary__c==true?'Yes':'No'}); 
                    nebula.logger.fine(logMsg,iPhone).addTag(TAG);

                    if (!iPhone.Is_Primary__c ) {
                        iPhone.Is_Primary__c = true;
                        recordsToUpdate.add(iPhone);
                    }
                } else {
                    if (!nonCallistaList.isEmpty()) {
	                    iPhone = nonCallistaList[0];
	                    logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No',anyOtherPrimaryWhereSetByUser==True?'Yes':'No','Latest start date (' + iphone.type__c + ')'  ,''+nonCallistaList.size(),''+callistaSourceCustomList.size(),iPhone.is_primary__c==true?'Yes':'No'}); 
                        nebula.logger.fine(logMsg,iPhone).addTag(TAG);
                        if (!iPhone.is_primary__c) {
                            iPhone.Is_Primary__c = true;
                            recordsToUpdate.add(iPhone);
                        }
                    }
                }
            } else {
                if (!anyOtherPrimaryWhereSetByUser) {  
                    if (!allPhoneList.isEmpty()) {
                        iPhone = allPhoneList[0];
                        logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No',anyOtherPrimaryWhereSetByUser==True?'Yes':'No','Latest start date (' + iphone.type__c +')',''+nonCallistaList.size(),''+callistaSourceCustomList.size(),iPhone.is_primary__c==true?'Yes':'No'}); 
                        nebula.logger.fine(logMsg,iPhone).addTag(TAG);
                        if (!iPhone.is_primary__c) {
                            iPhone.Is_Primary__c = true;
                            recordsToUpdate.add(iPhone);
                        }
                    } 
                } else {
                    logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No','Yes','Override',''+nonCallistaList.size(),''+callistaSourceCustomList.size(), '-'}); 
                    nebula.logger.fine(logMsg,orRec).setRecord(contact).addTag(TAG);
                }
            }
        }

        if (!recordsToUpdate.isEmpty()) {

            nebula.logger.fine('Updating the phone primary field (new primaries)',recordsToUpdate).addTag(TAG);
            Triggers.bypass('FindNewPrimary');
            List<Database.SaveResult> saveResults = Database.update(recordsToUpdate, false);
            List<Database.SaveResult> failedRecordsErrors = new List<Database.SaveResult>();
            for (Database.SaveResult saveResult : saveResults) {
                if (!saveResult.isSuccess()) {
                    failedRecordsErrors.add(saveResult);
                }
            }
            
            if (!failedRecordsErrors.isEmpty()) {
                nebula.logger.error('Phone find new primary database errors',failedRecordsErrors);
            }
            Triggers.clearBypass('FindNewPrimary');
        }

        nebula.logger.endScenario(scenario);
        nebula.logger.saveLog();
    }
	
	/*
	 * Person360 and MFA services need to generate a phone UID 
	 */    
    public static Set<String> buildPhoneKeySet(Phone__c callMe) {
		return buildPhoneKeySet(callMe.Contact__c, callMe.Type__c, callMe.Name);
    }

    public static Set<String> buildPhoneKeySet(String phoneContactID, String phonetype, String phoneNumber) {
        Set<String> keySet = new Set<String> {phoneContactID};
        keySet.add(phonetype); // Mobile etc.
        if (String.isNotBlank(phoneNumber)) {
            keySet.add(phoneNumber.replaceAll('[^0-9]','')); // Strip all non-numeric characters from hash source
        }
		return keySet;
    }

    /**
     * @author      Martin Cadman
     * @description Applies formatting to two numbers and compares the result
     * @return      Boolean
     * @revision    2022-11-20 
     */
    public static Boolean compareNumbers(String p1Number, String p2Number ) {
        return rawFormatPhone(p1Number) == rawFormatPhone(p2Number);
    }

    /**
     * @author      Sachin Shetty
     * @description Strips all non numeric characters from the formatted phone number
     * @return      String
     * @revision    2022-08-23 - Sachin Shetty - Created
     */
    public static String rawFormatPhone(String phoneNumber) {
        if(String.isBlank(phoneNumber)) return '';
        return formatPhone(phoneNumber).replaceAll('[^0-9]','');
    }

   /**
     * @author      Martin Cadman	
     * @description Strips all non numeric characters from an unformatted phone number, leaving single spaces and lead +
     * @return      String
     * @revision    2024-01-23 - Martin Cadman - Created
     */
    public static String tidyPhone(String phoneNumber) {
        if(String.isBlank(phoneNumber)) return '';
        return phoneNumber.normalizeSpace().replaceAll('[^\\d+\\h]|(?!^)\\+','');
    }

    /**
     * @author      Martin Cadman
     * @description Formats the supplied phone number based on the country phone code
     * @param:      String : Supplied phone number
     * @return      String
     * @revision    2022-08-04 - Martin Cadman - Created
     *              2022-08-17 - Sachin Shetty - Update to handle formatting phone numbers of different countries(via custom metadatatype)
     *              2022-08-31 - Sachin Shetty - Check for empty input
     */
    public static String formatPhone(String phoneNumber) { 
		return initiatePhoneFormat(phoneNumber).phoneNumber;
    }

    public static formatPhoneWrapper initiatePhoneFormat(String phoneNumber) { 
        formatPhoneWrapper fpw = new formatPhoneWrapper();

        if(String.isBlank(phoneNumber)) {
            return fpw;
        }
        fpw.phoneNumber = phoneNumber;
        
		Map<String, String> phoneFormatDataByCountry = getPhoneNumberFormatParams();
		
        // Ability to turn this off
		Feature_Switch__c fs = Feature_Switch__c.getInstance();
        if(fs.Format_Mobile__c) {
        	String cleansedNumber = phoneNumber.replaceAll('[^0-9]', ''); // Remove the noise
            if (String.isNotBlank(cleansedNumber)) {
				fpw = matchPatternAndFormatNumber(phoneFormatDataByCountry, cleansedNumber, phoneNumber);
            }
        }        
        return fpw;
    }
    
    /**
     * @author      Sachin Shetty
     * @description Returns the details(RegEx, Active flag etc.,) needed for formatting phone numbers from custom metadatatype
     *              Sample: "Australia +61": {
	 *							"Country_Name" : "Australia",
								"Country_Code" : "+61",
     *                          "RegEx": "^(?=.{10,})^((?:\+|00|0011|\+00|\+0011)?61)?(0?[4])(\d{8})$"
     *                       }
     * @return      Map<String, String>
     * @revision    2022-08-17 - Sachin Shetty - Created
     */
    public static Map<String, String> getPhoneNumberFormatParams(){
        Map<String, String> keyValuePair = new Map<String, String>();
        List<System_Settings__mdt> phoneNumberFormatMetadatas = SystemSettingsUtil.getInstance().getByFeature(PHONE_NUMBER_FORMAT_CUSTOM_METADATATYPE_FEATURE);

        if(!phoneNumberFormatMetadatas.isEmpty()){
            for(System_Settings__mdt objSettings : phoneNumberFormatMetadatas){
                keyValuePair.put(objSettings.Key__c, objSettings.Value__c);
            }
        }
        return keyValuePair;
    }

    /**
     * @author      Sachin Shetty
     * @description Formats the phone number using appropriate regEx
     * @param:      Map<String, String> : Map of country by it's phone format from custom metadata
     *              String : Cleansed number
     *              String : Original input phone number
     * @return      String
     * @revision    2022-08-17 - Sachin Shetty - Created
     */
    public static formatPhoneWrapper matchPatternAndFormatNumber(Map<String, String> phoneFormatDataByCountry, String cleansedNumber, String inputNumber) {
        
        formatPhoneWrapper fpw = new formatPhoneWrapper(inputNumber);
                
        try {
            Matcher myMatcher = null;
            PhoneFormatCustomMetadataWrapper matchedCountry = new PhoneFormatCustomMetadataWrapper();
            try {
                for(String country : phoneFormatDataByCountry.keySet()) {
                    PhoneFormatCustomMetadataWrapper formatDetails = (PhoneFormatCustomMetadataWrapper) JSON.deserialize(phoneFormatDataByCountry.get(country), PhoneFormatCustomMetadataWrapper.class);
                    Pattern myPattern = complieRegEx(country, formatDetails.RegEx);
                    myMatcher = myPattern?.matcher(cleansedNumber);
                   
                    if (myMatcher?.matches()){
                        matchedCountry = formatDetails;
                        break;
                    }
                }
            }
            catch (Exception ex) {
	            nebula.logger.exception(ex.getMessage(), ex);
          	}
            
            // 0 - full matched input
            // 1 - optional country code
            // 2 - number prefix, optional leading 0
            // >=3 - remaining numbers
            if (myMatcher?.matches()) {
                // Group 0 is ignored
                // Group 1 is ignored and we plug the corresponding country code in the template from custom metadata
                List<String> parameters = new  List<String>();
                parameters.add(matchedCountry.Country_Code);
                parameters.add(' ');
                for(Integer i=2; i<= myMatcher.groupCount(); i++){ // Ignoring Group 0 and Group 1
                    if(i == 2){         // Group 2 has the leading 0 removed
                        parameters.add(myMatcher.group(i).replaceFirst('^0',''));
                    }
                    if(i > 2){          // Group 3 and beyond (remaining numbers), if it exists, is appended to Group 2 above
                        parameters[2] += myMatcher.group(i);
                    }
                }
                fpw.countryCode = matchedCountry.Country_Code;
                fpw.countryName = matchedCountry.Country_Name;
                fpw.phoneNumber = String.format(PHONE_NUMBER_STRING_FORMAT, parameters);
                fpw.formatted = true;
            }
        } catch (Exception ex) {
            nebula.logger.exception(ex.getMessage(), ex);
        } finally {
            nebula.logger.saveLog();
        }
		return fpw;
    }

    /**
     * @author      Sachin Shetty
     * @description Compiles the regEx
     * @param:      String : Country
     *              String : Phone number RegEx for the country from the custom metadatatype
     * @return      Pattern
     * @revision    2022-08-17 - Sachin Shetty - Created
     *              2022-11-25 - Martin Cadman - Changed cache key handling
     */
    public static Pattern complieRegEx(String country, String regEx) {
        Pattern myPattern;
        try {
            // Ensure a unique, and valid, cache key
			String cacheKey = String.valueOf('PFN' + Country.hashCode()).replace('-','X');

            if (Cache.Org.getName() != null) {
                myPattern = (Pattern)Cache.Org.get(cacheKey);
                // pattern does not exist in the cache, so insert it
                if (myPattern == null) {
                    myPattern = Pattern.compile(regEx); 
                    Cache.Org.put(cacheKey, myPattern);
                }
            }
            else{
                myPattern = Pattern.compile(regEx);
            }
        } catch (Cache.Org.OrgCacheException ex) {
            // no default Org cache defined on the platform
            nebula.logger.exception(ex.getMessage(), ex);
            myPattern = Pattern.compile(regEx);
        }
        return myPattern;
    }

    /**
     * @author      Vinothraja
     * @description Gets the MFA Verified Mobile number for a Contact
     * @revision    2022-11-30 - Vinothraja - Created
     */
    public static String retrieveMFAVerifiedPhone (String contactId) {
        String mfaVerifiedPhone = '';
        if (String.isNotBlank(contactId)) {
            List<Phone__c> phoneNumbers = [SELECT Name 
                                                FROM Phone__c 
                                                WHERE Contact__c = :contactId 
                                                    AND Verification_Status__c = 'Verified by MFA'
                                                    AND Is_Active__c = true
                                                ORDER by Start_Date__c DESC
                                                LIMIT 1];
            if (phoneNumbers != null && !phoneNumbers.isEmpty()) {
                mfaVerifiedPhone = phoneNumbers[0].name;
            }
        }
        return mfaVerifiedPhone;
    }

    /**
     * @author      Martin Cadman
     * @description Wrapper to hold the formatting phone and country code
     * @revision    2022-11-30 - Martin Cadman - Created
     *              2024-01-22 - Martin Cadman - Added formatted flag
     */
     public class formatPhoneWrapper {
        public String countryCode {get;set;}
        public String countryName {get;set;}
        public String phoneNumber {get;set;}
        public boolean formatted {get;set;} 
        public String rawphoneNumber {get {return this.phoneNumber.normalizeSpace().replaceAll('[^\\d+\\h]|(?!^)\\+','');}}
         
        public formatPhoneWrapper () {
			this.phoneNumber = '';            
			this.countryCode = '';            
            this.countryName = '';
            this.formatted = false;
        }

        public formatPhoneWrapper (boolean formatted ) {
			this.formatted = formatted;   
        }

         public formatPhoneWrapper (String phoneNumber) {
			this.phoneNumber = phoneNumber;            
			this.countryCode = '';            
            this.countryName = '';
            this.formatted = false;
        }

        public formatPhoneWrapper (String phoneNumber, String countryCode) {
			this.phoneNumber = phoneNumber;            
			this.countryCode = countryCode;            
            this.countryName = '';
            this.formatted = false;
         }

         public formatPhoneWrapper (String phoneNumber, String countryCode, String countryName) {
			this.phoneNumber = phoneNumber;            
			this.countryCode = countryCode;            
			this.countryName = countryName;
            this.formatted = false;
		}
     }

    /**
     * @author      Sachin Shetty
     * @description Wrapper to hold the formatting details from custom metadatatype
     * @revision    2022-08-17 - Sachin Shetty - Created
     */
    public class PhoneFormatCustomMetadataWrapper {
        @AuraEnabled
        public String country_Name {get; set;}
        @AuraEnabled
        public String Country_Code {get; set;}
        @AuraEnabled
        public String RegEx {get; set;}

        public PhoneFormatCustomMetadataWrapper(){
            this.Country_Code = '';
            this.RegEx = '';
        }

        public PhoneFormatCustomMetadataWrapper(String countrycode, String regEx){
            this.Country_Code = countrycode;
            this.RegEx = regEx;
        }

        public PhoneFormatCustomMetadataWrapper(String countrycode, String regEx, String countryName){
            this.Country_Code = countrycode;
            this.RegEx = regEx;
            this.country_Name = countryName;
        }
    }
}