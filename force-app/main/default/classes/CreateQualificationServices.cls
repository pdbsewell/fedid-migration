/**
 * @author      J.Mapanao
 * @date        12.OCT.2019
 * @description Trigger by Create_Contact_Qualification lightning flow
 * 
 * @revision    12.OCT.2019 - J.Mapanao - Initial creation
 */
public with sharing class CreateQualificationServices {

    @AuraEnabled
    public static DataWrapperAddResult createQualification(String sObjectId, String jsonContactQualification) {
        DataWrapperAddResult result = new DataWrapperAddResult();
        Savepoint sp = Database.setSavepoint();
        try {
            if (String.isBlank(sObjectId)) {
                result.status = 'error';
                return result;
            }
            String sObjectName = findObjectNameFromRecordIdPrefix(sObjectId);
            String applicationId;
            String contactId;
            List<Application__c> applications = new List<Application__c>();
            List<Application_Course_Preference__c> applicationCoursePreferences = new List<Application_Course_Preference__c>();

            // When passing sObjectId, kindly add more if condition here.
            // Logic to get the application Id and contact Id
            // which are required for Application Qualification Provided.
            if (sObjectName == 'Application__c') {
                applications = [SELECT Id, Applicant__c, Status__c, Assessment_Status__c FROM Application__c WHERE Id =: sObjectId];
            } else if (sObjectName == 'Application_Course_Preference__c') {
                applicationCoursePreferences = [SELECT Id, Application__c FROM Application_Course_Preference__c WHERE Id =: sObjectId];
                applications = [SELECT Id, Applicant__c, Status__c, Assessment_Status__c FROM Application__c WHERE Id =: applicationCoursePreferences.get(0).Application__c];
            }
            
            Application__c application = applications.get(0);
            // Create contact qualification
            Contact_Qualification__c conQual = (Contact_Qualification__c) JSON.deserialize(jsonContactQualification, Contact_Qualification__c.class);
            conQual.Contact__c = application.Applicant__c;
            insert conQual;

            // Create related Application Qualification Provided
            Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c(
                Contact_Qualification__c = conQual.Id,
                Application__c = application.Id
            );
            insert aqp;

            // Create Document Checklist record
            DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{application.Id});
            rulesDocChecklistEngine.evaluateRules('Application Assessment');
            List<Document_Checklist__c> checklists = rulesDocChecklistEngine.resultChecklistItemsMap.get(application.Id).values();
            upsert checklists;

            result.status = 'success';
        } catch (Exception ex) {
            Database.rollback(sp);
            result.status = 'error';
            ExLog.add('CreateQualificationServices','Application','createQualification', ex);
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static DataWrapper fetchInitialData() {
        DataWrapper dataResult = new DataWrapper();

        // Get all Qualification Type Options
        dataResult.qualificationRecordTypeOptions = getQualificationRecordTypeOptions();
        // Get all countries options
        dataResult.countryStudiedOptions = getAllCountriesOptions();
        // Get all institution options
        dataResult.institutionOptions = getInstitutionOptions();
        // Get completion status options
        dataResult.completionStatusOptions = getCompletionStatusOptions();
        // Get australia state options
        dataResult.ausStateOptions = getAusStateOptions();
        // Get qualifications options
        dataResult.qualificationOptions = getSecQualificationOptions();
        // Get english test options
        dataResult.admissionTestOptions = getAdmissionTestOptions();
        // Get Tertiary Qualification Level options
        dataResult.tertiaryQualificationLevelOptions = getTertiaryQualificationLevel();
        // Get Qualification GPA Calc Method
        dataResult.qualificationGPACalcMethodOptions = getQualificationGPACalcMethod();
        // Get Monash Equivalent Band options
        dataResult.monashEquivalentGPAOptions = getMonashEquivalentGPA();
        // Get Verification Status
        dataResult.verificationStatusOptions = getVerificationStatus();

        return dataResult;
    }
    
    public static Map<String, String> getQualificationRecordTypeOptions() {
        Map<String, String> options = new Map<String, String>();

        for (RecordType recType : [
            SELECT  Id, Name, sObjectType
            FROM    RecordType
            WHERE   sObjectType = 'Contact_Qualification__c'
            ORDER BY Name DESC
        ]) {
            options.put(recType.Id, recType.Name);
        }
        return options;
    }
    
    public static Map<String, String> getAllCountriesOptions() {
        Map<String, String> options = new Map<String, String>();

        for (Country_Attribute__c objCountry : [
            SELECT  Id, Country__c
            FROM    Country_Attribute__c
            WHERE   Country__c != null
            ORDER BY Name ASC
        ]) {
            options.put(objCountry.Id, objCountry.Country__c);
        }
        return options;
    }

    public static Map<String, Institution__c> getInstitutionOptions(){
        Map<String, Institution__c> options = new Map<String, Institution__c>();
        for (Institution__c objInstitution : [
            SELECT  Id, Institution_Name__c, Institution_Code__c, Type__c, Country__c, State__c
            FROM    Institution__c
            ORDER BY Institution_Name__c
        ]) {
            options.put(objInstitution.Id, objInstitution);
        }
        return options;
    }

    public static Map<String, Qualification__c> getSecQualificationOptions(){
        Map<String, Qualification__c> options = new Map<String, Qualification__c>();

        for (Qualification__c objQualification : [
            SELECT  Id, Qualification_Name__c, Overseas__c, State__c, RecordType.Name
            FROM    Qualification__c
            ORDER BY Qualification_Name__c ASC
        ]) {
            options.put(objQualification.Id, objQualification);
        }
        return options;
    }

    public static Map<String,String> getAdmissionTestOptions()
    {
        // get the RecordTypeId of admission test qualifications
        String admissionTestRecTypeId = [SELECT Id, Name, sObjectType FROM RecordType WHERE DeveloperName = 'Admission_Test'].Id;

        Map<String,String> options = new Map<String,String>();
        for (Qualification__c qualificationRec: [
            SELECT  Qualification_Name__c, Available_on_Portal__c
            FROM    Qualification__c
            WHERE   RecordTypeId =: admissionTestRecTypeId
            AND     Available_on_Portal__c = TRUE
            ORDER BY Qualification_Name__c
        ]) {
            options.put(qualificationRec.Id, qualificationRec.Qualification_Name__c);
        }
        return options;
    }

    public static Map<String,String> getCompletionStatusOptions() {
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Status__c.getDescribe();
        return populatePicklistAsOptions(fieldResult);
    }

    public static Map<String,String> getAusStateOptions() {
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.State__c.getDescribe();
        return populatePicklistAsOptions(fieldResult);
    }

    public static Map<String,String> getTertiaryQualificationLevel() {
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Tertiary_Qualification_Level__c.getDescribe();
        return populatePicklistAsOptions(fieldResult);
    }

    public static Map<String,String> getQualificationGPACalcMethod() {
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Qualification_GPA_Calc_Method__c.getDescribe();
        return populatePicklistAsOptions(fieldResult);
    }

    public static Map<String,String> getMonashEquivalentGPA() {
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Monash_Equivalent_GPA__c.getDescribe();
        return populatePicklistAsOptions(fieldResult);
    }

    public static Map<String,String> getVerificationStatus() {
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Verification_Status__c.getDescribe();
        return populatePicklistAsOptions(fieldResult);
    }

    /**
     * @description     reusable function to get picklist options for lightning components
     * @param           fieldResult
     * @return          a list of {value,label} objects for use as lightning:select options
     */
    private static Map<String,String> populatePicklistAsOptions(Schema.DescribeFieldResult fieldResult) {
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Map<String,String> options = new Map<String,String>();
        for( Schema.PicklistEntry f : ple) {
            options.put(f.getValue(), f.getLabel());
        }
        return options;
    }

    public class DataWrapper {
        @AuraEnabled
        public Map<String, String> qualificationRecordTypeOptions;
        @AuraEnabled
        public Map<String, String> countryStudiedOptions;
        @AuraEnabled
        public Map<String, Institution__c> institutionOptions;
        @AuraEnabled
        public Map<String, String> completionStatusOptions;
        @AuraEnabled
        public Map<String, String> ausStateOptions;
        @AuraEnabled
        public Map<String, Qualification__c> qualificationOptions;
        @AuraEnabled
        public Map<String, String> admissionTestOptions;
        @AuraEnabled
        public Map<String, String> tertiaryQualificationLevelOptions;
        @AuraEnabled
        public Map<String, String> qualificationGPACalcMethodOptions;
        @AuraEnabled
        public Map<String, String> monashEquivalentGPAOptions;
        @AuraEnabled
        public Map<String, String> verificationStatusOptions;
    }

    public class DataWrapperAddResult {
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;
    }

    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);

            //Get schema information
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe();

            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){

                //if (!sObj.contains('__')) to exclude managed package objects

                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                System.debug('Prefix is ' + prefix);

                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        }catch(Exception e){
            //System.debug(e);
            ExLog.add('CreateQualificationServices','Application','findObjectNameFromRecordIdPrefix', e);
        }
        return objectName;
    }
}