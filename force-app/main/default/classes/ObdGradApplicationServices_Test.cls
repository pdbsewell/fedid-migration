/**
 * @description Unit tests for ObdGradApplicationServices
 * @group       Grads
 * @revision    2024-09-06 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=true)
private class ObdGradApplicationServices_Test {

    private static Graduation_Award__c createAward(Id appId) {
        return new Graduation_Award__c(
            Graduation_Application__c = appId,
            Award_Code_1__c = '1012',
            Award_Course_Code__c = 'A2000',
            Award_Course_Version__c = 2,
            Award_Course_Title__c = 'Bachelor of Arts',
            Award_Title_1__c = 'Bachelor of Arts',
            Award_Type__c = 'SINGLE',
            Course_Code__c = 'A2000',
            Course_Title__c = 'Bachelor of Arts',
            Course_Version_Number__c = 1,
            Integration_Id__c = appId + '|' + '1012|' + System.currentTimeMillis(),
            Is_Attending_Ceremony__c = true
        );
    }

    @IsTest
    static void testObdGradApplicationServicesEventHandler() {
        // GIVEN - 3 Graduation Awards with different scenarios
        Contact student = new Contact(
            LastName = 'TestStudent',
            FirstName = 'John',
            Person_ID_unique__c = 'TEST001'
        );
        insert student;

        Calendar__c cal = new Calendar__c(
            Calendar_Code__c = '4567',
            Category__c = 'GRADUATION'
        );
        insert cal;

        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = student.Id,
            Status__c = 'Applied',
            Graduation_Calendar__c = cal.Id
        );
        insert app;

        Graduation_Award__c award1 = createAward(app.Id);
        award1.Callista_Writeback_Requested_Time__c = Datetime.now().addHours(-1);
        award1.Last_Callista_Writeback_Success_Time__c = null;
        award1.Writeback_Apex_Job_Id__c = null;

        Graduation_Award__c award2 = createAward(app.Id);
        award2.Callista_Writeback_Requested_Time__c = Datetime.now().addHours(-2);
        award2.Last_Callista_Writeback_Success_Time__c = Datetime.now().addHours(-1);
        award2.Writeback_Apex_Job_Id__c = null;

        Graduation_Award__c award3 = createAward(app.Id);
        award3.Callista_Writeback_Requested_Time__c = Datetime.now().addHours(-1);
        award3.Last_Callista_Writeback_Success_Time__c = null;
        award3.Writeback_Apex_Job_Id__c = 'SomeJobId';

        Graduation_Award__c[] awards = new List<Graduation_Award__c>{award1, award2, award3};

        TriggerCommon.disableTrigger('Graduation_Award__c');
        insert awards;

        // WHEN - Outbound Grad Application events are published
        Test.startTest();
        EventBus.publish(new List<Outbound_Grad_Application__e>{
            new Outbound_Grad_Application__e(Award_Id__c = award1.Id),
            new Outbound_Grad_Application__e(Award_Id__c = award2.Id),
            new Outbound_Grad_Application__e(Award_Id__c = award3.Id)
        });
        Test.stopTest();

        // THEN - Verify the results
        List<Graduation_Award__c> updatedAwards = [
            SELECT Writeback_Apex_Job_Id__c FROM Graduation_Award__c WHERE Id IN :awards
        ];

        // Verify that only award1 was updated
        Assert.areEqual(3, updatedAwards.size(), 'Expected 3 awards to be queried');

        for (Graduation_Award__c award : updatedAwards) {
            if (award.Id == award1.Id) {
                Assert.isNotNull(award.Writeback_Apex_Job_Id__c, 'Expected award1 to have a Writeback_Apex_Job_Id__c');
            } else if (award.Id == award2.Id) {
                Assert.isNull(award.Writeback_Apex_Job_Id__c, 'Expected award2 to not have a Writeback_Apex_Job_Id__c');
            } else if (award.Id == award3.Id) {
                Assert.areEqual('SomeJobId', award.Writeback_Apex_Job_Id__c, 'Expected award3 to retain its original Writeback_Apex_Job_Id__c');
            }
        }

        // Verify that a queueable job was enqueued
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = 'GradsCallistaSyncService'];
        Assert.areEqual(1, jobs.size(), 'Expected one GradsCallistaSyncService job to be enqueued');
    }
}