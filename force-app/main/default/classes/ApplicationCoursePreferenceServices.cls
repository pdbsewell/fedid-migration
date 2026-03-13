/*
 * @author	Martin Cadman
 * @description  Contains all the services class for Application_Course_Preference__c
 * @revision
 * Shalini Mendu - Nov 2019 - SFTN-318(ACP Platform events from Callista are wiping out some fields)
 * Shalini Mendu - Nov 2019 - Admission Test/ English Test: Send test results to Callista SFTN-154
 * Ayush Agrawal - Mar 2020 - Some rework
 * Martin Cadman - May 2020 - Moved calendar and course/unitset lookup here from a involable Apex called from a process builder.
 * Martin Cadman - May 2020 - Moved ACP naming logic from process builder to trigger/services
 * Martin Cadman - May 2020 - Removed SOQL-in-loop issue in createPlatformEventForEnglishTestScore
 * Martin Cadman - May 2020 - Make course lookup case independent
 * Martin Cadman - May 2020 - Null check for ACP name (PD ACPs affected)
 * Martin Cadman - Feburary 2021 - Pulled the acp Name logic to separate methods
 * Martin Cadman - Feburary 2021 - Ensure Calendar lookup aligns with course offering calendar rather than CI fields
 * Cartick Sub   - April 2021 - PRODEV-678 - Convert the Process Builder, "PD Update ACP [Partitioning for Short Courses]", into a before trigger
 * Cartick Sub   - June 2021 - PRODEV-690 - Convert the Process Builder and Flow, "PD Update Faculty Student Email CC", into a before trigger
 * Sachin Shetty - Sep 2023 - Added a static property - eventList that collects ObdACP__e events (Used for testing only)  
 * Martin Cdaman - Feb 2024 - EPCP-3722 - Allow for submitted ACPs to have the calendar sequence numbers and original C/O update
 * Rajesh Punjabi - Jan 2025 - SMSTA-128: Validate Assessment Status and update release flag and release reason.
 * Davey Yu       - Feb 2025 - MGROI-823 update createPlatformEventForEnglishTestScore to prevent request to callista for graduate research applications
 * Sravani Naramsetti - Mar 2025 - SMSTA-512 Updating ACP.Assessment_Status__c with ACP.Workflow_Status__c
 * Davey Yu 	  - SMSTA-517 create new method createTimestampLogs in after insert and after update to log timestamp if ACP workflow status field is updated
 * Davey Yu 	  - SMSTA-590 update updateReleaseFlag method to update the workflow_status_date_change__c field 
 * Sravani Naramsetti - May 2025 - SMSTA-620 Removing Workflow Status as Released when ACP is put On Hold
 * Rumi           - Aug 2025 - DANO-696 Add additional conditions to set the course admission status rules
*/

public with sharing class ApplicationCoursePreferenceServices {

    // Platform event list variable used for testing only
    @testVisible private static List<ObdACP__e> eventList = new List<ObdACP__e>();

   /*
    * @author Martin Cadman
    * @date   01.05.2023
    * @description If the feature switch is enabled, this before-trigger method will change the owner of an ACP that is linked to an agency. It does this by
    *              identifying the branch manager user record of the linked agency.
    *              Note that this will fire on any of the ACP. Since the agency fields in use on the ACP are formula fields, it is not possible to check if the application
    *              agency or ownership values have changed. 
    */
    public class populateOwner extends TriggerAbstract {
		Set<String> orgUnits = new Set<String>();
		Feature_Switch__c fs = Feature_Switch__c.getInstance();

        // Handle after insert event checking and filtering
        public override void process(SObject rec) {
            Application_Course_Preference__c acp = (Application_Course_Preference__c)rec;
            
            if (fs.Align_ACP_Owner__c) {
    			if (AgentPortalServices.isValidOrgUnit(acp.Application_Agent_Code__c)) {
                	orgUnits.add(acp.Application_Agent_Code__c.toLowerCase());
                	records.add(acp);
                }
            }
        }
        
        // Handle after update event checking and filtering
        public override void process(SObject rec, SObject oldRec) {
            Application_Course_Preference__c acp    = (Application_Course_Preference__c)rec;
            Application_Course_Preference__c oldACP = (Application_Course_Preference__c)oldRec;
            
            if (fs.Align_ACP_Owner__c) {
                if (AgentPortalServices.isValidOrgUnit(acp.Application_Agent_Code__c)) {
                    orgUnits.add(acp.Application_Agent_Code__c.toLowerCase());
                    records.add(acp);
                }
            }
        }
        
        // Run functionality logic
        public override void execute() {
            try {
                if (!records.isEmpty() && !orgUnits.isEmpty()) {
                    Set<Application_Course_Preference__c> acps = new Set<Application_Course_Preference__c>((List<Application_Course_Preference__c>)records);

                    Set<String> agencyPartners = new Set<String>();
                    for (Account acc : [SELECT Id, Callista_Org_Unit_Code__c FROM Account WHERE Callista_Org_Unit_Code__c IN :orgUnits and ispartner = true]){
                        agencyPartners.add(acc.Callista_Org_Unit_Code__c.toLowerCase());
                    }
                    
                    AgentPortalServices.AgencyWrapper aw = AgentPortalServices.buildAgencyMaps(orgUnits); // get the breakdown of agents within an agency
                    
                    for (Application_Course_Preference__c acp : acps) {
                        if (!aw.agentUsers.keySet().contains(acp.OwnerId)
                            && acp.Application_Status__c != 'Submitted'
                            && agencyPartners.contains(acp.Application_Agent_Code__c.toLowerCase())) { // the ACP is owned outside of the Agency & the agency is a enabled as a partner
                            if (aw.agencyManagers.containsKey(acp.Application_Agent_Code__c.toLowerCase()) 
                                && aw.agencyManagers.get(acp.Application_Agent_Code__c.toLowerCase()) != null
                                && acp.OwnerId != aw.agencyManagers.get(acp.Application_Agent_Code__c.toLowerCase()).id) { // the org unit has a branch manager
                                acp.OwnerId = aw.agencyManagers.get(acp.Application_Agent_Code__c.toLowerCase()).id; // assign the branch manager as the owner
                            } else {
                                // this warning may also be caused if the user updating the record does not have access to the agency user records, so removing it
                                // logUtilityException.logExceptionMsg('WARNING', acp.Application_Agent_Code__c + '\r' + acp.Callista_Unique_Key_ADM__c, 'ACP Update Failed. No active branch manager user available for agency');
                            }
                        }    
                    }   
                }
            } catch (Exception ex) {
                logUtilityException.logException(ex);
            }
        }
	}

   /*
    * @author       Shalini Mendu
    * @date         06.Aug.2018
    * @description  Submits approval process for ACP with Short_Course
    * @revision     Shalini Mendu, 21.Sep.2018 - Order of Execution issue fix
    */
    public class submitApprovalProcess implements Triggers.Handler {
        public void run() {
            List<Application_Course_Preference__c> newACPList = (List<Application_Course_Preference__c>) Trigger.new;
            Approval.ProcessSubmitRequest [] requestList = new Approval.ProcessSubmitRequest []{};
            if (!newACPList.isEmpty()) {
                if (newACPList[0].Status__c == 'Registered - Pending Approval') {
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setComments('Submitting request for approval.');
                    req1.setObjectId(newACPList[0].id);

                    //Nadula Karunaratna | PRODEV-332 | Updated soql to pick up MSDI | 31/01/2019
                    List<ProcessDefinition> approvalList = [select Id, Name,TableEnumOrId,type from ProcessDefinition where name like 'Faculty%' or name like 'Monash Sus%'];
                    //List<ProcessDefinition> approvalList  = [select Id, Name,TableEnumOrId,type from ProcessDefinition where name like 'Faculty%'];

                    String facultyName = null;
                    try {
                        Boolean runApprovalProcess = false;
                        for (ProcessDefinition pd : approvalList) {
                            if (newACPList.size() > 0 && newACPList[0].Managing_Faculty_Text__c != null &&
                                    newACPList[0].PaymentCheckURL__c != null &&
                                    newACPList[0].Managing_Faculty_Text__c.startsWithIgnoreCase(pd.Name) &&
                                    newACPList[0].Course_Type__c == 'Short_Course'
                                    && newACPList[0].PaymentCheckURL__c.startsWith('https')) {
                                String pd15digitID = String.valueOf(pd.Id).substring(0, 15);
                                req1.setProcessDefinitionNameOrId(pd15digitID);
                                facultyName = pd.Name;

                                requestList.add(req1);

                                if (req1.getProcessDefinitionNameOrId() != null){
                                    runApprovalProcess = true;
                                }
                                break;
                               
                            }

                        }
                        if(runApprovalProcess){
                            Approval.ProcessResult[] result = Approval.process(requestList);
                        }

                    } catch (Exception e) {
                        LogUtilityException.logException(e,'Application_Course_Preference__c');
                        throw e;
                    }

                }
            }
        }
    }
    
   /*
    * @author       Martin Cadman
    * @date         May.2020
    * @description  Identifies the course, unitset and calendar lookups on an ACP. ACP for PD has a different naming convention.
    * @revision     18-04-2023 Moved triger framework
    */
    public class calculateName  extends TriggerAbstract {
        
        public override void process(SObject record) {
            Application_Course_Preference__c acp    = (Application_Course_Preference__c)record;
			records.add(acp);
        }

		public override void process(SObject record, SObject oldRec) {
            Application_Course_Preference__c acp    = (Application_Course_Preference__c)record;
            Application_Course_Preference__c oldACP = (Application_Course_Preference__c)oldRec;
            // could add field change logic here
			records.add(acp);
        }
        
        public override void execute() {
            if(!records.isEmpty()) {
                try {
                    Set<Application_Course_Preference__c> acps = new Set<Application_Course_Preference__c>((List<Application_Course_Preference__c>)records);
                    for (Application_Course_Preference__c acp : acps) {
                        String acpName = buildACPName(acp);
    
                        if (acp.name != acpName && !String.isBlank(acpName) ) {
                            acp.name = acpName;
                        }
                    }
                } 
                catch(Exception e){
                    LogUtilityException.logException (e,'Application_Course_Preference__c');
                }
            }
        }
    }

   /*
    * Overloaded helper function to build an ACP name that adjusts to the available fields and the type of ACP
    */    
	public static String buildACPName(Application_Course_Preference__c aACP) { 
        return buildACPName(aACP.ACP_ID__c, aACP.Course_Type__c, aACP.Course_Code__c, aACP.Intake_Period__c, aACP.Unit_Set_Code__c, aACP.Location_Code__c );
    }

   /*
	* Overloaded helper function to build an ACP name that adjusts to the available fields and the type of ACP
    */    
	public static String buildACPName(String acpId, String Course_Type, String Course_Code, String Intake_Period, String Unit_Set_Code, String Location_Code) { 
		String Name;
        
		if (Course_Type == 'Short_Course' || String.isBlank(Course_Code)) {
        	Name = acpId;
        } else {
        	Name = Course_Code + 
            (String.isBlank(Intake_Period) ? '' : '/' + Intake_Period.replace('/', '-')) + 
            (String.isBlank(Unit_Set_Code) ? '' : '/' + Unit_Set_Code) +
            (String.isBlank(Location_Code) ? '' : '/' + Location_Code);
        }
        return Name;
    }
    
   /*
    * @author       Martin Cadman
    * @date         May.2020
    * @description  Identifies the course, unit set and calendar lookups on an ACP
    * @revision     
    * Martin Cadman - SFTG-1768 - Originally the two CI sequence number fields were used to populate the Calendar lookup and this is still the fallback position.
    * 	              The default behaviour is to use the course offering to determine the correct calendar. The CI sequence numbers are also no longer updated when a new
    *                 course offering is selected; this caused problems when sending ACP data back to Callista.
    * 	
    * Martin Cadman - 07/02/2024 - SFTG-3722 - Ammendment to SFTG-1768 to allow unsubmitted acp calendar sequence fields to be aligned with the selected course offering
    *                                          Submitted means there is no Callista Application ID assigned. 
    */
    public class ACPLookups extends TriggerAbstract {

		// Any an all insert and...        
        public override void process(SObject record) {
			records.add(record);
        }

        // ...updates are processed
		public override void process(SObject record, SObject oldRec) {
			records.add(record);
        }

        public override void execute() {
            if(!records.isEmpty()) {
                List<Application_Course_Preference__c> newACPs = (List<Application_Course_Preference__c>)records;
                List<Id> crseOffId = new List<Id>();
                Map<Id,Course_Offering__c> coCalSeq = new Map<Id,Course_Offering__c>();
                Map<String, Set<String>> queryFields = new Map<String, Set<String>>();
                List<String> queryKeys = new List<String>{
                    'CourseCodes','CalendarCodes'
                };
    
                try {
    
                    for (String key : queryKeys) {
                        queryFields.put(key, new Set<String>());
                    }
    
                    for (Application_Course_Preference__c aACP : newACPs) {
    
                        // Gather all references to course offering ids
                        if (aACP.Course_Offering__c != null) {
                            crseOffId.add(aACP.Course_Offering__c);
                        }
    
                        if (aACP.Course_Code__c != null) {
                                If (aACP.Course_Version_Number__c==null) {
                                    // PD Courses do not have version numbers
                                    queryFields.get('CourseCodes').add(aACP.Course_Code__c.toUpperCase());
                                } else {
                                    queryFields.get('CourseCodes').add(aACP.Course_Code__c.toUpperCase() + '_' + String.valueOf(aACP.Course_Version_Number__c));
                                }
                        }
                        
                        if (aACP.Unit_Set_Code__c != null) {
                            queryFields.get('CourseCodes').add(aACP.Unit_Set_Code__c.toUpperCase() + '_' + String.valueOf(aACP.Unit_Set_Version__c));
                        } 
                        
                        if (aACP.Academic_CI_Sequence_Number__c != null && aACP.Admission_CI_Sequence_Number__c != null) {
                            queryFields.get('CalendarCodes').add(String.valueOf(aACP.Academic_CI_Sequence_Number__c) + '_' + String.valueOf(aACP.Admission_CI_Sequence_Number__c));
                        }
                    }
                    
                    // Get course offering calendar sequence fields and add these to the potential calendar lookups
                    for (Course_Offering__c aCO : [SELECT Id, Academic_CI_Sequence_Number__c, Admission_CI_Sequence_Number__c
                                                   FROM Course_Offering__c
                                                  WHERE Id in :crseOffId ]){
                        coCalSeq.put(aCO.id, aCo);
                        queryFields.get('CalendarCodes').add(String.valueOf(aCO.Academic_CI_Sequence_Number__c) + '_' + String.valueOf(aCO.Admission_CI_Sequence_Number__c));
                    }
    
                    Map<String,id> crsMap = new Map<String,id>();
                    // Query includes name to collect PD course which do not populate the unique key field
                    for (Course__c aCrs : [select id, name, Course_Code__c from course__c
                                           where type__c in ('Course-All', 'Unit Set','Short_Course')
                                           and (Course_Code__c in :queryFields.get('CourseCodes') or Name in :queryFields.get('CourseCodes'))
                                           order by status__c desc
                                          ]) {
                                              crsMap.put(aCrs.course_code__c!=null?aCrs.course_code__c.toUpperCase():aCrs.Name.toUpperCase(), aCrs.id);
                                          }
                    
                    Map<String,id> calMap = new Map<String,id>();
                    for (Calendar__c aCal : [select id, Calendar_Code__c from calendar__c
                                             where Calendar_Code__c in :queryFields.get('CalendarCodes')
                                            ]) {
                                                calMap.put(aCal.Calendar_Code__c, aCal.id);
                                            }
    
                    for (Application_Course_Preference__c ACP : newACPs) {
                        
                        //Course
                        if (acp.Course_Code__c != null) {
                            if (acp.Course_Version_Number__c==null) {
                                if (acp.course__c != crsMap.get(acp.Course_Code__c.toUpperCase())) {
                                    acp.course__c = crsMap.get(acp.Course_Code__c.toUpperCase());   // PD Course                         
                                }
                            }
                            else {
                                if (acp.course__c != crsMap.get(acp.Course_Code__c.toUpperCase() + '_' + acp.Course_Version_Number__c)) {
                                    acp.course__c = crsMap.get(acp.Course_Code__c.toUpperCase() + '_' + acp.Course_Version_Number__c);
                                }
                            }
                        } else {
                            // Clear the lookup field if it was originally populated. 
                            acp.course__c = null;
                        }
                        
                        // Unit Set
                        if (acp.Unit_Set_Code__c != null && acp.Unit_Set_Version__c != null) {
                            if (acp.unit_set__c != crsMap.get(acp.Unit_Set_Code__c.toUpperCase() + '_' + acp.Unit_Set_Version__c)) {
                                acp.unit_set__c = crsMap.get(acp.Unit_Set_Code__c.toUpperCase() + '_' + acp.Unit_Set_Version__c);
                            }
                        } else {
                            // Clear the field if it was originally populated. 
                            acp.unit_set__c = null;
                        }
    
                        //Calendar
                        if (acp.Academic_CI_Sequence_Number__c != 0 && acp.Admission_CI_Sequence_Number__c != 0) {
                            if (acp.calendar_code__c != calMap.get(acp.Academic_CI_Sequence_Number__c + '_' + acp.Admission_CI_Sequence_Number__c)) {
                                acp.calendar_code__c = calMap.get(acp.Academic_CI_Sequence_Number__c + '_' + acp.Admission_CI_Sequence_Number__c);
                            }
                        } else {
                            // Clear the field if it was originally populated. 
                            acp.calendar_code__c = null;
                        }
   
                        // This overrides the above calendar field changes if the course offering is populated
                        if (acp.Course_Offering__c != null) {
                            Course_Offering__c co = coCalSeq.get(acp.Course_Offering__c);
                            acp.calendar_code__c = calMap.get(co.Academic_CI_Sequence_Number__c + '_' + co.Admission_CI_Sequence_Number__c);
 							// SFTG-3722
 							// Never been submitted, so the CO calendar sequence numbers must be represented on the ACP
 							// Also update the original course offering prior to the initial submission to Callista
                            if (acp.Callista_Application_Id__c == null ) {
                                acp.Academic_CI_Sequence_Number__c  = co.Academic_CI_Sequence_Number__c;
                                acp.Admission_CI_Sequence_Number__c = co.Admission_CI_Sequence_Number__c;
                                acp.Original_Course_Offering__c = acp.Course_Offering__c; 
                            }
                        }
                    }
                } catch (Exception e){
                    LogUtilityException.logException (e,'Application_Course_Preference__c');
                }
            }
        }
    }
   

    /*
     * @author       Shalini Mendu
     * @date         03.Sep.2019
     * @description  Populate ACP field values from Course_Offering__c fields.
     * @revision
     * Shalini Mendu 03.09.2019 - SFTN-175
     * Ayush Agrawal 12.03.2020 - EPBBS-984
     * Martin Cadman 18.02.2021 - SFTG-1768 - stop the update of the academic and admission CI sequence numbers when a new course offering is selected
     */
    public class copyCourseOfferings implements Triggers.Handler {
        public void run() {
            
            List<Application_Course_Preference__c> newACPs = Trigger.new;
            Map<Id, Application_Course_Preference__c> oldACPsMap = new Map<Id, Application_Course_Preference__c>();
            if(Trigger.isUpdate) {
                oldACPsMap = (Map<Id, Application_Course_Preference__c>) Trigger.oldMap;
            }

            Try {
                Set<Id> CourseOfferingIds = new Set<Id>();
            
                for(Integer i = 0; i < newACPs.size(); i++) {
                    Application_Course_Preference__c acp = newACPs[i];
                   
                    // Nothing to do here
                    if (acp.Course_Offering__c == null && acp.Deferred_Course_Offering__c == null) {
                        continue;
                    }

					// Set the original offering field to the first offering assigned to this ACP
					// Note that PD ACPs will have this assigned as well but will not have any negative effects
                    if (acp.Original_Course_Offering__c == null) {
                        if (oldACPsMap.size() > 0  && oldACPsMap.get(acp.Id).Course_Offering__c!=null) {
                            acp.Original_Course_Offering__c = oldACPsMap.get(acp.Id).Course_Offering__c;
                        } else {
                            acp.Original_Course_Offering__c = acp.Course_Offering__c;
                        }
                    }
                    
					if(Trigger.isUpdate) {
                        if (acp.Course_Offering__c != null 
                         	&& oldACPsMap.get(acp.Id).Course_Offering__c != null
                         	&& acp.Course_Offering__c != oldACPsMap.get(acp.Id).Course_Offering__c) { CourseOfferingIds.add(acp.Course_Offering__c);}

						// The 'old' acp has a NULL offering but the 'new' has one
                        if (acp.Course_Offering__c != null 
                            && oldACPsMap.get(acp.Id).Course_Offering__c == null ){CourseOfferingIds.add(acp.Course_Offering__c);}
    
                        if (acp.Deferred_Course_Offering__c != null) { 
                            if (oldACPsMap.get(acp.Id).Deferred_Course_Offering__c == null
                                || acp.Deferred_Course_Offering__c != oldACPsMap.get(acp.Id).Deferred_Course_Offering__c) {
                                CourseOfferingIds.add(acp.Deferred_Course_Offering__c);
                            } 
                        }
                    } else {
                        if (acp.Course_Offering__c != null) {courseOfferingIds.add(acp.Course_Offering__c);}
                        if (acp.Deferred_Course_Offering__c != null) {CourseOfferingIds.add(acp.Deferred_Course_Offering__c);}
                    }

                }
                
                
                if (CourseOfferingIds.size() > 0 ) {

                    // Map of all offers of interest based on above
                    Map<Id, Course_Offering__c> mapOfCourseOfferingIdToCourseOffering = new Map<Id, Course_Offering__c>([
                        SELECT
                            Academic_Calendar_Type__c, Academic_CI_Sequence_Number__c, Admission_Calendar_Description__c, Admission_Calendar_Type__c,
                            Admission_CI_Sequence_Number__c, Attendance_Mode__c, Attendance_Mode_Description__c, Attendance_Type__c,
                            Attendance_Type_Description__c, Commencement_Period__c, Correspondence_Category__c, Course_Code__c, Course_Code_F__c, Course_Title__c,
                            Course_Title_F__c, Course_Version_Number__c, Enrolment_Category__c, Fee_Category__c, Hecs_Payment_Option__c,
                            Unit_Set_Code__c, Unit_Set_Description__c, Unit_Set_Version__c, Location_Code__c, Admission_Category__c
                        FROM Course_Offering__c
                        WHERE Id IN :CourseOfferingIds
                    ]);
        
                    for(Integer i = 0; i < newACPs.size(); i++) {
                        Application_Course_Preference__c acp = newACPs[i];
						Course_Offering__c courseOffering = new Course_Offering__c();
                            
                        if (acp.Course_Offering__c != null && CourseOfferingIds.contains(acp.Course_Offering__c)) {
                            courseOffering = mapOfCourseOfferingIdToCourseOffering.get(acp.Course_Offering__c);
                            
                            acp.Correspondence_Category__c  = courseOffering.Correspondence_Category__c;
                            acp.Enrolment_Category__c       = courseOffering.Enrolment_Category__c;
                            acp.Fee_Category__c             = courseOffering.Fee_Category__c;
                            acp.Fee_Payment_Option__c       = courseOffering.Hecs_Payment_Option__c;
                            
                            // SFTN-652
                            acp.Academic_Calendar_Type__c       = courseOffering.Academic_Calendar_Type__c;
                            acp.Admission_Calendar_Type__c      = courseOffering.Admission_Calendar_Type__c;
                            if(Trigger.isInsert) {
                                // Don't change these on existing ACPs as they are sent outbound and changes will conflict with Callista
                                acp.Academic_CI_Sequence_Number__c  = courseOffering.Academic_CI_Sequence_Number__c;
                                acp.Admission_CI_Sequence_Number__c = courseOffering.Admission_CI_Sequence_Number__c;
                            }                            
                            acp.Attendance_Mode__c              = courseOffering.Attendance_Mode__c;
                            acp.Attendance_Mode_Description__c  = courseOffering.Attendance_Mode_Description__c;
                            acp.Attendance_Type__c              = courseOffering.Attendance_Type__c;
                            acp.Attendance_Type_Description__c  = courseOffering.Attendance_Type_Description__c;
                            acp.Commencement_Period__c          = courseOffering.Admission_Calendar_Description__c;
                            acp.Course_Code__c                  = courseOffering.Course_Code__c == null ? courseOffering.Course_Code_F__c : courseOffering.Course_Code__c;
                            acp.Course_Code_Unique__c           = courseOffering.Course_Code__c + '_' + courseOffering.Course_Version_Number__c;
                            acp.Course_Title__c                 = courseOffering.Course_Title__c == null ? courseOffering.Course_Title_F__c : courseOffering.Course_Title__c;
                            acp.Course_Version_Number__c        = courseOffering.Course_Version_Number__c;
                            acp.Unit_Set_Code__c                = courseOffering.Unit_Set_Code__c;
                            acp.Unit_Set_Description__c         = courseOffering.Unit_Set_Description__c;
                            acp.Unit_Set_Version__c             = courseOffering.Unit_Set_Version__c;
                            acp.Location_Code__c                = courseOffering.Location_Code__c;
                            acp.Admission_Category__c           = courseOffering.Admission_Category__c;
	                    }
                        
                        if (acp.Deferred_Course_Offering__c != null && CourseOfferingIds.contains(acp.Deferred_Course_Offering__c)) {
                            courseOffering = mapOfCourseOfferingIdToCourseOffering.get(acp.Deferred_Course_Offering__c);

                            acp.Deferred_Academic_CI_Sequence__c    = courseOffering.Academic_CI_Sequence_Number__c;
                            acp.Deferred_Admission_Calendar_Type__c = courseOffering.Admission_Calendar_Type__c;
                            acp.Deferred_Admission_Ci_Sequence__c   = courseOffering.Admission_CI_Sequence_Number__c;
                            acp.Deferred_Commencement_Period__c     = courseOffering.Admission_Calendar_Description__c;
                        }
                    }
                }
            } 
            catch (Exception e) {
            	LogUtilityException.logException (e,'Application_Course_Preference__c');
            }
        }
    }

    /*
     * @author       Davey Yu
     * @date         27.Apr.2026
     * @description  Timestamp logger for application course preference record
     */
    public class createTimestampLogs extends TriggerAbstract{
         Map<Id, Application_Course_Preference__c> oldApplicationCoursePreferenceMap = new Map<Id, Application_Course_Preference__c>();

        /**
         * Handle after insert event checking and filtering
         */
        public override void process(SObject record) {
            //Include application for processing
            records.add(record);
        }
        
        /**
         * Handle after update event checking and filtering
         */
        public override void process(SObject record, SObject oldRec) {
            //Start process
            Application_Course_Preference__c contextACP = (Application_Course_Preference__c)record;
            Application_Course_Preference__c contextOldACP = (Application_Course_Preference__c)oldRec;

            //Check status change
            if(contextACP.Workflow_Status__c != contextOldACP.Workflow_Status__c){
                records.add(record);
            }
             
          
        }
        
         /*
         * Run functionality logic
         */
        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
           		 Try {
                    //Pass as the newMap record to include related fields.
                    Map<Id, SObject> newACPMap = new Map<Id, SObject>(
                        [SELECT Id, Workflow_Status__c, OnHold_Comments__c, On_Hold_Reason__c,
                            Release_Reason__c, Owner_Name__c, Owner_Team__c, Application__r.Name, Admission_Category__c, Course_Code__c,
                            Course_Level__c, Intake_Period__c, Location_Code__c,Managing_Faculty__c, Person_Id__c,  Application_Course_Preference__c.Name,
                            LastModifiedBy.Name, LastModifiedBy.id
                        FROM Application_Course_Preference__c
                        WHERE Id IN :trigger.newMap.keySet()]
                    );
    
                    TimestampLogger.logChanges(Trigger.oldMap, newACPMap, 'Application_Course_Preference__c', Trigger.isUpdate, Trigger.isInsert);
                 }catch (Exception e) {
                	Nebula.Logger.error('ApplicationCoursePreferenceServices.createTimestampLogs', e);
                    Nebula.Logger.saveLog();
                }
            }
        }
       
    }

    /*
     * @author       Ayush Agrawal
     * @date         08.Apr.2020
     * @description  EPBBS-1011 -> https://confluence.apps.monash.edu/display/EPBBS/New+Course+Admission+Status+Rules
     * @description  SA-1009 -> Implement rule updates received from Admissions (Emmanuel Tse).
     */
    public class generateCourseAdmissionStatus implements Triggers.Handler {
        public void run() {//NOPMD
			
            Map<Id, String> mapOfLOVIdToLOVValue = new Map<Id, String>();

            for (List_of_Values__c lov : [SELECT Id, Value__c FROM List_of_Values__c]) {
                mapOfLOVIdToLOVValue.put(lov.Id, lov.Value__c);
            }

            List<Application_Course_Preference__c> acps = (List<Application_Course_Preference__c>) Trigger.new;
            for (Application_Course_Preference__c acp : acps) {
                String cos = acp.Conditional_Offer_Status_LOV__c != null ? mapOfLOVIdToLOVValue.get(acp.Conditional_Offer_Status_LOV__c) : '';
                String ods = acp.Deferment_Status_LOV__c != null ? mapOfLOVIdToLOVValue.get(acp.Deferment_Status_LOV__c) : '';
                String ds = acp.Documentation_Status_LOV__c != null ? mapOfLOVIdToLOVValue.get(acp.Documentation_Status_LOV__c) : '';
                String eqs = acp.Entry_Qualification_Status_LOV__c != null ? mapOfLOVIdToLOVValue.get(acp.Entry_Qualification_Status_LOV__c) : '';
                String ors = acp.Offer_Response_Status_LOV__c != null ? mapOfLOVIdToLOVValue.get(acp.Offer_Response_Status_LOV__c) : '';
                String os = acp.Outcome_Status_LOV__c != null ? mapOfLOVIdToLOVValue.get(acp.Outcome_Status_LOV__c) : '';
                
                Date cosd = acp.Conditional_Offer_Satisfied_Date__c;

                String cas = null;
                
                if(
                    ((eqs == 'PENDING') && (ds == 'PENDING') && (os == 'IN-PROGRES'))
                    ||
                    ((eqs == 'PENDING') && (ds == 'PENDING') && ( os.startsWith('P-OFF') || os == 'P-REJECT' ))
                ) {
                    // CRSE_STAT == '01'
                    cas = 'In Progress - Faculty';
                } else if(
                    ((eqs == 'PENDING') && (ds == 'INCOMPLETE') && (os == 'IN-PROGRES'))
                    ||
                    ((eqs == 'PENDING') && (ds == 'INCOMPLETE') && (os == 'REJECT-Q'))
                    ||
                    ((eqs == 'PENDING') && (ds == 'PENDING' || ds == 'SATISFIED') && (os == 'REJECT-Q'))
                ) {
                    // CRSE_STAT == '02'
                    cas = 'Pending';
                } else if(
                    ((eqs == 'QUALIFIED') && (ds == 'SATISFIED' || ds == 'DOC-UNCERT' || ds == 'DOC-ENROL') && (os == 'OFFER-PROV' || os == 'OFFER') && (ors == 'PENDING' || ors == 'DEFERRAL' || ors == 'SIGNED' || ors == 'NO-RESP') && (ods == 'APPROVED' || ods == 'APPROVED-R' || ods == 'WITHDRN-CA' || ods == 'NOT-APPLIC' || ods == 'SIGNED'))
                ) {
                    // CRSE_STAT == '03'
                    cas = 'Full Offer';
                } else if(
                    ((eqs == 'QUALIFIED') && (ds == 'SATISFIED') && (os == 'OFFER-COND' || os == 'OFFER-C-E' || os == 'OFFER-C-FY' || os == 'OFFER-C-MC') && (ors == 'PENDING' || ors == 'DEFERRAL' || ors == 'SIGNED' || ors == 'NO-RESP') && (cos == 'SATISFIED') && (cosd != null) && (ods == 'APPROVED' || ods == 'APPROVED-R' || ods == 'WITHDRN-CA' || ods == 'NOT-APPLIC' || ods == 'SIGNED'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'DOC-UNCERT' || ds == 'DOC-ENROL') && (os == 'OFFER-COND' || os == 'OFFER-C-E') && (ors == 'PENDING' || ors == 'DEFERRAL' || ors == 'SIGNED' || ors == 'NO-RESP') && (cos == 'SATISFIED' || cos == 'WAIVED') && (cosd != null) && (ods == 'APPROVED' || ods == 'APPROVED-R' || ods == 'WITHDRN-CA' || ods == 'NOT-APPLIC' || ods == 'SIGNED'))
                ) {
                    // CRSE_STAT == '03'
                    cas = 'Full Offer';
                } else if(
                    ((eqs == 'NOT-QUAL') && (os == 'REJECTED' || os == 'REJ-MICERT' || os == 'REJ-MIDIP' || os == 'REJ-MIMUFY' || os == 'REJ-MINEXT' || os == 'REJECT-GAC' || os == 'REJECT-PSC' || os == 'REJECT-GTE' || os == 'REJECT-Q') && (ds == 'REJECTED'))
                ) {
                    // CRSE_STAT == '04'
                    cas = 'Ineligible';
                } else if(
                    ((eqs == 'QUALIFIED') && (ds == 'SATISFIED' || ds == 'DOC-UNCERT' || ds == 'DOC-ENROL') && (os == 'OFFER-PROV' || os == 'OFFER') && (ors == 'REJECTED' || ors == 'ACC-DEL'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'SATISFIED') && (os == 'OFFER-COND' || os == 'OFFER-C-FY' || os == 'OFFER-C-E' || os == 'OFFER-C-MC') && (ors == 'REJECTED' || ors == 'ACC-DEL') && (cos == 'SATISFIED'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'DOC-UNCERT' || ds == 'DOC-ENROL') && (os == 'OFFER-COND' || os == 'OFFER-C-E') && (ors == 'REJECTED' || ors == 'ACC-DEL') && (cos == 'SATISFIED' || cos == 'WAIVED'))
                ) {
                    // CRSE_STAT == '05'
                    cas = 'Full Offer - Declined';
                } else if(
                    ((os == 'ERROR-ACAT' || os == 'ERROR-CRS' || os == 'ERROR-ACAL' || os == 'CITZ-CHNG' || os =='CHANGE-R'))
                ) {
                    // CRSE_STAT == '07'
                    cas = 'Monash Error';
                } else if(
                    ((eqs == 'QUALIFIED') && (ds == 'DOC-PEND') && (os == 'OFFER-COND' || os == 'OFFER-G-CO') && (ors == 'PENDING' || ors == 'DEFERRAL' || ors == 'SIGNED' || ors == 'NO-RESP') && (ods == 'APPROVED' || ods == 'APPROVED-R' || ods == 'WITHDRN-CA' || ods == 'NOT-APPLIC' || ods == 'SIGNED'))
                ) {
                    // CRSE_STAT == '08'
                    cas = 'Cond Offer';
                } else if(
                    ((eqs == 'PENDING') && (ds == 'PENDING') && (os == 'IN-PROG-MI'))
                ) {
                    // CRSE_STAT == '10'
                    cas = 'In Progress - IRS';
                } else if(
                    ((eqs == 'PENDING') && (os == 'APP-WDRWN'))
                ) {
                    // CRSE_STAT == '12'
                    cas = 'App Withdrawn';
                } else if(
                    ((eqs == 'QUALIFIED') && (ds == 'SATISFIED' || ds == 'DOC-UNCERT' || ds == 'DOC-ENROL') && (os == 'WITHDRAWN' || os == 'WITHDRAWQ' || os == 'WTHDRN-R'))
                ) {
                    // CRSE_STAT == '13'
                    cas = 'Full Offer - Withdrawn';
                } else if(
                    ((eqs == 'QUALIFIED') && (ds == 'DOC-PEND' || ds == 'NOT-REQ') && (os == 'WITHDRAWN'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'DOC-PEND' || ds == 'NOT-REQ' || ds == 'PACK-DOC' || ds == 'PACK-DOC-U') && (os == 'WITHDRAWQ' || os == 'WITHDRAWC' || os == 'WTHDRN-C-R'))
                ) {
                    // CRSE_STAT == '18'
                    cas = 'Cond Offer - Withdrawn';
                } else if(
                    ((eqs == 'QUALIFIED') && (ds == 'DOC-PEND' || ds == 'NOT-REQ') && (os == 'OFFER-COND' || os == 'OFFER-G-CO') && (ors == 'REJECTED' || ors == 'ACC-DEL'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'PACK-DOC') && (os == 'OFFER-COND' || os == 'OFFER-C-E' || os == 'OFFER-C-FY' || os == 'OFFER-C-MC') && (ors == 'REJECTED' || ors == 'ACC-DEL'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'PACK-DOC-U') && (os == 'OFFER-COND' || os == 'OFFER-C-E') && (ors == 'REJECTED' || ors == 'ACC-DEL'))
                ) {
                    // CRSE_STAT == '50'
                    cas = 'Cond Offer - Declined';
                } else if(
                    ((eqs == 'QUALIFIED') && (ds == 'NOT-REQ') && (os == 'OFFER-COND') && (ors == 'PENDING' || ors == 'DEFERRAL' || ors == 'SIGNED' || ors == 'NO-RESP') && (ods == 'APPROVED' || ods == 'APPROVED-R' || ods == 'WITHDRN-CA' || ods == 'NOT-APPLIC' || ods == 'SIGNED'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'PACK-DOC') && (os == 'OFFER-COND' || os == 'OFFER-C-E' || os == 'OFFER-C-FY' || os == 'OFFER-C-MC') && (ors == 'PENDING' || ors == 'DEFERRAL' || ors == 'SIGNED' || ors == 'NO-RESP') && (ods == 'APPROVED' || ods == 'APPROVED-R' || ods == 'WITHDRN-CA' || ods == 'NOT-APPLIC' || ods == 'SIGNED'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'PACK-DOC-U') && (os == 'OFFER-COND' || os == 'OFFER-C-E') && (ors == 'PENDING' || ors == 'DEFERRAL' || ors == 'SIGNED' || ors == 'NO-RESP') && (ods == 'APPROVED' || ods == 'APPROVED-R' || ods == 'WITHDRN-CA' || ods == 'NOT-APPLIC' || ods == 'SIGNED'))
                ) {
                    // CRSE_STAT == '80'
                    cas = 'Packaged Cond Offer';
                } else if(
                    ((eqs == 'QUALIFIED') && (ds == 'DOC-PEND' || ds == 'NOT-REQ') && (os == 'OFFER-COND') && (ors == 'ACCEPT-CND' || ors == 'ACC-C-AG-P'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'DOC-PEND' || ds == 'NOT-REQ') && (os == 'OFFER-COND') && (ors == 'DEFERRAL') && (ods == 'COND-PAID' || ods == 'ACC-C-AG-P'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'PACK-DOC') && (os == 'OFFER-COND' || os == 'OFFER-C-E' || os == 'OFFER-C-FY' || os == 'OFFER-C-MC') && (ors == 'ACCEPT-CND' || ors == 'ACC-C-AG-P'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'PACK-DOC') && (os == 'OFFER-COND' || os == 'OFFER-C-E' || os == 'OFFER-C-FY' || os == 'OFFER-C-MC') && (ors == 'DEFERRAL') && (ods == 'COND-PAID' || ods == 'ACC-C-AG-P'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'PACK-DOC-U') && (os == 'OFFER-COND' || os == 'OFFER-C-E') && (ors == 'ACCEPT-CND' || ors == 'ACC-C-AG-P'))
                    ||
                    ((eqs == 'QUALIFIED') && (ds == 'PACK-DOC-U') && (os == 'OFFER-COND' || os == 'OFFER-C-E') && (ors == 'DEFERRAL') && (ods == 'COND-PAID' || ods == 'ACC-C-AG-P'))
                ) {
                    // CRSE_STAT == '88'
                    cas = 'Cond Offer - Accepted';
                } else if(
                    ((os == 'OFFER' || os == 'OFFER-PROV') && (ors == 'ACCEPTED' || ors == 'ACCEPT-CND' || ors == 'ACCEPT-PRV' || ors =='ACC-C-AG-P') && (eqs == 'QUALIFIED') && (ds == 'SATISFIED' || ds == 'DOC-UNCERT' || ds == 'DOC-ENROL'))
                    ||
                    ((os == 'OFFER' || os == 'OFFER-PROV') && (ors == 'DEFERRAL') && (ods == 'COND-PAID' || ods == 'ACC-C-AG-P') && (eqs == 'QUALIFIED') && (ds == 'SATISFIED' || ds == 'DOC-UNCERT' || ds == 'DOC-ENROL'))
                ) {
                    // CRSE_STAT == '90'
                    cas = 'Full Offer - Accepted';
                } else if(
                    ((ds == 'SATISFIED') && (os == 'OFFER-COND' || os == 'OFFER-C-E' || os == 'OFFER-C-FY' || os == 'OFFER-C-MC') && (cos == 'SATISFIED') && (cosd != null) && (ors == 'ACCEPTED' || ors == 'ACCEPT-CND' || ors == 'ACCEPT-PRV' || ors == 'ACC-C-AG-P') && (eqs == 'QUALIFIED'))
                    ||
                    ((ds == 'SATISFIED') && (os == 'OFFER-COND' || os == 'OFFER-C-E' || os == 'OFFER-C-FY' || os == 'OFFER-C-MC') && (cos == 'SATISFIED') && (cosd != null) && (ors == 'DEFERRAL') && (ods == 'COND-PAID' || ods == 'ACC-C-AG-P') && (eqs == 'QUALIFIED'))
                    ||
                    ((ds == 'DOC-UNCERT' || ds == 'DOC-ENROL') && (os == 'OFFER-COND' || os == 'OFFER-C-E') && (cos == 'SATISFIED' || cos == 'WAIVED') && (cosd != null) && (ors == 'ACCEPTED' || ors == 'ACCEPT-CND' || ors == 'ACCEPT-PRV' || ors == 'ACC-C-AG-P') && (eqs == 'QUALIFIED'))
                    ||
                    ((ds == 'DOC-UNCERT' || ds == 'DOC-ENROL') && (os == 'OFFER-COND' || os == 'OFFER-C-E') && (cos == 'SATISFIED' || cos == 'WAIVED') && (cosd != null) && (ors == 'DEFERRAL') && (ods == 'COND-PAID' || ods == 'ACC-C-AG-P') && (eqs == 'QUALIFIED'))
                ) {
                    // CRSE_STAT == '90'
                    cas = 'Full Offer - Accepted';
                }else if(
                    (os == 'AP-LAPSED')
                ){
                    cas = 'Application Lapsed';
                }
                
                acp.Course_Admission_Status__c = cas;
            }
        }
    }
  
	/*
     * @author       Shalini Mendu
     * @date         11.Nov.2019
     * @description  Send English Test Contact Qualification when ACP is created(updated with AdmissionAppl Number) -SFTN-154
     * @revision 	 Removed SOQL in loop error
     * @revision 	 Hardend up the error checking and handling
     */
    public class createPlatformEventForEnglishTestScore implements Triggers.Handler {
            public void run() {//NOPMD
                
                Map<Id, Application_Course_Preference__c> newACPMap = (Map<Id, Application_Course_Preference__c>) Trigger.newMap;
                Map<Id, Application_Course_Preference__c> oldACPMap = (Map<Id, Application_Course_Preference__c>) Trigger.oldMap;
                Application_Course_Preference__c acpErr = new Application_Course_Preference__c();
                Map<String, Set<String>> queryFields = new Map<String, Set<String>>();
                List<String> queryKeys = new List<String>{
                    'ApplicationIDs'
                };
                
                if (!oldACPMap.isEmpty() && !newACPMap.isEmpty()) {
                    
                    for (String key : queryKeys) {
                        queryFields.put(key, new Set<String>());
                    }

                    for (Application_Course_Preference__c aACP : newACPMap.values()) {
                        if (aACP.Application__c != null) {
                            queryFields.get('ApplicationIDs').add(aACP.Application__c);
                        }
                    }
                    
                    Map<Id, List<Application_Qualification_Provided__c>> aqpMap= new Map <Id, List<Application_Qualification_Provided__c>>();
                    for (Application_Qualification_Provided__c aqp : [select Contact_Qualification__c, Contact_Qualification__r.Id, Application__c, Application__r.Type_Of_Study__c 
                                                                        from Application_Qualification_Provided__c 
                                                                        where Contact_Qualification__r.Qualification_Type__c = 'English Test' 
                                                                        and Application__r.Type_of_Study__c != 'Graduate Research'
                                                                        and Application__c in :queryFields.get('ApplicationIDs')]) {
                        if (!aqpMap.containsKey(aqp.Application__c)) {
                        aqpMap.put(aqp.Application__c, new List<Application_Qualification_Provided__c>());
                        }
                        aqpMap.get(aqp.Application__c).add(aqp);
                    }

                    // Send LOI payload for BDP(Source system=CCT records)
                    List<Application__c> appList = [Select id,name,English_Entry_Mode__c, Meets_Minimum_English__c from Application__c where Id in :queryFields.get('ApplicationIDs') and Source_System__c ='CCT'];

                    try { 
                        for (Application_Course_Preference__c acpRec : newACPMap.values()) {
                            acpErr = acpRec;
                            if (!String.isBlank(String.valueOf(acpRec.Admission_Application_Number__c)) 
                                && String.isBlank(String.valueOf(oldACPMap.get(acpRec.Id).Admission_Application_Number__c))) {
                                    // Send LOI payload for BDP(Source system=CCT records)
                                    for(Application__c app: appList)
                                    {
                                        ObdLOIEnglishInterface.fireOutboundRequest(app.Id, app.English_Entry_Mode__c, app.Meets_Minimum_English__c );
                                    }

                                    if (aqpMap.containsKey(acpRec.Application__c)) {
                                        for (Application_Qualification_Provided__c aqp : aqpMap.get(acpRec.Application__c)) {
                                            EnglishTestScoreInterface.fireOutboundRequest(new List<Id>{aqp.Contact_Qualification__r.Id});
                                        }
                                    }
                            }
                        }
                    } catch (Exception e){
                        LogUtilityException.logException (e, '\r For ID: '+ acpErr.id);
                    }
                }
            }
        }
    
   /*
    * @author       ?
    * @date         ?
    * @description  ?
    */
    @AuraEnabled(cacheable=false)
    public static List<Application_Course_Preference__c> selectACPOfferedByApplicantId(String applicantId) {
        List<Application_Course_Preference__c> acps = new List<Application_Course_Preference__c>();
        List<Application_Course_Preference__c> tmp = new ACPSelector().selectOfferedByApplicantId(applicantId);
        Map<String, Map<String, String>> citizenshipTypes = MyApplicationUtilities.getDynamicCitizenship();

        for (Application_Course_Preference__c acp : tmp) {
            if (isEligibleACP(acp, citizenshipTypes)) {
                acps.add(acp);
            }
        }
        return acps;
    }

	/**
	 * @author      Arnie Ug
	 * @description method to support selectACPOfferedByApplicantId in relation to CognitiveComplexity
	 * @revision    14/05/2025 - Arnie Ug - Created
	 */
    private static Boolean isEligibleACP(Application_Course_Preference__c acp, Map<String, Map<String, String>> citizenshipTypes) {
        if (acp.Application__r.Campus_Location__c == null || acp.Application__r.Residency_Status__c == null) {
            return false;
        }

        Boolean isInternationalOrOnline = citizenshipTypes.get(acp.Application__r.Campus_Location__c)
            .get(acp.Application__r.Residency_Status__c) == MyApplicationUtilities.INTERNATIONAL
            || acp.Application__r.Campus_Location__c == 'Online';

        if (!isInternationalOrOnline) {
            return false;
        }

        if (acp.Application__r.Campus_Location__c.equalsIgnoreCase('Malaysia')) {
            return isMalaysiaCampusEligible(acp.Application__r.Type_of_Study__c);
        }
        return true;
    }

	/**
	 * @author      Arnie Ug
	 * @description method to support selectACPOfferedByApplicantId in relation to CognitiveComplexity
	 * @revision    14/05/2025 - Arnie Ug - Created
	 */
    private static Boolean isMalaysiaCampusEligible(String typeOfStudy) {
        if (String.isBlank(typeOfStudy)) {
            return false;
        }

        return typeOfStudy.equalsIgnoreCase(Constants.MONASH_ABROAD_SA_STUDY_TYPE)
            || typeOfStudy.equalsIgnoreCase(Constants.MONASH_ABROAD_EX_STUDY_TYPE);
    }

    /*
    * @author       JM Mapanao
    * @date         03.NOV.2020
    * @description  Query to fetch all related ACPs for Domestic Offer
    */
    @AuraEnabled(cacheable=false)
    public static List<Application_Course_Preference__c> selectACPOfferedForDomesticByApplicantId(String applicantId){
        List<Application_Course_Preference__c> acps = new List<Application_Course_Preference__c>();
        // Query all Domestic ACP where ACP.Application__r.Campus_Location__c == 'Australia'
        List<Application_Course_Preference__c> tmp = new ACPSelector().selectOfferedByApplicantId(applicantId);
        Map<String, Map<String, String>> citizenshipTypes = MyApplicationUtilities.getDynamicCitizenship();
        
        for (Application_Course_Preference__c acp : tmp){
            if (acp.Application__r.Campus_Location__c != null && acp.Application__r.Residency_Status__c != null && 
                citizenshipTypes.get(acp.Application__r.Campus_Location__c).get(acp.Application__r.Residency_Status__c) == MyApplicationUtilities.DOMESTIC){
                    acps.add(acp);
            }
        }
        return acps;
    }

   /*
    * @author       Shalini Mendu
    * @date         09.April.2020
    * @description  Assign Residency status on Application on ACP insert/update
    */
    public class assignApplicationResidencyStatus implements Triggers.Handler {
        public void run() {
            List<Application_Course_Preference__c> newACPs = Trigger.new;
            Map<Id, Id> acpCOIdMap = new Map<Id, Id>();
            Map<Id, Id> acpAppIdMap = new Map<Id, Id>();

            populateACPMaps(newACPs, acpCOIdMap, acpAppIdMap);

            Map<Id, Course_Offering__c> coMap = getCourseOfferings(acpCOIdMap.values());
            List<Application__c> appList = getApplications(acpAppIdMap.values());

            if (!appList.isEmpty()) {
                updateResidencyStatus(acpCOIdMap, acpAppIdMap, coMap, appList);
            }
        }

        /**
         * @author      Arnie Ug
         * @description method to support assignApplicationResidencyStatus.run in relation to CognitiveComplexity
         * @revision    14/05/2025 - Arnie Ug - Created
         */
        private void populateACPMaps(List<Application_Course_Preference__c> newACPs, Map<Id, Id> acpCOIdMap, Map<Id, Id> acpAppIdMap) {
            for (Application_Course_Preference__c acp : newACPs) {
                acpCOIdMap.put(acp.Id, acp.Course_Offering__c);
                acpAppIdMap.put(acp.Id, acp.Application__c);
            }
        }

        /**
         * @author      Arnie Ug
         * @description method to support assignApplicationResidencyStatus.run in relation to CognitiveComplexity
         * @revision    14/05/2025 - Arnie Ug - Created
         */
        private Map<Id, Course_Offering__c> getCourseOfferings(List<Id> courseOfferingIds) {
            return new Map<Id, Course_Offering__c>(
                [SELECT Id, Citizenship_Type__c FROM Course_Offering__c WHERE Id IN :courseOfferingIds]
            );
        }

        /**
         * @author      Arnie Ug
         * @description method to support assignApplicationResidencyStatus.run in relation to CognitiveComplexity
         * @revision    14/05/2025 - Arnie Ug - Created
         */
        private List<Application__c> getApplications(List<Id> applicationIds) {
            return [SELECT Id, Residency_Status__c FROM Application__c WHERE Residency_Status__c = null AND Id IN :applicationIds];
        }

        /**
         * @author      Arnie Ug
         * @description method to support assignApplicationResidencyStatus.run in relation to CognitiveComplexity
         * @revision    14/05/2025 - Arnie Ug - Created
         */
        private void updateResidencyStatus(
            Map<Id, Id> acpCOIdMap,
            Map<Id, Id> acpAppIdMap,
            Map<Id, Course_Offering__c> coMap,
            List<Application__c> appList
        ) {
            Map<Id, Application__c> appMap = new Map<Id, Application__c>(appList);

            for (Id acpId : acpAppIdMap.keySet()) {
                Id coId = acpCOIdMap.get(acpId);
                Course_Offering__c courseOffering = coMap.get(coId);
                Id appId = acpAppIdMap.get(acpId);

                if (appMap.containsKey(appId)) {
                    Application__c app = appMap.get(appId);
                    app.Residency_Status__c = (courseOffering != null ? courseOffering.Citizenship_Type__c : null);
                }
            }

            update appList;
        }
    }

   	/*
     * @author       Shalini Mendu
     * @date         27.JUL.2020
     * @description  Convert Outbound ACP PB to trigger/apex - SFTG-1283
     */
    public class fireCallistaOutbound implements Triggers.Handler 
    {
        public void run() 
        {
            Schema.FieldSet fieldSetObj = Schema.getGlobalDescribe().get('Application_Course_Preference__c').getDescribe().FieldSets.getMap().get('ACP_Field_Updates_For_Outbound_call');
            List<Id> changedList = new List<Id>();
            Map<Id,Application_Course_Preference__c> transferTypeMap = new  Map<Id,Application_Course_Preference__c>([Select id, Application__r.Transfer_Type__c from Application_Course_Preference__c where Id in :Trigger.new]);
            for(Application_Course_Preference__c acp : (List<Application_Course_Preference__c>) Trigger.new)
            {
                for(Schema.FieldSetMember fld: fieldSetObj.getFields())
                {
                    if(transferTypeMap.get(acp.Id).Application__r.Transfer_Type__c!=BDPConstants.CAMPUS_TRANSFER_TYPE
                         &&  UserInfo.getName()!='Automated Process'
                         &&  Trigger.oldMap.get(acp.Id).get(fld.getFieldPath())!=acp.get(fld.getFieldPath()))
                    {
                     
                        if(!changedList.contains(acp.Id))
                        {
                                changedList.add(acp.Id);
                        }
                    }
               }
            }
            if(changedList.size()>0)
            {
                
                ObdACPImplementation.fireCallistaOutboundRequest(changedList);
            }
        }
    }

    /**
    @author Cartick Sub
    @date 22 April 2021
    @group Professional Development
    @description Updates the Managing Faculty Text and Course Type Text fields on ACPs whose parent Course has the Type, Short Course
    @revision
    **/
    public class SetPDFaculty implements Triggers.Handler {

        public final String SHORT_COURSE_TYPE = 'Short_Course';

        public void run() {          
            List<Application_Course_Preference__c> listACPs = (List<Application_Course_Preference__c>)Trigger.new;
            List<Application_Course_Preference__c> listPDACPs = new List<Application_Course_Preference__c>();
            Set<Id> setParentCOIds = new Set<Id>();
            
            for (Application_Course_Preference__c recACP : listACPs) {
                // Process only ACPs whose parent Course Type is Short Course and whose Managing Faculty Text and Course Type Text have not already been updated
                if (recACP.Course_Type__c == SHORT_COURSE_TYPE && String.isBlank(recACP.Course_Type_Text__c) && String.isBlank(recACP.Managing_Faculty_Text__c)) {
                    listPDACPs.add(recACP);
                    // Collect the Ids of the parent Course Offerings
                    setParentCOIds.add(recACP.Course_Offering__c);
                }
            }

            if (!listPDACPs.isEmpty()) {
                // Retrieve the parent Course Offerings from the database - including their parent Course Managing Faculty
                List<Course_Offering__c> listParentCOs = [SELECT Id, Name, Course__r.Managing_Faculty__c FROM Course_Offering__c WHERE Id IN :setParentCOIds];
                // Convert the Course Offerings into a map so records can be accessed by Id
                Map<Id, Course_Offering__c> mapParentCOs = new Map<Id, Course_Offering__c>(listParentCOs);

                // Iterate through new or updated ACPs
                for (Application_Course_Preference__c recPDACP : listPDACPs) {
                    // Use map to get parent Course Offering record by Id on ACP record
                    Course_Offering__c parentCO = mapParentCOs.get(recPDACP.Course_Offering__c);
                    recPDACP.Course_Type_Text__c = SHORT_COURSE_TYPE;
                    // Call helper method to set Managing Faculty Text
                    recPDACP.Managing_Faculty_Text__c = getManagingFacultyTextFromCourse(parentCO.Course__r.Managing_Faculty__c);
                } 
            } 
        }

        /** 
        @description A helper method which returns the correct ACP Managing Faculty Text value according to the parent Course Managing Faculty
        @param courseManagingFaculty The Managing Faculty value on the parent Course
        @return The value to put on the ACP Managing Faculty Text. Will be a blank string if the parent Course is for a non-PD faculty
        @revision
        **/
        private String getManagingFacultyTextFromCourse(String courseManagingFaculty) {
            String result;

            switch on courseManagingFaculty {
                when ('Faculty of Education') {
                    result = 'Faculty of Education';
                }
                when ('Faculty of Medicine, Nursing & Health Sciences') {
                    result = 'Faculty of Medicine, Nursing & Health Sciences';
                }
                when ('Faculty of Business & Economics') {
                    result = 'Faculty of Business & Economics';
                }
                when ('Faculty of Arts') {
                    result = 'Faculty of Arts';
                }
                when ('Monash Sustainable Development Institute') {
                    result = 'Monash Sustainable Development Institute';
                }
                when ('Monash Centre for Professional Development') {
                    result = 'Monash Centre for Professional Development';
                }
                when else {
                    result = '';
                }
            }
            return result;
        }
    }

    /**
    @author Cartick Sub
    @date 2 June 2021
    @group Professional Development
    @description Sets the Faculty_Student_Email_CC__c on Professional Development Application Course Preferences.
    The Process Builder, PD ACP Emails Faculty Default, will send faculty copy emails to that address.
    This trigger logic replaces the Process Builder and Flow both named PD Update Faculty Student Email CC.
    @revision
    **/
    public class SetPDFacultyCCEmail extends TriggerAbstract {
        
        public final String SHORT_COURSE_TYPE = 'Short_Course';
        Set<String> setFaculties = new Set<String>();

        public override void process(SObject record) {
            Application_Course_Preference__c recACP = (Application_Course_Preference__c)record;
            if (recACP.Course_Type__c == SHORT_COURSE_TYPE && String.isBlank(recACP.Faculty_Student_Email_CC__c) && String.isNotBlank(recACP.Managing_Faculty_Text__c)) {
                records.add(recACP);
                setFaculties.add(recACP.Managing_Faculty_Text__c);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Application_Course_Preference__c recACP = (Application_Course_Preference__c)record;
            if (recACP.Course_Type__c == SHORT_COURSE_TYPE && String.isBlank(recACP.Faculty_Student_Email_CC__c) && String.isNotBlank(recACP.Managing_Faculty_Text__c)) {
                records.add(recACP);
                setFaculties.add(recACP.Managing_Faculty_Text__c);
            }
        }

        public override void execute() {  
            if (!records.isEmpty()) {

                // Get the custom metadata type records for the faculties to which the new ACPs relate
                List<Faculty_Custom_Data__mdt> listFacultyCMDT = [SELECT Managing_Faculty__c, Faculty_Student_Email_CC__c FROM Faculty_Custom_Data__mdt WHERE Managing_Faculty__c IN :setFaculties];

                // Build a map of managing faculty to CC email address
                Map<String,String> mapFacultyCCEmail = new Map<String,String>();
                for (Faculty_Custom_Data__mdt facultyCMDT : listFacultyCMDT) {
                    mapFacultyCCEmail.put(facultyCMDT.Managing_Faculty__c, facultyCMDT.Faculty_Student_Email_CC__c);
                }

                // Populate ACP faculty CC email address
                for (Application_Course_Preference__c recACP : (List<Application_Course_Preference__c>)records) {
                    recACP.Faculty_Student_Email_CC__c = mapFacultyCCEmail.get(recACP.Managing_Faculty_Text__c);
                }
            }
        }
    }

    /*
    * @author       Kristian Vegerano
    * @date         13.APR.2022
    * @description  Query to fetch all fee category pricebook mappings
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> retrievefeeCategoryMappings(){
        Map<String, List<String>> feeCategoryMapping = new Map<String, List<String>>();
        for(Fee_Category_Pricebook_Mapping__mdt mapping : [SELECT DeveloperName, Pricebook_External_ID__c FROM Fee_Category_Pricebook_Mapping__mdt WHERE Pricebook_External_ID__c != null]){
            if(!feeCategoryMapping.containsKey(mapping.Pricebook_External_ID__c)){
                feeCategoryMapping.put(mapping.Pricebook_External_ID__c, new List<String>());
            }
            feeCategoryMapping.get(mapping.Pricebook_External_ID__c).add(mapping.DeveloperName);
        }

        return feeCategoryMapping;
    }

    /*
        * @author rajesh.punjabi@monash.edu | 25-10-2024     
        * @description Set Routing flag to false and execute routing service (Before Update).
    */
    public class RunACPQueueRouting extends TriggerAbstract {
        /**
        * @description validate if routing flag is set to true, and application status is subnmitted.
        * @author rajesh.punjabi@monash.edu | 25-10-2024 
        * @param rec 
        * @param oldRec 
        **/
        public override void process(SObject rec, SObject oldRec) {
            Application_Course_Preference__c acp    = (Application_Course_Preference__c)rec;
            Application_Course_Preference__c oldACP = (Application_Course_Preference__c)oldRec;
            
            if(acp.Run_Queue_Routing__c == true && oldACP.Run_Queue_Routing__c == false && acp.Application_Status__c == 'Submitted'){
                acp.Run_Queue_Routing__c = false;
                records.add(acp);
            }
        }
    
        /**
        * @description execture routing service for ACPs
        * @author rajesh.punjabi@monash.edu | 25-10-2024 
        **/
        public override void execute() {
            if(!records.isEmpty()) {
                try {
                    List<Async_Process__e> evtList = new List<Async_Process__e>();
                    for(Application_Course_Preference__c acp : (List<Application_Course_Preference__c>)records) {
                        AsyncProcessPayload payload = new AsyncProcessPayload();
                        payload.put ('acpId', acp.Id);
                        Async_Process__e evt = new Async_Process__e (
                            Process_Name__c = 'ACPQueueRoutingPlatformEventHandler',
                            Parameter__c = payload.serialize()
                        );
                        evtList.add(evt);
                    }
                    if(!evtList.isEmpty()) {
                        EventBus.publish(evtList);
                    }
                }  
                catch(Exception ex){
                    Nebula.Logger.error('ApplicationCoursePreferenceServices.RunACPQueueRouting', ex);
                    Nebula.Logger.saveLog();
                }
            }
        }
    }

    /*
        * @author: rajesh.punjabi@monash.edu | 09-JAN-2025
        * @description: Update release flag and release reason when assessment status = On Hold.
    */
    public class UpdateReleaseFlag extends TriggerAbstract {
        
        public override void process(SObject record) {
            Application_Course_Preference__c acp    = (Application_Course_Preference__c)record;
			if(acp.Workflow_Status__c != null){
                acp.Workflow_Status_Date_Change__c = system.now();
            }
        }

        /**
        * @description Check Workflow status and update release reason.
        * @author: rajesh.punjabi@monash.edu | 09-JAN-2025
        * @modified: sravani.naramsetti@monash.edu | 19-MAY-2025
        * @param rec 
        * @param oldRec 
        **/
        public override void process(SObject rec, SObject oldRec) {
            Application_Course_Preference__c acp    = (Application_Course_Preference__c)rec;
            Application_Course_Preference__c oldACP = (Application_Course_Preference__c)oldRec;
            
            if(oldACP.Workflow_Status__c != 'On Hold' && acp.Workflow_Status__c == 'On Hold' && (!String.isBlank(acp.Release_Reason__c))){
                acp.Release_Reason__c = '';
            }

            if(oldACP.Workflow_Status__c != acp.Workflow_Status__c){
                acp.Workflow_Status_Date_Change__c = System.now();
            }
        }
    
        /**
        * @description
        * @author: rajesh.punjabi@monash.edu | 09-JAN-2025
        **/
        public override void execute() {
            //.. No required for before update.
        }
    }

    /*
    * @author       Arnie Ug
    * @date         05.May.2025
    * @description  Create platform event to send GradRes Submission Email 
    */
    public class createPlatformEventForGRSubmission implements Triggers.Handler {
        public void run() {
            List<Application_Course_Preference__c> newACPs = Trigger.new;
            Map<Id, Application_Course_Preference__c> oldACPMap = (Map<Id, Application_Course_Preference__c>) Trigger.oldMap;

            Map<Id,Application_Course_Preference__c> newGradResACPMap = new Map<Id,Application_Course_Preference__c>();
            // only process ACPs where GradRes_Callista_Id__c was populated
            // Added Callista_Student_ID_MIX__c check to ensure it is populated before sending the email
            for(Application_Course_Preference__c acp:newACPs){
                if(acp.GradRes_Callista_Id__c != null && acp.Callista_Student_ID_MIX__c != null && (oldACPMap.get(acp.Id).GradRes_Callista_Id__c == null || oldACPMap.get(acp.Id).Callista_Student_ID_MIX__c == null)){
                    newGradResACPMap.put(acp.Id,acp);
                }
            }

            // filter only ACPs where 
            //    - Application is Submitted
            //    - Application is for Graduate Research
            // also get related fields 
            List<Application_Course_Preference__c> newGradResACPList = [SELECT Id, Callista_Applicant_Id__c, GradRes_Callista_Id__c, Proposed_Commencement_Date__c, Graduate_Research_Application_Type__c,
                                                                                Applicant__r.First_Name__c, Applicant__r.Full_Name__c, Application__r.Name,   
                                                                                Applicant__r.Email, Application__r.Submitted_Date_Time__c, Course__r.Name,Person_ID__c,Callista_Student_ID_MIX__c
                                                                        FROM Application_Course_Preference__c 
                                                                        WHERE Id in :newGradResACPMap.keySet() 
                                                                            AND Application__r.Status__c = 'Submitted'
                                                                            AND Application__r.Type_of_Study__c = 'Graduate Research'
                                                                            AND Application__r.Submitted_Date_Time__c != null];
            
            List<Async_Process__e> eventList = new List<Async_Process__e>();
            if(newGradResACPList.size() > 0){
                for(Application_Course_Preference__c acpInfo : newGradResACPList){
                    GRApplicationSubmissionEmail emailJson = new GRApplicationSubmissionEmail();
                    emailJson.firstName = acpInfo.Applicant__r.First_Name__c;
                    emailJson.fullName = acpInfo.Applicant__r.Full_Name__c;
                    emailJson.applicationId = acpInfo.Application__r.Name;
                    emailJson.callistaApplicantId = acpInfo.Callista_Applicant_Id__c;
                    emailJson.gradResCallistaId = acpInfo.GradRes_Callista_Id__c;
                    emailJson.gradResAppType = acpInfo.Graduate_Research_Application_Type__c;
                    emailJson.proposedCommencementDate = acpInfo.Proposed_Commencement_Date__c != null ? DateTime.newInstance(acpInfo.Proposed_Commencement_Date__c.year(),acpInfo.Proposed_Commencement_Date__c.month(),acpInfo.Proposed_Commencement_Date__c.day()).format('dd MMM YYYY') : null;
                    emailJson.recipientEmail = acpInfo.Applicant__r.Email;
                    emailJson.course = acpInfo.Course__r.Name;
                    emailJson.submitedDate = acpInfo.Application__r.Submitted_Date_Time__c.format('dd MMM yyyy hh:mm a', 'Australia/Sydney');
                    emailJson.monashPersonId = acpInfo.Callista_Student_ID_MIX__c;
                    String jsonRequestString = JSON.serializePretty(emailJson);
                    //email will be sent via platform event flow as a workaround because with the current user execution mode, user doesnt have access to the org wide email 
                    eventList.add(new Async_Process__e(
                        Process_Name__c = 'GRApplicationSubmissionEmail',
                        Parameter__c = jsonRequestString
                    ));
                }

                try {
                    // Publish events
                    List<Database.SaveResult> results = EventBus.publish(eventList);
                    Nebula.logger.info('HDRApplication Submission Email event published').addTag('Graduate Research');
                }catch (Exception ex) {
                    Nebula.Logger.error(ex.getMessage(), ex);
                }
                Nebula.Logger.saveLog();
            }
        }
    }

    /*
    * @author       Vishal Gupta
    * @date         28.May.2025
    * @description  Send the application to callista 
    */
    public class RetryHDRIntegration implements Triggers.Handler {
        public void run() {
            List<Application_Course_Preference__c> newACPs = Trigger.new;
            Map<Id, Application_Course_Preference__c> oldACPMap = (Map<Id, Application_Course_Preference__c>) Trigger.oldMap;

            Map<Id,Application_Course_Preference__c> newGradResACPMap = new Map<Id,Application_Course_Preference__c>();
            Integer availableLimit;
            // only process ACPs where Sync_In_Progress__c was checked
            for(Application_Course_Preference__c acp:newACPs){
                if(acp.Sync_In_Progress__c == true && oldACPMap.get(acp.Id).Sync_In_Progress__c == false && acp.GradRes_Callista_Id__c == null){
                    newGradResACPMap.put(acp.Id,acp);
                }
            }

            // filter only ACPs where 
            //    - Application is Submitted
            //    - Application is for Graduate Research
            // also get related fields 
            if(!newGradResACPMap.isEmpty()) {
                
                for(Application_Course_Preference__c acp : [SELECT Application__c, Applicant__c
                                                                        FROM Application_Course_Preference__c 
                                                                        WHERE Id in :newGradResACPMap.keySet() 
                                                                            AND Application__r.Status__c = 'Submitted'
                                                                            AND Application__r.Type_of_Study__c = 'Graduate Research']) {
                    availableLimit = Limits.getLimitQueueableJobs() - Limits.getQueueableJobs();
                    try{
                        GRSendApplicationToCallistaQueuable queueable = new GRSendApplicationToCallistaQueuable(acp.Application__c, acp.Applicant__c);
                        if(availableLimit > 0) {
                            System.enqueueJob(queueable);//NOPMD
                            Nebula.logger.info('HDRApplication sent to callista').addTag('Graduate Research');
                        } else {
                            Nebula.Logger.error('Queuable job limit exceeded. Please untick the Sync_In_Progress__c checkbox and try again the sync again.');
                        }
                    }
                    catch (Exception ex) {
                        Nebula.Logger.error(ex.getMessage(), ex);
                    }
                    Nebula.Logger.saveLog();
                }
            }
        }
    }
}