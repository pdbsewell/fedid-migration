/**
 * @author Nick Guia
 * @date 24-08-2020
 * @group Commons
 * @description Test class for CampaignMemberStatusManager
 *		15-06-2021  Ibrahim Rumi    - EPBBS-1988 updated testmethods to include the new statuses from event Attendee
 *		22-03-2022	Ibrahim Rumi	- EPBBS-2121 updated testmethods to handle updates in CampaignMemberStatusManager
 *		21-03-2025	Vinothraja	    - EPCP-4433  added testmethod to handle Campaign member status generation for Campaign Type
 **/
@isTest(isParallel=true)
private class CampaignMemberStatusManager_Test {

    @TestSetup
    static void setup(){
        //create campaigns
        List<Campaign> campaignList = TestHelper.createEventCampaigns(2, new List<conference360__Event__c>());
        //disable trigger so campaign member statuses won't get created yet
        TriggerCommon.disableTrigger('Campaign');
        insert campaignList;
        TriggerCommon.enableTrigger('Campaign');
    }
    
    /**
     * @description test creation of expected campaign member statuses
     *  for an event type of campaign
     */
    @isTest
    static void campaignMemberStatusGetterTest(){
        map<Id, List<Campaign_Member_Status__mdt>> campMemStatusesMap;
        
        campMemStatusesMap = CampaignMemberStatusManager.campMemStatusesByCampRecType;
        
        id eventRecType = CampaignServices.EVENT_RECTYPE;
        
        List<Campaign_Member_Status__mdt> cmStatusList = [SELECT Campaign_Record_Type__c, MasterLabel, Has_Responded__c, Is_Default__c 
                                                          FROM Campaign_Member_Status__mdt WHERE Campaign_Record_Type__c = 'Event'];
        
        Assert.areEqual(cmStatusList.size(), campMemStatusesMap.get(eventRecType)?.size(), 'status mapping returned less results');
    }
    
     /**
     * @description test creation of expected campaign member statuses
     *  for an event type of campaign
     */
    @isTest
    static void shouldCreateEventMemberStatuses() {

        //given
        Campaign testCamp = [SELECT Id, recordtypeId, Type
                            FROM Campaign 
                            WHERE RecordTypeId = :CampaignServices.EVENT_RECTYPE
                            LIMIT 1];
        
        CommonUtilities.assignCampaignMemberStatus(testCamp.Id);
		
        List<CampaignMemberStatus> precmStatusList = [SELECT Id, Label
                                                    FROM CampaignMemberStatus
                                                    WHERE CampaignId = :testCamp.Id];
        
        Assert.isTrue(!precmStatusList.isEmpty(), 'default status values does not exist');
        
        Set<String> expectedStatuses = new Set<String> {
            'To Invite',
            'Pending',
            'Registered',
            'Canceled',
            'Waitlisted - Pending',
            'Waitlisted - Rejected',
            'Waitlisted - Expired',
            'Attended',
            'No-Show'
        };

        
        Test.startTest();

        //when
        new CampaignMemberStatusManager.Builder(testCamp)
                    .getExistingStatuses()
                    .build()
                    .deletePreviousStatuses();
        

        Test.stopTest();

        //then
        
        List<CampaignMemberStatus> cmStatusList = [SELECT Id, Label
                                                    FROM CampaignMemberStatus
                                                    WHERE CampaignId = :testCamp.Id];
        Assert.isTrue(!cmStatusList.isEmpty(), 'Unable to generate new Campaign Member Statuses');
        for(CampaignMemberStatus iStat : cmStatusList) {
            Assert.isTrue(
                expectedStatuses.contains(iStat.Label), 
                'Unexpected Campaign Member status for Event type : ' + iStat.Label
            );
        }
    }
     /**
     * @description test creation of expected campaign member statuses
     *  for an event type of campaign
     */
    @isTest
    static void shouldCreateEventMemberStatusesForCampaignType() {

        // GIVEN
        //create campaigns
        List<Campaign> campaignList = TestHelper.createEventCampaigns(1, new List<conference360__Event__c>());
        // of type Domestic Post App
        campaignList[0].Type = 'Domestic Post App';
        // expected statuses are a combination of the statuses for EVENT RecordType 
        // and the statuses for the Campaign Type Domestic Post App
        Set<String> expectedStatuses = new Set<String> {
            'Called',
            'Open',
            'Unreachable',
            'Attended',
            'Canceled',
            'No-Show',
            'Pending',
            'Registered',
            'To Invite',	
            'Waitlisted - Pending',
            'Waitlisted - Rejected'
        };

        // WHEN
        // campaigns are created
        Test.startTest();
            insert campaignList;
        Test.stopTest();

        // THEN
        // Campaign Member Statuses are created
        List<CampaignMemberStatus> cmStatusList = [SELECT Id, Label, HasResponded, IsDefault
                                                    FROM CampaignMemberStatus
                                                    WHERE CampaignId = :campaignList[0].Id];
        Assert.isFalse(cmStatusList.isEmpty(), 'Unable to generate new Campaign Member Statuses');
        Assert.isTrue(cmStatusList.size() == expectedStatuses.size(), 'Unexpected number of Campaign Member Statuses');
        // check that the expected statuses are present
        for(CampaignMemberStatus iStat : cmStatusList) {
            Assert.isTrue(expectedStatuses.contains(iStat.Label), 
                                                'Unexpected Campaign Member status for Campaign Type (Domestic Post App) : ' + iStat.Label
            );
            if (iStat.Label == 'Pending') { // Pending status has been retained as default, after resolving duplicate statuses
                Assert.isFalse(iStat.IsDefault, 'Subsequent Campaign Member Default Statuses should be ignored ');
            }
        }
    }
    
    /**
     * @description test creation of handling multiple campaigns
     */
    @isTest
    static void multiCampaignTest() {

        //given
        List<Campaign> testCampList = [SELECT Id, recordtypeId, Type
                                       FROM Campaign 
                                       WHERE RecordTypeId = :CampaignServices.EVENT_RECTYPE];
        
        for(Campaign cm: testCampList){
            CommonUtilities.assignCampaignMemberStatus(cm.Id);
        }
        
        Test.startTest();

        //when
        new CampaignMemberStatusManager.Builder(testCampList)
                    .getExistingStatuses()
                    .build()
                    .deletePreviousStatuses();
        

        Test.stopTest();

        //then
        List<CampaignMemberStatus> cmStatusList = [SELECT Id, Label
                                                    FROM CampaignMemberStatus];
        Assert.isTrue(!cmStatusList.isEmpty(), 'Unable to generate new Campaign Member Statuses');
    }
    
    /**
     * @description test exception handling
     */
    @isTest
    static void exceptionHandlingTest(){
        
        List<campaign> camplist = new List<campaign>();
    	Boolean exceptionThrown = false;
        try{
            new CampaignMemberStatusManager.Builder(camplist)
                    .deletePreviousStatuses()
                    .build();
        }catch(exception e){
            exceptionThrown = true;
        }
        
        Assert.isTrue(exceptionThrown, 'no exception was thrown');
    }
}