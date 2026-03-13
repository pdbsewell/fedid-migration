/*
 * @author       Nadula Karunaratna
 * @date         08/03/2018
 * @description  Test class for unit test methods of PaymentServices class
 */

@isTest(isParallel=true)
private class PaymentServices_Test{
	
	static testMethod void updatePaymentStatusTest(){

		Contact newContact = new Contact();
		Course_Offering__c newCo = new Course_Offering__c();
		Case newEnq = new Case();
		Application__c newApplication = new Application__c();
		Payment__c newPayment = new Payment__c();

		PDTestHelper.createMagentoSettings();

		newContact = PDTestHelper.createContact();
		newCo = PDTestHelper.createCourseOffering();
		newEnq = PDTestHelper.createEnquiry();
		newApplication = PDTestHelper.createApplication(newContact,newEnq);
		newPayment = PDTestHelper.createPayment(newCo,newContact,newApplication);
		
		newPayment.Processor_Status__c = 'paid';
		upsert newPayment;
		newPayment = [SELECT Payment_Status__c FROM Payment__c WHERE Id =:newPayment.Id];
		System.assertEquals('Processed', newPayment.Payment_Status__c);

		newPayment.Processor_Status__c = 'refunded';
		upsert newPayment;
		newPayment = [SELECT Payment_Status__c FROM Payment__c WHERE Id =:newPayment.Id];
		System.assertEquals('Refund Processed', newPayment.Payment_Status__c);

	}
	
	static testMethod void generatePaymentReceiptTest(){
		Test.startTest();
		
		Contact newContact = new Contact();
		Course_Offering__c newCo = new Course_Offering__c();
		Case newEnq = new Case();
		Application__c newApplication = new Application__c();
		Payment__c newPayment = new Payment__c();

		newContact = PDTestHelper.createContact();
		newCo = PDTestHelper.createCourseOffering();
		newEnq = PDTestHelper.createEnquiry();
		newApplication = PDTestHelper.createApplication(newContact,newEnq);
		
		newPayment = PDTestHelper.createPayment(newCo,newContact,newApplication);
		newPayment.Payment_Status__c = 'Processed';
		newPayment.Send_Receipt__c = true;		
		upsert newPayment;				
		
		Integer invocations = Limits.getEmailInvocations();
		System.debug('generatePaymentReceiptTest: ' + invocations);
        System.assertEquals(1, invocations, 'An email has not been sent');

		Test.stopTest();
	}

}