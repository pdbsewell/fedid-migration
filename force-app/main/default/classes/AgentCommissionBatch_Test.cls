/**
 * @description AgentCommissionBatch_Test creates test data and runs the batch job AgentCommissionBatch direclty or via schedule.
 *
 * @author Vinothraja
 * @date 2021-07-30
 * @revision 1.0
 **/
@isTest(isParallel=false) // due to schedule evaluations
public without sharing class AgentCommissionBatch_Test {

    @TestSetup
    public static void setupData() {
        // Payment_Request__c record types
        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Payment_Request__c.getRecordTypeInfosByName();

        // Account
        Account a = new Account();
        a.name = 'Account '+String.valueOf(JournalBatch_Test.class);
        a.SAP_Vendor_Id__c = '83986';
        a.Callista_Org_Unit_Code__c = 'SUPER-GAD';
        insert a;
        // Create a COMMISSION - Payment Request record
        Payment_Request__c prCommission = new Payment_Request__c ();
        prCommission.Invoice_No__c = 'M-M2021072';
        prCommission.Invoice_Date__c = Date.today();
        prCommission.Account__c = a.id; 
        prCommission.GST_Inclusive__c = true;
        prCommission.RecordTypeId = recordTypes.get('Commission').getRecordTypeId();
        prCommission.Status__c = 'Approved'; 
        insert prCommission;

        // Create a CREDIT - Payment Request record
        Payment_Request__c prCredit = new Payment_Request__c ();
        prCredit.Invoice_No__c = 'M-M2021073';
        prCredit.Invoice_Date__c = Date.today();
        prCredit.Account__c = a.id; 
        prCredit.GST_Inclusive__c = false;
        prCredit.RecordTypeId = recordTypes.get('Credit').getRecordTypeId();
        prCredit.Status__c = 'Approved'; 
        insert prCredit;

        // Create Payment Request items
        List<Payment_Request_Item__c> lstPRI = new List<Payment_Request_Item__c> ();
        for (Integer i = 0; i < 10; i++) {
            Payment_Request_Item__c pri = new Payment_Request_Item__c ();
            // pri.Name
            pri.Payable_Amount__c = 100.0 + (10 * i);
            pri.Fund_Code__c = '4980032';
            pri.Cost_Centre_Code__c = 'W06016';
            if (i < 5){
                pri.Payment_Request__c = prCommission.id;
            } else {
                pri.Payment_Request__c = prCredit.id;
            }
            pri.Entity__c = 'Monash College';
            pri.Status__c = 'Verified';
            lstPRI.add(pri);
        }
        insert lstPRI;
        
    }

    @isTest
    public static void testExecuteBatch() {
        /* GIVEN */
        /* WHEN */
        Test.startTest();
        Id batchId = Database.executeBatch(new AgentCommissionBatch(), 10);
        Test.stopTest();
        /* THEN */
        AsyncApexJob batchJob = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :batchId];
        System.assertEquals(true, batchJob!=null, 'Asynchronous Apex job was not created.');
        System.assertEquals(0, batchJob.NumberOfErrors, 'Asynchronous Apex job executed with errors');
        String likeFilter = AgentCommissionBatch.FILE_PREFIX + '%';
        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE PathOnClient LIKE :likeFilter LIMIT 1];
        System.assert(null!=cv, 'ContentVersion file was not created for the batch result.');
    }

    @isTest
    public static void testExecuteSchedule() {
        /* GIVEN */
        //Unscheduled Job if it is scheduled / currently running
        List<AsyncApexJob> asyncApexJobList = [SELECT ApexClassId,ApexClass.Name,Id,JobType,Status FROM AsyncApexJob WHERE ApexClass.Name = 'AgentCommissionBatch' AND JobType = 'ScheduledApex'];
        if(asyncApexJobList != null && !asyncApexJobList.isEmpty()) {
            for(AsyncApexJob cron :asyncApexJobList) {
                //Delete the Job in schdule during test context
                System.abortJob(cron.Id);
            }
        }
        //Unscheduled Job if it is scheduled
        List<CronTrigger> cjdList = [SELECT CronJobDetailId,Id,State FROM CronTrigger WHERE CronJobDetail.Name = 'AgentCommissionBatch'];
        if(cjdList != null && !cjdList.isEmpty()) {
            for(CronTrigger cjd :cjdList) {
                System.abortJob(cjd.Id);
            }
        }
        /* WHEN */
        Test.startTest();
        AgentCommissionBatch jb = new AgentCommissionBatch();
        // call custom schedule method which set default schedule
        String jobId = jb.schedule();
        // String cronID = System.scheduleBatch(new AgentCommissionBatch(), 'JournalFile', 1);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(0, ct.TimesTriggered, 'Scheduled Apex job is not scheduled and to be run.');
        Test.stopTest();
    }
}