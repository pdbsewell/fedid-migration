/**
 * @author Tom Gangemi
 * @date Jan.2022
 * @group Test Class
 * @revision
 *     2023-10-04 - SA-2372 - Tom Gangemi - DoI 2023 Refresh Updates
*/
@IsTest(IsParallel=true)
public class DOICaseDigestBatch_Test {

    final static Id DOI_RT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(DOICaseDigestBatch.DOI_RECORD_TYPE).getRecordTypeId();

    /**
     * Create and return a new Case sObject with a mocked record ID
     */
    private static Case createCase(Id ownerId, Datetime mockCreatedDate, Boolean isClosed) {
        Case c = (Case)MonConTestDataFactory.createSObject(new Case());
        c.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        c.OwnerId = ownerId;
        Map<String, Object> overrideFields = new Map<String, Object>();
        if(mockCreatedDate != null) {
            overrideFields.put('CreatedDate', mockCreatedDate);
        }
        if(isClosed) {
            overrideFields.put('IsClosed', true);
            c.Status = 'Solved';
        }
        if(!overrideFields.isEmpty()) {
            c = setNonWritableFields(c, overrideFields);
        }
        return c;
    }

    private static Case createCase(Id ownerId, Boolean isClosed) {
        return createCase(ownerId, null, isClosed);
    }

    private static Case createCase(Id ownerId) {
        return createCase(ownerId, null, false);
    }

    private static Case setNonWritableFields(Case c, Map<String,Object> fields) {
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(c));
        m.putAll(fields);
        return (Case)JSON.deserialize(JSON.serialize(m), Case.class);
    }

    /**
     * Validate digestion object creation works as expected
     */
    @IsTest static void testCreateAndFilterDigests() {
        // Arrange
        Id owner01Id = UserInfo.getUserId();
        Id owner02Id = fflib_IDGenerator.generate(User.getSObjectType());
        Id owner03Id = fflib_IDGenerator.generate(User.getSObjectType());

        // add user01 to the do-not-send group
        Group doNotSendGroup = [SELECT Id FROM Group WHERE DeveloperName = :DOICaseDigestBatch.NO_DIGEST_GROUP];
        System.runAs(new User(Id=owner01Id)) {
            insert new GroupMember(UserOrGroupId=owner01Id, GroupId=doNotSendGroup.Id);
        }
        Case doiCase01 = createCase(owner01Id);
        Case doiCase02 = createCase(owner01Id);
        Case doiCase03 = createCase(owner02Id);
        Case doiCase04 = createCase(owner01Id);
        Case doiCase05 = createCase(owner03Id);
        Case doiCase06 = createCase(owner03Id);
        Map<Id, Case> casesById = new Map<Id, Case>(
            new Case[]{doiCase01, doiCase02, doiCase03, doiCase04, doiCase05, doiCase06}
        );

        // Act - create digests
        Map<Id,EmailDigestUtilities.Digest> result = DOICaseDigestBatch.createUserDigests(casesById);

        // Assert
        Assert.areEqual(3, result.size(), 'Should have 1 digest per user');
        Assert.areEqual(3, result.get(owner01Id).casesById.size(), 'Owner 01 digest incorrect case count');
        Assert.areEqual(owner01Id, result.get(owner01Id).userId, 'Digest should have userId set');
        for(Case c : result.get(owner01Id).casesById.values()) {
            Assert.isTrue(c.OwnerId == owner01Id, 'All cases in digest should belong to same owner');
        }
        Assert.areEqual(1, result.get(owner02Id).casesById.size());
        Assert.areEqual(2, result.get(owner03Id).casesById.size());

        // Act - filter digests
        DOICaseDigestBatch.removeDigestsForDoNotSendUsers(result);

        // Assert
        Assert.areEqual(2, result.size(), 'Should have removed a digest');
        Assert.isFalse(result.containsKey(owner01Id), 'Should have removed owner 01 digest');
    }

    /**
     * Validate counting logic that creates merge data
     */
    @IsTest static void testCreateMergeData() {
        // Arrange
        String openCaseStage = DOICaseDigestBatch.STAGES_REQ_ACTION.iterator().next();
        Id ownerId = fflib_IDGenerator.generate(User.getSObjectType());
        Case cOpen = createCase(ownerId, false); // open
        cOpen.Case_Stage__c = openCaseStage;
        Case cOpen2 = createCase(ownerId, false); // open
        cOpen2.Case_Stage__c = openCaseStage;
        Case cNothing = createCase(ownerId, true); // nothing to declare
        cNothing.Enquiry_Type__c = DOICaseDigestBatch.ENQ_TYPE_HR_DOI_SUBMISSION;
        Case cNoAction = createCase(ownerId, true); // no action
        cNoAction.Enquiry_Type__c = DOICaseDigestBatch.ENQ_TYPE_HR_DOI;
        cNoAction.Response_Required__c = 'No';
        Case cNoAction2 = createCase(ownerId, true); // no action
        cNoAction2.Enquiry_Type__c = DOICaseDigestBatch.ENQ_TYPE_HR_DOI;
        cNoAction2.Response_Required__c = 'No';
        Case cNop = createCase(ownerId, true); // not counted

        EmailDigestUtilities.Digest digest = new EmailDigestUtilities.Digest(
            ownerId, new Case[]{cOpen, cOpen2, cNothing, cNoAction, cNoAction2, cNop}
        );

        // Act
        Map<String,Object> result = DOICaseDigestBatch.createMergeData(digest);

        // Assert
        Assert.areEqual(2, result.get(DOICaseDigestBatch.MERGE_KEY_OPEN));
        Assert.areEqual(1, result.get(DOICaseDigestBatch.MERGE_KEY_NOTHING));
        Assert.areEqual(2, result.get(DOICaseDigestBatch.MERGE_KEY_NO_ACTION));
        Assert.areEqual(3, result.get(DOICaseDigestBatch.MERGE_KEY_CLOSED));
    }

    /**
     * Validate email sending logic
     */
    @IsTest static void testSendEmails() {
        // Arrange
        // setup users
        User[] users = [SELECT Id FROM User WHERE UserType = 'Standard' AND IsActive = TRUE LIMIT 2];
        User owner1 = users[0];
        owner1.Email='test_doi_1@example.com';
        owner1.FirstName='Test1';
        User owner2 = users[1];
        owner2.Email = 'test_doi_2@example.com';
        owner2.FirstName = 'Test2';
        Map<Id, User> usersById = new Map<Id, User>{owner1.Id => owner1, owner2.Id => owner2};

        // create cases
        Case cOpen1 = createCase(owner1.Id, false); // open
        cOpen1.Case_Stage__c = DOICaseDigestBatch.STAGES_REQ_ACTION.iterator().next();
        Case cNothing1 = createCase(owner2.Id, true); // nothing to declare
        cNothing1.Enquiry_Type__c = DOICaseDigestBatch.ENQ_TYPE_HR_DOI_SUBMISSION;
        Case cOpen2 = createCase(owner2.Id, false); // open
        cOpen2.Case_Stage__c = DOICaseDigestBatch.STAGES_REQ_ACTION.iterator().next();

        // create digests
        EmailDigestUtilities.Digest digest1 = new EmailDigestUtilities.Digest(owner1, new Case[]{cOpen1, cNothing1});
        EmailDigestUtilities.Digest digest2 = new EmailDigestUtilities.Digest(owner2, new Case[]{cOpen2});
        EmailDigestUtilities.Digest[] digests = new EmailDigestUtilities.Digest[]{digest1, digest2};
        OrgWideEmailAddress orgWideAddress = [
            SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = :DOICaseDigestBatch.FROM_ADDRESS_NAME
        ];
        // get email template and modify it
        EmailTemplate emailTemplate = [
            SELECT HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = :DOICaseDigestBatch.EMAIL_TEMPLATE_NAME
        ];
        emailTemplate.HtmlValue = 'Hello {{Recipient.FirstName}} -- {{'+DOICaseDigestBatch.MERGE_KEY_OPEN+'}}';
        emailTemplate.Subject = 'Subject Line';
        Map<String, Object> commonMergeData = new Map<String, Object>{};

        // setup DOICaseDigestBatch with mock mailer
        EmailDigestUtilities.MockMailer mailer = new EmailDigestUtilities.MockMailer();
        DOICaseDigestBatch.digestMailer = mailer;
        DOICaseDigestBatch sendEmailsBatch = new DOICaseDigestBatch();

        // Act
        sendEmailsBatch.sendEmails(digests, emailTemplate, orgWideAddress, commonMergeData);

        // Assert
        Assert.areEqual(2, mailer.sentEmails.size());
        Map<Id,Messaging.SingleEmailMessage> emailsByRecipient = new Map<Id,Messaging.SingleEmailMessage>();
        for(Messaging.SingleEmailMessage m : mailer.sentEmails) {
            Assert.isTrue(m.targetObjectId != null && usersById.containsKey(m.targetObjectId), 'Unexpected recipient');
            emailsByRecipient.put(m.targetObjectId, m);
            // validate email properties and merge data
            Assert.areEqual(orgWideAddress.Id, m.orgWideEmailAddressId);
            Assert.areEqual(emailTemplate.Subject, m.subject);
            String expectedBody = 'Hello ' + usersById.get(m.targetObjectId).FirstName + ' -- 1';
            Assert.areEqual(expectedBody, m.htmlBody, 'Email did not merge/render correctly');
        }
        // validate each email address was used
        Assert.isTrue(emailsByRecipient.containsKey(owner1.Id));
        Assert.isTrue(emailsByRecipient.containsKey(owner2.Id));

        Assert.isTrue(sendEmailsBatch.sentMergeDataByEmail.containsKey(owner1.Email));
    }

    /**
     * Validate the SOQL query used to get cases
     */
    @IsTest static void testGetCases() {
        Case case01 = (Case)MonConTestDataFactory.createSObject(new Case());
        case01.RecordTypeId = DOI_RT;
        case01.Enquiry_Type__c = DOICaseDigestBatch.ENQ_TYPE_HR_DOI;
        case01.Subject = '1';
        case01.Status = 'Solved';
        Case case02 = case01.clone();
        case02.Subject = '2';
        Case case03 = case01.clone();
        case03.Subject = '3';
        case03.Status = 'Open';
        case03.Case_Stage__c = DOICaseDigestBatch.STAGES_REQ_ACTION.iterator().next();
        Case caseNoneDoi = (Case)MonConTestDataFactory.createSObject(new Case()); // should not get returned by getCases
        Case[] cases = new Case[]{case01, case02, case03, caseNoneDoi};
        insert cases;

        // Act
        Map<Id, Case> results = DOICaseDigestBatch.getCases();

        // Assert
        Assert.areEqual(3, results.size());
        Assert.isTrue(results.containsKey(case01.Id));
        Assert.isTrue(results.containsKey(case02.Id));
        Assert.isTrue(results.containsKey(case03.Id));
        Assert.isFalse(results.containsKey(caseNoneDoi.Id));
    }

    /**
     * Run the whole process
     */
    @IsTest static void testEndToEnd() {
        // Arrange
        User[] users = [
            SELECT Id FROM User WHERE Profile.Name = 'System Administrator'
            AND IsActive = TRUE AND Id != :UserInfo.getUserId() LIMIT 2
        ];

        Case case01 = (Case)MonConTestDataFactory.createSObject(new Case()); // will trigger a digest
        case01.RecordTypeId = DOI_RT;
        case01.Enquiry_Type__c = DOICaseDigestBatch.ENQ_TYPE_HR_DOI;
        case01.Subject = '1';
        case01.Status = 'Open';
        case01.OwnerId = UserInfo.getUserId();
        case01.Case_Stage__c = DOICaseDigestBatch.STAGES_REQ_ACTION.iterator().next();

        Case case02 = case01.clone(false); // will trigger a digest
        case02.OwnerId = users[0].Id;

        Case case03 = case01.clone(false); // will not trigger a digest
        case03.RecordTypeId = MonConCaseServices.MONCON_RECTYPEID;
        case03.OwnerId = users[1].Id;
        case03.Case_Stage__c = null;

        insert new Case[]{case01, case02, case03};

        EmailDigestUtilities.MockMailer mockEmailer = new EmailDigestUtilities.MockMailer();
        DOICaseDigestBatch.digestMailer = mockEmailer;
        DOICaseDigestBatch batchDigest = new DOICaseDigestBatch();

        // Act
        Test.startTest();
        Database.executeBatch(batchDigest,50);
        Test.stopTest();

        // Assert
        System.assertEquals(1, mockEmailer.invokeCounter);
        System.assertEquals(2, mockEmailer.sentEmails.size());

        Exception_Log__c[] logResult = [
            SELECT Input__c, Message__c FROM Exception_Log__c WHERE Source_Type__c = :DOICaseDigestBatch.EX_LOG_LOG_TYPE
        ];
        Assert.areEqual(1, logResult.size(), 'Log not found');
    }

}