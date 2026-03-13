/**
 * @author Nick Guia
 * @date 07-10-2020
 * @group Lead Management
 * @description test class for ExplodingLeadsServiceV2 
 **/
@isTest(isParallel=true)
private class ExplodingLeadsServiceV2_Test {
    
    @TestSetup
    static void makeData(){
        List<Contact> conList = TestHelper.createProspectiveStudentContact(2);
        insert conList;

        //Turn on environment settings - Exploding Leads Active
		Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Exploding_Leads_Active__c = true;
        insert envSettings;

        //create a Monash University Global Account record and use ID in custom setting
        Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
        
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
     * @description test run each exploding Leads step
     */
    @isTest
    static void shouldRunExplodingLeads() {
        //given
        List<Contact> conList = [SELECT Id FROM Contact LIMIT 10];
        List<String> courseCodes = new List<String>();
        for(Course_Master__c iCM : [SELECT Id, Course_Code__c FROM Course_Master__c LIMIT 100]) {
            courseCodes.add(iCM.Course_Code__c);
        }
        Map<String, Campaign> campMap = new Map<String, Campaign>();
        for(Campaign iCamp : [SELECT Id, Name FROM Campaign LIMIT 10]) {
            campMap.put(iCamp.Name, iCamp);
        }
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(2);
        Integer ctr = 0;
        for(Staged_Prospective_Student__c iSps : spsList) {
            iSps.Event_Campaigns__c = ''+campMap.get('EventCampaign').Id;
            iSps.Subscription_Lists__c = ''+campMap.get('SubscriptionCampaign').Id;
            iSps.Acquisition_Source_Campaign__c = ''+campMap.get('AcquisitionCampaign').Id;
            iSps.Interested_Course_List__c = String.join(courseCodes, ',');
            iSps.Exploded_Target__c = conList[ctr].Id;
            ctr++;
        }
        Map<Id, StagedProspectiveStudentDAOV2> daoMap;

        Test.startTest();

        //when
        ExplodingLeadsServiceV2 service = new ExplodingLeadsServiceV2(spsList);
        service.createPerson360()
            .createLeadsAndCourseInterest()
            .createContactQualifications()
            .createCampaignMembers()
            .save();
        daoMap = service.getSpsDaoMap();

        Test.stopTest();

        //then
        System.assert(daoMap.size() == 2, 'Unexpected number of DAO instances found');

        //validate records were created
        for(StagedProspectiveStudentDAOV2 iDao : daoMap.values()) {
            System.assert(iDao.p360 != null, 'Unable to create Person 360 for SPS');
            System.assert(iDao.leadDao != null, 'Unable to create Lead for SPS');
            System.assert(iDao.campaignDAO != null, 'Unable to create Campaign Members for SPS');
            System.assert(iDao.contactQualificationList != null, 'Unable to create Contact Qualifications for SPS');
        }
    }
}