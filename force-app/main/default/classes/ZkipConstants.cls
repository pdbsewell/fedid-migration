/**
 * @author          Shalini Mendu
 * @description     Constants
 * @revision
 * 		2025-17-08	-	Sachin Shetty	-	Added a default contructor
 **/
public class ZkipConstants {

    public static final String ENDPOINT_PREFIX = 'callout:';
    public static final String METHOD_GET = 'GET';
    public static final String METHOD_POST = 'POST';
    public static final String METHOD_PATCH = 'PATCH';
    public static final String API_ACCESS_KEY_PREFIX = 'Bearer ';
    public static final String CONTENT_TYPE_JSON = 'application/json'; 


    public static final String GUEST_TYPE = 'guests';
    public static final String GUEST_LIST_TYPE = 'guest-lists';
    public static final String CUSTOM_FIELD_VALUES_UNICRM_CAMPMEMBID = 'UniCRM Campaign Member Id';
    public static final String CUSTOM_FIELD_VALUES_TITLE = 'Title';
    public static final String CUSTOM_FIELD_VALUES_INVITEE = 'Invitee';
    public static final String CUSTOM_FIELD_VALUES_SUFFIX1 = 'Suffix 1';
    public static final String CUSTOM_FIELD_VALUES_GUESTPARTNER = 'Guest';
    public static final String CUSTOM_FIELD_VALUES_POSITIONS = 'Position';
    public static final String CUSTOM_FIELD_VALUES_DIETREQ = 'Dietary Requirements';
    public static final String CUSTOM_FIELD_VALUES_ACCESSIBILITYREQ = 'Accessibility Requirements';


    public static final String ERR_MISSING_CAMPID = 'Error! Missing Campaign Id';
    public static final String ERR_MISSING_SETTING = 'Error! Missing Custom Setting. Please contact your administrator.';
    public static final String ERR_CALLOUT = 'Error! Problem while doing callout. Please contact your administrator.';
    public static final String ERR_EVENT_ALRDY_CREATED = 'Error! Event already exists in zkipster.';
    public static final String ERR_EVENT_NOT_EXISTS = 'Error! Event do not exists in Zkipster. Please create first, by clicking Create Event. Thanks!';
    public static final String ERR_GUEST_LIST_NOT_EXISTS = 'Error! Guest List do not exists in Zkipster. Please create first, by clicking Create Guest List. Thanks!';
    public static final String ERR_NO_GUEST_LIST_TO_CREATE = 'Error! No Guest List to create in zkipster.';
    public static final String ERR_ALL_GUEST_LIST_EXISTS = 'Error! All Guest List already exists in Zkipster.';
    public static final String SUCC_CREATE_EVENT = 'Event successfully created in zkipster.';
    public static final String SUCC_UPDATE_EVENT = 'Event successfully updated in zkipster.';
    public static final String SUCC_CREATE_GUEST_LIST ='Guest Lists successfully created in zkipster.';
    public static final String SUCC_GET_UPDATES = 'Getting updates from Zkipster started. Please refresh the page.';
    public static final String ERR_GET_UPDATES = 'Error! Getting updates from Zkipster is in progress.';
    public static final String SUCC_SYNC_INITIATED = 'Synchronizing Members started. Please refresh the page.';
    public static final String ERR_SYNC_IN_PROGRESS = 'Error! Synchronisation Members is in progress.';
    public static final String ERR_EVENT_START_DATE_PAST = 'Error! Event already started. Updating details is not allowed.';
    public static final String ERR_EVENT_STATUS_COMPLETED = 'Error! Event already completed.';

    public static final String CAMP_STATUS_COMPLETED = 'Completed';
    
    // Default Constructor
    public ZkipConstants(){} //NOPMD
}