/*******************************************************************************
* @author       Ryan Wilson
* @date         06.04.2017         
* @description  Test class for updating campaign member status
* @revision     
*******************************************************************************/
@isTest(isParallel=true)
private class BMSUpdateCampaignMemStatusBatch_Test {
	
	@isTest(SeeAllData=false) 
	static void UpdateCampaignMemberTest() {
		//insert sample Contacts
        String strKnownToMonashRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Known to Monash systems').getRecordTypeId();
        List<Contact> contactRecordList = BMS_TestDataHelper.buildSampleContacts();
        insert contactRecordList;

        List<Contact> changeContactRecordType = new List<Contact>();
        for (Contact contactRecord: [SELECT Id, RecordTypeId FROM Contact WHERE Id IN: contactRecordList]) {
            contactRecord.RecordTypeId = strKnownToMonashRecTypeId;
            changeContactRecordType.add(contactRecord);
        }

        if (!changeContactRecordType.isEmpty()) {
            update changeContactRecordType;
        }

        Campaign crmEmail = BMS_TestDataHelper.buildSampleCRMMassEmail('Sample Template');
        crmEmail.Type = 'Email';
        insert crmEmail;

        List<CampaignMember> campaignMemberToInsertList = new List<CampaignMember>();
		for (Contact contactRecord: contactRecordList) {
			CampaignMember campaignMemberRec = new CampaignMember();
			campaignMemberRec.ContactId = contactRecord.Id;
			campaignMemberRec.Status = 'Pending Approval';
			campaignMemberRec.CampaignId = crmEmail.id;
			campaignMemberToInsertList.add(campaignMemberRec);
		}
		if (!campaignMemberToInsertList.isEmpty()) {
			insert campaignMemberToInsertList;
		}

        test.startTest();
        crmEmail.Status = 'Approved';
        update crmEmail;

        List<String> campaignIds = new List<String>();
        campaignIds.add(crmEmail.Id);

        BMSUpdateCampaignMemStatusQueueable campaignMemberJob = new BMSUpdateCampaignMemStatusQueueable(campaignIds);
        System.enqueueJob(campaignMemberJob);
		test.stopTest();

        // THEN
        // Campaign member status should be updated to 'Ready to send'
        List<CampaignMember> updatedCampaignMemberList = [SELECT Id, Status FROM CampaignMember WHERE CampaignId IN: campaignIds];
        Assert.areEqual('Ready to Send', updatedCampaignMemberList[0].Status, 'Campaign member status was not updated'); 
	}
	
}