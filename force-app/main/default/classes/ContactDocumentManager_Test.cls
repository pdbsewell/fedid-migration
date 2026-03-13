/**
 * @description This is unit test for ContactDocumentManager.cls
 */
@isTest(isParallel=true)
public class ContactDocumentManager_Test {

    /*
     * @description GIVEN Visa Application Checklist with 1 (one) Contact Document
     *              AND Application Checklist's Status equals to Submitted
     *              WHEN Assessor change checklist item from Visa to Other Documents
     *              AND click Save button
     *              THEN update Application Checklist's Status to Requested
     */
    @IsTest
    static void testRetrieveDataVisa() {
        // Given: Visa Application Checklist with 1 (one) Contact Document AND Application Checklist's Status equals to Submitted
        List<Application__c> applications = [SELECT Id, Applicant__r.Id FROM Application__c];
        Assert.isTrue(applications.size() > 0, '### Error No test application record retrieved. Insertion of test data failed.');

        // Create application checklist for Visa
        Document_Checklist__c checklistVisa = new Document_Checklist__c(
            Application__c = applications[0].Id,
            Rule_DeveloperName__c = 'Visa_Check',
            Status__c = 'Submitted',
            Unique_ID__c = String.valueOf(Date.today()),
            Allowed_Document_Type__c = 'OTHERDCTYP',
            Type__c = 'Visa'
        );
        insert checklistVisa;
        Assert.isTrue(checklistVisa.Id != null, '### Error insert DML for Application Checklist record.');

        // Create Contact Document for application checklist Visa
        Contact_Document__c contactDocument = new Contact_Document__c(
            Application__c = applications[0].Id,
            Document_Checklist__c = checklistVisa.Id,
            Document_Type__c = 'OTHERDCTYP',
            Contact__c = applications[0].Applicant__r.Id
        );
        insert contactDocument;
        Assert.isTrue(contactDocument.Id != null, '### Error insert DML for Contact Document record.');

        // Create a file and link it to the contact document
        ContentVersion cv = new ContentVersion(
            Title = 'Header_Picture1',
            PathOnClient = '/Header_Picture1.jpg',
            VersionData = Blob.valueOf('Unit Test ContentVersion Body'),
            Origin = 'H'
        );
        insert cv;
        Assert.isTrue(cv.Id != null, '### Error insert DML for ContentVersion record.');

        List<ContentDocument> conDocuments = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = contactDocument.Id,
            ContentDocumentId = conDocuments[0].Id,
            ShareType = 'V'
        );
        insert cdl;
        Assert.isTrue(cdl.Id != null, '### Error insert DML for ContentDocumentLink record.');

        Test.startTest();
        // When: Assessor changes checklist item from Visa to Other Documents AND clicks Save button
        Object retrieveDataResult = ContactDocumentManager.retrieveDataDocumentChecklist(contactDocument.Id);
        Assert.isTrue(retrieveDataResult != null);

        Object saveDocumentResult = ContactDocumentManager.saveDocumentDocumentChecklistWithDocumentOwnerMismatch(
            contactDocument.Id,
            'Other', // Changing from 'Visa' to 'Other'
            'OTHERDCTYP',
            conDocuments[0].Id,
            '',
            false,
            false
        );

        // Then: document is saved and Application Checklist's Status is updated to Requested
        Assert.isTrue(saveDocumentResult != null);
        Map<String, String> resultMap = (Map<String, String>) saveDocumentResult;
        Assert.isTrue(resultMap.containsKey('SUCCESS'));
        Test.stopTest();
        checklistVisa = [SELECT Id, Status__c FROM Document_Checklist__c WHERE Id = :checklistVisa.Id];
        Assert.areEqual('Requested', checklistVisa.Status__c, '### Application Checklist Status should be updated to Requested.');
    }

    /*
     * @description GIVEN a Contact Document record
     *              AND Contact Document's Document Type equals to Other Document Type
     *              WHEN Assessor change checklist item from Other Documents to Visa
     *              AND click Save button
     *              THEN update Visa Application Checklist's Status from:
     *              1. Requested to Submitted
     *              2. Insufficient to Insufficient
     *              3. Submitted to Submitted
     */
    @IsTest
    static void testRetrieveDataOther() {
        // Given: A Contact Document record AND Contact Document's Document Type equals to Other Document Type
        List<Application__c> applications = [SELECT Id, Applicant__r.Id FROM Application__c];
        Assert.isTrue(applications.size() > 0, '### Error No test application record retrieved. Insertion of test data failed.');

        // Create application checklist for Visa
        Document_Checklist__c checklistVisa = new Document_Checklist__c(
            Application__c = applications[0].Id,
            Rule_DeveloperName__c = 'Visa_Check',
            Status__c = 'Requested', // Start with 'Requested' status
            Unique_ID__c = String.valueOf(Date.today()),
            Allowed_Document_Type__c = 'OTHERDCTYP',
            Type__c = 'Visa'
        );
        insert checklistVisa;
        Assert.isTrue(checklistVisa.Id != null, '### Error insert DML for Application Checklist record.');

        // Create Contact Document not linked to any checklist
        Contact_Document__c contactDocument = new Contact_Document__c(
            Application__c = applications[0].Id,
            Document_Checklist__c = null,
            Document_Type__c = 'OTHERDCTYP',
            Contact__c = applications[0].Applicant__r.Id
        );
        insert contactDocument;
        Assert.isTrue(contactDocument.Id != null, '### Error insert DML for Contact Document record.');

        // Create a file and link it to the contact document
        ContentVersion cv = new ContentVersion(
            Title = 'Header_Picture2',
            PathOnClient = '/Header_Picture2.jpg',
            VersionData = Blob.valueOf('Unit Test ContentVersion Body'),
            Origin = 'H'
        );
        insert cv;
        Assert.isTrue(cv.Id != null, '### Error insert DML for ContentVersion record.');

        List<ContentDocument> conDocuments = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = contactDocument.Id,
            ContentDocumentId = conDocuments[0].Id,
            ShareType = 'V'
        );
        insert cdl;
        Assert.isTrue(cdl.Id != null, '### Error insert DML for ContentDocumentLink record.');

        Test.startTest();
        // When: Assessor changes checklist item from Other Documents to Visa and clicks Save button
        Object retrieveDataResult = ContactDocumentManager.retrieveDataDocumentChecklist(contactDocument.Id);
        Assert.isTrue(retrieveDataResult != null);

        Object saveDocumentResult = ContactDocumentManager.saveDocumentDocumentChecklist(
            contactDocument.Id,
            checklistVisa.Id, // Linking to Visa checklist
            'OTHERDCTYP',
            conDocuments[0].Id,
            '',
            false
        );

        // Then: document is saved and Application Checklist's Status is updated to Submitted
        Assert.isTrue(saveDocumentResult != null);
        Map<String, String> resultMap = (Map<String, String>) saveDocumentResult;
        Assert.isTrue(resultMap.containsKey('SUCCESS'));
        Test.stopTest();
        checklistVisa = [SELECT Id, Status__c FROM Document_Checklist__c WHERE Id = :checklistVisa.Id];
        // Since initial status is 'Requested', after submission it should change to 'Submitted'
        System.assertEquals('Submitted', checklistVisa.Status__c, '### Application Checklist Status should be updated to Submitted.');
    }

    @TestSetup static void setup() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Assert.isTrue(testAccount.Id != null, '### Insert Test Account Failed.');

        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test FirstName',
            LastName = 'Test LastName',
            MobilePhone = '0481977625',
            Email = 'testemail001@monash.edu',
            Monash_Email_Address__c = 'testemailmonash@monash.edu',
            Birthdate = Date.today().addYears(-11),
            SAP_Staff_Id__c = ''
        );
        insert testContact;
        Assert.isTrue(testContact.Id != null, '### Insert Test Contact Failed.');

        // Create Application
        Application__c testApplication = new Application__c(
            Applicant__c = testContact.Id,
            Status__c = 'Draft'
        );
        insert testApplication;
        Assert.isTrue(testApplication.Id != null, '### Insert Test Application Failed.');
    }
}