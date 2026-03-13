/**
 * @description       : Channel Event processing utility for the break-up of Channel__c records to contact points (Address__c, Email__c, Phone__c)
 * @author            : Stefan Scheit
 * @group             : Helper
 * @last modified on  : 2020-10-14
 * @last modified by  : Stefan Scheit
 * Modifications Log
 * Date         Author          Modification
 * 2019-08-04   Paul Victoriano Initial Version
 * 2020-05-04   JM Mapanao      Added logic to populate Contact Point's Source__c field to 'Callista' when Channel__c.Source_System__c equals to 'callista'
 * 2020-10-14   Stefan Scheit   Moved from ContactPointUtility to ChannelEventUtility
 * 2021-07-05   P.Victoriano    Added bypass logic based on criteria
 * 2021-07-16   P.Victoriano    Fixed Null Pointer exception [EPCP-1419]
 * 2022-08-03   RANAND          Channel Bypass Type MD migration to System MD [EPBBS-2802]
 * 2022-08-20   Martin Cadman   Stopped a mobile and undefined phone contact point from being created if the numbers supplied are the same, post formatting [EPCP-2385]
 * 2024-06-13   Martin Cadman   Emergency Contact event processing added
 * 2024-07-01   Martin Cadman   Basic EMERCONT relationship transformation added
 **/

public class ChannelEventUtility {
    List<Channel_Event__e> channelEvents = new List<Channel_Event__e>();
    
    @TestVisible
    Map<Id, Channel__c> channelUpdates {
        get; set;
    }
    @TestVisible
    private Map<Id, Channel__c> channels {
        get; set;
    }
    @TestVisible
    private Map<Id, Person360DAO> mapContactChannels {
        get; set;
    }
    @TestVisible
    private Set<Id> contactRecordIds {
        get; set;
    }
    @TestVisible
    private Set<Id> channelRecordIds {
        get; set;
    }
    @TestVisible
    private static List<Channel_Contact_Point_Mapping__mdt> mappingConfig {
        get; set;
    }
    @TestVisible
    private Map<Id,Channel_Event__e> channelEventMap {
        get; set;
    }
    private String SOURCE_CALLISTA = 'callista';
    private String FEATURE_CHANNEL_BYPASS_TYPE = 'CHANNEL_BYPASS_TYPE';
    private static final String DELIMITER = '_';
    private static final String DEFEC = 'Other';
	private static final String ECTYPE = 'EMERCONT';
    
    @TestVisible
    private Map<String,List<SystemSettingWrapper.ChannelBypassType>> mapBypassValueList {
        get; set;
    }
    
    /**
     * Constructor
     */
    public ChannelEventUtility(Set<Id> conIds, Set<Id> channIds) {
        this.contactRecordIds = conIds;
        this.channelRecordIds = channIds;
        mapContactChannels = new Map<Id, Person360DAO>();
        channelUpdates = new Map<Id, Channel__c>();
        channelEventMap = new Map<Id,Channel_Event__e>();
        //Retrieve Mapping Configuration
        retrieveContactPointMapping();
        //Key of Target Object and Field Bypass
        retrieveChannelByPass();
    }

    /**
     * Execute
     */
    public void execute() {
        try {
            //Step 1: Retrieve All Channels related to Contact
            retrieveChannelRecordsForUpdate();
            //Step 2: Process Channel records
            processChannels();
            //Step 3: Commit changes
            saveChanges();
        } catch (Exception ex){
            nebula.logger.exception (ex.getMessage(), ex);
        } finally {
            nebula.logger.saveLog();
        }
    }

    /**
     * setContactPoint retry
     */
    public void setContactPoint(Map<Id,Channel_Event__e> mpParam) {
        if (mpParam != null) {
            channelEventMap = mpParam;
        }
    }

    /**
     * Performs commit to Database based on ExternalId hash map
     */
    @TestVisible
    private void saveChanges() {
        Map<String, Email__c> emails = new Map<String, Email__c>();
        Map<String, Phone__c> phones = new Map<String, Phone__c>();
        Map<String, Address__c> addresses = new Map<String, Address__c>();
        if (!mapContactChannels.isEmpty()) {
            //Collect all changes
            for (Person360DAO dao : mapContactChannels.values()) {
                //Push Emails
                if (!dao.emails.isEmpty()) {
                    for (Email__c email : dao.emails.values()) {
                        // Do not process if email is one of the monash owned domain
                        if (EmailServices.isMonashEmail(email.Name) == false) {
                            //Create Hash Key
                            new EmailTriggerHandler.PopulateHash().process(email);
                            if (breakDownBypass(email, 'Email__c')) {
                                emails.put(email.Key_UID__c, email);
                            }
                        }
                    }
                }
                //Push Phones
                if (!dao.phones.isEmpty()) {
                    for (Phone__c phone : dao.phones.values()) {
                        new PhoneTriggerHandler.PopulateHash().process(phone);
                        if (breakDownBypass(phone, 'Phone__c')) {
                            phones.put(phone.Key_UID__c, phone);
                        }
                    }
                }
                //Push Address
                if (!dao.addresses.isEmpty()) {
                    for (Address__c address : dao.addresses.values()) {
                        //Format Address Name to Concatenate
                        if (address.Street_Name__c != null) {
                            new AddressTriggerHandler.FormatAddressName().process(address);
                            //Create Hash Key
                            new AddressTriggerHandler.PopulateHash().process(address);
                            if (breakDownBypass(address, 'Address__c')) {
                                addresses.put(address.Key_UID__c, address);
                            }
                        }
                    }
                }
                //Multi Channel Handling from DAO changes
                if (dao.channelIds != null && !dao.channelIds.isEmpty()) {
                    for (Id chId:dao.channelIds) {
                        //Default to true as this will be updated by the ContactPoint Objects
                        Channel__c chRecTemp = new Channel__c();
                        chRecTemp.Id = chId;
                        chRecTemp.Is_Processed__c = true;
                        channelUpdates.put(chRecTemp.Id,chRecTemp);
                    }
                }
            }
            //Perform Commit - Collects Records that Failed
            if (!emails.isEmpty()) {
                List<Database.UpsertResult> resultEmail = Database.upsert(emails.values(), Email__c.Key_UID__c, false);
                processUpsertResult(resultEmail, emails.values());
            }
            if (!phones.isEmpty()) {
                List<Database.UpsertResult> resultPhone = Database.upsert(phones.values(), Phone__c.Key_UID__c, false);
                processUpsertResult(resultPhone, phones.values());
            }
            if (!addresses.isEmpty()) {
                List<Database.UpsertResult> resultAdd = Database.upsert(addresses.values(), Address__c.Key_UID__c, false);
                processUpsertResult(resultAdd, addresses.values());
            }
            //Perform Channel Updates
            if (!channelUpdates.isEmpty()) {
                List<Database.UpsertResult> resultChannel = Database.upsert(channelUpdates.values());
                if (resultChannel != null) {
                    Integer indCnt = 0;
                    Channel__c chRec;
                    for (Database.UpsertResult rsCH : resultChannel) {
                        String sIdx;
                        chRec = channelUpdates.values().get(indCnt);
                        if (String.isNotBlank(rsCH.getId())) {
                            sIdx = rsCH.getId();
                        } else if (chRec != null && String.isNotBlank(chRec.Id)) {
                            sIdx = chRec.Id;
                        }
                        //If Not Success re-fire
                        if (!rsCH.isSuccess() &&
                            String.isNotBlank(sIdx) &&
                            channelUpdates.containsKey(sIdx)) {
                            chRec = channelUpdates.get(sIdx);
                            Channel_Event__e cpe = new Channel_Event__e(Contact_Id__c = chRec.Contact__c, Channel_Id__c = chRec.Id);
                            if (channelEventMap != null && channelEventMap.containsKey(chRec.Id)) {
                                cpe = channelEventMap.get(chRec.Id);
                            }
                            channelEvents.add(cpe);
                        }
                        //Increase count
                        indCnt++;
                    }
                }
            }
        }
        //Redispactch failed Records
        if (channelEvents != null && !channelEvents.isEmpty()) {
            Database.SaveResult[] srList = EventBus.publish(channelEvents);
        }
    }

    /**
     * Processes Upsertresult and get failed records
     */
    @TestVisible
    private void processUpsertResult(List<Database.UpsertResult> results, List<SObject> records) {
        if (results != null && records != null) {
            Integer index = 0;
            Channel__c upd;
            try {
	            for (Database.UpsertResult res : results) {
                    SObject sobj = records.get(index);
                    /**
                     * If there are more than one error that is not of a validation rule,
                     * retry. Otherwise, if only validation rule error persists,
                     * do not retry.
                     */
                    Database.Error sysErr;
                    StatusCode resultStatusCode;
                    if (!res.isSuccess()) {
                        sysErr = res.getErrors()[0];
                        resultStatusCode = sysErr.getStatusCode();
                    }
                    if (sobj != null) {
                        Object recordChId = sobj.get('Channel__c');
                        if (recordChId != null) {
                            //Capture the upsert result
                            Boolean isSuccess = res.isSuccess();
                            upd = new Channel__c();
                            upd.Id = (Id)recordChId;
                            // Check if Last Update failed to persist
                            if (upd.Id != null) {
                                // for any failed processing due to field validations
                                if (!isSuccess && resultStatusCode == System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
                                    // create an exception log that a validation rule error occurred and data needs to be corrected
                                    nebula.logger.warn(sysErr.getMessage(), res);
                                    isSuccess = true;
                                }
                                if (channelUpdates.containsKey(upd.Id)) {
                                    //Check if Channel was tagged as Unprocessed by other objects
                                    Channel__c chEx = channelUpdates.get(upd.Id);
                                    if (chEx.Is_Processed__c == false) {
                                        isSuccess = false;
                                    }
                                }
                                //Perform Channel Updates
                                upd.Is_Processed__c = isSuccess;
                                channelUpdates.put(upd.Id, upd);
                            }
                        }
                    }
                    index++;
                }
            } catch (Exception e) {
                nebula.logger.error(e.getMessage(),e);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }

    /**
     * Process Channel Records
     */
    @TestVisible
    private void processChannels() {
        if (channels != null) {
            for (Channel__c channel : channels.values()) {
                Person360DAO dao = new Person360DAO();
                //Check if DAO is already existing
                if (mapContactChannels.containsKey(channel.Contact__c)) {
                    dao = mapContactChannels.get(channel.Contact__c);
                    //Contact has been used with different channel, tag channel to processed
                    dao.storePreviousChannelId();
                }
                //Start Processing
                startMapping(dao, channel);
                //
                mapContactChannels.put(channel.Contact__c, dao);
            }
        }
    }

    /**
     * Begin mapping from parsing MDT config with Channel populated fields
     */
    @TestVisible
    private void startMapping(Person360DAO dao, Channel__c channel) {
        //Retrieve Contact fields populated
        Map<String, Object> mapConFieldsPopulated = channel.getPopulatedFieldsAsMap();
        if (dao != null && mappingConfig != null) {
            //Updates the Channel Record replacing any existing
            dao.channelRec = channel;
            
            // Standardise the phone numbers, formatted or not - Add any missing country codes and then strip non-numeric characters
            // Yet another call to the formatting functions.
            String mp = channel.Mobile_Phone__c==null?null:phoneServices.rawFormatPhone(channel.Mobile_Phone__c);
            String p1 = channel.phone__c==null?null:phoneServices.rawFormatPhone(channel.phone__c);
            String p2 = channel.phone_2__c==null?null:phoneServices.rawFormatPhone(channel.phone_2__c);

            //Process config mapping
            for (Channel_Contact_Point_Mapping__mdt mdt : mappingConfig) {
                String sourceFld = mdt.SourceField__r.QualifiedApiName;
                if (mapConFieldsPopulated.containsKey(sourceFld)) {
                    Object conFieldVal = mapConFieldsPopulated.get(sourceFld);
                    String sObjName = mdt.TargetObject__r.QualifiedApiName;
                    String sFldName = mdt.TargetField__r.QualifiedApiName;

                    // This pulls us away from the generic field handling that the mdt was supposed to supply. Sorry.
                    // Mobile has priority and will always be promoted to a CP if populated.
                    // Phone and Phone 2 will only be promoted if they add any new information.
                    if (sObjName == 'Phone__c'){
						// Phone 1 matches mobile, so don't promote it to a contact point
						// If Phone 1 is null, skip any remaining processing
						if (mdt.Label == 'Phone' && (String.IsBlank(p1) || (String.IsNotBlank(mp) && mp.equals(p1))))  {
                            continue;
						}
						// Phone 2 matches mobile or phone 1, so don't promote it to a contact point
						// If Phone 2 is null, skip any remaining processing
                        if (mdt.Label == 'Phone_2' && (String.IsBlank(p2) || ((String.IsNotBlank(mp) && mp.equals(p2) || String.IsNotBlank(p1) && p1.equals(p2))))) {
                        	continue;
						}
						// No further processing required                        
						if (mdt.Label == 'Mobile_Phone' && String.IsBlank(mp)) {
                        	continue;
						}
                    }

                    dao.initialize(sObjName, mdt.Label + channel.Id);
                    //Set field value mapping
                    dao.addFieldValue(sFldName, conFieldVal);
                    //Fixed Mapping config for Classification
                    if (String.isNotBlank(mdt.Classification__c)) {
                        dao.addFieldValue('Classification__c', mdt.Classification__c);
                    }
                    //Fixed Mapping config for Type
                    if (String.isNotBlank(mdt.Type__c)) {
                        dao.addFieldValue('Type__c', mdt.Type__c);
                    }
                    //Link contact to Person 360 objects
                    dao.addFieldValue('Contact__c', channel.Contact__c);
                    dao.addFieldValue('Channel__c', channel.Id);
                    dao.addFieldValue('Is_Deleted__c', channel.Deleted_In_Source__c);
                    // Explicitly set Start and End Date regardless if they are null
                    dao.setFieldValue('Start_Date__c', channel.Start_Date__c);
                    dao.setFieldValue('End_Date__c', channel.End_Date__c);
                    // Set the source of the contact point record to 'Callista' when Channel__c.Source_System__c == 'callista'
                    if (String.isNotBlank(channel.Source_System__c) && SOURCE_CALLISTA.equalsIgnoreCase(channel.Source_System__c)) {
                        dao.setFieldValue('Source__c', 'Callista');
                    }
                }
            }
            //reset target
            dao.clearCache();
        }
    }

    /**
     * Retrieves Channel records for processing
     */
    @TestVisible
    private void retrieveChannelRecordsForUpdate() {
        if (!contactRecordIds.isEmpty()) {
            channels = new Map<Id, Channel__c>(
                [SELECT AU_Post_Code__c, City__c, Contact__c, Country__c, Deleted_In_Source__c, Email_Unverified__c, Email__c, End_Date__c,
                 Id, IsDeleted, Is_Processed__c, Last_Modified_By_API__c, Last_Modified_Date_API__c,
                 Line_1__c, Line_2__c, Line_3__c, Line_4__c, Line_5__c,
                 Mobile_Phone__c, Name, OS_Post_Code__c, OwnerId, Phone_2__c, Phone__c, Post_Code__c, Role_Type__c, Role__c,
                 Source_System__c, Start_Date__c, State__c, Street__c, Type__c, Unique_Id__c
                 FROM Channel__c
                 WHERE Contact__c IN: contactRecordIds 
                 AND Is_Processed__c = false
                 AND type__c != 'EMERCONT'] //  Emergency Contacts have a different field mapping and are dealt with separately
                );
        }
    }

    /**
     * Retrieve Custom Metadata mapping
     */
    @TestVisible
    private void retrieveContactPointMapping() {
        if (mappingConfig == null) {
            mappingConfig = new List<Channel_Contact_Point_Mapping__mdt>(
                [SELECT DeveloperName, Label,
                 MasterLabel, Classification__c,
                 Type__c,
                 TargetObject__c,
                 TargetObject__r.DeveloperName,
                 TargetObject__r.QualifiedApiName,
                 TargetField__c,
                 TargetField__r.DeveloperName,
                 TargetField__r.QualifiedApiName,
                 SourceObject__c,
                 SourceObject__r.DeveloperName,
                 SourceObject__r.QualifiedApiName,
                 SourceField__c,
                 SourceField__r.DeveloperName,
                 SourceField__r.QualifiedApiName
                 FROM Channel_Contact_Point_Mapping__mdt
                 ORDER BY TargetObject__c, SourceField__c]
                );
        }
    }

    /**
     * @description re-parents contact point records with a new Latest (Start Date) AND
     *  "Active" Channel
     *  @param  contactPoints : List of Contact Point objects to be re
     */
    public static void findNewContactPointChannel(List<SObject> contactPoints, Set<String> channelSourceFields) {
        try {
            Map<Id, Map<String, SObject>> cpByContact = new Map<Id, Map<String, SObject>>();
            Map<Id, Channel__c> reprocessChannels = new Map<Id, Channel__c>();
            String skEY;

            //map contact points by contact ID and by name
            for (SObject iCp : contactPoints) {
                if (iCp.get('Contact__c') != null) {
                    //get contact ID from Contact Point
                    Id contactId = (Id) iCp.get('Contact__c');
                    //get existing collection of sibling contact point
                    Map<String, SObject> cpByName = cpByContact.get(contactId);
                    if (cpByName == null) {
                        cpByName = new Map<String, SObject>();
                    }
                    skEY = (String)iCp.get('Name');
                    if (iCp.getSObjectType().getDescribe().getName() == 'Address__c') {
                        skEY = retrieveChannelAddresskey((Address__c)iCp);
                    }
                    //add to list
                    cpByName.put(skEY, iCp);
                    cpByContact.put(contactId, cpByName);
                }
            }
            
            if (!cpByContact.isEmpty() && !channelSourceFields.isEmpty()) {
                for (Contact iCon : [SELECT Id,
                                     (SELECT Id, Start_Date__c, is_Active__c, State__c,
                                      City__c, Country__c, Street__c, Post_Code__c, Email__c,
                                      Mobile_Phone__c, Phone__c, Phone_2__c, Contact__c,
                                      Address_Key__c
                                      FROM Channels__r
                                      WHERE is_Active__c = TRUE
                                      ORDER BY Start_Date__c DESC)
                                     FROM Contact
                                     WHERE Id IN :cpByContact.keySet()]) {
                    //get related contact points for this Contact
                    if (iCon.Channels__r.size() > 0) {
                        Map<String, SObject> cpList = cpByContact.get(iCon.Id);
                        for (Channel__c iCh : iCon.Channels__r) {
                            Boolean hasNewPrimary = false;
                            for (String source : channelSourceFields) {
                                //get string value of field value in Channel
                                String val = String.valueOf(iCh.get(source));
                                //try to get the contact point record that has the same value
                                if (cpList.containsKey(val)) {
                                    iCh.is_Processed__c = false;
                                    reprocessChannels.put(iCh.Id, iCh);
                                    hasNewPrimary = true;
                                }
                            }
                            //if new primary
                            if (hasNewPrimary) {
                                break;
                            }
                        }
                    }
                }
            }
            if (!reprocessChannels.isEmpty()) {
                update reprocessChannels.values();
            }
        }
        catch (Exception ex) {
            nebula.logger.error(ex.getMessage(), ex);
        } finally {
            nebula.logger.saveLog();
        }
    }

    @TestVisible
    private static String retrieveChannelAddresskey(Address__c ch) {
        String str = '';
        if (String.isNotBlank(ch.Street_Name__c)) {
            str += ch.Street_Name__c;
        }
        if (String.isNotBlank(ch.City__c)) {
            str += ch.City__c;
        }
        if (String.isNotBlank(ch.State__c)) {
            str += ch.State__c;
        }
        /*  if(String.isNotBlank(ch.Post_Code__c)) {
             str += ch.Post_Code__c;
           } */
        if (String.isNotBlank(ch.Country2__c)) {
            str += ch.Country2__c;
        }
        return str;
    }
    /**
     * @description retrieveChannelByPass Custom Metadata Include / Exclude from System Settings metadata
     * @author RANAND
     */
    @TestVisible
    private void retrieveChannelByPass() {
        if (mapBypassValueList == null) {
            mapBypassValueList = new Map<String,List<SystemSettingWrapper.ChannelBypassType>>();
            List<System_Settings__mdt> settings = SystemSettingsUtil.getinstance().getByFeature(FEATURE_CHANNEL_BYPASS_TYPE);
            List<SystemSettingWrapper.ChannelBypassType> parsedChannelList = new List<SystemSettingWrapper.ChannelBypassType>();
            SystemSettingWrapper.ChannelBypassType channelType;
            if(!settings.isEmpty()){
                for(System_Settings__mdt objSetting : settings){
                    channelType = (SystemSettingWrapper.ChannelBypassType) SystemSettingWrapper.parse(objSetting, SystemSettingWrapper.ChannelBypassType.class);
                    parsedChannelList.add(channelType);
                }
            }
            if(!parsedChannelList.isEmpty()){
                
                for(SystemSettingWrapper.ChannelBypassType objChannel : parsedChannelList){
                    List<SystemSettingWrapper.ChannelBypassType> newChannelList = new List<SystemSettingWrapper.ChannelBypassType>();
                    if (mapBypassValueList.containsKey(objChannel.channelSObject)) {
                        newChannelList = mapBypassValueList.get(objChannel.channelSObject);
                    }
                    newChannelList.add(objChannel);
                    mapBypassValueList.put(objChannel.channelSObject, newChannelList);
                }
            }
        }
    }

    /**
     * @description breakDownBypass referenced in saveChanges
     * @author pvic0002
     * @param  rec SObject being validated
     * @return     return False is excluded
     */
    @TestVisible
    private Boolean breakDownBypass(SObject rec, String sobjStrName) {
        //Default to include
        Boolean isIncluded = true;
        try {
            if (rec != null) {
                if (mapBypassValueList.containsKey(sobjStrName)) {
                    List<SystemSettingWrapper.ChannelBypassType> byPassList = mapBypassValueList.get(sobjStrName);
                    if (byPassList != null) {
                        //Checks Field Values exact or contains
                        for (SystemSettingWrapper.ChannelBypassType bypObj : byPassList) {
                            Object objVal = rec.get(bypObj.field);
                            if(objVal != null){
                                String sFieldValue = String.valueOf(objVal);
                                if (bypObj.exactMatch) {
                                    //Exact match comparison
                                    if (sFieldValue.equals(bypObj.excludeValue)) {
                                        isIncluded = false;
                                    }
                                } else {
                                    //Contains match comparison
                                    if (sFieldValue.contains(bypObj.excludeValue)) {
                                        isIncluded = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            nebula.logger.error(ex.getMessage(), ex);
        }
        return isIncluded;
    }
    
    /*
     * @description Channel unique key methods
     */  
    public static String getUniqueKey (ibdChannel__e iEvent) {
        // This passes the source details
        return getUniqueKey(iEvent.Address_Type__c, iEvent.Person_ID__c, iEvent.Start_Date__c, iEvent.Address_Line_2__c);
    }

    /*
     * @description Channel unique key methods
     */  
    public static String getUniqueKey (Channel__c aChannel) {
        return getUniqueKey(aChannel.type__c, aChannel.Person_ID__c, aChannel.Start_Date__c, aChannel.Relationship_unverified__c);
    }
    
    
   /*
    * @description
    * The relationship field is for EC channels only
    * We receive the uncleansed version of this value
	*/
    public static String getUniqueKey (String aType, String personId, Date startDate, String Relationship) {
        Datetime activeFrom = Datetime.newInstance(startDate.year(),startDate.month(),startDate.day());
        String key = personId + DELIMITER + aType;
        
        If (aType==ECTYPE && String.isNotBlank(relationship)) {
            relationship = relationship.replaceAll('[^a-zA-Z]', '').replaceAll('[sS]$', '');
            If (String.isBlank(relationship)) {relationship=DEFEC;}
            key += DELIMITER+relationship.toUppercase();
        }

        key += DELIMITER + activeFrom.format('yyyyMMdd');
        return key;
    }

    /*
     * @description Async Process event handler for Emergency Contacts. Generated from channelTriggerHandler.
     */ 
    public class ProcessECChannel implements IPlatformEventInvocable {
        private Map<Id, Integer> channelMap = new Map<Id, Integer>();
        
        public void execute(List<AsyncProcessPayload> payload) {
			try {
				initialize(payload);
				run();
			} catch(Exception ex) {
				nebula.logger.error(ex.getMessage(), ex);
			} finally {
				nebula.logger.saveLog();
			}
		}

        /*
         *  @description Pull apart the simple payload
         * {
         * "Id":"a2d9p000000CVODAA4", 
         * "retryCount":"0"
         * }
         * 
		 */
		private void initialize(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {
				for(AsyncProcessPayload payload : payloads) {
                    // Create a map of the channel ids and their retry count
					this.channelMap.put((Id) payload.get('Id'),(Integer)payload.get('retryCount'));
				}
			}
		}

        /*
         * @description At this point we have a set of channel ids that require processing.
         * 
         * This method implements the Channel to EC field mappings directly, they are not defined in custom metadata.
         * 
         * The channel is marked as processed when the emergency contact has been successfully upserted
         */ 
        public void run() {
            Emergency_Contact__c ec;
            list<Emergency_Contact__c> upsertList = new list<Emergency_Contact__c>();
            list<Channel__c> updateList = new list<channel__c>();
            Set<String> keySet;
            Integer vRetryCount;
               
            if (channelMap.size() > 0) {
                // Don't filter out is processed as these have not been included
            	List<Channel__c> cList = [select City__c, Contact__c, Country__c, Deleted_In_Source__c, Email__c, End_Date__c, Id, Person_ID__c,
                                                  Mobile_Phone__c, Phone__c, Phone_2__c,Post_Code__c, Start_Date__c, State__c, Street__c, fullname__c, Relationship__c, Relationship_unverified__c, type__c
                                             from channel__c where id in :channelMap.keySet()];
				
                nebula.logger.debug('Emergency Contact Channels to be processed : ' + Integer.valueOf(cList.size()));
                for (Channel__c c : cList) {
                    // Map fields from channel to Emergency Contact
                    ec = new Emergency_Contact__c();
                    ec.contact__c = c.contact__c;
                    ec.Channel__c = c.id;
                    ec.Relationship__c = c.relationship__c;
                    ec.Active_From__c = c.start_date__c;
                    ec.Active_To__c = c.end_date__c;
                    ec.Emergency_Contact_Name__c = c.fullname__c;
                    ec.Mobile_Phone__c = c.mobile_phone__c; 
                    ec.alternate_phone__c = c.phone__c;

                    // Get as many unique numbers as we can
                    // If the result is still identical numbers, the EC trigger will remove the copy
                    if (!String.isBlank(c.phone_2__c)) {
                        if (phoneServices.compareNumbers(c.mobile_phone__c, c.phone__c)) {
                            ec.alternate_phone__c = c.phone_2__c;
                        }
                    }
					ec.Email_Address__c = c.email__c;

                    // Tidy up the Callista data. This is not done when entered manaually.
                    ec.City__c = contactServices.toProperCase(c.City__c);
					ec.Street_Name__c = contactServices.toProperCase(c.street__c);
                    ec.State__c = contactServices.toProperCase(c.state__c);
                    ec.Post_Code__c = c.post_code__c;
                    ec.Country__c = c.country__c;
                    
                    // Use the contact point approach for the uique key
                    keySet = EmergencyContactServices.buildECKeySet(ec);
                    ec.Key_UID__c = Person360Helper.generatePerson360Key(keySet);
                    
                    upsertList.add(ec);
                }

                nebula.logger.debug('Emergency Contacts to be upserted : ' + Integer.valueOf(upsertList.size()));
                Database.UpsertResult [] upsertResults = Database.upsert(upsertList, Emergency_Contact__c.Fields.key_uid__c, false);
                Database.UpsertResult aResult = null;
                for (Integer i=0; i<upsertResults.size(); i++) {
                    aResult = upsertResults[i];
                    if (!aResult.isSuccess()) {
                        vRetryCount = 0;
                        for (Database.Error err : aResult.getErrors()) {
							// to do implement a rety                            
                            nebula.Logger.error(err.getMessage() + '\r' + json.serializePretty(upsertList[i]), upsertList[i].channel__c); // link error to the channel 
                        } 
                    }  else {
						cList[i].unique_id__c = getUniqueKey(cList[i]);
                        cList[i].is_processed__c = true;
                        updateList.add(cList[i]);
                        nebula.logger.fine('Emergency Contact successfully ' + String.valueOf(aResult.isCreated()?'created':'updated') ,aResult.getId());
                    }
                }
                
                // Set the successful channels to processed
                nebula.logger.debug('Emergency Contact Channels to be updated : ' + Integer.valueOf(updateList.size()));
				triggerCommon.disableTrigger('Channel__c');
                Database.SaveResult [] updateResults = Database.update(updateList, false);
				triggerCommon.enableTrigger('Channel__c');
                Database.SaveResult udResult = null;
                for (Integer i=0; i<updateResults.size(); i++) {
                    udResult = updateResults[i];
                    if (!udResult.isSuccess()) {
                        for (Database.Error err : udResult.getErrors()) {
                            nebula.Logger.error(err.getMessage() + '\r' + json.serializePretty(updateList[i]),updateList[i].id);
                        } 
                    }  else {
                        nebula.logger.fine('Emergency contact channel successfully processed',udResult.getId());
                    }
                }
            } 
        }
    }
}