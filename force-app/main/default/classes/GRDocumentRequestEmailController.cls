/*******************************************************************************
* @author       Vishal Gupta
* @date         5/12/2024
* @description  when GR student uploads the document and submitted to callista, then it will notify the assessor with the uploaded document information 
* @revision      
* 5/12/2024 - Vishal Gupta - Created
*******************************************************************************/
public with sharing class GRDocumentRequestEmailController implements IPlatformEventInvocable {
    public String applicantName;
    public String personId;
    public String applicationId;
    public String applicationType;
    public String courseTitle;
    public String documentType; 
    public String recipientEmail;
    public static Boolean isSuccess;

    /**
     * @author      Vishal Gupta
     * @description form the email body and send the email to the notify email addresses in document checklist comment for Grad Research 
     * @revision    5/12/2024 - Initial Version
    */
    @InvocableMethod(label='Doc request email invocable' description='sending the email when the grad research student upload the document on document request')
    public static void sendEmail(List<String> payload) {
        GRDocumentRequestEmailController emailParams = new GRDocumentRequestEmailController();
        if(payload != null && !payload.isEmpty()) {
            emailParams = (GRDocumentRequestEmailController) JSON.deserialize(payload[0], GRDocumentRequestEmailController.class);
        }
        try {
            OrgWideEmailAddress orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'mgro-apply@f.e.monash.edu' LIMIT 1];

            String emailBody = 'Dear Higher DREAMS application assessor,<br><br>';
            emailBody += 'The document requested by you or on your behalf has been uploaded by the following applicant:<br><br>';
            emailBody += 'Applicant Name: ' + emailParams.applicantName + '<br>';
            emailBody += 'Applicant Person ID: ' + emailParams.personId + '<br>';
            emailBody += 'Application ID: ' + emailParams.applicationId + '<br>';
            emailBody += 'Application Type: ' + emailParams.applicationType + '<br>';
            emailBody += 'Application Course Title: ' + emailParams.courseTitle + '<br><br>';
            
            emailBody += 'Please return to the application in Callista, review the document provided and proceed with assessment of the application.<br><br>';
            
            emailBody += 'Document Provided: ' +emailParams.documentType+ '<br><br>';
            
            emailBody += 'Sincerely,<br>';
            emailBody += 'Admissions Team<br>';
            emailBody += 'Monash Graduate Research Office<br>';
            emailBody += 'Monash University';

            // Send the email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { emailParams.recipientEmail });
            mail.setOrgWideEmailAddressId(orgWideAddress.Id);

            mail.setSubject('Document Uploaded for Application '+emailParams.applicationId);
            mail.setHtmlBody(emailBody);
            nebula.Logger.info('enter email');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            nebula.Logger.info('success');
            isSuccess = true;
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            isSuccess = false;
        }
    }

     /*
     * @description  Subscriber to the event Async_Process__e to run
     */
    public void execute(List<AsyncProcessPayload> payloads) {
        //do nothing, this method is just mandatory for the interface IPlatformEventInvocable
    }
}