/**
 * @author Charlie Park, UC Innovation
 * @date 10/16/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for Nav Controller
 */
@isTest(isParallel=true)
public class PORTAL_UCIN_NavController_Test {     
    //Create a portal account owner user and a community user
    @TestSetup
    static void makeData(){
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];

        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'test2@test.com',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);

        System.runAs ( portalAccountOwner1 ) {
            //Create account
            Account portalAccount1 = new Account(
            Name = 'TestAccount',
            OwnerId = portalAccountOwner1.Id);
            Database.insert(portalAccount1);       

            //create contact (needed by user)
            Contact contact = new contact(LastName = 'LastName', Firstname = 'FirstName');
            contact.Birthdate =  Date.valueOf('2019-09-24');
            contact.AccountId = portalAccount1.Id;
            insert contact;

            User user = new User();
            user.FirstName = 'Customer';
            user.LastName = 'User';
            user.Alias = 'test';
            user.CommunityNickname = 'Test1';
            user.TimeZoneSidKey = 'America/New_York';
            user.LocaleSidKey = 'en_US';
            user.EmailEncodingKey = 'UTF-8';
            user.Email = 'testEmail925@gmail.com';
            user.Username = 'testEmail925@gmail.com';
            user.IsActive = true;
            user.LanguageLocaleKey = 'en_US';
            user.App_Birthdate__c = Date.valueOf('2019-09-24');        
            
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name ='Customer Community General User']; //MUST use a profile that is a portal user!
            system.debug('PROFILES SIZE: ' + profiles.size());
            if(profiles.size() > 0)
            {
                user.ProfileID = profiles[0].Id;       		
                user.ContactId = contact.Id;
                insert user;
            }     
        }
    }

    @isTest
    public static void testGetUserType() {
        User portalUser = [SELECT ID FROM User WHERE username = 'testEmail925@gmail.com'];

        test.startTest();
        system.runAs(portalUser) {
            system.assertEquals(PORTAL_UCIN_NavController.SERVER_getUserType(), true);
        }
        test.stopTest();
    }

    @isTest
    public static void testGetContactId() {
        User portalUser = [SELECT ID FROM User WHERE username = 'testEmail925@gmail.com'];
        Contact portalContact = [SELECT ID FROM Contact LIMIT 1];

        test.startTest();
        system.runAs(portalUser) {
            system.assertEquals(PORTAL_UCIN_NavController.SERVER_getContactId(), portalContact.Id);
        }
        test.stopTest();
    }

    @isTest
    public static void testBaseURL() {
        test.startTest();
        PORTAL_UCIN_NavController.SERVER_getDomainName();
        test.stopTest();
    }
}