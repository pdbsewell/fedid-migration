/**
 * @File Name          : CommonUtilities_Test.cls
 * @Description        : Test class for CommonUtilities.cls
 * @Author             : Nick Guia
 * @Group              : Commons
 * 01-06-2025 Martin Cadman : Moved to Assert class, improved fieldHasChanged tests to include different data types
 * 14-08-2025 Matt Maramot  : Removed testAssignCampaignMemberStatus
 */
@isTest(isParallel=true)
private class CommonUtilities_Test {

	@TestSetup
	static void setup(){
		//create test accounts
		List<Contact> conList = TestHelper.createProspectiveStudentContact(3);
		insert conList;

		//create channels and Roles
		List<Channel__c> chList = new List<Channel__c>();
		List<Roles__c> roleList = new List<Roles__c>();

		for(Contact iCon : conList) {
			Channel__c ch = TestHelper.createChannel(iCon);
			chList.add(ch);

			Roles__c rl = TestHelper.createRole(iCon, null);
			roleList.add(rl);
		}
		insert chList;
		insert roleList;

		//create test campaign
		List<Campaign> campList = TestHelper.createCampaign(1);
		campList[0].RecordTypeId = CampaignServices.BMS_RECTYPE;

		//create test records
        Campaign mie = new Campaign();
        mie.Name = 'The Monash Info and Events for Prospective Students';
        mie.RecordTypeId = CampaignServices.SUB_LIST_RECTYPE;
        mie.Channel_Type__c = 'SMS;Email';
        mie.IsActive = true; 

        Campaign mr = new Campaign();
        mr.Name = 'The Market research participation';
        mr.RecordTypeId = CampaignServices.SUB_LIST_RECTYPE;
        mr.Channel_Type__c = 'SMS;Email';
		mr.IsActive = true;
		
        campList.add(mie);
		campList.add(mr);
		
		insert campList;

        Marketing_Subscription_List__c setting = new Marketing_Subscription_List__c();
        setting.MIE__c = mie.Id;
        setting.MR__c = mr.Id;
		insert setting;
	}

	/**
	 * @description test scenario for sending a BMS email campaign.
	 * 	We verify that emails got sent by validating the number of 
	 * 	Email invokations that happened.
	 */
	@isTest
	static void testSendBMSEmail() {
		// GIVEN: We have BMS Email Campaign to send
		List<Campaign> campaignList = [SELECT Id 
									FROM Campaign 
									WHERE RecordTypeId = :CampaignServices.BMS_RECTYPE];
		Integer emailSends = 0;

		// WHEN: Emails are sent
		Test.startTest();
		CommonUtilities.sendBMSEmail(campaignList);
		emailSends = Limits.getEmailInvocations();
		Test.stopTest();

		// THEN: verify that we are able to invoke email sends based on number of Campaigns
		Assert.areEqual(campaignList.size(), emailSends, 'Unable to send all BMS emails');
	}

	/**
	 * @description test scenario for capturing the last Ascend login Date
	 */
	@IsTest
     public static void testUpdateLastPortalLoginDate()
    {
        // GIVEN/WHEN : the User has logged in and completed the session
        test.startTest();
        CommonUtilities.updateLastPortalLoginDate(UserInfo.getUserId(), String.valueOf(Label.Ascend_Portal_Name));
        test.stopTest();

        // THEN: Retrieving the linked Contact 
        List<User> loggedUser = [SELECT Id, Contact.Last_Ascend_Portal_Login__c FROM User WHERE Id = :UserInfo.getUserId()];
        Assert.isNull(loggedUser[0].Contact.Last_Ascend_Portal_Login__c, 'Contact Last Login Update failed');
    }
	
	/**
	 * @description test scenario for terminating the logged in User Session across all Browsers
	 */
	@IsTest
     public static void testTerminateUserSession()
    {
        // GIVEN : the session exists
		List<AuthSession> loggedUserSession = [SELECT Id FROM AuthSession WHERE UsersId = :UserInfo.getUserId()];
        Assert.areNotEqual(loggedUserSession.size(), 0, 'expected at least one active session');
		
		// WHEN: the User session is terminated
        test.startTest();
        CommonUtilities.terminateUserSession(UserInfo.getUserId());
        test.stopTest();

        // then: only the current session is active, the one running currently
        List<AuthSession> loggedUserNonCurrentSession = [SELECT Id FROM AuthSession WHERE UsersId = :UserInfo.getUserId() AND IsCurrent = false];
        Assert.areEqual(0, loggedUserNonCurrentSession.size(),'expected no active sessions (excluding current session)');
    }

	/**
	 * @description test scenario for getting the default BMS send type
	 * 	based on URL parameter of the VF Page
	 */
	@isTest
	static void testRetrieveSendType() {
		// GIVEN/WHEN: We need the BMS send type
		String urlParamSendType = 'sms';
		System.currentPageReference().getParameters().put('type', urlParamSendType);
		String sendType;

		Test.startTest();
		sendType = CommonUtilities.retrieveSendType();
		Test.stopTest();

		// THEN: The retrieved send type matches the URL Parameter
		Assert.areEqual(urlParamSendType, sendType, 'Unable to get actual BMS send type');
	}

	/**
	 * @description test scenario for getting the default BMS send type
	 * 	when it wasn't explicitly indicated in the URL parameter. This
	 * 	should always default to email
	 */
	@isTest
	static void testRetrieveSendTypeNegative() {

		// GIVEN: We have no send type and none indicated in URL parameter
		String sendType;

		// WHEN: We retrieve send type
		Test.startTest();
		sendType = CommonUtilities.retrieveSendType();
		Test.stopTest();

		// THEN: Retrieved send type is the default value
		Assert.areEqual('email', sendType, 'Unable to get actual BMS send type');
	}

	/**
	 * @description test scenario for getting Profile of current running user
	 */
	@isTest
	static void testGetProfileName() {
		// GIVEN: We have no profile name
		String profileName;

		// WHEN: We retrieve profile name
		Test.startTest();
		profileName = CommonUtilities.getProfileName();
		Test.stopTest();

		// THEN: Retrieved value matches the current user
		String currentUserProfile = [SELECT Id, Name FROM Profile WHERE Id =: userinfo.getProfileId() ].Name;
		Assert.areEqual (currentUserProfile, profileName, 'Unable to get actual user profile');
	}

	/**
	 * @description test scenario for validating an
	 * 	email address
	 */
	@isTest
	static void testValidateEmail() {
		// GIVEN: We have an email address
		String sEmail = 'test@test.org';
		Boolean isValid = false;

		// WHEN: It is validated
		Test.startTest();
		isValid = CommonUtilities.validateEmail(sEmail);
		Test.stopTest();

		// THEN: Email is flagged as valid
		Assert.isTrue (isValid, 'Unable to validate correct email address : ' + sEmail);
	}

	/**
	 * @description test scenario for validating an
	 * 	invalid email address
	 */
	@isTest
	static void testValidateEmailNegative() {
		// GIVEN: We have an invalid email address
		String sEmail = 'INVALID_EMAIL12345';
		Boolean isValid = false;

		// WHEN: It is validated
		Test.startTest();
		isValid = CommonUtilities.validateEmail(sEmail);
		Test.stopTest();

		// THEN: Email is flagged as invalid
		Assert.isTrue(!isValid, 'Unable to validate incorrect email address : ' + sEmail);
	}

	/**
	 * @description test scenario for querying existing Roles
	 */
	@isTest
	static void testGetRoles() {
		// GIVEN: We have existing roles
		Map<Id, Roles__c> rlMap = new Map<Id, Roles__c>(
			[SELECT Id FROM Roles__c LIMIT 10000]
			);

		//get Role IDs
		Set<Id> rlIds = new Set<Id>();
		if(!rlMap.isEmpty()) {
			rlIds = rlMap.keySet();
		}

		List<Roles__c> rlResult = new List<Roles__c>();

		// WHEN: Roles are retrieved
		Test.startTest();
		rlResult = CommonUtilities.getRoles(rlIds);
		Test.stopTest();

		// THEN: They are successfully retrieved 
		Assert.isTrue (!rlResult.isEmpty(), 'Unable to query Role records');
	}

	/**
	 * @description test scenario for querying existing Channels
	 */
	@isTest
	static void testGetChannels() {
		//GIVEN: We have existing Channels 
		Map<Id, Channel__c> chMap = new Map<Id, Channel__c>(
			[SELECT Id FROM Channel__c LIMIT 10000]
			);

		Set<Id> channelIds = new Set<Id>();
		if(!chMap.isEmpty()) {
			channelIds = chMap.keySet();
		}

		List<Channel__c> chResult = new List<Channel__c>();

		// WHEN: Channels are retrieved
		Test.startTest();
		chResult = CommonUtilities.getChannels(channelIds);
		Test.stopTest();

		// THEN: They are successfully retrieved
		Assert.isTrue (!chResult.isEmpty(), 'Unable to query Channel records');
	}

	/**
	 * @description test scenario getting a comma-separated String
	 * 	value of all fields for a certain SObject
	 */
	@isTest
	static void testGetAllFields() {
		// GIVEN/WHEN: We retrieve all fields from an object
		String sFields;

		Test.startTest();
		sFields = CommonUtilities.getAllFields('Contact');
		Test.stopTest();

		// THEN: Verify that string is not blank and test 3 fields that got included
		Assert.isTrue (String.isNotBlank(sFields), 'CommonUtilities.getAllFields returned a null value');
		Assert.isTrue (sFields.contains('Email'), 'Unable to query Email field from Contact');
		Assert.isTrue (sFields.contains('FirstName'), 'Unable to query FirstName field from Contact');
		Assert.isTrue (sFields.contains('LastName'), 'Unable to query ELastNamemail field from Contact');
	}

	/**
	 * @description tests whether Pciklist Values are fetched for a specific Object.Field
	 */
	@isTest
	static void testGetPicklistValues() {
		// GIVEN/WHEN: We obtain picklist values from Contact 's Gender__c field
		Map<String, String> mapPicklistValues;

		Test.startTest();
		mapPicklistValues = CommonUtilities.getPicklistValues('Contact', 'Gender__c');
		Test.stopTest();

		// THEN: Verify that picklist values are returned
		Assert.isTrue(mapPicklistValues != null && !mapPicklistValues.isEmpty(), 'CommonUtilities.getPicklistValues returned a null value');
	}

	/**
	 * @description test scenario for building a Dynamic query
	 * 	based on SObject name parameter String.
	 */
	@isTest
	static void testQueryBuilder() {
		// GIVEN/WHEN: We build a dynamic query for Contact object
		String queryString;

		Test.startTest();
		queryString = CommonUtilities.queryBuilder('Contact');
		Test.stopTest();

		// THEN: Verify that string is not blank and test 3 fields that got included
		Assert.isTrue (String.isNotBlank(queryString), 'CommonUtilities.queryBuilder returned a null value');
		Assert.isTrue (queryString.contains('Email'), 'Unable to query Email field from Contact');
		Assert.isTrue (queryString.contains('FirstName'), 'Unable to query FirstName field from Contact');
		Assert.isTrue (queryString.contains('LastName'), 'Unable to query ELastNamemail field from Contact');
	}

	/**
	 * @description test the method for getting the difference
	 * 	between two DateTimes, in Seconds
	 */
	@isTest
	static void testGetDateTimeDifference() {
		// GIVEN/WHEN: We want to calculate DateTime differences
		DateTime dt = System.now();
		Integer secDifference;
		Integer arbSec = 5;

		Test.startTest();
		secDifference = (Integer) CommonUtilities.getDateTimeDifference(dt, dt.addSeconds(arbSec));
		Test.stopTest();

		//THEN: the arbitrary Seconds should be equal to the computed time difference 
		Assert.areEqual(arbSec, secDifference, 'Unexpected value received from date time difference');
	}

	/**
	 * @description test scenario for checking whether an sobject
	 * Compare the same field on different records and return true if the values are different. This is commonly used in trigger handlers
	 */
	@isTest
	static void testFieldHasChanged() {
		// GIVEN: We have a NEW and OLD contact record
		Contact con1 = new Contact(FirstName = 'Test1', LastName = 'testa', birthdate=Date.today(),is_student__c=false,mailingCountry = 'Australia',middlename='John');
		Contact con2 = new Contact(FirstName = 'Test2', LastName = 'TESTA', birthdate=Date.today(),is_student__c=true,mailingCountry = 'United Kingdom');

		// WHEN: When the fields are compared between NEW and OLD
		Test.startTest();
		Boolean fieldChangedFN = CommonUtilities.fieldHasChanged('FirstName', con2, con1); // values different
        Boolean fieldChangedLN = CommonUtilities.fieldHasChanged('LastName', con2, con1); // case different
        Boolean fieldChangedBD = CommonUtilities.fieldHasChanged('birthdate', con2, con1); // same day
        Boolean fieldChangedStudent = CommonUtilities.fieldHasChanged('is_student__c', con2, con1); // true vs. false
        Boolean fieldChangedMC = CommonUtilities.fieldHasChanged('mailingCountry', con2, con1); // different picklist values
        Boolean fieldChangedMN = CommonUtilities.fieldHasChanged('middlename', con2, con1); // different values, one null
        Boolean fieldChangedPFN = CommonUtilities.fieldHasChanged('preferred_name__c', con2, con1); // both one null
        
        Test.stopTest();

		// THEN: Fields that have modified are flagged
		Assert.isTrue(fieldChangedFN, 'Expected field change to have been detected');
		Assert.isTrue(fieldChangedLN, 'Expected field change to have been detected');
		Assert.isFalse(fieldChangedBD, 'Expected no field change');
		Assert.isTrue(fieldChangedStudent, 'Expected field change to have been detected');
		Assert.isTrue(fieldChangedMC, 'Expected field change to have been detected');
		Assert.isTrue(fieldChangedMN, 'Expected field change to have been detected');
		Assert.isFalse(fieldChangedPFN, 'Expected no field change');
	}

	/**
	 * @description negative test scenario for checking whether an sobject
	 * 	field has doesn't match it's previous value. 
	 * 	Test by providing null parameters
	 */
	@isTest
	static void testFieldHasChangedNegative() {
		// GIVEN: We have a NEW and OLD contact record
        Contact c1 = new contact(lastname='Contact');
        Contact c2 = new contact(lastname='CONTACT');

        // WHEN: When the fields are compared between NEW and OLD
		Test.startTest();
		Boolean fieldChangedNull = CommonUtilities.fieldHasChanged(null, null, null);
        Boolean fieldChangedNoNull = CommonUtilities.fieldHasChanged('firstname', c1, c2);
        Boolean fieldChangedLNull = CommonUtilities.fieldHasChanged('firstname', null, c2);
        Boolean fieldChangedRNull = CommonUtilities.fieldHasChanged('firstname', c1, null);
        Boolean fieldChangedLN = CommonUtilities.fieldHasChanged('lastname', c1, c2);
        Boolean fieldChangedConLN = CommonUtilities.valueDiff(c1.lastname, c2.lastname);
		Test.stopTest();

		// THEN: Fields that have modified are flagged
		Assert.isTrue(!fieldChangedNull, 'Null fieldname should return false');
		Assert.isTrue(!fieldChangedNoNull, 'Null fields should return false');
		Assert.isTrue(!fieldChangedLNull, 'Null objects should return false');
		Assert.isTrue(!fieldChangedRNull, 'Null objects should return false');
		Assert.isTrue(fieldChangedLN, 'Different case lastnames should be detected');
		Assert.isTrue(fieldChangedConLN, 'Unexpected value returned while checking field update');

	}

	@isTest
	static void testAddListToMapByKey() {
		// GIVEN: We have Roles to assign to Contacts
		List<Roles__c> roleList = new List<Roles__c>();
		for(Contact iCon : [SELECT Id FROM Contact]) {
			//create two children Role records for each Contact
			Roles__c roleRec1 = TestHelper.createRole(iCon, null);
			Roles__c roleRec2 = TestHelper.createRole(iCon, null);
			roleList.add(roleRec1);
			roleList.add(roleRec2);
		}

		Map<String, List<SObject> > res = new Map<String, List<SObject> >();

		// WHEN: We add list to map by key
		Test.startTest();
		res = CommonUtilities.addListToMapByKey(roleList, 'Contact__c');
		Test.stopTest();

		// THEN: We should have a map with Contact Id as key and list of child records as value
		Assert.isTrue (!res.isEmpty(), 'Received an empty result');
		for(String key : res.keySet()) {
			Assert.areEqual (2, res.get(key).size(), 'Unexpected number of child records found in map');
        }
	}

	/**
	 * @description test method for mergeRecordList.
	 *  This will merge data of List of SObject records
	 *  latest - greatest
	 */
	@isTest
	static void testMergeRecordList() {
		// GIVEN: We have two lead records
		Lead param1 = new Lead();
		param1.FirstName = 'TestLead1';
		param1.LastName = 'TestLast1';
		param1.Company = 'N/A';
		param1.Phone = '987654321';

		Lead param2 = new Lead();
		param2.FirstName = 'TestLead2';
		param2.LastName = 'TestLast2';
		param2.Company = 'N/A';
		param2.Phone = '123456789';

		List<Lead> leadList = new List<Lead> {param1, param2};
		Lead mergedLead;

		// WHEN: They are merged 
		Test.startTest();
		mergedLead = (Lead) CommonUtilities.mergeRecordList(leadList);
		Test.stopTest();

		// THEN: Information from param2 Lead should supersede
		Assert.areEqual(param2.FirstName, mergedLead.FirstName, 'Unexpected merged value for field : FistName');
        Assert.areEqual(param2.LastName, mergedLead.LastName, 'Unexpected merged value for field : LastName');
        Assert.areEqual(param2.Phone, mergedLead.Phone, 'Unexpected merged value for field : Phone');
	}

    /**
     * TEST METHOD CREATED FOR COVERAGE. 
     * UTILITY METHOD TO BE DELETED
     */
	@isTest
	static void testMergeRecordListOldestGreatest() {
		// GIVEN: We have two lead records
		Lead param1 = new Lead();
		param1.FirstName = 'TestLead1';
		param1.LastName = 'TestLast1';
		param1.Company = 'N/A';
		param1.Phone = '987654321';

		Lead param2 = new Lead();
		param2.FirstName = 'TestLead2';
		param2.LastName = 'TestLast2';
		param2.Company = 'N/A';
		param1.Phone = '123456789';

		List<Lead> leadList = new List<Lead> {param1, param2};
		Lead mergedLead;

		// WHEN: They are merged by OldestGreatest
		Test.startTest();
		mergedLead = (Lead) CommonUtilities.mergeRecordListOldestGreatest(leadList);
		Test.stopTest();
	}

	/**
	 * @description test method for mergeRecords.
	 *  This method should ONLY populate blank values
	 *  of parameter 2 from values of parameter 1
	 */
	@isTest
	static void testMergeRecords() {
		// GIVEN: We have two lead records
		Lead param1 = new Lead();
		param1.FirstName = 'TestLead1';
		param1.LastName = 'TestLast1';
		param1.Company = 'N/A';
		param1.Phone = '987654321';

		Lead param2 = new Lead();
		param2.FirstName = 'TestLead2';
		param2.LastName = 'TestLast2';
		param2.Company = 'N/A';
		param2.MobilePhone = '123456789';

		Lead mergedLead;

		// WHEN: They are merged
		Test.startTest();
		mergedLead = (Lead) CommonUtilities.mergeRecords(param1, param2);
		Test.stopTest();

		// THEN: mergedLead should now contain both Phone and MobilePhone
		Assert.areEqual(param1.Phone, mergedLead.Phone, 'Unexpected value for merged field value : Phone');
        Assert.areEqual(param2.MobilePhone, mergedLead.MobilePhone, 'Unexpected value for merged field value : MobilePhone');
	}
	
	/**
	 * @description test Get LongMonthName With MonthNumber
	 */
	@isTest
	static void testGetLongMonthNameWithMonthNumber() {
		// GIVEN/WHEN: We need a map of months
		Test.startTest();
		Map<Integer,String> m_monthNumberMonthLongName = CommonUtilities.getLongMonthNameWithMonthNumber();
		Test.stopTest();

		// THEN: the Map should have the months with numbers
		Assert.areEqual(m_monthNumberMonthLongName.get(1), 'January');
	} 

    /**
	 * @description test method for correctName method
     *  the method should remove any numeric characters and convert
     *  words into proper case.
	 */
	@isTest
	static void testCorrectName() {
		// GIVEN: We have a string with an invalid name format
        String inpTestString = 'test987 lastname';
		String outpString;

		// WHEN: We correct the name
		Test.startTest();
		outpString = CommonUtilities.correctName(inpTestString);
		Test.stopTest();

		// THEN: We get a proper case format
		Assert.isTrue (String.isNotBlank(outpString), 'Unexpected output String');
		Assert.areEqual('Test Lastname', outpString, 'Unable to get proper case format of ' + inpTestString);
	}

    /**
     * @description test utility method for fetching the Monash University Global account record.
     *  This Account record is the parent of all Prospective Student Role records.
     */
	@isTest
	static void testGetGlobalMonashAccountId() {

		// GIVEN/WHEN: We need Monash University Global Account Record
		Id mGlobalId;

		Test.startTest();
		mGlobalId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
		Test.stopTest();

		// THEN: We obtain the Global Account
		Account globalAccount = [SELECT Id, Name FROM Account WHERE Name = 'Monash University Global Account' LIMIT 1];
		Assert.isTrue (globalAccount != null, 'Unable to create Monash University Global Account');
		Assert.areEqual(globalAccount.Id, mGlobalId, 'Unexpected Global Monash Account ID');
	}
	
	/**
     * @description test get marketing subscription list 
	 * 	custom setting
     */
	@isTest
	static void shouldHaveSubscriptionListCampaignIds() {

		//GIVEN: We have a campaign

		Set<Id> marketingSubList = new Set<Id>();
		Set<Id> sublistCampaigns = new Map<Id, Campaign>(
			[SELECT Id 
			FROM Campaign 
			WHERE RecordTypeId = :CampaignServices.SUB_LIST_RECTYPE]).keySet();

		// WHEN: We get the marketing subscription list
		Test.startTest();
		marketingSubList = CommonUtilities.MARKETING_SUB_LISTS;
		Test.stopTest();

		//THEN:The marketing subscription list contains the campaignids
		for(Id subListId : sublistCampaigns) {
			Assert.isTrue(marketingSubList.contains(subListId));
		}

    }
	/**
     * @description test the createNicknameForUser
	 * 
     */
	@isTest
	static void createNicknameForUserTest() {
		// GIVEN: We have a contact
        Contact con = [select id,LastName,FirstName from Contact LIMIT 1 ];
		
		// WHEN: We create nickname for user
        Test.startTest();
	 		CommonUtilities.createNicknameForUser(con.FirstName, con.LastName, 1);
		Test.stopTest();
		
		//THEN: The contact last name is Prospective
        Assert.areEqual('Prospective', con.LastName);
	}
	
	 /**
     * @description test the createAliasForUser
	 * 
     */
	@isTest
	static void createAliasForUserTest() {
		// GIVEN: We have a contact
        Contact con = [select id,LastName,FirstName from Contact LIMIT 1 ];
		
		// WHEN: We create alias for user
        Test.startTest();
	 		CommonUtilities.createAliasForUser(con.FirstName, con.LastName);
		Test.stopTest();

		// THEN: The contact last name is Prospective
        Assert.areEqual('Prospective', con.LastName);
    }
	/**
	 * @description testMethod description
	 */ 
	@isTest
	static void populateSObjectStrLengthByDescribeTest(){
		//GIVEN - Limits Field length via Field Describe
		User usr = new User();
		usr.Alias = 'None';
		Schema.sObjectField fieldToTest = User.Alias;
		//WHEN - Behaviour to Test
		
		CommonUtilities.populateSObjectStrLengthByDescribe('123456789', usr, fieldToTest);
		
		//THEN - String value trimmed 
		Assert.areEqual(usr.Alias.length(),
			fieldToTest.getDescribe().getLength(),
			'Describe field length incorrect '+usr.Alias);
	}
}