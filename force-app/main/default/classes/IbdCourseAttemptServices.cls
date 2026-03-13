/**
* @author Gabriel Ludik
* @date 25.04.2018
*
* @group Qualification
*
* @description 
* Platform Event handler for course attempts. Call from subscribing trigger on the IbdCourseAttempt__e object.</br>
*
* Course Attempts are courses studied by a student. They are directly related to a contact record.<br/>
* Unit Attempts within a course attempt context denote subjects being studied.<br/>
* Unit Set Attempts within a course attempt context denote specialisations.<br/>
*
* Retry exceptions are raised for various criteria. There are risks.<br/>
* https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_subscribe_apex_refire.htm<br/>
*
* Delete events set a deleted_in_source flag wich can be used as a filter criteria in the record purge scheduled job.<br/>
*
* Supporting test class: IbdCourseAttemptServices_Test<br/>
*
* @revision
* 24.04.2018 Gabriel Ludik - Initial version<br/>
* 27.04.2018 Stefan Scheit - Updates<br/>
* 13.12.2018 Nick Guia - Added fields in mapEventToObject<br/>
* 07.09.2019 Martin Cadman - Major rewrite to bring this class into alignment with other inbound platform event handling. This removed delete and duplicate check logic.<br/>
* 23.09.2019 Martin Cadman - Move to standardised event naming convention and new trigger framework.<br/>
* 31.12.2019 Martin Cadman - Allowed inserts to undelete (unset the flag) a record. <br/>
* 07.06.2020 Martin Cadman - Ensure that updates/inserts and deletes for the same record in the same batch are processe correctly.<br/>
* 01.07.2020 Martin Cadman - Introduced intermission fields.<br/>
* 13.07.2020 Martin Cadman - Forced intermission future dates to be nulled.<br/>
* 26.04.2021 Martin Cadman - Updated Name handling.<br/>
* 25.05.2021 Martin Cadman - Granted advanced standing field mapping<br/>
* 26.04.2024 Martin Cadman - Included logger entries - including using the triggercontext to pass the logger transaction id between event retries<br/>
*
*/
public class IbdCourseAttemptServices {
    private static final Integer MAXRETRIES = 3;
    
    private static final String SCENARIO = 'Inbound Course Attempts';

    // Exception to allow an eventbus retry to be bubbled up
    public class MyRetryException extends Exception {}

	// Different log message formats    
    private static String msgfmt0 = '{0} {1}';
    private static String msgfmt1 = '{0} - {1}';
    private static String msgfmt2 = '{0}\r\r{1}';
    private static String msgfmt3 = '{0} - {1}\r\r{2}';
    
    public class EventHandler extends TriggerAbstract {
        private Set<String> personIDs = new Set<String>();
        private Set<String> acpIDs = new Set<String>();

        public override void execute() {
        	// The unique map of the records to be processed        
            Map<String,IbdCourseAttempt__e> aDeleteMap = new Map<String,IbdCourseAttempt__e>();
            Map<String,IbdCourseAttempt__e> aUpsertMap = new Map<String,IbdCourseAttempt__e>();
            List<Course_Attempt__c> upsertList = new List<Course_Attempt__c>();
            List<Course_Attempt__c> deleteList = new List<Course_Attempt__c>();
            Map<String,ID> personMap = new Map<String,ID>();
            Map<String,ID> acpMap = new Map<String,ID>();
            String jsonEvent;
            nebula.logMessage logMsg;
            
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
            
            // Stopped utilising the process method to breakup the trigger - this approach appears more performant
            for (sObject record : trigger.new) {
	            IbdCourseAttempt__e iEvent = (IbdCourseAttempt__e)record;
				jsonEvent = JSON.serializePretty(iEvent);
    			try {
                    if (!String.isBlank(iEvent.Person_ID__c) && !String.isBlank(iEvent.Course_Code__c)) {
                        personIDs.add(iEvent.Person_ID__c);
                        if (!String.isBlank(iEvent.Callista_Admission_Application_Id__c)) {acpIDs.add(iEvent.Callista_Admission_Application_Id__c);}
                        Switch on (iEvent.Event_Type__c!=null?iEvent.Event_Type__c.touppercase():'UNKNOWN') {
                            when 'INSERT','UPDATE' {aUpsertMap.put(getUniqueKey(iEvent), iEvent);}
                            when 'DELETE' {aDeleteMap.put(getUniqueKey(iEvent), iEvent);}
                            when else {
                                logMsg = new nebula.LogMessage(msgfmt2,'Supplied event type is invalid', jsonEvent);
                                nebula.logger.ERROR(logMsg);
                            }
                        }
                    } else {
                        logMsg = new nebula.LogMessage(msgfmt3,'Mandatory field not included', 'Person_ID__c and Course_Code__c must be supplied', jsonEvent);
                        nebula.logger.ERROR(logMsg);
                    }
                } catch (Exception ex) {
                    nebula.logger.exception(ex.getMessage(), ex);
                } finally {
                    nebula.logger.saveLog();
                }
            }

            nebula.logger.debug('Course Attempts for Processing : ' + Integer.valueOf(aUpsertMap.size() + aDeleteMap.size()));
            try {
                if (personIDs.size() > 0) {
                    for (Contact con :[select id, person_id__c from contact where person_id__c in :personIDs]) {
                        personMap.put(con.person_id__c, con.id);
                    }
                }

				if (acpIDs.size() > 0) {
                    for (Application_Course_Preference__c acp :[select id, Callista_Unique_Key_ADM__c from Application_Course_Preference__c where Callista_Unique_Key_ADM__c in :acpIDs]) {
                        acpMap.put(acp.Callista_Unique_Key_ADM__c, acp.id);
                    }
                }

                if (aUpsertMap.size() > 0) {
                    for (IbdCourseAttempt__e iEvent : aUpsertMap.values()) {        
						jsonEvent = JSON.serializePretty(iEvent);
                        logMsg = new nebula.LogMessage(msgfmt3, getName(iEvent,false), 'Course Attempt Upsert', jsonEvent);
                        nebula.logger.info(logMsg);
                        upsertList.add(this.mapEventToObject(iEvent, personMap, acpMap));
                    }
                }

                if (aDeleteMap.size() > 0) {
                    for (IbdCourseAttempt__e iEvent : aDeleteMap.values()) {          
						jsonEvent = JSON.serializePretty(iEvent);
                        logMsg = new nebula.LogMessage(msgfmt3, getName(iEvent,false), 'Course Attempt Delete', jsonEvent);
                        nebula.logger.info(logMsg);
                        deleteList.add(this.mapDeleteEventToObject(iEvent, personMap));
                    }
                }

	            nebula.logger.debug('Course Attempts to be upserted : ' + Integer.valueOf(aUpsertMap.size()));
                if (upsertList.size() > 0) {
                    Database.UpsertResult [] upsertResults = Database.upsert(upsertList, Course_Attempt__c.Fields.Callista_External_Id__c , false);
                    Database.UpsertResult aResult = null;
                    for (Integer i=0; i<upsertResults.size(); i++) {
                       aResult = upsertResults[i];
                       if (!aResult.isSuccess()) {
                            for (Database.Error err : aResult.getErrors()) {
								Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, upsertList[i].Person_ID__c, 'Retry ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1)+ ' - ' + err.getMessage());
	                                        nebula.logger.warn (logMsg, aResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
											nebula.logger.error (upsertList[i].Person_ID__c + ' - Maximum retries (' + MAXRETRIES + ') reached for Course Attempt', aResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].Person_ID__c, 'Course Attempt Upsert error - ' + err.getMessage());
                                        nebula.logger.error(LogMsg, aResult);
                                    }
	                            }                                
                            }
						} else {
							nebula.logger.fine('Course Attempt successfully ' + String.valueOf(aResult.isCreated()?'created':'updated') ,aResult.getId());
                        }
                    }
                } 
                
                // Process the deletes in this batch last
                // We could add the delete list to the upsertlist and get the same result.
	            nebula.logger.debug('Course Attempts to be deleted : ' + Integer.valueOf(aDeleteMap.size()));
                if (deleteList.size() > 0) {
                    Database.UpsertResult [] deleteResults = Database.upsert(deleteList, Course_Attempt__c.Fields.Callista_External_Id__c, false);
                    Database.UpsertResult aDelResult = null;
                    for (Integer i=0; i<deleteResults.size(); i++) {
                       aDelResult = deleteResults[i];
                       if (!aDelResult.isSuccess()) {
                            for (Database.Error err : aDelResult.getErrors()) {
								Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, deleteList[i].Person_ID__c, 'Retry ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1)+ ' - ' + err.getMessage());
	                                        nebula.logger.warn (logMsg, aDelResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
											nebula.logger.error (deleteList[i].Person_ID__c + ' - Maximum retries (' + MAXRETRIES + ') reached for Course Attempt', aDelResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].Person_ID__c, 'Course Attempt upsert (delete) error - ' + err.getMessage());
                                        nebula.logger.error(LogMsg, aDelResult);
                                    }
	                            }                                
                            }
                        } else {
                        	nebula.logger.fine('Course Attempt successfully (soft) deleted', aDelResult.getId());
	                    }
	                }
                } 
                
            } catch (MyRetryException mex) {
				// A retry replays the entire batch, so there is no need to duplicate the logs for each.
				// This does delay when the first message is avaliable in the logs
                if (!nebula.logger.isDebugEnabled()) {nebula.logger.flushBuffer();}
                throw new EventBus.RetryableException('Course Attempt Retry ' + (EventBus.TriggerContext.currentContext().retries + 1) + ' of ' + MAXRETRIES +'\r' + mex.getMessage() + '\r[[' + tId + ']]'); // add logger transaction id
            } catch (Exception ex) { 
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
				nebula.logger.saveLog();
            }
        }
        
       /*
        * @description Builds the UK for the Object
        * @param iEvent An individual inbound event
        * @return A String representations of the UK 
        */
        private string getUniqueKey(IbdCourseAttempt__e iEvent) {
            return iEvent.Person_Id__c + '_' + iEvent.course_code__c;
        }

       /*
        * @description Builds the name for the Object
        * @param iEvent An individual inbound event
        * @return A String representations of the name
        */
        private string getName(IbdCourseAttempt__e iEvent, Boolean Deleted) {
            return CourseAttemptServices.getUniqueName(iEvent.Person_ID__c, iEvent.Course_Code__c, Deleted);
        }
        
        /*
		 * @description Builds a individual CA - field mappings, including lookups and literals, go here.
         * @param iEvent An individual inbound event
         * @return A populated base-object with values mapped from the inbound event
            {
            "Last_Modified_Datetime__c" : "2020-04-16T09:55:52.000+0000",
            "Course_Requirements_Completed__c" : false,
            "Version__c" : "2",
            "CreatedById" : "0050I000007dkSFQAY",
            "Last_Modified_By__c" : "callista",
            "CreatedDate" : "2020-06-08T04:48:39.000+0000",
            "Event_Type__c" : "DELETE",
            "Student_Confirmed__c" : false,
            "Course_Code__c" : "M6012",
            "Person_ID__c" : "32323232"
            }
        */
        private Course_Attempt__c mapDeleteEventToObject(IbdCourseAttempt__e iEvent, Map<String,ID> personMap ) {
            Course_Attempt__c aCA = new Course_Attempt__c();

            // Lookups
            if (personMap.containsKey(iEvent.Person_Id__c)) {
                aCA.Contact__c = personMap.get(iEvent.Person_Id__c);
            } else {
            	aCA.Contact__r = new Contact(Person_id_unique__c = iEvent.Person_Id__c);
	        }
            
            if (!String.isBlank(iEvent.Course_Code__c) && !String.isBlank(iEvent.Version__c)) {
	            aCA.Course__r = new Course__c(Course_Code__c = CourseServices.getCourseCodeUnique(iEvent.Course_Code__c, iEvent.Version__c));
            }
			
            // Fields
            aCA.Name = getName(iEvent, true);
            aCA.Callista_External_Id__c = getUniqueKey(iEvent);
            aCA.Person_ID__c = iEvent.Person_ID__c;

			aCA.deleted_in_source__c = true;
 
            return aCA;
        }

       /**
		@description Builds a individual CA - field mappings, including lookups and literals, go here.
        @param iEvent An individual inbound event
        @return A populated base-object with values mapped from the inbound event

		Below does not contain the Intermission Fields

		{
        "Last_Modified_Datetime__c" : "2021-01-14T00:00:00.000+0000",
        "Fee_Category_Code__c" : "AU_DOM_P21",
        "Last_Modified_By__c" : "callista",
        "Int_Future_Voluntary_Ind__c" : false,
        "Event_Type__c" : "UPDATE",
        "Student_Confirmed__c" : true,
        "COO_Id__c" : "135199",
        "WAM__c" : 80.583,
        "Version__c" : "2",
        "CreatedById" : "0050I000007dkSFQAY",
        "Course_Attempt_Status__c" : "ENROLLED",
        "Fee_Payment_Option_Description__c" : "HECS-HELP DEFERRED ALL OR PARTIAL PAYMENT",
        "Nominated_Completion_Year__c" : 2021.0,
        "Location__c" : "CLAYTON",
        "Course_Code__c" : "D60015",
        "Nominated_Completion_Period__c" : "M",
        "Attendance_Type__c" : "FT",
        "Campus_Location_Description__c" : "CLAYTON",
        "Campus_Location_Type__c" : "CAMPUS",
        "Campus__c" : "CLAYTON",
        "Campus_Country__c" : "AUSTRALIA",
        "GPA__c" : 3.583,
        "Portal_Application_Id__c" : "1149308-D60015-1",
        "Attendance_Mode__c" : "IN",
        "Student_Type__c" : "Domestic",
        "Fee_Payment_Option_Start_Date__c" : "2021-01-13",
        "Course_Requirements_Completed__c" : false,
        "Int_Voluntary_Ind__c" : false,
        "CreatedDate" : "2021-04-28T09:37:31.000+0000",
        "Callista_Admission_Application_Id__c" : "31539386-1-D60015-1",
        "Fee_Payment_Option__c" : "201-P21",
        "Commencement_Date__c" : "2020-03-02",
        "Person_ID__c" : "31539386", 
        "JRG_Ind__c" : true
        }
        */
        private Course_Attempt__c mapEventToObject(IbdCourseAttempt__e iEvent, Map<String,ID> personMap, Map<String,ID> acpMap ) {
            Course_Attempt__c aCA = new Course_Attempt__c();
            
            // Lookups
            if (personMap.containsKey(iEvent.Person_Id__c)) {
                aCA.Contact__c = personMap.get(iEvent.Person_Id__c);
            } else {
            	aCA.Contact__r = new Contact(Person_id_unique__c = iEvent.Person_Id__c);
	        }

            if (!String.isBlank(iEvent.Course_Code__c) && !String.isBlank(iEvent.Version__c)) {
	            aCA.Course__r = new Course__c(Course_Code__c = CourseServices.getCourseCodeUnique(iEvent.Course_Code__c, iEvent.Version__c));
            }
            
            if (acpMap.containsKey(iEvent.Callista_Admission_Application_Id__c)){
                aCA.Application_Course_Preference__c =  acpMap.get(iEvent.Callista_Admission_Application_Id__c);
            }
            
            // Fields
            aCA.Name = getName(iEvent, false);
            aCA.Callista_External_Id__c = getUniqueKey(iEvent);
            aCA.Person_ID__c = iEvent.Person_ID__c;
            
            aCA.Attendance_Mode__c = iEvent.Attendance_Mode__c;
            aCA.Attendance_Type__c = iEvent.Attendance_Type__c;
            aCA.Callista_Admission_Application_Id__c = iEvent.Callista_Admission_Application_Id__c;
            aCA.Commencement_Date__c = iEvent.Commencement_Date__c;
            aCA.COO_Id__c = iEvent.COO_Id__c;
            aCA.Course_Attempt_Status__c = iEvent.Course_Attempt_Status__c;
            aCA.Course_Requirements_Completed__c = iEvent.Course_Requirements_Completed__c;
            aCA.Course_Requirements_Completion_Date__c = iEvent.Course_Requirements_Completion_Date__c;
            aCA.Discontinued_Date__c = iEvent.Discontinued_Date__c;
            
            if (String.isBlank(iEvent.Discontinuation_Code__c)) {
                aCA.Discontinuation_Reason__c = '';
            } else {
                aCA.Discontinuation_Reason__c = iEvent.Discontinuation_Code__c + ' | ' + iEvent.Discontinuation_Reason__c;
            }
            
            aCA.Fee_Category_Code__c = iEvent.Fee_Category_Code__c;
            aCA.Fee_Payment_Option__c = iEvent.Fee_Payment_Option__c;
            aCA.Fee_Payment_Option_Description__c = iEvent.Fee_Payment_Option_Description__c;
            aCA.Fee_Payment_Option_Start_Date__c = iEvent.Fee_Payment_Option_Start_Date__c;
            aCA.Fee_Payment_Option_End_Date__c = iEvent.Fee_Payment_Option_End_Date__c;
            aCA.GPA__c = iEvent.GPA__c;
            aCA.Location__c = iEvent.Location__c;
            aCA.Nominated_Completion_Period__c = iEvent.Nominated_Completion_Period__c;
            aCA.Nominated_Completion_Year__c = iEvent.Nominated_Completion_Year__c;
            aCA.Portal_Application_Id__c = iEvent.Portal_Application_Id__c;
            aCA.Student_Confirmed__c = iEvent.Student_Confirmed__c;
            aCA.WAM__c = iEvent.WAM__c;

            aCA.Campus__c = iEvent.Campus__c;
            aCA.Campus_Location_Description__c = iEvent.Campus_Location_Description__c;
            aCA.Campus_Location_Type__c = iEvent.Campus_Location_Type__c;
            aCA.Campus_Country__c = iEvent.Campus_Country__c;
            aCA.Student_Type__c = iEvent.Student_Type__c;
            
            // Granted_Advanced_Standing_Credit_Points__c is being updated manually until the supporting MIX change is released and the value is being cleared the SCA
            // is updated in MIX and sent via the existing channel.
            //
            // The default value for the field is -1. If this is detected, we know that Callista did not supply the field in the payload.
            //
            if (iEvent.Granted_Advanced_Standing_CP__c != -1) {
                aCA.Granted_Advanced_Standing_Credit_Points__c = iEvent.Granted_Advanced_Standing_CP__c;
            }

            aCA.Estimated_Student_Course_Year__c = iEvent.Estimated_Student_Course_Year__c;
            
            // Intermission Fields
            aCA.Int_Start_Date__c = iEvent.Int_Start_Date__c;
            aCA.Int_End_Date__c = iEvent.Int_End_Date__c;
            aCA.Int_Voluntary_Ind__c = iEvent.Int_Voluntary_Ind__c;
            aCA.Int_Comments__c = iEvent.Int_Comments__c;
            
			// Make sure the future fields are cleared when the intermission becomes current
            aCA.Int_Future_Start_Date__c = iEvent.Int_Future_Start_Date__c==null?null:iEvent.Int_Future_Start_Date__c;
            aCA.Int_Future_End_Date__c = iEvent.Int_Future_End_Date__c==null?null:iEvent.Int_Future_End_Date__c;
            aCA.Int_Future_Voluntary_Ind__c = iEvent.Int_Future_Voluntary_Ind__c==null?null:iEvent.Int_Future_Voluntary_Ind__c;
            aCA.Int_Future_Comments__c = iEvent.Int_Future_Comments__c==null?null:iEvent.Int_Future_Comments__c;

            // Job Ready Graduates indicator
			aCA.JRG_Ind__c = iEvent.JRG_Ind__c;
            
            if (iEvent.Event_Type__c.touppercase() == 'INSERT') {
                aCA.deleted_in_source__c = false;
            }

			// initial_intermit_start_date__c is calulated in the services class.
            
            return aCA;
        }
    }
}