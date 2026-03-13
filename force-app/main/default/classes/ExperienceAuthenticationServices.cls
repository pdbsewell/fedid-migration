/**
 * @author      Kristian Vegerano
 * @description Services class for authentication actions required for any external facing pages / myapp and partner experience / login / register / forgot password
 *              Services class also used by managePartnerUser lwc which enables internal users to enable a contact as a partner user
 * @group       Services
 * @revision    04/03/2021 - Kristian Vegerano - Created
 *              24/02/2022 - Kristian Vegerano - Update to add functionality required for my.app and alumni portal MFA
 *              28/02/2022 - Kristian Vegerano - Added MFA on partner created applicants
 *              09/08/2022 - Ken McGuire - Security uplift
 *              30/08/2022 - Vinothraja - Enabled creation of user, contact, account without first name, to accomodate mononymous names
 *              5/10/2022 - ken mcguire - added recaptcha 
 *      5/11/2022 - Shalini Mendu - added Experian PS to my.app/partner portal users
 *      14/12/2022 - Ken McGuire - Return more meaningful error messages.
 *      24/01/2023 - Ken McGuire - Improved error handling
 *      14/09/2023 - Peter Sewell - Check for Twilio verified mobile numbers
 *      01/11/2023 - Peter Sewell - Add WES SSO community name to Experience Site Perm Set map so it shows up in Portal Info component
 *      01/11/2023 - Peter Sewell - Assign MFA Permset to a user when they register and the user already exists
 *      06/02/2024 - Peter Sewell - Handle exception if perm set assignment fails due to 'already assigned' error
 */
public with sharing class ExperienceAuthenticationServices {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}
    public String changePasswordError {get; set;}  

    public String identifier {get; set;}
    public String verificationCode {get; set;}  
    public String verificationCodeError {get; set;}

    // Password reset help text - SFTG-2173
    public static final Integer MAX_INVALID_LOGIN_ATTEMPTS = 3;

    // profile name for my.app users
    public static final String MYAPP_PROFILE = 'Customer Community General User';

    //  messages returned to client - could be moved to a constants class
    public static final String RESULT_TYPE_OK = 'OK';
    public static final String RESULT_TYPE_ERROR = 'ERROR';
    public static final String TYPE_ERROR = 'ERROR';

    public static final String RESULT_TYPE_LOCKED = 'LOCKED'; 
    public static final String RESULT_TYPE_NO_MATCH = 'NO_MATCH';
    public static final String RESULT_TYPE_NO_PERMISSIONSET = 'NoPermissionSet';
    public static final String RESULT_TYPE_HAS_DUPLICATE = 'HAS_DUPLICATE';
    public static final String RETURN_RESULT = 'result';
    public static final String RETURN_STATUS = 'STATUS';
    public static final String STATUS_TYPE_SUCCESS = 'SUCCESS';
    public static final String RETURN_MESSAGE = 'message';
    public static final String MESSAGE_UNSAFE_INPUT = 'One or more fields are not in the expected format.  Please correct the input and try again.';
    public static final String MESSAGE_UNSAFE_PARAMETERS = 'Sorry, we encountered an issue. Please try again later.';
    public static final String MESSAGE_INCORRECT_VERIFICATION_CODE = '* You have entered an incorrect verification code';
    public static final String MESSAGE_INVALID_CREDENTAILS = 'Sorry, the details you\'ve entered are incorrect.  Please check your spelling and try again, or reset your password.';
    public static final String MESSAGE_ACCOUNT_LOCKED =  'Your account has been temporarily locked due to too many unsuccessful login attempts. Try again in 15 minutes. You will not be able to reset your password during this time';
    public static final String MESSAGE_PASSWORD_REQUEST_SENT  = 'Password request was sent to the following user name:';
    public static final String MESSAGE_PASSWORD_RESET = 'Password successfully reset and e-mail sent to the User';
    public static final String MESSAGE_INVALID_USER = 'Contact doesn\'t have a valid associated User';
    public static final String MESSAGE_USER_LOCKED =  'User is currently locked out';
    public static final String MESSAGE_NOT_COMMUNITY_USER = 'User is not part of any Communities';
    public static final String MESSAGE_EMPTY_CAPTCHA_TOKEN = 'captcha token can not be empty';
    public static final String MESSAGE_CAPTCHA_NOT_VERIFIED = 'Failed to verify captcha';
    public static final String MESSAGE_CAPTCHA_EXCEPTION = 'An unexpected captcha error occurred.';
    public static final String MESSAGE_ACCOUNT_EXISTS = 'Looks like you already have an account. Please login with your credentials.';
    public static final String MESSAGE_EXCEPTION = 'An unexpected error occurred.';

    @TestVisible
    public static Integer tstFailedLoginAttempts = 0;

    @TestVisible
    public static Boolean tstIsPasswordLocked = false;

    //Permission Set - Experience Site Mapping - SFTG-2041
    public static final Map<String, String> mapPermSetExperience = new Map<String, String> {
        'Customer_Community_My_Application' => 'My.App',
        'Partner_Community_Access' => 'Partner Experience',
        'Alumni_Portal_Permission_Set' => 'Alumni Portal',
        'Customer_Community_Ask_Monash_Student' => 'Ask.Monash, Student Experience',
        'Customer_Community_Ask_Monash_Staff' => 'Ask.Monash',
        'SsoLite_SSO_user' => 'WES Past Student'
    };

    //Experience Site - Reset Password Template - Mapping 
    public static final Map<String, String> mapExperienceEmailTemplate = new Map<String, String> {
        'My.App' => 'AA_Changed_Password_Internal',
        'Partner Experience' => 'Partner_Change_Password_Email_Internal',
        'Alumni Portal' => 'ascend_Portal_Reset_Password',
        'Student Experience' => 'CommunityChangePasswordEmailTemplate',
        'Ask.Monash' => 'CommunityChangePasswordEmailTemplate'
    };

    //Experience Site - Relevant Profile - Mapping 
    public static final Map<String, String> mapExperienceToProfile = new Map<String, String> {
        'My.App' => 'Customer Community General User - Default My.App',
        'Alumni Portal' => 'Customer Community General User - Default Alumni'
    };

    // Partner Access Level - Permission Set Mapping - SFTG-2170
    public static final Map<String, String> PARTNER_ACCESS_MAP = new Map<String, String> {
        AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER => 'Partner_Community_Delegated_Admin',
        AccountTeamConstants.PARTNER_ROLE_DELEGATED_ADMIN => 'Partner_Community_Delegated_Admin',
        AccountTeamConstants.PARTNER_ROLE_STANDARD_USER => ''
    };

    /* constructor */
    public ExperienceAuthenticationServices(){
        changePasswordError = '';   
        verificationCodeError = '';
    }

    /**
     * @author      Kristian Vegerano
     * @description Default method called by the Partner_TwoFactor visualforce page called by the login flow
     * @param       None
     * @return      None
     * @revision    17/03/2021 - Kristian Vegerano - Created
     */
    public PageReference checkTwoFactor(){
        // check if the identity challenge needs to be bypassed or not
        if(new CommitQueryRecords().determineByPassTwoFactor(UserInfo.getUserId())){
            return Auth.SessionManagement.finishLoginFlow('/partner/s/');
        }else{
            sendEmailVerification();
            return null;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Method that initiates the 2FA email
     * @param       None
     * @return      None
     * @revision    23/03/2021 - Kristian Vegerano - Created
     */
    public void sendEmailVerification(){
        verificationCodeError = '';
        identifier = UserManagement.initVerificationMethod(Auth.VerificationMethod.EMAIL);
    }

    /**
     * @author      Kristian Vegerano
     * @description Method that verifies if the entered code matches with the identifier sent to the email
     * @param       None
     * @return      PageReference - page to be redirected from
     * @revision    23/03/2021 - Kristian Vegerano - Created
     */
    public PageReference verifyVerification() {
        PageReference redirectPage;
        verificationCodeError = '';
        // requiring identifier from the initVerification
        // the code will need to be entered in this method
        Auth.VerificationResult verificationResult;
        if(!Test.isRunningTest()){
            verificationResult = UserManagement.verifyVerificationMethod(identifier, verificationCode, Auth.VerificationMethod.EMAIL);
        }
        // check if the match is success, if so redirect to the home page else show error message
        if(Test.isRunningTest() || (verificationResult != null && verificationResult.success)){
            // update last 2fa login of the user
            User contextUser = new User(Id = UserInfo.getUserId(), Last_2FA_Login__c = System.NOW());
            contextUser = new CommitQueryRecords().updateUserRecord(contextUser);
            
            verificationCodeError = '';
            redirectPage = Auth.SessionManagement.finishLoginFlow('/partner/s/');
        }else{
            verificationCodeError = MESSAGE_INCORRECT_VERIFICATION_CODE;
            redirectPage = null;
        }
        return redirectPage;
    }

    /**
     * @author     Ken McGuire
     * @description Method that initiates login action
     * @param       String username
     *              String password
     *              String startUrl
                    String captchaToken
     * @return      Map<String, Object>
     */

    @AuraEnabled
    public static Map<String, Object> loginAuthenticateWithCaptcha(String username, String password, String startUrl,String captchaToken) {
        Map<String,Object> validateResult = validateCaptchaToken(captchaToken);
        if (validateResult.size()>0) return validateResult;
        return loginAuthenticate(username, password, startUrl);
    }

    /**
     * @author      Kristian Vegerano
     * @description Method that initiates login action
     * @param       String username
     *              String password
     *              String startUrl
     * @return      Map<String, Object>
     * @revision    25/03/2020 - Kristian Vegerano - Created
     * @revision    11/08/2022 - Ken McGuire - Security Uplif
     * @revision    15/10/2022 - made privte to incorporate captcha for my.app
     * @revision    17/10/2022 - made public via bug fix to accomodate partner portal dependency (to be removed)
     * @revision    20/10/2022 - made private again after implimenting captcha to partner portal.
     */
    @TestVisible
    private  static Map<String, Object> loginAuthenticate(String username, String password, String startUrl) {
        // Input Guard - do not evaluate password as it may contain special character combinations.
        if (isUnsafe(new List<String>{username,startUrl})) return userMessage(RESULT_TYPE_ERROR,MESSAGE_UNSAFE_INPUT);
        
        Map<String, Object> resultMap = new Map<String, String>();
        Boolean flag;
        Map<String, Object> usr = new CommitQueryRecords().queryUserDetails(username); 
        try{
            // checking if user exists 
            if (usr.IsEmpty()) {
                return userMessage(RESULT_TYPE_ERROR,MESSAGE_INVALID_CREDENTAILS);
            } 
            Integer failedLoginAttempts = (Integer) usr.get('NumberOfFailedLogins');
			failedLoginAttempts = failedLoginAttempts==null?0:failedLoginAttempts;
            
            //if user exits and checking the permission set
            if(startUrl.containsIgnoreCase('partner')){
                flag = true;
            }else{
                flag = getPermissionsetAssignment((Id)usr.get('id'));
            }
            if(flag == true){                
                // user already have permission set

                PageReference authenticationResult = new CommitQueryRecords().authenticateUser(username, password, startUrl);
                if (authenticationResult == null) {
                        resultMap.put(RETURN_RESULT, MESSAGE_INVALID_CREDENTAILS);
                    failedLoginAttempts++;
                    String message = '';
                    if (((Boolean)usr.get('isPasswordLocked')) == true || (MAX_INVALID_LOGIN_ATTEMPTS == failedLoginAttempts)) {
                        message = MESSAGE_ACCOUNT_LOCKED;
                    } else {
                        message = MESSAGE_INVALID_CREDENTAILS +  ' You have '+ (MAX_INVALID_LOGIN_ATTEMPTS - failedLoginAttempts) + ' more login attempt(s) before your account is temporarily locked';
                    }
                    resultMap.put(RETURN_MESSAGE, message);
                } else 
                {
                    //return pagereference as json content
                    resultMap.put(RETURN_RESULT,RESULT_TYPE_OK);
                    resultMap.put(RETURN_MESSAGE, authenticationResult.getUrl());
                }

            }else{
                resultMap.put(RETURN_RESULT, RESULT_TYPE_NO_PERMISSIONSET);
            }               
        } catch(Exception e){
            // log exception
            nebula.logger.exception(e.getMessage(), e);
            nebula.logger.saveLog();
            // inform client
            resultMap.put(RETURN_RESULT, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE, MESSAGE_EXCEPTION);
        }
		return resultMap;
    }
    
    /***
     * @author      Steffi Narang
     * @description Checking exiting user has permission set or not
     */
    public static Boolean getPermissionsetAssignment(String userId) {
       //         Map<String, Object> resultMap = new Map<String, String>();
        Boolean flag;
        //checking my app permission set for loggged in user..
        Map<ID, PermissionSetAssignment>  permSetAssignentMyApp = new Map<ID, PermissionSetAssignment>([SELECT Id, PermissionSetId, PermissionSet.Name, 
                              PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId,Assignee.Name FROM PermissionSetAssignment 
                              WHERE PermissionSet.Name = 'Customer_Community_My_Application'and AssigneeId=:userId]);
                            
        //checking user has assigned permission set or not 
        if(permSetAssignentMyApp.isEmpty()){
            flag = false;
        }else{
            flag = true;
        } 
                                                                                       
        return flag;
    }
     /***
     * @author      Steffi Narang
     * @description This method is used to assigned the permission set to the user
     */
    public static void assignPermissionSet(string portalUserId) {
        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
        for(PermissionSet permSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN ('Customer_Community_My_Application', 'Experience_Custom_MFA')]) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = permSet.Id, AssigneeId = portalUserId);
            permSetAssignments.add(psa);
        }
        if(!permSetAssignments.isEmpty()){
            // insert the perm sets
            UserServices.InsertSobjectsQueueable insertQueuable = new UserServices.InsertSobjectsQueueable(permSetAssignments, false); // do not fail all records if a particular item fails
            Id jobId = System.enqueueJob(insertQueuable);
        }             
    }
    /**
     * @author      Ken McGuire
     * @description Method that initiates request reset password action
     * @param       String username
                    String captchaToken
     * @return      Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> requestResetPasswordWithCaptcha(String username,String captchaToken) {
        Map<String,Object> validateResult = validateCaptchaToken(captchaToken);
        if (validateResult.size()>0) return validateResult;
        return requestResetPassword(username);
    }

    /**
     * @author      Kristian Vegerano
     * @description Method that initiates request reset password action
     * @param       String username
     * @return      Map<String, Object>
     * @revision    25/03/2020 - Kristian Vegerano - Created
    * @revision    15/10/2022 - made privte to incorporate captcha for my.app
     * @revision    17/10/2022 - made public via bug fix to accomodate partner portal dependency (to be removed)
     * @revision    20/10/2022 - made private again after implimenting captcha to partner portal.
     */
    @TestVisible
    private  static Map<String, Object> requestResetPassword(String username) {
        // Input Guard
        if (isUnsafe(username)) return unsafeUserInputMessage();
        
        Map<String, Object> resultMap = new Map<String, String>();
        try{
            //Retrieve matching community user's details
            Map<String, Object> mapUserDetails = new CommitQueryRecords().queryUserDetails(username);

            //reset password result
            if(mapUserDetails != null && mapUserDetails.size() != 0){
                if (((Boolean)mapUserDetails.get('isPasswordLocked')) == true) {
                    resultMap.put(RETURN_RESULT, RESULT_TYPE_LOCKED);
                    resultMap.put(RETURN_MESSAGE,MESSAGE_ACCOUNT_LOCKED);
                } else {
                    Boolean resetPasswordResult = new CommitQueryRecords().forgotPasswordUser(username);

                    resultMap.put(RETURN_RESULT,RESULT_TYPE_OK);
                    resultMap.put(RETURN_MESSAGE, MESSAGE_PASSWORD_REQUEST_SENT + username);
                }
            } else {
                resultMap.put(RETURN_RESULT, RESULT_TYPE_NO_MATCH);
                resultMap.put(RETURN_MESSAGE, MESSAGE_PASSWORD_REQUEST_SENT + username);
            }
        }catch(Exception error){
            // Log exception
            LogUtilityException.LogException(error);
            // inform client
            resultMap.put(RETURN_RESULT, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE,MESSAGE_EXCEPTION);
        }
        return resultMap;
    }

    /**
     * @author      Vinothraja
     * @description Method that initiates request reset password action - using System Class
     * @param       String contactId
     * @return      Map<String, Object>
     * @revision    18/07/2021 - Created
     */
    @AuraEnabled
    public static Map<String, Object> sendResetLinkToUser(String contactId, String selectedExperience) {
        Map<String, Object> resultMap = new Map<String, String>(); 
        // Input Guard
        if (isUnsafe(new List<String>{contactId,selectedExperience})) return unsafeUserInputMessage();

        Integer firstItem = 0;

        try{
            User matchingUser;
            List<Object> results;
            //Fetch the Contact's Associated User record, in a without-sharing context
            if (String.isNotBlank(contactId)) {
                results = new CommitQueryRecords().queryRecords('SELECT Id, ProfileId FROM User WHERE ContactId =\'' + contactId + '\'');
            } 
            if (results != null && results.size() != 0){
                for(Object loopUser : results){
                    matchingUser = (User)loopUser;
                }
                Boolean sendEmailToUser = true;
                //reset password using the System.resetPassword method to unlock the user
                if(matchingUser != null){
                    Id originalProfile = matchingUser.ProfileId;
                    String newProfileId;

                    // reset user's mobile number
                    matchingUser.MobilePhone = null;
                    matchingUser.Last_2FA_Login__c = null;

                    // update user's profile to the targetted experience profile
                    if(mapExperienceToProfile.containsKey(selectedExperience)){
                        // retrieve target experience profile name
                        Profile myAppProfile = (Profile)new CommitQueryRecords().queryRecords('SELECT Id FROM Profile WHERE Name = \'' + mapExperienceToProfile.get(selectedExperience) + '\' LIMIT 1')[firstItem];
                        newProfileId = myAppProfile.Id;
                    }  

                    // commit user changes
                    if(newProfileId != null){
                        new CommitQueryRecords().updateUserRecordProfile(matchingUser, newProfileId);
                    }else{
                        new CommitQueryRecords().updateUserRecord(matchingUser);
                    }

                    // send email template
                    Boolean resetPasswordResult = new CommitQueryRecords().resetPasswordUser(matchingUser.id, sendEmailToUser, selectedExperience, originalProfile);
                    if (resetPasswordResult){
                        resultMap.put(RETURN_RESULT,RESULT_TYPE_OK);
                        resultMap.put(RETURN_MESSAGE,MESSAGE_PASSWORD_RESET);
                    } else {
                        throw new EmailException('Password not reset and email not sent');
                    }
                } 
            } else {
                resultMap.put(RETURN_RESULT, RESULT_TYPE_ERROR);
                resultMap.put(RETURN_MESSAGE,MESSAGE_INVALID_USER);
            }
        }catch(Exception error){
            // Log exception
            LogUtilityException.LogException(error);
            // inform client
            resultMap.put(RETURN_RESULT, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE,MESSAGE_EXCEPTION);
        }
        
        return resultMap;
    }

    /***
     * @author  Vinothraja
     * @param   String UserId
     * @description Method to get all Permission Sets the user has been assigned
    */
    @AuraEnabled(cacheable=true)
    public static List<PermissionSetAssignment> getAllPermissionSets(String userId) {
        // Input Guard
        if (isUnsafe(userId)) return null;
        
        
        List<Map<String, String>> result = new List<Map<String, String>> ();

        Map<String, String> resultMap;
        //Fetching all Permission sets for user
        List<PermissionSetAssignment>  permSetAssigned = [SELECT Id, PermissionSetId, PermissionSet.Name 
                                                            FROM PermissionSetAssignment 
                                                            WHERE AssigneeId = :userId];
        return permSetAssigned;
    }

    /***
     * @author  Vinothraja
     * @param   ContactId   
     * @description Method to get Portal User info for the Contact
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPortalUserInfo(String contactId) {
        Map<String, Object> resultMap = new Map<String, Object>();
        // Input Guard
        if (isUnsafe(contactId)) return unsafeParameterMessage();
        
        Boolean isUserLockedOut = false;
        try{
            //Retrieve matching community user record for the Contact
            Map<String, Object> mapUserDetails;
            if (String.isNotBlank(contactId)) {
                mapUserDetails = new CommitQueryRecords().queryUserDetails(contactId);
            } 
            if (mapUserDetails != null && mapUserDetails.size() != 0){
                resultMap.put(RETURN_RESULT,RESULT_TYPE_OK);
                // user's mobile number
                resultMap.put('Mobile', mapUserDetails.get('Mobile'));
                // user's mobile number verification state
                resultMap.put('HasVerified', mapUserDetails.get('HasVerified'));
                resultMap.put('username', mapUserDetails.get('Username'));
                resultMap.put('isActive', mapUserDetails.get('isActive'));
                resultMap.put('isLockedOut', mapUserDetails.get('isPasswordLocked'));
                //Retrieve all the Communities the User is part of by checking his Permission Sets
                List<PermissionSetAssignment> permSetAssigned = getAllPermissionSets((Id)mapUserDetails.get('id'));
                if (permSetAssigned != null && permSetAssigned.size() !=0) {
                    Set<String> communities = new Set<String> ();
                    for (PermissionSetAssignment psa : permSetAssigned) { // Fetch the associated Community for the Permission Set
                        if (mapPermSetExperience.containsKey(psa.PermissionSet.Name)) {
                            communities.addAll(mapPermSetExperience.get(psa.PermissionSet.Name).split(','));//Logic to remove duplicate Communities, if the user is part of multiple permission sets having common communities
                        }
                    }
                    if (!communities.isEmpty()) {
                        // Commma-separated list of Communities to accomodate multiple Communities for one PS
                        resultMap.put('communities', String.join(new List<String>(communities),',')); 
                        if (((Boolean)mapUserDetails.get('isPasswordLocked')) == true) {
                            resultMap.put(RETURN_MESSAGE, MESSAGE_USER_LOCKED);
                        } else {
                            resultMap.put(RETURN_MESSAGE, '');
                        }
                    } else {
                        resultMap.put(RETURN_MESSAGE, MESSAGE_NOT_COMMUNITY_USER);
                    }
                }
            } else {
                resultMap.put(RETURN_RESULT, RESULT_TYPE_ERROR);
                resultMap.put('isActive', false);
                resultMap.put(RETURN_MESSAGE, MESSAGE_NOT_COMMUNITY_USER);
            }
        }catch(Exception error){
            resultMap.put('isActive', false);
            // Log exception
            LogUtilityException.LogException(error);
            // inform client
            resultMap.put(RETURN_RESULT, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE,MESSAGE_EXCEPTION);
        }
        return resultMap;
    }

    /**
     * @author      Ken McGuire
     * @description validates captcha token and generates appropriate aura LWC error messages.
     * @param       captchaToken The captcha tokent to validate
     * @return      a Map of any errors encountered.
     */
    public static Map<String, Object>  validateCaptchaToken(String captchaToken) {
        Map<String, Object> captchaError = new Map<String,Object>();
        if (String.isEmpty(captchaToken)) {
            captchaError.put(RETURN_RESULT, RESULT_TYPE_ERROR);
            captchaError.put(RETURN_MESSAGE, MESSAGE_EMPTY_CAPTCHA_TOKEN);
            return captchaError;
        }
        try {
            boolean success = ReCaptchaService.validateCaptchaToken(captchaToken);
            if (success == false) {
                captchaError.put(RETURN_RESULT, RESULT_TYPE_ERROR);
                captchaError.put(RETURN_MESSAGE, MESSAGE_CAPTCHA_NOT_VERIFIED);
            }

        } catch (ReCaptchaService.CaptchaException ex) {
            captchaError.put(RETURN_RESULT, RESULT_TYPE_ERROR);
            captchaError.put(RETURN_MESSAGE, MESSAGE_CAPTCHA_EXCEPTION);
        }
        return captchaError;
    }

    /**
     * @author      Kristian Vegerano
     * @description Method that creates a My.App applicant user based off from a contact record
     *              Main scenario is my.app user is created after the partner is done with the application and hands it over to the applicant to fill up on my.app
     * @param       Contact pageApplicant
     * @return      Map<String, Object>
     * @revision    25/01/2021 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> registerUser(Contact pageApplicant) {
        Map<String, Object> resultMap = new Map<String, String>();
        // Input Guard
        Contact cleanPageApplicant = (Contact)cleanSObject(pageApplicant,'Id,Email,FirstName,LastName');
        if (cleanPageApplicant == null) {
            resultMap.put(RETURN_RESULT, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE, MESSAGE_UNSAFE_INPUT);
            return resultMap;
        } 

        //Initialize variables
        

        // Check if the current user has access to the contact record
        Boolean hasAccess = false;
        for(UserRecordAccess loopAccess : [SELECT RecordId, HasReadAccess, HasEditAccess, HasDeleteAccess
                                           FROM UserRecordAccess
                                           WHERE UserId = :UserInfo.getUserId()
                                                AND RecordId = :cleanPageApplicant.Id]){
            hasAccess = true;
        }       

        // proceed processing if access granted
        if(hasAccess){
            String userId;
            Boolean flag;
            //Create a savepoint while user isnt created yet
            Savepoint registerUserSavePoint = Database.setSavepoint();

            try {      
                //retrieve community user profile
                Profile myAppProfile = (Profile)new CommitQueryRecords().queryRecords('SELECT Id FROM Profile WHERE Name = \'' + MYAPP_PROFILE + '\' LIMIT 1')[0];
                
                //prepare community user
                User communityUser = new User(Username = cleanPageApplicant.Email, Email = cleanPageApplicant.Email, 
                                                FirstName = cleanPageApplicant.FirstName, LastName = cleanPageApplicant.LastName, 
                                                ContactId = cleanPageApplicant.Id, ProfileId = myAppProfile.Id);
                
                //generate user alias
                String alias = '';                      
                if(communityUser.FirstName != null) {
                    alias = alias + communityUser.FirstName.toLowerCase().substring(0, 1);
                }
                if(communityUser.LastName.length() > 3){
                    alias = alias + communityUser.LastName.toLowerCase().substring(0, 4);
                }else if(communityUser.LastName.length() > 2){
                    alias = alias + communityUser.LastName.toLowerCase().substring(0, 3);
                }else if(communityUser.LastName.length() > 1){
                    alias = alias + communityUser.LastName.toLowerCase().substring(0, 2);
                }else if(communityUser.LastName.length() > 0){
                    alias = alias + communityUser.LastName.toLowerCase().substring(0, 1);
                }

                if(alias.length() > 5) {
                    alias = alias.substring(0, 5);
                }         
                communityUser.Alias = alias;

                //generate user nickname
                String nickname = '';
                String contactId = cleanPageApplicant.Id;
                if(communityUser.FirstName != null) {
                    nickname = nickname + communityUser.FirstName.toUpperCase().substring(0, 1);
                }
                nickname = nickname + communityUser.LastName.toUpperCase().substring(0, 1);
                nickname = nickname + contactId.substring(2, contactId.length());
                communityUser.CommunityNickname = nickname;
                communityUser.EmailEncodingKey =  Constants.EMAIL_ENCODING_KEY;
                communityUser.LanguageLocaleKey =  Constants.LANGUAGE_LOCALE_KEY;
                communityUser.LocaleSidKey =  Constants.LOCALE_SID_KEY;
                communityUser.TimeZoneSidKey =  Constants.TIME_ZONE_SID_KEY;
                communityUser = new CommitQueryRecords().insertUserRecord(communityUser);
                assignMyAppPermissionset(communityUser.Id, true);
               /* 
               
                //Assign Customer_Community_My_Application permission set
                List<String> toAssignPermissionSet = new List<String>();
                toAssignPermissionSet.add('Customer_Community_My_Application');
                
                //add Experian PS to the user
                toAssignPermissionSet.add(Constants.EXPERIAN_PERMSET_NAME);

                //Add mfa when activate for registrants date is due
                Date registrantActivateDate = Date.parse(Label.Activate_MFA_for_Registrants);
                if(System.Today() > registrantActivateDate){
                    toAssignPermissionSet.add('Experience_Custom_MFA');
                }

                assignPermissionSets(new Set<String>{communityUser.Id}, toAssignPermissionSet , null);

               //Assign Customer_Community_My_Application permission set
                List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
                for(PermissionSet permSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :toAssignPermissionSet]) {
                    PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = permSet.Id, AssigneeId = communityUser.Id);
                    permSetAssignments.add(psa);
                }
                if(!permSetAssignments.isEmpty()){
                    UserServices.InsertSobjectsQueueable insertQueuable = new UserServices.InsertSobjectsQueueable(permSetAssignments, false); // do not fail all records if a particular item fails
                    Id jobId = System.enqueueJob(insertQueuable);
                }*/

                resultMap.put(RETURN_RESULT,RESULT_TYPE_OK);
                resultMap.put(RETURN_MESSAGE, communityUser.Id);
            } catch (Exception error) {
                //Rollback to when the user isnt created yet
                Database.rollback(registerUserSavePoint);
                
                //log error
                ExLog.add('PartnerApplicationService', 'Partner Experience', 'createUser', error);

                resultMap.put(RETURN_RESULT, RESULT_TYPE_ERROR);
                resultMap.put(RETURN_MESSAGE, error.getMessage());
            }
        }else{
            resultMap.put(RETURN_RESULT, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE, 'NO ACCESS');
        }
        
        return resultMap;
    }

    public static void assignMyAppPermissionset(Id communityUserId, Boolean addMyAppPS)
    {
        try{ 
            //Assign Customer_Community_My_Application permission set
            List<String> toAssignPermissionSet = new List<String>();
            if(addMyAppPS)
            {
                toAssignPermissionSet.add('Customer_Community_My_Application');
            }
            
            //add Experian PS to the user
            toAssignPermissionSet.add(Constants.EXPERIAN_PERMSET_NAME);

            //Add mfa when activate for registrants date is due
            Date registrantActivateDate = Date.parse(Label.Activate_MFA_for_Registrants);
            //if(System.Today() > registrantActivateDate){
                toAssignPermissionSet.add('Experience_Custom_MFA');
            //}
            assignPermissionSets(new Set<String>{communityUserId}, toAssignPermissionSet , null);
        } catch (Exception error) {
            throw error;
        }
    }
    /**
     * @author      Ken McGuire
     * @description Method that registers a new user 
     * @param       String firstname : The registration users first name
     * @param       String lastName : The registration users lass name  
     * @param       String email : the registration users email
     * @param       String captchaToken : the captcha token to validate
     * @return      Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> registerUserWithCaptcha(String firstName, String lastName, String email,String captchaToken) {
        Map<String,Object> validateResult = validateCaptchaToken(captchaToken);
        if (validateResult.size()>0) return validateResult;
        return registerUser(firstName,lastName,email);
    }


    /**
     * @author      Kristian Vegerano
     * @description Method that initiates request reset password action
     * @param       String username
     * @return      Map<String, Object>
     * @revision    25/03/2020 - Kristian Vegerano - Created
     *              25/11/2020 - Steffi updated - when user already exist without permission set while registering.
     *              30/08/2022 - Vinothraja - updated Contact, Account and User generation to accomodata Mononymous names
     * @revision    15/10/2022 - made privte to incorporate captcha for my.app
     * @revision    17/10/2022 - made public via bug fix to accomodate partner portal dependency (to be removed)
     * @revision    20/10/2022 - made private again after implimenting captcha to partner portal.
     */
    @TestVisible
    private static Map<String, Object> registerUser(String firstName, String lastName, String email) {
        Map<String, Object> resultMap = new Map<String, String>();
        // Input Guard
        if (isUnsafe(new List<String>{firstName,lastName,email})) return unsafeUserInputMessage();
        //Initialize variables

        String userId;
        Boolean flag;
        //Create a savepoint while user isnt created yet
        Savepoint registerUserSavePoint = Database.setSavepoint();

        try {      
            Map<Id, User> usrs = new Map<Id, User>((List<User>)new CommitQueryRecords().queryRecords('SELECT Id, Name, Username, Email FROM User where username = \'' + email + '\' and ContactId != null LIMIT 1'));
            for(User o : usrs.values()){
                userId = o.Id;
            }
            if(usrs.isEmpty()){
                //prepare community contact' account
                User systemAdminUser = (User)new CommitQueryRecords().queryRecords('SELECT Id FROM User WHERE Name = \'System Admin\' AND Profile.Name = \'System Administrator\' LIMIT 1')[0];
                Account newCommunityUserAccount = new Account(Name = (String.isBlank(firstName)?'':firstName + ' ') + lastName,
                                                              OwnerId = systemAdminUser.Id,
                                                              RecordTypeId = CommonServices.RecordTypeId('Account', AccountServices.ACCOUNT_INDIVIDUAL_TYPE));
                newCommunityUserAccount = new CommitQueryRecords().insertAccountRecord(newCommunityUserAccount);

                //prepare community contact
                Contact newCommunityUserContact = new Contact(FirstName = firstName, LastName = lastName, Email = email, Personal_Email__c = email, AccountId = newCommunityUserAccount.Id);
                newCommunityUserContact = new CommitQueryRecords().insertContactRecord(newCommunityUserContact);

                //retrieve community user profile
                Profile myAppProfile = (Profile)new CommitQueryRecords().queryRecords('SELECT Id FROM Profile WHERE Name = \'' + MYAPP_PROFILE + '\' LIMIT 1')[0];

                //prepare community user
                User communityUser = new User(Username = newCommunityUserContact.Email, Email = newCommunityUserContact.Email, 
                                              FirstName = newCommunityUserContact.FirstName, LastName = newCommunityUserContact.LastName, 
                                              ContactId = newCommunityUserContact.Id, ProfileId = myAppProfile.Id);
                
                //generate user alias
                String alias = '';                      
                if(!String.isBlank(communityUser.FirstName)) {
                    alias = alias + communityUser.FirstName.toLowerCase().substring(0, 1);
                }
                if(communityUser.LastName.length() > 3){
                    alias = alias + communityUser.LastName.toLowerCase().substring(0, 4);
                }else if(communityUser.LastName.length() > 2){
                    alias = alias + communityUser.LastName.toLowerCase().substring(0, 3);
                }else if(communityUser.LastName.length() > 1){
                    alias = alias + communityUser.LastName.toLowerCase().substring(0, 2);
                }else if(communityUser.LastName.length() > 0){
                    alias = alias + communityUser.LastName.toLowerCase().substring(0, 1);
                }
                
                if(alias.length() > 5) {
                    alias = alias.substring(0, 5);
                }         
                communityUser.Alias = alias;
                
                //generate user nickname
                String nickname = '';
                String contactId = newCommunityUserContact.Id;
                if(!String.isBlank(communityUser.FirstName)) {
                    nickname = nickname + communityUser.FirstName.toUpperCase().substring(0, 1);
                    nickname = nickname + communityUser.LastName.toUpperCase().substring(0, 1);
                } else {
                    nickname = nickname + communityUser.LastName.toUpperCase().substring(0, 2);
                }
                nickname = nickname + contactId.substring(2, contactId.length());
                communityUser.CommunityNickname = nickname;

                Id portalUserId = new CommitQueryRecords().createExternalUser(communityUser, newCommunityUserAccount.Id);

                //Assign Customer_Community_My_Application permission set
                List<String> toAssignPermissionSet = new List<String>();
                toAssignPermissionSet.add('Customer_Community_My_Application');
                //add Experian PS to the user
                toAssignPermissionSet.add(Constants.EXPERIAN_PERMSET_NAME);
                //Add mfa when activate for registrants date is due
                Date registrantActivateDate = Date.parse(Label.Activate_MFA_for_Registrants);
                if(System.Today() > registrantActivateDate){
                    toAssignPermissionSet.add('Experience_Custom_MFA');
                }

                //Commit permission set assignments
                List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
                for(PermissionSet permSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :toAssignPermissionSet]) {
                    PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = permSet.Id, AssigneeId = portalUserId);
                    permSetAssignments.add(psa);
                }
                if(!permSetAssignments.isEmpty()){
                    UserServices.InsertSobjectsQueueable insertQueuable = new UserServices.InsertSobjectsQueueable(permSetAssignments, false); // do not fail all records if a particular item fails
                    Id jobId = System.enqueueJob(insertQueuable);
                }

                resultMap.put(RETURN_RESULT,RESULT_TYPE_OK);
                resultMap.put(RETURN_MESSAGE, portalUserId);
            }else{
                // user is existing
                flag = getPermissionsetAssignment(userId);                
                if(flag == false){
                    assignPermissionSet(userId);
                    resultMap.put(RETURN_RESULT, RESULT_TYPE_NO_PERMISSIONSET);
                }else{
                    resultMap.put(RETURN_RESULT,RESULT_TYPE_HAS_DUPLICATE);
                    resultMap.put(RETURN_MESSAGE, MESSAGE_ACCOUNT_EXISTS);
                }
            }
        } catch (Exception error) {
            //Rollback to when the user isnt created yet
            Database.rollback(registerUserSavePoint);
            // Log exception
            LogUtilityException.LogException(error, email);
            // inform client
            resultMap.put(RETURN_RESULT, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE,MESSAGE_EXCEPTION);
        }
        
        return resultMap;
    }


    /**
     * @author      Kristian Vegerano
     * @description Method that changes password
     * @param       String enteredPassword
     *              String enteredConfirmPassword
     *              String currentOldPassword
     * @return      PageReference
     * @revision    25/03/2020 - Kristian Vegerano - Created
     */
    public PageReference changeUserPassword() {
        PageReference redirectionPage = new CommitQueryRecords().changeUserPassword(newPassword, verifyNewPassword);
        if(redirectionPage != null){             
            // register email as verification method
            UserManagement.verifyRegisterVerificationMethod(UserInfo.getUserEmail(), Auth.VerificationMethod.Email);
            
            // update last 2fa login of the user
            User contextUser = new User(Id = UserInfo.getUserId(), Last_2FA_Login__c = System.NOW());
            contextUser = new CommitQueryRecords().updateUserRecord(contextUser);

            redirectionPage.setRedirect(true);     
            //logout the user        
            String experienceURL = Network.getLoginUrl(Network.getNetworkId());
            if(experienceURL.containsIgnoreCase('admissions') || experienceURL.containsIgnoreCase('myapp')){
                redirectionPage = new Pagereference('/secur/logout.jsp?retUrl=' + Network.getLoginUrl(Network.getNetworkId()) + '%3Fun=' + UserInfo.getUserName());
            }

            // kill the other user sessions
            CommonUtilities.terminateUserSession(UserInfo.getUserId());
        }else{
            if (Test.isRunningTest()) {
                changePasswordError = 'Error: You cannot reuse this old password.';

                // kill the other user sessions
                CommonUtilities.terminateUserSession(UserInfo.getUserId());
            }
            // show SF generated visualforce apex message - expected that error message shown 1 at a time
            for (ApexPages.Message m : ApexPages.getMessages()) {
                changePasswordError = m.getDetail();
            }
        }
        return redirectionPage;
    }

    /**
     * @author      Kristian Vegerano
     * @description Method that initiates my.app user generation after the application has been created by a partner user which has been sent to the applicant
     * @param       String applicationId - application to reset its progress status - after partner sends the application to the applicant
     * @return      Map<String, Object>
     * @revision    
     * 25/02/2021 - Kristian Vegerano - Created
     * 03/08/2022 - Vinothraja - SFTG-2654 - Added Partner_Controlled_Timestamp__c logging
     */
    @AuraEnabled
    public static Map<String, Object> generateUserResetApplicationProgressStatus(String applicationId) {
        // Input Guard
        if (isUnsafe(applicationId)) return unsafeParameterMessage();
        
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();
        
        //Query application details
        Application__c pageApplication = [SELECT Id, Applicant__c,Type_of_Study__c,
                                          Partner_Agreement__c, Partner_Controlled_Timestamp__c 
                                          FROM Application__c
                                          WHERE Id = :applicationId 
                                          LIMIT 1];
        pageApplication.Furthest_Progress__c = 'Declaration';
        pageApplication.Submission_Progress__c = 'Declaration';
        pageApplication.Partner_Controlled__c = false;
        pageApplication.Partner_Controlled_Timestamp__c = DateTime.now();
        update pageApplication;
        List<Partner_Agreement__c> paList = [select id,Quota__c, Remaining_quota__c from Partner_Agreement__c where Id=:pageApplication.Partner_Agreement__c];
        if(pageApplication.Type_of_Study__c == 'EXCHANGE' && !pageApplication.Partner_Controlled__c && paList.size()>0)
        {
            if(paList[0].Remaining_quota__c!=null && paList[0].Remaining_quota__c>0)
            {
                paList[0].Remaining_quota__c = paList[0].Remaining_quota__c-1;
            }else{
                paList[0].Remaining_quota__c = (paList[0].Quota__c!=null && paList[0].Quota__c>0)?paList[0].Quota__c-1 :0;
            }
            update paList[0];
        }
        //Query applicant details
        Contact pageApplicant = [SELECT Id, AccountId, FirstName, MiddleName, LastName, Email
                                 FROM Contact
                                 WHERE Id = :pageApplication.Applicant__c 
                                 LIMIT 1];
        
        //Register user
        resultMap = ExperienceAuthenticationServices.registerUser(pageApplicant);

        //Return results
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Method used by managePartnerUser lwc to determine if the current contact's account is already enabled as a partner
     * @param       String contactId - id of the contact user in context
     * @return      Map<String, Object>
     * @revision    25/02/2021 - Kristian Vegerano - Created
     * 04/10/2021   Vinothraja - Added Account ID to the result Map as part of SFTG-2170
     */
    @AuraEnabled
    public static Map<String, Object> isPartnerEnabled(String contactId) {
        // Input Guard
        if (isUnsafe(contactId)) return unsafeParameterMessage();
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();
        try{
            Contact contextContact;
            for(Contact loopContact : [SELECT Id, Account.Id, Account.IsPartner 
                                       FROM Contact 
                                       WHERE Id = :contactId]){
                contextContact = loopContact;
            }

            //check if there is matching contact id
            if(contextContact.AccountId != null){
                //true result
                if(contextContact.Account.IsPartner){
                    resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
                    resultMap.put('HAS_PARTNER_ENABLED', JSON.serialize(true));
                    resultMap.put('PARTNER_ACCOUNT_ID', JSON.serialize(contextContact.Account.Id)); // SFTG-2170 
                }else{
                    //false result
                    resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
                    resultMap.put('HAS_PARTNER_ENABLED', JSON.serialize(false));
                    resultMap.put('PARTNER_ACCOUNT_ID', ''); // SFTG-2170 
                }
            }else{
                //false result
                resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
                resultMap.put('HAS_PARTNER_ENABLED', JSON.serialize(false));
                resultMap.put('PARTNER_ACCOUNT_ID', ''); // SFTG-2170 
            }
            
        }catch(Exception ex){
            // inform client          
            resultMap.put(RETURN_STATUS, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE,MESSAGE_EXCEPTION);
            // Log exception
            LogUtilityException.LogException(ex);
        }

        //Return results
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Method used by managePartnerUser lwc to determine if the current contact already has a partner user associated to it
     * @param       String contactId - id of the contact user in context
     * @return      Map<String, Object>
     * @revision    25/02/2021 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> checkHasPartnerUser(String contactId) {
        System.debug(' in partner user??');
        // Input Guard
        if (isUnsafe(contactId)) return unsafeParameterMessage();
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();

        try{
            //Query profile
            Profile partnerUserProfile = [SELECT Id FROM Profile WHERE Name = :Constants.PARTNER_USER_PROFILE];

            User partnerUser;
            for(User loopUser : [SELECT Id, IsActive, contact.AccountId, Username 
                                 FROM User 
                                 WHERE ContactId = :contactId 
                                    AND ProfileId = :partnerUserProfile.Id]){
                partnerUser = loopUser;
            }

            //check if there is matching contact id
            if(partnerUser != null){
                //add result
                resultMap.put('USER_NAME', JSON.serialize(partnerUser.Username));
                resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
                resultMap.put('HAS_PARTNER_USER', JSON.serialize(true));
                resultMap.put('TEAM_MEMBER_ROLE', JSON.serialize(AccountTeamConstants.PARTNER_ROLE_STANDARD_USER));
                List<AccountTeamMember> lstATM = (List<AccountTeamMember>)new CommitQueryRecords().queryRecords('SELECT TeamMemberRole FROM AccountTeamMember WHERE isDeleted = false AND UserId = \'' + partnerUser.Id + '\'');
                if (!lstATM.isEmpty()) {
                    resultMap.put('TEAM_MEMBER_ROLE', JSON.serialize(lstATM[0].TeamMemberRole));
                } 
                resultMap.put('IS_PARTNER_ACTIVE', JSON.serialize(partnerUser.IsActive));
                resultMap.put('PARTNER_ACCOUNT_ID', JSON.serialize(partnerUser.contact.AccountId));
            }else{
                //add result
                resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
                resultMap.put('HAS_PARTNER_USER', JSON.serialize(false));
                resultMap.put('IS_PARTNER_ACTIVE', JSON.serialize(true));
                resultMap.put('TEAM_MEMBER_ROLE', JSON.serialize(AccountTeamConstants.PARTNER_ROLE_STANDARD_USER));
                resultMap.put('PARTNER_ACCOUNT_ID', JSON.serialize(''));
            }
            
        }catch(Exception ex){
            // inform client          
            resultMap.put(RETURN_STATUS, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE,MESSAGE_EXCEPTION);
            // Log exception
            LogUtilityException.LogException(ex);
        }

        //Return results
        return resultMap;
    }

    
    
    /**
     * @author      Kristian Vegerano
     * @description Method used by managePartnerUser lwc which enables the internal user to generate a partner user for the contact
     * @param       String partnerUserSpecifics - contact record in JSON format
     * @return      Map<String, Object>
     * @revision    25/02/2021 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> generatePartnerUser(String partnerUserSpecifics) {
        // Input Guard
        if (isUnsafe(partnerUserSpecifics)) return unsafeUserInputMessage();
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();

        try{
            //Query profile
            Profile partnerUserProfile = (Profile)new CommitQueryRecords().queryRecords('SELECT Id FROM Profile WHERE Name = \'' + Constants.PARTNER_USER_PROFILE + '\'')[0];

            //Deserialize user details
            Map<String, Object> userDetails = (Map<String, Object>)JSON.deserializeUntyped(partnerUserSpecifics);

            //prepare community user
            User partnerUser = new User(Username = (String)userDetails.get('Username'), Email = (String)userDetails.get('Email'), 
                                        FirstName = (String)userDetails.get('FirstName'), MiddleName = (String)userDetails.get('MiddleName'),
                                        LastName = (String)userDetails.get('LastName'), Suffix = (String)userDetails.get('Suffix'), 
                                        CommunityNickname = (String)userDetails.get('Nickname'), ContactId = (String)userDetails.get('ContactId'),
                                        IsActive = true, ProfileId = partnerUserProfile.Id);

            String partnerAccessLevel = (String)userDetails.get('PartnerAccessLevel');
            //generate user alias
            String alias = '';                      
            if(partnerUser.FirstName != null) {
                alias = alias + partnerUser.FirstName.toLowerCase().substring(0, 1);
            }
            if(partnerUser.LastName.length() > 3){
                alias = alias + partnerUser.LastName.toLowerCase().substring(0, 4);
            }else if(partnerUser.LastName.length() > 2){
                alias = alias + partnerUser.LastName.toLowerCase().substring(0, 3);
            }else if(partnerUser.LastName.length() > 1){
                alias = alias + partnerUser.LastName.toLowerCase().substring(0, 2);
            }else if(partnerUser.LastName.length() > 0){
                alias = alias + partnerUser.LastName.toLowerCase().substring(0, 1);
            }

            if(alias.length() > 5) {
                alias = alias.substring(0, 5);
            }         
            partnerUser.Alias = alias;
            partnerUser.EmailEncodingKey =  Constants.EMAIL_ENCODING_KEY;
            partnerUser.LanguageLocaleKey =  Constants.LANGUAGE_LOCALE_KEY;
            partnerUser.LocaleSidKey =  Constants.LOCALE_SID_KEY;
            partnerUser.TimeZoneSidKey =  Constants.TIME_ZONE_SID_KEY;
            // Super user access for Deleting Applications
            if (partnerAccessLevel == AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER) { 
                partnerUser.IsPrmSuperUser = true; 
            }else if (partnerAccessLevel ==  AccountTeamConstants.PARTNER_ROLE_DELEGATED_ADMIN) {
                partnerUser.IsPrmSuperUser = true; 
            } else {
                partnerUser.IsPrmSuperUser = false; 
            }
            partnerUser = new CommitQueryRecords().insertUserRecord(partnerUser);

            //Add permission sets -- START
            List<String> addedPermissionSets = new List<String>();
            // Adding the basic Partner Access
            addedPermissionSets.add('Partner_Community_Access');
            //add Experian PS to the user
             addedPermissionSets.add(Constants.EXPERIAN_PERMSET_NAME);
            //Query Account ID
            Contact con = (Contact)new CommitQueryRecords().queryRecords('SELECT AccountId FROM Contact WHERE id = \'' + (String)userDetails.get('ContactId') + '\'')[0];

            Id partnerAccountId = con.AccountId;
            // Adding permission sets based on Partner Access Levels
            if (partnerAccessLevel == AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER) {
                addedPermissionSets.add(PARTNER_ACCESS_MAP.get(AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER));
            } else if (partnerAccessLevel ==  AccountTeamConstants.PARTNER_ROLE_DELEGATED_ADMIN) {
                addedPermissionSets.add(PARTNER_ACCESS_MAP.get(AccountTeamConstants.PARTNER_ROLE_DELEGATED_ADMIN));
            }
            AccountServices.upsertPartnerRole(partnerUser.Id, partnerAccountId, partnerAccessLevel);
                assignPermissionSets(new Set<String>{partnerUser.Id}, addedPermissionSets, null);
            //Add permission sets -- END

            //add result
            resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
            resultMap.put('PARTNER_ID', partnerUser.Id);
        }catch(Exception ex){
            // inform client          
            resultMap.put(RETURN_STATUS, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE,MESSAGE_EXCEPTION);
            // Log exception
            LogUtilityException.LogException(ex);
        }

        //Return results
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Method used by managePartnerUser lwc which enables the internal user to remove/add the delegated admin access permission of a contact user
     * @param       String partnerUserSpecifics - contact record in JSON format
     * @return      Map<String, Object>
     * @revision    25/02/2021 - Kristian Vegerano - Created
     * 28/09/2021   Vinothraja - Added logic to handle Activating/Deactivating User
     */
    @AuraEnabled
    public static Map<String, Object> updatePartnerUser(String partnerUserSpecifics) {
        // Input Guard
        if (isUnsafe(partnerUserSpecifics)) return unsafeUserInputMessage();
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();
        try{
            //Query profile
            Profile partnerUserProfile = (Profile)new CommitQueryRecords().queryRecords('SELECT Id FROM Profile WHERE Name = \'' + Constants.PARTNER_USER_PROFILE + '\'')[0];

            //Deserialize user details
            Map<String, Object> userDetails = (Map<String, Object>) JSON.deserializeUntyped(partnerUserSpecifics);

            //Retrieve related partner user
            String contactId = (String)userDetails.get('ContactId');

            User partnerUser;
            for(User loopUser : [SELECT Id, IsActive
                                 FROM User 
                                 WHERE ContactId = :contactId 
                                    AND ProfileId = :partnerUserProfile.Id]){
                partnerUser = loopUser;
            }            

            Boolean updatedPartnerActiveStatus = (Boolean)userDetails.get('isPartnerActive');
            String partnerAccessLevel = (String)userDetails.get('PartnerAccessLevel');
            Id partnerAccountId = (Id)userDetails.get('PartnerAccountId');
            //Activate or Deactivate Partner User
            if(updatedPartnerActiveStatus != partnerUser.IsActive){
                User u = (User) new CommitQueryRecords().updateUserRecord(new User(id = partnerUser.id, IsActive = updatedPartnerActiveStatus));
            }
            // Assign/Remove Permission Sets based on Partner Access Levels
            if (updatedPartnerActiveStatus){
                List<User> updateUserList = new List<User> ();
                // Primary Account Holder
                if (partnerAccessLevel == AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER) {
                    assignPermissionSets(new Set<String>{partnerUser.Id}, new List<String>{PARTNER_ACCESS_MAP.get(AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER)}, null);
                    updateUserList.add(new User(id = partnerUser.id, IsPrmSuperUser = true)); // Super user access for Deleting Applications
                    // Delegated Admin User
                } else if (partnerAccessLevel ==  AccountTeamConstants.PARTNER_ROLE_DELEGATED_ADMIN) {
                    assignPermissionSets(new Set<String>{partnerUser.Id}, new List<String>{PARTNER_ACCESS_MAP.get(AccountTeamConstants.PARTNER_ROLE_DELEGATED_ADMIN)}, null);
                    updateUserList.add(new User(id = partnerUser.id, IsPrmSuperUser = true)); // Super user access for Deleting Applications
                    // Standard Partner User
                } else {
                    removePermissionSets(partnerUser.Id, new List<String>{PARTNER_ACCESS_MAP.get(AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER)});
                    updateUserList.add(new User(id = partnerUser.id, IsPrmSuperUser = false));
                }
                // Set the Account Team Member Role based on Partner Access Level
                AccountServices.upsertPartnerRole(partnerUser.Id, partnerAccountId, partnerAccessLevel);
                // Update Partner Super User Access - call queueable class to avoid MIXED_DML_OPERATION by updating User and Contact in one transaction
                Queueable queueItem = new UserServices.UpdateSobjectsQueueable(updateUserList);
                ID jobID = System.enqueueJob(queueItem);
            } else { // Remove Permission sets and Account Team Member role when set to Inactive
                removePermissionSets(partnerUser.Id, new List<String>{PARTNER_ACCESS_MAP.get(AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER)});
                AccountServices.removePartnerRole(partnerUser.Id, partnerAccountId);
            }

            //add result
            resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
        }catch(Exception ex){
            // inform client          
            resultMap.put(RETURN_STATUS, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE,MESSAGE_EXCEPTION);
            // Log exception
            LogUtilityException.LogException(ex);
        }

        //Return results
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description This method is used to assign the multiple permission sets to bulk users
     * @param       Set<String> portalUserIds - set of user ids
     *              List<String> permissionSetNames - list of permission set names
     *              List<String> permissionSetGroupNames - list of permissionSetGroup names
     * @return      Map<String, Object>
     * @revision    25/02/2021 - Kristian Vegerano - Created
     * @revision    24/04/2024 - Shalini Mendu - Updated to take PermissionSetGroup names as a parameter
     */
    public static void assignPermissionSets(Set<String> portalUserIds, List<String> permissionSetNames , List<String> permissionSetGroupNames) {
        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> permSetGroupAssignments = new List<PermissionSetAssignment>();
        //add all the Permissionsets into a list
        for(String loopUserId : portalUserIds){
            for(PermissionSet permSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetNames]) {
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = permSet.Id, AssigneeId = loopUserId);
                permSetAssignments.add(psa);
            }
        }

        //filter out the permisisonsets
        if(!permSetAssignments.isEmpty()){
            // Filter out permission set assignments with ids
            List<PermissionSetAssignment> filteredPermSetAssignments = new List<PermissionSetAssignment>();
            for(PermissionSetAssignment loopAssignment : permSetAssignments){
                if(loopAssignment.Id == null){
                    filteredPermSetAssignments.add(loopAssignment);
                }
            }
            if(!filteredPermSetAssignments.isEmpty()){
                UserServices.InsertSobjectsQueueable insertQueuable = new UserServices.InsertSobjectsQueueable(filteredPermSetAssignments, false); // do not fail all records if a particular item fails
                Id jobId = System.enqueueJob(insertQueuable);
            }
        }      
        
        if(permissionSetGroupNames==null)
        {
            return;
        }
       //add all the PermissionsetGroups into a list
       for(String loopUserId : portalUserIds){
            for(PermissionSetGroup permSetGroup : [SELECT Id FROM PermissionSetGroup WHERE DeveloperName IN :permissionSetGroupNames]) {
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetGroupId = permSetGroup.Id, AssigneeId = loopUserId);
                permSetGroupAssignments.add(psa);
            }
        }
        //filter out the permisisonsetgroups
        if(!permSetGroupAssignments.isEmpty()){
            // Filter out permission set group assignments with ids
            List<PermissionSetAssignment> filteredPermSetGroupAssignments = new List<PermissionSetAssignment>();
            for(PermissionSetAssignment loopAssignment : permSetGroupAssignments){
                if(loopAssignment.Id == null){
                    filteredPermSetGroupAssignments.add(loopAssignment);
                }
            }
            if(!filteredPermSetGroupAssignments.isEmpty()){
                UserServices.InsertSobjectsQueueable insertQueuable = new UserServices.InsertSobjectsQueueable(filteredPermSetGroupAssignments, false); // do not fail all records if a particular item fails
                Id jobId = System.enqueueJob(insertQueuable);
            }
        }           
    }

    /**
     * @author      Kristian Vegerano
     * @description This method is used to remove the permission sets to the user
     * @param       Set<String> portalUserIds - set of user ids
     *              List<String> permissionSetNames - list of permission set names
     * @return      Map<String, Object>
     * @revision    25/02/2021 - Kristian Vegerano - Created
     */
    public static void removePermissionSets(String portalUserId, List<String> permissionSetNames) {
        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
        for(PermissionSetAssignment permSetAssignment : [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :portalUserId AND PermissionSet.Name IN :permissionSetNames]) {
            permSetAssignments.add(permSetAssignment);
        }
        if(!permSetAssignments.isEmpty()){
            delete permSetAssignments;
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description This method is used to auto assign Partner Community Access permission set for partners created by delegated partner users
     * @param       List<User> userList - list of users where the permission set needs to be assigned
     * @return      Map<String, Object>
     * @revision    25/02/2021 - Kristian Vegerano - Created
     */
    public static void assignPartnerPermissionDelegatedUser(List<User> userList) {
        //Query profile
        Profile partnerUserProfile = [SELECT Id FROM Profile WHERE Name = :Constants.PARTNER_USER_PROFILE];

        Set<Id> userIds = new Set<Id>();
        for(User loopUser : userList){
            userIds.add(loopUser.Id);
        }

        Set<String> delegatedPartnerCreatedUserIds = new Set<String>();
        for(User loopUser : [SELECT Id, CreatedBy.ProfileId FROM User WHERE Id IN :userIds AND Profile.Name = :Constants.PARTNER_USER_PROFILE]){
            //check if the user that created the record being processed is a partner user
            if(loopUser.CreatedBy.ProfileId == partnerUserProfile.Id){
                delegatedPartnerCreatedUserIds.add(loopUser.Id);
            }
        }

        if(!delegatedPartnerCreatedUserIds.isEmpty()){
            //Add permission sets
            List<String> addedPermissionSets = new List<String>();
            addedPermissionSets.add('Partner_Community_Access');
            //add Experian PS to the user
            addedPermissionSets.add(Constants.EXPERIAN_PERMSET_NAME);
            assignPermissionSets(delegatedPartnerCreatedUserIds, addedPermissionSets, null);
        }
    }

    /**
     * @description       : Inner class for committing and querying records
     * @author            : Kristian Vegerano
     * @group             : Services
     * @last modified on  : 2021-03-12
     * @last modified by  : Kristian Vegerano
     * Modifications Log 
     * Ver   Date         Author          Modification
     * 1.0   2021-03-12 - Kristian Vegerano - Created
     */
    @TestVisible
    private without sharing class CommitQueryRecords {
        /**
         * @author      Kristian Vegerano
         * @description Method that authenticates the user
         */
        public PageReference authenticateUser(String username, String password, String startUrl){
            PageReference result;
            try {
                result =  Site.login(username, password, startUrl);
            }
            catch(Exception error){
                result = null;
            }
            return result;
        }

        /**
         * @author      Kristian Vegerano
         * @description Method that sends the request to reset password
         */
        public Boolean forgotPasswordUser(String username){
            return Site.forgotPassword(username);
        }

        /**
         * @author      Vinothraja
         * @description Method that sends the request to reset password using System Class
         * Included part of SFTG-2041 to send reset links which don't expire during Anti-Virus crawls
         */
        public Boolean resetPasswordUser(String userId, Boolean sendUserEmail, String experienceName, Id originalId){
            System.ResetPasswordResult rpr = System.resetPasswordWithEmailTemplate(userId, sendUserEmail, mapExperienceEmailTemplate.get(experienceName));

            // revert user's profile
            User contextUser = new User(Id = userId, ProfileId = originalId);
            update contextUser;

            if (rpr != null) {
                return true;
            }
            return false;
        }

        /**
         * @author      Kristian Vegerano
         * @description Method that sends the request to create an external user
         */
        public Id createExternalUser(User communityUser, Id newCommunityUserAccountId){
            return Site.createExternalUser(communityUser, newCommunityUserAccountId, null);
        }

        /**
         * @author      Kristian Vegerano
         * @description Method that sends the request to change a user's password
         */
        public PageReference changeUserPassword(String newPassword, String verifyNewPassword){
            return Site.changePassword(newPassword, verifyNewPassword, null);
        }        

        /**
         * @author      Kristian Vegerano
         * @description Method that commits the record to database in without sharing context
         */
        public Account insertAccountRecord(Account commitAccount){
            insert commitAccount;
            return commitAccount;
        }

        /**
         * @author      Kristian Vegerano
         * @description Method that commits the record to database in without sharing context
         */
        public Contact insertContactRecord(Contact commitContact){
            insert commitContact;
            return commitContact;
        }

        /**
         * @author      Kristian Vegerano
         * @description Method that commits the record to database in without sharing context
         */
        public User insertUserRecord(User commitRecord){
            insert commitRecord;
            return commitRecord;
        }

        /**
         * @author      Kristian Vegerano
         * @description Method that commits the record to database in without sharing context with the profile id updated as well
         */
        public User updateUserRecordProfile(User commitRecord, String profileId){
            commitRecord.ProfileId = profileId;
            update commitRecord;
            return commitRecord;
        }

        /**
         * @author      Kristian Vegerano
         * @description Method that commits the record to database in without sharing context
         */
        public User updateUserRecord(User commitRecord){
            update commitRecord;
            return commitRecord;
        }

        /**
         * @author      Kristian Vegerano
         * @description Method that commits the record to database in without sharing context
         */
        public List<Object> queryRecords(String queryString){
            return Database.query(queryString);
        }

        /**
         * @author      Vinothraja
         * @description Method that queries the User's details in without sharing context
         * @param user String - Can be a username or Contact ID
         */
        public Map<String, Object> queryUserDetails(String strUser){
            Map<String, Object> mapResult = new Map<String, Object> ();
            List<User> lstUsers;
            User usr;
            Boolean isContact;
            // SFTG-2584 input validation and identifying whether it is a contact or username, without instanceOf
            if (String.isNotBlank(strUser)) {
                try {
                    Id contactId = (Id) strUser; 
                    // Additional check to ensure it is a Contact 
                    String userType = contactId.getSObjectType().getDescribe().getName();
                    if (userType == 'Contact') {
                        isContact = true;
                    } 
                } catch(Exception ex) { 
                    isContact = false;
                }
            } else {
                return mapResult;
            }
            if (isContact) {
                // Querying user details based on Contact ID
                lstUsers = [SELECT Id, Name, Username, isActive, Email, NumberOfFailedLogins, MobilePhone 
                            FROM User 
                            WHERE ContactId = :strUser LIMIT 1];
            } else {
                // Querying user details based on username
                lstUsers = [SELECT Id, Name, Username, isActive, Email, NumberOfFailedLogins, MobilePhone 
                            FROM User 
                            WHERE username = :strUser  
                            AND isActive = true 
                            AND contactId != null 
                            LIMIT 1];
            }
            // Consolidate the User details into a Map
            if (lstUsers != null && !lstUsers.isEmpty()) {
                usr = lstUsers[0];

                // retrieve TwoFactorMethodsInfo of the user
                Boolean hasUserVerified = true;
                if(!Test.isRunningTest()){
                    TwoFactorMethodsInfo[] verifiedInfos = [SELECT HasUserVerifiedMobileNumber, HasUserVerifiedEmailAddress
                                                        FROM TwoFactorMethodsInfo
                                                        WHERE UserId = :usr.Id];
                    if (verifiedInfos.size() > 0) {
	                    hasUserVerified = verifiedInfos[0].HasUserVerifiedMobileNumber;
                    }
                        
                }
                hasUserVerified |= hasExternalVerifiedMobile(usr.Id);
                // user's mobile number
                mapResult.put('Mobile', usr.MobilePhone);
                // user's mobile number verification state
                mapResult.put('HasVerified', hasUserVerified);

                mapResult.put('id', usr.id);
                mapResult.put('Name', usr.Name);
                mapResult.put('Username', usr.Username);
                mapResult.put('isActive', usr.isActive);
                mapResult.put('Email', usr.Email);
                mapResult.put('NumberOfFailedLogins', usr.NumberOfFailedLogins);
                if (Test.isRunningTest()) {
                    mapResult.put('NumberOfFailedLogins', tstFailedLoginAttempts);
                }
                // Querying to find whether the user is locked out or not
                UserLogin loginDetails = [SELECT isPasswordLocked FROM UserLogin WHERE UserId = :usr.id LIMIT 1];
                if (loginDetails != null){
                    mapResult.put('isPasswordLocked', loginDetails.isPasswordLocked);
                } else {
                    mapResult.put('isPasswordLocked', false);
                }
                if (Test.isRunningTest()) {
                    mapResult.put('isPasswordLocked', tstIsPasswordLocked);
                }
            }
            return mapResult;
        }

        /**
         * @author      Kristian Vegerano
         * @description Method that determines if the user's identity needs to be challenged or not
         * @revision    23/03/2021 - Kristian Vegerano - Created
         */
        public Boolean determineByPassTwoFactor(Id userId){
            // initialize variable
            LoginHistory contextLoginHistory;
            List<VerificationHistory> verificationHistoryList = new List<VerificationHistory>();

            // retrieve LoginHistory for the current user
            for(LoginHistory loopLoginHistory : [SELECT Id, SourceIp, Browser 
                                                 FROM LoginHistory 
                                                 WHERE UserId = :userId
                                                 ORDER BY LoginTime DESC
                                                 LIMIT 1]){
                contextLoginHistory = loopLoginHistory;
            }

            // retrieve VerificationHistory of the current user for email
            if(contextLoginHistory != null){
                for(VerificationHistory loopVerificationHistory : [SELECT Id, SourceIp, LoginHistory.Browser
                                                                FROM VerificationHistory 
                                                                WHERE UserId = :userId
                                                                        AND Status = 'Succeeded'
                                                                        AND LoginHistory.SourceIp = :contextLoginHistory.SourceIp
                                                                        AND VerificationMethod = 'Email'
                                                                ORDER BY VerificationTime DESC]){
                    // check per browser
                    if(contextLoginHistory.Browser == loopVerificationHistory.LoginHistory.Browser){
                        verificationHistoryList.add(loopVerificationHistory);
                    }
                }
            }

            Boolean doBypass = false;
            // retrieve user details            
            User contextUser = [SELECT Id, CreatedDate, LastLoginDate, LastPasswordChangeDate, Last_2FA_Login__c FROM User WHERE Id = :userId LIMIT 1];
            if(contextUser != null){
                // requested for a password reset - or test is running
                if(contextUser.LastLoginDate == contextUser.LastPasswordChangeDate && !Test.isRunningTest()){
                    doBypass = true;
                }

                // the user have not logged in yet before
                if(contextUser.Last_2FA_Login__c == null){
                    doBypass = true;
                }

                // skip challenge if device address already verified
                if(!verificationHistoryList.isEmpty()){
                    doBypass = true;
                }
            }

            return doBypass;
        }
    }
    
    // Helper class for text validation utility 
    // @parameter input - a string to validate
    // @returns - true if the string contains cross scripting or other undesirable texts
    public static boolean isUnsafe(String input) {
        if(String.isEmpty(input)) return false;
        if (TextValidationUtility.isSafe(input)) return false;
        // Insert any methods to log suspicious activity between here and the return statement
        return true;
    }
    
    // Helper class override for text validation utility
    // @parameter input - a list of field values to validate
    // @returns - true if the string contains cross scripting or other undesirable texts
    public static boolean isUnsafe(List<Object> input) {
        string toValidate = '';
        for (Object currentFieldValue : input) {
            String strValue = String.valueOf(currentFieldValue);
            if (String.isNotEmpty(strValue)) toValidate += strValue;
        }
        return isUnsafe(toValidate);
    }

    // Helper class override for text validation utility
    // @parameter dataObject - an SObject to validate
    // @returns - true if any fields of the SObject contain cross scripting or other undesirable texts
    public static boolean isUnsafe(SObject dataObject) {
        if (dataObject == null) return false;
        return isUnsafe(dataObject.getPopulatedFieldsAsMap().values());
    }
    
     // Validates an SOBject for unsafe data and strips an SObject of unwanted fields of data
    // @parameter dataObject - an SObject to clean
    // @parameter fieldsToKeep - a csv list of fields to be retained
    // @returns - a cleaned SObject if no unsafe data is found, otherwise null
    public static SObject cleanSObject(SObject maybeUnsafe, String fieldsToKeep) {
        Map<String,Object> populatedFields = maybeUnsafe.getPopulatedFieldsAsMap();
        if (isUnsafe(populatedFields.values())) return null;
        return stripSObject(maybeUnsafe.getSObjectType(),populatedFields,fieldsToKeep);
    }
    
    // Override that Removes unwanted or unexpected fields from an SObject
    // @parameter maybeUnsafe - A data object that may contain unexpectedly populated fields
    // @parameter fieldsToKeep  a csv list of fields to retain (wanted fields)
    // @returns - a new Sobject that is striped of unwanted fields
    public static SObject stripSObject(SObject maybeUnsafe, String fieldsToKeep) {
        if (maybeUnsafe == null) return null;
        return stripSObject(maybeUnsafe.getSObjectType(),maybeUnsafe.getPopulatedFieldsAsMap(),fieldsToKeep);
    }

    // Removes unwanted or unexpected fields from an SObject
    // @parameter maybeUnsafe - A data object that may contain unexpectedly populated fields
    // @parameter populatedFields - A Map of Field names and their values
    // @parameter fieldsToKeep  a csv list of fields to retain (wanted fields)
    // @returns - a new Sobject that is striped of unwanted fields
    public static SObject stripSObject(Schema.SObjectType targetType, Map<String,Object> populatedFields, String fieldsToKeep) {
        SObject maybeSafe = targetType.newSObject();
        for(string currentFieldName : fieldsToKeep.split(',')) {
            if (populatedFields.containsKey(currentFieldName)) maybeSafe.put(currentFieldName,populatedFields.get(currentFieldName));
        }
        return maybeSafe;
    }
    
    // there is inconsistent ways in which errors are reported to LWC clients.
    // this override method caters for a "result" type return message.
    public static Map<String,String> userMessage(String type, String message) {
        return new Map<String, String> {
            RETURN_RESULT => type,
            RETURN_MESSAGE => message   
        };
    }
    
    // there is inconsistent ways in which errors are reported to LWC clients.
    // this override method caters for a "status" type return message.
    public static Map<String,String> userMessageCC(String type, String message) {
        return new Map<String, String> {
            RETURN_STATUS => type,
            RETURN_MESSAGE => message   
        };
    }

    
    private static Map<String,String> unsafeUserInputMessage() {
        return userMessage(RESULT_TYPE_ERROR,MESSAGE_UNSAFE_INPUT);
    }
    private static Map<String,String> unsafeParameterMessage() {
        return ExperienceAuthenticationServices.userMessage(RESULT_TYPE_ERROR,MESSAGE_UNSAFE_PARAMETERS);
    }


     /**
     * @author      Vinothraja
     * @description Creates an Agent Portal user, adds him to the Agent Portal community, and assigns the necessary Permission sets/groups
     * @param       User agentUser - user record 
     * @return      User
     * @revision    06/04/2023 - Vinothraja - Created
     * @revision    24/04/2023 - SMendu - Optimized to reuse the helper methods 
     */
    public static User createAgentUser(User agentUser) {
          // Input Guard
          //if (isUnsafe(agentUser)) return unsafeUserInputMessage();
          //Initialize variables
          Map<String, Object> resultMap = new Map<String, String>();
          Savepoint userCreationSavePoint = Database.setSavepoint();
          System.Domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
          String suffix = AgentPortalConstants.AGENT_PORTAL_USER_SUFFIX + (d.getSandboxName() != null ? '.' + d.getSandboxName() : '');
          User createdPartnerUser = null;
          try{
         
            //prepare community user
            agentUser.IsActive = true;
            // agentUser.ProfileId = AgentPortalConstants.AGENT_PROFILE_ID;

            //generate user alias
            agentUser.Alias = '';
            // take first letter of First Name
            if(agentUser.FirstName != null) {
                agentUser.Alias += agentUser.FirstName.toLowerCase().substring(0, 1); 
            }
            // take first 4 letters from Last Name (Padding to accomodate LN less than 4 chars long)
            agentUser.Alias += agentUser.LastName.toLowerCase().rightpad(5).substring(0, 4).trim(); 
            agentUser.username = agentUser.username + suffix;
            agentUser.EmailEncodingKey =  Constants.EMAIL_ENCODING_KEY;
            agentUser.LanguageLocaleKey =  Constants.LANGUAGE_LOCALE_KEY;
            agentUser.LocaleSidKey =  Constants.LOCALE_SID_KEY;
            agentUser.TimeZoneSidKey =  Constants.TIME_ZONE_SID_KEY;
            // Super user access for sharing Applications within the Agency
            agentUser.IsPrmSuperUser = true; 

            createdPartnerUser = new CommitQueryRecords().insertUserRecord(agentUser);

            assignPermissionSets(new Set<String>{createdPartnerUser.Id}, new List<String>{AgentPortalConstants.AGENT_PERMISSION_SET }, new List<String>{AgentPortalConstants.AGENT_PERMISSION_SET_GROUP});

            // Add permission sets -- END
        } catch(Exception ex){
            LogUtilityException.LogException(ex);    
            // revert changes
            Database.rollback(userCreationSavePoint);
            //throw new AgentPortalPayload.AgentManagementException('Create Agency User failed - ' + ex.getMessage());
        }

        return createdPartnerUser;
    }

    /**
     * @author      Vinothraja
     * @description Gets the Portal Roles available for a Contact's Agency, 
     *              and returns the apt role based on the Contact's Access Level
     * @param       List<Contact> conList - List of Contacts whose UserRole needs to retrieved
     * @return      Map of Contact To UserRole
     * @revision    24/04/2023 - Vinothraja - Created
     * @revision    24/01/2024 - Jitender Padda - bulkified
    */
    public static Map<Id, UserRole> getUserRole(List<Contact> conList) {
        Map<Id, UserRole> conIdToPortalUserRoleMap = new Map<Id, UserRole>();
        Set<Id> agencyIdSet = new Set<Id>();

        for (Contact con : conList) {
            List<String> agentAccessLevel = con.Agency_Contact_Roles__c?.split(';');
            Account agency = new Account(id = con.AccountId);

            if (agentAccessLevel == null || agency == null) {
                throw new AgentPortalPayload.AgentManagementException('Invalid Agent Role');
            }

            agencyIdSet.add(con.AccountId);
        }

        // Create a map of Agency with Portal User Roles (only 2 roles exist) - Partner Manager, Partner User
        Map<String, UserRole> agencyIdToUserRoleMap = new Map<String, UserRole>();

        for (UserRole ur : [
            SELECT Id, Name, PortalAccountId
            FROM UserRole
            WHERE PortalAccountId IN :agencyIdSet
        ]) {
            if (ur.Name.contains('Partner Manager')) {
                agencyIdToUserRoleMap.put(ur.PortalAccountId + 'Manager', ur);
            } else {
                agencyIdToUserRoleMap.put(ur.PortalAccountId + 'User', ur);
            }
        }

        for (Contact con : conList) {
            // Assign Agent's Role based on the accesslevel
            List<String> agentAccessLevel = con.Agency_Contact_Roles__c.split(';');

            for (String ar : agentAccessLevel) {
                if (AgentPortalConstants.AGENT_PORTAL_MANAGERS.contains(ar)) {
                    conIdToPortalUserRoleMap.put(con.Id, agencyIdToUserRoleMap.get(con.AccountId + 'Manager'));
                    break;
                }

                if (AgentPortalConstants.AGENT_PORTAL_USERS.contains(ar)) {
                    conIdToPortalUserRoleMap.put(con.Id, agencyIdToUserRoleMap.get(con.AccountId + 'User'));
                }
            }
        }
        
        return conIdToPortalUserRoleMap;
    }

   /**
     * @author      Shalini Mendu
     * @description Method used by manageAgencyUser lwc which enables the internal user to generate a partner user for the contact
     * @param       String partnerUserSpecifics - contact record in JSON format
     * @return      Map<String, Object>
     * @revision    24/04/2023 - Shalini Mendu - Created
     */
    @AuraEnabled
    public static Map<String, Object> buildAndGenerateAgentUser(String partnerUserSpecifics) {
        // Input Guard
        if (isUnsafe(partnerUserSpecifics)) return unsafeUserInputMessage();
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();
        User agentUser  = null;
        try {
            //Deserialize user details
            Map<String, Object> userDetails = (Map<String, Object>)JSON.deserializeUntyped(partnerUserSpecifics);
            //Query profile
            Profile partnerUserProfile = (Profile)new CommitQueryRecords().queryRecords('SELECT Id FROM Profile WHERE Name = \'' + Constants.AGENT_USER_PROFILE + '\'')[0];
            Id contactId = (String)userDetails.get('ContactId');
            Contact con = (Contact)new CommitQueryRecords().queryRecords('SELECT Id,AccountId,Agency_Contact_Roles__c FROM Contact WHERE Id = \'' + (String)userDetails.get('ContactId') + '\'')[0];
            //prepare community user
            agentUser = new User(Username = (String)userDetails.get('Username'), Email = (String)userDetails.get('Email'), 
                                FirstName = (String)userDetails.get('FirstName'), MiddleName = (String)userDetails.get('MiddleName'),
                                LastName = (String)userDetails.get('LastName'), Suffix = (String)userDetails.get('Suffix'), 
                                CommunityNickname = (String)userDetails.get('Nickname'), ContactId = (String)userDetails.get('ContactId'),
                                IsActive = true, ProfileId = partnerUserProfile.Id);
            User completeUser = createAgentUser(agentUser);
            // update user's role 
            // NOTE: portal role hierarchy is established after the first user is created
            UserRole userRole = getUserRole(new List<Contact>{con}).get(con.Id);
            System.debug('userRole=='+userRole);
            completeUser.UserRoleId = userRole.id;
            update completeUser;
            resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
            resultMap.put('AGENT_ID', completeUser.Id);
        } catch(Exception ex) {
            // inform client          
            resultMap.put(RETURN_STATUS, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE, MESSAGE_EXCEPTION);
            // Log exception
            LogUtilityException.LogException(ex);  
			throw new AgentPortalPayload.AgentManagementException('Something went wrong, check the exception logs');

        }
        return  resultMap;
    }
    /**
     * @author      Shalini Mendu
     * @description Checks if the current Contact is already created as a User, if so, disables User creation button
     * @param       String contactId - contact record Id
     * @return      Map<String, Object>
     * @revision    24/04/2023 - Shalini Mendu - Created
     */
    @AuraEnabled
    public static Map<String, Object> checkHasAgentUser(String contactId) {
                System.debug(' in checkhas agent user???');

        // Input Guard
        if (isUnsafe(contactId)) return unsafeParameterMessage();
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();

        try{
            //Query profile
            Profile agentUserProfile = [SELECT Id FROM Profile WHERE Name = :AgentPortalConstants.AGENT_PROFILE];

            User agentUser = null;
            List<User> userList = [SELECT Id, IsActive, contact.AccountId, Username 
                                 FROM User 
                                 WHERE ContactId = :contactId 
                                    AND ProfileId = :agentUserProfile.Id];
            if(!userList.isEmpty())
            {
                agentUser = userList[0];
            }
            //check if there is matching contact id
            if(agentUser!=null){
                //add result
                resultMap.put('USER_NAME', JSON.serialize(agentUser.Username));
                resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
                resultMap.put('HAS_PARTNER_USER', JSON.serialize(true));
                resultMap.put('IS_PARTNER_ACTIVE', JSON.serialize(agentUser.IsActive));
                resultMap.put('PARTNER_ACCOUNT_ID', JSON.serialize(agentUser.contact.AccountId));
            }else{
                //add result
                resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
                resultMap.put('HAS_PARTNER_USER', JSON.serialize(false));
                resultMap.put('IS_PARTNER_ACTIVE', JSON.serialize(true));
                resultMap.put('PARTNER_ACCOUNT_ID', JSON.serialize(''));
            }
            
        }catch(Exception ex){
            // inform client          
            resultMap.put(RETURN_STATUS, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE,MESSAGE_EXCEPTION);
            // Log exception
            LogUtilityException.LogException(ex);
        }

        //Return results
        return resultMap;
    }

     /**
     * @author      Shalini Mendu
     * @description Updates Agent user
     * @param       String partnerUserSpecifics - contact record in JSON format
     * @return      Map<String, Object>
     * @revision    24/04/2023 - Shalini Mendu - Created
     */
    @AuraEnabled
    public static Map<String, Object> updateAgentUser(String partnerUserSpecifics) {
        // Input Guard
        if (isUnsafe(partnerUserSpecifics)) return unsafeUserInputMessage();
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();
        try{
            //Query profile
            Profile partnerUserProfile = (Profile)new CommitQueryRecords().queryRecords('SELECT Id FROM Profile WHERE Name = \'' + Constants.AGENT_USER_PROFILE + '\'')[0];
            //Deserialize user details
            Map<String, Object> userDetails = (Map<String, Object>) JSON.deserializeUntyped(partnerUserSpecifics);

            //Retrieve related partner user
            String contactId = (String)userDetails.get('ContactId');

            User partnerUser;
            for(User loopUser : [SELECT Id, IsActive
                                 FROM User 
                                 WHERE ContactId = :contactId 
                                    AND ProfileId = :partnerUserProfile.Id]){
                partnerUser = loopUser;
            }            

            Boolean updatedPartnerActiveStatus = (Boolean)userDetails.get('isPartnerActive');
            Id partnerAccountId = (Id)userDetails.get('PartnerAccountId');
            //Activate or Deactivate Partner User
            if(updatedPartnerActiveStatus !=  partnerUser.IsActive){
                User u = (User) new CommitQueryRecords().updateUserRecord(new User(id = partnerUser.id, IsActive = updatedPartnerActiveStatus));
            }
            // Assign/Remove Permission Sets based on Partner Access Levels
            if (!updatedPartnerActiveStatus){

                 // Remove Permission sets when Inactive
                removePermissionSets(partnerUser.Id, new List<String>{AgentPortalConstants.AGENT_PERMISSION_SET});
                removePermissionSets(partnerUser.Id, new List<String>{AgentPortalConstants.AGENT_PERMISSION_SET_GROUP});
            }else{
                // Assign Permission sets when turned to Active
                assignPermissionSets(new Set<String>{partnerUser.Id}, new List<String>{AgentPortalConstants.AGENT_PERMISSION_SET }, new List<String>{AgentPortalConstants.AGENT_PERMISSION_SET_GROUP});

            }

            //add result
            resultMap.put(RETURN_STATUS, STATUS_TYPE_SUCCESS);
        }catch(Exception ex){
            // inform client          
            resultMap.put(RETURN_STATUS, RESULT_TYPE_ERROR);
            resultMap.put(RETURN_MESSAGE,MESSAGE_EXCEPTION);
            // Log exception
            LogUtilityException.LogException(ex);
        }

        //Return results
        return resultMap;
    }
    
    /**
     * @author      Shalini Mendu
     * @description Updates Agent user
     * @param       String ContactId of the user
     * @return      Map<String, Object>
     * @revision    24/04/2023 - Shalini Mendu - Created
     
    @AuraEnabled
    public static String retrieveUserDetails(String contactId) {
        return [select id, firstname from contact where id=:contactId].firstname;
    }*/

    /**
     * @author      Peter Sewell
     * @description Checks if user has verified mobile number via External Service. e.g. Twilio
     * @param       String Id of the user
     * @return      true if externally verified, otherwise false
     * @revision    14/09/2023 - Peter Sewell - Created
     */
    private static Boolean hasExternalVerifiedMobile(String userId) {
        Boolean externalVerifiedMobile = false;
        
        // Check schema to ensure that externally verified flag field exists on user object
        String extVerifiedFieldName = 'MFA_Mobile_Verified_External__c';
        Boolean doesFieldExist = Schema.SObjectType.User.fields.getMap().containsKey(extVerifiedFieldName);

        // If so, check its value
        if (doesFieldExist) {
            String strWhereClause = ' Id = :userId';
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
                                                    .showSOQLStatement(true)
                                                    .setEnforced(false)
                                                    .querySObject('User')
                                                    .queryFields(new Set<String> {extVerifiedFieldName})
                                                    .getQuery(strWhereClause);

            for (User usr : Database.query(dynamicSearchQuery)) {
                externalVerifiedMobile = (Boolean) usr.get(extVerifiedFieldName);
            }
        }

        return externalVerifiedMobile;
    } 

}