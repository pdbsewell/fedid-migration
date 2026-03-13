/**
 * @author          tom.gangemi@monash.edu
 * @description		SA-1629 JRG - Handle upload of "JRG Case" records
 * @date            Jul.2022
 * @group			Student Administration
 * Revision
 * 1.1   11.06.2024   Idhanoa     Enhancement to create OCR & Campaign Member (MCT-404)
*/
@isTest(IsParallel=true)
public class JrgCaseCreator_Test {

    final static String CALLISTAID01 = '27806324_A2000';
    final static String CALENDARCODE01 = '10270_10593';

    /**
     * @description Method to create a Request
     * @param personId Person Id
     * @return Wrapper class 
     */
    public static JrgCaseCreator.JrgCaseRequest createReq(String personId) {
        return createReq(personId, CALENDARCODE01, CALLISTAID01);
    }

    /**
     * @description Method to create a Request
     * @param personId Person Id
     * @param calendarCode calendar Code
     * @param callistaId callista Id
     * @return Wrapper class 
     */
    public static JrgCaseCreator.JrgCaseRequest createReq(String personId, String calendarCode, String callistaId) {
        JrgCaseCreator.JrgCaseRequest req = new JrgCaseCreator.JrgCaseRequest();
        req.personId = personId;
        req.calendarCode = calendarCode;
        req.courseAttemptCallistaId = callistaId;
        return req;
    }

    /**
     * @description Method to debug Errors 
     * @param errors Array of the Wrapper class
     * @return String of the Error message
     */
    public static String debugErrors(JrgCaseCreator.ValidationError[] errors) {
        String[] out = new String[0];
        for(JrgCaseCreator.ValidationError e :errors) {
            out.add('Message: ' + e.message + ', Reference: ' + e.reference);
        }
        return String.join(out, '\n');
    }

    /**
     * @description Method to setup Data 
     */
    @testSetup public static void setup() {
        insert new Campaign(
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Advisory').getRecordTypeId(),
            Type = 'JRG',
            EndDate = Date.Today(),
            Name = 'JRG Campaign'
        );
        Course__c course = (Course__c)TestDataFactory.createSObject(new Course__c());
        insert course;
        TriggerCommon.disableTrigger('Contact');
        Contact cont = (Contact)TestDataFactory.createSObject(new Contact());
        cont.Person_ID_unique__c = '111';
        Contact cont2 = (Contact)TestDataFactory.createSObject(new Contact());
        cont2.Person_ID_unique__c = '222';
        Contact cont3 = (Contact)TestDataFactory.createSObject(new Contact());
        cont3.Person_ID_unique__c = '333';
        Contact cont4 = (Contact)TestDataFactory.createSObject(new Contact());
        cont4.Person_ID_unique__c = '444';
        insert new Contact[]{cont, cont2,cont3, cont4};
        Course_Attempt__c ca = new Course_Attempt__c(
            Callista_External_Id__c = CALLISTAID01, Course__c = course.Id,
            Contact__c = cont.Id, Course_Attempt_Status__c = 'Enrolled'
        );
        insert ca;
        Calendar__c cal = new Calendar__c(Calendar_Code__c = CALENDARCODE01);
        insert cal;
    }

    @isTest static void testValidateOk() {
        // GIVEN: The setup of Input parameters are done
        JrgCaseCreator.JrgCaseRequest ce01 = createReq('111');
        JrgCaseCreator.JrgCaseRequest ce02 = createReq('222');
        Campaign[] campaignResult = [SELECT Id, EndDate FROM Campaign WHERE Type = 'JRG' ORDER By CreatedDate DESC LIMIT 1]; 

        // Act
        Test.startTest();
        JrgCaseCreator.ValidationError[] errors = JrgCaseCreator.validateRequests(
            new JrgCaseCreator.JrgCaseRequest[]{ce01, ce02}, campaignResult
        );
        Test.stopTest();

        // Assert
        System.assertEquals(0, errors.size(), debugErrors(errors));
    }

    @isTest static void testValidateError() {
        Campaign[] campaignResult = [SELECT Id, EndDate FROM Campaign WHERE Type = 'JRG' ORDER By CreatedDate DESC LIMIT 1];
        JrgCaseCreator.JrgCaseRequest ce01 = createReq('111', 'INVALID_CA_01', 'INVALID_CAL_01');
        JrgCaseCreator.JrgCaseRequest ce02 = createReq('222', 'INVALID_CA_01', 'INVALID_CAL_02');
        JrgCaseCreator.JrgCaseRequest ce03 = createReq('333');

        // WHEN: The method is invoked
        Test.startTest();
        JrgCaseCreator.ValidationError[] errors = JrgCaseCreator.validateRequests(
            new JrgCaseCreator.JrgCaseRequest[]{ce01, ce02, ce03}, campaignResult
        );
        Test.stopTest();

        // THEN: The errors are captured
        System.assertEquals(3, errors.size(), debugErrors(errors));
    }

    @isTest static void testInsertRecords() {
        // GIVEN: The setup of Input parameters are done
        Id campaignId = [SELECT Id FROM Campaign WHERE Type = 'JRG' LIMIT 1].Id;
        JrgCaseCreator.JrgCaseRequest cr01 = createReq('111', CALENDARCODE01, CALLISTAID01);
        Case ce01 = JrgCaseCreator.createCase(cr01);
        JrgCaseCreator.JrgCaseRequest cr02 = createReq('222', CALENDARCODE01, CALLISTAID01);
        Case ce02 = JrgCaseCreator.createCase(cr02);
        ce02.Number_Of_Occurrences__c = 2;
        insert new Case[]{ce01, ce02};

        JrgCaseCreator.JrgCaseRequest cr03 = createReq('111'); // update
        JrgCaseCreator.JrgCaseRequest cr04 = createReq('222'); // update
        JrgCaseCreator.JrgCaseRequest cr05 = createReq('222'); // update
        JrgCaseCreator.JrgCaseRequest cr06 = createReq('333');
        cr06.outreachPriority = 'Critical';
        JrgCaseCreator.JrgCaseRequest cr07 = createReq('333');
        cr07.outreachPriority = 'Critical';
        JrgCaseCreator.JrgCaseRequest cr08 = createReq('444');
        cr08.outreachPriority = 'Medium';
        cr07.outreachCategory = 'Consecutive Assessment Fails';
        cr08.outreachCategory = 'Consecutive Assessment Fails;Studying Elsewhere';
        cr08.suppliedState = 'WCI_MO';
        cr08.unitCode = 'FIT1045';

        JrgCaseCreator.JrgCaseRequest[] caseExts = new JrgCaseCreator.JrgCaseRequest[]{
            cr03, cr04, cr05, cr06, cr07, cr08
        };

        
        Test.startTest();
        // WHEN: The Batch is invoked
        JrgCaseCreator.RequestResponse rr = JrgCaseCreator.submitCreationRequest(caseExts, String.valueOf(campaignId));
        Test.stopTest();

        // THEN: The records are created
        System.assertEquals(true, rr.success, debugErrors(rr.errors));

        Map<String, Case> casesByExternalId = new Map<String, Case>();
        Case[] caseResults = [
            SELECT Subject, Alias__c, ContactId, Number_Of_Occurrences__c, Risk_Category__c, Priority,
                Calendar__r.Calendar_Code__c, Course_Attempt__r.Callista_External_Id__c, Campaign__c, Status,
                Supplied_State__c, Unit_Code__c
            FROM Case
        ];
        System.assertEquals(4, caseResults.size());
        for(Case c :caseResults) {
            casesByExternalId.put(c.Alias__c, c);
        }

        Case ce111 = casesByExternalId.get(ce01.Alias__c);
        System.assertEquals(2, ce111.Number_Of_Occurrences__c);
        System.assertEquals(ce01.Subject, cr01.personId + ' - JRG - ' + cr01.calendarCode);

        Case ce222 = casesByExternalId.get(ce02.Alias__c);
        System.assertEquals(3, ce222.Number_Of_Occurrences__c);

        Case ce333 = casesByExternalId.get(JrgCaseCreator.createExternalId(cr07));
        System.assertEquals(cr06.outreachPriority, ce333.Priority);
        System.assertEquals(1, ce333.Number_Of_Occurrences__c);
        System.assertEquals(cr07.outreachCategory, ce333.Risk_Category__c);
        System.assertEquals(campaignId, ce333.Campaign__c);
        Assert.areEqual('Open', ce333.Status);

        Case ce444 = casesByExternalId.get(JrgCaseCreator.createExternalId(cr08));
        System.assertEquals(1, ce444.Number_Of_Occurrences__c);
        System.assertEquals(cr08.outreachPriority, ce444.Priority);
        System.assert(ce444.Risk_Category__c.contains('Consecutive Assessment Fails'));
        System.assert(ce444.Risk_Category__c.contains('Studying Elsewhere'));
        Assert.areEqual('Solved', ce444.Status);
        Assert.areEqual(cr08.suppliedState, ce444.Supplied_State__c);
        Assert.areEqual(cr08.unitCode, ce444.Unit_Code__c);

        System.assertNotEquals(null, JrgCaseCreatorBatch.emailMessage);
        System.assert(JrgCaseCreatorBatch.emailMessage.subject.startsWith('JRG Upload - Success'), JrgCaseCreatorBatch.emailMessage.subject);

        CampaignMember[] campMembResults = [SELECT Id FROM CampaignMember];
        Assert.areEqual(campMembResults.size(), 1, 'Campaign Member Creation Mismatch');
    }

    @IsTest static void getCsvMappingTest() {
        // Given - mapping is stored in custom metadata
        // When - mapping is retrieved
        String mappingJson = JrgCaseCreator.getDefaultCsvMappingJSON();
        if(String.isNotBlank(mappingJson)) {
            try {
                JSON.deserialize(mappingJson, Map<String,String>.class);
            } catch (Exception e) {
                // Then - mapping should be valid if it is not blank
                Assert.fail('Failed to parse mapping JSON: ' + e.getMessage());
            }
        }
    }
}