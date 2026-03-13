/**
 * @description JournalBatch_Test creates test data and runs the batch job JournalBatch direclty or via schedule.
 *
 * @author Stefan Scheit
 * @date 2019-12-17
 * @revision 1.0
 **/
@isTest(isParallel=false) // due to schedule evaluations
public without sharing class JournalBatch_Test { 

    @TestSetup
    public static void setupData() {
        // Proposal record type, cannot query by Schema as the name/record
        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Id proposalRecordTypeId = recordTypes.get('Major Gift').getRecordTypeId(); // Proposal record type

        // Account
        Account accnt = (Account)TestDataFactory.createSObject(new Account(Name = String.valueOf(JournalBatch_Test.class)), true); 

        // Contact
        Contact cont = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'First', lastName = String.valueOf(JournalBatch_Test.class)), true); 

         // Contact must be assigned (trigger validation on Opportunity object)
         Ucinn_ascendv2__Assignment__c assignment = (Ucinn_ascendv2__Assignment__c)TestDataFactory.createSObject(new Ucinn_ascendv2__Assignment__c(Ucinn_ascendv2__Contact__c = cont.Id, 
                                                                                                            Ucinn_ascendv2__Account__c = accnt.Id, 
                                                                                                            Ucinn_ascendv2__Assigned_Relationship_Manager_User__c = UserInfo.getUserId(),
                                                                                                            ucinn_ascendv2__Assignment_Type__c = 'Alumni Manager'), true); 

        // Oppty creation
        Opportunity oppty = (Opportunity)TestDataFactory.createSObject(new Opportunity(Name = String.valueOf(JournalBatch_Test.class), StageName = 'Identification', CloseDate = date.today().addDays(3), AccountId = accnt.Id //,ucinn_ascendv2__Contact__c = cont.Id
                                                                        , RecordTypeId = proposalRecordTypeId, Amount = 10.00, ucinn_ascendv2__External_Payment_Gateway_ID__c = 'PRAX-081821-082411849'), true);
        
        // Designation
        ucinn_ascendv2__Designation__c designation =  (ucinn_ascendv2__Designation__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation__c(Name = 'Designation Name', ucinn_ascendv2__Program_Code__c = 'GL_Acc', 
                                                              ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack', ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD', Tax_Status_Code__c = 'S1'), true);

         // Designation detail (linked to Oppty) 
        ucinn_ascendv2__Designation_Detail__c designationDetail =  (ucinn_ascendv2__Designation_Detail__c)TestDataFactory.createSObject(new ucinn_ascendv2__Designation_Detail__c(Name = '[Default Name]', ucinn_ascendv2__Opportunity__c = oppty.Id), true);

        // Payment
        ucinn_ascendv2__Payment__c payment = (ucinn_ascendv2__Payment__c)TestDataFactory.createSObject(new ucinn_ascendv2__Payment__c(Name = 'Payment Name', ucinn_ascendv2__Designation_Detail__c = designationDetail.Id, 
                                            ucinn_ascendv2__Opportunity__c = oppty.Id, Sent_to_SAP__c = false, ucinn_ascendv2__Transaction_ID__c = '100010001001000', Payment_Settled__c = true, Batch_Id__c = '123456',
                                            Payment_Settlement_Date__c = system.now(), ucinn_ascendv2__Tender_Type_for_Gifts__c = 'Visa',
                                            ucinn_ascendv2__Payment_Amount__c = 10.00), true);

         // Session
         ucinn_ascendv2__Session__c session =  (ucinn_ascendv2__Session__c)TestDataFactory.createSObject(new ucinn_ascendv2__Session__c(ucinn_ascendv2__Session_Totals_Approved__c = System.now()), true);

         // Hard/soft credit
         ucinn_ascendv2__Hard_and_Soft_Credit__c hsCredit =  (ucinn_ascendv2__Hard_and_Soft_Credit__c)TestDataFactory.createSObject(new ucinn_ascendv2__Hard_and_Soft_Credit__c(Name = 'Hard/Soft Credit',ucinn_ascendv2__Credit_Amount__c = 10.00,ucinn_ascendv2__Designation_Detail__c = designationDetail.Id,
                                                              ucinn_ascendv2__Credit_Type__c = 'Hard',ucinn_ascendv2__Source__c = 'Payment',ucinn_ascendv2__Payment__c = payment.Id,ucinn_ascendv2__Designation__c = designation.Id,
                                                              ucinn_ascendv2__Session__c = session.Id), true);

        /* Error scenarios */

        // Designation error 1 (all GL details are missing)
        /* REMOVED AS IT'S BLOCKED VIA A VALIDATION RULE IN THE SYSTEM
        ucinn_ascendv2__Designation__c designationError1 = new ucinn_ascendv2__Designation__c();
        designationError1.Name = 'Designation Name Error 1'; // all GL attributes are missing
        insert designationError1;
        ucinn_ascendv2__Hard_and_Soft_Credit__c hsDesignationError1 = new ucinn_ascendv2__Hard_and_Soft_Credit__c();
        hsDesignationError1.Name = 'Hard/Soft Credit - Designation Name Error 1';
        hsDesignationError1.ucinn_ascendv2__Credit_Amount__c = 10.00;
        hsDesignationError1.ucinn_ascendv2__Designation_Detail__c = designationDetail.Id; // required
        hsDesignationError1.ucinn_ascendv2__Credit_Type__c = 'Hard'; // required
        hsDesignationError1.ucinn_ascendv2__Source__c = 'Payment';
        hsDesignationError1.ucinn_ascendv2__Payment__c = payment.Id;
        hsDesignationError1.ucinn_ascendv2__Designation__c = designationError1.Id;
        insert hsDesignationError1;*/

        // Designation error 2 (only GL ack description is present)
        /* REMOVED AS IT'S BLOCKED VIA A VALIDATION RULE IN THE SYSTEM
        ucinn_ascendv2__Designation__c designationError2 = new ucinn_ascendv2__Designation__c();
        designationError2.Name = 'Designation Name Error 2';
        designationError2.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Desc'; // valid, but rest is missing
        insert designationError2;
        ucinn_ascendv2__Hard_and_Soft_Credit__c hsDesignationError2 = new ucinn_ascendv2__Hard_and_Soft_Credit__c();
        hsDesignationError2.Name = 'Hard/Soft Credit - Designation Name Error 2';
        hsDesignationError2.ucinn_ascendv2__Credit_Amount__c = 10.00;
        hsDesignationError2.ucinn_ascendv2__Designation_Detail__c = designationDetail.Id; // required
        hsDesignationError2.ucinn_ascendv2__Credit_Type__c = 'Hard'; // required
        hsDesignationError2.ucinn_ascendv2__Source__c = 'Payment';
        hsDesignationError2.ucinn_ascendv2__Payment__c = payment.Id;
        hsDesignationError2.ucinn_ascendv2__Designation__c = designationError2.Id;
        insert hsDesignationError2;*/
    }

    @isTest
    public static void testExecuteBatch() {
        /* GIVEN */
        /* WHEN */
        Test.startTest();
        Id batchId = Database.executeBatch(new JournalBatch(), 10);
        Test.stopTest();
        /* THEN */
        AsyncApexJob batchJob = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :batchId];
        System.assertEquals(true, batchJob!=null, 'Asynchronous Apex job was not created.');
        System.assertEquals(0, batchJob.NumberOfErrors, 'Asynchronous Apex job executed with errors');
        String likeFilter = JournalBatch.FILE_PREFIX + '%';
        List<ContentVersion> cv = [SELECT Id FROM ContentVersion WHERE PathOnClient LIKE :likeFilter LIMIT 1];
        System.assert(cv.size()==1, 'ContentVersion file was not created for the batch result.');
    }

    @isTest
    public static void testExecuteSchedule() {
        /* GIVEN */
        //Unscheduled Job if it is scheduled / currently running
        List<AsyncApexJob> asyncApexJobList = [SELECT ApexClassId,ApexClass.Name,Id,JobType,Status FROM AsyncApexJob WHERE ApexClass.Name = 'JournalBatch' AND JobType = 'ScheduledApex'];
        if(asyncApexJobList != null && !asyncApexJobList.isEmpty()) {
            for(AsyncApexJob cron :asyncApexJobList) {
                //Delete the Job in schdule during test context
                System.abortJob(cron.Id);
            }
        }
        //Unscheduled Job if it is scheduled
        List<CronTrigger> cjdList = [SELECT CronJobDetailId,Id,State FROM CronTrigger WHERE CronJobDetail.Name = 'JournalBatch'];
        if(cjdList != null && !cjdList.isEmpty()) {
            for(CronTrigger cjd :cjdList) {
                System.abortJob(cjd.Id);
            }
        }
        /* WHEN */
        Test.startTest();
        JournalBatch jb = new JournalBatch();
        // call custom schedule method which set default schedule
        String jobId = jb.schedule();
        String cronID = System.scheduleBatch(new JournalBatch(), 'JournalFile', 1);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(0, ct.TimesTriggered, 'Scheduled Apex job is not scheduled and to be run.');
        Test.stopTest();
        /* THEN */
        // nothing to evaluate
    } 
}