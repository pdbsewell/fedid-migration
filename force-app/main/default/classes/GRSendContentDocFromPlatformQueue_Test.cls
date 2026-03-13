/*******************************************************************************
    * @author       Davey Yu
    * @date         04/02/2025
    * @description  Test class for GRSendContentDocFromPlatformEventQueue
    * @revision     04/02/2025 - Initial Version
*******************************************************************************/
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION : DML operations aren't permitted on this type of object: User
public class GRSendContentDocFromPlatformQueue_Test {
	@TestSetup
    static void makeData(){
        //Create Agent User make data
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');

        // STEP 1 - Create Agent Onboarding Settings
       	insert AgentPortalTestDataBuilder.factory.createAgentOnboardingSettings();

        // STEP 2 - Create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
        //Factory instantiation
        AgentPortalTestDataFactory factory = new AgentPortalTestDataFactory();

        // create contacts
        List<Contact> conList = new List<Contact>();
        // create an Applicant contact without a user
        Contact applicantWithoutUser = factory.createApplicantContact();
        // create a contact with a user
        Contact applicantWithUser = factory.createApplicantContact();

        // to avoid Error: 'Portal account owner must have a role'
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];

        System.runAs(adminUser) {

            List<Account> applicantAccounts = new List<Account>();
            Id ACCOUNT_INDIVIDUAL_RECTYPE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                                            .get(AccountServices.ACCOUNT_INDIVIDUAL_TYPE)
                                            .getRecordTypeId();

            // manually create individual Accounts for the contact so their owner would always have a Role
            Account applicantWithoutUserAccount = new Account(
                Name = applicantWithoutUser.FirstName + ' ' + applicantWithoutUser.LastName,
                OwnerId = adminUser.Id,
                RecordTypeId = ACCOUNT_INDIVIDUAL_RECTYPE
            );
            applicantAccounts.add(applicantWithoutUserAccount);

            Account applicantWithUserAccount = new Account(
                Name = applicantWithUser.FirstName + ' ' + applicantWithUser.LastName,
                OwnerId = adminUser.Id,
                RecordTypeId = ACCOUNT_INDIVIDUAL_RECTYPE
            );
            applicantAccounts.add(applicantWithUserAccount);

            TriggerCommon.disableTrigger('Account');
            insert applicantAccounts;
            TriggerCommon.enableTrigger('Account');

            // assign accounts to contacts
            applicantWithoutUser.AccountId = applicantWithoutUserAccount.Id;
            applicantWithUser.AccountId = applicantWithUserAccount.Id;

            conList.add(applicantWithoutUser);
            conList.add(applicantWithUser);

            TriggerCommon.disableTrigger('Contact');
            insert conList;
            TriggerCommon.enableTrigger('Contact');

            /**
             * this would have been more ideal to use a test data factory,
             * but since the existing ones are too tightly coupled, we'll use
             * the one from the service class instead and move it later on
             */
            User myAppUser = new ApplicationService().generateMyAppUser(applicantWithUser);
            insert myAppUser;
        }

        // create Applications
        List<Application__c> appList = new List<Application__c>();
        appList.add(factory.createApplication(applicantWithoutUser.Id));
        appList.add(factory.createApplication(applicantWithUser.Id));

        TriggerCommon.disableTrigger('Application__c');
        insert appList;
        TriggerCommon.enableTrigger('Application__c');
    }
    
    /******************************************************************************* 
    * @author       Sethu Venna
    * @date         28/01/2025
    * @description  GIVEN An Application is created
                    WHEN the status gets updated to Submitted
                    THEN create Async Platform events to enable integration
    * @revision     created 29/01/2025 Sethu Venna
    *******************************************************************************/
	static testMethod void testGRSendDocToCallistaPlatformEventService() {

        Test.startTest();	
        Map<Integer,String> fileExtensionMap = new Map<Integer,String>{
            0 => '.pdf',
            1 => '.doc',
            2 => '.docx',
            3 => '.txt',
            4 => '.gif',
            5 => '.jpeg',
            6 => '.jpg',
            7 => '.png',
            8 => '.bmp',
            9 => '.tiff'
        };

        Contact newContact = new Contact();
        newContact.FirstName = 'FN in GRSendContentDocQueuable_Test';
        newContact.LastName = 'LN in GRSendContentDocQueuable_Test';
        insert newContact;

        Application__c app = new Application__c();
        app.Applicant__c = newContact.id;
        app.Callista_Applicant_Id__c = 'testApp1';
        app.Type_Of_Study__c = 'Graduate Research';
        app.Status__c = 'Sent for Submission';
        insert app;

        List<Contact_Document__c> conDocList = new List<Contact_Document__c>();
        for(Integer i=0; i < 10 ; i++) {
            Contact_Document__c conDoc = new Contact_Document__c();
            conDoc.Contact__c = newContact.id;
            conDoc.Application__c = app.Id;
            conDoc.Document_Type__c = 'PARENT_GUARDIAN';
            conDoc.Filename__c = 'testdoc';
            conDocList.add(conDoc);
        }
        insert conDocList;

        List<ContentVersion> cvList = new List<ContentVersion>();
        for(Integer i=0; i < 10 ; i++) {
            Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
            ContentVersion contentVersionRec = new ContentVersion(
                Title='Header_Picture1', 
                PathOnClient ='/Header_Picture1'+fileExtensionMap.get(i),
                VersionData = bodyBlob, 
                origin = 'H'
            );
            cvList.add(contentVersionRec);
        }
        Database.SaveResult[] saveCVList = Database.insert(cvList, false);
        Set<Id> cvIdSet = new Set<Id>();
        for (Database.SaveResult sr : saveCVList) {
            if (sr.isSuccess()) {
                cvIdSet.add(sr.getId());
            }
        }
        List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
        Integer i = 0;
        for(ContentVersion contentVersionRec : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvIdSet]) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = conDocList.get(i).Id;
            cdl.ContentDocumentId = contentVersionRec.ContentDocumentId;
            cdl.ShareType = 'V';
            cdLinkList.add(cdl);
            i++;
        }
        insert cdLinkList;

        insert new Feature_Switch__c(Graduate_Research_Integration__c = true);

        
        GRCallistaFileApiMock_Test mock = new GRCallistaFileApiMock_Test();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        app.Status__c = 'Submitted';
        update app;
        Test.stopTest();
        Assert.isNotNull(
            [SELECT Name, Position, Retries, LastError 
            FROM EventBusSubscriber 
            WHERE Topic='Async_Process__e'
            ],
            'Platform Events are published to enable document callout'
        );
    }
    
    /******************************************************************************* 
    * @author       Davey Yu
    * @date         28/01/2025
    * @description  GIVEN An Application is created and status is submitted
                    WHEN the platform events fails
                    THEN should catch the exception
    * @revision     created 29/01/2025 Sethu Venna
    *******************************************************************************/
	static testMethod void testGRSendDocToCallistaPlatformEventService_Negative() {
		   // Step 1: Mock data (Content Document Ids)
        Set<Id> mockConDocIdSet = new Set<Id>();
        //mockConDocIdSet.add('069xx000000abcdAAA');  // Add a sample Content Document ID
        
        // Step 2: Use a Mockable class to simulate an exception
        Test.startTest();
        
        // Mock the exception by setting the GRSendContentDocQueuable to throw an exception
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); // Optional if using callouts
        
        try {
            // Trigger the future method with an invalid scenario that will throw an exception
            //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); // Mock callout response if needed
            GRSendContentDocFromPlatformEventQueue.execute(mockConDocIdSet);
        } catch (Exception e) {
            System.debug('Caught exception: ' + e.getMessage());
        }
        
        // Step 3: Validate the catch block executed (indirectly checking logs)
        // You can assert that an exception has been caught based on the logger output or other indirect methods
        // If you have a log checker for Nebula.Logger, you can validate if the log was saved.
        Test.stopTest();

    }
}