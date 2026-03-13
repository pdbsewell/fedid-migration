/**
 * @description Controller class for Portal_TwoFactor Visualforce page used to implement two factor registration and
 *              challenges for both my.app and alumni community users
 * @group       Services
 * @revision    14/02/2022 - Kristian Vegerano - Created
 * Ver   Date         Author          		Modification
 * 2.2	 2025-08-26	  Ibrahim Rumi			DANO-565
 * 2.1   2024-03-19   Inderpal Dhanoa   	PENGAGE-2730
 * 2.0   2023-11-28   Peter Sewell          Use Twilio as default MFA method where SFDC SMS does not support country
 * 1.9   2023-10-25   Peter Sewell          Fix Open Redirect issue in finishFlow
 * 1.8   2023-07-04   Peter Sewell          Support external SMS MFA
 * 1.7   2022-08-01   Ken McGuire			SFTG-2700
 * 1.6   2022-30-06   Kristian Vegerano   	SFTG-2785
 * 1.5   2022-20-05   Inderpal Dhanoa   	PENGAGE-2361
 * 1.4   2022-19-05   Kristian Vegerano   	SFTG-2677, SFTG-2678
 * 1.3   2022-17-05   Inderpal Dhanoa   	PENGAGE-2327
 * 1.2   2022-26-04   Inderpal Dhanoa   	PENGAGE-2309
 * 1.1   2022-23-03   Inderpal Dhanoa   	PENGAGE-2240
 * 1.0   2022-14-02   Kristian Vegerano   	Initial Version
 * 1.0   14/4/2025	  Vishal Gupta		   	MGROI-880 MFA redirect to email for Sanctioned Countries
 */
public with sharing class PortalTwoFactorController {
	public String CACHE_KEY_PREFIX ='MFA';
    private static final String TAG_MFA_LOGIN_FLOW = 'My.App Login Flow';

	public enum MFA_STATE {
		NOT_REGISTERED,
		AWAITING_REGO_CODE_PRIMARY,
		AWAITING_REGO_CODE_FALLBACK,
		AWAITING_VERIFICATION_CODE_PRIMARY,
		AWAITING_VERIFICATION_CODE_FALLBACK,
		VERIFIED
	}
	public MFA_STATE mfaState { get; set; }

	public Boolean renderEmailVerification { get; set; }
	public Boolean hasVerifiedMobileNumber { get; set; } // True if user has self verified mobile number either SFDC or External service
	public Boolean hasExternalVerification { get; set; } // True if user has self verified mobile number by External service
	public Boolean hasRequestedNewMobile { get; set; }
	public Boolean isResendRegistrationCode { get; set; } // True if user retried sending code on MFA registration page
	public Boolean isResendVerificationCode { get; set; } // True if user retried sending code on MFA verification page
	public Integer deviceHashCode { get; set; } // Hash of IP and Browser strings, used to check if user logging in from same IP & browser as last good MFA
	public String identifier { get; set; }
	
		public Boolean verifyCodeLimitExceeded { get; set; }
	
	public String verificationCodeErrorLogoutMsg { get; set; }

	
	public String verificationCode { get; set; }

	public String verificationCodeError { get; set; }
	public String verificationMethod { get; set; }
	
	public String selectedCountry { get; set; }
	public String countryCode { get; set; }
	public String extensionCountry { get; set; }
	public String mobilePhoneCountry { get; set; }
	public String mobileNumber { get; set; }
	public String mobileNumberFormatted { get; set; }
	public String mobileNumberFourDigit { get; set; }
	public String userEmail { get; set; }

	public Contact contactRecord { get; set; }

	//----------------
	public String formHeadertext1 { get; set; }
	public String formHeadertext2 { get; set; }
	public String formHeadertext3 { get; set; }
	public String formfootertext4 { get; set; }
	public String invalidCountryAlumnitext { get; set; }
	public String items { get; set; }
	public Integer emailVerficationCount { get; set; }
	public Integer failedAttempts { get; set; }
	public Integer failedAttemptsLimit { get; set; }
	public Boolean failedAttemptsLimitExceeded { get; set; }
	public Boolean emailSMSVerificationSent { get; set; }
	public Boolean showCountryMobileSection { get; set; }
	public Boolean licenseLimitExceeded { get; set; }
	public Boolean invalidCountry { get; set; }
	public Boolean invalidMobileNumberRange { get; set; }
	public Integer emailVerificationUsageCount { get; set; }
	public Boolean isSantionedCountry {get; set;}
	public String unverifiedMobileNumber {get; set;}
	public String unverifiedMobileCountryCode {get; set;}

	// MFA Carousel related attributes -- START
	public class Slide {
		public string heading { get; set; }
		public string subHeading { get; set; }
		public string helpText { get; set; }
		public Slide(String heading, String subHeading, String helpText) {
			this.heading = heading;
			this.subHeading = subHeading;
			this.helpText = helpText;
		}
	}
	public String slides { get; set; }
	// MFA Carousel related attributes -- END

	/* constructor */
	public PortalTwoFactorController() {
		try {
			//Initialize variables
			Integer firstItem = 0;
			//Integer secondItem = 1;
			Map<String, Object> resultsMap = new Map<String, Object>();
			resultsMap = ExperienceMFAServices.retrieveCurrentUserDetails();

			// default flag states
			mfaState = MFA_STATE.NOT_REGISTERED;
			hasRequestedNewMobile = false;
			isResendRegistrationCode = false;
			isResendVerificationCode = false;

			// determine if the user has registered mobile number
			hasVerifiedMobileNumber = (Boolean) resultsMap.get('HasVerified');
			hasExternalVerification = (Boolean) resultsMap.get('HasExternalVerification');
			if (hasVerifiedMobileNumber) {
				if (!hasExternalVerification) {
					mfaState = MFA_STATE.AWAITING_VERIFICATION_CODE_PRIMARY;
				} else {
					mfaState = MFA_STATE.AWAITING_VERIFICATION_CODE_FALLBACK;
				}
			}

			// get IP and browser hash to compare with last MFA login IP and browser hash
			deviceHashCode = (Integer) resultsMap.get('DeviceHashCode');

			// store current user mobile number
			if (hasVerifiedMobileNumber) {
				String countryMobileNumber = (String) resultsMap.get('MobileNumberCountry');
				String mobNumber = (String) resultsMap.get('MobileNumber');
				if (String.isNotBlank(mobNumber)) {
					List<String> compoundMobileNumber = mobNumber.split(' ');
					this.mobileNumberFourDigit = mobNumber.right(4);
					this.selectedCountry = countryMobileNumber + ' (' + compoundMobileNumber[firstItem] + ')';
					this.mobileNumberFormatted = mobNumber;
				}
			} else {
				//MGROI-880, on subsequent login, we need the unverified phone number so that we know that the Country is sanctioned
				this.unverifiedMobileNumber = (String) resultsMap.get('contactPhone');
				if(this.unverifiedMobileNumber != null) {
					List<String> compoundMobileNumber = this.unverifiedMobileNumber.split(' ');
					this.unverifiedMobileCountryCode = compoundMobileNumber[firstItem];
				}				
			}

			// retrieve email verification count
			this.renderEmailVerification = false;
			Decimal emailVerificationCount = (Decimal) resultsMap.get('EmailVerificationCount');
			this.emailVerificationUsageCount = Integer.valueOf(resultsMap.get('EmailVerificationCount'));
			if (
				emailVerificationCount < Integer.valueOf(Label.MaxMFAEmailVerification) &&
				(Boolean) resultsMap.get('HasVerified')
			) {
				this.renderEmailVerification = true;
			}
			// do not show send link to email on password reset
			if ((Boolean) resultsMap.get('HasRequestedPasswordReset')) {
				this.renderEmailVerification = false;
			}

			//MGROI-880, on subsequent login we need to set renderEmailVerification flag to false so that it wont send the 
			//email twice as we are already redirecting it to email verification for sacntioned country
			if(this.unverifiedMobileCountryCode != null && new CountriesSelector().isSanctionedBySFDC(this.unverifiedMobileCountryCode)) {
				this.renderEmailVerification = false;
			}

			// default verification method
			this.verificationMethod = 'SMS';

			// retrieve user's contact detail
			User currentUser= [
					SELECT ContactId, Email
					FROM User
					WHERE Id = :userInfo.getUserId()
				];
			if (currentUser.ContactId != null) {
				if (Schema.sObjectType.Contact.isAccessible()) {
					contactRecord = [
						SELECT Id, Birthdate
						FROM Contact
						WHERE Id = :currentUser.ContactId
					];
				} else {
					throw new SecurityException('Insufficient permissions to access Contact object.');
				}
			}

			// retrieve user's email
			this.userEmail = currentUser.Email;

			// retrieve invalid attempts for the last 15 mins
			this.failedAttemptsLimit = Integer.valueOf(Label.MFA_Verification_Limit);
			this.failedAttempts = 0;
			this.verifyCodeLimitExceeded = false;
			if (resultsMap.containsKey('FailedAttempts')) {
				this.failedAttempts = (Integer) resultsMap.get('FailedAttempts');
			}
			handleMaxAttempts(false);

			//----------------------------

			showCountryMobileSection = true;
			licenseLimitExceeded = false;
			invalidCountry = false;
			invalidMobileNumberRange = false;
			// mock country and invalid mobile number range errors
			String bypassParameter = ApexPages.currentPage().getParameters().get('ByPass');
			if (String.isNotBlank(bypassParameter)) {
				if (bypassParameter.equalsIgnoreCase('ic')) {
					// invalid country
					invalidCountry = true;
					hasRequestedNewMobile = true;
				} else if (bypassParameter.equalsIgnoreCase('imnr')) {
					// invalid mobile number range
					invalidMobileNumberRange = true;
					hasRequestedNewMobile = true;
				}
			}

			invalidCountryAlumnitext = '';
			if (hasVerifiedMobileNumber) {
				formHeadertext1 = '';
				formHeadertext2 = 'ENTER YOUR SECURITY CODE';
				formHeadertext3 =
					'A security code has been sent to your registered MFA mobile(XXXXXX' +
					mobileNumberFourDigit +
					').<br>Enter this code below to login to the Alumni Portal.';
			} else {
				formHeadertext1 = 'REGISTER YOUR MOBILE';
				formHeadertext2 = 'SECURE YOUR DATA.';
				formHeadertext3 = 'The Alumni Portal uses multi-factor authentication to keep your data safe. When you log in, we\'ll send a code to your mobile to make sure it\'s you logging in.<br><br>Register your mobile number below. ';
				formfootertext4 = 'We will use your mobile number for security verification and for the purposes set out in the <a href="https://www.monash.edu/__data/assets/pdf_file/0006/1595265/Alumni-Friends-and-Supporters-Data-Protection-and-Privacy-Collection-Statement.pdf" target="_blank"><u>Alumni Friends and Supporters Data Protection and Privacy Collection Statement</u></a>. <br/><br/>You can manage your communication preferences in the \'My Preferences\' section of the Alumni Portal under \'My Details\'.';
			}

			// Initialise the Carousel
			List<Slide> carousel = new List<Slide>();
			Slide s = new Slide(
				'Make sure you have service',
				'Check your device to ensure it has a signal and is able to send and receive messages.',
				'Make sure you have service'
			);
			carousel.add(s);
			s = new Slide(
				'Make sure you have entered your number correctly',
				'Check the number you provided on the MFA Registration page is correct and has the right number of digits for your country.',
				'Make sure you have entered your number correctly'
			);
			carousel.add(s);
			s = new Slide(
				'Make sure international roaming is turned off',
				'If international roaming is active on your device you may not receive the SMS with the verification code.',
				'Make sure international roaming is turned off'
			);
			carousel.add(s);
			s = new Slide(
				'Restart your phone',
				'If you still have not received your verification code, try turning your mobile off and restarting it.',
				'Restart your phone'
			);
			carousel.add(s);
			// TODO: temp Fix for Production
			// s = new Slide('Request another code', 'If you still have not received your verification code after these steps, try requesting another code.', 'Request another code');
			// INC00000367674: Urgnet fix to update this message Jan 24 2025
			s = new Slide(
				'Request another code',
				'If you still have not received your verification code after these steps. Go back to the previous page and try again.<br>',
				'Request another code'
			);
			carousel.add(s);
			String url = 'https://www.monash.edu/esolutions/contact';
			s = new Slide(
				'Submit a support enquiry',
				'If you still have not received your verification code after these steps, please submit a support request <a + href=' +
					url +
					'>Contact us | eSolutions</a>',
				'Submit a support enquiry'
			);
			carousel.add(s);
			slides = JSON.serialize(carousel);

		} catch (Exception ex) {
			Nebula.logger.error('PortalTwoFactorController ' + ex.getMessage(), ex);
			Nebula.logger.savelog();	
		}
	}

	public void changeCountry() {
		try {
			if (items != null) {
				setCountryAndMobilePhoneCountry();
			}
		} catch (Exception ex) {
			Nebula.logger.error('PortalTwoFactorController.changeCountry ' + ex.getMessage(), ex);
			Nebula.logger.savelog();			
			
		}
	}

	public void setCountryAndMobilePhoneCountry() {
		try { 
			if (items.contains('(+')) {
				countryCode = (items.split('\\+')[1].replace(')', '')).replace('(', '');
				mobilePhoneCountry = items.split(' ')[0];
			}
		} catch (Exception ex) {
			Nebula.logger.error('PortalTwoFactorController.setCountryAndMobilePhoneCountry ' + ex.getMessage(), ex);
			Nebula.logger.savelog();		
		}
	}

	/**
	 * @author      Kristian Vegerano
	 * @description Method that verifies user's entered verification code for 2FA SMS
	 * @param       None
	 * @return      None
	 * @revision    07/02/2022 - Kristian Vegerano - Created
	 *              23/04/2024 - Peter Sewell - check max failed attempts prior to verification
	 */
	public PageReference verifyVerificationCode() {
		PageReference redirectPage;
		try {
			handleMaxAttempts(true);

			Map<String, Object> resultsMap = verifyCode();

			redirectPage = processVerificationResults(resultsMap);
		} catch (Exception ex) {
			Nebula.logger.error('PortalTwoFactorController.verifyVerificationCode ' + ex.getMessage(), ex);
			Nebula.logger.savelog();
		}
		return redirectPage;
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support verifyVerificationCode in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private Map<String, Object> verifyCode() {
		Map<String, Object> resultsMap = new Map<String, Object>();
		if ((hasExternalVerification || isResendVerificationCode) && verificationMethod.equalsIgnoreCase('SMS')) {
			resultsMap = verifyWithExternalService();
		} else {
			resultsMap = ExperienceMFAServices.verifyVerificationCode(this.identifier, verificationCode, verificationMethod);
		}
		return resultsMap;
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support verifyVerificationCode in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private Map<String, Object> verifyWithExternalService() {
		Map<String, Object> resultsMap = new Map<String, Object>();
		Boolean isVerified = true;
		if (!Test.isRunningTest()) {
			isVerified = OneTimeTokenService.verifyOtp(
				ExperienceMFAServices.otpWrapper(this.verificationCode, this.identifier),
				OneTimeTokenService.Service.MFA
			);
		}
		if (isVerified) {
			resultsMap.put('Status', 'success');
			resultsMap.put('Message', '');
			User contextUser = [SELECT Id, MFA_Email_Verification_Count__c FROM User WHERE Id = :UserInfo.getUserId()];
			contextUser.Last_2FA_Login__c = System.NOW();
			contextUser.Last_2FA_Login_Device__c = deviceHashCode;
			contextUser.MFA_Email_Verification_Count__c = 0;
			update contextUser;
			ExperienceMFAServices.syncMobileDetails();
		} else {
			resultsMap.put('Status', 'error');
			resultsMap.put('Message', '* You have entered an incorrect verification code');
		}
		return resultsMap;
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support verifyVerificationCode in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private PageReference processVerificationResults(Map<String, Object> resultsMap) {
		PageReference redirectPage;
		if (resultsMap != null && (((String) resultsMap.get('Status')).equalsIgnoreCase('success'))) {
			this.mfaState = MFA_STATE.VERIFIED;
			this.verificationCodeError = '';
			redirectPage = this.finishFlow();
		} else {
			this.failedAttempts += 1;
			formHeadertext3 = 'We\'re sorry, that wasn\'t quite right. <br><br> Please check the code and try again. Alternatively you can request a new code by hitting the \'re-send code\' button below';
			this.verificationCodeError = (String) resultsMap.get('Message');
			handleMaxAttempts(false);
		}
		return redirectPage;
	}

	/**
	 * @author      Kristian Vegerano
	 * @description Default method called by the Partner_TwoFactor visualforce page called by the login flow
	 * @param       None
	 * @return      None
	 * @revision    17/03/2021 - Kristian Vegerano - Created
	 */
	public PageReference checkTwoFactor() {
		PageReference redirectPage;
		try {
			Boolean isBypassed = ExperienceMFAServices.determineByPassTwoFactor(UserInfo.getUserId());
			if (isBypassed) {
				redirectPage = this.finishFlow();
			} else if (isCountrySancationedForMyApp()) {
				sendSanctionedCountryMFA();
			} else {
				handleVerifiedMobileNumber();
			}
		} catch (Exception ex) {
			handleCheckTwoFactorException(ex);
		}
		return redirectPage;
	}

	/**
	 * @author      Vishal Gupta
	 * @description method to check sanctioned countries for my.app
	 * @revision    6/06/2025 - Vishal Gupta - Created
	 */
    @TestVisible
	private Boolean isCountrySancationedForMyApp() {
		String experienceURL = Network.getLoginUrl(Network.getNetworkId());
		Boolean myappUser = false;
		if(String.isNotBlank(experienceURL) && (experienceURL.containsIgnoreCase('admissions') || experienceURL.containsIgnoreCase('myapp'))){
			myappUser = true;
		}
		//if the user is logged into my.app and mobile number country is sanctioned, then we do not bypass the verification
		if(myappUser && this.unverifiedMobileCountryCode != null && new CountriesSelector().isSanctionedBySFDC(this.unverifiedMobileCountryCode)) {
			return true;
		}
		return false;
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support checkTwoFactor in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
    @TestVisible
	private void sendSanctionedCountryMFA() {
		this.verificationMethod = 'Email';
		this.hasVerifiedMobileNumber = true;
		sendVfEmailVerification();
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support checkTwoFactor in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
    @TestVisible
	private void handleVerifiedMobileNumber() {
		if (hasVerifiedMobileNumber && this.failedAttempts < 3) {
			if (getCacheValue(this.mobileNumberFormatted) == null && verificationMethod.equalsIgnoreCase('SMS')) {
				OTPGuard.validateOTPAttempt(this.mobileNumberFormatted, 900);
				sendVfSmsVerification();
			}
		}
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support checkTwoFactor in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	@TestVisible
	private void handleCheckTwoFactorException(Exception ex) {
		if (ex instanceof OTPGuard.OTPAttemptException || ex instanceof IP_RateLimitUtility.RateLimitException) {
			this.failedAttemptsLimitExceeded = true;
			this.verificationCodeErrorLogoutMsg = ex.getMessage();
		}
		Nebula.logger.error('PortalTwoFactorController.handleCheckTwoFactorException ' + ex.getMessage(), ex).addTag(TAG_MFA_LOGIN_FLOW);
		Nebula.logger.savelog();
	}

	/**
	 * @author      Kristian Vegerano
	 * @description Method that initiates the 2FA sms
	 * @param       None
	 * @return      None
	 * @revision    11/02/2022 - Kristian Vegerano - Created
	 */
	public void sendVfSmsVerification() {
		try {
			verificationCodeError = '';
			if (!Test.isRunningTest()) {
				if (!this.hasExternalVerification) {
					// Send code via native SFDC SMS service...identifier passed to paired verifyVerificationMethod()
					this.mfaState = MFA_STATE.AWAITING_VERIFICATION_CODE_PRIMARY;
					this.identifier = UserManagement.initVerificationMethod(Auth.VerificationMethod.SMS);
				} else {
					// ...otherwise send code via external service. e.g. Twilio. identifier passed to paired verifyOtp()
					this.mfaState = MFA_STATE.AWAITING_VERIFICATION_CODE_FALLBACK;
					OneTimeTokenService.OneTimeTokenWrapper resp = OneTimeTokenService.sendOtp(
						mobileNumberFormatted,
						'sms',
						ExperienceMFAServices.MFA_OTP_TEMPLATE_NAME,
						OneTimeTokenService.Service.MFA
					);
					this.identifier = resp.VerificationSid + ExperienceMFAServices.MFA_OTP_SEPARATOR + resp.ServiceSid;
				}
			}
		} catch (Exception ex) {
			if (ex.getMessage().contains('limit has been exceeded') || ex.getMessage().contains('Rate limit for phone number and service reached')|| (ex.getMessage().contains('Max send attempts reached'))) {
				licenseLimitExceeded = true;
			}
			Nebula.logger.error('PortalTwoFactorController.sendVfSmsVerification ' + ex.getMessage(), ex);
			Nebula.logger.savelog();		
		}
	}

	/**
	 * @author      Kristian Vegerano
	 * @description Method that initiates the 2FA email
	 * @param       None
	 * @return      None
	 * @revision    11/02/2022 - Kristian Vegerano - Created
	 */
	public void sendVfEmailVerification() {
		try {
			verificationCodeError = '';
			verificationMethod = 'Email';
			//clear cache as it Email verification
			clearCache();
			if (!Test.isRunningTest()) {
				this.identifier = UserManagement.initVerificationMethod(Auth.VerificationMethod.Email);
			}
			formHeadertext3 =
				'We have sent you a code on your registered email address (' +
				this.userEmail.left(3) +
				'XXXXXX' +
				this.userEmail.right(6) +
				').<br>Enter this code below to login to the Alumni Portal';
			if (this.emailVerificationUsageCount < (Integer.valueOf(Label.MaxMFAEmailVerification))) {
				Integer currentEmailUsageCount = this.emailVerificationUsageCount + 1;
				formHeadertext3 =
					formHeadertext3 +
					'<br> ' +
					currentEmailUsageCount +
					' out of ' +
					Integer.valueOf(Label.MaxMFAEmailVerification) +
					' attempts left for email verificationâ€¦';
			}
			renderEmailVerification = false;
		} catch (Exception ex) {	
			Nebula.logger.error('PortalTwoFactorController.sendVfEmailVerification ' + ex.getMessage(), ex);
			Nebula.logger.savelog();
		}
	}

	/**
	 * @author      Kristian Vegerano
	 * @description Method that initiates the 2FA email
	 * @param       None
	 * @return      None
	 * @revision    11/02/2022 - Kristian Vegerano - Created
	 */
	public void resetCountryMobileNumber() {
		try {
			//clear cache as it is a different mobile number
			clearCache();
			
			verificationCodeError = '';
			hasRequestedNewMobile = false;
			mobileNumber = '';
			mobileNumberFormatted = '';
			selectedCountry = '';

			//retrieve current user details
			User currentUser;
			for (User loopUser : [
				SELECT
					Id,
					Alias,
					CommunityNickname,
					Email,
					MFA_Email_Verification_Count__c,
					LanguageLocaleKey,
					LastName,
					MobilePhone,
					ProfileId,
					Username
				FROM User
				WHERE Id = :UserInfo.getUserId()
			]) {
				currentUser = loopUser;
			}

			//remove mobile number
			currentUser.MobilePhone = null;
			currentUser.Mobile_Phone_Country__c = null;
			update currentUser;

			invalidCountryAlumnitext = '';
			invalidCountry = false;

			formHeadertext3 = 'The Alumni Portal uses multi-factor authentication to keep your data safe. When you log in, we\'ll send a code to your mobile to make sure it\'s you logging in.<br><br>Register your mobile number below. ';

			showCountryMobileSection = true;
			emailSMSVerificationSent = false;
			mobilePhoneCountry = null;
			mobileNumber = null;
			mobileNumberFormatted = '';
			mobileNumberFourDigit = null;
			items = null;
			verificationCode = null;
			
			
		} catch (Exception ex) {
			Nebula.logger.error('PortalTwoFactorController.resetCountryMobileNumber ' + ex.getMessage(), ex);
			Nebula.logger.savelog();	
		}
	}

	/**
	 * @author      Kristian Vegerano
	 * @description Method that re-initiates the 2FA sms
	 * @param       None
	 * @return      None
	 * @revision    11/02/2022 - Kristian Vegerano - Created
	 */
	public void resendVerification() {
		try {
			verificationCodeError = '';
			//Rate limit applies only to SMS
			if (verificationMethod.equalsIgnoreCase('SMS')){
				OTPGuard.validateOTPAttempt(mobileNumberFormatted, 900);
			}
			if (!Test.isRunningTest()) {
				if (verificationMethod == 'Email') {
					this.identifier = UserManagement.initVerificationMethod(Auth.VerificationMethod.Email);
				} else if (verificationMethod == 'SMS') {
					// Resent codes always sent via external sms service. e.g. Twilio
					this.mfaState = MFA_STATE.AWAITING_VERIFICATION_CODE_FALLBACK;
					this.isResendVerificationCode = true;
					OneTimeTokenService.OneTimeTokenWrapper resp = OneTimeTokenService.sendOtp(
						mobileNumberFormatted,
						'sms',
						ExperienceMFAServices.MFA_OTP_TEMPLATE_NAME,
						OneTimeTokenService.Service.MFA
					);
					this.identifier = resp.VerificationSid + ExperienceMFAServices.MFA_OTP_SEPARATOR + resp.ServiceSid;
				}
			}
		} catch (Exception ex) {
			if (ex.getMessage().contains('limit has been exceeded') || ex.getMessage().contains('Rate limit for phone number and service reached') || (ex.getMessage().contains('Max send attempts reached'))) {
				licenseLimitExceeded = true; 
			}
			// if (ex.getMessage().contains('Maximum OTP attempts reached') ){
			if (ex instanceof OTPGuard.OTPAttemptException || ex instanceof IP_RateLimitUtility.RateLimitException) {
				// this.verificationCodeError = 'You have exceeded the maximum number of verification code requests. For security reasons, you cannot request for more verification codes. Please try again later.';
				this.verificationCodeError = ex.getMessage();
					this.failedAttemptsLimitExceeded = true;
			}
			Nebula.logger.error('PortalTwoFactorController.resendVerification ' + ex.getMessage(), ex).addTag(TAG_MFA_LOGIN_FLOW);
			Nebula.logger.savelog();			
		}
	}

	/**
	 * @author      Kristian Vegerano
	 * @description Method that starts the mobile number registration for MFA
	 *              Initial registration code always sent via SFDC
	 * @param       None
	 * @return      None
	 * @revision    14/02/2022 - Kristian Vegerano - Created
	 */
	public void registerVfMobileNumber() {
		try {
            if(this.hasVerifiedMobileNumber){
				this.verificationCodeError = 'A mobile number has already been registered for this account. Please verify with your existing mobile number';
				return;
			}
			if (handleSanctionedCountry()) {
				return;
			}
			if (handleUnsupportedCountry()) {
				return;
			}

			if (String.isNotBlank(this.countryCode) && String.isNotBlank(this.mobileNumber) && String.isNotBlank(this.mobilePhoneCountry)) {
				processMobileNumberRegistration();
			} else {
				this.verificationCodeError = 'Please enter the mobile number to be registered.';
			}
		} catch (Exception ex) {
			handleRegistrationException(ex);
		}
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support registerVFMobileNumber in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private Boolean handleSanctionedCountry() {
		if (new CountriesSelector().isSanctionedBySFDC(this.countryCode)) {
			this.isSantionedCountry = true;
			this.verificationMethod = 'Email';
			this.hasVerifiedMobileNumber = true;
			this.mobileNumberFourDigit = this.mobileNumber.right(4);
			sendVfEmailVerification();
			syncCountryMobileNumber();
			return true;
		}
		return false;
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support registerVFMobileNumber in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private Boolean handleUnsupportedCountry() {
		if (new CountriesSelector().isSfdcSmsUnsupported(this.countryCode)) {
			resendVfRegisterMobileNumber();
			return true;
		}
		return false;
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support registerVFMobileNumber in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private void processMobileNumberRegistration() {
		Integer attempts = 0;
		this.mfaState = MFA_STATE.AWAITING_REGO_CODE_PRIMARY;
		this.hasRequestedNewMobile = true;
		this.isResendRegistrationCode = false;
		this.selectedCountry = this.mobilePhoneCountry + ' (' + this.countryCode + ')';

		if (getCacheValue(this.mobileNumber) == null && verificationMethod.equalsIgnoreCase('SMS')) {
			attempts = OTPGuard.validateOTPAttempt(this.mobileNumber, 900);
		}

		if (!Test.isRunningTest() && attempts == 1) {
			this.identifier = ExperienceMFAServices.systemRegisterMobileNumber(
				this.countryCode,
				this.mobileNumber,
				this.mobilePhoneCountry
			);
		}

		this.mobileNumberFourDigit = this.mobileNumber.right(4);
		formHeadertext3 =
			'A security code has been sent to your registered MFA mobile(XXXXXX' +
			mobileNumberFourDigit +
			').<br>Enter this code below to login to the Alumni Portal.';

		emailSMSVerificationSent = true;
		showCountryMobileSection = false;

		handleInvalidCountryOrNumber();
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support registerVFMobileNumber in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private void handleInvalidCountryOrNumber() {
		if (String.isNotBlank(this.identifier)) {
			if (this.identifier.containsIgnoreCase('provide a valid country code')) {
				invalidCountry = true;
				invalidCountryAlumnitext = 'Your mobile number is not currently supported. Please visit FAQs or contact monashalumni@monash.edu if you need any assistance or information.';
			} else if (this.identifier.containsIgnoreCase('provide a valid phone number')) {
				invalidMobileNumberRange = true;
				invalidCountryAlumnitext = 'Your mobile number is not currently supported. Please visit FAQs or contact monashalumni@monash.edu if you need any assistance or information.';
			}
		}
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support registerVFMobileNumber in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private void handleRegistrationException(Exception ex) {
		if (ex instanceof OTPGuard.OTPAttemptException || ex instanceof IP_RateLimitUtility.RateLimitException) {
			this.failedAttemptsLimitExceeded = true;
			this.verificationCodeError = '';
			this.verificationCodeErrorLogoutMsg = ex.getMessage();
		}
		if (ex.getMessage().contains('limit has been exceeded') || ex.getMessage().contains('Rate limit for phone number and service reached') || ex.getMessage().contains('Max send attempts reached')) {
			licenseLimitExceeded = true;
		}
		Nebula.logger.error('PortalTwoFactorController.registerVfMobileNumber: ' + ex.getMessage(), ex).addTag(TAG_MFA_LOGIN_FLOW);
		Nebula.logger.saveLog();
	}

	/**
	 * @author      Kristian Vegerano
	 * @description Method that re-initiate mobile number registration for MFA
	 *              Resending registration code always sent via fallback service
	 * @param       None
	 * @return      None
	 * @revision    14/02/2022 - Kristian Vegerano - Created
	 */
	public void resendVfRegisterMobileNumber() {
		try {
			//Rate limit applies only to SMS
			
				this.mfaState = MFA_STATE.AWAITING_REGO_CODE_FALLBACK;
				this.isResendRegistrationCode = true;
				this.hasRequestedNewMobile = true;
				this.selectedCountry = this.mobilePhoneCountry + ' (' + this.countryCode + ')';
				if (verificationMethod.equalsIgnoreCase('SMS')){
					OTPGuard.validateOTPAttempt(this.mobileNumber, 900);
				}
				if (!Test.isRunningTest()) {
					this.identifier = ExperienceMFAServices.systemRegisterMobileNumberFallback(
						this.countryCode,
						this.mobileNumber,
						this.mobilePhoneCountry
					);
		
			}
		} catch (Exception ex) {
			// if (ex.getMessage().contains('Maximum OTP attempts reached')) {
			if (ex instanceof OTPGuard.OTPAttemptException || ex instanceof IP_RateLimitUtility.RateLimitException) {
				// this.verificationCodeError = 'You have exceeded the maximum number of verification code requests. For security reasons, you cannot request for more verification codes. Please try again later.';
				this.verificationCodeError = ex.getMessage();
				this.failedAttemptsLimitExceeded = true;
			}
			Nebula.logger.error('PortalTwoFactorController.resendVfRegisterMobileNumber: ' + ex.getMessage(), ex).addTag(TAG_MFA_LOGIN_FLOW);
			Nebula.logger.saveLog();
       }
	}

	
	/**
	 * @author      Kristian Vegerano
	 * @description Method that verifies the user's input, if successful tag the number as verified
	 * @param       None
	 * @return      None
	 * @revision    14/02/2022 - Kristian Vegerano - Created
	 */
	@TestVisible
	private String exceptionText { get; set; }
	public PageReference confirmMobileNumberRegistration() {
		PageReference redirectPage;
		try {
			exceptionText = null;
			handleExceptionText();
			if (String.isBlank(exceptionText)) {
				redirectPage = handleSuccessfulVerification();
			} else {
				handleFailedVerification();
			}
		} catch (Exception ex) {
			handleVerificationException(ex);
		}
		return redirectPage;
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support confirmMobileNumberRegistration in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private void handleExceptionText() {
		if (!Test.isRunningTest()) {
			if (!isResendRegistrationCode) {
				exceptionText = System.UserManagement.verifyRegisterVerificationMethod(
					this.verificationCode,
					Auth.VerificationMethod.SMS
				);
			} else {
				Boolean isVerified = OneTimeTokenService.verifyOtp(
					ExperienceMFAServices.otpWrapper(this.verificationCode, this.identifier),
					OneTimeTokenService.Service.MFA
				);
				exceptionText = isVerified ? '' : 'Could not verify code';
			}
		}
	}

	/**
	 * @author      Arnie Ug
	 * @description method to support confirmMobileNumberRegistration in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private PageReference handleSuccessfulVerification() {
		this.mfaState = MFA_STATE.VERIFIED;
		ExperienceMFAServices.syncMobileDetails();
		if (isResendRegistrationCode) {
			ExperienceMFAServices.setVerifiedByExternalService();
		}
		this.verificationCodeError = '';
		return this.finishFlow();
	}
	
	/**
	 * @author      Arnie Ug
	 * @description method to support confirmMobileNumberRegistration in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private void handleFailedVerification() {
		formHeadertext3 = 'We\'re sorry, that wasn\'t quite right. <br><br> Please check the code and try again. Alternatively you can request a new code by hitting the \'re-send code\' button below';
		this.verificationCodeError = '* You have entered an incorrect verification code';
	}
	
	/**
	 * @author      Arnie Ug
	 * @description method to support confirmMobileNumberRegistration in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
	private void handleVerificationException(Exception ex) {
		if (ex.getMessage().contains('limit has been exceeded') || ex.getMessage().contains('Rate limit for phone number and service reached') || ex.getMessage().contains('Max send attempts reached') || ex.getMessage().contains('Max check attempts reached')) {
			licenseLimitExceeded = true;
		}
		Nebula.logger.error('PortalTwoFactorController.handleVerificationException: ' + ex.getMessage(), ex).addTag(TAG_MFA_LOGIN_FLOW);
		Nebula.logger.saveLog();
	}
	
	/**
	 * @author      Kristian Vegerano
	 * @description Method that generates the url where the user is meant to land after finishing the login flow
	 * @param       None
	 * @return      PageReference - user's landing page
	 * @revision    07/02/2022 - Kristian Vegerano - Created
	 */
	private PageReference finishFlow() {
		//Initialize variables
		PageReference redirectPage;
		Boolean blockRedirect = true;

		try {
			// delete other user session prior to logging in
			CommonUtilities.terminateUserSession(UserInfo.getUserId());

			// Update the lastLogin Date on the COntact record
			CommonUtilities.updateLastPortalLoginDate(UserInfo.getUserId(), String.valueOf(Label.Ascend_Portal_Name));

			// only allow redirects relative url to prevent potentially malicious attempts to redirect to external url
			// note any retURL NOT starting with a / is converted by SF to an absolute URL starting with http
			String retUrl = ApexPages.currentPage().getParameters().get('retURL');
			if (retUrl == null || !retUrl.startsWithIgnoreCase('http')) {
				blockRedirect = false;
			}

			if (!Test.isRunningTest()) {
				redirectPage = blockRedirect
					? Auth.SessionManagement.finishLoginFlow('/s') // redirect instead to home page
					: Auth.SessionManagement.finishLoginFlow(retUrl); // redirect to value of retURL or home if retURL is null
			}
		} catch (Exception ex) {
			Nebula.logger.error('PortalTwoFactorController.finishFlow: ' + ex.getMessage(), ex);
			Nebula.logger.saveLog();			
		}
		return redirectPage;
	}

	public List<Selectoption> getItemsList() {
		List<SelectOption> options = new List<SelectOption>();
		try {
			// Load Country details
			options.add(new SelectOption('', '-- Please Select --'));
			for (Country_Attribute__c country : new CountriesSelector().selectAllCountries()) {
				if(!country.Blocked__c || country.Sanctioned_by_Salesforce__c) {
					options.add(
						new SelectOption(
							country.ShortName__c + ' (+' + country.NumericPhoneCode__c + ')',
							country.shortName__c + ' (+' + country.NumericPhoneCode__c + ')'
						)
					);
				}
			}
		} catch (Exception ex) {
			Nebula.logger.error('PortalTwoFactorController.getItemsList: ' + ex.getMessage(), ex);
			Nebula.logger.saveLog();		
		}
		return options;
	}
	public class MaxFailedAttemptException extends Exception {
	}
	/**
	 * @author      SMendu
	 * @description Mediator method to clear cache after checking the parameter
	 * @return      None
	 * @revision    26/03/2025- Created
	 */
	private  void clearCache()
	{
		this.failedAttemptsLimitExceeded = false;
		if(String.isNotBlank(this.mobileNumber)) {
			clearCacheValue(this.mobileNumber);
		}
		if(String.isNotBlank(this.mobileNumberFormatted)){ 
		    clearCacheValue(this.mobileNumberFormatted);
		}
	}
	/**
	 * @author      SMendu
	 * @description Clearing key from the Session Cache
	 * @param       key
	 * @return      None
	 * @revision    26/03/2025- Created
	 */
    public  void clearCacheValue(String key) {
        try {
            Cache.SessionPartition partition = Cache.Session.getPartition('MONASH');
			String cleanedKey = key.replaceAll('[^A-Za-z0-9]', '');
            if (partition != null &&  String.isNotBlank(cleanedKey) ) {
                partition.remove(cleanedKey);
            }
        } catch (Exception e) {
			Nebula.logger.error('PortalTwoFactorController.clearCacheValue: ' + e.getMessage(), e);
			Nebula.logger.saveLog();	
        }
    }

	/**
	 * @author      SMendu
	 * @description Getting key from the Session Cache
	 * @param       key
	 * @return      None
	 * @revision    26/03/2025- Created
	 */
    public  Object getCacheValue(String key) {
		Object cacheObj = null;
        try {
				String cleanedKey = key.replaceAll('[^A-Za-z0-9]', '');
				
				Cache.SessionPartition partition = Cache.Session.getPartition('MONASH');
				if (partition != null) {
					cacheObj = partition.get(cleanedKey);
				}
        } catch (Exception e) {
			Nebula.logger.error('PortalTwoFactorController.getCacheValue: ' + e.getMessage(), e);
			Nebula.logger.saveLog();
        }
		return cacheObj;
    }

	/**
	 * @author      Vishal Gupta
	 * @description Method that sync the phone number to user and contact records for sanctioned country
	 * @param       None
	 * @return      None
	 */
	public void syncCountryMobileNumber() {
		try {
			// Check CRUD permissions for the User object
			if (Schema.sObjectType.User.isAccessible()) {
				// Retrieve current user details
				User currentUser = [
					SELECT
						ContactId
					FROM User
					WHERE Id = :UserInfo.getUserId()
				];
				// Sync phone number
				ExperienceMFAServices.syncUnverifiedMobileDetails(currentUser.ContactId, this.countryCode + ' ' + this.mobileNumber);
			} else {
				throw new SecurityException('Insufficient permissions to access User object.');
			}
		} catch (Exception ex) {
			Nebula.Logger.error('PortalTwoFactorController.syncCountryMobileNumber ' + ex.getMessage(), ex);
			Nebula.Logger.saveLog();
		}
	}

	private void handleMaxAttempts(Boolean throwException) {
		if (this.failedAttempts >= 3) {
			this.verifyCodeLimitExceeded = true;
			this.verificationCodeErrorLogoutMsg = 'We have temporarily blocked your account for providing incorrect verification code multiple times. Please try again after 15 minutes.';
			if(throwException) {
				throw new MaxFailedAttemptException('Temporarily blocked account for providing incorrect verification code multiple times');
			}
		}
	}
}