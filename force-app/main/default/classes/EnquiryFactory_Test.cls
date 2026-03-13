/**
* @author Angelo Rivera
* @date 15.Jan.2020
* @group Test Class
* @description  Test Class to test the functionality of EnquiryFactory
* @revision     APRivera, 15.Jan.2020 - Created <br/>
*/
@isTest(isParallel=true)
private class EnquiryFactory_Test {

	@IsTest
	static void testBehavior() {
		Test.startTest();
		EnquiryFactory enquiryFactory = new EnquiryFactory(EnquiryUtil.EnquiryPurpose.GENERAL);
		Case cse1 = enquiryFactory.createEnquiry();
		System.assertNotEquals(null, cse1);

		Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
		Lead ld = (Lead)MonConTestDataFactory.createSObject(new Lead());
		ld.Contact__c = con.Id;
		EnquiryFactory enquiryFactory2 = new EnquiryFactory(EnquiryUtil.EnquiryPurpose.STUDENT, con, ld);
		Case cse2 = enquiryFactory2.createEnquiry();
		System.assertNotEquals(null, cse2);

		EnquiryFactory enquiryFactory3 = new EnquiryFactory(EnquiryUtil.EnquiryPurpose.STAFF, con);
		Case cse3 = enquiryFactory3.createEnquiry();
		System.assertNotEquals(null, cse3);

		EnquiryFactory enquiryFactory4 = new EnquiryFactory(EnquiryUtil.EnquiryPurpose.AGENT);
		Case cse4 = enquiryFactory4.createEnquiry();
		System.assertNotEquals(null, cse4);
		Test.stopTest();
	}
}