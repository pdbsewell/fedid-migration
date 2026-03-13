/**
 * @author     Tom Gangemi
 * @group      Test Class
 * @revision   2022-09-21 - Tom Gangemi - Initial version
 */

@isTest
public class CaseUnitAttemptTriggerHandler_Test {

    @isTest static void testSpecConOnStatusChange() {
        Case cse = new Case(
            Subject = 'Test Spec Con Existing',
            Enquiry_Type__c = 'Special Consideration',
            Status = 'Solved',
            RecordTypeId = MonConCaseServices.SPECON_RECTYPEID,
            Origin = 'Web - Monash Forms'

        );
        TriggerCommon.disableTrigger('Case');
        insert cse;
        TriggerCommon.enableTrigger('Case');

        Case_Unit_Attempt__c cua = new Case_Unit_Attempt__c(
            Enquiry__c = cse.Id,
            RecordTypeId = SpecConServices.CUA_RT_ID,
            Status__c = 'Approved',
            Emails_Sent__c = '',
            Moodle_Integration_Status__c = 'Success',
            Assessment_Due_Date_New__c = Date.today().addDays(1)
        );
        SpecConServices.setEmailSent(cua, SpecConServices.EMAIL_TYPE_APPROVED);
        insert cua;

        cua.Status__c = 'Declined';
        update cua;

        Case_Unit_Attempt__c result  = [
            SELECT Emails_Sent__c, Moodle_Integration_Status__c, Assessment_Due_Date_New__c
            FROM Case_Unit_Attempt__c WHERE Id = :cua.Id
        ];
        Assert.isNull(result.Moodle_Integration_Status__c);
        Assert.isNull(result.Emails_Sent__c);
        Assert.isNull(result.Assessment_Due_Date_New__c);
    }

    @isTest static void testSpecConUpdateCaseOutcome() {
        Case cse = new Case(
            Subject = 'Test Spec Con Existing',
            Enquiry_Type__c = 'Special Consideration',
            Status = 'Solved',
            RecordTypeId = MonConCaseServices.SPECON_RECTYPEID,
            Origin = 'Web - Monash Forms'

        );
        TriggerCommon.disableTrigger('Case');
        insert cse;
        TriggerCommon.enableTrigger('Case');

        Case_Unit_Attempt__c cua = new Case_Unit_Attempt__c(
            Enquiry__c = cse.Id,
            RecordTypeId = SpecConServices.CUA_RT_ID
        );
        insert cua;

        Test.startTest();
        cua.Status__c = 'Approved Extension';
        update cua;
        Assert.areEqual(cua.Status__c, [SELECT Case_Outcome__c FROM Case WHERE Id = :cse.Id].Case_Outcome__c);

        cua.Status__c = null;
        update cua;
        Assert.areEqual(cua.Status__c, [SELECT Case_Outcome__c FROM Case WHERE Id = :cse.Id].Case_Outcome__c);
        Test.stopTest();
    }

    @isTest static void testUpdateExistingSpecConCUAs() {
        Contact cont1 = new Contact(
            LastName = 'Test1',
            Email = 'cua.test1@example.com',
            Person_ID_unique__c = '1808'
        );
        Contact cont2 = new Contact(
            LastName = 'Test2',
            Email = 'cua.test2@example.com',
            Person_ID_unique__c = '2909'
        );
        insert new Contact[]{cont1, cont2};

        Case approvedCase = new Case(
            Subject = 'Test Spec Con Existing',
            Enquiry_Type__c = 'Special Consideration',
            Status = 'Solved',
            ContactId = cont1.Id
        );
        Case existingCase = approvedCase.clone();
        existingCase.Status = 'Open';
        Case existingCase2 = existingCase.clone();
        existingCase2.ContactId = cont2.Id;

        TriggerCommon.disableTrigger('Case');
        insert new Case[]{approvedCase, existingCase, existingCase2};
        TriggerCommon.enableTrigger('Case');

        final String moodleAssessmentId = 'SC_TEST_555';

        Case_Unit_Attempt__c approvedCua = new Case_Unit_Attempt__c(
            Enquiry__c = approvedCase.Id,
            Status__c = 'Approved Extension',
            Moodle_Assessment_ID__c = moodleAssessmentId,
            RecordTypeId = SpecConServices.CUA_RT_ID
        );
        Case_Unit_Attempt__c existingCua = new Case_Unit_Attempt__c(
            Enquiry__c = existingCase.Id,
            Moodle_Assessment_ID__c = moodleAssessmentId,
            RecordTypeId = SpecConServices.CUA_RT_ID
        );
        Case_Unit_Attempt__c existingCua2 = existingCua.clone();
        existingCua2.Enquiry__c = existingCase2.Id;

        insert new Case_Unit_Attempt__c[]{approvedCua, existingCua, existingCua2};

        Test.startTest();
        Case newCase = existingCase.clone(false);
        insert newCase;

        Case_Unit_Attempt__c newCua = new Case_Unit_Attempt__c(
            Enquiry__c = newCase.Id,
            Moodle_Assessment_ID__c = moodleAssessmentId,
            RecordTypeId = SpecConServices.CUA_RT_ID
        );
        insert newCua;
        Test.stopTest();

        Map<Id,Case_Unit_Attempt__c> result = new Map<Id,Case_Unit_Attempt__c>([
            SELECT Status__c, Enquiry__r.Status, Enquiry__r.Case_Outcome__c FROM Case_Unit_Attempt__c
        ]);
        Assert.areEqual(4, result.size());
        Case_Unit_Attempt__c approvedCuaResult = result.get(approvedCua.Id);
        Case_Unit_Attempt__c existingCuaResult = result.get(existingCua.Id);
        Case_Unit_Attempt__c existingCuaResult2 = result.get(existingCua2.Id);
        Case_Unit_Attempt__c newCuaResult = result.get(newCua.Id);

        Assert.areEqual('Approved Extension', approvedCuaResult.Status__c);
        Assert.areEqual('Solved', approvedCuaResult.Enquiry__r.Status);

        Assert.areEqual('Withdrawn', existingCuaResult.Status__c);
        Assert.areEqual('Withdrawn', existingCuaResult.Enquiry__r.Case_Outcome__c);
        Assert.areEqual('Solved', existingCuaResult.Enquiry__r.Status);

        Assert.areEqual(null, existingCuaResult2.Status__c);
        Assert.areEqual('Open', existingCuaResult2.Enquiry__r.Status);

        Assert.areEqual(null, newCuaResult.Status__c);
        Assert.areEqual('Open', newCuaResult.Enquiry__r.Status);
    }

    @isTest static void testSpecConEmails() {
        // SpecConServices_Test provides a more thorough validation of SpecConServices
        Case_Unit_Attempt__c cuaNotClosed = SpecConServices_Test.createCua();
        cuaNotClosed.RecordTypeId = SpecConServices.CUA_RT_ID;
        Case_Unit_Attempt__c cuaClosed = cuaNotClosed.clone();
        cuaClosed.Is_Closed_On_Create__c = false;
        Case_Unit_Attempt__c[] cuas = new Case_Unit_Attempt__c[]{cuaClosed, cuaNotClosed};
        insert cuas;
        cuaClosed.Is_Closed_On_Create__c = true;
        update cuas;
        Map<Id,Case_Unit_Attempt__c> results = new Map<Id,Case_Unit_Attempt__c>(
            [SELECT Emails_Sent__c, Approval_Email_Sent__c FROM Case_Unit_Attempt__c WHERE Id IN :cuas]
        );
        Assert.isFalse(SpecConServices.getEmailSent(results.get(cuaNotClosed.Id), SpecConServices.EMAIL_TYPE_APPROVED));
        Assert.isTrue(SpecConServices.getEmailSent(results.get(cuaClosed.Id), SpecConServices.EMAIL_TYPE_APPROVED));
        EmailMessage[] emailResults = [SELECT FromAddress FROM EmailMessage WHERE ParentId = :cuaNotClosed.Enquiry__c];
        Assert.areEqual(1, emailResults.size());
        Assert.areEqual(SpecConServices.FROM_ADDRESS_REGULAR, emailResults[0].FromAddress);
    }

}