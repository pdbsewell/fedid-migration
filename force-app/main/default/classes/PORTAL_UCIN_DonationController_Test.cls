/*
 * @author Charlie Park, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for donation controller
 * @Revsion steffi change isParallel=false Error - In parallel Apex tests, DML operations aren't permitted on this type of object: User https://trailblazer.salesforce.com/ideaView?id=0873A000000lGvtQAE*
 * 2020-10-15   Ken McGuire   	Modified tests after moving processing methods off of client and onto server
 * 2025-07-16   Matthew Maramot Ascend Package Upgrade 5.48.7 (EPCP-4869)
 * note: make keys used in Map<String, Object> params have the correct case
*/


@isTest(isParallel=false) // In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
public class PORTAL_UCIN_DonationController_Test {
    // Setup for community user
    @TestSetup
    static void makeData(){
       //creating unique username 
        String orgId = UserInfo.getOrganizationId();
    	String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
		Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
    	String uniqueName = orgId + dateString + randomInt;       

        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
		Profile profile1 = [Select Id from Profile where name = 'System Administrator'];

        //insert a user..
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,           
            Username = uniqueName + '@test' + orgId + '.org',   
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
            if(profiles.size() > 0)
            {
                user.ProfileID = profiles[0].Id;       		
                user.ContactId = contact.Id;
                insert user;
            }     
        }
    }
	@IsTest
    public static void test_createNewOnlineDonation()
    {
        test.startTest();
        Map<String, Object> params = new Map<String, Object>();
        
        String isAnonymousUser = 'isAnonymousUser';
        Boolean anon = true;
        params.put(isAnonymousUser, anon);
        
        // GIVEN: credit card used for donation
        params.put('creditCardNumber', '1234 1234 1234 1234');
        params.put('creditCardType', 'VISA');
        //for credit card expiration date, must make sure the card is not expired (having trouble converting date to string)
        params.put('creditCardExpirationDate', '2199-09-24');
        params.put('paymentChargeId', '123456789');
        
        // GIVEN: spouse of donor making the donation
        //contact
        Contact spouse = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert spouse;
        
        // GIVEN: donor making the donation
        Contact contact = new Contact(LastName = 'LastName2', FirstName = 'FirstName2', ucinn_ascendv2__Preferred_Spouse__c = spouse.Id);
        params.put('constituentRec', contact);
        insert contact;
        
        //account
        Account account = new Account(Name = 'TestName925');
        insert account;
        params.put('organizationRec', account);
        
        //Opportunity
        Opportunity opp = new Opportunity();
		opp.AccountId = account.Id;      
        opp.Name = 'Test Opp'; //Name
        opp.StageName = 'Active'; //StageName
        opp.CloseDate = System.today() + 30; //Close Date
        Opp.Amount = 300;
        params.put('giftRec', opp);
        
        //Designation detail list
        List<ucinn_ascendv2__Designation_Detail__c> desigDetailList = new List<ucinn_ascendv2__Designation_Detail__c>();
        ucinn_ascendv2__Designation_Detail__c desigDetail = new ucinn_ascendv2__Designation_Detail__c();
        desigDetail.ucinn_ascendv2__Amount__c = 300;
        desigDetail.ucinn_ascendv2__Contact__c = contact.Id;

		desigDetailList.add(desigDetail);
		params.put('designationDetailRecList', desigDetailList);
        params.put('externalPaymentGatewayId', 'PRAX-TEST-1234455643');
        
        params.put('contact_firstname', 'test first name');

        PORTAL_UCIN_Domain_Name__c newDomainName = new PORTAL_UCIN_Domain_Name__c();
        newDomainName.Domain_Name__c = 'test';
        newDomainName.Name = 'test';
        insert newDomainName;
        
        // WHEN: donation is created
        PORTAL_UCIN_DonationController.createNewOnlineDonation(params);        
        List<ucinn_ascendv2__Review_Transaction_v2__c> createdTransactions = [SELECT ID, ucinn_ascendv2__Payment_Amount_1_1__c,ucinn_ascendv2__Interim__c FROM ucinn_ascendv2__Review_Transaction_v2__c];
        
        // create and link interim
        PORTAL_UCIN_GiftCreation giftCreation = new PORTAL_UCIN_GiftCreation();
        createdTransactions[0].ucinn_ascendv2__Interim__c = giftCreation.createInterim(params);
        update createdTransactions[0];

        // code coverage
        params.put('amountToPayToday','200');
        PORTAL_UCIN_DonationController.constructOpportunityRecord(params);
		PORTAL_UCIN_DonationController.getErrorCodeMessage('202');
        PORTAL_UCIN_DonationController.fauxPaymentCallout(createdTransactions[0].id);


        String receiptURL = Portal_UCIN_Utils.getReviewTransactionReceiptURL(createdTransactions[0].Id);            
        PORTAL_UCIN_DonationController.createGiftReceipt(createdTransactions[0].Id, '', 'test@test.com', receiptURL, null);

        PORTAL_UCIN_DonationController.getTransaction(createdTransactions[0].id);
        test.stopTest();

        // THEN: verify the donation amount
        // Make sure gift/transactions are created with correct amounts
        Assert.areNotEqual(createdTransactions.size(), 0);
        Assert.isTrue(createdTransactions[0].ucinn_ascendv2__Payment_Amount_1_1__c == 300);
    }

    @IsTest
    public static void test_createNewOnlineDonation2()
    {
        test.startTest();
        Map<String, Object> params = new Map<String, Object>();
        
        String isAnonymousUser = 'isAnonymousUser';
        Boolean anon = true;
        params.put(isAnonymousUser, anon);
        
        // GIVEN: credit card used for donation
        params.put('creditCardNumber', '1234 1234 1234 1234');
        params.put('creditCardType', 'VISA');
        //for credit card expiration date, must make sure the card is not expired (having trouble converting date to string)
        params.put('creditCardExpirationDate', '2199-09-24');
        params.put('paymentChargeId', '123456789');
        
        // GIVEN: spouse of donor making the donation
        //contact
        Contact spouse = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert spouse;
        
        // GIVEN: donor making the donation
        Contact contact = new Contact(LastName = 'LastName2', FirstName = 'FirstName2', ucinn_ascendv2__Preferred_Spouse__c = spouse.Id);
        params.put('constituentRec', contact);
        insert contact;
        
        //account
        Account account = new Account(Name = 'TestName925');
        insert account;
        params.put('organizationRec', account);
        
        //Opportunity
        Opportunity opp = new Opportunity();
		opp.AccountId = account.Id;      
        opp.Name = 'Test Opp'; //Name
        opp.StageName = 'Active'; //StageName
        opp.CloseDate = System.today() + 30; //Close Date
        Opp.Amount = 300;
        params.put('giftRec', opp);
        
        //Designation detail list
        List<ucinn_ascendv2__Designation_Detail__c> desigDetailList = new List<ucinn_ascendv2__Designation_Detail__c>();
        ucinn_ascendv2__Designation_Detail__c desigDetail = new ucinn_ascendv2__Designation_Detail__c();
        desigDetail.ucinn_ascendv2__Amount__c = 300;
        desigDetail.ucinn_ascendv2__Contact__c = contact.Id;

		desigDetailList.add(desigDetail);
		params.put('designationDetailRecList', desigDetailList);
        params.put('externalPaymentGatewayId', 'PRAX-TEST-1234455643');
        
        params.put('contact_firstname', 'test first name');

        PORTAL_UCIN_Domain_Name__c newDomainName = new PORTAL_UCIN_Domain_Name__c();
        newDomainName.Domain_Name__c = 'test';
        newDomainName.Name = 'test';
        insert newDomainName;
        
        // WHEN: donation is created
        PORTAL_UCIN_DonationController.createNewOnlineDonation(params);        
        List<ucinn_ascendv2__Review_Transaction_v2__c> createdTransactions = [SELECT ID, ucinn_ascendv2__Payment_Amount_1_1__c,ucinn_ascendv2__Interim__c FROM ucinn_ascendv2__Review_Transaction_v2__c];
        
        // create and link interim
        PORTAL_UCIN_GiftCreation giftCreation = new PORTAL_UCIN_GiftCreation();
        createdTransactions[0].ucinn_ascendv2__Interim__c = giftCreation.createInterim(params);
        createdTransactions[0].ucinn_ascendv2__Transaction_Type__c = 'Gift';
        update createdTransactions[0];

        // code coverage
        params.put('amountToPayToday','200');
        PORTAL_UCIN_DonationController.constructOpportunityRecord(params);
		PORTAL_UCIN_DonationController.getErrorCodeMessage('202');
        PORTAL_UCIN_DonationController.fauxPaymentCallout(createdTransactions[0].id);


        String receiptURL = Portal_UCIN_Utils.getReviewTransactionReceiptURL(createdTransactions[0].Id);            
        PORTAL_UCIN_DonationController.createGiftReceipt(createdTransactions[0].Id, '', 'test@test.com', receiptURL, null);

        PORTAL_UCIN_DonationController.getTransaction(createdTransactions[0].id);
        test.stopTest();

        // THEN: verify the donation amount
        // Make sure gift/transactions are created with correct amounts
        Assert.areNotEqual(createdTransactions.size(), 0);
        Assert.isTrue(createdTransactions[0].ucinn_ascendv2__Payment_Amount_1_1__c == 300);
    }
    
    @IsTest
    public static void test_getSelectableDesignations()
    {
        test.startTest();
        // GIVEN: active designations to query
        //designations
       	ucinn_ascendv2__Designation__c desig = new ucinn_ascendv2__Designation__c();
        desig.ucinn_ascendv2__Designation_Name__c = 'Test Designation';
        desig.Name = 'Test Name';
        //make designation active (formula)
        desig.ucinn_ascendv2__G_L_Effective_Date__c = System.today() -30;
        desig.ucinn_ascendv2__G_L_Expiration_Date__c = System.today() + 30;
        desig.ucinn_ascendv2__External_System_Id__c = '123';
        desig.ucinn_ascendv2__Program_Code__c = 'GL_Acc'; // 7 char
        desig.ucinn_ascendv2__G_L_Acknowledgement_Description__c = 'GL_Ack'; // 6 char
        desig.ucinn_ascendv2__G_L_Short_Description__c = 'GL_SD'; // 6 char
        desig.Tax_Status_Code__c = 'S1';
        insert desig;
        
        String designationIdsCommaSeparated = '123';        
        test.stopTest();

        // WHEN: query for active designations
        // THEN: verify active designation found
        // Only passing one id, should get one designation back
        Assert.areEqual(PORTAL_UCIN_DonationController.getSelectableDesignations(designationIdsCommaSeparated).size(), 1);
    }
    
    @IsTest
    public static void test_getCountriesAndStates()
    {
        // WHEN: get country picklist options from Address__c object
        // THEN: verify that there was at least 1 country cound
        List<PORTAL_UCIN_DonationController.SelectOptionDetail> countryList = PORTAL_UCIN_DonationController.getCountryOptions();
        Assert.areNotEqual(0, countryList.size());
    }
    
    @IsTest
    public static void test_getDonorByLoggedInUser()
    {
        test.startTest();
        // GIVEN: user with asscoicated contact and account records
        //must add contactId and accountId to current user to get more code coverage 
        Contact contact = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert contact;
        
        Account account = new Account(Name = 'TestName925');
        insert account;
        
        User portalUser = [SELECT ID FROM User WHERE username = 'testEmail925@gmail.com' LIMIT 1];
        Map<String, Object> result;

        // WHEN: get records associated with logged in user
        system.runAs(portalUser) {
            result = (Map<String, Object>)PORTAL_UCIN_DonationController.getDonorByLoggedInUser();
        }
        
        test.stopTest();

        // THEN: verify the logged in user's User record
        // Should grab the logged in user
        Assert.areEqual(((User)result.get('currentUser')).Id, portalUser.Id);
    }

    @IsTest
    public static void test_getDonorByLoggedInUserException()
    {
        Boolean exceptionEncountered = false;
        test.startTest();
        // GIVEN: user with asscoicated contact and account records
        //must add contactId and accountId to current user to get more code coverage 
        Contact contact = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert contact;
        
        Account account = new Account(Name = 'TestName925');
        insert account;
        
        User portalUser = [SELECT ID FROM User WHERE username = 'testEmail925@gmail.com' LIMIT 1];

        // WHEN: get records associated with logged in user
        system.runAs(portalUser) {
            try{
                PORTAL_UCIN_DonationController.throwExceptionForTesting = true;
                PORTAL_UCIN_DonationController.getDonorByLoggedInUser();
            }
            catch (Exception ex) {
                exceptionEncountered = true;
            }
        }
        test.stopTest();

        // THEN: error should have occurred
        Assert.areEqual(exceptionEncountered, true);
        
    }

    @IsTest
    public static void test_getSalutationsOptions()
    {
        // WHEN: get picklist values from Contact.Salutation_ERDA__c
        // THEN: validate that at least 1 value found
        test.startTest();
        List<PORTAL_UCIN_DonationController.SelectOptionDetail> salutationList = PORTAL_UCIN_DonationController.getSalutationsOptions();
        test.stopTest();

        Assert.isTrue(salutationList.size() > 0);
    }

    @IsTest
    public static void test_getErrorMessages()
    {
        // WHEN: get error messages from PORTAL_UCIN_Donation_Error__mdt
        test.startTest();
        Map<String, String> errorMessageMap = PORTAL_UCIN_DonationController.getErrorMessages();
        test.stopTest();

        // THEN: verify that error message from 'Default Error' record is not blank
        Assert.isTrue(errorMessageMap.size() > 0);
        Assert.areNotEqual(null, errorMessageMap.get('Default Error'));
    }

    @IsTest
    public static void test_SERVER_Callout_Cybersource_Failure()
    {
        Map<String, Object> params = new Map<String, Object>();
        
        String isAnonymousUser = 'isAnonymousUser';
        Boolean anon = true;
        params.put(isAnonymousUser, anon);

        // GIVEN: credit card used for donation
        params.put('creditCardNumber', '1234123412341234');
        params.put('creditCardType', 'VISA');
        params.put('creditCardExpirationDate', '1123');
        params.put('paymentChargeId', '123456789');
        
        // GIVEN: spouse of donor making the donation
        //contact
        Contact spouse = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert spouse;
        
        // GIVEN: donor making the donation
        Contact contact = new Contact(LastName = 'LastName2', FirstName = 'FirstName2', ucinn_ascendv2__Preferred_Spouse__c = spouse.Id);
        params.put('constituentRec', contact);
        insert contact;
        
        //account
        Account account = new Account(Name = 'TestName925');
        insert account;
        params.put('organizationRec', account);
        
        //Opportunity
        Opportunity opp = new Opportunity();
		opp.AccountId = account.Id;      
        opp.Name = 'Test Opp'; //Name
        opp.StageName = 'Active'; //StageName
        opp.CloseDate = System.today() + 30; //Close Date
        Opp.Amount = 300;
        Opp.Type = 'Recurring';
        params.put('giftRec', opp);
        
        //Designation detail list
        List<ucinn_ascendv2__Designation_Detail__c> desigDetailList = new List<ucinn_ascendv2__Designation_Detail__c>();
        
        ucinn_ascendv2__Designation_Detail__c desigDetail = new ucinn_ascendv2__Designation_Detail__c();
        desigDetail.ucinn_ascendv2__Amount__c = 300;
        desigDetail.ucinn_ascendv2__Contact__c = contact.Id;

		desigDetailList.add(desigDetail);
		params.put('designationDetailRecList', desigDetailList);
        params.put('externalPaymentGatewayId', 'PRAX-TEST-1234455643');
        params.put('amountToPayToday', '10.0');
        params.put('creditCardExpirationDate', '1123');
        params.put('giftTypeSelected', 'OutrightGift');

        params.put('contact_salutation', 'Mr');
        params.put('contact_firstname', 'Test');
        params.put('contact_lastname', 'Test');
        params.put('contact_phone', '1234567676');
        params.put('contact_email', 'test@test.com');
        params.put('contact_address1', '788 Fake Street');
        params.put('contact_city', 'Irvine');
        params.put('contact_state', 'CA');
        params.put('contact_postalcode', '92229');
        params.put('contact_country', 'USA');
        params.put('pageName', 'armi');

        params.put('captchaResponseKey', 'captchakey');
        params.put('captchaBypassToken', 'testByPassToken');

        
        ucinn_ascendv2__Transaction_Data__c badResult = new ucinn_ascendv2__Transaction_Data__c(ucinn_ascendv2__Reason_Code__c = '230');
        insert badResult;


        CaptchaSettings__c cs = CaptchaSettings__c.getOrgDefaults();
        cs.Captcha_URL__c = 'https://test.com';
        cs.Site_key__c = 'sitekey123';
        cs.Secret_key__c = 'secretkey123';
        cs.Page_bypass__c = 'bypass';
        upsert cs;

        Blob key = Crypto.generateAesKey(256);

        Environment_Settings__c envSettng = Environment_Settings__c.getOrgDefaults();
        envSettng.Captcha_Key__c = EncodingUtil.base64Encode(key);
        upsert envSettng;

        test.startTest();
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ReCaptchaHTTPMock());
        ReCaptchaService.bEnterprise = false;
        // WHEN: donation is created
        Map<String, Object> createTransactionResult = PORTAL_UCIN_DonationController.createTransaction(params);
 		params.put('transactionId',createTransactionResult.get('transactionId'));
		params.put('externalPaymentGatewayId', badResult.id);
        params.remove('captchaResponseKey');
        params.remove('captchaBypassToken');
        params.put('encryptedKey',createTransactionResult.get('encryptedKey'));
        

      	PORTAL_UCIN_DonationController.processPayment(params);
        test.stopTest();

        // THEN: verify that the transaction was created
		// Confirm transaction data is created
        List<ucinn_ascendv2__Transaction_Data__c> createdTransactions = [SELECT ID,ucinn_ascendv2__Message__c,ucinn_ascendv2__Reason_Code__c FROM ucinn_ascendv2__Transaction_Data__c]; 
        Assert.areNotEqual(createdTransactions.size(), 0);
    }
    @IsTest
    public static void test_SERVER_Callout_Cybersource_Success()
    {
        Map<String, Object> params = new Map<String, Object>();

        
        
        String isAnonymousUser = 'isAnonymousUser';
        Boolean anon = true;
        params.put(isAnonymousUser, anon);

        // GIVEN: credit card used for donation
        params.put('creditCardNumber', '1234123412341234');
        params.put('creditCardType', 'VISA');
        params.put('creditCardExpirationDate', '1123');
        params.put('paymentChargeId', '123456789');
        
        // GIVEN: spouse of donor making the donation
        //contact
        Contact spouse = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert spouse;
        
        // GIVEN: donor making the donation
        Contact contact = new Contact(LastName = 'LastName2', FirstName = 'FirstName2', ucinn_ascendv2__Preferred_Spouse__c = spouse.Id);
        params.put('constituentRec', contact);
        insert contact;
        
        //account
        Account account = new Account(Name = 'TestName925');
        insert account;
        params.put('organizationRec', account);
        
        //Opportunity
        Opportunity opp = new Opportunity();
		opp.AccountId = account.Id;      
        opp.Name = 'Test Opp'; //Name
        opp.StageName = 'Active'; //StageName
        opp.CloseDate = System.today() + 30; //Close Date
        Opp.Amount = 300;
        Opp.Type = 'Outright';
        params.put('giftRec', opp);
        
        //Designation detail list
        List<ucinn_ascendv2__Designation_Detail__c> desigDetailList = new List<ucinn_ascendv2__Designation_Detail__c>();
        
        ucinn_ascendv2__Designation_Detail__c desigDetail = new ucinn_ascendv2__Designation_Detail__c();
        desigDetail.ucinn_ascendv2__Amount__c = 300;
        desigDetail.ucinn_ascendv2__Contact__c = contact.Id;

		desigDetailList.add(desigDetail);
		params.put('designationDetailRecList', desigDetailList);
        params.put('externalPaymentGatewayId', 'PRAX-TEST-1234455643');
        params.put('amountToPayToday', '10.0');
        params.put('creditCardExpirationDate', '1123');
        params.put('giftTypeSelected', 'OutrightGift');

        params.put('contact_salutation', 'Mr');
        params.put('contact_firstname', 'Test');
        params.put('contact_lastname', 'Test');
        params.put('contact_phone', '1234567676');
        params.put('contact_email', 'test@test.com');
        params.put('contact_address1', '788 Fake Street');
        params.put('contact_city', 'Irvine');
        params.put('contact_state', 'CA');
        params.put('contact_postalcode', '92229');
        params.put('contact_country', 'USA');
		params.put('pageName', 'armi');
        params.put('captchaResponseKey', 'captchakey');
        params.put('captchaBypassToken', 'testByPassToken');
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ReCaptchaHTTPMock());
        ReCaptchaService.bEnterprise = false;

        CaptchaSettings__c cs = CaptchaSettings__c.getOrgDefaults();
        cs.Captcha_URL__c = 'https://test.com';
        cs.Site_key__c = 'sitekey123';
        cs.Secret_key__c = 'secretkey123';
        cs.Page_bypass__c = 'bypass';
        upsert cs;

        Blob key = Crypto.generateAesKey(256);

        Environment_Settings__c envSettng = Environment_Settings__c.getOrgDefaults();
        envSettng.Captcha_Key__c = EncodingUtil.base64Encode(key);
        upsert envSettng;
        
        ucinn_ascendv2__Transaction_Data__c goodResult = new ucinn_ascendv2__Transaction_Data__c(ucinn_ascendv2__Reason_Code__c = '100');
        insert goodResult;
        // given : the Account and Contact are created
        test.startTest();
		// when : the a payment with credit card type VISA is initiated
        Map<String, Object> createTransactionResult = PORTAL_UCIN_DonationController.createTransaction(params);
 		params.put('transactionId',createTransactionResult.get('transactionId'));
		params.put('externalPaymentGatewayId',goodResult.id);
        params.put('encryptedKey',createTransactionResult.get('encryptedKey'));

        params.remove('captchaResponseKey');
        params.remove('captchaBypassToken');


      	PORTAL_UCIN_DonationController.processPayment(params);
        test.stopTest();
		// then: Confirm transaction data is created with the related reason code
        List<ucinn_ascendv2__Transaction_Data__c> createdTransactions = [SELECT ID,ucinn_ascendv2__Message__c,ucinn_ascendv2__Reason_Code__c FROM ucinn_ascendv2__Transaction_Data__c WHERE ucinn_ascendv2__Reason_Code__c = '100'];
        Assert.areEqual(createdTransactions.size(), 1);
    }
	
	@IsTest
    public static void test_SERVER_Callout_Cybersource_Success_AmericanExpress()
    {
        Map<String, Object> params = new Map<String, Object>();
        
        String isAnonymousUser = 'isAnonymousUser';
        Boolean anon = true;
        params.put(isAnonymousUser, anon);

        params.put('creditCardNumber', '1234123412341234');
        params.put('creditCardType', 'american express');
        params.put('creditCardExpirationDate', '1123');
        params.put('paymentChargeId', '123456789');
        
        //contact
        Contact spouse = (Contact)TestDataFactory.createSObject(new Contact(LastName = 'LastName', FirstName = 'FirstName'), true);
        
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(LastName = 'LastName2', FirstName = 'FirstName2', ucinn_ascendv2__Preferred_Spouse__c = spouse.Id), true);
        params.put('constituentRec', contact);
        
        //account
        Account account = (Account)TestDataFactory.createSObject(new Account(Name = 'TestName925'), true);
        params.put('organizationRec', account);
        
        //Opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = account.Id,Name = 'Test Opp',StageName = 'Active',CloseDate = System.today() + 30,Amount = 300,Type = 'Outright' ), false);
        params.put('giftRec', opp);
        
        //Designation detail list
        List<ucinn_ascendv2__Designation_Detail__c> desigDetailList = new List<ucinn_ascendv2__Designation_Detail__c>();
        
        ucinn_ascendv2__Designation_Detail__c desigDetail = new ucinn_ascendv2__Designation_Detail__c();
        desigDetail.ucinn_ascendv2__Amount__c = 300;
        desigDetail.ucinn_ascendv2__Contact__c = contact.Id;

		desigDetailList.add(desigDetail);
		params.put('designationDetailRecList', desigDetailList);
        params.put('externalPaymentGatewayID', 'PRAX-TEST-1234455643');
        params.put('amountToPayToday', '10.0');
        params.put('creditCardExpirationDate', '1123');
        params.put('giftTypeSelected', 'OutrightGift');

        params.put('contact_salutation', 'Mr');
        params.put('contact_firstname', 'Test');
        params.put('contact_lastname', 'Test');
        params.put('contact_phone', '1234567676');
        params.put('contact_email', 'test@test.com');
        params.put('contact_address1', '788 Fake Street');
        params.put('contact_city', 'Irvine');
        params.put('contact_state', 'CA');
        params.put('contact_postalcode', '92229');
        params.put('contact_country', 'USA');
		params.put('pageName', 'armi');
        params.put('captchaResponseKey', 'captchakey');
        params.put('captchaBypassToken', 'testByPassToken');
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ReCaptchaHTTPMock());
        ReCaptchaService.bEnterprise = false;

        CaptchaSettings__c cs = CaptchaSettings__c.getOrgDefaults();
        cs.Captcha_URL__c = 'https://test.com';
        cs.Site_key__c = 'sitekey123';
        cs.Secret_key__c = 'secretkey123';
        cs.Page_bypass__c = 'bypass';
        upsert cs;

        Blob key = Crypto.generateAesKey(256);

        Environment_Settings__c envSettng = Environment_Settings__c.getOrgDefaults();
        envSettng.Captcha_Key__c = EncodingUtil.base64Encode(key);
        upsert envSettng;

        ucinn_ascendv2__Transaction_Data__c goodResult = (ucinn_ascendv2__Transaction_Data__c)TestDataFactory.createSObject(new ucinn_ascendv2__Transaction_Data__c(ucinn_ascendv2__Reason_Code__c = '101'), true);
        // given : the Account and Contact are created
        test.startTest();
        // when : the a payment with credit card type American Express is initiated
        Map<String, Object> createTransactionResult = PORTAL_UCIN_DonationController.createTransaction(params);
 		params.put('transactionId',createTransactionResult.get('transactionId'));
		params.put('externalPaymentGatewayId',goodResult.id);
        params.put('encryptedKey',createTransactionResult.get('encryptedKey'));

        params.remove('captchaResponseKey');
        params.remove('captchaBypassToken');

      	PORTAL_UCIN_DonationController.processPayment(params);
        test.stopTest();
		// then: Confirm transaction data is created with the related reason code
        List<ucinn_ascendv2__Transaction_Data__c> createdTransactions = [SELECT ID,ucinn_ascendv2__Message__c,ucinn_ascendv2__Reason_Code__c FROM ucinn_ascendv2__Transaction_Data__c WHERE ucinn_ascendv2__Reason_Code__c = '101'];
        Assert.areEqual(createdTransactions.size(), 1);
    }

    @IsTest
    public static void test_getBaseUrl()
    {
        // GIVEN/WHEN: Error messages from PORTAL_UCIN_Donation_Error__mdt
        test.startTest();
        String baseUrl = PORTAL_UCIN_DonationController.getBaseUrl();
        test.stopTest();

        // THEN: verify that error message from 'Default Error' record is not blank
        Assert.IsTrue(baseUrl != null);
    }
}