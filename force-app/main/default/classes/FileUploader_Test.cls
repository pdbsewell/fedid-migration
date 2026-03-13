/**
 *  Test Fileuploader - linking to an Account
    @author  Shalini Mendu
 */
@isTest(isParallel=true)
public with sharing class FileUploader_Test {
    @isTest
    static void testFileUpload(){
        //create Account
        Account acc = new Account();
        acc.Name = 'FileUploader Agent activation';
        Database.insert(acc);
        // GIVEN: An account is present
            String base64 = 'J1RSSVNUQVInLCdEQVZFJywnSk9ITicsJ2Rqb2huQGdldG5kYWMuY29tJw==';
            // retrieve it again to get the ContentDocumentId
            Test.startTest();
        // WHEN: Button is clicked with a file to upload
                String Idd = FileUploader.uploadFile( base64, 'agent.csv',acc.Id );
            Test.stopTest();
        // THEN: The file should be linked to the Account
            List<ContentDocumentLink> cdlList = [Select Id, ContentDocumentId, LinkedEntityId from ContentDocumentLink where linkedentityid = : acc.Id];
            Assert.areEqual(1, cdlList.size(),'There should be one ContentDocumentLink record linked to this account id');
    }
   

}