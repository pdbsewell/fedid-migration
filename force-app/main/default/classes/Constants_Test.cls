@isTest(isParallel=true)
public class Constants_Test {
    @isTest
    /**
     * @author      unknown
     * @description Tests creating for the apex class constants
     * @revision    16/07/24 updated
     *
     * GIVEN there are constants defined at a certain place
     * WHEN constants are being called from any apex class
     * THEN system shoud see the actual value defined in the constants
     */
    private static void test_constants(){
        Assert.isTrue(Constants.PRODUCT2_OFFER == 'Offer');

        Assert.isTrue(Constants.BUNDLE_PRODUCT_FAMILY == 'Bundle'); 
        Assert.isTrue(Constants.COURSE_PRODUCTS == new string[] {'English Course', 'Course', 'Diploma'});
        /**COURSE_FEE__C */
        Assert.isTrue(Constants.COURSEFEE_SYNCINPROGRESS == 'SYNC IN PROGRESS...');
        Assert.isTrue(Constants.COURSEFEE_SYNCCOMPLETED == 'SYNC COMPLETED!');
        /**SBQQ__QUOTE__C */
        Assert.isTrue(Constants.QUOTE_PRICE_CALCULATED == 'Pricing Completed');
        Assert.isTrue(Constants.QUOTE_STATUS_IN_REVIEW == 'In Review');
        Assert.isTrue(Constants.QUOTE_SUBSTATUS_QAPREVIEW == 'Preview in QA');
        

        Assert.isTrue(Constants.DEFAULT_PRODUCT_BUNHEALTH == 'BUNHEALTH');
        Assert.isTrue(Constants.IS_SHADOW_PHASE == 'IN_SHADOW_PHASE');
        /**QUEUE**/
        Assert.isTrue(Constants.BUSINESS_OFFER_QUEUE == 'Offer_Business_Queue');

        /**Product2  */
        Assert.isTrue(Constants.GRANT_SCHOLARSHIP_PRODUCT_FAMILIES == new string[] {'Scholarship', 'Grant'});

        /**Clause */
        Assert.isTrue(Constants.CLAUSE_OBJECTTYPES == new string[] {'SBQQ__QuoteLine__c','SBQQ__Quote__c'});

        /**Monash abroad */
        Assert.isTrue(Constants.MONASH_ABROAD_SA_COURSE_TITLE == 'Study Abroad');
        Assert.isTrue(Constants.MONASH_ABROAD_EX_COURSE_TITLE == 'Exchange');
        Assert.isTrue(Constants.MONASH_ABROAD_SA_COURSE_UG_CODE == '7001');
        Assert.isTrue(Constants.MONASH_ABROAD_SA_COURSE_PG_CODE == '7002');
        Assert.isTrue(Constants.MONASH_ABROAD_EX_COURSE_UG_CODE == '8001');
        Assert.isTrue(Constants.MONASH_ABROAD_EX_COURSE_PG_CODE == '8002');
        Assert.isTrue(Constants.MONASH_ABROAD_SA_STUDY_TYPE == 'Study Abroad');
        Assert.isTrue(Constants.MONASH_ABROAD_EX_STUDY_TYPE == 'Exchange');
        Assert.isTrue(Constants.FIELD_MAP_FACULTY_OPTIONS == 'facultyOptions');
        Assert.isTrue(Constants.FIELD_MAP_CAMPUS_OPTIONS=='campusOptions');
        Assert.isTrue(Constants.INDONESIA_CAMPUS_LOCATION == 'INDONESIA');
        Assert.isTrue(Constants.OPP_OFFERCATEGORY_DOMESTIC_DEFERRAL == 'Domestic Deferral');
        Assert.isTrue(Constants.MYAPP_MFA_PERMSET_NAME == 'Experience_Custom_MFA');
        Assert.isTrue(Constants.EXPERIAN_PERMSET_NAME == 'Experian');
        Assert.isTrue(Constants.EMAIL_ENCODING_KEY == 'UTF-8');
        Assert.isTrue(Constants.LANGUAGE_LOCALE_KEY == 'en_US');
        Assert.isTrue(Constants.LOCALE_SID_KEY == 'en_AU');
        Assert.isTrue(Constants.TIME_ZONE_SID_KEY == 'Australia/Sydney');
        Assert.isTrue(Constants.AGENT_USER_PROFILE == 'Agent Portal Next Gen User');
        Assert.isTrue(Constants.PARTNER_BUSINESS_USER_PROFILE == 'Monash Abroad Base Profile');
        Assert.isTrue(Constants.AGENCY_BUSINESS_USER_PROFILE == 'System Administrator');

        //Start assertion - check that the Custom settings are correctly fetched
        //Environment_Settings__c
        Environment_Settings__c environmentSettings = new Environment_Settings__c();
        environmentSettings.PARTNR_Agent_Person_Id__c = 'TstPartner'; //max 10 chars long
        insert environmentSettings;
        Assert.areEqual('TstPartner', Constants.PARTNR, 'PARTNR_Agent_Person_Id__c is undefined in Environment Settings or is not fetched properly');
        //Offer_Setting__c
        Offer_Setting__c offerSettings = new Offer_Setting__c();
        offerSettings.Minimum_Unit_s_for_MA_Applications__c = 1; 
        offerSettings.Maximum_Unit_s_for_MA_Applications__c = 99; 
        offerSettings.Minimum_Unit_s_for_Online_Applications__c = 1; 
        offerSettings.Maximum_Unit_s_for_Online_Applications__c = 99; 
        insert offerSettings;
        Assert.areEqual(1, Constants.MIN_UNITS_MA, 'Minimum_Unit_s_for_MA_Applications__c in Offer Settings is not fetched properly');
        Assert.areEqual(99, Constants.MAX_UNITS_MA, 'Maximum_Unit_s_for_MA_Applications__c in Offer Settings is not fetched properly');
        Assert.areEqual(1, Constants.MIN_UNITS_ONLINE, 'Minimum_Unit_s_for_Online_Applications__c in Offer Settings is not fetched properly');
        Assert.areEqual(99, Constants.MAX_UNITS_ONLINE, 'Maximum_Unit_s_for_Online_Applications__c in Offer Settings is not fetched properly');
        
        //Test for My.App Study Type based questions
        Assert.areEqual('Exchange / Study Abroad', Constants.MY_APP_STUDYTYPE_QUESTIONS.get('Study Abroad')[0]);
    }
}