/**
 * @description       : Test class for AccountServices.cls
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2021-01-21
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.2   2021-01-21   Stefan Scheit   Added ACCOUNT_EXTERNAL_ORGANISATION and ACCOUNT_MONASH_ORGANISATION
 * 1.1   2020-10-16   Stefan Scheit   Updated ACCOUNT_INDIVIDUAL_TYPE from Household to Household_Account
 * 1.0   20??-??-??   PwC             Initial version
**/
@isTest // setting isParallel=true is not applicable as DML operations on User object aren't permitted during Parallel Apex tests
public class AccountServices_Test{

    @TestSetup
    static void setup(){
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact con = new Contact ();
        con.FirstName ='test';
        con.LastName ='testsecond';
        insert con;
        Id proId =[select id from profile where name ='Monash Partner Community Login User'].id;
        Integer rnd = Integer.valueOf(Math.random()*9999);
        User u= new User();
        u.Username = String.valueOf(rnd) + 'testLastName@TestEmail.com.domain';
        u.email = String.valueOf(rnd) + 'testLastName@TestEmail.com';
        u.ContactId = con.id; 
        u.LastName ='test';
        u.Alias ='test';
        u.isActive = true;
        u.TimeZoneSidKey ='Australia/Sydney';
        u.LocaleSidKey ='en_AU';
        u.EmailEncodingKey ='ISO-8859-1';
        u.ProfileId = proId;
        u.LanguageLocaleKey ='en_US';
        insert u;
    }
    /*
    * Dummy for test coverage
    */
    public testMethod static void testAccountServicesConstants() {
        System.assertEquals(AccountServices.ACCOUNT_INDIVIDUAL_TYPE,'Household_Account');
        System.assertEquals(AccountServices.ACCOUNT_EXTERNAL_ORGANISATION,'External_Organisation');
        System.assertEquals(AccountServices.ACCOUNT_MONASH_ORGANISATION,'Monash_Organisation');
        System.assertEquals(AccountServices.ACCOUNT_ORGANISATION_TYPE,'Organization');
    }

    /*
    * Method to test upsertPartnerRole - insert
    */
    @isTest
    public static void testUpsertPartnerRoleInsert() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT id FROM User WHERE Username LIKE '%testLastName@TestEmail.com.domain%' LIMIT 1];
        Test.startTest();
            AccountServices.upsertPartnerRole(usr.Id, acc.Id, 'Primary Account Holder');
        Test.stopTest();
        AccountTeamMember atm = [SELECT TeamMemberRole FROM AccountTeamMember WHERE UserId = :usr.id AND AccountId = :acc.id LIMIT 1];
        System.assertEquals('Primary Account Holder', atm.TeamMemberRole, 'Account Team Member not inserted properly');
    }
    /*
    * Method to test upsertPartnerRole - update
    */
    @isTest
    public static void testUpsertPartnerRoleUpdate() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT id FROM User WHERE Username LIKE '%testLastName@TestEmail.com.domain%' LIMIT 1];
        AccountTeamMember atm = new AccountTeamMember(UserId = usr.Id, AccountId = acc.Id, TeamMemberRole = 'Primary Account Holder');
        insert atm;
        Test.startTest();
            AccountServices.upsertPartnerRole(usr.Id, acc.Id, 'Delegated Admin User');
        Test.stopTest();
        AccountTeamMember updatedATM = [SELECT TeamMemberRole FROM AccountTeamMember WHERE UserId = :usr.id AND AccountId = :acc.id LIMIT 1];
        System.assertEquals('Primary Account Holder', atm.TeamMemberRole, 'Account Team Member not inserted properly');
        System.assertEquals('Delegated Admin User', updatedATM.TeamMemberRole, 'Account Team Member not updated properly');
    }
    /*
    * Method to test upsertPartnerRole - demote existing Primary Account Holder
    */
    @isTest
    public static void testUpsertPartnerRoleDemote() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT id FROM User WHERE Username LIKE '%testLastName@TestEmail.com.domain%' LIMIT 1];
        AccountTeamMember atm = new AccountTeamMember(UserId = usr.Id, AccountId = acc.Id, TeamMemberRole = 'Primary Account Holder');
        insert atm;
        Test.startTest();
            Contact con = new Contact ();
            con.FirstName ='test';
            con.LastName ='testfirst';
            insert con;
            Id proId =[select id from profile where name ='Monash Partner Community Login User'].id;
            Integer rnd = Integer.valueOf(Math.random()*9999);
            User usr2= new User();
            usr2.Username = String.valueOf(rnd) + 'testLastName@TestEmail.com.newdomain';
            usr2.email = String.valueOf(rnd) + 'testLastName@TestEmail.com';
            usr2.ContactId = con.id; 
            usr2.LastName ='test';
            usr2.Alias ='test';
            usr2.isActive = true;
            usr2.TimeZoneSidKey ='Australia/Sydney';
            usr2.LocaleSidKey ='en_AU';
            usr2.EmailEncodingKey ='ISO-8859-1';
            usr2.ProfileId = proId;
            usr2.LanguageLocaleKey ='en_US';
            insert usr2;
            AccountServices.upsertPartnerRole(usr2.Id, acc.Id, 'Primary Account Holder');
        Test.stopTest();
        AccountTeamMember oldATM = [SELECT TeamMemberRole FROM AccountTeamMember WHERE UserId = :usr.id AND AccountId = :acc.id LIMIT 1];
        System.assertEquals('Delegated Admin User', oldATM.TeamMemberRole, 'Account Team Member not demoted to DAU');
        AccountTeamMember newATM = [SELECT TeamMemberRole FROM AccountTeamMember WHERE UserId = :usr2.id AND AccountId = :acc.id LIMIT 1];
        System.assertEquals('Primary Account Holder', newATM.TeamMemberRole, 'Account Team Member not inserted properly');
    }
    /*
    * Method to test upsertPartnerRole - update
    */
    @isTest
    public static void testRemovePartnerRoleUpdate() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        User usr = [SELECT id FROM User WHERE Username LIKE '%testLastName@TestEmail.com.domain%' LIMIT 1];
        AccountTeamMember atm = new AccountTeamMember(UserId = usr.Id, AccountId = acc.Id, TeamMemberRole = 'Primary Account Holder');
        insert atm;
        Test.startTest();
            AccountServices.removePartnerRole(usr.Id, acc.Id);
        Test.stopTest();
        List<AccountTeamMember> updatedATM = [SELECT TeamMemberRole FROM AccountTeamMember WHERE UserId = :usr.id AND AccountId = :acc.id LIMIT 1];
        System.assertEquals(0, updatedATM.size(), 'Account Team Member role(s) not removed');
    }
}