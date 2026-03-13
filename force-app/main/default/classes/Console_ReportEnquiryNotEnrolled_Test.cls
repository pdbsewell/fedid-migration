/**
* @author Nadula Karunaratna
* @date 05-09-2017
* @group Professional Development
* @description Test class for Console_ReportEnquiryNotEnrolled
* @revision Nadula Karunaratna | 10-08-2018 | Added Faculty specific data 
* @revision Nadula Karunaratna | 16-01-2020 | Renamed with '_Test', Utilised "runAs" to test each faculty, increased code coverage from 43% to 86%
* @revision Cartick Sub - 18 May 2021 - PRODEV-686 - Improve test coverage; optimize code
*/

@isTest(isParallel=false) // User-based code fails when isParallel=true 
private class Console_ReportEnquiryNotEnrolled_Test {  

    @isTest static void TestGetLoginUserFaculty(){  
        // GIVEN
        // Get Professional Profile Id
        Profile PDProfile = [SELECT Id FROM Profile WHERE Name='Professional Development'];

        // Get Education Short Courses Team Role Id
        UserRole EDUuserRole = [select Id from UserRole where Name = 'Education Short Courses Team'];


        // Create a unique username
        String uniqueUserName = 'pdtestuser' + DateTime.now().getTime() + '@mailinator.com';  
        
        // Create a test Professional Development user    
        User u = new User(Alias = 'pdtuser', Email='pdtestuser@mailinator.com', EmailEncodingKey='UTF-8', LastName='Testuser', LanguageLocaleKey='en_US', LocaleSidKey='en_AU', ProfileId = PDProfile.Id, TimeZoneSidKey='Australia/Sydney', UserName=uniqueUserName, UserRoleId=EDUuserRole.Id);
        String faculty;

        // WHEN
        // Runs as the test PD user
        System.runAs(u){
            Test.startTest();
                Console_ReportEnquiryNotEnrolled x =  new Console_ReportEnquiryNotEnrolled();
                // The getLoginUserFaculty method is invoked
                faculty = x.getLoginUserFaculty();
            Test.stopTest();
            
            // THEN
            Assert.areEqual('Faculty of Education', faculty, 'getLoginUserFaculty method not running properly'); 
        }
        
        // Negative test
        Console_ReportEnquiryNotEnrolled x =  new Console_ReportEnquiryNotEnrolled();
        faculty = x.getLoginUserFaculty();                
        Assert.areEqual('All Faculties', faculty, 'getLoginUserFaculty method not running properly'); 
    }

    @isTest static void TestProcessData() {

        // Add Contacts
        Contact newContact1 = PDTestHelper.createContact2('Test','TEST1','test.test1@gmail.com');
        
        Contact newContact2 = PDTestHelper.createContactWithAddress('Test','TEST2','test.test2@gmail.com','Monash University,Level 2,700 Blackburn Road','Notting Hill','Victoria','3168','0399054000','0400123456');
        newContact2.Course_Code__c = 'PDD0001';
        newContact2.HasOptedOutOfEmail = false;
        update newContact2;

        Contact newContact3 = PDTestHelper.createContactWithAddress('Test','TEST3','test.test3@gmail.com','Monash University,Level 2,700 Blackburn Road','Notting Hill','Victoria','3168','0399054000','0400123456');
        Contact newContactPresenter1 = PDTestHelper.createContact2('Presenter','TEST1','Presenter.test1@gmail.com');

        // Add a Course with the Course Code, PDD0001
        Course__c course = PDTestHelper.createCourse();

        // Add a Course Offering for the above Course
        Course_Offering__c co = PDTestHelper.createCourseOfferingForCourse(course);
        co.Presenter__c = newContactPresenter1.Id;    
        update co;

        // Add Enquiries
        RecordType pdRecordType = [select Id from RecordType where Name = 'Professional Development' and SobjectType = 'Case' LIMIT 1]; 

        Case enq1 = new Case();      
        enq1.RecordTypeId = pdRecordType.Id;
        enq1.ContactId = newContact1.Id; 
        enq1.Status = 'Open';
        enq1.Course__c = course.Id;
        insert enq1; 

        Case enq2 = new Case();      
        enq2.RecordTypeId = pdRecordType.Id;
        enq2.ContactId = newContact2.Id;
        enq2.Status = 'Open';
        enq2.Course__c = course.Id;
        insert enq2; 

        Case enq3 = new Case();      
        enq3.RecordTypeId = pdRecordType.Id;
        enq3.ContactId = newContact3.Id;  
        enq3.Status = 'Open';
        enq3.Course__c = course.Id;
        insert enq3;   

        // Add an Application
        Application__c application = new Application__c();
        application.Status__c = 'Registered';
        application.Enquiry_Number__c = enq1.Id;
        application.Applicant__c = newContact1.Id;
        insert application;  

        // Add Application Course Preferences
        Application_Course_Preference__c acp = new Application_Course_Preference__c();
        acp.Applicant__c = newContact1.Id;
        acp.Status__c = 'Registered';
        acp.Course_Offering__c = co.Id;
        acp.Application__c = application.Id;
        acp.Course_Code__c = course.Name;
        acp.Course__c = course.Id;
        acp.Course_Type_Text__c = 'Short_Course';
        acp.Managing_Faculty_Text__c = 'Faculty of Education';
        insert acp;  

        Application_Course_Preference__c acp2 = new Application_Course_Preference__c();
        acp2.Applicant__c = newContact2.Id;
        acp2.Status__c = 'Registered - Not paid';
        acp.Course_Offering__c = co.Id;
        acp2.Application__c = application.Id;
        acp2.Course_Code__c = course.Name;
        acp2.Course__c = course.Id;
        acp2.Course_Type_Text__c = 'Short_Course';
        acp2.Managing_Faculty_Text__c = 'Faculty of Education';        
        insert acp2;          

        // URL Parameters
        Console_ReportEnquiryNotEnrolled testObj = new Console_ReportEnquiryNotEnrolled();
        testObj.getCriteria = '2021-01-01|2099-12-31|PDD0001|null|null|Faculty of Education';
        testObj.processData();
        
    }
}