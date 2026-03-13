/**
 * @author Zachary Soohoo, UC Innovation
 * @date 1/31/20
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test Class for PORTAL_UCIN_CommunityUtils
 */
@isTest(isParallel=true)
public class PORTAL_UCIN_CommunityUtils_Test {
    
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
    }
    
    @IsTest
    public static void test_UserContactInfo() {
        setupUserData();

        PORTAL_UCIN_CommunityUtils.getContactInfoFromUser(communityUser.Id);
        User loggedInUserInfo = PORTAL_UCIN_CommunityUtils.getLoggedInUserInfo(communityUser.Id);
        System.assertEquals(communityUser.Id, loggedInUserInfo.Id);
        System.assertEquals(con.Id, loggedInUserInfo.ContactId);
        
    }
    
    @IsTest
    public static void test_getBaseUrlWithNetworkId() {
        PORTAL_UCIN_CommunityUtils.testHasNetworkId = true;
        
        PORTAL_UCIN_CommunityUtils.testHasUrlPathPrefix = true;
        PORTAL_UCIN_CommunityUtils.testHasNetwork = true;
        PORTAL_UCIN_CommunityUtils.getBaseUrl();
        PORTAL_UCIN_CommunityUtils.getCommunityPrefixName();
        
        PORTAL_UCIN_CommunityUtils.testHasUrlPathPrefix = true;
        PORTAL_UCIN_CommunityUtils.testHasNetwork = false;
        System.assertNotEquals('', PORTAL_UCIN_CommunityUtils.getBaseUrl());
        
        PORTAL_UCIN_CommunityUtils.testHasUrlPathPrefix = false;
        PORTAL_UCIN_CommunityUtils.testHasNetwork = true;
        System.assertNotEquals('', PORTAL_UCIN_CommunityUtils.getBaseUrl());

        PORTAL_UCIN_CommunityUtils.testHasUrlPathPrefix = false;
        PORTAL_UCIN_CommunityUtils.testHasNetwork = false;
        System.assertNotEquals('', PORTAL_UCIN_CommunityUtils.getBaseUrl());         
    }
    
    @IsTest
    public static void test_getBaseUrlWithNoNetworkId() {
        PORTAL_CommunityUtils.testHasNetworkId = false;
        PORTAL_CommunityUtils.getBaseUrl();
        System.assertEquals('', PORTAL_CommunityUtils.getCommunityPrefixName());      
    }
}