/**
* @author Ryan Wilson
* @date 10/11/2017
* @group Professional Development
* @description Rest service for Magento callout. Fetch booking/payment details from CRM.
* @revision 02-10-2018 | Nadula karunaratna | Added Vendor ID integration
* @revision 18-05-2020 | Nadula karunaratna | PRODEV-542 update with invoice related fields including ABN
*/

@RestResource(urlMapping='/GetCourseRegistrationDetails/*')
global with sharing class CourseRegistrationDetails {

    
    @HttpGet
    global static CourseRegistrationDetailsResponse doGet() {
      
        System.debug('!@#$% Request received : ');
        RestRequest req = RestContext.request;
        
        RestResponse res = RestContext.response;
        String paymentId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        List<Payment__c> payments = [SELECT Id, 
                                    Name, 
                                    Contact__r.FirstName, 
                                    Contact__r.LastName, 
                                    Contact__r.Email,
                                    Contact__r.HomePhone, 
                                    Contact__r.Phone, 
                                    Contact__r.MobilePhone,
                                    Company_Name__c,
                                    Street__c,
                                    Suburb__c,
                                    Postcode__c,
                                    State__c,
                                    Course_Offering__r.Course__r.Name,
                                    Course_Offering__r.Course__r.Course_Description__c,
                                    Course_Offering__r.Course__r.GL_Account__c,
                                    Course_Offering__r.Course__r.Cost_Centre__c,
                                    Course_Offering__r.Course__r.Fund__c,
                                    Course_Offering__r.Campus__c,
                                    Course_Offering__r.Start_Date__c,
                                    Course_Offering__r.Apply_GST__c,
                                    Payment_Amount__c,
                                    Quantity__c,
                                    Country__c,
                                    Course_Faculty__c,
                                    Organisation_Contact_Phone__c,
                                    Organisation_Contact_Email__c,
                                    Organisation_ABN__c,
                                    Organisation_Name__c,
									Payment_Type__c   									
                                    FROM Payment__c WHERE Id = :paymentId];
        
        CourseRegistrationDetailsResponse crdr = new CourseRegistrationDetailsResponse();
        
        if(payments != null && payments.size() > 0) {
            Payment__c payment = payments.get(0);
            // Course Details
            crdr.courseInfo = new CourseRegistrationDetailsResponse.CourseInfo();
            crdr.courseInfo.courseCode = payment.Course_Offering__r.Course__r.Name;
            crdr.courseInfo.courseName = payment.Course_Offering__r.Course__r.Course_Description__c;
            crdr.courseInfo.glAccount = payment.Course_Offering__r.Course__r.GL_Account__c;
            crdr.courseInfo.costCenter = payment.Course_Offering__r.Course__r.Cost_Centre__c;
            crdr.courseInfo.fund = payment.Course_Offering__r.Course__r.Fund__c;
            crdr.courseInfo.startDate = String.valueOf(payment.Course_Offering__r.Start_Date__c);
            crdr.courseInfo.location = payment.Course_Offering__r.Campus__c;
            crdr.courseInfo.price = payment.Payment_Amount__c;
            crdr.courseInfo.quantity = payment.Quantity__c;
            crdr.courseInfo.paymentId = payment.Name;
            crdr.courseInfo.bookingId = payment.Id;
            crdr.courseInfo.courseTaxType = payment.Course_Offering__r.Apply_GST__c;

            //Getting Vendor ID
            List<Faculty_Custom_Data__mdt> facultyCustomDataList = [Select Vendor_ID__c,Managing_Faculty__c from Faculty_Custom_Data__mdt where Managing_Faculty__c = :payment.Course_Faculty__c];
            crdr.courseInfo.vendorId = facultyCustomDataList[0].Vendor_ID__c; 

            // Candidate Details
            crdr.candidateInfo = new CourseRegistrationDetailsResponse.CandidateInfo();
            crdr.candidateInfo.firstName = payment.Contact__r.FirstName;
            crdr.candidateInfo.lastName = payment.Contact__r.LastName;
            crdr.candidateInfo.email = payment.Contact__r.Email;
            crdr.candidateInfo.homePhone = payment.Contact__r.HomePhone;
            crdr.candidateInfo.workPhone = payment.Contact__r.Phone;
            crdr.candidateInfo.mobile = payment.Contact__r.MobilePhone;
            crdr.candidateInfo.companyName = payment.Company_Name__c;
            crdr.candidateInfo.streetAddress = payment.Street__c;
            crdr.candidateInfo.suburb = payment.Suburb__c;
            crdr.candidateInfo.postCode = payment.Postcode__c;
            crdr.candidateInfo.state = payment.State__c;
            crdr.candidateInfo.country = payment.Country__c;

            crdr.candidateInfo.customerName = payment.Organisation_Name__c;
            crdr.candidateInfo.customerPhone = payment.Organisation_Contact_Phone__c;
            crdr.candidateInfo.customerEmail = payment.Organisation_Contact_Email__c;
            crdr.candidateInfo.companyAbn =  payment.Organisation_ABN__c;
            
            crdr.candidateInfo.paymentType =  (payment.Payment_Type__c == 'Credit_Card' ? 'creditCard' : 'invoice');    
            System.debug('crdr.candidateInfo.paymentType='+crdr.candidateInfo.paymentType);
            System.debug('payment.Payment_Type__c='+payment.Payment_Type__c); 
            

        } else {
            crdr.error = 'record not found';
        }
        
        return crdr;
    }
}