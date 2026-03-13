/*******************************************************************************
* @author       Sethu Venna
* @date         04/11/2024
* @description  invoke callista interface v1/admissions/sms/documents to post HDR Docs
* @revision      
* 04/11/2024 - Sethu Venna - Created
* 21/10/2024 - DYU - MGROI-485 Scholarship only application
* 4/11/2024  - Vishal Gupta - Document request patch callout when the document is sent post application submission
*******************************************************************************/
public class GRSendDocumentToCallistaService extends UniCRMIntegrationPoint implements Database.AllowsCallouts {

    private static final String INTERFACE_NAME = 'IP10_GR_Callista_Doc_Insert';
    private static final String CALLISTA_APPLICANT_IDENTIFIER = 'smsApplicantId';
    private static final String TAG = 'Callista document callout';
    private static final String BLOB_REPLACEMENT_TEXT = '<blob explicitly removed for this payload due to length limitation of the field>';
    private static final String GRT_SCHOLARSHIP_APPLICATION_ONLY = 'Scholarship application only';
    private static final String GRADUATE_RESEARCH = 'Graduate Research';


    public Contact_Document__c contactDocumentRec;
    private ContentDocumentLink contentDocumentLinkRec;
    private ContentVersion contentVersionRec;

    /**
     * @author      Sethu Venna
     * @description Constructor
     * @param       contactDocumentRec
     * @param       contentDocumentLinkRec
     * @param       contentVersionRec
     * @revision    05/10/2024 - Initial Version
     */
    public GRSendDocumentToCallistaService (
        Contact_Document__c contactDocumentRec,
        ContentDocumentLink contentDocumentLinkRec,
        ContentVersion contentVersionRec
    ) 
    {
        this.doInit(INTERFACE_NAME);
        this.contactDocumentRec = contactDocumentRec;
        this.contentDocumentLinkRec = contentDocumentLinkRec;
        this.contentVersionRec = contentVersionRec;
    }

    /**
     * @author      Sethu Venna
     * @description creates request body for the call out
     * @revision    05/10/2024 - Initial Version
     */
    public void createRequestBody()
    { 
        try 
        {
            GRSendDocumentJSONClass reqJSON = new GRSendDocumentJSONClass();
            GRSendDocumentJSONClass.Cls_document docRequest = new GRSendDocumentJSONClass.Cls_document();
            Blob documentBlob = contentVersionRec.VersionData;
            docRequest.binaryString = EncodingUtil.base64Encode(documentBlob);
            docRequest.comment = StudFirst_Utilities.convertTo7BitAcceptedString(contactDocumentRec.Comments__c,'?');
            docRequest.contentType = mapContentType(contentDocumentLinkRec.ContentDocument.FileExtension);
            docRequest.filename = StudFirst_Utilities.convertTo7BitAcceptedString(contactDocumentRec.Filename__c,'?');
            docRequest.type = contactDocumentRec.Document_Checklist__r.Document_Type__c != null ? 
                              contactDocumentRec.Document_Checklist__r.Document_Type__c : 'OTHERDCTYP';
            GRSendDocumentJSONClass.Cls_additionalDetails additionalDetails = new GRSendDocumentJSONClass.Cls_additionalDetails();
            additionalDetails.name = CALLISTA_APPLICANT_IDENTIFIER;
            
            //MGROI-485 Pass the Parent Application Callista Id for Scholarship application only
            if(contactDocumentRec.Application__r.Type_of_Study__c == GRADUATE_RESEARCH 
                && contactDocumentRec.Application__r.Graduate_Research_Application_Type__c == GRT_SCHOLARSHIP_APPLICATION_ONLY
                && contactDocumentRec.Application__r.Parent_Application__c != null){
                    additionalDetails.value = contactDocumentRec.Application__r.Parent_Application__r.Callista_Applicant_Id__c; //maybe not needed
            }else{
                additionalDetails.value = contactDocumentRec.Application__r.Callista_Applicant_Id__c; // check if this value is still there
            }

            docRequest.additionalDetails = new List<GRSendDocumentJSONClass.Cls_additionalDetails>{(additionalDetails)};
            reqJSON.document = docRequest;
            this.jsonRequest = reqJson;
        }
        catch (Exception ex) 
        {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
    }

    /**
     * @author       Sethu Venna
     * @description  Map content type / mime type to callista compatible content type / mime types
     * @param        fileExtension
     * @return       converted content typeString
     * @revision     05/10/2024 - Initial Version
     */
    public String mapContentType(String fileExtension) 
    {
        String contentType = '';
        
        if (String.isBlank(fileExtension)) 
        {
            return '';
        }   

        switch on fileExtension.toUpperCase() 
        {
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
            when 'JPEG','JPG' {
                contentType = 'image/jpeg';
            }
            when 'PNG' {
                contentType = 'image/png';
            }
            when 'BMP' {
                contentType =  'image/bmp';
            }
            when 'TIFF','TIF' {
                contentType =  'image/tiff';
            }
            when else {
                contentType = 'application/octet-stream';
            }
        }
        return contentType;
    }

    /**
     * @author      Sethu Venna
     * @description Read the web service call response & update fields on the Contact Document
     *              records after the call out
     * @revision    05/10/2024 - Initial Version
    */
    public void handleResponse()
    {
        try 
        {
            if(jsonRequest != null)
            {
                GRSendDocumentJSONClass reqJSON = (GRSendDocumentJSONClass) jsonRequest;
                reqJSON.document.binaryString = (reqJSON.document.binaryString != null) ? BLOB_REPLACEMENT_TEXT : null;
                String jsonRequestString = JSON.serializePretty(reqJSON);
                contactDocumentRec.API_Request__c = jsonRequestString;
                Map<String,Object> respBody = this.getResponseBody();
                contactDocumentRec.API_Response__c = JSON.serializePretty(respBody);
                contactDocumentRec.Has_API_Response__c = true;
                contactDocumentRec.Has_API_Request__c = true;
                contactDocumentRec.Sync_In_Progress__c = false;
                contactDocumentRec.Last_sync_date_time__c = Datetime.now();
                if (this.httpResponseCode == 200) 
                { 
                    if(respBody.containsKey('document')) 
                    {
                        Map<String,Object> respDocBody = (Map<String,Object>) respBody.get('document');
                        String docId = String.valueOf(respDocBody.get('id'));
                        contactDocumentRec.Callista_Document_Id__c = docId;
                        contactDocumentRec.File_Upload_Successful__c = true;
                        contactDocumentRec.Document_Status__c = true;

                        //if the document is submitted post submission, then a Document Patch is required to send to callista
                        if(contactDocumentRec.Post_Submission__c) {
                            GRDocumentRequestPatchToCallistaService docReqPatchService = new GRDocumentRequestPatchToCallistaService(
                                contactDocumentRec,
                                docId
                            );
                            docReqPatchService.createRequestBody();
                            docReqPatchService.sendMessage();
                            docReqPatchService.handleResponse();
                        }
                        Nebula.logger.info('docId returned from callista: ' + docId).addTag(TAG);
                    }
                }
                else 
                {
                    Nebula.Logger.info('Response from GRSendDocumentToCallistaService: '+string.valueOf(this.httpResponseCode)).addTag(TAG);
                }
            }
        }
        catch (Exception ex) 
        {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
    }
}