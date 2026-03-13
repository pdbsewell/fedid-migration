/**
 * @description Test Class for ACPValidationFullOfferService
 * @author      Sravani Naramsetti
 * @date        07/01/2025
 * @group       Admissions
 */
@isTest(isParallel=true)
public class ACPValidationFullOfferService_Test {
	@testsetup
    public static void setup() {
		//create contact
        contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        //create country
        Country_Attribute__c country =  new Country_Attribute__c();
        country.Country__c = 'India';
        country.GTE_Risk_Rating__c = '2';
        insert country;        
		//create application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(applicant, country);
        app.HasDisabilities__c = 'Yes';
        app.Residency_Status__c = 'INTRNTNL';
        app.Existing_Aus_disability_support__c = 'No';
        app.Campus_Location__c = 'Australia';
        app.Submission_Location_Country__c = country.Id;
        insert app;
        //create qualification
        Qualification__c qual = StudFirst_TestHelper.createQualification('custom qual');
        insert qual;
        //create contact qualification
        Contact_Qualification__c cqual = StudFirst_TestHelper.createContactQualification(applicant, qual, 'Secondary Education');
        cqual.Qualification_Country__c = country.Id;
        insert cqual;
        //create application qualification provided
        Application_Qualification_Provided__c aqp = StudFirst_TestHelper.createAppQualProvided(app.Id, cqual.Id);
        insert aqp;
        //create contact document
        Contact_Document__c cd = StudFirst_TestHelper.createContactDocument(applicant.id, cqual.id);
        cd.Document_Type__c = 'SECSCH_RES';
        insert cd;
        //create course
        Course__c Course = StudFirst_TestHelper.createCourse();
        course.Course_Description__c = 'Master of Advanced Manufacturing Technology';
        insert Course;
        //create course offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;
        //create application course preference
        Application_Course_Preference__c coursePref = StudFirst_TestHelper.createCoursePreferences(app, applicant, courseOffering, course);
        coursePref.Preference_Number__c = '1';
        insert coursePref;
    }
    
    @isTest
    public static void validateEducationQual() {
        //GIVEN: a ACP without English and Education Qualification
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        Test.startTest();
        //WHEN: Full offer Outcome
        List<ACPValidationFullOfferService.ValidationResponse> resp=ACPValidationFullOfferService.FullOfferValidationCheck(new List<Id>{acp.Id});
        //THEN: Validation is full failed
        Assert.areEqual(resp[0].isValid,false);
        Assert.areEqual(resp[0].resultEnglishMessage,'Full failed');
        Test.stopTest();
        
    }
    
    @isTest
    public static void validateQual(){
        //GIVEN: a ACP without Education Qualification
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        Contact_Qualification__c contactQual = [Select Id from Contact_Qualification__c LIMIT 1];
        Contact c = [Select Id from Contact LIMIT 1];
        //English Qualification is assigned to ACP
        Course_Preference_Qualification__c coursePreferenceQualification = new Course_Preference_Qualification__c();
        coursePreferenceQualification.Type__c = 'English Test Results';
        coursePreferenceQualification.Application_Course_Preference_Parent__c = acp.Id;
        coursePreferenceQualification.Contact_Qualification__c = contactQual.Id;
        coursePreferenceQualification.Qualification_Type__c = 'English';
        coursePreferenceQualification.Contact__c = c.Id;
        coursePreferenceQualification.Result__c = 'Satisfactory';
        insert coursePreferenceQualification;
        Test.startTest();
        //WHEN: Full offer Outcome
        List<ACPValidationFullOfferService.ValidationResponse> resp=ACPValidationFullOfferService.FullOfferValidationCheck(new List<Id>{acp.Id});
        //THEN: Education Validation is failed
        Assert.areEqual(resp[0].isValid,false);
        Assert.areEqual(resp[0].resultEducationMessage,'No Education');
        Test.stopTest();
    }
    
    @isTest
    public static void validateEnglishQual(){
        //GIVEN: a ACP with no Education Qualificationand Unsatisfactory English Qualification
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        Contact_Qualification__c contactQual = [Select Id from Contact_Qualification__c LIMIT 1];
        Contact c = [Select Id from Contact LIMIT 1];
        //Unsatisfactory English Qualification assigned
        Course_Preference_Qualification__c coursePreferenceQualification = new Course_Preference_Qualification__c();
        coursePreferenceQualification.Type__c = 'English Test Results';
        coursePreferenceQualification.Application_Course_Preference_Parent__c = acp.Id;
        coursePreferenceQualification.Contact_Qualification__c = contactQual.Id;
        coursePreferenceQualification.Qualification_Type__c = 'English';
        coursePreferenceQualification.Contact__c = c.Id;
        coursePreferenceQualification.Result__c = 'Unsatisfactory';
        insert coursePreferenceQualification;
        Test.startTest();
        //WHEN: Full offer Outcome
        List<ACPValidationFullOfferService.ValidationResponse> resp=ACPValidationFullOfferService.FullOfferValidationCheck(new List<Id>{acp.Id});
        //THEN: Education and English Validation are failed
        Assert.areEqual(resp[0].isValid,false);
        Assert.areEqual(resp[0].resultEnglishMessage,'No Satisfactory English');
        Assert.areEqual(resp[0].resultEducationMessage,'No Education');
        Test.stopTest();
    }
    
    @isTest
    public static void validateSuccess(){
        //GIVEN: a ACP with English and Education Qualification
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        Contact_Qualification__c contactQual = [Select Id from Contact_Qualification__c LIMIT 1];
        Contact c = [Select Id from Contact LIMIT 1];
        //Satisfactory English Qualification assigned
        Course_Preference_Qualification__c coursePreferenceQualification = new Course_Preference_Qualification__c();
        coursePreferenceQualification.Type__c = 'English Test Results';
        coursePreferenceQualification.Application_Course_Preference_Parent__c = acp.Id;
        coursePreferenceQualification.Contact_Qualification__c = contactQual.Id;
        coursePreferenceQualification.Qualification_Type__c = 'English';
        coursePreferenceQualification.Contact__c = c.Id;
        coursePreferenceQualification.Result__c = 'Satisfactory';
        insert coursePreferenceQualification;
        //Education Qualification assigned
        Course_Preference_Qualification__c coursePreferenceQualification1 = new Course_Preference_Qualification__c();
        coursePreferenceQualification1.Application_Course_Preference_Parent__c = acp.Id;
        coursePreferenceQualification1.Contact_Qualification__c = contactQual.Id;
        coursePreferenceQualification1.Qualification_Type__c = 'Education';
        coursePreferenceQualification1.Contact__c = c.Id;
        coursePreferenceQualification1.Result__c = 'Satisfactory';
        insert coursePreferenceQualification1;
        Test.startTest();
        //WHEN: Full offer Outcome
        List<ACPValidationFullOfferService.ValidationResponse> resp=ACPValidationFullOfferService.FullOfferValidationCheck(new List<Id>{acp.Id});
        //THEN: Validation is successful
        Assert.areEqual(resp[0].isValid,true);
        Test.stopTest();
    }
}