/**
 *  Test coverage written for the assessmentsDSSandGTECheck
    @author  Suman Gunaganti
 */
@isTest
public with sharing class assessmentsDSSandGTECheck_Test {
    @testsetup static void setup() {
        Account ac = new Account(Name='ABC');
        //insert ac;
        contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        
        Country_Attribute__c country =  new Country_Attribute__c();
        country.Country__c = 'India';
        country.GTE_Risk_Rating__c = '2';
        insert country;        

        Application__c app = StudFirst_TestHelper.createInternationalApplication(applicant, country);
        app.HasDisabilities__c = 'Yes';
        app.Residency_Status__c = 'INTRNTNL';
        app.Existing_Aus_disability_support__c = 'No';
        app.Campus_Location__c = 'Australia';
        app.Submission_Location_Country__c = country.Id;
        insert app;
        
        Qualification__c qual = StudFirst_TestHelper.createQualification('custom qual');
        insert qual;
        
        Contact_Qualification__c cqual = StudFirst_TestHelper.createContactQualification(applicant, qual, 'Secondary Education');
        cqual.Qualification_Country__c = country.Id;
        insert cqual;
        
        Application_Qualification_Provided__c aqp = StudFirst_TestHelper.createAppQualProvided(app.Id, cqual.Id);
        insert aqp;
        
        Contact_Document__c cd = StudFirst_TestHelper.createContactDocument(applicant.id, cqual.id);
        cd.Document_Type__c = 'SECSCH_RES';
        insert cd;
        
        Course__c Course = StudFirst_TestHelper.createCourse();
        course.Course_Description__c = 'Master of Advanced Manufacturing Technology';
        insert Course;
        
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;
        
        Application_Course_Preference__c coursePref = StudFirst_TestHelper.createCoursePreferences(app, applicant, courseOffering, course);
        coursePref.Preference_Number__c = '1';
        insert coursePref;
    }
    static testmethod void testDSSandGTECheck(){
        Map<Id,Application_Course_Preference__c> acps = new Map<Id,Application_Course_Preference__c>([select id from Application_Course_Preference__c LIMIT 1]);
        List<Id> acpIds = new List<id>();
        acpIds.addAll(acps.keySet());
        List<assessmentsDSSandGTECheck.DSSandGTECheckResponse> response = assessmentsDSSandGTECheck.DSSandGTECheck(acpIds);
        System.assertEquals('Required', response.get(0).isDSSCheckRequired);
    }

    static testmethod void testDSSandGTECheckGTECountry(){
        Map<Id,Application_Course_Preference__c> acps = new Map<Id,Application_Course_Preference__c>([select id from Application_Course_Preference__c LIMIT 1]);
        List<Id> acpIds = new List<id>();
        acpIds.addAll(acps.keySet());
        List<assessmentsDSSandGTECheck.DSSandGTECheckResponse> response = assessmentsDSSandGTECheck.DSSandGTECheck(acpIds);
        System.assertEquals('Required', response.get(0).isGTECheckRequired);
        System.assertEquals('India and Nepal', response.get(0).GTEReviewGroup);
    }
    
    static testmethod void testDSSandGTECheckGTECountryGTENotRequired(){
        Course__c course = [SELECT Course_Description__c FROM Course__c LIMIT 1];
        course.Course_Description__c = 'Bachelor of Engineering';
        update course;
        Application_Course_Preference__c acp = [select id from Application_Course_Preference__c LIMIT 1];
        List<Id> acpIds = new List<id>{acp.id};
        List<assessmentsDSSandGTECheck.DSSandGTECheckResponse> response = assessmentsDSSandGTECheck.DSSandGTECheck(acpIds);
        System.assertEquals('Required', response.get(0).isGTECheckRequired);
    }
}