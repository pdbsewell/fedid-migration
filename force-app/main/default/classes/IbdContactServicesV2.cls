/**
 * @author Martin Cadman
 * @date 12.02.2021
 *
 * @description 
 * Trigger handler class to process IbdContact__e platform events to create, update or soft delete Contact records
 * 
 * Retry exceptions are raised for various criteria when saving Contacts. There are risks.
 * https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_subscribe_apex_refire.htm
 *
 * We often receive updates and deletes for the same record in the same batch. Delete events within a processing batch will take precedents over any 
 * updates or inserts for the same key - that is, they are processed last.
 * 
 * Delete events set a deleted_in_source flag wich can be used as a filter criteria in the record purge scheduled job. Setting this flag has no direct affect on anything
 * record related to the Contact.  Insert events can 'undelete' a deleted record (i.e. if an insert follows a delete in a separate batch) but updates will not reverse this status. 
 * 
 * Two child objects are upserted along with Contact in this class. These types are not created via any other method.
 * Exceptions that arise against name and email upserts are reported and swallowed. The Contact upsert will still take place. 
 * Name__c  : a 'Student Name' type with Callista source - middle name is calculated and salutation is included
 *          : a 'Common Name' type with undefined source will created via the person360Rolldown processing (assuming this is enabled)
 * Email__c : a 'Monash' type with Callista source - must be a valid email address and in a know Monash format
 * 
 * The primary name is decided based on Person360 business rules.
 * 
 * Supporting test class: IbdContactServicesV2_Test
 *
 * @revision
 * 10.03.2021 Martin Cadman - Further name handling changes. Added async rollup call for all successfully upserted contact ids.
 * 22.03.2021 Martin Cadman - Code is getting very entangled with the Person360 logic so have disabled only the minimum funtionality.
 *                            PlatformEventSubscriberConfig was added to the IbdContactTrigger to allow the limiting of the inbContact batch size. 
 *                            [select id, batchsize from PlatformEventSubscriberConfig] using the tooling API to see the value.
 * 30.03.2021 Martin Cadman - Ensure Student Name is only created on update. Name fields are only mapped to the contact for new records
 * 31.03.2021 Martin Cadman - Removed the process method as debug indicated this was processing expensive
 * 01.04.2021 Martin Cadman - Disable individual rollups for Name and Email; call async method at the end of processing
 * 10.09.2021 Stefan Scheit - Propercase enhancement to include word delimiters other than a space
 * 13.09.2021 Martin Cadman - If then logic for only updating preferred name for student records
 * 11.12.2021 Martin Cadman - Monash Email end date handling, reduce duplicate name errors
 * 26.03.2022 Martin Cadman - Start upserting student name records for inserts and updates
 * 20.06.2022 Martin Cadman - Allow the override of a non-null erda salutation for active students 
 * 01.08.2022 Nick Guia     - moved all references of Platform_Event_Integration__mdt to SystemSettingsUtil
 * 22.06.2023 Martin Cadman - Stopped updating the owner of the contacts for existing records
 * 02.08.2023 Martin Cadman - Added option to skip direct creation of the student name for a list of specified record types
 * 07.09.2023 Martin Cadman - Added Role Account (Agency) special handling 
 * 26.02.2024 Martin Cadman - Moved to Nebula Logger
 * 26.04.2024 Martin Cadman - Included logger entries - including using the triggercontext to pass the logger transaction id between event retries
 * 03.10.2024 Martin Cadman - Reorganised the firstname and first_name assignments in the field mapping section
 * 16.11.2024 Martin Cadman - Simplify the salutation assignment. Now we always align the Contact to the data in Callista and let person360 sort it out [EPCP-4036]
 * 23.11.2024 Martin Cadman - Feature switch for end dating Student Names (as we do with email addresses) [EPCP-4058]
 * 23.11.2024 Martin Cadman - Feature switch to allow contacts events to be processed even if the API lastmodified date is out of sequence.[EPCP-4058]
 *
 **/
public without sharing class IbdContactServicesV2 {
    @TestVisible
    private static final String DEFSRCSYS = 'Callista';     // source system
    @TestVisible
    private static final String DEFSTDNM  = 'Student name'; // name classification
    @TestVisible
    private static final String DEFEMCLS  = 'Monash';       // email classification
    @TestVisible
    private static final String SYSTEM_SETTING_FEATURE = 'PE_INTEGRATION_DEFAULT' ;
    private static final String SCENARIO = 'Inbound Contact';
    
    // If set too high there is a risk of heap or cpu errors when under load as the numbr of records being processed by each iteration will increase.
    // Only retry for Contact level errors, not utilised for Name or Email.
    @TestVisible
    private static final Integer MAXRETRIES = 3; 
    
    /*
     * @description Exception to allow an eventbus retry to be bubbled up
     **/
    public class MyRetryException extends Exception {}

	// Different log message formats    
    private static String msgfmt0 = '{0} {1}';
    private static String msgfmt1 = '{0} - {1}';
    private static String msgfmt2 = '{0}\r\r{1}';
    private static String msgfmt3 = '{0} - {1}\r\r{2}';
    
    public static Feature_Switch__c fs = Feature_Switch__c.getInstance();
    
    /*
     * @description Event handler called from the event subscription trigger
     **/
    public without sharing class EventHandler extends TriggerAbstract {
        
        /*
         * @description Updates, Inserts and Deletes are all handled in an UPSERT operation.
         */
        public override void execute() {
            Set<String> personIDs = new Set<String>();
            Set<String> applicantIDs = new Set<String>();
            
            Person360Muting__c p360ctmd = Person360Muting__c.getInstance();
            Set<String> restrictedRT = new Set<String>();
            
            // The unique maps of the records to be processed        
            Map<String, IbdContact__e> aDeleteMap = new Map<String, IbdContact__e>(); // Person Id, event
            Map<String, IbdContact__e> aUpsertMap = new Map<String, IbdContact__e>(); // Person Id, event
            List<Contact> contactUpsertList = new List<Contact>(); // Contact records to be upserted
            List<Contact> contactDeleteList = new List<Contact>(); // Contact records to be soft deleted (updated)
            Map<String,String> eConAsApp = new Map<String,String>();  // applicantid, CRM Id - the crm id of existing contacts matched via application
            Map<String,String> eConAsPer = new Map<String,String>();  // Personid, CRM Id - the crm id of existing contacts matched by person id
            Map<String,Contact> eCon     = new Map<String,Contact>(); // CRM Id, Contact - existing contacts
            Set<Name__c>  nameCpSet      = new Set<Name__c>();  // Name__c records for upserting
            Set<Email__c> emailCpSet     = new Set<Email__c>(); // Email__c records for upserting
            List<String> eventEmail      = new List<String>();  // Monash Emails addresses
            Set<String> cids             = new Set<String>();   // set of contact ids for async rollup
            Contact eContact;             
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
            
            for (sObject record : trigger.new) {
                IbdContact__e iEvent = (IbdContact__e)record;
                jsonEvent = JSON.serializePretty(iEvent);
                    
                try {
                    if (String.isNotBlank(iEvent.Person_ID__c)) {
                        // build a set of person ids included in the batch
                        personIDs.add(iEvent.Person_ID__c);
                        if (!String.isBlank(iEvent.Applicant_IDs__c)) {
                            // build a set of all applicant ids in the batch
                            applicantIDs.addAll(iEvent.Applicant_IDs__c.split(';')); 
                        }
                        switch on (iEvent.Event_Type__c!=null?iEvent.Event_Type__c.touppercase():'UNKNOWN') {
                            // process delete events separately 
                            when 'INSERT','UPDATE' {
                                if (String.isNotBlank(iEvent.Last_Name__c)) {  // Lastname is not mandatory for delete events
                                    aUpsertMap.put(iEvent.Person_ID__c, iEvent);
                                } else {
                                    // Person id is mandatory on the event object, however last name is not (see above)
                                    logMsg = new nebula.LogMessage(msgfmt3,'Mandatory field missing', 'Person_ID__c and Last_Name__c must be supplied', jsonEvent); 
                                    nebula.logger.error(logMsg);
                                }
                            }
                            when 'DELETE' {aDeleteMap.put(iEvent.Person_ID__c, iEvent);}
                            when else {
                                logMsg = new nebula.LogMessage(msgfmt2,'Supplied event type '+ iEvent.Event_Type__c +' is invalid', jsonEvent);
                                nebula.logger.error(logMsg);
                            }
                        }
                    } else {
                        logMsg = new nebula.LogMessage(msgfmt3,'Mandatory field missing', 'Person_ID__c and Last_Name__c must be supplied', jsonEvent);
                        nebula.logger.error(logMsg);
                    }
                } catch (Exception e) {
                    nebula.logger.exception(e.getMessage(), e);
                } finally {
                    nebula.logger.saveLog();
                }
            }
            
            // At this point we have various popualted collections
            // aUpsertMap   - INSERT & UPDATE events, Person Id key (if multiple were received, we have the last one)
            // aDeleteMap   - DELETE events, Person Id key
            // personIDs    - Unique list of Person Ids in the batch
            // applicantIDs - Unique list of Applicant Ids in the batch
            try {
                logMsg = new nebula.LogMessage(msgfmt0, 'Contacts for processing', Integer.valueOf(aUpsertMap.size() + aDeleteMap.size()));
                nebula.logger.debug(logMsg.getMessage());
                if (String.isNotBlank(p360ctmd.Record_Type_Roll_Down_Bypass__c)) {
                    restrictedRT.addAll(p360ctmd.Record_Type_Roll_Down_Bypass__c.toLowerCase().split(',')); 
                }

                if (!aUpsertMap.isEmpty() || !aDeleteMap.isEmpty()) {
                    // Find existing Contact records and the external key we can use to Upsert against
                    if (!applicantIDs.isEmpty()) {
                        eConAsApp = getAppContacts(applicantIDs);
                    }
                    
                    if (!personIDs.isEmpty()) {
                        eConAsPer = getPerContacts(personIDs);
                    }

                    if (!eConAsApp.isEmpty() || !eConAsPer.isEmpty()) {
                        eCon = getExistingContacts(eConAsPer.values(), eConAsApp.values());
                    }

                    // At this point we have more popualted collections
                    // eConAsApp   - applicantid, CRM Id 
                    // eConAsPer   - personid, CRMId
                    // eCon - CRMid, Contact - All existing contacts based on applicant or person id
                    
                    // Process non-delete events
                    if (!aUpsertMap.isEmpty()) {
                        for (IbdContact__e iEvent : aUpsertMap.values()) {          
                            jsonEvent = JSON.serializePretty(iEvent);
                            logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c, 'Contact Upsert', jsonEvent);
                            nebula.logger.info(logMsg);

                            eContact = new Contact();
                            if (!eCon.isEmpty()) {
                                
                                if (eConAsPer.containsKey(iEvent.Person_ID__c) ) {
                                    eContact = eCon.get(eConAsPer.get(iEvent.Person_ID__c));
                                    logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c, 'Matched on Person id', jsonEvent);
                                    nebula.logger.info(logMsg, eContact);
                                }

                                if (eContact.Id == null && !eConAsApp.isEmpty() && String.isNotEmpty(iEvent.Applicant_IDs__c)) {
                                    for (String a : iEvent.Applicant_IDs__c.split(';')) {
                                        if (eConAsApp.containsKey(a)) {
                                            String pId = eCon.get(eConAsApp.get(a)).person_id__c;
                                            if (String.isEmpty(pId) || pId == iEvent.Person_ID__c) {
                                                eContact = eCon.get(eConAsApp.get(a));
			                                    logMsg = new nebula.LogMessage(msgfmt3, a, 'Matched on Applicant Id', jsonEvent);
                                                nebula.logger.info(logMsg, eContact);
                                                break;
                                            } else {
                                                // Stopping the inbound processing from updating a person id
                                                // This condition would be caught as a DB error due to validation rules
                                                logMsg = new nebula.LogMessage(msgfmt1, iEvent.Person_ID__c, 'Matched on Applicant Id ' + a + ' but person ID can not be changed. Event Rejected.');
                                                nebula.logger.error(logMsg, eContact);
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if (eContact.id == null 
                                || eContact.LastModifiedDate_API__c == null 
                                || fs.AllowOutOfSyncEvents__c
                                || (eContact.LastModifiedDate_API__c != null && iEvent.Last_Modified_Date__c >= eContact.LastModifiedDate_API__c)) {
                                contactUpsertList.add(this.mapEventToObject(iEvent, eContact));

                                if (iEvent.Monash_Email__c !=null && (!CommonUtilities.validateEmail(iEvent.Monash_Email__c) || !EmailServices.isMonashEmail(iEvent.Monash_Email__c))) {
                                    eventEmail.add(null); // add email address is blank to align the lists
                                } else{
                                    eventEmail.add(iEvent.Monash_Email__c);
                                }
                            } else {
                                logMsg = new nebula.logMessage(msgfmt1, iEvent.Person_ID__c, 'Contact skipped as payload last update ' + String.valueOf(iEvent.Last_Modified_Date__c) + ' is younger than ' + String.valueOf(eContact.LastModifiedDate_API__c));
                                nebula.logger.warn(logMsg, eContact);
                            }
                        }
                    }
                    

                    // Handle deletes differently. 
                    // Will only attempt a delete if the contact exists and can be identified via the Person Id.
                    if (aDeleteMap.size() > 0) {
                        for (IbdContact__e iEvent : aDeleteMap.values()) {          
                            jsonEvent = JSON.serializePretty(iEvent);
                            logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c, 'Delete', jsonEvent);
                            nebula.logger.debug(logMsg);

                            if (!eConAsPer.isEmpty() && eConAsPer.containsKey(iEvent.Person_ID__c)) { 
                                eContact = new Contact();
                                eContact = eCon.get(eConAsPer.get(iEvent.Person_ID__c));
                                contactDeleteList.add(this.mapDeleteEventToObject(iEvent, eContact));
                            } else {
                                logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c, 'Contact deletion skipped - Person Id does not exist', jsonEvent);
                                nebula.logger.warn(logMsg);
                            }
                        } 
                    }
                    
                    logMsg = new nebula.LogMessage(msgfmt0, 'Contacts to be upserted: ', contactUpsertList.size());
                    nebula.logger.debug(logMsg);
                    if (contactUpsertList.size() > 0) {

                        Triggers.bypass('RollUpLogic'); // batch level rollup is done
                        Triggers.bypass('InvokeRollUpContactPointsAsync'); 
                        Database.UpsertResult [] upsertResults = Database.upsert(contactUpsertList, false);
                        Triggers.Clearbypass('InvokeRollUpContactPointsAsync'); 
                        Triggers.Clearbypass('RollUpLogic');
                        Database.UpsertResult aResult = null;
                        for (Integer i=0; i<upsertResults.size(); i++) {
                           aResult = upsertResults[i];
                           if (!aResult.isSuccess()) {
                                for (Database.Error err : aResult.getErrors()) {
                                    switch on (err.getStatusCode()) {
                                        when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                            if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                                logMsg = new nebula.LogMessage(msgfmt1,contactUpsertList[i].Person_ID_unique__c, 'Contact Retry ' + String.valueOf(EventBus.TriggerContext.currentContext().retries + 1) + ' - ' + err.getMessage());
	                                            nebula.logger.warn (logMsg, aResult); // flushed unless in debug mode
                                                throw new MyRetryException(err.getMessage());
                                            } else {
                                                nebula.logger.error ('Maximum retries (' + MAXRETRIES + ') reached', aResult);
                                            }
                                        }
                                        // Required field missing is only included to support a test method. It is not an error that is remedied by a retry.
                                        // It Is possible to produce this if the lastname field contains only numbers, which are stripped.
                                        when REQUIRED_FIELD_MISSING {
                                            if (EventBus.TriggerContext.currentContext().retries < 1) {
                                                throw new MyRetryException(err.getMessage());
                                            } else {
                                                nebula.logger.error(err.getMessage(), aResult);
                                            }
                                        }
                                        when else {
                                            logMsg = new nebula.LogMessage(msgfmt1,contactUpsertList[i].Person_ID_unique__c,'Contact upsert error - ' + err.getMessage());
		                                    nebula.logger.error(logMsg, aResult);
                                        }
                                    }                                
                                }
                            } else {
                                logMsg = new nebula.LogMessage(msgfmt0,'Contact successfully ',String.valueOf(aResult.isCreated()?'created':'updated'));
                                nebula.logger.fine(logMsg, aResult.getId());

                                // We have a successfully upserted Contact so retain the id for submission to the rollup
                                cids.add(aResult.getId());

                                //**No longer required. Upsert the student name for both inserts and updates.**
                                //Build Student Name entries for successfull Contact *updates*
                                //if (aResult.isCreated() == false){
                                //}

                                // A limited rolldown blocker, primarily to stop non-student records from rolldown (agency role accounts)
                                // 
                                // This works fine when contacts are created in the CRM. However, when a contact is created in Callista and inserted via here, the 
                                // recordtype will be null - name contact points records will be created even if the resulting recordtypes 
                                // have been blocked from rolldown. Not so for updates.
                                if ((restrictedRT.isEmpty() || 
                                   !restrictedRT.contains(contactUpsertList[i].recordtype?.developername?.toLowerCase()) &&
                                   !contactUpsertList[i].Role_Account_Flag__c )) {
                                    nameCpSet.addAll(buildNameRec(contactUpsertList[i]));
                                } 
                                
                                // Build Monash Email entries for successfull Contact upserts
                                // This includes end dating all existing emails if no email address was supplied    
                                if (!contactUpsertList[i].Role_Account_Flag__c) {                   
                                    emailCpSet.addAll(buildEmailRec2(contactUpsertList[i], eventEmail[i]));
                                }
                            }
                        }
                    } 

					logMsg = new nebula.LogMessage(msgfmt0,'Student Names to be upserted : ', nameCpSet.size());
                    nebula.logger.debug(logMsg);
                    if (nameCpSet.size() > 0) {
                        List<Name__c> sn = new list<Name__c>(nameCpSet);
                        Triggers.bypass('RollUpLogic'); // a final rollup is done async later
                        Database.UpsertResult [] upsertNameResults = Database.upsert(sn,  Name__c.Fields.Key_UID__c, false);
                        Triggers.Clearbypass('RollUpLogic');
                        Database.UpsertResult aNameResult = null;
                        for (Integer i=0; i<upsertNameResults.size(); i++) {
                           aNameResult = upsertNameResults[i];
                           if (!aNameResult.isSuccess()) {
                               for (Database.Error err : aNameResult.getErrors()) {
                                    if (StatusCode.DUPLICATE_VALUE == err.getStatusCode()) {
                                        logMsg = new nebula.LogMessage(msgfmt2,'Name key duplicated', JSON.serializePretty(sn[i]));
					                    nebula.logger.fine(logMsg);
                                    }
                                }
                            } else {
                                logMsg = new nebula.LogMessage(msgfmt0,'Name successfully ',String.valueOf(aNameResult.isCreated()?'created':'updated'));
                                nebula.logger.fine(logMsg, aNameResult.getId());
                            }
                        }
                    } 

					logMsg = new nebula.LogMessage(msgfmt0,'Student Emails to be upserted : ', emailCpSet.size());
                    nebula.logger.debug(logMsg);
                    if (emailCpSet.size() > 0) {
                        Triggers.bypass('RollUpLogic'); // a final rollup is done async later
                        Triggers.bypass('FindNewParentChannel'); // Not attached to a channel so redundant processing
                        List<Email__c> se = new list<Email__c>(emailCpSet);
                        Database.UpsertResult [] upsertEmailResults = Database.upsert(se, Email__c.Fields.Key_UID__c, false);
                        Triggers.Clearbypass('RollUpLogic');
                        Triggers.Clearbypass('FindNewParentChannel');
                        Database.UpsertResult aEmailResult = null;
                        for (Integer i=0; i<upsertEmailResults.size(); i++) {
                           aEmailResult = upsertEmailResults[i];
                           if (!aEmailResult.isSuccess()) {
                                for (Database.Error err : aEmailResult.getErrors()) {
                                    switch on (err.getStatusCode()) {
                                        when REQUIRED_FIELD_MISSING {
                                            if (err.getFields().contains('Start Date')) {
												logMsg = new nebula.LogMessage(msgfmt2,'Unable to upsert Monash Email record - check that triggers are active', JSON.serializePretty(se[i]));
                                                nebula.logger.error(logMsg,aEmailResult);
                                            } 
                                        }
                                        when else {
                                            logMsg = new nebula.LogMessage(msgfmt2,err.getMessage(), JSON.serializePretty(se[i]));
						                    nebula.logger.error(logMsg,aEmailResult);
                                        }
                                    }
                                }
                            } else {
                                nebula.logger.fine('Monash Email successfully ' + String.valueOf(aEmailResult.isCreated()?'created':'updated') ,aEmailResult.getId());
                            }
                        }
                    } 
                    
                    // Rollup all contacts that were inserted or updated as part of this batch
                    if (cids.size() > 0) {
                        nebula.logger.debug('Submitting Async Rollup for ' + cids.size() + ' contacts');
                        new Person360RollUpServices.PerformRollUp().run(cids, null, new List<String>{'Email__c','Name__c'}, true);  
                    }
                   
                    // FYI - No name or email records are changed for deleted contacts other than what occurs as part of Person360
                    logMsg = new nebula.LogMessage(msgfmt0,'Contacts to be deleted : ', contactDeleteList.size());
                    nebula.logger.debug(logMsg);
                    if (contactDeleteList.size() > 0) {
                        Triggers.bypass('RollUpLogic');
                        Triggers.bypass('InvokeRollUpContactPointsAsync');
                        Database.UpsertResult [] deleteResults = Database.upsert(contactDeleteList, false);
                        Triggers.Clearbypass('RollUpLogic');
                        Triggers.Clearbypass('InvokeRollUpContactPointsAsync');
                        Database.UpsertResult adResult = null;
                        for (Integer i=0; i<deleteResults.size(); i++) {
                           adResult = deleteResults[i];
                           if (!adResult.isSuccess()) {
                                for (Database.Error err : adResult.getErrors()) {
                                    switch on (err.getStatusCode()) {
                                        when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                            if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
												logMsg = new nebula.LogMessage(msgfmt1,contactDeleteList[i].Person_ID__c, 'Retry ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
	                                            nebula.logger.warn (logMsg, adResult); // flushed unless in debug mode
                                                throw new MyRetryException(err.getMessage());
                                            } else {
                                                nebula.logger.Error('Maximum Contact retries (Soft Delete) of ' + MAXRETRIES + ' reached',adResult);
                                            }
                                        }
                                        when else {
                                            logMsg = new nebula.LogMessage(msgfmt1,contactDeleteList[i].Person_ID_unique__c,'Contact upsert (delete) error - ' + err.getMessage());
		                                    nebula.logger.error(logMsg, adResult);
                                        }
                                    }                                
                                }
                            } else {
                                nebula.logger.fine('Contact successfully (soft) deleted',adResult.getId());
                            }
                        }
                    } 
                }
            } catch (MyRetryException mex) {
				// A retry replays the entire batch, so there is no need to duplicate the logs for each.
				// This does delay when the first message is avaliable in the logs
                if (!nebula.logger.isDebugEnabled()) {nebula.logger.flushBuffer();}
                // Include the logger transaction id
                throw new EventBus.RetryableException('Contact Retry ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' of ' + MAXRETRIES +'\r' + mex.getMessage() + '\r[[' + tId + ']]');
            } catch (Exception e) { 
                nebula.logger.exception(e.getMessage(), e);
            } finally {
                nebula.logger.saveLog();
            }
        }        

        /*
         * @description List of all contact that match supplied applicant ids on Applications                        
         * @param appIDs A unique list (set) of application ids involved in this batch
         * @return A map of applicant ids and crm ids
         */
        public Map<String,String> getAppContacts (Set<String> appIDs) {
            Map<String,String> eConAsApp = new Map<String,String>();
            
            for (Application__c a : [select callista_applicant_id__c, applicant__r.crm_id__c 
                                    from Application__c 
                                   where callista_applicant_id__c in :appIDs]) {
                         eConAsApp.put(a.callista_applicant_id__c, a.applicant__r.crm_id__c);
                    }
            return eConAsApp;
        }

        /*
         * @description  List of all contacts that match supplied person ids
         * @param perIDs A unique list (set) of person ids involved in this batch
         * @return A map of person ids and crm ids
         */
        public Map<String,String> getPerContacts (Set<String> perIDs) {
            Map<String,String> eConAsPer = new Map<String,String>();

            for (Contact c :[select id, person_id_unique__c, CRM_Id__c, ownerid
                             from contact 
                             where person_id_unique__c in :perIDs]) {
                                 eConAsPer.put(c.person_id_unique__c, c.CRM_Id__c);
                             }
            
            return eConAsPer;
        }

        /*
         * @description Populates a map of all existing contacts in the batch based on the person and applicant ids, including their email addresses 
         * @param perIds A list of person ids involved in this batch
         * @param appIds A list of application ids involved in this batch
         * @return A map of crm ids and contact record ids
         */
        public Map<String,Contact> getExistingContacts (List<String> perIds, List<String> appIds) {
            Map<String,Contact> eCon = new Map<String,Contact>();
            
            perIds.addAll(appIds);
            
            // Unique list of existing contacts what match either Person ids or Applicant ids
            for (Contact c :[
                    SELECT Name, Person_ID_unique__c, Person_ID__c, CRM_Id__c, LastModifiedDate_API__c, Is_Student__c, Role_Account_Flag__c,
                        FirstName, LastName, First_Name__c, Last_Name__c, Preferred_Name__c, Salutation, Salutation_ERDA__c, Monash_Email_Address__c, contact_profile__c, OwnerId, recordtype.developername,
                        (SELECT Name, Key_UID__c, End_Date__c, Is_Deleted__c, Contact__r.Person_ID__c
                        FROM Emails__r WHERE Classification__c = :DEFEMCLS),
                        (SELECT Key_UID__c, End_Date__c
                        FROM Names__r WHERE type__c = :DEFSTDNM)
                    FROM Contact
                    WHERE CRM_Id__c IN :perIds
            ]) {
                eCon.put(c.CRM_Id__c, c);
            }
            return eCon;
        }

        /*
         * @description Helper method to replace incorrect symbols (i.e. numbers) in names
         * @param strInputName The original string
         * @param personId The person id - only used for logging purposes
         * @param message A tailored error message
         * @return Converted string
         */
        private String correctName(String strInputName, String personId, String message) {
            
            String strOutputName = strInputName;
            
            if (String.isNotBlank(strOutputName)) {
                if(strOutputName.containsAny('1234567890')) {
                    strOutputName = strOutputName.replaceAll('[0-9]', '');
					nebula.logger.info(new nebula.LogMessage(msgfmt3, personid, message, strInputName + '->' + strOutputName));
                }

                // Removing the invalid characters could make it blank.
                if (String.isNotBlank(strOutputName)) {
                    strOutputName = contactServices.toProperCase(strOutputName);
                }
            }
            return strOutputName;
        }
        
        /*
         * @description Event to Contact field mapping for upserts, including transforms
         * @param iEvent The platform event payload
         * @param aC The contact reference to be updated
         * @return The updated contact record
         * @example
          {
            "ESOS__c" : false,
            "DSS_Registered__c" false,
            "Source_System__c" : "callista",
            "Govt_Citizenship_Cd__c" : "1",
            "Birthdate__c" : "1985-08-27",
            "Has_Arrived_In_Australia__c" : false,
            "Last_Modified_By__c" : "FIM_CONNECT",
            "Event_Type__c" : "INSERT",
            "Monash_Email__c" : "aiss0002@student.monash.edu",
            "Gender__c" : "F",
            "Last_Modified_Date__c" : "2021-02-15T03:23:38.000+0000",
            "Monash_Username__c" : "aiss0002",
            "Title__c" : "MRS",
            "Deceased__c" : false,
            "CreatedById" : "0050I000007dkSFQAY",
            "Applicant_IDs__c" : "2137328",
            "ReplayId" : "44180481",
            "CreatedDate" : "2021-02-15T03:23:45.000+0000",
            "First_Name__c" : "ANN SHALINI",
            "IT_account_disabled__c" : false,
            "Last_Name__c" : "ISSAC",
            "Person_ID__c" : "32429932",
            "Preferred_Name__c" : ""
            }
        */
        private Contact mapEventToObject(IbdContact__e iEvent, Contact aC) {

            Boolean isRoleAccount = aC.Role_Account_Flag__c; // Agency role account

            Boolean isAlumni = false;
            if (aC.Contact_Profile__c != null) {
                List<String> selections = aC.Contact_Profile__c.split(';');
                if (selections.contains('Alumni') || selections.contains('Alumni No Degree')) {
                    isAlumni = true;
                }
            }
            
            // The approach here is to revert the name fields of the inbound contact to align with Callista.
            // The person360 rolldown and rollup framework will then be able to identifiy a duplicate name contact point correctly.
            // Rollup will immediately 'correct' the contact values if required.

            // MiddleName is never sent from Callista
            aC.MiddleName = '';

            // Reset and use the legal name
            aC.FirstName = '';
            aC.First_Name__c = '';
            if(String.isNotBlank(iEvent.First_Name__c)) {
	            aC.First_Name__c = contactServices.toProperCase(iEvent.First_Name__c);
                aC.FirstName = aC.First_Name__c.abbreviate(40);
            }                

            // Allow numbers and do not alter the case for agency role account contacts
            if (!isRoleAccount) {
                // Case corrected, numbers removed
                aC.Last_Name__c = correctName(iEvent.Last_Name__c, iEvent.Person_ID__c,'Invalid Last Name - Fixed');
            } else {
                aC.Last_Name__c = iEvent.Last_Name__c;
            }
            
            aC.LastName = '';
            if (String.isNotBlank(aC.Last_Name__c)) {
                // Note that you can create an invalid Event by only supplying numbers in the lastname. This is taken advantage of in the test class.
                aC.LastName = aC.Last_Name__c.abbreviate(80); // mandatory to allow the Contact to save
            }

			/* Original logic causes mixed salutation name records
            aC.Salutation = '';
            if(String.isNotBlank(iEvent.Title__c)) {
                aC.Salutation = contactServices.toProperCase(iEvent.Title__c);
                if(String.isBlank(aC.Salutation_ERDA__c)) { // default the value on the contacts if the field is null.
                    aC.Salutation_ERDA__c = aC.Salutation;
                }
            }
            
            // If the contact is an active student, or is not yet an alumni (i.e. applicant), align to the salutation fields, including clearing it.
            if (aC.is_student__c || !isAlumni) {
                aC.Salutation_ERDA__c = aC.Salutation;
            }
			*/

            // Always completely align with the Callista record and let roll up sort it out
            aC.Salutation = cleanseTitle(iEvent.Title__c);
            aC.Salutation_ERDA__c = aC.Salutation;
            
            aC.LastModifiedBy_API__c = iEvent.Last_Modified_By__c;
            aC.LastModifiedDate_API__c = iEvent.Last_Modified_Date__c;
            aC.Birthdate = iEvent.Birthdate__c;
            aC.Deceased__c = iEvent.Deceased__c;
            aC.Authcate__c = iEvent.Monash_Username__c; 
            aC.IT_account_disabled__c = iEvent.IT_account_disabled__c;
            aC.ESOS__c = iEvent.ESOS__c;
            aC.DSS_Registered__c = iEvent.DSS_Registered__c;
            
            if ((String.isNotBlank(iEvent.Preferred_Name__c)) && (iEvent.Preferred_Name__c != 'N/A')) { // N/A is the default value on the event object and will only be assigned if the field is not included in the payload.
                // Assign Callista value if 
                // - PFN is null
                // - Active student
                // - Inactive student but not an alumni
                if (aC.Is_Student__c || String.isBlank(aC.Preferred_Name__c) || (!aC.Is_Student__c && !isAlumni)) {
                    aC.Preferred_Name__c = contactServices.toProperCase(iEvent.Preferred_Name__c);                        
                } 
            } else {
                // Callista sent null. For active students, Callista is the owner of the PFN. If they are not active but also not an alumni, honour the update.
                if (aC.Is_Student__c || (!aC.Is_Student__c && !isAlumni)) {
                    aC.Preferred_Name__c = null; 
                }
            }
            
            aC.Citizenship_Code__c = iEvent.Govt_Citizenship_Cd__c;
            aC.Gender__c = iEvent.Gender__c;
            aC.Nationality__c = iEvent.Nationality__c;
            
            if (String.isBlank(aC.OwnerID )) {
                aC.OwnerID = Id.valueOf(
                                SystemSettingsUtil.getInstance()
                                .getByKeyFeature(SYSTEM_SETTING_FEATURE, 'CONTACT_OWNER_ID')
                                .Value__c);
            }
            aC.Source_System__c = iEvent.Source_System__c;

            // Not included in Callista payload
            // aC.bulkapi_Email_Addresses__c = iEvent.Applicant_Email_Addresses__c;

            aC.bulkapi_Applicant_Ids__c = iEvent.Applicant_IDs__c;
            aC.Has_Arrived_In_Australia__c = iEvent.Has_Arrived_In_Australia__c;
            aC.Last_Student_Card_Image_Updated_Date__c = iEvent.Last_Student_Card_Image_Updated_Date__c;
            
            // [Yet] another alternate identifier on the contact. This is end dated in Callista after censis date and removed the payload.
            aC.VTAC_ID__c = iEvent.VTAC_ID__c;

            // [Yet] another alternate identifier on the contact. 
            aC.USI__c = iEvent.USI__c;

            aC.Person_ID_unique__c = iEvent.Person_ID__c;

            // As with all integration processing, soft undelete a record when it is inserted from Callista
            if (iEvent.Event_Type__c == 'INSERT') {
                aC.Deleted_In_Source__c = false;
            }

            return aC;
        }

        /*
         * @description Event to Contact field mapping for deletes
         * @param iEvent The platform event payload
         * @param aC The contact reference to be updated
         * @return The updated contact record
         */
        private Contact mapDeleteEventToObject(IbdContact__e iEvent, Contact aC) {

            aC.LastModifiedBy_API__c = iEvent.Last_Modified_By__c;
            aC.LastModifiedDate_API__c = iEvent.Last_Modified_Date__c;
            aC.Deleted_In_Source__c = true;
            
            return aC;
        }
        
         /*
		 * @description Mapping - Callista data to ERDA
		 * @param title Callista title (saluation) code
		 * @return A remapped value
		 */
        private String cleanseTitle (String title) {
            if (String.isBlank(title)) {
            	return '';
            }
            
            String cleanSal = title.tolowercase();
            
            // Normalise
            String j = '{'
                +'"Associate Professor"  : ["A/Prof"],'
                +'"Assistant Professor"  : ["ASST PROF"],'
                +'"Brother"              : ["Br"],'
                +'"Clinical Associate Professor"   : ["C A Prof"],'
                +'"Captain"              : ["CAPT"],'
                +'"Commander"            : ["CDR"],'
                +'"Colonel"              : ["COL"],'
                +'"Corporal"             : ["CORP"],'
                +'"Flight Lieutenant"    : ["FLT-LT"],'
                +'"Father"               : ["Fr"],'
                +'"General"              : ["Gen"],'
                +'"Inspector"            : ["Insp"],'
                +'"Lieutenant"           : ["LT"],'
                +'"Lieutenant Commander" : ["LT-CDR"],'
                +'"Lieutenant Colonel"   : ["LT-COL"],'
                +'"Pastor"               : ["Pr"],'
                +'"Professor"            : ["Prof"],'
                +'"Rear Admiral"         : ["RADM"],'
                +'"Reverend"             : ["Rev"],'
                +'"Senator"              : ["Sen"],'
                +'"Sergeant"             : ["SGT"],'
                +'"Squadron Leader"      : ["SQNLDR"],'
                +'"Sister"               : ["Sr"],'
                +'"Senior Sergeant"      : ["SR-SGT"],'
                +'"Wing Commander"       : ["WG-CDR"]'
                +'}';
            
            j = j.toLowercase();
            // convert the JSON into a Map
            map <string,set<string>> t = (map<string,set<string>>)JSON.deserialize(j,map<string,set<string>>.class);
            
            for (String k : t.keySet()) { // for each map key
                set<String> s = t.get(k);
                title = title.tolowercase();
                if (s.contains(title)) { // check the set for a match
                    cleanSal = k;
                    break;
                }
            }

            return cleanSal.capitalize() ;
        }
       

        /*
         * @description This creates a 'Student Name' record which populates the middlename.
         *              Relies on the custom fields first_name__c and last_name__c being representative of Callista (unaffected by previous rollups)
         * @param eCon The current contact record
         * @return An instantiated student name record
         */
        public Set<Name__c> buildNameRec(Contact eContact) {
            Name__c aName = new Name__c();
            Set <Name__c> sN = new Set <Name__c>();

            // Default values
            aName.Contact__c = eContact.id;
            aName.Type__c = DEFSTDNM; // Student even if not isStudent
            aName.Source__c = DEFSRCSYS; // we know this is comming from Callista

            // Establish the Name as it appears in Callista
            aName.Prefix__c = eContact.Salutation; 
            aName.Suffix__c = null; 
            aName.Salutation__c = eContact.Salutation_ERDA__c; // grey area 
            aName.Last_Name__c = eContact.Last_Name__c; // case corrected event value
            aName.First_Name__c = eContact.First_Name__c; // case corrected event value, potentially contains middle name

            // Supporting the mono field on the Name__c record when rolldown isn't performed
            if (String.isBlank(aName.First_Name__c)) {
	            aName.Is_Mononymous_Name__c = true;
            }
            aName.Middle_Name__c = '';
            aName.Preferred_First_Name__c = eContact.Preferred_Name__c;

            // splitting the given names into two; first word will be mapped to  FirstName , the rest will be mapped to the middlename
            if(Person360Helper.nameCanBeSplit(aName.First_Name__c)) {
                Person360Helper.splitLegalFirstNameIntoFirstAndMiddle(aName.First_Name__c, aName);
            }

            // call Key UID generation method
            aName.Key_UID__c = NameServices.generateKeyUID(aName);
            sN.add(aName);

            if (fs.EndDateStudentNames__c) {
                // Cycle all emails for the contact and end date any active emails that do not match event email
                for (Name__c aN : eContact.Names__r) {
                    if (aN.key_UID__c != aName.key_UID__c && aN.End_Date__c == null) {
                        aName = aN; 
                        aName.End_Date__c = Date.today(); 
                        sN.add(aName);
                    }
                }
            }
            
            return sN;
        }
    
        /*
         * @description Creates a Monash Email record or end dates an existing Monash Email records if the payload did not including one (i.e. it has been removed from Callista)
         * @param eContact The current contact record
         * @param eventEmail The monash email address in the event payload
         * @return A unique list (set) of email__c records to be updated
         */
        public Set <Email__c> buildEmailRec2(Contact eContact, String eventEmail) {
            Email__c aEmail = new Email__c();
            Set <Email__c> sE = new Set <Email__c>();
            
            aEmail.key_UID__c = 'Initialised';
            if (String.isNotEmpty(eventEmail) && CommonUtilities.validateEmail(eventEmail) && EmailServices.isMonashEmail(eventEmail)) {
                // Non-null, valid email address
                aEmail.Name = eventEmail.toLowerCase();
                aEmail.Classification__c = DEFEMCLS;
                aEmail.Contact__c = eContact.Id;
                aEmail.Source__c = DEFSRCSYS;
//                aEmail.Start_Date__c = date.today(); // Setting is will overwrite existing email records. Just allow the default to be applied.
                aEmail.End_Date__c = null; // Explictly set this as we may be reinstating an email address

                // generate the Key_UID__c field, this is required for the upsert
                new EmailTriggerHandler.PopulateHash().process(aEmail); 

                sE.add(aEmail);
            } 

            // Cycle all student names for the contact and end dates any other active records
            for (Email__c aE : eContact.Emails__r) {
                if (aE.key_UID__c != aEmail.key_UID__c && aE.End_Date__c == null) {
                    aEmail = aE; 
                    aEmail.End_Date__c = Date.today(); 
                    aEmail.Source__c = DEFSRCSYS;
                    sE.add(aEmail);
                }
            }
            return sE;
       }
    }
}