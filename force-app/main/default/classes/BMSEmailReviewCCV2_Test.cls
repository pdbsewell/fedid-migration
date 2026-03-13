/**
* @author           Nick Guia
* @date             07/08/2017
* @description      - Test class for BMSEmailReviewV2
**/

@isTest(isParallel=true)
private class BMSEmailReviewCCV2_Test {

	@testSetup
	private static void init() {
		//insert sample Contacts
        String KnownToMonashRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Known to Monash systems').getRecordTypeId();
        List<Contact> contactRecordList = BMS_TestDataHelper.buildSampleContacts();
        insert contactRecordList;

        List<Contact> changeContactRecordType = new List<Contact>();
        for (Contact contactRecord: [SELECT Id, RecordTypeId FROM Contact WHERE Id IN: contactRecordList]) {
            contactRecord.RecordTypeId = KnownToMonashRecTypeId;
            changeContactRecordType.add(contactRecord);
        }

        if (!changeContactRecordType.isEmpty()) {
            update changeContactRecordType;
        }
        
        Campaign crmMassEmailRecord = BMS_TestDataHelper.buildSampleCRMMassEmail('Student Communication');
        crmMassEmailRecord.Status = 'On Hold';
        insert crmMassEmailRecord;
	}

	@isTest static void test_getPicklistValues() {
		Test.startTest();
	        //user goes to URL
	        /*PageReference pageRef = Page.BulkMessagingSystem;
	        Test.setCurrentPage(pageRef);*/

	        BMSEmailReviewCCV2 controller = new BMSEmailReviewCCV2();

	        List<String> campaignStatusList = controller.campaignStatusList;
	        System.assertEquals(campaignStatusList.size() , 3);

	        List<String> campaignTypeList = controller.campaignTypeList;
	        System.assertEquals(campaignTypeList.size() , 2);
	            
        Test.stopTest();
	}
	
	@isTest static void test_initializeTable() {
		Test.startTest();
	        //user goes to URL
	        /*PageReference pageRef = Page.BulkMessagingSystem;
	        Test.setCurrentPage(pageRef);*/

	        String sJSON = BMSEmailReviewCCV2.initializeTableData();
	        System.assert(sJSON != null);
	            
        Test.stopTest();
	}

	@isTest static void test_approveAll() {
		Set<Id> cmpIds = new Map<Id, Campaign>(
							[SELECT Id FROM Campaign WHERE Status = :Label.Campaign_Status_On_Hold]
						).keySet();

		Test.startTest();
	        //user goes to URL
	        /*PageReference pageRef = Page.BulkMessagingSystem;
	        Test.setCurrentPage(pageRef);*/

	        BMSEmailReviewCCV2.updateCampaignStatus((List<String>) new List<Id>(cmpIds), true);

	        //test if records were approved
	        Boolean allApproved = true;
	        for(Campaign cmpLoop : [SELECT Id, Status FROM Campaign WHERE Id IN :cmpIds]) {
	        	if(cmpLoop.Status != Label.Campaign_Status_Approved) {
	        		allApproved = false;
	        	}
	        }
	        if(allApproved) System.assert(true);
	            
        Test.stopTest();
	}

	@isTest static void test_cancelAll() {
		Set<Id> cmpIds = new Map<Id, Campaign>(
							[SELECT Id FROM Campaign WHERE Status = :Label.Campaign_Status_On_Hold]
						).keySet();
		Test.startTest();
	        //user goes to URL
	        /*PageReference pageRef = Page.BulkMessagingSystem;
	        Test.setCurrentPage(pageRef);*/

	        BMSEmailReviewCCV2.updateCampaignStatus((List<String>) new List<Id>(cmpIds), false);

	        //test if records were approved
	        Boolean allApproved = true;
	        for(Campaign cmpLoop : [SELECT Id, Status FROM Campaign WHERE Id IN :cmpIds]) {
	        	if(cmpLoop.Status != Label.Campaign_Status_Cancelled) {
	        		allApproved = false;
	        	}
	        }
	        if(allApproved) System.assert(true);
	            
        Test.stopTest();
	}
}