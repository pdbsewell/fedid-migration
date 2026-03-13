/**
 * @description       : CDC Course Attempt Trigger Handler
 * @author            : Martin Cadman
 * @group             : Trigger Handler
 * @last modified on  : 2021-11-10
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Date         Author          Modification
 * 2020-12-07   Martin Cadman   Full rewrite to better stucture the code
 * 2021-03-22   Stefan Scheit   EPCP-1107: Fix 'is student' recalculation post the transition period of the course attempt completion date.
 *                              Refactored CourseAttemptChangeEventService.EvaluateIsStudent to work off contact ids
 * 2021-11-10   Stefan Scheit   EPCP-1815: Changed 'is student' recalcuation by moving criteria into SOQL instead of precedural evaluation
 * 2021-12-14 - Ken McGuire     Added new graduate logic
 * 2022-09-07 - Inderpal D      Added contact profile fix PENGAGE-2495
 * 2023-03-07 - Martin C        Updated cdcACPLookup to clear the SCA lookup on existing ACPs when new ACPs take precedence
**/
public class CourseAttemptChangeEventService {

/*
    * @description Generic CDC trigger handler
    *
    * @author Martin Cadman
    * @date 2020-12-07
    *
    * @revision
    *   2020-12-07 - M.Cadman - All CDC operations require Interrogating the changeEvent
    *   2021-03-22 - Stefan Scheit - Changed invocation of IsStudent logic
    * 	2021-12-14 - Ken McGuire - Added new graduate logic
    */
    public class cdcSCAHandler extends TriggerAbstract {

        public override void execute() {
            Set<String> crsAttIds = New Set<String>();
            Set<String> newGraduateCandidateIds = new Set<String>();
            try {
                for (Course_Attempt__ChangeEvent event : (List<Course_Attempt__ChangeEvent>)Trigger.new) {
                    EventBus.ChangeEventHeader header = event.ChangeEventHeader;
                    crsAttIds.addAll(event.ChangeEventHeader.getRecordIds());
 					if (header.changetype == ContactQualificationChangeEvent.CHANGE_TYPE_UPDATE && onChangeAlumniLogicRequired(header.changedfields, event)){
                        newGraduateCandidateIds.addAll(event.ChangeEventHeader.getRecordIds());
                    } 
                }
                if (crsAttIds.size()==0) return;
                System.debug(loggingLevel.FINE,crsAttIds.size() + ' Course Attempt IDs identified for processing');
                // process ACP lookups
                new CourseAttemptChangeEventService.cdcACPLookup().run(crsAttIds);
                // process 'is student' flag (on Contact)
                // TODO: this can be replaced once Change Data Capture supports fields to be always added to events (Contact__c is required in this instance)
                Set<Id> contactIdSet = this.getContactIds(crsAttIds);
                new CourseAttemptChangeEventService.EvaluateIsStudent().publishEvents(contactIdSet);
                // process course attempt roll-up to Contact
                new CourseAttemptChangeEventService.cdcSCARollup().run(crsAttIds);
                // process alumni (no degree) calculations on contact
                AffiliationService.performAlumniNoDegreeLogic(crsAttIDs);
                // check for new alumni
                if (newGraduateCandidateIds.size()>0) ContactQualificationChangeEvent.performNewAlumniLogic(getContactQualifications(newGraduateCandidateIds));
            } catch (Exception ex) {
                LogUtilityException.logException(ex);
            }
        }
        
        /**
        * @description determines if changes to the Course Attempt requires evaluation of Studient Alumni Logic.
        * @param changedFields the fields that have changed.
        * @param event the change event.
        * @return true if new data meets entry critera.
        **/
        private boolean onChangeAlumniLogicRequired(List<String> changedFields, Course_Attempt__ChangeEvent event) {
            // If the Course Attempt Status has changed to "Completed" then re-evaluate if the Student (Contact) Qualifies for Alumni Status
        	if(changedfields.contains('Course_Attempt_Status__c') && event.Course_Attempt_Status__c ==  ContactQualificationChangeEvent.COURSE_ATTEMPT_STATUS_COMPLETED) return true;
            // If the course no longer requires "Completion" then re-evaluate if the Student(Contact) Qualifies for Alumni Status
            if(changedfields.contains('Location__c') && ContactQualificationChangeEvent.courseMustBeCompleted(new Course_Attempt__c(Location__c = event.Location__c))) return true;
            return false;
        }
        
        /**
        * @description retrieve a list of contact qualifications and associated records from the salesforce database.
        * @param ids The course attempt ids to retrieve.
        * @return a list of contact qualfications and associated records
        **/
        private List<Contact_Qualification__c> getContactQualifications(Set<String> courseAttemptIds) {
             return [SELECT id, Contact__c,Contact__r.Contact_Profile__c,Obtained_Status__c,Date_Achieved__c, Faculty__c, Graduation_Date__c,
                     Course_Attempt__c, Course_Attempt__r.Location__c, Course_Attempt__r.Course_Attempt_Status__c, Qualification_Type__c, Institution_Name__c
                     FROM Contact_Qualification__c 
                     WHERE Course_Attempt__c IN: courseAttemptIds];
        }
        /**
         * Method to return the Contact ids from the input set of course attempt ids.
        * @param courseAttemptIds as Set of course attempt ids
        * @returns a set of contact ids from the input course attempt ids
        */
        private Set<Id> getContactIds(Set<String> courseAttemptIds) {
            Set<Id> contactIdSet = new Set<Id>();
            // query contact ids from course attempts, this includes (just) deleted course attempts (from the change data capture events)
            for(Course_Attempt__c ca : [SELECT Contact__c FROM Course_Attempt__c WHERE Id IN :courseAttemptIds ALL ROWS]) {
                contactIdSet.add(ca.Contact__c);
            }
            return contactIdSet;
        }
    }
    
/*
    * @description - Update the ACP related to the SCA, linking the two records
    *
    * @author Martin Cadman
    * @date 2020-12-07
    *
    * @revision
    *   2020-12-07 - Martin C
    *   2023-03-07 - Martin C - As student reapply for the same course, the ACP lookup on their SCA for that course is changed. This lead to multiple ACP
    *                           referencing 1 SCA, which caused issues for Marcket Cloud (enrolment concierge) journeys.
    *                           A change has been added to remove the old reference so we have a strict 1:1
    */
    public class cdcACPLookup {

        public void run(Set<String> crsAttIds) {
            Map<Id,Id> ACPSCAMap = new Map<Id,Id>();
            Set<Application_Course_Preference__c> sACP = new Set<Application_Course_Preference__c>();
            
            try {
                if(Trigger.isDelete) {
                    return; // no action required, avoid null pointer for delete trigger
                } else {
                    // Uses the lookup from the SCA to the ACP, which is populated in ibdCourseAttemptServices, to establish the correct relationship
                    for (Course_Attempt__c aSCA : [select id, application_course_preference__c, contact__c from course_attempt__c where id in :crsAttIds]) {
                        if (aSCA.application_course_preference__c != null){
                            ACPSCAMap.put(aSCA.application_course_preference__c, aSCA.id);
                        }
                    }
                    
                    if (!ACPSCAMap.isEmpty()) {
                        // This loop now traverses all ACP that are referenced from the SCA and reference the SCA
                        for (Application_Course_Preference__c aACP : [select id, name, course_attempt__c, course_attempt__r.application_course_preference__c from Application_Course_Preference__c 
                                                                       where id in :ACPSCAMap.keySet()
                                                                          or course_attempt__c in :crsAttIds])  
                        { 
                            if (ACPSCAMap.containsKey(aACP.id)) {
                                if (aACP.course_attempt__c == null ) { // just to limit unnecessary updates
                                    aACP.course_attempt__c = ACPSCAMap.get(aACP.id);
                                    sACP.add(aACP);                                                                          
                                }
                            } else { // not the ACP being referenced on the SCA, so remove the lookup value
								if (aACP.course_attempt__c != null) {
                                    aACP.course_attempt__c = null;                          
                                    sACP.add(aACP);						                        
                                }
                            }
                        }
                                                                         
						if (sACP.size() > 0) {
                            list<Application_Course_Preference__c> lACP = new list<Application_Course_Preference__c>(sACP);
                            Database.SaveResult[] srList = Database.update(lACP, false);
                            for(Integer i = 0; i< srList.size(); i++) {              
                                Database.SaveResult sr = srList[i];
                                if(!sr.isSuccess()) {
                                    for(Database.Error err : sr.getErrors()) {
                                        LogUtilityException.logExceptionMSG('Database update error',  'CourseAttemptChangeEventService.cdcACPLookup ' + lACP[i].id, err.getMessage());
                                    }
                                }
                            }
                        }
                    }
                }
            } catch (Exception ex){
                LogUtilityException.logException(ex, 'CourseAttemptChangeEventService.cdcACPLookup');
            }
        }
    }

/*
    * @description - Update primary SCA fields on the Contact
    *
    * @author Martin Cadman
    * @date 2020-12-07
    *
    * @revision
    *   2020-12-07 - M.Cadman - Disable all contact triggers prior to updating the Contact
    *   2020-12-07 - M.Cadman - Introduced async retry on database errors
    */
    public class cdcSCARollup implements IPlatformEventInvocable {
        @TestVisible
        private Map<String, Integer> IDRetryCountMap = new Map<String, Integer>();
        @TestVisible
        private List<Id> contactIDList = new list<Id>();

        private String payloadKey = 'keyCourseAttemptIdRetryCountMap';
        private String processName = 'CourseAttemptChangeEventService.cdcSCARollup';

        public void execute(List<AsyncProcessPayload> payload) {
            try {
                initialize(payload);
                run(contactIDList, IDRetryCountMap);
            } catch(Exception e) {
                LogUtilityException.logException(e, contactIDList);
            } 
        }
        
        // Executed from the intial trigger call
        public void run(Set<String> crsAttIDs) {
            try {
                // Get all contacts from the changed course attempts
                // Note the ALL ROWS to ensure you get the contacts of deleted course attempts - sadly, also gets deleted Contacts, which causes a rollup error when contacts are removed
                // Limit to last 5 days to force an efficient query plan (high volume platform events are only kept for 72 hours)
                Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id 
                                                                    FROM Contact
                                                                    WHERE Contact.isdeleted = false
                                                                    AND Id IN (SELECT contact__c 
                                                                                FROM course_attempt__c 
                                                                                WHERE SystemModStamp = LAST_N_DAYS:5 AND Id IN :crsAttIDs) ALL ROWS]);
                if (!contactMap.isEmpty()) {
                    AsyncProcessPayload payload = null;
                    List<Course_Attempt_Event__e> apList = new List<Course_Attempt_Event__e>();
                    for (Id conID: contactMap.keySet()) {
                        payload = new AsyncProcessPayload();
                        payload.put (payloadKey, new Map<String, Integer> {conID => 1});
                        apList.add(new Course_Attempt_Event__e(
                            Process_Name__c = processName,
                            Parameter__c = payload.serialize()
                        ));
                    }
                    //Always use the platform event
                    if (!apList.isEmpty()) {
                        Eventbus.publish(apList);
                    }
                }
            } catch (Exception ex) {
                LogUtilityException.logException(ex, processName);
            }                
        }

        // Executed directly from async event logic
        public void run(List<Id> contactList, Map<String, Integer> IDRetryCountMap) {
            Map<ID, Course_Attempt__c> sca = new Map<ID, Course_Attempt__c>();
            List<Contact> contactsToUpdate = new List<Contact>();
            try {
                // Populate the map with an ordered list of course attempts
                // Deleted on source records are filtered out
                for (Course_Attempt__c ca : [SELECT Id, Contact__r.Person_ID__c, Contact__c, Attendance_Mode__c, Attendance_Type__c, Commencement_Date__c,
                                                    Course_Faculty_Code__c, Course_Title__c,Course_Attempt_Status__c, Course_Code__c,
                                                Course_Sub_Level__c, Course_Managing_Faculty__c, Location__c,Contact__r.Id, Contact__r.isdeleted, Course_Level__c
                                            FROM Course_Attempt__c 
                                            WHERE Contact__r.Id IN :contactList
                                                AND deleted_in_source__c = false
                                            ORDER BY Contact__c, Course_Attempt_Status_Ranking__c ASC, Course_Sub_Level__c ASC nulls last, SystemModStamp DESC]) {
                    // Trust in SOQL - the first record for each Contact is the primary course attempt
                    if (!sca.ContainsKey(ca.Contact__c)) {
                        sca.put(ca.Contact__c, ca);                                        
                    }
                } 

                // For all the Contacts that were identified, update the field
                for (ID i : new Set<id>(contactList)) {
                    if (sca.ContainsKey(i)) {
                        contactsToUpdate.add(new Contact(Id = i,
                        Course_Code__c = sca.get(i).Course_Code__c,
                        Course_Type_Group__c = sca.get(i).Course_Level__c,
                        Course_Name__c = sca.get(i).Course_Title__c,
                        Responsible_org_unit_code_description__c = sca.get(i).Course_Faculty_Code__c,
                        Faculty__c = sca.get(i).Course_Managing_Faculty__c,
                        Campus__c = sca.get(i).Location__c,
                        Commencement_Date__c = sca.get(i).Commencement_Date__c,
                        Attendance_Mode__c = sca.get(i).Attendance_Mode__c,
                        Course_Attempt_Status__c = sca.get(i).Course_Attempt_Status__c,
                        // Formula field support
                        primary_course_attempt__c = sca.get(i).id
                        ));
                    } else {
                        contactsToUpdate.add(new Contact(Id = i,
                        Course_Code__c = '',
                        Course_Type_Group__c = '',
                        Course_Name__c = '',
                        Responsible_org_unit_code_description__c = '',
                        Faculty__c = '',
                        Campus__c = '',
                        Commencement_Date__c = null,
                        Attendance_Mode__c = '',
                        Course_Attempt_Status__c = '',
                        // Formula field support
                        primary_course_attempt__c = null
                        ));
                    }
                }
                
                if (contactsToUpdate.size() > 0) {
                    AsyncProcessPayload payload = null;
                    List<Course_Attempt_Event__e> apList = new List<Course_Attempt_Event__e>();
                    Integer retryCount;
                    
                    // No fields being updated in the Contact require any further actions to take place on the Contact
                    triggercommon.disableTrigger('Contact');
                    Database.SaveResult [] saveResults = Database.update(contactsToUpdate, false);
                    triggercommon.enableTrigger('Contact');
                    Database.SaveResult sr = null;
                    // Iterate on Database.SaveResult
                    for (Integer i=0; i < saveResults.size(); i++) {
                        retryCount = 0;
                        sr = saveResults[i];
                        // Allow test class to simulate a retry
                        if (!sr.isSuccess() || (Test.isRunningTest() && retryCount < 2)) {
    
                            if (IDRetryCountMap != null && IDRetryCountMap.containsKey(contactsToUpdate.get(i).id)) {
                                retryCount = IDRetryCountMap.get(contactsToUpdate.get(i).id);
                            }
                            retryCount = (retryCount != null) ? retryCount + 1 : 1;
                            if (retryCount < 5) {
                                payload = new AsyncProcessPayload();
                                payload.put (payloadKey, new Map<String, Integer> {contactsToUpdate.get(i).id => retryCount});
                                apList.add(new Course_Attempt_Event__e(
                                    Process_Name__c = processName,
                                    Parameter__c = payload.serialize()
                                ));
                            } else {
                                // If max retry has reached, add Exception Log
                                for (Database.Error err : sr.getErrors()) {
                                    LogUtilityException.addLogEvent('Contact', contactsToUpdate.get(i).id, err, processName + ' - Unable to rollupSCA details');
                                }
                            }
                        }
                    }
                    
                    if (!apList.isEmpty()) {
                        Eventbus.publish(apList);
                    }
                }

            } catch (Exception ex) {
                LogUtilityException.logException(ex, processName);
            } finally {
                LogUtilityException.publishAll();
                triggercommon.enableTrigger('Contact');
            }
        }
        
        
        /*
        * Initialize process by extracting the method parameters from the platform event payload specific to this class
        */
        private void initialize(List<AsyncProcessPayload> payloads) {
            if(payloads != null) {
                for(AsyncProcessPayload payload : payloads) {
                    Map<String, Object> objMap = (Map<String, Object>) payload.get(payloadKey);
                    for (String key : objMap.keySet()) {
                        contactIDList.add(key);
                        IDRetryCountMap.put(key, Integer.valueOf(objMap.get(key)));
                    }
                }
            }
        }
    }
    
    /*
    * @description - Toggle the 'is Student' indicator on the Contact records based on the details of the course attempt records linked to the Contact.
    * If any of below is true, the contact is considered a student:
    * - Any course attempt with a status of "enrolled" OR "intermit" - student is actively studying
    * - Any course attempt with a status of "inactive" (and at least 1 active or completed unit attempt) means the student has (only) paused their studies (and has commenced/completed units in the past)
    * - Any course attempt with a status of "completed" AND the "Course_Requirements_Completion_Date" > (today - transition period) - that means the student recently completed their studies
    *
    * @author Stefan Scheit
    * @date 2021-03-18
    */
    public class EvaluateIsStudent implements IPlatformEventInvocable {
        // parameters for the platform event payload
        public final String PAYLOAD_KEY = 'keyContactIdRetryCountMap';
        public final String PROCESS_NAME = String.valueOf(CourseAttemptChangeEventService.EvaluateIsStudent.class);
        
        @TestVisible // map of contact ids with their retry count
        private Map<String, Integer> contactIdRetryCountMap = new Map<String, Integer>();
        
        /**
         * Method implementing the IPlatformEventInvocable interface. This is invoked with the list of platform events.
        */
        public void execute(List<AsyncProcessPayload> payload) {
            try {
                // maps event input into contactIdRetryCountMap
                initialize(payload);
                if(this.contactIdRetryCountMap==null || this.contactIdRetryCountMap.isEmpty()) {
                    return;
                }

                // hold contact ids that qualify as students
                Set<String> determinedAsStudentSet = new Set<String>();

                // select all course attempts that qualify a contact as a student, a similar query exists in 
                for (Course_Attempt__c courseAttempt : [SELECT Contact__c FROM Course_Attempt__c WHERE
                                                            Contact__c IN :this.contactIdRetryCountMap.keySet()
                                                            AND deleted_in_source__c = false
                                                            AND (
                                                                Course_Attempt_Status__c IN ('Enrolled', 'Intermit')
                                                                OR (Course_Attempt_Status__c = 'Inactive' AND (Number_of_Active_Unit_Attempts__c > 0 OR Number_of_Completed_Unit_Attempt__c > 0))
                                                                OR (Course_Attempt_Status__c = 'Completed' AND Course_Requirements_Completion_Date__c > :CourseAttemptServices.IS_STUDENT_TRANSITION_DATE)
                                                            )
                                                        ]) {
                    determinedAsStudentSet.add(courseAttempt.Contact__c);
                }
    
                // evaluate whether a contact id from the event/payload qualifies as student
                List<Contact> contactsToUpdate = new List<Contact>();
                Boolean bIsStudent;
                for (String contactId : this.contactIdRetryCountMap.keySet()) {
                    bIsStudent = (determinedAsStudentSet.contains(contactId)) ? true : false;
                    contactsToUpdate.add(new Contact(Id = contactId, Is_Student__c = bIsStudent));
                }
    
                // update contact records (or increase retry counter in case of errors)
                if (!contactsToUpdate.isEmpty()) {
                    AsyncProcessPayload republishPayload = null;
                    List<Course_Attempt_Event__e> republishList = new List<Course_Attempt_Event__e>();
                    Integer retryCount;
                    
                    Database.SaveResult[] saveResults = Database.update(contactsToUpdate, false);
                    Database.SaveResult sr = null;
                    // Iterate on Database.SaveResult
                    for (Integer i=0; i<saveResults.size(); i++) {
                        retryCount = 0;
                        sr = saveResults[i];
                        // Allow test class to simulate a retry
                        if (!sr.isSuccess() || (Test.isRunningTest() && retryCount < 2)) {
                            if (this.contactIdRetryCountMap.containsKey(contactsToUpdate[i].Id)) {
                                retryCount = this.contactIdRetryCountMap.get(contactsToUpdate[i].Id);
                            }
                            retryCount = (retryCount != null) ? retryCount+1 : 1;
                            if (retryCount < 5) {
                                republishPayload = new AsyncProcessPayload();
                                republishPayload.put (PAYLOAD_KEY, new Map<String, Integer> {contactsToUpdate[i].Id => retryCount});
                                republishList.add(new Course_Attempt_Event__e(
                                    Process_Name__c = PROCESS_NAME,
                                    Parameter__c = republishPayload.serialize()
                                ));
                            } else {
                                // If max retry has reached, add Exception Log
                                for (Database.Error err : sr.getErrors()) {
                                    LogUtilityException.addLogEvent('Contact', contactsToUpdate[i].id, err, PROCESS_NAME + ' - Unable to update isStudent indicator');
                                }
                            }
                        }
                    }
                    if (!republishList.isEmpty()) {
                        Eventbus.publish(republishList);
                    }
                }
            } catch (Exception ex){
                LogUtilityException.logException(ex, 'CourseAttemptChangeEventService');
            } finally {
                LogUtilityException.publishAll();
            }
        }
        
        /**
        * @description Publishes platform events to evaluate the 'is student' flag for the set of contact ids.
        * @param contactIdSet set of contact ids
        */
        public void publishEvents(Set<Id> contactIdSet) {
            try {
                // build event payload (for async processing) for each contact 
                AsyncProcessPayload payload = null;
                List<Course_Attempt_Event__e> apList = new List<Course_Attempt_Event__e>();
                for(Id contactId : contactIdSet) {
                    payload = new AsyncProcessPayload();
                    payload.put (PAYLOAD_KEY, new Map<String, Integer> {contactId => 1}); // put contact id and retry count of 1
                    apList.add(new Course_Attempt_Event__e(
                        Process_Name__c = PROCESS_NAME,
                        Parameter__c = payload.serialize()
                    ));
                }
                // publish platform event
                if(!apList.isEmpty()) {
                    Eventbus.publish(apList);
                    //System.debug(loggingLevel.FINE, PROCESS_NAME + ' submitting ' + apList.size() + ' contact ids');
                }
            } catch (Exception ex) {
                LogUtilityException.logException(ex, PROCESS_NAME);
            }
        }

        /**
         * @description initialize process by extracting the method parameters from the platform event payload
        */
        private void initialize(List<AsyncProcessPayload> payloads) {
            if(payloads != null) {
                Map<String, Object> objMap = null;
                for(AsyncProcessPayload payload : payloads) {
                    objMap = (Map<String, Object>) payload.get(PAYLOAD_KEY);
                    for (String key : objMap.keySet()) {
                        // get contact id and the retry count for it
                        this.contactIdRetryCountMap.put(key, Integer.valueOf(objMap.get(key)));
                    }
                }
            }
        }
    }
}