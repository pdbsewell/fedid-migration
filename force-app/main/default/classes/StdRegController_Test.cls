/**
@author Shalini Mendu 
@date 24/08/2018
@group Professional Development
@description Test class for StdRegController
@revision Nadula Karunaratna | 24/07/2019 | PRODEV-359 Adding invoicing related changes
@revision Nadula Karunaratna | 17/02/2020 | PRODEV-456 Added test method for retrieveFacultyData
@revision Nadula Karunaratna | 07/07/2020 | PRODEV-567 Summer20 change
@revision Cartick Sub - 21 May 2021 - PRODEV-687 - Update methods for main class changes
**/
@isTest
public with sharing class StdRegController_Test {

    @testSetup
    public static void setUpData(){
        Course__c course = PDTestHelper.createCourse();
        PDTestHelper.createCourseOfferingForCourse(course);
        Course_Offering__c cof = [SELECT Id, Name FROM Course_Offering__c LIMIT 1];
        PDTestHelper.createCourseOfferingPricing(cof.Id, 'Normal Rate');
        PDTestHelper.createApplicant();
       
        Country_Attribute__c country = PDTestHelper.createCountry();
        PDTestHelper.createState(country);
        PDTestHelper.createMagentoSettings();
    }

    @isTest
    public static void validateRetrieveCOPSList() {
        Course_Offering__c cof = [SELECT Id, Name FROM Course_Offering__c LIMIT 1];
        
        Test.startTest();
        List<String> results = StdRegController.retrieveCOPSList(cof.Name);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Did not retrieve Course Offering Pricings');
    }

    @isTest
    public static void validateGetCOByName() {
        Course_Offering__c cof = [SELECT Id, Name FROM Course_Offering__c LIMIT 1];
        
        Test.startTest();
        Course_Offering__c result = StdRegController.getCOByName(cof.Name);
        Test.stopTest();

        System.assert(result != null, 'Did not retrieve Course Offering by Name');
    }

    @isTest
    public static void validateProcessCourseEnquiry() {
        
        Course_Offering__c cof = [SELECT Id, Name FROM Course_Offering__c LIMIT 1];
        Contact applicant = [SELECT Id, Salutation, Title, Company__c, FirstName, LastName, Preferred_Name__c, Email, MobilePhone, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode, OtherStreet, OtherCity, OtherState, OtherCountry, OtherPostalCode FROM Contact LIMIT 1];
       
        StdRegServices.CourseEnquiry courseEnquiry = new StdRegServices.CourseEnquiry();
        courseEnquiry.applicant = applicant;
        courseEnquiry.courseOfferingId = cof.Id;
        courseEnquiry.heardAboutFrom = 'LinkedIn post';

        StdRegServices.CourseRegistration courseReg = StdRegController.processCourseEnquiry(courseEnquiry);
    }

    @isTest
    public static void validateProcessCoursePaymentRequest() {
        
        Contact applicant = [SELECT Id, Salutation, Title, Company__c, FirstName, LastName, Preferred_Name__c, Email, MobilePhone, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode, OtherStreet, OtherCity, OtherState, OtherCountry, OtherPostalCode FROM Contact LIMIT 1];
        Course_Offering__c cof = [SELECT Id, Name FROM Course_Offering__c LIMIT 1];
       
        StdRegServices.CourseEnquiry courseEnquiry = new StdRegServices.CourseEnquiry();
        courseEnquiry.applicant = applicant;
        courseEnquiry.courseOfferingId = cof.Id;
        courseEnquiry.heardAboutFrom = 'LinkedIn post';

        StdRegServices.CourseRegistration courseReg = StdRegController.processCourseEnquiry(courseEnquiry);

        Application__c application = [SELECT Id FROM Application__c LIMIT 1];
        Course_Offering_Pricing__c cop = [SELECT Id FROM Course_Offering_Pricing__c LIMIT 1];
        Case enquiry = [SELECT Id FROM Case LIMIT 1];

        StdRegServices.PaymentOrganisation paymentOrganisation = new StdRegServices.PaymentOrganisation();
        paymentOrganisation.abn = '12345678';
        paymentOrganisation.contactDepartment = 'Finance';
        paymentOrganisation.contactEmail = 'TestFirst.TestLast@monash.edu';
        paymentOrganisation.contactName = 'TestFirst';
        paymentOrganisation.contactPhone = '0000000000';
        paymentOrganisation.addressCountry = 'Australia';
        paymentOrganisation.name = 'Test Org';
        paymentOrganisation.addressPostcode = '3168';
        paymentOrganisation.addressState = 'Victoria';
        paymentOrganisation.addressStreet = '700 Blackburn Road';
        paymentOrganisation.addressSuburb = 'Notting Hill';
        paymentOrganisation.poNumber = '0000000000';

        StdRegServices.CoursePaymentRequest paymentRequest = new StdRegServices.CoursePaymentRequest();
        paymentRequest.applicantId = applicant.Id;
        paymentRequest.applicationId = application.Id;
        paymentRequest.courseOfferingId = cof.Id;
        paymentRequest.courseOfferingPricingId = cop.Id;
        paymentRequest.organisation = paymentOrganisation;
        paymentRequest.paymentTypeCode = 'register';
        paymentRequest.enquiryId = enquiry.Id;
        paymentRequest.costCentre = 'costcentre';
        paymentRequest.fund = 'fund';
        paymentRequest.evidenceId = '123456';
        paymentRequest.evidenceType = 'NotRequired';
        paymentRequest.envLink = 'envlink';
        paymentRequest.isSelective = false;

        StdRegServices.CoursePayment coursePayment = StdRegController.processCoursePaymentRequest(paymentRequest);
        StdRegController.confirmCoursePayment(coursePayment);
        StdRegController.getMagentoURL(String.valueOf(coursePayment.paymentId));
    }
    
    @isTest
    public static void validateProcessCoursePaymentRequest_Waitlist() {
       
        Course_Offering__c cof = [SELECT Id, Name, Course__c, Course__r.Course_Type__c, Course__r.Course_Description__c, Course__r.Managing_Faculty__c, Course_Code_F__c FROM Course_Offering__c LIMIT 1];
        Contact applicant = [SELECT Id, Salutation, Title, Company__c, FirstName, LastName, Preferred_Name__c, Email, MobilePhone, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode, OtherStreet, OtherCity, OtherState, OtherCountry, OtherPostalCode FROM Contact LIMIT 1];

        StdRegServices.CourseEnquiry courseEnquiry = new StdRegServices.CourseEnquiry();
        courseEnquiry.applicant = applicant;
        courseEnquiry.courseOfferingId = cof.Id;
        courseEnquiry.heardAboutFrom = 'LinkedIn post';

        StdRegServices.CourseRegistration courseReg = StdRegController.processCourseEnquiry(courseEnquiry);

        Application__c application = [SELECT Id FROM Application__c LIMIT 1];
        Course_Offering_Pricing__c cop = [SELECT Id FROM Course_Offering_Pricing__c LIMIT 1];
        Case enquiry = [SELECT Id FROM Case LIMIT 1];

        StdRegServices.CoursePaymentRequest paymentRequest = new StdRegServices.CoursePaymentRequest();
        paymentRequest.applicantId = applicant.Id;
        paymentRequest.applicationId = application.Id;
        paymentRequest.courseOfferingId = cof.Id;
        paymentRequest.courseOfferingPricingId = cop.Id;
        paymentRequest.paymentTypeCode = 'waitlist';
        paymentRequest.enquiryId = enquiry.Id;
        paymentRequest.evidenceId = '123456';
        paymentRequest.isSelective = false;

        StdRegServices.CoursePayment coursePayment = StdRegController.processCoursePaymentRequest(paymentRequest);
        //List<String> pricewaitlist = StdRegController.savePricingInfoForWaitlist('waitlist', contactInfo[0],contactInfo[1],contactInfo[2],cof, cop.Id, '12345');
    }

    @isTest
    public static void validateUploadDocument() {
        
        Case enquiry = PDTestHelper.createEnquiry();
        String content = 'Something';
        String base64Data = EncodingUtil.urlEncode(content, 'UTF-8');

        Id docId = StdRegController.saveChunk(enquiry.Id, 'file1.txt',base64Data, 'txt',  '');
        StdRegController.saveChunk(enquiry.Id, 'file1.txt',base64Data, 'txt',  docId);
    }

    @isTest
    public static void validateDeleteAttachments() {
        Case enquiry = PDTestHelper.createEnquiry();
        Contact applicant = [SELECT Id FROM Contact LIMIT 1];
        Attachment attachment = PDTestHelper.createAttachment(enquiry.Id);

        StdRegServices.CourseEnqiryAttachments inputAttachments = new StdRegServices.CourseEnqiryAttachments();
        inputAttachments.enquiryId = enquiry.Id;
        inputAttachments.applicantId = applicant.Id;
        inputAttachments.attachments = new List<Attachment>{attachment};

        StdRegController.deleteAttachments(inputAttachments);
    }

    @isTest
    public static void validateRetrievePickListValues() {
        StdRegController.retrieveSalutations();
        StdRegController.retrieveHeardFrom();
        List<String> countryList = StdRegController.retrieveCountries();
        List<String> stateList = StdRegController.retrieveStateForCountry('AU');
        String tnc = StdRegController.retrieveFacultyTnc('Faculty of Education');
    }

    @isTest 
    public static void validateRetrieveFacultyData(){
        Course__c course = PDTestHelper.createCourse();	
		String courseName = course.Name;
        String courseFaculty = course.Managing_Faculty__c;
       	
        Test.startTest();
        //Positive test
        List<Faculty_Custom_Data__mdt> facultyDataTrue = StdRegController.retrieveFacultyData(courseName);
        //Negative test
        List<Faculty_Custom_Data__mdt> facultyDataFalse = StdRegController.retrieveFacultyData('courseNameTestText');
        Test.stopTest();        
        System.assertEquals(courseFaculty, facultyDataTrue[0].Managing_Faculty__c);  
        System.assert(facultyDataFalse == null);    
    }

    @isTest
    public static void testFieldLabelling() {
       
        Course_Offering__c cof = [SELECT Id, Name FROM Course_Offering__c LIMIT 1];
        Contact applicant = [SELECT Id, Salutation, Title, Company__c, FirstName, LastName, Preferred_Name__c, Email, MobilePhone, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode, OtherStreet, OtherCity, OtherState, OtherCountry, OtherPostalCode FROM Contact LIMIT 1];

        StdRegServices.courseEnquiry courseEnquiry = new StdRegServices.courseEnquiry();
        courseEnquiry.applicant = applicant;
        courseEnquiry.courseOfferingId = cof.Id;
        courseEnquiry.heardAboutFrom = 'LinkedIn post';

        StdRegServices.courseRegistration courseReg = StdRegController.processCourseEnquiry(courseEnquiry);
        
        Application__c application = [SELECT Id FROM Application__c LIMIT 1];
        Course_Offering_Pricing__c cop = [SELECT Id FROM Course_Offering_Pricing__c LIMIT 1];
        Case enquiry = [SELECT Id FROM Case LIMIT 1];

        StdRegServices.coursePaymentRequest paymentRequest = new StdRegServices.coursePaymentRequest();
        paymentRequest.applicantId = applicant.Id;
        paymentRequest.applicationId = application.Id;
        paymentRequest.courseOfferingId = cof.Id;
        paymentRequest.courseOfferingPricingId = cop.Id;
        paymentRequest.paymentTypeCode = 'register';
        paymentRequest.enquiryId = enquiry.Id;
        paymentRequest.costCentre = 'costcentre';
        paymentRequest.fund = 'fund';
        paymentRequest.evidenceId = '123456';
        paymentRequest.evidenceType = 'NotRequired';
        paymentRequest.envLink = 'envlink';
        paymentRequest.isSelective = false;

        StdRegServices.CoursePayment coursePayment = StdRegController.processCoursePaymentRequest(paymentRequest);
        //List<String> pricingOptions = StdRegController.savePricingInfoForRegister('register', contactInfo[0],contactInfo[1],contactInfo[2], cof , 'NotRequired', cop.Id, false, '123456','hellolink','costcentre','fund');

        Course_Application_Answers__c ca = new Course_Application_Answers__c(ACPLookup__c = coursePayment.coursePreferenceId, ShortQuestion1__c ='Testing');
        insert ca;

        BatchFieldLabel ba = new BatchFieldLabel(ca);
        System.enqueueJob(ba);
    }
}