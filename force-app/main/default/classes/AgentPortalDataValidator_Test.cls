/**
 * @author Shalini Mendu
 * @date 06 Dec 2019
 * @group Test Class
 * @description Test class to cover the AP validation library
 */
@isTest(isParallel=true)
private class AgentPortalDataValidator_Test {
    private final static String CONTACT_NAME = 'APDataValidator';
    @TestSetup
    static void setup() {
        Contact o_testContact = StudFirst_TestHelper.createInternationalApplicant();
        o_testContact.FirstName = CONTACT_NAME;
        insert o_testContact;
         Application__c o_testApplication = StudFirst_TestHelper.createApplication(o_testContact);
        o_testApplication.Source_System__c = 'AgentPortal';
        insert o_testApplication;
        Course__c o_testCourse = StudFirst_TestHelper.createCourse();
        insert o_testCourse;
        Course_Offering__c o_testCourseOffering = StudFirst_TestHelper.createCourseOffering(o_testCourse);
        insert o_testCourseOffering;
    }

    @IsTest
    static void validateNegativeTestCase() {
        List<Contact> li_contacts = [
                SELECT Id
                FROM Contact
                WHERE FirstName = :CONTACT_NAME
        ];
        System.assert(li_contacts.size() > 0);
        List<Application__c> li_applications = [
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
                WHERE Applicant__c = :li_contacts[0].Id
        ];

        System.assert(li_applications.size() > 0);

        li_applications[0].Residency_Status__c = 'INTRNTNL';
        li_applications[0].Visa_Type__c = '411';
        li_applications[0].Visa_Number__c = '';
        li_applications[0].Passport_Number__c = '';
        li_applications[0].Visa_Start_Date__c = null;
        li_applications[0].Visa_End_Date__c = null;
        update li_applications[0];

        List<Application_Course_Preference__c> li_acp = [
                SELECT Id, Course_Code__C
                FROM Application_Course_Preference__c
                WHERE APPLICATION__C = :li_applications[0].Id
        ];

      new AgentPortalDataValidator().validateApplicationData(li_applications[0].Id);
        System.assert(String.isNotBlank(
                [SELECT Data_Validation_Errors__c FROM APPLICATION__C WHERE Id= :li_applications[0].Id].Data_Validation_Errors__c));
    }

    @IsTest
    static void validatePositiveTestCase() {
        Country_Attribute__c indiaCtry = new Country_Attribute__c(Name = 'INDIA', Callista_Code__c = '7103',
                Country__c = 'INDIA');
        insert indiaCtry;

        Application_Course_Preference__c o_testCoursePreference = StudFirst_TestHelper.createCoursePreferences([SELECT ID FROM APPLICATION__c], [SELECT ID FROM CONTACT], [SELECT ID FROM Course_Offering__c], [SELECT ID FROM Course__c]);

        insert o_testCoursePreference;

        Qualification__c o_testQualification = StudFirst_TestHelper.createQualification('AP Test Qualification');
        insert o_testQualification;

        Contact_Qualification__c o_testContactQualification = StudFirst_TestHelper.createContactQualification([SELECT ID FROM CONTACT], o_testQualification, 'Tertiary Education');
        insert o_testContactQualification;
        //Get the application First
        List<Contact> li_contacts = [
                SELECT Id
                FROM Contact
                WHERE FirstName = :CONTACT_NAME
        ];


        System.assert(li_contacts.size() > 0);

        List<Application__c> li_applications = [
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
                WHERE Applicant__c = :li_contacts[0].Id
        ];

        System.assert(li_applications.size() > 0);


        li_applications[0].Residency_Status__c = 'INTRNTNL';
        li_applications[0].Visa_Type__c = '411';
        li_applications[0].Visa_Number__c = 'v13434343';
        li_applications[0].Passport_Number__c = 'A3456776';
        li_applications[0].Visa_Start_Date__c = Date.today().addYears(-5);
        li_applications[0].Visa_End_Date__c =  Date.today().addYears(5);
        li_applications[0].Citizenship_Country__c = indiaCtry.Id;
        update li_applications[0];

        List<Application_Course_Preference__c> li_acp = [
                SELECT Id, Course_Code__C
                FROM Application_Course_Preference__c
                WHERE APPLICATION__C = :li_applications[0].Id
        ];
       Test.startTest();
        new AgentPortalDataValidator().validateApplicationData(li_applications[0].Id);
        System.assert(String.isBlank(
                [SELECT Data_Validation_Errors__c FROM APPLICATION__C WHERE Id= :li_applications[0].Id].Data_Validation_Errors__c));

        Test.stopTest();
    }
}