@isTest(isParallel=true)
private class BusinessLicenseTriggerHandler_Test {
	
	@isTest static void test_method_one() {
		Business_License__c testBusinessLicense = new Business_License__c();
		testBusinessLicense.Name = 'Faculty - Medicine, Nursing and Health Sciences';
		testBusinessLicense.Baseline_Licenses__c = 100;
		testBusinessLicense.Paid_Licenses__c = 100;
		Test.startTest();
			insert testBusinessLicense;
		Test.stopTest();

		List<Business_License__Share> objectShare = [SELECT Id, ParentId, AccessLevel FROM Business_License__Share WHERE ParentId =: testBusinessLicense.Id];
		System.assert(!objectShare.isEmpty());
	}
}