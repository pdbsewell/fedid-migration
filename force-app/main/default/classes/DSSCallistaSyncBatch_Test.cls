/**
 * @author          Matthew Maramot
 * @description     Test class for DSSCallistaSyncBatch_Test
 * @revision        07/08/2025 - M. Maramot - Initial version
 */
@isTest(isParallel=true)
public with sharing class DSSCallistaSyncBatch_Test {
    static final Integer NUM_TEST_CONTACTS = 5;

    // Set up Mock Response
    private class MockDSSCallistaResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String resBody = '{"disabilitySupportDetails":{"privateRoom": "Y", "restMovement": "Y", "restMovementDescription": "00:15", "extraWritingTime": "Y", "extraWritingTimeDescription": "00:15", "scribe": "", "reader": "", "auslanInterpreter": "", "otherDescription": "OPTION TO WRITE OR TYPE DURING ON-CAMPUS EXAMS. E-COPY (PDF) AND HARD-COPY IN ON-CAMPUS EXAMS.  PLEASE USE CALI FONT STYLE IN ENGLISH EXAMS AND USE KIATI FONT STYLE IN CHINESE EXAMS; FONT REQUEST DOES NOT APPLY TO E-EXAMS.\\nNO MORE THAN 1 EXAM PER DAY.", "needs": "OPTION TO WRITE OR TYPE DURING ON-CAMPUS EXAMS. E-COPY (PDF) AND HARD-COPY IN ON-CAMPUS EXAMS.  PLEASE USE CALI FONT STYLE IN ENGLISH EXAMS AND USE KIATI FONT STYLE IN CHINESE EXAMS; FONT REQUEST DOES NOT APPLY TO E-EXAMS.\\nNO MORE THAN 1 EXAM PER DAY.", "threeSidedCubicle": "Y", "documentationExpirySemester": 2, "documentationExpiryYear": 2024, "officerResponsible": "DSS OFFICER", "specialConsideration": "Y", "preferentialTimetabling": "", "flexibleAttendance": ""}}';
            res.setBody(resBody);
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup
    static void createTestContacts() {
        // Create 10 test Contact records
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < NUM_TEST_CONTACTS; i++) {
            contacts.add(new Contact(
                LastName = 'LastName' + i, 
                FirstName ='Test',
                DSS_Registered__c = true,
                Person_Id_unique__c = '0000000' + i
            ));
        }
        insert contacts;
    }

    @isTest
    static void testContactSync() {
        // Set the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockDSSCallistaResponse());

        // Set custom metadata entry
        System_Settings__mdt setting = new System_Settings__mdt();
        setting.Is_Active__c = true;
        setting.Value__c = '{"querySELECT" : "id,person_id__c,dss_registered__c", "queryFROM" : "Contact", "queryWHERE" : "dss_registered__c = TRUE AND person_id__c != null", "maxRecords" : "10000", "personIdField" : "person_id__c", "fieldMapping" : {"officerResponsible" : "dss_officer__c"}}';
        SystemSettingsUtil.getInstance().gssByFeatureKeyMap.put(
            DSSCallistaSyncBatch.SYS_SETTINGS_FEATURE+'CONTACT', setting);

        // GIVEN: We have a batch job to sync Callista Data for DSS Registered Contacts
        DSSCallistaSyncBatch batch = new DSSCallistaSyncBatch('CONTACT'); 

        // WHEN: The batch runs
        Test.startTest();
        Database.executeBatch(batch, 50); 
        Test.stopTest();

        // THEN: DSS Officer should now be updated to match values from response
        List<Contact> updatedContacts = [SELECT Id, DSS_Officer__c FROM Contact WHERE DSS_Registered__c = true AND DSS_Officer__c != null];
        Assert.isTrue(updatedContacts.size() == NUM_TEST_CONTACTS, 'Expected ' + NUM_TEST_CONTACTS + ' Contacts to be updated with a DSS Officer, but only ' + updatedContacts.size() + ' were updated.');
    }
}