@isTest(isParallel=true)
private class ConsoleContactCaseRelatedListCC_Test {
    
    @testSetup static void methodName() {
        Contact testContact = new Contact(LastName = 'TestContact');
        insert testContact;
    }
    
	private static testMethod void testPageLoadNoEnquiry() {
	    //Initialize Variables
	    Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'TestContact' LIMIT 1];
        
        //Test console enquiry related list constructor
        Test.startTest();
            ApexPages.StandardController testStandardController = new ApexPages.StandardController(testContact);
            ConsoleContactCaseRelatedListCC testConsoleContactEnquiryRelatedList = new ConsoleContactCaseRelatedListCC(testStandardController);
            
            PageReference pageRef = Page.Console_ContactEnquiryRelatedList;
            pageRef.getParameters().put('id', String.valueOf(testContact.Id));
            Test.setCurrentPage(pageRef);
        Test.stopTest();
        
        //Assert results
        System.assertEquals(testConsoleContactEnquiryRelatedList.enquiryList.size(), [SELECT Id FROM Case WHERE ContactId = :testContact.Id].size());
	}
	
	private static testMethod void testPageLoadWithEnquiry() {
	    //Initialize Variables
	    Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'TestContact' LIMIT 1];
	    Case testEnquiry = new Case(ContactId = testContact.Id);
	    insert testEnquiry;
	    
        //Test console enquiry related list constructor
        Test.startTest();
            ApexPages.StandardController testStandardController = new ApexPages.StandardController(testContact);
            ConsoleContactCaseRelatedListCC testConsoleContactEnquiryRelatedList = new ConsoleContactCaseRelatedListCC(testStandardController);
            
            PageReference pageRef = Page.Console_ContactEnquiryRelatedList;
            pageRef.getParameters().put('id', String.valueOf(testContact.Id));
            Test.setCurrentPage(pageRef);
        Test.stopTest();
        
        //Assert results
        System.assertEquals(testConsoleContactEnquiryRelatedList.enquiryList.size(), [SELECT Id FROM Case WHERE ContactId = :testContact.Id].size());
	}
}