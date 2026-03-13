/**
* @author Angelo Rivera
* @date 09.Jan.2020
* @group Test Class
* @description  Test Class to test the functionality of StudentEnquiryFactory
* @revision     APRivera, 09.Jan.2020 - Created <br/>
*/
@isTest(isParallel=true)
private class StudentEnquiryFactory_Test {

	@IsTest
	static void testBehavior() {
		Test.startTest();
		//Create test contact to associate the lead with
		Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
		Contact testContact1 = (Contact)MonConTestDataFactory.createSObject(new Contact());
		testContact1.Person_ID_unique__c = '123456';
		insert testContact1;

		Lead leadRec = (Lead)MonConTestDataFactory.createSObject(new Lead());
		leadRec.Contact__c = testContact.Id;
		insert leadRec;

		Lead leadRec2 = (Lead)MonConTestDataFactory.createSObject(new Lead());
		leadRec2.Student_type__c = Label.Student_Type_International;
		leadRec2.Contact__c = testContact1.Id;
		insert leadRec2;

		StudentEnquiryFactory studFactory = new StudentEnquiryFactory(testContact, leadRec);
		Case cse1 = studFactory.createEnquiry();
		System.assertEquals(Label.Student_Type_Domestic, cse1.Student_Type__c);

		StudentEnquiryFactory studFactory2 = new StudentEnquiryFactory(testContact1, leadRec2);
		Case cse2 = studFactory2.createEnquiry();
		System.assertEquals(Label.Student_Type_International, cse2.Student_Type__c);
		Test.stopTest();
	}
}