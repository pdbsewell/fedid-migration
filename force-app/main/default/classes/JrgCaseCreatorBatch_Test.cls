/**
 * @author          tom.gangemi@monash.edu
 * @description		SA-1629 JRG - Handle upload of "JRG Case" records
 * @date            Jul.2022
 * @group			Student Administration
 * Revision
 * 1.1   11.06.2024   Idhanoa     Enhancement to create OCR & Campaign Member (MCT-404)
 * 1.2   11.07.2024   Idhanoa     Enhancement to create OCR (MCT-414)
*/
@isTest(IsParallel=true)
public class JrgCaseCreatorBatch_Test {

    final static String CALLISTAID01 = '27806324_A2000';
    final static String CALENDARCODE01 = '10270_10593';

    @testSetup static void setup() {
        JrgCaseCreator_Test.setup();
    }

    @isTest static void testBatchWithErrors() {
        Campaign[] campaignResult = [SELECT Id FROM Campaign WHERE Type = 'JRG' ORDER By CreatedDate DESC LIMIT 1]; 
        JrgCaseCreator.JrgCaseRequest cr01 = JrgCaseCreator_Test.createReq('111', CALENDARCODE01, CALLISTAID01);
        cr01.inputCsvRow = 0;
        cr01.outreachPriority = 'Critical';
        Case ce01 = JrgCaseCreator.createCase(cr01);
        ce01.Campaign__c = campaignResult[0].Id;
        JrgCaseCreator.JrgCaseRequest cr02 = JrgCaseCreator_Test.createReq('XXX', CALENDARCODE01, CALLISTAID01); // invalid personId
        cr02.inputCsvRow = 1;
        cr02.outreachPriority = 'Critical';
        Case ce02 = JrgCaseCreator.createCase(cr02);
        ce02.Campaign__c = campaignResult[0].Id;
        
        Case[] casesForUpsert = new Case[]{ce01,ce02};
        Map<String,JrgCaseCreator.JrgCaseRequest> requestsByExternalId = new Map<String, JrgCaseCreator.JrgCaseRequest>{
            ce01.Alias__c => cr01, ce02.Alias__c => cr02
        };
        Contact con = [SELECT Id,Person_ID_unique__c FROM Contact WHERE Person_ID_unique__c = '111' ORDER BY CreatedDate DESC LIMIT 1];

        Course_Attempt__c ca = [SELECT Id,Callista_External_Id__c FROM Course_Attempt__c WHERE Callista_External_Id__c = :CALLISTAID01];

        Map<String, JrgCaseCreator.JrgCaseRequest> ocrRequestsByExternalId = new Map<String, JrgCaseCreator.JrgCaseRequest> { '111' + '-' + '27806324_A2000' => cr01 };
        Map<Id, String> personIdByContactId = new Map<Id, String>();
        personIdByContactId.put(con.Id, '111');

        Map<Id, String> callistaIdByCourseAttemptId = new Map<Id, String>();
        callistaIdByCourseAttemptId.put(ca.Id, '27806324_A2000');

        // GIVEN: The Batch params are setup 
        Test.startTest();
        // WHEN : The Batch is executed
        Database.executeBatch(new JrgCaseCreatorBatch(casesForUpsert, requestsByExternalId, ocrRequestsByExternalId, personIdByContactId, callistaIdByCourseAttemptId));
        Test.stopTest();

        // THEN: verify case creation
        Case[] caseResults = [SELECT Id, Alias__c FROM Case];
        System.assertEquals(1, caseResults.size(), 'Unexpected number of cases created');
        System.assertEquals(ce01.Alias__c, caseResults[0].Alias__c);

        CampaignMember[] campaignMembResults = [SELECT Id FROM CampaignMember WHERE COntactId = :con.id];
        System.assertEquals(1, campaignMembResults.size(), 'Unexpected number of campaign Member created');

        Outbound_Call_Result__c[] ocresults = [SELECT Id FROM Outbound_Call_Result__c WHERE COntact__c = :con.id];
        System.assertEquals(1, ocresults.size(), 'Unexpected number of ocr created');

        // verify email message and error CSV
        System.assert(JrgCaseCreatorBatch.emailMessage.subject.startsWith('JRG Upload - Errors'), JrgCaseCreatorBatch.emailMessage.subject);
        Messaging.EmailFileAttachment[] attachments = JrgCaseCreatorBatch.emailMessage.getFileAttachments();
        System.assertEquals(1, attachments.size());
        String rawCsv = attachments[0].body.toString();
        String[] csvRows = rawCsv.split('\n');
        System.assertEquals(3, csvRows.size(), '\n-----\n' + rawCsv);
        System.assert(csvRows[2].startsWith('1'), csvRows[2]);
        System.assert(csvRows[2].contains('Error'), csvRows[2]);
    }
}