/**
 * @description Test class for ApplicationAssessmentUtil.cls
 */
@isTest(isParallel=true)
public class ApplicationAssessmentUtil_Test {

    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == DOM-AUS
     *              THEN Applicant is DOMESTIC
     */
    static testMethod void test_CitizenshipDomestic_Scenario1() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'DOM-AUS';
        update applications;
        
        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('DOMESTIC',citizenship);
        Test.stopTest();
    }
    
    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == DOM-HV
     *              THEN Applicant is DOMESTIC
     */
    static testMethod void test_CitizenshipDomestic_Scenario2() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'DOM-HV';
        update applications;

        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('DOMESTIC',citizenship);
        Test.stopTest();
    }

    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == DOM-NZ
     *              THEN Applicant is DOMESTIC
     */
    static testMethod void test_CitizenshipDomestic_Scenario3() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'DOM-NZ';
        update applications;

        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('DOMESTIC',citizenship);
        Test.stopTest();
    }

    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == DOM-PR
     *              THEN Applicant is DOMESTIC
     */
    static testMethod void test_CitizenshipDomestic_Scenario4() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'DOM-PR';
        update applications;

        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('DOMESTIC',citizenship);
        Test.stopTest();
    }

    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == DOM-SUN
     *              THEN Applicant is INTERNATIONAL
     */
    static testMethod void test_CitizenshipInternational_Scenario1() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'DOM-SUN';
        update applications;

        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('INTERNATIONAL',citizenship);
        Test.stopTest();
    }

    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == DOM-SA
     *              THEN Applicant is INTERNATIONAL
     */
    static testMethod void test_CitizenshipInternational_Scenario2() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'DOM-SA';
        update applications;

        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('INTERNATIONAL',citizenship);
        Test.stopTest();
    }

    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == INTRNTNL
     *              THEN Applicant is INTERNATIONAL
     */
    static testMethod void test_CitizenshipInternational_Scenario3() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'INTRNTNL';
        update applications;

        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('INTERNATIONAL',citizenship);
        Test.stopTest();
    }

    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == INT-TEP
     *              THEN Applicant is INTERNATIONAL
     */
    static testMethod void test_CitizenshipInternational_Scenario4() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'INT-TEP';
        update applications;

        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('INTERNATIONAL',citizenship);
        Test.stopTest();
    }

    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == INT-SUN-P
     *              THEN Applicant is INTERNATIONAL
     */
    static testMethod void test_CitizenshipInternational_Scenario5() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'INT-SUN-P';
        update applications;

        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('INTERNATIONAL',citizenship);
        Test.stopTest();
    }

    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == INT-SUN
     *              THEN Applicant is INTERNATIONAL
     */
    static testMethod void test_CitizenshipInternational_Scenario6() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'INT-SUN';
        update applications;

        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('INTERNATIONAL',citizenship);
        Test.stopTest();
    }

    /**
     * @description GIVEN Application is submitted
     *              WHEN Residency_Status__c == INT-SA
     *              THEN Applicant is INTERNATIONAL
     */
    static testMethod void test_CitizenshipInternational_Scenario7() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__r.Id, Residency_Status__c FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');

        applications.get(0).Residency_Status__c = 'INT-SA';
        update applications;

        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0).Id);
        System.assertEquals('INTERNATIONAL',citizenship);
        Test.stopTest();
    }

    /**
     * @description Test catch scenario
     */
    static testMethod void test_Catch_Scenario1() {
        String param = null;
        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(param);
        System.assertEquals('ERROR',citizenship);
        Test.stopTest();
    }

    /**
     * @description Test catch scenario
     */
    static testMethod void test_Catch_Scenario2() {
        Application__c param = null;
        Test.startTest();
        String citizenship = ApplicationAssessmentUtil.getCitizenshipType(param);
        System.assertEquals('ERROR',citizenship);
        Test.stopTest();
    }
    
    @testSetup static void setup() {
        // Create test account
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;
        System.assert(testAccount.Id != null, '### Insert Test Account Failed.');

        //Create test contact
        Contact testContact = new Contact();
        testContact.FirstName = 'Test FirstName';
        testContact.LastName = 'Test LastName';
        testContact.MobilePhone = '0481977625';
        testContact.Email = 'testemail001@monash.edu';
        testContact.Monash_Email_Address__c = 'testemailmonash@monash.edu';
        testContact.Birthdate = Date.today().addYears(-11);
        testContact.SAP_Staff_Id__c = '';
        insert testContact;
        System.assert(testContact.Id != null, '### Insert Test Contact Failed.');

        //Create Application
        Application__c testApplication = new Application__c();
        testApplication.Applicant__c = testContact.Id;
        testApplication.Status__c = 'Draft';
        insert testApplication;
        System.assert(testApplication.Id != null, '### Insert Test Application Failed.');
    }
}