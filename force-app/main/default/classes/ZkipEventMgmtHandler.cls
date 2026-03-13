/**
 * @author J Mapanao
 * @description Class that will be called from Campaign lightning record page (RecordType = ERDA Event)
 *              This will be used for Salesforce - Zkipster Integration:
 *              -Create Event in Zkipster using Campaign details (Recordtype = ERDA Event)
 *              -Update Event in Zkipster using updated Campaign details (Recordtype = ERDA Event)
 *              -Create Guest List(s) in Zkipster using Campaign details (Recordtype = ERDA Guest List)
 *              -Add Guests in Zkipster using Campaign Member records
 * @revision
 */
public with sharing class ZkipEventMgmtHandler {

    /**
     * @param campaignId
     * @description Handle logic for Event creation in Zkipster from Campaign record (Recordtype = ERDA Event)
     * @return String
     */
    @AuraEnabled
    public static String createEventToZkipster(String campaignId) {

        if (String.isBlank(campaignId)) return ZkipConstants.ERR_MISSING_CAMPID;

        Campaign camp = [SELECT Id, Name, Zkipster_Event_Id__c, Event_Street__c,  Event_City__c, Event_State__c,
                                Event_Zip__c, Event_Country__c, Event_Start_DateTime__c, Event_End_DateTime__c,
                                Event_Location__c, Zkipster_Error_Message__c, Type
                        FROM Campaign
                        WHERE Id =: campaignId];

        // If zkipster Event Id is not blank or null, do not allow user to create again. Throw error message
        if (String.isNotBlank(camp.Zkipster_Event_Id__c)) return ZkipConstants.ERR_EVENT_ALRDY_CREATED;

        // Validate if custom setting for CreateEvent and CreateGuestList is not null and its field values
        // Otherwise, do nothing or log error
        Map<String, IntegrationSettingCRMToZkipster__mdt> integSettingCE = ZkipsterUtil.retrieveIntegrationCRMToZkipster();
        IntegrationSettingCRMToZkipster__mdt integSettingCreateEvent = integSettingCE.get('CreateEvent');

        if (integSettingCreateEvent == null || String.isBlank(integSettingCreateEvent.Named_Credentials__c) || String.isBlank(integSettingCreateEvent.Path__c)
                || String.isBlank(integSettingCreateEvent.Method__c)) {
            return ZkipConstants.ERR_MISSING_SETTING;
        }

        try {

            // Get endpoint
            String ceEndpoint = ZkipConstants.ENDPOINT_PREFIX + integSettingCreateEvent.Named_Credentials__c + integSettingCreateEvent.Path__c;

            // Get authorization key
            //String ceAuthKey = ZkipConstants.API_ACCESS_KEY_PREFIX + integSettingCreateEvent.API_Access_Key__c;

            // Create payload stub
            String payload = ZkipCreateUpdateEventRequest.createEventPayload(camp, false);
            System.debug('### ZkipEventMgmtHandler.createEventToZkipster payload ==>'+payload);

            HttpResponse resZkipCEResponse = ZkipsterUtil.send(ZkipConstants.CONTENT_TYPE_JSON, integSettingCreateEvent.Method__c, ceEndpoint, payload, 40000);
            System.debug('### ZkipEventMgmtHandler.createEventToZkipster response getStatusCode() ==>'+resZkipCEResponse.getStatusCode());
            System.debug('### ZkipEventMgmtHandler.createEventToZkipster response getBody() ==>'+resZkipCEResponse.getBody());

            // Get Zkipster Event Id when creation is successful
            if (resZkipCEResponse.getStatusCode() == 201) {

                // Convert json response to apex wrapper class
                ZkipCreateUpdateEventResponse desResponse = ZkipCreateUpdateEventResponse.parse(resZkipCEResponse.getBody());

                camp.Zkipster_Event_Id__c = desResponse.data.id;
                camp.Zkipster_Error_Message__c = '';
                update camp;
            }
            else {
                camp.Zkipster_Error_Message__c = resZkipCEResponse.getBody();
                update camp;
                return ZkipConstants.ERR_CALLOUT;
            }
        } catch (Exception ex) {
            System.debug('### ZkipEventMgmtHandler.createEventToZkipster error ==>'+ex + ex.getLineNumber() + ex.getStackTraceString());
            ExLog.add('Zkipster Callout', 'ZkipEventMgmtHandler', 'createEventToZkipster', ex, campaignId);
            return ZkipConstants.ERR_CALLOUT;
        }

        return ZkipConstants.SUCC_CREATE_EVENT;
    }

    /**
     * @param campaignId
     * @description Handle logic for Event update in Zkipster from Campaign record (Recordtype = ERDA Event)
     * @return String
     */
    @AuraEnabled
    public static String updateEventToZkipster(String campaignId) {

        if (String.isBlank(campaignId)) return ZkipConstants.ERR_MISSING_CAMPID;

        Campaign camp = [SELECT Id, Name, Zkipster_Event_Id__c, Event_Street__c, Event_City__c, Event_State__c,
                                Event_Zip__c, Event_Country__c, Event_Start_DateTime__c, Event_End_DateTime__c,
                                Event_Location__c, Zkipster_Error_Message__c, Type, Status
                        FROM Campaign
                        WHERE Id =: campaignId];

        // If zkipster Event Id is not blank or null, do not allow user to create again. Throw error message
        if (String.isBlank(camp.Zkipster_Event_Id__c)) {
            return ZkipConstants.ERR_EVENT_NOT_EXISTS;
        }
        // Throw error when Campaign status is Completed
        else if (camp != null && camp.Status != null && camp.Status == ZkipConstants.CAMP_STATUS_COMPLETED) {
            return ZkipConstants.ERR_EVENT_STATUS_COMPLETED;
        }
        // Throw error when Campaign's Start Date is < TODAY as Zkipster API doesn't allow update on Event when Start Date is in the past
        else if (camp != null && camp.Event_Start_DateTime__c != null && camp.Event_Start_DateTime__c < Date.today()) {
            return ZkipConstants.ERR_EVENT_START_DATE_PAST;
        }

        // Validate if custom setting for CreateEvent and CreateGuestList is not null and its field values
        // Otherwise, do nothing or log error
        Map<String, IntegrationSettingCRMToZkipster__mdt> integSettingUE = ZkipsterUtil.retrieveIntegrationCRMToZkipster();
        IntegrationSettingCRMToZkipster__mdt integSettingUpdateEvent = integSettingUE.get('UpdateEvent');

        if (integSettingUpdateEvent == null || String.isBlank(integSettingUpdateEvent.Named_Credentials__c) || String.isBlank(integSettingUpdateEvent.Path__c)
                || String.isBlank(integSettingUpdateEvent.Method__c)) {
            return ZkipConstants.ERR_MISSING_SETTING;
        }

        try {

            // Get endpoint
            String tempEndpoint = ZkipConstants.ENDPOINT_PREFIX + integSettingUpdateEvent.Named_Credentials__c + integSettingUpdateEvent.Path__c;
            String updateEventEndpoint = tempEndpoint.replace('{eventId}',String.valueOf(camp.Zkipster_Event_Id__c));

            // Get authorization key
           // String ueAuthKey = ZkipConstants.API_ACCESS_KEY_PREFIX + integSettingUpdateEvent.API_Access_Key__c;

            // Create payload stub
            String payload = ZkipCreateUpdateEventRequest.createEventPayload(camp, true);
            System.debug('### ZkipEventMgmtHandler.updateEventToZkipster payload ==>'+payload);

            HttpResponse resZkipUEResponse = ZkipsterUtil.send(ZkipConstants.CONTENT_TYPE_JSON, integSettingUpdateEvent.Method__c, updateEventEndpoint, payload, 40000);
            System.debug('### ZkipEventMgmtHandler.updateEventToZkipster response getStatusCode() ==>'+resZkipUEResponse.getStatusCode());
            System.debug('### ZkipEventMgmtHandler.updateEventToZkipster response getBody() ==>'+resZkipUEResponse.getBody());

            // Capture error message if update callout is not successful
            if (resZkipUEResponse.getStatusCode() != 200) {
                camp.Zkipster_Error_Message__c = resZkipUEResponse.getBody();
                update camp;
                return ZkipConstants.ERR_CALLOUT;
            } else {
                if (String.isNotBlank(camp.Zkipster_Error_Message__c)) {
                    camp.Zkipster_Error_Message__c = '';
                    update camp;
                }
            }

        } catch (Exception ex) {
            System.debug('### ZkipEventMgmtHandler.updateEventToZkipster error ==>'+ex);
            ExLog.add('Zkipster Callout', 'ZkipEventMgmtHandler', 'updateEventToZkipster', ex, campaignId);
            return ZkipConstants.ERR_CALLOUT;
        }

        return ZkipConstants.SUCC_UPDATE_EVENT;
    }

    /**
     * @param campaignId
     * @description Handle logic for Guest List creation in Zkipster from Campaign record (Recordtype = ERDA Guest List)
     * @return String
     */
    @AuraEnabled
    public static String createGuestListToZkipster(String campaignId) {

        if (String.isBlank(campaignId)) return ZkipConstants.ERR_MISSING_CAMPID;

        Map<String, IntegrationSettingCRMToZkipster__mdt> integSettingCGL = ZkipsterUtil.retrieveIntegrationCRMToZkipster();
        IntegrationSettingCRMToZkipster__mdt integSettingCreateGL = integSettingCGL.get('CreateGuestList');

        // Validate if custom setting for CreateEvent and CreateGuestList is not null and its field values
        // Otherwise, do nothing or log error
        if (integSettingCreateGL == null || String.isBlank(integSettingCreateGL.Named_Credentials__c) || String.isBlank(integSettingCreateGL.Path__c)
                || String.isBlank(integSettingCreateGL.Method__c)) {
            return ZkipConstants.ERR_MISSING_SETTING;
        }

        List<Campaign> existingGuestList = [SELECT Id, Name, Parent_ERDA_Event__c, Parent_ERDA_Event__r.Zkipster_Event_Id__c, Zkipster_Guest_List_Id__c
                                            FROM Campaign
                                            WHERE Parent_ERDA_Event__r.Id =: campaignId];

        // Return error when no campaign records to create in zkipster
        if (existingGuestList.isEmpty()) return ZkipConstants.ERR_NO_GUEST_LIST_TO_CREATE;

        Boolean isEventIdMissing = false;
        String zkipsterEventId = null;
        List<Campaign> guestListToCreateInZkip = new List<Campaign>();

        for (Campaign gl : existingGuestList) {
            if (String.isBlank(gl.Parent_ERDA_Event__r.Zkipster_Event_Id__c)) {
                isEventIdMissing = true;
                break;
            }
            else {
                zkipsterEventId = gl.Parent_ERDA_Event__r.Zkipster_Event_Id__c;
            }

            // Collect all campaigns with no zkipster id
            if (String.isBlank(gl.Zkipster_Guest_List_Id__c)) {
                guestListToCreateInZkip.add(gl);
            }
        }

        // Return error message when parent campaign's zkipster id do not exists
        if (isEventIdMissing) {
            return ZkipConstants.ERR_EVENT_NOT_EXISTS;
        }
        // Return error message when all campaigns have zkipster id
        else if (guestListToCreateInZkip.isEmpty()) {
            return ZkipConstants.ERR_ALL_GUEST_LIST_EXISTS;
        }

        try {

            // Get endpoint
            String createGuestListEndpoint = ZkipConstants.ENDPOINT_PREFIX + integSettingCreateGL.Named_Credentials__c + integSettingCreateGL.Path__c;
            // Get authorization key
            //String createGuestListAuthKey = ZkipConstants.API_ACCESS_KEY_PREFIX + integSettingCreateGL.API_Access_Key__c;

            for (Campaign gl : guestListToCreateInZkip) {

                String payload = ZkipCreateUpdateGuestListRequest.createGuestListPayload(gl,true);
                System.debug('### ZkipEventMgmtHandler.createGuestListToZkipster Create Guest List payload ==>'+payload);

                HttpResponse resZkipCreateGuestListResponse = ZkipsterUtil.send(ZkipConstants.CONTENT_TYPE_JSON, integSettingCreateGL.Method__c, createGuestListEndpoint, payload, null);
                System.debug('### ZkipEventMgmtHandler.createGuestListToZkipster response getStatusCode() ==>'+resZkipCreateGuestListResponse.getStatusCode());
                System.debug('### ZkipEventMgmtHandler.createGuestListToZkipster response getBody() ==>'+resZkipCreateGuestListResponse.getBody());

                // Store zkipster id when guest list has been created
                if (resZkipCreateGuestListResponse.getStatusCode() == 201) {
                    ZkipCreateUpdateGuestListResponse desResponse = ZkipCreateUpdateGuestListResponse.parse(resZkipCreateGuestListResponse.getBody());
                    gl.Zkipster_Guest_List_Id__c = desResponse.data.id;
                }
                // Store call out error for creation of guest list in zkipster
                else {
                    gl.Zkipster_Error_Message__c = resZkipCreateGuestListResponse.getBody();
                }
            }

            update guestListToCreateInZkip;

        } catch (Exception ex) {
            System.debug('### ZkipEventMgmtHandler.createGuestListToZkipster error ==>'+ex);
            ExLog.add('Zkipster Callout', 'ZkipEventMgmtHandler', 'createGuestListToZkipster', ex, campaignId);
            return ZkipConstants.ERR_CALLOUT;
        }

        return ZkipConstants.SUCC_CREATE_GUEST_LIST;
    }

    /**
     * @param campaignId
     * @description Handle logic for Guest creation in Zkipster using Campaign Member record
     *              This will call a batch to handle creation of Guests in Zkipster due to avoid callout limits
     *              as Guest List might contain more than 100 Campaign Members
     * @return String
     */
    @AuraEnabled
    public static String syncMembers(String campaignId) {

        if (String.isBlank(campaignId)) return ZkipConstants.ERR_MISSING_CAMPID;

        Campaign camp = [SELECT Id, Zkipster_Event_Id__c, (SELECT Id, Zkipster_Guest_List_Id__c FROM Campaigns__r) FROM Campaign WHERE Id =: campaignId];

        if (String.isBlank(camp.Zkipster_Event_Id__c)) return ZkipConstants.ERR_EVENT_NOT_EXISTS;

        for (Campaign guestListRec : camp.Campaigns__r) {
            if (String.isBlank(guestListRec.Zkipster_Guest_List_Id__c)) {
                return ZkipConstants.ERR_GUEST_LIST_NOT_EXISTS;
            }
        }

        List<ApexClass> apList = [Select Id from ApexClass where Name = 'ZkipSyncMembersBatch'];

        Integer enqueuedJobs = [SELECT COUNT() FROM AsyncApexJob
                                WHERE JobType='BatchApex'
                                AND Status IN ('Processing','Preparing','Queued')
                                AND ApexClassID =: apList[0].Id] ;

        if (enqueuedJobs <= 0) {
            // Batch size set to 5 to avoid govern limit for callout
            Id batchInstanceId = Database.executeBatch(new ZkipSyncMembersBatch(campaignId), 5);
            return ZkipConstants.SUCC_SYNC_INITIATED;
        }
        else {
            return ZkipConstants.ERR_SYNC_IN_PROGRESS;
        }
    }

    /**
     * @param campaignId
     * @description Handle logic for:
     *              -Getting updates from zkipster such us status, etc.
     *              -Create Interim record for guest created directly from zkipster
     * @return String
     */
    @AuraEnabled
    public static String getUpdatesFromZkipster(String campaignId) {

        if (String.isBlank(campaignId)) return ZkipConstants.ERR_MISSING_CAMPID;

        List<ApexClass> apList = [Select Id from ApexClass where Name = 'ZkipGetUpdatesBatch'];

        Integer enqueuedJobs = [SELECT COUNT() FROM AsyncApexJob
                                WHERE JobType='BatchApex'
                                AND Status IN ('Processing','Preparing','Queued')
                                AND ApexClassID =: apList[0].Id];

        if (enqueuedJobs <= 0) {
            // Batch size set to 1 (process 1 campaign that might contains multiple campaign members)
            // to avoid govern limit for callout
            if (!Test.isRunningTest())
                Id batchInstanceId = Database.executeBatch(new ZkipGetUpdatesBatch(campaignId), 1);
            return ZkipConstants.SUCC_GET_UPDATES;
        }
        else {
            return ZkipConstants.ERR_GET_UPDATES;
        }
    }

    /**
     * @param campaignId
     * @description Handle logic for closing campaign status to Completed and call getUpdatesFromZkipster method
     * @return String
     */
    @AuraEnabled
    public static String closeEvent(String campaignId) {
        if (String.isBlank(campaignId)) return ZkipConstants.ERR_MISSING_CAMPID;

        Campaign camp = [SELECT Id FROM Campaign WHERE Id =: campaignId];
        camp.Status = ZkipConstants.CAMP_STATUS_COMPLETED;
        update camp;
        return getUpdatesFromZkipster(camp.Id);
    }
}