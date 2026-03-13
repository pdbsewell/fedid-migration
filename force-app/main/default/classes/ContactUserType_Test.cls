/**
* @author Angelo Rivera
* @date 13.01.2020
* @group Test Class
* @description  Test Class to test the functionality of MonConCaseServices
* @revision     APRivera, 13.01.2020 - Created <br/>
*/

@isTest(isParallel=true)
private class ContactUserType_Test {

	@IsTest
	static void testBehavior() {
		Test.startTest();
		Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
		MonConTestDataFactory.createSObject(new Case(), true);

		con.Person_ID_unique__c = '';
		con.SAP_Staff_Id__c = '123245';
		update con;
		MonConTestDataFactory.createSObject(new Case(), true);

		con.Person_ID_unique__c = '';
		con.SAP_Staff_Id__c = '';
		update con;
		MonConTestDataFactory.createSObject(new Case(), true);
		Test.stopTest();

		System.assertEquals(3, [SELECT  count() FROM Case]);
	}
}