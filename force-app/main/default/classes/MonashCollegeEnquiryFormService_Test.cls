@isTest(isParallel=true)
private class MonashCollegeEnquiryFormService_Test {

    @isTest
	private static void testGetPickListValuesIntoList() {
        //Run test
        List<String> picklistValues = new List<String>();
        Test.startTest();
            picklistValues.addAll(MonashCollegeEnquiryFormService.getPickListValuesIntoList('Case', 'Status'));
        Test.stopTest();
        
        //Assert results
        System.assert(picklistValues.size() > 0);
	}
	
	@isTest
	private static void testRetrieveContact() {
        //Initialize test records
        Contact testContact = new Contact(Person_ID_unique__c = '11111111', 
                                          Email = 'test@test.com',
                                          FirstName = 'testFirst',
                                          LastName = 'testLast');
        insert testContact;
        
        //Run test
        String contactRetrieveResult;
        Test.startTest();
            contactRetrieveResult = MonashCollegeEnquiryFormService.retrieveContact(testContact.Person_ID_unique__c, 
                                                                                    testContact.Email);
        Test.stopTest();
        
        //Assert results
        System.assert(contactRetrieveResult != 'No Match');
	}
    
    @isTest
	private static void testSubmitGeneralEnquiry() {
        //Initialize test records
        Contact testContact = new Contact(Person_ID_unique__c = '11111111', 
                                          Email = 'test@test.com',
                                          FirstName = 'testFirst',
                                          LastName = 'testLast');
        insert testContact;
        
        //Run test
        String enquiryResult;
        Test.startTest();
            enquiryResult = MonashCollegeEnquiryFormService.submitGeneralEnquiry(testContact.Person_ID_unique__c, 
                                                                                 testContact.Email,
                                                                                 'Professional Year',
                                                                                 'Payment',
                                                                                 'Test Description');
        Test.stopTest();
        
        //Assert results
        System.assert(enquiryResult != 'Fatal Error');
	}
	
	@isTest
	private static void testSubmitNotificationEnquiry() {
        //Initialize test records
        Contact testContact = new Contact(Person_ID_unique__c = '11111111', 
                                          Email = 'test@test.com',
                                          FirstName = 'testFirst',
                                          LastName = 'testLast');
        insert testContact;
        
        //Run test
        String enquiryResult;
        Test.startTest();
            enquiryResult = MonashCollegeEnquiryFormService.submitNotificationEnquiry(testContact.Person_ID_unique__c, 
                                                                                      testContact.Email,
                                                                                     'Professional Year', 
                                                                                     'Monday', 
                                                                                     null, 
                                                                                     null, 
                                                                                     'Leave', 
                                                                                     'Personal commitment or obligation (i.e. family, study or work)', 
                                                                                     null, 
                                                                                     'Test Description', 
                                                                                     null, 
                                                                                     '1 month');
        Test.stopTest();
        
        //Assert results
        System.assert(enquiryResult != 'Fatal Error');
	}
	
	@isTest
	private static void testSubmitSpecialConsiderationEnquiry() {
        //Initialize test records
        Contact testContact = new Contact(Person_ID_unique__c = '11111111', 
                                          Email = 'test@test.com',
                                          FirstName = 'testFirst',
                                          LastName = 'testLast');
        insert testContact;
        
        //Run test
        String enquiryResult;
        Test.startTest();
            enquiryResult = MonashCollegeEnquiryFormService.submitSpecialConsiderationEnquiry(testContact.Person_ID_unique__c, 
                                                                                              testContact.Email,
                                                                                              'Professional Year', 
                                                                                              'Monday', 
                                                                                              'Ongoing health issue or condition', 
                                                                                              null, 
                                                                                              'Test Description');
        Test.stopTest();
        
        //Assert results
        System.assert(enquiryResult != 'Fatal Error');
	}
    
	@isTest
	private static void testSubmitFutureGeneralEnquiry() {
        //Initialize test records
        Contact testContact = new Contact(Person_ID_unique__c = '11111111', 
                                          Email = 'test@test.com',
                                          FirstName = 'testFirst',
                                          LastName = 'testLast',
                                          BirthDate = Date.newInstance(2000, 12, 9));
        insert testContact;
        
        //Run test
        String enquiryResult;
        Test.startTest();
            enquiryResult = MonashCollegeEnquiryFormService.submitFutureGeneralEnquiry('Mr',
                								       testContact.FirstName, 
                                                                                       testContact.LastName,
                                                                                       'test1@test.com',
                                                                                       Date.newInstance(2000, 12, 9),
                                                                                       null,
                                                                                       null,
                                                                                       '92560000',
                                                                                       'Test Description',
                                                                                       'ARGENTINA',
                                                                                       'ARGENTINA',
                                                                                       'New Zealand Citizen',
                                                                                       'Clayton',
                                                                                       'March',
                                                                                       'Postgraduate',
                                                                                       'Monash',
                                                                                       'Accounting',
                                                                                       'Monash University Foundation Year',
                                                                                       'Agent');
        Test.stopTest();
        
        //Assert results
        System.assert(enquiryResult != 'Fatal Error');
	}
}