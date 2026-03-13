/**
 * @author Inderpal Dhanoa, Engage Enterprise
 * @date 2/23/22
 * @group Engage Enterprise
 * @description Test Class for PortalTwoFactorController used for MFA
 * @revision Ken McGuire 17 Aug 2022 - retired static country list for database table
 * @revision Peter Sewell 01 Dec 2023 - additional Test for Twilio SMS MFA default
 * @revision Peter Sewell 24 Apr 2024 - Test verification rate limit being exceeded
 * @revision Ibrahim Rumi 26 Aug 2025 - fix for vfRegistration test methods
 */
@isTest//(isParallel=true) In parallel Apex Tests, DML operations aren't permitted on this type of object: User: []
public class PortalTwoFactorController_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Test setup
    *******************************************************************************/
    
    @TestSetup
    static void setupData(){
        // insert experience mfa custom setting
        ExperienceMFASetting__c	mfaSetting = new ExperienceMFASetting__c();
        mfaSetting.AutoTest_Bypass_Key__c = 'bypasskeyword';
        insert mfaSetting;
        
        User loggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs ( LoggedInUser ) {
            //Create account
            Account portalAccount1 = new Account(
            Name = 'TestAccount',
            OwnerId = UserInfo.getUserId());
            Database.insert(portalAccount1);       

            //create contact (needed by user)
            Contact contact = new contact(LastName = 'LastName', Firstname = 'FirstName');
            contact.Birthdate =  Date.valueOf('2019-09-24');
            contact.AccountId = portalAccount1.Id;
            insert contact;

            User user = new User();
            user.FirstName = 'Customer';
            user.LastName = 'User';
            user.Alias = 'Test';
            user.MobilePhone = '+61 0401234567';
            user.Mobile_Phone_Country__c = 'Australia';
            user.CommunityNickname = 'Test1';
            user.TimeZoneSidKey = 'America/New_York';
            user.LocaleSidKey = 'en_US';
            user.MFA_Email_Verification_Count__c = 1;
            user.EmailEncodingKey = 'UTF-8';
            user.Email = 'TestEmail925@gmail.com';
            user.Username = 'TestEmail925@gmail.com';
            user.IsActive = true;
            user.LanguageLocaleKey = 'en_US';
            user.App_Birthdate__c = Date.valueOf('2019-09-24');        
            
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name ='Customer Community General User']; //MUST use a profile that is a portal user!
            if(profiles.size() > 0){
                user.ProfileID = profiles[0].Id;       		
                user.ContactId = contact.Id;
                insert user;

                // Grant Permission Set
                List<PermissionSetAssignment> mfaAndPortalAccess = new List<PermissionSetAssignment>();
                for(PermissionSet mfaPermSet : [SELECT Id FROM PermissionSet WHERE Name = 'Experience_Custom_MFA' OR Name = 'Alumni_Portal_Permission_Set']){
                    mfaAndPortalAccess.add(new PermissionSetAssignment(PermissionSetId = mfaPermSet.Id, AssigneeId = user.Id));
                }
                insert mfaAndPortalAccess;
            }  
        }
    }
    private static void setupOtpSettings(Boolean ipRateLimitEnabled) {
        OTPGuard.OTP_SETTINGS = new Admissions_Settings__mdt(
          DeveloperName = 'My_App_OTP_Attempts',
          MasterLabel = 'My App OTP Attempts',
          Configs__c = '{"ipRateLimitEnabled":' +
            String.valueOf(ipRateLimitEnabled).toLowerCase() +
            ',"otpAttemptAllowed":5,"otpttlInSeconds":900,"otpmessage":"Maximum OTP attempts reached","ipRateLimitKey":"perIP","otpAttemptMessage":"Maximum OTP attempts reached","ipRateLimitMessage":"You have exceeded the maximum number of verification code requests"}',
          Messages__c = 'Maximum OTP attempts reached'
        );
      }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User conditional MFA check or bypass the check
    *******************************************************************************/
	@IsTest
    static void checkTwoFactor_Test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email = 'TestEmail925@gmail.com']; 
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', false);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        

        system.runAs(portalUser[0]){
            Test.startTest();
            // setup Test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            // WHEN : the two Factor check is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            PortalTwoFactorController.checkTwoFactor();
            Test.stopTest();
            // THEN: exceptionText is null
            Assert.areEqual(portalTwoFactorController.exceptionText, null);
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User to change the Residing country
    *******************************************************************************/
    @IsTest
    public static void changeCountry_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 3);

        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;

            // WHEN : the change country is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.items = 'Australia (+61)';
            portalTwoFactorController.changeCountry();
            Test.stopTest();
            // THEN:countrycode is 61
            Assert.areEqual(portalTwoFactorController.countryCode, '61');   
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal setting in the country and Mobile Phone
    *******************************************************************************/
    @IsTest
    public static void setCountryAndMobilePhoneCountry_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;

            // WHEN : the set country and Mobile phone is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.items = 'Australia (+61)';
            portalTwoFactorController.setCountryAndMobilePhoneCountry();
            Test.stopTest();
            // THEN:countryCode is 61
            Assert.areEqual(portalTwoFactorController.countryCode, '61');   
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal user getting the list of all the country names with country code
    *******************************************************************************/
    @IsTest
    public static void getItemsList_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // WHEN : the get Item list for countries is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            List<Selectoption> allOptions = portalTwoFactorController.getItemsList();
            Test.stopTest();
            // THEN:allOptions SIZE should be 0
            system.assertNotEquals(allOptions.size(), 0);
            
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal user verifying the 6 digit code
    *******************************************************************************/
    @IsTest
    public static void verifyVerificationCodeSuccess_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            ExperienceMFAServices.testVerificationResult = new Auth.VerificationResult(new PageReference('test'), true, 'Success');

            // WHEN : the verify verification code is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.verifyVerificationCode();
            Test.stopTest();
            // THEN:verificationCodeError is not empty
            Assert.areEqual(portalTwoFactorController.verificationCodeError, '');   
        }
    } 

    /*******************************************************************************
    * @author       Peter Sewell
    * @date         03.Aug.2023
    * @description  Tests portal user verifying the code via fallback service
    *******************************************************************************/
    @IsTest
    public static void verifyVerificationCodeSuccessFallback_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', true);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
                // GIVEN:setup test data
                ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
                ExperienceMFAServices.testVerificationResult = new Auth.VerificationResult(new PageReference('test'), true, 'Success');

                // WHEN : the verify verification code is initiated
                PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
                portalTwoFactorController.isResendVerificationCode = true;
                portalTwoFactorController.verifyVerificationCode();
            Test.stopTest();
            // THEN:verificationCodeError not null
            Assert.areEqual(portalTwoFactorController.verificationCodeError, '');   
        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal user verifying the 6 digit code
    *******************************************************************************/
    @IsTest
    public static void verifyVerificationCodeError_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
                // GIVEN:setup test data
                ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
                ExperienceMFAServices.testVerificationResult = new Auth.VerificationResult(new PageReference('test'), false, 'Error');

                // WHEN : the verify verification code is initiated
                PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
                portalTwoFactorController.verifyVerificationCode();
            Test.stopTest();
            // THEN:verificationCodeError is not blank
            Assert.areEqual(String.isBlank(portalTwoFactorController.verificationCodeError), false);   
        }
    } 

    /*******************************************************************************
    * @author       Peter Sewell
    * @date         24.Apr.2024
    * @description  Tests rate limiting of verification code entry
    *******************************************************************************/
    @IsTest
    public static void verifyVerificationCodeMaxFailure_test() {
        setupOtpSettings(false);
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
                // GIVEN:setup test data
                ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
                ExperienceMFAServices.testVerificationResult = new Auth.VerificationResult(new PageReference('test'), false, 'Error');

                // WHEN : the verify verification code is initiated multiple times
                PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
                portalTwoFactorController.failedAttempts = 0;
                PageReference pageRef;
                for (Integer i = 0; i <= (OTPGuard.OTP_CONFIG.otpAttemptAllowed+2); i++) {                
                    pageRef = portalTwoFactorController.verifyVerificationCode();
                }
            Test.stopTest();
            // THEN: should verifyCodeLimitExceeded error
            Assert.areEqual(portalTwoFactorController.verifyCodeLimitExceeded, true);   
        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal user sending the 6 digit code
    *******************************************************************************/
    @IsTest
    public static void sendVfSmsVerification_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // WHEN : the send SMS is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.sendVfSmsVerification();
            Test.stopTest();
            // THEN:verificationCodeError is null
            Assert.areEqual(portalTwoFactorController.verificationCodeError, '');   

        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal user sending the 6 digit code onto his registered email
    *******************************************************************************/
    @IsTest
    public static void sendVfEmailVerification_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // WHEN : the send EMail is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.sendVfEmailVerification();
            Test.stopTest();
            // THEN:verificationCodeError is not null
            Assert.areEqual(portalTwoFactorController.verificationCodeError, '');   
        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal user resetting his Country and Mobile details
    *******************************************************************************/
    @IsTest
    public static void resetCountryMobileNumber_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // WHEN : the reset Country and Mobile is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.resetCountryMobileNumber();
            Test.stopTest();
            portalUser = [SELECT Id, MobilePhone FROM User WHERE Email='testEmail925@gmail.com'];
            // THEN::MobilePhone is null
            Assert.areEqual(portalUser.MobilePhone, null);
        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal user resending the details through Email or Mobile
    *******************************************************************************/
    @IsTest
    public static void resendVerification_test() {
        setupOtpSettings(false);
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // WHEN : the resend Verification code is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            for (Integer i = 0; i <= (OTPGuard.OTP_CONFIG.otpAttemptAllowed+3); i++) {   
                portalTwoFactorController.mobileNumberFormatted = '0400000000';
                portalTwoFactorController.resendVerification();
            }
            Test.stopTest();
            // THEN:verificationCodeError is not null
            Assert.areNotEqual(portalTwoFactorController.verificationCodeError, '');   
        }
    } 


 /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal registering his new Mobile Number 
    *******************************************************************************/
    @IsTest
    public static void registerVfMobileNumber_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', false);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // WHEN : the register Mobile is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.countryCode = '+61';
            portalTwoFactorController.mobileNumber = '0400000000';
            portalTwoFactorController.mobilePhoneCountry = 'Australia';
            portalTwoFactorController.identifier ='provide a valid phone number';
            portalTwoFactorController.registerVfMobileNumber();
            Test.stopTest();
            // THEN:isResendRegistrationCode is false
            Assert.areEqual(portalTwoFactorController.isResendRegistrationCode, false);
        }
    } 

   /*******************************************************************************
    * @author       Peter Sewell
    * @date         27.Nov.2023
    * @description  Tests portal registering new Mobile Number 
    *               but where the number is in a country not suported by SFDC SMS
    *******************************************************************************/
    @IsTest
    public static void registerVfMobileNumberUnsuportedBySfdc_test() {
        
        // insert country data row flagged as unsupported by SFDC SMS service
        List<Country_Attribute__c> countryTestData = new List<Country_Attribute__c>();
        countryTestData.add(new Country_Attribute__c(Name = 'AUSTRALIA',
                                                     Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                     Country__c = 'Australia',
                                                     NumericPhoneCode__c = '61',
                                                     SFDC_SMS_Unsupported__c = true));
        insert countryTestData;
        
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', false);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // WHEN : the register Mobile is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.countryCode = '+61';
            portalTwoFactorController.mobileNumber = '0400000000';
            portalTwoFactorController.mobilePhoneCountry = 'Australia';
            portalTwoFactorController.registerVfMobileNumber(); // should use fallback (resend) service
            Test.stopTest();
            // THEN:isResendRegistrationCode is true
            Assert.areEqual(portalTwoFactorController.isResendRegistrationCode, true);
        }
    } 

    
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal registering his new Mobile Number 
    *******************************************************************************/
    @IsTest
    public static void registerVfMobileNumberMissingDetails_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            setupOtpSettings(false);
            PortalTwoFactorController portalTwoFactorController = null;
          
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            // WHEN : the resend register Mobile is initiated
            portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.mobileNumber = '0400000000';
            portalTwoFactorController.countryCode ='+61';
			portalTwoFactorController.mobilePhoneCountry ='0400000000';
            portalTwoFactorController.registerVfMobileNumber();
              
            Test.stopTest();
            // THEN:verificationCodeErrorLogoutMsg is blank
            Assert.areEqual(String.isBlank(portalTwoFactorController.verificationCodeErrorLogoutMsg), true);   
        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal user pressing the resend button on new registration 
    *******************************************************************************/
    @IsTest
    public static void resendVfRegisterMobileNumber_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('mobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        system.runAs(portalUser){
            setupOtpSettings(false);
             // set as if custom metdata is updated and util should work of this configuration
            PortalTwoFactorController portalTwoFactorController = null;
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            // WHEN : the resend register Mobile is initiated within allwoed attempts
            portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.mobileNumber = '0400000000';
            for (Integer i = 0; i <= OTPGuard.OTP_CONFIG.otpAttemptAllowed; i++) {
                portalTwoFactorController.resendVfRegisterMobileNumber();
              }
            
            Test.stopTest();
            // THEN:isResendRegistrationCode is True
            Assert.areEqual(portalTwoFactorController.isResendRegistrationCode, true);   
        }
    } 
      /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal user confirming the 6 digit code
    *******************************************************************************/
    @IsTest
    public static void confirmMobileNumberRegistration_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // WHEN : the confirm Mobile is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.isResendRegistrationCode = true;
            portalTwoFactorController.confirmMobileNumberRegistration();
            Test.stopTest();
            // THEN:No exceptionText
            Assert.areEqual(portalTwoFactorController.exceptionText, null);
        }
    }

    /*******************************************************************************
    * @author       Peter Sewell
    * @date         03.Aug.2023
    * @description  Tests portal user confirming the code via fallback service
    *******************************************************************************/
    @IsTest
    public static void confirmMobileNumberRegistrationFallback_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', true);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN -setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // WHEN : the confirm Mobile is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.confirmMobileNumberRegistration();
            Test.stopTest();
            // THEN:There is no exceptionText
            Assert.areEqual(portalTwoFactorController.exceptionText, null);
        }
    }

    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         24.Mar.2022
    * @description  Tests portal user confirming the 6 digit code - reconfirming wrong code after failing
    *******************************************************************************/
    @IsTest
    public static void confirmMobileNumberRegistrationReError_test() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // WHEN : the confirm Mobile is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.exceptionText = 'Verification error';
            portalTwoFactorController.confirmMobileNumberRegistration();
            Test.stopTest();
            // THEN: error hasnt changed
            Assert.areEqual(portalTwoFactorController.exceptionText, null);
        }
    }

    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         24.Mar.2022
    * @description  Tests non-bypassed check
    *******************************************************************************/
	@IsTest
    static void checkTwoFactorError_test() {
        // given : the Portal user is created 
        Integer firstResult = 0;
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email = 'testEmail925@gmail.com']; 
        portalUser[firstResult].Last_2FA_Login__c = System.NOW();
        update portalUser[firstResult];

        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('hasVerifiedMobileNumber', true);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 1);

        system.runAs(portalUser[0]){
            PageReference mfaPage = Page.Portal_TwoFactor;
            Test.setCurrentPage(mfaPage);
            Test.startTest();

            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            // WHEN : the two Factor check is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.extensionCountry = '';
            portalTwoFactorController.emailVerficationCount = null;
            portalTwoFactorController.hasVerifiedMobileNumber = true;
            portalTwoFactorController.failedAttempts = 1;
            PageReference pgRef = portalTwoFactorController.checkTwoFactor();
            Test.stopTest();
            // THEN: current user should stay on the same page
            Assert.areEqual(pgRef, null);
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal user verifying the 6 digit code
    *******************************************************************************/
    @IsTest
    public static void verifyVerificationCodeErrorMultiple_test() {
       setupOtpSettings(false);
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        System.runAs(portalUser){
            PageReference mfaPage = Page.Portal_TwoFactor;
            Test.setCurrentPage(mfaPage);
            Test.startTest();
            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            ExperienceMFAServices.testVerificationResult = new Auth.VerificationResult(new PageReference('test'), false, 'Error');
            PageReference pageRef = null;
            // WHEN : the verify verification code is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            for (Integer i = 0; i <= OTPGuard.OTP_CONFIG.otpAttemptAllowed; i++) {
                pageRef = portalTwoFactorController.verifyVerificationCode();
            }
            Test.stopTest();
            // THEN: current user should stay on the same page
            Assert.areEqual(pageRef, null);
        }
    } 

    /*
    * @author       Kristian Vegerano
    * @date         28.Apr.2022
    * @description  Tests unsupported country mobile number / handles unsupported invalid mobile number
    */
	@isTest
    static void unsupportedregisterVfMobileNumber_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            Test.startTest();
            // WHEN : the two Factor check is initiated - exception should fire
            PortalTwoFactorController controller = new PortalTwoFactorController();
            controller.countryCode = 'asd';
            controller.mobileNumber = '1234567890';
            controller.mobilePhoneCountry = 'East Timor';
            controller.registerVfMobileNumber();
            Test.stopTest();
        }
        // THEN changes should be reverted - mobile number should remain as is
        Integer firstItem = 0;
        Assert.areEqual('+61 0401234567', [SELECT Id, email, username, MobilePhone FROM User WHERE Email='testEmail925@gmail.com'][firstItem].MobilePhone);
    }

    /*
     * @author       Kristian Vegerano
     * @date         19.May.2022
     * @description  Tests parameter initiated unsupported country mobile number error
     */
	@IsTest
    static void constructorUnsupportedCountry_test() {
        // given : the Portal user is created
        Integer firstResult = 0;
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email = 'testEmail925@gmail.com']; 
        portalUser[firstResult].Last_2FA_Login__c = System.NOW();
        update portalUser[firstResult];

        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);

        System.runAs(portalUser[0]){
            PageReference mfaPage = Page.Portal_TwoFactor;
            mfaPage.getParameters().put('bypass', 'ic');
            Test.setCurrentPage(mfaPage);

            // WHEN the user navigates to the mfa page with parameters to force the unsupported country error
            Test.startTest();
                // GIVEN:setup test data
                ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
                // WHEN constructor runs
                PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            Test.stopTest();

            // THEN: the controller should have the invalid country error flags fired
            Assert.areEqual(true, portalTwoFactorController.invalidCountry);
            Assert.areEqual(true, portalTwoFactorController.hasRequestedNewMobile);
        }
    }

    /*
     * @author       Kristian Vegerano
     * @date         19.May.2022
     * @description  Tests parameter initiated unsupported range mobile number error
     */
	@IsTest
    static void constructortUnsupportedRange_test() {
        // given : the Portal user is created
        Integer firstResult = 0;
        List<User> portalUser = new List<User>([SELECT Id, email, username FROM User WHERE Email = 'testEmail925@gmail.com']); 
        portalUser[firstResult].Last_2FA_Login__c = System.NOW();
        update portalUser[firstResult];

        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);

        // WHEN the user navigates to the mfa page with parameters to force the unsupported country error
        System.runAs(portalUser[0]){
            PageReference mfaPage = Page.Portal_TwoFactor;
            mfaPage.getParameters().put('bypass', 'imnr');
            Test.setCurrentPage(mfaPage);

            Test.startTest();
                // GIVEN:setup test data
                ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
                // WHEN constructor runs
                PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            Test.stopTest();

            // THEN: the controller should have the invalid country error flags fired
            Assert.areEqual(true, portalTwoFactorController.invalidMobileNumberRange);
            Assert.areEqual(true, portalTwoFactorController.hasRequestedNewMobile);
        }
    }

    /*
     * @author       Ken McGuire
     * @date         3.Aug.2022
     * @description  Tests construction of country list
     */
	@IsTest
    // Given (includes duplicate record)
    static void testConstructCountryList() {
     	List<Country_Attribute__c> countryTestData = new List<Country_Attribute__c>();
        countryTestData.add(new Country_Attribute__c(Name = 'AUSTRALIA',
                                                     ShortName__c = 'Australia',
                                                     Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                     NumericPhoneCode__c = '61',
                                                     Blocked__c = false, 
                                                     Country__c = 'Australia'));
        countryTestData.add(new Country_Attribute__c(Name = 'ENGLAND',
                                                     ShortName__c = 'United Kingdom',
                                                     Callista_Code__c = '2102',
                                                     NumericPhoneCode__c = '42',
                                                     Blocked__c = false, 
                                                     Country__c = 'United Kingdom'));
        countryTestData.add(new Country_Attribute__c(Name = 'UK',
                                                     ShortName__c = 'United Kingdom',
                                                     NumericPhoneCode__c = '42',
                                                     Callista_Code__c = '2103',
                                                     Blocked__c = false, 
                                                     Country__c = 'United Kingdom'));
        insert countryTestData;  
        // When 
        List<SelectOption> countryList = new PortalTwoFactorController().getItemsList();
        // Then
        Assert.areEqual(3, countryList.size(),'Duplicate value should not appear in list');
    }

     /*******************************************************************************
    * @author       Shalini Mendu
    * @date         25.MAR.2025
    * @description  Tests Registration failure due to OTP limits exceeded 
    *******************************************************************************/
    @IsTest 
    public static void registerVfMobileNumberDoesNotThrowException() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            Test.startTest();
        
            setupOtpSettings(false);
            PortalTwoFactorController portalTwoFactorController = null;
          
            // setup Test data
            ExperienceMFAServices.TestCurrentUserDetails = currentUserDetails;
            // WHEN : the resend register Mobile is initiated within allowed attempts
            portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.mobileNumber = '0400000000';
            portalTwoFactorController.countryCode ='+61';
			portalTwoFactorController.mobilePhoneCountry ='0400000000';
            portalTwoFactorController.identifier = 'provide a valid country code';
            portalTwoFactorController.verificationMethod = 'SMS';

            for (Integer i = 0; i <= OTPGuard.OTP_CONFIG.otpAttemptAllowed; i++){
                portalTwoFactorController.registerVfMobileNumber();
              }
         
            Test.stopTest();
            // THEN: verificationCodeErrorLogoutMsg must be true
            Assert.areEqual(String.isBlank(portalTwoFactorController.verificationCodeErrorLogoutMsg), true);   
        }
    } 

      /*******************************************************************************
    * @author       Shalini Mendu
    * @date         25.MAR.2025
    * @description  Tests Registration failure due to OTP limits exceeded 
    *******************************************************************************/
    @IsTest
    public static void resendVfRegisterMobileNumberThrowException() {
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        setupOtpSettings(false);
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
     
        system.runAs(portalUser){
            Test.startTest();
        
            PortalTwoFactorController portalTwoFactorController = null;
          
            // setup Test data
            ExperienceMFAServices.TestCurrentUserDetails = currentUserDetails;
            portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.mobileNumber = '0400000000';
            portalTwoFactorController.countryCode ='+61';
			portalTwoFactorController.mobilePhoneCountry ='0400000000';
            portalTwoFactorController.verificationMethod = 'SMS';
            // WHEN : the resend register is called more than the allowed times
            for(Integer i=0;i<=10;i++)
            {
                portalTwoFactorController.resendVfRegisterMobileNumber();
            }
           
            Test.stopTest();
            // THEN:failedAttemptsLimitExceeded must be true
            Assert.areEqual(portalTwoFactorController.failedAttemptsLimitExceeded , true);   
            }
        }
    
    /*******************************************************************************
    * @author       Vishal Gupta
    * @date         15.Apr.2025
    * @description  Tests portal registering new Mobile Number 
    *               but where the country is santioned then it redirects to Email verification
    *******************************************************************************/
    @IsTest
    public static void registerVfSanctionedMobileNumber_test() {
        
        // insert country data row flagged as unsupported by SFDC SMS service
        List<Country_Attribute__c> countryTestData = new List<Country_Attribute__c>();
        countryTestData.add(new Country_Attribute__c(Name = 'AUSTRALIA',
                                                     Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                     Country__c = 'Australia',
                                                     NumericPhoneCode__c = '61',
                                                     Sanctioned_by_Salesforce__c = true));
        insert countryTestData;
        
        // given : the Portal user is created 
        User portalUser = [SELECT Id FROM User WHERE Email='testEmail925@gmail.com'];
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', false);
        currentUserDetails.put('HasExternalVerification', false);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);
        
        system.runAs(portalUser){
            test.startTest();
            // setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            
            // when : the register Mobile is initiated
            PortalTwoFactorController o_PortalTwoFactorController = new PortalTwoFactorController();
            o_PortalTwoFactorController.countryCode = '+61';
            o_PortalTwoFactorController.mobileNumber = '0400000000';
            o_PortalTwoFactorController.mobilePhoneCountry = 'Australia';
            o_PortalTwoFactorController.registerVfMobileNumber(); 
            test.stopTest();
            // then:
            Assert.areEqual(o_PortalTwoFactorController.isSantionedCountry, true);
        }
    }
    
    /*******************************************************************************
    * @author       Ibrahim Rumi
    * @date         27.AUG.2025
    * @description  Tests if the country is sanctioned for my app
    *******************************************************************************/
    @isTest
    public static void isCountrySancationedForMyApp_test(){
        Boolean isSanctionedCountry = new PortalTwoFactorController().isCountrySancationedForMyApp();
        Assert.areEqual(isSanctionedCountry, false);
    }
    
    /*******************************************************************************
    * @author       Ibrahim Rumi
    * @date         27.AUG.2025
    * @description  Tests handling verified mobile number
    *******************************************************************************/
    @isTest
    public static void sendSanctionedCountryMFA_Test(){
        
        PortalTwoFactorController o_PortalTwoFactorController = new PortalTwoFactorController();
        o_PortalTwoFactorController.sendSanctionedCountryMFA();
        
        Assert.areEqual(o_PortalTwoFactorController.verificationMethod, 'Email');
    }
    
    /*******************************************************************************
    * @author       Ibrahim Rumi
    * @date         27.AUG.2025
    * @description  Tests handling two factor exception
    *******************************************************************************/
    @isTest
    public static void handleCheckTwoFactorException_test(){
        
        PortalTwoFactorController o_PortalTwoFactorController = new PortalTwoFactorController();
        OTPGuard.OTPAttemptException except = new OTPGuard.OTPAttemptException();
        o_PortalTwoFactorController.handleCheckTwoFactorException(except);
        
        Assert.areEqual(o_PortalTwoFactorController.failedAttemptsLimitExceeded, true);
    }
    
    /*******************************************************************************
    * @author       Ibrahim Rumi
    * @date         27.AUG.2025
    * @description  Tests handling verified mobile number
    *******************************************************************************/
    @isTest
    public static void handleVerifiedMobileNumber_test(){
        
        
        // given : the Portal user is created 
        Integer firstResult = 0;
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email = 'testEmail925@gmail.com']; 
        portalUser[firstResult].Last_2FA_Login__c = System.NOW();
        update portalUser[firstResult];

        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('hasVerifiedMobileNumber', true);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('FailedAttempts', 1);

        system.runAs(portalUser[0]){
            PageReference mfaPage = Page.Portal_TwoFactor;
            Test.setCurrentPage(mfaPage);
            Test.startTest();

            // GIVEN:setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            // WHEN : the two Factor check is initiated
            PortalTwoFactorController portalTwoFactorController = new PortalTwoFactorController();
            portalTwoFactorController.handleVerifiedMobileNumber();
            Test.stopTest();
            
            Assert.areEqual(String.isBlank(portalTwoFactorController.verificationCodeErrorLogoutMsg), true);
    	}
    }
    
    
}