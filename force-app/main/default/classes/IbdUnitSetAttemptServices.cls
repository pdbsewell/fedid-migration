/**
* @author Ravi Nukala
* @date 26.04.2019
*
* @group Qualification
*
* @description 
* Platform Event handler for contact qualification. Call from subscribing trigger on the IbdUnitSetAttempt__e object.</br>
*
* Process platform events for unit set attempts. <br/>
* USA records are linked to the [student] course attempt record, and should be considered 'inflight' study until there is also a link to a qualification, in which case they have been completed.<br/>
* The link to quaification is only sent when study has completed. This process expects the contact qualification record to exist already and creates/updates an entry in the junction object.<br/>
*
* Retry exceptions are raised for various criteria. There are risks.<br/>
* https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_subscribe_apex_refire.htm<br/>
*
* Delete events set a deleted_in_source flag wich can be used as a filter criteria in the record purge scheduled job.<br/>
*
* Supporting test class: IdbUnitSetAttemptServices_Test<br/>
*
* @revision
* 26.04.2019 Ravi Nukala - Initial version<br/>
* 11.07.2019 Martin Cadman - Added capability for the unit set attempt qualification junction object to allow major/minor to be represented against a qualification. Supports 1 USA to be linked to multiple qualifcations.<br/>
* 01.08.2019 Martin Cadman - Added various field mapping changes.<br/>  
* 01.09.2019 Martin Cadman - Added retry exception handling.<br/>
* 07.09.2019 Martin Cadman - Extended retry exception handling to include parental record locking.<br/>
* 23.09.2019 Martin Cadman - Move to standardised event naming convention and new trigger framework.<br/>
*
**/
public without sharing class IbdUnitSetAttemptServices {
    private static final Integer MAXRETRIES = 3; // Shared between the USA insert and the USA Qual.

    // Exception to allow an eventbus retry to be bubbled up
    public class MyRetryException extends Exception {}
    
    private static final String SCENARIO = 'Inbound Unit Set Attempt';
    
	// Different log message formats    
    private static String msgfmt0 = '{0} {1}';
    private static String msgfmt1 = '{0} - {1}';
    private static String msgfmt2 = '{0}\r\r{1}';
    private static String msgfmt3 = '{0} - {1}\r\r{2}';    
 
    public class EventHandler extends TriggerAbstract {

        // The unique map of the records to be processed        
        private Map<String, IbdUnitSetAttempt__e> aDeleteMap = new Map<String, IbdUnitSetAttempt__e>();
        private Map<String, IbdUnitSetAttempt__e> aUpsertMap = new Map<String, IbdUnitSetAttempt__e>();
        
        // Process the unique map of records
        public override void execute() {
            List<Unit_Set_Attempt__c> upsertList = new List<Unit_Set_Attempt__c>();
            List<Unit_Set_Attempt__c> deleteList = new List<Unit_Set_Attempt__c>();
            List<String> qualList = new List<String>();
            List<Unit_Set_Attempt_Qualification__c> upsertQList = new List<Unit_Set_Attempt_Qualification__c>();
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
            
			nebula.logger.debug('Unit Set Attempt Batchsize ' + trigger.size);
            for (sObject record : trigger.new) {
                IbdUnitSetAttempt__e iEvent = (IbdUnitSetAttempt__e)record;
	            jsonEvent = JSON.serializePretty(iEvent);
                try {
                    if (!String.isBlank(iEvent.Person_ID__c) && !String.isBlank(iEvent.Course_Code__c) && !String.isBlank(iEvent.Unit_Set_Code__c) && !String.isBlank(iEvent.Sequence_Number__c)) {
                        Switch on (iEvent.Event_Type__c!=null?iEvent.Event_Type__c.touppercase():'UNKNOWN') {
                            when 'INSERT','UPDATE' {aUpsertMap.put(getUniquekey(iEvent), iEvent);}
                            when 'DELETE' {aDeleteMap.put(getUniqueKey(iEvent), iEvent);}
                            when else {
                                logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c,'Invalid Event Type', jsonEvent);
			                    nebula.logger.ERROR(logMsg);
                            }
                        }
                    } else {
                        logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c,'Mandatory field not included\rPerson_ID__c, Course_Code__c, Unit_Set_Code__c and Sequence_Number__c must be specified', jsonEvent);
	                    nebula.logger.ERROR(logMsg);
                    }
                } catch (Exception ex) {
					nebula.logger.exception(ex.getMessage(), ex);
                } 
            }
            
			nebula.logger.debug('Unit Set Attempts for processing: ' + Integer.valueOf(aUpsertMap.size() + aDeleteMap.size()));
            try {
                if (aUpsertMap.size() + aDeleteMap.size() > 0) {
                    if (aUpsertMap.size() > 0) {
                        for (IbdUnitSetAttempt__e iEvent : aUpsertMap.values()) { 
                            jsonEvent = JSON.serializePretty(iEvent);
							logMsg = new nebula.LogMessage(msgfmt3, getName(iEvent, False), 'Unit Set Attempt Upsert', jsonEvent);
	                        nebula.logger.info(logMsg);
                            upsertList.add(this.mapEventToObject(iEvent));
		                    qualList.add(iEvent.Qualification_List__c); // Inserts null if empty
                        }
                    }
                    
                    if (aDeleteMap.size() > 0) {
                        for (IbdUnitSetAttempt__e iEvent : aDeleteMap.values()) {          
							jsonEvent = JSON.serializePretty(iEvent);
                            logMsg = new nebula.LogMessage(msgfmt3, getName(iEvent, False), 'Unit Set Attempt Delete', jsonEvent);
	                        nebula.logger.info(logMsg);
                            deleteList.add(this.mapDeleteEventToObject(iEvent));
                        }
                    }                
                }

				nebula.logger.debug('Unit Set Attempts to be upserted: '+upsertList.size());
                if (upsertList.size() > 0) {
                	Database.UpsertResult [] upsertResults = Database.upsert(upsertList, Unit_Set_Attempt__c.Fields.Unique_External_Id__c , false);
                    Database.UpsertResult aResult = null;
                    for (Integer i=0; i<upsertResults.size(); i++) {
                        aResult = upsertResults[i];
                        if (!aResult.isSuccess()) {
                            for (Database.Error err : aResult.getErrors()) {
                                Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, upsertList[i].Person_ID__c, 'Retry SUSA ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
	                                        nebula.logger.warn (logMsg, aResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
                                            logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].Person_ID__c,'Maximum retries (' + MAXRETRIES + ') reached for Unit Set Attempt - ' + err.getMessage());
                                            nebula.logger.error (logMsg, aResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].Person_ID__c,'Unit Set Attempt upsert error - ' + err.getMessage());
	                                    nebula.logger.error(logMsg, aResult);
                                    }
                                }                                
                            }
                        } else {
                            // Note that if a retry happens for SUSA or SUSA Quals, the record link in this log entry may be invalid as any inserts are rolled back
                            nebula.logger.fine('Unit Set Attempt successfully ' + String.valueOf(aResult.isCreated()?'created':'updated') ,aResult.getId());

                            // For each successfully saved SUSA, see if there was an association with a qualification. This happens in Callista at course completion.
                            if (qualList[i] != null ) { 
                                for (String qpk : qualList[i].split(',')) {
                                    // Build the junction object record
                                    upsertQList.add(mapEventToJunction(upsertList[i], qpk.trim()));
                                }                
                            }
                        }
                    }
                } 
                    
                // Process the deletes in this batch last
                nebula.logger.debug('Unit Set Attempts to be deleted: ' + deleteList.size());
                if (deleteList.size() > 0) {
                    Database.UpsertResult [] deleteResults = Database.upsert(deleteList, Unit_Set_Attempt__c.Fields.Unique_External_Id__c, false);
                    Database.UpsertResult aDelResult = null;
                    for (Integer i=0; i<deleteResults.size(); i++) {
                        aDelResult = deleteResults[i];
                        if (!aDelResult.isSuccess()) {
                            for (Database.Error err : aDelResult.getErrors()) {
                                Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, deleteList[i].Person_ID__c, 'Retry SUSA (soft delete) ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
                                            nebula.logger.warn (logMsg, aDelResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
                                            logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].Person_ID__c, 'Maximum retries (' + MAXRETRIES + ') reached for Unit Set Attempt - ' + err.getMessage());
                                            nebula.logger.error (logMsg, aDelResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].Person_ID__c, 'Unit Set Attempt upsert (Delete) error - ' + err.getMessage());
                                        nebula.logger.error(logMsg, aDelResult);
                                    }
                                }                                
                            }
                        } 
                        else {
                            nebula.logger.fine('Unit Set Attempt successfully (soft) deleted',aDelResult.getId());
                        }
                    }
                } 
                    
                // We don't expect the junction record to change after it has been created but upsert is much easier to deal with.
                // It does mean having to have an external key on the junction object.
                // This uses the upsertlist from the initial upsert to log the person id errors.
                nebula.logger.debug('Unit Set Attempt Qualification links to be inserted: ' + upsertQList.size());
                if (upsertQList.size() > 0) {
                    Database.UpsertResult [] upsertResults = Database.upsert(upsertQList,unit_set_attempt_qualification__c.Fields.Unique_Key__c,false);
                    Database.UpsertResult aResultQ = null;
                    for (Integer i=0; i<upsertResults.size(); i++) {
                        aResultQ = upsertResults[i];
                        if (!aResultQ.isSuccess()) {
                            for (Database.Error err : aResultQ.getErrors()) {
                                Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, upsertQList[i].Unique_Key__c.substring(0,8), 'Retry SUSA Qual ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
                                            nebula.logger.warn (logMsg, aResultQ);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
                                            logMsg = new nebula.LogMessage(msgfmt1,upsertQList[i].Unique_Key__c.substring(0,8), 'Maximum retries (' + MAXRETRIES + ') reached for Unit Set Attempt Qualification - ' + err.getMessage());
                                            nebula.logger.error (logMsg, aResultQ);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,upsertQList[i].Unique_Key__c.substring(0,8), 'Unit Set Attempt Qualification upsert error - ' + err.getMessage());
                                        nebula.logger.error(logMsg, aResultQ);
                                    }
                                }                                
                            }
                        } 
                        else {
                            nebula.logger.fine('Unit Set Attempt Qualification successfully ' + String.valueOf(aResultQ.isCreated()?'created':'updated') ,aResultQ.getId());
                        }
                    } 
                }
            } catch (MyRetryException mex) {
                // A retry replays the entire batch, so there is no need to duplicate the logs for each.
				// This does delay when the first message is avaliable in the logs
                if (!nebula.logger.isDebugEnabled()) {nebula.logger.flushBuffer();}
                throw new EventBus.RetryableException('Unit Set Attempt Retry ' + (EventBus.TriggerContext.currentContext().retries + 1) + ' of ' + MAXRETRIES +'\r' + mex.getMessage()+ '\r[[' + tId + ']]'); // add logger transaction id
            } catch (Exception ex) { 
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();                
            }
        }
        
        /**
        @description Builds the UK for the Object
        @param iEvent An individual inbound event
        @return A String representations of the UK 
        */
        private string getUniqueKey(IbdUnitSetAttempt__e iEvent) {
            return iEvent.Person_ID__c + '_' + iEvent.Course_Code__c + '_'+ iEvent.Unit_Set_Code__c + '_' +iEvent.Sequence_Number__c;
        }

        /**
        @description Builds a individual USA - field mappings, including lookups and literals, go here.
        @param iEvent An individual inbound event
        @return A populated base-object with values mapped from the inbound event

		{
        "CreatedById" : "0054a000000IwVbAAK",
        "CreatedDate" : "2020-06-16T00:53:37.000+0000",
        "Unit_Set_Code__c" : "PSYCHOL01",
        "Event_Type__c" : "DELETE",
        "Sequence_Number__c" : "778151",
        "Course_Code__c" : "A2000",
        "Person_ID__c" : "28115120"
        }
        */
        private Unit_Set_Attempt__c mapDeleteEventToObject(IbdUnitSetAttempt__e iEvent) {
            Unit_Set_Attempt__c unitSetAttempt = new Unit_Set_Attempt__c();
            
            unitSetAttempt.deleted_on_source__c = true;
            
            // Fields
            unitSetAttempt.Person_ID__c = iEvent.Person_ID__c;
            unitSetAttempt.Code__c = iEvent.Unit_Set_Code__c;
            unitSetAttempt.Name = iEvent.Person_ID__c + '/' + iEvent.Course_Code__c + '/' + iEvent.Unit_Set_Code__c;
            
            unitSetAttempt.Unique_External_Id__c = getUniqueKey(iEvent);
            
            return unitSetAttempt;
        }

        /**
        @description Builds a individual USA - field mappings, including lookups and literals, go here.
        @param iEvent An individual inbound event
        @return A populated base-object with values mapped from the inbound event

		{
        "Qualification_List__c" : "28115120_A2000_1_1011",
        "Event_Type__c" : "UPDATE",
        "Title__c" : "Philosophy",
        "Rank__c" : "2",
        "CreatedById" : "0054a000000IwVbAAK",
        "Requirements_Complete_Date__c" : "2019-07-15",
        "Selection_Date__c" : "2017-10-31",
        "Category__c" : "EXTENDED MAJOR",
        "CreatedDate" : "2020-06-16T01:11:52.000+0000",
        "Unit_Set_Code__c" : "PHILSPHY03",
        "Version_Number__c" : "1",
        "Sequence_Number__c" : "794954",
        "Course_Code__c" : "A2000",
        "Person_ID__c" : "28115120"
        }

        */
        private Unit_Set_Attempt__c mapEventToObject(IbdUnitSetAttempt__e iEvent) {
            Unit_Set_Attempt__c unitSetAttempt = new Unit_Set_Attempt__c();
            
            // Lookups - Both should be considered mandatory
            unitSetAttempt.Course_Attempt__r = new Course_Attempt__c (Callista_External_Id__c = iEvent.Person_ID__c + '_' + iEvent.Course_Code__c);
            unitSetAttempt.Unit_Set__r = new Course__c(Course_Code__c=iEvent.Unit_Set_Code__c + '_' + iEvent.Version_Number__c);
            
            // Fields
            unitSetAttempt.Person_ID__c = iEvent.Person_ID__c;
            unitSetAttempt.Code__c = iEvent.Unit_Set_Code__c;
            unitSetAttempt.Version__c = iEvent.Version_Number__c;
            unitSetAttempt.Course_Code__c = iEvent.Course_Code__c;
            unitSetAttempt.Title__c = iEvent.Title__c;
            unitSetAttempt.Rank__c = iEvent.Rank__c;
            unitSetAttempt.Category__c = iEvent.Category__c;
            unitSetAttempt.Selection_Date__c = iEvent.Selection_Date__c;
            unitSetAttempt.End_Date__c = iEvent.End_Date__c;
            unitSetAttempt.Requirements_Complete_Date__c = iEvent.Requirements_Complete_Date__c;
            unitSetAttempt.Name = getName(iEvent, False);

            unitSetAttempt.Unique_External_Id__c = getUniqueKey(iEvent);
            
            if (iEvent.Event_Type__c.touppercase() == 'INSERT') {
                unitSetAttempt.deleted_on_source__c = false;
            }
            
            return unitSetAttempt;
        }
        
        /*
        * @description Builds the name for the Object
        * @param iEvent An individual inbound event
        * @return A String representations of the name
        */
        private string getName(IbdUnitSetAttempt__e iEvent, Boolean Deleted) {
            return UnitSetAttemptServices.getUniqueName(iEvent.Person_ID__c, iEvent.Course_Code__c, iEvent.Unit_Set_Code__c, Deleted);
        }

        /**
        @description Builds a individual USAQ (juntion record between USA and CQ) - field mappings, including lookups and literals, go here.
        @param aUSA The parent USA record
        @param qualPK An individual Contact Qualification external key 
        @return A populated base-object with values mapped from the inbound event
        */
        private Unit_Set_Attempt_Qualification__c mapEventToJunction (Unit_Set_Attempt__c aUSA,  String qualPK) {
            Unit_Set_Attempt_Qualification__c aUSAQ = new Unit_Set_Attempt_Qualification__c();
            
            // External key to support upsert
            aUSAQ.Unique_Key__c = qualPK + '_' + aUSA.Code__c ;
            aUSAQ.Contact_Qualification__r = new Contact_Qualification__c(Unique_External_Id__c = qualPK);                
            aUSAQ.Unit_Set_Attempt__c = aUSA.id;
            
            return aUSAQ;
        }
        
    }
}