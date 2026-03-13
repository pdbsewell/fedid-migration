/**
 * @description       : Test class for BatchAccountMerge
 * @author            : Angelo Rivera
 * @date              : 18/1/2024
 * @group             : Test
 * @group             : Enterprise
 * @last modified on  : 2024-04-17 
 * @last modified by  : Sachin Shetty
 * Modifications Log
 * Date         Author          Modification
 * 2024-04-17   Sachin Shetty   Update to point to DBConnect fields
**/

@IsTest(IsParallel=true)
private class BatchAccountMerge_Test {

    /*
    * @description     This method will insert all test accounts to test the behaviour of batch class
    * Expected result: Accounts will be created.
    */
    @TestSetup
    static void setup() {
        List<User> l_allUsers = new List<User>();
        List<Topic> l_allTopics = new List<Topic>();
        List<TopicAssignment> l_allTopicAssignments = new List<TopicAssignment>();
        List<AccountTeamMember> l_newMembers = new List<AccountTeamMember>();
        BaseClass bc = new BaseClass();
        bc.initialize(new List<Schema.SObjectType> {
                Account.SObjectType
        });

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        String random = String.valueOf(System.currentTimeMillis());
        Profile internalProfile = [SELECT Id FROM Profile WHERE Name = 'Enterprise Base Profile'];
        User userRecord1 = new User(
                ProfileId = internalProfile.Id,
                Username = random + 'testing1@monash.edu',
                Alias = 'test_ao',
                Email='test_ao1@monash.edu',
                EmailEncodingKey='UTF-8',
                FirstName='Firstname' + random,
                LastName='Lastname' + random,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='Australia/Sydney'
        );
        l_allUsers.add(userRecord1);

        User userRecord2 = new User(
                ProfileId = internalProfile.Id,
                Username = random + 'testing2@monash.edu',
                Alias = 'test_ao',
                Email='test_ao2@monash.edu',
                EmailEncodingKey='UTF-8',
                FirstName='Firstname' + random,
                LastName='Lastname' + random,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='Australia/Sydney'
        );
        l_allUsers.add(userRecord2);

        User userRecord3 = new User(
                ProfileId = internalProfile.Id,
                Username = random + 'testing3@monash.edu',
                Alias = 'test_ao',
                Email='test_ao3@monash.edu',
                EmailEncodingKey='UTF-8',
                FirstName='Firstname' + random,
                LastName='Lastname' + random,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='Australia/Sydney'
        );
        l_allUsers.add(userRecord3);

        System.runAs(thisUser) {
            Database.insert(l_allUsers);
        }

        Id recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId();

        // to test the duplicate accounts where Duns are matching
        Account master3 = new Account(	Name = 'test CreateExternal Account',
                DBC_DUNS_Number__c = '12345',
                RecordTypeId = recTypeId);
        bc.push(master3);
        Account master3Dup = new Account(	Name = 'test CreateExternal Account Dup',
                DBC_DUNS_Number__c = '12345',
                RecordTypeId = recTypeId);
        bc.push(master3Dup);

        // to test the duplicate accounts where Duns are matching and one account has Pure Org Id
        Account master = new Account(	Name = 'testCreateExternalAccount',
                Anonymous_Donor__c = true, DBC_DUNS_Number__c = '1234',
                PURE_Organisation_ID__c = '100000000',
                RecordTypeId = recTypeId);
        bc.push(master);
        Account masterDup = new Account(	Name = 'testCreateExternalAccountDup',
                Anonymous_Donor__c = true,  DBC_DUNS_Number__c = '1234',
                RecordTypeId = recTypeId);
        bc.push(masterDup);

        // to test the duplicate accounts where Duns are matching and duplicate Account has child
        Account master4 = new Account(	Name = 'test CreateExternal Account',
                DBC_DUNS_Number__c = '123456',
                PURE_Organisation_ID__c = '',
                RecordTypeId = recTypeId);
        bc.push(master4);
        Account master4Dup = new Account(	Name = 'test CreateExternal Account Dup',
                DBC_DUNS_Number__c = '123456',
                PURE_Organisation_ID__c = '',
                LastModifiedDate = System.today()-1,
                CreatedDate = System.today()-1,
                RecordTypeId = recTypeId);
        bc.push(master4Dup);

        // to test the duplicate accounts where Duns are matching and both Accounts have child
        // test the child re-parenting
        Account master9 = new Account(	Name = 'test CreateExternal Account',
                DBC_DUNS_Number__c = '13579',
                RecordTypeId = recTypeId);
        bc.push(master9);
        Account master9Dup = new Account(	Name = 'test CreateExternal Account Dup',
                DBC_DUNS_Number__c = '13579',
                LastModifiedDate = System.today()-1,
                CreatedDate = System.today()-1,
                RecordTypeId = recTypeId);
        bc.push(master9Dup);

        // to test the duplicate accounts where Org Id, Org Type, Org Alt Id, Org ID Type Alt match
        Account master2 = new Account(	Name = 'test CreateExternal Account',
                Organisation_Identifier__c = '1234567',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                Organisation_Identifier_Alternative__c = '76543',
                Organisation_Identifier_Type_Alternative__c = 'Company Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master2);
        Account master2Dup = new Account(	Name = 'test CreateExternal Account Dup',
                Organisation_Identifier__c = '1234567',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                Organisation_Identifier_Alternative__c = '76543',
                Organisation_Identifier_Type_Alternative__c = 'Company Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master2Dup);

        // to test the duplicate accounts where Org Id, Org Type, Org Alt Id, Org ID Type Alt match where one account has Duns
        Account master5 = new Account(	Name = 'test CreateExternal Account',
                Organisation_Identifier__c = '1234444',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                Organisation_Identifier_Alternative__c = '76544',
                Organisation_Identifier_Type_Alternative__c = 'Company Number (AU)',
                DBC_DUNS_Number__c = '9876543',
                RecordTypeId = recTypeId);
        bc.push(master5);
        Account master5Dup = new Account(	Name = 'test CreateExternal Account Dup',
                Organisation_Identifier__c = '1234444',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                Organisation_Identifier_Alternative__c = '76544',
                Organisation_Identifier_Type_Alternative__c = 'Company Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master5Dup);

        // to test the duplicate accounts where Org Id, Org Type, Org Alt Id, Org ID Type Alt match where one account has Pure Org Id
        Account master6 = new Account(	Name = 'test CreateExternal Account',
                Organisation_Identifier__c = '1234455',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                Organisation_Identifier_Alternative__c = '7654455',
                Organisation_Identifier_Type_Alternative__c = 'Company Number (AU)',
                PURE_Organisation_ID__c = '19876543',
                RecordTypeId = recTypeId);
        bc.push(master6);
        Account master6Dup = new Account(	Name = 'test CreateExternal Account Dup',
                Organisation_Identifier__c = '1234455',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                Organisation_Identifier_Alternative__c = '7654455',
                Organisation_Identifier_Type_Alternative__c = 'Company Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master6Dup);

        // to test the duplicate accounts where Org Id, Org Type, Org Alt Id, Org ID Type Alt match where one account has a child
        Account master7 = new Account(	Name = 'test CreateExternal Account',
                Organisation_Identifier__c = '1234466',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                Organisation_Identifier_Alternative__c = '7654477',
                Organisation_Identifier_Type_Alternative__c = 'Company Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master7);
        Account master7Dup = new Account(	Name = 'test CreateExternal Account Dup',
                Organisation_Identifier__c = '1234466',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                Organisation_Identifier_Alternative__c = '7654477',
                Organisation_Identifier_Type_Alternative__c = 'Company Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master7Dup);

        // to test the duplicate accounts where Org Id, Org Type, Org Alt Id, Org ID Type Alt match where both accounts have a child
        Account master10 = new Account(	Name = 'test CreateExternal Account',
                Organisation_Identifier__c = '1234466',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                Organisation_Identifier_Alternative__c = '7654477',
                Organisation_Identifier_Type_Alternative__c = 'Company Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master10);
        Account master10Dup = new Account(	Name = 'test CreateExternal Account Dup',
                Organisation_Identifier__c = '1234466',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                Organisation_Identifier_Alternative__c = '7654477',
                Organisation_Identifier_Type_Alternative__c = 'Company Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master10Dup);

        bc.commitRecords();

        Account master9Child = new Account(	Name = 'test CreateExternal Account Dup',
                DBC_DUNS_Number__c = '1234665',
                RecordTypeId = recTypeId);
        bc.push(master9Child);
        bc.relate(master9Child,Account.ParentId,master9);

        Account master9DupChild = new Account(	Name = 'test CreateExternal Account Dup',
                DBC_DUNS_Number__c = '1234611',
                RecordTypeId = recTypeId);
        bc.push(master9DupChild);
        bc.relate(master9DupChild,Account.ParentId,master9Dup);

        Account master4DupChild = new Account(	Name = 'test CreateExternal Account Dup',
                DBC_DUNS_Number__c = '12346',
                RecordTypeId = recTypeId);
        bc.push(master4DupChild);
        bc.relate(master4DupChild,Account.ParentId,master4Dup);

        Account master7DupChild = new Account(	Name = 'test CreateExternal Account Dup',
                Organisation_Identifier__c = '1234478',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master7DupChild);
        bc.relate(master7DupChild,Account.ParentId,master7Dup);

        Account master10Child = new Account(	Name = 'test CreateExternal Account Dup',
                Organisation_Identifier__c = '1234478',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master10Child);
        bc.relate(master10Child,Account.ParentId,master10);

        Account master10DupChild = new Account(	Name = 'test CreateExternal Account Dup',
                Organisation_Identifier__c = '1234479',
                Organisation_Identifier_Type__c = 'Business Number (AU)',
                RecordTypeId = recTypeId);
        bc.push(master10DupChild);
        bc.relate(master10DupChild,Account.ParentId,master10Dup);

        bc.commitRecords();

        // Topic creation
        Topic topic1 = new Topic (Name = 'test topic 1 : ' + Datetime.now());
        l_allTopics.add(topic1);
        Topic topic2 = new Topic (Name = 'test topic 2 : ' + Datetime.now());
        l_allTopics.add(topic2);
        insert l_allTopics;

        TopicAssignment topic1Assignment = new TopicAssignment (EntityId = master.Id, TopicId  = topic1.Id);
        l_allTopicAssignments.add(topic1Assignment);
        TopicAssignment topic2Assignment = new TopicAssignment (EntityId = master2.Id, TopicId  = topic2.Id);
        l_allTopicAssignments.add(topic2Assignment);
        insert l_allTopicAssignments;

        //Share the Account with the Child Owner
        AccountTeamMember accTeamMember1 = new AccountTeamMember();
        accTeamMember1.UserId = userRecord1.Id;
        accTeamMember1.AccountAccessLevel = 'Read';
        accTeamMember1.AccountId = master4DupChild.Id;
        accTeamMember1.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember1);

        //Share the Account with the Child Owner
        AccountTeamMember accTeamMember2 = new AccountTeamMember();
        accTeamMember2.UserId = userRecord2.Id;
        accTeamMember2.AccountAccessLevel = 'Read';
        accTeamMember2.AccountId = master4DupChild.Id;
        accTeamMember2.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember2);

        AccountTeamMember accTeamMember3 = new AccountTeamMember();
        accTeamMember3.UserId = userRecord1.Id;
        accTeamMember3.AccountAccessLevel = 'Read';
        accTeamMember3.AccountId = master7Dup.Id;
        accTeamMember3.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember3);
        insert l_newMembers;

    }

    /*
    * @description     This method will test the behaviour of batch class
    * Expected result: Duplicate Accounts will be merged.
    *
    * GIVEN the duplicate accounts in the system
    * WHEN the BatchAccountMerge runs
    * THEN Duplicate Accounts will be merged.
    */
    @IsTest
    static void testBehavior() {

        List<Account> accountsPresent = [SELECT Id FROM Account ORDER BY CreatedDate ASC];
        System.assertEquals(24,accountsPresent.size());

        Test.startTest();
        Id batchJobId = Database.executeBatch(new BatchAccountMerge(), 200);
        Test.stopTest();

        accountsPresent = [SELECT Id FROM Account];
        System.assertEquals(14,accountsPresent.size());

    }
}