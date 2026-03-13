/**
 * @description       : Test class for Portal Login Controller
 * @author            : Charlie Park, UC Innovation
 * @group             : Test
 * @last modified on  : 2020-10-19
 * @last modified by  : Stefan Scheit
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.2   2020-10-19   Stefan Scheit   Initial Version
 * 1.1   2010-08-10   Ajitabh Jha     Coverage for setting CommunityAccess__c property on User
 * 1.0   2019-10-09   Charlie Park    Initial Version
**/
@isTest(isParallel=false)
public class PORTAL_UCIN_LoginController_Test {

    static final String USER_NAME = 'testEmail925@gmail.com';

    //Create a portal account owner user and a community user
    @TestSetup
    static void makeData(){
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];

        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.currentTimeMillis() + 'test2@test.com',
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
            user.Email = USER_NAME;
            user.Username = USER_NAME;
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

    @IsTest
    static void testLoginWithInvalidCredentials() {
        Test.startTest();

        PORTAL_UCIN_LoginController.login(USER_NAME, 'fakepwd', null);
        //Test.stopTest();
        List<User> userList = [select id,Community_Access__c,Username from User where Username = :USER_NAME];
        System.assert(userList!=null && !userList.isEmpty(), 'User record could not be retrieved');
        system.debug('com acc '+userList[0].Community_Access__c);
        String strCommAccess = userList[0].Community_Access__c;
        //System.assert(String.isNotBlank(strCommAccess), 'Field Community_Access__c is not present or populated.');
        //System.assert(strCommAccess.equalsIgnoreCase(PORTAL_UCIN_LoginController.COMMUNITY_NAME), 'The field [Community_Access__c] on User was not updated or appended with the expected value [ascendportal]. The fields contains: '+strCommAccess);
    }

    @IsTest
    static void PORTAL_UCIN_LoginControllerInstantiation() {
        PORTAL_UCIN_LoginController controller = new PORTAL_UCIN_LoginController();
        System.assertNotEquals(controller, null);
    }

    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = PORTAL_UCIN_LoginController.getAuthConfig();
        System.assertNotEquals(null, authConfig);

    }

    //ADDITIONAL TEST COVERAGE BELOW (James), Not my code above
    @IsTest
    static void test_forgotPassword()
    {
        test.startTest();

        //throw error
        System.assertNotEquals(PORTAL_UCIN_LoginController.forgotPassword(null, null), null);

        //Invalid Username
        String userName = 'testEmail925@gmail.com';
        String checkEmailUrl = 'testEmail925@gmail.com';
        System.assertEquals(PORTAL_UCIN_LoginController.forgotPassword(userName, checkEmailUrl), null);

        test.stopTest();
    }

    @IsTest
    static void test_activateAccount()
    {
        test.startTest();
        String verifcationCode = 'TestCode925';
        String firstName = 'FirstName';
        String lastName = 'LastName';
        String birthDate = null;
        String degree = 'Test Degree';
        String checkEmailUrl = 'testEmail925@gmail.com';
        System.assertNotEquals(PORTAL_UCIN_LoginController.activateAccount( verifcationCode, firstName, lastName, birthDate, degree, checkEmailUrl), null);//invalid date for try/catch block coverage

        Date today = System.today();
        System.debug('TODAY: ' + today);
        birthDate = '2019-09-24';
        System.debug('THIS IS THE DATE BEING USED: ' + Date.valueOf(birthDate));
        System.assertNotEquals(PORTAL_UCIN_LoginController.activateAccount( verifcationCode, firstName, lastName, birthDate, degree, checkEmailUrl), null); //valid date, but not matching user

        User thisUser = [SELECT ID FROM User WHERE Name = 'Customer User' LIMIT 1];
        Activation_Token__c token = new Activation_Token__c();
        token.Retry_Count__c = 2;
        token.Last_Retried_Date__c = System.today() - 5;
        token.Active__c = true;
        token.User__c = thisUser.Id;
        token.Token__c = 'TestCode925'; //causes internal salesforce error(?)
        insert token;

        //call function to be tested, valid date, valid user
        // Should return null on successful activation
        System.assertEquals(PORTAL_UCIN_LoginController.activateAccount( verifcationCode, firstName, lastName, birthDate, degree, checkEmailUrl), null);

        test.stopTest();
    }

    // These are still pending business logic changes, not putting asserts until then
    @IsTest
    static void misc()
    {
        test.startTest();
      //  PORTAL_UCIN_LoginController.getForgotPasswordUrl();
        PORTAL_UCIN_LoginController.getContactQualificationDegreeLevels();
        test.stopTest();
    }

}