/**
 * @description       : Test Class for AL_Assessment_Tap
 * @author            : Jitender Padda
 **/
@isTest(isParallel=true)
private class ALAssessentTap_FT {
    @testSetup
    static void setup() {
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
        Application__c application = [SELECT Id, Citizenship_Classification__c FROM Application__c LIMIT 1][0];

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

        //WHEN :  Assessment Tap flow is called with the Application
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('ApplicationId', application.Id);

        Flow.Interview.AL_Assessment_Tap flow = new Flow.Interview.AL_Assessment_Tap(flowInputs);

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            flow.start();
        }
        Test.stopTest();

        //THEN : Tap returns TRUE
        Boolean isTapEnabled = (Boolean) flow.getvariableValue('TapEnabled');
        Assert.areEqual(true, isTapEnabled);
    }
    
    /**
     * @description Assessment Tap test for Master of Biotechnology
     **/
    @isTest
    private static void tapForMasterOfBiotechnology_Test() {
        // GIVEN : An Application with ACP for Master of Biotechnology
        Account facultyAccount = [SELECT Id FROM Account WHERE RecordType.Name = 'Faculty' LIMIT 1][0];
        Application__c application = [SELECT Id, Citizenship_Classification__c FROM Application__c LIMIT 1][0];

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
            'M6030',
            '1'
        );
        insert acp;

        //WHEN :  Assessment Tap flow is called with the Application
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('ApplicationId', application.Id);

        Flow.Interview.AL_Assessment_Tap flow = new Flow.Interview.AL_Assessment_Tap(flowInputs);

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            flow.start();
        }
        Test.stopTest();

        //THEN : Tap returns TRUE
        Boolean isTapEnabled = (Boolean) flow.getvariableValue('TapEnabled');
        Assert.areEqual(true, isTapEnabled);
    }
}