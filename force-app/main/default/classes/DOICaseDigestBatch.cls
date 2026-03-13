/**
 * @author Tom Gangemi
 * @date Jan.2022
 * @group Batch Class
 * @revision
 *     2023-10-04 - SA-2372 - Tom Gangemi - DoI 2023 Refresh Updates
 *
 * @description This batch class is used to send daily digest emails of new declaration of interest cases.
 * Each owner and case team member is sent a single email containing all the previous day's cases.
 */
public without sharing class DOICaseDigestBatch implements Database.Batchable<EmailDigestUtilities.Digest>, Database.Stateful, Schedulable {

    @TestVisible private final static String DOI_RECORD_TYPE = 'Declaration_of_Interest';
    @TestVisible private final static String EMAIL_TEMPLATE_NAME = Label.DOI_Digest_Email_Template_Name;
    @TestVisible private final static String FROM_ADDRESS_NAME = Label.DOI_Digest_Email_From_Address_Name;
    @TestVisible private final static String NO_DIGEST_GROUP = 'DoI_Digest_Do_Not_Send';
    @TestVisible private final static Boolean IS_MONDAY = ((Datetime)Date.today()).format('u') == '1';

    @TestVisible private final static String ENQ_TYPE_HR_DOI_SUBMISSION = 'HR DOI Submission';
    @TestVisible private final static String ENQ_TYPE_HR_DOI = 'HR DOI';
    @TestVisible private final static String EX_LOG_LOG_TYPE = 'DOICaseDigestBatchLog';
    @TestVisible private final static String EX_LOG_ERR_TYPE = 'DOICaseDigestBatchError';

    // digestMailer will remain a single instance for a unit test but will be recreated for each batch
    @TestVisible private static EmailDigestUtilities.Mailer digestMailer = new EmailDigestUtilities.LiveMailer();
    @TestVisible private final Map<String, Object> sentMergeDataByEmail = new Map<String, Object>();
    @TestVisible private final Map<String, Object> failedMergeDataByEmail = new Map<String, Object>();
    private Map<String, Object> commonMergeData;

    private EmailTemplate htmlTemplate;
    private OrgWideEmailAddress fromAddress;

    public void execute(SchedulableContext sc) {
        DOICaseDigestBatch batchDigest = new DOICaseDigestBatch();
        Database.executeBatch(batchDigest,50);
    }

    /**
     * Batch Start
     */
    public Iterable<EmailDigestUtilities.Digest> start(Database.BatchableContext bc) {
        // Get email template
        List<EmailTemplate> templates = [
            SELECT HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = :EMAIL_TEMPLATE_NAME
        ];
        if(templates.isEmpty()) {
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Email Template Missing - ' + EMAIL_TEMPLATE_NAME);
            throw ex;
        }
        htmlTemplate = templates[0];
        htmlTemplate.Subject = new HmlTool.Context(
            new Map<String, Object>{'Today'=>Datetime.now().format('d MMMM yyyy')}
        ).render(htmlTemplate.Subject);

        // Get from address
        List<OrgWideEmailAddress> orgWideAddresses = [
            SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = :FROM_ADDRESS_NAME
        ];
        if(orgWideAddresses.isEmpty()) {
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Org Wide Email Address Missing - ' + FROM_ADDRESS_NAME);
            throw ex;
        }
        fromAddress = orgWideAddresses[0];

        // set common template merge data
        this.commonMergeData = new Map<String, Object>{
            'BaseUrl' => Url.getOrgDomainUrl().toExternalForm()
        };

        // https://unicrm--gcpqa.sandbox.lightning.force.com/lightning/app/c__Service_Console_Lite/o/Case/list?filterName=DoI_Review_Declaration
        // https://unicrm--gcpqa.sandbox.lightning.force.com/lightning/n/Declaration_of_Interest_Overview
        // https://unicrm--gcpqa.sandbox.lightning.force.com/lightning/app/c__Service_Console_Lite/n/Declaration_of_Interest_Overview

        // Get cases
        Map<Id,Case> cases = getCases();

        // Create digests
        Map<Id, EmailDigestUtilities.Digest> digestsByUserId = createUserDigests(cases);

        removeDigestsForDoNotSendUsers(digestsByUserId);

        return digestsByUserId.values();
    }

    /**
    * Batch Process
    */
    public void execute(Database.BatchableContext bc, List<EmailDigestUtilities.Digest> digests) {
        // Query the user info required for merge fields in the email template
        Id[] userIds = new Id[0];
        for(EmailDigestUtilities.Digest di :digests) {
            userIds.add(di.userId);
        }
        Map<Id, User> usersById = new Map<Id, User>([
            SELECT FirstName, LastName, Full_Name__c, Email FROM User WHERE Id IN :userIds
        ]);
        for(EmailDigestUtilities.Digest di :digests) {
            di.user = usersById.get(di.userId);
        }
        sendEmails(digests, htmlTemplate, fromAddress, this.commonMergeData);
    }

    public void finish(Database.BatchableContext bc) {
        EmailDigestUtilities.insertLog(
            EX_LOG_LOG_TYPE,
            'DOICaseDigestBatch.finish',
            JSON.serializePretty(new Map<String,Object>{
                'Sent' => sentMergeDataByEmail.keySet(),
                'Failed' => failedMergeDataByEmail.keySet()
            }),
            JSON.serializePretty(new Map<String,Object>{
                'Sent' => sentMergeDataByEmail,
                'Failed' => failedMergeDataByEmail
            })
        );
    }

    public static final Set<String> STAGES_REQ_ACTION = new Set<String>{
        'Review Declaration', 'Review Management Plan','Review Response (Management Plan)'
    };

    /**
     * Returns open cases or auto-closed (Response_Required__c) cases that have been closed within the last working day
     */
    @TestVisible
    private static Map<Id,Case> getCases() {
        // if this is being run on monday, extend the cutoff to 72 hours
        Integer closedCutoffHours = IS_MONDAY ? -72 : -24;
        Datetime closedCutoff = Datetime.now().addHours(closedCutoffHours);

        return new Map<Id,Case>([
            SELECT OwnerId, Enquiry_Type__c, IsClosed, Response_Required__c, Case_Stage__c FROM Case
            WHERE
                RecordType.DeveloperName = :DOI_RECORD_TYPE
                AND
                (Enquiry_Type__c = :ENQ_TYPE_HR_DOI_SUBMISSION OR Enquiry_Type__c = :ENQ_TYPE_HR_DOI)
                AND
                (Case_Stage__c IN :STAGES_REQ_ACTION OR ClosedDate >= :closedCutoff)
        ]);
    }

    @TestVisible
    private static Map<Id, EmailDigestUtilities.Digest> createUserDigests(Map<Id, Case> cases) {
        Map<Id, EmailDigestUtilities.Digest> digestsByUserId = new Map<Id, EmailDigestUtilities.Digest>();

        // Collect cases by owner
        for(Case c :cases.values()) {
            if(c.OwnerId.getSobjectType() == User.getSObjectType()) {
                if(digestsByUserId.containsKey(c.OwnerId)) {
                    digestsByUserId.get(c.OwnerId).casesById.put(c.Id, c);
                } else {
                    digestsByUserId.put(c.OwnerId, new EmailDigestUtilities.Digest(c.OwnerId, new Case[]{c}));
                }
            }
        }

        return digestsByUserId;
    }

    @TestVisible
    private static void removeDigestsForDoNotSendUsers(Map<Id, EmailDigestUtilities.Digest> digestsByUserId) {
        // Remove digests for users who have opted out of receiving them
        for(GroupMember member :[SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = :NO_DIGEST_GROUP]) {
            digestsByUserId.remove(member.UserOrGroupId);
        }
    }

    public final static String MERGE_KEY_OPEN = 'OpenCases';
    public final static String MERGE_KEY_CLOSED = 'ClosedCases';
    public final static String MERGE_KEY_NOTHING = 'NothingToDeclare';
    public final static String MERGE_KEY_NO_ACTION = 'NoActionRequired';

    /**
     * Given a digest, create the merge data for the email template
     * This involves creating various tallies of cases based on their properties
     */
    public static Map<String, Object> createMergeData(EmailDigestUtilities.Digest digest) {
        Integer openCases = 0;
        Integer nothingCases = 0;
        Integer noActionCases = 0;

        for(Case c :digest.casesById.values()) {
            if(c.IsClosed) {
                if(c.Enquiry_Type__c == ENQ_TYPE_HR_DOI_SUBMISSION) {
                    nothingCases++;
                } else if(c.Enquiry_Type__c == ENQ_TYPE_HR_DOI && c.Response_Required__c == 'No') {
                    noActionCases++;
                }
            } else if (!c.IsClosed && STAGES_REQ_ACTION.contains(c.Case_Stage__c)) {
                openCases++;
            }
        }

        return new Map<String, Object>{
            MERGE_KEY_OPEN => openCases,
            MERGE_KEY_NOTHING => nothingCases,
            MERGE_KEY_NO_ACTION => noActionCases,
            MERGE_KEY_CLOSED => nothingCases + noActionCases
        };
    }

    @TestVisible
    private void sendEmails(
        List<EmailDigestUtilities.Digest> digests,
        EmailTemplate et,
        OrgWideEmailAddress owea,
        Map<String, Object> commonMergeData
    ) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

        Map<String,Object> mergeDataByEmail = new Map<String,Object>();
        for(EmailDigestUtilities.Digest di : digests) {
            if(di.user == null) continue;

            // create Case count merge data
            Map<String, Object> mergeData = createMergeData(di);
            if((Integer)mergeData.get(MERGE_KEY_OPEN) == 0 && (Integer)mergeData.get(MERGE_KEY_CLOSED) == 0) {
                // only send the email if there is a count
                continue;
            }
            mergeDataByEmail.put(di.user.Email, mergeData.clone()); // for logging

            mergeData.putAll(commonMergeData);
            mergeData.put('Recipient', di.user.getPopulatedFieldsAsMap());

            // create email message
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject(et.Subject);
            mail.setHtmlBody(new HmlTool.Context(mergeData).render(et.HtmlValue));
            mail.setTargetObjectId(di.userId);
            mail.setTreatTargetObjectAsRecipient(true);
            mail.setSaveAsActivity(false);
            mail.setOrgWideEmailAddressId(owea.Id);
            messages.add(mail);
        }

        try {
            digestMailer.sendEmail(messages);
            sentMergeDataByEmail.putAll(mergeDataByEmail);
        } catch (Exception e) {
            System.debug(e.getMessage());
            Exception_Log__c exLog = new Exception_Log__c();
            exLog.Source_Type__c = EX_LOG_ERR_TYPE;
            exLog.Function_Name__c = 'DOICaseDigestBatch.sendEmails';
            exLog.Exception_Type__c = e.getTypeName();
            exLog.Message__c = e.getMessage();
            exLog.Stack_Trace__c = e.getStackTraceString();
            exLog.CurrentUser__c = UserInfo.getUserId();
            Map<Id,User> usersById = new Map<Id,User>();
            for(EmailDigestUtilities.Digest di : digests) {
                usersById.put(di.userId, di.user);
            }
            exLog.Input__c = JSON.serializePretty(usersById);
            insert exLog;
            failedMergeDataByEmail.putAll(mergeDataByEmail);
        }
    }
}