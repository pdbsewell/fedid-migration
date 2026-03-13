/**
 * @description Batchable Class to generate a file (ContentVersion) as journal file to be sent to SAP.
				Class implements Database.Stateful to retain the journal and paymentIds instance variables between batches of the execute method.
				Class implements Database.Schedule
 * @author Stefan Scheit
 * @date 2019-12-17
 * @revision 1.3
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author          	Modification
 * 1.5	 17-01-2023   Inderpal Dhanoa   Updated logic to consider Sent to SAP PENGAGE-2615
 * 1.4	 02-01-2023   Inderpal Dhanoa   Updated logic to consider Charge Id PENGAGE-2603
 * 1.3	 28-11-2022   Inderpal Dhanoa   Updated file layout PENGAGE-2480
 * 1.2	 31-10-2022   Inderpal Dhanoa   Updated API name for Monash Receipt Number PENGAGE-2550
 * 1.1   14-06-2022   Inderpal Dhanoa   PENGAGE-2372 Limit Batch Size to allow sending files to SAP  
 * 1.0   17-12-2019   Stefan Scheit     Initial Version
 * 
 * Sending gateway id via SL08
 * Include AMEX in the list of credit cards
 **/
public without sharing class JournalBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    public static final string EMPTY_STRING = '';
    public static final String[] CREDIT_CARDS = new String[] {'Visa','MasterCard','American Express','Diners','AMEX'};
    public static final String FILE_PREFIX = '400' + '371' + 'CS' + '_'; 		// file prefix used for outbound file to SAP (400 = interface type, 371 client number)
	public static final String FILE_SUFFIX = '.txt'; 							// end .txt to SAP
	public static final Integer MAX_RECORDS = 450; 								// limit to avoid more than 900 line items in output journal file (2 per each ucinn_ascendv2__Payment__c record due separate credit and debit line items). SAP line item limit is 950. 
	public static final String DEFAULT_SCHEDULE = '0 0 2 * * ?'; 				// at 2 am every day
	private static final Id INTEGRATION_USER  = [SELECT Id FROM User WHERE Username LIKE 'mix.api.event@monash.edu%' LIMIT 1].Id; // MiX user for LIKE SOQL to read the outbound journal event to retrieve the file (has to be shared)
	private JournalFile journal = new JournalFile();							// journal file contain result records
	private Set<Id> paymentIds = new Set<Id>(); 								// payment records to be marked as part of journal

	/**
     * Method to initialise query locator
     * @param  bc as BatchableContext
     * @return    QueryLocator
     */
	public Database.QueryLocator start(Database.BatchableContext bc) {
		// retrieve all (credit card) payments a journal should be created for
		return Database.getQueryLocator(
				// SOQL spelled out to force dependency checking on fields (instead of loosely coupled String)  
		[SELECT
		// Hard/Soft Credit fields
				Id, ucinn_ascendv2__Credit_Amount__c, 
				// Designation fields
				ucinn_ascendv2__Designation__r.ucinn_ascendv2__G_L_Acknowledgement_Description__c, ucinn_ascendv2__Designation__r.ucinn_ascendv2__G_L_Short_Description__c, ucinn_ascendv2__Designation__r.ucinn_ascendv2__Program_Code__c, ucinn_ascendv2__Designation__r.Tax_Status_Code__c,
         		ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Opportunity__c,ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Opportunity__r.ucinn_ascendv2__External_Payment_Gateway_ID__c,ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Opportunity__r.ucinn_ascendv2__External_System_ID__c,ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Opportunity__r.id,
				// Payment fields
				ucinn_ascendv2__Payment__r.Id, /*ucinn_ascendv2__Payment__r.Name,*/ ucinn_ascendv2__Payment__r.Monash_Receipt_Number__c, ucinn_ascendv2__Payment__r.Receipt_Number_Formula__c, ucinn_ascendv2__Payment__r.ucinn_ascendv2__Tender_Type_Formula__c, ucinn_ascendv2__Payment__r.Payment_Settlement_Date__c, ucinn_ascendv2__Payment__r.Batch_Id__c, ucinn_ascendv2__Payment__r.ucinn_ascendv2__Transaction_ID__c, ucinn_ascendv2__Payment__r.ucinn_ascendv2__Charge_Request_ID__c 
		// Session fields
		/*ucinn_ascendv2__Session__r.Name*/
		FROM
				ucinn_ascendv2__Hard_and_Soft_Credit__c
		WHERE
		// needs to be a (one-off) payment or recurring gift payment
		ucinn_ascendv2__Source__c IN ('Payment','Recurring Gift Payment')      
		// hard credit (=payment) only
		AND ucinn_ascendv2__Credit_Type__c = 'Hard'
		// only send amounts > 0 to journal
		AND ucinn_ascendv2__Credit_Amount__c > 0
		// only Settled entries
		AND ucinn_ascendv2__Payment__r.Payment_Settled__c = true
		// of type credit card, exclude Credit/Debit Card - Other as it is used for direct capture of payments (via CC) in SAP
		AND ucinn_ascendv2__Payment__r.ucinn_ascendv2__Tender_Type_Formula__c IN :CREDIT_CARDS
		// in right oppty stage (not adjusted or does not relate to an 'adjustment' opportunity
		AND (ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Opportunity__r.StageName != 'Adjusted' OR ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Opportunity__r.ucinn_ascendv2__Adjusted_Gift__c != null)
		// not yet sent to the finance system
		AND ucinn_ascendv2__Payment__r.Sent_to_SAP__c = false
		AND ucinn_ascendv2__Payment__r.Sent_Date_to_SAP__c = null 		
		// and session approved
		AND ucinn_ascendv2__Session__r.ucinn_ascendv2__Session_Totals_Approved__c != null
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
		List<ucinn_ascendv2__Hard_and_Soft_Credit__c> records = scope;
		// journal file data objects
		Journalfile.LineItem creditLineItem = null;
		// Exception object(s)
		List<Exception_Log__c> exLogRecordList = new List<Exception_Log__c>();
		Exception_Log__c exLogRecord = null;
		Map<String, List<ucinn_ascendv2__Hard_and_Soft_Credit__c>> m_batchIdSettlmntDteHardSoftCredits = new Map<String, List<ucinn_ascendv2__Hard_and_Soft_Credit__c>>();
		List<ucinn_ascendv2__Hard_and_Soft_Credit__c> l_relCreditRecds;
		String s_key, s_reqId;
		for(ucinn_ascendv2__Hard_and_Soft_Credit__c record : records) {
			try {
				if (null != record.ucinn_ascendv2__Payment__r && String.isNotBlank(record.ucinn_ascendv2__Payment__r.Batch_Id__c) && record.ucinn_ascendv2__Payment__r.Payment_Settlement_Date__c != null){
					s_key = record.ucinn_ascendv2__Payment__r.Batch_Id__c + '_' + convertDateTimeToString(record.ucinn_ascendv2__Payment__r.Payment_Settlement_Date__c);
					if(m_batchIdSettlmntDteHardSoftCredits.containsKey(s_key)){
						l_relCreditRecds = m_batchIdSettlmntDteHardSoftCredits.get(s_key);
					}else{
						l_relCreditRecds = new List<ucinn_ascendv2__Hard_and_Soft_Credit__c>();
					}
					l_relCreditRecds.add(record);
					m_batchIdSettlmntDteHardSoftCredits.put(s_key, l_relCreditRecds);
				}
				// Get the Req Id either from ucinn_ascendv2__Transaction_ID__c or ucinn_ascendv2__Charge_Request_ID__c
				if(null != record.ucinn_ascendv2__Payment__r){ 
					s_reqId = String.isNotBlank(record.ucinn_ascendv2__Payment__r.ucinn_ascendv2__Transaction_ID__c) ? record.ucinn_ascendv2__Payment__r.ucinn_ascendv2__Transaction_ID__c : record.ucinn_ascendv2__Payment__r.ucinn_ascendv2__Charge_Request_ID__c;
				}
				// Credit Line Item: create item per record in result set and set fields required (others are defaulted in JournalFile)
				creditLineItem = new JournalFile.LineItem();
				// SL03
				if (null != record.ucinn_ascendv2__Credit_Amount__c && record.ucinn_ascendv2__Credit_Amount__c > 0) {
					creditLineItem.sl03 = String.valueOf(record.ucinn_ascendv2__Credit_Amount__c.setScale(2));
				} else {
					throw new JournalBatchException('The debit amount of hard/soft credit item ['+record.Id+'] is not valid for processing the field SL03 (credit) as part of the SAP journal file.');
				}
				// SL04

				if (null != record.ucinn_ascendv2__Designation__r && String.isNotBlank(record.ucinn_ascendv2__Designation__r.ucinn_ascendv2__G_L_Acknowledgement_Description__c)) {
					creditLineItem.sl04 = record.ucinn_ascendv2__Designation__r.ucinn_ascendv2__G_L_Acknowledgement_Description__c;
				} else {
					throw new JournalBatchException('The GL Acknowledgement Description of hard/soft credit item ['+record.Id+'] is not valid for processing the field SL04 (credit) as part of the SAP journal file.');
				}
				// SL05
				if (null != record.ucinn_ascendv2__Designation__r && String.isNotBlank(record.ucinn_ascendv2__Designation__r.ucinn_ascendv2__G_L_Short_Description__c)) {
					creditLineItem.sl05 = record.ucinn_ascendv2__Designation__r.ucinn_ascendv2__G_L_Short_Description__c;
				} else {
					throw new JournalBatchException('The GL Short Description of hard/soft credit item ['+record.Id+'] is not valid for processing the field SL05 (credit) as part of the SAP journal file.');
				}
				// SL06
				if (null != record.ucinn_ascendv2__Designation__r && String.isNotBlank(record.ucinn_ascendv2__Designation__r.ucinn_ascendv2__Program_Code__c)) {
					creditLineItem.sl06 = record.ucinn_ascendv2__Designation__r.ucinn_ascendv2__Program_Code__c;
				} else {
					throw new JournalBatchException('The GL Account (Program Code) of hard/soft credit item ['+record.Id+'] is not valid for processing the field SL06 (credit) as part of the SAP journal file.');
				}
				// SL07
				if (null != record.ucinn_ascendv2__Payment__r && String.isNotBlank(record.ucinn_ascendv2__Payment__r.Batch_Id__c) && record.ucinn_ascendv2__Payment__r.Payment_Settlement_Date__c != null
				&& String.isNotBlank(s_reqId)) { 
						creditLineItem.sl07 =  record.ucinn_ascendv2__Payment__r.Batch_Id__c + '-' + convertDateTimeToString(record.ucinn_ascendv2__Payment__r.Payment_Settlement_Date__c)  + '-' + s_reqId;
				} else {
					throw new JournalBatchException('The Payment Receipt Number of hard/soft credit item ['+record.Id+'] is not valid for processing the field SL07 (credit) as part of the SAP journal file.');
				}
				// SL13
				if (null != record.ucinn_ascendv2__Designation__r && String.isNotBlank(record.ucinn_ascendv2__Designation__r.Tax_Status_Code__c)) {
					creditLineItem.sl13 = record.ucinn_ascendv2__Designation__r.Tax_Status_Code__c;
				} else {
					throw new JournalBatchException('The Tax Status Code of hard/soft credit item ['+record.Id+'] is not valid for processing the field SL13 (credit) as part of the SAP journal file.');
				} 

				// Add line items to journal
				journal.addCreditLineItem(creditLineItem);
				// Mark record as extracted / journalled by payment Id 
				paymentIds.add(record.ucinn_ascendv2__Payment__r.Id);
			} catch (Exception exc) {
				System.debug(LoggingLevel.Error, 'Error while processing hard/soft credit item ['+record.Id+'] with exception: '+exc);
				// log exception (and add to list to be captured (eventually via insert))
				exLogRecord = ExLog.writeExlog('Field not present', 'JournalBatch', 'execute', String.valueOf(record.Id), exc);exLogRecordList.add(exLogRecord);
			}
		}
		// calculate AggregatedEntries which Add sum of Amount for each Batch Id and Settlement date
		if(!m_batchIdSettlmntDteHardSoftCredits.isEmpty()){
			journal = generateAggragetedEntries(m_batchIdSettlmntDteHardSoftCredits, records, journal);
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
	 * Method to generate Aggregate Entries.
	 * @param  Map of String and List<ucinn_ascendv2__Hard_and_Soft_Credit__c> entries
	 * @return    JournalFile
	 */
	public JournalFile generateAggragetedEntries(Map<String, List<ucinn_ascendv2__Hard_and_Soft_Credit__c>> m_batchIdSettlmntDteHardSoftCredits, List<ucinn_ascendv2__Hard_and_Soft_Credit__c> records, JournalFile journal){
		// journal file data objects
		Journalfile.LineItem debitLineItem = null;
		Decimal d_aggregatedAmount;
		List<ucinn_ascendv2__Hard_and_Soft_Credit__c> l_linkedRecds;
		List<String> l_splitInfo;
		for(String s_batchIdSettlmntDte : m_batchIdSettlmntDteHardSoftCredits.keyset()) {
			try {
				d_aggregatedAmount = 0;
				l_linkedRecds = m_batchIdSettlmntDteHardSoftCredits.get(s_batchIdSettlmntDte);
				l_splitInfo = s_batchIdSettlmntDte.split('_');
				debitLineItem = new JournalFile.LineItem();
				// Sum up all the entries to get the Aggregate Amount
				for(ucinn_ascendv2__Hard_and_Soft_Credit__c record : m_batchIdSettlmntDteHardSoftCredits.get(s_batchIdSettlmntDte)){
					d_aggregatedAmount = d_aggregatedAmount + record.ucinn_ascendv2__Credit_Amount__c.setScale(2);
				}
				// SL02
				if (d_aggregatedAmount > 0) {
					debitLineItem.sl02 = String.valueOf(d_aggregatedAmount);
				} else {
					throw new JournalBatchException('The aggregate credit amount of Aggregated hard/soft debit item ['+s_batchIdSettlmntDte+'] is not valid for processing the field SL02 (debit) as part of the SAP journal file.');
				}
				// SL06
				debitLineItem.sl06 = '101004';
				// SL07
				if (String.isNotBlank(l_splitInfo[1])) {
					debitLineItem.sl07 = l_splitInfo[1];
				} else {
					throw new JournalBatchException('The Batch Id field of Aggregated hard/soft debit item ['+s_batchIdSettlmntDte+'] is not valid for processing the field SL07 (debit) as part of the SAP journal file.');
				}
                // SL08
				if (String.isNotBlank(l_splitInfo[0])) {
                    debitLineItem.sl08 = l_splitInfo[0]; 
				} else {
					throw new JournalBatchException('The External Payment Gateway ID of Aggregated hard/soft debit item ['+s_batchIdSettlmntDte+'] is not valid for processing the field SL08 (debit) as part of the SAP journal file.');
				}
				// Add line items to journal
				journal.addDebitLineItem(debitLineItem);
			} catch (Exception exc) {
				LogUtilityException.logException(exc,'Error while processing hard/soft credit item'); 
			}
		}
		return journal;
	}

	/**
	 * Method to convert date time into String.
	 * @param  DateTime as dt_settlmntDate
	 * @return    String
	 */
	public String convertDateTimeToString(Datetime dt_settlmntDate) {
		String s_convDateTime = String.valueOf(dt_settlmntDate);
		String s_convDate = s_convDateTime.split(' ')[0];
		return s_convDate.replace('-','');
	}


	/**
	 * Method to finish processing
	 * @param  bc as BatchableContext
	 */
	public void finish(Database.BatchableContext bc) {
		// generate file (as ContentVersion)
		String strFileContent = journal.toStringFixedLength();
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

			// update paymentIds as journalled to have them not queried (and procesed) again
			List<ucinn_ascendv2__Payment__c> paymentProcessedList = new List<ucinn_ascendv2__Payment__c>();
			for (ucinn_ascendv2__Payment__c payment : [SELECT Id, ucinn_ascendv2__Send_to_G_L__c, ucinn_ascendv2__Sent_to_G_L_Date__c
			FROM ucinn_ascendv2__Payment__c
			WHERE Id in :paymentIds]) {
				payment.Sent_to_SAP__c = true;
				payment.Sent_Date_to_SAP__c = Date.today();
				paymentProcessedList.add(payment);
			}
			Database.update(paymentProcessedList);

			// create outbound platform event (for integration layer)
			Outbound_Journal__e outEvent = new Outbound_Journal__e();
			outEvent.FileUrl__c = '/services/data/v47.0/sobjects/ContentVersion/'+file.Id;
			Eventbus.publish(outEvent);
		} catch(DMLException e) {
			System.debug(LoggingLevel.ERROR, e);
			Exception_Log__c exLogRecord = ExLog.writeExlog('File generation', 'JournalBatch', 'execute', null, e);
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
		JournalBatch myJournalBatch = new JournalBatch();
		Database.executeBatch(myJournalBatch);
	}

	/**
	 * Method to schedule the JournalBatch with a default cron timing (at 2:00 am)
	 */
	public String schedule() {
		String schedule = DEFAULT_SCHEDULE;
		return this.schedule(schedule);
	}

	/**
    * Method to schedule the JournalBatch with a set cron timing
    * @param schedule The schedule as cron String
    */
	public String schedule(String schedule) {
		JournalBatch myBatch = new JournalBatch();
		String scheduleName = String.valueOf(JournalBatch.class);
		// assign unique name when running in test context as it cannot have the same name of an already scheduled one
        if (Test.isRunningTest()) {
			scheduleName += System.currentTimeMillis();
		}
		String jobId = System.schedule(scheduleName, schedule, myBatch);
		return jobId;
	}
	
	/**
    * @description Exception class for invalid values retrieved from payment information to create a journal (file)
    * @author Stefan Scheit
    * @date 2019-12-14
    * @revision 1.0
	**/
	private virtual class JournalBatchException extends Exception {
	}
}