/**
 * @author Trent De Laney
 * @author Martin Cadman
 * @author Shalini Mendu
 * @date April 2020
 * @description Inbound services class used for processing ACP platform events from external systems.</br>
 * @revision 
 * Martin Cadman - May 2020 Updated logging details and other cosmetic changes
 * Martin Cadman - June 2020 Added support for deferrals 
 * Martin Cadman - July 2020 Added submitted date default for new Appplications
 * Martin Cadman - July 2020 Calculate the Application and ACP owner depending on community access **REMOVED**
 * Martin Cadman - August 2020 Unit Set Description logic updated
 * Martin Cadman - August 2020 Submission Date logic added
 * Martin Cadman - August 2020 Citizenship_Country__c mapping added
 * Martin Cadman - September 2020 Added exception handler and logging to stop a non-seletive query from rejecting the entire batch
 * Martin Cadman - Feburary 2021 Added name build function
 * 17.04.2023 Ken McGuire: Changed Comments__c (255 characters) to LongComments__c (4000 characters)
 * 22.06.2023 Martin Cadman - Added logic to allow applications with a Hybrid source system to have an affiliation created
 * 28.09.2023 Martin Cadman - Revert Hybrid to Callista when updated
 * 26.04.2024 Martin Cadman - Included logger entries - including using the triggercontext to pass the logger transaction id between event retries
 * 11.09.2024 Martin Cadman - Added offer_round mapping
 */

public class IbdACPServicesV2 {
    private static final String DEFSOURCESYS = 'Callista';
    private static final String HYBSOURCESYS = 'Hybrid';

    // If set too high there is a risk of heap or cpu errors when under load as the numbr of records being processed by each iteration will increase.
    private static final Integer MAXRETRIES = 3; 

    private static final String REFTAG   = 'Missing Reference Data';
    private static final String SCENARIO = 'Inbound ACP';
    
	// Different log message formats    
    private static String msgfmt0 = '{0} {1}';
    private static String msgfmt1 = '{0} - {1}';
    private static String msgfmt2 = '{0}\r\r{1}';
    private static String msgfmt3 = '{0} - {1}\r\r{2}';
    
    /**
     * @description Exception to allow an eventbus retry to be bubbled up
     */ 
    public class MyRetryException extends Exception {}

    /**
     * @author Trent De Laney
     * @date March 2020
     * @description Internal wrapper class for course offerings. Possible offerings are loaded into memory, constrained by records in the batch. Individual ACP are then compared
     * to the in-memory data to find a match.
     * Requires 1 course offering query per batch processed.
     * Heap usage can max out for large batches, hence the MAXRETRIES is set low.
     */
    public class CourseOfferingIndexWrapper{
        private String CourseCode;
        private Decimal CourseVersion;
        private String AdmissionCalendarType;
        private String LocationCode;
        private String AttendanceType;
        private String AttendanceMode;
        private Decimal AcademicSequenceNumber;
        private Decimal AdmissionSequenceNumber;
        private String AdmissionCategory;
        private String CitizenshipType;
        private String UnitSetCode;
        private Decimal UnitSetVersion;
        
        public CourseOfferingIndexWrapper(String courseCode, String admissionCalendarType, String locationCode, String attendanceType,
                String attendanceMode, Decimal academicSequenceNumber, Decimal admissionSequenceNumber, String admissionCategory, String citizenshipType,
                Decimal CourseVersion, String UnitSetCode, Decimal UnitSetVersion ){
            this.CourseCode = courseCode;
            this.AdmissionCalendarType = admissionCalendarType;
            this.LocationCode = locationCode;
            this.AttendanceType = attendanceType;
            this.AttendanceMode = attendanceMode;
            this.AcademicSequenceNumber = academicSequenceNumber;
            this.AdmissionSequenceNumber = admissionSequenceNumber;
            this.AdmissionCategory = admissionCategory;
            this.CitizenshipType = citizenshipType;
            this.CourseVersion = CourseVersion;
            this.UnitSetCode = UnitSetCode;
            this.UnitSetVersion = UnitSetVersion;
        }

        public CourseOfferingIndexWrapper(Application_Course_Preference__c aACP, String resStatus){
            this.CourseCode = aACP.Course_Code__c;
            this.AdmissionCalendarType = aACP.Override_Admission_Calendar_Type__c==null?aACP.Admission_Calendar_Type__c:aACP.Override_Admission_Calendar_Type__c;
            this.LocationCode = aACP.Location_Code__c;
            this.AttendanceType = aACP.Attendance_Type__c;
            this.AttendanceMode = aACP.Attendance_Mode__c;
            this.AcademicSequenceNumber = aACP.Override_Academic_CI_Sequence__c==null?aACP.Academic_CI_Sequence_Number__c:aACP.Override_Academic_CI_Sequence__c;
            this.AdmissionSequenceNumber = aACP.Override_Admission_CI_Sequence__c==null?aACP.Admission_CI_Sequence_Number__c:aACP.Override_Admission_CI_Sequence__c;
            this.AdmissionCategory = aACP.Admission_Category__c;
            this.CitizenshipType = resStatus;
            this.CourseVersion = aACP.Course_Version_Number__c;
            this.UnitSetCode = aACP.Unit_Set_Code__c;
            this.UnitSetVersion = aACP.Unit_Set_Version__c;
        }
        
        public Boolean equals(Object obj){
            if (obj instanceof CourseOfferingIndexWrapper){
                CourseOfferingIndexWrapper compare = (CourseOfferingIndexWrapper) obj;
                if(
                        this.CourseCode == compare.CourseCode &&
                        this.AdmissionCalendarType == compare.AdmissionCalendarType &&
                        this.LocationCode == compare.LocationCode &&
                        this.AttendanceType == compare.AttendanceType &&
                        this.AttendanceMode == compare.AttendanceMode &&
                        this.AcademicSequenceNumber == compare.AcademicSequenceNumber &&
                        this.AdmissionSequenceNumber == compare.AdmissionSequenceNumber &&
                        this.AdmissionCategory == compare.AdmissionCategory &&
                        compare.CitizenshipType.contains(this.CitizenshipType) &&
                        this.CourseVersion == compare.CourseVersion &&
                        this.UnitSetCode == compare.UnitSetCode && 
                        this.UnitSetVersion == compare.UnitSetVersion
                ){
                    return true;
                }
            }
            return false;
        }

        public Integer hashCode(){
            return this.CourseCode.hashCode() + this.CourseVersion.toPlainString().hashCode() + this.AdmissionCategory.hashCode() + this.AdmissionCalendarType.hashCode() + this.LocationCode.hashCode() + this.AttendanceType.hashCode() +
                    this.AttendanceMode.hashCode() + this.CitizenshipType.hashCode() + (this.UnitSetCode==null?0:this.UnitSetCode.hashCode()) +(this.UnitSetVersion==null?0:this.UnitSetVersion.toPlainString().hashCode());
        }
    }
    
   /*
    * @description The EventHandler called by the trigger framework
    */
    public class EventHandler extends TriggerAbstract {
        
        // Global containers populated in the process method
        private Map<String, IbdACP__e> mapADMACP = new Map<String, IbdACP__e>();
        private Map<String, IbdACP__e> mapAPP = new Map<String, IbdACP__e>();
        private Set<String> personIDs = new Set<String>();
        private Set<String> applicantIDs = new Set<String>();
        private Set<String> countryCodes = new Set<String>();
        
        /**
         * @description Helper method to build an ADM unique key
         * @param iEvent The event being processed
         * @return A key created from event fields
         */
        private String CreateAdmKeyFromEvent(IbdACP__e iEvent) {
            return iEvent.PERSON_ID__c + '-' + iEvent.Admission_Application_Number__c + '-' + iEvent.Course_Code__c + '-' + iEvent.Application_Sequence_Number__c;
        }
        
        /**
         * @description Helper method to build an AP unique key
         * @param iEvent The event being processed
         * @return A key created from event fields
         */
        private String CreateApKeyFromEvent(IbdACP__e iEvent) {
            return iEvent.Callista_Application_Id__c != null ? iEvent.Callista_Application_Id__c + '-' + iEvent.Portal_Sequence_Number__c : null;
        }
        
        /**
         * @description Helper method to build an Application unique key
         * @param iEvent The event being processed
         * @return A key created from event fields
         */
        private String CreateApplicationKeyFromEvent(IbdACP__e iEvent) {
            return iEvent.Callista_Application_Id__c != null ? iEvent.Callista_Application_Id__c : iEvent.Callista_Student_ID_MIX__c + '-' + iEvent.Admission_Application_Number__c;
        }
        
        /**
         * @description Helper method to return a map of all existing ACP records found, matching on the ADM keys in the batch
         * The ADM unique key is the map key, the ACP is the value.
         * The fact that an existing ACP has an ADM key indicates that we have received it from Callista in the past.
         * @return A map of an ACP unique key and the acp record
         */
        private Map<String, Application_Course_Preference__c> getExistingACP() {
            Map<String, Application_Course_Preference__c> eACPM = new MAP<String, Application_Course_Preference__c>();
            
            List<Application_Course_Preference__c> eACPL = new list<Application_Course_Preference__c>(
                [SELECT Id, Callista_Unique_Key_ADM__c
                 FROM Application_Course_Preference__c
                 WHERE Callista_Unique_Key_ADM__c IN :mapADMACP.keySet()]
            );
            
            for (Application_Course_Preference__c a : eACPL){
                eACPM.put(a.Callista_Unique_Key_ADM__c, a);
            }
            
            return eACPM;
        }

        /**
         * @description Helper method to return a map of all existing applications records found, matching on the callista application id
         * @return A map of applications ids and their application record
         */
        private Map<String, Application__c> getExistingAPP() {
            Map<String, Application__c> eAPPM = new MAP<String, Application__c>();
            
            List<Application__c> eAPPL = new list<Application__c>(
                [SELECT Id, Callista_Application_ID__c, applicant__c, Source_System__c, residency_status__c, submitted_date__c, createdDate
                 FROM Application__c
                 WHERE Callista_Application_ID__c IN :mapAPP.keySet()]
            );
            
            for (Application__c a : eAPPL){
                eAPPM.put(a.Callista_Application_ID__c, a);
            }
            return eAPPM;
        }
        
       /**
        * @description Helper method to return a contact ID for the event being processed
        * @param iEvent The event being processed
        * @param applicantMap A map of applicants/persons and their contact ids
        * @return The contact id for the event being processed
        */
        private ID getContactID(ibdACP__e iEvent, Map<String,ID> applicantMap) {
            ID contactID;
            
            if (!applicantMap.isEmpty()) {
                if (applicantMap.containsKey('A' + iEvent.Callista_applicant_ID__c)) {
                    contactID = applicantMap.get('A' + iEvent.Callista_applicant_ID__c); // Prefixed in case applicant and person ids ever cross over
                }
                
                if (contactID == null){
                    if (applicantMap.containsKey('P' + iEvent.Person_ID__c)) {
                        contactID = applicantMap.get('P' + iEvent.Person_ID__c);
                    }
                }
            }
            return contactID;
        }
        
       /*
        * @description Populate a map that contains all 'A'pplicant ids and 'P'erson CRM ids for the applicant ids in the batch
        * @param aIDs A set pf applicant ids
        * @param pIDs A set of person ids
        * @return A map of contact identifiers and contact is
        */
        private Map<String,ID> getApplicants(Set<String> aIDs, Set<String> pIDs) {
            Map<String,ID> idContact = new Map<String,ID>();
                    
            if (aIDs.size() > 0 ) {
                for (Application__c app :[select callista_applicant_id__c, applicant__c from Application__c where callista_applicant_id__c in :aIDs]) {
                    idContact.put('A' + app.callista_applicant_id__c, app.applicant__c);
                }
            }
            
            if (pIDs.size() > 0) {
                for (Contact con :[select id, person_id__c from contact where person_id__c in :pIDs]) {
                    idContact.put('P' + con.person_id__c, con.id);
                }
            }
            
            return idContact;
        }
        
        /*
        * @description Helper method get a map of callista country codes and country attrobute ids
        * @param cCodes The lookup set of callista country codes
        * @return A map for callista country codes and country attribute ids
		*/
        private Map<String,id> getCountry(Set<String> cCodes){
            Map<String,id> ccMap = new Map<String,id>();
            
            if (cCodes.size() > 0) {
                for (country_attribute__c c : [select id, callista_code__c from country_attribute__c where callista_code__c in :cCodes]){
                    ccMap.put(c.callista_code__c, c.id);
                }
            }
            
            return ccMap;
        }
        
 
       /*
        * @description Helper class to format pseudo SOQL statment for logging
        * @param aACP The acp record being built
        * @param resStatus Residency Status
        * @return Dynamic SOQL string
        */
        private String formatSOQL(Application_Course_Preference__c aACP, String resStatus) {
            String soqlLog;

            soqlLog = formatSOQL(aACP
                               , aACP.Override_Admission_Calendar_Type__c!=null?aACP.Override_Admission_Calendar_Type__c:aACP.Admission_Calendar_Type__c
                               , aACP.Override_Academic_CI_Sequence__c!=null?aACP.Override_Academic_CI_Sequence__c:aACP.Academic_CI_Sequence_Number__c
                               , aACP.Override_Admission_CI_Sequence__c!=null?aACP.Override_Admission_CI_Sequence__c:aACP.Admission_CI_Sequence_number__c
                               , resStatus);
            
            return soqlLog;
        }        

       /*
        * @description Helper class to format pseudo SOQL statment for logging (Overloaded)
        * @param aACP The acp record being built
        * @param calType Calendar Type
        * @param acaSeq Calendar sequence
        * @param admSeq Calendar sequence
        * @param resStatus Residency Status
        * @return Dynamic SOQL string
        */
        private String formatSOQL(Application_Course_Preference__c aACP, String calType, Decimal acaSeq, Decimal admSeq, String resStatus) {
            // Strictly to supporting log messages - never executed 
            // Sorting puts the primary record for the key to the top
            String soqltemplate = 'SELECT Id, Course_Code__c, Course_Version_Number__c, Admission_Calendar_Type__c, Location_Code__c, Attendance_Mode__c, Attendance_Type__c, Academic_CI_Sequence_Number__c, Admission_CI_Sequence_Number__c, Admission_Category__c, Citizenship_Type__c, Unit_Set_Code__c, Unit_Set_Version__c, fee_category__c, Type_of_place_code__c, Active__c' 
                + ' FROM Course_Offering__c WHERE Course_Code__c = :tmpVar01 AND Admission_Calendar_Type__c = :tmpVar02 AND Location_Code__c = :tmpVar03 AND Attendance_Type__c = :tmpVar04' 
                + ' AND Attendance_Mode__c =:tmpVar05 AND Academic_CI_Sequence_Number__c = :tmpVar06 AND Admission_CI_Sequence_Number__c = :tmpVar07 AND Admission_Category__c = :tmpVar08'
                + ' AND Course_Version_Number__c = :tmpVar09 AND Unit_Set_Code__c = :tmpVar10 AND Unit_Set_Version__c = :tmpVar11 AND Citizenship_Type__c in :tmpVar12 ORDER BY Default_Admission_Category_Ind__c desc, Active__c desc NULLS FIRST';
            String soqlLog;
            
            soqlLog = soqltemplate;

            // Prepare soql for log message
            soqlLog = soqlLog.replace(':tmpVar01',aACP.Course_Code__c!=null?'\''+aACP.Course_Code__c+'\'':'null');
            soqlLog = soqlLog.replace(':tmpVar02',calType!=null?'\''+calType+'\'':'null');
            soqlLog = soqlLog.replace(':tmpVar03',aACP.Location_Code__c!=null?'\''+aACP.Location_Code__c+'\'':'null');
            soqlLog = soqlLog.replace(':tmpVar04',aACP.Attendance_Type__c!=null?'\''+aACP.Attendance_Type__c+'\'':'null');
            soqlLog = soqlLog.replace(':tmpVar05',aACP.Attendance_Mode__c!=null?'\''+aACP.Attendance_Mode__c+'\'':'null');
            soqlLog = soqlLog.replace(':tmpVar06',acaSeq!=null?String.valueOf(acaSeq):'null');
            soqlLog = soqlLog.replace(':tmpVar07',admSeq!=null?String.valueOf(admSeq):'null');
            soqlLog = soqlLog.replace(':tmpVar08',aACP.Admission_Category__c!=null?'\''+aACP.Admission_Category__c+'\'':'null');
            soqlLog = soqlLog.replace(':tmpVar09',aACP.Course_Version_Number__c!=null?String.valueOf(aACP.Course_Version_Number__c):'null');
            soqlLog = soqlLog.replace(':tmpVar10',aACP.Unit_Set_Code__c!=null?'\''+aACP.Unit_Set_Code__c+'\'':'null');
            soqlLog = soqlLog.replace(':tmpVar11',aACP.Unit_Set_Version__c!=null?String.valueOf(aACP.Unit_Set_Version__c):'null');
            soqlLog = soqlLog.replace(':tmpVar12',resStatus);
            
            return soqlLog;
        }

        /**
         * @description Execution entry point. Individual records are delivered here for processing or filtering
         */
        public override void process(SObject record) {
            IbdACP__e iEvent = (IbdACP__e)record;
            
            try {
                // Map of all inbound ACP ADM keys
                mapADMACP.put(CreateAdmKeyFromEvent(iEvent), iEvent);
                // Map of all inbound Application keys
                mapAPP.put(CreateApplicationKeyFromEvent(iEvent), iEvent);
                // List of all inbound person ids
                if (!String.isBlank(iEvent.Person_ID__c)) { personIDs.add(iEvent.Person_ID__c); } 
                // List of all inbound applicant ids
                if (!String.isBlank(iEvent.Callista_applicant_ID__c)) { applicantIDs.add(iEvent.Callista_applicant_ID__c); }
                // List of all required country codes
                if (!String.isBlank(iEvent.Citizenship_Country__c)) {countryCodes.add(iEvent.Citizenship_Country__c); }
            } catch (Exception e) {
                nebula.logger.error(e.getMessage(), e);
            } 
        }
        
         /**
         * @description Post-process execution
         */
        public override void execute() {
            Map<String, Application__c> upsertAPPMap = new Map<String, Application__c>();
            Map<String, Application__c> existingAPPMap = new Map<String, Application__c>();
            Map<String, Application_Course_Preference__c> existingADMMap = new Map<String, Application_Course_Preference__c>();
            Set<Application_Course_Preference__c> upsertAPSet = new Set<Application_Course_Preference__c>();
            Set<Application_Course_Preference__c> updateADMSet = new Set<Application_Course_Preference__c>();
            Map<String,ID> applicantMap = new Map<String,ID>();
            Map<String,ID> countryMap = new Map<String,ID>();
            String soqlLog;
            String resStatus;
            nebula.LogMessage logMsg;
            String jsonEvent;
            
            // Set logging to the inbound event scenario, which controls the default logging level etc.
            // See the Logger Scenario Rules custom metadata
            nebula.Logger.setScenario(SCENARIO);      

			// Allow for logs to be linked across event retired by inserting the initial transaction id in the error message
            String tId = nebula.Logger.getTransactionId();
            if (EventBus.TriggerContext.currentContext().lastError != null) {
                tId = EventBus.TriggerContext.currentContext().lastError.subStringBetween('[[',']]');
                if (String.isNotEmpty(tId)) {
	                nebula.Logger.setParentLogTransactionId(tId);
                }
            } 
            
            try {
                if (mapADMACP.size() > 0) {
                    existingADMMap = getExistingACP();
                    existingAPPMap = getExistingAPP();
	                nebula.logger.debug('App Records for Processing : ' + mapAPP.size());
	                nebula.logger.debug('App possible Inserts       : ' + string.valueOf(mapAPP.size() - existingAPPMap.size()));
	                nebula.logger.debug('App possible Updates       : ' + existingAPPMap.size());

                    nebula.logger.debug('ACP Records for Processing : ' + mapADMACP.size());
                    nebula.logger.debug('ACP possible Inserts       : ' + string.valueOf(mapADMACP.size() - existingADMMap.size()));
                    nebula.logger.debug('ACP possible Updates       : ' + existingADMMap.size());

                    // applicantMap contains all person ids and applicant ids for the batch
                    applicantMap = getApplicants(applicantIDs, personIDs);
                    nebula.logger.debug('Applicants found\r' + JSON.serializePretty(applicantMap).abbreviate(10000));
                    
                    // A lits of country codes and ids for this batch
                    countryMap = getCountry(countryCodes);
                    nebula.logger.debug('Country Codes found\r' + JSON.serializePretty(countryMap).abbreviate(10000));
                    
                    // Gather all possible course offerings for the ACPs in the batch, including override and deferred
                    // This will contain all possible combinations of fields and does not filter on citizenship type, active status or default indicator
                    Map<CourseOfferingIndexWrapper, Course_Offering__c> offerings = SelectAllCourseOfferingsInBatch(mapADMACP.values());
                    nebula.logger.debug('Possible Course Offerings\r' + JSON.serializePretty(offerings).abbreviate(10000));

                    // For each event record in the batch
                    for (Integer i=0; i < mapADMACP.size(); i++ ) {
                        ibdACP__e iEvent = mapADMACP.values()[i];
                        jsonEvent = JSON.serializePretty(iEvent);
                        
                        // Log immediately
                        logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c + '/' + ApplicationCoursePreferenceServices.buildACPName('', '', iEvent.Course_Code__c, iEvent.Intake_Period__c, iEvent.Unit_Set_Code__c, iEvent.Location__c), 'Application/ACP Upsert' ,jsonEvent);
                        nebula.logger.info(logMsg);

                        Application__c aApp = new Application__c();
                        Application_course_preference__c aACP = new Application_course_preference__c();

                        // Map the application fields from the current event record
                        aApp = this.mapEventToApplication(iEvent, countryMap);
                        if (aApp != null) {
                            // if we have an acp, try and map the contact to app
                            id contactID = getContactID (iEvent, applicantMap);
                            
                            if (contactID == null) {
                                // Inelegant way to force an invalid field error on database.upsert. 
                                // By forcing an error we guaranetee that App and ACP will align correctly with the Contact.
                                // If this is required, no point processing the ACP
                                aApp.Applicant__r = new Contact(Person_id_unique__c = '!' + aApp.Person_ID__c); // note adjusted person id to force error
                            } else {
                                nebula.logger.debug('Parent Contact found', contactID);
                                // Non standard field mappings for application
                                if (existingAPPMap.containsKey(aAPP.Callista_Application_Id__c)) {
                                    // When applications are updated, we can revert the hybrid source system to AgentPortal
                                    if (existingAPPMap.get(aAPP.Callista_Application_Id__c).source_system__c == HYBSOURCESYS) {
                                        aAPP.Source_System__c = DEFSOURCESYS;
                                    } else {
										// A 'Null' source system assumes Callista
										aAPP.Source_System__c = existingAPPMap.get(aAPP.Callista_Application_Id__c).source_system__c==null?DEFSOURCESYS:existingAPPMap.get(aAPP.Callista_Application_Id__c).source_system__c;                                        
                                    }
                                    aAPP.Residency_Status__c = existingAPPMap.get(aAPP.Callista_Application_Id__c).Residency_Status__c==null?null:existingAPPMap.get(aAPP.Callista_Application_Id__c).Residency_Status__c;
									// A 'Null' submitted date assumes an old record. Set the date to the createddate of the Application
                                    aAPP.Submitted_Date__c = existingAPPMap.get(aAPP.Callista_Application_Id__c).Submitted_Date__c==null?existingAPPMap.get(aAPP.Callista_Application_Id__c).createddate.date():existingAPPMap.get(aAPP.Callista_Application_Id__c).Submitted_Date__c;
                                } else {
                                    // New applications
                                    if (AgentPortalServices.isValidOrgUnit(aAPP.Agent_Org_Unit_Code__c)) {
                                        // Agent applications created in Callista
                                        // Assigned a temporary source system to allow an affiliation to be created (applicationHandler.AddModifyAffiliationRecords)
                                        aAPP.Source_System__c =  HYBSOURCESYS; 
                                    } else {
                                        aAPP.Source_System__c = DEFSOURCESYS;
                                    }
                                    aAPP.Submitted_Date__c = System.Date.today();
                                }

                                // Assign the contact to both ACP and App, and map the ACP fields
                                aApp.Applicant__c = contactID;
                                aACP = this.mapEventToACP(iEvent);
                                aACP.Applicant__c = contactID;
                                
                                resStatus = determineResidencyStatus(aApp);
                                    
                                soqlLog = formatSOQL(aACP, resStatus);

                                if (offerings.size() > 0) {
                                    // Create a course offering wrapper for the current event
                                    CourseOfferingIndexWrapper acpCO = new CourseOfferingIndexWrapper(aACP, resStatus);
				                    nebula.logger.fine('ACP Course offering Details\r'+ JSON.serializePretty(acpCO));
                                    
                                    // See if it exists in the map of possible course offerings
                                    if (offerings.containsKey(acpCO)) {
                                        aACP.Course_Offering__c = offerings.get(acpCO).Id;
                                    } else {
                                        // warning
                                        aACP.Course_Offering__c = null;
										logMsg = new nebula.logMessage(msgfmt3, 'C/O not found', aACP.Admission_Category__c + '/' + aACP.Course_Code__c + '_' + aACP.Course_Version_Number__c + '/' + aACP.Admission_Calendar_Type__c + '/' + aACP.Commencement_Period__c.replace('/', '-') + '/' + resStatus +')',soqlLog);
                                        nebula.logger.warn(logMsg).addTag(REFTAG);
                                    }
                                    
                                    if (aACP.Deferred_Admission_Calendar_Type__c != null) {
                                        soqlLog = formatSOQL(aACP, aACP.Deferred_Admission_Calendar_Type__c, aACP.Deferred_Academic_CI_Sequence__c , aACP.Deferred_Admission_Ci_Sequence__c, resStatus);

                                        // Create a course offering wrapper for the current event deferred fields
                                        acpCO = new CourseOfferingIndexWrapper(aACP.Course_Code__c, aACP.Deferred_Admission_Calendar_Type__c, aACP.Location_Code__c,
                                        aACP.Attendance_Type__c, aACP.Attendance_Mode__c, aACP.Deferred_Academic_CI_Sequence__c , aACP.Deferred_Admission_Ci_Sequence__c
                                        , aACP.Admission_Category__c, resStatus, aACP.Course_Version_Number__c, aACP.Unit_Set_Code__c, aACP.Unit_Set_Version__c);
					                    nebula.logger.debug('ACP Deferred Course offering Details\r'+ JSON.serializePretty(acpCO));
                                        
                                        // See if it exists in the map of possible course offerings
                                        if (offerings.containsKey(acpCO)) {
                                            // No new is good news
                                            aACP.deferred_Course_Offering__c = offerings.get(acpCO).Id;
                                        } else {
                                            // warning
                                            aACP.deferred_Course_Offering__c = null;
                                            logMsg = new nebula.logMessage(msgfmt3, 'Deferred C/O not found', aACP.Admission_Category__c + '/' + aACP.Course_Code__c + '_' + aACP.Course_Version_Number__c + '/' + aACP.Admission_Calendar_Type__c + '/' + aACP.Commencement_Period__c.replace('/', '-') + '/' + resStatus +')',soqlLog);
			                                nebula.logger.warn(logMsg).addTag(REFTAG);
                                        }
                                    } else {
                                        // clear the field in case this is an override event
                                        aACP.deferred_Course_Offering__c = null;    
                                    }
                                        
                                } else {
                                    aACP.Course_Offering__c = null;
                                    aACP.deferred_Course_Offering__c = null;
	                                nebula.logger.warn(new nebula.logMessage(msgfmt1, 'No C/O for batch', '('+soqlLog+')').getMessage()).addTag(REFTAG);
                                }
                                
                                // Use the application external key to link the ACP and Application
                                aACP.Application__r = new Application__c(Callista_Application_Id__c = aApp.Callista_Application_Id__c);
                                
                                // Decide if we are updating an ACP (the ADM key exists) or upserting (based on the AP Key)
                                if (existingADMMap.containsKey(aACP.Callista_Unique_Key_ADM__c)) {
                                    aACP.id=existingADMMap.get(aACP.Callista_Unique_Key_ADM__c).ID;
                                    updateADMSet.add(aACP); // Matched on ADM key, we have the CRM id so we can update                           
                                } else {
                                    upsertAPSet.add(aACP); // Didn't match on ADM key, we upsert on the AP Key, which will insert new records or update AP Keys that exist
                                }
                            }
                            // All applications can be upserted 
                            upsertAPPMap.put(aApp.Callista_Application_Id__c, aApp);
                        }        
                    }
                }
                
                // Applications           
                List<Application__c> upsertAppList = new List<Application__c>(upsertAPPMap.values());    
                nebula.logger.debug('Applications to be upserted : ' + upsertAppList.size());
                if (upsertAppList.size() > 0 ) {
                    Triggers.bypass('Person360RollDown');
                    Database.UpsertResult [] upsertResults = Database.upsert(upsertAppList, Application__c.Fields.Callista_Application_Id__c, false);
                    Triggers.clearbypass('Person360RollDown');
                    Database.UpsertResult aResult = null;
                    for (Integer i=0; i<upsertResults.size(); i++) {
                        aResult = upsertResults[i];
                        if (!aResult.isSuccess()) {
                            for (Database.Error err : aResult.getErrors()) {
                                Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, upsertAppList[i].Person_ID__c, 'Retry Application ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
                                            nebula.logger.warn (logMsg, aResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
                                            logMsg = new nebula.LogMessage(msgfmt1,upsertAppList[i].Person_ID__c, 'Maximum retries (' + MAXRETRIES + ') reached for Application - ' + err.getMessage());
                                            nebula.logger.error(logMsg, aResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,upsertAppList[i].Person_ID__c,'Application upsert error - ' + err.getMessage());
	                                    nebula.logger.error(logMsg, aResult);
                                    }
                                }
                            } 
                        } else {
                            nebula.logger.fine('Application successfully ' + String.valueOf(aResult.isCreated()?'created':'updated') ,aResult.getId());
                        }
                    }
                }
                
                // ACP Updates (we have the ADM key already)    
                List<Application_course_preference__c> updateACPList = new List<Application_course_preference__c>(updateADMSet);
                nebula.logger.debug('ACP ADM updates : ' + updateACPList.size());
                if (updateACPList.size() > 0) {
                    Triggers.bypass('Person360RollDown');
                    Database.SaveResult [] updateResults = Database.update(updateACPList , false);
                    Triggers.clearbypass('Person360RollDown');
                    Database.SaveResult audResult = null;
                    for (Integer i=0; i<updateResults.size(); i++) {
                        audResult = updateResults[i];
                        if (!audResult.isSuccess()) {
                            for (Database.Error err : audResult.getErrors()) {
                                Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW { 
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, updateACPList[i].Callista_Student_ID_MIX__c, 'Retry ACP ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
                                            nebula.logger.warn (logMsg, audResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
                                            logMsg = new nebula.LogMessage(msgfmt1,updateACPList[i].Callista_Student_ID_MIX__c, 'Maximum retries (' + MAXRETRIES + ') reached for ACP');
                                            nebula.logger.error (logMsg, audResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,updateACPList[i].Callista_Student_ID_MIX__c,'ACP update error - ' + err.getMessage());
	                                    nebula.logger.error(logMsg, audResult);
                                    }
                                }
                            }
                        }  else {
                            nebula.logger.fine('ACP successfully updated', audResult.getId());
                        }
                    }
                }
                
                // ACP Upserts either have the AP key or it's a new record   
                // The AP Key must be populated. For the few records at we recieved that do not, we use the ADM key 
                List<Application_course_preference__c> upsertAPList = new List<Application_course_preference__c>(upsertAPSet);
                nebula.logger.debug('ACP AP updates : ' + upsertAPList.size());
                if (upsertAPList.size() > 0 ) {
                    Triggers.bypass('Person360RollDown');
                    Database.UpsertResult [] usACPResults = Database.upsert(upsertAPList,Application_course_preference__c.fields.Callista_Unique_Key_AP__c , false);
                    Triggers.clearbypass('Person360RollDown');
                    Database.UpsertResult ausResult = null;
                    for (Integer i=0; i<usACPResults.size(); i++) {
                        ausResult = usACPResults[i];
                        if (!ausResult.isSuccess()) {
                            for (Database.Error err : ausResult.getErrors()) {
                                Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW { //, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, upsertAPList[i].Callista_Student_ID_MIX__c, 'Retry ACP AP ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
                                            nebula.logger.warn (logMsg, ausResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
                                            logMsg = new nebula.LogMessage(msgfmt1,upsertAPList[i].Callista_Student_ID_MIX__c + ' - Maximum retries (' + MAXRETRIES + ') reached for ACP');
                                            nebula.logger.error (logMsg, ausResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,upsertAPList[i].Callista_Student_ID_MIX__c,'ACP AP upsert error - ' + err.getMessage());
                                        nebula.logger.error(logMsg, ausResult);
                                    }
                                }
                            } 
                        } else {
                            nebula.logger.fine('ACP (AP) successfully ' + String.valueOf(ausResult.isCreated()?'created':'updated') ,ausResult.getId());
                        }
                    }
                }
            } catch (MyRetryException mex) {
				// A retry replays the entire batch, so there is no need to duplicate the logs for each.
				// This does delay when the first message is avaliable in the logs
                if (!nebula.logger.isDebugEnabled()) {nebula.logger.flushBuffer();}
                // Include the logger transaction id
                throw new EventBus.RetryableException('Application/ACP Retry ' + String.ValueOf(EventBus.TriggerContext.currentContext().retries + 1) + ' of ' + MAXRETRIES + ' - ' + mex.getMessage() + '\r[[' + tId + ']]');
            } catch (Exception ex) { 
                nebula.logger.error(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
        
         /**
         * @description Helper method to return the citizenship. Return value is quoted and in bracers for a contains comparison.
         *              5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes
         * @param aApp The application being built
         * @return Callista Citizenship value
         */
        public String determineResidencyStatus(Application__c aApp){
            return aApp.Residency_Status__c!=null?'(\'' + aApp.Residency_Status__c + '\')':'(\'DOM-AUS\', \'INTRNTNL\', \'DOM-SUN\', \'DOM-IDN\')';
        }
        
        /**
         * @description Query for course offering records based on the supplied criteria. The result is all possible combinations of the fields, which can be a big join.
         * IMPORTANT - The query that populates the offering list is sorted in reverse order. Default_Admission_Category_Ind__c and active records for each key will come last.
         *             When they are added to the courseOfferings map, the last record for each survives.
         * @param A list of acps to link to course offerings
         * @return A map of course offerings from the batch and course offering records
         */
        public Map<CourseOfferingIndexWrapper, Course_Offering__c> SelectAllCourseOfferingsInBatch(List<IbdACP__e> acpEvents) {
            Map<String, Set<String>> queryFields = new Map<String, Set<String>>();
            List<String> queryKeys = new List<String>{
                'CourseCodes', 'AdmissionCalendarTypes', 'LocationCodes', 'AttendanceTypes', 'AttendanceModes',
                'AdmissionCategory', 'UnitSetCodes', 'Calendars'
                    };
                        
                        for (String key : queryKeys) {
                            queryFields.put(key, new Set<String>());
                        }
            
            for (IbdACP__e event : acpEvents) {
                try{
                    // Build composite keys to try and limit the cartesian join this produces
                    if (event.Course_Code__c!=null && event.Course_Version__c!=null) {queryFields.get('CourseCodes').add(event.Course_Code__c + '_' + event.Course_Version__c);}
                    if (event.Admission_Calendar_Type__c!=null) {queryFields.get('AdmissionCalendarTypes').add(event.Admission_Calendar_Type__c);}
                    if (event.override_admission_calendar_type__c !=null) {queryFields.get('AdmissionCalendarTypes').add(event.override_admission_calendar_type__c);}
                    if (event.deferred_admission_calendar_type__c !=null) {queryFields.get('AdmissionCalendarTypes').add(event.deferred_admission_calendar_type__c);}
                    queryFields.get('LocationCodes').add(event.Location__c);
                    queryFields.get('AttendanceTypes').add(event.Att_Type__c);
                    queryFields.get('AttendanceModes').add(event.Att_Mode__c);
                    if (event.Academic_CI_Sequence_Number__c!=null && event.Admission_CI_Sequence_Number__c!=null) {queryFields.get('Calendars').add(event.Academic_CI_Sequence_Number__c + '_' + event.Admission_CI_Sequence_Number__c);}
                    if (event.Override_Academic_CI_Sequence__c!=null && event.Override_Admission_CI_Sequence__c!=null) {queryFields.get('Calendars').add(event.Override_Academic_CI_Sequence__c + '_' + event.Override_Admission_CI_Sequence__c);}
                    if (event.Deferred_Academic_CI_Sequence__c!=null && event.Deferred_Admission_CI_Sequence__c!=null) {queryFields.get('Calendars').add(event.Deferred_Academic_CI_Sequence__c + '_' + event.Deferred_Admission_CI_Sequence__c);}
                    queryFields.get('AdmissionCategory').add(event.Admission_Category__c);
                    queryFields.get('UnitSetCodes').add(event.Unit_Set_Code__c==null||event.Unit_Set_Version__c==null?null:event.Unit_Set_Code__c + '_' + event.Unit_Set_Version__c);
                }
                catch(Exception ex){
                    nebula.logger.exception(ex.getMessage(), ex);
                }
            }

			Map<CourseOfferingIndexWrapper, Course_Offering__c> courseOfferings = new Map<CourseOfferingIndexWrapper, Course_Offering__c>();
             
            try {

                // Create Indexes
                // Using a select in a for loop to reduce heap usage
                // Use the Mix_Unique_Id to get a favourable  query plan
                for (Course_Offering__c offering : [SELECT Id, Course_Code__c, Course_Version_Number__c, Admission_Calendar_Type__c, Location_Code__c, Attendance_Mode__c, Attendance_Type__c,
                                                    Academic_CI_Sequence_Number__c, Admission_CI_Sequence_Number__c, Admission_Category__c, Citizenship_Type__c, Unit_Set_Code__c, Unit_Set_Version__c
                                                    FROM Course_Offering__c
                                                    WHERE course_key__c IN :queryFields.get('CourseCodes')
                                                    AND Admission_Calendar_Type__c IN :queryFields.get('AdmissionCalendarTypes')
                                                    AND Location_Code__c IN :queryFields.get('LocationCodes')
                                                    AND Calendar_Key__c IN :queryFields.get('Calendars')
                                                    AND Attendance_Type__c IN :queryFields.get('AttendanceTypes')
                                                    AND Attendance_Mode__c IN :queryFields.get('AttendanceModes')
                                                    AND Admission_Category__c IN :queryFields.get('AdmissionCategory')
                                                    AND Unit_Set_Key__c IN :queryFields.get('UnitSetCodes') 
                                                    //AND Mix_Unique_Id__c != null
                                                    Order by Default_Admission_Category_Ind__c ASC, Active__c asc] ) {

					CourseOfferingIndexWrapper wrapper = new CourseOfferingIndexWrapper(offering.Course_Code__c, offering.Admission_Calendar_Type__c,
                                                            offering.Location_Code__c, offering.Attendance_Type__c, offering.Attendance_Mode__c, offering.Academic_CI_Sequence_Number__c,
                                                            offering.Admission_CI_Sequence_Number__c, offering.Admission_Category__c, offering.Citizenship_Type__c, offering.Course_Version_Number__c, offering.unit_set_code__c, offering.unit_set_version__c);
                                                            courseOfferings.put(wrapper, offering);
                                                    }
            } catch(Exception ex){
                nebula.logger.exception( 'SELECT Id, Course_Code__c, Course_Version_Number__c, Admission_Calendar_Type__c, Location_Code__c, Attendance_Mode__c, Attendance_Type__c, Academic_CI_Sequence_Number__c, Admission_CI_Sequence_Number__c, Admission_Category__c, Citizenship_Type__c, Unit_Set_Code__c, Unit_Set_Version__c FROM Course_Offering__c where course_key__c IN (' + queryFields.get('CourseCodes') +
                                        ') AND Admission_Calendar_Type__c IN ('  + queryFields.get('AdmissionCalendarTypes') +
                                        ') AND Location_Code__c IN (' + queryFields.get('LocationCodes') +
                                        ') AND Admission_Category__c IN (' + queryFields.get('AdmissionCategory') + 
                                        ') AND Unit_Set_Key__c IN (' + queryFields.get('UnitSetCodes') +
                                        ') AND Calendar_Key__c IN (' + queryFields.get('Calendars') +
                                        ') AND Attendance_Type__c IN (' + queryFields.get('AttendanceTypes') + 
                                        ') AND Attendance_Mode__c IN (' + queryFields.get('AttendanceModes') + 
                                        ') Order by Default_Admission_Category_Ind__c ASC, Active__c asc', ex);
            } 

            return courseOfferings;
        }

       /**
        * @description Individual field mappings for the Application
        * @param iEvent The event being mapped
        * @param mapCCodes The country attribute lookup codes 
        * @return A populated Application record
        */
        private Application__c mapEventToApplication(ibdACP__e iEvent, Map<String, ID> mapCCodes) {
            Application__c aa = new Application__c();
            
            aa.Status__c = 'Submitted';
            aa.Callista_Applicant_Id__c = iEvent.Callista_Applicant_Id__c != null ? iEvent.Callista_Applicant_Id__c : null;
            aa.Callista_Application_Id__c = CreateApplicationKeyFromEvent(iEvent);
            // ignore updating the application's agent when the incoming agent org unit code is PARTNR fomr Constants class
            aa.Agent_Org_Unit_Code__c = iEvent.Org_Unit_Code__c != null && iEvent.Org_Unit_Code__c != Constants.CALLISTA_PARTNER_ORG_UNIT_CODE ? iEvent.Org_Unit_Code__c : null;
            aa.LastModifiedBy_API__c = iEvent.LastModifiedBy_API__c;
            aa.LastModifiedDate_API__c = iEvent.LastModifiedDate_API__c;
            aa.Person_ID__c = iEvent.PERSON_ID__c;
            aa.Campus__c = iEvent.Location__c;
            
            // Set lookup to the country attribute
            if (mapCCodes.size() > 0 && mapCCodes.containsKey(iEvent.Citizenship_Country__c) ){
                aa.Citizenship_Country__c = mapCCodes.get(iEvent.Citizenship_Country__c);
            }
            
            // Source_System__c - Dealt with in main body, comparing against existing records. 'Null' assumes Callista.
            // Residency_Status__c - Dealt with in main body & in the application before-trigger.
            // Submitted_Date__c - Dealt with in main body, comparing against existing records. New applications are assumed to have been created in Callista and the data is set to today.
            
            return aa;
        }

        /**
         * @description Individudal field mappings for the ACP
         * @param iEvent The event being mapped
         * @return A populated ACP record
         */
        private Application_Course_Preference__c mapEventToACP(ibdACP__e iEvent){
            Application_Course_Preference__c aACP = new Application_Course_Preference__c();

            // Fields removed from mapping as not received from Callista
            //aACP.Accepted_Date__c = iEvent.Accepted_Date__c;

            aACP.Academic_Calendar_Type__c = iEvent.Academic_Calendar_Type__c;

            aACP.Academic_CI_Sequence_Number__c = iEvent.Academic_CI_Sequence_Number__c != null ? Integer.valueOf(iEvent.Academic_CI_Sequence_Number__c) : null;
            aACP.Admission_CI_Sequence_Number__c = iEvent.Admission_CI_Sequence_Number__c != null ? Integer.valueOf(iEvent.Admission_CI_Sequence_Number__c) : null;

            aACP.Actual_Academic_Alternate_Code__c = iEvent.Actual_Academic_Alternate_Code__c;
            aACP.Actual_Admission_Calendar_Type__c = iEvent.Actual_Admission_Calendar_Type__c;
            aACP.Actual_Offer_Response_Date__c = iEvent.Actual_Offer_Response_Date__c;
            aACP.Admission_Calendar_Type__c = iEvent.Admission_Calendar_Type__c;
            aACP.Admission_Code__c = iEvent.Admission_Code__c;
            aACP.Application_Date__c = iEvent.Application_Date__c;
            aACP.Admission_Category__c = iEvent.Admission_Category__c;
            aACP.Attendance_Mode__c = iEvent.Att_Mode__c;
            aACP.Attendance_Type__c = iEvent.Att_Type__c;
            aACP.Attendance_Certificate__c = iEvent.Attendance_Certificate__c;
            aACP.Attendance_Mode_Description__c = iEvent.Attendance_Mode_Description__c;
            aACP.Attendance_Type_Description__c = iEvent.Attendance_Type_Description__c;
            aACP.Basis_For_Adminssion_Type__c = iEvent.Basis_For_Admission_Type__c;
            aACP.Callista_Last_Modified_Date__c = iEvent.Callista_Last_Modified_Date__c;
            aACP.Certificate_to_be_printed__c = iEvent.Certificate_to_be_printed__c;
            aACP.Cancelled__c = iEvent.Cancelled__c;
            aACP.Certification_Completed__c = iEvent.Certification_Completed__c;
            aACP.Certification_Completed_Without_Points__c = iEvent.Certification_Completed_Without_Points__c;
            aACP.Commencement_Period__c = iEvent.Commencement_Period__c;
            if (!String.isBlank(iEvent.Comments__c)) {aACP.LongComments__c = iEvent.Comments__c.abbreviate(4000);}
            aACP.Completion_Certificate_Mailed_Date__c = iEvent.Completion_Certificate_Mailed_Date__c;
            aACP.Course_Code__c = iEvent.Course_Code__c;
            aACP.Course_Version_Number__c = iEvent.Course_Version__c != null ? Integer.valueOf(iEvent.Course_Version__c) : null;
            aACP.Course_Confirmed__c = iEvent.Course_Confirmed__c;
            aACP.Course_Result__c = iEvent.Course_Result__c;
            aACP.Course_Title__c = iEvent.Course_Title__c;
            aACP.Offer_Round__c = iEvent.Offer_Round__c;

            // Same logic is applied in the ACP trigger
            aACP.name = ApplicationCoursePreferenceServices.buildACPName(aACP.ACP_ID__c, '', iEvent.Course_Code__c, iEvent.Intake_Period__c, iEvent.Unit_Set_Code__c, iEvent.Location__c);

            aACP.Days_Attended__c = iEvent.Days_Attended__c != null ? Integer.valueOf(iEvent.Days_Attended__c) : null;
            aACP.Application_Sequence_Number__c = iEvent.Application_Sequence_Number__c != null ? Integer.valueOf(iEvent.Application_Sequence_Number__c) : null;
            
            // Deferred 
            aACP.Deferred_Admission_CI_Sequence__c = iEvent.Deferred_Admission_CI_Sequence__c != null ? Integer.valueOf(iEvent.Deferred_Admission_CI_Sequence__c) : null;
            aACP.Deferred_Academic_CI_Sequence__c = iEvent.Deferred_Academic_CI_Sequence__c != null ? Integer.valueOf(iEvent.Deferred_Academic_CI_Sequence__c) : null;
            aACP.Deferred_Admission_Calendar_Type__c = iEvent.Deferred_Admission_Calendar_Type__c;
            aACP.Deferred_Academic_Alternate_Code__c = iEvent.Deferred_Academic_Alternate_Code__c;
            aACP.Deferred_Commencement_Period__c = iEvent.Deferred_Commencement_Period__c;

            // Override
            aACP.Override_Academic_CI_Sequence__c = iEvent.Override_Academic_CI_Sequence__c != null ? Integer.valueOf(iEvent.Override_Academic_CI_Sequence__c) : null;
            aACP.Override_Admission_CI_Sequence__c = iEvent.Override_Admission_CI_Sequence__c != null ? Integer.valueOf(iEvent.Override_Admission_CI_Sequence__c) : null;
            aACP.Override_Admission_Calendar_Type__c = iEvent.Override_Admission_Calendar_Type__c;
             
            aACP.Admission_Application_Number__c = iEvent.Admission_Application_Number__c != null ? Integer.valueOf(iEvent.Admission_Application_Number__c) : null;
            aACP.Fee_Category__c = iEvent.Fee_Category__c;
            aACP.Intake_Period__c = iEvent.Intake_Period__c;
            aACP.LastModifiedBy_API__c = iEvent.LastModifiedBy_API__c;
            aACP.LastModifiedDate_API__c = iEvent.LastModifiedDate_API__c;
            aACP.Legacy_Application_ID__c = iEvent.Legacy_Application_ID__c;
            aACP.Legacy_Payment_Type_ID__c = iEvent.Legacy_Payment_Type_ID__c;
            aACP.Location_Code__c = iEvent.Location__c;
            aACP.Location_Description__c = iEvent.Location_Description__c;
            aACP.Marks__c = iEvent.Marks__c;
            aACP.Offer_Condition__c = iEvent.Offer_Condition__c;
            aACP.Offer_Date__c = iEvent.Offer_Date__c;
            aACP.Offer_Response_Date__c = iEvent.Offer_Response_Date_Lapse_Date__c;
            aACP.Admission_Category__c = iEvent.Admission_Category__c;
            aACP.Org_Unit_Description__c = iEvent.Org_Unit_Description__c;
            aACP.Portal_Sequence_Number__c = iEvent.Portal_Sequence_Number__c;
            aACP.Preference_Number__c = iEvent.Pref__c;
            aACP.Receipt_Number__c = iEvent.Receipt_Number__c;
            aACP.Result__c = iEvent.Result__c;
            aACP.Status__c = iEvent.Status__c;
            aACP.Callista_Student_ID_MIX__c = iEvent.PERSON_ID__c;
            aACP.Type_of_Place_Code__c = iEvent.Type_of_Place_Code__c;
            aACP.Type_of_Place_Description__c = iEvent.Type_of_Place_Description__c;
            aACP.Conditions_Must_Be_Satisfied__c = iEvent.Conditions_Must_Be_Satisfied__c;
            aACP.Conditional_Offer_Satisfied_Date__c = iEvent.Conditional_Offer_Satisfied_Date__c;

            aACP.Unit_Set_Code__c = iEvent.Unit_Set_Code__c;
            if (iEvent.Unit_Set_Description__c != null) { aACP.Unit_Set_Description__c = iEvent.Unit_Set_Description__c;}
            aACP.Unit_Set_Version__c = iEvent.Unit_Set_Version__c != null ? Integer.valueOf(iEvent.Unit_Set_Version__c) : null;
            
            //SFTLG-868 Field Removed
            //aACP.Recruitment_Reference_Description__c = iEvent.Recruitment_Reference_Description__c;
            aACP.Recruitment_Reference_Code__c = iEvent.Recruitment_Reference_Code__c;
            
            //SFTLG-881 Fields added
            aACP.Precedent_ID__c = iEvent.Precedent_ID__c != null ? Integer.valueOf(iEvent.Precedent_ID__c) : null;
            aACP.Requirement_Satisfied_Code__c = iEvent.Requirement_Satisfied_Code__c;
            
            aACP.Enrolment_Category__c = iEvent.Enrolment_Category__c;
            aACP.Fee_Payment_Option__c = iEvent.Fee_Payment_Option__c;
            aACP.Correspondence_Category__c = iEvent.Correspondence_Category__c;
            aACP.Admissions_Process_Type__c = iEvent.Admissions_Process_Type__c;

            // Unique Keys
            aACP.Callista_Unique_Key_ADM__c = CreateAdmKeyFromEvent(iEvent);
            // To allow upsert on AP key, the field must be populated
            // As some Callista records do not have an AP Key, use the ADM key instead
            aACP.Callista_Unique_Key_AP__c = iEvent.Callista_Application_Id__c != null? CreateApKeyFromEvent(iEvent) : CreateAdmKeyFromEvent(iEvent);

            // LOVs
            aACP.Outcome_Status_LOV__r = iEvent.Outcome_Status__c == null?null:new List_Of_Values__c(Unique_Key__c = iEvent.Outcome_Status__c + Label.Application_Outcome_Status);
            aACP.Offer_Response_Status_LOV__r = iEvent.Offer_Response_Status__c == null?null:new List_Of_Values__c(Unique_Key__c = iEvent.Offer_Response_Status__c + Label.Offer_Response_Status);
            aACP.Conditional_Offer_Status_LOV__r = iEvent.Conditional_Offer_Status__c == null?null:new List_Of_Values__c(Unique_Key__c = iEvent.Conditional_Offer_Status__c + Label.Conditional_Offer_Status);
            aACP.Deferment_Status_LOV__r = iEvent.Deferment_Status__c == null?null:new List_Of_Values__c(Unique_Key__c = iEvent.Deferment_Status__c + Label.Deferment_Status);
            aACP.Documentation_Status_LOV__r = iEvent.Documentation_Status__c == null?null:new List_Of_Values__c(Unique_Key__c = iEvent.Documentation_Status__c + Label.Documentation_Status);
            aACP.Entry_Qualification_Status_LOV__r = iEvent.Entry_Qualification_Status__c == null?null:new List_Of_Values__c(Unique_Key__c = iEvent.Entry_Qualification_Status__c + Label.Entry_Qualification_Status);
                
            return aACP;
        }
    }
}