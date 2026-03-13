/**
 * @File Name          : ProspectiveStudentCampaignDAO_Test.cls
 * @Description        : Test class for ProspectiveStudentCampaignDAO
 * @Author             : Nick Guia
 * @Group              : Lead Management
**/
@isTest(isParallel=true)
private class ProspectiveStudentCampaignDAO_Test {

    @testSetup 
    static void setup() {
        //create Contact
        List<Contact> testConList = TestHelper.createProspectiveStudentContact(1);
        insert testConList;

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

    @isTest
    static void getSubscriptionMembersTest() {
        CampaignMember cm = setupCampaignMember('SubscriptionCampaign');
        Test.startTest();
            ProspectiveStudentCampaignDAO psDao = new ProspectiveStudentCampaignDAO();
            psDao.addSubscriptionMember(cm);
            Map<Id, CampaignMember> subMember = psDao.getSubscriptionMembers();
        Test.stopTest();
        
        System.assert(!subMember.isEmpty(), 'Unable to retrieve Subscription Members');
    }

    @isTest
    static void getEventMembersTest() {
        CampaignMember cm = setupCampaignMember('EventCampaign');
        Test.startTest();
            ProspectiveStudentCampaignDAO psDao = new ProspectiveStudentCampaignDAO();
            psDao.addEventMembers(cm);
            Map<Id, CampaignMember> evMember = psDao.getEventMembers();
        Test.stopTest();
        
        System.assert(!evMember.isEmpty(), 'Unable to retrieve Event Members');
    }

    @isTest
    static void getAcquisitionSourceTest() {
        CampaignMember cm = setupCampaignMember('AcquisitionCampaign');
        Test.startTest();
            ProspectiveStudentCampaignDAO psDao = new ProspectiveStudentCampaignDAO();
            psDao.addAcquisitionSource(cm);
            Map<Id, CampaignMember> acqMember = psDao.getAcquisitionSource();
        Test.stopTest();
        
        System.assert(!acqMember.isEmpty(), 'Unable to retrieve Acquisition Members');
    }

    @isTest
    static void getAllMembersTest() {
        ProspectiveStudentCampaignDAO psDao = new ProspectiveStudentCampaignDAO();
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];
        for(Campaign iCamp : [SELECT Id, Name FROM Campaign LIMIT 3]) {
            CampaignMember cm = new CampaignMember(ContactId = testCon.Id, CampaignId = iCamp.Id);
            if(iCamp.Name == 'AcquisitionCampaign') {
                psDao.addAcquisitionSource(cm);
            } else if(iCamp.Name == 'SubscriptionCampaign') {
                psDao.addSubscriptionMember(cm);
            } else if(iCamp.Name == 'EventCampaign') {
                psDao.addEventMembers(cm);
            }
        }

        Test.startTest();
            Map<Id, CampaignMember> allMembers = psDao.getAllMembers();
        Test.stopTest();
        
        System.assertEquals(allMembers.size(), 3, 'Unexpected number of campaign members found');
    }

    @isTest
    static void addSubscriptionMemberTest() {
        CampaignMember cm = setupCampaignMember('SubscriptionCampaign');
        Test.startTest();
            ProspectiveStudentCampaignDAO psDao = new ProspectiveStudentCampaignDAO();
            psDao.addSubscriptionMember(cm);
        Test.stopTest();
        System.assert(!psDao.subscriptionListMembers.isEmpty(), 'Unable to add a subscription member');
    }

    @isTest
    static void addEventMembersTest() {
        CampaignMember cm = setupCampaignMember('EventCampaign');
        Test.startTest();
            ProspectiveStudentCampaignDAO psDao = new ProspectiveStudentCampaignDAO();
            psDao.addEventMembers(cm);
        Test.stopTest();
        System.assert(!psDao.eventMembers.isEmpty(), 'Unable to add a Event member');
    }

    @isTest
    static void addAcquisitionSourceTest() {
        CampaignMember cm = setupCampaignMember('AcquisitionCampaign');
        Test.startTest();
            ProspectiveStudentCampaignDAO psDao = new ProspectiveStudentCampaignDAO();
            psDao.addAcquisitionSource(cm);
        Test.stopTest();
        System.assert(!psDao.acquisitionSourceMembers.isEmpty(), 'Unable to add a acquisition member');
    }

    @isTest
    static void resolveDependenciesTest() {
        BaseClass bc = new BaseClass(
        new List<Schema.SObjectType> {
            Contact.SObjectType,
            Lead.SObjectType,
            CampaignMember.SObjectType
        });
        //get test contact
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];
        //create test lead
        Lead testLead = TestHelper.createLeads(1)[0];
        bc.push(testLead);

        //create campaign members
        ProspectiveStudentCampaignDAO psDao = new ProspectiveStudentCampaignDAO();
        for(Campaign iCamp : [SELECT Id, Name FROM Campaign LIMIT 3]) {
            CampaignMember cm = new CampaignMember(ContactId = testCon.Id, CampaignId = iCamp.Id);
            if(iCamp.Name == 'AcquisitionCampaign') {
                psDao.addAcquisitionSource(cm);
            } else if(iCamp.Name == 'SubscriptionCampaign') {
                psDao.addSubscriptionMember(cm);
            } else if(iCamp.Name == 'EventCampaign') {
                psDao.addEventMembers(cm);
            }
        }

        Test.startTest();
            psDao.resolveDependencies(bc, testLead);
            bc.commitRecords();
        Test.stopTest();

        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        for(CampaignMember iCm : [SELECT Id, Related_Prospect__c FROM CampaignMember LIMIT 3]) {
            System.assertEquals(leadRec.Id, iCm.Related_Prospect__c, 'Unable to resolve dependency for field Related_Prospect__c');
        }
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