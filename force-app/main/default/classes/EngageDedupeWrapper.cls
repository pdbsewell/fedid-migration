/**
 * @author          Mark Johnson: UC Innovation
 * @description    	Contains wrapper classes used by EngageDedupe prefixed classes.
 * @revision        10/09/2019 - Mark Johnson - Initial version
 * @revision		20.3.2023	Ken McGuire - country of birth replace ISO with SAAC
 */

 public class EngageDedupeWrapper {

    /**
     * @author          Mark Johnson: UC Innovation
     * @description    	Wrapper representing a contact object constructed from Interim
     * @revision        10/09/2019 - Mark Johnson - Initial version
     */
    public virtual class ConstituentWrapper {
        public String firstName {get; set;}
        public String lastName {get; set;}
        public String middleName {get; set;}
        public String salutation {get; set;}
        public String suffix {get; set;}
        public String knownAs {get; set;}

        public String gender {get; set;}

        public String birthYear {get; set;}
        public String birthMonth {get; set;}
        public String birthDay {get; set;}

        public String deceasedYear {get; set;}
        public String deceasedMonth {get; set;}
        public String deceasedDay {get; set;}
        public Boolean deceased {get; set;}

        //public Date dateMarkedDeceased {get; set;}
        public String deceasedSource {get; set;}

        public String constituentType {get;set;}
        public String dataSource {get; set;}

        //public Boolean isActualBirthday {get; set;}

        public String reId {get; set;}
        public String studentId {get; set;}

        //public String maritalStatus {get; set;}

        //public String isActive {get; set;}
        public Boolean givesAnonymously {get; set;}

        public Boolean isSolicitor {get; set;}

        public String source {get; set;}
        public String birthPlace {get; set;}
        public String aboriginalOrTorresStraitIslander {get; set;}
        public String nationality {get; set;}
        public String preferredCountry {get; set;}
        public Boolean doNotEmail {get; set;}

        public Id constituentId {get; set;}


        public ConstituentWrapper() {
        }

        /*******************************************************************************
        * @author       Mark Johnson - UC Innovation
        * @date         10/9/2019 
        * @description  Populates values on the contact.
        *******************************************************************************/ 
        public virtual Contact generateConstituent() {
            Contact constituent;

            if (constituentId == null) {
                constituent = new Contact();
                constituent.RecordTypeId = Contact.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId();
            } else {
                constituent = new Contact(Id = constituentId);
            }

            if (String.isNotBlank(salutation)) constituent.Salutation_ERDA__c = salutation;
            if (String.isNotBlank(firstName)) constituent.FirstName = firstName;
            if (String.isNotBlank(lastName)) constituent.LastName = lastName;
            if (String.isNotBlank(middleName)) constituent.MiddleName = middleName;
            if (String.isNotBlank(suffix)) constituent.Suffix = suffix;
            if (String.isNotBlank(knownAs)) constituent.Known_As__c = knownAs;

            if (String.isNotBlank(gender)) constituent.Gender__c = gender;
            if (String.isNotBlank(birthYear)) constituent.Birth_Year__c = birthYear;
            if (String.isNotBlank(birthMonth)) constituent.Birth_Month__c = birthMonth;
            if (String.isNotBlank(birthDay)) constituent.Birth_Day__c = birthDay;
            //constituent.ucinn_ascendv2__Is_Actual_Birthday__c = isActualBirthday;
            if (String.isNotBlank(deceasedYear)) constituent.Deceased_Date_Year__c = deceasedYear;
            if (String.isNotBlank(deceasedMonth)) constituent.Deceased_Date_Month__c = deceasedMonth;
            if (String.isNotBlank(deceasedDay)) constituent.Deceased_Date_Day__c = deceasedDay;
            if (deceased != null) constituent.Deceased__c = deceased;
            //constituent.ucinn_ascendv2__Date_Marked_Deceased__c = dateMarkedDeceased;
            if (String.isNotBlank(deceasedSource)) constituent.Deceased_Source__c = deceasedSource;
            if (String.isNotBlank(constituentType)) constituent.Contact_Profile__c = constituentType;
            if (String.isNotBlank(source)) constituent.Ucinn_ascendv2__Source__c = source;
            if (String.isNotBlank(dataSource)) constituent.Ucinn_ascendv2__Data_Source__c = dataSource;
            if (isSolicitor != null) constituent.Is_Solicitor__c = isSolicitor;

            if (givesAnonymously != null) constituent.Anonymous_Donor__c = givesAnonymously;
            if (String.isNotBlank(aboriginalOrTorresStraitIslander)) constituent.Aboriginal_or_Torres_Strait_Islander__c = aboriginalOrTorresStraitIslander;
            if (String.isNotBlank(nationality)) constituent.Nationality__c = nationality;
            if (String.isNotBlank(birthPlace)) constituent.Country_Of_Birth__c = birthPlace;
            if (String.isNotBlank(birthPlace)) constituent.CountryOfBirth__c = countryServices.getCountryId(birthPlace,CountryServices.FORMAT_ISO);
            if (String.isNotBlank(preferredCountry)) constituent.Country_Of_Residence__c = preferredCountry;
            if (doNotEmail != null) constituent.HasOptedOutOfEmail = doNotEmail;

            //constituent.Ucinn_ascendv2__Is_Active__c = isActive;

            /*
            if (createdDateTime != null) {
              constituent.CreatedDate = createdDateTime;
            }*/

            return constituent;
        }
    }

    
    /**
     * @author          Mark Johnson: UC Innovation
     * @description    	Wrapper representing an email object constructed from Interim
     * @revision        10/09/2019 - Mark Johnson - Initial version
     */
    public class InterimEmailWrapper {
        public String emailType {get; set;}
        public String emailAddress {get; set;}
        public Boolean emailFound {get; set;}
        public Boolean emailPreferred {get; set;}
        public Boolean isEmailValid {get; set;}
        public String emailImportId {get; set;}
        public Date emailLastChanged {get; set;}
        public String emailSource {get; set;}

        public InterimEmailWrapper(String emailType,
                                   String emailAddress,
                                   Boolean emailFound,
                                   Boolean emailPreferred,
                                   Boolean isEmailValid,
                                   String emailImportId,
                                   Date emailLastChanged,
                                   String emailSource) {
            this.emailType = emailType;
            this.emailAddress = emailAddress;
            this.emailFound = emailFound;
            this.emailPreferred = emailPreferred;
            this.isEmailValid = isEmailValid;
            this.emailImportId = emailImportId;
            this.emailLastChanged = emailLastChanged;
            this.emailSource = emailSource;
        }
    }

    public class InterimPhoneWrapper {
        public String phoneType {get; set;}
        public String phone {get; set;}
        public Boolean phoneFound {get; set;}
        public Boolean phonePreferred {get; set;}
        public Boolean isPhoneValid {get; set;}
        public String phoneImportId {get; set;}
        public Date phoneLastChanged {get; set;}
        public String classification {get; set;}
        public String phoneSource {get; set;}

        public InterimPhoneWrapper(String phoneType,
                                   String phone,
                                   Boolean phoneFound,
                                   Boolean phonePreferred,
                                   Boolean isPhoneValid,
                                   String phoneImportId,
                                   Date phoneLastChanged,
                                   String classification,
                                   String phoneSource) {
            this.phoneType = phoneType;
            this.phone = phone;
            this.phoneFound = phoneFound;
            this.phonePreferred = phonePreferred;
            this.isPhoneValid = isPhoneValid;
            this.phoneImportId = phoneImportId;
            this.phoneLastChanged = phoneLastChanged;
            this.classification = classification;
            this.phoneSource = phoneSource;
        }
    }
    
    /**
     * @author          Mark Johnson: UC Innovation
     * @description    	Wrapper representing an address object constructed from Interim
     * @revision        10/09/2019 - Mark Johnson - Initial version
     */
    public class InterimAddressWrapper {
        public String addressType {get; set;}
        public String addressStreet {get; set;}
        public String addressCity {get; set;}
        public String addressState {get; set;}
        public String addressPostalCode {get; set;}
        public String addressCountry {get; set;}
        public Boolean addressFound {get; set;}
        public Boolean addressPreferred {get; set;}
        public Boolean isAddressValid {get; set;}
        public String addressImportId {get; set;}
        public Date addressDateCreated {get; set;}
        public Date addressDateFrom {get; set;}
        public Date addressDateLastChanged {get; set;}
        public Date addressDateTo {get; set;}
        public String addressSource {get; set;}
        public String classification {get; set;}

        public InterimAddressWrapper(String addressType,
                                     String addressStreet,
                                     String addressCity,
                                     String addressState,
                                     String addressPostalCode,
                                     String addressCountry,
                                     Boolean addressFound,
                                     Boolean addressPreferred,
                                     Boolean isValid,
                                     String addressImportId,
                                     Date addressDateCreated,
                                     Date addressDateFrom,
                                     Date addressDateLastChanged,
                                     Date addressDateTo,
                                     String addressSource,
                                     String classification) {

            this.addressType = addressType; 
            this.addressStreet = addressStreet; 
            this.addressCity = addressCity; 
            this.addressState = addressState; 
            this.addressPostalCode = addressPostalCode; 
            this.addressCountry = addressCountry; 
            this.addressFound = addressFound; 
            this.addressPreferred = addressPreferred;
            this.isAddressValid = isValid;
            this.addressImportId = addressImportId;
            this.addressDateCreated = addressDateCreated;
            this.addressDateFrom = addressDateFrom;
            this.addressDateLastChanged = addressDateLastChanged;
            this.addressDateTo = addressDateTo;
            this.addressSource = addressSource;
            this.classification = classification;
        }
    }
    

    /**
     * @author          Mark Johnson: UC Innovation
     * @description    	Holds the interim id and the wrapper representing the contact.
     * @revision        10/09/2019 - Mark Johnson - Initial version
     */
    public class InterimConstituentWrapper {
        public Id interimId {get; set;}
        public ConstituentWrapper constituentWrapper {get; set;}

        public InterimConstituentWrapper() {

        }

        public InterimConstituentWrapper(Id interimId, ConstituentWrapper constituentWrapper) {
            this.interimId = interimId;
            this.constituentWrapper = constituentWrapper;
        }
    }

}