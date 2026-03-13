/**
 * @description Test for Batchable Class to send reminder Email to Chief Examiners.
				Class implements Database.Schedule
 * @author Inderpal Dhanoa
 * @date 2021-07-21
 * @revision 1.0
 **/
@IsTest// (isParallel=true) In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
public class AcadmIntegUnReadEmailNotifBatch_Test {
    @IsTest
    public static void testAcadmIntegUnReadEmailNotifBatch(){
        Test.startTest();

        String complaintsRecType = CommonServices.recordTypeId('Case', 'Complaint');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                Status = 'Open',
                                Incoming_Email__c = true,
                                Enquiry_Type__c = 'Student Misconduct',
                                Category_Level_1__c = 'Academic Integrity Breach',
                                Origin = 'Web - Monash Forms',
                                RecordTypeId = complaintsRecType );
        insert caseRec;
        
        AcadmIntegUnReadEmailNotifBatch acadIntegEmailRem = new AcadmIntegUnReadEmailNotifBatch();        
        String schTime = '0 0 7 * * ?';
        String jobId = System.schedule('acadIntegEmailRemSch',  schTime, acadIntegEmailRem);  
        Database.executeBatch(acadIntegEmailRem);
        
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
        System.assert(ct!=null, 'The scheduled job could not be found.');
        System.assertEquals(0, ct.TimesTriggered, 'Scheduled Apex job is not scheduled to be run.');
    }


}