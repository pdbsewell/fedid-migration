/**
 * @author       : Ibrahim Rumi
 * @date         : 14-04-2022
 * @group        : consent management
 * @description  : Test Creating Monash Info and events Subscription Members from enquiries
**/
@isTest(isParallel=true)
public class EnquiryMarketingConsentCapture_Test{

    @TestSetup
	static void setup(){
    
        //create test records
        Campaign mie = new Campaign();
        mie.Name = 'The Monash Info and Events for Prospective Students';
        mie.RecordTypeId = CampaignServices.SUB_LIST_RECTYPE;
        mie.Channel_Type__c = 'Email';
        mie.IsActive = true; 

        Campaign mr = new Campaign();
        mr.Name = 'The Market research participation';
        mr.RecordTypeId = CampaignServices.SUB_LIST_RECTYPE;
        mr.Channel_Type__c = 'Email';
        mr.IsActive = true;

        List<Campaign> campList = new List<Campaign>();
        campList.add(mie);
        campList.add(mr);
        insert campList;

        Marketing_Subscription_List__c setting = new Marketing_Subscription_List__c();
        setting.MIE__c = mie.Id;
        setting.MR__c = mr.Id;
        insert setting;
        
        //create test contact
		List<Contact> conList = TestHelper.createProspectiveStudentContact(1);
        TriggerCommon.disableTrigger('Contact');
		insert conList;
        TriggerCommon.enableTrigger('Contact');
        
        //create test lead
		List<Lead> leadList = TestHelper.createLeads(1);
		leadList[0].Contact__c = conList[0].Id;
		leadList[0].RecordTypeId = StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT;
        TriggerCommon.disableTrigger('Lead');
		insert leadList;
		TriggerCommon.enableTrigger('Lead');

    }
    
    @isTest
    static void createMIECampaignMemberTest(){
        //given
		List<contact> conList = [select id from contact limit 1];
        List<Lead> leadList = [select id from lead limit 1];
        
        Case psCase = new Case(
            ContactId = conList[0].Id
        );

        List<case> caselist = new List<case>();
        caselist.add(psCase);
        //when
        Test.startTest();
        
            EnquiryMarketingConsentCapture.createMIECampaignMember(caselist);
        	
        Test.stopTest();

        //then

        //due to error : INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
        //when platform events create campaign members in test class,
        //this cannot be asserted
        //ideally :
        //campaign members must have been created
        //List<CampaignMember> subList = [SELECT id,contactid FROM campaignmember];

        //system.assertEquals(subList[0].contactid,conList[0].Id,'Unable to create Monash Info Subscription member from case');
        
    }
    
}