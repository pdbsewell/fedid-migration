@isTest(isParallel=true)
public with sharing class AffiliationCheckService_Test {
    @TestSetup
    static void makeData(){
        // Agencies
        Account testAccount1 = new Account(Name = 'AgencyOne', Monash_AM_Campus__c = 'Malaysia', Status__c='Appointed', Callista_Org_Unit_Code__c='TESTA1');
        Account testAccount2 = new Account(Name = 'AgencyTwo', Monash_AM_Campus__c = 'Australia;Malaysia', Status__c='Appointed', Callista_Org_Unit_Code__c='TESTA2');
        Account testAccount3 = new Account(Name = 'AgencyThree', Monash_AM_Campus__c = 'Malaysia', Status__c='Appointed', Callista_Org_Unit_Code__c='TESTA3');
        Account testAccount4 = new Account(Name = 'AgencyFour', Monash_AM_Campus__c = 'Australia;Malaysia', Status__c='Contract Terminated', Callista_Org_Unit_Code__c='TESTA4');
        Account testAccount5 = new Account(Name = 'AgencyFive', Monash_AM_Campus__c = 'Australia', Status__c='Appointed', Callista_Org_Unit_Code__c='TESTA5');
        insert new List<Account> {testAccount1, testAccount2, testAccount3, testAccount4, testAccount5};
        
        // Applicant
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', Email = 'TestEmail94183@testemail.com');
        insert testContact;
        
        // Applications
        Application__c appForTerminatedAgency = new Application__c(Source_system__c = 'Agent Portal', Applicant__c = testContact.id, Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B', Agent__c = testAccount4.id);
        insert appForTerminatedAgency;
        
        // ACP Statuses
        List_Of_Values__c lov1 = new List_Of_Values__c (value__c= 'AP-PROGRES', system_code__c = 'PENDING', type__c='ADM_OUTCOME_STATUS', name = 'AP-PROGRES (PENDING)', is_Active__c = true);
        List_Of_Values__c lov2 = new List_Of_Values__c (value__c= 'ACC-DEL', system_code__c = 'REJECTED', type__c='ADM_OFFER_RESP_STATUS', name = 'ACC-DEL (REJECTED)', is_Active__c = true);
        List_Of_Values__c lov3 = new List_Of_Values__c (value__c= 'ACCEPTED', system_code__c = 'ACCEPTED', type__c='ADM_OFFER_RESP_STATUS', name = 'ACCEPTED (ACCEPTED)', is_Active__c = true);
        List_Of_Values__c lov4 = new List_Of_Values__c (value__c= 'OFFER', system_code__c = 'OFFER', type__c='ADM_OUTCOME_STATUS', name = 'OFFER (OFFER)', is_Active__c = true);
        List_Of_Values__c lov5 = new List_Of_Values__c (value__c= 'REJECTED', system_code__c = 'REJECTED', type__c='ADM_OUTCOME_STATUS', name = 'REJECTED (REJECTED)', is_Active__c = true);
        List_Of_Values__c lov6 = new List_Of_Values__c (value__c= 'DEFERRAL', system_code__c = 'DEFERRAL', type__c='ADM_OFFER_RESP_STATUS', name = 'DEFERRAL (DEFERRAL)', is_Active__c = true);
        insert new List<List_Of_Values__c> {lov1, lov2, lov3, lov4, lov5, lov6};
        
        // Course
        Course__c course1 = StudFirst_TestHelper.createCourse();
        insert new List<Course__c> {course1};
        // Course offerings
        Course_Offering__c offering1 = StudFirst_TestHelper.createCourseOffering(course1);
        offering1.Course_Title__c = 'General Course';
        Course_Offering__c offering2 = StudFirst_TestHelper.createCourseOffering(course1);
        offering2.Course_Title__c = 'Live Course';
        offering2.Start_Date__c = date.today();
        Course_Offering__c offering3 = StudFirst_TestHelper.createCourseOffering(course1);
        offering3.Course_Title__c = 'Expired Course';
        offering3.Start_Date__c = date.today().addDays(-500);
        insert new List<Course_Offering__c> {offering1, offering2, offering3};
            
        // Disable the linking of applications to the branch manager of an Agency
		Feature_Switch__c fs = new Feature_Switch__c();
        fs.Align_Application_Owner__c = false;
        insert fs;
            
	}
    
    @isTest
    private static void NoOtherApplicationsCheck_Test() {
        Contact applicant = [SELECT id FROM Contact WHERE email = 'TestEmail94183@testemail.com' LIMIT 1];
        Account agency = [SELECT id FROM Account WHERE Name = 'AgencyOne' LIMIT 1];
        Test.startTest();
            AffiliationCheckService.AffiliationResult ar = new AffiliationCheckService(applicant.Id, agency.Id, 'Australia', null).result;
        Test.stopTest();
        System.assert(ar.canCreateApplications == true && ar.canSubmitApplications == true, 'NoOtherApplicationsCheck failed');
    }
    @isTest
    private static void AllowIfDraftsCheck_Test() {
        Contact applicant = [SELECT id FROM Contact WHERE email = 'TestEmail94183@testemail.com' LIMIT 1];
        List<Account> agency = [SELECT id FROM Account WHERE Name IN ('AgencyOne', 'AgencyTwo', 'AgencyThree') ];
        Account applyingAgency = [SELECT id FROM Account WHERE Name = 'AgencyFive' LIMIT 1];
        Application__c draft1 = new Application__c(Source_system__c = 'Agent Portal',Applicant__c = applicant.id, Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B', Agent__r = agency.get(0), Agent_Org_Unit_Code__c = 'TESTA1');
        Application__c draft2 = new Application__c(Source_system__c = 'Agent Portal',Applicant__c = applicant.id, Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B', Agent__r = agency.get(1), Agent_Org_Unit_Code__c = 'TESTA2');
        Application__c draft3 = new Application__c(Source_system__c = 'Agent Portal',Applicant__c = applicant.id, Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B', Agent__r = agency.get(2), Agent_Org_Unit_Code__c = 'TESTA3');
        insert new List<Application__c> {draft1, draft2, draft3};
        Test.startTest();
            AffiliationCheckService.AffiliationResult ar = new AffiliationCheckService(applicant.Id, applyingAgency.Id, 'Australia', null).result;
        Test.stopTest();
        System.assert(ar.canCreateApplications == true && ar.canSubmitApplications == true, 'AllowIfDraftsCheck failed');
    }
    @isTest
    private static void CompletedApplicationsCheck_Test() {
        Contact applicant = [SELECT id FROM Contact WHERE email = 'TestEmail94183@testemail.com' LIMIT 1];
        List<Account> agency = [SELECT id FROM Account WHERE Name IN ('AgencyOne', 'AgencyTwo', 'AgencyThree') ];
        Account applyingAgency = [SELECT id FROM Account WHERE Name = 'AgencyFive' LIMIT 1];
        Application__c appn1 = new Application__c(Source_system__c = 'Agent Portal',Applicant__c = applicant.id, Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B', Agent__r = agency.get(0), Agent_Org_Unit_Code__c = 'TESTA1', Status__c = 'Review');
        Application__c appn2 = new Application__c(Source_system__c = 'Agent Portal',Applicant__c = applicant.id, Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B', Agent__r = agency.get(1), Agent_Org_Unit_Code__c = 'TESTA2', Status__c = 'Review');
        Application__c appn3 = new Application__c(Source_system__c = 'Agent Portal',Applicant__c = applicant.id, Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B', Agent__r = agency.get(2), Agent_Org_Unit_Code__c = 'TESTA3', Status__c = 'Draft');
        insert new List<Application__c> {appn1, appn2, appn3};
        Course_Offering__c offering = [SELECT id FROM Course_Offering__c WHERE Course_Title__c = 'General Course' LIMIT 1];
        Course__c course = [SELECT id FROM Course__c LIMIT 1];
        List_Of_Values__c rejectedByApplicant = [SELECT id FROM List_Of_Values__c WHERE name = 'ACC-DEL (REJECTED)' LIMIT 1];
        List_Of_Values__c rejectedByMonash = [SELECT id FROM List_Of_Values__c WHERE name = 'REJECTED (REJECTED)' LIMIT 1];
        List_Of_Values__c acceptedByMonash = [SELECT id FROM List_Of_Values__c WHERE name = 'OFFER (OFFER)' LIMIT 1];
        Test.startTest();
            Application_Course_Preference__c acpForAppn1 = StudFirst_TestHelper.createCoursePreferences(appn1, applicant, offering, course);
            acpForAppn1.Outcome_Status_LOV__c = rejectedByMonash.id;
            Application_Course_Preference__c acpForAppn2 = StudFirst_TestHelper.createCoursePreferences(appn2, applicant, offering, course);
            acpForAppn2.Outcome_Status_LOV__c = acceptedByMonash.id;
            acpForAppn2.Offer_Response_Status_LOV__c = rejectedByApplicant.id;
            Application_Course_Preference__c acpForAppn3 = StudFirst_TestHelper.createCoursePreferences(appn3, applicant, offering, course);
            insert new List<Application_Course_Preference__c> {acpForAppn1, acpForAppn2, acpForAppn3};
            AffiliationCheckService.AffiliationResult ar = new AffiliationCheckService(applicant.Id, applyingAgency.Id, 'Australia', null).result;
        Test.stopTest();
        System.assert(ar.canCreateApplications == true && ar.canSubmitApplications == true, 'CompletedApplicationsCheck failed');
        System.assert(ar.message.containsIgnoreCase('Agent may proceed with creating Applications.'), 'CompletedApplicationsCheck failed');
    }
    
    @isTest
    private static void AcceptedApplicationsCheck_BLOCKED_Test() {
        
        Contact applicant = [SELECT id FROM Contact WHERE email = 'TestEmail94183@testemail.com' LIMIT 1];
        List<Account> agency = [SELECT id, callista_org_unit_code__c FROM Account WHERE Name IN ('AgencyOne', 'AgencyTwo') ];
        // Account applyingAgency = [SELECT id FROM Account WHERE Name = 'AgencyFive' LIMIT 1];

        // Application__c appn1 = new Application__c(Source_system__c = 'Agent Portal', Applicant__c = applicant.id, Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B',  Agent_Org_Unit_Code__c = 'TESTA1', Status__c = 'Review');
        Application__c appn2 = new Application__c(Source_system__c = 'Agent Portal', Applicant__c = applicant.id, Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B',  Agent_Org_Unit_Code__c = 'TESTA2', Status__c = 'Review');
        Application__c incomingAppn = new Application__c(Source_system__c = 'Agent Portal', Applicant__c = applicant.id, Campus_Location__c = 'Malaysia', Residency_Status__c = 'DOM-SUN', Residency_Sub_status__c = 'DOM-SUN.B',  Agent_Org_Unit_Code__c = 'TESTA2', Status__c = 'Draft');
        insert new List<Application__c> {appn2, incomingAppn};
            
		Course_Offering__c offering = [SELECT id FROM Course_Offering__c WHERE Course_Title__c = 'Live Course' LIMIT 1];
        Course__c course = [SELECT id FROM Course__c LIMIT 1];
        List_Of_Values__c acceptedByMonash = [SELECT id FROM List_Of_Values__c WHERE name = 'OFFER (OFFER)' LIMIT 1];
        List_Of_Values__c acceptedByApplicant = [SELECT id FROM List_Of_Values__c WHERE name = 'ACCEPTED (ACCEPTED)' LIMIT 1];
        Test.startTest();
            // blank outcome
            // Application_Course_Preference__c acpForAppn1 = StudFirst_TestHelper.createCoursePreferences(appn1, applicant, offering, course);
            // outcome = offered; response = accepted
            Application_Course_Preference__c acpForAppn2 = StudFirst_TestHelper.createCoursePreferences(appn2, applicant, offering, course);
            acpForAppn2.Outcome_Status_LOV__c = acceptedByMonash.id;
            acpForAppn2.Offer_Response_Status_LOV__c = acceptedByApplicant.id;
            Application_Course_Preference__c incomingACP = StudFirst_TestHelper.createCoursePreferences(incomingAppn, applicant, offering, course);
        	insert new List<Application_Course_Preference__c> {acpForAppn2, incomingACP};
            List<Application_Course_Preference__c> incomingACPs = [SELECT id, Application__c, Application__r.Name, Outcome_Status_LOV__r.Value__c, Offer_Response_Status_LOV__r.Value__c, Course__c, Course_Title__c, Calendar_Start_Date__c, Course_Offering__r.Course__r.id 
                                                        FROM Application_Course_Preference__c WHERE id = :incomingACP.id]; // fetching formula fields
                AffiliationCheckService.AffiliationResult ar = new AffiliationCheckService(applicant.Id, agency[1].Id, 'Malaysia', incomingACPs).result;
        Test.stopTest();
        System.assert(ar.canCreateApplications == false && ar.canSubmitApplications == false, 'CompletedApplicationsCheck::Same Course/Intake::Same Campus failed');
    }
}