/**
 * @author      Peter Sewell
 * @description Test class for TSP_EventsToBlockAsync
 * @group       Apex Class
 * @revision    28.02.24 - Peter Sewell - Created
 */
@isTest // (isParallel=true) not set due to DML operations not permitted PermissionSetAssignment
public class TSP_EventsToBlockAsync_Test {
    @TestSetup
    static void setupData() {
        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(LoggedInUser) {
            // Enable the Feature Switch Custom Settings
            Feature_Switch_TSP__c featureSwitch = new Feature_Switch_TSP__c();
            featureSwitch.Detect_File_Events__c = true;
            featureSwitch.Evaluate_TSP_in_Sandbox__c = true;
            insert featureSwitch; 
        }
        createContactWithDocument('John', 'Doe', 'TSPSampleDocument.pdf', Blob.valueOf('Sample document content'));
    } 

    // Test when user previews a file
    //
    @IsTest
    static void testFileAccessPreview() {

        // GIVEN a user accessing a file
        TSP_EventsToBlockAsync eventCondition;
        FileEventStore evt;
        Boolean evtResult;

        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ContentDocument doc = [SELECT Id, Title FROM ContentDocument WHERE Title = 'TSPSampleDocument.pdf'];

        // WHEN a file of interest
        System.runAs(loggedInUser) {
            test.startTest();
                // set up our event and its field values
                evt = new FileEventStore();
                evt.FileAction = 'PREVIEW';
                evt.UserId = loggedInUser.Id;
                evt.FileName = doc.Title;
                evt.DocumentId = doc.Id;

                // Fire the event
                eventCondition = new TSP_EventsToBlockAsync();
                evtResult = eventCondition.evaluate(evt);
            test.stopTest();
        }

        // THEN policy should return true
        // Test that the Apex returns true for this event
        System.assert(evtResult, 'File Access policy should return true'); 
    } 

    // Method to create a contact and link a document to it
    @future // avoid mixed DML error
    private static void createContactWithDocument(String contactFirstName, String contactLastName, String documentName, Blob documentBody) {
        // Create a new contact
        Contact newContact = new Contact(
            FirstName = contactFirstName,
            LastName = contactLastName
        );
        insert newContact;
        
        // Create a new ContentVersion to hold the document
        ContentVersion newContentVersion = new ContentVersion(
            Title = documentName,
            VersionData = documentBody,
            PathOnClient = documentName
        );
        insert newContentVersion;
        
        // Create a new ContentDocumentLink to link the document to the contact
        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :newContentVersion.Id];
        ContentDocumentLink newContentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = newContact.Id,
            ShareType = 'V'
        );
        insert newContentDocumentLink;
    }
}