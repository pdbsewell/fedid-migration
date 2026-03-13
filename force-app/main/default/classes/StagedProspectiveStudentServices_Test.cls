/**
 * @File Name          : StagedProspectiveStudentServices_Test.cls
 * @Description        : Test class for StagedProspectiveStudentServices.
 * @Author             : Nick Guia
 * @Group              : Lead Management
 */
@IsTest(isParallel=true)
private class StagedProspectiveStudentServices_Test {

	@TestSetup
	static void setup(){
		//Turn on environment settings - Exploding Leads Active
		Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Exploding_Leads_Active__c = true;
		insert envSettings;

		//create a Monash University Global Account record and use ID in custom setting
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
		Campaign eventCampaign = new Campaign(Name = 'EventCampaign');
		campaignList.add(eventCampaign);

		//insert campaigns
		insert campaignList;
	}

	/**
	 * @description test coverage for different constructor parameters
     * 1: List parameter
     * 2: single record parameter
	 */
	@isTest
	static void testConstructors() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(3);
		Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];

		StagedProspectiveStudentServices service1;
		StagedProspectiveStudentServices service2;

		Test.startTest();

		service1 = new StagedProspectiveStudentServices(spsList);
		service2 = new StagedProspectiveStudentServices(spsRec);

		Test.stopTest();

		System.assert (!service1.spsList.isEmpty(),
		               'Unable to initiaise StagedProspectiveStudentServices properly');
        System.assert (!service2.spsList.isEmpty(),
		               'Unable to initiaise StagedProspectiveStudentServices properly');
    }

	/**
	 * @description test service class logic for creating/finding existing
	 *  Contact records based on SPS first name + last name + email
	 */
	@isTest
	static void processProspectiveStudentContactTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);

		Test.startTest();

		StagedProspectiveStudentServices service = new StagedProspectiveStudentServices(spsList);
		spsList = service.processProspectiveStudentContact();

		Test.stopTest();

		for(Staged_Prospective_Student__c iSps : spsList) {
			System.assert (iSps.Exploded_Target__c != null,
			               'Exploding Leads Service Unable to create Contact for SPS');
		}
	}

	/**
	 * @description test all exploding leads processes post-creation of Contact
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
	static void runExplodingLeadsTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(1);
		spsList = setupSPSDependencies(spsList);

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

		//switch on Exploding Leads again
		envSettings.Exploding_Leads_Active__c = true;
		update envSettings;

		Test.startTest();
        
        StagedProspectiveStudentServices service2 = new StagedProspectiveStudentServices(spsList);
		service2.runExplodingLeads();

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