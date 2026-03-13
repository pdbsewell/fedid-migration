/**
 * @author Inderpal Dhanoa, Engage Enterprise
 * @date 2/23/22
 * @group Engage Enterprise
 * @description Test Class for ExperienceMFAServices
 * Revision  2022-08-22   Ken McGuire			Replace country static resource with table. 
 *           2023-07-23   Peter Sewell          Support external SMS verification service for MFA
 *           2024-05-24   Peter Sewell          Test mobile number returned by Twilio 
 */
@isTest//(isParallel=true) In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
public class ExperienceMFAServices_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Test setup
    *******************************************************************************/
    @TestSetup
    static void setupData(){
        
        // insert experience mfa custom setting
        ExperienceMFASetting__c	mfaSetting = new ExperienceMFASetting__c();
        mfaSetting.Autotest_Bypass_Key__c = 'bypasskeyword';
        insert mfaSetting;
		
		// insert country codes
        Country_Attribute__c testCont = (Country_Attribute__c)TestDataFactory.createSObject(new Country_Attribute__c(ShortName__c='test Country' , Blocked__c=false, NumericPhoneCode__c='11'), true);

        User LoggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

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
            user.Alias = 'test';
            user.MobilePhone = '+61 401234567';
            user.Mobile_Phone_Country__c = 'Australia';
            user.CommunityNickname = 'Test1';
            user.TimeZoneSidKey = 'America/New_York';
            user.LocaleSidKey = 'en_US';
            user.MFA_Email_Verification_Count__c = 1;
            user.EmailEncodingKey = 'UTF-8';
            user.Email = 'testEmail925@gmail.com';
            user.Username = 'testEmail925@gmail.com';
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
	

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User conditional MFA check or bypass the check
    *******************************************************************************/
	@IsTest
    static void determineByPassTwoFactor_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();

            // when : the two Factor check is initiated
            Boolean byPass = ExperienceMFAServices.determineByPassTwoFactor(portalUser[0].Id);
            test.stopTest();
            // then: 
        }
    }
    

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User Mobile to be registered
    *******************************************************************************/
	@IsTest
    static void systemRegisterMobileNumber_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated
            String code = ExperienceMFAServices.systemRegisterMobileNumber('61', '0412345678', 'Australia');
            test.stopTest();
            // then: 
            Assert.areEqual(code, '');
        }
    } 

    /*******************************************************************************
    * @author       Peter Sewell
    * @date         28.Nov.2023
    * @description  Tests whether country is supported by SFDC SMS service  
    *******************************************************************************/
	@IsTest
    static void mobileNumberCountryNotSupportedBySfdc_test() {
        // insert country data row flagged as unsupported by SFDC SMS service
        List<Country_Attribute__c> countryTestData = new List<Country_Attribute__c>();
        countryTestData.add(new Country_Attribute__c(Name = 'AUSTRALIA',
                                                     Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                     Country__c = 'Australia',
                                                     NumericPhoneCode__c = '61',
                                                     SFDC_SMS_Unsupported__c = true));
        insert countryTestData;

        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
                Assert.areEqual(ExperienceMFAServices.isSfdcSmsSupported('61'), false);          
                Assert.areEqual(ExperienceMFAServices.isSfdcSmsSupported('+61'), false);            
            test.stopTest();
            // then: 
        }
    } 

    /***********************************************************************************
    * @author       Peter Sewell
    * @date         04.Jul.2023
    * @description  Tests portal logging in User Mobile to be registered with resent code
    ************************************************************************************/
	@IsTest
    static void systemRegisterMobileNumberResentCode_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated
            String code = ExperienceMFAServices.systemRegisterMobileNumberFallback('61', '0412345678', 'Australia');
            test.stopTest();
            // then: 
            Assert.areEqual(String.isBlank(code), false);
            portalUser = [SELECT Id, email, username, mobilePhone FROM User WHERE Email='testEmail925@gmail.com']; 
            Assert.areEqual(portalUser[0].mobilePhone, '+61412345678');

        }
    } 

    /***********************************************************************************
    * @author       Peter Sewell
    * @date         04.Jul.2023
    * @description  Tests setVerifiedByExternalService
    ************************************************************************************/
	@IsTest
    static void setVerifiedByExternalService_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
                ExperienceMFAServices.setVerifiedByExternalService();
            test.stopTest();
        }
        // then: 
        portalUser = [SELECT Id, email, username, MFA_Mobile_Verified_External__c FROM User WHERE Email='testEmail925@gmail.com']; 
        Assert.areEqual(true, portalUser[0].MFA_Mobile_Verified_External__c, 'External verification flag not set on user record');
    } 

    /***********************************************************************************
    * @author       Peter Sewell
    * @date         04.Jul.2023
    * @description  Tests otpWrapper
    ************************************************************************************/
	@IsTest
    static void otpWrapper_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        OneTimeTokenService.OneTimeTokenWrapper otpWrapper;
        system.runAs(portalUser[0]){
            test.startTest();
                otpWrapper = ExperienceMFAServices.otpWrapper(
                    'Code', 'VerificationSid' + ExperienceMFAServices.MFA_OTP_SEPARATOR + 'ServiceSid'
                );
            test.stopTest();
        }
        // then: 
        Assert.areEqual(otpWrapper.Code, 'Code', 'OTP code not set correctly');
        Assert.areEqual(otpWrapper.VerificationSid, 'VerificationSid', 'OTP VerificationSid not set correctly');
        Assert.areEqual(otpWrapper.ServiceSid, 'ServiceSid', 'OTP ServiceSid not set correctly');
    } 
	
	/*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         06.Apr.2022
    * @description  Tests portal logging in User Mobile to be registered
    *******************************************************************************/
	@IsTest
    static void syncMobileDetails_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, contactId, mobilePhone FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
            // when : A new Mobile Number is verified
            ExperienceMFAServices.syncMobileDetails();
            test.stopTest();
            // then: The Mobile Object is synced with the details
            Set<String> keySet = PhoneServices.buildPhoneKeySet(portalUser[0].ContactId, 'Mobile', portalUser[0].MobilePhone);
            String keyId = Person360Helper.generatePerson360Key(keySet);
            List<Phone__c> upsertResults = [SELECT Name, Verification_Status__c FROM Phone__c WHERE Key_UID__c = :keyId];
            Assert.areEqual(upsertResults[0].Name.replaceAll('[^0-9]',''), portalUser[0].MobilePhone.replaceAll('[^0-9]',''), 
             String.format('Failed Sync Mobile Number: Contact Point:{0} - Portal: {1}',new List<String>{
                upsertResults[0].Name,
                portalUser[0].MobilePhone
             }));
            Assert.areEqual('Verified by MFA', upsertResults.get(0).Verification_Status__c, 'Incorrect verification status');
            
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User's details check
    *******************************************************************************/
	@IsTest
    static void retrieveCurrentUserDetails_test() {
        // given : the Portal user is created 
        Integer firstResult = 0;
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        portalUser[firstResult].MFA_Email_Verification_Count__c = null;
        update portalUser;
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated
            Map<String, Object> resultsMap = ExperienceMFAServices.retrieveCurrentUserDetails();
            test.stopTest();
            // then: 
            Assert.areEqual(resultsMap, null);
        }
    }

    /*******************************************************************************
    * @author       Peter Sewell
    * @date         04.Jul.2023
    * @description  Tests portal logging in User's details check for user with  
    *               mobile verified by external service e.g. Twilio
    *******************************************************************************/
	@IsTest
    static void retrieveCurrentUserDetailsExternalSMSUser_test() {
        // given : the Portal user is created 
        Integer firstResult = 0;
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        portalUser[firstResult].MFA_Email_Verification_Count__c = null;
        portalUser[firstResult].MFA_Mobile_Verified_External__c = true;
        update portalUser;
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated
            Map<String, Object> resultsMap = ExperienceMFAServices.retrieveCurrentUserDetails();
            test.stopTest();
            // then: 
            Assert.areEqual(resultsMap, null);
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User verification code check by SMS
    *******************************************************************************/
	@IsTest
    static void verifyMobileNumber_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated
            String verifyMobileNumberRes = ExperienceMFAServices.verifyMobileNumber('temp','123456','https://www.test.com');
            test.stopTest();
            // then: 
            Assert.areNotEqual(verifyMobileNumberRes, 'exception');
        }
    }

    /*******************************************************************************
    * @author       Peter Sewell
    * @date         07.Aug.2023
    * @description  Tests portal logging in User verification code check by 
    *               SMS fallback service
    *******************************************************************************/
	@IsTest
    static void verifyMobileNumberFallback_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated
            String verifyMobileNumberRes = ExperienceMFAServices.verifyMobileNumberFallback('temp','123456','https://www.test.com');
            test.stopTest();
            // then: 
            Assert.areNotEqual(verifyMobileNumberRes, 'exception');
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User send code by SMS
    *******************************************************************************/
	@IsTest
    static void sendSmsVerification_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated
            Map<String, Object> sendSMS = ExperienceMFAServices.sendSmsVerification();
            test.stopTest();
            // then: 
            Assert.areNotEqual(sendSMS.get('Status'), 'success');
        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User verification code check by Email
    *******************************************************************************/
	@IsTest
    static void sendEmailVerification_test() { 
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated
            Map<String, Object> sendEmail = ExperienceMFAServices.sendEmailVerification();
            test.stopTest();
            // then: 
            Assert.areNotEqual(sendEmail.get('Status'), 'success');
        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User conditional MFA check or bypass the check
    *******************************************************************************/
	@IsTest
    static void sendEmailVerification_testEmail() { 
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);

        system.runAs(portalUser[0]){
            test.startTest();
            // setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            ExperienceMFAServices.testVerificationResult = new Auth.VerificationResult(new PageReference('test'), true, 'Success');

            // when : the two Factor check is initiated
            Map<String, Object> verifcnres = ExperienceMFAServices.verifyVerificationCode('identifier', '123456', 'Email');
            test.stopTest();
            // then: 
            Assert.areEqual(verifcnres.get('Status'), 'success');
        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User conditional MFA check or bypass the check
    *******************************************************************************/
	@IsTest
    static void sendEmailVerification_testEmailError() { 
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 

        system.runAs(portalUser[0]){
            test.startTest();
            
            // when : the two Factor check is initiated
            Map<String, Object> verifcnres = ExperienceMFAServices.verifyVerificationCode('identifier', '123456', 'Email');
            test.stopTest();
            // then: 
            Assert.areNotEqual(verifcnres.get('Status'), 'success');
        }
    } 

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User verification code check by SMS
    *******************************************************************************/
	@IsTest
    static void sendEmailVerification_testSMS() { 
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        
        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('HasRequestedPasswordReset', false);
        currentUserDetails.put('MobileNumberCountry', 'Australia');
        currentUserDetails.put('MobileNumber', '+61 0400000000');
        currentUserDetails.put('EmailVerificationCount', 1);
        currentUserDetails.put('HasRequestedPasswordReset', true);
        currentUserDetails.put('FailedAttempts', 0);

        system.runAs(portalUser[0]){
            test.startTest();
            // setup test data
            ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
            ExperienceMFAServices.testVerificationResult = new Auth.VerificationResult(new PageReference('test'), true, 'Success');

            // when : the two Factor check is initiated
            Map<String, Object> verifcnres = ExperienceMFAServices.verifyVerificationCode('identifier', '123456', 'SMS');
            test.stopTest();
            // then:
            Assert.areEqual(verifcnres.get('Status'), 'success');
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests portal logging in User verification code check by SMS
    *******************************************************************************/
	@IsTest
    static void sendEmailVerification_testSMSError() { 
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated
            Map<String, Object> verifcnres = ExperienceMFAServices.verifyVerificationCode('identifier', '123456', 'SMS');
            test.stopTest();
            // then: 
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         23.Feb.2022
    * @description  Tests internal class retrieve current user details
    *******************************************************************************/
	@IsTest
    static void internalRetrieveCurrentUserDetails_test() { 
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated
            Map<String, Object> verifcnres = new ExperienceMFAServices.CommitQueryRecords().retrieveCurrentUserDetails(portalUser[0].Id);
            test.stopTest();
            // then: 
        }
    }

    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         24.Mar.2022
    * @description  Tests portal logging in for autotest user trying to bypass the mfa check
    *******************************************************************************/
	@IsTest
    static void determineByPassTwoFactorAutoTestBypass_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){

            // set page
            PageReference mfaPage = Page.Portal_TwoFactor;
            Test.setCurrentPage(mfaPage);
            // put the lead id as a parameter
            ApexPages.currentPage().getParameters().put('ByPass', 'bypasskeyword');

            Test.startTest();

            // when : the two Factor check is initiated
            Boolean byPass = ExperienceMFAServices.determineByPassTwoFactor(portalUser[0].Id);
            Test.stopTest();
            // then: 
            Assert.areEqual(true, byPass);
        }
    }

    /*
    * @author       Kristian Vegerano
    * @date         28.Apr.2022
    * @description  Tests unsupported country mobile number / handles unsupported invalid mobile number
    */
	@isTest
    static void unsupportedSystemRegisterMobileNumber_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, username FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
            // when : the two Factor check is initiated - exception should fire
            ExperienceMFAServices.systemRegisterMobileNumber('asd', '1234567890', 'East Timor');
            test.stopTest();
        }
        // then changes should be reverted
        Integer firstItem = 0;
        Assert.areEqual('+61 401234567', [SELECT Id, email, username, MobilePhone FROM User WHERE Email='testEmail925@gmail.com'][firstItem].MobilePhone);
    } 
    
        /*
    * @author       Kristian Vegerano
    * @date         28.Apr.2022
    * @description  Tests unsupported country mobile number / handles unsupported invalid mobile number
    */
	@isTest
    static void test_Error_Paths() {
        
     Map<String, Object> verificationResult = ExperienceMFAServices.verifyVerificationCode('safeString', 'safeString', '<script>unsafe string</script>');
     System.assertEquals(ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT, verificationResult.get('message'));
        
    } 

    /*******************************************************************************
    * @author       Vishal Gupta
    * @date         14.Apr.2025
    * @description  Tests syncing portal user's mobile number with contact record
    *******************************************************************************/
	@IsTest
    static void syncUnverifiedMobileDetails_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, contactId, mobilePhone FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
            // when : A new Mobile Number is verified
            ExperienceMFAServices.syncUnverifiedMobileDetails(portalUser[0].contactId, portalUser[0].mobilePhone);
            test.stopTest();
            // then: The Mobile Object is synced with the details
            Set<String> keySet = PhoneServices.buildPhoneKeySet(portalUser[0].ContactId, 'Mobile', portalUser[0].MobilePhone);
            String keyId = Person360Helper.generatePerson360Key(keySet);
            List<Phone__c> upsertResults = [SELECT Name, Verification_Status__c FROM Phone__c WHERE Key_UID__c = :keyId];
            Assert.areEqual(upsertResults[0].Name.replaceAll('[^0-9]',''), portalUser[0].MobilePhone.replaceAll('[^0-9]',''), 
             String.format('Failed Sync Mobile Number: Contact Point:{0} - Portal: {1}',new List<String>{
                upsertResults[0].Name,
                portalUser[0].MobilePhone
             }));
        }
    }

    /*******************************************************************************
    * @author       Vishal Gupta
    * @date         14.Apr.2025
    * @description  Tests syncing portal user's mobile number with contact record - error
    *******************************************************************************/
	@IsTest
    static void syncUnverifiedMobileDetailsError_test() {
        // given : the Portal user is created 
        List<User> portalUser = [SELECT Id, email, contactId, mobilePhone FROM User WHERE Email='testEmail925@gmail.com']; 
        system.runAs(portalUser[0]){
            test.startTest();
            // when : A new Mobile Number is verified
            ExperienceMFAServices.syncUnverifiedMobileDetails(null, null);
            test.stopTest();
            // then: The Mobile Object is synced with the details
            Set<String> keySet = PhoneServices.buildPhoneKeySet(null, 'Mobile', null);
            String keyId = Person360Helper.generatePerson360Key(keySet);
            List<Phone__c> upsertResults = [SELECT Name, Verification_Status__c FROM Phone__c WHERE Key_UID__c = :keyId];
            Assert.areEqual(upsertResults.isEmpty(), true, 'No phone number added');
        }
    }
}