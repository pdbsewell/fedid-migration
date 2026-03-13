/**
 * @description Test class for ApplicationService
 * @author      Nick guia
 * @date        FEB.06.2024
 */
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION : DML operations aren't permitted on this type of object: User
private class ApplicationService_Test {

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

    /**
     * @description test if the method properly collects existing users
     * and new users from an Application's related Contact record.
     */
    @isTest
    static void shouldCreateMyAppUserFromApplication() {

        // GIVEN
        List<Application__c> appList = [SELECT Id, Applicant__c
                                        FROM Application__c];
        Set<Id> contactIdSet = new Set<Id>();
        for(Application__c iApp : appList) {
            contactIdSet.add(iApp.Applicant__c);
        }
        // map out contacts with existing user records
        Map<Id, User> existingUserByContactIdMap = new Map<Id, User>();
        for(User iUser : [SELECT Id, ContactId
                        FROM User
                        WHERE ContactId IN :contactIdSet])
        {
            existingUserByContactIdMap.put(iUser.ContactId, iUser);
        }

        ApplicationService appService;
        ApplicationService.MyAppUserWrapper result;

        Test.startTest();

        // WHEN
        appService = new ApplicationService();
        result = appService.createMyAppUserFromApplication(appList);

        Test.stopTest();

        // THEN

        // the collection of new users must not exist in the map of existing users
        for(User newUser : result.newUserList) {
            Assert.isTrue(!existingUserByContactIdMap.containsKey(newUser.ContactId), 'Unexpected value in new user collection');
        }

        // the collection of existing users must exist in the map of existing users
        for(User existingUser : result.existingUserList) {
            Assert.isTrue(existingUserByContactIdMap.containsKey(existingUser.ContactId), 'Unexpected value in existing user collection');
        }
    }

    /**
     * @description when an Application does not have a linked applicant, the system
     * should log an exception record
     */
    @isTest
    static void shouldLogExceptionWhenCreatingUserFromApplicationWithNullApplicant() {

        // GIVEN
        Application__c appWithoutanApplicant = new AgentPortalTestDataFactory().createApplication(null);
        ApplicationService appService;

        Test.startTest();

        // WHEN
        appService = new ApplicationService();
        appService.createMyAppUserFromApplication(new List<Application__c>{ appWithoutanApplicant });

        Test.stopTest();

        // THEN
        Nebula__LogEntry__c log =  [SELECT Id 
                                FROM Nebula__LogEntry__c 
                                WHERE Nebula__OriginLocation__c = 'ApplicationService.createMyAppUserFromApplication'
                                LIMIT 1];
        Assert.isNotNull(log, 'Unable to create a log after processing an Application without an Applicant');
    }

    /**
     * @description test that the method is generating a List of User records
     * out of a List of contact records
     */
    @isTest
    static void shouldCreateMyAppUserFromApplicant() {

        // GIVEN
        List<Contact> conList = [SELECT Id, Email, FirstName, LastName
                                FROM Contact];

        ApplicationService appService;
        List<User> result;

        Test.startTest();

        // WHEN
        appService = new ApplicationService();
        result = appService.createMyAppUserFromApplicant(conList);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null value while trying to create a user from contact');
        Assert.isTrue(!result.isEmpty(), 'Unexpected empty value while trying to create a user from contact');
    }

    /**
     * @description test that the method generates a User record, with all
     * fields properly populated, based on an applicant Contact
     */
    @isTest
    static void shouldGenerateMyAppUserFromApplicant() {

        // GIVEN
        Contact con = [SELECT Id, Email, FirstName, LastName
                        FROM Contact
                        LIMIT 1];
        ApplicationService appService;
        User result;

        Test.startTest();

        // WHEN
        appService = new ApplicationService();
        result = appService.generateMyAppUser(con);

        Test.stopTest();

        // THEN
        Assert.isTrue(result != null, 'Unexpected null result when generating a user record from an applicant');
        Assert.areEqual(result.Username, con.Email, 'Unexpected value in username');
        Assert.areEqual(result.FirstName, con.FirstName, 'Unexpected value in FirstName');
        Assert.areEqual(result.LastName, con.LastName, 'Unexpected value in LastName');
        Assert.areEqual(result.ContactId, con.Id, 'Unexpected value in ContactId');
        Assert.areEqual(result.ProfileId, MyApplicationUtilities.MY_APP_USER_PROFILE.Id, 'Unexpected value in Profile');
        Assert.areEqual(result.TimeZoneSidKey, Constants.TIME_ZONE_SID_KEY, 'Unexpected value in TimeZoneSidKey');
        Assert.areEqual(result.LocaleSidKey, Constants.LOCALE_SID_KEY, 'Unexpected value in LocaleSidKey');
        Assert.areEqual(result.LanguageLocaleKey, Constants.LANGUAGE_LOCALE_KEY, 'Unexpected value in LanguageLocaleKey');
        Assert.areEqual(result.EmailEncodingKey, Constants.EMAIL_ENCODING_KEY, 'Unexpected value in EmailEncodingKey');
        // alias and community nickname is tested separately.
    }

    /**
     * @description test that method generates a myapp user alias as per requirement
     */
    @isTest
    static void shouldGenerateUserAliasFromApplicant() {

        // GIVEN
        Contact con1 = new Contact();
        con1.FirstName = 'John';
        con1.LastName = 'Smith';
        String con1Expected = 'jsmit';
        String con1Actual;

        Contact con2 = new Contact();
        con2.FirstName = 'Mark';
        con2.LastName = 'III';
        String con2Expected = 'miii';
        String con2Actual;

        Contact con3 = new Contact();
        con3.FirstName = 'Mark';
        con3.LastName = 'II';
        String con3Expected = 'mii';
        String con3Actual;

        Contact con4 = new Contact();
        con4.FirstName = 'Mark';
        con4.LastName = 'I';
        String con4Expected = 'mi';
        String con4Actual;

        ApplicationService appService;

        Test.startTest();

        // WHEN
        appService = new ApplicationService();

        con1Actual = appService.generateMyAppUserAlias(con1);
        con2Actual = appService.generateMyAppUserAlias(con2);
        con3Actual = appService.generateMyAppUserAlias(con3);
        con4Actual = appService.generateMyAppUserAlias(con4);

        Test.stopTest();

        // THEN
        Assert.areEqual(con1Expected, con1Actual, 'Unexpected alias format');
        Assert.areEqual(con2Expected, con2Actual, 'Unexpected alias format');
        Assert.areEqual(con3Expected, con3Actual, 'Unexpected alias format');
        Assert.areEqual(con4Expected, con4Actual, 'Unexpected alias format');
    }

    /**
     * @description test that method generates a myapp user nickname as per requirement
     */
    @isTest
    static void shouldGenerateUserNicknameFromApplicant() {

        // GIVEN
        Contact con = new Contact();
        con.Id = fflib_IDGenerator.generate(Contact.SObjectType);
        String contactId = con.Id;
        con.FirstName = 'John';
        con.LastNAme = 'Smith';

        String expected = 'JS' + contactId.substring(2, contactId.length());
        String actual;
        ApplicationService appService;

        Test.startTest();

        // WHEN
        appService = new ApplicationService();
        actual = appService.generateUserNickname(con);

        Test.stopTest();

        // THEN
        Assert.areEqual(expected, actual, 'Unexpected nickname');
    }

    /**
     *@description Verify if it the running user is OES
     */
    @isTest
    static void shouldBeOESUser() {
        //GIVEN 
        User agent = AgentPortalTestDataFactory.util.getAgentUser();
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=agent.Id,PermissionSetId=ps.Id);
        //WHEN
        insert psa;
        System.runAs(agent){
            Test.startTest();
                //THEN
                Assert.isTrue(ApplicationService.isOESUser(), 'The user must be from OES client');
            Test.stopTest();
        }
    }

    /**
     *@description Verify that source system for OES running user is OES
     */
    @isTest
    static void shouldBeOESSourceSystemForOESUser() {
        //GIVEN 
        User agent = AgentPortalTestDataFactory.util.getAgentUser();
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=agent.Id,PermissionSetId=ps.Id);
        //WHEN
        insert psa;
        //verify that the source system returned is OES
        System.runAs(agent){
            Test.startTest();
                //THEN
                Assert.areEqual('OES',ApplicationService.getSourceSystem(), 'The source system must be OES');
            Test.stopTest();
        }
    }

     /**
     *@description Verify if it the running user is AgentPortal
     */
    @isTest
    static void shouldBeAgentPortalUser() {
        //GIVEN 
        User agent = AgentPortalTestDataFactory.util.getAgentUser();
        //WHEN - No additional permission set assigned 

        System.runAs(agent){
            Test.startTest();
                //THEN
                Assert.isFalse(ApplicationService.isOESUser(), 'The user must be from Agent Portal client');
            Test.stopTest();
        }
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
}