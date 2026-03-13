/**
* @author Angelo Rivera
* @date  30.Jan.2017
* @group Test Class
* @description  Test Class for the batch class EnquiryAgeCalculationBatch
* @revision     20/01/2020 - Created. <br/>
*/

@isTest(isParallel=false)
private class CalabrioCallUpdatesBatch_Test {

	@isTest static void CheckActiveCall_Test() {
		//set up custom settings to allow callout
		CalabrioIntegration__c calabrioSetting = new CalabrioIntegration__c();
		calabrioSetting.Name = 'Credentials';
		calabrioSetting.AllowCallout__c = true;
		calabrioSetting.AllowedStaff__c = '';
		calabrioSetting.CalabrioURL__c = 'http://calabrio.ocio.monash.edu/cwfo/apps/Recordings.html?loadContact=';
		calabrioSetting.Client_ID__c = 'e4300af3f0ca487b855031659cac6caa';
		calabrioSetting.Client_Secret__c = '1414625753724c45830316ADDAE08C7C';
		calabrioSetting.AllowedStaff__c = 'eSolutions';
		insert calabrioSetting;

		List<Case> caseList = TestHelper.webToCaseForms(1);
		Id SEBS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SEBS').getRecordTypeId();
		List<String> category3List = new List<String> {  'Location Change','Day/Time Change','Duration Change - Compulsory',
				'Weeks offered change','Delivery Model Change','Enrolment Number Change',
				'Add Class - Compulsory','Add Class - Non Compulsory','Make Up Class',
				'Staff - Unexpected Turnover','Staff - Special Needs', 'Staff - Unavailable', 'Other'
		};

		caseList[0].RecordTypeId = SEBS_RecTypeId;
		caseList[0].Origin = 'Phone';
		caseList[0].Category_3__c = category3List[0];
		if (caseList[0].Category_3__c == 'Other') {
			caseList[0].Other_Reason__c = 'Other Test';
		}

		Test.startTest();
		SingleRequestMock fakeResponse = new SingleRequestMock(200,
				'Complete',
				'{"id": 89301,"startTime": 1481672239000,"callDuration": 205000,"agent": {"lastName": "Eaton","firstName": "Alexandra","username": "aeaton"},"recordingUrl": "/api/rest/recording/contact/89301/recording","hasScreen": false,"hasVoice": true}',
				null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		insert caseList;

		Id taskRecordType = [select id from RecordType where SObjectType = 'Task' and DeveloperName = 'Enquiry' limit 1].id;

		Task t = new task(recordtypeId = taskRecordType,
				subject = 'test',
				WhatId = caseList[0].Id);
		insert t;
		Test.stopTest();

	}

	@isTest static void CalabrioBatchUpdate_Test() {
		List<Case> caseList = TestHelper.webToCaseForms(1);
		Id SEBS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SEBS').getRecordTypeId();
		List<String> category3List = new List<String> {  'Location Change','Day/Time Change','Duration Change - Compulsory',
				'Weeks offered change','Delivery Model Change','Enrolment Number Change',
				'Add Class - Compulsory','Add Class - Non Compulsory','Make Up Class',
				'Staff - Unexpected Turnover','Staff - Special Needs', 'Staff - Unavailable', 'Other'
		};

		caseList[0].RecordTypeId = SEBS_RecTypeId;
		caseList[0].Origin = 'Phone';
		caseList[0].Category_3__c = category3List[0];
		if (caseList[0].Category_3__c == 'Other') {
			caseList[0].Other_Reason__c = 'Other Test';
		}

		//set up custom settings
		TestHelper.calabrioSetUp();

		Test.startTest();
		insert caseList;

		Call_Recording__c callRecord = new Call_Recording__c();
		callRecord.Call_Id__c = '89301';
		callRecord.Enquiry__c = caseList[0].Id;
		insert callRecord;

		SingleRequestMock fakeResponse = new SingleRequestMock(200,
				'Complete',
				'{"id": 89301,"startTime": 1481672239000,"callDuration": 205000,"agent": {"lastName": "Eaton","firstName": "Alexandra","username": "aeaton"},"recordingUrl": "/api/rest/recording/contact/89301/recording","hasScreen": false,"hasVoice": true}',
				null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);

		String CRON_EXP = '0 0 0 15 3 ? *';
		String jobId = System.schedule('CalabrioCallUpdates',
				CRON_EXP,
				new CalabrioCallUpdatesSC());
		Test.stopTest();
	}
}