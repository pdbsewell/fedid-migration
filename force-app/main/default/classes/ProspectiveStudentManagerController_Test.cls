/**
 * @File Name          : ProspectiveStudentManagerController_Test.cls
 * @Description        : Test Class for ProspectiveStudentManagerController.cls
 * @Author             : Nick Guia
 * @Group              : Lead Management
 **/
@isTest(isParallel=true)
private class ProspectiveStudentManagerController_Test {

	@TestSetup
	static void setup() {
		//Turn on environment settings - Exploding Leads Active
		Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Exploding_Leads_Active__c = true;
		insert envSettings;

		//create a Monash University Global Account record and use ID in custom setting
		Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;

		//create LCA setting for finding latest
		LCA_Grouping_Interval__c lcaSetting = new LCA_Grouping_Interval__c();
        lcaSetting.Time_Interval_In_Seconds__c = 3600;
        insert lcaSetting;

		//create test contact
		List<Contact> conList = TestHelper.createProspectiveStudentContact(1);
		insert conList;

		//create test lead
		List<Lead> leadList = TestHelper.createLeads(1);
		leadList[0].Contact__c = conList[0].Id;
		leadList[0].RecordTypeId = StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT;
		insert leadList;

		//create test courses which will eventually create course masters
		List<Course__c> courseList = new List<Course__c>();
		Integer ctr = 1;
		Set<String> courseCodeSet = new Set<String>();
		for(Course__c iCourse : TestHelper.createCourses(1)) {
			iCourse.Name = 'exLeadTest'+ctr;
			iCourse.Type__c = Label.Course_Type_Course_All;
			iCourse.Course_Code__c = iCourse.Name;
			courseList.add(iCourse);
			courseCodeSet.add(iCourse.Name);
			ctr++;
		}
		insert courseList;

		List<Course_Master__c> cmList = [SELECT Id FROM Course_Master__c LIMIT 1];
		System.assert (!cmList.isEmpty(), 'Unable to generate Course Master records in setup');

		//create LCA's
		List<Lead_Course_Association__c> lcaList = new List<Lead_Course_Association__c>();
		for(Lead_Course_Association__c lca : TestHelper.createLCA(cmList[0].Id, leadList[0].Id, 1)) {
			lca.Associated_Date__c = System.now();
			lca.Last_Associated_Rank__c = 1;
			lcaList.add(lca);
		}
		insert lcaList;

		//create Case
		Case caseRec = new Case(Subject='Test Case', Description='Test data', ContactId = conList[0].Id);
		insert caseRec;
		System.assert (caseRec.Id != null, 'Unable to create setup Case record');
	}

	/**
	 * @description Test create Prospective Student record
	 *  via SPS data structure, where target Contact is not provided
	 */
	@isTest
	static void createProspectiveStudentTest() {
		Id contactId; //expected return vaue
		Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];

		//remove unneeded fields in this process
		spsRec.Contact_Qualification_JSON__c = '';

		Test.startTest();

		ProspectiveStudentManagerController.PsmDTO dto = new ProspectiveStudentManagerController.PsmDTO();
		dto.residencyStatus = 'Australian Citizen';
		dto.educLevel = 'Bachelors';
		dto.conProf = 'Current Student (Dom) [CSD]';
		dto.sps = spsRec;
		contactId = ProspectiveStudentManagerController.createProspectiveStudent(dto);

		Test.stopTest();

		System.assert (contactId != null, 'Unable to create Prospective Student record');
	}

	/**
	 * @description Test create Prospective Student record
	 *  via SPS data structure, where target Contact is not provided.
	 *  Do not provide any email value so that the Contact matching is bypassed,
	 *  resulting to creation of a new contact record
	 */
	@isTest
	static void createProspectiveStudentBypassMatchingTest() {
		//retrieve setup Contact
		List<Contact> existingContactList = [SELECT Id FROM Contact LIMIT 10000];
		System.assert (!existingContactList.isEmpty(), 'Unable to retrieve setup Contact records');
		Id exConId = existingContactList[0].Id;

		Id contactId; //expected return vaue
		Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
		//remove unneeded fields in this process
		spsRec.Email__c = null; //remove email value to bypass matching rule
		spsRec.Contact_Qualification_JSON__c = '';

		Test.startTest();

		ProspectiveStudentManagerController.PsmDTO dto = new ProspectiveStudentManagerController.PsmDTO();
		dto.residencyStatus = 'Australian Citizen';
		dto.educLevel = 'Bachelors';
		dto.conProf = 'Current Student (Dom) [CSD]';
		dto.sps = spsRec;
		contactId = ProspectiveStudentManagerController.createProspectiveStudent(dto);

		Test.stopTest();

		System.assert (contactId != null, 'Unable to create Prospective Student record');
		System.assert (contactId != exConId, 'Unable to bypass matching rule. Prospective Student record without complete First Name, Last Name and Email should always create a new Contact');
	}

	/**
	 * @description Test create Prospective Student Lead record
	 *  via SPS data structure, where target Contact is provided
	 */
	@isTest
	static void createProspectiveStudentLeadTest() {
		Id leadId; //expected return vaue

		//retrieve setup Contact
		List<Contact> conList = [SELECT Id FROM Contact LIMIT 10000];
		System.assert (!conList.isEmpty(), 'Unable to retrieve setup Contact records');
		Id contactId = conList[0].Id;

		Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
		spsRec.Exploded_Target__c = contactId;

		//remove unneeded fields in this process
		spsRec.Contact_Qualification_JSON__c = '';

		Test.startTest();

		ProspectiveStudentManagerController.PsmDTO dto = new ProspectiveStudentManagerController.PsmDTO();
		dto.residencyStatus = 'Australian Citizen';
		dto.educLevel = 'Bachelors';
		dto.conProf = 'Current Student (Dom) [CSD]';
		dto.sps = spsRec;
		leadId = ProspectiveStudentManagerController.createProspectiveStudentLead(dto);

		Test.stopTest();

		System.assert (leadId != null, 'Unable to create Prospective Student Lead record');
	}

	/**
	 * @description Test update Prospective Student Lead and Contact values
	 * via SPS data structure. Target Contact and Lead are provided in SPS
	 */
	@isTest
	static void updateProspectiveStudentTest() {
		String newFirstName = 'New First Name';
		String newLastName = 'New Last Name';

		//retrieve setup Contact
		List<Contact> conList = [SELECT Id FROM Contact LIMIT 10000];
		System.assert (!conList.isEmpty(), 'Unable to retrieve setup Contact records');
		Id contactId = conList[0].Id;

		//retrieve setup Lead
		List<Lead> leadList = [SELECT Id FROM Lead LIMIT 10000];
		System.assert (!leadList.isEmpty(), 'Unable to retrieve setup Lead records');
		Id leadId = leadList[0].Id;

		Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
		spsRec.Exploded_Target__c = contactId;
		spsRec.Exploded_Lead__c = leadId;

		//remove unneeded fields in this process
		spsRec.Contact_Qualification_JSON__c = '';

		//update values
		spsRec.First_Name__c = newFirstName;
		spsRec.Last_Name__c = newLastName;

		Test.startTest();

		ProspectiveStudentManagerController.PsmDTO dto = new ProspectiveStudentManagerController.PsmDTO();
		dto.residencyStatus = 'Australian Citizen';
		dto.educLevel = 'Bachelors';
		dto.conProf = 'Current Student (Dom) [CSD]';
		dto.sps = spsRec;
		ProspectiveStudentManagerController.updateProspectiveStudent(dto);

		Test.stopTest();

		Contact con = [SELECT Id, FirstName, LastName
		               FROM Contact
		               WHERE Id = :contactId
		                          LIMIT 1];
		//verify new contact values
		System.assertEquals(newFirstName, con.FirstName, 'Unable to update Contact FirstName');
		System.assertEquals(newLastName, con.LastName, 'Unable to update Contact LastName');

		//verify new lead values
		Lead ld = [SELECT Id, FirstName, LastName
		           FROM Lead
		           WHERE Id = :leadId
		                      LIMIT 1];
		System.assertEquals(newFirstName, ld.FirstName, 'Unable to update Lead FirstName');
		System.assertEquals(newLastName, ld.LastName, 'Unable to update Lead LastName');
	}

	/**
	 * @description test retrieve Lead Course Association records of a Lead
	 */
	@isTest
	static void getLeadCourseInterestsTest() {
		//retrieve setup Lead
		List<Lead> leadList = [SELECT Id FROM Lead LIMIT 10000];
		System.assert (!leadList.isEmpty(), 'Unable to retrieve setup Lead records');
		Id leadId = leadList[0].Id;

		List<Lead_Course_Association__c> lcaList = new List<Lead_Course_Association__c>();

		Test.startTest();

		lcaList = ProspectiveStudentManagerController.getLeadCourseInterests(leadId);

		Test.stopTest();

		System.assert (!lcaList.isEmpty(), 'Unable to retrieve Lead Course Interests');
	}

	/**
	 * @description test save Lead Course Association via SPS data structure
	 */
	@isTest
	static void saveLeadCourseInterestsTest() {
		Course_Master__c cm = [SELECT Id, Course_Code__c FROM Course_Master__c LIMIT 1];

		//retrieve setup Contact
		List<Contact> conList = [SELECT Id FROM Contact LIMIT 10000];
		System.assert (!conList.isEmpty(), 'Unable to retrieve setup Contact records');
		Id contactId = conList[0].Id;

		Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];
		spsRec.Exploded_Target__c = contactId;

		//remove unneeded fields in this process
		spsRec.Contact_Qualification_JSON__c = '';

		//add course interest
		spsRec.Interested_Course_List__c = cm.Course_Code__c;

		Test.startTest();

		ProspectiveStudentManagerController.saveLeadCourseInterests(spsRec);

		Test.stopTest();

		//verify that an LCA was assigned to the Lead
		Lead leadRec = [SELECT Id,
		                (SELECT Id FROM Lead_Courses_Association__r)
		                FROM Lead
                        WHERE Contact__c = :contactId
                        LIMIT 1];
		System.assert (!leadRec.Lead_Courses_Association__r.isEmpty(), 'Unable to assign LCA to Lead');
	}

	@isTest
	static void getPsDataTest() {
		Case caseRec = [SELECT Id, ContactId, Lead__c FROM Case LIMIT 1];
		ProspectiveStudentManagerController.CaseProspectiveStudent cps;

		Test.startTest();

		cps = ProspectiveStudentManagerController.getPsData(caseRec.Id);

		Test.stopTest();

        System.assert (cps.caseRec != null, 'Unable to retrieve Case details');
        System.assert (cps.contactRec != null, 'Unable to retrieve Contact details');
        System.assert (cps.leadRec != null, 'Unable to retrieve Lead details');
    }
}