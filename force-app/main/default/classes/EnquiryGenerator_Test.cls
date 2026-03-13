/**
* @author Kristian Vegerano
* @date AUG.10.2018
* @group Test Class
* @description  Test Class to test the functionality of EnquiryGenerator
* @revision     AUG.10.2018     Kristian Vegerano - Created <br/>
*               JAN.15.2020     APRivera - Renamed and updated code coverage <br/>
*/
@isTest(isParallel=true)
private class EnquiryGenerator_Test {

	@IsTest
	static void testBehavior() {
		Test.startTest();
		EnquiryGenerator enquiryFactory = new EnquiryGenerator(EnquiryUtil.EnquiryPurpose.GENERAL);
		Case cse1 = enquiryFactory.generateEnquiry('TestSubject', 'TestDescription');
		System.assertEquals('TestSubject', cse1.Subject);

		Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
		Lead ld = (Lead)MonConTestDataFactory.createSObject(new Lead());
		ld.Contact__c = con.Id;
		EnquiryGenerator enquiryFactory2 = new EnquiryGenerator(EnquiryUtil.EnquiryPurpose.STUDENT, con, ld);

		EnquiryGenerator enquiryFactory3 = new EnquiryGenerator(EnquiryUtil.EnquiryPurpose.STAFF, con);

		EnquiryGenerator enquiryFactory4 = new EnquiryGenerator(EnquiryUtil.EnquiryPurpose.AGENT);
		Test.stopTest();
	}
}