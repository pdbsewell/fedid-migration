/**
 * @description Controller class for the WES SSO registration and login LWC components
 * @revision    16/10/2023 - Peter Sewell - Created
 * Date         Author          Modification
 * 2023-10-16   Peter Sewell   	Initial Version
 * 2023-10-31   Peter Sewell    A few updates to message strings and stop exception messages bubbling up to the user 
 * 2023-10-31   Peter Sewell    Enhance OTP code expiry logic to enable expiry time to be set to < Twilio min of 5 minutes via OTP_EXPIRY_SECS
 * 2023-11-03   Peter Sewell    Add support for multiple contact points to be returned to LWC enabling user to pick one for OTP  
 * 2023-11-03   Peter Sewell    Fix a few UI navigation issues
 * 2023-11-12   Peter Sewell    Fix year match bug
 * 2023-11-15   Peter Sewell    Trim leading and trailing spaces from FN/LN before matching
 * 2024-03-14   Peter Sewell    Add mono name support (contact has no legal first name)
 * 2024-10-08   Peter Sewell    Handle scenario where an inactive user has duplicate student id in user.person_id field
 * 2024-10-08   Peter Sewell    Migrate logging to Nebula
 */
 public without sharing class WesLoginAndRegistrationController {
    
    // Constants
    public static final String SSO_MEMBER_PERM_SET = 'SsoLite SSO user';
    public static final String SSO_PROFILE = 'Customer Community General User';
    public static final String NAME_SPACE_VERIFICATION = 'WESV'; // Used to prefix verification org cache keys
    public static final String NAME_SPACE_CONTACT_POINTS = 'WESP'; // Used to prefix contact point org cache keys
    public static final Integer OTP_EXPIRY_SECS = 595; // Verification code expiry 
    public static final String TST_CONTACT_PERSON_ID = '00000000'; // Used to simulate an Experian exception
    public static final String LOG_TAG = 'WesLoginAndRegistrationController'; // Tag for Nebula logger

    // Messages returned and displayed in Login UI
    public static final Map<String, String> MSG = new Map<String, String> {
        'UNSAFE_INPUT'      => 'Details entered do not match a past student record. Bad input.',
        'NO_PAST_STUDENT'   => 'No past student record found. Please check the details entered.',
        'NO_CONTACT_MATCH'  => 'Details entered do not exactly match a past student record. Details must exactly match those we have on your past student record.',
        'CURRENT_STUDENT'   => 'You appear to be a current student. Please navigate back to the WES home page and login using the current students button.',
        'NO_PERSONAL_EMAIL' => 'There is no personal email address linked to your past student record. A non Monash email address is required to complete login. To update, please contact Monash Connect.',
        'NO_CONTACT_POINT'  => 'No valid mobile or email is linked to your past student record. A valid mobile or email is required to complete login. To update your details, please contact Monash Connect.',
        'CP_NOT_IN_CACHE'   => 'Page timed out. Click back button to return to WES login page and try again.',
        'CONTACT_POINT_UNREACHABLE'=> 'The mobile or email linked to your past student record cannot be verified. A valid mobile or email is required to complete login. Please contact Monash Connect.',
        'USER_UPSERT_ERROR' => 'A temporary issue prevented login. Please click back button to return to WES login page and try again',
        'CODE_EXPIRED'      => 'Verification code expired. Click back button to return to WES login page and try again.',
        'CODE_BAD'          => 'Oops, that code doesn\'t look quite right. Please check and verify again.',
        'AUTH_ERROR'        => 'Unable to log you in at this time. Login server is unavailable. Please try again later',
        'REG_EXCEPTION'     => 'Unable to log you in right now. Please try again later or contact Monash Connect.',
        'CP_EXCEPTION'      => 'Unable to send code to selected channel. Please try again later or contact Monash Connect.',
        'VERIFY_EXCEPTION'  => 'Unable to log you in at this time. Login server is unavailable. Please try again later or contact Monash Connect'
    };

    // Default constructor
    public WesLoginAndRegistrationController() {
    }

    // Wrapper for registration results returned to LWC
    //
    public class CheckRegistrationDetailsResult {
        @AuraEnabled
        public String status;

        @AuraEnabled
        public String errorMessage;

        @AuraEnabled
        public String studentId;

        @AuraEnabled
        public String emailAddress;

        @AuraEnabled
        public String contactPoints;

        public Contact studentContact;
    
        public CheckRegistrationDetailsResult(String theStatus, String theErrorMessage, String theStudentId, String theEmailAddress, String theContactPoints, Contact theStudentContact) {
            status = theStatus;
            errorMessage = theErrorMessage;
            studentId = theStudentId;
            emailAddress = ''; // Dont need to return email address
            contactPoints = obfuscateContactPoints(theContactPoints);
            studentContact = theStudentContact;
        }
    }

    // Wrapper for login result returned to LWC
    //
    public class LoginResult {
        @AuraEnabled
        public String status;

        @AuraEnabled
        public String errorMessage;

        @AuraEnabled
        public String verificationId;
    
        public LoginResult(String theStatus, String theDetails, String studentId) {
           
            status = theStatus;
            if (theStatus == 'SUCCESS') {
                errorMessage = '';
                verificationId = theDetails;
            } else {
                String message = MSG.get(theDetails);
                LogUtilityException.logExceptionMSG('WES SSO LoginResult', 'Student Id ' + studentId, message);
                nebula.logger.debug('WES SSO LoginResult: '  + 'Student Id ' + studentId + ': ' + message, getContactByStudentId(studentId)).addTag(LOG_TAG);
                nebula.logger.saveLog();
                errorMessage = message;
                verificationId = '';                
            }
        }
    }

    // Wrapper for verification state stored in org cache
    //
    private class VerificationState {

        public DateTime timeSent;       // Time OTP was sent
        public String verificationId;   // Twilio verify id returned when otp is sent
    
        public VerificationState(DateTime theTimeSent, String theVerificationIdentifier) {
            timeSent = theTimeSent;
            verificationId = theVerificationIdentifier;
        }
    }

    /**
     * @author      Peter Sewell
     * @description Method that initiates SSO login to WES
     *              Checks if the details entered on SSO login screen match a valid past student contact
     *              If so caches the contact points so that a code can be sent to one in the next step
     * @param       studentId - past student id (person  id)
     * @param       dateOfBirth - used to match contact
     * @param       firstName - used to match contact
     * @param       lastName - used to match contact    
     * @revision    16/10/2023 - Peter Sewell - Created
     */
    @AuraEnabled
    public static CheckRegistrationDetailsResult checkRegistrationDetails(String studentId, String dateOfBirth, String firstName, String lastName){

        try {

            // Validate input params
            if (String.isBlank(studentId) || 
                String.isBlank(dateOfBirth) || 
                String.isBlank(firstName + lastName)) {
                throw new WesLoginAndRegistrationException('checkRegistrationDetails parameters cant be null');
            }

            // Ensure no XSS is in input
            if (isUnsafeInputs(new List<String>{studentId, dateOfBirth, firstName, lastName})) {
                return failedRegistrationCheck(studentId, 'UNSAFE_INPUT');
            }

            // Find contact matching the entered student id
            Contact studentContact = getContactByStudentId(studentId);

            if (studentContact == null) {
                return failedRegistrationCheck(studentId, 'NO_PAST_STUDENT');
            }

            // Check if other details entered match those on the contact record
            if (!registrationDetailsMatchContact(studentContact, dateOfBirth, firstName, lastName)) {
                return failedRegistrationCheck(studentId, 'NO_CONTACT_MATCH');
            }
            
            // Ensure the contact record is for a past student
            if (!isPastStudent(studentContact)) {
                return failedRegistrationCheck(studentId, 'CURRENT_STUDENT');
            }

            // A personal email is required on the contact so we can create a community user
            String validEmail = getPersonalEmail(studentContact); 
            if (String.isBlank(validEmail)) {
                return failedRegistrationCheck(studentId, 'NO_PERSONAL_EMAIL');
            }

            // A valid mobile or email contact point on the contact is required so we can send the OTP for login
            String validContactPoints = getValidContactPoints(studentContact); 
            if (String.isBlank(validContactPoints)) {
                return failedRegistrationCheck(studentId, 'NO_CONTACT_POINT');
            }

            // Now we have a valid past student contact, we cache the contact points 
            // so as we can avoid the (significant) overhead of getting them again
            cachePutContactPoints(validContactPoints, studentId, dateOfBirth, firstName, lastName);
            
            return succeededRegistrationCheck(studentContact, validContactPoints);
        }
        catch(Exception e){
            LogUtilityException.logExceptionMSG('WES SSO checkRegistrationDetails', 'Student Id ' + studentId, e.getMessage());
            nebula.logger.debug('WES SSO checkRegistrationDetails: ' + 'Student Id ' + studentId + ': ' + e.getMessage()).addTag(LOG_TAG);
            nebula.logger.saveLog();
            return failedRegistrationCheck(studentId, 'REG_EXCEPTION');
        }  
    }

    /**
     * @author      Peter Sewell
     * @description Send OTP code to the cached contact point at the specified index
     *              Creates an SSO community user for the contact (if one does not exist) or finds the existing user (if one already does exist)
     * @param       contactPointIndex - index of the contact point in cache
     * @param       studentId - past student id (person  id)
     * @param       dateOfBirth - used to match contact
     * @param       firstName - used to match contact
     * @param       lastName - used to match contact    
     * @revision    06/11/2023 - Peter Sewell - Created
     */
    @AuraEnabled
    public static CheckRegistrationDetailsResult sendCode(String contactPointIndex, String studentId, String dateOfBirth, String firstName, String lastName) {
        try {

            // Validate input params
            if (String.isBlank(contactPointIndex) || 
                String.isBlank(studentId) || 
                String.isBlank(dateOfBirth) ||
                String.isBlank(firstName + lastName)) {
                throw new WesLoginAndRegistrationException('Send code parameters cant be null');
            }

            // Ensure no XSS is in input
            if (isUnsafeInputs(new List<String>{contactPointIndex, studentId, dateOfBirth, firstName, lastName})) {
                return failedRegistrationCheck(studentId, 'UNSAFE_INPUT');
            }

            // Send an OTP code to contact point at the selected contactPointIndex
            String contactPoint = cacheGetContactPoint(contactPointIndex, studentId, dateOfBirth, firstName, lastName);
            if (String.isBlank(contactPoint)) {
                return failedRegistrationCheck(studentId, 'CP_NOT_IN_CACHE');
            }

            if (!sendOtp(studentId, contactPoint)) {
                return failedRegistrationCheck(studentId, 'CONTACT_POINT_UNREACHABLE');
            }    

            // Finally we create or update the portal user to be logged in.
            // The user is linked to the contact associated to the studentId. 
            // NB. We have to do the User DML now as if we do the user DML in verifyLogin() 
            // we will get the exception 'You have uncommitted work pending' when attempting to get the access token 
            // This is because getting the token requires a callout which is not allowed AFTER the user DML :-(
            if (createUserToLogin(studentId) == null) {
                return failedRegistrationCheck(studentId, 'USER_UPSERT_ERROR');
            }
            
            return succeededRegistrationCheck(getContactByStudentId(studentId), contactPoint);
        }
        catch(Exception e){
            LogUtilityException.logExceptionMSG('WES SSO sendCode', 'Student Id ' + studentId, e.getMessage());
            nebula.logger.debug('WES SSO sendCode: '  + 'Student Id ' + studentId + ': ' + e.getMessage(), getContactByStudentId(studentId)).addTag(LOG_TAG);
            nebula.logger.saveLog();
            return failedRegistrationCheck(studentId, 'CP_EXCEPTION');
        }  
    }

    /**
     * @author      Peter Sewell
     * @description Method that verifies the entered OTP matches the code sent to the users contact point in checkRegistrationDetails()
     *              If OTP verification succeeds, the user corresponding to the studentId
     *              is then logged in (an access token is obtained via JWT flow)
     *              This access token is sent to frontdoor.jsp which will set an SSO sid cookie
     *              and ultimately results in a SAML response being sent to WES ACS
     * @param       studentId - the student Id (person id)
     * @param       code - the OTP verification code entered by the user (which will be matched)
     * @param       startUrl - the URL to redirect the user after logging in (should be the IDP end point which will redirect to SP ACS)
     * @revision    16/10/2023 - Peter Sewell - Created
     */
    @AuraEnabled
    public static LoginResult verifyLogin(String studentId, String code, String startUrl) {
        
        try {

            // Validate input params
            if (String.isBlank(studentId) || 
                String.isBlank(code) || 
                String.isBlank(startUrl)) {
                throw new WesLoginAndRegistrationException('Verify Login parameters cant be null');
            }

            // Verify the code has not expired and that the entered code matches the one sent
            //
            VerificationState verificationState = (VerificationState) Cache.Org.get(NAME_SPACE_VERIFICATION + studentId);
            if (verificationState == null || verificationState.timeSent.addSeconds(OTP_EXPIRY_SECS) < datetime.now()) {
                return new LoginResult('FAILED', 'CODE_EXPIRED', studentId);
            }
            Boolean isVerified = !isTst()? OneTimeTokenService.verifyOtp(ExperienceMFAServices.otpWrapper(code, verificationState.verificationId), OneTimeTokenService.Service.MFA): true;
            if (!isVerified) {
                return new LoginResult('FAILED', 'CODE_BAD', studentId);
            }

            // Login the user
            String token = getAccessToken(studentId);
            if (String.isBlank(token)) {
                return new LoginResult('FAILED', 'AUTH_ERROR', studentId);
            }
            String siteUrl = Site.getBaseRequestUrl().substring(0, Math.max(Site.getBaseRequestUrl().length(),2) - 2);
            String encodedStartUrl = EncodingUtil.urlEncode(startUrl, 'UTF-8');

            //TODO Clear cache

            PageReference frontDoor = new PageReference(siteUrl + '/secur/frontdoor.jsp?sid=' + token + '&retURL=' + encodedStartUrl);
            return new LoginResult('SUCCESS', frontDoor.getUrl(), studentId); 
        }
        catch(Exception e){
            LogUtilityException.logExceptionMSG('WES SSO verifyLogin', 'Student Id ' + studentId, e.getMessage());
            nebula.logger.debug('WES SSO verifyLogin: ' + 'Student Id ' + studentId + ': ' + e.getMessage()).addTag(LOG_TAG);
            nebula.logger.saveLog();
            return new LoginResult('FAILED', 'VERIFY_EXCEPTION', studentId);
        }  
    }

    /**
     * @author      Peter Sewell
     * @description Method that creates or updates user to login
     * @revision    16/10/2023 - Peter Sewell - Created
     */
    private static User createUserToLogin (String studentId) {
        User userToLogin = null;

        // Ensure there is no inactive non portal user with this studentId (Person_Id__c)
        // Otherwise we will get a DUPLICATE_VALUE exception
        if (cleanPersonIdFromInactiveNonPortalUser(studentId)) {
            return null; // above line (necessarily) runs async so we can only return a null, user will have to try logging in again
        }

        // Get the contact associated to this student id
        Contact ctc = getContactByStudentId(StudentId);
        if (ctc == null) {return userToLogin;}

        // See if there is already a user for this contact
        List<User> existingUsers = [SELECT id, Username, Person_Id__c, 
                                            Contact_Date_of_Birth__c, 
                                            Contact_Legal_FN__c,
                                            Contact_Legal_LN__c,
                                            IsActive,
                                            ContactId,
                                            IsPortalEnabled
                                    FROM User WHERE ContactId = :ctc.Id LIMIT 1];

        if (existingUsers != null && !existingUsers.isEmpty()) { 
            // Yes there is...
            User existingUser = existingUsers[0];
            userToLogin = existingUser;

            // ...however, if the linked user is inactive, we must delink and create a new user
            if (existingUser.IsActive == false) {
                delinkCommunityUser(existingUser.Id);
                return null; // above line runs async so we can only return a null, user will have to try logging in again
            }
        } else {
            // No existing user for this contact, go make one
            userToLogin = createUserForContact(ctc); 
        }

        // Ensure SAML attributes pulled from the user record are updated with latest
        // details from the contact record
        // Namely: Legal FN & LN, DOB, Person id (student id)
        Date dDob = ctc.Birthdate;
        String dateStr = dDob.day() + '/' + dDob.month() + '/' + dDob.year();
        if (userToLogin.Contact_Date_of_Birth__c != dateStr) {
            userToLogin.Contact_Date_of_Birth__c = dateStr;
        }
        userToLogin.Contact_Legal_FN__c = (String.isBlank(ctc.First_Name__c)) ? ctc.Last_Name__c : ctc.First_Name__c; // FN = LN for mono names otherwise SAML assert is bad
        userToLogin.Contact_Legal_LN__c = ctc.Last_Name__c;
        userToLogin.Person_Id__c = StudentId;

        // Finally, either create or update user... 
        Database.upsert(userToLogin);

        // ...and ensure SSO perm set is assigned
        // This perm set is required to 
        // 1. make user member of ssolite community
        // 2. provide access to UniCRMUtilities cApp (used to get an access token)
        makeSsoPortalMember(userToLogin); 

        return userToLogin;
    }

    // Find any inactive user with studentId in person_id__c field and that is NOT a portal user
    // If found clear the value and return true, otherwise false
    @TestVisible
    private static Boolean cleanPersonIdFromInactiveNonPortalUser(String studentId) {

        for (User u : [SELECT Id, person_id__c FROM User WHERE person_id__c = :studentId AND IsActive = false AND IsPortalEnabled = false]) {
            try { 
                List<Async_Process__e> eventsToPublish = new List<Async_Process__e>();
                AsyncProcessPayload payload = new AsyncProcessPayload();
                payload.put ('userId', u.Id);
                Async_Process__e evt = new Async_Process__e (Process_Name__c = 'WesLoginAndRegistrationController.CleanPersonIdFromInactiveNonPortalUser',Parameter__c = payload.serialize());
                eventsToPublish.add(evt);
                if(!eventsToPublish.isEmpty()) {
                    EventBus.publish(eventsToPublish);
                }
            } catch(Exception ex){
                LogUtilityException.logException('WES SSO cleanPersonIdFromInactiveNonPortalUser',JSON.serializePretty(u.Id),ex,ex.getMessage(),'Error'); 
                nebula.logger.error(
                    'WES SSO cleanPersonIdFromInactiveNonPortalUser: '  + 
                    'Student Id ' + studentId + ': ' + 
                    'User Id ' + u.Id + ': ' + 
                    ex.getMessage(), 
                    getContactByStudentId(studentId)).addTag(LOG_TAG);
                nebula.logger.saveLog();
            } finally {
                return true;
            }    
        }

        return false; // no user found
    }

    // Async class to clear person_id__c field from user record
    //
    public class CleanPersonIdFromInactiveNonPortalUser implements IPlatformEventInvocable {
     
        private String userId;

        public void execute(List<AsyncProcessPayload> payload) {
			try {
				initialize(payload);
				run();
			} catch(Exception e) {
				LogUtilityException.logException(e, this.userId);
                nebula.logger.error(
                    'WES SSO CleanPersonIdFromInactiveNonPortalUser: ' + 
                    'User Id ' + this.userId + ': ' + 
                    e.getMessage()).addTag(LOG_TAG);
                nebula.logger.saveLog();
			} finally {
				LogUtilityException.getLimits();
			}
		}

		private void initialize(List<AsyncProcessPayload> payloads) { 
			if(payloads != null) {
				for(AsyncProcessPayload payload : payloads) {
					this.userId = (String) payload.get('userId');
				}
			}
		}

        public void run() {

            String oldPersonId;

            // User to clear person_id__c from 
            List<User> usrs = [SELECT id, Person_Id__c 
                               FROM User 
                               WHERE Id = :this.userId LIMIT 1];
            User u = usrs[0];
            oldPersonId = u.Person_Id__c;
            u.Person_Id__c = null; 
            Database.SaveResult sr = Database.update(u);

            // We want to know about these cases, so log it
            LogUtilityException.logExceptionMSG(
                'WES SSO CleanPersonIdFromInactiveNonPortalUser', 
                'User Id ' + this.userId,
                'Inactive user had duplicate student id in person_id field (' + 
                oldPersonId + '), and has had this field cleared to avoid duplicate value exception');
            nebula.logger.debug(
                'WES SSO CleanPersonIdFromInactiveNonPortalUser: ' + 
                'User Id ' + this.userId + ': ' +
                'Inactive user had duplicate student id in person_id field (' + 
                oldPersonId + '), and has had this field cleared to avoid duplicate value exception', u).addTag(LOG_TAG);
            nebula.logger.saveLog();

            // Check results
            if (!sr.isSuccess()) {
                for(database.Error err: sr.getErrors()){
                    LogUtilityException.logExceptionMSG(
                        'WES SSO CleanPersonIdFromInactiveNonPortalUser', 
                        'User Id ' + this.userId,
                        'Error clearing person_id field from user record');
                    nebula.logger.error(
                        'WES SSO CleanPersonIdFromInactiveNonPortalUser: ' + 
                        'User Id ' + this.userId + ': ' +
                        'Error clearing person_id field from user record', u).addTag(LOG_TAG);
                    nebula.logger.saveLog();
                }
            }
        }
    }

    // Delink contact from community user (async)
    // We have to do this async as community users (including guest) cant delink contacts from users
    // Async process runs as autoproc user 
    private static void delinkCommunityUser(String userId) {
        try{ 
            List<Async_Process__e> eventsToPublish = new List<Async_Process__e>();
            AsyncProcessPayload payload = new AsyncProcessPayload();
            payload.put ('userId', userId);
            Async_Process__e evt = new Async_Process__e (Process_Name__c = 'WesLoginAndRegistrationController.DelinkCommunityUser',Parameter__c = payload.serialize());
            eventsToPublish.add(evt);
            if(!eventsToPublish.isEmpty()) {
                EventBus.publish(eventsToPublish);
            }
        }catch(Exception ex){
            LogUtilityException.logException('WES SSO delinkCommunityUser',JSON.serializePretty(userId),ex,ex.getMessage(),'Error'); 
            nebula.logger.error(
                'WES SSO delinkCommunityUser: '  + 
                'User Id ' + userId + ': ' + 
                ex.getMessage()).addTag(LOG_TAG);
            nebula.logger.saveLog();
        }        
    }

    // Async class to delink contact from community user
    //
    public class DelinkCommunityUser implements IPlatformEventInvocable {
     
        private String userId;

        public void execute(List<AsyncProcessPayload> payload) {
			try {
				initialize(payload);
				run();
			} catch(Exception e) {
				LogUtilityException.logException(e, this.userId);
                nebula.logger.error(
                    'WES SSO DelinkCommunityUser: ' + 
                    'User Id ' + this.userId + ': ' + 
                    e.getMessage()).addTag(LOG_TAG);
                nebula.logger.saveLog();
			} finally {
				LogUtilityException.getLimits();
			}
		}

		private void initialize(List<AsyncProcessPayload> payloads) { 
			if(payloads != null) {
				for(AsyncProcessPayload payload : payloads) {
					this.userId = (String) payload.get('userId');
				}
			}
		}

        public void run() {

            // User to delink from contact
            List<User> usrs = [SELECT id, 
                                Username, Person_Id__c, 
                                Contact_Date_of_Birth__c, 
                                Contact_Legal_FN__c,
                                Contact_Legal_LN__c,
                                IsActive,
                                ContactId,
                                IsPortalEnabled
                            FROM User WHERE Id = :this.userId LIMIT 1];
            User u = usrs[0];
            u.IsPortalEnabled = false; 
            u.Person_Id__c = null; 
            u.Contact_Date_of_Birth__c = null;
            u.Contact_Legal_FN__c = null;
            u.Contact_Legal_LN__c = null;
            Database.SaveResult sr = Database.update(u);

            // We want to know about these cases, so log it
            LogUtilityException.logExceptionMSG(
                'WES SSO DelinkCommunityUser', 
                'User Id ' + this.userId,
                'Contact was associated to an inactive user ' + 
                u.username + ', and has been unlinked');
            nebula.logger.debug(
                'WES SSO DelinkCommunityUser: ' + 
                'User Id ' + this.userId + ': ' +
                'Contact was associated to an inactive user ' + 
                u.username + ', and has been unlinked', u).addTag(LOG_TAG);
            nebula.logger.saveLog();

            // Check results
            if (!sr.isSuccess()) {
                for(database.Error err: sr.getErrors()){
                    LogUtilityException.logExceptionMSG(
                        'WES SSO DelinkCommunityUser', 
                        'User Id ' + this.userId,
                        'Error delinking user from contact');
                    nebula.logger.error(
                        'WES SSO DelinkCommunityUser: ' + 
                        'User Id ' + this.userId + ': ' +
                        'Error clearing person_id field from user record', u).addTag(LOG_TAG);
                    nebula.logger.saveLog();
                }
            }
        }
    }

    // Find a contact associated to the unique student id
    //
    private static Contact getContactByStudentId(String studentId) {

        // Validate input
        if (String.isBlank(studentId)) {
            return null;
        }

        Contact contactByStudent = null;
        String studentIdTrimmed = studentId.trim();

        Set<String> fieldApiNames = new Set<String>{
            'Id', 
            'Person_Id__c', 
            'Person_ID_unique__c', 
            'Is_Student__c', 
            'PersonalEmail_Text__c',
            'Email',
            'Birthdate',
            'First_Name__c',
            'Last_Name__c'
        };
        String strWHERE = '';
        strWHERE += ' Person_ID_unique__c = :studentIdTrimmed ';
        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(false)
                .querySObject('Contact')
                .queryFields(fieldApiNames)
                .getQuery(strWHERE);
        List<Contact> ctcs = Database.Query(dynamicSOQL);

        if (!ctcs.isEmpty()) {
            contactByStudent = ctcs[0];
        }

        nebula.logger.saveLog();

        return contactByStudent;
    }

    // Determine if contact is relared to a past student
    //
    private static Boolean isPastStudent(Contact ctc) {
        return (!ctc.Is_Student__c);
    }

    /**
     * @author      Peter Sewell
     * @description Method that retrieves a contact's email suitable for passwordless login
     *              Must not be a Monash address
     *              Returns an empty string if no valid emails are found
     * @param       ctc - contact for which to find valid email
     * @revision    16/10/2023 - Peter Sewell - Created
     */
    @TestVisible
    private static String getPersonalEmail(Contact ctc) {
        if (isPersonalEmail(ctc.PersonalEmail_Text__c)) {
            return ctc.PersonalEmail_Text__c;
        }
        if (isPersonalEmail(ctc.Email)) {
            return ctc.Email;
        }
        return '';
    }

    /**
     * @author      Peter Sewell
     * @description Method that retrieves a contact's mobile numbers suitable for passwordless login
     *              Uses Experian to validate, and must be an ISO formatted number. e.g. +61 411 111 111
     *              If more than one valid mobile is linked to the contact returns the primary number (if available)
     *              and if not then the number most recently updated
     *              Returns an empty string if no valid mobiles are found
     * @param       ctc - contact for which to find valid mobile number
     * @revision    16/10/2023 - Peter Sewell - Created
     */
    @TestVisible
    private static String getValidMobileNumber(Contact ctc) {
        String validContactPoints = getValidContactPoints(ctc);

        if (!String.isBlank(validContactPoints)) {
            for (String cp : validContactPoints.split(',')) {
                if (!cp.contains('@')) {
                    return cp;
                }
            }
        }
        return '';
    }

    /**
     * @author      Peter Sewell
     * @description Method that retrieves a contact's mobile and/or email addresses numbers suitable for passwordless login
     *              Uses Experian to validate mobile numbers, and mobile CP must be an ISO formatted number. e.g. +61 411 111 111
     *              Returns contact points as a string list of comma separated contact points
     *              Returns an empty string if no valid contact points are found
     * @param       ctc - contact for which to find valid mobile numbers and/or email addresses
     * @revision    03/11/2023 - Peter Sewell - Created
     */
    @TestVisible
    private static String getValidContactPoints(Contact ctc) {
        List<String> validContactPoints = new List<String>();
        try {
            // Simulate Experian exception for test class
            if (ctc.Person_ID_unique__c == TST_CONTACT_PERSON_ID) throw new SimulatedExperianException('SimulatedExperianException');
            
            // Grab valid mobile and email contct points
            OTPService.ContactOtpAddresses otpAddresses = !isTst()? 
                OTPService.getContactOtpAddresses(ctc.id, true, false):  // True, false will use Experian to validate mobiles
                OTPService.getContactOtpAddresses(ctc.id, false, false); // False, false will bypass Experian
            validContactPoints.addAll(otpAddresses.sms.mobileNumbers);
            for (String e : otpAddresses.email.emailAddresses) {        // Only add personal email addresses
                if (isPersonalEmail(e)) {
                    validContactPoints.add(e);
                }
            }
        } catch (Exception e) {
            String fallbackEmail = getPersonalEmail(ctc);
            if (!String.isBlank(fallbackEmail)) {
                validContactPoints.add(fallbackEmail);
            }
            LogUtilityException.logExceptionMSG('WES SSO getValidContactPoints', 'Student Id ' + ctc.Person_Id__c, e.getMessage());
            nebula.logger.error(
                'WES SSO getValidContactPoints: ' + 
                'Student Id ' + ctc.Person_Id__c + ': ' +
                e.getMessage(), ctc).addTag(LOG_TAG);
            nebula.logger.saveLog();
        }

        return !validContactPoints.isEmpty() ? String.join(validContactPoints, ',') : '';
    }

    // Checks if dateOfBirth, firstName, lastName exactly match those of the ctc
    //
    private static Boolean registrationDetailsMatchContact(Contact ctc, String dateOfBirth, String firstName, String lastName) {
        Boolean detailsMatch = true;

        DateTime DOB = ctc.Birthdate;
        String strDate = DOB.format('yyyy-MM-dd');
        if (strDate != dateOfBirth) {
            detailsMatch = false;
        }

        // Handle mono name i.e. No first name, only last name
        if (String.isBlank(firstName)) { // Mono name (no first name)
            if (String.isNotBlank(ctc.First_Name__c)) { // Has to match null first name on contact
                detailsMatch = false;
            }
        } else { // Has a first name
            if (!firstName.trim().equalsIgnoreCase(ctc.First_Name__c.trim())) {
                detailsMatch = false;
            }
        }

        if (!lastName.trim().equalsIgnoreCase(ctc.Last_Name__c.trim())) {
            detailsMatch = false;
        }

        return detailsMatch;
    }

    /**
     * @author      Peter Sewell
     * @description Send OTP to mobile phone or email
     * @param       contactPoint - mobile or email to send OTP (mobile must be in ISO format with country code)
     * @revision    16/10/2023 - Peter Sewell - Created
     */
    private static Boolean sendOtp(String personId, String contactPoint) {

        try{
            OneTimeTokenService.OneTimeTokenWrapper resp = !isTst()? 
                OneTimeTokenService.sendOtp(
                    contactPoint, 
                    contactPoint.contains('@') ? 'email' : 'sms', 
                    ExperienceMFAServices.MFA_OTP_TEMPLATE_NAME,
                    OneTimeTokenService.Service.MFA)
                :TEST_OTP_WRAPPER();
            // Cache verification Sid and Service Id against personId to we can later validate
            VerificationState verificationState = new VerificationState(
                datetime.now(), 
                resp.VerificationSid + ExperienceMFAServices.MFA_OTP_SEPARATOR + resp.ServiceSid
            );
            Cache.Org.remove(NAME_SPACE_VERIFICATION + personId); // remove prior to ensure ttl is reset
            Cache.Org.put(NAME_SPACE_VERIFICATION + personId, verificationState, math.max(600, OTP_EXPIRY_SECS));
        }catch(Exception ex){
            LogUtilityException.logException(ex, 'WES SSO Twilio : sending to ' + contactPoint + ' for student id ' + personId);
            nebula.logger.error(
                'WES SSO Twilio : sending to: ' + 
                contactPoint + ': ' +
                ' for student id ' + personId + ': ' +
                ex.getMessage()).addTag(LOG_TAG);
            nebula.logger.saveLog();
            return false;
        }  
        return true;
    }               

    // Returns a CheckRegistrationDetailsResult with stats set to FAILED indicating
    // that the entered past student details were invalid.  
    // An explanation of the failure is a string value referenced in the MSG map by the errorLabel key
    // Typically the explanation string is returned to the LWC and displayed in the UI
    //
    private static CheckRegistrationDetailsResult failedRegistrationCheck(String studentId, String errorLabel) {
        
        String errorMsg = MSG.get(errorLabel);

        LogUtilityException.logExceptionMSG('WES SSO failedRegistrationCheck', 'Student Id ' + studentId, errorMsg);
        nebula.logger.debug(
            'WES SSO failedRegistrationCheck: ' + 
            'Student Id ' + studentId + ': ' +
            errorMsg).addTag(LOG_TAG);
        nebula.logger.saveLog();
        
        CheckRegistrationDetailsResult userRegistrationDets = new CheckRegistrationDetailsResult(
            'FAILED',   // Status
            errorMsg,   
            studentId,   
            '',        // Students email address - none for error 
            '',        // Students contact points - none for error
            null);     // Contact - none for error
        return userRegistrationDets;
    }

    // Returns a CheckRegistrationDetailsResult with values indicating that the entered past student 
    // details were valid and eliigible to login.
    //
    private static CheckRegistrationDetailsResult succeededRegistrationCheck(Contact ctc, String contactPoints) {

        CheckRegistrationDetailsResult userRegistrationDets = new CheckRegistrationDetailsResult(
            'SUCCESS',  // Status
            '',         // Error message - none in this case
            ctc.Person_ID_unique__c,
            getPersonalEmail(ctc),
            contactPoints,
            ctc);

        return userRegistrationDets;
    }

    // Instantiates a new community user object associated to the provided contact
    // Does NOT insert the user
    //
    private static User createUserForContact(Contact ctc) {
    
        //retrieve community user profile
        Profile wesProfile = [SELECT Id FROM Profile WHERE Name = :SSO_PROFILE LIMIT 1][0];
        
        //prepare community user
        String email = getPersonalEmail(ctc);
        User communityUser = new User(
            Username = createUniqueUsername(email), // Uses email as username if unique, otherwise makes unique
            Email = email, 
            FirstName = ctc.First_Name__c,
            LastName = ctc.Last_Name__c,
            ContactId = ctc.Id, 
            ProfileId = wesProfile.Id);

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
        String contactId = ctc.Id;
        if(communityUser.FirstName != null) {
            nickname = nickname + communityUser.FirstName.toUpperCase().substring(0, 1);
        }
        nickname = nickname + communityUser.LastName.toUpperCase().substring(0, 1);
        nickname = nickname + contactId.substring(2, contactId.length());
        communityUser.CommunityNickname = nickname;
        communityUser.EmailEncodingKey = 'UTF-8';
        communityUser.TimeZoneSidKey = 'Australia/Sydney';
        communityUser.LanguageLocaleKey = 'en_US';
        communityUser.LocaleSidKey = 'en_AU';

        communityUser.Person_Id__c = ctc.Person_ID_unique__c;
        
        return communityUser;
    } 

    // Assign ssolite perm set to the user
    //
    private static void makeSsoPortalMember(User u) {

        // Dont assign perm set if already has 
        if (isSsoPortalMember(u)) {
            return;
        }

        // Assign user the perm set to make them a member of the SSO portal and UniCRMUtilities cApp
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        for (PermissionSet ps : [SELECT id from PermissionSet WHERE label = :SSO_MEMBER_PERM_SET]) {
             PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=ps.id);
             psas.add(psa);
        }
        if (!psas.isEmpty()) {
            insert psas;
        }   
    }   

    // Check if user already has ssolite perm set assigned
    //
    private static Boolean isSsoPortalMember(User u) {
        Boolean isMemberOfSsoPortal = false;

        for (PermissionSetAssignment psA : [select id from PermissionSetAssignment where PermissionSet.label = :SSO_MEMBER_PERM_SET and AssigneeId = :u.Id]) {
            isMemberOfSsoPortal = true;
        }
        return isMemberOfSsoPortal;
    }   

    // Get an access token to use to login the user associated to the studentId
    //
    private static String getAccessToken(String studentId) {

        String accessToken = null;

        // Find the user
        User u = [SELECT username FROM User where Person_Id__c = :studentId];
        if (u == null) {return null;}

        // Get client id for connected app used to exchange JWT for access token
        String clientId = getClientId();
        if (clientId == null) {return null;}

        // Get name of certificate to use to sign JWT
        String certName = getCertName();
        if (certName == null) {return null;}

        // Construct token request end point
        String siteUrl = Site.getBaseRequestUrl().substring(0, Math.max(Site.getBaseRequestUrl().length(),2) - 2);
        String tokenEndpoint = siteUrl + '/services/oauth2/token';
        
        // Create a JWT representing the user to be logged in
        Auth.JWS jws;
        Auth.JWT jwt = new Auth.JWT();

        jwt.setIss(clientId);
        jwt.setSub(u.username);
        jwt.setAud(siteUrl);
        
        jws = new Auth.JWS(jwt, certName);

        // Exchange JWT for an access token (sid)
        if (!isTst()) {
            Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, jws);
            accessToken = bearer.getAccessToken();
        } else {
            accessToken = 'asdfghjkl1234567890'; // dummy for test class
        }

        return accessToken;
    }

    // Validate form field inputs as valid. i.e. no xss
    //
    private static Boolean isUnsafeInputs(List<String> inputs) {
        for (String input : inputs) {
            if (input == null) continue;
            if (!TextValidationUtility.isSafe(input)) return true;
        }
        return false;
    }

    // Get client id for connected app used to exchange JWT for access token
    // (At this time we are using UniCRMUtilities cApp)
    //
    private static string getClientId() {
        WesLogin__c wesSetting = WesLogin__c.getInstance();
        return (wesSetting != null) ? wesSetting.Client_Id__c : '';
    }

    // Get name of certificate used to sign JWT
    //
    private static string getCertName() {
        WesLogin__c wesSetting = WesLogin__c.getInstance();
        return (wesSetting != null) ? wesSetting.Certificate_Name__c : '';
    }

    // Get email OTP override flag
    //
    private static Boolean isEmailFallback() {
        WesLogin__c wesSetting = WesLogin__c.getInstance();
        return (wesSetting != null) ? wesSetting.Email_OTP__c : false;
    }

    // Obfuscate contact points string list
    //
    private static String obfuscateContactPoints(String contactPoints) {
        List<String> obfuscatedContactPointList = new List<String>();
        for (String cp : contactPoints.split(',')) {
            obfuscatedContactPointList.add(obfuscateContactPoint(cp));
        }
        if (!obfuscatedContactPointList.isEmpty()) {
            return String.join(obfuscatedContactPointList, ','); // convert back into a comma sep list
        } else {
            return '';
        }
    }   

    // Obfuscate a contact point - email or mobile number
    // e.g. foo@bar.com -> f*o@b*r.com
    //
    private static String obfuscateContactPoint(String contactPoint) {
        String emailRegEx = '(?<=.)[^@](?=[^@]*?[^@]@)|(?:(?<=@.)|(?!^)\\G(?=[^@]*$)).(?=.*[^@]\\.)';

        // email
        if (contactPoint.contains('@')) {
            return contactPoint.replaceAll(emailRegEx, '*');
        // mobile
        } else {
            return 'number ending in ' + contactPoint.right(4); 
        }
    }

    // Returns true if email is a personal address, rather than a Monash address
    //
    private static Boolean isPersonalEmail(String email) {
        if (!String.isBlank(email) && !email.endsWithIgnoreCase('monash.edu')) {
            return true;
        }
        return false;
    }

    // Cache the contact points string using a hash of student id, FN, LN, DOB as key
    private static void cachePutContactPoints(String contactPoints, String studentId, String dateOfBirth, String firstName, String lastName) {
        Integer keyInt = (studentId.trim() + dateOfBirth + firstName + lastName).hashCode();
        keyInt = Math.abs(keyInt);
        String key = NAME_SPACE_CONTACT_POINTS + String.valueOf(keyInt);

        Cache.Org.remove(key); // remove prior to ensure ttl is reset
        Cache.Org.put(key, contactPoints, math.max(600, OTP_EXPIRY_SECS));
    }

    // Get contact point at index from cache using a hash of student id, FN, LN, DOB as key
    // If index is out of range or contact points not found in cache return blank string
    // Otherwise return the contact point name
    private static String cacheGetContactPoint(String contactPointIndex, String studentId, String dateOfBirth, String firstName, String lastName) {
        Integer index = Integer.valueOf(contactPointIndex); // Index of contact point 

        Integer keyInt = (studentId.trim() + dateOfBirth + firstName + lastName).hashCode();
        keyInt = Math.abs(keyInt);
        String key = NAME_SPACE_CONTACT_POINTS + String.valueOf(keyInt);

        // Return blank if no contact points in the cache for this key
        String contactPointsStr = (String) Cache.Org.get(key);

        if (contactPointsStr == null) {
            return '';
        }

        // Return blank if index is out of range
        List<String> contactPoints = contactPointsStr.split(',');

        if (index < 0 || index >= contactPoints.size()){
            return '';
        }

        // Otherwise return the CP
        return contactPoints[index];

    }

    // For use when running in test class
    //
    private static OneTimeTokenService.OneTimeTokenWrapper TEST_OTP_WRAPPER() {
        OneTimeTokenService.OneTimeTokenWrapper wrapper = new OneTimeTokenService.OneTimeTokenWrapper();
        wrapper.VerificationSid = '1234567890';
        wrapper.ServiceSid = '1234567890';
        wrapper.Code = '';
        return wrapper;
    }

    // Are we running in a test class
    //
    private static Boolean isTst() {
        if (Test.isRunningTest()) {
            return true;
        }
        return false;
    }

    // Return a unique username.
    // If username param is already unique, returns username.
    // If not, returns username suffixed with a dot plus random 4 characters. 
    //
    @TestVisible
    private static String createUniqueUsername(String username) {
        
        // Already unique, yep
        if (!existsName(userName)) {
            return username;
        }

        // Nope, so make unique
        //
        String randomString = '';

        String characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        Integer charactersLength = characters.length();
        
        for (Integer i = 0; i < 4; i++) { // Generate a 4-character random string
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), charactersLength);
            randomString += characters.substring(randomIndex, randomIndex + 1);
        }
        
        return username + '.' + randomString;
    }

    // Check if username already exists
    //
    private static Boolean existsName(String fullUserName) {
        Boolean result = false;

        User user = new User();  
        user.FirstName = 'any';
        user.LastName = 'any';
        user.Alias = 'any';
        user.EMail = 'any@email.com';
        user.Username = fullUserName;
        user.CommunityNickname = fullUserName;
        user.LocaleSidKey = 'en_US';
        user.LanguageLocaleKey = 'en_US';
        user.EmailEncodingKey = 'UTF-8';
        user.TimeZoneSidKey = 'America/Los_Angeles';
        user.ProfileId = [SELECT Id, Name FROM Profile WHERE Name='Limited Access User' limit 1].Id;

        Savepoint sp = Database.setSavepoint();

        try {
            insert user;
        }
        catch(DmlException ex) {
            if(ex.getDmlStatusCode(0) == StatusCode.DUPLICATE_USERNAME.name()) {
                result = true; 
            }
        }
        finally {
            Database.rollback(sp);
        }

        return result;
    }

    public class SimulatedExperianException extends Exception {}

    public class WesLoginAndRegistrationException extends Exception {}

}