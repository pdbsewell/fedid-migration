/**
 * @author Peter Sewell
 * @date 24-Oct-2023
 * @group Platforms
 * @description Test Class for WesLoginAndRegistrationController
 * Revision  2023-10-24   Peter Sewell			Create 
 * 2023-11-03   Peter Sewell    Updated test to handle multiple CP scenrios 
 * 2023-11-13   Peter Sewell    test for DOB inlast week of December
 * 2023-11-15   Peter Sewell    test trim of leading and trailing spaces
 * 2024-03-14   Peter Sewell    test for mono name support (no first name)
 * 2024-10-09   Peter Sewell    test for null inputs to registration check method
 * 2024-10-09   Peter Sewell    convert from system.assert to assert class
 */
@isTest//(isParallel=true) In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
public class WesLoginAndRegistrationController_Test {

    @TestSetup
    static void setupData() {
        
        User LoggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(LoggedInUser ) {
    
            //create past student contact #1 (needed by user)
            Contact contact1 = new contact(
                LastName = ' LastName ', // intentionally add leading and trailing spaces
                Firstname = ' FirstName ', // intentionally add leading and trailing spaces
                Birthdate =  Date.valueOf('1997-12-31'),
                Person_ID_unique__c = '12345678');
            insert contact1;

            //create past student contact #2 
            Contact contact2 = new contact(
                LastName = 'LastName', 
                Firstname = 'FirstName', 
                Birthdate =  Date.valueOf('1997-12-31'),
                Person_ID_unique__c = WesLoginAndRegistrationController.TST_CONTACT_PERSON_ID);
            insert contact2;

            //create past student contact #3 linked to a community user
            String theEmail = generateRandomString() + '@wessywoo.com';
            Contact contact3 = new contact(
                LastName = 'LastName', 
                Firstname = 'FirstName', 
                Birthdate =  Date.valueOf('1997-12-31'),
                Person_ID_unique__c = '99999999',
                Email = theEmail,
                Personal_Email__c = theEmail);
            insert contact3;
            Contact c3 = [SELECT id, Last_Name__c, LastName, First_Name__c, Firstname, Birthdate, Person_ID_unique__c, Email, PersonalEmail_Text__c FROM Contact WHERE Person_ID_unique__c = '99999999'];
            createUserForContact(c3);

            //create an inactive user record with a person id set
            createInactiveUserWithStudentId('32323232');

            // Create a dummy Custom Setting
            WesLogin__c wesCustomSetting = WesLogin__c.getInstance();
            wesCustomSetting.Client_Id__c = '3MVG9mywN3hwYEwnV8jOp2hd64bsrUDBSx2jLs0nX8xj5IxqGDNszVAQ1n0ITTTs1kQWcF6Py9IVXaFpNOsNB';
            wesCustomSetting.Certificate_Name__c = 'MyCert';
            wesCustomSetting.Email_OTP__c = false;
            upsert wesCustomSetting; 
        }
    }

    // Tests: cleanPersonIdFromInactiveNonPortalUser()
    // Scenario: Inactive user record has studentId
    //
	@IsTest
    static void cleanPersonIdFromInactiveNonPortalUser_test() {
        
        // given : student details with student Id that exists on an inactive user record
        String studentId = '32323232'; 
        
        // when : cleanPersonIdFromInactiveNonPortalUser is invoked
        Boolean result = false;
        test.startTest();
            result = WesLoginAndRegistrationController.cleanPersonIdFromInactiveNonPortalUser(studentId);
        test.stopTest();

        // then: should return true to indicate it found an inactive user with that studentId set
        Assert.areEqual(true, result, 'User should have been found for this student id');
    } 

    // Tests: checkRegistrationDetails()
    // Scenario: Mono name (contact has null legal first name)
    //
	@IsTest
    static void checkRegistrationDetails_Mononame_test() {
        
        // given : student details with mono name
        String studentId = '12345678'; 
        String firstName = null;
        String lastName = 'LastName';
        String dateOfBirth = '1997-12-31';

        // given : a past student contact 
        Contact ctc = [SELECT id, Email, MobilePhone, First_Name__c, FirstName,
                PersonalEmail_Text__c, Person_ID_unique__c, Person_Id__c, Is_Student__c 
                FROM Contact WHERE Person_Id__c = :studentId];
        
        // Ensure is a past student
        ctc.Is_Student__c = false;

        // Make mono name (no first name)
        ctc.FirstName = null;   
        ctc.First_Name__c = null;

        // Add email   
        ctc.Email = generateRandomString() + '@wessywoo.com'; 
        update ctc;

        // Add a mobile
        Phone__c mobile = new Phone__c(
        name = '0491570006',
        Type__c = 'Mobile',
        Classification__c = 'Private',
        Verification_Status__c = 'Verified',
        Is_Active__c = true,
        Contact__c = ctc.Id);
        insert mobile;

        WesLoginAndRegistrationController.CheckRegistrationDetailsResult result;
        
        // when : mono name contact us checked
        test.startTest();
            result = WesLoginAndRegistrationController.checkRegistrationDetails(
                studentId, 
                dateOfBirth, 
                firstName, 
                lastName);

        test.stopTest();

        // then: should match a contact
        Assert.areEqual('SUCCESS', result.status, 'Contact match for this student id should have succeeded');
    } 

    // Tests: checkRegistrationDetails()
    // Scenario: Bad input e.g. XSS
    //
	@IsTest
    static void checkRegistrationDetails_UnsafeInput_test() {
        
        // given : student details 
        String studentId = '12345678'; 
        String firstName = '<div>'; // Bad input
        String lastName = 'LastName';
        String dateOfBirth = '1997-12-31';

        WesLoginAndRegistrationController.CheckRegistrationDetailsResult result;
        
        // when : unsafe inputs such as XSS are provided
        test.startTest();
            result = WesLoginAndRegistrationController.checkRegistrationDetails(
                studentId, 
                dateOfBirth, 
                firstName, 
                lastName);

        test.stopTest();

        // then: 
        String expectedErrMsg = WesLoginAndRegistrationController.MSG.get('UNSAFE_INPUT');
        Assert.areEqual('FAILED', result.status, 'Check should fail if unsafe input provided');
        Assert.areEqual(expectedErrMsg, result.errorMessage, 'Unexpected error message if unsafe input provided');
    } 
    
    // Tests: checkRegistrationDetails()
    // Scenario: No contact matched to provided student id
    //
	@IsTest
    static void checkRegistrationDetails_StudentIdNotFound_test() {
        
        // given : student details 
        String studentId = '87655555'; // no match
        String firstName = 'FirstName';
        String lastName = 'LastName';
        String dateOfBirth = '1997-12-31';

        WesLoginAndRegistrationController.CheckRegistrationDetailsResult result;
        
        // when : non matching student details are checked
        test.startTest();
            result = WesLoginAndRegistrationController.checkRegistrationDetails(
                studentId, 
                dateOfBirth, 
                firstName, 
                lastName);

        test.stopTest();

        // then: 
        String expectedErrMsg = WesLoginAndRegistrationController.MSG.get('NO_PAST_STUDENT');
        Assert.areEqual('FAILED', result.status, 'Check should fail if studentId does not match a contact');
        Assert.areEqual(expectedErrMsg, result.errorMessage, 'Unexpected error message if studentId does not match a contact');
    } 

    // Tests: checkRegistrationDetails()
    // Scenario: No contact matched to provided student details
    //
	@IsTest
    static void checkRegistrationDetails_NoContactMatch_test() {
        
        // given : student details 
        String studentId = '12345678'; 
        String firstName = 'SomeOtherName'; // no match
        String lastName = 'LastName';
        String dateOfBirth = '1997-12-31';

        WesLoginAndRegistrationController.CheckRegistrationDetailsResult result;
        
        // when : non matching student details are checked
        test.startTest();
            result = WesLoginAndRegistrationController.checkRegistrationDetails(
                studentId, 
                dateOfBirth, 
                firstName, 
                lastName);

        test.stopTest();

        // then: 
        String expectedErrMsg = WesLoginAndRegistrationController.MSG.get('NO_CONTACT_MATCH');
        Assert.areEqual('FAILED', result.status, 'Check should fail if details do not match a contact');
        Assert.areEqual(expectedErrMsg, result.errorMessage, 'Unexpected error message if details do not match a contact');
    } 

    // Tests: checkRegistrationDetails()
    // Scenario: Details match a current student contact (not a past student)
    //
	@IsTest
    static void checkRegistrationDetails_IsCurrentStudent_test() {
        
        // given : student details 
        String studentId = '12345678'; 
        String firstName = 'FirstName'; 
        String lastName = 'LastName';
        String dateOfBirth = '1997-12-31';
        
        // given : a current student contact 
        Contact ctc = [SELECT id, Is_Student__c FROM Contact WHERE Person_Id__c = :studentId];
        ctc.Is_Student__c = true;
        update ctc;

        WesLoginAndRegistrationController.CheckRegistrationDetailsResult result;
        
        // when : a matching contact is a current student
        test.startTest();
            result = WesLoginAndRegistrationController.checkRegistrationDetails(
                studentId, 
                dateOfBirth, 
                firstName, 
                lastName);

        test.stopTest();

        // then: 
        String expectedErrMsg = WesLoginAndRegistrationController.MSG.get('CURRENT_STUDENT');
        Assert.areEqual('FAILED', result.status, 'Check should fail if details match a current student');
        Assert.areEqual(expectedErrMsg, result.errorMessage, 'Unexpected error message if details match a current student');
    } 

    // Tests: checkRegistrationDetails()
    // Scenario: Details match a contact with no valid (non Monash) email
    //
	@IsTest
    static void checkRegistrationDetails_NoEmail_test() {
        
        // given : student details 
        String studentId = '12345678'; 
        String firstName = 'FirstName'; 
        String lastName = 'LastName';
        String dateOfBirth = '1997-12-31';
        
        // given : a current student contact 
        Contact ctc = [SELECT id, Email FROM Contact WHERE Person_Id__c = :studentId];
        ctc.Email = 'contact@monash.edu';
        update ctc;

        WesLoginAndRegistrationController.CheckRegistrationDetailsResult result;
        
        // when : a matching contact has no valid email
        test.startTest();
            result = WesLoginAndRegistrationController.checkRegistrationDetails(
                studentId, 
                dateOfBirth, 
                firstName, 
                lastName);

        test.stopTest();

        // then: 
        String expectedErrMsg = WesLoginAndRegistrationController.MSG.get('NO_PERSONAL_EMAIL');
        Assert.areEqual('FAILED', result.status, 'Check should fail if matched contact has no personal email');
        Assert.areEqual(expectedErrMsg, result.errorMessage, 'Unexpected error message if matched contact has no personal email');
    } 

    // Tests: checkRegistrationDetails()
    // Scenario: Details match a contact with no valid contact point
    //
	@IsTest
    static void checkRegistrationDetails_NoContactPoint_test() {
        
        // given : student details 
        String studentId = '12345678'; 
        String firstName = 'FirstName'; 
        String lastName = 'LastName';
        String dateOfBirth = '1997-12-31';

        // given : a current student contact 
        Contact ctc = [SELECT id, Email, PersonalEmail_Text__c FROM Contact WHERE Person_Id__c = :studentId];
        ctc.Email = generateRandomString() + '@wessywoo.com';
        update ctc;

        WesLoginAndRegistrationController.CheckRegistrationDetailsResult result;
        
        // when : a matching contact has no valid contact point
        test.startTest();
            result = WesLoginAndRegistrationController.checkRegistrationDetails(
                studentId, 
                dateOfBirth, 
                firstName, 
                lastName);

        test.stopTest();

        // then: 
        String expectedErrMsg = WesLoginAndRegistrationController.MSG.get('NO_CONTACT_POINT');
        Assert.areEqual('FAILED', result.status, 'Check should fail if matched contact has no valid OTP contact point');
        Assert.areEqual(expectedErrMsg, result.errorMessage, 'Unexpected error message if matched contact has no valid OTP contact point');
    } 

    // Tests: getValidContactPoints()
    // Scenario: Simulates an exception when retrieving contact points and fallback to personal email
    //
	@IsTest
    static void getValidContactPoints_FallbackToEmail_test() {
        
        // given : a current student contact 
        Contact ctc = [SELECT id, Email, PersonalEmail_Text__c, Person_ID_unique__c, Person_Id__c FROM Contact WHERE Person_Id__c = :WesLoginAndRegistrationController.TST_CONTACT_PERSON_ID];
        ctc.Email = generateRandomString() + '@wessywoo.com';
        update ctc;
        // Add a mobile
        Phone__c mobile = new Phone__c(
            name = '0491570006',
            Type__c = 'Mobile',
            Classification__c = 'Private',
            Verification_Status__c = 'Verified',
            Is_Active__c = true,
            Contact__c = ctc.Id);
        insert mobile;

        String contactPointStr = '';
        
        // when : this contact is passed to getValidContactPoints it should simulate an Experian exception
        test.startTest();
            contactPointStr = WesLoginAndRegistrationController.getValidContactPoints(ctc);
        test.stopTest();

        // then: the only contact point should be the personal email address of the contact
        Assert.areEqual(ctc.email, contactPointStr, 'Contact point should have been personal email address');
    } 

    // Tests: checkRegistrationDetails()
    // Scenario: Details match a valid contact and so a user should be created
    //
	@IsTest
    static void checkRegistrationDetails_CreateUser_test() {
        
        // given : student details 
        String studentId = '12345678'; 
        String firstName = ' FirstName';    // intentional leading space
        String lastName = 'LastName ';      // intentional trailing space
        String dateOfBirth = '1997-12-31';

        // given : a current student contact 
        Contact ctc = [SELECT id, Email, MobilePhone, 
                              PersonalEmail_Text__c, Person_ID_unique__c, Person_Id__c 
                       FROM Contact WHERE Person_Id__c = :studentId];
        // Add email
        ctc.Email = generateRandomString() + '@wessywoo.com';
        update ctc;
        // Add a mobile
        Phone__c mobile = new Phone__c(
            name = '0491570006',
            Type__c = 'Mobile',
            Classification__c = 'Private',
            Verification_Status__c = 'Verified',
            Is_Active__c = true,
            Contact__c = ctc.Id);
        insert mobile;

        WesLoginAndRegistrationController.CheckRegistrationDetailsResult result;
        WesLoginAndRegistrationController.CheckRegistrationDetailsResult sendCodeResult;
        String uniqueUsername;
        User u;
        String mobileCp = '';
        
        // when : a matching contact id found
        test.startTest();
            User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs ( thisUser ) {
                mobileCp = WesLoginAndRegistrationController.getValidMobileNumber(ctc);
                result = WesLoginAndRegistrationController.checkRegistrationDetails(
                    studentId, 
                    dateOfBirth, 
                    firstName, 
                    lastName);
                sendCodeResult = WesLoginAndRegistrationController.sendCode(
                    '0',
                    studentId, 
                    dateOfBirth, 
                    firstName, 
                    lastName);
                // Now test ability to test for unique username
                u = [SELECT username FROM User WHERE Person_Id__c = :studentId];
                uniqueUsername = WesLoginAndRegistrationController.createUniqueUsername(u.username); // Username should be suffixed
            }
        test.stopTest();

        // then: contact match should succeed and a user for this contact should have been created
        Assert.areEqual(false, String.isBlank(mobileCp), 'Mobile contact point should not be blank');
        Assert.areEqual('SUCCESS', result.status, 'Contact match for this student id should have succeeded');
        List<User> usrs = [SELECT id, Contact_Date_of_Birth__c FROM User WHERE Person_Id__c = :studentId AND contactId = :ctc.id];
        Assert.areEqual(1, usrs.size(), 'A user associated to the contact should have been created');
        Assert.areNotEqual(u.username, uniqueUsername, 'A unique user name should have been created by createUniqueUsername()');

    } 

    // Tests: verifyLogin()
    // Scenario: Simulates login of a valid user/contact
    //
	@IsTest
    static void checkRegistrationDetails_verifyLogin_test() {
        
        // given : student details 
        String studentId = '12345678'; 
        String firstName = 'FirstName'; 
        String lastName = 'LastName';
        String dateOfBirth = '1997-12-31';

        // given : a current student contact 
        Contact ctc = [SELECT id, Email, MobilePhone FROM Contact WHERE Person_Id__c = :studentId];
        // Add email
        ctc.Email = generateRandomString() + '@wessywoo.com';
        update ctc;
        // Add a mobile
        Phone__c mobile = new Phone__c(
            name = '0491570006',
            Type__c = 'Mobile',
            Classification__c = 'Private',
            Verification_Status__c = 'Verified',
            Is_Active__c = true,
            Contact__c = ctc.Id);
        insert mobile;

        WesLoginAndRegistrationController.CheckRegistrationDetailsResult contactCheckResult;
        WesLoginAndRegistrationController.CheckRegistrationDetailsResult sendCodeResult;
        WesLoginAndRegistrationController.LoginResult loginResult;

        // when : a matching contact id found
        test.startTest();
            User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs ( thisUser ) {
                contactCheckResult = WesLoginAndRegistrationController.checkRegistrationDetails(
                    studentId, 
                    dateOfBirth, 
                    firstName, 
                    lastName);
                sendCodeResult = WesLoginAndRegistrationController.sendCode(
                    '0',
                    studentId, 
                    dateOfBirth, 
                    firstName, 
                    lastName);
                loginResult = WesLoginAndRegistrationController.verifyLogin(studentId, '/return/url', '123456');
            }
        test.stopTest();

        // then: login result should be SUCCESS
        Assert.areEqual('SUCCESS', loginResult.status, 'Login should have succeeded');
    } 

    // Tests: verifyLogin()
    // Scenario: Simulates login of a valid user/contact where the contact is 
    // associated with an existing but deactivated user, and a new user has to be created
    //
	@IsTest
    static void checkRegistrationDetails_verifyLoginDeactivatedUser_test() {
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];

        // given : student details 
        String studentId = '99999999'; 
        String firstName = 'FirstName'; 
        String lastName = 'LastName';
        String dateOfBirth = '1997-12-31';

        // given : a current student contact linked to an existing user
        Contact ctc = [SELECT id, Email, MobilePhone FROM Contact WHERE Person_Id__c = :studentId];

        // Add a mobile
        Phone__c mobile = new Phone__c(
            name = '0491570006',
            Type__c = 'Mobile',
            Classification__c = 'Private',
            Verification_Status__c = 'Verified',
            Is_Active__c = true,
            Contact__c = ctc.Id);
        insert mobile;

        System.runAs (thisUser) {
            // Find and deactivate the associated user
            User u = [SELECT id, IsActive FROM User WHERE ContactId = :ctc.id];
            u.IsActive = false;
            update u;
        }

        WesLoginAndRegistrationController.CheckRegistrationDetailsResult contactCheckResult;
        WesLoginAndRegistrationController.CheckRegistrationDetailsResult sendCodeResult;
        WesLoginAndRegistrationController.LoginResult loginResult;

        // when : a matching contact id found
        test.startTest();
            System.runAs (thisUser) {
                contactCheckResult = WesLoginAndRegistrationController.checkRegistrationDetails(
                    studentId, 
                    dateOfBirth, 
                    firstName, 
                    lastName);
                sendCodeResult = WesLoginAndRegistrationController.sendCode(
                    '0',
                    studentId, 
                    dateOfBirth, 
                    firstName, 
                    lastName);
                loginResult = WesLoginAndRegistrationController.verifyLogin(studentId, '/return/url', '123456');
            }
        test.stopTest();

        // then: login result should be SUCCESS
        Assert.areEqual('SUCCESS', loginResult.status, 'Login should have succeeded');
    } 

    // Tests: checkRegistrationDetails()
    // Scenario: Simulates throwing an exception when any of the params are blank
    //
	@IsTest
    static void checkRegistrationDetails_verifyBadInputs_test() {
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        WesLoginAndRegistrationController.CheckRegistrationDetailsResult contactCheckResult;

        // given : student details are blank
        String studentId = ''; 
        String firstName = ''; 
        String lastName = '';
        String dateOfBirth = '';

        // when : these details are passed to the checkRegistrationDetails method
        test.startTest();
            System.runAs (thisUser) {
                contactCheckResult = WesLoginAndRegistrationController.checkRegistrationDetails(
                    studentId, 
                    dateOfBirth, 
                    firstName, 
                    lastName);
            }
        test.stopTest();

        // then: login result should be FAILED
        Assert.areEqual('FAILED', contactCheckResult.status, 'Registration check should have failed');
    }

    // Tests: sendCode()
    // Scenario: Simulates throwing an exception when any of the params are blank
    //
	@IsTest
    static void sendCode_verifyBadInputs_test() {
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        WesLoginAndRegistrationController.CheckRegistrationDetailsResult checkResult;

        // given : student details are blank
        String contactPointIndex = ''; 
        String studentId = ''; 
        String firstName = ''; 
        String lastName = '';
        String dateOfBirth = '';

        // when : these details are passed to the sendCode method
        test.startTest();
            System.runAs (thisUser) {
                checkResult = WesLoginAndRegistrationController.sendCode(
                    contactPointIndex, 
                    studentId,
                    dateOfBirth, 
                    firstName, 
                    lastName);
            }
        test.stopTest();

        // then: result should be FAILED
        Assert.areEqual('FAILED', checkResult.status, 'Send code should have failed');
    }

    // Tests: verifyLogin()
    // Scenario: Simulates throwing an exception when any of the params are blank
    //
	@IsTest
    static void verifyLogin_verifyBadInputs_test() {
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        WesLoginAndRegistrationController.LoginResult loginResult;

        // given : student details are blank
        String studentId = ''; 
        String code = ''; 
        String startURL = '';

        // when : these details are passed to the verifyLogin method
        test.startTest();
            System.runAs (thisUser) {
                loginResult = WesLoginAndRegistrationController.verifyLogin(
                    studentId,
                    code, 
                    startURL);
            }
        test.stopTest();

        // then: result should be FAILED
        Assert.areEqual('FAILED', loginResult.status, 'Verify login should have failed');
    }

    // Tests: LoginResult Class
    // Scenario: Tests logging of error message when status is FAILED 
    //
	@IsTest
    static void loginResult_FailedMessage_test() {
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        WesLoginAndRegistrationController.LoginResult result;

        // given : login result details
        String status = 'FAILED'; 
        String error = 'REG_EXCEPTION'; 
        String studentId = '32323232';

        // when : these details are passed to the LoginResult constructor 
        test.startTest();
            System.runAs (thisUser) {
                result = new WesLoginAndRegistrationController.LoginResult(
                    status,
                    error,
                    studentId
                );
            }
        test.stopTest();

        // then: message should match
        Assert.areEqual(WesLoginAndRegistrationController.MSG.get(error), result.errorMessage, 'Error message does not match');
    }

    private static String generateRandomString() {
        String randomString = '';

        String characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        Integer charactersLength = characters.length();
        
        for (Integer i = 0; i < 20; i++) { // Generate a 20-character random string
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), charactersLength);
            randomString += characters.substring(randomIndex, randomIndex + 1);
        }
        
        return randomString;
    }

    // Instantiates a new community user object associated to the provided contact
    //
    private static void createUserForContact(Contact ctc) {
    
        //retrieve community user profile
        Profile wesProfile = [SELECT Id FROM Profile WHERE Name = :WesLoginAndRegistrationController.SSO_PROFILE LIMIT 1][0];
        
        //prepare community user
        String email = WesLoginAndRegistrationController.getPersonalEmail(ctc);
        User communityUser = new User(
            Username = ctc.email, 
            Email = email, 
            FirstName = ctc.First_Name__c,
            LastName = ctc.Last_Name__c,
            ContactId = ctc.Id, 
            ProfileId = wesProfile.Id);

        //generate user alias
        String alias = '';                      
        if(communityUser.FirstName != null) {
            alias = alias + communityUser.FirstName.toLowerCase().substring(0, 1);
        }
        if(communityUser.LastName.length() > 3){
            alias = alias + communityUser.LastName.toLowerCase().substring(0, 4);
        }else if(communityUser.LastName.length() > 2){
            alias = alias + communityUser.LastName.toLowerCase().substring(0, 3);
        }else if(communityUser.LastName.length() > 1){
            alias = alias + communityUser.LastName.toLowerCase().substring(0, 2);
        }else if(communityUser.LastName.length() > 0){
            alias = alias + communityUser.LastName.toLowerCase().substring(0, 1);
        }

        if(alias.length() > 5) {
            alias = alias.substring(0, 5);
        }         
        communityUser.Alias = alias;

        //generate user nickname
        String nickname = '';
        String contactId = ctc.Id;
        if(communityUser.FirstName != null) {
            nickname = nickname + communityUser.FirstName.toUpperCase().substring(0, 1);
        }
        nickname = nickname + communityUser.LastName.toUpperCase().substring(0, 1);
        nickname = nickname + contactId.substring(2, contactId.length());
        communityUser.CommunityNickname = nickname;
        communityUser.EmailEncodingKey = 'UTF-8';
        communityUser.TimeZoneSidKey = 'Australia/Sydney';
        communityUser.LanguageLocaleKey = 'en_US';
        communityUser.LocaleSidKey = 'en_AU';

        communityUser.Person_Id__c = ctc.Person_ID_unique__c;
        
        insert communityUser;
    } 

    // Instantiates a new community user object associated to the provided contact
    //
    private static void createInactiveUserWithStudentId(String studentId) {
    
        // Fetch the standard profile by its name (e.g., 'Standard User')
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Get current date and time
        String timestamp = String.valueOf(System.currentTimeMillis());
    
        // Construct the username
        String uniqueUsername = 'user.' + timestamp + '@example.com';

        // Create a new user
        User newUser = new User(
            person_id__c = studentId,
            FirstName = 'John',
            LastName = 'Doe',
            Alias = 'jdoe',
            Email = 'johndoe@example.com',
            Username = uniqueUsername,
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles', // Set time zone
            LocaleSidKey = 'en_US', // Set locale
            EmailEncodingKey = 'UTF-8', // Set email encoding
            LanguageLocaleKey = 'en_US', // Set language
            UserRoleId = null, // Set role if needed
            IsActive = false
        );

        insert newUser;
    }

}