@isTest(isParallel=true)
private class LogAnActivityController_Test {
    
    @testSetup
    static void setupTestData(){
	    Contact testContact = TestHelper.createOrphanContactRecords(1)[0];
	    testContact.Birthdate = Date.newInstance(1975, 1, 1);
        testContact.Person_Id_unique__c = String.valueOf(12345);
	    insert testContact;
        
        Case testCase = new Case(Subject = 'TestSubject', ContactId = testContact.Id);
        insert testCase;
    }
    
	private static testMethod void testCommitTask() {
        Contact testContact = [SELECT Id, Birthdate, Person_Id_unique__c FROM Contact LIMIT 1];
        Case testCase = [SELECT Id, Subject, ContactId FROM Case LIMIT 1];

        Test.startTest();
        	LogAnActivityController.commitTask('TestType', 'TestSubject', 'TestDescription', testCase.Id, testContact.Id);
        Test.stopTest();
	}

}