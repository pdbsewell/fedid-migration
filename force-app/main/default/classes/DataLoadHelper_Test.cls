@isTest(isParallel=true)
private class DataLoadHelper_Test {
    
    @testSetup static void setup() {
        // Setup test data
        //Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        //User u = new User(Alias = 'pdtstusr', Email='pdtestuser@pdorg.com', 
        //EmailEncodingKey='UTF-8', LastName='pdtestuser', LanguageLocaleKey='en_US', 
        //LocaleSidKey='en_US', ProfileId = p.Id, 
        //TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@mailinator.com.pd');

        //insert u;

    }

    static testMethod void runPostDataLoadScript() {
        Test.startTest();

        User usr = createTestUser();
        System.runAs(usr) { 
            PDTestHelper.createPresenter();
            PDTestHelper.createVenue();
            PDTestHelper.createCourse();
            PDTestHelper.createCourseOffering();
        }
        System.runAs(usr) {         
            DataLoadHelper.processReferenceData(usr.Id);
            DataLoadHelper.getPartOfTheDay('2');
        }        
        Test.stopTest();
    }

    static testMethod void clearAllReferenceData() {
        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {         
            DataLoadHelper.clearAllReferenceData(usr.Id);
        }        
        Test.stopTest();

        //Assertions
        List<Venue__c> venues = [SELECT ID,CreatedDate FROM Venue__c WHERE CreatedById = :usr.Id LIMIT 10000];
        System.assertEquals(0,venues.size());

        List<Course__c> courses = [SELECT ID,CreatedDate FROM Course__c WHERE CreatedById = :usr.Id LIMIT 10000];
        System.assertEquals(0,courses.size());

        List<Course_Offering__c> cos = [SELECT ID,CreatedDate FROM Course_Offering__c WHERE CreatedById = :usr.Id LIMIT 10000];
        System.assertEquals(0,cos.size());
    }

    static testMethod void processApplicationsBatch() {
        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {     
            Contact contact = PDTestHelper.createContact();
            Case enquiry = PDTestHelper.createEnquiry();    
            Application__c app = PDTestHelper.createApplication(contact, enquiry);
            Course_Offering__c co = PDTestHelper.createCourseOffering();
            PDTestHelper.createPayment(co, contact, app);
            
            DataLoadHelper.processApplicationsBatch(usr.Id);
        }        
        Test.stopTest();
    }

    static testMethod void processEnquiriesBatch() {
        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {         
            PDTestHelper.createContact();
            PDTestHelper.createEnquiry(); 
            DataLoadHelper.processEnquiriesBatch(usr.Id, null);
        }        
        Test.stopTest();
    }

    static testMethod void deleteEnquiries() {
        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) { 
            PDTestHelper.createEnquiry();   
            DataLoadHelper.deleteEnquiries(usr.Id, 10);
        }        
        Test.stopTest();
    }

    static testMethod void deleteContacts() {
        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {         
            PDTestHelper.createContact();
            DataLoadHelper.deleteContacts(usr.Id, 10);
        }        
        Test.stopTest();
    }

    static testMethod void deletePayments() {
        Test.startTest();
        User usr = createTestUser();
        System.runAs(usr) {         
            DataLoadHelper.deletePayments(usr.Id, 10);
        }        
        Test.stopTest();
    }

    private static User createTestUser() {
        // Setup test data
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'pdtstusr', Email='pdtestuser@pdorg.com', 
        EmailEncodingKey='UTF-8', LastName='pdtestuser', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@mailinator.com.pd');

        insert u;
        return u;
    }
    
}