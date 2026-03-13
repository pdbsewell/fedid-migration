/**
 * @author Tom Gangemi
 * @date 2023-06-12
 * @group Test Class
 **/

@IsTest
private class ChiefExaminerDigestEmailBatch_Test {

    final static Id specConRt = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(ChiefExaminerDigestEmailBatch.SPEC_CON_RT_NAME).getRecordTypeId();

    private static Case createCase(Id ownerId) {
        return createCase(ownerId, false, false, false);
    }

    // create Cases and set non-writeable fields - No DML needed - Case will be Special Consideration
    private static Case createCase(Id ownerId, Boolean createId, Boolean createCua, Boolean isClosed) {
        Case c = (Case)MonConTestDataFactory.createSObject(new Case());
        c.RecordTypeId = specConRt;
        if(createId) {
            c.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        }
        if(createCua || isClosed) {
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(c));
            if(createCua) {
                m.put('Case_Unit_Attempt__r', new Map<String, Object> {
                    'totalSize' => 1, 'done' => true,
                    'records' => new List<Case_Unit_Attempt__c>{
                        new Case_Unit_Attempt__c(Origin__c = 'Moodle eLMS', Is_Closed_On_Create__c = isClosed)
                    }
                });
            }
            if(isClosed) {
                m.put('IsClosed', true);
                m.put('Status', 'Solved');
                m.put('Case_Outcome__c', 'Approved Extension');
            }
            c = (Case)JSON.deserialize(JSON.serialize(m), Case.class);
        }
        c.OwnerId = ownerId;
        c.Enquiry_Type__c = ChiefExaminerDigestEmailBatch.SPEC_CON_ENQUIRY_TYPE;
        c.Category_Level_1__c = 'Special Consideration';
        c.Origin = 'Web - Monash Forms';
        return c;
    }

    @IsTest
    public static void testDigestAndCreateMergeData() {

        // create CE 1 cases
        Id userId1 = fflib_IDGenerator.generate(Case.getSObjectType());
        String userEmail1 = 'u1@test.monash.edu';
        Case u1c1 = createCase(userId1, true, true, false);
        Case u1c2 = createCase(userId1, true, true, false);
        Case u1c3 = createCase(userId1, true, true, false);
        u1c3.Category_Level_1__c = 'Short Extension';
        Case u1c4 = createCase(userId1, true, true, true);
        Case u1c5 = createCase(userId1, true, true, false);
        u1c5.Case_Outcome__c = 'Approved Extension';
        u1c5.Case_Unit_Attempt__r[0].Moodle_Assessment_ID__c = '1234';
        u1c5.Case_Unit_Attempt__r[0].Moodle_Integration_Status__c = 'Error';
        Case u1c6 = createCase(userId1, true, true, false);
        u1c6.Case_Outcome__c = 'Approved Extension';
        u1c6.Case_Unit_Attempt__r[0].Moodle_Assessment_ID__c = '4567';
        u1c6.Case_Unit_Attempt__r[0].Moodle_Integration_Status__c = 'Success';

        // create CE 2 cases
        Id userId2 = fflib_IDGenerator.generate(Case.getSObjectType());
        String userEmail2 = 'u2@test.monash.edu';
        Case u2c1 = createCase(userId2, true, true, false);
        u2c1.Category_Level_1__c = 'Short Extension';
        Case u2c2 = createCase(userId2, true, true, false);
        u2c2.Category_Level_1__c = 'Short Extension';

        // create cases not owned by CE
        Id nonCeUserId = fflib_IDGenerator.generate(Case.getSObjectType());
        Case nonc1 = createCase(nonCeUserId, true, true, true);
        nonc1.Supplied_Supervisors_Email__c = userEmail1; // case will be included via supervisor email
        Case nonc2 = createCase(nonCeUserId, true, true, false);
        nonc2.Supplied_Supervisors_Email__c = userEmail1;
        Case nonc3 = createCase(nonCeUserId, true, true, true);

        Map<String, Id> userIdsByEmail = new Map<String, Id> {
            userEmail1 => userId1,
            userEmail2 => userId2
        };

        // create users afternoon digests
        Map<Id, EmailDigestUtilities.Digest> afterNoonDigests = ChiefExaminerDigestEmailBatch.createUserDigests(
            new Case[] {u1c1, u1c2, u1c3, u1c4, u1c5, u1c6, u2c1, u2c2, nonc1, nonc2, nonc3},
            new Set<Id>(userIdsByEmail.values()), userIdsByEmail, true
        );
        Assert.areEqual(5, afterNoonDigests.get(userId1).casesById.size());
        Assert.isFalse(afterNoonDigests.get(userId1).casesById.containsKey(u1c4.Id), 'Closed cases should not be in afternoon digest');

        // create users morning digests
        Map<Id, EmailDigestUtilities.Digest> digests = ChiefExaminerDigestEmailBatch.createUserDigests(
            new Case[] {u1c1, u1c2, u1c3, u1c4, u1c5, u1c6, u2c1, u2c2, nonc1, nonc2, nonc3},
            new Set<Id>(userIdsByEmail.values()), userIdsByEmail, false
        );
        Assert.areEqual(7, digests.get(userId1).casesById.size());
        Assert.isTrue(digests.get(userId1).casesById.containsKey(nonc1.Id), 'Closed cases linked by email should be in Digest');
        Assert.isFalse(digests.get(userId1).casesById.containsKey(nonc2.Id), 'Non-closed cases linked by email should not be in Digest');

        // generate and validate user1 merge data
        Map<String, Object> u1MergeData = ChiefExaminerDigestEmailBatch.createMergeData(digests.get(userId1));
        Assert.areEqual(4, ((Map<String, Object>)u1MergeData.get('SpecialConsideration')).get(ChiefExaminerDigestEmailBatch.MERGE_KEY_ALL_OPEN));
        Assert.areEqual(2, ((Map<String, Object>)u1MergeData.get('SpecialConsideration')).get(ChiefExaminerDigestEmailBatch.MERGE_KEY_ALL_CLOSED));
        Assert.areEqual(2, ((Map<String, Object>)u1MergeData.get('SpecialConsideration')).get(ChiefExaminerDigestEmailBatch.MERGE_KEY_MOODLE_NOT_UPDATED));
        Assert.areEqual(1, ((Map<String, Object>)u1MergeData.get('ShortExtension')).get(ChiefExaminerDigestEmailBatch.MERGE_KEY_ALL_OPEN));
        Assert.areEqual(5, u1MergeData.get(ChiefExaminerDigestEmailBatch.MERGE_KEY_ALL_OPEN));
        Assert.areEqual(2, u1MergeData.get(ChiefExaminerDigestEmailBatch.MERGE_KEY_ALL_CLOSED));

        // generate and validate user2 merge data
        Map<String, Object> u2MergeData = ChiefExaminerDigestEmailBatch.createMergeData(digests.get(userId2));
        Assert.areEqual(0, ((Map<String, Object>)u2MergeData.get('SpecialConsideration')).get(ChiefExaminerDigestEmailBatch.MERGE_KEY_ALL_OPEN));
        Assert.areEqual(2, ((Map<String, Object>)u2MergeData.get('ShortExtension')).get(ChiefExaminerDigestEmailBatch.MERGE_KEY_ALL_OPEN));
        Assert.areEqual(2, u2MergeData.get(ChiefExaminerDigestEmailBatch.MERGE_KEY_ALL_OPEN));
    }

    @IsTest
    public static void testEndToEnd() {
        Id queueId = [
            SELECT Id FROM Group
            WHERE DeveloperName = 'SEBS_Spec_Con_and_Spec_Circumstances' AND Type = 'Queue'
            LIMIT 1
        ].Id;
        Id digestGroupId = [
            SELECT Id FROM Group
            WHERE DeveloperName =: ChiefExaminerDigestEmailBatch.PUBLIC_GROUP AND Type = 'Regular'
            LIMIT 1
        ].Id;
        // select 5 users who are not already in the public group
        User[] users = [
            SELECT Id, Email, Username
            FROM User
            WHERE IsActive = TRUE AND Id != :UserInfo.getUserId() AND Profile.UserType = 'Standard' AND
                Id NOT IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :digestGroupId)
            LIMIT 5
        ];

        User nonCeUser1 = users.remove(0);
        User ceUser1 = users.get(0);
        User ceUser2 = users.get(1);
        User ceUser3 = users.get(2);

        GroupMember[] members = new GroupMember[0];
        for(User u :users) {
            members.add(new GroupMember(UserOrGroupId = u.Id, GroupId = digestGroupId));
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // avoid MIXED_DML_OPERATION exception
            insert members;
        }

        Contact cont = (Contact)MonConTestDataFactory.createSObject(new Contact());
        insert cont;

        Case nonCeCase = createCase(nonCeUser1.Id);
        Case queueCase = createCase(queueId);
        Case ce1Case1 = createCase(ceUser1.Id);
        Case ce1Case2 = createCase(ceUser1.Id);
        Case ce1CaseClosed = createCase(ceUser1.Id);
        ce1CaseClosed.Status = 'Solved';
        ce1CaseClosed.Case_Outcome__c = 'Approved Extension';
        Case ce1CaseClosedOld = createCase(ceUser1.Id);
        ce1CaseClosedOld.Status = 'Solved';
        ce1CaseClosedOld.Case_Outcome__c = 'Approved Extension';
        Case ce2Case1 = createCase(ceUser2.Id);
        Case ce3Case1Closed = createCase(ceUser3.Id);
        ce3Case1Closed.Status = 'Solved';
        ce3Case1Closed.Case_Outcome__c = 'Approved Extension';

        insert new Case[] {
            nonCeCase, queueCase, ce1Case1, ce1Case2, ce1CaseClosed, ce1CaseClosedOld, ce2Case1, ce3Case1Closed
        };
        Test.setCreatedDate(ce1CaseClosedOld.Id, Datetime.now().addDays(-3));

        EmailDigestUtilities.MockMailer mockEmailer = new EmailDigestUtilities.MockMailer();
        ChiefExaminerDigestEmailBatch.mailer = mockEmailer;

        Test.startTest();
        ChiefExaminerDigestEmailBatch batchDigest = new ChiefExaminerDigestEmailBatch(true, 1);
        Database.executeBatch(batchDigest,50);
        Test.stopTest();

        // validate email sent
        Assert.areEqual(1, mockEmailer.invokeCounter);
        Assert.areEqual(3, mockEmailer.sentEmails.size());
        Map<Id,Messaging.SingleEmailMessage> emailsByUserId = new Map<Id,Messaging.SingleEmailMessage>();
        for(Messaging.SingleEmailMessage email : mockEmailer.sentEmails) {
            emailsByUserId.put(email.getTargetObjectId(), email);
        }
        Assert.areEqual(3, emailsByUserId.size());

        // validate logs
        Map<String,User> usersByEmail = new Map<String,User>();
        for(User u :users) {
            // collect users that were sent an email
            if(emailsByUserId.containsKey(u.Id))
                usersByEmail.put(u.Email, u);
        }
        Exception_Log__c[] logResults = [
            SELECT Id, Input__c FROM Exception_Log__c WHERE Source_Type__c = :ChiefExaminerDigestEmailBatch.EX_LOG_LOG_TYPE
        ];
        Assert.areEqual(1, logResults.size());

        // retrieve the inserted file
        ContentDocumentLink[] cdl = [
            SELECT ContentDocument.LatestPublishedVersion.VersionData
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :logResults[0].Id
        ];

        Assert.areEqual(1, cdl.size());
        Map<String,Object> logInput = (Map<String,Object>)JSON.deserializeUntyped(
            cdl[0].ContentDocument.LatestPublishedVersion.VersionData.toString()
        );
        Map<String,Object> logSent = (Map<String,Object>)logInput.get('Sent');
        String msg = 'Log is missing some users.\nExpected: ' + usersByEmail.keySet() + '\nActual: ' + logSent.keySet();
        Assert.areEqual(usersByEmail.size(), logSent.keySet().size(), msg);
        Assert.isTrue(logSent.keySet().containsAll(usersByEmail.keySet()), msg);
    }
}