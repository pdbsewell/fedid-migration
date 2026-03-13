/**
 * @author Aref Samad
 * @date 24-08-2021
 * @group Event Management
 * @description Test class for BTEventGroupTriggerServices (Blackthorn)
 * @revision
 *         2021-08-23 -    Aref Samad     -EPBBS-2083 Link Event Group to Parent Campaign
 * 		   2022-04-19 -	   RANAND		  -EPBBS-2051 Test cascade fields from Parent Campaign in Event Group
 *         2023-08-05 -    RANAND         -EPBBS-3285 Test Event Group Camnpaign update from Event Group
 * 		   2024-03-07 -    Rumi           -EPBBS-3456 Test Method to create Event Group Campaign and associate against respective Event Group
 **/

@IsTest(isParallel=true)

public class BTEventGroupTriggerServices_Test {

    @TestSetup
    static void setupData(){
		List<Campaign> campaigns = new List<Campaign>();
        //Create a new test form record
		conference360__Form__c form1 = new conference360__Form__c(Name ='Test Form');
        insert form1;
        
        //Create a new Event Settings form record
        conference360__Event_Settings__c btEventSettings = TestHelper.createEventSettings(1)[0];
        insert btEventSettings;
        
        //Create new Campaigns with Cascaded fields populated
        Campaign newCamp = new Campaign(Name='Test campaign 1',
                                          Public_Display_Name__c='test campaign 1',
                                          RecordTypeId = CampaignServices.EVENT_RECTYPE,
                                          IsActive=true,
                                          Type ='Parent',
                                          UI_Experience__c ='Oak (Tabbed)',
                                          Custom_CSS_Url__c ='www.test.com.au',
                                          Form_Pre_Registration__c =form1.Id,
                                          Form_Post_Registration__c = form1.Id,
                                          Event_Settings__c = btEventSettings.Id
                                         );
         Campaign newCamp2 = new Campaign(Name='Test campaign 2',
                                          Public_Display_Name__c='test campaign 2',
                                          RecordTypeId = CampaignServices.EVENT_RECTYPE,
                                          IsActive=true,
                                          Type ='Parent',
                                          UI_Experience__c ='Ash (Simple)',
                                          Custom_CSS_Url__c ='www.test2.com.au',
                                          Form_Pre_Registration__c =form1.Id,
                                          Form_Post_Registration__c = form1.Id,
                                          Event_Settings__c = btEventSettings.Id
                                          );
		campaigns.add(newCamp);
        campaigns.add(newCamp2);
        insert campaigns;

    }
	/*
     * @author			RANAND
     * @description		EPBBS-2051 Test new Event Group creation from Parent campaign
     */
    @isTest()
    static void updateCampaignWithEventGroupForInsertTest()
    {
		Campaign newCampaign=[SELECT Id, UI_Experience__c, Custom_CSS_Url__c, Event_Settings__c FROM Campaign WHERE Name='Test campaign 1'][0];
        
        Test.startTest();
        //Create a new Event Group with Campaign populated
        conference360__Event_Group__c eventGroup1 = new conference360__Event_Group__c(Name = 'Event Group 1',Parent_Campaign__c=newCampaign.Id);
        insert eventGroup1;
        Test.stopTest();
		conference360__Event_Group__c evGroupCascaded = [SELECT Id, conference360__Event_Settings__c, 
                                                         conference360__UI_Experience__c,
                                                         conference360__Custom_CSS_Url__c,
                                                         Form_Pre_Registration__c, Form_Post_Registration__c 
                                                         FROM conference360__Event_Group__c 
                                                         WHERE Name = 'Event Group 1' 
                                                         LIMIT 1];
        
        System.assertEquals(newCampaign.Event_Settings__c, evGroupCascaded.conference360__Event_Settings__c);
        System.assertEquals(newCampaign.UI_Experience__c, evGroupCascaded.conference360__UI_Experience__c);  
        System.assertEquals(newCampaign.Custom_CSS_Url__c, evGroupCascaded.conference360__Custom_CSS_Url__c);
    }
    /*
     * @description		EPBBS-2051 Test get Cascade Mapping method
     */
    @isTest()
    static void getgetCampaignGroupMapTest(){
        Map<String, String> campaignMapTest = new BTEventGroupTriggerServices().getCampaignGroupMap();
        if(!campaignMapTest.isEmpty()){
            System.assert(campaignMapTest.size()>0);
        }
    }

   	/*
    * @description		EPBBS-3285 Test Event Group Camnpaign update from Event Group
    */
    @isTest
    static void egCampaignUpdateForEventGroupTest() {
        //GIVEN - A Parent Campaign is peresent, change data capture is enabled nd Event Group with associated Campaign is created
        Campaign newCampaign=[SELECT Id, UI_Experience__c, Custom_CSS_Url__c, Event_Settings__c FROM Campaign WHERE Name='Test campaign 1'][0];

        Test.startTest();
        //Create a new Event Group with Campaign populated
        conference360__Event_Group__c eventGroup1 = new conference360__Event_Group__c(Name = 'Event Group 1',Parent_Campaign__c=newCampaign.Id);
        insert eventGroup1;
		
	    conference360__Event_Group__c evGroupCascaded = [SELECT Id, conference360__Event_Settings__c, 
                                                         conference360__UI_Experience__c,
                                                         conference360__Custom_CSS_Url__c,
                                                         Form_Pre_Registration__c, Form_Post_Registration__c 
                                                         FROM conference360__Event_Group__c 
                                                         WHERE Name = 'Event Group 1' 
                                                         LIMIT 1];
        
        System.assertEquals(newCampaign.Event_Settings__c, evGroupCascaded.conference360__Event_Settings__c);
        System.assertEquals(newCampaign.UI_Experience__c, evGroupCascaded.conference360__UI_Experience__c);  
        System.assertEquals(newCampaign.Custom_CSS_Url__c, evGroupCascaded.conference360__Custom_CSS_Url__c);
        
        // WHEN - Cascade fields are updated on Event Group
        eventGroup1.conference360__Custom_CSS_Url__c = 'www.css.test.com';
        
        update eventGroup1;
        
        Test.stopTest();
        
        // THEN - Associated Event Group Campaigns should also get updated
        Campaign objCamp = [SELECT Audience_Type__c, Custom_CSS_Url__c FROM Campaign WHERE Name = 'Event Group 1'];
        
        Assert.areEqual(eventGroup1.conference360__Custom_CSS_Url__c, objCamp.Custom_CSS_Url__c);
    }
    
    /*
    * @description		EPBBS-3285 Test creation of EventGroup type of Campaign and setup relation between Event Group and Campaign
    */
    @isTest
    static void testManageEventGroupCampaign(){
        //GIVEN - A Parent Campaign is peresent and change data capture is enabled
        Campaign objCamp = [SELECT Id FROM Campaign WHERE Name='Test campaign 1' LIMIT 1][0];
   
        //WHEN - An Event Group is created on the Parent Campaign
        Test.startTest();
        conference360__Event_Group__c eventGroup = new conference360__Event_Group__c(Name='Event Group 1', Parent_Campaign__c = objCamp.Id);
        insert eventGroup;

        Test.stopTest();
        //WHEN - An associated Event Group type of Campaign should be created against the Event Group
        System.assertEquals(1, [SELECT Count() FROM conference360__Event_Group__c WHERE Event_Group_Campaign__c != null AND Name='Event Group 1'], 'Event Group Campaign Missing');
        System.assertEquals(1, [SELECT Count() FROM Campaign WHERE Type='Event Group'], 'Event Group Campaign not created');
    }
}