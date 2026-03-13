@IsTest(IsParallel=true)
public class CRMNotesService_Test {

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
     * @description Test sending person note to Callista
     */
    @IsTest
    static void testSendPersonNoteToCallista() {
        String mockResponse = '{"id": "123456"}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        //GIVEN: a new CRM Note
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
     * @description Test sending person note to Callista
     */
    @IsTest
    static void testSendACAINoteToCallista() {
        String mockResponse = '{"referenceNumber": "12345678"}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        //GIVEN: a new CRM Note
        CRM_Notes__c crmNote = AssessmentsTestDataFactory.createCRMNote('STDY-GRNT');
        crmNote.Text__c = '2025/2-Pathwaygrant-5000x2-31/01/2024-Accepted';
        crmNote.Application_Course_Preference__c = [SELECT Id FROM Application_Course_Preference__c LIMIT 1].Id;

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            //WHEN: CRM Note is inserted
            insert crmNote;
        }
        Test.stopTest();

        crmNote = [SELECT Id, Callista_Ref_Id__c FROM CRM_Notes__c WHERE Id = :crmNote.Id];

        //THEN : Note is synced to Callista & Ref Id gets populated
        Assert.areEqual('12345678', crmNote.Callista_Ref_Id__c);
    }
}