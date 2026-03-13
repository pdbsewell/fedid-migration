/**
 * @description       : test class for StagedProspectiveStudentDAOV2 
 * @author            : Nick Guia
 * @date              : 06-10-2020
 * @group             : Lead Management
 * @last modified on  : 05-07-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class StagedProspectiveStudentDAOV2_Test {

    @TestSetup
    static void makeData(){
        Contact con = new Contact(
            FirstName = 'StagedProspectiveStudentDAOV2_Test',
            LastName = 'test',
            Email = 'test@test.org'
        );
        insert con;

        //create test courses
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
     * @desription test all collection methods of the dao class
     * validate that all necessary information are properly collected within the dao instance
     */
    @isTest
    static void shouldCollectSpsDetails() {
        //given
        List<String> courseCodes = new List<String>();
        for(Course_Master__c iCM : [SELECT Id, Course_Code__c FROM Course_Master__c LIMIT 100]) {
            courseCodes.add(iCM.Course_Code__c);
        }
        Map<String, Campaign> campMap = new Map<String, Campaign>();
        for(Campaign iCamp : [SELECT Id, Name FROM Campaign LIMIT 10]) {
            campMap.put(iCamp.Name, iCamp);
        }
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(2);
        for(Staged_Prospective_Student__c iSps : spsList) {
            iSps.Event_Campaigns__c = ''+campMap.get('EventCampaign').Id;
            iSps.Subscription_Lists__c = ''+campMap.get('SubscriptionCampaign').Id;
            iSps.Acquisition_Source_Campaign__c = ''+campMap.get('AcquisitionCampaign').Id;
            iSps.Interested_Course_List__c = String.join(courseCodes, ',');
        }
        StagedProspectiveStudentDAOV2 dao;

        Test.startTest();

        //when
        dao = new StagedProspectiveStudentDAOV2(spsList[0]);
        dao.addSps(spsList[1]);

        Test.stopTest();

        //then
        System.assert(dao.cqMap != null, 'Unable to collect SPS Contact Qualilfication details');
        System.assert(dao.cqQualNameSet != null, 'Unable to collect SPS Contact Qualilfication details');
        System.assert(dao.cqInsNameSet != null, 'Unable to collect SPS Contact Qualilfication details');
        System.assert(dao.interestedCourseCodes != null, 'Unable to collect SPS Course Interest details');
        System.assert(dao.subscriptionListIDs != null, 'Unable to collect SPS Subscription List details');
        System.assert(dao.eventCampaignIDs != null, 'Unable to collect SPS Event Campaign details');
        System.assert(dao.aSourceCampaignIDs != null, 'Unable to collect SPS Acquisition Source details');
    }

    /**
     * @desription test getters
     */
    @isTest
    static void shouldReturnCollectionFromGetters() {
        //given
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(1);
        StagedProspectiveStudentDAOV2 dao;
        Campaign campRec = [SELECT Id, Name FROM Campaign LIMIT 1];

        Test.startTest();

        //when
        dao = new StagedProspectiveStudentDAOV2(spsList[0]);
        dao.cachedPhoneRecord = new Phone__c();
        dao.interestedCourseCodes = new List<String> { 'A0001', 'A0002', 'A0003' };
        dao.subscriptionListIDs = new Set<Id> { campRec.Id };
        dao.eventCampaignIDs = new Set<Id> { campRec.Id };
        dao.aSourceCampaignIDs = new Set<Id> { campRec.Id };

        //then
        System.assert(dao.getCachedPhone() != null, 'Unable to get cached Phone from DAO class');
        System.assert(dao.getSpsList().size() == 1, 'Unexpected number of SPS records found within the DAO class');
        System.assert(dao.getCourseInterests().size() == 3, 'Unexpected number of Course Codes found within the DAO class');
        System.assert(dao.getQualificationNames().size() == 2, 'Unexpected number of Contact Qualification Names found within the DAO class');
        System.assert(dao.getQualificationInstitutionNames().size() == 2, 'Unexpected number of Contact Qualification Names found within the DAO class');
        System.assert(dao.getContactQualificationMap().size() != null, 'Unexpected number of Contact Qualifications found within the DAO class');
        System.assert(dao.getSubscriptionListIds().size() == 1, 'Unexpected number of subscription list Ids found!');
        System.assert(dao.getEventCampaignIds().size() == 1, 'Unexpected number of event campaign Ids found!');
        System.assert(dao.getAcquisitionSourceIds().size() == 1, 'Unexpected number of acquisition campaign Ids found!');
        System.assert(dao.getmergedSps() != null, 'Unexpected null value for Merged SPS');

        Test.stopTest();
    }

    /**
     * @desription test setters
     */
    @isTest
    static void shouldSetValues() {
        Contact con = [SELECT Id 
                        FROM Contact 
                        WHERE FirstName = 'StagedProspectiveStudentDAOV2_Test' 
                        LIMIT 1];

        Staged_Prospective_Student__c sps = TestHelper.createSps(1)[0];
        sps.Exploded_Target__c = con.Id;

        Campaign campRec = [SELECT Id, Name FROM Campaign LIMIT 1];
        
        StagedProspectiveStudentDAOV2 dao = new StagedProspectiveStudentDAOV2(sps);
        dao.cachedPhoneRecord = new Phone__c();
        dao.interestedCourseCodes = new List<String> { 'A0001', 'A0002', 'A0003' };
        dao.subscriptionListIDs = new Set<Id> { campRec.Id };
        dao.eventCampaignIDs = new Set<Id> { campRec.Id };
        dao.aSourceCampaignIDs = new Set<Id> { campRec.Id };

        Test.startTest();

        //when
        dao.setAffiliation(null)
            .setAddress()
            .setEmail()
            .setMobile()
            .setPhone();
        dao.buildPerson360();

        Test.stopTest();

        //then
        Person360 p360 = dao.p360;
        System.assert(p360 != null, 'Unexpected null value for DAO Person 360');
        System.assert(p360.getAccount() != null, 'Unexpected null value for DAO Account');
        System.assert(p360.getContact() != null, 'Unexpected null value for DAO Contact');
        System.assert(p360.getAffiliation() != null, 'Unexpected null value for DAO Affiliation');
        System.assert(p360.getContactPointMap() != null, 'Unexpected null value for DAO Contact Points');
    }

    /**
     * @desription should add Campaign Members within the DAO instance
     */
    @isTest
    static void shouldAddCampaignMembersToDAO() {
        //given
        Contact con = [SELECT Id 
                        FROM Contact 
                        WHERE FirstName = 'StagedProspectiveStudentDAOV2_Test' 
                        LIMIT 1];
        //create test campaign member to be added to dao later
        CampaignMember subListMember;
        CampaignMember evMember;
        CampaignMember acqMember;
        //get campaign IDs
        String eventId;
        String subId;
        Id acqId;
        for(Campaign iCamp : [SELECT Id, Name FROM Campaign LIMIT 10]) {
            if(iCamp.Name == 'AcquisitionCampaign') {
                acqId = iCamp.Id;
                acqMember = new CampaignMember(CampaignId = iCamp.Id, ContactId = con.Id);
            } else if(iCamp.Name == 'SubscriptionCampaign') {
                subId = (String) iCamp.Id;
                subListMember = new CampaignMember(CampaignId = iCamp.Id, ContactId = con.Id);
            } else if(iCamp.Name == 'EventCampaign') {
                eventId = (String) iCamp.Id;
                evMember = new CampaignMember(CampaignId = iCamp.Id, ContactId = con.Id);
            }
        }
        //add campaign IDs to SPS
        Staged_Prospective_Student__c sps = TestHelper.createSPS(1)[0];
        sps.First_Name__c = 'StagedProspectiveStudentDAOV2_Test';
        sps.Last_Name__c = 'Test';
        sps.Email__c = 'test@test.org';
        sps.Exploded_Target__c = con.Id;
        sps.Event_Campaigns__c = eventId;
        sps.Subscription_Lists__c = subId;
        sps.Acquisition_Source_Campaign__c = acqId;

        StagedProspectiveStudentDAOV2 dao = new StagedProspectiveStudentDAOV2(sps);
        ProspectiveStudentCampaignDAO campaignDAO;

        Test.startTest();

        //when
        dao.addCampaignMember(subListMember);
        dao.addCampaignMember(evMember);
        dao.addCampaignMember(acqMember);
        campaignDAO = dao.campaignDAO;

        Test.stopTest();


        //then
        System.assert(campaignDAO.subscriptionListMembers.containsKey(subId),
            'Unable to add Subscription Member to DAO');
        System.assert(campaignDAO.eventMembers.containsKey(eventId),
            'Unable to add Event Member to DAO');
        System.assert(campaignDAO.acquisitionSourceMembers.containsKey(acqId),
            'Unable to add Acquisition Member to DAO');
    }
}