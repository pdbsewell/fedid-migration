/**
 * @author Trent De Laney
 * @date 18 Nov 2019 at 1:20:04 pm
 * @group Integration
 * @description Used to validate the information coming through the IDP submission channel to assess the completeness of an application before considering it for Assessment
 * 
 * @revision
 *          2020.05.13: SFTLG-902 - adding "pendig merge" before "sent for submission" status for contact merge
 */
public with sharing class IDPDataValidator implements IDataValidator {
    //5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes - part of indonesian implementation
    public static List<String> INTERNATIONAL_CITIZENSHIP_TYPES = new List<String>{
            'INTRNTNL', 'INT-TEP', 'INT-SUN', 'INT-SUN-P', 'INT-IDN', 'INT-IDN-P'
    };

    /*******************************************************************************
    * @author       Shalini Mendu
    * @date         09.Jul.2019
    * @description  This method validates the application data that comes with the submission to CRM
    * @revision Trent De Laney - SFTN-463 - Cloned from AgentPortalDataValidator to allow for specific tweaking per channel
    *******************************************************************************/
    public void validateApplicationData(String appId) {
        Application__c appRec = [
                SELECT Id, Status__c, Applying_for_Credit__c, Is_Sponsored__c, Sponsor_Name__c,
                        Sponsorship_Status__c, Guardian_Full_Name__c, Guardian_Phone_Number__c,
                        Guardian_Relationship__c, Guardian_Email_Address__c,Data_Validation_Errors__c,
                        Applicant__c, Residency_Status__c, HasDisabilities__c,
                        Citizenship_Country__c, Visa_Type__c, Australian_Immigration_Office_Issued__c, Visa_Number__c,
                        Passport_Number__c, Visa_Start_Date__c, Visa_End_Date__c,
                        Refused_entry_visa_to_any_country__c, Breached_visa_condition__c,
                        Medical_health_prevent_visa__c, Protection_visa_in_any_country__c,
                        Convicted_of_crime_offence__c, Access_and_Equity_Question__c, Applicant__r.Aboriginal_or_Torres_Strait_Islander__c, Fee_Payment_Mode__c, Fee_Waiver_Code__c
                FROM Application__c
                WHERE Id = :appId
        ];

        // add all the error messages into the list
        List<String> listSectionAndErrors = new List<String>();

        List<String> errorMessages = new List<String>();
        errorMessages = validateCitizenshipSection(appRec);

        if (errorMessages.size() > 0) {
            listSectionAndErrors.addAll(errorMessages);
        }

        errorMessages = validateACPSection(appRec);

        if (errorMessages.size() > 0) {
            listSectionAndErrors.addAll(errorMessages);
        }

        errorMessages = validateQualSection(appRec);
        if (errorMessages.size() > 0) {
            listSectionAndErrors.addAll(errorMessages);
        }

        if (listSectionAndErrors.size() > 0) {
            appRec.Status__c = 'Failed Data validation';
            appRec.Data_Validation_Errors__c = '';
            System.debug(LoggingLevel.DEBUG, 'errors==' + listSectionAndErrors);
            for (String err : listSectionAndErrors) {
                appRec.Data_Validation_Errors__c += err;
            }
        } else {
            // SFTLG-902 start
            // appRec.Status__c = 'Sent for Submission';
            appRec.Status__c = MyApplicationUtilities.APP_PENDING_MERGE_STATUS;
            appRec.Campus_Location__c = convertCourseOfferingLocationToCountryLocation(appRec);
            // SFTLG-902 end
            appRec.Submitted_Date__c = Date.today();
            appRec.Declaration_Accepted__c = true;
            appRec.Data_Validation_Errors__c = '';
        }

        update appRec;

    }

    /**
    * @author Trent De Laney
    * @description Converts the inbound course offering location to country for Application Assessment trigger.
    * @date 4 Jun 2020 at 11:39:25 am
    * @param Application userApplication
    * @return Campus Country Result
    */
    static public String convertCourseOfferingLocationToCountryLocation(Application__c userApplication) {
        String campusLocation = '';

        List<Application_Course_Preference__c> coursePreferences = [
                SELECT Course_Offering__r.Location_Code__c
                FROM Application_Course_Preference__c
                WHERE Application__c = :userApplication.Id
        ];

        campusLocation = MyApplicationUtilities.ConvertCampusToLocation(coursePreferences[0].Course_Offering__r.Location_Code__c);
        return campusLocation;
    }

    /*******************************************************************************
    * @author       Shalini Mendu
    * @date         09.Jul.2019
    * @description  This method validates the citizenship section
    * @revision Trent De Laney - SFTN-463 - Cloned from AgentPortalDataValidator to allow for specific tweaking per channel
    *******************************************************************************/
    static public List<String> validateCitizenshipSection(Application__c userApplication) {
        List<String> errorMessages = new List<String>();

        String residencyStatus = userApplication.Residency_Status__c;
        if (String.isBlank(residencyStatus)) {
            errorMessages.add('Application Residency Status:Citizenship Type is missing.\n');
        } else if (INTERNATIONAL_CITIZENSHIP_TYPES.indexOf(residencyStatus) >= 0) {
            if (userApplication.Citizenship_Country__c == null) {
                errorMessages.add('Application Citizenship Country:Country of Citizenship is missing.\n');
            }
            if (userApplication.Visa_Type__c != null) {

                if (String.isBlank(userApplication.Visa_Number__c)) {
                    errorMessages.add('Application Visa Number:Visa Number is not valid.\n');
                }

                if (String.isBlank(userApplication.Passport_Number__c)) {
                    errorMessages.add('Application Passport Number:Passport Number is not valid.\n');
                }

                if (userApplication.Visa_Start_Date__c == null) {
                    errorMessages.add('Application Visa Start Date:Visa Start Date is not valid.\n');
                }

                if (userApplication.Visa_End_Date__c == null) {
                    errorMessages.add('Application Visa End Date :Visa End Date is not valid.\n');
                }
            }

        }
        return errorMessages;
    }

    /*******************************************************************************
    * @author       Shalini Mendu
    * @date         09.Jul.2019
    * @description  This method validates the ACP section
    * @revision Trent De Laney - SFTN-463 - Cloned from AgentPortalDataValidator to allow for specific tweaking per channel
    *******************************************************************************/
    static public List<String> validateACPSection(Application__c userApplication) {
        List<String> errorMessages = new List<String>();

        List<Application_Course_Preference__c> appCourses = [
                SELECT Id, Name, Course_Code__c, Course_Offering__r.Active__c, Course_Offering__r.Location_Code__c, Application__r.Campus_Location__c
                FROM Application_Course_Preference__c
                WHERE Application__c = :userApplication.Id
        ];

        if (appCourses.isEmpty()) {
            errorMessages.add('Application ACP:Please add the courses you want to apply to continue.\n');
        }
        if (!appCourses.isEmpty() && isInvalidACPBundle(appCourses)) {
            errorMessages.add('Application ACP:The courses you selected cannot be submitted as a standalone application.');
        }

        if (appCourses.size() > 0) {
            String locationCode = '';
            for (Application_Course_Preference__c pref : appCourses) {
                if (locationCode == '') {
                    locationCode = MyApplicationUtilities.ConvertCampusToLocation(pref.Course_Offering__r.Location_Code__c);
                } else if (locationCode != MyApplicationUtilities.ConvertCampusToLocation(pref.Course_Offering__r.Location_Code__c)) {
                    System.debug(locationCode);
                    System.debug(MyApplicationUtilities.ConvertCampusToLocation(pref.Course_Offering__r.Location_Code__c));
                    errorMessages.add('Application ACP:' + pref.Name + ' different course preference campus selections. Please ensure that the ACPs under the application are for the same country');
                    break;
                }
                if (pref.Course_Offering__r != null && !pref.Course_Offering__r.Active__c) {
                    errorMessages.add('Application ACP:' + pref.Name + ' course preference(s) you have selected are no longer available and are marked for your action. Please remove them from your list, then search again to find an available course offering.');
                    break;
                } else if (pref.Course_Offering__r == null) {
                    errorMessages.add('Application ACP:' + pref.Name + ' course preference(s) has no CourserOfferings attached.');
                    break;
                }
            }
        }

        return errorMessages;
    }

    /*******************************************************************************
    * @author       Shalini Mendu
    * @date         09.Jul.2019
    * @description  This method validates the Qualification section
    * @revision Trent De Laney - SFTN-463 - Cloned from AgentPortalDataValidator to allow for specific tweaking per channel
    *******************************************************************************/
    static public List<String> validateQualSection(Application__c userApplication) {
        List<String> errorMessages = new List<String>();

        List<Contact_Qualification__c> conQuals = [
                SELECT Id, Qualification_Type__c
                FROM Contact_Qualification__c
                WHERE Contact__c = :userApplication.Applicant__c
        ];

        if (conQuals.isEmpty()) {
            errorMessages.add('Contact Qualification:Please add your qualifications to continue.');
        }

        return errorMessages;
    }

    /*******************************************************************************
    * @author       Shalini Mendu
    * @date         10.Jul.2019
    * @description  This method validates the ACP for some invalid course selections
    * @revision Trent De Laney - SFTN-463 - Cloned from AgentPortalDataValidator to allow for specific tweaking per channel
    *******************************************************************************/
    private static Boolean isInvalidACPBundle(List<Application_Course_Preference__c> selectedACPS) {
        Boolean isBundleInvalid = false;

        Set<String> notStandalone = new Set<String>();
        notStandalone.add('3626'); // Monash English Briding
        notStandalone.add('3623'); // Monash English Briding
        Integer numberOfACPs = 0;
        for (Application_Course_Preference__c acpTemp : selectedACPS) {
            if (notStandalone.contains(acpTemp.Course_Code__c)) {
                numberOfACPs++;
            }
        }

        if (numberOfACPs == selectedACPS.size()) {
            isBundleInvalid = true;
        }

        return isBundleInvalid;
    }
}