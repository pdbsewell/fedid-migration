//This class provides logic for inbound just-in-time provisioning of single sign-on users in your Salesforce organization.
global class AskMonash_JITHandler implements Auth.SamlJitHandler {
    private class JitException extends Exception {}
    
    global User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> attributes, String assertion) {
        try{
            //create account
            string firstName = '';
            string lastName = '';
            string email = '';
            string fedId = '';
            string ProfileId = '';
            ////Profile Changes - Start - Veera
            string studentProfileName = Label.Community_Student_Profile_Name;
            string staffProfileName = Label.Community_Staff_Profile_Name;
            string generalProfileName = Label.Customer_Community_General_User;
            string profileNamesLabel = Label.JIT_Handler_Profile_Names;
            list<string> profileNameList = profileNamesLabel.split(',');
            map<string,id> jitProfileMap = new map<string,id>();
            for(Profile profile : [SELECT Id,name FROM Profile WHERE name in :profileNameList]) {
                jitProfileMap.put(profile.name, profile.id);
            }
            //Profile Changes - End - Veera
            if (jitProfileMap.isEmpty()){
                throw new JitException();
            }
            if(attributes.containsKey('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname')) {
                firstName  = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname');
            }
            if(attributes.containsKey('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname')) {
                lastName  = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname');
            }
            if(attributes.containsKey('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress')) {
                email = attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress');
            }
            if(attributes.containsKey('http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname')) {
                fedId = attributes.get('http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname');
            }
            
            List<Contact> exisitingContacts = new list<Contact>();
            //try to find a matching contact
            if(String.isNotEmpty(fedId)) {
                exisitingContacts =[SELECT Id, SAP_Staff_Id__c, Person_ID__c FROM Contact WHERE Authcate__c = :fedId];
            }
            
            /** mulitple Contacts exist, should not happen **/
            if(exisitingContacts.size() > 1) {
                throw new JitException();
            }
            
            /** Contact does not exist **/
            if(exisitingContacts==null || exisitingContacts.size()==0) {
                ProfileId = jitProfileMap.get(generalProfileName); // get standard 'Customer Community General User' profile
                if (ProfileId == null || ProfileId =='') {
                    throw new JitException('Standard community user profile not found which is to be assigned during Single-Sign-On');
                }
                //create a new account if not found
                Account myAccount = new Account();
                myAccount.Name = firstName + lastName; 
                insert myAccount ;
                //create Contact with details from SAML assertion
                Contact myContact = new Contact();
                myContact.firstName = firstName;
                myContact.lastName = lastName;
                myContact.email = email ;
                myContact.accountid = myAccount.Id;
                myContact.Authcate__c  = fedId;
                insert myContact;
                //insert user
                User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id = :UserInfo.getUserId()];
                User u = new User();
                u.ContactId = myContact.Id;
                u.userName = email;
                u.email = email ;
                u.firstName = firstName;
                u.lastName = lastName;
                u.LocaleSidKey = currentUser.LocaleSidKey;
                u.LanguageLocaleKey = currentUser.LanguageLocaleKey;
                u.EmailEncodingKey  = currentUser.EmailEncodingKey ;
                u.TimeZoneSidKey = currentUser.TimeZoneSidKey;
                String alias = '';
                if(String.isEmpty(u.FirstName)) {
                    alias = u.LastName;
                } else {
                    alias = u.FirstName.charAt(0) + u.LastName;
                }
                if(alias.length() > 5) {
                    alias = alias.substring(0, 5);
                }
                u.Alias = alias;
                u.CommunityNickname = alias;
                u.FederationIdentifier = fedId;
                u.ProfileId = ProfileId ;
                u.IsActive = true;
                return u;
            }
            
            /** Contacts exist **/
            if(exisitingContacts.size() == 1) {
                //TODO: needs to align to standard profile user and additional permission sets by user group
                //Profile Changes -Start - Veera
                contact validContact = exisitingContacts[0];
                if(String.isNotEmpty(validContact.Person_ID__c)) {
                    ProfileId = jitProfileMap.get(studentProfileName);
                } else if (String.isNotEmpty(validContact.SAP_Staff_Id__c)) {
                    ProfileId = jitProfileMap.get(staffProfileName);
                } else {
                    ProfileId = jitProfileMap.get(generalProfileName);
                }
                if (ProfileId==null || ProfileId=='') {
                    throw new JitException();
                }
                //Profile Changes - End - Veera
                User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id = :UserInfo.getUserId()];
                User u = new User();
                u.ContactId = exisitingContacts[0].Id; // Contact could already have a user record mapped against it. This is prevented in 'ContactServices.MapMonashIdToUser' trigger handler class
                u.userName = email;
                u.email = email;
                u.firstName = FirstName;
                u.lastName = LastName;
                u.LocaleSidKey = currentUser.LocaleSidKey;
                u.LanguageLocaleKey = currentUser.LanguageLocaleKey;
                u.EmailEncodingKey  = currentUser.EmailEncodingKey ;
                u.TimeZoneSidKey = currentUser.TimeZoneSidKey;
                String alias = '';
                if(u.FirstName == null) {
                    alias = u.LastName;
                } else {
                    alias = u.FirstName.charAt(0) + u.LastName;
                }
                if(alias.length() > 5) {
                    alias = alias.substring(0, 5);
                }
                u.Alias = alias;
                u.FederationIdentifier = fedId ;
                u.ProfileId = ProfileId ;
                u.IsActive = true;
                return u; // insert is done by Auth.SamlJitHandler
            }
        }
        catch(Exception e){
            throw new JitException('Unexpected exception in Single-Sign-On flow.');
        }
        return null;
    }
    
    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
                           String federationIdentifier, Map<String, String> attributes, String assertion) {
    }
}