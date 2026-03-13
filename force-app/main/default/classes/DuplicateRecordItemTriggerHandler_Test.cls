/**
 * @description       : Test class to verify DuplicateRecordItemTriggerHandler
 * @author            : Sachin Shetty
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   2022-06-06   Sachin   Initial Version 
**/
@isTest
public with sharing class DuplicateRecordItemTriggerHandler_Test {

    @testSetup
    static void setup() {
        List<Contact> testContacts = new List<Contact>{
            new Contact(
                LastName = 'Test 1'
            ),
            new Contact(
                LastName = 'Test 2'
            ),
            new Contact(
                LastName = 'Test 3'
            ),
            new Contact(
                LastName = 'Test 4'
            )
        };
        insert testContacts;
        
        DuplicateRule rule = [SELECT id FROM DuplicateRule WHERE DeveloperName = 'Contact_Perfect_Match' LIMIT 1];
                         
        List<DuplicateRecordSet> drsRecords = new List<DuplicateRecordSet>{
            new DuplicateRecordSet(
                duplicateRuleId = rule.id,
                Process__c = true
            ),
            new DuplicateRecordSet(
                duplicateRuleId = rule.id,
                Process__c = true
            )
        };
        insert drsRecords;

        List<DuplicateRecordItem> items = new List<DuplicateRecordItem>{
            new DuplicateRecordItem(
                duplicateRecordSetId = drsRecords.get(0).id,
                recordId = testContacts.get(0).id
            ),
            new DuplicateRecordItem(
                duplicateRecordSetId = drsRecords.get(0).id,
                recordId = testContacts.get(1).id
            ),
            new DuplicateRecordItem(
                duplicateRecordSetId = drsRecords.get(1).id,
                recordId = testContacts.get(2).id
            ),
            new DuplicateRecordItem(
                duplicateRecordSetId = drsRecords.get(1).id,
                recordId = testContacts.get(3).id
            )
        };
        insert items;
    }

    @isTest
    public static void test_ProcessUnchecked(){

        // Given
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Test 1' LIMIT 1];
        List<DuplicateRecordItem> driRecords = [SELECT Id, duplicateRecordSetId FROM DuplicateRecordItem WHERE recordId =:testContact.Id];
        Id drsrecordId = driRecords.get(0).duplicateRecordSetId;

        // When
        Test.startTest();
            delete driRecords;
        Test.stopTest();

        // Then
        List<DuplicateRecordSet> drsRecords = [SELECT Id, Process__c FROM DuplicateRecordSet];
        System.assertEquals(2, drsRecords.size(), 'Incorrect number of DuplicateRecordSet records returned');
        for(DuplicateRecordSet drsRecord : drsRecords){
            if(drsRecord.Id == drsrecordId){
                System.assertEquals(false, drsRecord.Process__c, 'Process field should have been unchecked');
            }
            else{
                System.assertEquals(true, drsRecord.Process__c, 'Process field should have been checked');
            }
        }
    }
}