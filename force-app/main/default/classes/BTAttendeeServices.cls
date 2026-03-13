/**
* @author Ibrahim Rumi
* @date 29.09.2020
* @group Event Management
* @description Service class for Blackthorn Attendee object
* @revision
*   04.11.2020  Ibrahim Rumi    - EPBBS-1375 added method cancelRegistrationRelatedAttendee to handle cancellation of event registration by attendees
*   27.01.2121  Nick Guia       - EPBBS-1710 modified createAttendeePerson360
*   12.04.2021  Ibrahim Rumi    - EPBBS-1856 added method AutoRegisterAttendee to auto change the status from pending to registered
*   12.04.2021  Ibrahim Rumi    - EPBBS-1888 Removed method AutoRegisterAttendee as a part of refactoring process
*   14.06.2021  Aref Samad      - EPBBS-1985 Added constant ATTN_STATUS_ATTENDED,REG_STATUS_INVITED & REG_STATUS_DECLINED for unit test
*   21.06.2021  Aref Samad      - EPBBS-1909 Defect fix country of residency and citizenship mapping in contact
*                                 (modify getP360CommitOrder to add contact to top of the list to update)
*   12-07-2021  Ibrahim Rumi    - EPBBS-2067 added method shouldExpireWaitlistedAttendee to expire waitlisting for an attendee
*   12-07-2021  Ibrahim Rumi    - EPBBS-2067 added method getdefaultBlackthornSettings to get default blackthorn event settings
*   18.10.2021  Ibrahim Rumi    - EPBBS-2183 Share newly inserted Attendee with existing event Staff
*   17.01.2022  Ibrahim Rumi    - EPBBS-2379 validateRegistration method to Validate capacity and duplicates during attendee registration
*   08-02-2022  Ibrahim Rumi    - EPBBS-2427 updated processAttendeeCancellation() to use attendeegroupids to process group cancellation
*/
public with sharing class BTAttendeeServices {

    //event item types
    public static final String MAIN_EVENT_TICKET = 'Main event ticket';

    //registration statuses
    public static final String REG_STATUS_TO_INVITE = 'To Invite';
    public static final String REG_STATUS_INVITED = 'Invited';
    public static final String REG_STATUS_PENDING = 'Pending';
    public static final String REG_STATUS_REGISTERED = 'Registered';
    public static final String REG_STATUS_DECLINED = 'Declined';
    public static final String REG_STATUS_CANCELLED = 'Canceled';
    public static final String REG_STATUS_WL_PENDING = 'Waitlisted - Pending';

    //attendance statuses
    public static final String ATTN_STATUS_ATTENDED = 'Attended';

    //registration status reasons
    public static final String REG_STATUS_REASON_PENDING_WL_REG = 'Pending Waitlist Registration';
    public static final String REG_STATUS_REASON_NR = 'No Response';
    public static final String REG_STATUS_REASON_WL_Expired = 'Waitlist expired';
    public static final String DUPLICATE_ATTENDEE_ERROR_MESSAGE = 'Attendee already registered to event';
    public static final String EVENT_CAPACITY_ERROR_MESSAGE = 'Event has reached the total capacity' ;

    public static conference360__Blackthorn_Events_Settings__c defaultSettings {
        get {
            if(defaultSettings == null) {
                defaultSettings = getdefaultBlackthornSettings();
            }
            return defaultSettings;
        } set;
    }

    public static List<BT_Attendee_to_SPS_Mapping__mdt> spsMapping {
        get {
            if(spsMapping == null) {
                spsMapping = retrieveSPSMapping();
            }
            return spsMapping;
        }
        set;
    }

    public BTAttendeeServices() { }

    /**
     * @description generate person360 records for each member of the DAO list
     * @param daoList : List of BTAttendeeDAO class
     */
    public void createAttendeePerson360(List<BTContactAttendeeDAO> daoList) {

        BaseClass bc = new BaseClass(getP360CommitOrder());
        List<Staged_Prospective_Student__c> spsList = new List<Staged_Prospective_Student__c>();

        for(BTContactAttendeeDAO conDao : daoList) {

            for(BTEventAttendeeDAO attDao : conDao.eventAttendeeDAO) {
                //[EPBBS-2030 | Update Winning Affiliation value from Event]
                String evAffiliation = attDao.getEvent().Winning_Affiliation__c;

                if(String.isNotBlank(evAffiliation)) {
                    //if affiliation is Prospective Student, always create an SPS record
                    if(evAffiliation.equalsIgnoreCase(BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT)) {

                        BTProspectiveStudentAttendee psAttendee =
                            new BTProspectiveStudentAttendee(conDao.getContact(), attDao.getEvent(), attDao.getAttendee());
                        psAttendee.createAttendeePerson360();
                        psAttendee.pushRecords(bc);

                    } else {
                        //validate if an instance of the affiliation has been created in memory
                        if(conDao.shouldCreateNewAffiliation(attDao)) {
                            //if affiliation is industry
                            if(evAffiliation.equalsIgnoreCase(BTAudienceTypeAnalyser.EVENT_AUDIENCE_INDUSTRY)) {
                                //TODO
                            }
                                //ELSE IF() CAPTURE OTHER AFFILIATIONS HERE
                            else {
                                //UNKNOWN AFFILIATION THROW AN EXCEPTION
                                throw new BTAttendeeServicesException('Unrecognised Affiliation for Event : ' + evAffiliation);
                            }
                        }
                    }
                }
            }
        }
        BaseClass.ResultSet rs = bc.commitRecordsPartial();
        LogUtilityException.logCommitRecords(rs);
    }

    /**
     * @description checks the corresponding event settings in the below order
     * 1. Checks if skip for waitlisting is true(EPBBS-1856)
     * 2. Checks if waitlist registration expiry hours is greater than 0(EPBBS-1888)
     */
    public static BTEventAttendeeDAO processAttendeeWaitlisting(BTEventAttendeeDAO dao) {
        if(dao != null) {
            conference360__Attendee__c attendee = dao.getAttendee();
            conference360__Event__c event = dao.getEvent();
            conference360__Event_Settings__c setting = dao.getEventSetting();

            if(setting.Skip_Pending_for_Waitlisting__c) {
                //if skip pending is enabled, auto-register waitlisted attendee
                attendee.conference360__Registration_Status__c = REG_STATUS_REGISTERED;
            } else {
                //else, update reg status reason, and waitlist expiry fields
                attendee.Registration_status_reason__c = REG_STATUS_REASON_PENDING_WL_REG;
                attendee.Waitlist_Registration_Expiry_1hr__c = calculateWaitlistExpiry(event, setting);
            }
        } else {
            throw new BTAttendeeServicesException('Invalid null parameter');
        }
        return dao;
    }

    /**
     * @description Update registration status to cancelled for the related
     *  attendees of the attendee group when the primary attendee cancels the registration
     * @param attendeeGrpIds : Set of attendee group ids
     */
    public static List<conference360__Attendee__c> processAttendeeCancellation(Set<Id> attendeeGrpIds) {

        List<conference360__Attendee__c> cancelAttList = new List<conference360__Attendee__c>();
        
        if(attendeeGrpIds != null) {
                        
            List<conference360__Attendee__c> attList = new BTAttendeeSelector().selectAttendeesByAttendeeGroupIds(attendeeGrpIds);

            for(conference360__Attendee__c attendee :attList){
                if(attendeeGrpIds.contains(attendee.conference360__Attendee_Group__c) &&
                    !attendee.is_Primary_Registrant__c &&
                    attendee.conference360__Registration_Status__c != REG_STATUS_CANCELLED)
                	{
                    	attendee.conference360__Registration_Status__c = REG_STATUS_CANCELLED;
                        cancelAttList.add(attendee);
                	}
            }
        } else {
            throw new BTAttendeeServicesException('Invalid null parameter');
        }
        return cancelAttList;
    }

    /**
     * @description calculate the attendee's waitlist expiration date :
     *  - default expiry date is CURRENT_DATE + eventSetting.Waitlist_Registration_Expiry__c
     *  - if the resulting date is greated than event start date, use event start date instead
     *  - if eventSetting.Waitlist_Registration_Expiry__c is not set, use the custom setting default
     */
    public static DateTime calculateWaitlistExpiry(conference360__Event__c event, conference360__Event_Settings__c setting) {

        // if waitlist expiry hours from event setting is not greater than 0 it fetches the value from default setting
        Integer waitlistSetting = setting.Waitlist_Registration_Expiry__c != null ? (Integer) setting.Waitlist_Registration_Expiry__c : 0;
        Integer waitlistHours = waitlistSetting > 0 ? (waitlistSetting + 1) : ((Integer) BTAttendeeServices.defaultSettings.Waitlist_Registration_Expiry_hours__c + 1);

        // if final expiry hours is  beyond 24 hours before the event starts then the event start date/time is considered
        Datetime expiry = System.now().addHours(waitlistHours);
        expiry = expiry > event.conference360__Event_Start_Date_Time_GMT__c  ? event.conference360__Event_Start_Date_Time_GMT__c : expiry;
        return expiry;
    }
    
    /**
     * @description update the attendee's Registration status to Canceled and
     * Registration status reason to Waitlisted Expired
     */

    public List<conference360__Attendee__c> expireWaitlistedAttendee(List<conference360__Attendee__c> attlist){
        if(!attlist.isEmpty()){
            for(conference360__Attendee__c att: attlist){
                att.Registration_status_reason__c = BTAttendeeServices.REG_STATUS_REASON_WL_Expired;
            	att.conference360__Registration_Status__c = BTAttendeeServices.REG_STATUS_CANCELLED;
            }
        }
        return attlist;
    }

    /*
     * @description retrieve blackthorn default settings
     */
    private static conference360__Blackthorn_Events_Settings__c getdefaultBlackthornSettings(){
        conference360__Blackthorn_Events_Settings__c defaultSettings = conference360__Blackthorn_Events_Settings__c.getOrgDefaults();
        
        if(defaultSettings.Expire_Waitlist_Attendee_Batch_size__c == null){
            defaultSettings.Expire_Waitlist_Attendee_Batch_size__c = 100;
        }
        
        return defaultSettings;
    }
    
    /**
     * @description create SObject commit order for BaseClass
     */
    public List<Schema.SObjectType> getP360CommitOrder() {
        return new List<Schema.SObjectType> {
            Contact.SObjectType,
            Affiliation__c.SObjectType,
            Address__c.SObjectType,
            Email__c.SObjectType,
            Phone__c.SObjectType,
            Social__c.SObjectType,
            Name__c.SObjectType,
            Contact_Point_Affiliation__c.SObjectType,
            Staged_Prospective_Student__c.SObjectType
        };
    }

    /**
     * @description retrieve Attendee to SPS field mapping
     */
    private static List<BT_Attendee_to_SPS_Mapping__mdt> retrieveSPSMapping() {
        return [SELECT DeveloperName, Attendee_Field__c, SPS_Field__c
                FROM BT_Attendee_to_SPS_Mapping__mdt];
    }

    /**
     * @description shareAttendeeToEventStaff EPBBS-2183 Share newly inserted Attendee with existing event Staff
     * @param attList accepts list of attendees to be processed
     * @param eventIdSet accepts Set of eventIds to be processed
     */
    public void shareAttendeeToEventStaff(List<conference360__Attendee__c> attList,Set<Id> eventIdSet){
        
        if(!attList.isEmpty()){
            sObjectType sObjtype = attList.getsObjectType();
            sObject sObj = sObjtype.newSObject();
            sObjectType shareObj;
            BTStaffServices.shareObjectInfo shareInfo = new BTStaffServices.shareObjectInfo();
            Map<Id,conference360__Event__c> eventChildRecMap = new Map<Id,conference360__Event__c>();
            BTApexSharing btShare = new BTApexSharing();
            
            if(BTStaffServices.shareObjMap.containskey(sObjtype)){
                shareObj = BTStaffServices.shareObjMap.get(sObjtype);
                shareInfo = new BTStaffServices().getShareInfo(sObj);
                String sharingReason = shareInfo.sharingReason;
                String shareAccess = shareInfo.shareAccess;
                eventChildRecMap = new BTStaffservices().getEventChildRecordsMap(eventIdSet);
                
                for(conference360__Attendee__c att: attList){
                    if(eventChildRecMap.containskey(att.conference360__Event__c)){
                        conference360__Event__c eve = eventChildRecMap.get(att.conference360__Event__c);
                        if(eve.conference360__Staff__r!=null && !eve.conference360__Staff__r.isEmpty()) {
                            for(conference360__Staff__c staff: eve.conference360__Staff__r){
                                btShare.setshareRecord(att, shareObj, staff.conference360__User__c, sharingReason, shareAccess);
                            }
                        }
                    }
                }
                btShare.processSharing();
            }
        }
    }

    /**
    * @author Ibrahim Rumi
    * @description Custom validation of attendee Registration.
    * Events configured with check duplicate attendee flag in Event settings will ONLY be checked for duplication
    **/    
    public void validateRegistration(List<conference360__Attendee__c> attendeeList){
        if(!attendeeList.isEmpty()) {
            BTEventAttendeeDAOHelper dao= new BTEventAttendeeDAOHelper(attendeeList);
            List<BTEventAttendeeDAO> eventAttendeeList = dao.generateEventAttendeeDAO();
            Map<Id, Set<Id>> existingcontactWithEveIdMap = dao.getExistingRegisteredContactsforEvents();
            Map<Id, Set<Id>> newContactsWithEveIdMap = new Map<Id, Set<Id>>();
            
         	for(BTEventAttendeeDAO eventAttendee : eventAttendeeList) {
                conference360__Event__c event = eventAttendee.getEvent();
                conference360__Attendee__c attendee = eventAttendee.getAttendee();
                conference360__Event_Settings__c eventSetting = eventAttendee.getEventSetting();
                
                if(eventSetting.Validate_Attendee_Registration__c){

                    //check duplicates within the new records
                    if(newContactsWithEveIdMap.containsKey(event.Id)) {
                        Set<Id> contactIdSet = newContactsWithEveIdMap.get(event.Id);
                        
                        if(contactIdSet.contains(attendee.conference360__Contact__c)){
                            attendee.addError(DUPLICATE_ATTENDEE_ERROR_MESSAGE);
                        }else{
                            contactIdSet.add(attendee.conference360__Contact__c);
                            newContactsWithEveIdMap.put(event.Id, contactIdSet);
                        } 
                    } else {
                        newContactsWithEveIdMap.put(event.Id, new Set<Id> { attendee.conference360__Contact__c });
                    }
                    
                    //compare existing records with database
                    if(existingcontactWithEveIdMap.containskey(event.Id)){
                        Set<Id> existingcontactSet = existingcontactWithEveIdMap.get(event.Id);
                        Set<Id> newContactSet = newContactsWithEveIdMap.get(event.Id);
                        
                        if(existingcontactSet.contains(attendee.conference360__Contact__c) && 
                        newContactSet.contains(attendee.conference360__Contact__c))
                        {
                            attendee.addError(DUPLICATE_ATTENDEE_ERROR_MESSAGE);
                            newContactSet.remove(attendee.conference360__Contact__c);
                        }
                    }
                    
                    //validate event capacity and add error when capacity is reached
                    if(event.conference360__Remaining_Capacity__c != null){
                        
                        Set<Id> updNewContactSet = newContactsWithEveIdMap.get(event.Id);
                        Integer remainingCapacity = 0;
                        remainingCapacity = (Integer)event.conference360__Remaining_Capacity__c;
                        
                        if(updNewContactSet.size() > remainingCapacity){
                            attendee.addError(EVENT_CAPACITY_ERROR_MESSAGE);
                        } 
                    }
                }
            }
        }
    }

    public class BTAttendeeServicesException extends Exception { }
}