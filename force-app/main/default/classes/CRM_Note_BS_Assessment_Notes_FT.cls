/**
 * @description       : Test Class for CRM_Note_BS_Assessment_Notes
 * @author            : Jitender Padda
 **/
@isTest(isParallel=true)
private class CRM_Note_BS_Assessment_Notes_FT {
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
     * @description Autopopulate Contact / Application lookups based on ACP
     **/
    @isTest
    private static void ACPLinked_Test() {
        //GIVEN: a new CRM Note
        CRM_Notes__c crmNote = AssessmentsTestDataFactory.createCRMNote('CENTRAL');
        crmNote.Application_Course_Preference__c = [SELECT Id FROM Application_Course_Preference__c LIMIT 1].Id;

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            //WHEN: CRM Note is inserted
            insert crmNote;
        }
        Test.stopTest();

        crmNote = [SELECT Id, Name, Type__c, Contact__c, Application__c FROM CRM_Notes__c WHERE Id = :crmNote.Id];

        //THEN : Name gets updated to Type API name
        Assert.areEqual(crmNote.Name, crmNote.Type__c);
        //THEN : Application is autopopulatd
        Assert.areEqual(crmNote.Application__c, [SELECT Id FROM Application__c LIMIT 1].Id);
        //THEN : Contact is autopopulatd
        Assert.areEqual(crmNote.Contact__c, [SELECT Id FROM Contact LIMIT 1].Id);
    }

    /**
     * @description Autopopulate Contact lookup based on Application
     **/
    @isTest
    private static void ApplicationLinked_Test() {
        //GIVEN: a new CRM Note
        CRM_Notes__c crmNote = AssessmentsTestDataFactory.createCRMNote('CENTRAL');
        crmNote.Application__c = [SELECT Id FROM Application__c LIMIT 1].Id;

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            //WHEN: CRM Note is inserted
            insert crmNote;
        }
        Test.stopTest();

        crmNote = [SELECT Id, Name, Type__c, Contact__c, Application__c FROM CRM_Notes__c WHERE Id = :crmNote.Id];

        //THEN : Name gets updated to Type API name
        Assert.areEqual(crmNote.Name, crmNote.Type__c);
        //THEN : Contact is autopopulatd
        Assert.areEqual(crmNote.Contact__c, [SELECT Id FROM Contact LIMIT 1].Id);
    }

    /**
     * @description Prevent updates to Notes synced with Callista
     **/
    @isTest
    private static void PreventSyncedNoteUpdate_Test() {
        String mockResponse = '{"id": "123456"}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        //GIVEN: a new CRM Note
        CRM_Notes__c crmNote = AssessmentsTestDataFactory.createCRMNote('INTPAYMENT');
        crmNote.Text__c = 'Package Deposit: $1000\n' + 'OSHC: $200\n' + 'OSHC Sponsored: Y\n' + 'Tuition Sponsored: N';
        crmNote.Contact__c = [SELECT Id FROM Contact LIMIT 1].Id;
        Test.startTest();
        insert crmNote;
        Test.stopTest();

        crmNote = [SELECT Id, Callista_Ref_Id__c FROM CRM_Notes__c WHERE Id = :crmNote.Id];

        //GIVEN : synced with Callista
        Assert.isNotNull(crmNote.Callista_Ref_Id__c);

        System.runAs(new User(Id = UserInfo.getUserId())) {
            //WHEN: CRM Note is updated
            try {
                crmNote.Text__c = 'updated text';
                update crmNote;
            } catch (Exception e) {
                //THEN : Update fails due to validation
                Assert.areEqual('Cannot update a Note synced to Callista', e.getDmlMessage(0));
            }
        }

    }

    /**
     * @description Prevent insert / update to Notes where Contact has no person Id
     **/
    @isTest
    private static void PreventNoPersonIdUpsert_Test() {
        //GIVEN: a new CRM Note where contact has no person Id
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        con.Person_ID_unique__c = null;
        update con;
        CRM_Notes__c crmNote = AssessmentsTestDataFactory.createCRMNote('CENTRAL');
        crmNote.Contact__c = con.Id;

        Test.startTest();
        //WHEN: note is inserted
        try {
            insert crmNote;
        } catch (Exception e) {
            //THEN : Update fails due to validation
            Assert.areEqual('Cannot create or update a Note without Person Id on the Contact.', e.getDmlMessage(0));
        }
        Test.stopTest();
    }
}