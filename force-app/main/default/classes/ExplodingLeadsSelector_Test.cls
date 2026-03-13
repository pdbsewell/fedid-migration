/**
 * @description       : test class for ExplodingLeadsSelector 
 * @author            : Nick Guia
 * @date              : 06-10-2020
 * @group             : Lead Management
 * @last modified on  : 05-07-2023
 * @last modified by  : Nick Guia
 * @revision
 *  05-07-2023  Nick Guia   - Updated asserts and added trigger muting wherever possible
**/
@isTest(isParallel=true)
private class ExplodingLeadsSelector_Test {

    static final Integer CONTACT_SIZE = 1;
    
    /**
	 * @revision
	 * 	05-07-2023 	Nick Guia 	- added trigger muting wherever applicable
	 */
    @TestSetup
    static void makeData(){
        //Turn on environment settings - Exploding Leads Active
		Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Exploding_Leads_Active__c = true;
        insert envSettings;

        /**
		 * setup global monash account. The getter automatically creates
		 * an Account and injects the id to custom setting, hence the variable is unused
		 */
		TriggerCommon.disableTrigger('Account');
        Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
        TriggerCommon.enableTrigger('Account');
        
        //create Mutex record for managing asynchronous Exploding Leads
		Mutex__c mutexRec = new Mutex__c();
		mutexRec.Name = AsyncExplodingLeadsDispatcher.CONFIG_NAME;
		mutexRec.is_Locked__c = false;
		insert mutexRec;
        
        //create test course masters
        List<Course__c> courseList = new List<Course__c>();
		for(Course__c iCourse : TestHelper.createCourses(1)) {
			iCourse.Type__c = Label.Course_Type_Course_All;
			iCourse.Course_Code__c = iCourse.Name;
			courseList.add(iCourse);
		}
		insert courseList;

        //create test campaigns
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
        Campaign acquisition = new Campaign(Name = 'AcquisitionCampaign', RecordTypeId = nonMonRT);
        campaignList.add(acquisition);

        //Subscription Campaign
        Campaign subscriptionCampaign = new Campaign(Name = 'SubscriptionCampaign',
                                                    Channel_Type__c = 'Email;SMS',
                                                    RecordTypeId = subsListRT);
        campaignList.add(subscriptionCampaign);
        
        //Event Campaigns
        Campaign eventCampaign = new Campaign(Name = 'EventCampaign', RecordTypeId = nonMonRT);
        campaignList.add(eventCampaign);
        
        //insert campaigns
        TriggerCommon.disableTrigger('Campaign');
        insert campaignList;
        TriggerCommon.enableTrigger('Campaign');

        /**
         * create a test sps record and run exploding leads (v2)
         * and let it produce all necessary setup records
         */
        Staged_Prospective_Student__c sps = TestHelper.createSPS(CONTACT_SIZE)[0];
        sps.First_Name__c = 'ExplodingLeadsSelector_Test';
        sps.Last_Name__c = 'Test';
        sps.Email__c = 'test@test.org';
        sps.Exploding_Leads_V2__c = true;
        sps.Event_Campaigns__c = ''+eventCampaign.Id;
        sps.Subscription_Lists__c = ''+subscriptionCampaign.Id;
        sps.Acquisition_Source_Campaign__c = acquisition.Id;
        sps.Interested_Course_List__c = courseList[0].Course_Code__c;
        sps.Is_Synchronous__c = true;
        insert sps;

        //TODO - CQ, CM, LEAD, CPA NOT CREATED
    }

    /**
     * @description test query existing Contacts provided the contact IDs
     */
    @isTest
    static void shouldReturnExistingContacts() {
        //given
        Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 100]);
        System.assert(conMap.size() == CONTACT_SIZE, 'Unexpected number of setup Contacts');
        List<Contact> selectorResult;

        Test.startTest();

        //when
        ExplodingLeadsSelector selector = new ExplodingLeadsSelector();
        selectorResult = selector.selectExistingContacts(conMap.keySet());

        Test.stopTest();

        //then
        System.assertEquals(CONTACT_SIZE, selectorResult.size(), 'Unexpected number of records returned by the selector class');
    }

    /**
     * @description test query existing Prospective Student Affiliation related to a Contact
     * and Contact Point Affiliation related to the Affiliation.
     * @revision
	 * 	05-07-2023 	Nick Guia 	- removed CPA tests
     */
    @isTest
    static void shouldReturnExistingAffiliation() {
        //given
        Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 100]);
        System.assert(conMap.size() == CONTACT_SIZE, 'Unexpected number of setup Contacts');
        Map<Id, Affiliation__c> selectorResultAff;

        Test.startTest();

        //when
        ExplodingLeadsSelector selector = new ExplodingLeadsSelector();
        selectorResultAff = new Map<Id, Affiliation__c>(selector.selectProspectAffiliation(conMap.keySet()));

        Test.stopTest();

        //then
        Assert.areEqual(CONTACT_SIZE, selectorResultAff.size(), 'Unexpected number of Affiliation records returned by the selector class');
    }

    /**
     * @description test query existing Leads related to setup Contact
     * and existing LCA's related to the Lead
     */
    @isTest
    static void shouldReturnExistingLeadsAndLCA() {
        //given
        Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 100]);
        System.assert(conMap.size() == CONTACT_SIZE, 'Unexpected number of setup Contacts');
        Map<Id, Lead> selectorResultLead;
        List<Lead_Course_Association__c> selectorResultLCA;

        //get setup course masters
        Set<String> courseCodes = new Set<String>();
        for(Course_Master__c iCM : [SELECT Id, Course_Code__c FROM Course_Master__c LIMIT 100]) {
            courseCodes.add(iCM.Course_Code__c);
        }

        Test.startTest();

        //when
        ExplodingLeadsSelector selector = new ExplodingLeadsSelector();
        selectorResultLead = new Map<Id, Lead>(selector.selectExistingLeads(conMap.keySet()));
        selectorResultLCA = selector.selectExistingLCA(selectorResultLead.keySet(), courseCodes);

        Test.stopTest();

        //then
        System.assertEquals(CONTACT_SIZE, selectorResultLead.size(), 
            'Unexpected number of Lead records returned by the selector class');
        System.assertEquals(1, selectorResultLCA.size(), 
            'Unexpected number of LCA records returned by the selector class');
    }

    /**
     * @description test query existing Contact Qualification related
     * to setup Contacts. TestHelper.createSPS() method would have created
     * 2 Contact Qualification records for the contact
     */
    @isTest
    static void shouldReturnExistingCQ() {
        //given
        Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 100]);
        System.assert(conMap.size() == CONTACT_SIZE, 'Unexpected number of setup Contacts');

        Set<String> qualNames = new Set<String>();
        Set<String> insNames = new Set<String>();
        for(Contact_Qualification__c iCq : [SELECT Id, Contact__c, Other_Qualification__c, Institution_Name__c
                                            FROM Contact_Qualification__c WHERE Contact__c IN :conMap.keySet()])
        {
            qualNames.add(iCq.Other_Qualification__c);
            insNames.add(iCq.Institution_Name__c);
        }
        List<Contact_Qualification__c> selectorResult;

        Test.startTest();

        //when
        ExplodingLeadsSelector selector = new ExplodingLeadsSelector();
        selectorResult = selector.selectExistingContactQualifications(conMap.keySet(), qualNames, insNames);

        Test.stopTest();

        //then
        System.assertEquals(2, selectorResult.size(), 
            'Unexpected number of Contact Qualification records returned by the selector class');
    }

    /**
     * @description test query existing Course Master records.
     * Expecting to have 1 result based on setup records.
     */
    @isTest
    static void shouldReturnExistingCourseMaster() {
        //given
        Set<String> courseCodes = new Set<String>();
        for(Course_Master__c iCM : [SELECT Id, Course_Code__c FROM Course_Master__c LIMIT 100]) {
            courseCodes.add(iCM.Course_Code__c);
        }
        List<Course_Master__c> selectorResult;

        Test.startTest();

        //when
        ExplodingLeadsSelector selector = new ExplodingLeadsSelector();
        selectorResult = selector.selectCourseMasters(courseCodes);

        Test.stopTest();

        //then
        System.assertEquals(1, selectorResult.size(), 
            'Unexpected number of Course Master records returned by the selector class');
    }

    /**
     * @description test query existing Campaign Member records related
     * to setup Contacts
     */
    @isTest
    static void shouldReturnExistingCampaignMembers() {
        //given
        Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 100]);
        Set<Id> campaignIds = (new Map<Id, Campaign>([SELECT Id FROM Campaign])).keySet();
        List<Campaign> selectorResult;

        Test.startTest();

        //when
        ExplodingLeadsSelector selector = new ExplodingLeadsSelector();
        selectorResult =  selector.selectExistingCampaignMember(conMap.keySet(), campaignIds);

        Test.stopTest();

        //then
        System.assertEquals(3, selectorResult.size(),
            'Unexpected number of Campaign records returned by the selector class');
        for(Campaign iCamp : selectorResult) {
            System.assertEquals(1, iCamp.CampaignMembers.size(), 'Unexpected number of campaign members found');
        }
    }

    /**
     * @description test query unprocessed SPS records
     * (used for asynchronous Exploding Leads)
     */
    @isTest
    static void shouldReturnUnprocessedSPS() {
        //given - 5 new SPS recortds are present in system
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(5);
        //turn off trigger so async process won't run just yet
        TriggerCommon.disableTrigger('Staged_Prospective_Student__c');
        insert spsList;
        TriggerCommon.enableTrigger('Staged_Prospective_Student__c');
        List<Staged_Prospective_Student__c> selectorResult;

        Test.startTest();

        //when - the getunprocessedRecords method is called
        ExplodingLeadsSelector selector = new ExplodingLeadsSelector();
        selectorResult = selector.getUnprocessedRecords(50);

        Test.stopTest();

        //then - it should return 5 records with necessary fields
        System.assertEquals(5, selectorResult.size(),
            'Unexpected number of SPS records returned by the selector class');
    }

    /**
     * @description test that the selector returns the expected
     *  Channel record based on Role Id
     */
    @isTest
    static void shouldReturnContactChannelByRoleId() {

        // GIVEN
        List<Channel__c> selectorResult;
        List<Contact> contacts = new List<Contact>([SELECT Id FROM Contact LIMIT 1]);

        TriggerCommon.disableTrigger('Role');
        Roles__c objRole = new Roles__c(
            Contact__c = contacts[0].Id, 
            Role__c = Label.Roles_Role_ProspectiveStudent, 
            Status__c = Label.Roles_Status_Current
        );
		insert objRole;
        TriggerCommon.enableTrigger('Role');

        ExplodingLeadsSelector selector = new ExplodingLeadsSelector();

        Test.startTest();

        // WHEN
        selectorResult = selector.selectContactChannelByRoleId(new Set<Id>{objRole.Id});

        Test.stopTest();

        // THEN
        Assert.isTrue(selectorResult.isEmpty(), 'Channel Role mapping is not available');
    }

    /**
     * @description test that the selector returns the expected
     *  Role record based on Contact Id
     */
    @isTest 
    static void shouldReturnContactRolesByContactId() {

        // GIVEN
        List<Roles__c> selectorResult;
        List<Contact> contacts = new List<Contact>([SELECT Id FROM Contact LIMIT 1]);
        
        TriggerCommon.disableTrigger('Role');
        insert (
            new Roles__c(
                Contact__c = contacts[0].Id, 
                Role__c = Label.Roles_Role_ProspectiveStudent, 
                Status__c = Label.Roles_Status_Current));
		TriggerCommon.enableTrigger('Role');

        ExplodingLeadsSelector selector = new ExplodingLeadsSelector();

        Test.startTest();

        // WHEN
        selectorResult = selector.selectContactRolesByContactId(new Set<Id>{contacts[0].Id});

        Test.stopTest();

        // THEN
        Assert.isFalse(selectorResult.isEmpty(), 'Role query is returning blank');
        Assert.areEqual(Label.Roles_Role_ProspectiveStudent, selectorResult[0].Role__c, 'Role Mismatch');
    }

    /**
     * @description test that the selector returns the expected
     *  Case records record based on Contact Id and Case Id
     */
    @isTest
    static void shouldReturnCasesByContactIdAndCaseId() {

        // GIVEN
        List<Case> selectorResult;
        List<Contact> contacts = new List<Contact>([SELECT Id FROM Contact LIMIT 1]);
        List<Case> cases = TestHelper.webToCaseForms(3);
        for(Case objcase : cases){
            objcase.ContactId = contacts[0].Id;
        }
        TriggerCommon.disableTrigger('Casev2');
        insert cases;
        TriggerCommon.enableTrigger('Casev2');

        ExplodingLeadsSelector selector = new ExplodingLeadsSelector();

        Test.startTest();
        // WHEN
        selectorResult = selector.selectCases(new Set<Id>{contacts[0].Id}, new Set<Id>{cases[0].Id,cases[1].Id, cases[2].Id });

        Test.stopTest();

        // THEN
        Assert.isFalse(selectorResult.isEmpty(), 'Cases are not found');
        Assert.areEqual(3, selectorResult.size(), 'Count of Case mismatch');
    }
}