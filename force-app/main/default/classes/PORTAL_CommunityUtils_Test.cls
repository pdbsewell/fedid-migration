@isTest(isParallel=true)
public class PORTAL_CommunityUtils_Test {
    static public Contact con;
    static public User communityUser;
    
    static void setupUserData() {

        Id profileId = [select id from profile where name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON].id;
        Account acct = new Account(name = 'ACME Co') ;
        insert acct;

        con = new Contact(LastName = 'Test_Contact',
                          AccountId = acct.Id,
                          Email = 'testCommunityUsermig123@test.com');
        insert con;

        communityUser = new User(alias = 'comUser',
                                 email = 'testCommunityUsermig123@test.com',
                                 emailencodingkey='UTF-8',
                                 lastname = 'Batman',
                                 languagelocalekey='en_US',
                                 localesidkey='en_US',
                                 profileid = profileId,
                                 IsActive = true,
                                 ContactId = con.Id,
                                 timezonesidkey='America/Los_Angeles',
                                 username = 'testCommunityUsermig123@test.com');
        insert communityUser;

        System.debug('communityUser: ' + communityUser.Id);
        System.debug('communityUser.ContactId: ' + communityUser.ContactId);
    }
    
    static testMethod void testUserContactInfo() {
        setupUserData();

        PORTAL_CommunityUtils.getContactInfoFromUser(communityUser.Id);
        PORTAL_CommunityUtils.getLoggedInUserInfo(communityUser.Id);
    }
    
    static testMethod void testHasNetworkId() {
        PORTAL_CommunityUtils.testHasNetworkId = true;
        
        PORTAL_CommunityUtils.testHasUrlPathPrefix = true;
        PORTAL_CommunityUtils.testHasNetwork = true;
        PORTAL_CommunityUtils.getBaseUrl();
        PORTAL_CommunityUtils.getCommunityPrefixName();
        
        PORTAL_CommunityUtils.testHasUrlPathPrefix = true;
        PORTAL_CommunityUtils.testHasNetwork = false;
        PORTAL_CommunityUtils.getBaseUrl();
        
        PORTAL_CommunityUtils.testHasUrlPathPrefix = false;
        PORTAL_CommunityUtils.testHasNetwork = true;
        PORTAL_CommunityUtils.getBaseUrl();

        PORTAL_CommunityUtils.testHasUrlPathPrefix = false;
        PORTAL_CommunityUtils.testHasNetwork = false;
        PORTAL_CommunityUtils.getBaseUrl();         
    }
    
    static testMethod void testHasNoNetworkId() {
        PORTAL_CommunityUtils.testHasNetworkId = false;
        PORTAL_CommunityUtils.getBaseUrl();
        PORTAL_CommunityUtils.getCommunityPrefixName();
    }
    
}