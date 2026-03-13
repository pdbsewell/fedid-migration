/**
 * @description       : Test Class for AssessmentTapService
 * @author            : Sravani Naramsetti
 **/
@isTest(isParallel=true)
private class AssessmentTapService_Test {
    @testSetup
    static void setup() {
        Feature_Switch__c featureSwitch = AssessmentsTestDataFactory.createFeatureSwitch();
        insert featureSwitch;
        
        Account facultyAccount = AssessmentsTestDataFactory.createFacultyAccount();
        insert facultyAccount;

        Contact applicant = AssessmentsTestDataFactory.createApplicant();
        insert applicant;

        Application__c application = AssessmentsTestDataFactory.createDomesticApplication('CAID-1239090', applicant.Id);
        insert application;
    }

    /**
     * @description Assessment Tap test for Master of Social Work
     **/
    @isTest
    private static void tapForMasterOfSocialWork_Test() {
        // GIVEN : An Application with ACP for Master of Social work
        Account facultyAccount = [SELECT Id FROM Account WHERE RecordType.Name = 'Faculty' LIMIT 1][0];
        Application__c application = [SELECT Id FROM Application__c LIMIT 1][0];

        Course__c masterOfSocialWork = AssessmentsTestDataFactory.createCourse(
            facultyAccount,
            'Faculty of Medicine, Nursing and Health Sciences'
        );
        insert masterOfSocialWork;

        Application_Course_Preference__c acp = AssessmentsTestDataFactory.createACP(
            application.Id,
            masterOfSocialWork.Id,
            'AUSAID-PG',
            'CLAYTON',
            'IN',
            'M6012',
            '1'
        );
        insert acp;

        //WHEN :  AssessmenttapService is called with the Application
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('ApplicationId', application.Id);
        Boolean isTapEnabled;
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            isTapEnabled = AssessmentTapService.getTapValue(flowInputs);
        }
        Test.stopTest();

        //THEN : Tap returns TRUE
        Assert.areEqual(true, isTapEnabled);
    }
}