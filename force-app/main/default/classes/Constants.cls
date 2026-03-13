public with sharing class Constants {
  public static final String CAMPUS_LOCATION_AUS = 'Australia';
  public static final String RESIDENCY_STATUS_LOCATION_AUS_DOM = 'DOM-AUS';
  
  /**PRODUCT2 */
  public static final String PRODUCT2_OFFER = 'Offer';

  public static final String BUNDLE_PRODUCT_FAMILY = 'Bundle';
  public static final string[] COURSE_PRODUCTS = new string[] {'English Course', 'Course', 'Diploma'};
  public static final string[] BUNDLE_PRODUCT_EXTERNAL_IDS = new string[] {'BUNENG','BUNIAP','BUNCOL','BUNFOU','BUNDIP','BUNUNI','BUNMEC'};

  /**COURSE_FEE__C */
  public static final String COURSEFEE_SYNCINPROGRESS = 'SYNC IN PROGRESS...';
  public static final String COURSEFEE_SYNCCOMPLETED = 'SYNC COMPLETED!';
  private Constants() {}

  /**SBQQ__QUOTE__C */
  public static final String QUOTE_PRICE_CALCULATED = 'Pricing Completed';
  public static final String QUOTE_STATUS_ACCEPTED = 'Accepted';
  public static final String QUOTE_STATUS_IN_REVIEW = 'In Review';
  public static final String QUOTE_STATUS_PUBLISHED = 'Published';
  public static final String QUOTE_STATUS_SIGNED = 'Signed';
  public static final String QUOTE_STATUS_EXPIRED = 'Expired';
  public static final String QUOTE_STATUS_DEFERRED = 'Deferred';
  public static final String QUOTE_STATUS_CANCELLED = 'Cancelled';
  public static final String QUOTE_STATUS_EXPIRED_REGEN = 'Expired and regenerated';
  public static final String QUOTE_SUBSTATUS_OFFER_CONTRACT_CREATED = 'Contract Created';
  public static final String QUOTE_SUBSTATUS_OFFER_DOCUMENT_ERROR  = 'Conga Error';
  public static final String QUOTE_SUBSTATUS_OFFER_SIGNING_ERROR  = 'DocuSign Error';
  public static final String QUOTE_SUBSTATUS_OFFER_PENDING_SIGNATURE = 'Pending Signature in DocuSign';
  public static final String QUOTE_SUBSTATUS_OFFER_SIGNED_RECIPIENT1 = 'Signed recipient 1';
  public static final String QUOTE_SUBSTATUS_OFFER_SIGNED_RECIPIENT2 = 'Signed recipient 2'; 
  public static final String QUOTE_SUBSTATUS_OFFER_SIGNED_TO_BE_LOCKED = 'Signed to be locked';
  public static final String QUOTE_SUBSTATUS_OFFER_SIGNED_AND_LOCKED = 'Signed and locked';
  public static final String QUOTE_SUBSTATUS_OFFER_TECHNICAL_ERROR = 'APEX Doc. Gen/Save Error';
  public static final String QUOTE_SUBSTATUS_PREVIEW_REQUESTED ='Preview Requested';
  public static final String QUOTE_SUBSTATUS_CANEDIT_OSHC = 'Preview Released';
  public static final String QUOTE_SUBSTATUS_QAPREVIEW = 'Preview in QA';
  public static final String QUOTE_SUBSTATUS_OFFER_CREATION_ERROR = 'Offer creation/update error';
  public static final String OPPTY_STATUS_SPEC_REVIEW = 'Specialist Review';
  public static final String OPPTY_STATUS_SIGNED = 'Signed';
  public static final String ACP_STATUS_ACCEPTED = 'ACCEPTED';

  public static final String [] QUOTE_OFFER_SUBSTATUSES_READONLY = new String[] { QUOTE_SUBSTATUS_OFFER_CONTRACT_CREATED, QUOTE_SUBSTATUS_OFFER_DOCUMENT_ERROR,
    QUOTE_SUBSTATUS_OFFER_SIGNING_ERROR, QUOTE_SUBSTATUS_OFFER_PENDING_SIGNATURE, QUOTE_SUBSTATUS_OFFER_SIGNED_RECIPIENT1, 
    QUOTE_SUBSTATUS_OFFER_SIGNED_RECIPIENT2, QUOTE_SUBSTATUS_OFFER_TECHNICAL_ERROR };

  public static final String DEFAULT_PRODUCT_BUNHEALTH  = 'BUNHEALTH';
  public static final String IS_SHADOW_PHASE = 'IN_SHADOW_PHASE';
  /**QUEUE**/
  public static final String BUSINESS_OFFER_QUEUE = 'Offer_Business_Queue';
  public static final String TECHNICAL_OFFER_QUEUE = 'Offer_Technical_Queue';
  
  /**Product2  */
  public static final string[] GRANT_SCHOLARSHIP_PRODUCT_FAMILIES = new string[] {'Scholarship', 'Grant'};

  /**Clause */
  public static final string[] CLAUSE_OBJECTTYPES = new string[] {'SBQQ__QuoteLine__c','SBQQ__Quote__c'};

  public static final string OSHC_CTY_PICKLIST_PREFIX = 'OSHC for offer accepting all credit exemptions with ';
  public static final String PORTAL_PROFILE_NAME = 'Customer Community General User';
  public static final String MYAPP_PERMSET_NAME = 'Customer_Community_My_Application';
  public static final String MYAPP_MFA_PERMSET_NAME = 'Experience_Custom_MFA';
  public static final String EXPERIAN_PERMSET_NAME = 'Experian';
  

  /** OPPORTUNITY */
  public static final String OPP_OFFERCATEGORY_INTERNATIONAL_OFFER = 'International Offer';
  public static final String OPP_OFFERCATEGORY_INTERNATIONAL_DEFERRAL = 'International Deferral';
  public static final String OPP_OFFERCATEGORY_DOMESTIC_DEFERRAL = 'Domestic Deferral';
  public static final String OPP_OFFERCATEGORY_DOMESTIC_OFFER = 'Domestic Offer';

  /*Monash Abroad application*/
  public static String MONASH_ABROAD_SA_COURSE_TITLE = 'Study Abroad';
  public static String MONASH_ABROAD_EX_COURSE_TITLE = 'Exchange';
  public static String MONASH_ABROAD_SA_COURSE_UG_CODE = '7001';
  public static String MONASH_ABROAD_SA_COURSE_PG_CODE = '7002';
  public static String MONASH_ABROAD_EX_COURSE_UG_CODE = '8001';
  public static String MONASH_ABROAD_EX_COURSE_PG_CODE = '8002';
  public static String MONASH_ABROAD_SA_STUDY_TYPE = 'Study Abroad';
  public static String MONASH_ABROAD_EX_STUDY_TYPE = 'Exchange';
  public static String FIELD_MAP_FACULTY_OPTIONS = 'facultyOptions';
  public static String FIELD_MAP_CAMPUS_OPTIONS = 'campusOptions';
  public static String MONASH_ABROAD_CAMPUS_LOCATION_ONLINE = 'Online';
  public static String LOCATION_ONLINE_A = 'ONLINE-A';
  public static String INDONESIA_CAMPUS_LOCATION = 'INDONESIA';
  public static String STD_PRICE_BOOK_DELIMITER = '_STD';
  public static String AUD_CURRENCY = 'AUD';
  public static String IDR_CURRENCY = 'IDR';
  public static String INR_CURRENCY = 'INR';

  public static String EMAIL_ENCODING_KEY = 'UTF-8';
  public static String  LANGUAGE_LOCALE_KEY = 'en_US';
  public static String  LOCALE_SID_KEY = 'en_AU';
  public static String  TIME_ZONE_SID_KEY = 'Australia/Sydney';

  public static final String PARTNER_USER_PROFILE = 'Monash Partner Community Login User';
  public static final String AGENT_USER_PROFILE = 'Agent Portal Next Gen User';

  public static final String PARTNER_BUSINESS_USER_PROFILE = 'Monash Abroad Base Profile';
  public static final String AGENCY_BUSINESS_USER_PROFILE = 'System Administrator';
  //'Monash Agent Management Business Admin Profile';

  public static final String STUDYTYPE_EXCHANGE = 'Exchange';
  public static final String STUDYTYPE_STUDYABROAD = 'Study Abroad';
  public static final String PARTNER_PERMISSION_SET = 'Partner_Community_Access';
  public static final String CONTACT_PARTNER_RECORDTYPE_DEV_NAME = 'Partner';
  public static final String CONTACT_AGENCY_RECORDTYPE_DEV_NAME = 'Agency_Contact';
  public static final String CALLISTA_PARTNER_ORG_UNIT_CODE = 'PARTNR';

  //MGROI-233 MyApplication HDR Update
  public static final String COURSETYPE_GROUP_HDR = 'HDR';
  public static final String STUDYTYPE_GRADUATERESEARCH = 'Graduate Research';
  public static final String CITIZEN_TYPE_INTERNATIONAL = 'International';
  public static final String CITIZEN_TYPE_DOMESTIC = 'Domestic';


    /*ACP Constants*/
    public static final String GCO_OUTCOMESTATUS_VALUE = 'OFFER-G-CO';


  //SFTG-1949 Changed the string to fetch from Custom Setting instead of Custom Label
  public static String PARTNR {
    get {
      if (PARTNR == null) {
        Environment_Settings__c environmentSettings = Environment_Settings__c.getOrgDefaults();
        PARTNR = environmentSettings.PARTNR_Agent_Person_Id__c;
      }
      return PARTNR;
    }
    private set;
  }

  /**
   * Singleton for Offer Settings
   */
  public static Offer_Setting__c offersetting {
      get {
          if (offersetting == null) {
              offersetting = Offer_Setting__c.getOrgDefaults();
          }
          return offersetting;
      }
      set;
  }
  public static Integer MIN_UNITS_MA {
    get {
      if (MIN_UNITS_MA == null) {
        return offersetting.Minimum_Unit_s_for_MA_Applications__c == null ? 0 : offersetting.Minimum_Unit_s_for_MA_Applications__c.intValue();
      }
      return MIN_UNITS_MA;
    }
    set;
  }
  public static Integer MAX_UNITS_MA {
    get {
      if (MAX_UNITS_MA == null) {
        return offersetting.Maximum_Unit_s_for_MA_Applications__c == null ? 0 : offersetting.Maximum_Unit_s_for_MA_Applications__c.intValue();
      }
      return MAX_UNITS_MA;
    }
    set;
  }
  public static Integer MIN_UNITS_ONLINE {
    get {
      if (MIN_UNITS_ONLINE == null) {
        return offersetting.Minimum_Unit_s_for_Online_Applications__c == null ? 0 : offersetting.Minimum_Unit_s_for_Online_Applications__c.intValue();
      }
      return MIN_UNITS_ONLINE;
    }
    set;
  }
  public static Integer MAX_UNITS_ONLINE {
    get {
      if (MAX_UNITS_ONLINE == null) {
        return offersetting.Maximum_Unit_s_for_Online_Applications__c == null ? 0 : offersetting.Maximum_Unit_s_for_Online_Applications__c.intValue();
      }
      return MAX_UNITS_ONLINE;
    }
    set;
  }
  public static final String CONTACT_POINT_SOURCE_EXPERIAN = 'Experian';
  public static final String CONTACT_POINT_SOURCE_UNDEFINED = 'Undefined';
  public static final String CONTACT_POINT_SOURCE_THIRD_PARTY = 'Third party provided';

  public static final Map<String, List<String>> MY_APP_STUDYTYPE_QUESTIONS = new Map<String,List<String>> {
    'Coursework' => new List<String> {'Undergraduate',
                                      'Diploma',
                                      'Graduate Coursework',
                                      'Preparatory Course'},
    'Study Abroad' => new List<String> {'Exchange / Study Abroad'},
    'Graduate Research' => new List<String> {'Graduate Research'} 
  };

  public static final Map<String, String> MY_APP_STUDYTYPE_SUBHEADING = new Map<String,String> {
    'Undergraduate' => 'Bachelor Degree, Double Degree, Honours year',
    'Diploma' => 'Study lasting 1-2 years' ,
    'Graduate Coursework' => 'Masters by Coursework, Grad. Diploma, Grad. Certificate',
    'Preparatory Course' => 'English language or pathway course for university entry', 
    'Graduate Research' => 'PhD, Masters by Research',
    'Exchange / Study Abroad' => '1-2 semesters of study toward my home university degree'  
  };

  // DCA constants;
  public static final String DUPLICATE_RULE_CONTACT_PERFECT_MATCH = 'Contact Perfect Match';
  public static final String DUPLICATE_RULE_CONTACT_POTENTIAL_MATCH = 'Contact Potential Match';
  
}