/**
 * @description Helper class for Person360
 *
 * @author J.Mapanao
 * @date 19/03/19
 * 
 *
 * @revision
 *  JAN.20.2020     Nick Guia   - Added hasPrimary()
 *  MAR.05.2024     Jitender Padda   - Added isMUMStaffContact()
 **/
public class Person360Helper {

    public static final String automatedProcessUserName = 'autoproc@';
    public static final String mumStaffPersonnelAreaCodePrefix = 'MY';

    /*
     * For the given Contact record -
     * Populate the FirstName field with value of Preferred_Name__c when possible, otherwise use value of First_Name__c
     */
    public static void setContactFirstName(Contact c) {
        if (String.isNotBlank(c.Preferred_Name__c)) {
            c.FirstName = c.Preferred_Name__c;
        } else if (String.isNotBlank(c.First_Name__c)) {
            c.FirstName = c.First_Name__c;
        }
    }

    /*
     * @description Checks if the contact is a MUM staff contact
     */
    public static Boolean isMUMStaffContact(Contact con){
        if(con.SAP_Staff_Id__c != null) 
            if(con.Personnel_Area_Code__c != null 
                && con.Personnel_Area_Code__c.startsWith(mumStaffPersonnelAreaCodePrefix)){
                    
            return true;
        }

        return false;
    }

    /*
     * @description Full Address is concatenation of Street_Name__c + ", " + City__c + ", " + State__c + ", " + Country__c".
     *              If the addition of any component results in a length of >80 characters,
     *              the concatenation is stopped at the previously concatenated value with <80 characters.
     */
    public static String formatAddressName(String streetName, String city, String state, String country) {
        String fullAddress = '';
        // Full Address is concatenation of Street_Name__c + ", " + City__c + ", " + State__c + ", " + Country__c"
        fullAddress = (String.isNotBlank(streetName)) ? streetName+ ', ' : fullAddress;
        fullAddress = (String.isNotBlank(city)) ? fullAddress + city : fullAddress;
        fullAddress = (String.isNotBlank(state)) ? fullAddress + ', ' + state : fullAddress;
        fullAddress = (String.isNotBlank(country)) ? fullAddress + ', ' + country : fullAddress;
        // If the addition of any component results in a length of >80 characters, the concatenation is stopped at the previously concatenated value with <80 characters.
        fullAddress = (String.isNotBlank(fullAddress) && fullAddress.length() > 80) ? fullAddress.substring(0, 79) : fullAddress;
        return fullAddress;
    }

    /*
     * @description Full name (concatenated from First_Name__c + " " + Middle_Name__c + " " + Last_Name__c, e.g. Stefan Asterix Scheit
     *              If concatenation is >80 characters, it's shortened to 80 characters
     */
    public static String formatName(String firstName, String middleName, String lastName) {
        String fullName = '';
        Integer spaceCount = 1;
        Integer fNameCount = (String.isNotBlank(firstName)) ? firstName.length() : 0;
        Integer mNameCount = (String.isNotBlank(middleName)) ? middleName.length() : 0;
        Integer lNameCount = (String.isNotBlank(lastName)) ? lastName.length() : 0;
        Integer nameTotalCharCount = fNameCount + spaceCount + mNameCount + spaceCount + lNameCount;

        if (nameTotalCharCount > 80) {
            String tempFirstName = String.isNotBlank(firstName) ? firstName.subString(0, 1).toUpperCase() : null;
            String tempMiddleName = (String.isNotBlank(middleName)) ? middleName.subString(0, 1).toUpperCase() : null;
            String tempLastName = (String.isNotBlank(lastName)) ? lastName : '';

            if (tempLastName.length() >= 78) {
                tempLastName = tempLastName.subString(0, 76);
            }
            fullName = tempFirstName != null ? tempFirstName : '';
            fullName = tempMiddleName != null ? fullName + ' ' + tempMiddleName : fullName;
            fullName = fullName + ' ' + tempLastName;
        } else {
            fullName = String.isNotBlank(firstName) ? firstName : '';
            fullName = String.isNotBlank(middleName) ? fullName + ' ' + middleName : fullName;
            fullName = String.isNotBlank(lastName) ? fullName + ' ' + lastName : fullName;
        }
        return fullName;
    }
    /**
     * Sets the Date to Today if Blank
     * @return Date
     */
    public static Date setDefaultDate(Schema.SObjectField soField, SObject record) {
        Date setDateRet = null;
        //Check if Type is Date
        if (soField.getDescribe().getType() == Schema.DisplayType.Date) {
            Object oObj = record.get(soField);
            if (oObj != null) {
                setDateRet = (Date)oObj;
            } else {
                setDateRet = Date.today();
                record.put(soField, setDateRet);
            }

        }
        return setDateRet;
    }

    /**
     * Dynamic field mapping - cast to display type
     */
    public static SObject addFieldValue(SObject sObj, String pSOField, Object fieldValue) {
        if (sObj != null) {
            Map<String, Schema.SObjectField> mpFieldMap = sObj.getSObjectType().getDescribe().fields.getMap();
            if (mpFieldMap.containsKey(pSOField)) {
                Schema.SObjectField soField = mpFieldMap.get(pSOField);
                if (soField.getDescribe().getType() == Schema.DisplayType.Date) {
                    sObj.put(soField.getDescribe().getName(), fieldValue != null ? (Date)fieldValue : null);
                } else if (soField.getDescribe().getType() == Schema.DisplayType.String) {
                    sObj.put(soField.getDescribe().getName(), fieldValue != null ? (String)fieldValue : null);
                } else if (soField.getDescribe().getType() == Schema.DisplayType.Boolean) {
                    sObj.put(soField.getDescribe().getName(), fieldValue != null ? (Boolean)fieldValue : null);
                } else if (soField.getDescribe().getType() == Schema.DisplayType.ID) {
                    sObj.put(soField.getDescribe().getName(), fieldValue != null ? (Id)fieldValue : null);
                }
            }
        }
        return sObj;
    }
    /**
     * Generate a key for ExternalId - limit 255
     */
    public static String generatePerson360Key(Set<String> stMultiKey) {
        String str = '';
        if (stMultiKey != null) {
            for (String sVal : stMultiKey) {
                if (String.isNotBlank(sVal)) {
                    //Encode special characters to UTF-8
                    str += sVal;
                }
            }
            //Create Key Digest 128 characters
            Blob blb = Blob.valueOf(str);
            Blob hash = Crypto.generateDigest('SHA-512', blb);
            //Encode Key to String - UTF-8
            str = EncodingUtil.base64Encode(hash);
        }
        return str;
    }

    /**
     * @description checks if the list of contact point objects already
     *  has an existing Primary.
     * Assumptions:
     *  - contactPoints are of the same SObject Types
     *  - contactPoints belong to the same Contact ID
     */
    public static Boolean hasPrimary(List<SObject> contactPoints) {
        Boolean hasPrimary = false;
        for(SObject iSobj : contactPoints) {
            try {
                hasPrimary = (Boolean) iSobj.get('is_Primary__c');
                if(hasPrimary) {
                    break;
                }
            } catch(Exception e) {
                //TODO: LOG UTILITY
            }
        }
        return hasPrimary;
    }

    /**
     * @description     This method will set the Primary_set_by__c to either
     *                  system (when current user is Automated Process user)
     *                  user (when current user is not Automated Process user)
     */
    public static void setUserOrSystemToPrimarySetBy(SObject record) {
        if ((UserInfo.getUserName().toLowerCase().contains(automatedProcessUserName)) || UserInfo.getUserType().toLowerCase().contains('partner')) {
            record.put('Primary_set_by__c', 'system');
        } else {
            record.put('Primary_set_by__c', 'user');
        }
    }

    public static Boolean nameCanBeSplit(String n) {
        return String.isNotBlank(n) && n.contains(' ');
    }

    public static void splitLegalFirstNameIntoFirstAndMiddle(String legalName, Name__c name) {
        String[] nameParts = legalName.split(' ', 2);
        name.First_Name__c = nameParts[0];
        name.Middle_Name__c = nameParts[1];
    }

    /**
    * Wrapper to create a sortable Name contact point to determine the primary - Primary record will be first.
    * Ordering is: Rollup Rank ASC, Start Date DESC, Created Date DESC NULLS FIRST, Primary TRUE FIRST
    */
    public class SortableContactPoint implements Comparable {

        public final SObject obj;
        public final Integer rollupRank; // lower = more important
        public final Datetime startDate;
        public final Datetime createdDate;
        public final Boolean isPrimary;

        public SortableContactPoint(SObject cp, Integer rollupRank) {
            this.obj = cp;
            this.rollupRank = rollupRank;
            this.startDate = (Datetime)obj.get('Start_Date__c');
            this.createdDate = (Datetime)obj.get('CreatedDate');
            Boolean isPrimary = (Boolean)obj.get('Is_Primary__c');
            this.isPrimary = isPrimary != null ? isPrimary : false;
        }

        public Integer compareTo(Object o) {
            final SortableContactPoint compareObj = (SortableContactPoint)o;

            //  0 = objects are equal
            //  1 = compared obj comes before
            // -1 = compared obj comes after
            Integer returnValue = 0;

            // sort by lowest rollup rank
            if (rollupRank > compareObj.rollupRank) {
                returnValue = 1;
            } else if (rollupRank < compareObj.rollupRank) {
                returnValue = -1;
            }
            // then sort by newest start date (nulls last)
            else if (startDate > compareObj.startDate) {
                returnValue = -1;
            } else if (startDate < compareObj.startDate) {
                returnValue = 1;
            } else if (startDate == null && compareObj.startDate != null) {
                returnValue = 1;
            } else if (startDate != null && compareObj.startDate == null) {
                returnValue = -1;
            }
            // then sort by newest created date (nulls first for newly inserted records)
            else if (createdDate > compareObj.createdDate) {
                returnValue = -1;
            } else if (createdDate < compareObj.createdDate) {
                returnValue = 1;
            } else if (createdDate == null && compareObj.createdDate != null) {
                returnValue = -1;
            } else if (createdDate != null && compareObj.createdDate == null) {
                returnValue = 1;
            }
            // then sort by Is Primary (true first)
            else if (isPrimary && !compareObj.isPrimary) {
                returnValue = -1;
            } else if (!isPrimary && compareObj.isPrimary) {
                returnValue = 1;
            }
            return returnValue;
        }
    }
}