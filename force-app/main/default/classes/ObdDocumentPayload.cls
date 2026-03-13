/*******************************************************************************
 * @author       Shalini mendu
 * @date         18 June 2019
 * @description  Payload request and response for URI '/v1/CRMDocumentSubmit/*'
 * @revision
 * 27-07-2023   Ken McGuire     Added documentChecklistId and documentType for APNG
 *******************************************************************************/
global class ObdDocumentPayload {

    //Payload Request wrapper for the webservice
    global class ObdDocumentPayloadRequest
    {
        global String agentPersonId {get;set;}
        global String externalApplicantId {get;set;}
        global String applicationId {get;set;}
        global String documentChecklistId {get;set;}
        global String documentType {get;set;}
        global String contentType {get;set;}
        global String fileName {get;set;}
        global String binaryString {get;set;}
        global String comments {get;set;}
    }

    //Payload Response wrapper for the webservice
    global class ObdDocumentPayloadResponse
    {
        global String status {get;set;}
        global String error {get;set;}
    }
}