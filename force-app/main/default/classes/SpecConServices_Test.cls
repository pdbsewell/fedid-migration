/**
 * @author     Tom Gangemi
 * @group      Test Class
 * @revision   2023-07-19 - Tom Gangemi - Initial version
 */

@IsTest(IsParallel=true)
public class SpecConServices_Test {

    public static final String ASSESSMENT_NAME = 'Test Assessment ##123';

    /**
     * Setup all the test records required for Spec Con: Contact, Course, Course Attempt, Unit Attempt
     * Along with creating a Spec Con request: Case, Case Unit Attempt
     */
    public static Case_Unit_Attempt__c createCua() {
        Course__c course = (Course__c)MonConTestDataFactory.createSObject(new Course__c());
        Contact cont = (Contact)MonConTestDataFactory.createSObject(new Contact());
        Course_Attempt__c courseAttempt = (Course_Attempt__c)MonConTestDataFactory.createSObject(new Course_Attempt__c());
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.Category_Level_1__c = 'Special Consideration';

        TriggerCommon.disableTrigger('Contact');
        insert cont;
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.disableTrigger('Case');
        cse.ContactId = cont.Id;
        insert cse;
        TriggerCommon.enableTrigger('Case');
        insert course;
        courseAttempt.Course__c = course.Id;
        courseAttempt.Contact__c = cont.Id;
        insert courseAttempt;

        Unit_Attempt__c ua = new Unit_Attempt__c(
            Course_Attempt__c = courseAttempt.Id, Calendar_Type__c='S2-01',
            Unit_Code__c = 'ATS3142', CI_Sequence_Number__c='9742'
        );
        insert ua;

        Case_Unit_Attempt__c cua = new Case_Unit_Attempt__c(
            RecordTypeId = SpecConServices.CUA_RT_ID,
            Enquiry__c = cse.Id, Unit_Attempt__c = ua.Id,
            Assessment_Name__c = ASSESSMENT_NAME,
            Assessment_Type__c = 'Test Assessment Type',
            Supplied_Supervisors_Email__c = 'test@example.com',
            Assessment_Due_Date_Original__c = Date.today(),
            Assessment_Due_Date_New__c = Date.today().addDays(10),
            Status__c = 'Approved Extension'
        );
        return cua;
    }

    @TestSetup
    static void setup() {
        insert createCua();
    }

    /**
     * Validate that the correct template is retrieved for the given type - Approved or Declined
     */
    @IsTest
    static void testGetEmailTemplate() {
        // arrange
        String approvalName = SystemSettingsUtil.getInstance().getByKeyFeature(SpecConServices.SYS_SETTINGS_FEATURE_TEMPLATES, SpecConServices.EMAIL_TYPE_APPROVED).Value__c;
        String declinedName = SystemSettingsUtil.getInstance().getByKeyFeature(SpecConServices.SYS_SETTINGS_FEATURE_TEMPLATES, SpecConServices.EMAIL_TYPE_DECLINED).Value__c;
        String examApprovalName = SystemSettingsUtil.getInstance().getByKeyFeature(SpecConServices.SYS_SETTINGS_FEATURE_TEMPLATES, SpecConServices.EMAIL_TYPE_APPROVED+'-exam').Value__c;
        String examWithdrawnName = SystemSettingsUtil.getInstance().getByKeyFeature(SpecConServices.SYS_SETTINGS_FEATURE_TEMPLATES, SpecConServices.EMAIL_TYPE_WITHDRAWN+'-exam').Value__c;

        Map<String,Id> templateIds = new Map<String,Id>();
        for(EmailTemplate et :[
            SELECT DeveloperName FROM EmailTemplate
            WHERE DeveloperName IN (:approvalName, :declinedName, :examApprovalName, :examWithdrawnName)
        ]) {
            if(et.DeveloperName == approvalName) {
                templateIds.put(SpecConServices.EMAIL_TYPE_APPROVED, et.Id);
            } else if(et.DeveloperName == declinedName) {
                templateIds.put(SpecConServices.EMAIL_TYPE_DECLINED, et.Id);
            } else if(et.DeveloperName == examApprovalName) {
                templateIds.put(SpecConServices.EMAIL_TYPE_APPROVED+'-exam', et.Id);
            } else if(et.DeveloperName == examWithdrawnName) {
                templateIds.put(SpecConServices.EMAIL_TYPE_WITHDRAWN+'-exam', et.Id);
            }
        }

        // act
        EmailTemplate etApproval = SpecConServices.getEmailTemplate(SpecConServices.EMAIL_TYPE_APPROVED, false);
        EmailTemplate etDeclined = SpecConServices.getEmailTemplate(SpecConServices.EMAIL_TYPE_DECLINED, false);
        EmailTemplate etExamApproval = SpecConServices.getEmailTemplate(SpecConServices.EMAIL_TYPE_APPROVED, true);
        EmailTemplate etExamWithdrawn = SpecConServices.getEmailTemplate(SpecConServices.EMAIL_TYPE_WITHDRAWN, true);

        // assert
        Assert.areEqual(templateIds.get(SpecConServices.EMAIL_TYPE_APPROVED), etApproval.Id);
        Assert.areEqual(templateIds.get(SpecConServices.EMAIL_TYPE_DECLINED), etDeclined.Id);
        Assert.areEqual(templateIds.get(SpecConServices.EMAIL_TYPE_APPROVED+'-exam'), etExamApproval.Id);
        Assert.areEqual(templateIds.get(SpecConServices.EMAIL_TYPE_WITHDRAWN+'-exam'), etExamWithdrawn.Id);
    }

    /**
     * Send an approval email using the invokable method - This example uses a no-reply address.
     * Validates: Email is linked to the enquiry and Emails_Sent__c field is updated.
     */
    @IsTest
    static void testSendSpecConApprovalEmailInvokable() {
        Case_Unit_Attempt__c cua = [SELECT Enquiry__c, Enquiry__r.Contact.Email FROM Case_Unit_Attempt__c LIMIT 1];
        cua.Moodle_Integration_Status__c = Label.Moodle_Integration_Status_Success;
        TriggerCommon.disableTrigger('Case');
        update new Case(Id = cua.Enquiry__c, Category_Level_1__c = 'Short Extension'); // will use no-reply address
        update cua;
        TriggerCommon.enableTrigger('Case');

        // get a merged template and validate it contains the validation text
        SpecConServices.EmailData ed = SpecConServices.getMergedEmailTemplate(
            cua.Enquiry__c, SpecConServices.EMAIL_TYPE_APPROVED, false
        );
        final String validationRenderedText = 'CUAID:'+cua.Id;
        Assert.isTrue(ed.htmlBody.right(100).contains(validationRenderedText), 'Unexpected template: ' + ed.htmlBody.right(100));

        // send an approval email
        String result = SpecConServices.sendManualApprovalEmail(cua.Id, false);
        Assert.isTrue(String.isBlank(result), result == null ? '' : result);

        Case_Unit_Attempt__c cuaResult = [
            SELECT Emails_Sent__c, Approval_Email_Sent__c FROM Case_Unit_Attempt__c WHERE Id = :cua.Id
        ];
        Assert.isTrue(
            SpecConServices.getEmailSent(cuaResult, SpecConServices.EMAIL_TYPE_APPROVED),
            'Approval email should have been sent: ' + cuaResult.Emails_Sent__c
        );
        EmailMessage emailResult = [
            SELECT FromAddress, ToAddress, ThreadIdentifier, RelatedToId,
                (SELECT RelationId FROM EmailMessageRelations WHERE RelationType = 'ToAddress')
            FROM EmailMessage WHERE ParentId = :cua.Enquiry__c
        ];
        Assert.areEqual(SpecConServices.FROM_ADDRESS_NOREPLY, emailResult.FromAddress);
        Assert.isNull(emailResult.ThreadIdentifier);
        Assert.areEqual(cua.Enquiry__r.Contact.Email, emailResult.ToAddress);
        Assert.areEqual(cua.Enquiry__r.ContactId, emailResult.EmailMessageRelations[0].RelationId);
    }

    /**
     * Send an approval email - This example uses a replyable email address.
     * Validates: Email is linked to the enquiry, Emails_Sent__c field is updated, Correct template used
     */
    @IsTest
    static void testSendSpecConApprovalEmail() {
        Case_Unit_Attempt__c cua = [
            SELECT Contact_ID__c, Supplied_Supervisors_Email__c, Moodle_Integration_Status__c,
                Assessment_Due_Date_Original__c, Assessment_Due_Date_New__c, Assessment_Name__c,
                Enquiry__c, Complex_Assignment_Indicator__c, Assessment_Type__c, Status__c,
                Emails_Sent__c, Approval_Email_Sent__c, Exempt_Assessment__c, Enquiry_Number__c,
                Unit_Code_Formula__c, Unit_Code__c, Unit_Title__c, Outbound_Comments__c, Assessment_Due_Time_Original__c
            FROM Case_Unit_Attempt__c LIMIT 1
        ];
        Contact c = [SELECT Email FROM Contact WHERE Id = :cua.Contact_ID__c];

        final String validationRenderedText = 'CUAID:'+cua.Id;

        SpecConServices.sendApprovalEmails(new Case_Unit_Attempt__c[]{cua}, null, false);
        EmailMessage result01 = [
            SELECT RelatedToId, ToAddress, Subject, ParentId, HtmlBody, FromAddress, ThreadIdentifier
            FROM EmailMessage WHERE ParentId = :cua.Enquiry__c
        ];
        Assert.areEqual(cua.Enquiry__c, result01.RelatedToId);
        Assert.areEqual(c.Email, result01.ToAddress);
        Assert.areEqual(SpecConServices.FROM_ADDRESS_REGULAR, result01.FromAddress);
        Assert.isNotNull(result01.ThreadIdentifier);

        Assert.isTrue(result01.HtmlBody.right(100).contains(validationRenderedText), 'Unexpected template: ' + result01.HtmlBody.right(100));
        SpecConServices.sendApprovalEmails(new Case_Unit_Attempt__c[]{cua}, SpecConServices.FromType.REGULAR, false);
        EmailMessage result02 = [
            SELECT RelatedToId, ToAddress, Subject, ParentId, HtmlBody, FromAddress, ThreadIdentifier
            FROM EmailMessage WHERE Id != :result01.Id AND ParentId = :cua.Enquiry__c
        ];
        Assert.areEqual(cua.Enquiry__c, result02.RelatedToId);
        Assert.areEqual(SpecConServices.FROM_ADDRESS_REGULAR, result02.FromAddress);
        Assert.isNotNull(result02.ThreadIdentifier);
    }

    /**
     * Validates accessor methods for the email sent field
     */
    @IsTest
    static void testEmailSentField() {
        Case_Unit_Attempt__c cua = new Case_Unit_Attempt__c();

        Assert.isFalse(SpecConServices.getEmailSent(cua, SpecConServices.EMAIL_TYPE_APPROVED), 'Approval email sent should be false');
        Assert.isTrue(SpecConServices.setEmailSent(cua, SpecConServices.EMAIL_TYPE_APPROVED), 'Change of email sent field should be true');
        Assert.isTrue(SpecConServices.getEmailSent(cua, SpecConServices.EMAIL_TYPE_APPROVED), 'Approval email sent should be true');

        Assert.isTrue(SpecConServices.setEmailSent(cua, SpecConServices.EMAIL_TYPE_DECLINED), 'Change of email sent field should be true');
        Assert.isFalse(SpecConServices.setEmailSent(cua, SpecConServices.EMAIL_TYPE_DECLINED), 'Field should not change again');

        Assert.isTrue(SpecConServices.getEmailSent(cua, SpecConServices.EMAIL_TYPE_APPROVED), 'Approval email sent should be true');
        Assert.isTrue(SpecConServices.getEmailSent(cua, SpecConServices.EMAIL_TYPE_DECLINED), 'Declined email sent should be true');
    }

    /**
     * Testing for the AssessmentsCasesDataProvider that returns the related cases for a given assessment
     * Should return a student's other cases that are related to the same Moodle_Assessment_ID__c
     */
    @IsTest
    public static void testGetAssessmentsRelatedCases() {
        final String moodleAssessmentId = 'XX-11';

        Case_Unit_Attempt__c cua1 = [
            SELECT Enquiry__c, Enquiry__r.RecordTypeId, Enquiry__r.Category_Level_1__c,
                Enquiry__r.Enquiry_Type__c, Enquiry__r.ContactId
            FROM Case_Unit_Attempt__c LIMIT 1
        ];
        cua1.Moodle_Assessment_ID__c = moodleAssessmentId;

        Case case2 = cua1.Enquiry__r.clone(false);
        TriggerCommon.disableTrigger('Case');
        insert case2;
        Case_Unit_Attempt__c cua2 = cua1.clone(false);
        cua2.Enquiry__c = case2.Id;

        upsert new Case_Unit_Attempt__c[]{cua1, cua2};

        Test.startTest();
        SpecConServices.AssessmentsCasesDataProvider acdp = new SpecConServices.AssessmentsCasesDataProvider();
        List<ApexRelatedListController.Record> result1 = acdp.getRecords(cua1.Enquiry__c);
        Assert.areEqual(1, result1.size(), 'Expected exactly one case');
        Assert.areEqual(case2.Id, result1[0].id, 'Should return the other case');

        cua1.Moodle_Assessment_ID__c = 'XX-22';
        update cua1;

        List<ApexRelatedListController.Record> result2 = acdp.getRecords(case2.Id);
        Assert.areEqual(0, result2.size(), 'Should not return the other case with different Moodle_Assessment_ID__c');
        Test.stopTest();
    }

    /**
     * Test TransferCaseToSuppliedSupervisor method
     * Includes success and error paths
     */
    @IsTest
    public static void testTransferCaseToSuppliedSupervisor() {
        TriggerCommon.disableTrigger('Case_Unit_Attempt__c');

        Case_Unit_Attempt__c cua = [SELECT Enquiry__c, Enquiry__r.OwnerId FROM Case_Unit_Attempt__c LIMIT 1];
        cua.Supplied_Supervisors_Email__c = '455user_not_exsits78987@speccontest.com.au';
        update cua;

        // attempt to transfer case to invalid email address
        String result1 = SpecConServices.transferCaseToSuppliedSupervisor(cua.Id);
        Assert.isTrue(result1 != null && result1.startsWith('Error:'), 'Should have failed to transfer case: ' + result1);
        Case caseResult1 = [SELECT OwnerId FROM Case WHERE Id = :cua.Enquiry__c];
        Assert.areEqual(cua.Enquiry__r.OwnerId, caseResult1.OwnerId, 'Case should not have been transferred');

        // get a user that will be the new owner and update the cua
        User newOwner = [
            SELECT Email FROM User
            WHERE IsActive = TRUE AND Profile.Name = 'System Administrator' AND Email != :UserInfo.getUserEmail()
            LIMIT 1
        ];
        cua.Supplied_Supervisors_Email__c = newOwner.Email;
        update cua;

        // attempt to transfer case to valid email address
        String result2 = SpecConServices.transferCaseToSuppliedSupervisor(cua.Id);
        Assert.isTrue(result2 != null && result2.startsWith('Success:'), 'Should have successfully transferred case: ' + result2);
        Case caseResult2 = [SELECT OwnerId FROM Case WHERE Id = :cua.Enquiry__c];
        // just check owner changed (in case more than one user has the email address we used)
        Assert.areNotEqual(cua.Enquiry__r.OwnerId, caseResult2.OwnerId, 'Case should have been transferred');
    }

}