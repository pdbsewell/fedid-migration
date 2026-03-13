/**
 * @author          Kristian Vegerano
 * @description     Utility class for Contact Qualification object related details 
 * @group           Utilities
 * @revision        31/05/2019 - Kristian Vegerano - Added static CONTACT_QUALIFICATION_ENGLISH_REC_TYPE variable for calling contact qualification's english test record type by developer name
 *                  31/05/2019 - Kristian Vegerano - Added static CONTACT_QUALIFICATION_SECONDARY_REC_TYPE variable for calling contact qualification's secondary education record type by developer name
 *                  31/05/2019 - Kristian Vegerano - Added static CONTACT_QUALIFICATION_TERTIARY_REC_TYPE variable for calling contact qualification's tertiary education record type by developer name
 *                  31/05/2019 - Kristian Vegerano - Added static CONTACT_QUALIFICATION_OTHER_REC_TYPE variable for calling contact qualification's other education record type by developer name
 */
public with sharing class ContactQualificationUtility {
    /**
      * @description Use this variable to get contact qualification's english test record type by its developer name
      */
    public static Id CONTACT_QUALIFICATION_ENGLISH_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_ENGLISH_REC_TYPE == null) {
                CONTACT_QUALIFICATION_ENGLISH_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('English_Test')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_ENGLISH_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's secondary education record type by its developer name
      */
    public static Id CONTACT_QUALIFICATION_SECONDARY_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_SECONDARY_REC_TYPE == null) {
                CONTACT_QUALIFICATION_SECONDARY_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Secondary_Education')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_SECONDARY_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's tertiary education record type by its developer name
      */
    public static Id CONTACT_QUALIFICATION_TERTIARY_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_TERTIARY_REC_TYPE == null) {
                CONTACT_QUALIFICATION_TERTIARY_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Tertiary_Education')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_TERTIARY_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's english test record type by its developer name
      */
    public static Id CONTACT_QUALIFICATION_OTHER_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_OTHER_REC_TYPE == null) {
                CONTACT_QUALIFICATION_OTHER_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Other_Qualification')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_OTHER_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's Awards_and_Scholarships record type by its developer name
      */
      public static Id CONTACT_QUALIFICATION_AWARDS_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_AWARDS_REC_TYPE == null) {
                CONTACT_QUALIFICATION_AWARDS_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Awards_and_Scholarships')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_AWARDS_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's Experience record type by its developer name
      */
      public static Id CONTACT_QUALIFICATION_EXPERIENCE_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_EXPERIENCE_REC_TYPE == null) {
                CONTACT_QUALIFICATION_EXPERIENCE_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Employment_and_Research')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_EXPERIENCE_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's referee record type by its developer name
      */
      public static Id CONTACT_QUALIFICATION_REFEREE_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_REFEREE_REC_TYPE == null) {
                CONTACT_QUALIFICATION_REFEREE_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Referees')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_REFEREE_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's music record type by its developer name
      */
      public static Id CONTACT_QUALIFICATION_MUSIC_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_MUSIC_REC_TYPE == null) {
                CONTACT_QUALIFICATION_MUSIC_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Music')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_MUSIC_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's publications record type by its developer name
      */
      public static Id CONTACT_QUALIFICATION_PUBLICATIONS_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_PUBLICATIONS_REC_TYPE == null) {
                CONTACT_QUALIFICATION_PUBLICATIONS_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Publications')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_PUBLICATIONS_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's theatre performance record type by its developer name
      */
      public static Id CONTACT_QUALIFICATION_THEATRE_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_THEATRE_REC_TYPE == null) {
                CONTACT_QUALIFICATION_THEATRE_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Theatre_Performance')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_THEATRE_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's theatre performance record type by its developer name
      */
      public static Id CONTACT_QUALIFICATION_EXHIBITION_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_EXHIBITION_REC_TYPE == null) {
                CONTACT_QUALIFICATION_EXHIBITION_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Exhibitions')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_EXHIBITION_REC_TYPE;
        }
        set;
    }

    /**
      * @description Use this variable to get contact qualification's theatre performance record type by its developer name
      */
      public static Id CONTACT_QUALIFICATION_CREATIVE_WORK_REC_TYPE {
        get {
            if(CONTACT_QUALIFICATION_CREATIVE_WORK_REC_TYPE == null) {
                CONTACT_QUALIFICATION_CREATIVE_WORK_REC_TYPE = Schema.SObjectType.Contact_Qualification__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Creative_Works')
                    .getRecordTypeId();
            }
            return CONTACT_QUALIFICATION_CREATIVE_WORK_REC_TYPE;
        }
        set;
    }
}