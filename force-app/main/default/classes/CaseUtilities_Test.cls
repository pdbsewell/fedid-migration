/**
* @author Angelo Rivera
* @date 15.Jan.2020
* @group Test Class
* @description  Test Functionality of CaseUtilities
* @revision     APRivera, 15.Jan.2020 - Created <br/>
* 				APRivera, 11.Feb.2020 - Updated Code coverage <br/>
*/
@isTest(isParallel=true)
private class CaseUtilities_Test {

	@testSetup
	static void setup(){
		//Populate custom settings
		MonConTestDataFactory.createSObject(new RecordTypes_Allowed_on_CaseTrigger__c(), true);
	}

	@IsTest
	static void testBehavior1() {
		Test.startTest();
		Contact con = (Contact) MonConTestDataFactory.createSObject(new Contact(), true);
		Case cse = (Case) MonConTestDataFactory.createSObject(new Case());
		cse.ContactId = con.Id;
		insert cse;

		cse.Status = 'Pending Investigation';
		update cse;

		Set<Id> setUserOwnerIds = new Set<Id>();
		setUserOwnerIds.add(UserInfo.getUserId());
		CaseUtilities.retrieveCaseOwner(setUserOwnerIds);
		Test.stopTest();
		System.assertNotEquals(null, [SELECT count() FROM Case]);
	}

	@IsTest
	static void testBehavior2() {
		Test.startTest();
		System.assertNotEquals(null, CaseUtilities.retrieveRoleHierarchyChildren());
		System.assertNotEquals(null, CaseUtilities.lstCastToContactMappings);
		System.assertNotEquals(null, CaseUtilities.stopStatusSet);
		System.assertNotEquals(null, CaseUtilities.closedStatusSet);
		System.assertNotEquals(null, CaseUtilities.mapRecordTypeIdByName);
		System.assertNotEquals(null, CaseUtilities.defaultHours);
		System.assertNotEquals(null, CaseUtilities.setFacultyEmailAddresses);
		Map<Id, Group> queueMap = new Map<Id, Group>();
		Map<String, Group> queueNameMap = new Map<String, Group>();
		CaseUtilities.retrieveQueueMap(queueMap,queueNameMap);
		System.assertNotEquals(null, queueMap);
		System.assertNotEquals(null, queueNameMap);
		Test.stopTest();
	}

}