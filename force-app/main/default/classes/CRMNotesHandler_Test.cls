@IsTest(isParallel=true)
public class CRMNotesHandler_Test {
    @testSetup
    static void setup() {
        Account facultyAccount = AssessmentsTestDataFactory.createFacultyAccount();
        insert facultyAccount;

        Contact applicant = AssessmentsTestDataFactory.createApplicant();
        insert applicant;

        Application__c application = AssessmentsTestDataFactory.createDomesticApplication('CAID-1239090', applicant.Id);
        insert application;

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
        acp.Applicant__c = applicant.Id;
        // callista fields
        acp.Admission_Application_Number__c = 1;
        acp.Application_Sequence_Number__c = 2;
        insert acp;
    }

    /**
     * @description Test pushing person note to Callista - INSERT
     */
    @IsTest
    static void testPushNoteToCallista_insert() {
        String mockResponse = '{"id": "123456"}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        //GIVEN: a new CRM Note (specific type eg. - INTPAYMENT)
        CRM_Notes__c crmNote = AssessmentsTestDataFactory.createCRMNote('INTPAYMENT');
        crmNote.Text__c = 'Package Deposit: $1000\n' + 'OSHC: $200\n' + 'OSHC Sponsored: Y\n' + 'Tuition Sponsored: N';
        crmNote.Application_Course_Preference__c = [SELECT Id FROM Application_Course_Preference__c LIMIT 1].Id;

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            //WHEN: CRM Note is inserted
            insert crmNote;
        }
        Test.stopTest();

        crmNote = [SELECT Id, Callista_Ref_Id__c FROM CRM_Notes__c WHERE Id = :crmNote.Id];

        //THEN : Note is synced to Callista & Ref Id gets populated
        Assert.areEqual('123456', crmNote.Callista_Ref_Id__c);
    }

    /**
     * @description Test pushing person note to Callista - UPDATE
     */
    @IsTest
    static void testPushNoteToCallista_update() {
        String mockResponse = '{"id": "123456"}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        //GIVEN: a new CRM Note (specific type eg. - INTPAYMENT)
        CRM_Notes__c crmNote = AssessmentsTestDataFactory.createCRMNote('INTPAYMENT');
        crmNote.Text__c = 'Package Deposit: $1000\n' + 'OSHC: $200\n' + 'OSHC Sponsored: Y\n' + 'Tuition Sponsored: N';
        crmNote.Application_Course_Preference__c = [SELECT Id FROM Application_Course_Preference__c LIMIT 1].Id;
        
        //GIVEN: failed sync with Callista on insert
        TriggerCommon.disableTrigger('CRM_Notes__c');
        insert crmNote;
        TriggerCommon.enableTrigger('CRM_Notes__c');

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            //WHEN: a failed CRM Note is updated
            update crmNote;
        }
        Test.stopTest();

        crmNote = [SELECT Id, Callista_Ref_Id__c FROM CRM_Notes__c WHERE Id = :crmNote.Id];

        //THEN : Note is synced to Callista & Ref Id gets populated
        Assert.areEqual('123456', crmNote.Callista_Ref_Id__c);
    }
}