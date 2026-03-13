/**
 * @description Batchable Class to generate a file (ContentVersion) as Payment Request file to be sent to SAP.
				Class implements Database.Stateful to retain the AgentCommission File and paymentRequestIds instance variables between batches of the execute method.
				Class implements Database.Schedule
 * @author Vinothraja
 * @date 2021-07-26
 * @revision 1.0
 **/
public without sharing class AgentCommissionBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    public static final String FILE_PREFIX = '400' + '347' + 'AGENT' + '_'; 		// file prefix used for outbound file to SAP (400 = interface type, 371 client number)
    public static final String FILE_SUFFIX = '.txt'; 							// end .txt to SAP
    public static final Integer MAX_RECORDS = 500; 								// due to Apex CPU limit of Ascend trigger logic on 'ucinn_ascendv2__Payment__c' object
    public static final String DEFAULT_SCHEDULE = '0 05 21 * * ?'; 				// at 21:05 every day
    private static final Id INTEGRATION_USER  = [SELECT Id FROM User WHERE Username LIKE 'mix.api.event@monash.edu%' LIMIT 1].Id; // MiX user for LIKE SOQL to read the outbound journal event to retrieve the file (has to be shared)
    private AgentCommissionFile agentCommFile = new AgentCommissionFile();							// journal file contain result records
    private Set<Id> paymentRequestIds = new Set<Id>(); 								// payment request records to be marked as part of journal

    /**
     * Method to initialise query locator
     * @param  bc as BatchableContext
     * @return    QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // retrieve all (credit card) payments a journal should be created for
        return Database.getQueryLocator(
                   // payment request header fields
                   [SELECT id, Invoice_No__c, Invoice_Date__c, SAP_Vendor_Id__c, Calculated_Payable_Amount__c, Agent_Code__c, GL_Code__c, RecordType.Name,
                           // payment request line item fields
                           (SELECT id, Name, Payable_Amount__c, Fund_Code__c, Cost_Centre_Code__c, Tax_Code__c
                            FROM Payment_Request_Items__r
                            WHERE Status__c = 'Verified')
                    FROM Payment_Request__c
                    // checking whether the Payment Requests are Ready for SAP submission
                    WHERE Status__c = 'Approved'
                    LIMIT :MAX_RECORDS]
               );
    }
    /**
     * Method to process records retrieved from query.
     * @param  scope as List<sObject>
     * @return    QueryLocator
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {

        System.debug(LoggingLevel.FINEST, 'Records to be processed: ' + scope);
        List<Payment_Request__c> lstPaymentRecords = scope;

        // Agent Commission file record init
        AgentCommissionFile.Record record = null;
        // Exception object(s)
        List<Exception_Log__c> exLogRecordList = new List<Exception_Log__c>();
        Exception_Log__c exLogRecord = null;

        for(Payment_Request__c pr : lstPaymentRecords) {
            try {
                if (null == pr.Payment_Request_Items__r || pr.Payment_Request_Items__r.isEmpty()) {
                    throw new AgentCommissionBatchException('The Payment Request items for ['+pr.id+'] is empty and not valid for processing as part of the SAP Agent Commission file.');
                }

                record = new AgentCommissionFile.Record ();
                AgentCommissionFile.Header header = new AgentCommissionFile.Header();

                //SH03 Record Type
                if (null != pr.RecordType.Name) {
                    if (pr.RecordType.Name == 'Commission') {
                        header.sh03 = 'KC';
                    } else {
                        header.sh03 = 'KD';
                    }
                }
                //SH07 Invoice No
                if (null != pr.Invoice_No__c && String.isNotBlank(pr.Invoice_No__c)) {
                    header.sh07 = pr.Invoice_No__c;
                } else {
                    throw new AgentCommissionBatchException('The Invoice No of Payment Request ['+pr.id+'] is not valid for processing the field SH07 (Invoice No) as part of the SAP Agent Commission file.');
                }
                //SH09 Invoice Date
                if (null != pr.Invoice_Date__c) {
                    // This is the issue date of the invoice in ddMMyyyy format
                    header.sh09 = String.valueOf(pr.Invoice_Date__c.day()).leftpad(2,'0') + String.valueOf(pr.Invoice_Date__c.month()).leftpad(2,'0') + pr.Invoice_Date__c.year();
                } else {
                    throw new AgentCommissionBatchException('The Invoice Date of Payment Request ['+pr.id+'] is not valid for processing the field SH09 (Invoice Date) as part of the SAP Agent Commission file.');
                }
                //SH14 SAP Vendor Id
                if (null != pr.SAP_Vendor_Id__c && String.isNotBlank(pr.SAP_Vendor_Id__c)) {
                    header.sh14 = pr.SAP_Vendor_Id__c;
                } else {
                    throw new AgentCommissionBatchException('The SAP Vendor Id of Payment Request ['+pr.id+'] is not valid for processing the field SH14 (SAP Vendor Id) as part of the SAP Agent Commission file.');
                }                
                //SH15 Payable Amount
                if (null != pr.Calculated_Payable_Amount__c || pr.Calculated_Payable_Amount__c == 0) {
                    header.sh15 = String.valueOf(pr.Calculated_Payable_Amount__c.setScale(2));
                } else {
                    throw new AgentCommissionBatchException('The Payable Amount of Payment Request ['+pr.id+'] is not valid for processing the field SH15 (Payable Amount) as part of the SAP Agent Commission file.');
                }    
                //SH16 Concatenate Invoice No & Agent Code
                if ((null != pr.Invoice_No__c && String.isNotBlank(pr.Invoice_No__c))
                    && (null != pr.Agent_Code__c && String.isNotBlank(pr.Agent_Code__c))) {
                    header.sh16 = '*' + pr.Invoice_No__c + ' ' + pr.Agent_Code__c;
                } else {
                    throw new AgentCommissionBatchException('The Invoice No / Agent Code of Payment Request ['+pr.id+'] is not valid for processing the field SH16 (Invoice No & Agent Code concatenation) as part of the SAP Agent Commission file.');
                }                  
                record.addHeader(header);



                for (Payment_Request_Item__c pri : pr.Payment_Request_Items__r) {
                    AgentCommissionFile.LineItem lineitem = new AgentCommissionFile.LineItem();
                    // SL02 SL03 Payable Amount
                    if (null != pri.Payable_Amount__c) {
                        if (pr.RecordType.Name == 'Credit') {
                            lineitem.sl02 = '';
                            lineitem.sl03 = String.valueOf(pri.Payable_Amount__c.setScale(2));
                        } else {
                            lineitem.sl02 = String.valueOf(pri.Payable_Amount__c.setScale(2));
                            lineitem.sl03 = '';
                        }
                    } else {
                        throw new AgentCommissionBatchException('The Payable amount of Payment Request item ['+pri.id+'] is not valid for processing the field SL02/SL03 (Payable Amount) as part of the SAP Agent Commission file.');
                    }
                    // SL04 Fund Code
                    if (null != pri.Fund_Code__c && String.isNotBlank(pri.Fund_Code__c)) {
                        lineitem.sl04 = pri.Fund_Code__c;
                    } else {
                        throw new AgentCommissionBatchException('The Fund Code of Payment Request item ['+pri.id+'] is not valid for processing the field SL04 (Fund Code) as part of the SAP Agent Commission file.');
                    }
                    // SL05 Cost Centre Code
                    if (null != pri.Cost_Centre_Code__c && String.isNotBlank(pri.Cost_Centre_Code__c)) {
                        lineitem.sl05 = pri.Cost_Centre_Code__c;
                    } else {
                        throw new AgentCommissionBatchException('The Cost Centre Code of Payment Request item ['+pri.id+'] is not valid for processing the field SL05 (Cost Centre Code) as part of the SAP Agent Commission file.');
                    }
                    // SL06 GL Code
                    if (null != pr.GL_Code__c && String.isNotBlank(pr.GL_Code__c)) {
                        lineitem.sl06 = pr.GL_Code__c;
                    } else {
                        throw new AgentCommissionBatchException('The GL Code of Payment Request item ['+pri.id+'] is not valid for processing the field SL06 (GL Code) as part of the SAP Agent Commission file.');
                    }
                    // SL07 Concatenation of Invoice No, Agent Code & Payment Request Item Name
                    if ((null != pr.Invoice_No__c && String.isNotBlank(pr.Invoice_No__c))
                            && (null != pr.Agent_Code__c && String.isNotBlank(pr.Agent_Code__c))
                            && (null != pri.Name && String.isNotBlank(pri.Name))) {
                        lineitem.sl07 = pr.Invoice_No__c + ' ' + pr.Agent_Code__c + ' ' + pri.Name;
                    } else {
                        throw new AgentCommissionBatchException('The Invoice no / Agent Code of [' + pr.id + '] or Name of the Payment Request item ['+pri.id+'] is not valid for processing the field SL07 (Concatenation of Invoice No, Agent Code & Payment Request Item Name) as part of the SAP Agent Commission file.');
                    }
                    // SL11 Tax Code
                    if (null != pri.Tax_Code__c && String.isNotBlank(pri.Tax_Code__c)) {
                        lineitem.sl11 = pri.Tax_Code__c;
                    } else {
                        throw new AgentCommissionBatchException('The Tax Code of Payment Request item ['+pri.id+'] is not valid for processing the field SL11 (Tax Code) as part of the SAP Agent Commission file.');
                    }
                    record.addLineItem(lineitem);
                }
                //Add the record to the Agent Commission file
                agentCommFile.addRecord(record);
                // Mark record as extracted / journalled by payment Id
                paymentRequestIds.add(pr.Id);
            } catch (Exception exc) {
                System.debug(LoggingLevel.Error, 'Error while processing item ['+pr.id+'] with exception: '+exc);
                // log exception (and add to list to be captured (eventually via insert))
                exLogRecord = ExLog.writeExlog('Field not present', 'AgentCommissionBatch', 'execute', String.valueOf(pr.Id), exc);
                exLogRecordList.add(exLogRecord);
            }
        }
        // insert all exception log records
        try {
            Database.insert(exLogRecordList, false);
        } catch (Exception exc) {
            // ignore as it impacts exception logging only
            System.debug(LoggingLevel.ERROR, 'Exception occurred when attempting to store Exception_Log__c records with error details.');
        }
    }
    /**
     * Method to finish processing
     * @param  bc as BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
        // generate file (as ContentVersion)
        String strFileContent = agentCommFile.toStringFixedLength();
        //System.debug(LoggingLevel.FINEST, 'File content (fixed length): ' +strFileContent);
        if (String.isBlank(strFileContent)) {
            return; // file does not need to be written
        }
        // create a ContentVersion (400 = interface type, 370 client number)
        Datetime today = Datetime.now();
        String strFilename = FILE_PREFIX + today.format('yyyyMMddHHmmss') + FILE_SUFFIX;
        ContentVersion file = new ContentVersion();
        file.VersionData = Blob.valueOf(strFileContent);
        file.Title = strFilename;
        file.Description = 'SAP Journal File ' + today.format('yyyyMMddHHmmss');
        file.PathOnClient = strFilename;
        try {
            // insert ContentVersion (068...)
            insert file;
            System.debug(LoggingLevel.DEBUG, 'DocumentVersionId ['+file.Id+'] created');

            // set owner to integration user, so it will have access (instead of sharing)
            if (null != INTEGRATION_USER) {
                // cannot set owner to different user (than context user), share with integration user instead
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id].ContentDocumentId; // retrieve automatically created ContentDocument (069...)
                cdl.LinkedEntityId = INTEGRATION_USER;
                cdl.ShareType = 'V';
                insert cdl;
            }

            // update paymentRequestIds as Submitted to SAP to have them not queried (and processed) again
            List<Payment_Request__c> submittedPRs = new List<Payment_Request__c>();
            for (Payment_Request__c pr : [SELECT Id, status__c
                                                 FROM Payment_Request__c
                                                 WHERE Id in :paymentRequestIds]) {
                pr.status__c = 'Submitted to SAP';
                pr.Submission_Date__c = Date.today();
                submittedPRs.add(pr);
            }
            Database.update(submittedPRs);

            // create outbound platform event (for integration layer)
            Outbound_Agent_Commission__e outEvent = new Outbound_Agent_Commission__e();
            outEvent.FileUrl__c = '/services/data/v51.0/sobjects/ContentVersion/'+file.Id;
            //System.debug(LoggingLevel.FINEST, 'File URL : ' + outEvent.FileUrl__c );
            Eventbus.publish(outEvent);
        } catch(DMLException e) {
            System.debug(LoggingLevel.ERROR, e);
            Exception_Log__c exLogRecord = ExLog.writeExlog('File generation', 'AgentCommissionBatch', 'execute', null, e);
            try {
                Database.insert(exLogRecord);
            } catch (Exception exc) {
                // simply log as it's about logging the error into the exception object
                System.debug(LoggingLevel.ERROR, exc);
            } 
        }
        // TODO: delete old content version
    }

    /**
     * Method implements the Schedulable interface
     * @param  sc as SchedulabeContext
     */
    public void execute(SchedulableContext sc) {
        AgentCommissionBatch myAgentCommissionBatch = new AgentCommissionBatch();
        Database.executeBatch(myAgentCommissionBatch);
    }

    /**
     * Method to schedule the AgentCommissionBatch with a default cron timing (at 2:00 am)
     */
    public String schedule() {
        String schedule = DEFAULT_SCHEDULE;
        return this.schedule(schedule);
    }

    /**
    * Method to schedule the AgentCommissionBatch with a set cron timing
    * @param schedule The schedule as cron String
    */
    public String schedule(String schedule) {
        AgentCommissionBatch myBatch = new AgentCommissionBatch();
        String scheduleName = String.valueOf(AgentCommissionBatch.class);
        // assign unique name when running in test context as it cannot have the same name of an already scheduled one
        if (Test.isRunningTest()) {
            scheduleName += System.currentTimeMillis();
        }
        String jobId = System.schedule(scheduleName, schedule, myBatch);
        return jobId;
    }
    /**
    * @description Exception class for invalid values retrieved from payment information to create a journal (file)
    * @author Vinothraja
    * @date 2021-07-30
    * @revision 1.0
    **/
    private virtual class AgentCommissionBatchException extends Exception {
    }
}