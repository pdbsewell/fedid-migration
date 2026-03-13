/**
@author To be confirmed
@date To be confirmed
@group Professional Development
@description Sibling test class for CourseEnrolmentController
@revision 8 April 2021 - Cartick Sub - PRODEV-476 - Migrate Magento data from custom labels to custom settings
**/

@isTest(isParallel=true)
private class CourseEnrolmentController_Test {

    static testMethod void registerCandidate_NonConcession() {
        Course__c course = PDTestHelper.createCourse();
        Course_Offering__c co = PDTestHelper.createCourseOffering();
        co.Course__c = course.Id;
        update co;

        String givenName = 'Mario';
        String familyName = 'Bro';
        String address = '738 Blackburn Road'; 
        String suburb = 'Notting Hill';
        String state = 'Victoria'; 
        String postCode = '3168';
        String homePhoneNumber = '0389768976';
        String workPhoneNumber = '0389761122'; 
        String mobileNumber = '0433433455';
        String email = 'mario.bro@mailinator.com';
        String jobTitle = 'Student';
        String selectedCourseOfferingId = co.Id; 
        String howDidyouHearAboutUs = 'Age'; 
        String organisation = 'Awesome University';
        String orgStreetAddress = '700 Blackburn Road';
        String orgSuburb = 'Notting Hill';
        String orgState = 'Victoria';
        String orgPostcode = '3168';
        Boolean isConcession = false;

        // Enrol
        List<String> enrol = CourseEnrolmentController.register(givenName, familyName, address, suburb, state, postCode, homePhoneNumber, workPhoneNumber, mobileNumber, email, jobTitle, selectedCourseOfferingId, howDidyouHearAboutUs, organisation, orgStreetAddress, orgSuburb, orgState, orgPostcode, isConcession,false,'test');
        
    }

    static testMethod void registerCandidate_Concession() {
        Course__c course = PDTestHelper.createCourse();
        Course_Offering__c co = PDTestHelper.createCourseOffering();
        co.Course__c = course.Id;
        update co;

        String givenName = 'Mario';
        String familyName = 'Bro';
        String address = '738 Blackburn Road'; 
        String suburb = 'Notting Hill';
        String state = 'Victoria'; 
        String postCode = '3168';
        String homePhoneNumber = '0389768976';
        String workPhoneNumber = '0389761122'; 
        String mobileNumber = '0433433455';
        String email = 'mario.bro@mailinator.com';
        String jobTitle = 'Student';
        String selectedCourseOfferingId = co.Id; 
        String howDidyouHearAboutUs = 'Age'; 
        String organisation = '';
        String orgStreetAddress = '';
        String orgSuburb = '';
        String orgState = '';
        String orgPostcode = '';
        Boolean isConcession = true;

        List<String> enrol = CourseEnrolmentController.register(givenName, familyName, address, suburb, state, postCode, homePhoneNumber, workPhoneNumber, mobileNumber, email, jobTitle, selectedCourseOfferingId, howDidyouHearAboutUs, organisation, orgStreetAddress, orgSuburb, orgState, orgPostcode, isConcession,false,'test');

    }

    static testMethod void waitlistCandidate_NonConcession() {
        Course__c course = PDTestHelper.createCourse();
        Course_Offering__c co = PDTestHelper.createCourseOffering();
        co.Course__c = course.Id;
        update co;

        String givenName = 'Mario';
        String familyName = 'Bro';
        String address = '738 Blackburn Road'; 
        String suburb = 'Notting Hill';
        String state = 'Victoria'; 
        String postCode = '3168';
        String homePhoneNumber = '0389768976';
        String workPhoneNumber = '0389761122'; 
        String mobileNumber = '0433433455';
        String email = 'mario.bro@mailinator.com';
        String jobTitle = 'Student';
        String selectedCourseOfferingId = co.Id; 
        String howDidyouHearAboutUs = 'Age'; 
        String organisation = 'Awesome University';
        String orgStreetAddress = '700 Blackburn Road';
        String orgSuburb = 'Notting Hill';
        String orgState = 'Victoria';
        String orgPostcode = '3168';
        Boolean isConcession = false;

        CourseEnrolmentController.waitlist(givenName, familyName, address, suburb, state, postCode, homePhoneNumber, workPhoneNumber, mobileNumber, email, jobTitle, selectedCourseOfferingId, howDidyouHearAboutUs, organisation, orgStreetAddress, orgSuburb, orgState, orgPostcode, isConcession,false,'test');
    }

    static testMethod void waitlistCandidate_Concession() {
        Course__c course = PDTestHelper.createCourse();
        Course_Offering__c co = PDTestHelper.createCourseOffering();
        co.Course__c = course.Id;
        update co;

        String givenName = 'Mario';
        String familyName = 'Bro';
        String address = '738 Blackburn Road'; 
        String suburb = 'Notting Hill';
        String state = 'Victoria'; 
        String postCode = '3168';
        String homePhoneNumber = '0389768976';
        String workPhoneNumber = '0389761122'; 
        String mobileNumber = '0433433455';
        String email = 'mario.bro@mailinator.com';
        String jobTitle = 'Student';
        String selectedCourseOfferingId = co.Id; 
        String howDidyouHearAboutUs = 'Age'; 
        String organisation = 'Awesome University';
        String orgStreetAddress = '700 Blackburn Road';
        String orgSuburb = 'Notting Hill';
        String orgState = 'Victoria';
        String orgPostcode = '3168';
        Boolean isConcession = true;

        CourseEnrolmentController.waitlist(givenName, familyName, address, suburb, state, postCode, homePhoneNumber, workPhoneNumber, mobileNumber, email, jobTitle, selectedCourseOfferingId, howDidyouHearAboutUs, organisation, orgStreetAddress, orgSuburb, orgState, orgPostcode, isConcession,false,'test');
    }

    static testMethod void retrieveHAFValues() {
        CourseEnrolmentController.retrieveHAFValues();
    }

    static testMethod void payment() {
        Course__c course = PDTestHelper.createCourse();
        Course_Offering__c co = PDTestHelper.createCourseOffering();    
        co.Course__c = course.Id;
        update co;
        Contact contact = PDTestHelper.createContact();
        Case enquiry = PDTestHelper.createEnquiry();
        Application__c application = PDTestHelper.createApplication(contact, enquiry);
        PDTestHelper.createMagentoSettings();
        Payment__c payment = PDTestHelper.createPayment(co, contact, application);
        ChargentOrders__ChargentOrder__c chOrder = PDTestHelper.createChargentOrder(payment);
        ChargentOrders__Payment_Request__c paymentRequest = PDTestHelper.createPaymentRequest(chOrder);
        
        payment.Send_Receipt__c = true;
        payment.Processor_Status__c = 'expired';
        update payment;
    }

    static testMethod void magento_MockCallout() {
        Course__c course = PDTestHelper.createCourse();
        Course_Offering__c co = PDTestHelper.createCourseOffering();    
        co.Course__c = course.Id;
        update co;
        Contact contact = PDTestHelper.createContact();
        Case enquiry = PDTestHelper.createEnquiry();
        Application__c application = PDTestHelper.createApplication(contact, enquiry);
        Payment__c payment = PDTestHelper.createPayment(co, contact, application);
        Magento_Settings__c magentoSettings = PDTestHelper.createMagentoSettings();

        Test.startTest();
            String strReturn = CourseEnrolmentController.createPayment(application.Id, contact.Id, co, false, 'test address', 'suburb', 'state', '1234');
            
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();

            req.requestURI = '/services/apexrest/GetCourseRegistrationDetails/'+payment.Id;
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;

            SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                     'Complete',
                                                     '{"error": null,"courseInfo": {"startDate": "2018-01-09","quantity": 1,"price": 1145,"location": "Clayton","glAccount": "552041","fund": "2259511","courseTaxType": true,"courseName": "Certificate of Education Support - IntegrationAide / Teacher Aide","courseCode": "PDD1001","costCenter": "D01011","bookingId": "a2I0l0000001dUGEAY"},"candidateInfo": {"workPhone": "0387654321","suburb": "Toorak","streetAddress": "1 Toorak Road","state": "Victoria","postCode": "3000","mobile": "0433211899","lastName": "Lee","homePhone": "0387654321","firstName": "Bruce","email": "bruce.lee@mailinator.com","country": "AU"}}',
                                                     null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            CourseRegistrationDetails.doGet();

            payment.Processor_Status__c = magentoSettings.MagentoStatus_Paid__c;
            update payment;

        Test.stopTest();
    }

    static testMethod void paymentRequest() {
        Course__c course = PDTestHelper.createCourse();
        Course_Offering__c co = PDTestHelper.createCourseOffering();    
        co.Course__c = course.Id;
        update co;
        Contact contact = PDTestHelper.createContact();
        Case enquiry = PDTestHelper.createEnquiry();
        Application__c application = PDTestHelper.createApplication(contact, enquiry);
        Payment__c payment = PDTestHelper.createPayment(co, contact, application);
        ChargentOrders__ChargentOrder__c chOrder = PDTestHelper.createChargentOrder(payment);
        ChargentOrders__Payment_Request__c paymentRequest = PDTestHelper.createPaymentRequest(chOrder);
        PDTestHelper.makePayment(paymentRequest, chOrder);
        Magento_Settings__c magentoSettings = PDTestHelper.createMagentoSettings();

        payment.Send_Receipt__c = true;
        payment.Processor_Status__c = magentoSettings.MagentoStatus_Refunded__c;
        payment.Online_Registration__c = false;
        update payment;
    }

    static testMethod void uploadDocument() {
        Case enquiry = PDTestHelper.createEnquiry();
        String content = 'Something';
        Id docId = CourseEnrolmentController.saveTheChunk('Test File', content, '.txt', null, String.valueOf(enquiry.Id));
        CourseEnrolmentController.saveTheChunk('Test File', content, '.txt', String.valueOf(docId), String.valueOf(enquiry.Id));
    }

    static testMethod void deleteDocument() {
        Case enquiry = PDTestHelper.createEnquiry();
        Attachment attachment = PDTestHelper.createAttachment(enquiry.Id);
        CourseEnrolmentController.deleteDocument(attachment.Id);
    }
}