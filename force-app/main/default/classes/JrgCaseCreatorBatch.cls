/**
 * @author          tom.gangemi@monash.edu
 * @description		SA-1629 JRG - Handle upload of "JRG" case records
 * @date            Jul.2022
 * @group			Student Administration
 * Revision
 * 1.1   11.06.2024   Idhanoa     Enhancement to create OCR & Campaign Member (MCT-404)
 * 1.2   11.07.2024   Idhanoa     Enhancement to create OCR & Campaign Member (MCT-414)
*/
public without sharing class JrgCaseCreatorBatch implements Database.Batchable<Case>, Database.Stateful {

    /**
     * @author          tom.gangemi@monash.edu
     * @description     Represents a record's DML result
     */
    class BatchResult {
        String dmlStatus;
        String errors;
    }

    Case[] casesToUpsert;
    Map<String, JrgCaseCreator.JrgCaseRequest> requestsByExternalId;
    Map<String, JrgCaseCreator.JrgCaseRequest> ocrRequestsByExternalId;
    Map<Id, String> personIdByContactId;
    Map<Id, String> callistaIdByCourseAttemptId;
    Map<Integer, String> enqExternalIdByCsvRowNum;
    Map<Integer, String> ocrExternalIdByCsvRowNum;
    Map<String, BatchResult> batchResultsByExternalId;
    Boolean hasEnqError = false;
    Boolean hasOCRError = false;
    Boolean hasCampMembError = false;
    Id ocrRecdTypeId; 
    Id ocrQueueId;
    String engagementType = 'Student Support';
    String callStatus = 'Open';
    String origin = 'System Generated';
    String priorityHigh = 'High';
    String priorityCritical = 'Critical';

    @testVisible private static Messaging.SingleEmailMessage emailMessage; // used for unit testing

    /**
     *  @description Contructor class to initialize variables
     *  @param casesToUpsert cases To Upsert
     *  @param requestsByExternalId requests By External Id
     *  @param ocrRequestsByExternalId ocr Requests By ExternalId
     *  @param personIdByContactId personId By ContactId
     *  @param callistaIdByCourseAttemptId callista Id By Course Attempt Id
     */
    public JrgCaseCreatorBatch(Case[] casesToUpsert,  Map<String, JrgCaseCreator.JrgCaseRequest> requestsByExternalId,
                                Map<String, JrgCaseCreator.JrgCaseRequest> ocrRequestsByExternalId, 
                                Map<Id, String> personIdByContactId, Map<Id, String> callistaIdByCourseAttemptId) { 
        this.casesToUpsert = casesToUpsert;
        this.requestsByExternalId = requestsByExternalId;
        this.ocrRequestsByExternalId = ocrRequestsByExternalId;
        this.personIdByContactId = personIdByContactId;
        this.callistaIdByCourseAttemptId = callistaIdByCourseAttemptId;
        this.enqExternalIdByCsvRowNum = new Map<Integer, String>();
        this.ocrExternalIdByCsvRowNum = new Map<Integer, String>();
        this.batchResultsByExternalId = new Map<String, BatchResult>();
        this.ocrRecdTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'MonCon_Support' AND SobjectType = 'Outbound_Call_Result__c'].Id;
        this.ocrQueueId = [Select id,Developername, name, type from Group where DeveloperName = 'Outbound_Call_Unassigned' and Type = 'Queue'].Id;
    }

    /**
     * @description Batch Start method
     * @param Database BatchableContext
     * @return List of Iterable cases
     */
    public Iterable<Case> start(Database.BatchableContext bc) {
        return this.casesToUpsert;
    }

    /**
     * @description Batch Execute method
     * @param info List of Iterable cases
     * @param scope Database.BatchableContext information
     */
    public void execute(Database.BatchableContext info, Case[] scope){
        List<Case> createOcrEnquiries = new List<Case>();
        List<Outbound_Call_Result__c> createOcr = new List<Outbound_Call_Result__c>();

        // Upsert the Enquiries
        if(!scope.isEmpty()){
            Database.UpsertResult[] results = Database.upsert(scope, false);
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult result = results[i];
                Case c = scope[i];
                JrgCaseCreator.JrgCaseRequest req = requestsByExternalId.get(c.Alias__c);
                this.enqExternalIdByCsvRowNum.put(req.inputCsvRow, c.Alias__c); // for creating result CSV later

                // collect all record's errors
                String[] rowErrors = new String[0];
                for (Database.Error err : result.getErrors()) {
                    rowErrors.add(err.getStatusCode() + ': ' + err.getMessage());
                }
                if (!result.isSuccess()) {
                    this.hasEnqError = true;
                }
                BatchResult br = new BatchResult();
                br.dmlStatus = result.isSuccess() ? result.isCreated() ? 'Created' : 'Updated' : 'Error';
                if(result.isSuccess() && result.isCreated() && (c.Priority == priorityCritical || c.Priority == priorityHigh)){
                    createOcrEnquiries.add(c);
                }
                br.errors = String.join(rowErrors, '; '); // join record's errors into single string
                this.batchResultsByExternalId.put(c.Alias__c, br);
            }
        }
        // Create OCR records
        if(!createOcrEnquiries.isEmpty()){
            createOcr = constructOCRRecords(createOcrEnquiries, ocrRecdTypeId, ocrQueueId, engagementType, callStatus, origin);
            Database.SaveResult[] results = Database.insert(createOcr, false);
            String personIdCallistaId;
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results[i];
                Outbound_Call_Result__c c = createOcr[i];
                personIdCallistaId = personIdByContactId.get(c.contact__c) + '-' + callistaIdByCourseAttemptId.get(c.Course_Attempt__c);
                JrgCaseCreator.JrgCaseRequest req = ocrRequestsByExternalId.get(personIdCallistaId);
                this.ocrExternalIdByCsvRowNum.put(req.inputCsvRow, personIdCallistaId); // for creating result CSV later

                // collect all record's errors
                String[] rowErrors = new String[0];
                for (Database.Error err : result.getErrors()) {
                    rowErrors.add(err.getStatusCode() + ': ' + err.getMessage());
                }
                if (!result.isSuccess()) {
                    this.hasOCRError = true;
                }

                BatchResult br = new BatchResult();
                br.dmlStatus = result.isSuccess() ? 'Created' : 'Error';
                br.errors = String.join(rowErrors, '; '); // join record's errors into single string
                this.batchResultsByExternalId.put(personIdCallistaId, br);
            }
        }
    }

    /**
     * @description Batch Class finish method to send the Email with Errors as an attachment
     * @param    info Database.BatchableContext information
     */
    public void finish(Database.BatchableContext info) {
        String errorCsv;
        Integer numRecords = this.enqExternalIdByCsvRowNum.size() + this.ocrExternalIdByCsvRowNum.size();
        Integer numErrors = 0;
        Integer[] csvRowNums;
        String[] emailCsvRows;
        // Capture Enquiry Errors
        if (this.hasEnqError) {
            // DML errors occurred, generate a CSV
            csvRowNums = new List<Integer>(this.enqExternalIdByCsvRowNum.keySet());
            csvRowNums.sort();
            emailCsvRows = new String[0];
            emailCsvRows.add('Original_CSV_Row,Calendar_Code__c,Callista_External_Id__c,Person_ID__c,JRG_Risk_Indicators__c,Status,Errors');
            for (Integer rowNum : csvRowNums) {
                String externalId = this.enqExternalIdByCsvRowNum.get(rowNum);
                BatchResult br = this.batchResultsByExternalId.get(externalId);
                JrgCaseCreator.JrgCaseRequest req = this.requestsByExternalId.get(externalId);

                String[] row = new String[]{
                    String.valueOf(rowNum), req.calendarCode, req.courseAttemptCallistaId,
                    req.personId, req.outreachCategory, br.dmlStatus, br.errors.escapeCsv()
                };
                emailCsvRows.add(String.join(row, ','));
                if (br.dmlStatus == 'Error') {
                    numErrors++;
                }
            }
            errorCsv = String.join(emailCsvRows, '\n');
        }
        // Capture OCR Errors
        if (this.hasOCRError) {
            // DML errors occurred, generate a CSV
            csvRowNums = new List<Integer>(this.ocrExternalIdByCsvRowNum.keySet());
            csvRowNums.sort();
            emailCsvRows = new String[0];
            for (Integer rowNum : csvRowNums) {
                String externalId = this.ocrExternalIdByCsvRowNum.get(rowNum);
                BatchResult br = this.batchResultsByExternalId.get(externalId);
                JrgCaseCreator.JrgCaseRequest req = this.ocrRequestsByExternalId.get(externalId);

                String[] row = new String[]{
                    String.valueOf(rowNum), req.calendarCode, req.courseAttemptCallistaId,
                    req.personId, req.outreachCategory, br.dmlStatus, br.errors.escapeCsv()
                };
                emailCsvRows.add(String.join(row, ','));
                if (br.dmlStatus == 'Error') {
                    numErrors++;
                }
            }
            errorCsv = String.join(emailCsvRows, '\n');
        }
        sendEmail(!(this.hasCampMembError || this.hasOCRError || this.hasEnqError), errorCsv, numRecords, numErrors);
    }

    /**
     * @description Method to formulate the body of the Email
     * @param    success or failre of DML
     * @param    errorCsv list of the errors
     * @param    numRecords Number of records
     * @param    numErrors Number of errors
     */
    public static void sendEmail(Boolean success, String errorCsv, Integer numRecords, Integer numErrors) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String successLabel;
        String messageBody;
        if (success) {
            successLabel = 'Success';
            messageBody = 'The upload completed successfully - ' + numRecords + ' Cases were updated/inserted, Campaign Members and OCR records were created.';
        } else {
            successLabel = 'Errors';
            messageBody = 'Errors were encountered while creating Enquiries, OCR and Campaign Member from the JRG records.\n';
            messageBody += numErrors + ' of ' + numRecords + ' records encountered errors.\n';
            messageBody += 'Please see attached CSV for details.';

            Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
            csvAttachment.setFileName('jrg_results.csv');
            csvAttachment.setContentType('text/csv');
            csvAttachment.setBody(Blob.valueOf(errorCsv));
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{
                csvAttachment
            });
        }

        String subject = 'JRG Upload - ' + successLabel + ' - ' + Datetime.now().format('YYYY-MM-dd HH:mm');

        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :String.valueOf(Label.AI_Digest_Email_Address)];

        mail.setSaveAsActivity(false);
        mail.setOrgWideEmailAddressId(owea[0].Id);
        mail.setSubject(subject);
        mail.setToAddresses(new String[]{UserInfo.getUserEmail()});
        mail.setPlainTextBody(messageBody);

        emailMessage = mail;
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }

    /**
     * @description Method to construct the OCR records 
     * @param    createOcrEnquiries list of create Ocr Enquiries
     * @param    ocrRecdTypeId ocr recd type Id
     * @param    ocrQueueId ocr Queue Id
     * @param    engagmntType engagmnt Type
     * @param    callStatus call status
     * @param    origin enquiry origin
     * @return List of OCRS
     */
    public static List<Outbound_Call_Result__c> constructOCRRecords(List<Case> createOcrEnquiries, Id ocrRecdTypeId, Id ocrQueueId, 
                                                                    String engagmntType, String callStatus, String origin) {
        String[] splitKey;
        Set<String> linkedCourseAttemptCallistaId = new Set<String>();
        Set<String> linkedPersonId = new Set<String>();
        List<Outbound_Call_Result__c> createOCR = new List<Outbound_Call_Result__c>();
        Map<String,Id> courseAttmptIdByCallistaId = new Map<String, Id>();
        Map<String,Id> contactIdByPersonId = new Map<String, Id>();
        Set<Id> linkedCampaigns = new Set<Id>();
        Set<Id> notEndedCampaigns = new Set<Id>();
        for(Case freshEnq : createOcrEnquiries){
            if(freshEnq.Alias__c.contains('-')){
                splitKey = freshEnq.Alias__c.split('-');
                linkedCourseAttemptCallistaId.add(splitKey[1]);
                linkedPersonId.add(splitKey[0]);
                linkedCampaigns.add(freshEnq.Campaign__c);
            }  
        }
        // CHeck for Campaigns which are not EndDated
        for(Campaign cmp : [SELECT Id FROM CAMPAIGN WHERE EndDate >= :Date.TODAY() AND Id IN :linkedCampaigns]){
            notEndedCampaigns.add(cmp.Id);
        }
        for(Course_Attempt__c c : [SELECT Callista_External_Id__c FROM Course_Attempt__c WHERE Callista_External_Id__c IN :linkedCourseAttemptCallistaId]) {
            courseAttmptIdByCallistaId.put(c.Callista_External_Id__c, c.Id);
        }
        for(Contact c : [SELECT Person_ID__c FROM Contact WHERE Person_ID__c IN :linkedPersonId]) {
            contactIdByPersonId.put(c.Person_ID__c, c.Id);
        }
        for(Case freshEnq : createOcrEnquiries){
            // Add the OCR's only if the Campaign is not EndDated
            if(notEndedCampaigns.contains(freshEnq.Campaign__c)){
                if(freshEnq.Alias__c.contains('-')){
                    splitKey = freshEnq.Alias__c.split('-');
                    createOCR.add(new Outbound_Call_Result__c(Contact__c = contactIdByPersonId.get(splitKey[0]), 
                                                            Case__c = freshEnq.Id,
                                                            Course_Attempt__c = courseAttmptIdByCallistaId.get(splitKey[1]), 
                                                            RecordTypeId = ocrRecdTypeId,
                                                            Campaign__c = freshEnq.Campaign__c, 
                                                            Engagement_Type__c = engagmntType, 
                                                            Call_Status__c = callStatus,
                                                            Origin__c = origin,
                                                            OwnerId = ocrQueueId));
                }
            }            
        }
        return createOCR;
    }

    /**
    * @description Implement Wrapper class for Start Method.
    */
    public class CampMembEnquiryWrapper{
        public Case caseToUpsert;
        public CampaignMember campMembrToCreate;
    }

}