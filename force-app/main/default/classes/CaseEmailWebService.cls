/**
 * @author Tom Gangemi
 * @date July.2023
 * @testclass CaseEmailService_Test
 * @revision
 *     2023-07-12 - Tom Gangemi - SA-2339 - Case Email Web Service Initial Version
 * @description A REST web service for send emails and logging copies of them against cases
 **/

@RestResource(UrlMapping='/CaseEmailService/v1/*')
global with sharing class CaseEmailWebService {
    public class RequestException extends Exception {}
    public final static String ACTION_SEND_EMAIL = 'SendEmail';
    final static Set<String> actions = new Set<String>{ACTION_SEND_EMAIL};

    // error messages
    public final static String ERROR_INVALID_ACTION = 'Invalid action';
    public final static String ERROR_MISSING_BODY = 'htmlBody is required';
    public final static String ERROR_MISSING_SUBJECT = 'subject is required';
    public final static String ERROR_MISSING_FROM_ADDRESS = 'fromAddress is required';
    public final static String ERROR_MISSING_TO_ADDRESSES = 'toAddresses is required';
    public final static String ERROR_BLANK_TO_ADDRESS = 'toAddress cannot be blank';
    public final static String ERROR_INVALID_CASE_ID = 'invalid caseIds value: ';
    public final static String ERROR_INVALID_REPLY_TO_CASE_ID = 'invalid replyToCaseId: ';
    public final static String ERROR_INVALID_CONTENT_DOCUMENT_ID = 'invalid contentDocumentId: ';

    public class Request {
        public EmailMessageRequest[] emails;
    }

    public class EmailMessageRequest {
        public String htmlBody;
        public String subject;
        public String fromAddress;
        public String[] toAddresses;
        public String[] ccAddresses; // optional
        public String[] bccAddresses; // optional
        public Id[] caseIds; // optional
        public Id replyToCaseId; // optional
        public Id[] contentDocumentIds; // optional
    }

    /**
     * Entry point handles processing of JSON request/response and routing to action
     */
    @HttpPost
    global static void handlePost() {
        RestRequest restReq = RestContext.request;
        RestResponse restRes = RestContext.response;

        // get action from URI
        String[] uriParts = restReq.requestURI.split('/');
        String action = uriParts[uriParts.size()-1];

        try {
            Request req = (Request)JSON.deserialize(restReq.requestBody.toString(), Request.class);

            validateRequest(req, action);

            // route to action
            if(action == ACTION_SEND_EMAIL) {
                sendEmails(req.emails);
            }

            restRes.statusCode = 200;
        } catch (JSONException e) {
            restRes.statusCode = 400;
            restRes.responseBody = createErrorBody('Invalid request body: ' + e.getMessage());
        } catch (RequestException e) {
            restRes.statusCode = 400;
            restRes.responseBody = createErrorBody(e.getMessage());
        } catch (Exception e) {
            restRes.statusCode = 500;
            restRes.responseBody = createErrorBody('Internal server error: ' + e.getMessage() + e.getStackTraceString());
        }
    }

    private static Blob createErrorBody(String msg) {
        return Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => msg}));
    }

    @TestVisible private static void validateRequest(Request req, String action) {
        if(!actions.contains(action)) {
            throw new RequestException(ERROR_INVALID_ACTION);
        }

        for(EmailMessageRequest em :req.emails) {
            if(String.isBlank(em.htmlBody)) {
                throw new RequestException(ERROR_MISSING_BODY);
            }
            if(String.isBlank(em.subject)) {
                throw new RequestException(ERROR_MISSING_SUBJECT);
            }
            if(String.isBlank(em.fromAddress)) {
                throw new RequestException(ERROR_MISSING_FROM_ADDRESS);
            }
            if(em.toAddresses == null || em.toAddresses.size() == 0) {
                throw new RequestException(ERROR_MISSING_TO_ADDRESSES);
            }
            for(String toAddress : em.toAddresses) {
                if(String.isBlank(toAddress)) {
                    throw new RequestException(ERROR_BLANK_TO_ADDRESS);
                }
            }
            if(em.caseIds != null) {
                for(Id caseId : em.caseIds) {
                    if(caseId == null || caseId.getSobjectType() != Case.SObjectType) {
                        throw new RequestException(ERROR_INVALID_CASE_ID + caseId);
                    }
                }
            }
            if(em.replyToCaseId != null && em.replyToCaseId.getSobjectType() != Case.SObjectType) {
                throw new RequestException(ERROR_INVALID_REPLY_TO_CASE_ID + em.replyToCaseId);
            }
            if(em.contentDocumentIds != null) {
                for(Id cdId :em.contentDocumentIds) {
                    if(cdId == null || cdId.getSobjectType() != ContentDocument.SObjectType) {
                        throw new RequestException(ERROR_INVALID_CONTENT_DOCUMENT_ID + cdId);
                    }
                }
            }
        }
    }

    private static void sendEmails(EmailMessageRequest[] emails) {
        // collect ids for queries
        Set<String> fromAddresses = new Set<String>();
        Set<Id> contentDocumentIds = new Set<Id>();
        for(EmailMessageRequest em : emails) {
            em.fromAddress = em.fromAddress.toLowerCase();
            fromAddresses.add(em.fromAddress);
            if(em.contentDocumentIds != null) {
                contentDocumentIds.addAll(em.contentDocumentIds);
            }
        }

        // retrieve org wide addresses
        Map<String,Id> orgWideAddressIdsByAddress = new Map<String,Id>();
        for(OrgWideEmailAddress owea :[
            SELECT Id, Address FROM OrgWideEmailAddress WHERE Address IN :fromAddresses
        ]) {
            orgWideAddressIdsByAddress.put(owea.Address.toLowerCase(), owea.Id);
        }
        fromAddresses.removeAll(orgWideAddressIdsByAddress.keySet());
        if(fromAddresses.size() > 0) {
            throw new RequestException('OrgWideEmailAddresses not found: ' + String.join(fromAddresses, ', '));
        }

        // retrieve content doc version ids
        Map<Id,Id> contentVersionIdsByContentDocumentId = new Map<Id,Id>();

        if(contentDocumentIds.size() > 0) {
            for(ContentDocument cd : [
                SELECT LatestPublishedVersionId
                FROM ContentDocument WHERE Id IN :contentDocumentIds
            ]){
                contentVersionIdsByContentDocumentId.put(cd.Id, cd.LatestPublishedVersionId);
            }
        }

        // create emails
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>(); // outbound emails
        List<EmailMessage> emailsToLink = new List<EmailMessage>(); // emails that are just a log of the outbound email
        List<List<ContentDocumentLink>> emailsToLinkAttachments = new List<List<ContentDocumentLink>>(); // attachments to link to the log email
        Integer dbgCounter = 0;
        for(EmailMessageRequest emr :emails) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            emailsToSend.add(message);

            message.setHtmlBody(emr.htmlBody);
            message.setSubject(emr.subject);
            message.setOrgWideEmailAddressId(orgWideAddressIdsByAddress.get(emr.fromAddress.toLowerCase()));
            message.setToAddresses(emr.toAddresses);
            message.setCcAddresses(emr.ccAddresses);
            message.setBccAddresses(emr.bccAddresses);

            if (emr.caseIds == null) emr.caseIds = new Id[0];

            // link the outgoing email to a case
            if(emr.replyToCaseId != null) {
                // replyToCaseId is present - link to case and generate a thread identifier
                message.setReferences(Cases.generateThreadingMessageId(emr.replyToCaseId));
                Integer indx = emr.caseIds.indexOf(emr.replyToCaseId);
                if(indx >= 0) {
                    emr.caseIds.remove(indx);
                }
            }
            else if(emr.caseIds.size() > 0) {
                // only caseIds are present - link to emr.caseIds[0] but don't add thread identifier (will not receive replies)
                message.setWhatId(emr.caseIds.remove(0));
            }

            ContentDocumentLink[] attachments = new ContentDocumentLink[0];
            if(emr.contentDocumentIds != null) {
                // add attachments
                Id[] contentVersionIds = new Id[0];
                for(Id cdId : emr.contentDocumentIds) {
                    contentVersionIds.add(contentVersionIdsByContentDocumentId.get(cdId));
                    attachments.add(new ContentDocumentLink(ContentDocumentId = cdId));
                }
                message.setEntityAttachments(contentVersionIds);
            }

            // emObj is just a log of the email and not an actual send
            EmailMessage emObj = new EmailMessage();
            emObj.FromAddress = emr.fromAddress;
            emObj.ToAddress = String.join(emr.toAddresses, ',');
            if(emr.ccAddresses != null) {
                emObj.CcAddress = String.join(emr.ccAddresses, ',');
            }
            if(emr.bccAddresses != null) {
                emObj.BccAddress = String.join(emr.bccAddresses, ',');
            }
            emObj.Subject = emr.subject;
            emObj.HtmlBody = emr.htmlBody;
            emObj.Incoming = false;

            for(Id caseId : emr.caseIds) {
                System.debug(dbgCounter++ + ' - ' + caseId + ' - ' + emr.replyToCaseId);
                // store a copy of the email against each case that isn't linked by references or whatId
                EmailMessage caseEm = emObj.clone();
                caseEm.ParentId = caseId;
                emailsToLink.add(caseEm);
                emailsToLinkAttachments.add(attachments);
            }
        }

        Messaging.sendEmail(emailsToSend);
        insert emailsToLink;

        ContentDocumentLink[] attachmentLinks = new ContentDocumentLink[0];
        for(Integer i = 0; i < emailsToLink.size(); i++) {
            EmailMessage em = emailsToLink[i];
            for(ContentDocumentLink cdl : emailsToLinkAttachments[i]) {
                cdl.LinkedEntityId = em.Id;
                attachmentLinks.add(cdl);
            }
        }

        insert attachmentLinks;
    }

}