/**
* @author Martin Cadman
* @date 28.03.2019
*
* @description 
* Platform Event handler for encumbrances. Call from subscribing trigger on the IbdEncumbrance__e object.</br>
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
* Supporting test class: IbdEncumbranceServices_Test<br/>
*
* @revision
* 28.03.2019 Martin Cadman - Initial version<br/>
* 07.09.2019 Martin Cadman - Added retry exception handling, including parental record locking.<br/>
* 23.09.2019 Martin Cadman - Move to standardised event naming convention and new trigger framework.<br/>
* 31.12.2019 Martin Cadman - Allowed inserts to undelete (unset the flag) a record. <br/>
* 05.03.2020 Martin Cadman - Added additional logging.<br/>
* 26.05.2020 Martin Cadman - Ensure that updates/inserts and deletes for the same record in the same batch are processe correctly.<br/>
* 07.06.2020 Martin Cadman - Minor cosmetic changes.<br/>
* 29/05/2024 Martin Cadman - Nebula Logger.<br/>
* 
*/
public class IbdEncumbranceServices {
    private static final Integer MAXRETRIES = 3;

    // Exception to allow an eventbus retry to be bubbled up
    public class MyRetryException extends Exception {}

    private static final String SCENARIO = 'Inbound Encumbrance';
    
	// Different log message formats    
    private static String msgfmt0 = '{0} {1}';
    private static String msgfmt1 = '{0} - {1}';
    private static String msgfmt2 = '{0}\r\r{1}';
    private static String msgfmt3 = '{0} - {1}\r\r{2}';    
    
    public class EventHandler extends TriggerAbstract {
        private Set<String> personIDs = new Set<String>();
        
        public override void execute() {
	        // The unique map of the records to be processed        
    		Map<String,IbdEncumbrance__e> aDeleteMap = new Map<String,IbdEncumbrance__e>();
        	Map<String,IbdEncumbrance__e> aUpsertMap = new Map<String,IbdEncumbrance__e>();
            List<Encumbrance__c> upsertList = new List<Encumbrance__c>();
            List<Encumbrance__c> deleteList = new List<Encumbrance__c>();
			Map<String, Id> scaMap = new Map<String, Id>();
            Map<String, Id> personMap = new Map<String, Id>();
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
            
			nebula.logger.debug('Encumbrance Batchsize ' + trigger.size);
			for (sObject record : trigger.new) {
                IbdEncumbrance__e iEvent = (IbdEncumbrance__e)record;
				jsonEvent = JSON.serializePretty(iEvent);
                try {
                    if (!String.isBlank(iEvent.encumbranceEffectUniqueKey__c) && !String.isBlank(iEvent.Person_ID__c)) {
                        personIDs.add(iEvent.Person_ID__c);
                            Switch on (iEvent.Event_Type__c!=null?iEvent.Event_Type__c.touppercase():'UNKNOWN') {
                            when 'INSERT','UPDATE' {
                                aUpsertMap.put(iEvent.encumbranceEffectUniqueKey__c, iEvent);
                                if (ievent.effectCourseCode__c!=null) {
                                	scaMap.put(iEvent.PERSON_ID__c + '_' + ievent.effectCourseCode__c,null);
                                } else if (ievent.spoCourseCode__c!=null) {
                                    scaMap.put(iEvent.PERSON_ID__c + '_' + ievent.spoCourseCode__c,null);
                                }
                            }
                            when 'DELETE' {aDeleteMap.put(iEvent.encumbranceEffectUniqueKey__c, iEvent);}
                            when else {
                                logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c,'Invalid Event Type', jsonEvent);
			                    nebula.logger.ERROR(logMsg);
                            }
                        }
                    } else {
                        logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c,'Mandatory field not included\rPerson_Id__c and encumbranceEffectUniqueKey__c must be specified', jsonEvent);
	                    nebula.logger.ERROR(logMsg);
                    }
                } catch (Exception ex) {
					nebula.logger.exception(ex.getMessage(), ex);
                } 
            }
            
            try { 
                if (personIDs.size() > 0) {
                    for (Contact con :[select id, person_id__c,(select id, Callista_External_Id__c from course_attempts__r where Callista_External_Id__c in :scaMap.keySet() ) from contact where person_id__c in :personIDs]) {
                        personMap.put(con.person_id__c, con.id);
                        if (con.course_attempts__r.size()==1) {
                            scaMap.put(con.course_attempts__r[0].Callista_External_Id__c,con.course_attempts__r[0].id);
                        } 
                    }
                }

                nebula.logger.debug('Encumbrances for processing: ' + Integer.valueOf(aUpsertMap.size() + aDeleteMap.size()));
                if (aUpsertMap.size() > 0) {
                    for (IbdEncumbrance__e iEvent : aUpsertMap.values()) {          
                        jsonEvent = JSON.serializePretty(iEvent);
						logMsg = new nebula.LogMessage(msgfmt3, iEvent.encumbranceEffectUniqueKey__c.replaceAll('_','/'), 'Encumbrance Upsert', jsonEvent);
                        nebula.logger.info(logMsg);
                        upsertList.add(this.mapEventToObject(iEvent, personMap, scaMap));
                    }
                }

                if (aDeleteMap.size() > 0) {
                    for (IbdEncumbrance__e iEvent : aDeleteMap.values()) {          
                        jsonEvent = JSON.serializePretty(iEvent);
                        logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c, 'Encumbrance Delete', jsonEvent);
                        nebula.logger.info(logMsg);
                        deleteList.add(this.mapDeleteEventToObject(iEvent, personMap));
                    }
                }
                
				nebula.logger.debug('Encumbrances to be upserted: '+upsertList.size());
                if (upsertList.size() > 0) {
                    Database.UpsertResult [] upsertResults = Database.upsert(upsertList, Encumbrance__c.Fields.enceff_key__c, false);
                    Database.UpsertResult aResult = null;
                    for (Integer i=0; i<upsertResults.size(); i++) {
                       aResult = upsertResults[i];
                       if (!aResult.isSuccess()) {
                            for (Database.Error err : aResult.getErrors()) {
								Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, upsertList[i].Person_ID__c, 'Retry Encumbrance ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
	                                        nebula.logger.warn (logMsg, aResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
                                            logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].Person_ID__c,'Maximum retries (' + MAXRETRIES + ') reached for Encumbrance - ' + err.getMessage());
                                            nebula.logger.error (logMsg, aResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].Person_ID__c, 'Encumbrance upsert error - ' + err.getMessage());
                                        nebula.logger.error(LogMsg, aResult);
                                    }
	                            }                                
                            }
                        } else {
                            nebula.logger.fine('Encumbrance successfully ' + String.valueOf(aResult.isCreated()?'created':'updated') ,aResult.getId());
                        }
                    }
                } 
                
                // Process the deletes in this batch last
                // We could add the delete list to the upsertlist and get the same result.
				nebula.logger.debug('Encumbrances to be deleted: ' + deleteList.size());
                if (deleteList.size() > 0) {
                    Database.UpsertResult [] deleteResults = Database.upsert(deleteList, Encumbrance__c.Fields.enceff_key__c, false);
                    Database.UpsertResult aDelResult = null;
                    for (Integer i=0; i<deleteResults.size(); i++) {
                       aDelResult = deleteResults[i];
                       if (!aDelResult.isSuccess()) {
                            for (Database.Error err : aDelResult.getErrors()) {
								Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, deleteList[i].Person_ID__c, 'Retry Encumbrance (soft delete) ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
	                                        nebula.logger.warn (logMsg, aDelResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
                                            logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].Person_ID__c, 'Maximum retries (' + MAXRETRIES + ') reached for Encumbrance - ' + err.getMessage());
                                            nebula.logger.error (logMsg, aDelResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].Person_ID__c, 'Encumbrance upsert (delete) error - ' + err.getMessage());
                                        nebula.logger.error(LogMsg, aDelResult);
                                    }
	                            }                                
                            }
                        } else {
                            nebula.logger.fine('Encumbrance successfully (soft) deleted',aDelResult.getId());
                        }
                    }
                } 
                
            } catch (MyRetryException mex) {
				// A retry replays the entire batch, so there is no need to duplicate the logs for each.
				// This does delay when the first message is avaliable in the logs
                if (!nebula.logger.isDebugEnabled()) {nebula.logger.flushBuffer();}
                throw new EventBus.RetryableException('Encumbrance Retry ' + (EventBus.TriggerContext.currentContext().retries + 1) + ' of ' + MAXRETRIES +'\r' + mex.getMessage() + '\r[[' + tId + ']]'); // add logger transaction id
            } catch (Exception ex) { 
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();                
            }
        }
        
       /*
        * @description Returns a populated encumbrance object for a delete event, which has few field mapping and may have different field handling
        * @param iEvent A single inbound event record
        * @param personMap Map of person ids and contact ids  
        * @return A encumbrance record populated from the inbound event, including calculated lookups and composite fields. 
        * 
        *   {
            "CreatedById" : "0050I000007dkSFQAY",
            "encumbranceEffectUniqueKey__c" : "32323232_INV-FEE_2002-01-10-000000_RVK_SRVC_2002-01-10-000000_13197",
            "CreatedDate" : "2020-06-05T07:30:31.000+0000",
            "Event_Type__c" : "DELETE",
            "effectTypeApplyToCourseInd__c" : false,
            "financialIndicator__c" : false,
            "PERSON_ID__c" : "32323232",
            "encumbranceUniqueKey__c" : "32323232_INV-FEE_2002-01-10-000000"
            }
        */
        private Encumbrance__c mapDeleteEventToObject(IbdEncumbrance__e iEvent, Map<String, Id> personMap) {
            Encumbrance__c encumbrance = new Encumbrance__c();

            encumbrance.enceff_key__c = iEvent.encumbranceEffectUniqueKey__c.touppercase();
            encumbrance.eff_apply_course__c = iEvent.effectTypeApplyToCourseInd__c;
            encumbrance.financial_ind__c = iEvent.financialIndicator__c;
            encumbrance.Person_ID__c = iEvent.PERSON_ID__c;

            if (personMap.containsKey(iEvent.Person_Id__c)) {
                encumbrance.Contact__c = personMap.get(iEvent.Person_Id__c);
            } else {
            	encumbrance.Contact__r = new Contact(Person_id_unique__c = iEvent.Person_Id__c);
	        }

			// If a deleted encumbrance is sent first, the fields used to name the record are null
			// todo move to services class to ensure naming conventions are enforced
			encumbrance.Name = '[Pending Delete] ' + iEvent.PERSON_ID__c;
            
            encumbrance.deleted_in_source__c = true;
            
            return encumbrance;
        }

       /*
        * @description Builds a individual Encumbrance - field mappings, including lookups and literals, go here.
        * @param iEvent An individual inbound event
        * @param personMap Map of person ids and contact ids
        * @return A populated base-object with values mapped from the inbound event
		* {
            "encumbranceStartDate__c" : "2002-01-10",
            "penUpdateOn__c" : "2020-06-05",
            "encumbranceLevel__c" : 3.0,
            "Event_Type__c" : "UPDATE",
            "effectExpiryDate__c" : "2020-06-05",
            "effectTypeApplyToCourseInd__c" : false,
            "effectType__c" : "RVK_SRVC",
            "encumbranceTypeGeneralInfo__c" : "Non-payment of any fee except HECS.\nStudent not allowed a Transcript\nStudent not allowed to Graduate",
            "effectDescription__c" : "ALL SERVICES REVOKED",
            "encumbranceDescription__c" : "INVALIDATION - UNPAID FEES",
            "penUpdateWho__c" : "RNANCARR",
            "CreatedById" : "0050I000007dkSFQAY",
            "effectStartDate__c" : "2002-01-10",
            "PERSON_ID__c" : "32323232",
            "encumbranceExpiryDate__c" : "2020-06-05",
            "effectUpdateWho__c" : "RNANCARR",
            "encumbranceComments__c" : "STUDENT INVALIDATED DUE TO NON PAYMENT OF FEES",
            "encumbranceType__c" : "INV-FEE",
            "authorisedBy__c" : "ERRIT JAMES TREVOR DE JONG",
            "encumbranceUniqueKey__c" : "32323232_INV-FEE_2002-01-10-000000",
            "authPersonId__c" : "18094414",
            "sEncumbranceCat__c" : "ADMIN",
            "encumbranceEffectUniqueKey__c" : "32323232_INV-FEE_2002-01-10-000000_RVK_SRVC_2002-01-10-000000_13197",
            "CreatedDate" : "2020-06-05T07:30:25.000+0000",
            "financialIndicator__c" : true,
            "effectUpdateOn__c" : "2020-06-05",
            "effectSequenceNumber__c" : "13197"
            }
        */
        private Encumbrance__c mapEventToObject(IbdEncumbrance__e iEvent, Map<String, Id> personMap, Map<String, Id> scaMap) {
            Encumbrance__c encumbrance = new Encumbrance__c();

            encumbrance.enceff_key__c = iEvent.encumbranceEffectUniqueKey__c.touppercase();
            encumbrance.eff_apply_course__c = iEvent.effectTypeApplyToCourseInd__c;
            encumbrance.financial_ind__c = iEvent.financialIndicator__c;
            encumbrance.Person_ID__c = iEvent.PERSON_ID__c;

			encumbrance.Name = iEvent.PERSON_ID__c;
            if (iEvent.sEncumbranceCat__c != null) encumbrance.Name = encumbrance.Name + '/' + iEvent.sEncumbranceCat__c;
            if (iEvent.encumbranceType__c != null) encumbrance.Name = encumbrance.Name + '/' + iEvent.encumbranceType__c ;
            if (iEvent.effectType__c!= null) encumbrance.Name = encumbrance.Name + '/' + iEvent.effectType__c;
            
            encumbrance.eff_course_code__c = iEvent.effectCourseCode__c;
            encumbrance.eff_description__c = iEvent.effectDescription__c;
            encumbrance.eff_expiry_date__c = iEvent.effectExpiryDate__c;
            encumbrance.eff_sequence__c = iEvent.effectSequenceNumber__c;
            encumbrance.eff_start_date__c = iEvent.effectStartDate__c;
            encumbrance.eff_type__c = iEvent.effectType__c;
            
            encumbrance.enc_exclusionstartdate__c = iEvent.ExclusionStartDate__c;
            encumbrance.enc_Authorised_By__c = iEvent.authorisedBy__c;
            encumbrance.enc_Authorised_By_ID__c = iEvent.authPersonId__c;
            encumbrance.enc_category__c = iEvent.sEncumbranceCat__c;
            encumbrance.enc_comments__c = iEvent.encumbranceComments__c;
            encumbrance.enc_course_code__c = iEvent.spoCourseCode__c;
            encumbrance.enc_description__c = iEvent.encumbranceDescription__c;
            encumbrance.enc_expired__c = iEvent.expiryAuthorisedBy__c;
            encumbrance.enc_expired_id__c = iEvent.expiryAuthPersonId__c;
            encumbrance.enc_expiry_date__c = iEvent.encumbranceExpiryDate__c;
            encumbrance.enc_info__c = iEvent.encumbranceTypeGeneralInfo__c;
            encumbrance.enc_level__c = iEvent.encumbranceLevel__c;
            encumbrance.enc_sequence__c = iEvent.spoSeqNumber__c;
            encumbrance.enc_start_date__c = iEvent.encumbranceStartDate__c;
            encumbrance.enc_type__c = iEvent.encumbranceType__c;
            
            if (personMap.containsKey(iEvent.Person_Id__c)) {
                encumbrance.Contact__c = personMap.get(iEvent.Person_Id__c);
            } else {
            	encumbrance.Contact__r = new Contact(Person_id_unique__c = iEvent.Person_Id__c);
	        }
            
            if(iEvent.effectCourseCode__c != null) {
                if (scaMap.ContainsKey(iEvent.Person_Id__c + '_' + iEvent.effectCourseCode__c)) {
                    encumbrance.eff_course_code_lookup__c = scaMap.get(iEvent.Person_Id__c + '_' + iEvent.effectCourseCode__c);
                }
            } else if (iEvent.spoCourseCode__c != null) {
                if (scaMap.ContainsKey(iEvent.Person_Id__c + '_' + iEvent.spoCourseCode__c)) {
                    encumbrance.eff_course_code_lookup__c = scaMap.get(iEvent.Person_Id__c + '_' + iEvent.spoCourseCode__c);
                }
            }
            
            if(iEvent.ExclusionCourseGroup__c != null){
                encumbrance.enc_course_group__r = new Course_Group__c(Course_Group__c = iEvent.ExclusionCourseGroup__c);
            }
            
            if (iEvent.Event_Type__c.touppercase() == 'INSERT') {
                encumbrance.deleted_in_source__c = false;
            }
            
            return encumbrance;
        }
    }
}