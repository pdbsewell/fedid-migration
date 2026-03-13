@isTest(isParallel=true)
private class ManageEnquiryContactService_Test {
    @testSetup
    static void setupTestData(){
	    Course__c testCourse = new Course__c(Name = 'TestCourse', Managing_Faculty__c = 'TestFaculty');
        insert testCourse;
        
	    Contact testContact = TestHelper.createOrphanContactRecords(1)[0];
	    testContact.LastName = 'TestContact';
	    testContact.Email = 'test.test@test.com';
	    testContact.Birthdate = Date.newInstance(1975, 1, 1);
        testContact.Person_Id_unique__c = String.valueOf(12345);
	    insert testContact;
        
        Case testCase = new Case(Subject = 'TestSubject', ContactId = testContact.Id);
        insert testCase;
    }
    
	private static testMethod void testSearchContact() {
        Contact testContact = [SELECT Id, Name, Birthdate, Person_Id_unique__c FROM Contact LIMIT 1];
        
        String searchResult;
        Test.startTest();
            List<Id> fixedSearchResults = new List<Id>();
            fixedSearchResults.add(testContact.Id);
            Test.setFixedSearchResults(fixedSearchResults);
            
            searchResult = ManageEnquiryContactService.searchContact('test');
        Test.stopTest();
        
        System.assertEquals(testContact.Id, ((List<Contact>)JSON.deserialize(searchResult, List<Contact>.class))[0].Id);
	}
    
    private static testMethod void testCopyContactDetailsFromEnquiry() {
        Contact testContact = [SELECT Id, Birthdate, Person_Id_unique__c FROM Contact LIMIT 1];
        Case testCase = [SELECT Id, Subject, ContactId FROM Case LIMIT 1];
        
        Case resultCase;
        Test.startTest();
        	resultCase = ManageEnquiryContactService.copyContactDetailsFromEnquiry(testCase.Id);
        Test.stopTest();
        
        System.assertEquals(testCase.Id, resultCase.Id);
	}
}