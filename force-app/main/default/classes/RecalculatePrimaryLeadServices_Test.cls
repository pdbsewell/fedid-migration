/**
 * @author          J.Mapanao
 * @description     Service class for recalculating primary lead
 * @date            05.MAR.2020
 * @revision        
 *                  05.MAR.2020 - J.Mapanao - Initial Created
 */
@isTest(isParallel=true)
private class RecalculatePrimaryLeadServices_Test {

    @IsTest
    static void testRecalculatePrimaryLead() {
        Id contact_RecordTypeId_NotKnownToMonash = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'Non_Student' LIMIT 1].Id;
        Contact test_Contact = new Contact(
            LastName = 'Test Last Name Contact',
            FirstName = 'Test First Name Contact',
            RecordTypeId = contact_RecordTypeId_NotKnownToMonash
        );
        insert test_Contact;
        System.assert(test_Contact.Id != null, '### ERROR! Inserting test Contact record failed.');
        
        TriggerCommon.disableTrigger('Lead');

        Id lead_RecordTypeId_Lead = [SELECT Id FROM RecordType WHERE sObjectType = 'Lead' AND DeveloperName = 'Lead' LIMIT 1].Id;
        Id lead_RecordTypeId_Prospective_Student = [SELECT Id FROM RecordType WHERE sObjectType = 'Lead' AND DeveloperName = 'Prospective_Student' LIMIT 1].Id;
        Id lead_RecordTypeId_SR_Lead = [SELECT Id FROM RecordType WHERE sObjectType = 'Lead' AND DeveloperName = 'SR_Lead' LIMIT 1].Id;
        List<Lead> leadToInsert = new List<Lead>();
        Lead test_Lead1 = new Lead(
            Status = 'Open',
            LastName = 'Last Name Lead 1',
            Company = 'Company Lead 1',
            Contact__c = test_Contact.Id,
            Active_Lead_Contact_Id__c = '123123123123123123',
            RecordTypeId = lead_RecordTypeId_Lead
        );
        insert test_Lead1;
        System.debug('### test_Lead1:' + JSON.serializePretty(test_Lead1));
        System.assert(test_Lead1.Id != null, '### ERROR! Inserting test Lead 1 record failed.');
        Lead test_Lead2 = new Lead(
            Status = 'Qualified',
            LastName = 'Last Name Lead 2',
            Company = 'Company Lead 2',
            Contact__c = test_Contact.Id,
            Active_Lead_Contact_Id__c = '456456456456456456',
            RecordTypeId = lead_RecordTypeId_Prospective_Student
        );
        insert test_Lead2;
        System.debug('### test_Lead2:' + JSON.serializePretty(test_Lead2));
        System.assert(test_Lead2.Id != null, '### ERROR! Inserting test Lead 2 record failed.');
        Lead test_Lead3 = new Lead(
            Status = 'Contacted',
            LastName = 'Last Name Lead 3',
            Company = 'Company Lead 3',
            Contact__c = test_Contact.Id,
            Active_Lead_Contact_Id__c = test_Contact.Id,
            RecordTypeId = lead_RecordTypeId_SR_Lead
        );
        insert test_Lead3;
        System.debug('### test_Lead3:' + JSON.serializePretty(test_Lead3));
        System.assert(test_Lead3.Id != null, '### ERROR! Inserting test Lead 3 record failed.');
        TriggerCommon.enableTrigger('Lead');

        // Start Test
        Test.startTest();
        Map<Id, List<Lead>> contactIdListLeadMap = RecalculatePrimaryLeadServices.getContactAndLeadMap(test_Contact.Id);
        System.assert(!contactIdListLeadMap.isEmpty() , '### ERROR! No test lead has been created.');
        RecalculatePrimaryLeadServices.reCalculate(contactIdListLeadMap);
        Test.stopTest();
        
        Map<Id,Lead> leadMap = new Map<Id, Lead>([SELECT Id, Status, Active_Lead_Contact_Id__c FROM Lead WHERE Id =: test_Lead1.Id OR Id =: test_Lead2.Id OR Id =: test_Lead3.Id]);
        System.debug('### leadMap:' + JSON.serializePretty(leadMap));
        Integer primaryCount = 0;
        for (Lead loop_Lead : leadMap.values()) {
            if (loop_Lead.Active_Lead_Contact_Id__c != null) {
                primaryCount++;
            }
        }
        System.assertEquals(1, primaryCount, '### ERROR! Active Primary Lead is not equal to 1.');
    }
}