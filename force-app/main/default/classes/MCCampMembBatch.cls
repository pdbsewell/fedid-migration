/**
 * @author          inderpal.dhanoa@monash.edu
 * @description		MCT-388 Create Quick Action
 * @date            Apr.2024
 * @group			Monash Connect
*/
public with sharing class MCCampMembBatch implements Database.Batchable<CampMembOCRWrapper>, Database.Stateful{

    /**
     * Represents a record's DML result
     */
    class BatchResult {
        String dmlStatus;
        String errors;
    }

    Map<String, String> m_freshCourseAttmptPersonIds;
    Set<String> s_freshContactPersonIds;
    Map<String, CampaignMemberCreator.CampaignMemberOCRRequest> ocrRequestsByExternalId;
    Map<String, CampaignMemberCreator.CampaignMemberOCRRequest> campMembRequestsByExternalId;
    String engageTypeRequest;
    String campaignId;
    Map<Integer, String> campMembExternalIdByCsvRowNum;
    Map<Integer, String> ocrExternalIdByCsvRowNum;
    Map<String, BatchResult> campMemberBatchResultsByExternalId;
    Map<String, BatchResult> ocrBatchResultsByExternalId;
    Boolean hasCampMembError = false;
    Boolean hasOCRError = false;
    Integer ocrRecdCount = 0;
    Integer campMembRecdCount = 0;
    Id i_ocrRecdTypeId;
    String s_ocrCallStatus = 'Open';
    String s_ocrOrigin = 'System Generated';
    

    @testVisible private static Messaging.SingleEmailMessage emailMessage;

    //Batch Class constructor
	/*
     *  Method Name: MCCampMembBatch
     *  Description: Batch Class constructor to get the variables
    */
    public MCCampMembBatch(Map<String, String> m_freshCourseAttmptPersonIds, Set<String> s_freshContactPersonIds,Map<String, CampaignMemberCreator.CampaignMemberOCRRequest> ocrRequestsByExternalId,
                           Map<String, CampaignMemberCreator.CampaignMemberOCRRequest> campMembRequestsByExternalId, String engageTypeRequest, String campaignId) {
        this.m_freshCourseAttmptPersonIds = m_freshCourseAttmptPersonIds;
        this.s_freshContactPersonIds = s_freshContactPersonIds;
        this.ocrRequestsByExternalId = ocrRequestsByExternalId;
        this.campMembRequestsByExternalId = campMembRequestsByExternalId;
        this.engageTypeRequest = engageTypeRequest;
        this.campaignId = campaignId;
        this.campMembExternalIdByCsvRowNum = new Map<Integer, String>();
        this.ocrExternalIdByCsvRowNum = new Map<Integer, String>();
        this.campMemberBatchResultsByExternalId = new Map<String, BatchResult>();
        this.ocrBatchResultsByExternalId = new Map<String, BatchResult>();
        this.i_ocrRecdTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'MonCon_Support' AND SobjectType = 'Outbound_Call_Result__c'].Id;
    }

    /**
    * Implement start method (from interface) to create a wrapper list
    */
    public Iterable<CampMembOCRWrapper> start(Database.BatchableContext bc) {
        List<CampMembOCRWrapper> l_campMembOCR = new List<CampMembOCRWrapper>();
        CampMembOCRWrapper wrapperObj;
        for(String personId : s_freshContactPersonIds){
            wrapperObj = new CampMembOCRWrapper();
            wrapperObj.s_campMemberPersontId = personId;
            l_campMembOCR.add(wrapperObj);
        }
        for(String courseAttemptCallistaId : m_freshCourseAttmptPersonIds.keySet()){
            wrapperObj = new CampMembOCRWrapper();
            wrapperObj.s_ocrCourseAttemptCallistaId = courseAttemptCallistaId;
            wrapperObj.s_ocrPersonId = m_freshCourseAttmptPersonIds.get(courseAttemptCallistaId);
            l_campMembOCR.add(wrapperObj);
        }
        return l_campMembOCR;
    }

    /**
    * Implement execute method (from interface) to run the business logic
    */
    public void execute(Database.BatchableContext info, CampMembOCRWrapper[] scope) {
        Set<String> s_campaignMembPersonIds = new Set<String>();
        Set<String> s_ocrPersonIds = new Set<String>();
        Set<String> s_ocrCourseAttemptCallistaIds = new Set<String>();
        for(CampMembOCRWrapper campWrap : scope){
            if(String.isNotBlank(campWrap.s_campMemberPersontId)){
                s_campaignMembPersonIds.add(campWrap.s_campMemberPersontId);
            }
            if(String.isNotBlank(campWrap.s_ocrCourseAttemptCallistaId)){
                s_ocrCourseAttemptCallistaIds.add(campWrap.s_ocrCourseAttemptCallistaId);
            }
            if(String.isNotBlank(campWrap.s_ocrPersonId)){
                s_ocrPersonIds.add(campWrap.s_ocrPersonId);
            }
        }
        List<CampaignMember> l_campMember = new List<CampaignMember>();
        Id i_contId;
        List<Outbound_Call_Result__c> l_OutbCallRecds = new List<Outbound_Call_Result__c>();
        Map<String, Id> m_callistaContactId = new Map<String, Id>();
        Map<String, Id> m_personIdByContactId = new Map<String, Id>();
        Map<Id, String> m_contactIdByPersonId = new Map<Id, String>();
        Map<String, Id> m_callistaIdByCourseAttmptId = new Map<String, Id>();
        Map<Id, String> m_courseAttmptIdByCallistaId = new Map<Id, String>();
        // Linked Contact recds
        for(Contact con : [SELECT Id, Person_ID_unique__c 
                           FROM Contact 
                           WHERE Person_ID_unique__c IN :s_ocrPersonIds OR 
                           Person_ID_unique__c IN :s_campaignMembPersonIds]){
            m_personIdByContactId.put(con.Person_ID_unique__c,con.Id);
            m_contactIdBypersonId.put(con.Id,con.Person_ID_unique__c);
        }
        // Setup Campaign Member List
        for(String personId : s_campaignMembPersonIds){
            if(s_freshContactPersonIds.contains(personId)){
                l_campMember.add(new CampaignMember(ContactId = m_personIdByContactId.get(personId), campaignId = Id.valueOf(campaignId)));
            }
        }
        
        // Linked OCR results
        for(Course_Attempt__c courseAttmpt : [SELECT Id, Callista_External_Id__c 
                                             FROM Course_Attempt__c 
                                             WHERE Callista_External_Id__c IN :s_ocrCourseAttemptCallistaIds]){
            m_callistaIdByCourseAttmptId.put(courseAttmpt.Callista_External_Id__c, courseAttmpt.Id);
            m_courseAttmptIdByCallistaId.put(courseAttmpt.Id, courseAttmpt.Callista_External_Id__c);
            if(m_freshCourseAttmptPersonIds.containsKey(courseAttmpt.Callista_External_Id__c)){
                i_contId = m_personIdByContactId.get(m_freshCourseAttmptPersonIds.get(courseAttmpt.Callista_External_Id__c));
                if(String.isNotBlank(i_contId)){
                    l_OutbCallRecds.add(new Outbound_Call_Result__c(Contact__c = i_contId, 
                                                                    Course_Attempt__c = courseAttmpt.Id, 
                                                                    RecordTypeId = this.i_ocrRecdTypeId,
                                                                    Campaign__c = Id.valueOf(campaignId), 
                                                                    Engagement_Type__c = engageTypeRequest, 
                                                                    Call_Status__c = this.s_ocrCallStatus,
                                                                    Origin__c = s_ocrOrigin));
                }
            }
        }
        // Insert Campaign members
        Database.SaveResult[] results = Database.insert(l_campMember, false);
        this.campMembRecdCount = this.campMembRecdCount + results.size();
        CampaignMember campMembr;
        Database.SaveResult result;
        Outbound_Call_Result__c ocr;
        for (Integer i = 0; i < results.size(); i++) {
            result = results[i];
            campMembr = l_campMember[i];
            CampaignMemberCreator.CampaignMemberOCRRequest req = campMembRequestsByExternalId.get(m_contactIdBypersonId.get(CampMembr.ContactId));
            this.campMembExternalIdByCsvRowNum.put(req.inputCsvRow, m_contactIdBypersonId.get(CampMembr.ContactId));
            
            // collect all record's errors
            String[] rowErrors = new String[0];
            for (Database.Error err : result.getErrors()) {
                rowErrors.add(err.getStatusCode() + ': ' + err.getMessage());
            }
            if (!result.isSuccess()) {
                this.hasCampMembError = true;
            }
            BatchResult br = new BatchResult();
            br.dmlStatus = result.isSuccess() ? 'Created' : 'Error';
            br.errors = String.join(rowErrors, '; '); // join record's errors into single string
            this.campMemberBatchResultsByExternalId.put(m_contactIdBypersonId.get(campMembr.ContactId), br);
        }

        // Insert OCR records
        results = Database.insert(l_OutbCallRecds, false);
        this.ocrRecdCount = this.ocrRecdCount + results.size();
        String s_externalId;
        for (Integer i = 0; i < results.size(); i++) {
            result = results[i];
            ocr = l_OutbCallRecds[i];
            s_externalId = m_contactIdBypersonId.get(ocr.Contact__c) + '-' + m_courseAttmptIdByCallistaId.get(ocr.Course_Attempt__c);
            CampaignMemberCreator.CampaignMemberOCRRequest req = ocrRequestsByExternalId.get(s_externalId);
            this.ocrExternalIdByCsvRowNum.put(req.inputCsvRow, s_externalId);

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
            s_externalId = m_contactIdBypersonId.get(ocr.Contact__c) + '-' + m_courseAttmptIdByCallistaId.get(ocr.Course_Attempt__c);
            this.ocrBatchResultsByExternalId.put(s_externalId, br);
        }
    }

    /**
    * Implement finsh method (from interface) to wrap up processing.
    */
    public void finish(Database.BatchableContext info) {
        String errorCsv;
        Integer numRecords = this.ocrRecdCount + this.campMembRecdCount;
        Integer numErrors = 0;
        String[] emailCsvRows;
        Integer[] csvRowNums;

        if (this.hasCampMembError) {
            // DML errors occurred, generate a CSV
            csvRowNums = new List<Integer>(this.campMembExternalIdByCsvRowNum.keySet());
            csvRowNums.sort();
            emailCsvRows = new String[0];
            emailCsvRows.add('Original_CSV_Row,Person_ID__c,Status,Errors'); 
            for (Integer rowNum : csvRowNums) {
                String externalId = this.campMembExternalIdByCsvRowNum.get(rowNum);
                BatchResult br = this.campMemberBatchResultsByExternalId.get(externalId);
                CampaignMemberCreator.CampaignMemberOCRRequest req = this.campMembRequestsByExternalId.get(externalId);
                String[] row = new String[]{
                    String.valueOf(rowNum), req.personId, br.dmlStatus, br.errors.escapeCsv()
                };
                emailCsvRows.add(String.join(row, ','));
                if (br.dmlStatus == 'Error') {
                    numErrors++;
                }
            }
            errorCsv = String.join(emailCsvRows, '\n\n\n\n');
        }

        if(this.hasOCRError){
            // Save results for OCR records
            csvRowNums = new List<Integer>(this.ocrExternalIdByCsvRowNum.keySet()); csvRowNums.sort();
            emailCsvRows = new String[0];
            emailCsvRows.add('Original_CSV_Row,Person_ID__c,Callista_External_Id__c,Status,Errors');
            for (Integer rowNum : csvRowNums) {
                String externalId = this.ocrExternalIdByCsvRowNum.get(rowNum);
                BatchResult br = this.ocrBatchResultsByExternalId.get(externalId);
                CampaignMemberCreator.CampaignMemberOCRRequest req = this.ocrRequestsByExternalId.get(externalId);
                String[] row = new String[]{
                    String.valueOf(rowNum), req.personId, req.courseAttemptCallistaId, br.dmlStatus, br.errors.escapeCsv()
                };
                emailCsvRows.add(String.join(row, ','));
                if (br.dmlStatus == 'Error') {
                    numErrors++;
                }
            }
            errorCsv = String.join(emailCsvRows, '\n');
        }  
        sendEmail(!this.hasCampMembError, !this.hasOCRError, errorCsv, numRecords, numErrors);
    }

    /*
    * Method Name: sendEmail
     * @param  campMembrSuccess Boolean flag
     * @param  ocrSuccess Boolean flag
     * @param  errorCsv String with the Entire Error message
     * @param  numRecords number of Records 
     * @param  numErrors number of Errors
     * Description: Send Email to Owner
    */
    public static void sendEmail(Boolean campMembrSuccess, Boolean ocrSuccess, String errorCsv, Integer numRecords, Integer numErrors) {

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String successLabel;
        String messageBody;
        if (campMembrSuccess && ocrSuccess) {
            successLabel = 'Success'; messageBody = 'The upload completed successfully - ' + numRecords + ' Campaign Member records and Outbound Call records were created.';
        } else {
            // Error attach CSV file 
            successLabel = 'Errors'; messageBody = 'Errors were encountered while creating records.\n';
            messageBody += numErrors + ' of ' + numRecords + ' records encountered errors.\n';messageBody += 'Please see attached CSV for details.';
            Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
            csvAttachment.setFileName('jrg_results.csv');csvAttachment.setContentType('text/csv');csvAttachment.setBody(Blob.valueOf(errorCsv));
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
        }

        String subject = 'Campaign Member and Outbound Call record Upload - ' + successLabel + ' - ' + Datetime.now().format('YYYY-MM-dd HH:mm');
        System.debug('#! CaseCreator.sendEmail \nSubject: ' + subject + '\nBody: ' + messageBody + '\n---CSV---\n' + errorCsv);
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
    * Implement Wrapper class for Start Method.
    */
    public class CampMembOCRWrapper{
        public String s_campMemberPersontId;
        public String s_ocrCourseAttemptCallistaId;
        public String s_ocrPersonId;
    }
}