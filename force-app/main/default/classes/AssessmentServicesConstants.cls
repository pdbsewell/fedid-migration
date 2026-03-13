/**
 * @author      J.Mapanao
 * @description All constants related to AssessmentServices.cls
 * @revision    J.Mapanao, 08.Aug.2019 - created
 * @revision
 * 		2025-17-08	-	Sachin Shetty	-	Added a default contructor
 */
public class AssessmentServicesConstants {
    
    // Same values from Assessment Flow Status (Global Value Set)
    public static final String APP_ASSESSMENT_TASK_STATUS_REQUIRED = 'Required';
    public static final String APP_ASSESSMENT_TASK_STATUS_INPROGRESS = 'In Progress';
    public static final String APP_ASSESSMENT_TASK_STATUS_WFORDOCS = 'Waiting for docs';
    public static final String APP_ASSESSMENT_TASK_STATUS_COMPLETED = 'Completed';
    public static final String APP_ASSESSMENT_TASK_STATUS_FAILED = 'Failed';
    public static final String APP_ASSESSMENT_TASK_STATUS_NOTREQUIRED = 'Not Required';
    public static final String APP_ASSESSMENT_TASK_STATUS_WFORINTERNAL = 'Internal Input Required';
    public static final string APP_ASSESSMENT_TASK_STATUS_DISCONTINUED = 'Discontinued';
    
    // Process Flow Name
    public static final String ASSESSMENT_PROCESS_DOCQACHECK = 'Document QA Check';
    public static final String ASSESSMENT_PROCESS_VISACHECK = 'Visa Check';
    
    // Contact Document's Document Type values
    public static final String CONDOC_DOC_TYPE_OTHER = 'OTHERDCTYP';

    // Application Checklist's Status
    public static final String APP_CHECKLIST_STATUS_NOTREQUIRED = 'Not Required';
    public static final String APP_CHECKLIST_STATUS_INSUFFICIENT = 'Insufficient';
    public static final String APP_CHECKLIST_STATUS_REQUESTED = 'Requested';
    public static final String APP_CHECKLIST_STATUS_SUBMITTED = 'Submitted';
    public static final String APP_CHECKLIST_STATUS_APPROVED = 'Approved';
    public static final String APP_CHECKLIST_STATUS_AUTOCANCELLED = 'AutoCancelled';
    public static final String APP_CHECKLIST_STATUS_MANUALCANCELLED = 'ManualCancelled';

    // Application Checklist's Task Type
    public static final String APP_CHECKLIST_TASKTYPE_VISA = 'Visa';

    // Task trigger reasons
    public static final String EMAIL_RECEIVED = 'Email Received';
    public static final String DOCUMENT_RECEIVED = 'Document Received';

    
    // Application Course Preference's Task: Assessment (Task_Course_Preference__c)
    public static final String APP_COURSE_PREF_TASK_ASSESSMENT_INPROGRESS = 'In Progress';
    
    // Default Constructor
    public AssessmentServicesConstants(){} //NOPMD
}