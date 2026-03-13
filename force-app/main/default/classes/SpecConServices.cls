/**
 * @author       Tom Gangemi
 * @group        Service
 * @testclass    SpecConServices_Test
 * @revision     2023-07-19 - Tom Gangemi - Initial version
 * @description  Service class for SpecCon related functionality
 */

public with sharing class SpecConServices {

    public class SpecConServicesException extends Exception {}

    public final static Id CUA_RT_ID = Schema.SObjectType.Case_Unit_Attempt__c.getRecordTypeInfosByDeveloperName().get('Special_Consideration').getRecordTypeId();
    public final static Id CUA_EXAM_RT_ID = Schema.SObjectType.Case_Unit_Attempt__c.getRecordTypeInfosByDeveloperName().get('Special_Consideration_Exams').getRecordTypeId();

    public static final String SYS_SETTINGS_FEATURE_TEMPLATES = 'SPEC_CON_EMAIL_TEMPLATE';
    public static final String SYS_SETTINGS_FEATURE_ADDRESS_OVERRIDE = 'SPEC_CON_FROM_ADDRESS';

    public static final String EMAIL_TYPE_APPROVED = 'approved';
    public static final String EMAIL_TYPE_ELIGIBLE = 'eligible';
    public static final String EMAIL_TYPE_DECLINED = 'declined';
    public static final String EMAIL_TYPE_WITHDRAWN = 'withdrawn';

    public static final String FROM_ADDRESS_REGULAR;
    public static final String FROM_ADDRESS_NOREPLY;

    public enum FromType {REGULAR, NOREPLY}

    static {
        // get from addresses - either from static values or from overrides set in Custom Metadata
        System_Settings__mdt addressRegularOverride =
            SystemSettingsUtil.getInstance().getByKeyFeature(SYS_SETTINGS_FEATURE_ADDRESS_OVERRIDE, 'regular');
        if(addressRegularOverride != null && String.isNotBlank(addressRegularOverride.Value__c)) {
            FROM_ADDRESS_REGULAR = addressRegularOverride.Value__c.toLowerCase();
        } else {
            FROM_ADDRESS_REGULAR = 'ask.monash@f.e.monash.edu';
        }

        System_Settings__mdt addressNoReplyOverride =
            SystemSettingsUtil.getInstance().getByKeyFeature(SYS_SETTINGS_FEATURE_ADDRESS_OVERRIDE, 'noreply');
        if(addressNoReplyOverride != null && String.isNotBlank(addressNoReplyOverride.Value__c)) {
            FROM_ADDRESS_NOREPLY = addressNoReplyOverride.Value__c.toLowerCase();
        } else {
            FROM_ADDRESS_NOREPLY = 'noreply@f.e.monash.edu';
        }
    }

    // get/set methods for multiselect picklist field (semicolon separated list of values)
    public static Boolean getEmailSent(Case_Unit_Attempt__c cua, String emailType) {
        if(emailType == EMAIL_TYPE_APPROVED && cua.Approval_Email_Sent__c) {
            return true;
        }
        return cua.Emails_Sent__c != null && cua.Emails_Sent__c.split(';').contains(emailType);
    }

    public static Boolean setEmailSent(Case_Unit_Attempt__c cua, String emailType) {
        String[] values = new String[0];
        if(String.isNotBlank(cua.Emails_Sent__c)) {
            values = cua.Emails_Sent__c.split(';');
        }
        if(!values.contains(emailType)) {
            // modify the list
            values.add(emailType);
            cua.Emails_Sent__c = String.join(values, ';');
            return true;
        }
        return false;
    }

    public class EmailData {
        @AuraEnabled public String htmlBody;
        @AuraEnabled public String subject;
    }

    /**
     * Retrieve an email template with some data already merged in.
     * @param enqId Id of enquiry to merge data for
     * @param emailType Type of email template to load (approval, declined, incomplete, withdrawn)
     * @return
     */
    @AuraEnabled(cacheable=false)
    public static EmailData getMergedEmailTemplate(Id enqId, String emailType, Boolean isExam) {
        EmailTemplate et = getEmailTemplate(emailType, isExam);

        Case enq = [
            SELECT FIELDS(STANDARD), Case_Outcome__c, Category_Level_1__c, Enquiry_Type__c, First_Name_case_corrected__c,
                Contact.First_Name_case_corrected__c,
                (SELECT FIELDS(STANDARD), Assessment_Name__c, Assessment_Type__c, Assessment_Due_Date_New__c,
                    Assessment_Due_Date_Original__c, Assessment_Due_Date_Requested__c, Unit_Title__c, Unit_Code__c,
                    Enquiry_Number__c, Unit_Code_Formula__c, Assessment_Due_Time_Original__c, Status__c,
                    Moodle_Assessment_ID__c, Moodle_Integration_Status__c, Origin__c, Unit_Attempt__c
                FROM Case_Unit_Attempt__r)
            FROM Case
            WHERE Id = :enqId
        ];
        Case_Unit_Attempt__c cua = enq.Case_Unit_Attempt__r[0];

        HmlTool.Context cont = new HmlTool.Context(createEmailMergeData(enq.Contact, cua, enq));
        
        EmailData ed = new EmailData();
        ed.subject = cont.render(et.Subject);
        ed.htmlBody = cont.render(et.HtmlValue);
        return ed;
    }

    public static EmailTemplate getEmailTemplate(String emailType, Boolean isExam) {
        if(isExam) {
            emailType += '-exam';
        }
        System_Settings__mdt objSettings = SystemSettingsUtil.getInstance().getByKeyFeature(SYS_SETTINGS_FEATURE_TEMPLATES, emailType.toLowerCase());
        if(objSettings == null) {
            throw new SpecConServicesException('Unable to find System Settings for email type: ' + emailType);
        }
        EmailTemplate[] ets = [
            SELECT HtmlValue, Body, Subject FROM EmailTemplate
            WHERE DeveloperName = :objSettings.Value__c ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if(ets.isEmpty()) {
            throw new SpecConServicesException('Email template not found for type: ' + emailType);
        }
        return ets[0];
    }

    /**
     * Make sendApprovalEmails available to LWC
     * @return error message if any, otherwise null = Success
     */
    @AuraEnabled(Cacheable=false)
    public static String sendManualApprovalEmail(Id cuaId, Boolean isExam) {
        Case_Unit_Attempt__c[] cuaQuery = [
            SELECT Contact_ID__c, Supplied_Supervisors_Email__c, Moodle_Integration_Status__c,
                Assessment_Due_Date_Original__c, Assessment_Due_Time_Original__c, Assessment_Due_Date_New__c,
                Enquiry__c, Complex_Assignment_Indicator__c, Assessment_Type__c, Status__c, Assessment_Name__c,
                Emails_Sent__c, Approval_Email_Sent__c, Exempt_Assessment__c, Enquiry_Number__c,
                Unit_Code_Formula__c, Unit_Code__c, Unit_Title__c, Outbound_Comments__c, Unit_Attempt__c
            FROM Case_Unit_Attempt__c WHERE Id = :cuaId
        ];
        if(cuaQuery.isEmpty()) {
            return 'Unable to find Case Unit Attempt record';
        }
        Case_Unit_Attempt__c cua = cuaQuery[0];

        String emailType;
        if(cua.Status__c?.startsWithIgnoreCase('Eligible')) {
            emailType = EMAIL_TYPE_ELIGIBLE;
        } else if(cua.Status__c?.startsWithIgnoreCase('Approved')) {
            emailType = EMAIL_TYPE_APPROVED;
        } else {
            return 'Unable to send email for status: ' + cua.Status__c;
        }

        if(getEmailSent(cua, emailType)) {
            return 'Email already sent';
        }
        if(!isExam && cua.Assessment_Due_Date_New__c == null && !cua.Exempt_Assessment__c) {
            return 'Assessment Due Date (New) is required';
        }
        try {
            sendApprovalEmails(cuaQuery, null, isExam);
            setEmailSent(cua, emailType);
            update cua;
        } catch(Exception e) {
            return e.getMessage() + '\n' + e.getStackTraceString();
        }

        return null; // no error
    }

    /**
     * @param cuaIds Although this is a list (requirement for InvocableMethod) only a single Id at a time is supported
     *
     * @return list of error message strings (null value = no error) - Will only return a list with size = 1
     */
    @InvocableMethod(Label='Send Spec Con Approval Email' Category='SpecCon')
    public static List<String> sendManualApprovalEmails(List<Id> cuaIds) {
        if(cuaIds.size() != 1 || cuaIds[0].getSobjectType() != Case_Unit_Attempt__c.getSObjectType()) {
            throw new SpecConServicesException('Only a single Case_Unit_Attempt__c Id is supported');
        }

        return new String[]{sendManualApprovalEmail(cuaIds[0], false)};
    }

    public static String formatDate(Date d, String format, String tz) {
        return Datetime.newInstance(d.year(), d.month(), d.day()).format(format, tz);
    }
    
    public static String formatDate(Date d, String format) {
        return Datetime.newInstance(d.year(), d.month(), d.day()).format(format);
    }

    public static String formatDateAndTime(Date d, Time t) {
        String amPm = 'AM';
        Integer hour = t.hour();
        if(hour > 12) {
            hour -= 12;
            amPm = 'PM';
        }
        return formatDate(d, 'dd-MMM-yyyy') + ' ' + hour + ':' + t.minute() + ' ' + amPm;
    }

    private static Map<String,Object> createEmailMergeData(Contact cont, Case_Unit_Attempt__c cua, Case cse) {
        Boolean approvedExtension = cua.Status__c == 'Approved Extension';
        Boolean approvedExempt = cua.Status__c == 'Approved Exemption';
        Boolean approvedAlternative = cua.Status__c == 'Approved Alternative Assessment';
        Boolean eligible = cua.Status__c?.startsWithIgnoreCase('Eligible');
        Boolean shortExt = cse.Category_Level_1__c == 'Short Extension';
        Boolean specialCon = cse.Category_Level_1__c == 'Special Consideration';
        Boolean moodleUpdated = cua.Moodle_Integration_Status__c != null &&
            (cua.Moodle_Integration_Status__c.startsWith('Success') || cua.Moodle_Integration_Status__c == 'Manual Update');
        Boolean isDef = cse.Category_Level_1__c == 'Deferred Assessment';
        Boolean isRda = cse.Category_Level_1__c.startsWithIgnoreCase('Rescheduled Deferred Assessment');

        String subjectStart = cse.Category_Level_1__c.toLowerCase().capitalize();
        if(specialCon) {
            subjectStart += ' extension';
        } else if(shortExt) {
            subjectStart += ' application';
        }
        if(approvedExtension || approvedExempt || approvedAlternative) {
            subjectStart += ' approved';
        } else if(eligible) {
            subjectStart += ' eligibility confirmed';
        }
        if(shortExt && eligible) {
            // special case
            subjectStart = 'Short extension application approved';
        }
        String teachingPeriod = '';
        String dueTimeOriginal = '';
        if(isDef || isRda) {
            Unit_Attempt__c[] uas = [SELECT Teaching_Period__c FROM Unit_Attempt__c WHERE Id = :cua.Unit_Attempt__c];
            if(uas.size() > 0) {
                teachingPeriod = uas[0].Teaching_Period__c;
            }
            if(isDef) {
                subjectStart = 'Your Deferred assessment application';
            } else if(isRda) {
                subjectStart = 'Your Rescheduled deferred assessment application';
            }
            if(cua.Status__c == 'Approved') {
                subjectStart += ' approved';
            } else if(cua.Status__c == 'Declined') {
                subjectStart += ' declined';
            } else if(cua.Status__c == 'Withdrawn') {
                subjectStart += ' has been withdrawn';
            }
        }
        if(cua.Assessment_Due_Date_Original__c != null && cua.Assessment_Due_Time_Original__c != null) {
            dueTimeOriginal = formatDateAndTime(cua.Assessment_Due_Date_Original__c, cua.Assessment_Due_Time_Original__c);
        }

        Map<String, Object> mergeData = new Map<String, Object>{
            'Case' => cse.getPopulatedFieldsAsMap(),
            'Recipient' => cont.getPopulatedFieldsAsMap(),
            'Case_Unit_Attempt__c' => cua.getPopulatedFieldsAsMap(),
            'Apex' => new Map<String, Object>{
                'SubjectStart' => subjectStart,
                'ApplicationType' => cse.Category_Level_1__c.toLowerCase(),
                'ShortExtensionApproved' => shortExt && approvedExtension,
                'SpecialConsiderationApproved' => specialCon && approvedExtension,
                'ShortExtensionAlternative' => shortExt && approvedAlternative,
                'SpecialConsiderationAlternative' => specialCon && approvedAlternative,
                'ShortExtensionEligible' => shortExt && eligible,
                'SpecialConsiderationEligible' => specialCon && eligible,
                'Exempt' => approvedExempt,
                'NotExemptSpecCon' => !approvedExempt && specialCon,
                'NotExemptShortExt' => !approvedExempt && shortExt,
                'Eligible' => eligible,
                'MoodleUpdated' => moodleUpdated && (approvedExtension || approvedAlternative),
                'MoodleNotUpdated' => !moodleUpdated && (approvedExtension || approvedAlternative),
                'DueDateOriginal' => cua.Assessment_Due_Date_Original__c != null ? formatDate(cua.Assessment_Due_Date_Original__c, 'dd-MMM-yyyy') : '',
                'DueDateNew' => cua.Assessment_Due_Date_New__c != null ? formatDate(cua.Assessment_Due_Date_New__c, 'dd-MMM-yyyy') : '',
                'SpecialConsideration' => specialCon,
                'ShortExtension' => shortExt,
                'IsDef' => isDef,
                'IsRda' => isRda,
                'DueDateTimeOriginal' => dueTimeOriginal,
                'TeachingPeriod' => teachingPeriod
            }
        };

        return mergeData;
    }

    /**
     * @param cuas list of Case Unit Attempts to send approval emails to - Must contain required merge fields
     * This includes sending of the "eligible" email.
     * @param cuas list of Case_Unit_Attempts__c to send emails to
     * @param fromAddress email address to send from, if null it will determine which address to use
     */
    public static void sendApprovalEmails(Case_Unit_Attempt__c[] cuas, FromType ft, Boolean isExam) {

        // retrieve org wide email addresses
        Map<String, Id> oweaIdsByAddress = new Map<String, Id>();
        Map<Id, String> oweaAddressById = new Map<Id, String>();
        for(OrgWideEmailAddress owea :[
            SELECT Address FROM OrgWideEmailAddress WHERE Address IN (:FROM_ADDRESS_REGULAR, :FROM_ADDRESS_NOREPLY)
        ]) {
            oweaIdsByAddress.put(owea.Address.toLowerCase(), owea.Id);
            oweaAddressById.put(owea.Id, owea.Address);
        }

        // retrieve parent enquiry and contact
        Id[] contactIds = new Id[0];
        Id[] caseIds = new Id[0];
        for(Case_Unit_Attempt__c cua :cuas) {
            if(String.isNotBlank(cua.Contact_ID__c)) {
                contactIds.add(cua.Contact_ID__c);
            }
            caseIds.add(cua.Enquiry__c);
        }
        // retrieve fields for use email template
        Map<Id, Contact> contactsById = new Map<Id, Contact>([
            SELECT DSS_Registered__c, Email FROM Contact WHERE Id IN :contactIds
        ]);
        Map<Id, Case> enquiriesByIds = new Map<Id, Case>([
            SELECT Category_Level_1__c, Case_Outcome__c, First_Name_case_corrected__c, Enquiry_Type__c
            FROM Case WHERE Id IN :caseIds
        ]);

        EmailTemplate et = getEmailTemplate(EMAIL_TYPE_APPROVED, isExam);

        List<Messaging.SingleEmailMessage> regularMessages = new List<Messaging.SingleEmailMessage>();
        // directly insert emailmessage records for no-reply emails (ensure there is no ref/threading)
        List<Messaging.SingleEmailMessage> noReplyMessages = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> allMessages = new List<Messaging.SingleEmailMessage>();

        for(Case_Unit_Attempt__c cua :cuas) {
            Contact cont = contactsById.get(cua.Contact_ID__c);
            Case enq = enquiriesByIds.get(cua.Enquiry__c);

            // render email template and subject
            HmlTool.Context templateContext = new HmlTool.Context(createEmailMergeData(cont, cua, enq));
            String emailBody = templateContext.render(et.HtmlValue, false);
            String subject = templateContext.render(et.Subject, false);

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

            // determine from address - if none is supplied, select on Category Level 1 & Enquiry Type
            FromType enqsFromType = ft;
            if(enqsFromType == null) {
                if(enq.Category_Level_1__c == 'Special Consideration' || enq.Enquiry_Type__c == 'Special Consideration - Exams') {
                    enqsFromType = FromType.REGULAR;
                } else {
                    enqsFromType = FromType.NOREPLY;
                }
            }
            String enqsFromAddress = enqsFromType == FromType.REGULAR ? FROM_ADDRESS_REGULAR : FROM_ADDRESS_NOREPLY;

            message.setOrgWideEmailAddressId(oweaIdsByAddress.get(enqsFromAddress.toLowerCase()));
            message.setTemplateId(et.Id);
            message.setSubject(subject);
            message.setHtmlBody(emailBody);
            message.setTargetObjectId(cua.Contact_ID__c);
            message.setTreatBodiesAsTemplate(true);
            // link to case (also adds Ref ID threading) - gets removed for no-replies
            message.setWhatId(enq.Id);
            allMessages.add(message);

            if(enqsFromType == FromType.REGULAR) {
                // add Lightning threading reference
                message.setReferences(Cases.generateThreadingMessageId(cua.Enquiry__c));
                regularMessages.add(message);
            } else {
                noReplyMessages.add(message);
            }
        }

        if(noReplyMessages.size() > 0) {
            // create email messages and relations to contacts for no-reply emails
            Map<Id,EmailMessage> emailMessagesByCaseId = new Map<Id,EmailMessage>();
            Map<Id,Id> contactIdByCaseId = new Map<Id,Id>();
            for(Messaging.SingleEmailMessage sem :noReplyMessages) {
                EmailMessage em = new EmailMessage(
                    FromAddress = oweaAddressById.get(sem.getOrgWideEmailAddressId()),
                    ToAddress = contactsById.get(sem.getTargetObjectId()).Email,
                    Subject = sem.getSubject(),
                    HtmlBody = sem.getHtmlBody(),
                    ParentId = sem.getWhatId(),
                    Incoming = false,
                    Status = '3'
                );
                emailMessagesByCaseId.put(sem.getWhatId(), em);
                contactIdByCaseId.put(sem.getWhatId(), sem.getTargetObjectId());
                sem.setWhatId(null);
            }
            insert emailMessagesByCaseId.values();
            EmailMessageRelation[] emrs = new EmailMessageRelation[0];
            for(Id caseId :emailMessagesByCaseId.keySet()) {
                EmailMessage em = emailMessagesByCaseId.get(caseId);
                EmailMessageRelation emr = new EmailMessageRelation(
                    EmailMessageId = em.Id,
                    RelationId = contactIdByCaseId.get(caseId),
                    RelationType = 'ToAddress'
                );
                emrs.add(emr);
            }
            insert emrs;
        }

        // send emails
        Messaging.sendEmail(allMessages);
    }

    public class AssessmentsCasesDataProvider implements ApexRelatedListController.DataProvider {
        /**
         * @param ref caseId
         *
         * @return list of cases that are for the same Moodle_Assessment_ID__c as the given caseId (doesn't return given case)
         */
        public List<ApexRelatedListController.Record> getRecords(String ref) {
            Case_Unit_Attempt__c refCua = [
                SELECT Moodle_Assessment_ID__c, Enquiry__r.ContactId
                FROM Case_Unit_Attempt__c WHERE Enquiry__c = :ref
            ];

            Map<Id,ApexRelatedListController.Record> cases = new Map<Id,ApexRelatedListController.Record>();

            if(String.isNotBlank(refCua.Moodle_Assessment_ID__c)) {
                for(Case_Unit_Attempt__c cua : [
                    SELECT Enquiry__r.CaseNumber, Status__c, Enquiry__r.CreatedDate
                    FROM Case_Unit_Attempt__c
                    WHERE Moodle_Assessment_ID__c = :refCua.Moodle_Assessment_ID__c
                        AND Enquiry__r.ContactId = :refCua.Enquiry__r.ContactId
                        AND Enquiry__c != :ref
                    ORDER BY Enquiry__r.CreatedDate DESC
                ]) {
                    List<ApexRelatedListController.RecordValue> recordValues = new List<ApexRelatedListController.RecordValue>{
                        new ApexRelatedListController.RecordValue('CUA Status', cua.Status__c),
                        new ApexRelatedListController.RecordValue('Created Date', cua.Enquiry__r.CreatedDate.format())
                    };
                    cases.put(cua.Enquiry__c, new ApexRelatedListController.Record(
                        cua.Enquiry__c, cua.Enquiry__r.CaseNumber, recordValues
                    ));
                }
            }
            return cases.values();
        }
    }

    /**
     * @description For a given cuaId, transfer the parent Case's ownership to the user defined in Supplied_Supervisors_Email__c
     * @param cuaId Case_Unit_Attempt__c ID
     * @return Returns a result string starting with "Error: " or "Success: "
     */
    @AuraEnabled(Cacheable=false)
    public static String transferCaseToSuppliedSupervisor(Id cuaId) {
        Case_Unit_Attempt__c cua = [
            SELECT Supplied_Supervisors_Email__c, Enquiry__c, Enquiry__r.OwnerId
            FROM Case_Unit_Attempt__c WHERE  Id = :cuaId
        ];
        if(String.isBlank(cua.Supplied_Supervisors_Email__c)) {
            return 'Error: Supplied supervisor email address not found';
        }

        User[] userResult = [
            SELECT Name FROM User
            WHERE Email = :cua.Supplied_Supervisors_Email__c AND UserType = 'Standard' AND IsActive = TRUE
            ORDER BY LastLoginDate DESC NULLS LAST LIMIT 1
        ];
        if(userResult.isEmpty()) {
            return 'Error: Delegate user not found';
        }

        if(userResult[0].Id != cua.Enquiry__r.OwnerId) {
            update new Case(
                Id = cua.Enquiry__c,
                OwnerId = userResult[0].Id
            );
        }
        return 'Success: Enquiry ownership has been transferred to ' + userResult[0].Name;
    }

}