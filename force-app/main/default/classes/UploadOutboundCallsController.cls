/**
 * @author			Ayush Agrawal (ayush.agrawal@monash.edu)
 * @group			SRA (Student Recruitment and Admissions) - BabyShark
 * @description		EPBBS-1220 Custom process handler to upload outbound calls for SRA campaigns. This
 * 					is used by the Aura component 'UploadOutboundCalls'.
 * @revision		ayush.agrawal@monash.edu - EPBBS-1337 - Support for Contact ID during upload process.
 * @revision		tom.gangemi@monash.edu - SA-1557 - Add Upload Component Notification Email
 * @revision		RANAND Included logic to create Case for Pre Apps and associate Leads
 */
public class UploadOutboundCallsController {

    // used for unit-test validation
    @TestVisible private static Boolean testSuccess;
    @TestVisible private static Records testRecords;
    static final String REF_PERSON_ID = 'person_id';
    static Integer BATCH_SIZE;
    public class Records {
        public String contact_reference_type;
        public List<Record> records;
        public Integer numRows;
        public boolean success;
        public boolean isPostAppCampaign;
    }

    public class Record {
        public String contact_reference_id;
        public String acp_id;
        public String result;
    }

    @AuraEnabled
    public static String getCampaignType(Id recordId) {
        return [SELECT Id, Type FROM Campaign WHERE Id = :recordId LIMIT 1].Type;
    }
    
	@AuraEnabled
    public static void uploadOutboundCalls(Id recordId, String outboundCallsJSON) {
        String campType = getCampaignType(recordId);
        BATCH_SIZE =  Environment_Settings__c.getOrgDefaults().Outbound_Call_Batch_Size__c != null ? Integer.valueOf(Environment_Settings__c.getOrgDefaults().Outbound_Call_Batch_Size__c):50;
        Database.executeBatch(new UploadOutboundCallsBatch(outboundCallsJSON, recordId), BATCH_SIZE);
    }
    /**
     * @description EPBBS-3177 Method consolidates the dml outcome of individual contact rows in a csv file 
     *                         which then be used to sent as an attachment of email
     **/
    public static String generateCSV(Records recs, Boolean isPostAppCampaign) {
        String contactRefType = REF_PERSON_ID;
        if(recs.contact_reference_type !=  REF_PERSON_ID) {
            contactRefType = 'contact_id';
        }

        String header = contactRefType;
        if(isPostAppCampaign) {
            header += ', acp_id';
        }
        header += ', result';
        String[] csvRows = new String[]{header};
        for(Record rec :recs.records) {
            String cRefId = rec.contact_reference_id == null ? '' : rec.contact_reference_id;
            String acpId = rec.acp_id == null ? '' : rec.acp_id;
            String result = rec.result == null ? '' : rec.result;
            String row = cRefId;
            if(isPostAppCampaign) {
                row += ',' + acpId;
            }
            row += ',' + result;
            csvRows.add(row);
        }
        return String.join(csvRows, '\n');
    }
    /**
     * @description EPBBS-3177 Method used to operate on uploaded Contacts in order to identify below:
     *                          a. Outboud call already created
     *                          b. Create Enquiry in case of Pre Apps
     *                          c. Consolidate individual rows outcome
     *                          d. incorporates process to send email
     **/
    public static Records uploadOutboundCallsNow(Id recordId, List<Record> outboundCallsIncoming,String campType) {
        // Load reference data.
        String enquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Outbound Call').getRecordTypeId();
        Campaign campaignReference = [SELECT Id, Type FROM Campaign WHERE Id = :recordId LIMIT 1];
        
        Boolean isPostAppCampaign = campaignReference.Type == 'Domestic Post App' || campaignReference.Type == 'International Post App';
        
        Id outboundCallRecordTypeId = Schema.SObjectType.Outbound_Call_Result__c.getRecordTypeInfosByName().get(campaignReference.Type).getRecordTypeId();
        
        // Declare container variables.
        Set<String> contactReferenceIDs = new Set<String>();
        Set<String> acpIDs = new Set<String>();
        Set<Id> contactCaseIds = new Set<Id>();
        // Parse incoming JSON.
        //Records outboundCallsIncoming = (Records) JSON.deserialize(outboundCallsJSON, Records.class);
        
        for(Record outboundCallIncoming : outboundCallsIncoming) {
            contactReferenceIDs.add(outboundCallIncoming.contact_reference_id);
            
            if(isPostAppCampaign) {
                acpIDs.add(outboundCallIncoming.acp_id);
            }
        }

        // Create lookup map for Contact.
        Map<String, Id> contactIdByContactReference = new Map<String, Id>();
        if(campType == REF_PERSON_ID) {
            for(Contact c : [SELECT Id, Person_Id_Unique__c FROM Contact WHERE Person_Id_Unique__c IN :contactReferenceIDs]) {
                contactIdByContactReference.put(c.Person_Id_Unique__c, c.Id);
            }
        } else {
            for(Record outboundCallIncoming : outboundCallsIncoming) {
                contactIdByContactReference.put(outboundCallIncoming.contact_reference_id, outboundCallIncoming.contact_reference_id);
            }
        }
        
        // Create lookup map for Application_Course_Preference__c.
        Map<String, Id> acpSfidByAcpId = new Map<String, Id>();
        if(isPostAppCampaign) {
            for(Application_Course_Preference__c acp : [SELECT Id, ACP_ID__c FROM Application_Course_Preference__c WHERE ACP_ID__c IN :acpIDs]) {
                acpSfidByAcpId.put(acp.ACP_ID__c, acp.Id);
            }
        }
        
        // Create lookup map for existing outbound calls.
        Map<Id, Id> acpSfidByContactId = new Map<Id, Id>();
        for(Outbound_Call_Result__c ocr : [
            SELECT Application_Course_Preference__c, Contact__c
            FROM Outbound_Call_Result__c WHERE Campaign__c = :recordId
        ]) {
            acpSfidByContactId.put(ocr.Contact__c, ocr.Application_Course_Preference__c);
        }
        
        List<Outbound_Call_Result__c> outboundCallsToCreate = new List<Outbound_Call_Result__c>();

        Map<String, Record> recordsByContactIdAndAcpSfid = new Map<String, Record>();

        Boolean success = true;

        // Create new outbound calls if not found within the campaign.
        for(Record outboundCallIncoming : outboundCallsIncoming) {
            Id contactId = contactIdByContactReference.get(outboundCallIncoming.contact_reference_id);
            Id acpId = acpSfidByAcpId.get(outboundCallIncoming.acp_id);

            if(contactId == null) {
                outboundCallIncoming.result = 'Contact not found';
                success = false;
                continue;
            }

            String uniqueKey = contactId;

            Boolean skip = false; // true if existing records

            if(isPostAppCampaign) {
                if(acpId != null) {
                    uniqueKey += acpId;
                } else {
                    outboundCallIncoming.result = 'ACP not found';
                    continue;
                }
                
                if(acpSfidByContactId.get(contactId) == acpId) {
                    skip = true;
                }
            } else {
                if(acpSfidByContactId.containsKey(contactId)) {
                    skip = true;
                }
            }

            if(skip) {
                outboundCallIncoming.result = 'Skipped - Record Already Exists';
                continue;
            }
            
            if(recordsByContactIdAndAcpSfid.containsKey(uniqueKey)) {
                // already contains record
                outboundCallIncoming.result = 'Skipped - Duplicate';
                continue;
            }

            recordsByContactIdAndAcpSfid.put(uniqueKey, outboundCallIncoming);
            
            Outbound_Call_Result__c outboundCall = new Outbound_Call_Result__c();
            outboundCall.Campaign__c = recordId;
            outboundCall.Contact__c = contactId;
            outboundCall.RecordTypeId = outboundCallRecordTypeId;
            
            if(isPostAppCampaign) {
                outboundCall.Application_Course_Preference__c = acpId;
            }
            else{
                contactCaseIds.add((Id)contactId);
            }
            
            outboundCallsToCreate.add(outboundCall);
        }
        Map<Id,Id> contactCaseMap = new Map<Id,Id>();
        if(!contactCaseIds.isEmpty()){
            contactCaseMap = createPreAppCasesForOCR(recordId, enquiryRecordTypeId, contactCaseIds);
        }
        for(Outbound_Call_Result__c ocrObj : outboundCallsToCreate){
            if(contactCaseMap.containsKey(ocrObj.Contact__c)){
                ocrObj.Case__c = contactCaseMap.get(ocrObj.Contact__c);
            }
        }
        Integer numRows = 0;

        if(!outboundCallsToCreate.isEmpty()) {
            Savepoint sp = Database.setSavepoint();
            Database.SaveResult[] results = Database.insert(outboundCallsToCreate, false);
            numRows = outboundCallsToCreate.size();

            for(Integer i = 0; i < outboundCallsToCreate.size(); i++) {
                Outbound_Call_Result__c ocr = outboundCallsToCreate[i];
                Database.SaveResult sr = results[i];

                String uKey = ocr.Contact__c;
                if(isPostAppCampaign) {
                    uKey += ocr.Application_Course_Preference__c;
                }
                Record r = recordsByContactIdAndAcpSfid.get(uKey);

                if(!sr.success) {
                    // retrieve DML error and add it to the offending Record
                    success = false;
                    r.result = '"' + sr.errors[0].message.remove('"') + '"';
                } else {
                    r.result = 'OK';
                }
            }

            if(!success) {
                // revert
                Database.rollback(sp);
            }
        }

        Records returnItem = new Records();
        returnItem.records = outboundCallsIncoming;
        returnItem.numRows = numRows;
        returnItem.success = success;
        returnItem.isPostAppCampaign = isPostAppCampaign;
        testSuccess = success;
        testRecords = returnItem;
        return returnItem;
    }
    /**
     * @description EPBBS-3177 Method consolidates the outcome of OCR creation into a CSV and sends email to logged in User
     **/
    public static void sendEmail(Records recs, Boolean success, Boolean isPostAppCampaign) {

        String csvData = generateCSV(recs, isPostAppCampaign);
        Blob csvBlob = Blob.valueOf(csvData);
        Integer numRows = recs.numRows;
        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        String csvName = 'results.csv';
        csvAttachment.setFileName(csvName);
        csvAttachment.setBody(csvBlob);
        csvAttachment.setContentType('text/csv');

        String successLabel;
        String messageBody;
        if(success) {
            successLabel = 'Success';
            messageBody = 'The upload completed successfully - ' + numRows + ' Outbound Call Results were inserted.';
        } else {
            successLabel = 'Failure';
            messageBody = 'One or more rows encountered an error - No records have been inserted.';
        }
        messageBody += '\nPlease see attached CSV for details.';

        String subject = 'Outbound Call Result Upload - ' + successLabel + ' - ' + Datetime.now().format('YYYY-MM-dd');

        System.debug('#! UploadOutboundCallsController.sendEmail \nSubject: ' + subject + '\nBody: ' + messageBody + '\n---CSV---\n' + csvData);

        String[] toAddresses = new String[]{UserInfo.getUserEmail()};

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@f.e.monash.edu'];

        mail.setSaveAsActivity(false);
        mail.setOrgWideEmailAddressId(owea[0].Id);
        mail.setSubject(subject);
        mail.setToAddresses(toAddresses);
        mail.setPlainTextBody(messageBody);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});

        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }
    /**
     * @description EPBBS-3177 Create Enquiry for pre app type of Outbound Calls and return map of ContactId and created CaseId
     **/
    public static Map<Id,Id> createPreAppCasesForOCR(Id campaignId, Id enquiryRecordTypeId, Set<Id> contactIds){
        Map<Id, Id> contactLeadMap =  new Map<Id, Id>();
        Map<Id, Id> returnContactCaseMap =  new Map<Id, Id>();
        Map<Id, Case> casesCreated =  new Map<Id, Case>();
       
        for(Lead objL : [SELECT Id, Active_Lead_Contact_Id__c FROM Lead WHERE Active_Lead_Contact_Id__c IN: contactIds]) {
            Case objCaseCreate = new Case(
                                        ContactId=objL.Active_Lead_Contact_Id__c, 
                                        RecordTypeId = enquiryRecordTypeId,
                                        Campaign__c = campaignId,
                                        Lead__c = objL.Id
                                        );                        
            casesCreated.put(objL.Active_Lead_Contact_Id__c, objCaseCreate);
        }
        if(!casesCreated.isEmpty()){
            Database.SaveResult[]  results =  Database.insert(casesCreated.values(), false);
            for(Id key : casesCreated.keyset()){
                if(casesCreated.get(key).Id != null){
                    returnContactCaseMap.put(key, casesCreated.get(key).Id);
                }
            }
        }
        return returnContactCaseMap;
    }
}