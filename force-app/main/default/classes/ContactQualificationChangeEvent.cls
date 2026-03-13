/**
* @author          Ajitabh
* @description     Service class for Contact_Qualification__ChangeEvent sObject
* @revision		8/12/2021 Ken McGuire 
 * Date         Author          Modification
 * 2020-12-07   Ajitabh		   Initial Version
 * 2021-12-08 - Ken McGuire - Full rewrite to better stucture the code and added condition that course must be completed for specified locations in order to be Alumni
 * 2022-09-07 - Inderpal D - Added contact profile fix PENGAGE-2495
*/
public class ContactQualificationChangeEvent {
    public static final string OBTAINED_STATUS_MONASH = 'MONASH-OBTAINED';
    public static final string CONTACT_PROFILE_ALUMNI = 'Alumni';
    public static final string QUALIFICATION_TERTIARY = 'Tertiary Education';
    public static final string INSTITUTION_MONASH = 'MONASH UNIVERSITY';
    public static final List<String> COURSE_MUST_BE_COMPLETED_LOCATIONS = new List<String>{'SAFRICA'};
    public static final string COURSE_ATTEMPT_STATUS_COMPLETED = 'Completed';
    public static final string PICK_LIST_DELIMITER = ';';
    public static final string EMPTY_STRING = '';
    public static final string CHANGE_TYPE_CREATE = 'CREATE';
    public static final string CHANGE_TYPE_UPDATE = 'UPDATE';
    /**
    * @description When a Monash Qualification Course has been completed :-
    * (1) An affiliate record needs to be created for the new graduate (Contact)
    * (2) The new graduate (Contact) profile field needs to be set to Alumni status.
    **/
    public class enableAlumniFlagOnContact implements Triggers.Handler {
        public void run() {
            List<Contact_Qualification__ChangeEvent> newConQualEvent = (List<Contact_Qualification__ChangeEvent>)Trigger.new;  
            // gather up new qualificaitons which were obtained from monash.
            set<id> monashQualificationIds = new set<id>();
            for (Contact_Qualification__ChangeEvent event : newConQualEvent) {
                EventBus.ChangeEventHeader header = event.ChangeEventHeader;
                if ( (header.changetype == CHANGE_TYPE_CREATE && onCreateAlumniLogicRequired(event)) || (header.changetype == CHANGE_TYPE_UPDATE && onChangeAlumniLogicRequired(header.changedfields, event))) {
                    List<Id> recordIds = event.ChangeEventHeader.getRecordIds();
                    monashQualificationIds.addAll(recordIds);
                }
            }
         	if(monashQualificationIds.isEmpty()) return;
            try{
                // update new graduates with Alumni status. New graduates may have to meet graduation requirements.
                ContactQualificationChangeEvent.performNewAlumniLogic(getContactQualifications(monashQualificationIds));
            } catch(Exception exc) {
                LogUtilityException.addLogEvent('ContactQualificationChangeEvent','Contact', exc, 'ContactQualificationChangeEvent.enableAlumniFlagOnContact()');
            }
        }
        /**
        * @description determines whether Alumni Logic should run for a new record.
        * @param event the change event.
        * @return true if new data meets entry critera.
        **/
        private boolean onCreateAlumniLogicRequired(Contact_Qualification__ChangeEvent event) {
          	return event.Obtained_Status__c ==  OBTAINED_STATUS_MONASH 
                && event.Course_Attempt__c != null;
        }
        /**
        * @description determines whether Alumni Logic should run for a chaged record.
        * @param changedFields the fields that have changed.
        * @param event the change event.
        * @return true if new data meets entry critera.
        **/
        private boolean onChangeAlumniLogicRequired(List<String> changedFields, Contact_Qualification__ChangeEvent event) {
        	if(changedfields.contains('Obtained_Status__c') && event.Obtained_Status__c ==  OBTAINED_STATUS_MONASH) return true;
            if(changedfields.contains('Graduation_Date__c') &&  event.Graduation_Date__c != null) return true;
            if(changedfields.contains('Course_Attempt__c') && event.Course_Attempt__c != null) return true;
            return false;
        }
        /**
        * @description retrieve a list of contact qualifications and associated records from the salesforce database.
        * @param ids The contact qualification ids to retrieve.
        * @return a list of contact qualfications and associated records
        **/
        private List<Contact_Qualification__c> getContactQualifications(Set<id> contactQualificationIds) { 
             return [SELECT id, Contact__c,Contact__r.Contact_Profile__c,Obtained_Status__c,Date_Achieved__c, Faculty__c, Graduation_Date__c, Qualification_Type__c, Institution_Name__c,
                     Course_Attempt__c, Course_Attempt__r.Location__c, Course_Attempt__r.Course_Attempt_Status__c
                     FROM Contact_Qualification__c 
                     WHERE id IN: contactQualificationIds];
        }
    }
    /*
     * Performs the logic of filtering for new graduates and assigning them accordingly
     * The below methods could be moved to new business logic class ?
     **/
    public static void performNewAlumniLogic(List<Contact_Qualification__c> newGraduateCandidates) {
        // Filter the list of candidates for those students who have graduated
        List<Contact_Qualification__C> newGraduates = extractGraduates(newGraduateCandidates);
        if(newGraduates.isEmpty()) return;
        // ensure that the new graduates have affiliations
        AffiliationService.createAffiliationforCDCExp(newGraduates, null, 0);
        // ensure that the new graduates have Alumni profile set
        List<Contact> newAlumniList = new List<Contact>();
        Set<Id> s_uniqueAlumni = new Set<Id>();
        for(Contact_Qualification__c nextAlumniCandidate : newGraduates) {
            if (!s_uniqueAlumni.contains(nextAlumniCandidate.Contact__c) && requiresAlumni(nextAlumniCandidate.Contact__r)) {
                s_uniqueAlumni.add(nextAlumniCandidate.Contact__c);
                newAlumniList.add(makeAlumni(nextAlumniCandidate));
            }
        }
        if(newAlumniList.size()>0) {
            update newAlumniList;
        }
	}
    
    /**
    * @description filter Monash-Obtained Contact Qualification records for new graduates .
    * @param monashQualifications : a list of monash contact qualifications.
    * @return a list of contact qualifications that meet graduation criteria 
    **/
    private static List<Contact_Qualification__C>  extractGraduates(List<Contact_Qualification__C> monashQualifications) {
        List<Contact_Qualification__C>  graduates = new List<Contact_Qualification__C>();
        Set<id> courseAttemptsConsidered = new Set<id>(); // More than one Contact Qualification may be linked to a single course attempt, Any one of which may confer Alumni Status.
        for(Contact_Qualification__C nextMonashQualification : monashQualifications) {
            if( meetsAlumniDefinition(nextMonashQualification) && !courseAttemptsConsidered.contains(nextMonashQualification.Course_Attempt__c))
            {
                // Course Completion is sometimes necessary before conferring graduation status.
                // Additional check FOR countries amongst COURSE_MUST_BE_COMPLETED_LOCATIONS only (S AFRICA)
                if(nextMonashQualification.Course_Attempt__c != null && courseMustBeCompleted(nextMonashQualification.Course_Attempt__r)) {
                    if (courseHasBeenCompleted(nextMonashQualification,nextMonashQualification.Course_Attempt__r)) {
                        graduates.add(nextMonashQualification);
                        courseAttemptsConsidered.add(nextMonashQualification.Course_Attempt__c);
                    }
                } else {
                    graduates.add(nextMonashQualification);
                }
            }
        }
        return graduates;
    }
    /**
    * @description create an Alumni contact record from a non-Alumni contact record.
    * @param nonAlumni : The non-Alumni contact to be made into an Alumni contact.
    * @return an Alumni Contact
    **/
    private static Contact makeAlumni(Contact_Qualification__c preAlumni) {
        Contact alumni = new Contact(
            id = preAlumni.Contact__c,
            Contact_Profile__c = addValueToMultiPicklist(preAlumni.Contact__r.Contact_Profile__c,CONTACT_PROFILE_ALUMNI),
            Monash_Corporate__c=true,
            Monash_Community__c=true,
            Giving_to_Monash__c=true,
            Partner_with_Monash__c=true,
            Study_at_Monash__c =true,
            Volunteer_at_Monash__c=true,
            Research_with_Monash__c= true,
            Work_at_Monash__c =true);
        return alumni;
    }
        /**
    * @description appends a value to a multi-picklist field.
    * @param picklist : The multi picklist field
    * @param value : the value to append
    * @return the appended picklist
    **/
    private static string addValueToMultiPicklist(String picklist, string value) {
        if (String.isEmpty(picklist)) picklist = value;
        else if (picklist.right(1) == PICK_LIST_DELIMITER) picklist += value; 
        else picklist += PICK_LIST_DELIMITER + value;
        return picklist;
    }
    /**
    * @description determines whether a course attempt must be completed as a condition for graduation status.
    * @param qualification The contact qualification record with an associated course attempt.
    * @return true if the course attempt must be completed.
    **/
    public static boolean courseMustBeCompleted(Course_Attempt__c courseAttempt) {
        if (String.isEmpty(courseAttempt.Location__c)) return false; 
        // Contacts from specific locations (example South Africa) must complete the course before graduating.
        return COURSE_MUST_BE_COMPLETED_LOCATIONS.contains(courseAttempt.Location__c);
    }
    /**
    * @description determines whether a course attempt has been completed.
    * @param qualification The contact qualification record 
    * @param courseAttempt the associated course attempt.
    * @return true if the course has been completed.
    **/
    private static boolean courseHasBeenCompleted(Contact_Qualification__c qualification, Course_Attempt__c courseAttempt) {
        if (qualification.Graduation_Date__c == null) return false;
        return courseAttempt.Course_Attempt_Status__c == COURSE_ATTEMPT_STATUS_COMPLETED;
    }
    /**
    * @description determines whether an Alumni Candidate is already an Alumni.
    * @param candidate - the contact to determine if already Alumni.
    * @return true if the Candidate is already an Alumni.
    **/
    private static boolean requiresAlumni(Contact candidate) {
        if (candidate == null) return false;
        return (String.isEmpty(candidate.Contact_Profile__c) || !candidate.Contact_Profile__c.contains(CONTACT_PROFILE_ALUMNI)); 
    }

     /**
    * @description determines whether an Alumni Candidate has all the requirements
    * @param candidate - the contact to verify
    * @return true if the Candidate meets alumni definition
    **/
    private static boolean meetsAlumniDefinition(Contact_Qualification__c qualification){
        if(qualification.Qualification_Type__c == QUALIFICATION_TERTIARY && qualification.Obtained_Status__c ==  OBTAINED_STATUS_MONASH && qualification.Institution_Name__c == INSTITUTION_MONASH && qualification.Date_Achieved__c != null){
            return true;
        }
        return false;

    }
}