/**
 * @author          inderpal.dhanoa@monash.edu
 * @description		MCT-414 - Test Class to Handle autoclosure of "JRG" case records
 * @date            Jul.2024
 * @group			MC
 * Revision
 * 1.1   11.07.2024   Idhanoa     Enhancement to auto-close JRG Campaign's cases and OCR's (MCT-414)
*/
@isTest//(IsParallel=true) :  In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
public class AutoCloseJRGCampaignRecords_Test {
    @testSetup
    static void setup() {
        Date yesterdayDate;
        Date todayDate = Date.today();
        yesterdayDate = todayDate.addDays(-1);
        // A Contact record is created
        Contact con = (Contact)TestDataFactory.createSObject(new Contact(Salutation = 'Mr',FirstName = 'First',LastName = 'Last',MobilePhone = '111-111-1111',Email = 'test@test.com'), true);

        // Mute the Validation Request to create a campaign in the past
        Bypass_Mute_Request__c validationMute = new Bypass_Mute_Request__c();
        validationMute.SetupOwnerId = UserInfo.getUserId();
        validationMute.Bypass_All_Validation_Rules__c = true;
        insert validationMute;

        // GIVEN: A Campaign record is created
        Campaign camp = (Campaign)TestDataFactory.createSObject(new Campaign( Name = 'JRG Campaign Test', EndDate = yesterdayDate, Type ='JRG',
                                    RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Advisory').getRecordTypeId()), true);

        // A Case record is created
        TestDataFactory.createSObject(new Case(ContactId = con.Id, Status = 'Open',
                                    RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), Campaign__c = camp.Id), true);

        //  An OCR record is created
        TestDataFactory.createSObject(new Outbound_Call_Result__c(Contact__c = con.Id, Campaign__c = camp.Id, 
                                    Call_Status__c = 'Open', RecordTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId()), true);
    }

    /**
     * @description Test method to close Enquiry
     */
    @IsTest
    static void autoCloseJRGCampaignRecordsExecuteTest() {
        //Run as Admin, only admins will run the AutoScheduling
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];

        System.runAs(adminUser) {
            // GIVEN: Campaign should be open
            Test.startTest();
            // WHEN : The Batch is executed
            Database.executeBatch(new AutoCloseJRGCampaignRecords());
            Test.stopTest();
            // THEN : The Enq is updated
            Case updEnq = [SELECT Id, Status FROM Case WHERE Campaign__r.Name = 'JRG Campaign Test'];
            Assert.areEqual(updEnq.Status, 'Solved', 'Case updated failure');
        }
    }

    /**
     * @author                      Inderpal Dhanoa
     * @created                     2024-07-17
     * @description                 Test for checking the Schedule with CRM
    */
    @isTest
    public static void testExecuteSchedule() {

        //Run as Admin, only admins will run the AutoScheduling
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];

        System.runAs(adminUser) {
            /* GIVEN */
            // The campaign exists
            /* WHEN */
            // the Scheduled batch Job is executed 
            // call custom schedule method which set default schedule
            Test.startTest();
            AutoCloseJRGCampaignRecords jb = new AutoCloseJRGCampaignRecords();
            Test.stopTest();

            //THEN: Check the Scheule Job
            String jobId = jb.schedule();
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
            Assert.areEqual(0, ct.TimesTriggered, 'Scheduled Apex job is not scheduled and to be run.');
        } 
    }
}