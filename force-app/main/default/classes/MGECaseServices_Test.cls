/**
* @author Angelo Rivera
* @date 07.01.2020
* @group Test Class
* @description  Test Class to test the functionality of SEBSCaseServices
* @revision     APRivera, 09.January.2019 - Created <br/>
*/

@isTest(isParallel=true)
private class MGECaseServices_Test {
	/**
	 * @author                  Kristian Vegerano
	 * @description             Test method that tests sending email message when the MGE Form stack form is submitted with an attachment
	 */
	@istest
	static void testMgeDefaultValuesIncludeAttachmentOnEmailToFaculty(){
		//Create test contact to associate the enquiry with
		Contact testContact = new Contact(LastName = 'TestContact');
		insert testContact;

		//Create test mge enquiry
		List<Case> enquiryList = new List<Case>();
		for(Integer counter = 0; counter < 5; counter++){
			enquiryList.add(new Case(Subject = 'Test MGE Enquiry',
					ContactId = testContact.Id,
					RecordTypeId = MGECaseServices.MGE_RECTYPEID,
					Origin = CaseUtilities.ORIGIN_WEB_RDR
					//, File_Attachment__c = 'www.testlink.com'
					));
		}
		insert enquiryList;

		//Create test attachments
		List<Attachment> attachmentList = new List<Attachment>();
		for(Case loopCase : enquiryList){
			attachmentList.add(new Attachment(Name = String.valueOf('test.txt'),
					Body = Blob.valueOf('TestAttachmentContent'),
					ParentId = loopCase.Id));
		}
		//Start test
		Test.StartTest();
		//Create test attachments
		insert attachmentList;
		Test.StopTest();

		//Retrieve system email sends actual count after test
		System.assert(0 < [SELECT Id FROM AsyncApexJob].size());
	}
}