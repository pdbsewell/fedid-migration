/**
* @author Angelo Rivera
* @date 07.01.2020
* @group Test Class
* @description  Test Class to test the functionality of SEBSCaseServices
* @revision     APRivera, 09.January.2019 - Created <br/>
*/
@isTest(isParallel=true)
private class SEBSCaseServices_Test {
	@IsTest
	static void testBehavior1() {
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
		Test.startTest();
		cse.RecordTypeId = SEBSCaseServices.SEBS_RECTYPEID;
		cse.Category_3__c = 'Make Up Class';
		cse.Origin = CaseUtilities.ORIGIN_WEB;
		cse.Category_1__c = null;
		cse.Category_2__c = null;
		insert cse;
		Test.stopTest();
		Case c = [SELECT Id, Category_2__c FROM Case LIMIT 1];
		System.assertNotEquals(null, c.Category_2__c);
	}

	@IsTest
	static void testBehavior2() {
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
		Test.startTest();
		cse.RecordTypeId = SEBSCaseServices.SEBS_RECTYPEID;
		cse.Category_3__c = 'Enrolment Number Change';
		cse.Origin = CaseUtilities.ORIGIN_WEB;
		cse.Category_1__c = null;
		cse.Category_2__c = null;
		insert cse;
		Test.stopTest();
		Case c = [SELECT Id, Category_2__c FROM Case LIMIT 1];
		System.assertNotEquals(null, c.Category_2__c);
	}

	@IsTest
	static void testBehavior3() {
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
		Test.startTest();
		cse.RecordTypeId = SEBSCaseServices.SEBS_RECTYPEID;
		cse.Category_3__c = 'Location Change';
		cse.Origin = CaseUtilities.ORIGIN_WEB;
		cse.Category_1__c = null;
		cse.Category_2__c = null;
		insert cse;
		Test.stopTest();
		Case c = [SELECT Id, Category_2__c FROM Case LIMIT 1];
		System.assertNotEquals(null, c.Category_2__c);
	}
}