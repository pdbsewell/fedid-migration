/**
 * @author      Peter Sewell
 * @description Test class for TSP_EventsToBlock
 * @group       Apex Class
 * @revision    23.11.23 - Peter Sewell - Created
 *              09.01.24 - Peter Sewell - Test 'SAML Idp Initiated SSO' login type
 *              27.02.24 - Peter Sewell - Test File Event detection
 * 				02.08.25 - Sachin Shetty- Test allow listed application - Mulesoft JWT App
 */
@isTest // (isParallel=true) not set due to DML operations not permitted PermissionSetAssignment
public class TSP_EventsToBlock_Test {

    @TestSetup
    static void setupData() {
        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(LoggedInUser) {
            // Enable the Feature Switch Custom Settings
            Feature_Switch_TSP__c featureSwitch = new Feature_Switch_TSP__c();
            featureSwitch.Detect_Non_SSO_Login__c = true;
            featureSwitch.Detect_File_Events__c = true;
            featureSwitch.Evaluate_TSP_in_Sandbox__c = true;
            insert featureSwitch; 
        }
        assignSsoEnforcementPerm(loggedInUser.Id);
        createTestUserNonSso();

        createContactWithDocument('John', 'Doe', 'TSPSampleDocument.pdf', Blob.valueOf('Sample document content'));
        createContactWithDocument('Jane', 'Doe', ArchiveDocumentUtilities.ARCHIVE_TITLE_PREFIX + 'TSPSampleDocument.pdf', Blob.valueOf('Sample document content'));

    } 
    
    // User attempts to login directly but has SSO enforcement perms
    // Should be blocked
    @IsTest
    static void testNonSsoLoginBlock() {

        // GIVEN a user logging in
        TSP_EventsToBlock eventCondition;
        LoginEvent evt;
        Boolean evtResult;

        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // WHEN not SSO
        System.runAs(loggedInUser) {
            test.startTest();
                // set up our event and its field values
                evt = new LoginEvent();
                evt.LoginType = 'Lightning Login';  // Non SSO
                evt.Application = 'Browser';        // Non SSO only enforced when app is browser
                evt.UserId = loggedInUser.Id;

                // Fire the event
                eventCondition = new TSP_EventsToBlock();
                evtResult = eventCondition.evaluate(evt);
            test.stopTest();
        }

        // THEN policy should return true
        // Test that the Apex returns true for this event
        Assert.isTrue(evtResult, 'SSO policy should return true'); 
    } 

    // User attempts to login via non SSO however not via browser (so could be oauth)
    // Should be allowed
    @IsTest
    static void testNonSsoLoginAllowApp() {

        // GIVEN a user logging in
        TSP_EventsToBlock eventCondition;
        LoginEvent evt;
        Boolean evtResult;

        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // WHEN not SSO but non browser
        System.runAs(loggedInUser) {
            test.startTest();
                // set up our event and its field values
                evt = new LoginEvent();
                evt.LoginType = 'Remote Access 2.0';        // Non SSO
                evt.Application = 'Salesforce Connector';   // Non SSO however app is non browser
                evt.UserId = loggedInUser.Id;

                // Fire the event
                eventCondition = new TSP_EventsToBlock();
                evtResult = eventCondition.evaluate(evt);
            test.stopTest();
        }

        // THEN policy should return false
        // Test that the Apex returns true for this event
        Assert.isFalse(evtResult, 'SSO policy should return false'); 
    } 

    // User attempts to login directly but does NOT have SSO enforcement perm 
    // Should be allowed
    @IsTest
    static void testNonSsoLoginAllow() {

        // GIVEN a user logging in
        TSP_EventsToBlock eventCondition;
        LoginEvent evt;
        Boolean evtResult;

        User testUser = getTestUserNonSso();

        // WHEN SSO not enforced for this user via perm set
        System.runAs(testUser) {
            test.startTest();
                // set up our event and its field values
                evt = new LoginEvent();
                evt.LoginType = 'Lightning Login'; // Non SSO
                evt.Application = 'Browser';       
                evt.UserId = testUser.Id;

                // Fire the event
                eventCondition = new TSP_EventsToBlock();
                evtResult = eventCondition.evaluate(evt);
            test.stopTest();
        }

        // THEN policy should return false
        // Test that the Apex returns false for this event
        Assert.isFalse(evtResult, 'SSO policy should return false'); 
    } 

    // User attempts to login via SSO
    // Should be allowed
    @IsTest
    static void testSsoLoginAllowSfdcInitiated() {

        // GIVEN a user logging in
        TSP_EventsToBlock eventCondition;
        LoginEvent evt;
        Boolean evtResult;

        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // WHEN user logs in using SSO
        System.runAs(loggedInUser) {
            test.startTest();
                // set up our event and its field values
                evt = new LoginEvent();
                evt.LoginType = 'SAML Sfdc Initiated SSO'; // SSO
                evt.Application = 'Browser';        // Non SSO only enforced when app is broswer
                evt.UserId = loggedInUser.Id;

                // Fire the event
                eventCondition = new TSP_EventsToBlock();
                evtResult = eventCondition.evaluate(evt);
            test.stopTest();
        }

        // THEN policy should return false
        // Test that the Apex returns false for this event
        Assert.isFalse(evtResult, 'SSO policy should return false');
    } 

    // User attempts to login via SSO
    // Should be allowed
    @IsTest
    static void testSsoLoginAllowIdpInitiated() {

        // GIVEN a user logging in
        TSP_EventsToBlock eventCondition;
        LoginEvent evt;
        Boolean evtResult;

        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // WHEN user logs in using SSO
        System.runAs(loggedInUser) {
            test.startTest();
                // set up our event and its field values
                evt = new LoginEvent();
                evt.LoginType = 'SAML Idp Initiated SSO'; // SSO
                evt.Application = 'Browser';        // Non SSO only enforced when app is broswer
                evt.UserId = loggedInUser.Id;

                // Fire the event
                eventCondition = new TSP_EventsToBlock();
                evtResult = eventCondition.evaluate(evt);
            test.stopTest();
        }

        // THEN policy should return false
        // Test that the Apex returns false for this event
        Assert.isFalse(evtResult, 'SSO policy should return false');
    } 

    // Test when user downloads a file
    //
    @IsTest
    static void testFileAccessDownload() {

        // GIVEN a user accessing a file
        TSP_EventsToBlock eventCondition;
        FileEventStore evt;
        Boolean evtResult;

        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ContentDocument doc = [SELECT Id, Title FROM ContentDocument WHERE Title = 'TSPSampleDocument.pdf'];

        // WHEN a file of interest
        System.runAs(loggedInUser) {
            test.startTest();
                // set up our event and its field values
                evt = new FileEventStore();
                evt.FileAction = 'UI_DOWNLOAD';
                evt.UserId = loggedInUser.Id;
                evt.FileName = doc.Title;
                evt.DocumentId = doc.Id;

                // Fire the event
                eventCondition = new TSP_EventsToBlock();
                evtResult = eventCondition.evaluate(evt);
            test.stopTest();
        }

        // THEN policy should return true
        // Test that the Apex returns true for this event
        Assert.isTrue(evtResult, 'File Access policy should return true');
    } 

    // Test when user previews a file
    //
    @IsTest
    static void testFileAccessPreview() {

        // GIVEN a user accessing a file
        TSP_EventsToBlock eventCondition;
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
                eventCondition = new TSP_EventsToBlock();
                evtResult = eventCondition.evaluate(evt);
            test.stopTest();
        }

        // THEN policy should return true
        // Test that the Apex returns true for this event
        Assert.isTrue(evtResult, 'File Access policy should return true'); 
    } 

    // Test when user previews an archived file
    // Should be ignored
    //
    @IsTest
    static void testArchivedFileAccessPreview() {

        // GIVEN a user accessing an archived file
        TSP_EventsToBlock eventCondition;
        FileEventStore evt;
        Boolean evtResult;

        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        String title = ArchiveDocumentUtilities.ARCHIVE_TITLE_PREFIX + 'TSPSampleDocument.pdf';
        ContentDocument doc = [SELECT Id, Title FROM ContentDocument WHERE Title = :title];

        // WHEN an archived file is previewed
        System.runAs(loggedInUser) {
            test.startTest();
                // set up our event and its field values
                evt = new FileEventStore();
                evt.FileAction = 'PREVIEW';
                evt.UserId = loggedInUser.Id;
                evt.FileName = doc.Title;
                evt.DocumentId = doc.Id;

                // Fire the event
                eventCondition = new TSP_EventsToBlock();
                evtResult = eventCondition.evaluate(evt);
            test.stopTest();
        }

        // THEN policy should return false
        // Test that the Apex returns false for this event
        Assert.isFalse(evtResult, 'File Access policy should return false'); 
    }
    
    // Test allow listed application - Mulesoft JWT App
    @IsTest
    static void testAllowMulesoftJWTApp() {

        // GIVEN : a user logging in
        TSP_EventsToBlock eventCondition;
        LoginEvent evt;
        Boolean evtResult;

        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // WHEN : logged in via Mulesoft JWT App
        System.runAs(loggedInUser) {
            test.startTest();
                // set up our event and its field values
                evt = new LoginEvent();
                evt.LoginType = 'Remote Access 2.0';        // Non SSO
                evt.Application = 'Mulesoft JWT App';       // Non SSO however app is non browser
                evt.UserId = loggedInUser.Id;

                // Fire the event
                eventCondition = new TSP_EventsToBlock();
                evtResult = eventCondition.evaluate(evt);
            test.stopTest();
        }

        // THEN : Test that the Apex returns false for this event
        Assert.isFalse(evtResult, 'SSO policy should return false'); 
    }

    // Assign the SSO enforcement perm set
    //
    private static void assignSsoEnforcementPerm(Id userId) {
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = :TSP_EventsToBlock.CONST_ENFORCE_SSO_API_NAME LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = userId ;
        psa.PermissionSetId = permissionSet.Id;
        try {
            insert psa;
        } catch (Exception e) {
            system.debug('Ignoring perm set assignment exceptions in test class: ' + e.getMessage()); //NOPMD
        }
    }

    // De-assign the SSO enforcement perm set
    //
    private static void deassignSsoEnforcementPerm(Id userId) {
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = :TSP_EventsToBlock.CONST_ENFORCE_SSO_API_NAME LIMIT 1];
        PermissionSetAssignment psa = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :permissionSet.Id AND AssigneeId = :userId];
        delete psa;
    }

    private static void createTestUserNonSso() {
        
        // Create the partner account owner user
        String username = 'User' + Math.random()*100 + Datetime.now().getTime() + '@test.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        UserRole r = new UserRole(DeveloperName = 'MyCustomTestRole', Name = 'My Custom Test Role');
        insert r;

        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            Monash_User_Type__c='eSol Integration User', // Prevent SSO perm being assigned
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=username);

        insert u;
    }

    private static User getTestUserNonSso() {
        UserRole r = [SELECT Id FROM UserRole WHERE DeveloperName = 'MyCustomTestRole'];
        User u = [SELECT Id FROM User WHERE UserRoleId = :r.Id];
        return u;
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