/**
 * Constants service class for Bulk Data Processing object.  
 * @author David Browaeys
 * @group Bulk Data Processing
 */
public inherited sharing class BDPConstants {
    @TestVisible private BDPConstants() {}
    public static final String COURSE_TRANSFER_TYPE = 'Course Transfer';
    public static final String CAMPUS_TRANSFER_TYPE = 'Campus Transfer';
    public static final String CC_TRANSFER_RECORDTYPE = 'CC_Transfer';
    public static final String READY_STATUS = 'Ready for Offer';
    public static final String CALENDAR_CATEGORY = 'ADMISSION';
    public static final String DEFAULT_CITIZENSHIP = 'INTRNTNL';
    public static final String REVIEW_REQUIRED = 'Review Required';
    public static final String BDP_NEW = 'New';
    public static final String AUSTRALIA_CALLISTA_CODE = '1101';
    public static final String VICTORIA_CALLISTA_CODE  = '3000';
    public static final String BDP_COURSE_OFFERING_DUPLICATE_RULE = 'CC_Transfer_Course_Offering_Duplicate_Rule';
    public static final String COURSE_ATTEMPT_NOT_FOUND_MSG = 'Unable to find a matching Current Course Attempt record. Please check the data in the spreadsheet, delete this record and re-upload the spreadsheet, or manually update the BDP record.';
    public static final String ACP_NOT_FOUND_MSG = 'Unable to find a matching current ACP record. Please check the data in the spreadsheet, delete this record and re-upload the spreadsheet, or manually update the BDP record.';
    public static final String CO_NOT_FOUND_MSG = 'Unable to find a matching Transfer Course Offering record. Please check the data in the spreadsheet, delete this record and re-upload the spreadsheet, or manually update the BDP record.';
    public static final String MULTI_CO_FOUND_MSG = 'Multiple matching Course Offering records found. Please go to Suggested Course Offerings related list and mark the matching one as primary to continue.';
    public static final String STUDENT_NOT_FOUND = 'Unable to find an applicant with the same person ID in Salesforce.';
    public static final String CALENDAR_NOT_FOUND = 'Unable to find a calendar with the same calendar alternate name in Salesforce.';
    public static final String CREDIT_DURATION_WARNING = 'Unable to convert Credit Duration Value and Credit Duration Unit with the unit type in Credit: Adjusted Course Duration Type field in the Transfer To ACP record. Please update the Override Duration Unit in the primary suggested course offering record and/or update Credit: Adjusted Course Duration field in the Transfer To ACP record manually to generate an offer for this record.';
}