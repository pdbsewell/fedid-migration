/**
 * @author      Tom Gangemi
 * @date        2023-06-12
 * @testclass   ChiefExaminerDigestEmailBatch_Test
 * @group       Batch
 * @description Send summary of pending and recently approved SpecCon cases to Chief Examiners
 * @history     2024-02-12 - SA-2508 - Remove afternoon and weekend Sends + Template Changes
 **/

public with sharing class ChiefExaminerDigestEmailBatch implements Database.Batchable<EmailDigestUtilities.Digest>, Database.Stateful, Schedulable  {

    public final static String PUBLIC_GROUP = 'Spec_Con_Reviewer_Academics';
    public final static String SPEC_CON_ENQUIRY_TYPE = 'Special Consideration';
    public final static String SPEC_CON_RT_NAME = 'Special_Consideration';
    public final static String CL1_SHORT_EXTENSION = 'Short Extension';
    public final static String CL1_SPECIAL_CONSIDERATION = 'Special Consideration';

    private EmailTemplate emailTemplate;
    private OrgWideEmailAddress fromAddress;
    private String bccAddress; // all digests are BCCed to this address
    private final Map<String, Object> commonMergeData = new Map<String, Object>();
    private final Boolean showClosedCases;
    private final Integer daysToInclude;

    @TestVisible private static EmailDigestUtilities.Mailer mailer = new EmailDigestUtilities.LiveMailer();

    @TestVisible private static final String MERGE_KEY_ALL_OPEN = 'AllOpen';
    @TestVisible private static final String MERGE_KEY_NO_OUTCOME = 'NoOutcome';
    @TestVisible private static final String MERGE_KEY_MOODLE_NOT_UPDATED = 'MoodleNotUpdated';
    @TestVisible private static final String MERGE_KEY_ALL_CLOSED = 'AllClosed';

    @TestVisible private final static String EX_LOG_LOG_TYPE = 'SpecConDigestBatchLog';
    @TestVisible private final static String EX_LOG_ERR_TYPE = 'SpecConDigestBatchError';
    @TestVisible private final Map<String, Object> sentMergeDataByEmail = new Map<String, Object>();
    @TestVisible private final Map<String, Object> failedMergeDataByEmail = new Map<String, Object>();

    public ChiefExaminerDigestEmailBatch() {
        this.showClosedCases = true;
        this.daysToInclude = 1;
    }

    public ChiefExaminerDigestEmailBatch(Boolean showClosedCases, Integer daysToInclude) {
        this.showClosedCases = showClosedCases;
        this.daysToInclude = daysToInclude;
    }

    /**
     * Get all the SpecCon cases that are open or have been closed in the last (24 * daysToInclude) hours
     */
    public static Case[] getCases(Set<Id> ownerIds, Set<String> emailAddresses, Integer daysToInclude) {
        Datetime cutoff = Datetime.now().addHours(-24 * daysToInclude);
        return [
            SELECT OwnerId, Case_Outcome__c, IsClosed, CreatedDate, Category_Level_1__c, Supplied_Supervisors_Email__c,
                (SELECT Origin__c, Is_Closed_On_Create__c, Assessment_Type__c,
                    Moodle_Integration_Status__c, Moodle_Assessment_ID__c
                FROM Case_Unit_Attempt__r)
            FROM Case
            WHERE RecordType.DeveloperName = :SPEC_CON_RT_NAME AND
                Origin IN('Web - Monash Forms', 'SEBS') AND
                Enquiry_Type__c = :SPEC_CON_ENQUIRY_TYPE AND
                (OwnerId IN :ownerIds OR Supplied_Supervisors_Email__c IN :emailAddresses) AND
                Category_Level_1__c IN (:CL1_SHORT_EXTENSION, :CL1_SPECIAL_CONSIDERATION) AND
                (IsClosed = FALSE OR (ClosedDate >= :cutoff AND Case_Outcome__c LIKE 'Approved%'))
        ];
    }

    /**
     * Setup state and create the digests
     */
    public Iterable<EmailDigestUtilities.Digest> start(Database.BatchableContext bc) {

        // get email template name
        System_Settings__mdt templateNameSetting = SystemSettingsUtil.getInstance().getByName('SPEC_CON_DIGEST_TEMPLATE_NAME');
        String templateName = templateNameSetting != null ? templateNameSetting.Value__c : null;

        // set email template
        List<EmailTemplate> templates = [
            SELECT HtmlValue, Subject FROM EmailTemplate
            WHERE DeveloperName = :templateName
        ];
        if(templates.isEmpty()) {
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Email Template Missing - ' + templateName);
            throw ex;
        }
        this.emailTemplate = templates[0];

        // get from address
        System_Settings__mdt fromAddressSetting = SystemSettingsUtil.getInstance().getByName('SPEC_CON_DIGEST_FROM_ADDRESS');
        String fromAddress = fromAddressSetting != null ? fromAddressSetting.Value__c : null;

        // set from address
        List<OrgWideEmailAddress> orgWideAddresses = [
            SELECT Id FROM OrgWideEmailAddress WHERE Address = :fromAddress
        ];
        if(orgWideAddresses.isEmpty()) {
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Org Wide Email Address Missing - ' + fromAddress);
            throw ex;
        }
        this.fromAddress = orgWideAddresses[0];

        // set BCC address
        System_Settings__mdt bccEmailSetting = SystemSettingsUtil.getInstance().getByName('SPEC_CON_DIGEST_BCC_ADDRESS');
        this.bccAddress = bccEmailSetting != null ? bccEmailSetting.Value__c : null;

        // set common template merge data
        this.commonMergeData.put(
            'ServiceConsoleLiteUrl', [SELECT StartUrl FROM AppMenuItem WHERE Name = 'Service_Console_Lite']?.StartUrl
        );
        String listViewId = [SELECT Id FROM ListView WHERE DeveloperName = 'My_Cases']?.Id;
        this.commonMergeData.put(
            'ListViewUrl', Url.getOrgDomainUrl().toExternalForm()+'/lightning/o/Case/list?filterName=' + listViewId
        );
        this.commonMergeData.put('ShowRecentlyProcessedSection', showClosedCases);

        // get all the users in the public group
        Set<Id> userIds = new Set<Id>();
        Map<String,Id> userIdsByEmail = new Map<String,Id>(); // using separate map in case there is a duplicate email
        for(User u :[
            SELECT Email FROM User
            WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = :PUBLIC_GROUP)
        ]) {
            userIds.add(u.Id);
            userIdsByEmail.put(u.Email.toLowerCase(), u.Id);
        }

        // get the relevant cases and create digests
        Case[] cases = getCases(userIds, userIdsByEmail.keySet(), daysToInclude);

        Map<Id,EmailDigestUtilities.Digest> digestsByUserId = createUserDigests(cases, userIds, userIdsByEmail, !showClosedCases);

        return digestsByUserId.values();
    }

    /**
     * Create Digests for each user.
     * If a Case isn't owned by one of the CEs, attempt to lookup the user via the supplied supervisor email.
     * @param cases all cases to be processed
     * @param ceUserIds all users to create digests for
     * @param userIdsByEmail userIds by email (used for cases where the CE is the supplied supervisor)
     * @param ignoreClosed if true, closed cases will be ignored (used for the afternoon digest)
     */
    @TestVisible private static Map<Id, EmailDigestUtilities.Digest> createUserDigests(
        Case[] cases, Set<Id> ceUserIds, Map<String,Id> userIdsByEmail, Boolean ignoreClosed
    ) {
        Map<Id, EmailDigestUtilities.Digest> digestsByUserId = new Map<Id, EmailDigestUtilities.Digest>();
        for(Case c :cases) {
            if(c.IsClosed && ignoreClosed) {
                // skip closed cases
                continue;
            }
            Id[] receivingUserIds = new Id[0];
            if(String.isNotBlank(c.Supplied_Supervisors_Email__c) && c.IsClosed) {
                Id receivingUserId = userIdsByEmail.get(c.Supplied_Supervisors_Email__c.toLowerCase());
                if(receivingUserId != null) {
                    // supplied supervisor email is a CE
                    receivingUserIds.add(receivingUserId);
                }
            }
            if(ceUserIds.contains(c.OwnerId)) {
                // owner is CE
                receivingUserIds.add(c.OwnerId);
            }
            for(Id receiverId :receivingUserIds) {
                if(!digestsByUserId.containsKey(receiverId)) {
                    digestsByUserId.put(receiverId, new EmailDigestUtilities.Digest(receiverId, new List<Case>()));
                }
                digestsByUserId.get(receiverId).casesById.put(c.Id, c);
            }
        }
        return digestsByUserId;
    }

    public void execute(Database.BatchableContext bc, List<EmailDigestUtilities.Digest> digests) {
        Messaging.SingleEmailMessage[] emailMessages = new Messaging.SingleEmailMessage[0];
        Id[] userIds = new Id[0];
        for(EmailDigestUtilities.Digest digest :digests) {
            userIds.add(digest.userId);
        }
        Map<Id,User> usersById = new Map<Id,User>([SELECT FirstName, Name, Email FROM User WHERE Id IN :userIds]);
        Map<String,Object> mergeDataByEmail = new Map<String,Object>();
        try {
            for(EmailDigestUtilities.Digest digest :digests) {
                User u = usersById.get(digest.userId);
                Map<String, Object> mergeData = createMergeData(digest);
                mergeDataByEmail.put(u.Email, mergeData.clone()); // for logging
                mergeData.putAll(commonMergeData);
                mergeData.put('User', u.getPopulatedFieldsAsMap());

                mergeData.put('DashboardUrl', new HmlTool.Context(mergeData).render(Label.Spec_Con_Power_BI_Dashboard));
                mergeData.put('Today', Datetime.now().format('dd MMM yyyy'));

                // create the email body and subject
                String renderedBody = new HmlTool.Context(mergeData).render(emailTemplate.HtmlValue);
                String subject = new HmlTool.Context(mergeData).render(emailTemplate.Subject);

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTargetObjectId(digest.userId);
                email.setTreatTargetObjectAsRecipient(true);
                email.setSubject(subject);
                email.setHtmlBody(renderedBody);
                email.setTreatBodiesAsTemplate(true);
                email.setSaveAsActivity(false);
                email.setUseSignature(false);
                email.setOrgWideEmailAddressId(fromAddress.Id);
                if(String.isNotBlank(bccAddress)) {
                    email.setBccAddresses(new String[]{bccAddress});
                }

                emailMessages.add(email);
            }

            mailer.sendEmail(emailMessages);
            sentMergeDataByEmail.putAll(mergeDataByEmail);
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e);
            Exception_Log__c exLog = new Exception_Log__c();
            exLog.Source_Type__c = EX_LOG_ERR_TYPE;
            exLog.Function_Name__c = 'ChiefExaminerDigestEmailBatch.sendEmails';
            exLog.Exception_Type__c = e.getTypeName();
            exLog.Message__c = e.getMessage();
            exLog.Stack_Trace__c = e.getStackTraceString();
            exLog.CurrentUser__c = UserInfo.getUserId();
            exLog.Input__c = JSON.serializePretty(usersById);
            insert exLog;
            failedMergeDataByEmail.putAll(mergeDataByEmail);
        }
    }

    public void finish(Database.BatchableContext bc) {
        EmailDigestUtilities.insertLog(
            EX_LOG_LOG_TYPE,
            'ChiefExaminerDigestEmailBatch.finish',
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

    @TestVisible private static Map<String, Object> createMergeData(EmailDigestUtilities.Digest digest) {

        Map<String, Integer> countsShortExt = new Map<String, Integer>{
            MERGE_KEY_ALL_OPEN => 0,
            MERGE_KEY_NO_OUTCOME => 0,
            MERGE_KEY_MOODLE_NOT_UPDATED => 0,
            MERGE_KEY_ALL_CLOSED => 0
        };
        Map<String, Integer> countsSpecCon = countsShortExt.clone();

        for(Case c :digest.casesById.values()) {
            Map<String, Integer> counts;
            if(c.Category_Level_1__c == CL1_SHORT_EXTENSION) {
                counts = countsShortExt;
            } else if(c.Category_Level_1__c == CL1_SPECIAL_CONSIDERATION) {
                counts = countsSpecCon;
            } else {
                continue;
            }

            Case_Unit_Attempt__c cua = c.Case_Unit_Attempt__r.size() > 0 ? c.Case_Unit_Attempt__r[0] : null;
            if(cua == null) {
                // skip if missing a CUA
                continue;
            }

            if(!c.IsClosed) {
                counts.put(MERGE_KEY_ALL_OPEN, counts.get(MERGE_KEY_ALL_OPEN) + 1);
                if(String.isBlank(c.Case_Outcome__c) || c.Case_Outcome__c == 'Eligible') {
                    // A1/B1 case has no outcome
                    counts.put(MERGE_KEY_NO_OUTCOME, counts.get(MERGE_KEY_NO_OUTCOME) + 1);
                } else {
                    // A2/B2 case has outcome but still open (usually because Moodle has not been updated)
                    counts.put(MERGE_KEY_MOODLE_NOT_UPDATED, counts.get(MERGE_KEY_MOODLE_NOT_UPDATED) + 1);
                }
            } else {
                // C/D case is closed
                counts.put(MERGE_KEY_ALL_CLOSED, counts.get(MERGE_KEY_ALL_CLOSED) + 1);
            }
        }
        Integer allOpen = countsSpecCon.get(MERGE_KEY_ALL_OPEN) + countsShortExt.get(MERGE_KEY_ALL_OPEN);
        Integer allClosed = countsSpecCon.get(MERGE_KEY_ALL_CLOSED) + countsShortExt.get(MERGE_KEY_ALL_CLOSED);
        Integer total = allOpen + allClosed;

        Map<String, Object> mergeVars = new Map<String, Object>{
            'ShortExtension' => countsShortExt,
            'SpecialConsideration' => countsSpecCon,
            MERGE_KEY_ALL_OPEN => allOpen,
            MERGE_KEY_ALL_CLOSED => allClosed,
            'Total' => total
        };
        return mergeVars;
    }

    // Scheduling interface
    public static String CRON_EXP = '0 1 9 ? * MON-FRI';

    public void execute(SchedulableContext sc) {
        Integer daysToInclude = Datetime.now().format('E') == 'Mon' ? 3 : 1; // 3 days on Monday, 1 otherwise
        ChiefExaminerDigestEmailBatch batchDigest = new ChiefExaminerDigestEmailBatch(true, daysToInclude);
        Database.executeBatch(batchDigest,40);
    }

}