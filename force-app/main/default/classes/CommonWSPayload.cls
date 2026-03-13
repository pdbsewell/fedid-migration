/**
 * @description Contains Payload structure for commonly used objects
 * @author      Nick Guia
 * @since       JUL.30.2024
 * @group admissions
 */
// @SuppressWarnings('PMD') // workaround to block requiring ApexDoc for getter/setters
@SuppressWarnings('PMD.ApexDoc')
public inherited sharing class CommonWSPayload {

    /**
     * @description Apex version of the Country attribute object
     */
    public class Country {
        public Id id { get; set; } // record Id
        public String name { get; set; } // Name
        public String callistaCode { get; set; } // Callista_Code__c
        public String callistaCountry { get; set; } // Callista_Country__c
        public String uniqueCountryExternalId { get; set; } // Callista_Country__c
        public String crmRecordId { get; set; } // Callista_Country__c
    }

    /**
     * @description Apex version of the Email object
     */
    public class Email {
        public String type { get; set; }
        public String email { get; set; }
    }

    /**
     * @description Apex version of the Phone object
     */
    public class Phone {
        public String type { get; set; }
        public String phoneNumber { get; set; }
    }

    /**
     * @description Apex version of the Address object
     */
    public class Address {
        public String street { get; set; }
        public String city { get; set; }
        public String country { get; set; }
        public String geoCodeAccuracy { get; set; }
        public String latitude { get; set; }
        public String longitude { get; set; }
        public String postalCode { get; set; }
        public String state { get; set; }
        public String type { get; set; }
    }
	public class Status {
		public String code;
		public String value;
		public String hasRefusedEntry;
        public String hasBreachedVisa;
        public String hasMedicalIssues;
        public String hasProtectionVisa;
        public String hasConvictedOfCrime;

	}

    /**
     * @description Returns the phone number for a given type
     * @param phones List of Phone objects
     * @param type The type of phone number to return
     * @return The phone number for the given type
     */
    public static String getPhoneNumber(List<Phone> phones, String type) {
        for (Phone phone : phones) {
            if (phone.type.equalsIgnoreCase(type)) {
                return phone.phoneNumber;
            }
        }
        return '';
    }

    /**
     * @description Returns the email for a given type
     * @param emails List of Email objects
     * @param type The type of email to return
     * @return The email for the given type
     */
    public static String getEmail(List<Email> emails, String type) {
        for (Email email : emails) {
            if (email.type.equalsIgnoreCase(type)) {
                return email.email;
            }
        }
        return '';
    }
    /** @description The running user */
    public static User runningUser {
        get {
            if(runningUser == null) {
                runningUser = AgentPortalServices.getUser(UserInfo.getUserId());
            }
            return runningUser;
        }
        private set;
    }
    
}