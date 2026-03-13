/**
 * @author Inderpal Dhanoa
 * @date 9/20/2023
 * @group ERDA
 * @group-content 
 * @description A LWC page controller that allows Alumni OnBoarding
 * @last modified on  : 2023-03-20
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author              Modification  
 * 1.0   2023-03-20 - Inderpal Dhanoa - Initial Version
**/
public without sharing class OnBoardAlumniController { 

    /**
    * Method to validate contact Details, 
    *
    * @param: s_id                      Id of the JWT Token
    * @param: s_dateOfBirth             Date of Birth from the User
    * @param: s_captchaTokenKey         Google captcha Token
    * retrun: ContactWrapper            Wrapper of the Contact Object
    */
    @AuraEnabled
    public static ContactWrapper validateContactInfo(String s_id, String s_dateOfBirth, String s_captchaTokenKey){
        ContactWrapper contWrapperObj = new ContactWrapper(); 
        contWrapperObj.s_userStatus = null;
        try{
            // Check if User has entered a Captcha
            if(Test.isRunningTest() || ReCaptchaService.validateCaptchaToken(s_captchaTokenKey)){ 
                
                // Contact Validated for Registration Id & date Of Birth
                Date dtDateOfBirth = Date.valueOf(s_dateOfBirth);
                List<Contact> unRegisteredContact = validateTokenAndBirthdate(s_id, dtDateOfBirth);
                if(!unRegisteredContact.isEmpty()){
                    List<User> preRegisteredUser = [SELECT Id, FirstName, LastName, UserName, Contact.Email , (SELECT Id,PermissionSet.Name,AssigneeId FROM PermissionSetAssignments) 
                                                    FROM User 
                                                    WHERE ContactId = :unRegisteredContact[0].Id AND Contact.Birthdate = :unRegisteredContact[0].Birthdate];
                    if(!preRegisteredUser.isEmpty()){
                        // Need to check if the user has a different EMail on Contact vs User
                        // User Exists and check the assigned Perm Sets
                        for(PermissionSetAssignment assignedPermSet : preRegisteredUser[0].PermissionSetAssignments){
                            if(assignedPermSet.PermissionSet.Name == Label.Alumni_Portal_Permission_Set){
                                contWrapperObj.s_firstname = preRegisteredUser[0].FirstName;
                                contWrapperObj.s_lastname = preRegisteredUser[0].LastName;
                                contWrapperObj.s_userName = preRegisteredUser[0].UserName ; 
                                contWrapperObj.s_userStatus = 'AlumniUser';
                                return contWrapperObj;
                            }
                        }
                        // Check if the User has none of the Perm Sets assigned  
                        If(String.isBlank(contWrapperObj.s_userStatus)){
                            contWrapperObj.s_firstname = preRegisteredUser[0].FirstName;
                            contWrapperObj.s_lastname = preRegisteredUser[0].LastName;
                            contWrapperObj.s_userName = preRegisteredUser[0].UserName ;
                            contWrapperObj.s_userStatus = 'NonAlumniUser';
                        }
                    }else{  
                        // Contact does not exist
                        if(!unRegisteredContact.isEmpty()){
                            // Check if the Contact has a valid Email 
                            if(String.isNotBlank(unRegisteredContact[0].Personal_Email__c ) && CommonUtilities.validateEmail(unRegisteredContact[0].Personal_Email__c )){
                                // Do we need to check if the Email exists as another User 
                                List<User> duplicateUser = [SELECT Id, UserName FROM User WHERE Username = :unRegisteredContact[0].Personal_Email__c];
                                if(duplicateUser.isEmpty()){
                                    contWrapperObj = new ContactWrapper();
                                    contWrapperObj.s_firstname = unRegisteredContact[0].FirstName;
                                    contWrapperObj.s_lastname = unRegisteredContact[0].LastName;
                                    contWrapperObj.s_userName = unRegisteredContact[0].Personal_Email__c ;
                                    contWrapperObj.s_userStatus = 'FreshUser';
                                }else{
                                    // If duplicate User exists then THROW exception ???
                                    throw new AuraHandledException('Duplicate User exists for UserName :'+unRegisteredContact[0].Personal_Email__c);
                                }                        
                            }else{
                                // If no EMail exists then THROW exception ???
                                throw new AuraHandledException('You do not have an Email linked');
                            }
                        }else{
                            // no Contact Id, throw Error
                            throw new AuraHandledException('You do not have a linked Contact or Incorrect Date Of Birth'); 
                        }
                    }
                }  
            }else{
                // Captcha Validation failed, throw Error
                throw new AuraHandledException('You do not have a valid Captcha');
            }            
            return contWrapperObj;
        }catch(Exception ex){
            LogUtilityException.logException(ex);throw ex;
        }
    }

    /**
    * Method to validate token & contact Details, 
    *
    * @param: s_id                      Id of the JWT Token
    * @param: s_dateOfBirth             Date of Birth from the User
    * retrun: List<Contact>             List of the Contact Object
    */
    private static List<Contact> validateTokenAndBirthdate(String s_id, Date dtDateOfBirth){
        // Check for Equals %3D to =
        String jwtUrlDecode = EncodingUtil.urlDecode(s_id, 'UTF-8');
        String jwtString = EncodingUtil.base64Decode(jwtUrlDecode).tostring();
        List<String> jwtParts = jwtString.split('\\.');
        String jwtPayload = jwtParts[1];
        String jwtSignature = jwtParts[2];
        // Convert payload to string and then extract only the ContactID value
        String jwtPayloadDecoded = EncodingUtil.base64Decode(jwtPayload).tostring();
        String jwtPayloadContactId = jwtPayloadDecoded.substringBetween(':\"', '\"');
        String contactID = jwtPayloadContactId;
        String secretKey = String.valueOf(Label.alumniOnboardingMCSecret);
        // Check if contactId exists in contact object
        List<Contact> lstLinkedContact = [SELECT Id, FirstName, LastName, Personal_Email__c,Birthdate FROM Contact WHERE Id = :Id.valueOf(contactId)];

        // Call the generateJWT
        String crmJWT = generateJWT(secretKey, contactId);
        List<String> crmJWTParts = crmJWT.split('\\.');
        String crmJWTSignature = crmJWTParts[2];
        // Compare the Signature for Decision Making
        if (!lstLinkedContact.isEmpty() && jwtSignature == crmJWTSignature) {
            if(lstLinkedContact[0].Birthdate == dtDateOfBirth){
                return lstLinkedContact;
            }else{
                // Captcha Validation failed, throw Error
                throw new AuraHandledException('Date of birth does not match our records, please try again');
            }
        }else{
            throw new AuraHandledException('You do not have a valid URL');
        }
    } 

    /**
    * Method to validate token & contact Details, 
    *
    * @param: s_id                      Id of the JWT Token
    * @param: s_dateOfBirth             Date of Birth from the User
    * retrun: List<Contact>             List of the Contact Object
    */
    private static List<Contact> validateToken(String s_id){
        // Check for Equals %3D to =
        String jwtUrlDecode = EncodingUtil.urlDecode(s_id, 'UTF-8');
        String jwtString = EncodingUtil.base64Decode(jwtUrlDecode).tostring();
        List<String> jwtParts = jwtString.split('\\.');
        String jwtPayload = jwtParts[1];
        String jwtSignature = jwtParts[2];
        // Convert payload to string and then extract only the ContactID value
        String jwtPayloadDecoded = EncodingUtil.base64Decode(jwtPayload).tostring();
        String jwtPayloadContactId = jwtPayloadDecoded.substringBetween(':\"', '\"');
        String contactID = jwtPayloadContactId;
        String secretKey = String.valueOf(Label.alumniOnboardingMCSecret);
        // Check if contactId exists in contact object
        List<Contact> lstLinkedContact = [SELECT Id, FirstName, LastName, Personal_Email__c,Birthdate FROM Contact WHERE Id = :Id.valueOf(contactId)];

        // Call the generateJWT
        String crmJWT = generateJWT(secretKey, contactId);
        List<String> crmJWTParts = crmJWT.split('\\.');
        String crmJWTSignature = crmJWTParts[2];
        // Compare the Signature for Decision Making
        if (!lstLinkedContact.isEmpty() && jwtSignature == crmJWTSignature) {
            return lstLinkedContact;
        }else{
            throw new AuraHandledException('You do not have a valid URL');
        }
    } 

    /**
    * Method to generate JWT token 
    *
    * @param: secretKey                 Id of the JWT Token
    * @param: contactId                 Contact Id
    * return: String                    JWT Token generated
    */
    public static String generateJWT(String secretKey, String contactId){ 
        Map<String, Object> header = new Map<String, Object>{
            'typ' => 'JWT',
            'alg' => 'HS256'
        };
        // Must make sure that there isn't any space or wrong spelling in payload, because that will render the jwt differently.
        Map<String, Object> payload = new Map<String, Object>{
            'ID' => contactId
        };
        If(Test.isRunningTest()) {
            secretKey = OnBoardAlumniController_Test.JWTSecret;
        }
        String encodedHeader = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(header))).replace('+', '-').replace('/', '_').replace('=', '');
        String encodedPayload = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(payload))).replace('+', '-').replace('/', '_').replace('=', '');
        Blob signatureBlob = Crypto.generateMac('hmacSHA256', Blob.valueOf(encodedHeader + '.' + encodedPayload), Blob.valueOf(secretKey));
        String signature = EncodingUtil.base64Encode(signatureBlob).replace('+', '-').replace('/', '_').replace('=', '');
        return encodedHeader + '.' + encodedPayload + '.' + signature;
    }

    /**
    * Method to create Enquiry, 
    *
    * @param: s_id                      Id of the JWT Token
    */
    @AuraEnabled
    public static String createEnquiry(String s_id, String s_dateOfBirth){
        List<Contact> registeredContact = validateToken(s_id); 
        try{    
            if(!registeredContact.isEmpty()){ 
                date dtYesterday = date.today();
                dtYesterday = dtYesterday.addDays(-1);
                List<Case> linkedEnquiries = [SELECT Id, caseNumber, ContactId FROM Case WHERE ContactId = :registeredContact[0].Id AND CreatedDate > :dtYesterday];
                if(linkedEnquiries.isEmpty()){
                    // No Enquiry for the last 24 hrs so create one
                    Case relEnquiry = new Case();
                    relEnquiry.RecordTypeId = [SELECT Id, SobjectType FROM recordType WHERE SobjectType = 'Case' AND DeveloperName = 'Alumni_Engagement'].Id;
                    relEnquiry.OwnerId = [select Id, name FROM Group WHERE Name = 'Alumni Engagement' and Type = 'Queue'].Id;
                    relEnquiry.Status = 'New';
                    relEnquiry.Enquiry_Type__c = 'Alumni Portal Enquiry';
                    relEnquiry.Description = 'Date of birth validation failed when trying to activate alumni portal account';
                    relEnquiry.Rich_Description__c = 'Date of birth validation failed when trying to activate alumni portal account';
                    relEnquiry.ContactId = registeredContact[0].Id;
                    relEnquiry.SuppliedEmail = registeredContact[0].Personal_Email__c;
                    insert relEnquiry;

                    relEnquiry = [SELECT Id, caseNumber FROM Case WHERE Id = :relEnquiry.Id]; 

                    return relEnquiry.caseNumber;
                }else{
                    return linkedEnquiries[0].caseNumber;
                }            
            }else{
                // Captcha Validation failed, throw Error
                throw new AuraHandledException('There is an Error during resetting the Registration Id');
            }
        }catch(Exception ex){
            LogUtilityException.logException(ex);throw ex;
        }       
    }

    /**
    * Method to setup Alumni User, 
    *
    * @param: s_id                              Id of the JWT Token
    * @param: s_firstname                       First name of the User
    * @param: s_lastname                        Last name of the User
    * @param: s_userName                        User name of the User
    * @param: s_dateOfBirth                     Date of Birth from the User
    */
    @AuraEnabled
    public static void setupAlumniUser(String s_id, String s_firstname, String s_lastname, String s_userName, String s_dateOfBirth){
        try{
            Date dtDateOfBirth = Date.valueOf(s_dateOfBirth);
            List<Contact> unRegisteredContact = validateTokenAndBirthdate(s_id, dtDateOfBirth);
            if(!unRegisteredContact.isEmpty()){
                // Validate DoB & Contact again
                Id profileId = [SELECT id FROM Profile WHERE name ='Customer Community General User' LIMIT 1].Id;

                // create new user instead
                String alias = CommonUtilities.createAliasForUser(s_firstname,s_lastname);
                String nickname = CommonUtilities.createNicknameForUser(s_firstname,s_lastname,1);
                User newAlumUser = new User();
                newAlumUser.LastName = s_lastname;
                newAlumUser.FirstName = s_firstname;
                newAlumUser.Username = s_userName;
                newAlumUser.CommunityNickname =nickname+Datetime.now().getTime();
                newAlumUser.ContactId = Id.valueOf(unRegisteredContact[0].Id);
                newAlumUser.Email = s_userName;
                newAlumUser.ProfileId = profileId; 
                newAlumUser.EmailEncodingKey = 'UTF-8';
                newAlumUser.TimeZoneSidKey = 'Australia/Sydney';
                newAlumUser.LanguageLocaleKey = 'en_US';
                newAlumUser.LocaleSidKey = 'en_AU';
                newAlumUser.Alias = alias;
                newAlumUser.Messaging_Opt_In__c = true;
                insert newAlumUser;

                addPermSets(newAlumUser.Id, new List<String>{'Alumni_Portal_Permission_Set', 'Experience_Custom_MFA'});
                //resetContactRegistrationId(s_id);
            }else{
                // Captcha Validation failed, throw Error
                throw new AuraHandledException('An Error occurred');
            }                
        }catch(Exception ex){
            LogUtilityException.logException(ex);throw ex;
        }
    }

    /**
    * Method to extend User As Alumni, 
    *
    * @param: s_id                      Id of the JWT Token
    */
    @AuraEnabled
    public static void extendUserAsAlumni(String s_id, String s_dateOfBirth){
        try{
            List<Contact> registeredContact = validateTokenAndBirthdate(s_id, Date.valueOf(s_dateOfBirth));
            if(!registeredContact.isEmpty()){
                List<User> preRegisteredUser = [SELECT Id, UserName, Contact.Email, (SELECT Id,PermissionSet.Name,AssigneeId FROM PermissionSetAssignments) 
                                            FROM User 
                                            WHERE ContactId = :registeredContact[0].Id];
                addPermSets(preRegisteredUser[0].Id, new List<String>{'Alumni_Portal_Permission_Set'});
            }else{
                throw new AuraHandledException('An Error has occurred');
            }            
            //resetContactRegistrationId(s_id);
        }catch(Exception ex){
            LogUtilityException.logException(ex);throw ex;
        }
    }

    /**
    * Method to add permission sets
    *
    * @param: userId                    Id of the User
    * @param: l_newPermSets             List of permission Set Name
    */
    @AuraEnabled
    public static void addPermSets(Id userId, List<String> l_newPermSets){
        try{
            // Add MFA & Alumni Perm Set
            List<PermissionSetAssignment> newUserPermSetList = new List<PermissionSetAssignment>(); 
            for(PermissionSet assignPermSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :l_newPermSets]){
                // create a permission set instead
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.PermissionSetId = assignPermSet.Id;
                psa.AssigneeId = userId;
                newUserPermSetList.add(psa);
            }
            insert newUserPermSetList;
        }catch(Exception ex){
            LogUtilityException.logException(ex);throw ex;
        }
    }

    public class ContactWrapper{
        @AuraEnabled
        public String s_firstname;
        @AuraEnabled
        public String s_lastname;
        @AuraEnabled
        public String s_userName;
        @AuraEnabled 
        public String s_userStatus;
    }
}