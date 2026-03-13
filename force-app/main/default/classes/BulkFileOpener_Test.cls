/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
public class BulkFileOpener_Test {
	static testMethod void testGetAllDocuments() {
        Contact c = new Contact();
        c.LastName = 'Test';
        insert c;
        
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test'),
            IsMajorVersion = true
        );
        insert contentVersion_1;
        
        ContentVersion contentVersion_2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        
        ContentDocumentLink cld = new ContentDocumentLink();
        cld.LinkedEntityId = c.Id;
        cld.contentdocumentid = contentVersion_2.ContentDocumentId;
        cld.ShareType = 'V';
        insert cld;
        
        Test.startTest();
        
        BulkFileOpener.GetAllDocuments(c.Id);
        
        Test.stopTest();
    }
}