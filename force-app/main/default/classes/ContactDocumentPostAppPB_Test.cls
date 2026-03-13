/**
 * @author Trent De Laney
 * @date 19 Dec 2019 at 11:17:35 am
 * @group Test Class
 * @description Covers the execution of the ContactDocumentPostAppPB Invokeable methods
 */
@IsTest
public with sharing class ContactDocumentPostAppPB_Test {

    private static final string TEST_NAME = 'ContactDocumentPostApp';

    @TestSetup
    public static void setup() {
        Contact c = StudFirst_TestHelper.createApplicant();
        c.First_Name__c = TEST_NAME;
        insert c;

        Contact_Document__c contactDocument = StudFirst_TestHelper.createContactDocument(c.Id);
        contactDocument.Filename__c = TEST_NAME;
        insert contactDocument;

    }

    @IsTest
    public static void test_QueueFileToSend() {
        List<Contact_Document__c> contactDocuments = [
                SELECT Id
                FROM Contact_Document__c
                WHERE Filename__c = :TEST_NAME
        ];
        System.assertNotEquals(0, contactDocuments.size(), 'Unable to find the contact documents');

        List<Id> ids = new List<Id>();
        ids.add(contactDocuments[0].Id);
        ContactDocumentPostAppPB.QueueFileToSend(ids);
    }
}