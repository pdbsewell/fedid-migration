/**
 * @description Test class for MyAppUserProvisioning
 * @author      Nick guia
 * @date        FEB.06.2024
 * @group       Admissions
 */
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION : DML operations aren't permitted on this type of object: User
private class MyAppUserProvisioning_Test {

    @TestSetup
    static void makeData() {
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
     * @description should create a MyAppUser including necessary
     * permissions, when the username doesn't exist yet
     */
    @isTest
    static void shouldProvisionUserWhenTheyDontExist() {

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

        Test.startTest();

        // WHEN
        MyAppUserProvisioning.ProvisionUserQueueable q = new MyAppUserProvisioning.ProvisionUserQueueable(appList);
        System.enqueueJob(q);

        Test.stopTest();

        // THEN
        // each contact records from the Application must end up with a User record
        Map<Id, User> userByContactIdMap = new Map<Id, User>();
        for(User iUser : [SELECT Id, ContactId,
                            (SELECT PermissionSetGroupId, PermissionSetId, AssigneeId FROM PermissionSetAssignments
                            WHERE PermissionSetGroupId = :MyApplicationUtilities.MYAPP_USER_PSG.Id
                            OR PermissionSetId = :MyApplicationUtilities.MYAPP_USER_PS.Id)
                        FROM User
                        WHERE ContactId IN :contactIdSet])
        {
            userByContactIdMap.put(iUser.ContactId, iUser);
        }

        for(Id iCon : contactIdSet) {
            Assert.isTrue(userByContactIdMap.containsKey(iCon), 'Unable to create a MyApp user for Contact');

            // the user must have the required permissions
            User iUser = userByContactIdMap.get(iCon);
            Assert.isTrue(!iUser.PermissionSetAssignments.isEmpty(), 'User does not have all the expected permissions');

            // check permission set assignment IDs
            Map<Id, PermissionSetAssignment> psaByPSOrPSGId = new Map<Id, PermissionSetAssignment>();
            for(PermissionSetAssignment iPsa : iUser.PermissionSetAssignments) {
                if(iPsa.PermissionSetGroupId != null) {
                    psaByPSOrPSGId.put(iPsa.PermissionSetGroupId, iPsa);
                } else {
                    psaByPSOrPSGId.put(iPsa.PermissionSetId, iPsa);
                }
            }
            Assert.isTrue(psaByPSOrPSGId.containsKey(MyApplicationUtilities.MYAPP_USER_PSG.Id), 'User does not have all the expected permissions');
            Assert.isTrue(psaByPSOrPSGId.containsKey(MyApplicationUtilities.MYAPP_USER_PS.Id), 'User does not have all the expected permissions');
        }
    }

    /**
     * @description test that all required permissions are privisioned to
     * MyApp users
     */
    @isTest
    static void shouldProvissionAccessToMyAppUsers() {

        // GIVEN

        /**
         * get one of the Users from the setup.
         * We are assuming that this user does not have the MyApp PSG yet
         */
        Map<Id, Contact> conMap = new Map<Id, Contact>([SELECT Id FROM Contact]);
        User myAppUser = [SELECT Id, ContactId
                        FROM User 
                        WHERE ContactId IN :conMap.keySet()
                        LIMIT 1];
        
        MyAppUserProvisioning.ProvisionUserQueueable q;
        List<PermissionSetAssignment> result;

        Test.startTest();

        // WHEN
        q = new MyAppUserProvisioning.ProvisionUserQueueable();
        q.appListByContactIdMap = new Map<Id, List<Application__c>>();
        result = q.provisionAccess(new List<User>{ myAppUser });

        Test.stopTest();

        // THEN
        Assert.areEqual(result[0].AssigneeId, myAppUser.Id, 'Unexpected Permissionset Assignment result');
    }

    /**
     * @description test that Exception Logs are created when
     * (for whatever reason) User creation fails
     */
    @isTest
    static void shouldLogExceptionWhenUserCreationFails() {

        // GIVEN
        User emptyUser = new User(
            FirstName ='onlyFirstName',
            ContactId = fflib_IDGenerator.generate(Contact.SObjectType)
        );
        MyAppUserProvisioning.ProvisionUserQueueable q;
        List<User> result;

        Test.startTest();

        // WHEN
        q = new MyAppUserProvisioning.ProvisionUserQueueable();
        q.appListByContactIdMap = new Map<Id, List<Application__c>>(); // initialise to avoid null pointer
        result = q.commitNewUsers(new List<User>{ emptyUser });
        Nebula.Logger.saveLog();

        Test.stopTest();

        // THEN
        Assert.isTrue(result.isEmpty(), 'Unexpected successful creation of user');

        List<Nebula__LogEntry__c> logs =  [SELECT Id, Nebula__OriginLocation__c
                                            FROM Nebula__LogEntry__c
                                            WHERE Nebula__OriginLocation__c = 'MyAppUserProvisioning.ProvisionUserQueueable.commitNewUsers'];

        Assert.isNotNull(logs, 'Unable to create Exception Logs');
        Assert.isTrue(!logs.isEmpty(), 'Unable to create Exception Logs');
    }

    /**
     * @description when a duplicate username exist (related to a different contact),
     * and we try to provision a user via an Application to a duplicate contact,
     * the system should instead update the Application to indicate that a merge is required
     * first before going forward
     */
    @isTest
    static void shouldUpdateApplicationWhenUsernameExists() {

        // GIVEN

        // STEP 1 : get the contact and application that doesn't have a user yet
        Map<Id, User> existingUserByContactIdMap = new Map<Id, User>();
        for(User iUser : [SELECT Id, ContactId
                        FROM User
                        WHERE ContactId != null
                        AND Contact.FirstName LIKE 'ApplicantLName%'
                        AND Contact.Person_ID_unique__c != null])
        {
            existingUserByContactIdMap.put(iUser.ContactId, iUser);
        }
        // get the contact record without a user yet
        Contact con = [SELECT Id, FirstName, LastName, Email
                        FROM Contact 
                        WHERE Id NOT IN :existingUserByContactIdMap.keySet() 
                        LIMIT 1];
        Application__c app = [SELECT Id, Applicant__c
                            FROM Application__c
                            WHERE Applicant__c = :con.Id
                            LIMIT 1];

        // STEP 2 : create a duplicate Account > Contact > User structure to set up a duplicate scenario

        // to avoid Error: 'Portal account owner must have a role'
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];
        System.runAs(adminUser) {

            Id ACCOUNT_INDIVIDUAL_RECTYPE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                                            .get(AccountServices.ACCOUNT_INDIVIDUAL_TYPE)
                                            .getRecordTypeId();

            // manually create individual Accounts for the contact so their owner would always have a Role
            Account duplicateConAccount = new Account(
                Name = con.FirstName + ' ' + con.LastName,
                OwnerId = adminUser.Id,
                RecordTypeId = ACCOUNT_INDIVIDUAL_RECTYPE
            );

            TriggerCommon.disableTrigger('Account');
            insert duplicateConAccount;
            TriggerCommon.enableTrigger('Account');

            Contact duplicateContact = new Contact(
                FirstName = con.FirstName,
                LastName = con.LastName,
                Email = con.Email,
                AccountId = duplicateConAccount.Id
            );

            TriggerCommon.disableTrigger('Contact');
            insert duplicateContact;
            TriggerCommon.enableTrigger('Contact');

            User myAppUser = new ApplicationService().generateMyAppUser(duplicateContact);
            insert myAppUser;
        }

        MyAppUserProvisioning.ProvisionUserQueueable q;

        Test.startTest();

        // WHEN
        q = new MyAppUserProvisioning.ProvisionUserQueueable(new List<Application__c>{ app });
        System.enqueueJob(q);

        Test.stopTest();

        // THEN

        // a duplicate error should occur and the Application should have been updated
        Application__c updatedApp = [SELECT Id, Applicant__c, Task_Duplicate_Check__c 
                                    FROM Application__c 
                                    WHERE Id = :app.Id 
                                    LIMIT 1];
        Assert.areEqual('Required', updatedApp.Task_Duplicate_Check__c, 'Unable to update Task Duplicate Check');
    }

    /**
     * @description test that Exception Logs are created when
     * (for whatever reason) User access provisioning fails.
     * In this test, we simulate this by assigning a profile/license
     * that's not allowed to receive the PSG
     */
    @isTest
    static void shouldLogExceptionWhenAccessProvisioningFails() {

        // GIVEN
        Profile limited = [SELECT Id FROM Profile WHERE Name = 'Limited Access User' LIMIT 1];
        User limitedUser = new User(
            ProfileId = limited.Id,
            Username = AgentPortalTestDataFactory.util.makeUsernameUnique('testAgentLastName@TestEmail.com.domain'),
            email = 'testAgentLastName@TestEmail.com',
            LastName ='test',
            Alias ='test',
            isActive = true,
            TimeZoneSidKey ='Australia/Sydney',
            LocaleSidKey ='en_AU',
            EmailEncodingKey ='ISO-8859-1',
            LanguageLocaleKey ='en_US'
        );
        TriggerCommon.disableTrigger('User');
        insert limitedUser;
        TriggerCommon.enableTrigger('User');

        MyAppUserProvisioning.ProvisionUserQueueable q;
        List<PermissionSetAssignment> result;

        Test.startTest();

        // WHEN
        q = new MyAppUserProvisioning.ProvisionUserQueueable();
        q.appListByContactIdMap = new Map<Id, List<Application__c>>();
        result = q.provisionAccess(new List<User>{ limitedUser });
        Nebula.Logger.saveLog();

        Test.stopTest();

        // THEN
        Assert.isTrue(result.isEmpty(), 'Unexpected successful creation of user');

        List<Nebula__LogEntry__c> logs =  [SELECT Id, Nebula__OriginLocation__c
                                            FROM Nebula__LogEntry__c
                                            WHERE Nebula__OriginLocation__c = 'MyAppUserProvisioning.ProvisionUserQueueable.provisionAccess'];
        Assert.isNotNull(logs, 'Unable to create Exception Logs');
        Assert.isTrue(!logs.isEmpty(), 'Unable to create Exception Logs');
    }
}