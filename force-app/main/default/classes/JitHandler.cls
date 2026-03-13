/**
 * @description       : JIT (just-in-time) handler implementation for community users logging in via SSO/SAML
 * @author            : Stefan Scheit
 * @group             : Platform
 * @last modified on  : 2021-08-04
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.3   2021-08-05   P.Victoriano    Added inactive user matching logic nad update user 
 * 1.2   2021-08-04   Stefan Scheit   Prioritise student contact records if multiple are found (by authcate__c field)
 * 1.1   2020-09-21   Stefan Scheit   Make User.CommunityNickname unique for new users
 * 1.0   2020-07-23   Stefan Scheit   Initial Version
**/
global with sharing class JitHandler implements Auth.SamlJitHandler {
	
    // User to be returned from JitHandler
    private User myUser = new User();
    
    // JitException
    public class JitException extends Exception{}
    
    // inner class to hold the assertion details
    private AssertionDetails assertDetails = null;
    
    // community name (to be set on User)
    private String communityName = null;
    
    global User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> attributes, String assertion) {
        try{
            // Obtain community name
            if (String.isNotBlank(String.valueOf(communityId))) {
                List<Network> networkList = [SELECT Id, Name FROM Network WHERE Id = :communityId LIMIT 1];
                if (!networkList.isEmpty()) {
                    communityName = networkList[0].Name;
                }
            }

            // Initialise details from SAML assertion
            assertDetails = new AssertionDetails(attributes);
            System.debug(LoggingLevel.FINE, 'Assertion details: '+assertDetails);
               
            // Try to find existing Contact record AND prioritise student records (with person id present)
            List<Contact> exisitingContacts = [SELECT Id, Person_Id_unique__c, SAP_Staff_Id__c, Email, Personal_Email__c, Monash_Email_Address__c, Authcate__c, FirstName, LastName 
                                                FROM Contact 
                                                WHERE Authcate__c = :assertDetails.nameidentifier
                                                ORDER BY Person_Id_unique__c NULLS LAST];
            
            if(exisitingContacts == null || exisitingContacts.size() == 0) {
                /* SCENARIO 1: No Contact record found. Treat them as 'student' (not staff) and create Contact and User records. */    
                // create contact and assoicate with user
                Contact newContact = handleCreateContact(assertDetails.nameidentifier, assertDetails.emailaddress, assertDetails.givenname, assertDetails.surname); // email will be a Monash domain email
                myUser = handleCreateUser(newContact);
            }else if(exisitingContacts != null && exisitingContacts.size() > 0) {
                /* SCENARIO 2: Contact record found (at least one). Either use/update the user linked to it or create a new one */
                // take first Contact record which is usually the student record (with Person_Id_unique__c!=null)
                Contact existingContact = exisitingContacts[0];
                // evaluate whether a user is attached to this contact, update the federationId and return it
                List<User> users = [SELECT Id, Username, FederationIdentifier, IsActive, MonashObjectId__c, Community_Access__c FROM User WHERE ContactId = :existingContact.Id LIMIT 1];
                if (!users.isEmpty()) {
                    // A user is already linked (update federation identifier)
                    myUser = users[0];
                    myUser.FederationIdentifier = existingContact.Authcate__c; // = assertDetails.nameidentifier
                    myUser.isActive = true;
                    myUser.MonashObjectId__c = assertDetails.MonashObjectId;
                    // set field tracking access to current community (as obtained from JitHandler)
                    if (String.isNotBlank(communityName)) {
                        myUser.Community_Access__c = CommonUtilities.appendToMultiPicklist(myUser.Community_Access__c, communityName);
                    }
                } else {
                    // No user is linked
                    // Check email(s) of existing contact (i.e. ensure one is availabe to assign to the new user later on)
                    if (String.isBlank(existingContact.Email) && String.isBlank(existingContact.Personal_Email__c) && String.isBlank(existingContact.Monash_Email_Address__c)) {
                        // set email from the assertion (which will be a Monash domain email)
                        existingContact.Monash_Email_Address__c = assertDetails.emailaddress;
                        update existingContact;
                    }
                    myUser = handleCreateUser(existingContact);
                }
            }
            return myUser;
        } catch(Exception exc) {
            // log async (persistently)
            LogUtilityException.logException(exc, 'User');
            // re-throw exception
            throw exc;
        }
    }
    
    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> attributes, String assertion) {
        // Obtain community name to Community Access on User and add Monash Object Id
        if (String.isNotBlank(String.valueOf(communityId))) {
            List<Network> networkList = [SELECT Id, Name FROM Network WHERE Id = :communityId LIMIT 1];
            if (!networkList.isEmpty()) {
                communityName = networkList[0].Name;
            }
        }
        List<User> usersEx = [SELECT Id, Username, FederationIdentifier, IsActive, MonashObjectId__c, Community_Access__c FROM User WHERE IsActive = false AND Id =:userId LIMIT 1];
        try{
            if(usersEx.isEmpty() == false){
                User myUser = usersEx[0];
                myUser.MonashObjectId__c = assertDetails.MonashObjectId;
                // set field tracking access to current community (as obtained from JitHandler)
                if (String.isNotBlank(communityName)) {
                    myUser.Community_Access__c = CommonUtilities.appendToMultiPicklist(myUser.Community_Access__c, communityName);
                }
                update myUser;
            }
        } catch(Exception exc) {
            // log async (persistently)
            LogUtilityException.logException(exc, 'User');
        }
    }

    /**
     * Method to create a Contact with provided details (from SAML assertion)
     * Consideration: It assumes it is a student as there is not any info to decide between student and staff
     */
    @TestVisible
    private Contact handleCreateContact(String nameidentifier, String email, String firstName, String lastName) {
        // create a new account if not found
        Account newAccount = new Account();
        newAccount.Name = firstName + lastName; 
        insert newAccount;
        Contact newContact = new Contact();
        newContact.FirstName = firstName;
        newContact.LastName = lastName;
        // check for type of email address
        if (EmailServices.isMonashEmail(email)) {
            // email from assertion is a Monash email (should be the case)
            newContact.Monash_Email_Address__c = email;
        } else {
            // email from assertion is a non-Monash email address (not expected)
            newContact.Personal_Email__c = email;
        }
        //newContact.Email = email;
        newContact.Accountid = newAccount.Id;
        newContact.Authcate__c = nameidentifier;
        insert newContact;
        return newContact;
    }

    /**
     * Method to create a (Community) user with the common community profile and linked to the Contact
     */
    @TestVisible
    private User handleCreateUser(Contact contact) {
        
        // Get profile name(s) from custom label
        String profileName = Label.Customer_Community_General_User;
        Profile communityProfile = null;
        if(String.isEmpty(profileName)) {
            throw new JitException('Configuration data (custom profile) could not be read.'); 
        }
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name = :profileName LIMIT 1];
        if (!profiles.isEmpty()) {
            communityProfile = profiles[0];
        } else {
            throw new JitException('Profile could not be found by name ('+profileName+').');
        }
        
        // preference for personal email address as username for community users
        String preferredEmail = '';
        if (String.isNotBlank(contact.Personal_Email__c)) {
            preferredEmail = contact.Personal_Email__c;            
        } else if (String.isNotBlank(contact.Email)) {
            preferredEmail = contact.Email;
        } else if (String.isNotBlank(contact.Monash_Email_Address__c)) {
            preferredEmail = contact.Monash_Email_Address__c;
        } else {
            // we should not get here (no email available)
            throw new JitException('No email available to assign to new user.');
        }

        // evaluate if user name is available (can clash with active or inactive users)
        List<User> listUser = [SELECT Id, Username, FederationIdentifier FROM User WHERE Username = :preferredEmail LIMIT 1];
        if (!listUser.isEmpty()) {
            // user name is already taken (do not attempt to re-use existing user record and log non-fatal exception message)
            LogUtilityException.logExceptionMSG('JitHandler', preferredEmail , 'User name to be assigned ('+listUser[0].Username+') to the new SSO user is already in use. Attempting to use the email from the assertion ('+assertDetails.emailaddress+') instead.');
            
            // fallback, attempt to use assertDetails.emailaddress instead
            preferredEmail = assertDetails.emailaddress;
            listUser = [SELECT Id, Username, FederationIdentifier FROM User WHERE Username = :preferredEmail LIMIT 1];
            if (!listUser.isEmpty()) {
                // user name (from SAML assertion) is already taken (no alternative to throwing a fatal error)
                throw new JitException('Fallback username (from the SAML assertion email address: '+listUser[0].Username+') is already in use.');
            }
        }
        // fetch running user to grab locale
        User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id = :UserInfo.getUserId()];
        User newUser = new User();
        newUser.ContactId = contact.Id;
        newUser.Username = preferredEmail;
        newUser.MonashObjectId__c = assertDetails.monashObjectID;
        newUser.FederationIdentifier = contact.Authcate__c;
        newUser.ProfileId = communityProfile.Id;
        newUser.IsActive = true;
        // set value to current community being attempted to access (as obtained from JitHandler)
        if (String.isNotBlank(communityName)) {
            newUser.Community_Access__c = communityName;
        }
        newUser.Email = preferredEmail;
        newUser.FirstName = contact.FirstName;
        newUser.LastName = contact.LastName;
        newUser.LocaleSidKey = currentUser.LocaleSidKey;
        newUser.LanguageLocaleKey = currentUser.LanguageLocaleKey;
        newUser.EmailEncodingKey  = currentUser.EmailEncodingKey ;
        newUser.TimeZoneSidKey = currentUser.TimeZoneSidKey;
        String alias = CommonUtilities.createAliasForUser(newUser.FirstName,newUser.LastName);
        
        newUser.Alias = alias;
        newUser.CommunityNickname = alias + Datetime.now().getTime(); // CommunityNickname has a max of 40 char: alias (max 8 char) + datetime (13 char)
        return newUser;
    }
    
    /**
     * Inner class (value object) for SAML assertion details
     */
    @TestVisible
    private class AssertionDetails {
        @TestVisible
        private String monashObjectID {
            get{
                if(String.isBlank(monashObjectID)) {
                    throw new JitException('The SAML assertion does not contain the property for \'monashObjectID\'.');
                } else {
                    return monashObjectID;
                }
            }
            set;
        }
        @TestVisible
        private String nameidentifier {
            get {
                if(String.isBlank(nameidentifier)) {
                    throw new JitException('The SAML assertion does not contain the property for \'nameidentifier\'.');
                } else {
                    return nameidentifier;
                }
            }
            set;
        }
        @TestVisible
        private String givenname  {
            get{
                if(String.isBlank(givenname)) {
                    throw new JitException('The SAML assertion does not contain the property for \'givenname\'.');
                } else {
                    return givenname;
                }
            }
            set;
        }
        @TestVisible
        private String surname  {
            get{
                if(String.isBlank(surname)) {
                    throw new JitException('The SAML assertion does not contain the property for \'surname\'.');
                } else {
                    return surname;
                }
            }
            set;
        }
        @TestVisible
        private String emailaddress {
            get{
                if(String.isBlank(emailaddress)) {
                    throw new JitException('The SAML assertion does not contain the property for \'emailaddress\'.');
                } else {
                    return emailaddress;
                }
            }
            set;
        }
        
        /**
         * Constructor that also initialises the attributes
         */
        @TestVisible
        public AssertionDetails(Map<String,String> assertionAttributes) {
            String prefix = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/';
            if(assertionAttributes.containsKey(prefix+'monashObjectID')) {
                this.monashObjectID = assertionAttributes.get(prefix+'monashObjectID');
            }
            if(assertionAttributes.containsKey(prefix+'nameidentifier')) {
                this.nameidentifier = assertionAttributes.get(prefix+'nameidentifier');
            }
            if(assertionAttributes.containsKey(prefix+'givenname')) {
                this.givenname = assertionAttributes.get(prefix+'givenname');
            }
            if(assertionAttributes.containsKey(prefix+'surname')) {
                this.surname  = assertionAttributes.get(prefix+'surname');
            }
            if(assertionAttributes.containsKey(prefix+'emailaddress')) {
                this.emailaddress = assertionAttributes.get(prefix+'emailaddress');
            }
        }
    }
}