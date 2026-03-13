/**
 * @description Unit tests for GradsCallistaSyncService
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 *
 * IsParallel=false due to testDocQueueableSync & testRetrieveDocs (DML on ContentWorkspace but I don't know where)
 */
@IsTest(IsParallel=false)
private class GradsCallistaSyncService_Test {

    static final Integer calendar_code = 13343;
    static final String award_code1 = '1011';

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test University');
        insert testAccount;

        Contact testStudent = new Contact(
            LastName = 'TestStudent', AccountId = testAccount.Id, Person_ID_unique__c = '12345'
        );
        insert testStudent;

        Calendar__c cal = new Calendar__c(
            Description__c = '2024 (May) Ceremony',
            Type_Description__c = 'SEM 1',
            Type__c = 'GRAD1',
            Type_Alt__c = 'CLAYTON',
            Calendar_Code__c = String.valueOf(calendar_code),
            Sequence_Number__c = calendar_code,
            Start_Date__c = Date.newInstance(2024, 5, 01),
            End_Date__c = Date.newInstance(2024, 10, 31)
        );
        insert cal;

        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = testStudent.Id,
            Graduation_Calendar__c = cal.Id,
            Student_Testamur_Name__c = 'Test Student',
            Student_Personal_Email__c = 'test@example.com',
            Expected_Attendance_Fee_Unit_Amount__c = 100,
            Status__c = 'Applied',
            Staff_Comments__c = 'Test comments.'
        );
        TriggerCommon.disableTrigger('Graduation_Application__c');
        insert app;

        Graduation_Award__c award1 = new Graduation_Award__c(
            Graduation_Application__c = app.Id,
            Award_Code_1__c = award_code1,
            Award_Course_Code__c = 'A2000',
            Award_Course_Version__c = 2,
            Award_Course_Title__c = 'Bachelor of Arts',
            Award_Title_1__c = 'Bachelor of Arts',
            Award_Type__c = 'SINGLE',
            Course_Code__c = 'A2000',
            Course_Title__c = 'Bachelor of Arts',
            Course_Version_Number__c = 1,
            Integration_Id__c = app.Id + '|' + '1011',
            Is_Attending_Ceremony__c = true
        );
        Graduation_Award__c award2 = new Graduation_Award__c(
            Graduation_Application__c = app.Id,
            Award_Code_1__c = '1012',
            Award_Course_Code__c = 'A2000',
            Award_Course_Version__c = 2,
            Award_Course_Title__c = 'Bachelor of Arts',
            Award_Title_1__c = 'Bachelor of Arts',
            Award_Type__c = 'SINGLE',
            Course_Code__c = 'A2000',
            Course_Title__c = 'Bachelor of Arts',
            Course_Version_Number__c = 1,
            Integration_Id__c = app.Id + '|' + '1012',
            Is_Attending_Ceremony__c = true
        );
        TriggerCommon.disableTrigger('Graduation_Award__c');
        insert new List<Graduation_Award__c>{award1, award2};
    }

    static void testCreateReq() {
        // GIVEN - An award with all required fields
        Graduation_Award__c award = [SELECT Id FROM Graduation_Award__c WHERE Award_Code_1__c = :award_code1];
        award = GradsCallistaSyncService.retrieveAwards(new Set<Id>{award.Id})[0];

        // WHEN - Requested is created
        GradsCallistaCalloutService.AppReqBody req = GradsCallistaSyncService.createReq(award);

        // THEN - Request should be created as expected
        Assert.isNotNull(req, 'Request body should not be null');
        Assert.isNotNull(req.graduationApplication, 'Graduation application in request should not be null');
        Assert.isNotNull(req.graduationApplication.awardDetails, 'Award details in request should not be null');
        Assert.areEqual('ATTENDING', req.graduationApplication.graduandType, 'Graduand type should be ATTENDING');
        Assert.isNotNull(req.graduationApplication.graduationCalendar, 'Award in request should not be null');
        Assert.areEqual(calendar_code, req.graduationApplication.graduationCiSequenceNumber, 'Calendar code should match');
        Assert.areEqual(award_code1, req.graduationApplication.awardDetails.awardCode1, 'Award code should match');
    }

    @IsTest
    static void testProcessAwards() {
        // GIVEN - Two awards, one to process, one to skip
        Map<Id,Graduation_Award__c> awards = new Map<Id,Graduation_Award__c>([SELECT Id FROM Graduation_Award__c]);
        Graduation_Award__c writeBackAward = awards.values().iterator().next();
        writeBackAward.Callista_Writeback_Requested_Time__c = Datetime.now();
        writeBackAward.Bypass_Writeback_Trigger__c = true;
        update writeBackAward;

        GradsCallistaCalloutService_Test.MockCallistaResp mcr = new GradsCallistaCalloutService_Test.MockCallistaResp(
            200, '{"transactionNo": "4589"}'
        );
        Test.setMock(HttpCalloutMock.class, mcr);

        // WHEN - processAwards is called
        Test.startTest();
        String result = GradsCallistaSyncService.processAwards(awards.keySet());
        Test.stopTest();

        // THEN - It should complete without errors
        Assert.areEqual(1, mcr.callCount, 'Should have made one callout');
        Assert.areEqual(null, result, 'Unexpected error');
        for(Graduation_Award__c award : [
            SELECT Last_Callista_Writeback_Success_Time__c, Callista_Transaction_Number__c,
                Last_Callista_Writeback_Payload__c, Last_Callista_Writeback_Status__c, Last_Callista_Writeback_Status_Time__c
            FROM Graduation_Award__c WHERE Id IN :awards.keySet()
        ]) {
            if(award.Id == writeBackAward.Id) {
                Assert.isNotNull(award.Last_Callista_Writeback_Success_Time__c, 'Last writeback time should be updated');
                Assert.areEqual('4589', award.Callista_Transaction_Number__c, 'Transaction number should be updated');
                Assert.isNotNull(award.Last_Callista_Writeback_Payload__c, 'Payload should be saved');
                Assert.areEqual('Success', award.Last_Callista_Writeback_Status__c, 'Status should be SUCCESS');
                Assert.isNotNull(award.Last_Callista_Writeback_Status_Time__c, 'Status time should be updated');
            } else {
                Assert.isNull(award.Last_Callista_Writeback_Success_Time__c, 'Skipped award should not have writeback time updated');
                Assert.isNull(award.Callista_Transaction_Number__c, 'Skipped award should not have transaction number');
                Assert.isNull(award.Last_Callista_Writeback_Status__c, 'Skipped award should not have status updated');
                Assert.isNull(award.Last_Callista_Writeback_Status_Time__c, 'Skipped award should not have status time updated');

            }
        }
    }

    @IsTest
    static void testSyncNow() {
        // GIVEN - Awards to sync
        Graduation_Award__c award = [SELECT Id FROM Graduation_Award__c LIMIT 1];
        GradsCallistaCalloutService_Test.setMockSuccessApp('4589');

        // WHEN
        Test.startTest();
        GradsCallistaSyncService.syncNow(award.Id);
        Test.stopTest();

        // THEN - Last writeback time should be updated
        Graduation_Award__c updatedAward = [SELECT Last_Callista_Writeback_Success_Time__c FROM Graduation_Award__c WHERE Id = :award.Id];
        Assert.isNotNull(updatedAward.Last_Callista_Writeback_Success_Time__c, 'Last writeback time should be updated');
    }

    @IsTest
    static void testQueueableSync() {
        // GIVEN - Two awards ready to sync
        Map<Id,Graduation_Award__c> awards = new Map<Id,Graduation_Award__c>([SELECT Id FROM Graduation_Award__c LIMIT 2]);
        for(Graduation_Award__c award : awards.values()) {
            award.Callista_Writeback_Requested_Time__c = Datetime.now();
            award.Bypass_Writeback_Trigger__c = true;
        }
        update awards.values();

        GradsCallistaCalloutService_Test.MockCallistaResp mcr = new GradsCallistaCalloutService_Test.MockCallistaResp()
            .addResponse(200, '{"transactionNo": "4589"}')
            .addResponse(500, '{"description": "Internal Server Error"}');
        Test.setMock(HttpCalloutMock.class, mcr);

        // WHEN - One award is successful and one fails
        GradsCallistaSyncService.QueueableSync queueable = new GradsCallistaSyncService.QueueableSync(awards.keySet());
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();

        // THEN - Last writeback time should only be updated for one of the awards
        Assert.areEqual(2, mcr.callCount, 'Should have made two callouts');
        Graduation_Award__c[] updatedAwards = [
            SELECT Last_Callista_Writeback_Success_Time__c, Last_Callista_Writeback_Status__c, Last_Callista_Writeback_Status_Time__c
            FROM Graduation_Award__c WHERE Id IN :awards.keySet()
        ];
        Assert.areNotEqual(
            updatedAwards[0].Last_Callista_Writeback_Status__c,
            updatedAwards[1].Last_Callista_Writeback_Status__c,
            'Awards should have different statuses'
        );
        for(Graduation_Award__c award : updatedAwards) {
            Assert.isNotNull(award.Last_Callista_Writeback_Status_Time__c, 'Status time should be updated');
            if(award.Last_Callista_Writeback_Status__c == 'Success') {
                Assert.isNotNull(award.Last_Callista_Writeback_Success_Time__c, 'Last writeback time should be updated');
            } else if (award.Last_Callista_Writeback_Status__c == 'Failed') {
                Assert.isNull(award.Last_Callista_Writeback_Success_Time__c, 'Failed award should not have writeback time updated');
            } else {
                Assert.fail('Unexpected status: ' + award.Last_Callista_Writeback_Status__c);
            }
        }
    }

    @IsTest
    static void testRetrieveDocs() {
        // GIVEN - A document linked to an application
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDoc.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.File_Category__c = 'Graduation Portal - External User Generated';
        insert cv;

        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = conDocId;
        cdl.LinkedEntityId = app.Id;
        cdl.ShareType = 'V';
        insert cdl;

        // WHEN - Document is retrieved
        Test.startTest();
        Map<Id, ContentVersion> retrievedDocs = GradsCallistaSyncService.retrieveDocs(new Set<Id>{app.Id});
        Test.stopTest();

        // THEN - Document should be retrieved
        Assert.areEqual(1, retrievedDocs.size(), 'Should retrieve exactly one document');
        Assert.isTrue(retrievedDocs.containsKey(app.Id), 'Retrieved documents should contain the test application Id');
    }

    @IsTest
    static void testDocumentQueueableSync() {
        // GIVEN - An award with a document to sync
        Graduation_Award__c award = [SELECT Id, Graduation_Application__c FROM Graduation_Award__c LIMIT 1];

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDoc.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.File_Category__c = 'Graduation Portal - External User Generated';
        insert cv;

        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = conDocId;
        cdl.LinkedEntityId = award.Graduation_Application__c;
        cdl.ShareType = 'V';
        insert cdl;

        GradsCallistaSyncService.DocumentQueueableSync queueable = new GradsCallistaSyncService.DocumentQueueableSync(new Set<Id>{award.Id});

        // WHEN - Queueable is executed
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();

        // THEN - Document writeback pending should be false
        Graduation_Application__c updatedApp = [SELECT Document_Writeback_Pending__c FROM Graduation_Application__c WHERE Id = :award.Graduation_Application__c];
        Assert.isFalse(updatedApp.Document_Writeback_Pending__c, 'Document writeback pending should be false after queueable execution');
    }

    @IsTest
    static void testCreateSpecialReqStr() {
        // GIVEN - Test for createSpecialReqStr(Graduation_Application__c)
        Graduation_Application__c app = new Graduation_Application__c(
            Additional_Reqs_Graduand__c = 'Option1;Other',
            Additional_Reqs_Description_Graduand__c = 'Graduand description',
            Additional_Reqs_Guest__c = 'OptionA;OptionB',
            Additional_Reqs_Description_Guest__c = 'Guest description'
        );
        // WHEN - Special requirements string is created
        String result = GradsCallistaSyncService.createSpecialReqStr(app);

        // THEN - The special requirements string should be formatted correctly
        String expected = 'Graduand - Option1, Other - Graduand description\nGuest - OptionA, OptionB - Guest description';
        System.assertEquals(expected, result, 'The special requirements string for the application should be formatted correctly');
    }

}