/**
 * @File Name          : BulkSPSDAO_Test.cls
 * @Description        : Test Class for BulkSPSDAO
 * @Author             : Nick Guia
 * @Group              : Lead Management
 */
@isTest(isParallel=true)
private class BulkSPSDAO_Test {

	private static final Integer COURSE_MASTER_NUMBER = 1;

	@TestSetup
	static void setup() {

		//create courses which will eventually create course masters
		List<Course__c> courseList = new List<Course__c>();
		Integer ctr = 1;
		Set<String> courseCodeSet = new Set<String>();
		for(Course__c iCourse : TestHelper.createCourses(COURSE_MASTER_NUMBER)) {
			iCourse.Name = 'BulkSPSDAO_Test'+ctr;
			iCourse.Type__c = Label.Course_Type_Course_All;
			iCourse.Course_Code__c = iCourse.Name;
			courseList.add(iCourse);
			courseCodeSet.add(iCourse.Name);
			ctr++;
		}
		insert courseList;

		//retrieve created Course Master from Course trigger
		Course_Master__c setupCm = [SELECT Id, Name
		                            FROM Course_Master__c
		                            WHERE Name = 'BulkSPSDAO_Test1'
		                                         LIMIT 1];

		//create Campaigns
		List<Campaign> campaignList = new List<Campaign>();

		//get non montrack record type ID
		Id nonMonRT = Schema.SObjectType.Campaign
		              .getRecordTypeInfosByDeveloperName()
		              .get('Non_Montrack')
		              .getRecordTypeId();
		//get subscription list record type ID
		Id subsListRT = Schema.SObjectType.Campaign
		                .getRecordTypeInfosByDeveloperName()
		                .get('Subscription_List')
		                .getRecordTypeId();

		//acquisition campaign
		Campaign acquisition = new Campaign(Name = 'AcquisitionCampaign');
		campaignList.add(acquisition);

		//Subscription Campaign
		Campaign subscriptionCampaign = new Campaign(Name = 'SubscriptionCampaign',
		                                             Channel_Type__c = 'Email;SMS',
		                                             RecordTypeId = subsListRT);
		campaignList.add(subscriptionCampaign);

		//Event Campaigns
		Campaign eventCampaign = new Campaign(Name = 'EventCampaign');
		campaignList.add(eventCampaign);

		//insert campaigns
		insert campaignList;

		/**
		 * create a test SPS record that already has an Exploded Target (Contact)
		 * this is because BulkSPSDAO is only required after an SPS has success
		 * fully created a corresponding contact
		 */

		//create a test Contact
		List<Contact> conList = TestHelper.createProspectiveStudentContact(1);
		Contact con = conList[0];
		con.FirstName = 'setupPS';
		con.LastName = 'setupPS';
		con.Email = 'setupPS@test.org';
		insert con;

		//insert test Case record
		Case caseRec = new Case(
			ContactId = con.Id,
			Subject = 'BulkSPSDAO_Test',
			Description = 'BulkSPSDAO_Test'
			);
		insert caseRec;

		//create SPS record without running exploding leads
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(2);
		Staged_Prospective_Student__c setupSps = spsList[0];
		setupSps.First_Name__c = 'setupPS';
		setupSps.Last_Name__c = 'setupPS';
		setupSps.Email__c = 'setupPS@test.org';
		setupSps.Acquisition_Source_Campaign__c = acquisition.Id;
		setupSps.Event_Campaigns__c = ''+eventCampaign.Id;
		setupSps.Subscription_Lists__c = ''+subscriptionCampaign.Id;
		setupSps.Exploded_Target__c = conList[0].Id;
		setupSps.Exploded_Enquiry__c = caseRec.Id;
		setupSps.Interested_Course_List__c = String.join(new List<String>(courseCodeSet), ',');

		//invalid JSON SPS
		Staged_Prospective_Student__c invalidJSON = spsList[1];
		invalidJSON.First_Name__c = 'invalidJSON';
		invalidJSON.Last_Name__c = 'invalidJSON';
		invalidJSON.Contact_Qualification_JSON__c = '1234{};,.'; //put random characters
		/**
		 * Exploding_Leads_Active__c custom setting must not be true so
		 * we don't unintentoinally run Exploding Leads in this insert
		 */
		insert setupSps;

		//create setup Lead
		Lead setupLead = TestHelper.createLeads(1)[0];
		setupLead.Contact__c = con.Id;
		setupLead.Active_Lead_Contact_Id__c = con.Id;
		setupLead.RecordTypeId = Schema.SObjectType.Lead
		                         .getRecordTypeInfosByName()
		                         .get(Label.Lead_Rectype_ProspectiveStudent)
		                         .getRecordTypeId();
		insert setupLead;

		//create setup LCA
		Lead_Course_Association__c lca = TestHelper.createLCA(setupCm.Id, setupLead.Id, 1)[0];
		insert lca;

		//create setup Role
		Roles__c setupRole = TestHelper.createRole(con, null);
		setupRole.Role__c = Label.Roles_Role_ProspectiveStudent;
		insert setupRole;

		//create setup Channel
		Channel__c setupChannel = TestHelper.createChannel(con);
		setupChannel.Role__c = setupRole.Id;
		insert setupChannel;

		//create Campaign Members
		List<CampaignMember> setupCmList = new List<CampaignMember> {
			new CampaignMember(CampaignId = acquisition.Id, ContactId = con.Id),
			new CampaignMember(CampaignId = subscriptionCampaign.Id, ContactId = con.Id),
			new CampaignMember(CampaignId = eventCampaign.Id, ContactId = con.Id)
		};
		insert setupCmList;
	}

	/**
	 * @description test get all StagedProspectiveStudentDAO objects
	 * 	which got created after the process of collecting all sps information
	 * 	once BulkSPSDAO is constructed.
	 */
	@isTest
	static void getBulkCollectionResultTest() {
		//get setup SPS
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		List<StagedProspectiveStudentDAO> spsDaoList;

		Test.startTest();
		BulkSPSDAO dao = new BulkSPSDAO(spsList);
		spsDaoList = dao.getBulkCollectionResult();
		Test.stopTest();

		//the resulting sps DAO objects should be the same size as setup SPS
		//1 spsDAO = 1 corresponding Exploded Target
		System.assertEquals(spsList.size(), spsDaoList.size(),
		                    'Unexpected number of SPS records found in Bulk Collection');
	}

	/**
	 * @description test get a map version of all StagedProspectiveStudentDAO objects
	 * 	which got created after the process of collecting all sps information
	 * 	once BulkSPSDAO is constructed.
	 */
	@isTest
	static void getBulkCollectionResultMapTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		Map<Id, StagedProspectiveStudentDAO> spsDaoMap;

		Test.startTesT();
		BulkSPSDAO dao = new BulkSPSDAO(spsList);
		spsDaoMap = dao.getBulkCollectionResultMap();
		Test.stopTest();

		//the resulting sps DAO objects should be the same size as setup SPS
		//1 spsDAO = 1 corresponding Exploded Target
		System.assertEquals(spsList.size(), spsDaoMap.size(),
		                    'Unexpected number of SPS records found in Bulk Collection');
		for(Staged_Prospective_Student__c iSps : spsList) {
			System.assert (spsDaoMap.containsKey(iSps.Exploded_Target__c),
			               'Contact ID not found in Bulk SPS collection');
		}
	}

	/**
	 * @description get a collected course master record based on either
	 * 	Course Code, or Course Master ID
	 */
	@isTest
	static void getCourseMasterTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		Course_Master__c setupCm = [SELECT Id, Name
		                            FROM Course_Master__c
		                            WHERE Name = 'BulkSPSDAO_Test1'
		                                         LIMIT 1];
		Course_Master__c cmByCode; //course master to be fetched by Course Code
		Course_Master__c cmById; //course master to be fetched by Course Id

		Test.startTesT();
		BulkSPSDAO dao = new BulkSPSDAO(spsList);
		cmByCode = dao.getCourseMaster('BulkSPSDAO_Test1');
		cmById = dao.getCourseMaster(setupCm.Id);
		Test.stopTest();

		System.assert (cmByCode != null,
		               'Unexpected result while trying to get BulkSPSDAO_Test1 Course Master from collection');
		System.assert (cmById != null,
		               'Unexpected result while trying to get BulkSPSDAO_Test1 Course Master from collection');
		System.assertEquals(cmByCode.Id, cmById.Id,
		                    'Received different Course Master records while getting by name vs ID');
	}

	/**
	 * @description get a collected course master record based on either
	 * 	Course Code, or Course Master ID
	 */
	@isTest
	static void getExistingCampaignTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		Id acqId = spsList[0].Acquisition_Source_Campaign__c;
		//query acquisition source campaign
		Campaign acqCampaign = [SELECT Id
		                        FROM Campaign
		                        WHERE Id = :acqId
		                                   LIMIT 1];
		Campaign daoCampaign;

		Test.startTesT();
		BulkSPSDAO dao = new BulkSPSDAO(spsList);
		daoCampaign = dao.getExistingCampaign(acqId);
		Test.stopTest();

		System.assertEquals(acqId, daoCampaign.Id,
		                    'Unexpected value for Acquisition Source campaign in DAO class');
	}

	/**
	 * @description get a collected Case record based on ID
	 */
	@isTest
	static void getExistingCaseTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		Id caseId = spsList[0].Exploded_Enquiry__c;
		Case caseRec = [SELECT Id
		                FROM Case
		                WHERE ID = :caseId
		                           LIMIT 1];
		Case daoCase;

		Test.startTesT();
		BulkSPSDAO dao = new BulkSPSDAO(spsList);
		daoCase = dao.getExistingCase(caseId);
		Test.stopTest();

		System.assertEquals(caseId, daoCase.Id,
		                    'Unexpected value for Case in DAO class');
	}

	/**
	 * @description get a collected Case record based on ID
	 */
	@isTest
	static void getPartialErrorSpsTest() {
		String filter = ' WHERE First_Name__c = \'invalidJSON\' AND Last_Name__c = \'invalidJSON\' LIMIT 1';
		List<Staged_Prospective_Student__c> invalidJsonSps = getSetupSps(filter);
		List<Staged_Prospective_Student__c> daoInvalidJsonSps;

		Test.startTesT();
		BulkSPSDAO dao = new BulkSPSDAO(invalidJsonSps);
		daoInvalidJsonSps = dao.getPartialErrorSps();
		Test.stopTest();

		System.assertEquals(invalidJsonSps.size(), daoInvalidJsonSps.size(),
		                    'Unexpected number of invalid JSON sps from Bulk Collection');
	}

	/**
	 * @description get all collected contact IDs from SPS based on
	 * 	Exploded_Target__c field
	 */
	@isTest
	static void collectContactIdsTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//number of setup SPS (all with contact IDs) should be the same as the ones from collection
		System.assertEquals(spsList.size(), dao.spsDAOByContactId.size(),
			'Unexpected number of SPS DAO objects received from Bulk Collection');
	}

	/**
	 * @description get all collected subscription list IDs from SPS based on
	 * 	Subscription_Lists__c field
	 */
	@isTest
	static void collectSubListIdsTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//given that setup SPS only has 1 subscription list ID assigned
		System.assertEquals(1, dao.subscriptionListIDs.size(),
			'Unexpected number of Subscription List IDs found from collection');
	}

	/**
	 * @description get all collected event campaign IDs from SPS based on
	 * 	Event_Campaigns__c field
	 */
	@isTest
	static void collectEventCampaignIdsTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//given that setup SPS only has 1 event campaign ID assigned
		System.assertEquals(1, dao.eventCampaignIDs.size(),
			'Unexpected number of Event Campaign IDs found from collection');
	}

	/**
	 * @description get all collected acquisition source campaign IDs from SPS based on
	 * 	Acquisition_Source_Campaign__c field
	 */
	@isTest
	static void collectAcqSrcIdsTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//given that setup SPS only has 1 acquisition source campaign ID assigned
		System.assertEquals(1, dao.aSourceCampaignIDs.size(),
			'Unexpected number of Acquisition Source Campaign IDs found from collection');
	}

	/**
	 * @description get all collected contact qualification information from sps.
	 * 	the contact qualification information is based off Contact_Qualification_JSON__c field
	 * 	which then gets deserialised into List of Contact Qualification SObjects.
	 */
	@isTest
	static void collectContactQualificationTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//given that setup SPS has 2 contact qualifications in the json string
		System.assertEquals(2, dao.qualificationNameSet.size(),
			'Unexpected number of Qualification Names found from collection');
		System.assertEquals(2, dao.qualificationInstitutionNameSet.size(),
			'Unexpected number of Institution Names found from collection');
	}

	/**
	 * @description get all collected course ID/Code from
	 * 	sps.Interested_Course_List__c field
	 */
	@isTest
	static void collectCourseInterestsTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//collected course information should be the same number as created courses in setup
		System.assertEquals(COURSE_MASTER_NUMBER, dao.interestedCourseSet.size(),
			'Unexpected number of Interested Courses found from collection');
	}

	/**
	 * @description get all collected course ID/Code from
	 * 	sps.Interested_Course_List__c field
	 */
	@isTest
	static void collectEnquiryDetailsTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//given that setup SPS has an Exploded_Enquiry__c value
		System.assertEquals(1, dao.existingCaseMap.size(),
			'Unexpected number of Enquiry details found from collection');
	}

	/**
	 * @description test retrieve any existing Lead related to the Contact
	 * 	record of SPS.
	 */
	@isTest
	static void retrieveLeadInformationTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//get the SPS DAO instance of SPS contact
		StagedProspectiveStudentDAO spsDao = dao.spsDAOByContactId.get(spsList[0].Exploded_Target__c);
		//no lead record should exist in this DAO since the existing Contact doesn't have a related Lead yet
		Lead ldRec = spsDao.getLead();
		System.assert(ldRec != null, 'Unexpected value received from retrieving Lead information');
	}

	/**
	 * @description test retrieve the Contact record related to this SPS.
	 * 	In this test, the Contact retrieved should be the same as the Contact
	 * 	related to our setup SPS
	 */
	@isTest
	static void retrieveExistingContactsTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//get the SPS DAO instance of SPS contact
		StagedProspectiveStudentDAO spsDao = dao.spsDAOByContactId.get(spsList[0].Exploded_Target__c);
		//we should be able to retrieve the same contact as the one assigned to sps Exploded_Target__c
		Contact con = spsDao.getPerson();
		System.assertEquals(spsList[0].Exploded_Target__c, con.Id,
		                    'Unexpected value received from retrieving Contact information');
	}

	/**
	 * @description test retrieve the related Prospective Student Role and Channel
	 * 	from the Contact.
	 */
	@isTest
	static void retrieveExistingRolesAndChannelsTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//get the SPS DAO instance of SPS contact
		StagedProspectiveStudentDAO spsDao = dao.spsDAOByContactId.get(spsList[0].Exploded_Target__c);
		//retrieve Role and Channel
		Roles__c roleRec = spsDao.getPersonRole();
		Channel__c channelRec = spsDao.getPersonChannel();
		System.assert(roleRec != null, 'Unexpected value received from retrieving Role information');
		System.assert(channelRec != null, 'Unexpected value received from retrieving Channel information');
	}

	/**
	 * @description test retrieve existing Course Master records based on the 
	 * 	Interested Course List field in SPS. In this test, the number of retrieved information
	 * 	should be the same as our setup records (COURSE_MASTER_NUMBER)
	 */
	@isTest
	static void retrieveCourseMastersTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		System.assertEquals(COURSE_MASTER_NUMBER, dao.courseByCode.size(),
		                    'Unexpected value received from retrieving Course Master by Code');
		System.assertEquals(COURSE_MASTER_NUMBER, dao.courseById.size(),
		                    'Unexpected value received from retrieving Course Master by ID');
	}

	/**
	 * @description test retrieve existing Campaign Member records based on the 
	 * 	Acquisition Source Campaign, Subscription List Campaigns, and Event Campaigns
	 * 	fields in SPS.
	 */
	@isTest
	static void retrieveExistingCampaignMemberTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//get the SPS DAO instance of SPS contact
		StagedProspectiveStudentDAO spsDao = dao.spsDAOByContactId.get(spsList[0].Exploded_Target__c);
		System.assertEquals(3, spsDao.getAllMembers().size(),
		                    'Unexpected value received from retrieving Existing Campaign Members');
	}

	/**
	 * @description test retrieve existing Contact Qualification records based on the 
	 * 	Contact Qualification JSON field from SPS. In this test, no existing Contact Qualification
	 * 	record should exist.
	 */
	@isTest
	static void retrieveExistingContactQualificationsTest() {
		String filter = ' WHERE First_Name__c = \'setupPS\' AND Last_Name__c = \'setupPS\' LIMIT 1';
		List<Staged_Prospective_Student__c> spsList = getSetupSps(filter);
		BulkSPSDAO dao;

		Test.startTesT();
		dao = new BulkSPSDAO(spsList);
		Test.stopTest();

		//get the SPS DAO instance of SPS contact
		StagedProspectiveStudentDAO spsDao = dao.spsDAOByContactId.get(spsList[0].Exploded_Target__c);
		System.assertEquals(0, spsDao.getPersonContactQualification().size(),
		                    'Unexpected value received from retrieving Existing Contact Qualification');
	}

	private static List<Staged_Prospective_Student__c> getSetupSps(String filter) {
		String queryString = CommonUtilities.queryBuilder('Staged_Prospective_Student__c');
		List<Staged_Prospective_Student__c> spsList = Database.query(queryString+filter);
		return spsList;
    }
}