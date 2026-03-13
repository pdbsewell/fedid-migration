/**
 * @author       Nitin Khandelwal
 * @date         18.Sept.2018
 * @description  Synchronous call to submit documents to Callista
 * @revision
 * 22/07/2019 - Shalini Mendu- Refactoring and cleaning up
 * 03/08/2020 - Steffi       - fix PMD issue -Avoid making DML operations in Apex class constructor
 * 08/02/2022 - Vinothraja   - SFTG-2365 Added code to bulkify logging during & after callouts
 * 23/08/2024 - Kai-Fan Hsieh - DANO-31 Added code to append channel field to comments
 */
public without sharing class FileToCallistaInterface extends UniCRMIntegrationPoint implements Database.AllowsCallouts {

    private static final String AGENT_PERSON_ID = Label.CALLISTA_AGENT_PERSON_ID;
    private static final String API_SOURCE = 'unicrm';
    private static final String API_TYPE = 'document';
    public String callistaApplicantId;
    public Id conDocumentId;
    public Contact_Document__c contactDocumentRec;
    public ContentDocumentLink contentDocumentLinkRec;
    public ContentDocument contentDocumentRec;
    public Application__c application;
    public List<Exception_Log__c> logs;

    /**
     * @author      Nitin/Shalini
     * @description Constructor
     * @param contactDocRec     The contact document record.
     * @param cdlRec            The content document link  record.
     * @param cdRec             The content document record.
     * @param callApplicantId   The ID of the callista applicant.
     * @param contactPersonID   The ID of the contact person.
     * @revision
     */
    public FileToCallistaInterface(String contactDocRec, String cdlRec, String cdRec, String callApplicantId, String contactPersonID) {
        //Initialize Callista File Insert config which brings the call out configuration
        this.doInit('IP09_Callista_File_Insert');
        callistaApplicantId = callApplicantId;
        contactDocumentRec = (Contact_Document__c) JSON.deserialize(contactDocRec, Contact_Document__c.class);
        contentDocumentLinkRec = (ContentDocumentLink) JSON.deserialize(cdlRec, ContentDocumentLink.class);
        contentDocumentRec = (ContentDocument) JSON.deserialize(cdRec, ContentDocument.class);
        logs = new List<Exception_Log__c> ();
        CallCallistaInterface();
    }

    /**
    * @author Steffi
    * @description Created this method to resolve the PMD issue
    */
    public void CallCallistaInterface() {
        try {
            if (this.jsonRequest != null) {
                contactDocumentRec.API_Request__c = JSON.serializePretty(this.jsonRequest);
            }
            createRequestBody();
        } catch (Exception ex) {
            logs.add(ExLog.writeExlog('FileToCallistaInterface', 'File / Files Integration', 'FileToCallistaInterface', '', ex));
        }
    }

    /**
     * @author      Nitin/Shalini
     * @description Method to create request body for the call out
     * @revision
     */
    public void createRequestBody() {
        try {
            ObdSendDocumentsServiceRequest reqJson = new ObdSendDocumentsServiceRequest();
            List<ObdSendDocumentsServiceRequest.AppDocument> docList = new List<ObdSendDocumentsServiceRequest.AppDocument>();

            //Create the wrapper instance
            ObdSendDocumentsServiceRequest.AppDocument appdoc = new ObdSendDocumentsServiceRequest.AppDocument();
            appdoc.agentPersonId = AGENT_PERSON_ID;
            appdoc.externalApplicantId = contactDocumentRec.Contact__c;
            appdoc.contentType = this.mapContentType(contentDocumentRec.FileExtension);
            appdoc.filename = StudFirst_Utilities.convertTo7BitAcceptedString(contactDocumentRec.Filename__c, '?');
            appdoc.id = contentDocumentRec.LatestPublishedVersionId;
            // Check if the Channel__c field on the contact document record is not null
            if (contactDocumentRec.Channel__c != null) {
                // Prepare the string to be appended with the channel information
                String contentToAppend = '[Channel: ' + contactDocumentRec.Channel__c + ']';
                // Convert the string to a 7-bit accepted format, replacing any non-accepted characters with '?'
                String convertedContentToAppend = StudFirst_Utilities.convertTo7BitAcceptedString(contentToAppend, '?');
                // If comments already has content, append the converted channel information
                if (contactDocumentRec.Comments__c != null) {
                    appdoc.comments = contactDocumentRec.Comments__c + ' ' + convertedContentToAppend;
                } else {
                    // If comments is null, assign it with the converted channel information
                    appdoc.comments = convertedContentToAppend;
                }
            }
            //contact document record id so that MIX can update the fields related to it in the response
            appdoc.applicationDocumentId = contactDocumentRec.Id;
            if (contactDocumentRec.Document_Type__c != 'PARENT_GUARDIAN') {
                appdoc.documentType = contactDocumentRec.Document_Type__c;
            } else {
                appdoc.documentType = null;
            }
            appdoc.applicantId = callistaApplicantId;
            docList.add(appdoc);
            reqJson.source = API_SOURCE;
            reqJson.sourceTime = String.valueOf(System.now());
            reqJson.type = API_TYPE;
            reqJson.events = docList;
            this.jsonRequest = reqJson;
        } catch (Exception ex) {
            logs.add(ExLog.writeExlog('FileToCallistaInterface', 'File / Files Integration', 'createRequestBody', '', ex));
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Map content type / mime type to callista compatible content type / mime types
     * @param fileExtension The file extension to be mapped.
     * @return A string representing the mapped content type/mime type.
     * @revision    04/06/2019 - Kristian Vegerano - Created
     */
    public String mapContentType(String fileExtension) {
        String contentType = '';

        if (String.isBlank(fileExtension)) {
            return '';
        }

        switch on fileExtension.toUpperCase() {
            when 'PDF' {
                contentType = 'application/pdf';
            }
            when 'DOC' {
                contentType = 'application/msword';
            }
            when 'DOCX' {
                contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            }
            when 'TXT' {
                contentType = 'text/plain';
            }
            when 'GIF' {
                contentType = 'image/gif';
            }
            when 'JPEG', 'JPG' {
                contentType = 'image/jpeg';
            }
            when 'PNG' {
                contentType = 'image/png';
            }
            when 'BMP' {
                contentType = 'image/bmp';
            }
            when 'TIFF', 'TIF' {
                contentType = 'image/tiff';
            }
            when else {
                contentType = 'application/octet-stream';
            }
        }
        return contentType;
    }

    /**
     * @author      Nitin/Shalini
     * @description Read the web service call response & update fields on the Contact Document
     *              records after the call out
     * @revision
    */
    public void handleResponse() {
        try {
            if (this.httpResponseCode == 200) { // successful callout.
                //2019/09/20 - update all the contact docs with file upload successful = true
                if (jsonRequest != null) {
                    contactDocumentRec.API_Request__c = JSON.serializePretty(jsonRequest);
                    contactDocumentRec.File_Upload_Successful__c = true;
                }
            }   //When call out is a failure
            else {
                logs.add(ExLog.writeExlog('FileToCallistaInterface', 'File / Files Integration', 'handleResponse', '', String.valueOf(this.httpResponseCode)));
            }
        } catch (Exception ex) {
            logs.add(ExLog.writeExlog('FileToCallistaInterface', 'File / Files Integration', 'handleResponse', '', ex.getMessage()));
        }
    }
}