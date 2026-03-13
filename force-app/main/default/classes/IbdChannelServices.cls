/*
 * @author Martin Cadman
 * @date June 2024
 * @group Integration
 * @description Inbound services class to load and map the data to the Channel__c staging object
 * 
 * There is a tremendous amount of messing around as both contact points and emergency contacts are staged in Channel__c, and they are handled very differently.
 * This is further complicated by the EC unique key not being completely available in the DELETE event. 
 * 
 * @revision 
 * Martin Cadman - 12/06/2024 Refactored from original version
 *                            Fixed up the structure and aligned with other inbound support classes 
 *                 18/06/2024 Null checks added 
 *                 01/07/2024 Basic EMERCONT relationship transformation added
 *                 10/07/2024 Tried to tigthen up DELETE event handling
 *                 11/09/2024 Changed the order deletes are handled
 *                 22/11/2024 Only allow 1 active graduation email record
 */
public class IbdChannelServices {
    @TestVisible
    private static final Integer MAXRETRIES = 4; 
    @TestVisible
    private static final String DELIMITER = '_';
    @TestVisible
    private static final String SYSTEM_SETTING_FEATURE = 'PE_INTEGRATION_DEFAULT' ;
    @TestVisible
    private static final List<String> VALIDADDRTYPES = new List<String>(
                                                                String.valueOf(
                                                                    SystemSettingsUtil.getInstance()
                                                                    .getByKeyFeature(SYSTEM_SETTING_FEATURE, 'AT_TO_SYNC')
                                                                    .Value__c
                                                                ).trim().split('\\s*,\\s*'));

    private static final String REFTAG   = 'Missing Reference Data';
    private static final String SCENARIO = 'Inbound Channel';
    private static final String EMERCONT = 'EMERCONT';
    private static final String GRADAPPL = 'GRADUATION-APPL';
    
	// Different log message formats    
    private static String msgfmt0 = '{0} {1}';
    private static String msgfmt1 = '{0} - {1}';
    private static String msgfmt2 = '{0}\r\r{1}';
    private static String msgfmt3 = '{0} - {1}\r\r{2}';

    public static Feature_Switch__c fs = Feature_Switch__c.getInstance();

    /*
     * @description Local exception 
     */
    public class MyRetryException extends Exception {}

    /*
     * @description Inbound channel trigger handler
     */
    public class EventHandler extends TriggerAbstract {
        private Map<String,IbdChannel__e> channelEventMap = new Map<String,IbdChannel__e>();
        private Set<String> personIDs = new Set<String>();
        private Set<String> applicantIDs = new Set<String>();
		Map<String,ID> personMap = new Map<String,ID>();
		Map<String,ID> applicantMap = new Map<String,ID>();
		Map<String,Channel__c> channelMap = new Map<String,Channel__c>();
		Map<String,Channel__c> ecChannelMap = new Map<String,Channel__c>();

        String jsonEvent;
        nebula.LogMessage LogMsg;
        String tId;
        
       /*
        * @description Complete processing of triggered records
        */
        public override void execute() {
            List<Channel__c> upsertList = new List<Channel__c>();
            List<Channel__c> deleteList = new List<Channel__c>();
            

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

            try {    
                for (sObject record : trigger.new) {
                    IbdChannel__e iEvent = (IbdChannel__e)record;
                    jsonEvent = JSON.serializePretty(iEvent);
                    if (String.isBlank(iEvent.Person_ID__c) || String.isBlank(iEvent.Address_Type__c) || iEvent.start_date__c == null) {
                        logMsg = new nebula.LogMessage(msgfmt3,'Mandatory field not included', 'Person ID, Address Type & Start Date are required', jsonEvent);
                        nebula.logger.ERROR(logMsg);
                        break;
                    }
                    
                    if (!new String[]{'DELETE','UPDATE','INSERT'}.contains(iEvent.Event_Type__c.toUpperCase())) {
                        logMsg = new nebula.LogMessage(msgfmt3,'Invalid Event Type', iEvent.Event_Type__c + ' is not supported', jsonEvent);
                        nebula.logger.ERROR(logMsg);
                        break;
                    }
    
                    if (!VALIDADDRTYPES.contains(iEvent.Address_Type__c)) {
                        break; // UniCRM does not ingest all address types from Callista
                    } else {
                        channelEventMap.put(getUniqueKey(iEvent), iEvent); // Map of unqiue events
                        personIDs.add(iEvent.Person_ID__c); // Set of all involved person ids
                        if (!String.isBlank(iEvent.Applicant_IDs__c)) {
                            applicantIDs.addAll(iEvent.Applicant_IDs__c.split(';')); // set of all involved applicant ids - can be more than 1
                        }
                    } 
                }

                nebula.logger.debug('Channels for processing ' + Integer.valueOf(channelEventMap.size()));
                // Records are filtered out prior to this so there may not anything to do
                if (channelEventMap.size() > 0) {
                    for (Application__c app :[select callista_applicant_id__c, applicant__c from Application__c where callista_applicant_id__c in :applicantIDs]) {
                        applicantMap.put(app.callista_applicant_id__c, app.applicant__c);
                    }

                    // Add existing contact ids against person id
                    for (Contact con :[select id, person_id__c from contact where person_id__c in :personIDs]) {
                        personMap.put(con.person_id__c, con.id);
                    }
                    
                    // Existing channels - won't include EC delete channels
                    for (Channel__c chan :[select id, Type__c, Start_Date__c, Person_ID__c, Unique_Id__c from channel__c where Unique_Id__c in :channelEventMap.keySet()]) {
  						channelMap.put(chan.Unique_Id__c, chan);                      
                    }

                    // Existing emergency contact channels - reduced key only for deletes
                    for (Channel__c ecc :[select id, Type__c, Start_Date__c, Person_ID__c, Unique_Id__c from channel__c where person_id__c in :personIDs and type__c = :EMERCONT]) {
                        ecChannelMap.put(getUniqueKey(ecc.Type__c,ecc.Person_ID__c,ecc.Start_Date__c,''),ecc);   
                    }
                    
                    for (IbdChannel__e iEvent : channelEventMap.values()) {
                        jsonEvent = JSON.serializePretty(iEvent);
                        logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c + '/' + iEvent.Address_Type__c, 'Channel ' + String.valueOf(iEvent.Event_Type__c=='DELETE'?'Delete':'Upsert'), jsonEvent);
                        nebula.logger.info(logMsg);
                        Channel__c aChannel = new Channel__c();

                        // A contact parent is mandatory
                        ID parentID = getContactId(iEvent.Person_ID__c, iEvent.Applicant_IDs__c, personMap, applicantMap);

                        // Required individual field assignments for delete
                        if (iEvent.Event_Type__c == 'DELETE' && parentID != null) {
                            aChannel.Type__c = iEvent.Address_Type__c;
                            aChannel.Start_Date__c = iEvent.Start_Date__c;
                            aChannel.Person_ID__c = iEvent.Person_ID__c;

                            // For EC channels, the relationship value is included in the unqiue key. However, Callista doesn't supply this value in the delete payload.
                            // The saving grace here is that Callista is supposed to only have 1 active EC per-student. Minor risk we delete the wrong channel.
                            if (iEvent.Address_Type__c == EMERCONT) {
                                if (ecChannelMap.containsKey(getUniqueKey(aChannel.Type__c,aChannel.Person_ID__c, aChannel.Start_Date__c,''))) {
                                    aChannel = ecChannelMap.get(getUniqueKey(aChannel.Type__c,aChannel.Person_ID__c, aChannel.Start_Date__c,''));
                                    aChannel.Deleted_In_Source__c = true;
                                    aChannel.Is_Processed__c = false;
                                    aChannel.Last_Modified_Date_API__c = iEvent.Last_Modified_Datetime__c;
	                            	deleteList.add(aChannel);
                                } else {
                                    logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c + '/' + iEvent.Address_Type__c, 'Unable to find Emergency Contact Channel for deletion', jsonEvent);
                                    nebula.logger.warn(logMsg, parentID);
                                    break; // skip this record
                                }
                            } else {
                                if (channelMap.containsKey(getUniqueKey(iEvent))) {
	                                aChannel = channelMap.get(getUniqueKey(iEvent));
                                    aChannel.Deleted_In_Source__c = true;
                                    aChannel.Is_Processed__c = false;
                                    aChannel.Last_Modified_Date_API__c = iEvent.Last_Modified_Datetime__c;
	                             	deleteList.add(aChannel);
                                } else {
                                    logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c + '/' + iEvent.Address_Type__c, 'Unable to find Channel for deletion', jsonEvent);
                                    nebula.logger.warn(logMsg,parentID);
                                    break; // skip this record
                                }
                            }
                        } else { // standard mapping, non-delete event
                            aChannel = this.mapEventToObject(iEvent);
                        }

                        if (parentID == null) {
                            aChannel.Contact__r = new Contact(Person_id_unique__c = '!'+ iEvent.Person_ID__c); 
                            // forces an invalid field error on database.save, we don't want to create one
                            // We don't skip this record for processing as we want to retry in case the Contact record is on it's way
                            // Not reported for a DELETE operation - so retry will also not occur
                            logMsg = new nebula.LogMessage(msgfmt3, iEvent.Person_ID__c + '/' + iEvent.Address_Type__c, 'Unable to identify parent Contact', jsonEvent);
                            nebula.logger.error(logMsg);
                        } else {
                            aChannel.Contact__c = parentID;

                            // Special handling for graduate application personal emails - feature switch must be enabled
                            // End date previous gradutation application channels.
                            // This is only required for GA channels as other end-dates are managed by Callista.
                             if (aChannel.type__c == GRADAPPL && fs.EndDateGraduationChannels__c) {
                             	for (Channel__c ch : [Select id, start_date__c, end_date__c, Unique_Id__c, is_processed__c from channel__c where type__c = :GRADAPPL and contact__c = :parentID order by start_date__c asc]) {
                                    if 	(aChannel.start_date__c > ch.start_date__c) {
                                        if (ch.end_date__c == null) {
                                            ch.end_date__c = aChannel.start_date__c;
                                            ch.is_processed__c = false;
                                            upsertList.add(ch);
                                        }
                                    } 
                                    if 	(aChannel.start_date__c < ch.start_date__c) {
                                        aChannel.end_date__c = ch.start_date__c;
                                    }
                                }
                            }
                        }

                        if (iEvent.Event_Type__c.toUppercase()!='DELETE') {
                            upsertList.add(aChannel);
                        }
                    }
                }

				nebula.logger.debug('Channels to be (soft) deleted : ' + Integer.valueOf(deleteList.size()));
                Database.SaveResult [] deleteResults = Database.update(deleteList, false);
                Database.SaveResult delResult = null;
                for (Integer i=0; i<deleteResults.size(); i++) {
                    delResult = deleteResults[i];
                    if (!delResult.isSuccess()) {
                        for (Database.Error err : delResult.getErrors()) {
							nebula.logger.debug(err.getMessage());
                            Switch on (err.getStatusCode()) {
                                when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                    if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                        logMsg = new nebula.LogMessage(msgfmt1, deleteList[i].Person_ID__c, 'Retry Channel ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
                                        nebula.logger.warn (logMsg, delResult);
                                        throw new MyRetryException(err.getMessage());
                                    } else {
                                        logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].unique_id__c.substringbefore(DELIMITER), 'Maximum retries (' + MAXRETRIES + ') reached for Channel - ' + err.getMessage());
										nebula.logger.error (logMsg, deleteList[i].id); // note because it's an update we can link the error to a individual record
                                    }
                                }
                                when else {
                                    logMsg = new nebula.LogMessage(msgfmt1,deleteList[i].unique_id__c.substringbefore(DELIMITER), 'Channel upsert (delete) error - ' + err.getMessage());
                                    nebula.logger.error(LogMsg, deleteList[i].id); // note because it's an update we can link the error to a individual record
                                }
                            }
                        } 
                    }  else {
                        nebula.logger.fine('Channel successfully (soft) deleted' ,delResult.getId());
                    }
                }
                    
				nebula.logger.debug('Channels to be upserted : ' + Integer.valueOf(upsertList.size()));
                Database.UpsertResult [] upsertResults = Database.upsert(upsertList, channel__c.Fields.unique_Id__c, false);
                Database.UpsertResult aResult = null;
                for (Integer i=0; i<upsertResults.size(); i++) {
                    aResult = upsertResults[i];
                    if (!aResult.isSuccess()) {
                        for (Database.Error err : aResult.getErrors()) {
							nebula.logger.debug(err.getMessage());
                            Switch on (err.getStatusCode()) {
                                when UNABLE_TO_LOCK_ROW, INVALID_FIELD {
                                    if (EventBus.TriggerContext.currentContext().retries < MAXRETRIES) {
                                        logMsg = new nebula.LogMessage(msgfmt1, upsertList[i].Person_ID__c, 'Retry Channel ' + String.valueOf(EventBus.TriggerContext.currentContext().retries+1) + ' - ' + err.getMessage());
                                        nebula.logger.warn (logMsg, aResult);
                                        throw new MyRetryException(err.getMessage());
                                    } else {
                                        logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].unique_id__c.substringbefore(DELIMITER), 'Maximum retries (' + MAXRETRIES + ') reached for Channel - ' + err.getMessage());
										nebula.logger.error (logMsg, aResult);
                                    }
                                }
                                when else {
                                    logMsg = new nebula.LogMessage(msgfmt1,upsertList[i].unique_id__c.substringbefore(DELIMITER), 'Channel upsert error - ' + err.getMessage());
                                    nebula.logger.error(LogMsg, aResult);
                                }
                            }
                        } 
                    }  else {
                        nebula.logger.fine('Channel successfully ' + String.valueOf(aResult.isCreated()?'created':'updated') ,aResult.getId());
                    }
                }
            } catch (MyRetryException mex) {
				// A retry replays the entire batch, so there is no need to duplicate the logs for each.
				// This does delay when the first message is avaliable in the logs
                if (!nebula.logger.isDebugEnabled()) {nebula.logger.flushBuffer();}
                throw new EventBus.RetryableException('Channel Retry ' + (EventBus.TriggerContext.currentContext().retries + 1) + ' of ' + MAXRETRIES +'\r' + mex.getMessage() + '\r[[' + tId + ']]'); // add logger transaction id
			} catch (Exception ex) { 
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
				nebula.logger.saveLog();
            }
        }
        
        /*
		 * @description The event payload mapping to channel__c
		 *              Much of the complexity comes from the loose field mapping in Callista
		 * @param iEvent The individual event record being mapped
		 * @return A mapped (populated) channel__c record
		 * 
         * Delete Payload
         * { "Last_Modified_Datetime__c" : "2024-06-06T01:25:04.000+0000",
         * "Source_System__c" : "callista",
         * "Address_Type__c" : "OS-POSTAL",
         * "Event_Type__c" : "DELETE",
         * "Start_Date__c" : "2024-06-05",
         * "Person_ID__c" : "30000123"} 
         * 
         * OS Postal Payload
		 * {"Source_System__c" : "callista",
         * "Mobile_Phone__c" : "+86 13697320123",
         * "OS_Post_Code__c" : "430013",
         * "Address_Line_1__c" : "123 ZIXUANMEIJIA, NO. 16-1 ZHENGYI ROAD, JIANG'AN DISTRICT",
         * "Address_Line_2__c" : "WUHAN",
         * "Last_Modified_By__c" : "POSTMAN",
         * "Address_Line_3__c" : "HUBEI",
         * "Previous_Start_Date__c" : "2024-06-05",
         * "Event_Type__c" : "INSERT",
         * "Applicant_IDs__c" : "3000123",
         * "Address_Type__c" : "OS-POSTAL",
         * "Address_Line_4__c" : "CHINA",
         * "Start_Date__c" : "2024-06-05",
         * "Email__c" : "test_Xindy@@home.com",
         * "Person_ID__c" : "30000123"}
         */
		private Channel__c mapEventToObject(ibdChannel__e iEvent) {
            Channel__c aC = new Channel__c();

            aC.Unique_id__c = getUniqueKey(iEvent);

            // Required to trigger channel breakup             
            aC.Is_Processed__c = false;

            aC.Person_ID__c = iEvent.Person_ID__c;
            aC.Type__c = iEvent.Address_Type__c;
            aC.Last_Modified_By_API__c = iEvent.Last_Modified_By__c;
            aC.Start_Date__c = iEvent.Start_Date__c;
            aC.End_Date__c = iEvent.End_Date__c;
            
            aC.Line_1__c = iEvent.Address_Line_1__c;
            aC.Line_2__c = iEvent.Address_Line_2__c;
            aC.Line_3__c = iEvent.Address_Line_3__c;
            aC.Line_4__c = iEvent.Address_Line_4__c;
            aC.Line_5__c = iEvent.Address_Line_5__c;
            aC.Phone__c         = iEvent.Phone__c;
            aC.Phone_2__c       = iEvent.Phone_2__c;
            aC.Mobile_Phone__c  = iEvent.Mobile_Phone__c;
            aC.Source_System__c = iEvent.Source_System__c;
            aC.Last_Modified_Date_API__c = iEvent.Last_Modified_Datetime__c;
            aC.Email_Unverified__c = iEvent.Email__c;
            aC.AU_Post_Code__c = iEvent.AU_Post_Code__c;
            aC.OS_Post_Code__c = iEvent.OS_Post_Code__c;

            // Overridden below for POSTAL-EXT
            aC.Street__c = iEvent.Address_Line_1__c;
            aC.City__c   = iEvent.Address_Line_2__c==null?null:iEvent.Address_Line_2__c.abbreviate(40);
            aC.State__c  = iEvent.Address_Line_3__c==null?null:iEvent.Address_Line_3__c.abbreviate(80);

            // Ensure e-mail address is valid, otherwise record will not save
            if(!String.isBlank(iEvent.Email__c)) {
                if(CommonUtilities.validateEmail(iEvent.Email__c)) {
                    aC.Email__c = iEvent.Email__c;
                }
            }

            // undelete if record has been soft deleted prior
            aC.Deleted_In_Source__c = false;
            
            Switch on (iEvent.Address_Type__c.toUpperCase()) {
                when 'POSTAL-EXT' {
                    String streetAddr;
                    streetAddr = iEvent.Address_Line_1__c;
                    streetAddr = !String.isEmpty(streetAddr)?streetAddr + ', ' + iEvent.Address_Line_2__c:iEvent.Address_Line_2__c;
                    aC.Street__c = streetAddr==null?null:streetAddr.abbreviate(255).replace(',,',',').trim();
                    aC.City__c = iEvent.Address_Line_3__c==null?null:iEvent.Address_Line_3__c.abbreviate(40);
                    aC.State__c = iEvent.Address_Line_4__c==null?null:iEvent.Address_Line_4__c.abbreviate(80);
                    aC.Post_Code__c = iEvent.AU_Post_Code__c;

                    // Only default country if there are some address details - not the case for email only address types of 'ap-email' and 'graduation-appl'
                    // Logic duplicated in 'else'
                    if(!String.isBlank(aC.Street__c) || !String.isBlank(aC.City__c) || !String.isBlank(aC.State__c)) {
                        aC.Country__c = 'Australia';
                    }
                }    

                when 'OS-POSTAL', 'OS-HOME' {
                    aC.Post_Code__c = iEvent.OS_Post_Code__c;
                    // We often get numeric postcodes instead of country names from Callista. These need to be filtered out as there is a small chance they will match 
                    // a Callista code or the ISO numeric code. 
                    if (String.isNotEmpty(iEvent.Address_Line_4__c) && String.isNotEmpty(iEvent.Address_Line_4__c.replaceAll('[\\d]',''))) {
						aC.Country__c = CountryServices.getCountryName(iEvent.Address_Line_4__c,CountryServices.FORMAT_ISO);

                        // Common countries
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('HONG KONG')) {
							aC.Country__c = CountryServices.getCountryName('HONG KONG', CountryServices.FORMAT_ISO);
                        }
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('TAIWAN')) {
							aC.Country__c = CountryServices.getCountryName('TAIWAN', CountryServices.FORMAT_ISO);
                        }
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('CHINA')) {
							aC.Country__c = CountryServices.getCountryName('CHINA', CountryServices.FORMAT_ISO);
                        }
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('NEW ZEALAND')) {
							aC.Country__c = CountryServices.getCountryName('NEW ZEALAND', CountryServices.FORMAT_ISO);
                        }
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('SRI LANKA')) {
							aC.Country__c = CountryServices.getCountryName('SRI LANKA', CountryServices.FORMAT_ISO);
                        }
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('KOREA')) {
							aC.Country__c = CountryServices.getCountryName('SOUTH KOREA', CountryServices.FORMAT_ISO);
                        }
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('INDIA')) {
							aC.Country__c = CountryServices.getCountryName('INDIA', CountryServices.FORMAT_ISO);
                        }
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('MALAYSIA')) {
							aC.Country__c = CountryServices.getCountryName('MALAYSIA', CountryServices.FORMAT_ISO);
                        }
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('THAILAND')) {
							aC.Country__c = CountryServices.getCountryName('THAILAND', CountryServices.FORMAT_ISO);
                        }  
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('VIETNAM')) {
							aC.Country__c = CountryServices.getCountryName('VIETNAM', CountryServices.FORMAT_ISO);
                        }  
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('VIET NAM')) {
							aC.Country__c = CountryServices.getCountryName('VIET NAM', CountryServices.FORMAT_ISO);
                        }  
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('MYANMAR')) {
							aC.Country__c = CountryServices.getCountryName('MYANMAR', CountryServices.FORMAT_ISO);
                        }  
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('ENGLAND')) {
							aC.Country__c = CountryServices.getCountryName('ENGLAND', CountryServices.FORMAT_ISO);
                        }  
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('INDONESIA')) {
							aC.Country__c = CountryServices.getCountryName('INDONESIA', CountryServices.FORMAT_ISO);
                        }  
                        If (aC.Country__c==null && iEvent.Address_Line_4__c.containsIgnoreCase('JAPAN')) {
							aC.Country__c = CountryServices.getCountryName('JAPAN', CountryServices.FORMAT_ISO);
                        }  

                        if (aC.Country__c == null) {
                            nebula.logger.warn('ISO country name not found [' + iEvent.Address_Line_4__c + ']', aC).addTag(REFTAG);
                        }
 					}
                }
                
                // implemented some very low-key data cleansing
                when 'EMERCONT' {
                    aC.fullname__c = iEvent.Address_Line_1__c;
                    aC.Street__c = iEvent.Address_Line_3__c==null?null:iEvent.Address_Line_3__c.abbreviate(255).replace(',,',',').trim();
                    aC.City__c = iEvent.Address_Line_4__c==null?null:iEvent.Address_Line_4__c.abbreviate(40);
                    aC.Post_Code__c = iEvent.AU_Post_Code__c==null?iEvent.OS_Post_Code__c:iEvent.AU_Post_Code__c;
                    
                    aC.Relationship_unverified__c = iEvent.Address_Line_2__c; // just following the object pattern, not really required

                    aC.Relationship__c = aC.Relationship_unverified__c?.replaceAll('[-\\_+/?&().,%$#@*^:;><"!]',' '); // replace most punctuation with a space
                    aC.Relationship__c = aC.relationship__c?.replaceAll('[\\\\]',' '); // replace backslashes with spaces
                    aC.Relationship__c = aC.relationship__c?.normalizeSpace(); // removes double, leading and trailing spaces caused by previous replacements
                    aC.Relationship__c = aC.relationship__c?.replaceAll('[\'`]',''); // replace some characters with nothing
                    aC.Relationship__c = aC.relationship__c?.replaceAll('[\\d]',''); // replace all digits with nothing
                    aC.Relationship__c = aC.relationship__c?.replaceAll('[sS]\\b',''); // remove trailing 's' i.e. parents becomes parent
                    aC.Relationship__c = aC.relationship__c?.normalizeSpace(); // removes leading, trailing and multiple spaces
                    
                    if (String.isBlank(aC.Relationship__c)) {
                        aC.Relationship__c = 'Other'; // Could be blank after all that
                    } else {
                        // normalise some of the most common variations
                        aC.Relationship__c = cleanse(aC.Relationship__c); 
                    }
                    
                    // Line 5 can contain city, state, country or a combination
                    // Some basic work done to try and work it out
                    if (!String.isBlank(iEvent.Address_Line_5__c)) {
                        String line5 = iEvent.Address_Line_5__c.replaceAll('[^a-zA-Z\\s\'-]',' ').normalizeSpace(); 
						String state;
                        String country;

                        // An Australian EC is the most likely

						// If Australia is mentioned, set the country and remove Australia from the original string so further processing can occur                            
						if (line5.indexOfIgnoreCase('Australia') > -1) {
                        	line5 = replaceSubStr(line5, 'Australia', ''); 
                            state = line5;
                          	country = 'Australia';
                        }

                        // Compare against both Australian state codes and names
                        // If found, set the state to the state code value and the countryto Australia
                        // By assuming Australia, we don't pass in values such as 'SA' to the getcountry methods - this would match the country Saudi Arabia
                        // Only works if the state is the sole value - VIC MELBOURNE will not work
                        Map<String, String> sNames = new Map<String, String>{'VIC'=>'VICTORIA','TAS'=>'TASMANIA','NSW'=>'NEW SOUTH WALES','SA'=>'SOUTH AUSTRALIA','WA'=>'WESTERN AUSTRALIA','NT'=>'NORTH TERRITORY','QLD'=>'QUEENSLAND','ACT'=>'Australian Capital Territory'};
                        Map<String, String> sCodes = new Map<String, String>{'VICTORIA'=>'VIC','TASMANIA'=>'TAS','NEW SOUTH WALES'=>'NSW','SOUTH AUSTRALIA'=>'SA','WESTERN AUSTRALIA'=>'WA','NORTH TERRITORY'=>'NT','QUEENSLAND'=>'QLD','Australian Capital Territory'=>'ACT'};
                        If (sNames.containsKey(line5.toUppercase()) || sCodes.containsKey(line5.toUppercase())) {
                            State = replaceSubStr(line5, line5, sCodes.get(line5));                          
                            country = 'Australia';
                        } else 

                        // We haven't been able to establish Australia, so we spread the net
                        // This finds countries in strings such as 'KOWLOON, HONG KONG'
                        // A bit of redundant processing is happening if we find the country early
                        // We could loop around all Callista countries but there is CPU to consider
                        if (String.isBlank(country)) {
							wrapperClass wc = new wrapperClass();
                            wc.aCountry = country;
                            wc.aState = state;
                            wc = lookForCountry(wc, line5, 'Malaysia');
                            wc = lookForCountry(wc, line5, 'Hong Kong');
                            wc = lookForCountry(wc, line5, 'Taiwan');
                            wc = lookForCountry(wc, line5, 'Macau');
                            wc = lookForCountry(wc, line5, 'China Peoples Republic of');
                            wc = lookForCountry(wc, line5, 'China');
    						wc = lookForCountry(wc, line5, 'Singapore');
                            wc = lookForCountry(wc, line5, 'New Zealand');
                            wc = lookForCountry(wc, line5, 'India');
                            wc = lookForCountry(wc, line5, 'Indonesia');
                            wc = lookForCountry(wc, line5, 'Japan');
                            wc = lookForCountry(wc, line5, 'Vietnam');
                            wc = lookForCountry(wc, line5, 'Viet nam');
                            wc = lookForCountry(wc, line5, 'Republic of Korea');
                            wc = lookForCountry(wc, line5, 'South Korea');
                            wc = lookForCountry(wc, line5, 'Korea');
                            wc = lookForCountry(wc, line5, 'United Kingdom');
                            wc = lookForCountry(wc, line5, 'England');
                            wc = lookForCountry(wc, line5, 'Canada');
                            wc = lookForCountry(wc, line5, 'Philippines');
                            wc = lookForCountry(wc, line5, 'Thailand');
                            wc = lookForCountry(wc, line5, 'Nepal');
                            wc = lookForCountry(wc, line5, 'Myanmar');
                            wc = lookForCountry(wc, line5, 'The Netherlands');
                            wc = lookForCountry(wc, line5, 'Netherlands');
                            wc = lookForCountry(wc, line5, 'Mexico');
                            wc = lookForCountry(wc, line5, 'United States of America');
                            wc = lookForCountry(wc, line5, 'America');
                            wc = lookForCountry(wc, line5, 'USA');
                            wc = lookForCountry(wc, line5, 'United Arab Emirates');
                            wc = lookForCountry(wc, line5, 'UAE');
                            wc = lookForCountry(wc, line5, 'Pakistan');
                            wc = lookForCountry(wc, line5, 'Nigeria');
                            wc = lookForCountry(wc, line5, 'Sri Lanka');
                            wc = lookForCountry(wc, line5, 'Italy');
                            wc = lookForCountry(wc, line5, 'Cambodia');
                            wc = lookForCountry(wc, line5, 'Brunei');
                            wc = lookForCountry(wc, line5, 'Italy');
                            wc = lookForCountry(wc, line5, 'Germany');
                            wc = lookForCountry(wc, line5, 'France');
                            wc = lookForCountry(wc, line5, 'Spain');
                            
                            country = wc.aCountry;
                            state = wc.aState;

                            // Last throw of the dice
                            if (String.isBlank(country)) {country = CountryServices.getCountryName(line5, CountryServices.FORMAT_ISO);}
                            
                            // Use the raw data if nothing matches
                            if (String.isBlank(country) && String.isBlank(state)) {state = line5;}
                        }
                        aC.State__c = state;
                        aC.Country__c = country;
                    }
                }
                
                when else {
                    aC.Post_Code__c = iEvent.AU_Post_Code__c;
                    // Only default country if there are some address details - not the case for email only address types of 'ap-email' and 'graduation-appl'
                    // Logic duplicated in 'POSTAL-EXT'
                    if(!String.isBlank(aC.Street__c) || !String.isBlank(aC.City__c) || !String.isBlank(aC.State__c)) {
                        aC.Country__c = 'Australia';
                    }
                }
            }
            return aC;
        }

        /*
		 * @description Identify a country within a string
		 * @param wc A wrapper class containing a state and country name
		 * @param inputStr The string for processing
		 * @param findStr The country we're looking for in the inputStr
		 * @return Country details
		 * 
		 */
        private wrapperClass lookForCountry (wrapperClass wc, String inputStr, String findStr) {
			wrapperClass result = new wrapperClass();
            String countryStr = wc.aCountry;
            String stateStr = wc.aState;
            
        	if (String.isBlank(CountryStr)) {
                If (inputStr.indexOfIgnoreCase(findStr) > -1) {
                    CountryStr = CountryServices.getCountryName(findStr, CountryServices.FORMAT_ISO);
                    StateStr   = replaceSubStr(inputStr, findStr, '');  // Remove the findStr from the source. This can leave the state value untidy but at least information isn't duplicated.
                }
            }
            result.aCountry = countryStr;
            result.aState = stateStr;
            
            return result;
        }
        
        /*
		 * @description Helper method to find&repace a string within another string, case insenstive
		 * @param inputStr String for processing
		 * @param toReplace String to find
		 * @param replacedBy String to replace with
		 * @return Reformatted string
		 * 
		 */
        private String replaceSubStr (String inputStr, String toReplace, String replacedBy) {
            String result = inputStr;

            if (!String.isBlank(result)) {
                Integer indexStartReplace = result.indexOfIgnoreCase(toReplace);
                if (!String.isBlank(toReplace) && replacedBy!=null && indexStartReplace > -1) {
                    Integer indexEndReplace = indexStartReplace + toReplace.length();
                    result = result.replace(result.substring(indexStartReplace, indexEndReplace), replacedBy).replaceAll('[^\\w\\s]','').normalizeSpace(); 
                }
            }
            return result;
        }
        
        /*
		 * @description Helper method to find a contact id from either an applicant or contact id
		 *              Map key is Person ID or Applicant ID, value is the Contact id
         *              Channels follow the person id but fall back on the Applicant id
		 * @param pId A person id 
		 * @param aList A list of callista applicant ids
		 * @param personMap Map key is Person ID, value is the Contact id
		 * @param applicantMap Map key is Applicant ID, value is the Contact id
		 * @return A contact Id
		 */
        private ID getContactId(String pId, String aList, Map<String,ID> personMap, Map<String,ID> applicantMap) {
            ID parentID;
            
            if (!personMap.isEmpty()) {
                if (personMap.containsKey(pId)) {
                    parentID = personMap.get(pId);
					logMsg = new nebula.LogMessage(msgfmt1, pId, 'Channel matched on Person Id');
					nebula.logger.debug(logMsg, parentID);
                }
            }

            if (parentID == null && aList != null) {
                for(String str : aList.split(';')) {
                    if (applicantMap.containsKey(str)) {
                        parentID = applicantMap.get(str);
                        logMsg = new nebula.LogMessage(msgfmt1, pId, 'Channel matched on Applicant Id '+ str);
                        nebula.logger.debug(logMsg, parentID);
                        break;
                    }
                }
            }

            return parentID;
        }
        
        /*
		 * @description Helper method to generate a uniqueKey, built from record data
		 * @param aType The type of channel
		 * @param personId The student if
		 * @param startDate The channel start date
		 * @param Relationship For emergency contacts, the relationship type
		 * @return A concatenated string
		 */
        private string getUniqueKey (String aType, String personId, Date startDate, String Relationship) {
            return ChannelEventUtility.getUniqueKey(aType, personId,startDate, Relationship);
        }
            
        /*
		 * @description Helper method to generate a uniqueKey, built from record data
		 * @param iEvent The event being processed
		 * @return A concatenated string
		 */
        private String getUniqueKey (IbdChannel__e iEvent) {
            return ChannelEventUtility.getUniqueKey(iEvent);
        }

        /*
		 * @description Emergency contact type mapping - Callista data is free text
		 * @param rel Relationship string
		 * @return A remapped value
		 */
        private String cleanse (String rel) {
            if (String.isBlank(rel)) {
                return '';
            }

            String cleanRel = rel.tolowercase();
            
            // Normalise some of the most common 'off-brand' relationships, fixing spelling mistakes and aligning different variations
            String j = '{'
                +'"Aunt"     : ["Aunty","Auntie"],'
                +'"Brother"  : ["Older Brother","Elder Brother", "Younger Brother", "Twin Brother","Brother Guardian","My Brother"],'
                +'"Father"   : ["Dad","Father Daughter","Father Son","My Father","Farther","Father Parent", "Father Guardian","Parent Father","My Dad"],'
                +'"Friend"   : ["Schoolmate","Relatives Friend","Teammate","Firend","Freind","Boyfriend","Roommate","Girlfriend","Housemate","Family Friend","Classmate","Sister Friend","Brother Friend","Roomate","Girl Friend","Best Friend","Close Friend","Supervisor","Boy Friend","Flatmate","Student","House Mate","Room Mate","Colleague","Parent Friend","Friendship","My Friend","Mate","My Mate","Acquaintance","Best mat","Family Member","Friend Housemate"],'
                +'"Guardian" : ["Guardian Uncle","Uncle Guardian","Guardian Aunt","Aunt Guardian","Monash College Guardian","MCG Gaurdian","MCG","Gaurdian","Guardia","Parent Guardian"],'
                +'"Host"     : ["Host Mother","Host Father","Homestay Host","Host Family","Homestay Mother","Homestay Family","Hostmother"],'
                +'"Husband"  : ["My Husband","Spouse Husband","Husband Spouse","Partner Husband","Husband Wife","Hhusband","Husband Partner","Awesome Husband"],'
                +'"Mother"   : ["Mum","Mom","Mother Daughter","Mother Daughter","My Mother","Monther","Mather","Mother Child Relationship","My Mum","Mother Son", "Mother Daughter Relationship", "Mother Guardian","Parent Mother"],'
                +'"Other"    : ["Landlord","Landlady","Single","Homestay","Myself","Agent","Me","Counsellor Coordinator Of Ciencia Sem","Education Agent","Coordinator Of Ciencia Sem Fronteiras Pr","Accom Staff","Teacher","Tbc"],'
                +'"Parent"   : ["Mother Father","Father Mother","Mum Dad", "Mom Dad", "My Parent"],'
                +'"Grandparent" : ["My Grandparent","Grandfather","Grandmother","Grandpa","Grandma", "Grand Mother","Grand Father", "GrandMather","Grand Parent","Granddad","Grandad","Grand dad","Grandfarther","Grandmother Guardian","Guardian Grandmother","Grandmother Of","Grandfather Of"],'
                +'"Partner"  : ["Spose","Partner","Spouse","Fiance","De Facto","Fiancee","Defacto","Married","Couple","De Facto Partner","Defacto Partner","Domestic Partner","Parter","Life Partner","Partner Spouse","Fianc","Relationship Partner"],'
                +'"Relative" : ["Relative friend","Sibling","Family","Step Father","Step Mother","Step Brother", "Step Sister","Family Memeber","Paternal Uncle","Paternal Aunt","Maternal Aunt","Maternal Uncle","Granduncle","Grand Uncle", "Grand Aunt","Grandaunt","GrandAuntie","Cousin","Older Cousin","Sister In Law","Brother In Law","Father in Law","Mother in Law","Family Member","Cousin Brother","Cousin Wife","Cousion","Biological Mother","Biological Father","Male Cousin"],'
                +'"Sister"   : ["Older Sister","Elder Sister", "Younger Sister", "Twin Sister","Sister Guardian","My Sister"],'
                +'"Wife"     : ["My Wife","Spouse Wife","Wife Partner","Wife Spouse","Partner Wife","My Lovely Wife","Wife Lover Friend","Wifee","Wife Best Friend","Wifey","Beautiful Wife","Wife Boss"]'
                +'}';
            
            j = j.toLowercase();
            
            // convert the JSON into a Map
            map <string,set<string>> t = (map<string,set<string>>)JSON.deserialize(j,map<string,set<string>>.class);
            
            for (String k : t.keySet()) { // for each map key
                set<String> s = t.get(k);
                rel = rel.tolowercase();
                rel = rel.replace(' and ',' '); // reduces the required JSON combinations
                if (s.contains(rel)) { // check the set for a match
                    cleanRel = k;
                    break;
                }
            }
            
            return cleanRel.capitalize();
        }
    }

    /*
	 * @description A wrapper class to hold country and state values
	 */
    public class wrapperClass{
        String aState;
        String aCountry;
    }
}