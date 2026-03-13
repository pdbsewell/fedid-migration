@isTest(isParallel=true)
private class MonashCollegeFileUploadService_Test {

    @isTest
	private static void testGetAttachments() {
        //Initialize test records
        Case testCase = new Case();
        insert testCase;
        
        ContentDocument testDoc = createTestDocument(true, testCase.Id);
        
        //Run test
        List<ContentVersion> retrievedDocs = new List<ContentVersion>();
        Test.startTest();
            retrievedDocs.addAll(MonashCollegeFileUploadService.getAttachments(testCase.Id));
        Test.stopTest();
        
        //Assert results
        System.assert(retrievedDocs.size() > 0);
	}
	
	@isTest
	private static void testSaveDocument() {
        //Initialize test records
        Case testCase = new Case();
        insert testCase;
        
        ContentDocument testDoc = createTestDocument(true, testCase.Id);
        
        Blob bodyBlob = Blob.valueOf('Test File Content');
        
        //Run test
        Id fileId;
        Test.startTest();
            fileId = MonashCollegeFileUploadService.saveChunk(testCase.Id, 'TestFileName', bodyBlob.toString(), 'text/plain', '');
        Test.stopTest();
        
        //Assert results
        System.assert(fileId != null);
	}
	
	@isTest
	private static void testAppendDocument() {
        //Initialize test records
        Case testCase = new Case();
        insert testCase;
        
        ContentDocument testDoc = createTestDocument(true, testCase.Id);
        
        Blob bodyBlob = Blob.valueOf('Test File Content');
        
        //Run test
        Id fileId;
        Test.startTest();
            fileId = MonashCollegeFileUploadService.saveChunk(testCase.Id, 'TestFileName', bodyBlob.toString(), 'text/plain', '');
            fileId = MonashCollegeFileUploadService.saveChunk(testCase.Id, 'TestFileName', bodyBlob.toString(), 'text/plain', fileId);
        Test.stopTest();
        
        //Assert results
        System.assert(fileId != null);
	}
	
	@isTest
	private static void testDeleteAttachment(){
	    //Initialize test records
        Case testCase = new Case();
        insert testCase;
        
        ContentDocument testDoc = createTestDocument(true, testCase.Id);
        
        //Run test
        String deleteResultText;
        Test.startTest();
            deleteResultText = MonashCollegeFileUploadService.deleteFile(testDoc.Id);
        Test.stopTest();
        
        //Assert results
        System.assert(deleteResultText == 'SUCCESS');
	}
    
    static ContentDocument createTestDocument(Boolean allAccess, Id parentId){
        // create a file
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
                Title='Header_Picture1',
                PathOnClient ='/Header_Picture1.jpg',
                VersionData = bodyBlob,
                origin = 'H',
                FirstPublishLocationId = parentId
        );

        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE id =: cv.Id];

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId
        FROM ContentDocument
        WHERE id=:cv.ContentDocumentId];
        ContentDocument file = documents[0];

        if(allAccess){
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = UserInfo.getOrganizationId();
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'C';
            cdLink.Visibility = 'AllUsers';

            insert cdLink;

        }

        return file;
    }
}