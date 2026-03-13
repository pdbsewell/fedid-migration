/**
 * @description       : Test class for AccountMergeController
 * @author            : Inderpal Dhanoa
 * @date              : 2021-04-10
 * @group             : Test
 * @group             : Enterprise
 * @last modified on  : 2024-04-17
 * @last modified by  : Sachin Shetty
**/
@isTest(isParallel=true)
public class AccountMergeControllerTest {
/*******************************************************************************
* @author       Inderpal Dhanoa
* @date         10/04/2021
* @description  Test Setup Method for AccountMergeControllerTest LWC
* @revision     1.0
*******************************************************************************/
   @testSetup
   static void setup() {
     List<Account> l_allAccounts = new List<Account>();
     List<User> l_allUsers = new List<User>();
     List<Topic> l_allTopics = new List<Topic>();
     List<TopicAssignment> l_allTopicAssignments = new List<TopicAssignment>();
     List<AccountTeamMember> l_newMembers = new List<AccountTeamMember>();

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        String random = String.valueOf(System.currentTimeMillis());
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'Enterprise Base Profile'];
        User userRecord1 = new User(
            ProfileId = internalProfile.Id,
            Username = random + 'testing1@monash.edu',
            Alias = 'test_ao',
            Email='test_ao1@monash.edu',
            EmailEncodingKey='UTF-8',
            Firstname='Firstname' + random,
            Lastname='Lastname' + random,
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
            Firstname='Firstname' + random,
            Lastname='Lastname' + random,
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
            Firstname='Firstname' + random,
            Lastname='Lastname' + random,
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            TimeZoneSidKey='Australia/Sydney'
        );
        l_allUsers.add(userRecord3);

        System.runAs(thisUser) {
            Database.insert(l_allUsers);
        }

        Account master = new Account(	Name = 'testCreateExternalAccount',Monash_AM_Campus__c = 'Australia', fax = '1234',
        Anonymous_Donor__c = true, DBC_DUNS_Number__c = '1234',
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        //insert master;
        l_allAccounts.add(master);

        Account child1 = new Account(	Name = 'testCreateExternalAccount', fax = '12345', Bad_Debtor__c = true, Monash_AM_Campus__c = 'Malaysia',
        Anonymous_Donor__c = true,  DBC_DUNS_Number__c = '1234',
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        l_allAccounts.add(child1);

        Account child2 = new Account(	Name = 'testCreateExternalAccount', fax = '123456', Bad_Debtor__c = true, Monash_AM_Campus__c = 'South Africa',
        Anonymous_Donor__c = true, OwnerId = userRecord2.Id, DBC_DUNS_Number__c = '1234',
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        l_allAccounts.add(child2);

        insert l_allAccounts;

        // Topic creation
        Topic topic1 = new Topic (Name = 'test topic 1 : ' + Datetime.now());
        l_allTopics.add(topic1);

        Topic topic2 = new Topic (Name = 'test topic 2 : ' + Datetime.now());
        l_allTopics.add(topic2);

        insert l_allTopics; 

        TopicAssignment topic1Assignment = new TopicAssignment (EntityId = master.Id, TopicId  = topic1.Id);
        l_allTopicAssignments.add(topic1Assignment);
        
        TopicAssignment topic2Assignment = new TopicAssignment (EntityId = child1.Id, TopicId  = topic2.Id);
        l_allTopicAssignments.add(topic2Assignment);
        
        insert l_allTopicAssignments;

        //Share the Account with the Child Owner
        
        AccountTeamMember accTeamMember1 = new AccountTeamMember();
        accTeamMember1.UserId = userRecord1.Id;
        accTeamMember1.AccountAccessLevel = 'Read';
        accTeamMember1.AccountId = child1.Id;
        accTeamMember1.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember1);

        //Share the Account with the Child Owner
        AccountTeamMember accTeamMember2 = new AccountTeamMember();
        accTeamMember2.UserId = userRecord2.Id;
        accTeamMember2.AccountAccessLevel = 'Read';
        accTeamMember2.AccountId = child1.Id;
        accTeamMember2.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember2);

        AccountTeamMember accTeamMember3 = new AccountTeamMember();
        accTeamMember3.UserId = userRecord1.Id;
        accTeamMember3.AccountAccessLevel = 'Read';
        accTeamMember3.AccountId = child2.Id;
        accTeamMember3.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember3);

        AccountTeamMember accTeamMember4 = new AccountTeamMember();
        accTeamMember4.UserId = userRecord2.Id;
        accTeamMember4.AccountAccessLevel = 'Read';
        accTeamMember4.AccountId = child2.Id;
        accTeamMember4.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember4);

        AccountTeamMember accTeamMember5 = new AccountTeamMember();
        accTeamMember5.UserId = userRecord1.Id;
        accTeamMember5.AccountAccessLevel = 'Read';
        accTeamMember5.AccountId = master.Id;
        accTeamMember5.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember5);

        AccountTeamMember accTeamMember6 = new AccountTeamMember();
        accTeamMember6.UserId = userRecord3.Id;
        accTeamMember6.AccountAccessLevel = 'Read';
        accTeamMember6.AccountId = master.Id;
        accTeamMember6.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember6);

        AccountTeamMember accTeamMember7 = new AccountTeamMember();
        accTeamMember7.UserId = userRecord3.Id;
        accTeamMember7.AccountAccessLevel = 'Read';
        accTeamMember7.AccountId = master.Id;
        accTeamMember7.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember7);

        AccountTeamMember accTeamMember8 = new AccountTeamMember();
        accTeamMember8.UserId = UserInfo.getUserId();
        accTeamMember8.AccountAccessLevel = 'Read';
        accTeamMember8.AccountId = master.Id;
        accTeamMember8.TeamMemberRole = 'Education Lead';
        l_newMembers.add(accTeamMember8);

        insert l_newMembers;
   }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Test Method for AccountMergeController.getEntityData().
                    It ignores errors if no duplication rules are defined. 
    * @revision     1.0
    *******************************************************************************/
    @isTest
    @SuppressWarnings('PMD.AvoidDebugStatements')
    public static void getEntityDataTest(){   
        Test.startTest(); 
        List<Account> accountsPresent = [SELECT Id FROM Account]; 
        Exception exc = null;
        try{
            AccountMergeController.AccountMergeWrapper linkedAccounts = AccountMergeController.getEntityData(accountsPresent[0].Id);
        }catch (Exception myExc) {
            exc = myExc;
        }
        if(exc instanceof System.HandledException) {
            //ignore, can happen if duplication rules are not active or defined
            System.debug(LoggingLevel.DEBUG, 'System.HandledException is ignored as there are not any active duplication rules.');
        } else {
            System.assertEquals(null, exc, 'An exception occured when it should not.');
        }
        Test.stopTest();
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Test Method for AccountMergeController Method mergeAccounts 
    * @revision     1.0
    *******************************************************************************/
   @isTest 
   public static void mergeAccountsTest(){
     
    List<Account> accountsPresent = [SELECT Id FROM Account ORDER BY createddate ASC];
    system.assertEquals(3, accountsPresent.size());
    
    Test.startTest();
    Id masterAccountId = AccountMergeController.mergeAccounts(accountsPresent[0].Id, accountsPresent[1].Id, true);

    List<AccountTeammember> sharedMembers = [SELECT Id FROM AccountTeamMember WHERE AccountId = :accountsPresent[0].Id]; 
    system.assertEquals(3, sharedMembers.size());
    
    accountsPresent = [SELECT Id FROM Account ORDER BY createddate ASC];
    system.assertEquals(2,accountsPresent.size()); 
    
    //Share the Account with the Child Owner
    List<User> childUser = [SELECT Id FROM User WHERE EMail like '%test_ao1@monash.edu%'];
    AccountTeamMember accTeamMember = new AccountTeamMember();
    accTeamMember.UserId = childUser[0].Id;
    accTeamMember.AccountAccessLevel = 'Read';
    accTeamMember.AccountId = accountsPresent[0].Id;
    accTeamMember.TeamMemberRole = 'Education Lead';
    insert accTeamMember;

    masterAccountId = AccountMergeController.mergeAccounts(accountsPresent[0].Id, accountsPresent[1].Id, true);
    Test.stopTest(); 

    sharedMembers = [SELECT Id FROM AccountTeamMember WHERE AccountId = :accountsPresent[0].Id];

    system.assertEquals(4,sharedMembers.size());

    accountsPresent = [SELECT Id FROM Account];
    system.assertEquals(1,accountsPresent.size());
   }
}