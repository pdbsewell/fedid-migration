/**
@author Vineeth Batreddy
@date To be confirmed
@group Professional Development
@description This class acts as the controller for EnrolmentDetails lightning component
@revision 8 April 2021 - Cartick Sub - PRODEV-476 - Migrate Magento data from custom labels to custom settings
**/

public class CourseEnrolmentController {

    @AuraEnabled
    public static List<String> register(String givenName, String familyName, String address, String suburb, String state, String postCode, String homePhoneNumber, String workPhoneNumber, String mobileNumber, String email, String jobTitle, String selectedCourseOfferingId, String howDidyouHearAboutUs, String organisation, String orgStreetAddress, String orgSuburb, String orgState, String orgPostcode, Boolean isConcession, Boolean graduate, String courseName) {

        List<String> ids = new List<String>();
        ids.add('');
        ids.add('');
        ids.add('');
        ids.add('');

        try{
            // Create or Update contact
            Contact contact = upsertContact(givenName, familyName, address, suburb, state, postCode, homePhoneNumber, workPhoneNumber, mobileNumber, email, jobTitle, organisation, isConcession, orgStreetAddress, orgSuburb, orgState, orgPostcode, graduate, courseName);

            // Get Course Offering details
            Course_Offering__c co = getCourseOffering(selectedCourseOfferingId);

            // Create Enquiry
            String enqId;
            if(isConcession)
                enqId = createEnquiry(contact.Id, co.Course__c, howDidyouHearAboutUs, 'Open', 'Concession user - please validate eligibility');
            else
                enqId = createEnquiry(contact.Id, co.Course__c, howDidyouHearAboutUs, 'Solved', 'Online Course Registration');


            System.debug('!@#$% Enquiry ID : ' + enqId);
            // Create Application
            String appId = createApplication(enqId, contact.Id);

            // Create Application Course Preference
            createApplicationCoursePreference(contact.Id, appId, selectedCourseOfferingId, co.Course__c, co.Course__r.Course_Description__c, co.Course_Code_F__c, 'Registered - Not paid');
 
            System.debug('!@#$% Enquiry ID is : ' + enqId);

            ids.set(0, enqId);
            ids.set(1, appId);
            ids.set(2, contact.Id);

            System.debug('!@#$% REGISTRATION OUTCOME : ' + ids); 

        }
        catch(Exception e) {
            ids.set(3, e.getMessage());
            System.debug('!@#$% Exception while registering : ' + e);  
        }
        
        return ids;
    }

    @AuraEnabled
    public static List<String> waitlist(String givenName, String familyName, String address, String suburb, String state, String postCode, String homePhoneNumber, String workPhoneNumber, String mobileNumber, String email, String jobTitle, String selectedCourseOfferingId, String howDidyouHearAboutUs, String organisation, String orgStreetAddress, String orgSuburb, String orgState, String orgPostcode, Boolean isConcession, Boolean graduate, String courseName) {

        List<String> ids = new List<String>();
        ids.add('');
        ids.add('');
        ids.add('');
        ids.add('');

        try {
            // Create or Update contact
            Contact contact = upsertContact(givenName, familyName, address, suburb, state, postCode, homePhoneNumber, workPhoneNumber, mobileNumber, email, jobTitle, organisation, isConcession, orgStreetAddress, orgSuburb, orgState, orgPostcode, graduate, courseName);

            // Get Course Offering details
            Course_Offering__c co = getCourseOffering(selectedCourseOfferingId);

            // Create Enquiry
            String enqId = createEnquiry(contact.Id, co.Course__c, howDidyouHearAboutUs, 'Solved', 'Online Course Registration');

            // Create Application
            String appId = createApplication(enqId, contact.Id);

            // Create Application Course Preference
            createApplicationCoursePreference(contact.Id, appId, selectedCourseOfferingId, co.Course__c, co.Course__r.Course_Description__c, co.Course_Code_F__c, 'Waitlisted');
            
            System.debug('!@#$% Enquiry ID is : ' + enqId);     
            
            ids.set(0, enqId);
            ids.set(1, appId);
            ids.set(2, contact.Id);

        }
        catch(Exception e) {
            ids.set(3, e.getMessage());
            System.debug('!@#$% Exception while waitlisting : ' + e);    
        }
        
        return ids;
    }

    private static Contact upsertContact(String givenName, String familyName, String address, String suburb, String state, String postCode, String homePhoneNumber, String workPhoneNumber, String mobileNumber, String email, String jobTitle, String organisation, Boolean isConcession, String orgStreetAddress, String orgSuburb, String orgState, String orgPostcode, Boolean graduate, String courseName) {
        // Create or Update contact
        Contact contact = getExistingContact(givenName, familyName, email);

        if(contact == null) {
            contact = new Contact();
        }
        
        contact.FirstName = givenName;
        contact.LastName = familyName;
        contact.MailingStreet = address;
        contact.MailingCity = suburb;
        contact.MailingState = state;
        contact.MailingPostalCode = postCode;
        contact.OtherStreet = orgStreetAddress;
        contact.OtherCity = orgSuburb;
        contact.OtherState = orgState;
        contact.OtherPostalCode = orgPostcode;
        contact.HomePhone = homePhoneNumber;
        contact.Phone = workPhoneNumber;
        contact.MobilePhone = mobileNumber;
        contact.Email = email;
        contact.Title = jobTitle;
        contact.Company__c = organisation;
        contact.Concession__c = isConcession;
        contact.Previously_Studied_at_Monash__c = graduate;
        if(graduate)
            contact.Course_Name__c = courseName;
        
        upsert contact;
        return contact;
    }

    private static Contact getExistingContact(String givenName, String familyName, String email) {
        List<Contact> contacts = [SELECT FirstName, LastName, Title, Email, HomePhone, Phone, MobilePhone, MailingStreet, MailingCity, MailingState, MailingPostalCode, OtherStreet, OtherCity, OtherState, OtherPostalCode FROM Contact WHERE FirstName = :givenName AND LastName = :familyName AND Email = :email];
        if(contacts.size()>0)
            return contacts.get(0);
        else
            return null;
    }

    private static String createApplication(String enquiryId, String contactId) {
        Application__c application = new Application__c();
        application.Status__c = 'Registered - Not paid';
        application.Enquiry_Number__c = enquiryId;
        application.Applicant__c = contactId;

        insert application;
        return application.Id;
    }

    private static void createApplicationCoursePreference(String contactId, String applicationId, String courseOfferingId, String courseId, String courseTitle, String courseCode, String status) {
        Application_Course_Preference__c acp = new Application_Course_Preference__c();
        acp.Applicant__c = contactId;
        acp.Application__c = applicationId;
        acp.Status__c = status;
        acp.Course_Offering__c = courseOfferingId;
        acp.Course_Title__c = courseTitle;
        acp.Course_Code__c = courseCode;
        acp.Course__c = courseId;

        insert acp;
    }

    private static String createEnquiry(String contactId, String courseOfferingId, String heardFrom, String status, String description) {
        Case enquiry = new Case();
        enquiry.ContactId = contactId;
        enquiry.Subject = 'Online Course Registration';
        enquiry.Description = description;
        enquiry.Heard_About_From__c = heardFrom;
        enquiry.Origin = 'Web';     
        enquiry.Course__c = courseOfferingId;
        enquiry.Student_Type__c = 'Domestic';
        enquiry.Enquiry_Type__c = 'Future Course';
        enquiry.Managing_Faculty__c = 'Education';
        enquiry.Status = status;
        enquiry.RecordTypeId = getRecordTypes('Case').get('Professional Development').Id;
               
        insert enquiry;
        return enquiry.Id;
    }

    @AuraEnabled
    public static void reassignEnquiry(String enqId) {
        Case enquiry = [SELECT Id FROM Case WHERE Id = :enqId];
        
        // To enforece case assignment rules to run when creating case programatically
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.AssignmentRuleHeader.useDefaultRule = true;
        enquiry.setOptions(dml);
        
        upsert enquiry;
    }

    private static Course_Offering__c getCourseOffering(Id courseOfferingId) {
        List<Course_Offering__c> courseOfferings = [SELECT Id, Start_Date__c, End_Date__c, Fee__c, Concession_Fee__c, No_of_Sessions__c, Course__r.Course_Code__c, Number_of_Remaining_Places__c, Course__r.Course_Description__c, Venue__r.Name, Status__c, Course_Code_F__c FROM Course_Offering__c WHERE Id = :courseOfferingId];
        if(courseOfferings.size()>0)
            return courseOfferings.get(0);
        else
            return null;
    }

    private static Map<String,RecordType> getRecordTypes(String obj) {
        //Query for the record types of an object
        List<RecordType> rtypes = [Select Name, Id From RecordType where sObjectType= :obj and isActive=true];
     
        //Create a map between the RecordType Name and RecordType
        Map<String,RecordType> recordTypes = new Map<String,RecordType>{};
        for(RecordType rt: rtypes)
            recordTypes.put(rt.Name,rt);
     
        return recordTypes;
    }

    @AuraEnabled
    public static String createPayment(String applicationId, String contactId, Course_Offering__c co, Boolean isConcession, String streetAddress, String suburb, String state, String postcode) {
        System.debug('!@#$% Attempting to create Payment ');
        System.debug('!@#$% streetAddress : ' + streetAddress);
        System.debug('!@#$% postCode : ' + postCode);

        Payment__c payment = new Payment__c();
        payment.Application__c = applicationId;
        payment.Contact__c = contactId;        
        payment.Course_Offering__c = co.Id;
        payment.Street__c = streetAddress;
        payment.Suburb__c = suburb;
        payment.State__c = state;
        payment.Postcode__c = postcode;
        payment.Payment_Type__c = 'Credit_Card';
        payment.Payment_Status__c = 'Initiated';
        payment.Send_Receipt__c = false;
        payment.Quantity__c = 1;
        payment.Online_Registration__c = true;

        if(isConcession)
            payment.Payment_Amount__c = co.Concession_Fee__c;
        else
            payment.Payment_Amount__c = co.Fee__c;

        insert payment; 
        System.debug('!@#$% Payment : ' + payment);

        //Encrypt Id using HMAC key 
        Magento_Settings__c magentoSettings = Magento_Settings__c.getValues(PaymentServices.MAGENTO_SETTINGS_DATASET_NAME);
        String magentoURL = magentoSettings == null ? '' : magentoSettings.MagentoURL__c;
        String hmac_Key = magentoSettings == null ? '' : magentoSettings.MagentoHMACKey__c;
        Blob dataCode = Crypto.generateMac('HmacSHA256', Blob.valueOf(payment.Id), Blob.valueOf(hmac_Key));
        String encryptedParam = EncodingUtil.base64Encode(dataCode);

        //build URL
        String strURL = magentoURL+payment.Id+'&code='+EncodingUtil.urlEncode(encryptedParam, 'UTF-8');
        //String encodedURL = EncodingUtil.urlEncode(strURL, 'UTF-8');
        System.debug('****URL: '+strURL);

        return strURL;
    }

    @AuraEnabled
    public static List<String> retrieveHAFValues() {
        List<String> options = new List<String>();
        List<Schema.PicklistEntry> pValues = Case.Heard_About_From__c.getDescribe().getPicklistValues();

        for(Schema.PicklistEntry pValue : pValues) {
            options.add(pValue.getLabel());
        }

        return options;
    }

    @AuraEnabled
    public static Id saveTheChunk(String fileName, String base64Data, String contentType, String fileId, String parentId) { 
        system.debug('fileId: ' + fileId);
        if (fileId == '' || fileId == null) {
            fileId = uploadDocument(fileName, base64Data, contentType, parentId);
        } else {
            appendToFile(fileId, base64Data);
        }
        
        return Id.valueOf(fileId);
    }

    @AuraEnabled
    public static Id uploadDocument(String fileName, String base64Data, String contentType, String parentId) {
        User userDetail = [SELECT Id, ContactId FROM User WHERE Id =:UserInfo.getUserId()];

        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Attachment a = new Attachment();
        a.parentId = parentId;
        a.Body = EncodingUtil.base64Decode(base64Data);
        a.Name = fileName;
        a.ContentType = contentType;
        a.Description = fileName;
        insert a;

        return a.Id;
    }

    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        Attachment a = [
            SELECT Id, Body,ParentId
            FROM Attachment
            WHERE Id = :fileId
        ];
        
        String existingBody = EncodingUtil.base64Encode(a.Body);
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data); 
        
        update a;
    }

    @AuraEnabled
    public static List<Attachment> retrieveDocuments(String parentId) {
        List<Attachment> attachments = [SELECT Id, Name, ContentType, ParentId, Description FROM Attachment WHERE ParentId = :parentId];
        return attachments;     
    }

    @AuraEnabled
    public static List<Attachment> deleteDocument(String recordId) {
        List<Attachment> attachments = [SELECT Id, Name, ContentType, ParentId, Description FROM Attachment WHERE Id = :recordId];
        Attachment attachment;
        if(attachments.size()>0) {
            attachment = attachments.get(0);
        } 
        String parentId = attachment.ParentId;
        delete attachment;
        return retrieveDocuments(parentId);
    }

    @AuraEnabled
    public static String generatePaymentLink(String givenName, String familyName, String address, String suburb, String state, String postCode, String homePhoneNumber, String workPhoneNumber, String mobileNumber, String email, String selectedCourseOfferingId, String paymentId, Boolean isConcession, String enquiryId) {
        ChargentOrders__ChargentOrder__c co = new ChargentOrders__ChargentOrder__c();
        co.Payment__c = paymentId;
        co.ChargentOrders__Billing_First_Name__c = givenName;
        co.ChargentOrders__Billing_Last_Name__c = familyName;
        co.ChargentOrders__Billing_Phone__c = mobileNumber;
        co.ChargentOrders__Billing_Email__c = email;
        co.ChargentOrders__Billing_Address__c = address;
        co.ChargentOrders__Billing_City__c = suburb;
        co.ChargentOrders__Billing_State__c = state;
        co.ChargentOrders__Billing_Zip_Postal__c = postCode;
        co.ChargentOrders__Billing_Country__c = 'Australia';
        co.ChargentOrders__Payment_Method__c = 'Credit Card';
        if(isConcession)
            co.ChargentOrders__Subtotal__c = getCourseOffering(selectedCourseOfferingId).Concession_Fee__c;
        else
            co.ChargentOrders__Subtotal__c = getCourseOffering(selectedCourseOfferingId).Fee__c;
        
        insert co;

        // Assigning enquiry to the right queue
        reassignEnquiry(enquiryId);

        // Retrieve payment link
        ChargentOrders__Payment_Request__c pr = [SELECT ChargentOrders__Pay_Link__c, ChargentOrders__Billing_Contact__c, ChargentOrders__Email_Address__c FROM ChargentOrders__Payment_Request__c WHERE ChargentOrders__ChargentOrder__c = :co.Id];
        
        return pr.ChargentOrders__Pay_Link__c;
    }

}