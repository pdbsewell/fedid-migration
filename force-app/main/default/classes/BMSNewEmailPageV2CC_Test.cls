/**
 * @author           Nick Guia
 * @date             25/08/2017
 * @description      - Test class for BMSNewEmailPageV2CC
 **/
@isTest(isParallel=true)
private class BMSNewEmailPageV2CC_Test {

	@testSetup
	private static void init() {
		//insert CSV templates
		List<Document> templates = new List<Document>();

		Document personIdCSV = new Document();
		personIdCSV.Body = Blob.valueOf('PersonId');
		personIdCSV.ContentType = 'csv';
		//personIdCSV.DeveloperName = 'PersonId_CSV';
		personIdCSV.IsPublic = true;
		personIdCSV.Name = 'PersonId_CSV';
		personIdCSV.FolderId = [SELECT Id FROM Folder WHERE Name = 'BMSLogos'].Id;
		templates.add(personIdCSV);

		Document nameAndEmailCSV = new Document();
		nameAndEmailCSV.Body = Blob.valueOf('Name_Email');
		nameAndEmailCSV.ContentType = 'csv';
		//nameAndEmailCSV.DeveloperName = 'NameAndEmail_CSV';
		nameAndEmailCSV.IsPublic = true;
		nameAndEmailCSV.Name = 'NameAndEmail_CSV';
		nameAndEmailCSV.FolderId = [SELECT Id FROM Folder WHERE Name = 'BMSLogos'].Id;
		templates.add(nameAndEmailCSV);

		insert templates;

		//create a BMS campaign
		Campaign bms = BMS_TestDataHelper.buildSampleCRMMassEmail(null);
		insert bms;
	}

	@isTest static void test_initializeStaticValues() {
		Test.startTest();
		PageReference pageRef = Page.BMSNewEmailPageV2;
		Test.setCurrentPage(pageRef);

		//call static values
		Blob contentFile = BMSNewEmailPageV2CC.contentFile;
		String fileName = BMSNewEmailPageV2CC.fileName;

		//call non-static values
		BMSNewEmailPageV2CC controller = new BMSNewEmailPageV2CC();

		String filterFieldOptionWrapper = controller.filterFieldOptionWrapper;
		System.assert (filterFieldOptionWrapper != null);

		String getAllStaffOptionWrapper = controller.getAllStaffOptionWrapper;
		System.assert (getAllStaffOptionWrapper != null);

		String uOfferingFieldOptionWrapper = controller.uOfferingFieldOptionWrapper;
		System.assert (uOfferingFieldOptionWrapper != null);

		List<SelectOption> cohortOptions = controller.cohortOptions;
		System.assert (!cohortOptions.isEmpty());

		List<SelectOption> emailTemplates = controller.emailTemplates;
		System.assert (!emailTemplates.isEmpty());

		Boolean isAdmin = controller.isAdmin;
		System.assert (isAdmin != null);

		Test.stopTest();
	}

	@isTest static void test_getPicklistValues() {
		Test.startTest();
		//get select option values from 'faculty' field in Contact object
		List<String> facultyOptions = BMSNewEmailPageV2CC.getPickListValues('Contact', 'Faculty__c');
		//check if method returned a value
		System.assert (!facultyOptions.isEmpty());
		Test.stopTest();
	}
	@isTest static void test_buildPreview() {
		BMSNewEmailPageV2CC controller = new BMSNewEmailPageV2CC();
		//build JSON
		BMSUtils.BuildPreviewEmailWrapper bpew = new BMSUtils.BuildPreviewEmailWrapper();
		bpew.emailTemplate = controller.emailTemplates[0].getValue(); //get an email template id from controller
		bpew.name = 'Test Subject';
		bpew.messageHeader = 'Test Header';
		bpew.customMessage = 'Test Message';
		bpew.isAddCricos = true;
		bpew.isAddBaseSignature = true;

		String sJSON = JSON.serialize(bpew);
		Test.startTest();
		String htmlBody = BMSNewEmailPageV2CC.buildPreview(sJSON);
		System.assert (htmlBody != '' && htmlBody != null);
		Test.stopTest();
	}

	@isTest static void test_saveCampaign_Search() {
		//build JSON
		BMSNewEmailPageV2CC controller = new BMSNewEmailPageV2CC();
		BMSUtils.NewEmailSaveWrapper nesw = new BMSUtils.NewEmailSaveWrapper();
		BMSUtils.BuildPreviewEmailWrapper bpew = new BMSUtils.BuildPreviewEmailWrapper();

		//build preview JSON - this is so that we could produce an htmlBody
		bpew.emailTemplate = controller.emailTemplates[0].getValue(); //get an email template id from controller
		bpew.name = 'Test Subject';
		bpew.messageHeader = 'Test Header';
		bpew.customMessage = 'Test Message';
		bpew.isAddCricos = true;
		bpew.isAddBaseSignature = true;
		String sPreviewJSON = JSON.serialize(bpew);
		String htmlBody = BMSNewEmailPageV2CC.buildPreview(sPreviewJSON);

		//create Campaign
		Campaign cmp = new Campaign();
		cmp.Email_Template__c = controller.emailTemplates[0].getValue(); //get an email template id from controller
		cmp.Reply_To__c = 'testemail@monash.edu';
		cmp.Add_CRICOS__c = true;
		cmp.Add_Base_Signature__c = true;
		cmp.Name = 'Test Campaign';
		cmp.Message_Header__c = 'Test Header';
		cmp.Custom_Message__c = 'Test Message';
		cmp.Additional_Email__c = 'testAdditional1@monash.edu testAdditional2@monash.edu'; //delimit by space
		cmp.Notify__c = 'testNotify1@monash.edu;testNotify2@monash.edu'; //delimit by semi colon
		cmp.HTML_Email__c = htmlBody;

		nesw.audienceType = 'search';
		nesw.fileUpload = null;
		nesw.fileName = '';
		nesw.attachmentContent = '';
		nesw.finalQueryString = 'SELECT Id FROM Contact WHERE Faculty__c = \'FACULTY OF ART, DESIGN AND ARCHITECTURE\'';
		nesw.massEmailRecord = cmp;

		String sJSON = JSON.serialize(nesw);
		Test.startTest();
		//test with
		Boolean isSuccess = BMSNewEmailPageV2CC.saveCampaign(sJSON, false);
		System.assert (isSuccess);
		Test.stopTest();
	}

	@isTest static void test_saveCampaign_Upload() {
		PageReference pageRef = Page.BMSNewEmailPageV2;
		Test.setCurrentPage(pageRef);

		//build JSON
		BMSNewEmailPageV2CC controller = new BMSNewEmailPageV2CC();
		BMSUtils.NewEmailSaveWrapper nesw = new BMSUtils.NewEmailSaveWrapper();
		BMSUtils.BuildPreviewEmailWrapper bpew = new BMSUtils.BuildPreviewEmailWrapper();

		//build preview JSON - this is so that we could produce an htmlBody
		bpew.emailTemplate = controller.emailTemplates[0].getValue(); //get an email template id from controller
		bpew.name = 'Test Subject';
		bpew.messageHeader = 'Test Header';
		bpew.customMessage = 'Test Message';
		bpew.isAddCricos = true;
		bpew.isAddBaseSignature = true;
		String sPreviewJSON = JSON.serialize(bpew);
		String htmlBody = BMSNewEmailPageV2CC.buildPreview(sPreviewJSON);
		String strCsvContent = 'PERSON_ID'+'\r\n'+'1234567890'+'\r\n'+'1324567890'+'\r\n'+'1474567890'+'\r\n';
		Blob csvBlob = Blob.valueOf(strCsvContent);
		BMSNewEmailPageV2CC.contentFile = csvBlob;
		BMSNewEmailPageV2CC.fileName = 'Test Upload.csv';

		//create Campaign
		Campaign cmp = new Campaign();
		cmp.Email_Template__c = controller.emailTemplates[0].getValue(); //get an email template id from controller
		cmp.Reply_To__c = 'testemail@monash.edu';
		cmp.Add_CRICOS__c = true;
		cmp.Add_Base_Signature__c = true;
		cmp.Name = 'Test Campaign';
		cmp.Message_Header__c = 'Test Header';
		cmp.Custom_Message__c = 'Test Message';
		cmp.Additional_Email__c = 'testAdditional1@monash.edu testAdditional2@monash.edu'; //delimit by space
		cmp.Notify__c = 'testNotify1@monash.edu;testNotify2@monash.edu'; //delimit by semi colon
		cmp.HTML_Email__c = htmlBody;
		
		nesw.audienceType = 'upload';
		nesw.fileUpload = csvBlob;
		nesw.fileName = 'test.csv';
		nesw.attachmentContent = 'Person ID';
		nesw.massEmailRecord = cmp;

		String sJSON = JSON.serialize(nesw);
		Test.startTest();
		//test with
		Boolean isSuccess = BMSNewEmailPageV2CC.saveCampaign(sJSON, false);
		System.assert (isSuccess);
		Test.stopTest();
	}

	@isTest
	static void shouldReturnCampaignDetailsJSON() {
		//given
		Id bmsRecordType = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
		                   .get(Label.Campaign_Record_Type_BMS)
		                   .getRecordTypeId();
		Campaign bmsRec = [SELECT Id
		                   FROM Campaign
		                   WHERE RecordTypeId = :bmsRecordType
		                                        LIMIT 1];
		String campaignJson;

		Test.startTest();

		//when
		campaignJson = BMSNewEmailPageV2CC.retrieveCampaignDetails(bmsRec.Id);

		Test.stopTest();

		//then
		System.assert (String.isNotBlank(campaignJson), 'Unable to retrieve Campaign JSON String');
	}

	@isTest
	static void testAddUserAsCampaignMember() {
		//given
		Id bmsRecordType = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
		                   .get(Label.Campaign_Record_Type_BMS)
		                   .getRecordTypeId();
		Campaign bmsRec = [SELECT Id
		                   FROM Campaign
		                   WHERE RecordTypeId = :bmsRecordType
		                                        LIMIT 1];
		Boolean isSuccess = false;

		Test.startTest();

		//when
		isSuccess = BMSNewEmailPageV2CC.addUserAsCampaignMember(bmsRec.Id);

		Test.stopTest();

		//then
		Assert.isTrue(isSuccess, 'Unable to add user as Campaign Member');
	}
}