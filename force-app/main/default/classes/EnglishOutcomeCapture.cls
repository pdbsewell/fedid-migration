public with sharing class EnglishOutcomeCapture {

    public static final String COURSE_PREF_QUALIFICATION_ENG_QUALIFICATION_TYPE = 'English';
    public static final String COURSE_PREF_QUALIFICATION_EDU_QUALIFICATION_TYPE = 'Education'; 
    public static final String COURSE_PREF_QUALIFICATION_SATISFACTORY_RESULT = 'Satisfactory';
    public static final List<String> QUALIFICATION_TYPES_THAT_DONT_NEED_CONTACTQUAL = new List<String>{
        'Valid and Verified Professional Registration',
        'Monash English Pathway'
    };
    public static final List<String> STATUS_TO_EXCLUDE_LIST = new List<String>{
        'Draft',
        'Sent Draft Application to Applicant', 
        'Applicant Declaration Accepted',
        'Data Validation Ready',
        'Failed Data validation'
    };


    public class RecordSaveList {
        public List<RecordSaveStructure> records = new List<RecordSaveStructure>();
    }

    public class RecordSaveStructure {
        public String recordId;
        public String contactId;
        public String type;
        public String applicationCoursePreference;
        public String result;
        public String monashEnglishModule;
    }

    private static Map<String, String> recordTypeTranslation = new Map<String, String>{
            'VCE English Equivalent' => 'Secondary Education',
            'Language of Instruction' => 'Tertiary Education',
            'English Test Results' => 'English Test'
    };

    @AuraEnabled
    public static List<Application_Course_Preference__c> getApplicationCoursePreferences(String contactId) {
        List<Application_Course_Preference__c> applicationCoursePreferences = new List<Application_Course_Preference__c>();

        applicationCoursePreferences = [
                SELECT Id, Name, Course__r.Course_Code__c, Course_Title__c, Admission_Category__c, Location_Code__c
                FROM Application_Course_Preference__c
                WHERE Applicant__c = :contactId 
        ];

        return applicationCoursePreferences;
    }

    @AuraEnabled
    public static List<Course_Attempt__c> getCourseAttempts(String contactId) {
        List<Course_Attempt__c> courseAttempts = new List<Course_Attempt__c>();

        courseAttempts = [
                SELECT Id, Name, Application_Course_Preference__c, Course_Code__c, Course_Title__c, 
                       Application_Course_Preference__r.Admission_Category__c, Application_Course_Preference__r.Location_Code__c
                FROM Course_Attempt__c
                WHERE Contact__c = :contactId 
                AND Course_Code__c = :'3636'
        ];

        return courseAttempts;
    }

    @AuraEnabled
    public static List<Contact_Qualification__c> getContactQualificationsByRecordType(String contactId, String recordTypeName) {
        List<Contact_Qualification__c> contactQualifications = new List<Contact_Qualification__c>();
        try {
            contactQualifications = [
                    SELECT Id, Verification_Status__c, Score__c, Year_of_Completion__c, Qualification_Name__c, Name, Qualification_Type__c
                    FROM Contact_Qualification__c
                    WHERE Contact__c = :contactId
                    AND RecordType.Name = :recordTypeTranslation.get(recordTypeName)
            ];
        } catch (Exception e) {
            ExLog.add('Class', 'EnglishOutcomeCapture', 'getContactQualifications', e.getMessage());
        }
        return contactQualifications;
    }

    /*******************************************************************************
     * @author       Sethu Venna
     * @date         10/01/2025
     * @param        contactId
     * @description  Get the list of contact qualifications linked to ACP
     * @revision     10/01/2025 - Initial Version
     *******************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Contact_Qualification__c> getContactQualifications(String contactId)
    {   
        List<Contact_Qualification__c> contactQualifications = new List<Contact_Qualification__c>();
        try
        {
            List<Contact_Qualification__c> contactQualificationsList = new ContactQualificationsSelector().selectByContactId(new Set<Id>{contactId});
            for(Contact_Qualification__c cq:contactQualificationsList){
                if(STATUS_TO_EXCLUDE_LIST.contains(cq.Application_Status__c) == false)
                {
                    contactQualifications.add(cq);
                }
            }
        }
        catch(Exception ex)
        {
            Nebula.Logger.error(ex.getMessage(), ex);
            Nebula.Logger.saveLog();
        }
        return contactQualifications;
    }

    @AuraEnabled
    public static List<Course_Preference_Qualification__c> getCoursePreferenceQualifications(String acpId) {
        List<Course_Preference_Qualification__c> coursePreferenceQualifications = new List<Course_Preference_Qualification__c>();

        coursePreferenceQualifications = [
                SELECT Name, Contact_Qualification__c, Application_Course_Preference__c, Application_Course_Preference_Parent__c
                FROM Course_Preference_Qualification__c
                WHERE Application_Course_Preference_Parent__c = :acpId
        ];

        return coursePreferenceQualifications;
    }

    @AuraEnabled
    public static List<Course_Preference_Qualification__c> removeCoursePreferenceQualification(String coursePreferenceQualificationId) {
        List<Course_Preference_Qualification__c> coursePreferenceQualifications = [
                SELECT Id, Application_Course_Preference__c
                FROM Course_Preference_Qualification__c
                WHERE Id = :coursePreferenceQualificationId
        ];

        String acpId = coursePreferenceQualifications[0].Application_Course_Preference__c;
        delete coursePreferenceQualifications;

        //Get the new list
        return getCoursePreferenceQualifications(acpId);
    }

    @AuraEnabled
    public static List<Course_Preference_Qualification__c> createCoursePreferenceQualification(String records) {

        RecordSaveList recordsToSave = (RecordSaveList) JSON.deserialize(records, RecordSaveList.class);

        //Check to see if the records are assigned already
        if (recordsToSave.records.size() == 0) {
            return null;
        }

        Set<String> acpRecords = new Set<String>();

        //Remove Qualification records and ACP records for lookup
        for (RecordSaveStructure record : recordsToSave.records) {
            acpRecords.add(record.recordId);
        }

        List<Course_Preference_Qualification__c> existingQualifications = [
                SELECT Contact_Qualification__c, Application_Course_Preference_Parent__c
                FROM Course_Preference_Qualification__c
                WHERE Application_Course_Preference__c IN :acpRecords
        ];

        Set<String> contactQualificationsAttached = new Set<String>();
        Set<String> applicationCoursePreferenceAttached = new Set<String>();

        for(Course_Preference_Qualification__c pref : existingQualifications){
            if(pref.Contact_Qualification__c != null){
                contactQualificationsAttached.add(pref.Contact_Qualification__c);
            }else{
                applicationCoursePreferenceAttached.add(pref.Application_Course_Preference__c);
            }
        }


        List<Course_Preference_Qualification__c> coursePreferenceQualifications = new List<Course_Preference_Qualification__c>();
        Map<String, Application_Course_Preference__c> acpIdMapToUpdate = new Map<String, Application_Course_Preference__c>();
        for (RecordSaveStructure record : recordsToSave.records) {
            Course_Preference_Qualification__c coursePreferenceQualification = new Course_Preference_Qualification__c();
            coursePreferenceQualification.Contact__c = record.contactId;
            coursePreferenceQualification.Type__c = record.type;
            coursePreferenceQualification.Application_Course_Preference_Parent__c = record.applicationCoursePreference;
            coursePreferenceQualification.Result__c = record.result;
            if(record.type != COURSE_PREF_QUALIFICATION_EDU_QUALIFICATION_TYPE) 
            {
                coursePreferenceQualification.Qualification_Type__c = COURSE_PREF_QUALIFICATION_ENG_QUALIFICATION_TYPE;
                coursePreferenceQualification.Monash_English_Module__c = record.monashEnglishModule;
                if(record.applicationCoursePreference != null && record.result == COURSE_PREF_QUALIFICATION_SATISFACTORY_RESULT) {
                    Application_Course_Preference__c acp = new Application_Course_Preference__c(Id = record.applicationCoursePreference);
                    acp.English_Entry_Mode__c = record.type;
                    acpIdMapToUpdate.put(record.applicationCoursePreference, acp);
                }
            }
            else {
                coursePreferenceQualification.Qualification_Type__c = COURSE_PREF_QUALIFICATION_EDU_QUALIFICATION_TYPE;
            }
            
            if (!QUALIFICATION_TYPES_THAT_DONT_NEED_CONTACTQUAL.contains(record.type)) {
                coursePreferenceQualification.Contact_Qualification__c = record.recordId;
            }
            if(!contactQualificationsAttached.contains(coursePreferenceQualification.Contact_Qualification__c) || !applicationCoursePreferenceAttached.contains(coursePreferenceQualification.Application_Course_Preference__c)){
                coursePreferenceQualifications.add(coursePreferenceQualification);
            }
        }

        insert coursePreferenceQualifications;
        if(!acpIdMapToUpdate.isEmpty()) {
            update acpIdMapToUpdate.values();
        }

        return getCoursePreferenceQualifications(recordsToSave.records[0].applicationCoursePreference);
    }
}