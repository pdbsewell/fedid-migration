/**
* @description Test class for EncumbranceOutcomeController
* @author      Sravani Naramsetti
* @date        05/02/2025
* @group       Admissions
*/
@isTest(isParallel=true)
public class EncumbranceOutcomeController_Test {
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
        insert new List<Application_Course_Preference__c>{coursePref};
    }
    
    @isTest
    public static void revokedEncumbranceExists() {
        Contact ct = [Select Id from Contact LIMIT 1];
        //GIVEN: a ACP under Assessment
        Encumbrance__c enc = StudFirst_TestHelper.createEncumbranceAdmin(ct.Id);
        enc.eff_type__c = 'RVK_SRVC';
        enc.IsActive__c = true;
        insert enc;
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        Test.startTest();
        //WHEN: 'Offer/Conditional Offer' made and has Active 'RVK_SRVC' encumbrance on Contact
        List<EncumbranceOutcomeController.ValidationResponse> resp=EncumbranceOutcomeController.encumbrancesOutcomeCheck(new List<Id>{acp.Id});
        //THEN: hasEncumbrance is true
        Assert.areEqual(resp[0].hasEncumbrance,true);
        Test.stopTest();
    }
    
    @isTest
    public static void withdrawnEncumbranceExists() {
        Contact ct = [Select Id from Contact LIMIT 1];
        //GIVEN: a ACP under Assessment
        Encumbrance__c enc = StudFirst_TestHelper.createEncumbranceAdmin(ct.Id);
        enc.eff_type__c = 'SUS_SRVC';
        enc.IsActive__c = true;
        insert enc;
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        Test.startTest();
        //WHEN: 'Offer/Conditional Offer' made and has Active 'SUS_SRVC' encumbrance on Contact
        List<EncumbranceOutcomeController.ValidationResponse> resp=EncumbranceOutcomeController.encumbrancesOutcomeCheck(new List<Id>{acp.Id});
        //THEN: isBlocked is true
        Assert.areEqual(resp[0].isBlocked,true);
        Test.stopTest();
    }
    
    @isTest
    public static void excCourseExists() {
        Contact ct = [Select Id from Contact LIMIT 1];
        //GIVEN: a ACP under Assessment
        Encumbrance__c enc = StudFirst_TestHelper.createEncumbranceAdmin(ct.Id);
        enc.eff_type__c = 'EXC_COURSE';
        enc.IsActive__c = true;
        enc.enc_course_code__c = 'M00001';
        insert enc;
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        Test.startTest();
        //WHEN: 'Offer/Conditional Offer' made and has Active 'EXC_COURSE' encumbrance on Contact
        List<EncumbranceOutcomeController.ValidationResponse> resp=EncumbranceOutcomeController.encumbrancesOutcomeCheck(new List<Id>{acp.Id});
        //THEN: isBlocked is false
        Assert.areEqual(resp[0].isBlocked,false);
        Test.stopTest();
    }
    
    @isTest
    public static void excCourseGroupExists() {
        Contact ct = [Select Id from Contact LIMIT 1];
        //GIVEN: a ACP under Assessment
        course_group__c cg = new course_group__c (Course_Group__c='ABCD_1234',Type__c='Combined',Responsible_Org_Unit_Code__c='Fish',Is_Active__c=true);
        insert cg;
        Encumbrance__c enc = StudFirst_TestHelper.createEncumbranceAdmin(ct.Id);
        enc.eff_type__c = 'EXC_CRS_GP';
        enc.IsActive__c = true;
        enc.enc_course_code__c = 'M00001';
        enc.enc_course_group__c = cg.Id;
        insert enc;
        
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        Test.startTest();
        //WHEN: 'Offer/Conditional Offer' made and has Active 'EXC_CRS_GP' encumbrance on Contact
        List<EncumbranceOutcomeController.ValidationResponse> resp=EncumbranceOutcomeController.encumbrancesOutcomeCheck(new List<Id>{acp.Id});
        //THEN: isBlocked is false
        Assert.areEqual(resp[0].isBlocked,false);
        Test.stopTest();
    }
    
    @isTest
    public static void revokedEncumbranceAndCourseCodeExists() {
        Contact ct = [Select Id from Contact LIMIT 1];
        //GIVEN: a ACP under Assessment
        Encumbrance__c enc = StudFirst_TestHelper.createEncumbranceAdmin(ct.Id);
        enc.eff_type__c = 'RVK_SRVC';
        enc.IsActive__c = true;
        
        Encumbrance__c enc1 = StudFirst_TestHelper.createEncumbranceAdmin(ct.Id);
        enc1.eff_type__c = 'EXC_COURSE';
        enc1.IsActive__c = true;
        enc1.enc_course_code__c = 'M00001';
        
        Encumbrance__c enc2 = StudFirst_TestHelper.createEncumbranceAdmin(ct.Id);
        enc2.eff_type__c = 'RVK_SRVC';
        enc2.IsActive__c = true;
        insert new List<Encumbrance__c>{enc,enc1,enc2};
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        Test.startTest();
        //WHEN: 'Offer/Conditional Offer' made and has Active 'RVK_SRVC' and 'EXC_COURSE' encumbrance on Contact
        List<EncumbranceOutcomeController.ValidationResponse> resp=EncumbranceOutcomeController.encumbrancesOutcomeCheck(new List<Id>{acp.Id});
        //THEN: hasEncumbrance is true and isBlocked is true
        Assert.areEqual(resp[0].hasEncumbrance,true);
        Assert.areEqual(resp[0].isBlocked,true);
        Test.stopTest();
    }
}