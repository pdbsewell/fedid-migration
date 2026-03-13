/*******************************************************************************
* @author		Suman Gunaganti
* @date         13.Dec.2019
* @description   Test class for the CancelAdmissionApplication class
*******************************************************************************/
@IsTest
public with sharing class CancelAdmissionApplication_Test {
    @testSetup static void setup() {
        Account ac = new Account(Name='ABC');
        //insert ac;
        contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        Application__c app = StudFirst_TestHelper.createApplication(applicant);
        app.Status__c = 'Draft';
        insert app;
        Qualification__c qual = StudFirst_TestHelper.createQualification('custom qual');
        insert qual;
        Contact_Qualification__c cqual = StudFirst_TestHelper.createContactQualification(applicant, qual, 'Secondary Education');
        insert cqual;
        Application_Qualification_Provided__c aqp = StudFirst_TestHelper.createAppQualProvided(app.Id, cqual.Id);
        insert aqp;
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, applicant, courseOffering, course);
        insert acp;
        
        Document_Checklist__c appCheckList = new Document_Checklist__c();
        appCheckList.Contact_Qualification__c = cqual.id;
        appCheckList.Status__c = 'Submitted';
        appCheckList.Application__c = app.Id;
        appCheckList.Unique_ID__c = String.valueOf(app.Id) + String.valueOf(cqual.id);
        appCheckList.Contact__c = applicant.Id;
        Insert appCheckList;
        
        Contact_Document__c cd = StudFirst_TestHelper.createContactDocument(applicant.id, cqual.id);
        cd.Document_Type__c = 'SECSCH_RES';
        cd.Document_Checklist__c = appCheckList.Id;
        cd.Internal_Only__c = False;
        insert cd;
        ContentDocument file = StudFirst_TestHelper.createTestDocument(true, app.id, cd.id);
    }
    @IsTest
    static void test_cancelApplication(){           
        Test.startTest();
        Application__c app = [SELECT Id, Status__c FROM Application__c];
        app.Status__c = 'Cancelled';
        Update app;
        Test.stopTest();
        List<Application_Course_Preference__c> cancelledAcps = [select id from Application_Course_Preference__c where Application__c = :app.Id];
        System.assert(cancelledAcps.isEmpty(), 'ERROR: ACP records should be deleted');
        List<Contact_Qualification__c> cquals = [SELECT Id FROM Contact_Qualification__c];
        System.assert(cquals.isEmpty(), 'ERROR: contact Qual records should be deleted');
    }
    /*
    * SFTG-1841 Test Method to check the Fix for Duplicate IDs in List Exception
    */
    @IsTest
    static void test_cancelApplicationDuplicates(){       
        Contact applicant = [SELECT id FROM Contact WHERE LastName = 'Bloggs' LIMIT 1];
        Application__c app1 = StudFirst_TestHelper.createApplication(applicant);
        app1.Status__c = 'Draft';
        insert app1;
        Application__c app2 = StudFirst_TestHelper.createApplication(applicant);
        app2.Status__c = 'Draft';
        insert app2;
        Qualification__c qual = StudFirst_TestHelper.createQualification('custom qual');
        insert qual;
        Contact_Qualification__c cqual = StudFirst_TestHelper.createContactQualification(applicant, qual, 'Secondary Education');
        insert cqual;
        Application_Qualification_Provided__c appQual1 = StudFirst_TestHelper.createAppQualProvided(app1.id, cqual.id);
        insert appQual1;
        Application_Qualification_Provided__c appQual2 = StudFirst_TestHelper.createAppQualProvided(app2.id, cqual.id);
        insert appQual2;

        Test.startTest();
        List<Application__c> lstApps = new List<Application__c> ();
        for(Application__c app : [SELECT Id, Status__c FROM Application__c WHERE id = :app1.id OR id = :app2.id]){
            app.Status__c = 'Cancelled';
            lstApps.add(app);
        }
        Update lstApps;
        Test.stopTest();

        List<Contact_Qualification__c> cquals = [SELECT Id FROM Contact_Qualification__c WHERE id = :cqual.id];
        System.assert(cquals.isEmpty(), 'ERROR: Duplicate contact Qual records should be deleted');
    }
}