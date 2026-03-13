/**
 * @description Test class for GradsCallistaSyncBatch
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=false) // Can't use System.schedule in parallel tests
private class GradsCallistaSyncBatch_Test {

    @TestSetup
    static void makeData(){
        // Create test Graduation Awards that should be processed

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
            Calendar_Code__c = String.valueOf(13343),
            Sequence_Number__c = 13343,
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
            Status__c = 'Applied'
        );
        TriggerCommon.disableTrigger('Graduation_Application__c');
        insert app;

        List<Graduation_Award__c> testAwards = new List<Graduation_Award__c>();
        for (Integer i = 0; i < 10; i++) {
            Graduation_Award__c award = new Graduation_Award__c(
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
                Integration_Id__c = app.Id + '|' + '1012|' + i,
                Is_Attending_Ceremony__c = true
            );
            testAwards.add(award);
        }

        TriggerCommon.disableTrigger('Graduation_Award__c');
        insert testAwards;
    }

    @IsTest
    static void testRetries() {
        // GIVEN - A list of awards where some should get processed and some should not
        Map<Id,Graduation_Award__c> awardsToProcess = new Map<Id,Graduation_Award__c>([
            SELECT Id FROM Graduation_Award__c LIMIT 6
        ]);
        Map<Id,Graduation_Award__c> awardsNotProcessed = new Map<Id,Graduation_Award__c>([
            SELECT Id FROM Graduation_Award__c WHERE Id NOT IN :awardsToProcess.keySet() LIMIT 4
        ]);

        // Set up the awards to process based on number of retries and age
        for (Graduation_Award__c award : awardsToProcess.values()) {
            award.Callista_Writeback_Requested_Time__c = Datetime.now().addMinutes(-3);
        }
        Graduation_Award__c[] toProcessList = awardsToProcess.values();
        toProcessList[0].Writeback_Retry_Attempt__c = 1;
        toProcessList[0].Callista_Writeback_Requested_Time__c = Datetime.now().addMinutes(-121);
        toProcessList[1].Writeback_Retry_Attempt__c = 2;
        toProcessList[1].Callista_Writeback_Requested_Time__c = Datetime.now().addMinutes(-241);

        // Set up the awards not to process based on number of retries and age
        for (Graduation_Award__c award : awardsNotProcessed.values()) {
            award.Writeback_Retry_Attempt__c = 1;
            award.Callista_Writeback_Requested_Time__c = Datetime.now().addMinutes(-3);
        }
        Graduation_Award__c[] notProcessedList = awardsNotProcessed.values();
        notProcessedList[0].Writeback_Retry_Attempt__c = 2;
        notProcessedList[0].Callista_Writeback_Requested_Time__c = Datetime.now().addMinutes(-239);
        notProcessedList[1].Writeback_Retry_Attempt__c = 3;
        notProcessedList[1].Callista_Writeback_Requested_Time__c = Datetime.now().addHours(-7);
        notProcessedList[2].Writeback_Retry_Attempt__c = 7;
        notProcessedList[2].Callista_Writeback_Requested_Time__c = Datetime.now().addDays(-5);

        Graduation_Award__c[] allAwards = new List<Graduation_Award__c>(awardsToProcess.values());
        allAwards.addAll(awardsNotProcessed.values());

        TriggerCommon.disableTrigger('Graduation_Award__c');
        update allAwards;

        // WHEN - Batch is executed and Callista returns success
        GradsCallistaCalloutService_Test.MockCallistaResp mcr = new GradsCallistaCalloutService_Test.MockCallistaResp(
            200, '{"transactionNo": "4589"}'
        );
        Test.setMock(HttpCalloutMock.class, mcr);
        Test.startTest();
        Database.executeBatch(new GradsCallistaSyncBatch());
        Test.stopTest();

        // THEN - expected number of callouts should have happened and awards processed accordingly
        Assert.areEqual(awardsToProcess.size(), mcr.callCount);
        Graduation_Award__c[] results = [
            SELECT Last_Callista_Writeback_Success_Time__c, Writeback_Requested_Age_Minutes__c, Writeback_Retry_Attempt__c
            FROM Graduation_Award__c
        ];
        for(Graduation_Award__c award : results) {
            if(awardsToProcess.containsKey(award.Id)) {
                Assert.isNotNull(award.Last_Callista_Writeback_Success_Time__c, 'Award should have been processed');
                Assert.isFalse(award.Writeback_Retry_Attempt__c > 0, 'Retry attempt should have been reset');
            } else {
                Assert.isNull(award.Last_Callista_Writeback_Success_Time__c, 'Award should not have been processed');
            }
        }
    }

    @IsTest
    static void testWithSuppliedIds() {
        // GIVEN - A list of awards to process
        Id[] suppliedIds = new Id[0];
        for (Graduation_Award__c award : [SELECT Id FROM Graduation_Award__c LIMIT 5]) {
            suppliedIds.add(award.Id);
        }

        // WHEN - Batch is executed
        GradsCallistaCalloutService_Test.MockCallistaResp mcr = new GradsCallistaCalloutService_Test.MockCallistaResp(
            200, '{"transactionNo": "4589"}'
        );
        Test.setMock(HttpCalloutMock.class, mcr);
        Test.startTest();
        GradsCallistaSyncBatch batch = new GradsCallistaSyncBatch(suppliedIds);
        Database.executeBatch(batch);
        Test.stopTest();

        // THEN - awards should have been processed
        Assert.areEqual(5, mcr.callCount, 'Unexpected number of callouts');
        Graduation_Award__c[] processedAwards = [
            SELECT Id FROM Graduation_Award__c WHERE Last_Callista_Writeback_Success_Time__c != NULL
        ];
        Assert.areEqual(5, processedAwards.size(), 'Unexpected number of awards processed');
    }

    @IsTest
    static void testScheduledExecution() {
        // GIVEN - Mock the sync config
        GradsUtils.SyncConfig mockConfig = new GradsUtils.SyncConfig();
        mockConfig.scheduledBatchEnabled = true;

        // WHEN - The scheduled job is executed
        Test.startTest();
        GradsCallistaSyncBatch scheduledBatch = new GradsCallistaSyncBatch();
        String jobId = System.schedule('Test Scheduled Job', '0 0 0 * * ?', scheduledBatch);
        Test.stopTest();

        // THEN - The job should be scheduled correctly
        CronTrigger[] scheduledJobs = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(1, scheduledJobs.size(), 'Job was not scheduled correctly');
        Assert.areEqual('0 0 0 * * ?', scheduledJobs[0].CronExpression, 'Incorrect cron expression for scheduled job');
    }

    @IsTest
    static void testCalculateBackoffMinutes() {
        Assert.areEqual(2, GradsCallistaSyncBatch.calculateBackoffMinutes(0));
        Assert.areEqual(120, GradsCallistaSyncBatch.calculateBackoffMinutes(1));
        Assert.areEqual(240, GradsCallistaSyncBatch.calculateBackoffMinutes(2));
        Assert.areEqual(480, GradsCallistaSyncBatch.calculateBackoffMinutes(3));
        Assert.areEqual(2147483647, GradsCallistaSyncBatch.calculateBackoffMinutes(7));
    }
}