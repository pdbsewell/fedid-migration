/**
 * @description Test class to cover ElevatedDAO
 * @author      Kai-Fan Hsieh
 * @since       03 July 2024
 */
@isTest(isParallel=true)
private class ElevatedDAO_Test {
    private final static String OTHER_DOC_TYPE = 'OTHERDCTYP';

    /**
     * @description Test setup method to create initial test data.
     */
    @TestSetup
    static void setupData() {
        // Create a new Contact for testing
        Contact testContact = StudFirst_TestHelper.createApplicant();
        testContact.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        testContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId();
        Date dtToday = Date.today();
        testContact.Birthdate = dtToday.addYears(-20);
        insert testContact;
    }

    /**
     * @description Tests the insertRecords method of ElevatedDAO to verify multiple records insertion with elevated access.
     */
    @isTest
    static void test_InsertRecords() {
        // Given : init test data
        List<Contact_Document__c> contactDocuments = new List<Contact_Document__c>{
            getNewContactDocument(getContactId()),
            getNewContactDocument(getContactId())
        };

        // When : run as minimal access user and perform DAO with elevated access
        System.runAs(StudFirst_TestHelper.buildMinimalAccessApiUser()) {
            Test.startTest();
            new ElevatedDAO().insertRecords(contactDocuments);
            Test.stopTest();
        }

        // Then : verify the results
        List<Contact_Document__c> insertedContactDocuments = [SELECT Id, Name FROM Contact_Document__c];
        Assert.areEqual(2, insertedContactDocuments.size(), 'Unexpected number of contact documents inserted');
    }

    /**
     * @description Tests the insertRecord method of ElevatedDAO to verify a single record insertion with elevated access.
     */
    @isTest
    static void test_InsertRecord() {
        // Given : init test data
        Contact_Document__c contactDocument = getNewContactDocument(getContactId());

        // When : run as minimal access user and perform DAO with elevated access
        System.runAs(StudFirst_TestHelper.buildMinimalAccessApiUser()) {
            Test.startTest();
            new ElevatedDAO().insertRecord(contactDocument);
            Test.stopTest();
        }

        // Then : verify the results
        List<Contact_Document__c> insertedContactDocuments = [SELECT Id, Name FROM Contact_Document__c];
        Assert.areEqual(1, insertedContactDocuments.size(), 'Unexpected number of contact documents inserted');
    }

    /**
     * @description Tests the insertRecord method of ElevatedDAO to verify record insertion without elevated access.
     */
    @isTest
    static void test_InsertRecord_Negative() {
        // Given : init test data
        Contact_Document__c testContactDocument = getNewContactDocument(getContactId());

        // When : run as minimal access user and perform DAO without elevated access
        System.runAs(StudFirst_TestHelper.buildMinimalAccessApiUser()) {
            Test.startTest();
            Database.insert(testContactDocument, false);
            Test.stopTest();
        }

        // Then : verify the results
        List<Contact_Document__c> insertedContactDocuments = [SELECT Id, Name FROM Contact_Document__c];
        Assert.areEqual(0, insertedContactDocuments.size(), 'Unexpected number of contact documents inserted');
    }

    /**
     * @description Tests the updateRecords method of ElevatedDAO to verify multiple records update with elevated access.
     */
    @isTest
    static void test_UpdateRecords() {
        // Given : create test records
        List<Contact_Document__c> contactDocuments = new List<Contact_Document__c>();
        for (Integer i = 0; i < 5; i++) {
            contactDocuments.add(getNewContactDocument(getContactId()));
        }
        insert contactDocuments;

        List<Database.SaveResult> results;
        // When : run as minimal access user and perform DAO with elevated access
        System.runAs(StudFirst_TestHelper.buildMinimalAccessApiUser()) {
            Test.startTest();
            results = new ElevatedDAO().updateRecords(contactDocuments);
            Test.stopTest();
        }

        // Then : verify the results
        Assert.areEqual(5, results.size(), 'Unexpected number of update results');
        for (Database.SaveResult result : results) {
            Assert.isTrue(result.isSuccess(), 'Update should be successful');
        }
    }

    /**
     * @description Tests the updateRecord method of ElevatedDAO to verify a single record update with elevated access.
     */
    @isTest
    static void test_UpdateRecord() {
        // Given : create test records
        Contact_Document__c contactDocument = getNewContactDocument(getContactId());
        insert contactDocument;

        Database.SaveResult result;
        // When : run as minimal access user and perform DAO with elevated access
        System.runAs(StudFirst_TestHelper.buildMinimalAccessApiUser()) {
            Test.startTest();
            result = new ElevatedDAO().updateRecord(contactDocument);
            Test.stopTest();
        }
        // Then : verify the results
        Assert.isTrue(result.isSuccess(), 'Update should be successful');
    }

    /**
     * @description Tests the updateRecord method of ElevatedDAO to verify record update without elevated access.
     */
    @isTest
    static void test_UpdateRecord_Negative() {
        // Given : init test data
        Contact_Document__c contactDocument = getNewContactDocument(getContactId());
        insert contactDocument;

        Database.SaveResult result;
        // When : run as minimal access user and perform DAO without elevated access
        System.runAs(StudFirst_TestHelper.buildMinimalAccessApiUser()) {
            Test.startTest();
            result = Database.update(contactDocument, false);
            Test.stopTest();
        }

        // Then : verify the results
        Assert.isFalse(result.success, 'Update should be failed');
    }

    /**
     * @description Retrieves the Id of a test Contact record.
     * @return Id of a Contact.
     */
    private static Id getContactId() {
        return [SELECT Id FROM Contact LIMIT 1].Id;
    }

    /**
     * @description Creates and returns a new Contact_Document__c record.
     * @param contactId The Id of the associated Contact.
     * @return A new Contact_Document__c object.
     */
    private static Contact_Document__c getNewContactDocument(Id contactId) {
        return new Contact_Document__c(
            Contact__c = getContactId(),
            Document_Type__c = OTHER_DOC_TYPE
        );
    }
}