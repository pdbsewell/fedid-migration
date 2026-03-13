/**
* @author Ravi Nukala
* @date 26.04.2019
*
* @group Qualification
*
* @description 
* Platform Event handler for contact qualification. Call from subscribing trigger on the IbdQualification__e object.</br>
*
* Contact Qualifications handled by this integration are Monash Teritary quals. They exist with the context of a Course Attempt. 
* Unit Set Attempts are linked to a qualification when the qualification is awarded.<br/>
*
* Retry exceptions are raised for various criteria. There are risks.
* https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_subscribe_apex_refire.htm
*
* Delete events set a deleted_in_source flag wich can be used as a filter criteria in the record purge scheduled job.
*
* Supporting test class: IbdQualificationServices_Test<br/>
*
* @revision
* 26.04.2019 Ravi Nukala - Initial version<br/>
* 01.08.2019 Martin Cadman - Added various field mapping changes.<br/>  
* 01.09.2019 Martin Cadman - Added retry exception handling.<br/>
* 07.09.2019 Martin Cadman - Extended retry exception handling to include parental record locking. <br/>
* 31.12.2019 Martin Cadman - Allowed inserts to undelete (unset the flag) a record. <br/>
* 11.11.2020 Martin Cadman - Aligned code with other inbound classes to ensure deletes are handled correctly with a batch. <br/>
*
*/
public class IbdQualificationServices {
    private static final Integer MAXRETRIES = 3;

    // Exception to allow an eventbus retry to be bubbled up
    public class MyRetryException extends Exception {}

    private static final String SCENARIO = 'Inbound Awards';
    
    // Different log message formats    
    private static String msgfmt0 = '{0} {1}';
    private static String msgfmt1 = '{0} - {1}';
    private static String msgfmt2 = '{0}\r\r{1}';
    private static String msgfmt3 = '{0} - {1}\r\r{2}';    

    public class EventHandler extends TriggerAbstract {

        public override void execute() {
        	// The unique map of the records to be processed        
	        Map<String,IbdQualification__e> aDeleteMap = new Map<String, IbdQualification__e>();
    	    Map<String,IbdQualification__e> aUpsertMap = new Map<String, IbdQualification__e>();
            List<Contact_Qualification__c> upsertList = new List<Contact_Qualification__c>();
            List<Contact_Qualification__c> deleteList = new List<Contact_Qualification__c>();
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
            
			nebula.logger.debug('Award Batchsize ' + trigger.size);
            for (sObject record : trigger.new) {
                IbdQualification__e iEvent = (IbdQualification__e)record;
				jsonEvent = JSON.serializePretty(iEvent);
                try {
                    if(!String.isBlank(iEvent.Person_ID__c) && !String.isBlank(iEvent.Course_Code__c) && !String.isBlank(iEvent.Course_Version__c)&& !String.isBlank(iEvent.Qualification_Code__c )) {
                        Switch on (iEvent.Event_Type__c!=null?iEvent.Event_Type__c.touppercase():'UNKNOWN') {
                            when 'INSERT','UPDATE' {aUpsertMap.put(getUniquekey(iEvent), iEvent);}
                            when 'DELETE' {aDeleteMap.put(getUniqueKey(iEvent), iEvent); }
                            when else {
                                logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c,'Invalid Event Type', jsonEvent);
			                    nebula.logger.ERROR(logMsg);
                            }
                        }
                    } else {
                        logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c,'Mandatory field not included\rPerson_ID__c, Course_Code__c, Course_Version__c and Qualification_Code__c must be specified', jsonEvent);
	                    nebula.logger.ERROR(logMsg);
                    }
                } catch (Exception ex) {
					nebula.logger.exception(ex.getMessage(), ex);
                } 
            }

            nebula.logger.debug('Awards for processing: ' + Integer.valueOf(aUpsertMap.size() + aDeleteMap.size()));
            try {
                if (aUpsertMap.size() + aDeleteMap.size() > 0) {
                    if (aUpsertMap.size() > 0) {
                        for (IbdQualification__e iEvent : aUpsertMap.values()) {          
							jsonEvent = JSON.serializePretty(iEvent);
                            logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c+'/'+iEvent.Qualification_Code__c, 'Award Upsert', jsonEvent);
                            nebula.logger.info(logMsg);
                            upsertList.add(this.mapEventToObject(iEvent));
                        }
                    }
                    
                    if (aDeleteMap.size() > 0) {
                        for (IbdQualification__e iEvent : aDeleteMap.values()) {          
							jsonEvent = JSON.serializePretty(iEvent);
                            logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c+'/'+iEvent.Qualification_Code__c, 'Award Delete', jsonEvent);
                            nebula.logger.info(logMsg);
                            deleteList.add(this.mapDeleteEventToObject(iEvent));
                        }
                    }                
                }

				nebula.logger.debug('Awards to be upserted: '+upsertList.size());
                if (upsertList.size() > 0) {
                	Database.UpsertResult [] upsertResults = Database.upsert(upsertList, Contact_Qualification__c.Fields.Unique_External_Id__c , false);
                    Database.UpsertResult aResult = null;
                    for (Integer i=0; i<upsertResults.size(); i++) {
                        aResult = upsertResults[i];
                        if (!aResult.isSuccess()) {
                            for (Database.Error err : aResult.getErrors()) {
                                Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, upsertList[i].Person_ID__c, 'Retry Award ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
	                                        nebula.logger.warn (logMsg, aResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
                                            logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].Person_ID__c,'Maximum retries (' + MAXRETRIES + ') reached for Award - ' + err.getMessage());
                                            nebula.logger.error (logMsg, aResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].Person_ID__c, 'Award upsert error - ' + err.getMessage());
                                        nebula.logger.error(LogMsg, aResult);
                                    }
                                }                                
                            }
                        } else {
                            nebula.logger.fine('Award successfully ' + String.valueOf(aResult.isCreated()?'created':'updated') ,aResult.getId());
                        }
                    }
                } 
                    
                // Process the deletes in this batch last
				nebula.logger.debug('Awards to be deleted: ' + deleteList.size());
                if (deleteList.size() > 0) {
                    Database.UpsertResult [] deleteResults = Database.upsert(deleteList, Contact_Qualification__c.Fields.Unique_External_Id__c, false);
                    Database.UpsertResult aDelResult = null;
                    for (Integer i=0; i<deleteResults.size(); i++) {
                        aDelResult = deleteResults[i];
                        if (!aDelResult.isSuccess()) {
                            for (Database.Error err : aDelResult.getErrors()) {
                                Switch on (err.getStatusCode()) {
                                    when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                        if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                            logMsg = new nebula.LogMessage(msgfmt1, deleteList[i].Person_ID__c, 'Retry Award (soft delete) ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
	                                        nebula.logger.warn (logMsg, aDelResult);
                                            throw new MyRetryException(err.getMessage());
                                        } else {
                                            logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].Person_ID__c, 'Maximum retries (' + MAXRETRIES + ') reached for Award - ' + err.getMessage());
                                            nebula.logger.error (logMsg, aDelResult);
                                        }
                                    }
                                    when else {
                                        logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].Person_ID__c, 'Award upsert (delete) error - ' + err.getMessage());
                                        nebula.logger.error(LogMsg, aDelResult);
                                    }
                                }                                
                            }
                        } else {
                            nebula.logger.fine('Award successfully (soft) deleted',aDelResult.getId());
                        }
                    }
                } 
            } catch (MyRetryException mex) {
				// A retry replays the entire batch, so there is no need to duplicate the logs for each.
				// This does delay when the first message is avaliable in the logs
                if (!nebula.logger.isDebugEnabled()) {nebula.logger.flushBuffer();}
                throw new EventBus.RetryableException('Award Retry ' + (EventBus.TriggerContext.currentContext().retries + 1) + ' of ' + MAXRETRIES +'\r' + mex.getMessage() + '\r[[' + tId + ']]'); // add logger transaction id
            } catch (Exception e) { 
                nebula.logger.exception(e.getMessage() ,e);
            } finally {
                nebula.logger.saveLog();                
            }
        }

        /**
        @description Builds the UK for the Object
        @param iEvent An individual inbound event
        @return A String representations of the UK 
        */
        private string getUniqueKey(IbdQualification__e iEvent) {
            return iEvent.Person_ID__c + '_' + iEvent.Course_Code__c + '_' +iEvent.Course_Version__c + '_' + iEvent.Qualification_Code__c;
        }

        /**
        @description Builds a individual CQ - field mappings, including lookups and literals, go here.
        @param iEvent An individual inbound event
        @return A populated base-object with values mapped from the inbound event

		{
		"Course_Version__c" : "2",
        "Qualification_Code__c" : "9080",
        "Award_Faculty_Name__c" : "Monash University English Language Centre",
        "Award_Faculty_Code__c" : "50028341",
        "Award_Faculty_Start_Date__c" : "2004-01-01",
        "Award_Institution_Name__c" : "MONASH COLLEGE",
        "Event_Type__c" : "DELETE",
        "Qualification_Name__c" : "Certificate of English (Customised Study Groups)",
        "Award_Institution_Code__c" : "4340",
        "Date_Achieved__c" : "2016-08-02",
        "Obtained_Status__c" : "NON-MONASH-OBTAINED",
        "Testamur_Type__c" : "COMPCSP",
        "Graduation_Date__c" : "2016-07-15",
        "Qualification_Type__c" : "awards",
        "Course_Code__c" : "3649",
        "Person_ID__c" : "28233948"
        }

		For a delete event we do not demand a valid course attempt lookup, just the miniumum fields.

		*/
        private Contact_Qualification__c mapDeleteEventToObject(IbdQualification__e iEvent) {
            Contact_Qualification__c qualification = new Contact_Qualification__c();

            // Unique Key
            qualification.Unique_External_Id__c = getUniqueKey(iEvent);

            // FK
			qualification.Contact__r = new Contact(Person_id_unique__c = iEvent.Person_ID__c);

			// Record Type
            qualification.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();

            // Fields Mappings
            qualification.Qualification_Code__c = iEvent.Qualification_Code__c;
            qualification.Obtained_Status__c = iEvent.Obtained_Status__c;
            qualification.Name_at_Completion__c = iEvent.Name_at_Completion__c;
            qualification.Person_id__c = iEvent.Person_ID__c;
			qualification.deleted_on_source__c = true;            

            return qualification;
        }
 
		/*
		* @description Returns a populated contact qualification object
		* @param iEvent A single inbound event record
		* @return A contact qualification record populated from the inbound event, including calculated lookups and composite fields. 

		{
        "Course_Version__c" : "5",
        "Qualification_Code__c" : "3007",
        "Award_Faculty_Name__c" : "Faculty of Science",
        "Award_Faculty_Code__c" : "50000570",
        "Award_Faculty_Start_Date__c" : "1985-01-01",
        "Award_Institution_Name__c" : "MONASH UNIVERSITY",
        "Event_Type__c" : "INSERT",
        "Qualification_Name__c" : "Doctor of Philosophy",
        "Award_Institution_Code__c" : "3035",
        "Date_Achieved__c" : "2020-11-10",
        "Obtained_Status__c" : "MONASH-OBTAINED",
        "Testamur_Type__c" : "DEGREE",
        "Thesis_Title__c" : "The Water-energy Nexus Framework in Urban Water Management at Precinct Scale",
        "Qualification_Type__c" : "awards",
        "Course_Code__c" : "0057",
        "Person_ID__c" : "25377647"
        }

		*/        
        private Contact_Qualification__c mapEventToObject(IbdQualification__e iEvent) {
            Contact_Qualification__c qualification = new Contact_Qualification__c();

            // Unique Key
            qualification.Unique_External_Id__c = getUniqueKey(iEvent);

            // FK
            qualification.Contact__r = new Contact(Person_id_unique__c = iEvent.Person_ID__c);
            if (iEvent.Person_ID__c != null && iEvent.Course_Code__c != null) { qualification.Course_Attempt__r = new Course_Attempt__c (Callista_External_Id__c = iEvent.Person_ID__c + '_' + iEvent.Course_Code__c);}
            if (iEvent.Award_Faculty_Code__c != null) { qualification.Faculty__r = new Account (Callista_Org_Unit_code__c = iEvent.Award_Faculty_Code__c );}
            
            // Record Type
            qualification.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
            
            // Fields Mappings
            qualification.Person_id__c = iEvent.Person_ID__c;
            qualification.Testamur_Type__c = iEvent.Testamur_Type__c;
            qualification.Qualification_Code__c = iEvent.Qualification_Code__c;
            qualification.Qualification_Mark__c = iEvent.Qualification_Mark__c;
            qualification.Qualification_Grade__c = iEvent.Qualification_Grade__c;
            qualification.Title__c = iEvent.Qualification_Name__c;
            qualification.Other_Qualification__c = iEvent.Qualification_Name__c;
            qualification.Name_at_Completion__c = iEvent.Name_at_Completion__c;
            qualification.Obtained_Status__c = iEvent.Obtained_Status__c;
            
            qualification.Date_Achieved__c = iEvent.Date_Achieved__c;
            qualification.Graduation_Date__c = iEvent.Graduation_Date__c;
            qualification.Thesis_Title__c = iEvent.Thesis_Title__c;
            qualification.Institution_Name__c= iEvent.award_institution_name__c;
            qualification.Institution_Code__c= iEvent.award_institution_Code__c;
            qualification.Verification_Status__c='Verified'; // These are qualifications from Monash and 
            qualification.Instruction_in_English__c=true;

            if (iEvent.Event_Type__c.touppercase() == 'INSERT') {
                qualification.deleted_on_source__c = false;
            }

            return qualification;
        }
    }
}