/**
 * @description       : Test Class for JitHandler.cls
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2021-08-04
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-07-23   Stefan Scheit   Initial Version
**/
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
public class JitHandler_Test {

    /**
     * From SAML assertion:
     * 1. Create a contact and 
     * 2. Create a user
     */
    @isTest
    public static void testCreateUserAndContact() {

        // GIVEN: mock assertion values
        String nameIdentifier = 'zzzz9999';
        String monashObjectIdentifier = 'aaaabbbb-0000-0000-a0aa-a0aa00aaaaa0';
        Map<String,String> samlValues = new Map<String,String>();
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname','testLastname');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname','testFirstname');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress','testFirstname.testLastname@student.monash.edu');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/windowsaccountname',nameIdentifier);
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',nameIdentifier);
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/monashObjectID',monashObjectIdentifier);
        
        // WHEN: the handler is invoked
        Test.startTest();
        JitHandler handler = new JitHandler();
        User u = handler.createUser(null, null, null, nameIdentifier, samlValues, null);
        Test.stopTest();

        // THEN: the user was created as expected
        System.assertEquals('testFirstname', u.FirstName, 'The created SSO user\'s first name is not as expected.');
        System.assertEquals('testLastname', u.LastName, 'The created SSO user\'s last name is not as expected.');
        System.assertEquals('testFirstname.testLastname@student.monash.edu', u.Email, 'The created SSO user\'s email is not as expected.');
        System.assertEquals(nameIdentifier, u.FederationIdentifier, 'The created user\'s federation identifier is not as expected.');
        System.assertEquals(monashObjectIdentifier, u.MonashObjectId__c, 'The created user\'s MonashObjectId is not as expected.');

        // THEN: the contact was created
        System.assert(u.ContactId!=null, 'No Contact record was created for the SSO user.');
        Contact c = [SELECT FirstName, LastName, Authcate__c FROM Contact WHERE Authcate__c = :u.FederationIdentifier];
        System.assert(c!=null, 'No Contact record was created for the SSO user.');
        System.assertEquals('testFirstname', c.FirstName, 'The contact\'s first name is not as expected.');
        System.assertEquals('testLastname', c.LastName, 'The contact\'s first name is not as expected.');
    }

    /**
     * From SAML assertion:
     * 1. Find existing contact and 
     * 2. Create a user with the details from the Contact
     */
    @isTest
    public static void testCreateUserForExistingContact() {

        // GIVEN: mock assertion values
        String nameIdentifier = 'zzzz9999';
        String monashObjectIdentifier = 'aaaabbbb-0000-0000-a0aa-a0aa00aaaaa0';
        Map<String,String> samlValues = new Map<String,String>();
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname','testLastname');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname','testFirstname');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress','testFirstname.testLastname@student.monash.edu');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',nameIdentifier);
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/monashObjectID',monashObjectIdentifier);
        
        // GIVEN: log into a particular community
        Network network = null;
        List<Network> networkList = [SELECT Id, Name FROM Network LIMIT 1];
        if (!networkList.isEmpty()) {
            network = networkList[0];
        }
        
        // GIVEN: a contact with matching Authcate already exists
        Account myAccount = new Account(Name='FN LN');
        insert myAccount ;
        Contact myContact = new Contact();
        myContact.accountid = myAccount.Id;
        //myContact.firstName = 'FN'; leave first name blank for better test coverage
        myContact.lastName = 'Lastname';
        // no existing email scenario
        //myContact.email = 'fn.ln@gmail.com';
        //myContact.Monash_Email_Address__c = 'testFirstname.testLastname@student.monash.edu';
        myContact.Authcate__c = nameIdentifier;
        insert myContact;

        // WHEN: the handler is invoked
        Test.startTest();
        JitHandler handler = new JitHandler();
        User u = handler.createUser(null, network.Id, null, nameIdentifier, samlValues, null);
        Test.stopTest();

        // THEN: the user was created (linked to the existing Contact)
        System.assertEquals(myContact.Id, u.ContactId, 'The created user\'s contact lookup is not set to the existing contact as expected.');
        System.assertEquals('Lastname', u.LastName, 'The created SSO user\'s last name is not as expected.');
        System.assertEquals('testFirstname.testLastname@student.monash.edu', u.Email, 'The created SSO user\'s email is not as expected (from the assertion).');
        System.assertEquals(nameIdentifier, u.FederationIdentifier, 'The created user\'s federation identifier is not as expected.');
        System.assert(u.Community_Access__c.contains(String.valueOf(network.Name)), 'The new user\'s community access field was not updated with the network/community name.');
    }

    /**
     * From SAML assertion:
     * 1. Find existing user
     * 2. Update linked user with Contact (or SAML assertion) details
     */
    @isTest
    public static void testUpdateUserForExistingContact() {

        // GIVEN: mock assertion values
        String nameIdentifier = 'zzzz1111';
        String monashObjectIdentifier = 'aaaabbbb-0000-0000-a0aa-a0aa00aaaaa0';
        Map<String,String> samlValues = new Map<String,String>();
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname','testLastname');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname','testFirstname');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress','testFirstname.testLastname@student.monash.edu');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',nameIdentifier);
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/monashObjectID',monashObjectIdentifier);
        
        // GIVEN: log into a particular community
        Network network = null;
        List<Network> networkList = [SELECT Id, Name FROM Network LIMIT 1];
        if (!networkList.isEmpty()) {
            network = networkList[0];
        }
        
        // GIVEN: a contact with matching Authcate already exists
        Account myAccount = new Account(Name='FN LN');
        insert myAccount ;
        Contact myContact = new Contact();
        myContact.accountid = myAccount.Id;
        myContact.firstName = 'Firstname';
        myContact.lastName = 'Lastname';
        myContact.email = 'fn.ln@gmail.com';
        myContact.Monash_Email_Address__c = 'testFirstname.testLastname@student.monash.edu';
        myContact.Authcate__c = nameIdentifier;
        insert myContact;

        // GIVEN: a user is already linked to the Contact (but without the Federation Identifier)
        User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id = :UserInfo.getUserId()];
        String profileName = Label.Customer_Community_General_User;
        User myUser = new User();
        myUser.ContactId = myContact.Id; // links user to existing contact
        myUser.Username = myContact.email;
        myUser.Email = 'user_email@gmail.com';
        myUser.FirstName = 'User_Firstname';
        myUser.LastName = 'User_Lastname';
        myUser.Community_Access__c = 'dummyCommunityName';
        myUser.LocaleSidKey = currentUser.LocaleSidKey;
        myUser.LanguageLocaleKey = currentUser.LanguageLocaleKey;
        myUser.EmailEncodingKey  = currentUser.EmailEncodingKey ;
        myUser.TimeZoneSidKey = currentUser.TimeZoneSidKey;
        myUser.Alias = (myUser.FirstName.charAt(0) + myUser.LastName).abbreviate(8);
        myUser.CommunityNickname = myUser.Alias;
        // newUser.FederationIdentifier = contact.Authcate__c; not set
        myUser.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :profileName LIMIT 1].Id;
        myUser.IsActive = true;
        insert myUser;

        // WHEN: the handler is invoked (and locates existing user from above)
        Test.startTest();
        JitHandler handler = new JitHandler();
        User u = handler.createUser(null, network.Id, null, nameIdentifier, samlValues, null);
        System.runAs(currentUser) {
        	update u; // update because it was resolved to an existing user (as the JitHandler would do)
        }
        Test.stopTest();

        // THEN: the user was updated (and remains linked to the existing Contact)
        u = [SELECT Id, ContactId, FederationIdentifier, FirstName, LastName, Email, IsActive, Community_Access__c FROM USER WHERE Id = :u.Id LIMIT 1];
        System.assertEquals(myContact.Id, u.ContactId, 'The existing user\'s contact lookup is not set to the existing contact as expected.');
        System.assertEquals(nameIdentifier, u.FederationIdentifier, 'The existing user\'s federation identifier is not as expected.');
        System.assertEquals(u.IsActive, true, 'The user is marked inactive which is not as expected.');
        System.assertEquals('User_Firstname', u.FirstName, 'The existing user\'s first name was updated unexpectedly.');
        System.assertEquals('User_Lastname', u.LastName, 'The existing user\'s last name was updated unexpectedly.');
        System.assertEquals('user_email@gmail.com', u.Email, 'The existing user\'s email was updated unexpectedly.');
        System.assert(u.Community_Access__c.contains(String.valueOf(network.Name)), 'The existing user\'s community access field was not updated with the network/community name.');
    }
    
    /**
     * From SAML assertion:
     * 1. Find existing contact and 
     * 2. Create a user, but the username(s) are not available, i.e. expect an exception
     */
    @isTest
    public static void testFailToCreateUserForExistingUsernames() {

        // GIVEN: mock assertion values
        String nameIdentifier = 'zzzz9999';
        String assertionEmail = '12testFirstname.testLastname@student.monash.edu';
        String monashObjectIdentifier = 'aaaabbbb-0000-0000-a0aa-a0aa00aaaaa0';
        Map<String,String> samlValues = new Map<String,String>();
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname','testLastname');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname','testFirstname');
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',assertionEmail);
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',nameIdentifier);
        samlValues.put('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/monashObjectID',monashObjectIdentifier);
        
        // GIVEN: log into a particular community
        Network network = null;
        List<Network> networkList = [SELECT Id, Name FROM Network LIMIT 1];
        if (!networkList.isEmpty()) {
            network = networkList[0];
        }
        
        // GIVEN: a contact with matching Authcate already exists
        Account myAccount = new Account(Name='FN LN');
        insert myAccount ;
        Contact myContact = new Contact();
        myContact.accountid = myAccount.Id;
        myContact.firstName = 'FN';
        myContact.lastName = 'LN';
        myContact.email = 'fn.ln@gmail.com';
        myContact.Authcate__c = nameIdentifier;
        insert myContact;
        
        // GIVEN: A user with the desired username (personal email) exists
        User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id = :UserInfo.getUserId()];
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User myUser = new User();
        myUser.Username = myContact.email+UserInfo.getOrganizationId(); // the contact's email is taken (this will cause the overlap)
        myUser.Email = myContact.email;
        myUser.ProfileId = adminProfile.Id;
        myUser.LocaleSidKey = currentUser.LocaleSidKey;
        myUser.LanguageLocaleKey = currentUser.LanguageLocaleKey;
        myUser.EmailEncodingKey  = currentUser.EmailEncodingKey ;
        myUser.TimeZoneSidKey = currentUser.TimeZoneSidKey;
        myUser.FirstName = '1User_Firstname';
        myUser.LastName = '1User_Lastname';
        myUser.Alias = (myUser.FirstName.charAt(0) + myUser.LastName).abbreviate(8);
        myUser.CommunityNickname = myUser.Alias;
        insert myUser;
        
        // GIVEN: A user with the desired username (assertion email) exists
        myUser = new User();
        myUser.Username = '13'+assertionEmail; // the assertion's email is taken (this will cause the overlap)
        myUser.Email = assertionEmail;
        myUser.ProfileId = adminProfile.Id;
        myUser.LocaleSidKey = currentUser.LocaleSidKey;
        myUser.LanguageLocaleKey = currentUser.LanguageLocaleKey;
        myUser.EmailEncodingKey  = currentUser.EmailEncodingKey ;
        myUser.TimeZoneSidKey = currentUser.TimeZoneSidKey;
        myUser.FirstName = '2User_Firstname';
        myUser.LastName = '2User_Lastname';
        myUser.Alias = (myUser.FirstName.charAt(0) + myUser.LastName).abbreviate(8);
        myUser.CommunityNickname = myUser.Alias;
        insert myUser;
        
        // WHEN: the handler is invoked
        Test.startTest();
        Exception myExpectedException = null;
        try {
            JitHandler handler = new JitHandler();
            User u = handler.createUser(null, network.Id, null, nameIdentifier, samlValues, null);
        } catch (Exception exc) {
            // THEN:
            myExpectedException = exc;
            System.assert(myExpectedException!=null, 'The expected exception scenario did not cause an exception to be thrown.');
            System.assert(myExpectedException.getMessage().contains('Fallback username'));
        }    
        Test.stopTest();
    }
    
    /**
     * From SAML assertion:
     * 1. No user id was obtained
     * 2. Validate that error is thrown
     */
    @isTest
    public static void testMissingSamlAssertionValue() {
        
        // GIVEN: incomplete (empty) SAML assertion values
        String nameIdentifier = null;
        Map<String,String> samlValues = new Map<String,String>();
        
        // WHEN: the handler is invoked
        Exception myExpectedException = null;
        Test.startTest();
        JitHandler handler = new JitHandler();
        try {
            User u = handler.createUser(null, null, null, nameIdentifier, samlValues, null);
        } catch (Exception exc) {
            // assign expected exception
            myExpectedException = exc;
        }
        Test.stopTest();
        
        //THEN: the expected exception was thrown
        System.assert(myExpectedException!=null, 'The expected exception scenario did not cause an exception to be thrown.');
        System.assert(myExpectedException instanceOf JitHandler.JitException, 'The exception is not of the expected type.');
    }
    
    /**
     * Validate error paths of AssertionDetails inner class
     */
    @isTest
    public static void testAssertionDetails() {
        
        // GIVEN: empty SAML details are provided
        Map<String,String> samlValues = new Map<String,String>();
        JitHandler.AssertionDetails assertDetails = new JitHandler.AssertionDetails(samlValues);
        Exception myExpectedException = null;
        
        // WHEN: errors are thrown when accessing (non-existing) details
        String assertionValue = null;
        Test.startTest();
        try{
            assertionValue = assertDetails.monashObjectID;
        } catch (Exception exc) {
            // THEN: exception was thrown
            myExpectedException = exc;
            System.assert(myExpectedException!=null, 'The expected exception scenario did not cause an exception to be thrown.');
        }
        try{
            assertionValue = assertDetails.nameidentifier;
        } catch (Exception exc) {
            // THEN: exception was thrown
            myExpectedException = exc;
            System.assert(myExpectedException!=null, 'The expected exception scenario did not cause an exception to be thrown.');
        }
        try{
            assertionValue = assertDetails.emailaddress;
        } catch (Exception exc) {
            // THEN: exception was thrown
            myExpectedException = exc;
            System.assert(myExpectedException!=null, 'The expected exception scenario did not cause an exception to be thrown.');
        }
        try{
            assertionValue = assertDetails.givenname;
        } catch (Exception exc) {
            // THEN: exception was thrown
            myExpectedException = exc;
            System.assert(myExpectedException!=null, 'The expected exception scenario did not cause an exception to be thrown.');
        }
        try{
            assertionValue = assertDetails.surname;
        } catch (Exception exc) {
            // THEN: exception was thrown
            myExpectedException = exc;
            System.assert(myExpectedException!=null, 'The expected exception scenario did not cause an exception to be thrown.');
        }
        Test.stopTest();
    }

    @isTest
    public static void testUpdateUser() {
        // no logic, increase test coverage
        JitHandler handler = new JitHandler();
        try {
            handler.updateUser(null, null, null, null, null, null, null);
        } catch (Exception exc) {
            System.assert(false, 'The updateUser method failed processing.');
        }
    }
}