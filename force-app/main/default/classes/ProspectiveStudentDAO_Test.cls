/**
 * @File Name          : ProspectiveStudentDAO_Test.cls
 * @Description        : Test class for ProspectiveStudentDAO
 * @Author             : Nick Guia
 * @Group              : Lead Management
**/
@isTest(isParallel=true)
private class ProspectiveStudentDAO_Test {

    @TestSetup
    static void setup(){
        Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
        
        //create Contact
        List<Contact> testConList = TestHelper.createProspectiveStudentContact(1);
        insert testConList;

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
     * @description test getter/setter of contact in the DAO class
     */
    @isTest
    static void getsetPersonTest() {
        ProspectiveStudentDAO dao;
        Contact con = TestHelper.createProspectiveStudentContact(1)[0];
        Contact daoCon;

        Test.startTest();
            dao = new ProspectiveStudentDAO();
            dao.setPerson(con);
            daoCon = dao.getPerson();
        Test.stopTest();

        System.assert(daoCon != null, 'Unable to get / set ProspectiveStudentDAO contact');
    }

    /**
     * @description test getter/setter of Role in the DAO class
     */
    @isTest
    static void getsetPersonRoleTest() {
        ProspectiveStudentDAO dao = new ProspectiveStudentDAO();
        Contact con = TestHelper.createProspectiveStudentContact(1)[0];
        Roles__c psRole = TestHelper.createRole(con, null);
        Roles__c daoRole;

        Test.startTest();
            dao.setPerson(con);
            dao.setPersonRole(psRole);
            daoRole = dao.getPersonRole();
        Test.stopTest();

        System.assert(daoRole != null, 'Unable to get / set ProspectiveStudentDAO role');
    }

    /**
     * @description test getter/setter of channel in the DAO class
     */
    @isTest
    static void getsetPersonChannelTest() {
        ProspectiveStudentDAO dao = new ProspectiveStudentDAO();
        Contact con = TestHelper.createProspectiveStudentContact(1)[0];
        Channel__c psChannel = TestHelper.createChannel(con);
        Channel__c daoChannel;

        Test.startTest();
            dao.setPerson(con);
            dao.setPersonChannel(psChannel);
            daoChannel = dao.getPersonChannel();
        Test.stopTest();

        System.assert(daoChannel != null, 'Unable to get / set ProspectiveStudentDAO channel');
    }

    /**
     * @description test getter/setter of lead in the DAO class
     */
    @isTest
    static void getsetLeadTest() {
        ProspectiveStudentDAO dao = new ProspectiveStudentDAO();
        Lead psLead = TestHelper.createLeads(1)[0];
        Lead daoLead;

        Test.startTest();
            dao.setLead(psLead);
            daoLead = dao.getLead();
        Test.stopTest();

        System.assert(daoLead != null, 'Unable to get / set ProspectiveStudentDAO lead');
    }

    /**
     * @description test add a single Lead Course Association record 
     *  in the DAO class
     */
    @isTest
    static void addCourseInterestTest() {
        ProspectiveStudentDAO dao = new ProspectiveStudentDAO();
        Lead psLead = TestHelper.createLeads(1)[0];
        dao.setLead(psLead);
        List<Lead_Course_Association__c> daoLca;

        //create Lead Course Association records based on Course Master records
        List<Lead_Course_Association__c> testLcaList = new List<Lead_Course_Association__c>();
        List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
        System.assert(!cmList.isEmpty(), 'Unexpected error occurred. Course Masters were not generated');
        for(Course_Master__c iCm : cmList) {
            //create a Lead Course Association record per Course Master ID
            List<Lead_Course_Association__c> lcaList = TestHelper.createLCA(iCm.Id, null, 1);
            testLcaList.add(lcaList[0]);
        }

        Test.startTest();
            dao.addCourseInterest(testLcaList[0]);
            daoLca = dao.getCourseInterests();
        Test.stopTest();

        System.assertEquals(daoLca.size(), 1, 'Unexpected numbers of LCA in ProspectiveStudentDAO');
    }

    /**
     * @description test setting the list of Lead Course Association
     *  records in the DAO class
     */
    @isTest
    static void setCourseInterestTest() {
        ProspectiveStudentDAO dao = new ProspectiveStudentDAO();
        Lead psLead = TestHelper.createLeads(1)[0];
        dao.setLead(psLead);
        List<Lead_Course_Association__c> daoLca;

        //create Lead Course Association records based on Course Master records
        List<Lead_Course_Association__c> testLcaList = new List<Lead_Course_Association__c>();
        List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
        System.assert(!cmList.isEmpty(), 'Unexpected error occurred. Course Masters were not generated');
        for(Course_Master__c iCm : cmList) {
            //create a Lead Course Association record per Course Master ID
            List<Lead_Course_Association__c> lcaList = TestHelper.createLCA(iCm.Id, null, 1);
            testLcaList.add(lcaList[0]);
        }

        Test.startTest();
            dao.setCourseInterest(testLcaList);
            daoLca = dao.getCourseInterests();
        Test.stopTest();

        System.assertEquals(daoLca.size(), 1, 'Unexpected numbers of LCA in ProspectiveStudentDAO');
    }

    /**
     * @description test get the Lead Course Association from the DAO class
     *  in a map format
     */
    @isTest
    static void getCourseInterestsMapTest() {
        ProspectiveStudentDAO dao = new ProspectiveStudentDAO();
        Lead psLead = TestHelper.createLeads(1)[0];
        dao.setLead(psLead);
        Map<Id, Lead_Course_Association__c> daoLca;

        //create Lead Course Association records based on Course Master records
        List<Lead_Course_Association__c> testLcaList = new List<Lead_Course_Association__c>();
        List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
        System.assert(!cmList.isEmpty(), 'Unexpected error occurred. Course Masters were not generated');
        for(Course_Master__c iCm : cmList) {
            //create a Lead Course Association record per Course Master ID
            List<Lead_Course_Association__c> lcaList = TestHelper.createLCA(iCm.Id, null, 1);
            testLcaList.add(lcaList[0]);
        }

        Test.startTest();
            dao.setCourseInterest(testLcaList);
            daoLca = dao.getCourseInterestsMap();
        Test.stopTest();

        System.assertEquals(daoLca.size(), 1, 'Unexpected numbers of LCA in ProspectiveStudentDAO');
    }

    /**
     * @description test add / get the Subscription Campaign Member
     *  in the DAO class
     */
    @isTest
    static void getAddSubscriptionMemberTest() {
        ProspectiveStudentDAO psDao = new ProspectiveStudentDAO();
        CampaignMember cm = setupCampaignMember('SubscriptionCampaign');
        Map<Id, CampaignMember> cmMap;
        Test.startTest();
            psDao.addSubscriptionMember(cm);
            cmMap = psDao.getSubscriptionMembers();
        Test.stopTest();
        System.assert(!cmMap.isEmpty(), 'Unable to add / get a subscription member');
    }

    /**
     * @description test add / get the Event Campaign Member
     *  in the DAO class
     */
    @isTest
    static void getAddEventMembersTest() {
        ProspectiveStudentDAO psDao = new ProspectiveStudentDAO();
        CampaignMember cm = setupCampaignMember('EventCampaign');
        Map<Id, CampaignMember> cmMap;
        Test.startTest();
            psDao.addEventMembers(cm);
            cmMap = psDao.getEventMembers();
        Test.stopTest();
        System.assert(!cmMap.isEmpty(), 'Unable to add / get an Event member');
    }

    /**
     * @description test add / get the Acquisition Campaign Member
     *  in the DAO class
     */
    @isTest
    static void getAddAcquisitionSourceTest() {
        ProspectiveStudentDAO psDao = new ProspectiveStudentDAO();
        CampaignMember cm = setupCampaignMember('AcquisitionCampaign');
        Map<Id, CampaignMember> cmMap;
        Test.startTest();
            psDao.addAcquisitionSource(cm);
            cmMap = psDao.getAcquisitionSource();
        Test.stopTest();
        System.assert(!cmMap.isEmpty(), 'Unable to get / add an acquisition member');
    }

    /**
     * @description test get all Campaign Members in the DAO class
     */
    @isTest
    static void getAllMembersTest() {
        ProspectiveStudentDAO psDao = new ProspectiveStudentDAO();
        CampaignMember cm = setupCampaignMember('AcquisitionCampaign');
        Map<Id, CampaignMember> cmMap;
        Test.startTest();
            psDao.addAcquisitionSource(cm);
            cmMap = psDao.getAllMembers();
        Test.stopTest();
        System.assert(!cmMap.isEmpty(), 'Unable to get all Campaign Members!');
    }

    /**
     * @description test add / get Contact Qualification records
     *  in the DAO class
     */
    @isTest
    static void getAddPersonContactQualificationTest() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        System.assert(con != null, 'Unable to query test Contact record');

        List<Contact_Qualification__c> cqList = TestHelper.createContactQualifications(1, con.Id);
        System.assert(!cqList.isEmpty(), 'Unable to generate test Contact Qualification records');

        List<Contact_Qualification__c> daoCqList;
        ProspectiveStudentDAO psDao = new ProspectiveStudentDAO();
        
        Test.startTest();
            psDao.addPersonContactQualification(cqList[0]);
            daoCqList = psDao.getPersonContactQualification();
        Test.stopTest();

        System.assert(!daoCqList.isEmpty(), 'Unable to add / get Contact Qualification records');
    }

    /**
     * @description test set the Case record list in the DAO class
     */
    @isTest
    static void setProspectiveStudentEnquiriesTest() {
        List<Case> caseList = TestHelper.webToCaseForms(1);
        ProspectiveStudentDAO psDao = new ProspectiveStudentDAO();

        Test.startTest();
            psDao.setProspectiveStudentEnquiries(caseList);
        Test.stopTest();

        System.assert(!psDao.caseList.isEmpty(), 'Unable to add Enquiry for ProspectiveStudentDAO');
    }

    /**
     * @description test add a single Case record in the DAO class
     */
    @isTest
    static void addProspectiveStudentEnquiryTest() {
        List<Case> caseList = TestHelper.webToCaseForms(1);
        ProspectiveStudentDAO psDao = new ProspectiveStudentDAO();

        Test.startTest();
            psDao.addProspectiveStudentEnquiry(caseList[0]);
        Test.stopTest();

        System.assert(!psDao.caseList.isEmpty(), 'Unable to add Enquiry for ProspectiveStudentDAO');
    }

    /**
     * @description test get the Case record list in the DAO class
     */
    @isTest
    static void getProspectiveStudentEnquiriesTest() {
        List<Case> caseList = TestHelper.webToCaseForms(1);
        ProspectiveStudentDAO psDao = new ProspectiveStudentDAO();
        List<Case> daoCaseList;

        Test.startTest();
            psDao.addProspectiveStudentEnquiry(caseList[0]);
            daoCaseList = psDao.getProspectiveStudentEnquiries();
        Test.stopTest();

        System.assert(!daoCaseList.isEmpty(), 'Unable to add Enquiry for ProspectiveStudentDAO');
    }
    
    /**
     * @description test commit all records in the DAO class with all
     *  dependencies resolved:
     *  - Role and channel related to Contact
     *  - Role related to Global Monash Account
     *  - Channel related to Role
     *  - Lead related to Contact
     *  - LCA related to Lead
     *  - Campaign Member for the contact
     *  - Case related to Contact
     */
    @isTest
    static void resolveDependenciesTest() {
        BaseClass bc = new BaseClass(
            new List<Schema.SObjectType> {
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
            });

        //create Contact
        Contact psCon = TestHelper.createProspectiveStudentContact(1)[0];
        //set different names to ensure it's unique
        psCon.FirstName = 'resolveDependenciesTest';
        psCon.LastName = 'ProspectiveStudentDAO_Test';
        insert psCon;

        //create Roles
        Roles__c psRole = TestHelper.createRole(psCon, null);

        //create Channel
        Channel__c psChannel = TestHelper.createChannel(psCon);

        //create Lead
        Lead psLead = TestHelper.createLeads(1)[0];

        //create Lead Course Association records based on Course Master records
        List<Lead_Course_Association__c> psLcaList = new List<Lead_Course_Association__c>();
        List<Course_Master__c> cmList = [SELECT Id, Name FROM Course_Master__c];
        System.assert(!cmList.isEmpty(), 'Unexpected error occurred. Course Masters were not generated');
        for(Course_Master__c iCm : cmList) {
            //create a Lead Course Association record per Course Master ID
            List<Lead_Course_Association__c> lcaList = TestHelper.createLCA(iCm.Id, null, 1);
            psLcaList.add(lcaList[0]);
        }

        //create Contact Qualification
        List<Contact_Qualification__c> cqList = TestHelper.createContactQualifications(1, null);

        //create Case
        List<Case> caseList = TestHelper.webToCaseForms(1);

        //create campaign member
        CampaignMember cm = setupCampaignMember('AcquisitionCampaign');

        ProspectiveStudentDAO psDao = new ProspectiveStudentDAO();

        Test.startTest();
            psDao.setPerson(psCon);
            psDao.setPersonRole(psRole);
            psDao.setPersonChannel(psChannel);
            psDao.setLead(psLead);
            psDao.setCourseInterest(psLcaList);
            psDao.addAcquisitionSource(cm);
            psDao.addPersonContactQualification(cqList[0]);
            psDao.setProspectiveStudentEnquiries(caseList);
            psDao.resolveDependencies(bc);
            bc.commitRecordsPartial();
        Test.stopTest();

        //assert inserted records

        Roles__c createdRole = [SELECT Id FROM Roles__c LIMIT 1];
        System.assert(createdRole != null, 'Failed to create Role record');

        Channel__c createdChannel = [SELECT Id FROM Channel__c LIMIT 1];
        System.assert(createdChannel != null, 'Failed to create Channel record');

        Lead createdLead = [SELECT Id FROM Lead LIMIT 1];
        System.assert(createdLead != null, 'Failed to create Lead record');

        Lead_Course_Association__c createdLca = [SELECT Id FROM Lead_Course_Association__c LIMIT 1];
        System.assert(createdLca != null, 'Failed to create LCA record');

        Contact_Qualification__c createdCq = [SELECT Id FROM Contact_Qualification__c LIMIT 1];
        System.assert(createdCq != null, 'Failed to create Contact Qualification record');

        Case createdCase = [SELECT Id FROM Case LIMIT 1];
        System.assert(createdCase != null, 'Failed to create Case record');

        CampaignMember createdCm = [SELECT Id FROM CampaignMember LIMIT 1];
        System.assert(createdCm != null, 'Failed to create Campaign Member record');
    }

    private static CampaignMember setupCampaignMember(String campaignName) {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Campaign camp = [SELECT Id 
                        FROM Campaign 
                        WHERE Name = :campaignName
                        LIMIT 1];
        return new CampaignMember(
            ContactId = con.Id,
            CampaignId = camp.Id
        );
    }
}