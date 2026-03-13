/*******************************************************************************
* @author		Ant Custodio
* @date         23.Aug.2017        
* @description  test class for Admissions_AgentPortalCommsService Web Service Class
* @revision     
*******************************************************************************/
@isTest
public with sharing class Admissions_AgentPortalCommsService_Test {
	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         23.Aug.2017        
	* @description  attempt to post a message
	* @revision     
	*******************************************************************************/
	static testMethod void test_postMessage_HasEnquiry() {
		
		Test.startTest();

			Contact contactRec = StudFirst_TestHelper.createApplicant();
			contactRec.Person_ID_unique__c = '7748372812';
			insert contactRec;

	        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
	        Case caseRec = new  Case(SuppliedName = 'testName',
								SuppliedPhone = '0400000000',
								SuppliedEmail = 'testformEmail@monash.edu',
								ContactId = contactRec.Id,
								RecordTypeId = admissionsRecType );
			insert caseRec;

			ObdAgentPortalCommsRequest.CommsWrapper apMessage = new ObdAgentPortalCommsRequest.CommsWrapper();
			apMessage.enquiryRecordId = caseRec.Id;
			apMessage.callistaPersonId = contactRec.Person_ID_unique__c;
			apMessage.agentOrgUnitId = '';
			apMessage.agencyName = 'testing1';
			apMessage.staffName = 'testing1';
			apMessage.phoneNumber = '23164587987';
			apMessage.messageSubject = 'testing1';
			apMessage.messageBody = 'testing1';
			apMessage.category = 'REQ';
			apMessage.subCategory = 'REQ001';
			apMessage.applicantId = '2341234123412';

			Admissions_AgentPortalCommsService.postMessage(apMessage);

			//make sure a case feed is created
			System.assertEquals(1, [SELECT COUNT() FROM FeedItem WHERE ParentId =: caseRec.Id], 'Case feed (Chatter Post) not created');

		Test.stopTest();
	}

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         23.Aug.2017        
	* @description  attempt to post a message - No Enquiry
	* @revision     
	*******************************************************************************/
	static testMethod void test_postMessage_NoEnquiry() {
		
		Test.startTest();

			Contact contactRec = StudFirst_TestHelper.createApplicant();
			contactRec.Person_ID_unique__c = '7748372812';
			insert contactRec;

			ObdAgentPortalCommsRequest.CommsWrapper apMessage = new ObdAgentPortalCommsRequest.CommsWrapper();
			apMessage.enquiryRecordId = '';
			apMessage.callistaPersonId = contactRec.Person_ID_unique__c;
			apMessage.agentOrgUnitId = '';
			apMessage.agencyName = 'testing1';
			apMessage.staffName = 'testing1';
			apMessage.phoneNumber = '23164587987';
			apMessage.messageSubject = 'testing1';
			apMessage.messageBody = 'testing1';
			apMessage.category = 'REQ';
			apMessage.subCategory = 'REQ001';
			apMessage.applicantId = '2341234123412';

			Admissions_AgentPortalCommsService.postMessage(apMessage);

			//make sure a case is created
			List<Case> caseRequery = [SELECT Id, Category_Level_1__c, Category_Level_2__c FROM Case WHERE ContactId =: contactRec.Id LIMIT 1];
			System.assert(!caseRequery.isEmpty(), 'Case not created');
			//assert that the Custom metadata is mapping correctly
			System.assertEquals('Request', caseRequery[0].Category_Level_1__c, 'Custom Metadata not Mapped Properly');
			System.assertEquals('Packaged courses', caseRequery[0].Category_Level_2__c, 'Custom Metadata not Mapped Properly');

		Test.stopTest();
	}

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         23.Aug.2017        
	* @description  attempt to post a message - Required fields missing
	* @revision     
	*******************************************************************************/
	static testMethod void test_postMessage_MissingFields() {
		
		Test.startTest();

			Contact contactRec = StudFirst_TestHelper.createApplicant();
			contactRec.Person_ID_unique__c = '7748372812';
			insert contactRec;

			ObdAgentPortalCommsRequest.CommsWrapper apMessage = new ObdAgentPortalCommsRequest.CommsWrapper();
			apMessage.enquiryRecordId = '';
			apMessage.callistaPersonId = contactRec.Person_ID_unique__c;
			apMessage.agentOrgUnitId = '';
			apMessage.agencyName = 'testing1';
			apMessage.staffName = 'testing1';
			apMessage.phoneNumber = '23164587987';
			apMessage.messageSubject = '';
			apMessage.messageBody = 'testing1';
			apMessage.category = 'REQ';
			apMessage.subCategory = 'REQ001';
			apMessage.applicantId = '2341234123412';

			Admissions_AgentPortalCommsService.postMessage(apMessage);

			//make sure no case is created because of the missing field
			System.assertEquals(0, [SELECT COUNT() FROM Case WHERE ContactId =: contactRec.Id], 'Case not created');

		Test.stopTest();
	}
}