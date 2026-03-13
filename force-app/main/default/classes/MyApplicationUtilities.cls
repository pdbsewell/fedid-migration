/**
 * @author Trent De Laney
 * @date 18/07/2018
 * @group Utilities
 * @description A Static Utilities class which can be leveraged by various lightning components relating to the myApp Portal
 * @revision 
 *      06/02/19 Andrew Yeo - added method to calculate fee waiver when a contacts supplied monash id and birthdate matches to an existing contact
 *      13/05/20 KL         - SFTLG-902 - adding "pendig merge" before "sent for submission" status for contact merge
 *      5/2/2021 KV         - SFTG-1713 - Added Indonesian citizenship residency codes
 */
public without sharing class MyApplicationUtilities {

    public static List<String> DOMESTIC_CITIZENSHIP_TYPES = new List<String> {
        'DOM-AUS', 
        'DOM-NZ', 
        'DOM-PR', 
        'DOM-HV', 
        'DOM-SUN', 
        'DOM-IDN', 
        'DOM-IDN-PR' 
    };

    public static List<String> INTERNATIONAL_CITIZENSHIP_TYPES = new List<String>{
        'INTRNTNL', 
        'INT-TEP', 
        'INT-SUN', 
        'INT-SUN-P', 
        'INT-IDN', 
        'INT-IDN-P'
    };

    public static List<String> AUSTRALIAN_CAMPUS = new List<String>{
        'CLAYTON', 
        'MMC', 
        'CITY', 
        'ALFRED', 
        'BENDIGO', 
        'CAULFIELD', 
        'GIPPSLAND', 
        'NOTT HILL',
        'PARKVILLE', 
        'PENINSULA', 
        'SOUTHBANK', 
        'MEL-LAWCHM', 
        'MMS-ALFRED',
        'DOCKLANDS',
        'MCPL'
    };

    public static List<String> MALAYSIA_CAMPUS = new List<String>{
        'MALAYSIA', 
        'MUFY-SUN'
    };

    public static List<String> INDONESIA_CAMPUS = new List<String>{
        'INDONESIA'
    };    

    public static final Decimal AGE_18 = 18.0;
    public static String DOMESTIC = 'DOMESTIC';
    public static String INTERNATIONAL = 'INTERNATIONAL';
    public static String INDIA = 'India';

    public static String APP_PENDING_MERGE_STATUS = 'Submission on Hold (Duplicate Contact)';
    public static String APP_SENT_FOR_SUBMIT_STATUS = 'Sent for Submission';
    public static String APP_SENT_SUBMITTED_STATUS = 'Submitted';
    public static String APP_SENT_REVIEW_STATUS = 'Review';
    public static String APP_CANCELLED_STATUS = 'Cancelled';

    public static Profile MY_APP_USER_PROFILE {
        get {
            if(MY_APP_USER_PROFILE == null) {
                MY_APP_USER_PROFILE = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1];
            }
            return MY_APP_USER_PROFILE;
        } private set;
    }

    // adding this to a user does not trigger the welcome email
    public static PermissionSetGroup MYAPP_USER_PSG {
        get {
            if(MYAPP_USER_PSG == null) {
                MYAPP_USER_PSG = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'MyApp_User' LIMIT 1];
            }
            return MYAPP_USER_PSG;
        } private set;
    }

    // adding this to a user TRIGGERS the welcome email
    public static PermissionSet MYAPP_USER_PS {
        get {
            if(MYAPP_USER_PS == null) {
                MYAPP_USER_PS = [SELECT Id FROM PermissionSet WHERE Name = 'Customer_Community_My_Application' LIMIT 1];
            }
            return MYAPP_USER_PS;
        } private set;
    }

    /**
    * @author Trent De Laney
    * @description Checks to see if the code passed is a domestic type of Residency Status
    * @date 27 Nov 2019 at 2:23:29 pm
    * @param String citizenshipCode
    * @return If the claimed citizenship code is domestic
    */
    public static Boolean isDomestic(String citizenshipCode) {
        if (DOMESTIC_CITIZENSHIP_TYPES.indexOf(citizenshipCode) >= 0) {
            return true;
        }
        return false;
    }

    /**
    * @author Trent De Laney
    * @description Checks to see if the code passed is a International type of Residency Status
    * @date 27 Nov 2019 at 2:23:29 pm
    * @param String citizenshipCode
    * @return If the claimed citizenship code is international
    */
    public static Boolean isInternational(String citizenshipCode) {
        if (INTERNATIONAL_CITIZENSHIP_TYPES.indexOf(citizenshipCode) >= 0) {
            return true;
        }
        return false;
    }

    /**
     * Gets the Citizenship type of the Contact via a Contact ID
     * @author Trent De Laney
     * @date 18/07/2018
     * @param  string contactId 
     * @return citizenshipType(string)
     */
    public static String getCitizenshipType(String contactId) {
        String type = 'ERROR';
        if (contactId != null && contactId != '') {
            List<Contact> contacts = [
                    SELECT c.Id, c.Citizenship__c
                    FROM Contact c
                    WHERE c.Id = :contactId
            ];
            if (contacts.size() > 0) {
                type = contacts[0].Citizenship__c;
            } else {
                ExLog.add('MyApplicationUtitiles', 'N/A', 'GetCitizenshipType', 'No Contact ID has been found for ID ' + contactId);
            }
        } else {
            ExLog.add('MyApplicationUtitiles', 'N/A', 'GetCitizenshipType', 'No Contact ID passed to the function');
        }

        return type;
    }

    /**
     * @author Trent De Laney
     * @description Manages the logic for the integration layer to talk to Callista. This function has specifically been implemented to support the Callista integration and should not be used for any other functions within CRM.
     * @date 29 Jan 2019 at 9:12:16 am
     * @param String residencyStatus
     * @return Boolean
     */
    public static Boolean integrationInternational(String residencyStatus) {
        switch on residencyStatus {
            when 'DOM-AUS' {
                return false;
            }
            when 'DOM-NZ' {
                return false;
            }
            when 'DOM-PR' {
                return false;
            }
            when 'HOM-HV' {
                return false;
            }
        }
        return true;
    }

    /**
    * @author Trent De Laney
    * @description Determines the Citizenship classification for the combination of Residency Status and Location. Does not have an explicit test function to cover this.
    *              5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes
    * @date 27 Nov 2019 at 2:27:14 pm
    * @return Multimap of Campus Country -> Citizenship Type
    */
    public static Map<String, Map<String, String>> getDynamicCitizenship() {
        Map<String, Map<String, String>> citizenshipClassifications = new Map<String, Map<String, String>>();

        Map<String, String> australianClassifications = new Map<String, String>();
        Map<String, String> indonesiaClassifications = new Map<String, String>();
        Map<String, String> malaysianClassifications = new Map<String, String>();
        Map<String, String> southAfricaClassifications = new Map<String, String>();
        Map<String, String> onlineClassifications = new Map<String, String>(); //SFTG-1963 - For handling Online courses

        Schema.DescribeFieldResult fieldResult = Application__c.Residency_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {
            switch on f.getValue() {
                when 'DOM-AUS' {
                    australianClassifications.put(f.getValue(), 'DOMESTIC');
                    indonesiaClassifications.put(f.getValue(), 'INTERNATIONAL');
                    malaysianClassifications.put(f.getValue(), 'INTERNATIONAL');
                    southAfricaClassifications.put(f.getValue(), 'INTERNATIONAL');
                }
                when 'DOM-NZ' {
                    australianClassifications.put(f.getValue(), 'DOMESTIC');
                    indonesiaClassifications.put(f.getValue(), 'INTERNATIONAL');
                    malaysianClassifications.put(f.getValue(), 'INTERNATIONAL');
                    southAfricaClassifications.put(f.getValue(), 'INTERNATIONAL');
                }
                when 'DOM-SUN' {
                    malaysianClassifications.put(f.getValue(), 'DOMESTIC');
                }
                when 'DOM-SA' {
                    southAfricaClassifications.put(f.getValue(), 'DOMESTIC');
                }
                when 'DOM-PR' {
                    australianClassifications.put(f.getValue(), 'DOMESTIC');
                }
                when 'DOM-HV' {
                    australianClassifications.put(f.getValue(), 'DOMESTIC');
                }
                when 'INTRNTNL' {
                    australianClassifications.put(f.getValue(), 'INTERNATIONAL');
                    onlineClassifications.put(f.getValue(), 'INTERNATIONAL'); //SFTG-1963 - For handling Online courses
                }
                when 'INT-TEP' {
                    australianClassifications.put(f.getValue(), 'INTERNATIONAL');
                }
                when 'INT-SUN-P' {
                    malaysianClassifications.put(f.getValue(), 'INTERNATIONAL');
                }
                when 'INT-SUN' {
                    malaysianClassifications.put(f.getValue(), 'INTERNATIONAL');
                }
                when 'INT-SA' {
                    southAfricaClassifications.put(f.getValue(), 'INTERNATIONAL');
                }
                //5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes
                when 'DOM-IDN' {
                    indonesiaClassifications.put(f.getValue(), 'DOMESTIC');
                }
                when 'DOM-IDN-PR' {
                    indonesiaClassifications.put(f.getValue(), 'DOMESTIC');
                }
                when 'INT-IDN-P' {
                    indonesiaClassifications.put(f.getValue(), 'INTERNATIONAL');
                }
                when 'INT-IDN' {
                    indonesiaClassifications.put(f.getValue(), 'INTERNATIONAL');
                }
            }
        }

        citizenshipClassifications.put('Australia', australianClassifications);
        citizenshipClassifications.put('Indonesia', indonesiaClassifications);
        citizenshipClassifications.put('Malaysia', malaysianClassifications);
        citizenshipClassifications.put('South Africa', southAfricaClassifications);
        citizenshipClassifications.put('Online', onlineClassifications); //SFTG-1963 - For handling Online courses

        return citizenshipClassifications;
    }

    /**
    * @author Trent De Laney
    * @description Determines the dynamic Citizenship for an Application via the appId
    * @date 27 Nov 2019 at 2:28:21 pm
    * @param String appId
    * @return INTERNATIONAL or DOMESTIC
    */
    public static String getApplicationCitizenshipType(String appId) {

        Map<String, Map<String, String>> citizenshipTypes = getDynamicCitizenship();

        List<Application__c> apps = [
                SELECT Id, Campus_Location__c, Residency_Status__c
                FROM Application__c
                WHERE Id = :appId
        ];

        if (apps.size() > 0) {
            if (apps[0].Campus_Location__c != null && apps[0].Residency_Status__c != null) {
                Map<String, String> values = citizenshipTypes.get(apps[0].Campus_Location__c);
                return values.get(apps[0].Residency_Status__c);
            }
        }
        return 'DOMESTIC';
    }

    /**
     * Gets the Citizenship type of the Contact via an Application ID
     * @author Trent De Laney
     * @date 18/07/2018
     * @param  string appId
     * @return citizenshipType(string)
     */
    public static String getCitizenshipTypeByAppId(String appId) {
        String type = 'ERROR';
        if (appId != null && appId != '') {
            List<Application__c> applications = [
                    SELECT a.Id, a.Applicant__c
                    FROM Application__c a
                    WHERE a.Id = :appId
            ];

            if (applications.size() > 0) {
                List<Contact> contacts = [
                        SELECT c.Id, c.Citizenship__c
                        FROM Contact c
                        WHERE c.Id = :applications[0].Applicant__c
                ];
                if(contacts.size() > 0){
                    type = contacts[0].Citizenship__c;
                }
            }
        } else {
            ExLog.add('MyApplicationUtitiles', 'N/A', 'GetCitizenshipTypeByAppId', 'Blank App ID passed to the function' + appId);
        }

        return type;
    }

    /**
     * Get the  Citizenship Type Code based on the Contact Id that is provided.
     * @author  Majid Reisi Dehkordi
     * @date    31/07/2018
     * @param   contactId      id of the contact
     * @return  Retrieve the Citizenship Type Code of the contact
     */
    public static String getCitizenshipTypeCodeByContactId(String contactId) {
        List<Contact> listApplicants = [
                SELECT Residency_Status__c
                FROM Contact
                WHERE Id = :contactId
        ];
        if (listApplicants.size() == 1) {
            Contact applicant = listApplicants[0];
            return applicant.Residency_Status__c;
        }
        return null;
    }

    /**
     *
     * @author Trent De Laney
     * @date 23 Aug 2018 at 10:51:09 am
     * @param  string appId
     * @return applicationStatus(string)
     */
    public static String getApplicationStatusByAppId(String appId) {
        if (appId != '' && appId != null) {
            Application__c[] applications = [
                    SELECT Id, Submission_Progress__c
                    FROM Application__c
                    WHERE Id = :appId
            ];

            if (applications.size() > 0) {
                return applications[0].Submission_Progress__c;
            }
        }
        return 'ERROR';
    }

    /**
     * @author Trent De Laney
     * @date 28 Aug 2018 at 10:51:09 am
     * @param  string acpId
     * @return appId(string)
     */
    public static String getAppIdByAcpId(String acpId) {

        if (acpId != null && acpId != '') {
            List<Application_Course_Preference__c> prefs = [
                    SELECT Id, Application__c
                    FROM Application_Course_Preference__c
                    WHERE Id = :acpId
            ];

            if (prefs.size() > 0) {
                return prefs[0].Application__c;
            }
        }

        return 'ERROR';
    }

    /**
     * Gets a set of picklist options from a given object by label
     * @param  fieldName   Name of the Picklist
     * @param  sObjectName Name of the Object the picklist is on
     * @return             All picklist labels. (List<string>)
     */
    public static List<String> getPicklistOptions(String fieldName, String sObjectName) {
        List<String> options = new List<String>();
        try {
            // Get describe of all the objects
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            // Get the SObject Type from the specific object name that is passed in
            Schema.SObjectType sobjType = gd.get(sObjectName);
            // Get the describe result of the passed in object
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
            // Get the fields of the passed in object
            Map<String, Schema.SObjectField> field_map = r.fields.getMap();
            if (field_map != null) {
                List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldName).getDescribe().getPicklistValues();
                // get the pick list values of the field that was passed in from the field map of the object passed in
                for (Schema.PicklistEntry f : pick_list_values) {
                    options.add(f.getLabel());
                }
            }
        } catch (Exception e) {
            ExLog.add('MyApplicationUtitiles', 'N/A', 'GetPicklistOptions', e.getMessage());
        }

        return options;
    }

    public static Map<String, String> getPicklistOptionsMap(String fieldName, String sObjectName) {
        Map<String, String> options = new Map<String, String>();
        try {
            // Get describe of all the objects
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            // Get the SObject Type from the specific object name that is passed in
            Schema.SObjectType sobjType = gd.get(sObjectName);
            // Get the describe result of the passed in object
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
            // Get the fields of the passed in object
            Map<String, Schema.SObjectField> field_map = r.fields.getMap();
            if (field_map != null) {
                List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldName).getDescribe().getPicklistValues();
                // get the pick list values of the field that was passed in from the field map of the object passed in
                for (Schema.PicklistEntry f : pick_list_values) {
                    options.put(f.getLabel(), f.getValue());
                }
            }
        } catch (Exception e) {
            ExLog.add('MyApplicationUtitiles', 'N/A', 'GetPicklistOptions', e.getMessage());
        }

        return options;
    }

    /**
     * Gets all Encumbrances for a Contact
     * @author Vic Cheng
     * @date 26/07/2018
     * @param  Id Contact Id
     * @return Boolean - true if
     */
    public static List<Encumbrance__c> getEncumbrancesByContact(Id contactId) {
        List<Encumbrance__c> listEncs = [
                SELECT Id, enc_category__c
                FROM Encumbrance__c
                WHERE Contact__c = :contactId
                AND IsActive__c = TRUE
        ];
        return listEncs;
    }

    public static UserRecordAccess getRecordAccessForUserByIds(Id recordId, Id userId) {
        List<UserRecordAccess> listURA = [
                SELECT RecordId
                        , HasReadAccess
                        , HasEditAccess
                        , HasDeleteAccess
                FROM UserRecordAccess
                WHERE UserId = :userId
                AND RecordId = :recordId
        ];

        if (listURA.size() == 1) {
            return listURA[0];
        }
        return null;
    }

    /**
    * @author Trent De Laney
    * @description Used to calculate the fee waiver of previous Monash Students
    * @date 27 Nov 2019 at 2:21:02 pm
    * @param String previousMonashId, Date previousMonashDOB
    * @return Valid student if the data has been entered correctly
    */
    public static Boolean isMonashStudentFeeWaiver(String previousMonashId, Date previousMonashDOB) {

        Boolean validateStudent = false;
        List <Contact> monashSutdents = [
                SELECT Birthdate
                FROM Contact
                WHERE Person_ID_unique__c = :previousMonashId AND Birthdate = :previousMonashDOB
                LIMIT 1
        ];

        if (monashSutdents.size() == 1) {
            validateStudent = true;
        }

        return validateStudent;
    }

    /**
    * @author Trent De Laney
    * @description Used to convert the Campus information which may come through Channels/Course Offering into a Country Location
    * @date 12 Mar 2020 at 10:40:13 am
    * @param String campus
    * @return String campusLocation
    *
    */
    public static String ConvertCampusToLocation(String campus){
        if(AUSTRALIAN_CAMPUS.contains(campus)){
            return 'Australia';
        }
        else if(MALAYSIA_CAMPUS.contains(campus)){
            return 'Malaysia';
        }
        else if(INDONESIA_CAMPUS.contains(campus)){
            return 'Indonesia';
        }
        return null;
    }

    /**
     * @author          Kristian Vegerano
     * @description     Find matching contact record and related course attempts
     *                  This method is WITHOUT sharing by design. The method is called by my.app user to check if their supplied Monash Id is found in the system as other Contacts
     * @date            03/03/2020
     * @param           String previousMonashId
     *                  Date applicantBirthDate
     * @return          Contact
     */
    @AuraEnabled
    public static String findCurrentPreviousStudent(String previousMonashId, Date applicantBirthDate) {        
        //Initialize Variables
        String queryResult = 'NoMatch';
        
        Set<String> currentCourseAttemptStatus = new Set<String>();
        currentCourseAttemptStatus.add('Enrolled');
        currentCourseAttemptStatus.add('Inactive');
        currentCourseAttemptStatus.add('Intermit');

        Set<String> previousCourseAttemptStatus = new Set<String>();
        previousCourseAttemptStatus.add('Discontin');
        previousCourseAttemptStatus.add('Completed');

        //Query matching contact record
        if(previousMonashId != null && applicantBirthDate != null){
            for(Contact loopContact : [SELECT Id, (SELECT Id, Course_Attempt_Status__c FROM Course_Attempts__r)
                                       FROM Contact
                                       WHERE Person_ID_unique__c = :previousMonashId
                                            AND Birthdate = :applicantBirthDate
                                       ORDER BY LastModifiedDate DESC
                                       LIMIT 10]){
                //Setup for the first contact match
                if(queryResult != 'CurrentMatch' && queryResult != 'PreviousMatch'){
                    queryResult = 'HasMatch';
                }

                if(loopContact != null){
                    if(loopContact.Course_Attempts__r != null){
    
                        //Iterate through each existing course attempts for current student status
                        if(queryResult == 'HasMatch' || queryResult == 'PreviousMatch'){
                            for(Course_Attempt__c loopCourseAttempt : loopContact.Course_Attempts__r){
                                if(currentCourseAttemptStatus.contains(loopCourseAttempt.Course_Attempt_Status__c)){
                                    queryResult = 'CurrentMatch';
                                }
                            }
                        }
    
                        //Iterate through each existing course attempts for previous student status
                        if(queryResult == 'HasMatch'){
                            for(Course_Attempt__c loopCourseAttempt : loopContact.Course_Attempts__r){
                                if(previousCourseAttemptStatus.contains(loopCourseAttempt.Course_Attempt_Status__c)){
                                    queryResult = 'PreviousMatch';
                                }
                            }
                        }
    
                    }
                }

            }
        }

        return queryResult;
    }
}