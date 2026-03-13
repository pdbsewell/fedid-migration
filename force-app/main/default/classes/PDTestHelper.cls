/**
@author: Vineeth Batreddy
@date: 22-09-2017
@group: Professional Development
@description: Test Helper class for PD specific/related classes/triggers
@revision: 08-10-2019 | Nadula Karunaratna | commented fields Details__c, Parking_Details__c and added 'Course_Type__c' and 'Managing_Faculty__c' on method createVenue as per requirement on PRODEV-277
@revision 8 April 2021 - Cartick Sub - PRODEV-476 - Migrate Magento data from custom labels to custom settings
@revision 21 May 2021 - Cartick Sub - PRODEV-687 - Update methods for main class changes
**/
@isTest
public class PDTestHelper {
    public static Venue__c createVenue() {
        Venue__c venue = new Venue__c();
        venue.Name = 'Test venue';
        venue.Legacy_Venue_ID__c = '1';
        venue.Minimum_Capacity__c = 1;
        venue.Maximum_Capacity__c = 5;
        venue.Course_Type__c = 'Short Course';
        venue.Managing_Faculty__c = 'Faculty of Education';        
        insert venue;
        return venue;   
    }

    public static Application__c createApplication(Contact contact, Case enquiry) {
        Application__c application = new Application__c();        
        application.Status__c = 'Registered - Not paid';
        application.Enquiry_Number__c = enquiry.Id;
        application.Applicant__c = contact.Id;

        insert application;
        return application;
    }

    public static Course__c createCourse() {
        Course__c course = new Course__c();
        course.Name = 'PDD0001';
        course.Cost_Centre__c = '123';
        course.Course_Description__c = 'PD Test Course';
        course.Fee__c = 1;
        course.Fund__c = 'Fund';
        course.GL_Account__c = 'GL Account';
        course.Inactive__c = false;
        course.Managing_Faculty__c = 'Faculty of Education';
        course.Legacy_Course_ID__c = '1';
        course.Type__c = 'Short_course';
        course.is_selective__c = true;
        insert course; 
        return course; 
    }


    public static Course_Offering_Pricing__c createCourseOfferingPricing(Id coId, String pType) {
        Course_Offering_Pricing__c co = new Course_Offering_Pricing__c();
        co.Course_Offering__c = coId;
        co.Active__c = True;
        co.Fee__c = 235;
        co.Pricing_Name__c = 'Assessment,BBQ';
        co.Pricing_Type__c = pType;
        insert co;
        return co;
    }


    public static Course_Offering__c createCourseOffering() {
        Course_Offering__c co = new Course_Offering__c();
        co.Course__c = createCourse().Id;
        co.Course_Code__c = 'PDD0001';        
        co.Apply_GST__c = false;
        co.Campus__c = 'Clayton';
        co.Start_Date__c = System.today();
        co.Start_Date__c.addDays(10);
        co.End_Date__c = co.Start_Date__c.addDays(20);
        co.No_of_Sessions__c = 5;
        co.Session_Dates__c = 'test';                
        co.Fee__c = 1000;
        co.Concession_Fee__c = 800;
        co.Part_of_the_Day__c = 'Day';
        Venue__c v = createVenue();
        co.Venue__c = v.Id;
        co.Faculty__c = 'Faculty of Education';
        co.Course_Type__c = 'Short Course';
        co.Course_Presenter_Name__c = 'Test Presenter';

        insert co;
        return co; 
    }

    public static Course_Offering__c createCourseOfferingForCourse(Course__c course) {
        Course_Offering__c co = new Course_Offering__c();
        co.Course__c = course.Id;
        co.Course_Code__c = 'PDD0001';
        co.Apply_GST__c = false;
        co.Campus__c = 'Clayton';
        co.Legacy_Cancellation__c = true;
        co.Legacy_Course_ID__c = '1';
        co.Legacy_Presenter_ID__c = '1';
        co.Legacy_Time_ID__c = '1';
        co.Legacy_Venue_ID__c = '1';
        co.Legacy_Course_Offering_ID__c = '1';
        co.Start_Date__c = System.today();
        co.End_Date__c = co.Start_Date__c.addDays(10);
        co.Concession_Fee__c = 800;
        co.No_of_Sessions__c = 5;
        co.Session_Dates__c = 'some desc';
        co.Concession_Fee__c = 200;
        co.Part_of_the_Day__c ='Evening';
        co.Status__c = 'EOI';
        co.Fee__c = 1000;
        Venue__c v = createVenue();
        co.Venue__c = v.Id;

        insert co;
        return co;
    }
    public static Payment__c createPayment(Course_Offering__c co, Contact contact, Application__c application) {
        Payment__c payment = new Payment__c();
        payment.Application__c = application.Id;
        payment.Contact__c = contact.Id;
        payment.Course_Offering__c = co.Id;
        payment.Street__c = '1 Brighton Road';
        payment.Suburb__c = 'Hampton';
        payment.State__c = 'Victoria';
        payment.Postcode__c = '3163';
        payment.Payment_Type__c = 'Credit Card';
        payment.Payment_Status__c = 'Not Processed';
        payment.Send_Receipt__c = false;
        payment.Quantity__c = 1;
        payment.Payment_Amount__c = 100;

        insert payment;
        return payment;
    }
    public static Course_Offering_Pricing__c createCourseOfferingPricing(Course_Offering__c co) {
        Course_Offering_Pricing__c cop = new Course_Offering_Pricing__c();
        cop.Pricing_Name__c = 'Standard pricing';
        cop.Fee__c = 100;
        cop.Active__c = true;
        cop.Pricing_Type__c = 'Normal Rate';
        cop.DiscountEvidenceType__c = 'NotRequired';
        cop.Course_Offering__c = co.Id;
        insert cop;
        return cop;
    }
    public static Country_Attribute__c createCountry() {
        Country_Attribute__c co = new Country_Attribute__c();
        co.Country__c = 'Australia';
        co.ISO_Alpha_2__c = 'AU';
        insert co;
        return co;
    }
    public static Attachment createAttachment( Id parentId){
        Attachment attch =  new attachment(name = 'att_'+String.valueOf('Test'),
                    parentId = parentId,
                    body = Blob.valueOf('testAttachment'));
        insert attch;
        return attch;
    }
    public static State__c createState(Country_Attribute__c country) {
        State__c st = new State__c();
        st.Name = 'Victoria';
        st.State_Code__c = 'AU';
        st.Country__c = country.Id;
        st.Country_ISO_2__c = country.ISO_Alpha_2__c;
        insert st;
        return st;
    }
    public static void createPresenter() {
        Presenter__c p = new Presenter__c();
        p.Name = '1';
        p.Full_Name__c = 'Fred';
        insert p;
    }

    public static Contact createApplicant() {
        Contact applicant = new Contact(
            Salutation = 'Mr',
            Title = 'Tester',
            Company__c = 'Monash University',
            FirstName = 'TestFirst',
            LastName = 'TestLast',
            Preferred_Name__c = 'TestPreferred',
            Email = 'TestFirst.TestLast@monash.edu',
            MobilePhone = '0000000000',
            MailingStreet = '700 Blackburn Road',
            MailingCity = 'Notting Hill',
            MailingState = 'Victoria',
            MailingCountry = 'Australia',
            MailingPostalCode = '3168',
            OtherStreet = '700 Blackburn Road',
            OtherCity = 'Notting Hill',
            OtherCountry = 'Australia',
            OtherPostalCode = '3168',
            OtherState = 'Victoria'
        );
        insert applicant;
        return applicant;
    }

    public static Contact createContact() {
        Contact cont = new Contact();
        cont.LastName = 'Laster';
        cont.Legacy_Contact_ID__c = '1';
        cont.Email = 'nadula.test@gmail.com';
        insert cont;
        return cont;
    }

    public static Contact createContact2(String givenName, String familyName, String email) {
        Contact cont = new Contact();
        cont.FirstName = givenName;
        cont.LastName = familyName;
        cont.Email = email;        
        insert cont;
        return cont;
    }

    public static Contact createContactWithAddress(String givenName, String familyName, String email,
    String mailingStreet, String mailingCity, String mailingState, String postCode, String phone, String mobilePhone) {
        Contact cont = new Contact(
            FirstName = givenName,
            LastName = familyName,
            Email = email,
            MailingStreet = mailingStreet,
            MailingCity = mailingCity, 
            MailingState = mailingState,
            MailingPostalCode = postCode,
            Phone = phone,
            MobilePhone = mobilePhone
        );
        insert cont;
        return cont;
    } 

    public static Case createEnquiry() {
        Case enq = new Case();
        enq.Subject = 'Online Course Registration';
        enq.Description = 'Test';
        enq.Heard_About_From__c = 'Banners';
        enq.Origin = 'Web';     
        enq.Student_Type__c = 'Domestic';
        enq.Enquiry_Type__c = 'Future Student';
        enq.Managing_Faculty__c = 'Education';
        enq.Status = 'Open';
        enq.Course__c = createCourse().Id;
        enq.Legacy_Course_Id__c = '1';
        enq.Legacy_Contact_Id__c = '1';
        enq.Legacy_Preferred_Time_ID__c = '1';
        enq.Legacy_Processed_Flag__c = false;
        enq.RecordTypeId = getRecordTypes('Case').get('Standard Enquiry').Id;
        insert enq;
        return enq;
    }

    public static ChargentOrders__ChargentOrder__c createChargentOrder(Payment__c payment) {
        ChargentOrders__ChargentOrder__c co = new ChargentOrders__ChargentOrder__c();
        co.Payment__c = payment.Id;
        co.ChargentOrders__Billing_First_Name__c = 'Luigi';
        co.ChargentOrders__Billing_Last_Name__c = 'Longman';
        co.ChargentOrders__Billing_Phone__c = '0433433433';
        co.ChargentOrders__Billing_Email__c = 'luigi.longman@mailinator.com';
        co.ChargentOrders__Billing_Address__c = '1 Toorak Road';
        co.ChargentOrders__Billing_City__c = 'Toorak';
        co.ChargentOrders__Billing_State__c = 'Victoria';
        co.ChargentOrders__Billing_Zip_Postal__c = '3153';
        co.ChargentOrders__Billing_Country__c = 'Australia';
        co.ChargentOrders__Payment_Method__c = 'Credit Card';
        co.ChargentOrders__Subtotal__c = 100;
        
        insert co;
        return co;
    }

    public static Magento_Settings__c createMagentoSettings() {
        Magento_Settings__c magentoSettings = new Magento_Settings__c();
        magentoSettings.Name = PaymentServices.MAGENTO_SETTINGS_DATASET_NAME;
        magentoSettings.MagentoHMACKey__c = 'test';
        magentoSettings.MagentoStatus_Expired__c = 'expired';	
        magentoSettings.MagentoStatus_Paid__c = 'paid';
        magentoSettings.MagentoStatus_Refunded__c = 'refunded';
        magentoSettings.MagentoStatus_Removed__c = 'removed';
        magentoSettings.MagentoURL__c = 'https://shop.monash.edu/courseregistrationpayment?booking_id=';
        insert magentoSettings;
        return magentoSettings;
    }

    public static ChargentOrders__Payment_Request__c createPaymentRequest(ChargentOrders__ChargentOrder__c co) {
        ChargentOrders__Payment_Request__c paymentRequest = new ChargentOrders__Payment_Request__c();
        paymentRequest.ChargentOrders__ChargentOrder__c = co.Id;
        insert paymentRequest;
        return paymentRequest;
    }

    public static void makePayment(ChargentOrders__Payment_Request__c paymentRequest, ChargentOrders__ChargentOrder__c co) {
        
        ChargentOrders__Transaction__c tran = new ChargentOrders__Transaction__c();
        tran.ChargentOrders__Credit_Card_Name__c = 'Payee Name';
        tran.ChargentOrders__Credit_Card_Number__c = '4111111111111111';
        tran.ChargentOrders__Card_Last_4__c = '1111';
        tran.ChargentOrders__Order__c = co.Id;
        tran.ChargentOrders__Payment_Request__c = paymentRequest.Id;
        //insert tran;

        paymentRequest.ChargentOrders__Status__c = 'paid';
        update paymentRequest;
    }

    public static Map<String,RecordType> getRecordTypes(String obj) {
        //Query for the record types of an object
        List<RecordType> rtypes = [Select Name, Id From RecordType where sObjectType= :obj and isActive=true];
     
        //Create a map between the RecordType Name and RecordType
        Map<String,RecordType> recordTypes = new Map<String,RecordType>{};
        for(RecordType rt: rtypes)
            recordTypes.put(rt.Name,rt);
     
        return recordTypes;
    }
}