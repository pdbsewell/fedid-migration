/**
 * @description       : Test class for StagedProspectiveStudentUtil
 * @author            : Nick Guia
 * @date 			  : 06-02-2018
 * @group             : Lead Management
 * @last modified on  : 05-07-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class StagedProspectiveStudentUtil_Test {

	/**
	 * @revision
	 * 	05-07-2023 	Nick Guia 	- added trigger muting wherever applicable
	 */
	@TestSetup
	static void setup() {
		/**
		 * setup global monash account. The getter automatically creates
		 * an Account and injects the id to custom setting, hence the variable is unused
		 */
		TriggerCommon.disableTrigger('Account');
		Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
		TriggerCommon.enableTrigger('Account');

		//create Campaigns
		List<Campaign> campaignList = new List<Campaign>();

		//acquisition campaign
		Campaign acquisition = new Campaign(Name = 'AcquisitionCampaign');
		campaignList.add(acquisition);

		//Event Campaigns
		Campaign eventCampaign = new Campaign(Name = 'EventCampaign');
		campaignList.add(eventCampaign);

		//insert campaigns
		TriggerCommon.disableTrigger('Campaign');
		insert campaignList;
		TriggerCommon.enableTrigger('Campaign');
	}

	/**
	 * @description test get the order of commit (per SObjectType). It is
	 *  extremely important that these objects get comitted in this specific
	 *  order for BaseClass to resolve object relationships accordingly.
	 * @revision
	 * 	05-07-2023 	Nick Guia 	- updated asserts
	 */
	@isTest
	static void getCommitOrderTest() {
		List<Schema.SObjectType> commitOrder;
		List<Schema.SObjectType> commitOrderV2;

		Test.startTest();

		commitOrder = StagedProspectiveStudentUtil.commitOrder;
		commitOrderV2 = StagedProspectiveStudentUtil.commitOrderV2;

		Test.stopTest();

		// call it out if commit order changes without updating the tests
		List<Schema.SObjectType> expectedCommitOrder = new List<Schema.SObjectType>{
			Account.SObjectType,
            Contact.SObjectType,
            Lead.SObjectType,
            Lead_Course_Association__c.SObjectType,
            Campaign.SObjectType,
            CampaignMember.SObjectType,
            Roles__c.SObjectType,
            Channel__c.SObjectType,
            Contact_Qualification__c.SObjectType,
            Case.SObjectType,
            Staged_Prospective_Student__c.SObjectType
		};

		List<Schema.SObjectType> expectedCommitOrderV2 = new List<Schema.SObjectType>{
			Account.SObjectType,
            Contact.SObjectType,
            Lead.SObjectType,
            Lead_Course_Association__c.SObjectType,
            Campaign.SObjectType,
            CampaignMember.SObjectType,
            Affiliation__c.SObjectType,
            Address__c.SObjectType,
            Email__c.SObjectType,
            Phone__c.SObjectType,
            Social__c.SObjectType,
            Name__c.SObjectType,
            Contact_Qualification__c.SObjectType,
            Case.SObjectType,
            Staged_Prospective_Student__c.SObjectType
		};

		Assert.areEqual(expectedCommitOrder.size(), commitOrder.size(), 'Unexpected number of SObjectTypes found in commit order');
		Assert.areEqual(expectedCommitOrderV2.size(), commitOrderV2.size(), 'Unexpected number of SObjectTypes found in commit order');

		for(Integer i = 0; i < commitOrder.size(); i++) {
			Assert.areEqual(expectedCommitOrder[i], commitOrder[i], 'Unexpected number of SObjectType found in the commit order');
		}

		for(Integer i = 0; i < commitOrderV2.size(); i++) {
			Assert.areEqual(expectedCommitOrderV2[i], commitOrderV2[i], 'Unexpected number of SObjectType found in the commit order');
		}
	}

	/**
	 * @description test get the object and field mapping from the custom metadata.
	 *  at minimum, Contact, Channel, and Lead SObject field mappings should exist.
	 *  Otherwise, ExplodingLeadsFactory will fail.
	 * @revision
	 * 	05-07-2023 	Nick Guia 	- removed unnecessary getDescribe() calls to improve speed
	 */
	@isTest
	static void getMappingByTargetObjectTest() {
		Map<String, List<Staging_Object_Mapping__mdt> > mapping;

		Test.startTest();
		mapping = StagedProspectiveStudentUtil.mappingByTargetObject;
		Test.stopTest();

		//assert expected objects that should exist in the mapping
		Assert.isTrue(mapping.containsKey('Contact'), 'Mapping for Contact does not exist in Staging_Object_Mapping__mdt');
		Assert.isTrue(mapping.containsKey('Channel__c'), 'Mapping for Channel__c does not exist in Staging_Object_Mapping__mdt');
		Assert.isTrue(mapping.containsKey('Lead'), 'Mapping for Lead does not exist in Staging_Object_Mapping__mdt');
	}

	/**
	 * @description test build the keys to find an existing contact.
	 *  expected:
	 *      'FirstName(lower case):::LastName(lower case):::Email(lowercase)'
	 */
	@isTest
	static void buildMatchingKeyTest() {
		String key = '';
		String fName = 'fName';
		String lName = 'lName';
		String sEmail = 'test@test.org';
		String expectedKey = fName.toLowerCase() + ':::' + lName.toLowerCase() + ':::' + sEmail.toLowerCase();

		Test.startTest();
		key = StagedProspectiveStudentUtil.buildMatchingKey(fName, lName, sEmail);
		Test.stopTest();

		System.assertEquals(expectedKey, key,
		                    'Received an unexpected Key format');
	}

	/**
	 * @description test build the keys to find an existing contact qualification.
	 *  expected:
	 *      'Other_Qualification__c(lower case):::Institution_Name__c(lower case)'
	 */
	@isTest
	static void buildContactQualificationKeyTest() {
		String key = '';
		Contact_Qualification__c cq = new Contact_Qualification__c(
			Other_Qualification__c = 'other',
			Institution_Name__c = 'insName'
			);
		String expectedKey = cq.Other_Qualification__c.toLowerCase() + ':::' + cq.Institution_Name__c.toLowerCase();

		Test.startTest();
		key = StagedProspectiveStudentUtil.buildContactQualificationKey(cq);
		Test.stopTest();

		System.assertEquals(expectedKey, key,
		                    'Received an unexpected Key format');
	}

	/**
	 * @description test process of getting the latest broad areas of interest
	 *  based on SPS Update Mode. This test should overwrite the BAOI from SPS to Lead
	 */
	@isTest
	static void getLatestLeadInterestOverwriteTest() {
		//create test lead
		Lead ldRec = TestHelper.createLeads(1)[0];
		ldRec.Broad_area_s_of_interest__c = 'Engineering;Education';

		//create test sps
		Staged_Prospective_Student__c spsRec = TestHelper.createSps(1)[0];
		spsRec.Broad_area_s_of_interest__c = 'Science';
		spsRec.Broad_Area_of_Interest_Update_Mode__c = 'Overwrite';

		String baoi;

		Test.startTest();
		baoi = StagedProspectiveStudentUtil.getLatestLeadInterest(ldRec, spsRec);
		Test.stopTest();

		System.assertEquals ('Science', baoi,
		                     'Unexpected Broad Area(s) of Interest : ' + baoi + ' . Expecting : Science');
	}

	/**
	 * @description test process of getting the latest broad areas of interest
	 *  based on SPS Update Mode. This test should append the BAOI from SPS to Lead
	 */
	@isTest
	static void getLatestLeadInterestAppendTest() {
		//create test lead
		Lead ldRec = TestHelper.createLeads(1)[0];
		ldRec.Broad_area_s_of_interest__c = 'Engineering;Education';

		//create test sps
		Staged_Prospective_Student__c spsRec = TestHelper.createSps(1)[0];
		spsRec.Broad_area_s_of_interest__c = 'Science';
		spsRec.Broad_Area_of_Interest_Update_Mode__c = 'Append';

		String baoi;

		Test.startTest();
		baoi = StagedProspectiveStudentUtil.getLatestLeadInterest(ldRec, spsRec);
		Test.stopTest();

		System.assertEquals ('Engineering;Education;Science', baoi,
		                     'Unexpected Broad Area(s) of Interest : ' + baoi + ' . Expecting : Engineering;Education;Science');
	}

    /**
     * @description test get the appropriate "Acquisition Source" of a Lead. 
     *  If Acquisition Source Campaign field is populated in SPS, this will be the source,
     *  otherwise, if Event Campaign is present and has only 1 value, this will be taken
     *  as the source.
     */
	@isTest
	static void getAcquisitionSourceCampaignTest() {
		Campaign acq;
		Campaign ev;
		for(Campaign iCmp : [SELECT Id, Name
		                     FROM Campaign
		                     LIMIT 2])
		{
			if(iCmp.Name == 'AcquisitionCampaign') {
				acq = iCmp;
			} else if(iCmp.Name == 'EventCampaign') {
				ev = iCmp;
			}
		}
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(2);
		Staged_Prospective_Student__c spsRecWithAcq = spsList[0];
		spsRecWithAcq.Acquisition_Source_Campaign__c = acq.Id;

		Staged_Prospective_Student__c spsRecNoAcq = spsList[1];
		spsRecNoAcq.Acquisition_Source_Campaign__c = null;
		spsRecNoAcq.Event_Campaigns__c = '' + ev.Id;
		
		Id withAcq;
        Id noAcq;

		Test.startTest();
		withAcq = StagedProspectiveStudentUtil.getAcquisitionSourceCampaign(spsRecWithAcq);
        noAcq = StagedProspectiveStudentUtil.getAcquisitionSourceCampaign(spsRecNoAcq);
		Test.stopTest();

		System.assertEquals(acq.Id, withAcq);
        System.assertEquals(ev.Id, noAcq);
	}

	/**
	 * @description test get the Boolean value of a te
	 */
	@isTest
	static void getBooleanFromTextTest() {
		Boolean tRes; //result expected from true
		Boolean fRes; //result expected from false

		Test.startTest();
		tRes = StagedProspectiveStudentUtil.getBooleanFromText('t');
		fRes = StagedProspectiveStudentUtil.getBooleanFromText('f');
		Test.stopTest();

		System.assertEquals(TRUE, tRes,
		                    'Unexpected return value from getBooleanFromText');
		System.assertEquals(FALSE, fRes,
		                    'Unexpected return value from getBooleanFromText');
	}

    /**
	 * @description test the collection of unique values from String into Set
     *  using a regex delimiter 
	 */
	@isTest
	static void shouldReturnSetofRecordIds() {

		//given
		String randomIds = '7015P000000I81OQAS,7015P000000I81T';
		Set<String> sCollection;

		Test.startTest();

		//when
		sCollection = StagedProspectiveStudentUtil.collectIdsFromString(randomIds);

		Test.stopTest();

		//then
        //we should expect 2 collected IDs
		System.assertEquals(2, sCollection.size(), 'Unexpected number of collected record IDs');
	}
	
	/**
	 * @description test the collection of unique values from String into Set
     *  using a regex delimiter 
	 */
	@isTest
	static void shouldReturnSetofRecordIdsUsingV2() {

		//given
		String randomIds = '7015P000000I81OQAS,7015P000000I81T';
		Set<Id> sCollection;

		Test.startTest();

		//when
		sCollection = StagedProspectiveStudentUtil.collectIdsFromStringV2(randomIds);

		Test.stopTest();

		//then
        //we should expect 2 collected IDs
		System.assertEquals(2, sCollection.size(), 'Unexpected number of collected record IDs');
    }

	/**
	 * @description test the collection of unique values from String into Set
     *  using a regex delimiter 
	 */
	@isTest
	static void shouldErrorWhenInvalidSalesforceId() {

		//given
		String invalidIdStr = '123456,99999';
		Set<String> sCollection;

		Test.startTest();

		//when
		try {
			sCollection = StagedProspectiveStudentUtil.collectIdsFromString(invalidIdStr);
		} catch(Exception e) {
			System.assert(true);
		}

		Test.stopTest();

		//then
        System.assert(sCollection == null, 'Invalid record IDs should not be collected');
    }

	/**
	 * @description test the collection of unique values from String into Set
     *  using a regex delimiter 
	 */
	@isTest
	static void shouldReturnSetFromDelimitedString() {

		//given

		//mix of record IDs and Course Codes should be accepted
		String randomIds = 'A0001,A0002,B001,B002,a0K5P000000XBtQ';
		Set<String> sCollection;

		Test.startTest();

		//when
		sCollection = StagedProspectiveStudentUtil.collectCourseIdsFromString(randomIds);

		Test.stopTest();

		//then
		System.assertEquals(5, sCollection.size(), 'Unexpected number of collected Strings');
    }
}