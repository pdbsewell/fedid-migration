/**
 * @File Name          : ExplodingLeadsService_Test.cls   
 * @Description        : Test Class for ExplodingLeadsService
 **/ 
@isTest(isParallel=true)
private class ExplodingLeadsService_Test {

	@TestSetup
	static void setup() {
		//Turn on environment settings - Exploding Leads Active
		Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Exploding_Leads_Active__c = true;
		insert envSettings;

		//setup global monash account
		Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;

		//create Course Masters
		List<Course__c> courseList = new List<Course__c>();
		for(Course__c iCourse : TestHelper.createCourses(1)) {
			iCourse.Type__c = Label.Course_Type_Course_All;
			iCourse.Course_Code__c = iCourse.Name;
			courseList.add(iCourse);
		}
		insert courseList;

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
		Campaign eventCampaign = new Campaign(
			Name = 'EventCampaign',
			RecordTypeId = nonMonRT);
		campaignList.add(eventCampaign);

		//insert campaigns
		insert campaignList;
	}

	/**
	 * @description Test the creation SPS Dao classes to bulk process SPS records
	 */
	@isTest
	static void buildPSContactTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);
		List<StagedProspectiveStudentDAO> processedSpsDAO;

		Test.startTest();

		ExplodingLeadsService exLeads = new ExplodingLeadsService(spsList);
		processedSpsDAO = exLeads.buildPSContact();
		
		Test.stopTest();

		System.assert (processedSpsDAO != null, 'Unable to generate StagedProspectiveStudentDAO');
	}

	/**
	 * @description Test the creation of Contact record (only) out of Exploding Leads.
	 *  The created Contact record should be linked back to the Source SPS record.
	 */
	@isTest
	static void upsertProspectiveStudentContactTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);
		List<StagedProspectiveStudentDAO> processedSpsDAO;
		List<Staged_Prospective_Student__c> processedSps;

		Test.startTest();

		ExplodingLeadsService exLeads = new ExplodingLeadsService(spsList);
		processedSpsDAO = exLeads.buildPSContact();
		processedSps = exLeads.upsertProspectiveStudentContact(processedSpsDAO);

		Test.stopTest();

		for(Staged_Prospective_Student__c iSps : processedSps) {
			System.assert (iSps.Exploded_Target__c != null,
			               'Exploding Leads Service Unable to create Contact for SPS');
		}
	}

	/**
	 * @description Test the initialisation of Exploding Leads.
	 *  property BaseClass and BulkSPSDAO shouldn't be null upon initialisation.
	 */
	@isTest
	static void initialiseExplodingLeadsTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);
		ExplodingLeadsService exLeads;

		Test.startTest();
		exLeads = new ExplodingLeadsService(spsList);
		exLeads.initialiseExplodingLeads();
		Test.stopTest();

		System.assert (exLeads.bc != null,
		               'Unable to initialise ExplodingLeads Base Class');
		System.assert (exLeads.collection!= null,
		               'Unable to initialise ExplodingLeads Bulk Collection DAO');
	}

	/**
	 * @description Test explode the Staging records into actual
	 *  Prospective Student records.
	 *  The process should create the following if the data exists in the SPS
	 *      - Contacts
	 *      - Roles
	 *      - Channels
	 *      - Leads
	 *      - Lead Course Association
	 *      - Campaign Members
	 *      - Contact Qualification
	 *      - Cases
	 */
	@isTest
	static void execute() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);
		spsList = setupSPSDependencies(spsList);

		//first, explode this SPS to create a contact
		ExplodingLeadsService exLeads = new ExplodingLeadsService(spsList);
		List<StagedProspectiveStudentDAO> processedSpsDAO = exLeads.buildPSContact();
		List<Staged_Prospective_Student__c> spsWithContactIds = exLeads.upsertProspectiveStudentContact(processedSpsDAO);
		List<Staged_Prospective_Student__c> explodedSps;
		ExplodingLeadsService service;

		Test.startTest();

		service = new ExplodingLeadsService(spsWithContactIds);
		service.initialiseExplodingLeads();
		service.execute();

		Test.stopTest();

		BulkSPSDAO collection = service.collection;
		List<StagedProspectiveStudentDAO> spsDAOList = collection.getBulkCollectionResult();
		for(StagedProspectiveStudentDAO iDao : spsDAOList) {
			//verify that Contact is created
			System.assert (iDao.getPerson() != null,
			               'Unable to generate a Contact record for SPS');
			//verify that Role was created
			System.assert (iDao.getPersonRole() != null,
			               'Unable to generate a Role record for SPS');
			//verify that Channel was created
			System.assert (iDao.getPersonChannel() != null,
			               'Unable to generate a Channel record for SPS');
			//verify that Lead is created
			System.assert (iDao.getLead() != null,
			               'Unable to generate a Lead record for SPS');
			//verify that Lead Course Association was created
			System.assert (!iDao.getCourseInterests().isEmpty(),
			               'Unable to generate Lead Course Association records for SPS');
			//verify that Campaign Members were created
			System.assert (!iDao.getAllMembers().isEmpty(),
			               'Unable to generate Campaign Member records for SPS');
			//verify that Contact Qualification Qualifications were created
			System.assert (!iDao.getPersonContactQualification().isEmpty(),
			               'Unable to generate Contact Qualification records for SPS');
			//verify that Case was created
			System.assert (!iDao.getProspectiveStudentEnquiries().isEmpty(),
			               'Unable to generate Cases for SPS');
		}
	}

	/**
	 * @description Test explode the Staging records into actual
	 *  Prospective Student records and commit them to the database
	 *  The process should create the following if the data exists in the SPS
	 *      - Contacts
	 *      - Roles
	 *      - Channels
	 *      - Leads
	 *      - Lead Course Association
	 *      - Campaign Members
	 *      - Contact Qualification
	 *      - Cases
	 *  No SPS records should hit a partial error in this test
	 */
	@isTest
	static void commitRecordsTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);
		spsList = setupSPSDependencies(spsList);

		//first, explode this SPS to create a contact
		ExplodingLeadsService exLeads = new ExplodingLeadsService(spsList);
		List<StagedProspectiveStudentDAO> processedSpsDAO = exLeads.buildPSContact();
		List<Staged_Prospective_Student__c> spsWithContactIds = exLeads.upsertProspectiveStudentContact(processedSpsDAO);

		List<Staged_Prospective_Student__c> explodedSps;
		ExplodingLeadsService service;
		Set<Id> partialErrorSpsIDs;

		Test.startTest();

		service = new ExplodingLeadsService(spsWithContactIds);
		service.initialiseExplodingLeads();
		service.execute();
		partialErrorSpsIDs = service.commitRecords();

		Test.stopTest();

		Contact con = [SELECT Id FROM Contact LIMIT 1];
		//verify that Contact is created
		System.assert (con != null,
		               'Unable to generate a Contact record for SPS');

		Roles__c role = [SELECT Id FROM Roles__c WHERE Contact__c = :con.Id LIMIT 1];
		//verify that Role was created
		System.assert (role != null,
		               'Unable to generate a Role record for SPS');

		Channel__c channel = [SELECT Id FROM Channel__c WHERE Contact__c = :con.Id LIMIT 1];
		//verify that Channel was created
		System.assert (channel != null,
		               'Unable to generate a Channel record for SPS');

		Lead leadRec = [SELECT Id FROM Lead WHERE Contact__c = :con.Id LIMIT 1];
		//verify that Lead is created
		System.assert (leadRec != null,
		               'Unable to generate a Lead record for SPS');

		List<Lead_Course_Association__c> lcaList = [SELECT Id FROM Lead_Course_Association__c WHERE Lead__c = :leadRec.Id];
		//verify that Lead Course Association was created
		System.assert (!lcaList.isEmpty(),
		               'Unable to generate Lead Course Association records for SPS');

		List<CampaignMember> cmList = [SELECT Id FROM CampaignMember WHERE ContactId = :con.Id];        //verify that Campaign Members were created
		System.assert (!cmList.isEmpty(),
		               'Unable to generate Campaign Member records for SPS');

		List<Contact_Qualification__c> cqList = [SELECT Id FROM Contact_Qualification__c WHERE Contact__c = :con.Id];
		//verify that Contact Qualification Qualifications were created
		System.assert (!cqList.isEmpty(),
		               'Unable to generate Contact Qualification records for SPS');

		List<Case> caseList = [SELECT Id FROM Case WHERE ContactId = :con.Id];
		//verify that Case was created
		System.assert (!caseList.isEmpty(),
		               'Unable to generate Cases for SPS');

		//verify that no sps records got a Partial Error
		System.assert (partialErrorSpsIDs.isEmpty(),
		               'One or more SPS records encountered an error while processing');
	}

	/**
	 * @description test get the collection of StagedProspectiveStudentDAO mapped
	 *  by Contact ID which is build built after the execute method
	 */
	@isTest
	static void getSpsDAOMapTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);
		spsList = setupSPSDependencies(spsList);

		//first, explode this SPS to create a contact
		ExplodingLeadsService exLeads = new ExplodingLeadsService(spsList);
		List<StagedProspectiveStudentDAO> processedSpsDAO = exLeads.buildPSContact();
		List<Staged_Prospective_Student__c> spsWithContactIds = exLeads.upsertProspectiveStudentContact(processedSpsDAO);

		List<Staged_Prospective_Student__c> explodedSps;
		ExplodingLeadsService service;

		Test.startTest();

		service = new ExplodingLeadsService(spsWithContactIds);
		service.initialiseExplodingLeads();
		service.execute();

		Test.stopTest();

		Map<Id, StagedProspectiveStudentDAO> daoMap = service.getSpsDAOMap();
		for(Staged_Prospective_Student__c iSps : spsWithContactIds) {
			System.assert (daoMap.containsKey(iSps.Exploded_Target__c),
			               'Unable to build an SPS DAO class for SPS record');
		}
	}

	/**
	 * @description test that SPS records are updated with 'Partial Error' status
	 *  when an error occurs while trying to create records (past the creation of Contact)
	 */
	@isTest
	static void updateSPSRecordsTest() {
		//create an sps record that has an invalid information
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);
		spsList = setupSPSDependencies(spsList);
		//update SPS records with invalid Contact qualification JSON to produce a Partial Error scenario
		for(Staged_Prospective_Student__c iSps : spsList) {
			iSps.Contact_Qualification_JSON__c = 'test';
		}

		//first, explode this SPS to create a contact
		ExplodingLeadsService exLeads = new ExplodingLeadsService(spsList);
		List<StagedProspectiveStudentDAO> processedSpsDAO = exLeads.buildPSContact();
		List<Staged_Prospective_Student__c> spsWithContactIds = exLeads.upsertProspectiveStudentContact(processedSpsDAO);

		//switch off exploding leads so it won't process post-contact objects yet
		Environment_Settings__c envSettings = Environment_Settings__c.getOrgDefaults();
		envSettings.Exploding_Leads_Active__c = false;
		update envSettings;
		//insert sps with IDs so that they'll be eligible for updates
		insert spsWithContactIds;

		List<Staged_Prospective_Student__c> explodedSps;
		ExplodingLeadsService service;
		Set<Id> partialErrorSpsIDs;

		Test.startTest();

		//switch on Exploding Leads in this context
		envSettings.Exploding_Leads_Active__c = true;
		update envSettings;

		service = new ExplodingLeadsService(spsWithContactIds);
		service.initialiseExplodingLeads();
		service.execute();
		partialErrorSpsIDs = service.commitRecords();
		service.updateSPSRecords(partialErrorSpsIDs);

		Test.stopTest();

		//query SPS records that got a Partial Error
		List<Staged_Prospective_Student__c> spsErrorList = [SELECT Id, Status__c FROM Staged_Prospective_Student__c WHERE Status__c = 'Partial Error'];
		System.assert (!spsErrorList.isEmpty(),
		               'Failed to commit SPS records with Partial Error');

	}

	/**
	 * @description sets up the following additional data for SPS:
	 * 	- Acquisition Source Campaign
	 * 	- Event Campaign
	 * 	- Subscription List Campaign
	 * 	- Interested Course List (Course Master)
	 * 	- Case details
	 */
	private static List<Staged_Prospective_Student__c> setupSPSDependencies(List<Staged_Prospective_Student__c> spsList) {
		//get course master records
		Map<String, Course_Master__c> cmMap = new Map<String, Course_Master__c>([SELECT Id FROM Course_Master__c]);
		//join Ids by ',' delimiter
		String cmIds = String.join(new List<String>(cmMap.keySet()), ',');

		Campaign acq; //acquisition source campaign
		Campaign event; //Event campaign
		Campaign subList; //subscription list campaign

		//get Campaigns
		for(Campaign iCamp : [SELECT Id, Name FROM Campaign]) {
			if(iCamp.Name == 'AcquisitionCampaign') {
				acq = iCamp;
			} else if(iCamp.Name == 'SubscriptionCampaign') {
				event = iCamp;
			} else if(iCamp.Name == 'EventCampaign') {
				subList = iCamp;
			}
		}

		System.assert (acq != null, 'No setup Acquisition Source Campaign found!');
		System.assert (event != null, 'No setup Subscription List Campaign found!');
		System.assert (subList != null, 'No setup Event Campaign found!');

		//now, populate out setup SPS records with these values
		for(Staged_Prospective_Student__c iSps : spsList) {
			//for LCA
			iSps.Interested_Course_List__c = cmIds;
			//for Campaign Members
			iSps.Acquisition_Source_Campaign__c = acq.Id;
			iSps.Event_Campaigns__c = '' + event.Id;
			iSps.Subscription_Lists__c = '' + subList.Id;
			//for Cases
			iSps.Enquiry_Subject__c = 'Test Case Subject';
			iSps.Enquiry_Description__c = 'Test Case Description';
		}
		return spsList;
    }
}