/**
 * @description       : Utility Class for all Contact Points (Phone, Email, Name, Address)
 * @author            : Nick Guia
 * @date              : 07-07-2023
 * @group             : Person360
 * @revision          : 19-08-2023 Nick Guia
 *                    : 17-11-2024 Martin Cadman Added lowercase to type value in generateNameKey
 *                      TO DO: Move the name uid generation to one place
**/
public inherited sharing class ContactPointUtility {

    public static KeyGenerator keyGen {
        get {
            if(keyGen == null) {
                keyGen = new KeyGenerator();
            }
            return keyGen;
        }
        set;
    }

    /**
    * @description generates the composite key for affiliation.
    * @author Nick Guia | 18-07-2023 
    * @param Affiliation__c affiliation 
    * @return String 
    **/
    public static String getAffiliationKey(Affiliation__c affiliation) {
        return keyGen.generateAffiliationKey(affiliation);
    }

    /**
    * @description generates the sharing key for affiliation.
    * @author Nick Guia | 19-08-2023 
    * @param Affiliation__c affiliation 
    * @return String 
    **/
    public static String getAffiliationSharingKey(Affiliation__c affiliation) {
        return keyGen.generateAffiliationSharingKey(affiliation);
    }

    /**
    * @description generate a key set of any supported contact point. This is used to generate the unique hash
    * @author Nick Guia | 12-07-2023 
    * @param SObject contactPoint 
    * @return Set<String> 
    **/
    public static Set<String> getContactPointSObjectKey(SObject contactPoint) {
        return keyGen.generateKey(contactPoint);
    }

    /**
    * @description generate a key set of Phone object. This is used to generate the unique hash
    * @author Nick Guia | 12-07-2023 
    * @param Phone__c phone 
    * @return Set<String> 
    **/
    public static Set<String> getContactPointKey(Phone__c phone) {
        return keyGen.generatePhoneKey(phone);
    }

    /**
    * @description generate a key set of Email object. This is used to generate the unique hash
    * @author Nick Guia | 12-07-2023 
    * @param Email__c email 
    * @return Set<String> 
    **/
    public static Set<String> getContactPointKey(Email__c email) {
        return keyGen.generateEmailKey(email);
    }

    /**
    * @description generate a key set of Name object. This is used to generate the unique hash
    * @author Nick Guia | 12-07-2023 
    * @param Name__c name 
    * @return Set<String> 
    **/
    public static Set<String> getContactPointKey(Name__c name) {
        return keyGen.generateNameKey(name);
    }

    /**
    * @description generate a key set of Address object. This is used to generate the unique hash
    * @author Nick Guia | 12-07-2023 
    * @param Address__c address 
    * @return Set<String> 
    **/
    public static Set<String> getContactPointKey(Address__c address) {
        return keyGen.generateAddressKey(address);
    }

    /**
    * @description generates the composite key for contact point affiliation.
    * @author Nick Guia | 18-07-2023 
    * @param Contact_Point_Affiliation__c cpa 
    * @return String 
    *   TODO : update ContactPointAffiliationServices to use this so we don't have to
    *          repeat the switch-on statement
    **/
    public static String getContactPointAffiliationKey(Contact_Point_Affiliation__c cpa) {
        return keyGen.generateContactPointAffiliationKey(cpa);
    }

    /**
    * @description gets the ID of the related contact point
    * @author Nick Guia | 11-07-2023 
    * @param Contact_Point_Affiliation__c cpa 
    * @return Id 
    **/
    public static Id getContactPointIdFromCPA(Contact_Point_Affiliation__c cpa) {
        return switchOnContactPointAffiliation(cpa).contactPointId;
    }

    /**
    * @description gets the field API name of the related contact point
    * @author Nick Guia | 18-07-2023 
    * @param Contact_Point_Affiliation__c cpa 
    * @return String 
    **/
    public static String getContactPointLookupFieldFromCPA(Contact_Point_Affiliation__c cpa) {
        return switchOnContactPointAffiliation(cpa).contactPointAPIName;
    }

    /**
    * @description performs a switch case on CPA and collects essential details
    * @author Nick Guia | 18-07-2023 
    * @param Contact_Point_Affiliation__c cpa 
    * @return ContactPointAffiliationLookup 
    **/
    @TestVisible
    private static ContactPointAffiliationLookup switchOnContactPointAffiliation(Contact_Point_Affiliation__c cpa) {

        ContactPointAffiliationLookup result = new ContactPointAffiliationLookup();
        switch on cpa.Type__c {
            when 'Phone' {
                result.contactPointId =  cpa.Phone__c;
                result.contactPointAPIName =  'Phone__c';
            }
            when 'Email' {
                result.contactPointId =  cpa.Email__c;
                result.contactPointAPIName =  'Email__c';
            }
            when 'Address' {
                result.contactPointId =  cpa.Address__c;
                result.contactPointAPIName =  'Address__c';
            }
            when else {
                throw new ContactPointUtilityException('Unsupported Contact Point Affiliation Type : ' + cpa.Type__c);
            }
        }
        return result;
    }
    
    @TestVisible
    private class ContactPointAffiliationLookup {
        Id contactPointId { get; set; }
        String contactPointAPIName { get; set; }
    }

    /**
    * @description generates the key for Affiliation, CPA, and Contact Points. 
    *   This also serves as a contract of the list of fields
    *   that a certain SObject would rely on to generate a unique key
    * @author Nick Guia | 07-07-2023 
    **/
    public class KeyGenerator {

        @TestVisible
        private final Map<Schema.SObjectType, Set<String>> fieldKeyByContactPointType = new Map<Schema.SObjectType, Set<String>> {
            Phone__c.SObjectType => new Set<String>{
                'Contact__c',
                'Type__c',
                'Name'
            },
            Email__c.SObjectType => new Set<String>{
                'Contact__c',
                'Name'
            },
            Name__c.SObjectType => new Set<String>{
                'Contact__c',
                'Type__c'
                // last key is 'fullname' (via NameServices.generateFullName), but not required e.g. generate unique based on most data available
            },
            Address__c.SObjectType => new Set<String>{
                'Contact__c',
                'Street_Name__c',
                'City__c',
                'State__c',
                'Post_Code__c',
                'Country2__c'
            }
        };

        // lists here to retain order
        @TestVisible
        private final String CONTACT_POINT_ID_KEY = 'CONTACT_POINT_ID';
        @TestVisible
        private final List<String> contactPointAffiliationFieldKey = new List<String> {
            'Affiliation__c',
            CONTACT_POINT_ID_KEY
        };
        @TestVisible
        private final List<String> affiliationKey = new List<String> {
            'Contact__c',
            'Account__c',
            'RecordTypeId'
        };
        @TestVisible
        private final List<String> affiliationSharingKey = new List<String> {
            'Contact__c',
            'Account__c'
        };
        
        @TestVisible
        private Set<String> keySet;
        @TestVisible
        private Set<String> fieldKeys;

        public KeyGenerator() { }

        /**
        * @description generates the Key for a dynamic SObject contact point.
        *   This is simply for quality of life improvement if you're dealing with dynamic SObjects
        * @author Nick Guia | 07-07-2023 
        * @param SObject contactPoint 
        * @return Set<String> 
        **/
        public Set<String> generateKey(SObject contactPoint) {

            switch on contactPoint {
                when Phone__c phone {
                    this.keySet = generatePhoneKey(phone);
                }
                when Email__c email {
                    this.keySet = generateEmailKey(email);
                }
                when Name__c name {
                    this.keySet = generateNameKey(name);
                }
                when Address__c add {
                    this.keySet = generateAddressKey(add);
                }
                when else {
                    throw new ContactPointUtilityException('Unsupported SObjectType : ' + contactPoint.getSObjectType() + ' on KeyGenerator');
                }
            }
            return this.keySet;
        }

        /**
        * @description generates the composite key for contact point affiliation.
        * @author Nick Guia | 18-07-2023 
        * @param Contact_Point_Affiliation__c cpa 
        * @return String : unique composite key
        **/
        public String generateContactPointAffiliationKey(Contact_Point_Affiliation__c rec) {
            String compKey = '';
            for(String key : this.contactPointAffiliationFieldKey) {
                Id lookupRecordId; // always convert to 18-digit ID

                if(key.equals(this.CONTACT_POINT_ID_KEY)) {
                    lookupRecordId = getContactPointIdFromCPA(rec);
                } else {
                    lookupRecordId = (Id) rec.get(key);
                }
                compKey += String.valueOf(lookupRecordId);
            }
            return compKey;
        }

        /**
        * @description generates the composite key for affiliation.
        * @author Nick Guia | 18-07-2023 
        * @param Affiliation__c rec 
        * @return String 
        *   The class currently assumes that all keys are IDs
        **/
        public String generateAffiliationKey(Affiliation__c rec) {
            String compKey = '';
            for(String key : this.affiliationKey) {
                Id lookupRecordId = (Id) rec.get(key); // always convert to 18-digit ID
                compKey += lookupRecordId;
            }
            return compKey;
        }

        /**
        * @description generates the sharing key for affiliation.
        * @author Nick Guia | 18-07-2023 
        * @param Affiliation__c rec 
        * @return String 
        *   The class currently assumes that all keys are IDs
        **/
        public String generateAffiliationSharingKey(Affiliation__c rec) {
            String sharingKey = '';
            for(String key : this.affiliationSharingKey) {
                Id lookupRecordId = (Id) rec.get(key); // always convert to 18-digit ID
                sharingKey += lookupRecordId;
            }
            return sharingKey;
        }

        /**
        * @description generate Key set for Phone Contact Point.
        *   Special Rules:
        *       - formats the Phone number (Name field) before adding to key set
        * @author Nick Guia | 07-07-2023 
        * @param Phone__c rec 
        * @return Set<String> 
        **/
        public Set<String> generatePhoneKey(Phone__c rec) {
            this.fieldKeys = fieldKeyByContactPointType.get(Phone__c.SObjectType);
            this.keySet = new Set<String>();

            // if this is a mobile, format
            if(rec.Type__c == 'Mobile') {
                rec.Name = PhoneServices.formatPhone(rec.Name);
            }

            for(String iField : this.fieldKeys) {
                String keyMember = (String) rec.get(iField);
                if(iField.equals('Contact__c')) { // always convert to 18-digit
                    Id conId = keyMember; 
                    keyMember = conId;
                } else if(iField.equals('Name') && String.isNotBlank(keyMember)) { // special rule - strip all non-numeric characters
                    keyMember = keyMember.replaceAll('[^0-9]','');
                }
                this.keySet.add(keyMember);
            }
            return this.keySet;
        }

        /**
        * @description generate Key set for Email Contact Point.
        *   Special Rules:
        *       - Converts email address (Name field) to lower case
        * @author Nick Guia | 07-07-2023 
        * @param Email__c rec 
        * @return Set<String> 
        **/
        public Set<String> generateEmailKey(Email__c rec) {
            this.fieldKeys = fieldKeyByContactPointType.get(Email__c.SObjectType);
            this.keySet = new Set<String>();

            for(String iField : this.fieldKeys) {
                String keyMember = (String) rec.get(iField);

                if(iField.equals('Contact__c')) { // always convert to 18-digit
                    Id conId = keyMember; 
                    keyMember = conId;
                } else if(iField.equals('Name') && String.isNotBlank(keyMember)) { // special rule - lower case email name
                    keyMember = keyMember.toLowerCase();
                }

                this.keySet.add(keyMember);
            }
            return this.keySet;
        }

        /**
        * @description generate Key set for Name Contact Point.
        *   Special Rules:
        *       - If Type__c is blank, get the default picklist value, and add to key set
        *       - Calculates the Fullname (via NameServices.generateFullName()), and adds to the set of Keys
   	    * NOTE THAT THIS DUPLICATES LOGIC IN NAMESERVICES. CHANGES HERE MAY NEED TO BE REFLECTED THERE.
		* @author Nick Guia | 07-07-2023 
        * @param Name__c rec 
        * @return Set<String> 
        **/
        public Set<String> generateNameKey(Name__c rec) {
            this.fieldKeys = fieldKeyByContactPointType.get(Name__c.SObjectType);
            this.keySet = new Set<String>();

            for(String iField : this.fieldKeys) {
                String keyMember = (String) rec.get(iField);

                if(iField.equals('Contact__c')) { // always convert to 18-digit
                    Id conId = keyMember; 
                    keyMember = conId;
                } else if(iField.equals('Type__c')) {
                    if (rec.Type__c == null) { // special rule - get default Type
                    	keyMember = ((String) Schema.Name__c.Type__c.getDescribe().getDefaultValue()).toLowercase();
                    } else {
                        keyMember = rec.Type__c.tolowercase();
                    }                          
                }
                this.keySet.add(keyMember);
            }

            // special rule - calculate and add full name
            String fullName = NameServices.generateFullName(rec);
            if(String.isNotBlank(fullName)) {
                this.keySet.add(fullName.toLowercase());
            }
            return this.keySet;
        }

        /**
        * @description generate Key set for Address Contact Point.
        *   Special Rules:
        *       - N/A
        * @author Nick Guia | 07-07-2023 
        * @param Address__c rec 
        * @return Set<String> 
        **/
        public Set<String> generateAddressKey(Address__c rec) {
            this.fieldKeys = fieldKeyByContactPointType.get(Address__c.SObjectType);
            this.keySet = new Set<String>();

            for(String iField : this.fieldKeys) {
                String keyMember = String.valueOf(rec.get(iField));

                if(iField.equals('Contact__c')) { // always convert to 18-digit
                    Id conId = keyMember; 
                    /**
                     * ideally we shouldn't be converting this to lower case, but since this is
                     * the current state, not doing so will produce a different hash and duplicates records
                     * converting the String to IDs (18 digits) should alread mitigate the unwanted risks
                     */
                    keyMember = String.valueOf(conId).toLowerCase();
                } else {
                    // special rule - unless this is a contact id, convert to lower case and clean up
                    // clean up : remove any spaces and special characters
                    keyMember = keyMember?.toLowerCase().replaceAll('[^a-zA-Z0-9]','');
                }
                this.keySet.add(keyMember);
            }
            return this.keySet;
        }
    }

    public class ContactPointUtilityException extends Exception { }
}