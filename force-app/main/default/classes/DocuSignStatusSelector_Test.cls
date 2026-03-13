/**
 * @description Test class for DocuSignStatusSelector
 */
@isTest(isParallel=true)
public class DocuSignStatusSelector_Test {

    private static final String DOCUSIGN_COMPLETED_ENVELOP_STATUS = 'Completed';

    @testSetup
    static void createTestData() { 

        // Disable triggers for unit testing
        TriggerCommon.disableTrigger('dsfs__DocuSign_Status__c');

        List<dsfs__DocuSign_Status__c> docuSignStatuses = 
            new List<dsfs__DocuSign_Status__c>();
        
        dsfs__DocuSign_Status__c docusignStatus1 = new dsfs__DocuSign_Status__c();
        docusignStatus1.dsfs__DocuSign_Envelope_ID__c = 'ABC123';
        docusignStatus1.dsfs__Envelope_Status__c = 
            DOCUSIGN_COMPLETED_ENVELOP_STATUS;

        docuSignStatuses.add(docusignStatus1);

        dsfs__DocuSign_Status__c docusignStatus2 = new dsfs__DocuSign_Status__c();
        docusignStatus2.dsfs__DocuSign_Envelope_ID__c = 'ABC456';
        docusignStatus2.dsfs__Envelope_Status__c = 
            DOCUSIGN_COMPLETED_ENVELOP_STATUS;

        docuSignStatuses.add(docusignStatus2);

        Set<Id> insertedRecordIds = new Set<Id>();
        Database.SaveResult[] saveResults = Database.insert(docuSignStatuses);
        for (Database.SaveResult result : saveResults) {
            insertedRecordIds.add(result.getId());
        }
    }

    @isTest
    static void shouldReturnDocuSignStatusesWhenIdsMatch() {
        DocuSignStatusSelector selector = new DocuSignStatusSelector();
        
        List<Id> idsInSystem = extractIdsFromDocuSignStatus(
            [SELECT Id FROM dsfs__DocuSign_Status__c]);

        List<dsfs__DocuSign_Status__c> results = selector.selectById(
            new Set<Id>(idsInSystem));
        System.assertEquals(idsInSystem.size(), results.size(), 
            'Expected the same number of DocuSign Status returned compared to all the records created');
    }

    @isTest
    static void shouldReturnDocuSignStatusWhenIdsMatchForOneRecord() {
        DocuSignStatusSelector selector = new DocuSignStatusSelector();
        // Get just the first record id
        List<Id> oneIdInSystem = extractIdsFromDocuSignStatus(
            [SELECT Id FROM dsfs__DocuSign_Status__c LIMIT 1]);

        List<dsfs__DocuSign_Status__c> results = selector.selectById(
            new Set<Id>(oneIdInSystem));
        System.assertEquals(1, results.size(), 
            'Expected the same number of DocuSign Status returned compared to all the records created');

    }

    @isTest
    static void shouldReturnAllDocuSignStatusMatchingIdAndStatus() {
        
        List<Id> idsInSystem = extractIdsFromDocuSignStatus(
            [SELECT Id FROM dsfs__DocuSign_Status__c WHERE 
            dsfs__Envelope_Status__c = :DOCUSIGN_COMPLETED_ENVELOP_STATUS]);

        DocuSignStatusSelector selector = new DocuSignStatusSelector();
        List<dsfs__DocuSign_Status__c> results = selector.selectByIdAndEnvelopStatus(
            new Set<Id>(idsInSystem), DOCUSIGN_COMPLETED_ENVELOP_STATUS);
        System.debug('results: ' + results);
        System.assertEquals(2, results.size(), 
            'Expected the 2 records');
    }

    private static List<Id> extractIdsFromDocuSignStatus(List<dsfs__DocuSign_Status__c> statuses) {
        List<Id> ids = new List<Id>();
        
        for (dsfs__DocuSign_Status__c status : statuses) {
            ids.add(status.Id);
        }

        return ids;
    }

}