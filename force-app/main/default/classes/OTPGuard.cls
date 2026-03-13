/**
 * OTP Guard serves as a proxy service for OTP attempts. This service reads configs from metadata and apply otp attemps limits, IP rate limit
 * and throws exception if the limit is reached. Stores exception in Nebula
 *
 * @author Girish P
 *
 * @since Mar/2025
 */
public with sharing class OTPGuard {
  public virtual class OTPAttemptException extends Exception {
  }
  /**
   * Admissions_Settings__mdt - My_App_OTP_Attempts
   */
  public static final String CM_CONFIG_KEY = 'My_App_OTP_Attempts';
  private static final String REG_PREFIX = 'REG_';
  private static final String VER_PREFIX = 'VER_';
  // Custom metadata name for Fetching API Rate limit from IP_Rate_Limit__mdt
  private static final String PORTAL_OTP_KEY = 'My.App OTP Attempts';
  private static final String RATE_LIMIT_EXCEEDED_MSG = 'RATE_LIMIT_EXCEEDED for Phone: ({0}),';
  private static final String TAG_OTP = 'MY.App OTP';
  private static final String TAG_MFA = 'MY.App Re-Register MFA';
  /**
   * @description Template for logging maximum OTP attempts reached.
   */
  private static final String MAX_OTP_LOG_MESSAGE = 'Maximum OTP attempts reached for Phone: ({0}), Attempt: ({1}),';
  /**
   * @description Template for logging OTP attempts.
   */
  private static final String OTP_ATTEMPTED_LOG = 'OTP attempted for Phone: ({0}) Attempt: ({1})';
  /**
   * @description Template for logging mobile MFA registration.
   */
  private static final String MFA_REGISTER_LOG = 'Mobile MFA Registration attempted for Phone: {0}, CountryCode: {1}, from Country: {2}';
  /**
   * @description Template for logging mobile MFA verification.
   */
  private static final String MFA_VERIFY_LOG = 'Mobile MFA verify attempted for identifier: {0}, verificationCode: {1}';
  private static IP_RateLimitUtility rateLimit = OTP_CONFIG.ipRateLimitKey.equalsIgnoreCase('perIP')
    ? new IP_RateLimitUtility(PORTAL_OTP_KEY)
    : new IP_RateLimitUtility(PORTAL_OTP_KEY, UserInfo.getUserId());
  private static Integer attempts = 0;
  private static Integer maxAttempts;
  @TestVisible
  /**
   * @description OTP_CONFIG is a wrapper class to hold OTP configs read from custom metadata Admissions_Settings__mdt - My_App_OTP_Attempts.
   * Configs__c is a JSON string that contains the configuration settings for OTP attempts and rate limiting. OTPWrapper is used to deserialize the JSON string into a usable object.
   */
  private static OTPConfigWrapper OTP_CONFIG {
    get {
      if (String.isBlank(OTP_SETTINGS.Configs__c)) {
        throw new OTPAttemptException('Missing OTP Configs__c in Admissions_Settings__mdt for OTP rate limiting.');
      }
      return (OTPConfigWrapper) JSON.deserialize(OTP_SETTINGS.Configs__c, OTPConfigWrapper.class);
    }
    set {
      OTP_CONFIG = value;
    }
  }
  @TestVisible
  /**
   * @description OTP_SETTINGS is a wrapper class to hold OTP settings read from custom metadata Admissions_Settings__mdt - My_App_OTP_Attempts.
   * Messages__c is a JSON string that contains the messages for OTP attempts and rate limiting. <br>OTPWrapper is used to deserialize the JSON string into a usable object.
   * TestVisible is used to make this variable visible in test classes and for debugging purposes.
   */
  public static Admissions_Settings__mdt OTP_SETTINGS {
    get {
      return OTP_SETTINGS != null
        ? OTP_SETTINGS
        : [
            SELECT id, Configs__c, Messages__c
            FROM Admissions_Settings__mdt
            WHERE DeveloperName = :CM_CONFIG_KEY
          ];
    }
    set {
      OTP_SETTINGS = value;
    }
  }
  /**
   * Adds context information - Username and IP Address to the log message. Anyting additional required for logging should be added here.<br>
   * This method adds user information and IP address to the log message.
   * @param message - The message to be logged.
   * @return        `string` The formatted log message with context information.
   * @description  This method adds user information and IP address to the log message.
   */
  private static string getContextMessage(String message) {
    return message +=
      ' by userName: ' +
      UserInfo.getUserName() +
      ' from IP:' +
      rateLimit.clientIpAddress() +
      '. rateLimitKey:' +
      OTP_CONFIG.ipRateLimitKey;
  }
  /**
   * Logs the message with user metadata.
   * @param logMessage - The log message to be logged.
   * @return String - The formatted log message.
   */
  private static string logWithUserMeta(Nebula.LogMessage logMessage) {
    return getContextMessage(logMessage.getMessage());
  }
  /**
   * @description Validates the OTP attempt count and checks if the rate limit is exceeded<br>
   * This method increments the attempt count and checks if it exceeds the maximum allowed attempts.<br>
   * If the limit is exceeded, it throws an OTPAttemptException.<br>
   * It also logs the attempt count and the user information.<br>
   * The method uses the OTP_CONFIG to get the maximum allowed attempts and the time-to-live (TTL) for the cache.<br>
   * It also checks if the IP rate limit is exceeded and throws an exception if it is.<br>
   * The method returns the updated attempt count.<br>
   * @param key - Unique key for tracking login attempts. Source method can pass the key, Ex- Phone in current OTP scenarios
   * @param ttlSeconds - Expiration time for cache storage.
   * @return Integer - Updated attempt count.
   * @throws OTPException - If the maximum attempts are exceeded or if the rate limit is exceeded.
   * IP_RateLimitUtility.RateLimitException - If the rate limit is exceeded.
   * @example
   * // Example usage of validateOTPAttempt method
   * String key = '+ UserInfo.getUserId() + '+' + phone;
   * Integer attempts = 0;
   *
   * try {
   *   attempts = OTPGuard.validateOTPAttempt(key, 300);
   *  // Proceed with OTP verification
   * } catch (OTPGuard.OTPAttemptException e) {
   *  // Handle OTP attempt limit exceeded
   *   System.debug('OTP attempt limit exceeded: ' + e.getMessage());
   * } catch (IP_RateLimitUtility.RateLimitException e) {
   *  // Handle IP rate limit exceeded
   *  System.debug('IP rate limit exceeded: ' + e.getMessage());
   * } catch (Exception e) {
   *  // Handle other exceptions
   *  System.debug('An error occurred: ' + e.getMessage());
   * }
   *
   */
  public static Integer validateOTPAttempt(String key, Integer ttlSeconds) {
    String cleanedKey = cleanKey(key);
    String currentValue = (String) SessionUtils.getCacheValue(cleanedKey);
    // for first attempt in each session it will be null, hence counter starts with 1
    attempts = String.isBlank(currentValue) ? 0 : Integer.valueOf(currentValue);
    Nebula.logger.info(
        logWithUserMeta(new Nebula.LogMessage(OTP_ATTEMPTED_LOG, cleanedKey, String.valueOf(attempts + 1))),
        UserInfo.getUserId()
      )
      .addTag(TAG_OTP);
    Nebula.logger.savelog();
    // Check if the rate limit is exceeded. Log the warning and throw an exception if it is.
    if (OTP_CONFIG.ipRateLimitEnabled == true && exceedsRateLimit(cleanedKey)) {
      Nebula.logger.warn(
          logWithUserMeta(new Nebula.LogMessage(RATE_LIMIT_EXCEEDED_MSG, cleanedKey)),
          UserInfo.getUserId()
        )
        .addTag(TAG_OTP);
      Nebula.logger.savelog();
      throw new IP_RateLimitUtility.RateLimitException('', OTP_CONFIG.ipRateLimitMessage);
    }
    // Check if the number of attempts exceeds the limit.
    if (attempts >= OTP_CONFIG.otpAttemptAllowed) {
      Nebula.logger.warn(
          logWithUserMeta(new Nebula.LogMessage(MAX_OTP_LOG_MESSAGE, cleanedKey, String.valueOf(attempts + 1))),
          UserInfo.getUserId()
        )
        .addTag(TAG_OTP);
      Nebula.logger.savelog();
      throw new OTPAttemptException(OTP_CONFIG.otpAttemptMessage);
    }
    attempts++;
    SessionUtils.setCacheValue(
      cleanedKey,
      String.valueOf(attempts),
      ttlSeconds != null ? ttlSeconds : OTP_CONFIG.otpttlInSeconds
    );
    return attempts;
  }
  /**
   *  * Proxy method for mobile number registration. 
   * This method wraps all registration methods in ExperienceMFAServices including Fallback and OOTB SFDC. 
   * It checks the OTP attempt limit before invoking the service.
   *
   * @param countryCode        
   * @param phoneNumber        
   * @param mobilePhoneCountry 
   * @param registerMethod Type of registration method to use. <br>
   *                      Possible values: FALLBACK_REGISTER, SFDC_REGISTER, SFDC_INIT
   * @return                   `String`
   * @exception                
   */
  @AuraEnabled
  public static String registerMFA(
    String countryCode,
    String phoneNumber,
    String mobilePhoneCountry,
    String registerMethod
  ) {
    String cleanedKey = cleanKey(REG_PREFIX + phoneNumber);
    Nebula.logger.info(
        logWithUserMeta(new Nebula.LogMessage(MFA_REGISTER_LOG, cleanedKey, countryCode, mobilePhoneCountry)),
        UserInfo.getUserId()
      )
      .addTag(TAG_MFA);
    validateOTPAttempt(cleanedKey, OTP_CONFIG.otpttlInSeconds);
    Nebula.logger.savelog();
    switch on registerMethod.toUpperCase() {
      when 'FALLBACK_REGISTER' {
        return ExperienceMFAServices.systemRegisterMobileNumberFallback(countryCode, phoneNumber, mobilePhoneCountry);
      }
      when 'SFDC_REGISTER' {
        return ExperienceMFAServices.systemRegisterMobileNumber(countryCode, phoneNumber, mobilePhoneCountry);
      }
      when 'SFDC_INIT' {
        return String.valueOf(ExperienceMFAServices.sendSmsVerification());
      }
      when else {
        throw new OTPAttemptException('Invalid register method provided.');
      }
    }
  }
  /**
   * 
   * Proxy method for mobile number verification.
   * This method wraps all verification methods in ExperienceMFAServices including Fallback and OOTB SFDC.
   * It checks the OTP attempt limit before invoking the service.
   * @param identifier       
   * @param verificationCode 
   * @param startUrl         
   * @param verifyType Possible values: FALLBACK_VERIFY, SFDC_VERIFY, SFDC_CHALLENGE
   *                     FALLBACK_VERIFY - Fallback verification method<br>
   *                     SFDC_VERIFY - OOTB SFDC verification method<br>
   *                     SFDC_CHALLENGE - OOTB SFDC challenge method<br>
   * @return                 `Object`
   * @exception              
   */
  @AuraEnabled
  public static Object verifyMFA(String identifier, String verificationCode, String startUrl, String verifyType) {
    String cleanedKey = cleanKey(VER_PREFIX + UserInfo.getUserName());
    validateOTPAttempt(cleanedKey, OTP_CONFIG.otpttlInSeconds);

    Nebula.logger.info(
        logWithUserMeta(new Nebula.LogMessage(MFA_VERIFY_LOG, identifier, verificationCode)),
        UserInfo.getUserId()
      )
      .addTag(TAG_MFA);
    Nebula.logger.savelog();

    switch on verifyType.toUpperCase() {
      when 'FALLBACK_VERIFY' {
        return ExperienceMFAServices.verifyMobileNumberFallback(identifier, verificationCode, startUrl);
      }
      when 'SFDC_VERIFY' {
        return ExperienceMFAServices.verifyMobileNumber(identifier, verificationCode, startUrl);
      }
      when 'SFDC_CHALLENGE' {
        // startURL is the verification Method used in the challenge
        return ExperienceMFAServices.verifyVerificationCode(identifier, verificationCode, startUrl);
      }
      when else {
        throw new OTPAttemptException('Invalid verifyType provided.');
      }
    }
  }
  /**
   * Checks if IP rate limit is exceeded for a given key.
   * IP_RateLimitUtility 1 param constructor is used to check the rate limit for IP
     A 'qualifier' if passed to the constructor(2 params) is post-fixed to the formName to create a qualified formKey
    e.g. a qualifier of bot@xyz.edu becomes my.app::192.168.1.1::bot@xyz.edu
   * @param key   `String` The key to check against the rate limit. Calling class can pass the key, Ex- Phone in current OTP scenarios
   * @return    `Boolean` If IP rate limit is exceeded.
   * @see IP_RateLimitUtility
   */
  public static Boolean exceedsRateLimit(String key) {
    // default key is UserId, which will apply limit per user basis irrespective of Phone number or IP
    key = OTP_CONFIG.ipRateLimitKey.equalsIgnoreCase('perUserPhone')
      ? key + UserInfo.getUserId()
      : UserInfo.getUserId();
    // Portal OTP constructor is used to check the rate limit for IP<br>
    // A 'qualifier' if passed to the constructor is post-fixed to the formName to create a qualified formKey<br>
    // e.g. a qualifier of bot@xyz.edu becomes my.app::192.168.1.1::bot@xyz.edu
    rateLimit = OTP_CONFIG.ipRateLimitKey.equalsIgnoreCase('perIP')
      ? new IP_RateLimitUtility(PORTAL_OTP_KEY)
      : new IP_RateLimitUtility(PORTAL_OTP_KEY, key);
    return rateLimit.exceedsRateLimit();
  }

  /**
   * Cleans the key by removing non-alphanumeric characters. Cache keys should be alphanumeric.
   *
   * @param key   `String`
   * @return    `String`
   */
  public static String cleanKey(String key) {
    key=key.replaceAll('[^A-Za-z0-9]', '');
    // Remove non-alphanumeric characters and limit the length to 50 characters
    // This is to ensure that the cache key is alphanumeric and does not exceed the maximum length
    return key.length()>50?key.substring(0,50):key;
  }
  /**
   * Wrapper class for OTP configuration settings.<br>
   * This class is used to deserialize the JSON configuration from metadata.<br>
   * It contains properties for maximum attempts, time-to-live, and messages. Reads Admissions_Settings__mdt - My_App_OTP_Attempts
   */
  public class OTPConfigWrapper {
    /**
     * attemptAllowed - Maximum number of OTP attempts allowed.
     */
    public Integer otpAttemptAllowed { get; set; }
    /** Time-to-live for the OTP attempts in seconds.  */
    public Integer otpttlInSeconds { get; set; }
    /** Message to be shown when OTP attempts are exceeded */
    public String otpMessage { get; set; }
    /**
     * @description Messages to be shown when OTP attempts are exceeded.
     */
    public String otpAttemptMessage { get; set; }
    /*** Flag to enable/disable IP rate limiting*/
    public Boolean ipRateLimitEnabled { get; set; }
    /**
     * Message to be shown when IP rate limit is exceeded
     */
    public String ipRateLimitMessage { get; set; }
    /**
     * @description
     * 1. perUserPhone - OTP attempts are limited per user and phone number. <br>
     * 2. perIP - OTP attempts are limited per user and IP address. <br>
     * 3. perUser - OTP attempts are limited per user.  <br>
     */
    public String ipRateLimitKey { get; set; }
  }
}