/**
* @description       : Test class for ExperienceAuthenticationServices
* @author            : Kristian Vegerano
* @group             : Test
* @last modified on  : 2021-03-03
* @last modified by  : Kristian Vegerano
* Modifications Log 
* Date         Author          Modification
* 2021-03-03 - Kristian Vegerano - Added test scenarios for Partner Community Scenarios
* 2023-25-01   Ken McGuire - enhanced error management
* 2023-11-06   Peter Sewell - updates for WES SSO
* 2024-03-06   Peter Sewell - added GIVEN/WHEN/THEN
*
**/

@isTest //(isParallel=true) In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
public with sharing class ExperienceAuthenticationServices_Test {

    @testSetup 
    static void setup() {
        // insert experience mfa custom setting
        ExperienceMFASetting__c	mfaSetting = new ExperienceMFASetting__c();
        mfaSetting.Autotest_Bypass_Key__c = 'bypasskeyword';
        insert mfaSetting;
        
        Account testAccount = new Account(Name = 'TestAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        Id proId =[select id from profile where name ='Monash Partner Community Login User'].id;
        Integer rnd = Integer.valueOf(Math.random()*9999);
        User u= new User();
        u.Username = String.valueOf(rnd) + 'testLastName@TestEmail.com.domain';
        u.email = String.valueOf(rnd) + 'testLastName@TestEmail.com';
        u.ContactId = testContact.id; 
        u.LastName ='test';
        u.Alias ='test';
        u.isActive = true;
        u.TimeZoneSidKey ='Australia/Sydney';
        u.LocaleSidKey ='en_AU';
        u.EmailEncodingKey ='ISO-8859-1';
        u.ProfileId = proId;
        u.LanguageLocaleKey ='en_US';
        insert u;
        AccountTeamMember atm = new AccountTeamMember(UserId = u.id, AccountId = testAccount.id, TeamMemberRole = 'Delegated Admin User');
        insert atm;
    }
    
    /**
* @description Test class constructor
*/
    @isTest 
    static void validate_EASConstructor() {
        // GIVEN class instantiated 
        //Initialize variables
        ExperienceAuthenticationServices testController;
        
        // WHEN constructor called
        Test.startTest();
        testController = new ExperienceAuthenticationServices();
        Test.stopTest();
        
        //THEN change password should return null string
        //Start assertion
        Assert.areEqual(testController.changePasswordError, '');
    }
    
    /**
* @description Tests loginAuthenticate method
*/
    @isTest 
    static void validate_LoginAuthenticate() {
        //GIVEN Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        String Username = uniqueName + '@test' + orgId + '.org';
        
        //create user
        ExperienceAuthenticationServices.registerUser('TestFirstName', 'TestLastName', Username);
        Account acc = new Account();
        acc.Name = 'testAccount';
        insert acc;
        Contact con = new Contact ();
        con.FirstName ='test';
        con.LastName ='testsecond';
        insert con;
        Id proId =[select id from profile where name ='Customer Community General User'].id;
        User u= new User();
        u.Username = Username;
        u.email = 'testLastName@TestEmail.com';
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
        Map<ID, User> usermap = new Map<ID, User>();
        usermap.put(u.id,u);
        
        // WHEN login is called
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.loginAuthenticate(Username, 'TestLastName', '/');
        Test.stopTest();
        
        // THEN a null result should be returned
        //Start assertion
        Assert.isNotNull(resultsMap.get('result'));
    }
    
    /**
* @description Tests requestResetPassword method with match
*/
    @isTest 
    static void validate_RequestResetPassword_WithMatch() {
        // GIVEN Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        String Username = uniqueName + '@test1' + orgId + '.org';
        
        Account acc = new Account();
        acc.Name = 'testAccount';
        insert acc;
        Contact con = new Contact ();
        con.FirstName ='test';
        con.LastName ='testsecond';
        insert con;
        Id proId =[select id from profile where name ='Customer Community General User'].id;
        User u= new User();
        u.Username = Username;
        u.email = 'testLastName@TestEmail.com';
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
        //retrieve test community user
        User testCommunityUser = [SELECT Id, Username
                                  FROM User where Username =: Username LIMIT 1 ];
        
        // WHEN a password reset is called
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.requestResetPassword(testCommunityUser.Username);
        Test.stopTest();
        
        // THEN the result should be OK
        //Start assertion
        Assert.areEqual('OK', resultsMap.get('result'));
    }
    
    /**
* @description Tests requestResetPassword method no match
*/
    @isTest 
    static void validate_RequestResetPassword_NoMatch() {
        // GIVEN Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        
        // WHEN a password reset is requested with no matching user
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.requestResetPassword(UserInfo.getUserName());
        Test.stopTest();
        
        // THEN 'NO MATCH' should be returned
        //Start assertion
        Assert.areEqual('NO_MATCH', resultsMap.get('result'));
    }
    
    /**
* @description Tests requestResetPassword method Locked
*/
    @isTest 
    static void validate_ResetPasswordLocked() {
        // GIVEN Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        
        // WHEN a user makes too many bad logins
        Test.startTest();
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        String Username = uniqueName + '@test' + orgId + '.org';
        
        //create user
        ExperienceAuthenticationServices.registerUser('TestFirstName', 'TestLastName', Username);
        Account acc = new Account();
        acc.Name = 'testAccount';
        insert acc;
        Contact con = new Contact ();
        con.FirstName ='test';
        con.LastName ='testsecond';
        insert con;
        Id proId =[select id from profile where name ='Customer Community General User'].id;
        User u= new User();
        u.Username = Username;
        u.email = 'testLastName@TestEmail.com';
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
        
        //FIRST ATTEMPT
        ExperienceAuthenticationServices.tstFailedLoginAttempts = null; // null is replaced with 0 (EPCP-3709)
        resultsMap = ExperienceAuthenticationServices.loginAuthenticate(Username, 'WrongPassword1', '/partner');
        Assert.areEqual('Sorry, the details you\'ve entered are incorrect.  Please check your spelling and try again, or reset your password. You have 2 more login attempt(s) before your account is temporarily locked', resultsMap.get('message'));
        
        //SECOND ATTEMPT 
        ExperienceAuthenticationServices.tstFailedLoginAttempts = 1;
        resultsMap = ExperienceAuthenticationServices.loginAuthenticate(Username, 'WrongPassword2', '/partner');
        Assert.areEqual('Sorry, the details you\'ve entered are incorrect.  Please check your spelling and try again, or reset your password. You have 1 more login attempt(s) before your account is temporarily locked', resultsMap.get('message'));
        
        //THIRD ATTEMPT - User Locked
        ExperienceAuthenticationServices.tstFailedLoginAttempts = 2;
        resultsMap = ExperienceAuthenticationServices.loginAuthenticate(Username, 'WrongPassword3', '/partner');
        Assert.areEqual('Your account has been temporarily locked due to too many unsuccessful login attempts. Try again in 15 minutes. You will not be able to reset your password during this time', resultsMap.get('message'));
        
        // Trying to reset password while locked 
        ExperienceAuthenticationServices.tstIsPasswordLocked = true;
        resultsMap = ExperienceAuthenticationServices.requestResetPassword(Username);
        Test.stopTest();
        
        // THEN the user should be locked out
        //Start assertion
        Assert.areEqual('LOCKED', resultsMap.get('result'));
    }
    
    /**
* @description Tests sendResetLinkToUser method 
*/
    @isTest 
    static void validate_SendResetLinkToUser() {
        
        // GIVEN Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        
        setupData();
        
        Contact con = [SELECT id FROM Contact WHERE FirstName = 'test' AND LastName ='testsecond' LIMIT 1];
        User usr = [SELECT id FROM User WHERE ContactId =: con.id LIMIT 1];
        
        // WHEN a user requests a password reset
        System.runAs(usr) {
            Test.startTest();
            PermissionSet ps = [SELECT id FROM PermissionSet WHERE Name = 'Customer_Community_My_Application' LIMIT 1];
            Id psId = ps != null ? ps.id : '';
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = psId, AssigneeId = usr.id);
            insert psa;  
            resultsMap = ExperienceAuthenticationServices.sendResetLinkToUser(con.Id, 'My.App');
            Test.stopTest();
        }
        // THEN the message returned should be null
        //Start assertion
        Assert.isNotNull(resultsMap.get('message'));
    }   
    /**
* @description Tests sendResetLinkToUser method - when there is no matching User
*/
    @isTest 
    static void validate_SendResetLinkToUser_NoMatch() {
        
        // GIVEN Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        
        // WHEN a reset link is sent to a user that does not exist
        Test.startTest(); 
        resultsMap = ExperienceAuthenticationServices.sendResetLinkToUser('', 'My.App');
        Test.stopTest();
        
        // THEN the result should be 'ERROR'
        //Start assertion
        Assert.areEqual('ERROR', resultsMap.get('result'));
    }
    
   /**
	* @description Tests getPortalUserInfo method
	*/
    @isTest 
    static void validate_getPortalUserInfo() {
        
        // GIVEN Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        
        setupData();
        
        Contact con = [SELECT id FROM Contact WHERE FirstName = 'test' AND LastName ='testsecond' LIMIT 1];
        User usr = [SELECT id FROM User WHERE ContactId =: con.id LIMIT 1];
        // WHEN info is retrieved for the usert
        System.runAs(usr) {
            Test.startTest();
            PermissionSet ps = [SELECT id FROM PermissionSet WHERE Name = 'Customer_Community_My_Application' LIMIT 1];
            Id psId = ps != null ? ps.id : '';
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = psId, AssigneeId = usr.id);
            insert psa;  
            resultsMap = ExperienceAuthenticationServices.getPortalUserInfo(con.Id);
            Test.stopTest();
        }
        
        // THEN the result should be OK
        //Start assertion
        Assert.areEqual('OK', resultsMap.get('result'));
        Assert.areEqual('My.App', resultsMap.get('communities'));
    }
    
   /**
	* @description Tests getPortalUserInfo method - when there is no matching User
	*/
    @isTest 
    static void validate_GetPortalUserInfo_InvalidContact() {
        // GIVEN Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        String contactID = '';
        // WHEN no contact matches the user
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.getPortalUserInfo(contactID);
        Test.stopTest();
        
        // THEN an ERROR should be returned
        //Start assertion
        Assert.areEqual('ERROR', resultsMap.get('result'));
    }
   
   /**
	* @description Tests getPortalUserInfo method - when there is no matching Username
	*/
    @isTest 
    static void validate_GetPortalUserInfo_InvalidUsername() {
        // GIVEN Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        //testing with a 18 char long string, which might masquearade as an ID 
        String userName = '123a3003@abcdz.ttt';
        // WHEN an invalid userna,e is supplied
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.getPortalUserInfo(userName);
        Test.stopTest();
        
        // THEN an ERROR should be returned
        //Start assertion
        Assert.areEqual('ERROR', resultsMap.get('result'));
        Assert.areEqual('User is not part of any Communities', resultsMap.get('message'));
    }
    
   /**
	* @description Tests registerUser method
	*/
    @isTest 
    static void validate_RegisterContact() {
        // GIVEN a valid contact
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = new Account(Name = 'TestAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        
        // WHEN this contact is registered as a my app user
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.registerUser(testContact);
        Test.stopTest();
        
        // THEN the result should be OK
        //Start assertion
        Assert.areEqual('OK', resultsMap.get('result'));
    }
    
    /**
	* @description Tests registerUser method else part
	*/
    @isTest 
    static void validate_RegisterUserelse() {
        // GIVEN an existing user
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        String Username = uniqueName + '@test4' + orgId + '.org';
        
        //Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account acc = new Account();
        acc.Name = 'testAccount';
        insert acc;
        
        Contact con = new Contact ();
        con.FirstName ='test';
        con.LastName ='testsecond';
        con.AccountId = acc.id;
        insert con;
        User thisUser = [ select Id,Username from User where Id = :UserInfo.getUserId() ];
        
        Id proId =[select id from profile where name ='Customer Community General User'].id;
        User u= new User();
        u.Username = Username;
        u.email = 'testLastName@TestEmail.com';
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
        
        //retrieve test community user
        User testCommunityUser = [SELECT Id, Username
                                  FROM User where Username =: Username LIMIT 1 ];
        // WHEN the user is registered
        System.runAs ( thisUser ) {
            Test.startTest();
            // Assign MFA perm set to test duplicate PS assignment handling
            for(PermissionSet permSet : [SELECT Id, Name FROM PermissionSet WHERE Name = 'Experience_Custom_MFA']) {
                List<PermissionSetAssignment>  psList = [
                    SELECT Id 
                    FROM PermissionSetAssignment 
                    WHERE PermissionSetId = :permSet.Id AND AssigneeId=:u.Id];
                
                if (psList.isEmpty()) {
                    PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = permSet.Id, AssigneeId = testCommunityUser.Id);
                    insert psa;
                }
            }
            
            resultsMap = ExperienceAuthenticationServices.registerUser('TestFirstName', 'TestLastName', testCommunityUser.Username);
            Test.stopTest();
        }
        
        // THEN the result should return 'NoPermissionSet' 
        //Start assertion
        Assert.areEqual('NoPermissionSet', resultsMap.get('result'));
    }
    
    /**
	* @description Tests changeUserPassword method
	*/
    @isTest 
    static void validate_ChangeUserPassword() {
        // GIVEN Initialize variables
        ExperienceAuthenticationServices testController = new ExperienceAuthenticationServices();
        
        // WHEN a password change is initiated
        Test.startTest();
        testController.oldPassword = 'NewPassword123!';
        testController.newPassword = 'NewPassword123!';
        testController.changeUserPassword();
        
        Test.stopTest();
        
        //Start assertion
        Assert.areEqual('Error: You cannot reuse this old password.', testController.changePasswordError);
        
        // THEN: only the current session is active
        List<AuthSession> loggedUserNonCurrentSession = [SELECT Id FROM AuthSession WHERE UsersId = :UserInfo.getUserId() AND IsCurrent = false];
        Assert.areEqual(0, loggedUserNonCurrentSession.size());
    }
    
   /**
	* @description Tests generateUserResetApplicationProgressStatus method
	*/
    @isTest 
    static void validate_GenerateUserResetApplicationProgressStatus() {
        // GIVEN an application
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = new Account(Name = 'TestAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        Partner_Agreement__c pa = new Partner_Agreement__c(Quota__C=10, Expiry_date__c= Date.today(), Remaining_quota__C=0,Partner_Account__c=testAccount.Id);
        insert pa; 
        Application__c newApplication = new Application__c(
            Applicant__c = testContact.Id,
            Submission_Progress__c = 'Study Preferences',
            Furthest_Progress__c = 'Review',
            Source_System__c = 'Partner',
            Campus_Location__c = 'Australia',
            Partner_Controlled__c = true,
            Type_of_Study__c = 'Exchange',
            Partner_Agreement__c = pa.Id); 
        insert newApplication;  
        // WHEN application status is reset
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.generateUserResetApplicationProgressStatus(newApplication.Id);
        Test.stopTest();
        // THEN the result should be OK
        //Start assertion
        Assert.areEqual(9.0,[select id,Quota__c, Remaining_quota__c from Partner_Agreement__c where Id=:newApplication.Partner_Agreement__c].Remaining_quota__c);
        Assert.areEqual('OK', resultsMap.get('result'));
    }
    
   /**
	* @description Tests isPartnerEnabled method
	*/
    @isTest 
    static void validate_IsPartnerEnabled() {
        // GIVEN a partner account
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = [SELECT id FROM Account WHERE Name = 'TestAccount'];
        Contact testContact = [SELECT id FROM Contact WHERE Email = 'TestEmail@testemail.com'];
        
        // WHEN a partner chack is made
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.isPartnerEnabled(testContact.Id);
        Test.stopTest();
        
        // THEN it should return SUCCESS
        //Start assertion
        Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
    }
    
   /**
	* @description Tests checkHasPartnerUser method
	*/
    @isTest 
    static void validate_CheckHasPartnerUser() {
        // GIVEN a partner enabled account
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = [SELECT id FROM Account WHERE Name = 'TestAccount'];
        Contact testContact = [SELECT id FROM Contact WHERE Email = 'TestEmail@testemail.com'];
        // WHEN a check for a user is made
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.checkHasPartnerUser(testContact.Id);
        Test.stopTest();
        // THEN SUCCESS status should be returned
        //Start assertion
        Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
    }
    
   /**
	* @description Tests generatePartnerUser method
	*/
    @isTest 
    static void validate_GeneratePartnerUser() {
        // GIVEN an account
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = [SELECT id FROM Account WHERE Name = 'TestAccount'];
        Contact testContact = new Contact(FirstName = 'TestFirstNameTwo', LastName = 'TestLastNameTwo', AccountId = testAccount.Id, Email = 'TestEmailTWO@testemail.com');
        insert testContact;        
        String testUsername = String.valueOf(Math.random()) + 'testemail@testemail.com';
        String userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + testUsername + '","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User"}';
        
        // WHEN account is partner enabled
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.generatePartnerUser(userDetails);
        Test.stopTest();
        
        // THEN status should be SUCCESS
        //Start assertion
        Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
        User usr = [SELECT id, IsPrmSuperUser FROM User WHERE Username = :testUsername LIMIT 1];
        AccountTeamMember atm = [SELECT TeamMemberRole FROM AccountTeamMember WHERE UserId = :usr.id AND AccountId = :testAccount.id LIMIT 1];
        Assert.areEqual('Delegated Admin User', atm.TeamMemberRole, 'Account Team Member not inserted properly');
        Assert.isTrue(usr.IsPrmSuperUser, 'Delegated Admin User not given Super User Access - while generation');
    }
    
   /**
	* @description Tests updatePartnerUser method
	*/
    @isTest 
    static void validate_UpdatePartnerUser() {
        // GIVEN a partner user 
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = [SELECT id FROM Account WHERE Name = 'TestAccount'];
        Contact testContact = [SELECT id FROM Contact WHERE Email = 'TestEmail@testemail.com'];
        String testUsername = String.valueOf(Math.random()) + 'testemail@testemail.com';
        String userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + testUsername + '","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User","PartnerAccountId":"'+testAccount.id +'","isPartnerActive":' + true + '}';
        // WHEN partner details are updated 
        Test.startTest();
        ExperienceAuthenticationServices.generatePartnerUser(userDetails);
        resultsMap = ExperienceAuthenticationServices.updatePartnerUser(userDetails);
        Test.stopTest();
        // THEN status returned should be SUCCESS
        //Start assertion
        Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
    }
    
   /**
	* @description Tests updatePartnerUser method when set to Inactive SFTG-2170
	*/
    @isTest 
    static void validate_UpdatePartnerUser_SetInactive() {
        // GIVEN a partner user
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = [SELECT id FROM Account WHERE Name = 'TestAccount'];
        Contact testContact = [SELECT id FROM Contact WHERE Email = 'TestEmail@testemail.com'];
        User u = [SELECT id, Username FROM User WHERE Username LIKE '%testLastName@TestEmail.com.domain%'];
        
        // WHEN partner is set inactive
        Test.startTest();
        String userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"'+ u.Username + '","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User","PartnerAccountId":"'+testAccount.id +'","isPartnerActive":' + false + '}';
        resultsMap = ExperienceAuthenticationServices.updatePartnerUser(userDetails);
        Test.stopTest();
        
        // THEN the status returfned should be SUCCESS
        //Start assertion
        Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
        List<User> lstUsers = [SELECT IsActive FROM User WHERE id = :u.id LIMIT 1];
        Assert.isFalse(lstUsers[0].IsActive, 'Partner not set inactive');
        List<AccountTeamMember> lstATM = [SELECT TeamMemberRole FROM AccountTeamMember WHERE UserId = :u.id AND AccountId = :testAccount.id LIMIT 1];
        Assert.areEqual(0, lstATM.size(), 'Account Team Member role(s) not removed');
    }
    
   /**
	* @description Tests updatePartnerUser method
	*/
    @isTest 
    static void validate_UpdatePartnerUserRemove() {
        // GIVEN a partner user
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = [SELECT id FROM Account WHERE Name = 'TestAccount'];
        Contact testContact = [SELECT id FROM Contact WHERE Email = 'TestEmail@testemail.com'];
        String testUsername = String.valueOf(Math.random()) + 'testemail@testemail.com';
        String userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + testUsername + '","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User","isPartnerActive":' + true + '}';
        
        // WHEN partner user is removed
        Test.startTest();
        ExperienceAuthenticationServices.generatePartnerUser(userDetails);
        userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + testUsername + '","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User","PartnerAccountId":"'+testAccount.id +'","isPartnerActive":' + true + '}';
        resultsMap = ExperienceAuthenticationServices.updatePartnerUser(userDetails);
        Test.stopTest();
        
        // THEN the status returned should be SUCCESS 
        //Start assertion
        Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
    }
    
   /**
	* @description Tests updatePartnerUser method - change Partner Access Levels
	*/
    @isTest 
    static void validate_UpdatePartnerUserPrimaryAcctHolder() {
        // GIVEN partner user
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = [SELECT id FROM Account WHERE Name = 'TestAccount'];
        Contact testContact = new Contact(FirstName = 'TestFirstNameTwo', LastName = 'TestLastNameTwo', AccountId = testAccount.Id, Email = 'TestEmailTWO@testemail.com');
        insert testContact;  
        String testUsername = String.valueOf(Math.random()) + 'testemail@testemail.com';
        String userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + testUsername + '","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User","isPartnerActive":' + true + '}';
        ExperienceAuthenticationServices.generatePartnerUser(userDetails);
        
        // WHEN the primary account holder is updated
        Test.startTest();
        userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + testUsername + '","Nickname":"TestNickname","PartnerAccessLevel":"Primary Account Holder","PartnerAccountId":"'+testAccount.id +'","isPartnerActive":' + true + '}';
        resultsMap = ExperienceAuthenticationServices.updatePartnerUser(userDetails);
        Test.stopTest();
        
        // THEN the status returned should be SUCCESS
        //Start assertion
        Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
        User usr = [SELECT id, IsPrmSuperUser FROM User WHERE Username = :testUsername LIMIT 1];
        AccountTeamMember atm = [SELECT TeamMemberRole FROM AccountTeamMember WHERE UserId = :usr.id AND AccountId = :testAccount.id LIMIT 1];
        Assert.areEqual('Primary Account Holder', atm.TeamMemberRole, 'Account Team Member not inserted properly');
        Assert.isTrue(usr.IsPrmSuperUser, 'Primary Account Holder not given Super User Access - while updation');
    }
    
   /**
	* @description Tests redirection to Partner_TwoFactor page - redirect to the home page because the password is not set up yet
	*/
    @isTest 
    static void validate_checkTwoFactor_SetupPassword() {
        // GIVEN a portal user
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = new Account(Name = 'TestAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        String userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + String.valueOf(Math.random()) + 'testemail@testemail.com","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User"}';
        
        // WHEN two factor is checked
        Test.startTest();
        PageReference landingPage;
        resultsMap = ExperienceAuthenticationServices.generatePartnerUser(userDetails);
        User testPartnerUser = [SELECT Id, Username
                                FROM User WHERE Id = :(Id)resultsMap.get('PARTNER_ID') LIMIT 1];
        
        // run as partner user
        System.runAs(testPartnerUser) {             
            ExperienceAuthenticationServices pageController = new ExperienceAuthenticationServices();
            landingPage = pageController.checkTwoFactor();
        }
        Test.stopTest();
        
        // THEN the user is redirected
        //Start assertion
        Assert.areEqual('/partner/s/', landingPage.getUrl());
    }
    
    /**
	* @description Tests redirection to Partner_TwoFactor page - redirect to the Partner_TwoFactor page since the password has already been setup
	*/
    @isTest 
    static void validate_checkTwoFactor_SendVerifyCode() {
        // GIVEN Initialize variables
        ExperienceAuthenticationServices testController = new ExperienceAuthenticationServices();
        
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = new Account(Name = 'TestAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        String userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + String.valueOf(Math.random()) + 'testemail@testemail.com","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User"}';
        
        // WHEN two factor is checked
        Test.startTest();
        PageReference landingPage = Page.Partner_TwoFactor;
        resultsMap = ExperienceAuthenticationServices.generatePartnerUser(userDetails);
        
        // retrieve partner user
        User testPartnerUser = [SELECT Id, Username
                                FROM User WHERE Id = :(Id)resultsMap.get('PARTNER_ID') LIMIT 1];  
        
        // run as partner user
        System.runAs(testPartnerUser) {      
            // update 2fa login field
            testPartnerUser.Last_2FA_Login__c = System.NOW();
            update testPartnerUser;
            
            // retrieve landing page
            ExperienceAuthenticationServices pageController = new ExperienceAuthenticationServices();       
            try{
                // overcome error with test class where email verification cant be sent out    
                landingPage = pageController.checkTwoFactor();
            }catch(Exception ex){
                Assert.areEqual('User/Org configuration error: Could not send code due to :Email not verified ', ex.getMessage());
            }
        }
        Test.stopTest();
        
        // THEN the user is redirected
        //Start assertion
        Assert.areEqual('/apex/partner_twofactor', landingPage.getUrl());
    }
    
    /**
	* @description Tests verifying the code sent to the user
	*/
    @isTest 
    static void validate_checkTwoFactor_VerifyCode() {
        // GIVEN a portal user
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = new Account(Name = 'TestAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        String userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + String.valueOf(Math.random()) + 'testemail@testemail.com","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User"}';
        
        // WHEN the MFA code is checked
        Test.startTest();
        PageReference landingPage;
        resultsMap = ExperienceAuthenticationServices.generatePartnerUser(userDetails);
        User testPartnerUser = [SELECT Id, Username
                                FROM User WHERE Id = :(Id)resultsMap.get('PARTNER_ID') LIMIT 1];
        
        // run as partner user
        System.runAs(testPartnerUser) {             
            ExperienceAuthenticationServices pageController = new ExperienceAuthenticationServices();
            pageController.identifier = '78016';
            pageController.verificationCode = '78016';
            landingPage = pageController.verifyVerification();
        }
        Test.stopTest();
        
        // THEN the user is redirected
        //Start assertion
        Assert.areEqual('/partner/s/', landingPage.getUrl());
    }
    
    /**
	* @description Tests checking if the two factor page needs to be skipped or not
	*/
    @isTest 
    static void validate_determineByPassTwoFactor() {
        // GIVEN a portal user
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = new Account(Name = 'TestAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        String userDetails = '{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + String.valueOf(Math.random()) + 'testemail@testemail.com","Nickname":"TestNickname","PartnerAccessLevel":"Delegated Admin User"}';
        
        // WHEN check is made for MFA
        Test.startTest();
        Boolean result = false;
        resultsMap = ExperienceAuthenticationServices.generatePartnerUser(userDetails);
        User testPartnerUser = [SELECT Id, Username
                                FROM User WHERE Id = :(Id)resultsMap.get('PARTNER_ID') LIMIT 1];
        
        // run as partner user
        ExperienceAuthenticationServices.CommitQueryRecords testCommitQueryRecords = new ExperienceAuthenticationServices.CommitQueryRecords();
        result = testCommitQueryRecords.determineByPassTwoFactor((Id)UserInfo.getUserId());
        Test.stopTest();
        
        // THE result should be true
        //Start assertion
        Assert.isTrue(result);
    }
    
    /**
	* @description Tests security helper methods
	*/
    @isTest 
    static void validate_securityHelperMethods() {
        // GIVEN safe and unsafe strings
        string safeText = 'this is safe text';
        string unsafeText = 'This <script> is unsafe';
        
        // WHEN tested for safety
        
        // THEN safe and unsafe strings should be detected
        boolean isUnsafeString = ExperienceAuthenticationServices.isUnsafe(unsafeText);
        Assert.isTrue(isUnsafeString,'Unsafe string should be blocked');
        
        boolean isUnsafeStringList = ExperienceAuthenticationServices.isUnsafe(new List<String>{safeText,unsafeText});
        Assert.isTrue(isUnsafeStringList,'Unsafe string list should be blocked');   
        
        Contact unsafeContact = new Contact(FirstName = unsafeText, lastName = safeText, Salutation = 'Mr');
        
        boolean isUnsafeSObject = ExperienceAuthenticationServices.isUnsafe(unsafeContact);
        Assert.isTrue(isUnsafeSObject,'Unsafe data objects should be blocked');  
        
        Contact safeContact = new Contact(FirstName = safeText, lastName = safeText, Salutation = 'Mr');
        string contactFieldsToKeep = 'LastName,Salutation';
        
        Contact strippedContact = (Contact)ExperienceAuthenticationServices.stripSObject(safeContact,contactFieldsToKeep);
        Assert.isNull(strippedContact.FirstName,'Unwanted stroped fields should be removed from sObject');
        Assert.areEqual(safeText, strippedContact.LastName,'Desired stripped fields should be kept');  
        
        Contact cleanContact = (Contact)ExperienceAuthenticationServices.cleanSObject(safeContact,contactFieldsToKeep);
        Assert.isNull(cleanContact.FirstName,'Unwanted cleaned fields should be removed from SObjet');
        Assert.areEqual(safeText, cleanContact.LastName,'Desired Cleaned fields should be kept');  
        
        Contact dangerContact = (Contact)ExperienceAuthenticationServices.cleanSObject(unsafeContact,contactFieldsToKeep);
        Assert.isNull(dangerContact,'Unsafe cleaned objects should be blocked');
    }
    
    /**
	* Test Agency/Agent 
	*/
    @isTest 
    public static void validate_AgencyCreate()
    {
        // GIVEN an agency
        Map<String, Object> resultsMap = new Map<String, Object>();
        
        Id agencyRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency').getRecordTypeId(); 
        Id agentRecType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Agency_Contact').getRecordTypeId(); 
        
        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                  Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                  Country__c = 'Australia');
        insert australia;
        Account testAccount = new Account(Name = 'TestAgencyAU',
                                          Phone = '12345',
                                          Email__c = 'test@agency.com',
                                          Website = 'www.test-agency-1.com',
                                          Street__c = '123 testing st',
                                          City__c = 'Melbourne',
                                          State__c = 'VIC',
                                          Post_Code__c = '3000',
                                          Country_Lookup__c = australia.Id,
                                          ShippingStreet = '123 testing st',
                                          ShippingCity = 'Melbourne',
                                          ShippingState = 'VIC',
                                          ShippingPostalCode = '3000',
                                          ShippingCountry = 'Australia',
                                          Monash_AM_Web_Status__c = true,
                                          Callista_Org_Unit_Code__c = 'TESTAU',
                                          Monash_AM_Campus__c = 'Australia',
                                          RecordTypeId = AccountUtility.ACCOUNT_AGENCY_REC_TYPE,
                                          Status__c = 'Appointed');  
        insert testAccount;
        
        testAccount.IsPartner =true;
        update testAccount;
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            List<UserRole> urList = new List<UserRole>();
            urList.add(new UserRole( PortalAccountId = testAccount.Id, portalType = 'Partner' ));
            urList.add(new UserRole(PortalAccountId = testAccount.Id, portalType = 'Partner'));
            insert urList;
        }
        String agencyroles = 'Counsellor;Delegated Admin';
        Contact testContact = new Contact(RecordTypeId=agentRecType ,Agency_Contact_Roles__c=agencyroles, FirstName = 'TestAgentFirstName', LastName = 'TestAgentLastName', AccountId = testAccount.Id, Email = 'testagentEmail@testemail.com');
        insert testContact;
        
        String testUsername = String.valueOf(Math.random()) + 'testapemail@testapemail.com';
        String userDetails = '{"isPartnerActive": true,"agencyContactRoles":"Counsellor;Delegated Admin","accountId":"' + testAccount.Id + '","PartnerAccountId":"' + testAccount.Id + '", "ContactId":"' + testContact.Id + '","FirstName":"TestAgentFirstName","MiddleName":"TestAgentMiddleName","LastName":"TestAgentLastName","Email":"testagentEmail@testemail.com","Username":"' + testUsername + '"}';
        // WHEN an agent user is created
        Test.startTest();
        System.runAs(thisUser) {
            resultsMap = ExperienceAuthenticationServices.buildAndGenerateAgentUser(userDetails);
        }
        Test.stopTest();
        
        // THEN the result should be SUCCESS
        //Start assertion
        Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
        User usr = [SELECT id, IsPrmSuperUser,Username,IsActive,Profile.Name FROM User where contactId=:testContact.Id LIMIT 1];
        Assert.isTrue(usr.IsPrmSuperUser, 'All the Agents must given Super User Access - while generation');
        Assert.isTrue(usr.IsActive, 'Agent must be active');
        List<UserRole> uroleList = [Select id,name from UserRole where Id in (select UserRoleId from User  where Id=:usr.Id)];
        Assert.areEqual('TestAgencyAU Partner User',uroleList[0].Name);
        String userDetailsUpd = '{"isPartnerActive": false,"agencyContactRoles":"Branch Manager;Key Counsellor","accountId":"' + testAccount.Id + '","PartnerAccountId":"' + testAccount.Id + '", "ContactId":"' + testContact.Id + '","FirstName":"TestAgentFirstName","MiddleName":"TestAgentMiddleName","LastName":"TestAgentLastName","Email":"testagentEmail@testemail.com","Username":"' + testUsername + '"}';
        Map<String, Object> updmap = null;
        System.runAs(thisUser) {
            updmap  = ExperienceAuthenticationServices.updateAgentUser(userDetailsUpd);
        }
        User usr1 = [SELECT id, IsPrmSuperUser,IsActive,Username,Profile.Name FROM User where contactId=:testContact.Id LIMIT 1];
        Assert.isFalse(usr1.IsActive, 'Agent must not be active');
        String userDetailsUpd1 = '{"isPartnerActive": true,"agencyContactRoles":"Branch Manager;Key Counsellor","accountId":"' + testAccount.Id + '","PartnerAccountId":"' + testAccount.Id + '", "ContactId":"' + testContact.Id + '","FirstName":"TestAgentFirstName","MiddleName":"TestAgentMiddleName","LastName":"TestAgentLastName","Email":"testagentEmail@testemail.com","Username":"' + testUsername + '"}';
        System.runAs(thisUser) {
            updmap  = ExperienceAuthenticationServices.updateAgentUser(userDetailsUpd1);
        }
        User usr2 = [SELECT id, IsPrmSuperUser,IsActive,Username,Profile.Name FROM User where contactId=:testContact.Id LIMIT 1];
        Assert.isTrue(usr2.IsActive, 'Agent must  be active');
    }
    
    /**
	* Test Partner Manager Role
	*/
    @isTest 
    public static void validate_AssignAgencyPartnerManagerRole()
    {
        // GIVEN an agent user
        Map<String, Object> resultsMap = new Map<String, Object>();
        
        Id agentRecType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Agency_Contact').getRecordTypeId(); 
        Id agencyRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency').getRecordTypeId(); 
        
        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                  Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                  Country__c = 'Australia');
        insert australia;
        
        Account testAccount = new Account(Name = 'TestAgencyAU',
                                          Phone = '12345',
                                          Email__c = 'test@agency.com',
                                          Website = 'www.test-agency-1.com',
                                          Street__c = '123 testing st',
                                          City__c = 'Melbourne',
                                          State__c = 'VIC',
                                          Post_Code__c = '3000',
                                          Country_Lookup__c = australia.Id,
                                          ShippingStreet = '123 testing st',
                                          ShippingCity = 'Melbourne',
                                          ShippingState = 'VIC',
                                          ShippingPostalCode = '3000',
                                          ShippingCountry = 'Australia',
                                          Monash_AM_Web_Status__c = true,
                                          Callista_Org_Unit_Code__c = 'TESTAU',
                                          Monash_AM_Campus__c = 'Australia',
                                          RecordTypeId = AccountUtility.ACCOUNT_AGENCY_REC_TYPE,
                                          Status__c = 'Appointed');  
        insert testAccount;
        testAccount.IsPartner =true;
        update testAccount;
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            List<UserRole> urList = new List<UserRole>();
            urList.add(new UserRole( PortalAccountId = testAccount.Id, portalType = 'Partner' ));
            urList.add(new UserRole(PortalAccountId = testAccount.Id, portalType = 'Partner'));
            insert urList;
        }
        String agencyroles = 'Counsellor;Branch Manager';
        Contact testContact = new Contact(RecordTypeId=agentRecType ,Agency_Contact_Roles__c=agencyroles, FirstName = 'TestAgentFirstName', LastName = 'TestAgentLastName', AccountId = testAccount.Id, Email = 'testagentEmail@testemail.com');
        insert testContact;
        String testUsername = String.valueOf(Math.random()) + 'testapemail@testapemail.com';
        String userDetails = '{"isPartnerActive": true,"agencyContactRoles":"Counsellor;Delegated Admin","accountId":"' + testAccount.Id + '","PartnerAccountId":"' + testAccount.Id + '", "ContactId":"' + testContact.Id + '","FirstName":"TestAgentFirstName","MiddleName":"TestAgentMiddleName","LastName":"TestAgentLastName","Email":"testagentEmail@testemail.com","Username":"' + testUsername + '"}';
        // WHEN partner role is assigned
        Test.startTest();
        System.runAs(thisUser) {
            resultsMap = ExperienceAuthenticationServices.checkHasAgentUser(testContact.Id);
            resultsMap = ExperienceAuthenticationServices.buildAndGenerateAgentUser(userDetails);
        }
        Test.stopTest();
        
        // THEN result should be SUCCESS
        //Start assertion
        Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
        User usr = [SELECT id, IsPrmSuperUser,Username,IsActive,Profile.Name FROM User where contactId=:testContact.Id LIMIT 1];
        Assert.isTrue(usr.IsPrmSuperUser, 'All the Agents must given Super User Access - while generation');
        Assert.isTrue(usr.IsActive, 'Agent must be active');
        List<UserRole> uroleList = [Select id,name from UserRole where Id in (select UserRoleId from User  where Id=:usr.Id)];
        Assert.areEqual('TestAgencyAU Partner Manager',uroleList[0].Name);
    }
    
    /** 
	* @description Tests checkAgentUser method
	*/
    @isTest 
    static void validate_CheckHasAgentUser() {
        // GIVEN an account 
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = [SELECT id FROM Account WHERE Name = 'TestAccount'];
        Contact testContact = [SELECT id FROM Contact WHERE Email = 'TestEmail@testemail.com'];
        // WHEN a check is made for an agent user
        Test.startTest();
        resultsMap = ExperienceAuthenticationServices.checkHasAgentUser(testContact.Id);
        Test.stopTest();
        
        // THEN it should return SUCCESS
        //Start assertion
        Assert.areEqual('SUCCESS', resultsMap.get('STATUS'));
    }
    
    private static void setupData() {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        String Username = uniqueName + '@test1' + orgId + '.org';
        
        Account acc = new Account();
        acc.Name = 'testAccount';
        insert acc;
        Contact con = new Contact ();
        con.FirstName ='test';
        con.LastName ='testsecond';
        insert con;
        
        Id profileId =[select id from profile where name ='Customer Community General User'].id;
        User u= new User();
        u.Username = Username;
        u.email = 'testLastName@TestEmail.com';
        u.ContactId = con.id; 
        u.LastName ='test';
        u.Alias ='test';
        u.isActive = true;
        u.TimeZoneSidKey ='Australia/Sydney';
        u.LocaleSidKey ='en_AU';
        u.EmailEncodingKey ='ISO-8859-1';
        u.ProfileId = profileId;
        u.LanguageLocaleKey ='en_US';
        insert u;
    }
}