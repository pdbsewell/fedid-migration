/**
 * @File Name          : ExplodingLeadsFactory_Test.cls
 * @Description        : Test class for ExplodingLeadsFactory.
 * @Author             : Nick Guia
 * @Date               : APR.24.2018
 * @Group              : Lead Management
 **/
@isTest(isParallel=true)
private class ExplodingLeadsFactory_Test {

	private static final Integer COURSE_MASTER_NUMBER  = 1;

	@TestSetup
	static void initialize() {
		//setup global monash account
		Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
		
		//setup Campaign
		Id subsListRT = Schema.SObjectType.Campaign
		                .getRecordTypeInfosByDeveloperName()
		                .get('Subscription_List')
		                .getRecordTypeId();
		Campaign subscriptionCampaign = new Campaign (Name = 'ExplodingLeadsFactory_Test',
		                                              Channel_Type__c = 'SMS;Email',
		                                              RecordTypeId = subsListRT);
		insert subscriptionCampaign;

		//setup Course Masters

		//create courses which will eventually create course masters
		List<Course__c> courseList = new List<Course__c>();
		Integer ctr = 1;
		Set<String> courseCodeSet = new Set<String>();
		for(Course__c iCourse : TestHelper.createCourses(COURSE_MASTER_NUMBER)) {
			iCourse.Name = 'exLeadTest'+ctr;
			iCourse.Type__c = Label.Course_Type_Course_All;
			iCourse.Course_Code__c = iCourse.Name;
			courseList.add(iCourse);
			courseCodeSet.add(iCourse.Name);
			ctr++;
		}
		insert courseList;

		//setup contact
		Contact pscon = TestHelper.createProspectiveStudentContact(1)[0];
		insert pscon;
	}

	/**
	 * @description Test if method is returning Contact with expected field values
	 */
	@isTest
	static void buildProspectiveContactTest() {
		Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
		ExplodingLeadsFactory exFactor = new ExplodingLeadsFactory();

		Test.startTest();
		Contact con = exFactor.buildProspectiveContact(sps);
		Test.stopTest();

		//check if field mappings are correct
		System.assertEquals(sps.Birthdate__c, con.Birthdate,
		                    'Unexpected value for Contact Birthdate');

		System.assertEquals(sps.Birth_year__c, con.Birth_year__c,
		                    'Unexpected value for Contact Birth_year__c');

		System.assertEquals(sps.Country_of_Residence__c, con.Country_of_Residence__c,
		                    'Unexpected value for Contact Country_of_Residence__c');

		System.assertEquals(sps.Email__c, con.Email,
		                    'Unexpected value for Contact Email');

		System.assertEquals(sps.First_Name__c, con.FirstName,
		                    'Unexpected value for Contact FirstName');

		System.assertEquals(sps.Gender__c, con.Gender__c,
		                    'Unexpected value for Contact Gender__c');

		System.assertEquals(sps.Last_Name__c, con.LastName,
		                    'Unexpected value for Contact LastName');

		System.assertEquals(sps.Nationality__c, con.Nationality__c,
		                    'Unexpected value for Contact Nationality__c');

		System.assertEquals(sps.Salutation__c, con.Salutation,
		                    'Unexpected value for Contact Salutation');

		System.assertEquals(StagedProspectiveStudentUtil.CONTACT_RECTYPE_PROPECTIVESTUDENT, con.RecordTypeId,
		                    'Unexpected value for Contact Record Type');
	}

	/**
	 * @description Test if method is returning an updated Contact with
	 * 	null values populated
	 */
	@isTest
	static void mergeProspectiveContactTest() {
		Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
		ExplodingLeadsFactory exFactor = new ExplodingLeadsFactory();

		Contact existingCon = new Contact(
			FirstName = 'Test',
			LastName = 'con');
		Contact spsCon = exFactor.buildProspectiveContact(sps);
		Contact newcon;

		Test.startTest();
		newcon = exFactor.mergeProspectiveContact(existingCon, spsCon);
		Test.stopTest();

		//check if blank fields were populated
		System.assertEquals(sps.Birthdate__c, newcon.Birthdate,
		                    'Unexpected value for Contact Birth_year__c');

		System.assertEquals(sps.Gender__c, newcon.Gender__c,
		                    'Unexpected value for Contact Gender__c');

		System.assertEquals(sps.Country_of_Residence__c, newcon.Country_of_Residence__c,
		                    'Unexpected value for Contact Country_of_Residence__c');

		System.assertEquals(sps.Nationality__c, newcon.Nationality__c,
		                    'Unexpected value for Contact Nationality__c');

		System.assertEquals(sps.Birth_year__c, newcon.Birth_year__c,
		                    'Unexpected value for Contact Birth_year__c');
	}

	/**
	 * @description Test if method is generating a Role with expected fields values
	 */
	@isTest
	static void buildProspectiveRoleTest() {
		Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
		ExplodingLeadsFactory exFactor = new ExplodingLeadsFactory();
		Roles__c rol;

		Test.startTest();
		rol = exFactor.buildProspectiveRole(sps);
		Test.stopTest();

		//check if values are as expected
		System.assertEquals(Label.Roles_Role_ProspectiveStudent, rol.Role__c,
		                    'Unexpected value for Role Role__c');

		System.assertEquals(Label.Roles_Status_Current, rol.Status__c,
		                    'Unexpected value for Role Status__c');

		System.assertEquals(sps.Id, rol.External_ID__c,
		                    'Unexpected value for Role External_ID__c');

		System.assertEquals(true, rol.Is_Parent__c,
		                    'Unexpected value for Role Is_Parent__c');
	}

	/**
	 * @description Test if method is generating a Channel records with
	 * 	expected field values
	 */
	@isTest
	static void buildProspectiveChannelTest() {
		Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
		ExplodingLeadsFactory exFactor = new ExplodingLeadsFactory();
		Channel__c ch;

		Test.startTest();
		ch = exFactor.buildProspectiveChannel(sps);
		Test.stopTest();

		//check if values are as expected
		System.assertEquals(sps.Email__c, ch.Email__c,
		                    'Unexpected value for Channel Email__c');

		System.assertEquals(sps.Mobile__c, ch.Mobile_Phone__c,
		                    'Unexpected value for Channel Mobile_Phone__c');

		System.assertEquals(sps.Phone__c, ch.Phone__c,
		                    'Unexpected value for Channel Phone__c');

		System.assertEquals(sps.Mailing_Street__c, ch.Street__c,
		                    'Unexpected value for Channel Street__c');

		System.assertEquals(sps.Mailing_City__c, ch.City__c,
		                    'Unexpected value for Channel City__c');

		System.assertEquals(sps.Mailing_Postcode__c, ch.Post_Code__c,
		                    'Unexpected value for Channel Post_Code__c');

		System.assertEquals(sps.Mailing_State__c, ch.State__c,
		                    'Unexpected value for Channel State__c');

		System.assertEquals(sps.Mailing_Country__c, ch.Country__c,
		                    'Unexpected value for Channel Country__c');

		System.assertEquals(Label.ExLeads_Channel_Type, ch.Type__c,
		                    'Unexpected value for Channel Type__c');
	}

	/**
	 * @description Test if method is returning Lead with expected field values
	 */
	@isTest
	static void buildProspectiveLeadTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);
		ExplodingLeadsFactory exFactor = new ExplodingLeadsFactory();
		Lead ld;

		//test if one text field (to be parsed as checkbox) receives 'T' (or 1)
		spsList[0].Interested_in_Monash_College_Text__c = 'T';

		Test.startTest();
		ld = exFactor.buildProspectiveLead(ld, spsList);
		Test.stopTest();

		System.assertEquals(ld.Company, 'N/A',
		                    'Unexpected value for Lead Company');

		System.assertEquals(ld.Status, 'Open',
		                    'Unexpected value for Lead Status');

		System.assertEquals(TRUE, ld.Interested_in_Monash_College__c,
		                    'Unexpected value for Lead Interested_in_Monash_College__c');

		System.assertEquals(ld.RecordTypeId, StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT,
		                    'Unexpected value for Lead Record Type');
	}

	/**
	 * @description test build a Lead Course Association record
	 * 	based on provided course master ID and rank
	 */
	@isTest
	static void buildLeadCourseAssociationTest() {
		Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
		ExplodingLeadsFactory exFactor = new ExplodingLeadsFactory();

		Course_Master__c setupCm = [SELECT Id, Name
		                            FROM Course_Master__c
		                            WHERE Name = 'exLeadTest1'
		                                         LIMIT 1];
		Lead_Course_Association__c lca;
		Integer rank = 1;

		Test.startTest();
		lca = exFactor.buildLeadCourseAssociation(setupCm.Id, rank);
		Test.stopTest();

		System.assertEquals(setupCm.Id, lca.Course_Master__c,
		                    'Unexpected value for LCA Course_Master__c');

		System.assertEquals(rank, lca.Last_Associated_Rank__c,
		                    'Unexpected value for LCA Last_Associated_Rank__c');
	}

	/**
	 * @description test the generation of a Subscription List
	 * 	Campaign Member based on existing Campaign, Campaign Member,
	 *  Staged Prospective Student record
	 */
	@isTest
	static void buildSubscriptionMemberTest() {
		Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
		ExplodingLeadsFactory exFactor = new ExplodingLeadsFactory();

		Contact con = [SELECT Id FROM Contact LIMIT 1];
		Campaign camp = [SELECT Id, Channel_Type__c
		                 FROM Campaign
		                 WHERE Name = 'ExplodingLeadsFactory_Test'
		                              LIMIT 1];
		CampaignMember existingCm = new CampaignMember(
			ContactId = con.Id,
			CampaignId = camp.Id
			);
		CampaignMember newCm;

		Test.startTest();
		newCm = exFactor.buildSubscriptionMember(camp, existingCm, sps);
		Test.stopTest();

		System.assertEquals(sps.Lead_Source__c, newCm.Email_Subscription_Source__c,
		'Unexpected value for Campaign Member Email_Subscription_Source__c');

		System.assertEquals(TRUE, newCm.ChannelEmail__c,
		'Unexpected value for Campaign Member ChannelEmail__c');

		System.assertEquals(sps.Lead_Source__c, newCm.SMS_Subscription_Source__c,
		'Unexpected value for Campaign Member SMS_Subscription_Source__c');

		System.assertEquals(TRUE, newCm.ChannelSMS__c,
		'Unexpected value for Campaign Member ChannelSMS__c');

		System.assertEquals(TRUE, newCm.Active__c,
		'Unexpected value for Campaign Member Active__c');
	}
}