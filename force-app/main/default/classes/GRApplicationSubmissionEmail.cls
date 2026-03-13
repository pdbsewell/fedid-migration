/*******************************************************************************
* @author       Vishal Gupta
* @date         05/05/2025
* @description  send the email to the notify applicant when they submit the GR application
* @revision      
* 05/05/2025 - Vishal Gupta - Created
*******************************************************************************/
public with sharing class GRApplicationSubmissionEmail implements IPlatformEventInvocable {
    public String recipientEmail;
    public String firstName;
    public String fullName;
    public String callistaApplicantId;
    public String applicationId;
    public String gradResCallistaId;
    public String gradResAppType;
    public String proposedCommencementDate;
    public String course;
    public String submitedDate;
    public static Boolean isSuccess;
    public String monashPersonId;

    /**
     * @author      Vishal Gupta
     * @description send the email to the notify applicant when they submit the GR application 
     * @revision    05/05/2025 - Initial Version
    */
    @InvocableMethod(label='Doc request email invocable' description='sending the email when the grad research application successfully lands in Callista')
    public static void sendApplicationConfirmationEmail(List<String> payload) {
        isSuccess = true; // assume success unless error occurs
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        try {
            // Query Org-Wide Email Address only once
            OrgWideEmailAddress orgWideAddress = [
                SELECT Id 
                FROM OrgWideEmailAddress 
                WHERE Address = 'mgro-apply@f.e.monash.edu' 
                LIMIT 1
            ];

            for (String emailData : payload) {
                if (String.isBlank(emailData)) continue;

                GRApplicationSubmissionEmail emailParams = 
                    (GRApplicationSubmissionEmail) JSON.deserialize(emailData, GRApplicationSubmissionEmail.class);

                String subject = 'Monash Graduate Research Online Application submission confirmation';

                String body = '<p>Dear ' + emailParams.firstName + ',</p>' +
                    '<p>Thank you for considering undertaking a research degree at Monash University. Your application has been submitted to the Monash Graduate Research Admissions Team. The details of your application and the documents you have provided will be reviewed and forwarded to the appropriate academic unit/faculty for assessment.</p>' +
                    '<p>Following is a summary of your application:</p>' +
                    '<ul>' +
                    '<li>Applicant Name: ' + emailParams.fullName + '</li>' +
                    '<li>Monash Person ID: ' + emailParams.monashPersonId + '</li>' +
                    '<li>Application ID: ' + emailParams.applicationId + '</li>' +
                    '<li>Application Type: Graduate Research ' + emailParams.gradResAppType + '</li>' +
                    '<li>Proposed Commencement Date: ' + emailParams.proposedCommencementDate + '</li>' +
                    '<li>Proposed Course: ' + emailParams.course + '</li>' +
                    '<li>Application Submission Date (Australia/Melbourne Time): ' + emailParams.submitedDate + '</li>' +
                    '</ul>' +
                    '<p>You can review your application at any time by logging back into the My.App portal selecting the submitted tab, and choosing the corresponding application. Once submitted an application cannot be modified. Also, please be reminded that you may only submit one application per admission period. Please note your application will be assessed in accordance with the standard processing times as outlined at ' +
                    '<a href="https://www.monash.edu/graduate-research/future-students/apply">https://www.monash.edu/graduate-research/future-students/apply</a>.</p>' +
                    '<p>If you have any questions or concerns please contact <a href="mailto:mgro-apply@monash.edu.au">mgro-apply@monash.edu.au</a> quoting your <strong>Monash Person ID</strong>.</p>' +
                    '<p>Sincerely,<br/>' +
                    'Admissions Team<br/>' +
                    'Monash Graduate Research Office<br/>' +
                    'Monash University</p>' +
                    '<hr/>' +
                    '<p style="font-size:small;color:gray;">Additionally, the letter acknowledges and pays respects to the Elders and Traditional Owners of the land on which Monash University’s Australian campuses stand. For more information, visit the website for <a href="https://www.monash.edu/about/indigenous">Indigenous Australians</a>.</p>';

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { emailParams.recipientEmail });
                mail.setSubject(subject);
                mail.setOrgWideEmailAddressId(orgWideAddress.Id);
                mail.setHtmlBody(body);

                emailsToSend.add(mail);
            }

            if (!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
                nebula.Logger.info('GRApplicationSubmissionEmail - ' + emailsToSend.size() + ' emails sent successfully');
            }
        }catch(Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            isSuccess = false;
        }
        nebula.Logger.saveLog();
    }
    /*
     * @description  Subscriber to the event Async_Process__e to run
     */
    public void execute(List<AsyncProcessPayload> payloads) {
        //do nothing, this method is just mandatory for the interface IPlatformEventInvocable
    }
}