/**
 * @author Nick Guia
 * @date 24-03-2022
 * @group Commons
 * @description Test class for CampaignServices
 * @revision
 *  24-03-2022  Nick Guia   - Initial creation
 *  21-03-2025  Vinothraja  - EPCP-4433 updated test class to handle Campaign member status generation for Campaign Type
**/
@isTest(isParallel=true)
public class CampaignServices_Test {
    
    /**
     * @description test coverage for record type ID getters
     */
    @isTest
    static void testGetters() {

        //given

        Id eventRecType;
        Id bmsrecType;
        Id subListRecType;

        Test.startTest();

        //when

        eventRecType = CampaignServices.EVENT_RECTYPE;
        bmsrecType = CampaignServices.BMS_RECTYPE;
        subListRecType = CampaignServices.SUB_LIST_RECTYPE;

        Test.stopTest();

        //then

        Assert.areEqual(
            Schema.SObjectType.Campaign
            .getRecordTypeInfosByDeveloperName()
            .get('Event')
            .getRecordTypeId(), eventRecType,
            'Unexpected record type ID for Event Campaign');

        Assert.areEqual(
            Schema.SObjectType.Campaign
            .getRecordTypeInfosByDeveloperName()
            .get('BMS')
            .getRecordTypeId(), bmsrecType,
            'Unexpected record type ID for BMS Campaign');

        Assert.areEqual(
            Schema.SObjectType.Campaign
            .getRecordTypeInfosByDeveloperName()
            .get('Subscription_List')
            .getRecordTypeId(), subListRecType,
            'Unexpected record type ID for Subscription List Campaign');
    }
    
    /**
     * @description tests setting up of campaign member record type
     */
    @isTest
    static void alignCampainMemberRecordTypestest() {
    	
        //given
        List<Campaign> campaigns = new List<Campaign>();

        Campaign campaignOne = new Campaign();
        campaignOne.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Outbound_Call').getRecordTypeId();
        campaignOne.Name = 'Test Outbound Call campaign';
        campaigns.add(campaignOne);
 
        Campaign campaignTwo = new Campaign();
        campaignTwo.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Advisory').getRecordTypeId();
        campaignTwo.Name = 'Test Advisory Campaign';
        campaigns.add(campaignTwo);

        Campaign campaignThree = new Campaign();
        campaignThree.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
        campaignThree.Name = 'Test MonCon Support Campaign';
        campaigns.add(campaignThree);

        Campaign campaignFour = new Campaign();
        campaignFour.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ERDA_Guest_List').getRecordTypeId();
        campaignFour.Name = 'Test ERDA guest Campaign';
        campaigns.add(campaignFour);
        
        new CampaignServices().alignCampainMemberRecordTypes(campaigns);
        
        for(Campaign camp: campaigns){
            Assert.isNotNull(camp.CampaignMemberRecordTypeID);
        }
        
    }
    
    /**
     * @description tests retrieving campaign status mapping
     */
    @isTest
    static void retrieveStatusMappingTest() {
    
        Map<String, BT_Event_To_Campaign_Status_Mapping__mdt> eventStatusMap = new campaignServices().retrieveStatusMapping();
        
        List<BT_Event_To_Campaign_Status_Mapping__mdt> evntCampStatusMapping = [SELECT Campaign_Status__c,Event_Status__c,Campaign_Active__c
                                                             FROM BT_Event_To_Campaign_Status_Mapping__mdt];
        Assert.areEqual(evntCampStatusMapping.size(), eventStatusMap.size(), 'status mapping returned less results');
    }
    
    /**
     * @description tests retrieving campaign member status by campaign record type
     */
    @isTest
    static void retrieveCampMembStatusesByCampaignRecTypeTest() {
        
        id eventRecType = CampaignServices.EVENT_RECTYPE;
        Map<Id,List<Campaign_Member_Status__mdt>> campMemStatusMap = new campaignServices().retrieveCampMembStatusesByCampaignRecType();
        
        List<Campaign_Member_Status__mdt> cmStatusList = [SELECT Campaign_Record_Type__c, MasterLabel, Has_Responded__c, Is_Default__c 
                                              FROM Campaign_Member_Status__mdt WHERE Campaign_Record_Type__c = 'Event'];
        
        Assert.areEqual(cmStatusList.size(), campMemStatusMap.get(eventRecType)?.size(), 'status mapping for recordType returned less results');
    }
    /**
     * @description tests retrieving campaign member status by campaign type
     */
    @isTest
    static void retrieveCampMembStatusesByCampaignTypeTest() {
        
        // GIVEN
        // A Valid Campaign Type
        String campaignType = 'Domestic Pre App';
        // A List of Campaign Member Statuses
        List<Campaign_Member_Status__mdt> cmStatusList = [SELECT Campaign_Type__c, MasterLabel, Has_Responded__c, Is_Default__c 
                                                            FROM Campaign_Member_Status__mdt 
                                                            WHERE Campaign_Type__c = :campaignType];
        // WHEN
        // We retrieve the Campaign Member Statuses by Campaign Type
        Test.startTest();
            Map<String, List<Campaign_Member_Status__mdt>> campMemStatusMap = new campaignServices().retrieveCampMembStatusesByCampaignType();
        Test.stopTest();
        
        // THEN
        // We expect the number of Campaign Member Statuses to be the same
        Assert.areEqual(cmStatusList.size(), campMemStatusMap.get(campaignType)?.size(), 'status mapping for CampaignType returned less results');
    }
    
}