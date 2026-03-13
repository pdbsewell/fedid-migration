/**
@author Nadula Karunaratna
@date 17-01-2020
@group Professional Development
@description Test class for CourseApplicationAnswersServices
@revision 8 April 2021 - Cartick Sub - PRODEV-476 - Migrate Magento data from custom labels to custom settings
@revision 21 May 2021 - Cartick Sub - PRODEV-687 - Update methods for main class changes
**/

@isTest(isParallel=false) // Set isParallel to false to overcome mixed DML operation exception on parallel Apex test
private class CourseApplicationAnswersServices_Test {
	
    @testSetup
    public static void setUpData(){
        Course__c course = PDTestHelper.createCourse();
        PDTestHelper.createCourseOfferingForCourse(course);
        Course_Offering__c cof = [SELECT Id, Name FROM Course_Offering__c LIMIT 1];
        PDTestHelper.createCourseOfferingPricing(cof.Id, 'Normal Rate' );
        PDTestHelper.createApplicant();

        Country_Attribute__c country = PDTestHelper.createCountry();
        PDTestHelper.createState(country);
        PDTestHelper.createMagentoSettings();
    }
    
    @isTest    
    public static void testFieldLabelling(){
    
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