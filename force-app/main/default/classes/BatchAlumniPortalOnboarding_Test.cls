/**
 * @author          Ajitabh
 * @description     Test class for Batch class for Alumni User onboarding
 * @revision        Steffi updated this batchAlumniPortalOnboardingTest
 */
@isTest(isParallel=false)
public class BatchAlumniPortalOnboarding_Test {
@testSetup
    static void setup(){

        //reference data
        Id cmpRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('ERDA Guest List').getRecordTypeId();
        Id monashRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId();

         //create a contact 
        List<Contact> lstCont = new List<Contact>();
        lstCont = TestHelper.createOrphanContactRecords(2);
        lstCont[0].Personal_Email__c = 'johnsmith@abcde.com';
        lstCont[1].Personal_Email__c = 'Harry@abcdef.com';
        insert lstCont;
        
        //insert campaign..
        Campaign cmp = new Campaign(Name='Welcome Campaign', IsActive=true, RecordTypeId = cmpRecordTypeId);
        insert cmp;
        
        //put campaign id into custom setting..
        Alumni_Welcome_Campaign__c setting = new Alumni_Welcome_Campaign__c();
        setting.id__c = cmp.Id;
        insert setting;

        // added contact to campaign...
        List<CampaignMember> lstCmpMember = new List<CampaignMember>{
                new CampaignMember(CampaignId = cmp.Id, SSA__c = UserInfo.getUserId(), ContactId = lstCont.get(0).Id,Status='Sent'),
                new CampaignMember(CampaignId = cmp.Id, SSA__c = UserInfo.getUserId(), ContactId = lstCont.get(1).Id,Status='Sent')
        };
        insert  lstCmpMember;
        Date twoDaysAgo = Date.today().addDays(-1);
        Test.setCreatedDate(lstCmpMember[0].id, twoDaysAgo);
    }
    //method is used to test the batchbatchAlumniPortalOnboarding
    @isTest static void batchAlumniPortalOnboardingNewUserTest() {

        Test.startTest();
        BatchAlumniPortalOnboarding uca = new BatchAlumniPortalOnboarding();
        Id batchId = Database.executeBatch(uca);
        Test.stopTest();

        // after the testing stops, assert records were inserted properly
        List<Contact> conList = [select id from Contact];
        List<User> uList = [SELECT Id, ContactId, Name, Email FROM User where ContactId IN: conList];
        System.assertNotEquals(null, uList[0].contactId);
        List < PermissionSet > alumniPermissionSet = [select id, name from permissionset where name = 'Alumni_Portal_Permission_Set'];

        List<PermissionSetAssignment> permSetsAssign = [SELECT PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Username FROM 
                                                        PermissionSetAssignment WHERE AssigneeId = :uList[0].Id 
                                                        and Permissionset.Name = :alumniPermissionSet[0].Name];
        for(PermissionSetAssignment psa : permSetsAssign) {
            System.debug(LoggingLevel.DEBUG, 'UserServices_Test.testAssignPermissionSets: User['+psa.Assignee.Username+'] was assigned with PermissionSet ['+psa.PermissionSet.Name+']');
        }
        System.assertEquals('Alumni_Portal_Permission_Set', permSetsAssign[0].Permissionset.Name);
        System.assert(permSetsAssign.size()>0, 'permission sets assigned to community user');
    }
    @isTest static void batchAlumniPortalOnboardingExistingUserTest() {
        // create existing user without messaging opt in.
        Profile comProfile = [select id, name from profile where name = 'Customer Community General User' LIMIT 1].get(0);
        Contact con = [select id,FirstName,LastName,Personal_Email__c from Contact WHERE Personal_Email__c = 'johnsmith@abcde.com' LIMIT 1];
        String alias = CommonUtilities.createAliasForUser(con.firstname,con.lastname);
        String nickname = CommonUtilities.createNicknameForUser(con.firstname,con.lastname,1);
        User newuser = new User(LastName = con.LastName,FirstName = con.FirstName,Username = con.Personal_Email__c,CommunityNickname =nickname+DateTime.now().getTime(),ContactId = con.id,
        Email = con.Personal_Email__c, ProfileId = comProfile.id,EmailEncodingKey = 'UTF-8',TimeZoneSidKey = 'Australia/Sydney',LanguageLocaleKey = 'en_US',LocaleSidKey = 'en_AU',Alias = alias,
        Messaging_Opt_In__c = false);
        insert(newuser);
        Test.startTest();
        BatchAlumniPortalOnboarding uca = new BatchAlumniPortalOnboarding();
        Id batchId = Database.executeBatch(uca);
        Test.stopTest();

        // after the testing stops, assert record was updated properly
        User updatedUser = [SELECT Id, ContactId, Name, Email, Messaging_Opt_In__c FROM User where ContactId =: con.id LIMIT 1];
        System.assert(updatedUser.Messaging_Opt_In__c,'Messaging Opt in shoud be set to true for existing user');
    }
}