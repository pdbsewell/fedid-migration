/**
* @description Test class for NextNonRejectedACPController and CustomChoice classes
* @author      Sravani Naramsetti
* @date        16/01/2025
* @group       Admissions
*/
@isTest(isParallel=true)
public class NextNonRejectedACPController_Test {
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
        //Create LOV record
        List_of_Values__c lovRejected = new List_of_Values__c(Value__c = 'REJECTED'
        , Type__c='ADM_OUTCOME_STATUS'
        , System_Code__c='REJECTED');
        insert lovRejected;
        //create application course preference
        Application_Course_Preference__c coursePref = StudFirst_TestHelper.createCoursePreferences(app, applicant, courseOffering, course);
        coursePref.Preference_Number__c = '1';
        Application_Course_Preference__c coursePref1 = StudFirst_TestHelper.createCoursePreferences(app, applicant, courseOffering, course);
        coursePref1.Outcome_Status_LOV__c = lovRejected.Id;
        coursePref1.Preference_Number__c = '2';
        insert new List<Application_Course_Preference__c>{coursePref,coursePref1};
    }
    
    @isTest
    public static void noOtherACP() {
        //GIVEN: a ACP under Assessment
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        Test.startTest();
        //WHEN: Rejected and has no Other Non rejected ACP
        List<NextNonRejectedACPController.CustomOutput> resp=NextNonRejectedACPController.getnextACPChoices(new List<Id>{acp.Id});
        //THEN: Choice Set is Null
        Assert.areEqual(resp,null);
        Test.stopTest();
        
    }
    
    @isTest
    public static void oneACPExists() {
        //GIVEN: a ACP under Assessment
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        //Create LOV record OFFER
        List_of_Values__c lovOffer = new List_of_Values__c(Value__c = 'OFFER'
        , Type__c='ADM_OUTCOME_STATUS'
        , System_Code__c='OFFER');
        insert lovOffer;
        //Update application course preference
        Application_Course_Preference__c acp1 = [Select Id, Outcome_Status_LOV__c from Application_Course_Preference__c where id!=:acp.Id LIMIT 1];
        acp1.Outcome_Status_LOV__c=lovOffer.Id;
        update acp1;
        Test.startTest();
        //WHEN: Rejected and has one Non rejected ACP excluding current
        List<NextNonRejectedACPController.CustomOutput> resp=NextNonRejectedACPController.getnextACPChoices(new List<Id>{acp.Id});
        //THEN: Choice Set size is One
        Assert.areEqual(resp.size(),1);
        Test.stopTest();
        
    }
}