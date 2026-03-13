/**
* @author Martin Cadman
* @date 29.11.2018
*
* @description 
* Platform Event handler for unit attempts. Call from subscribing trigger on the IbdUnitAttempt__e object.</br>
*
* Unit Attempts are subjects studied by a student within the context of a course attempt. They are also directly related to a contact record.<br/>
* The record contains unit information as well as overall result status.<br/>
*
* Retry exceptions are raised for various criteria. There are risks.
* https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_subscribe_apex_refire.htm
*
* Delete events set a deleted_in_source flag wich can be used as a filter criteria in the record purge scheduled job. In the case of encumbrance, 
* setting the deleted_in_soruce__c flag to true will trigger a re-calculation of the isActive flag. 
*
* We often receive updates and deletes for the same record in the same batch. Delete events within a processing batch will take precedents over any 
* updates or inserts for the same key.
* Insert events can 'undelete' a deleted record (i.e. if an insert follows a delete in a separate batch) but updates will not reverse this status. 
* <br/>
*
* Supporting test class: IbdUnitAttemptServices_Test<br/>
*
* @revision
* 29.11.2018 Nick Guia - Initial version<br/>
* 01.07.2019 Martin Cadman - Major rewrite to bring this class into alignment with other inbound platform event handling.<br/>
* 01.08.2019 Martin Cadman - Added various field mapping changes.<br/>  
* 15.08.2019 Martin Cadman - Added faculty lookup.<br/>  
* 01.09.2019 Martin Cadman - Added retry exception handling.<br/>
* 07.09.2019 Martin Cadman - Extended retry exception handling to include parental record locking. UA loads could cause Contact locking.<br/>
* 06.06.2020 Martin Cadman - Ensure that updates/inserts and deletes for the same record in the same batch are processe correctly.<br/>
* 26.10.2020 Martin Cadman - Added teaching responsibility field mapping.<br/>
* 26.04.2021 Martin Cadman - Removed 'process' method. Added Unit Offering lookup to Unit Attempt.<br/>
* 27.04.2021 Martin Cadman - Improved some error handling and reporting
* 02.11.2022 Martin Cadman - Correctly setting the outcome_finalised flag based on payload value.
* 08.05.2024 Martin Cadman - The nebula thing
*
*/
public class IbdUnitAttemptServices {
    private static final Integer MAXRETRIES = 3;

    // Exception to allow an eventbus retry to be bubbled up
    public class MyRetryException extends Exception {}
    
    private static final String SCENARIO = 'Inbound Unit Attempt';
    private static final String REFTAG   = 'Missing Reference Data';
    
	// Different log message formats    
    private static String msgfmt0 = '{0} {1}';
    private static String msgfmt1 = '{0} - {1}';
    private static String msgfmt2 = '{0}\r\r{1}';
    private static String msgfmt3 = '{0} - {1}\r\r{2}';    
    
    public class EventHandler extends TriggerAbstract {
        private Set<String> personIDs = new Set<String>();

        
        // Updates, Inserts and Deletes are all handled in an UPSERT operation.
        public override void execute() {
            // The unique map of the records to be processed        
            Map<String, IbdUnitAttempt__e> aDeleteMap = new Map<String, IbdUnitAttempt__e>();
            Map<String, IbdUnitAttempt__e> aUpsertMap = new Map<String, IbdUnitAttempt__e>();
            Map<String, Id> unitOfferings = new Map<String, Id>();
			Map<String,ID> personMap = new Map<String,ID>();
            List<Unit_Attempt__c> upsertList = new List<Unit_Attempt__c>();
            List<Unit_Attempt__c> deleteList = new List<Unit_Attempt__c>();
            String jsonEvent;
            nebula.LogMessage logMsg;
        	String tId;

			// Set logging to the inbound event scenario, which controls the default logging level etc.
			// See the Logger Scenario Rules custom metadata
            nebula.Logger.setScenario(SCENARIO);       

			// Allow for logs to be linked across event retired by inserting the initial transaction id in the error message
            tId = nebula.Logger.getTransactionId();
            if (EventBus.TriggerContext.currentContext().lastError != null) {
                tId = EventBus.TriggerContext.currentContext().lastError.subStringBetween('[[',']]');
                if (String.isNotEmpty(tId)) {
	                nebula.Logger.setParentLogTransactionId(tId);
                }
            } 
            
			nebula.logger.debug('Unit Attempt Batchsize ' + trigger.size);
			for (sObject record : trigger.new) {
            	IbdUnitAttempt__e iEvent = (IbdUnitAttempt__e)record;
	            jsonEvent = JSON.serializePretty(iEvent);
                try {
                    if (!String.isBlank(iEvent.Person_ID__c) && 
                        !String.isBlank(iEvent.Course_Code__c) && 
                        !String.isBlank(iEvent.Unit_Code__c) && 
                        !String.isBlank(iEvent.Calendar_Type__c) && 
                        !String.isBlank(iEvent.CI_Sequence_Number__c)) {
                        personIDs.add(iEvent.Person_ID__c);
                        Switch on (iEvent.Event_Type__c!=null?iEvent.Event_Type__c.touppercase():'UNKNOWN') {
                            when 'INSERT','UPDATE' {
                                aUpsertMap.put(getUniquekey(iEvent), iEvent);
                                unitOfferings.put(UnitOfferingServices.getUniqueKey(iEvent),null); // No offering id at this point, just the unique keys
                            }
                            when 'DELETE' {aDeleteMap.put(getUniqueKey(iEvent), iEvent);}
                            when else {
                                logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c,'Invalid Event Type', jsonEvent);
			                    nebula.logger.ERROR(logMsg);
                            }
                        }
                    } else {
                        logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c,'Mandatory field not included\rPerson_ID__c, Course_Code__c, Unit_Code__c, Calendar_Type__c and CI_Sequence_Number__c must be supplied', jsonEvent);
	                    nebula.logger.ERROR(logMsg);
                    }
                } catch (Exception ex) {
					nebula.logger.exception(ex.getMessage(), ex);
                } 
            }
            
            try {
				nebula.logger.debug('Unit Attempts for processing: ' + Integer.valueOf(aUpsertMap.size() + aDeleteMap.size()));
	            if (aUpsertMap.size() + aDeleteMap.size() > 0) {
                    if (personIDs.size() > 0) {
                        for (Contact con :[select id, person_id__c from contact where person_id__c in :personIDs]) {
                            personMap.put(con.person_id__c, con.id);
                        }
                    }
                    
                    if (aUpsertMap.size() > 0) {
                        // Complete the list of all unit offerings referenced in this batch
                        // todo - we could consider using the platform cache for offerings
                        for (Unit_Offering__c uo :[select id, UO_Unique_Key__c from unit_offering__c where UO_Unique_Key__c in :unitOfferings.keySet()]) {
                           unitOfferings.put(uo.UO_Unique_Key__c, uo.id);
                        }
                        for (IbdUnitAttempt__e iEvent : aUpsertMap.values()) {     
							jsonEvent = JSON.serializePretty(iEvent);
                            logMsg = new nebula.LogMessage(msgfmt3, getName(iEvent,false), 'Unit Attempt Upsert', jsonEvent);
	                        nebula.logger.info(logMsg);
                            upsertList.add(this.mapEventToObject(iEvent, personMap, unitOfferings));
                        }
                    }
                    
                    if (aDeleteMap.size() > 0) {
                        for (IbdUnitAttempt__e iEvent : aDeleteMap.values()) {          
							jsonEvent = JSON.serializePretty(iEvent);
                            logMsg = new nebula.LogMessage(msgfmt3, getName(iEvent,false), 'Unit Attempt Delete', jsonEvent);
	                        nebula.logger.info(logMsg);
                            deleteList.add(this.mapDeleteEventToObject(iEvent, personMap));
                        }
                    }                
    
					nebula.logger.debug('Unit Attempts to be upserted: '+upsertList.size());
                    if (upsertList.size() > 0) {
                        Database.UpsertResult [] upsertResults = Database.upsert(upsertList, Unit_Attempt__c.Fields.SUA_External_ID__c, false);
                        Database.UpsertResult aResult = null;
                        for (Integer i=0; i<upsertResults.size(); i++) {
                           aResult = upsertResults[i];
                           if (!aResult.isSuccess()) {
                                for (Database.Error err : aResult.getErrors()) {
                                    Switch on (err.getStatusCode()) {
                                        when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                            if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                                logMsg = new nebula.LogMessage(msgfmt1, upsertList[i].Person_ID__c, 'Retry ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
		                                        nebula.logger.warn (logMsg, aResult);
                                                throw new MyRetryException(err.getMessage());
                                            } else {
                                                logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].Person_ID__c,'Maximum retries (' + MAXRETRIES + ') reached for Unit Attempt - ' + err.getMessage());
                                                nebula.logger.error (logMsg, aResult);
                                            }
                                        }
                                        when else {
                                            logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].Person_ID__c,'Unit Attempt Upsert error - ' + err.getMessage());
		                                    nebula.logger.error(logMsg, aResult);
                                        }
                                    }                                
                                }
                           } else {
	                           nebula.logger.fine('Unit Attempt successfully ' + String.valueOf(aResult.isCreated()?'created':'updated') ,aResult.getId());
                           }
                        }
                    } 
                    
                    // Process the deletes in this batch last
                    nebula.logger.debug('Unit Attempts to be deleted: ' + deleteList.size());
                    if (deleteList.size() > 0) {
                        Database.UpsertResult [] deleteResults = Database.upsert(deleteList, Unit_Attempt__c.Fields.SUA_External_ID__c, false);
                        Database.UpsertResult aDelResult = null;
                        for (Integer i=0; i<deleteResults.size(); i++) {
                           aDelResult = deleteResults[i];
                           if (!aDelResult.isSuccess()) {
                                for (Database.Error err : aDelResult.getErrors()) {
                                    Switch on (err.getStatusCode()) {
                                        when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                            if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                                logMsg = new nebula.LogMessage(msgfmt1, deleteList[i].Person_ID__c, 'Retry ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
		                                        nebula.logger.warn (logMsg, aDelResult);
                                                throw new MyRetryException(err.getMessage());
                                            } else {
                                                logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].Person_ID__c, 'Maximum retries (' + MAXRETRIES + ') reached for Unit Attempt - ' + err.getMessage());
                                                nebula.logger.error (logMsg, aDelResult);
                                            }
                                        }
                                        when else {
                                            logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].Person_ID__c, 'Unit Attempt upsert (delete) error - ' + err.getMessage());
                                            nebula.logger.error(logMsg, aDelResult);
                                        }
                                    }                                
                                }
                           } else {
	                           nebula.logger.fine('Unit Attempt successfully (soft) deleted',aDelResult.getId());
                           }
                        }
                    } 
                }
            } catch (MyRetryException mex) {
                // A retry replays the entire batch, so there is no need to duplicate the logs for each.
				// This does delay when the first message is avaliable in the logs
                if (!nebula.logger.isDebugEnabled()) {nebula.logger.flushBuffer();}
                throw new EventBus.RetryableException('Unit Attempt Retry ' + (EventBus.TriggerContext.currentContext().retries + 1) + ' of ' + MAXRETRIES +'\r' + mex.getMessage()+ '\r[[' + tId + ']]'); // add logger transaction id
            } catch (Exception ex) { 
                nebula.logger.exception(ex.getMessage() ,ex);
            } finally {
                nebula.logger.saveLog();
            }
        }

       /*
        * @description Builds the UK for the Object
        * @param iEvent An individual inbound event
        * @return A String representations of the UK 
        */
        private string getUniqueKey(IbdUnitAttempt__e iEvent) {
            return UnitAttemptServices.getUniqueExt(iEvent.Person_ID__c, iEvent.Course_Code__c, iEvent.Unit_Code__c, iEvent.Calendar_Type__c, iEvent.CI_Sequence_Number__c);
        }

       /*
        * @description Builds the name for the Object
        * @param iEvent An individual inbound event
        * @return A String representations of the name
        */
        private string getName(IbdUnitAttempt__e iEvent, Boolean Deleted) {
            return UnitAttemptServices.getUniqueName(iEvent.Person_ID__c, iEvent.Course_Code__c, iEvent.Unit_Code__c
                                                     , iEvent.Teaching_Period__c!=null?iEvent.Teaching_Period__c:iEvent.Calendar_Type__c
                                                     , iEvent.Academic_Year__c!=null?iEvent.Academic_Year__c:iEvent.CI_Sequence_Number__c
                                                     , Deleted);
        }
        
       /*
        * @description Returns a populated unit attempt object
        * @param iEvent A single inbound event record
        * @param personMap Map of person ids and contact ids
        * @return A unit attempt record populated from the inbound event, including calculated lookups and composite fields. 
        * 
 		*	{
            "Show_on_Official_Notifications__c" : false,
			"Unit_Level__c" : "3",
            "Academic_Year__c" : "2020",
            "Event_Type__c" : "INSERT",
            "Unit_Mode__c" : "ON",
            "Enrolled_Credit_Points__c" : 6.000,
            "CreatedById" : "0050I000007dkSFQAY",
            "Unit_Class__c" : "ON-CAMPUS",
            "Unit_Version__c" : 4.0,
            "Location__c" : "CLAYTON",
            "Teaching_Period__c" : "2",
            "Short_Title__c" : "ABNORMAL PSYCHOLOGY",
            "Outcome_Finalised__c" : false,
            "Course_Code__c" : "M3005",
            "Enrolment_Date__c" : "2020-06-06",
            "Org_Unit_Start_Date__c" : "1992-01-01",
            "EFTSL__c" : 0.125,
            "Updated_By__c" : "WESCONNECT",
            "Title__c" : "Abnormal psychology",
            "Calendar_Type__c" : "S2-01",
            "Org_Unit_Code__c" : "50000979",
            "Unit_Code__c" : "PSY3032",
            "CreatedDate" : "2020-06-06T05:06:33.000+0000",
            "Achieved_Credit_Points__c" : 6.000,
            "CI_Sequence_Number__c" : "9139",
            "Status__c" : "ENROLLED",
            "Updated_At__c" : "2020-06-06T00:00:00.000+0000",
            "Org_Unit_Description__c" : "PSYCHOLOGY",
            "Person_ID__c" : "30615127"
            }
        */        
        private Unit_Attempt__c mapEventToObject(IbdUnitAttempt__e iEvent, Map<String,ID> personMap, Map<String, Id> uoMap) {
            Unit_Attempt__c aUA = new Unit_Attempt__c();
            
            // Compsite fields
            aUA.SUA_External_ID__c = getUniqueKey(iEvent); 
            aUA.Name = getName(iEvent, false);
            
            // FK
            aUA.Course_Attempt__r = new Course_Attempt__c(Callista_External_Id__c = iEvent.Person_ID__c + '_' + iEvent.Course_Code__c);
            
            // Lookup to contact
            if (personMap.containsKey(iEvent.Person_Id__c)) {
                aUA.Student__c = personMap.get(iEvent.Person_Id__c);
                nebula.logger.debug('Parent Contact found',aUA.Student__c);
            } else {
            	aUA.Student__r = new Contact(Person_ID_unique__c = iEvent.Person_ID__c);
	        }

            // Mandatory lookups - the database upsert will fail if these fields reference entiries that do not exist
            if (iEvent.Org_Unit_Code__c != null) { aUA.Managing_Faculty__r = new Account(Callista_Org_Unit_Code__c = iEvent.Org_Unit_Code__c);}
            if (iEvent.Teaching_Org_Unit_Code__c != null) { aUA.teaching_responsibility__r = new Account(Callista_Org_Unit_Code__c = iEvent.Teaching_Org_Unit_Code__c);}  
            if (iEvent.CI_Sequence_Number__c != null) { aUA.Teaching_Calendar__r = new Calendar__c(Sequence_Number__c = Integer.valueOf(iEvent.CI_Sequence_Number__c));}

			// Non-mandatory reference  
            String uoKey = UnitOfferingServices.getUniqueKey(iEvent.Unit_Code__c, String.valueOf(Integer.valueOf(iEvent.Unit_Version__c)), iEvent.Calendar_Type__c, iEvent.CI_Sequence_Number__c, iEvent.Location__c, iEvent.Unit_Class__c);
          	
            if (uoMap.get(uoKey)!= null) {
                aUA.Unit_Offering__c = uoMap.get(uoKey);
            } else {
                aUA.Unit_Offering__c = null;
                // Errors indicate the UO reference data needs to be updated
                nebula.LogMessage logMsg = new nebula.LogMessage(msgfmt1, 'Unit Offering not found', uoKey);
                nebula.logger.warn(logMsg, aUA).addTag(REFTAG);
            }
            
            // Field Mappings
            aUA.Academic_Year__c = iEvent.Academic_Year__c;
            aUA.Achieved_Credit_Points__c = iEvent.Achieved_Credit_Points__c;
            aUA.Administrative_Unit_Status__c = iEvent.Administrative_Unit_Status__c;
            aUA.Calendar_Type__c = iEvent.Calendar_Type__c;
            aUA.CI_Sequence_Number__c = iEvent.CI_Sequence_Number__c;
            aUA.Discontinued_Date__c = iEvent.Discontinued_Date__c;
            aUA.EFTSL__c = iEvent.EFTSL__c;
            aUA.Enrolled_Credit_Points__c = iEvent.Enrolled_Credit_Points__c;
            aUA.Enrolment_Date__c = iEvent.Enrolment_Date__c;
            aUA.Grade__c = iEvent.Grade__c;
            aUA.Location__c = iEvent.Location__c;
            aUA.Mark__c = iEvent.Mark__c;
            aUA.Outcome_Date__c = iEvent.Outcome_Date__c;
            aUA.Outcome_Finalised__c = iEvent.Outcome_Finalised__c; 
            aUA.Override_Credit_Points_Reason__c = iEvent.Override_Credit_Points_Reason__c;
            aUA.Person_ID__c = iEvent.Person_ID__c;
            aUA.Result_Type__c = iEvent.Result_Type__c;
            aUA.Rule_Waived_Comments__c = iEvent.Rule_Waived_Comments__c;
            aUA.Rule_Waived_Date__c = iEvent.Rule_Waived_Date__c;
            aUA.Short_Title__c = iEvent.Short_Title__c;
            aUA.Show_on_Official_Notifications__c = iEvent.Show_on_Official_Notifications__c;
            aUA.Status__c = iEvent.Status__c;
            aUA.Teaching_Period__c = iEvent.Teaching_Period__c;
            aUA.Title__c = iEvent.Title__c;
            aUA.Unit_Class__c = iEvent.Unit_Class__c;
            aUA.Unit_Mode__c = iEvent.Unit_Mode__c; // A dependent picklist on unit_class
            aUA.Unit_Code__c = iEvent.Unit_Code__c;
            aUA.Unit_Level__c = iEvent.Unit_Level__c;
            aUA.Unit_Version__c = iEvent.Unit_Version__c;
            aUA.Updated_At__c = iEvent.Updated_At__c;
            aUA.Updated_By__c = iEvent.Updated_By__c;

            if (iEvent.Event_Type__c.touppercase() == 'INSERT') {
                aUA.deleted_in_source__c = false;
            }
            
            return aUA;
        }
        
       /*
        * @description Returns a populated unit attempt object for a delete event, which has few field mapping and may have different field handling
        * @param iEvent A single inbound event record
        * @param personMap Map of person ids and contact ids
        * @return A unit attempt record populated from the inbound event, including calculated lookups and composite fields. 
        * 
        * 	{
            "Show_on_Official_Notifications__c" : false,
            "Calendar_Type__c" : "S2-01",
            "CreatedById" : "0050I000007dkSFQAY",
            "Unit_Code__c" : "PSY3062",
            "CreatedDate" : "2020-06-06T05:06:33.000+0000",
            "Event_Type__c" : "DELETE",
            "CI_Sequence_Number__c" : "9139",
            "Outcome_Finalised__c" : false,
            "Course_Code__c" : "M3005",
            "Person_ID__c" : "30615127"
            }
        */        
        private Unit_Attempt__c mapDeleteEventToObject(IbdUnitAttempt__e iEvent, Map<String,ID> personMap) {
            Unit_Attempt__c aUA = new Unit_Attempt__c();
            
            // Compsite fields
            aUA.SUA_External_ID__c = getUniqueKey(iEvent); 
            aUA.Name = getName(iEvent, true);
            
            // Lookup to contact
            if (personMap.containsKey(iEvent.Person_Id__c)) {
                aUA.Student__c = personMap.get(iEvent.Person_Id__c);
            } else {
            	aUA.Student__r = new Contact(Person_ID_unique__c = iEvent.Person_ID__c);
	        }
            
            aUA.Course_Attempt__r = new Course_Attempt__c(Callista_External_Id__c = iEvent.Person_ID__c + '_' + iEvent.Course_Code__c);
            aUA.Person_ID__c = iEvent.Person_ID__c;
            aUA.Calendar_Type__c = iEvent.Calendar_Type__c;
            aUA.CI_Sequence_Number__c = iEvent.CI_Sequence_Number__c;
            aUA.Unit_Code__c = iEvent.Unit_Code__c;
            
            aUA.deleted_in_source__c = true;
            
            return aUA;
        }

    }
}