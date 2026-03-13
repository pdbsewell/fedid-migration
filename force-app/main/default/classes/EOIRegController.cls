/**
@author Shalini Mendu
@date 20 June 2018
@group Professional Development
@description Apex controller for EOIRegistration Aura component
@revision 22 April 2021 - Cartick Sub - PRODEV-683 - Fix Guest Licence User access issues, similar to StdRegController
          18 May 2021 - Cartick Sub - PRODEV-686 - Add MCPD to Enquiry creation code
**/

public with sharing class EOIRegController {
    
    /** @description Retrieves Course Offerings by Name
    @param coName  The Name (Auto number)of the Course Offering
    @return The Course Offering with the matching Name
    @revision 
    **/
    @AuraEnabled
    public static Course_Offering__c getCOByName(String coName){        
        if (String.isBlank(coName)) {
            return null;
        }

        List<Course_Offering__c> courseOfferings = [SELECT Name, Id, Start_Date__c, End_Date__c, Fee__c, Concession_Fee__c, No_of_Sessions__c, Course__r.Course_Code__c, Number_of_Remaining_Places__c, Course__r.Course_Description__c, Venue__r.Name,Course__r.Managing_Faculty__c,Course__r.Type__c,Status__c, Course_Code_F__c FROM Course_Offering__c where Name=:coName];
        if(!courseOfferings.isEmpty()) {
            return courseOfferings[0];
        }

        return null;
    }

    /**
    @description Retrieves the Salutation picklist option labels from the Contact object
    @return A List of Strings containing the Contact Salutation picklist option labels
    @revision 
    **/
    @AuraEnabled
    public static List<String> retrieveSalutations() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Contact.Salutation.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            options.add(f.getLabel());
        }
        return options;
    }

    /**
    @description Retrieves the Heard About From picklist option labels from the Enquiry object
    @return A List of Strings containing the Enquiry Heard About From picklist option labels
    @revision 
    **/
    @AuraEnabled
    public static List<String> retrieveHeardFrom() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Case.Heard_About_From__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            options.add(f.getLabel());
        }
        return options;
    }

    /**
    @description Upserts a Contact and inserts related records based on form values
    @param Values from the Aura component
    @return A List of Strings containing the Ids of the Enquiry, Application and Contact inserted, plus any Exception thrown
    @revision 
    **/
    @AuraEnabled
    public static List<String> register(String title, String firstName, String lastName, String jobTitle, String organisation, String phoneNumber,  String email, String hearfrom, String coName) {

        List<String> ids = new List<String>();
        ids.add('');
        ids.add('');
        ids.add('');
        ids.add('');

        try {

            // Initialize inner class instance to enable system mode operations
            EOIRegController.systemModeDataAccess sysModeDA = new EOIRegController.systemModeDataAccess();

            // Create or update Contact
            Contact contact = sysModeDA.upsertContact(title, firstName, lastName,  phoneNumber, email, jobTitle, organisation);

            // Get Course Offering
            Course_Offering__c co = getCOByName(coName);

            // Create, in system mode, the Enquiry
            String enqId = sysModeDA.createEnquiry(contact.Id, co.Course__c, hearfrom, 'Solved', 'Online Course Registration',co.Course__r.Managing_Faculty__c);

            // Create, in system mode, the Application
            String appId = sysModeDA.createApplication(enqId, contact.Id);

            // Create, in system mode, the Application Course Preference (ACP)
            sysModeDA.createApplicationCoursePreference(contact.Id, appId, co.Id, co.Course__c, co.Course__r.Course_Description__c, co.Course_Code_F__c, 'Registered - EOI Only',co.Course__r.Managing_Faculty__c,co.Course__r.Type__c);

            // Force, in system mode, the previously created Enquiry to go through the Case Assignment Rule
            sysModeDA.reassignEnquiry(enqId);

            // Return the Ids of the Enquiry, Application and Contact created
            ids.set(0, enqId);
            ids.set(1, appId);
            ids.set(2, contact.Id);
        }
        catch(Exception e) {
            ids.set(3, e.getMessage());
            System.debug('Exception while registering: ' + e);
        }
        return ids;
    }

    /**
    @description Retrieves the Record Types for a given sObject
    @param obj The sObject name (example: Case)
    @return A Map where the keys are the Record Type Names and the values are the Record Types
    @revision 
    **/
    private static Map<String,RecordType> getRecordTypes(String obj) {

        List<RecordType> rtypes = [Select Name, Id From RecordType where sObjectType= :obj and isActive=true];
        Map<String,RecordType> recordTypes = new Map<String,RecordType>{};
        for(RecordType rt: rtypes)
            recordTypes.put(rt.Name,rt);

        return recordTypes;
    }

    /**
    @author Cartick Sub
    @date 22 April 2021
    @group Professional Development
    @description Inner class to run DML operations in system mode to overcome Guest Licence User access issues
    @revision Initial version - 22 April 2021 - Cartick Sub - PRODEV-683
    **/
    public without sharing class systemModeDataAccess {

        /**
        @description Inserts a Contact based on form values, or updates the Contact if it already exists
        @param Values from the Aura component
        @return The Contact record after the upsert
        @revision 
        **/
        public Contact upsertContact(String title,String firstName, String lastName,String phoneNumber,String email,String jobTitle,String organisation) {

            Contact contact = getExistingContact(firstName, lastName, email);

            if(contact == null) {
                contact = new Contact();
            }
            contact.Salutation = title;
            contact.FirstName = firstName;
            contact.LastName = lastName;
            contact.Title = jobTitle;
            contact.Company__c = organisation;
            contact.Phone = phoneNumber;
            contact.MobilePhone = phoneNumber;
            contact.Email = email;

            upsert contact;
            return contact;
        }

        /**
        @description Checks if the database contains a Contact which exactly matches the specified parameters
        @param firstName The Contact FirstName field
        @param lastName The Contact LastName field
        @param email The Contact Email field
        @return The first matching Contact found, or null if none was found
        @revision 
        **/
        public Contact getExistingContact(String firstName, String lastName, String email) {
            List<Contact> contacts = [SELECT FirstName, LastName, Title, Email, HomePhone, Phone, MobilePhone, MailingStreet, MailingCity, MailingState, MailingPostalCode, OtherStreet, OtherCity, OtherState, OtherPostalCode FROM Contact WHERE FirstName = :firstName AND LastName = :lastName AND Email = :email];
            if(!contacts.isEmpty()) {
                return contacts.get(0);
            } else {
                return null;
            }
        }

        /**
        @description Creates an Application linked to the specified Enquiry and Contact
        @param enquiryId The Id of the Enquiry created under the register method
        @param contactId The Id of the Contact created under the register method
        @return The Id of the created Application
        @revision 
        **/
        public String createApplication(String enquiryId, String contactId) {
            Application__c application = new Application__c();
            application.Status__c = 'Registered - Not paid';
            application.Enquiry_Number__c = enquiryId;
            application.Applicant__c = contactId;

            insert application;
            return application.Id;
        }

        /**
        @description Creates an Application Course Preference (ACP) with the specified data
        @param Various data from the earlier created Contact, Application and Course Offering
        @revision 
        **/
        public void createApplicationCoursePreference(String contactId, String applicationId, String courseOfferingId, String courseId, String courseTitle, String courseCode, String status, String facultyType, String courseType) {
            
            Application_Course_Preference__c acp = new Application_Course_Preference__c();
            acp.Applicant__c = contactId;
            acp.Application__c = applicationId;
            acp.Status__c = 'Registered - EOI Only';
            acp.Course_Offering__c = courseOfferingId;
            acp.Course_Title__c = courseTitle;
            acp.Course_Code__c = courseCode;
            acp.Course__c = courseId;
            acp.Managing_Faculty_Text__c = facultyType;
            acp.Course_Type_Text__c = courseType;
            insert acp;
        }

        /**
        @description Creates an Enquiry with the specified data
        @param Various data from the Aura component, Contact and Course Offering
        @return The Id of the created Enquiry
        @revision 
        **/
        public String createEnquiry(String contactId, String courseOfferingId, String heardFrom, String status, String description, String faculty) {

            TriggerCommon.disableTrigger('Case');  

            Case enquiry = new Case();
            enquiry.ContactId = contactId;
            enquiry.Subject = 'Online Course Registration';
            enquiry.Description = description;
            enquiry.Heard_About_From__c = heardFrom;
            enquiry.Origin = 'Web';
            enquiry.Course__c = courseOfferingId;
            enquiry.Student_Type__c = 'Domestic';
            enquiry.Enquiry_Type__c = 'Future Course';

            switch on faculty {
                when 'Faculty of Education' {
                    enquiry.Managing_Faculty__c = 'Education';
                }	
                when ('Faculty of Medicine, Nursing & Health Sciences') {
                    enquiry.Managing_Faculty__c = 'Medicine, Nursing and Health Sciences';		
                }
                when ('Faculty of Business & Economics') {
                    enquiry.Managing_Faculty__c =  'Business and Economics';		
                }
                when 'Faculty of Arts' {
                    enquiry.Managing_Faculty__c = 'Arts';
                }
                when 'Monash Sustainable Development Institute' {
                    enquiry.Managing_Faculty__c = 'Monash Sustainable Development Institute';
                }
                when 'Monash Centre for Professional Development' {
                    enquiry.Managing_Faculty__c = 'Monash Centre for Professional Development';
                }
                when else {		  
                }
            }

            enquiry.Status = status;
            enquiry.RecordTypeId = getRecordTypes('Case').get('Professional Development').Id;
            insert enquiry;
            return enquiry.Id;
        }

        /**
        @description Forces the Case Assignment Rule to run on the specified Enquiry
        @param enqId The Id of the Enquiry to be forcibly re-assigned
        @revision 
        **/
        public void reassignEnquiry(String enqId) {
            
            Case enquiry = [SELECT Id FROM Case WHERE Id = :enqId];
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.AssignmentRuleHeader.useDefaultRule = true;
            enquiry.setOptions(dml);

            upsert enquiry;
        }
    }
}