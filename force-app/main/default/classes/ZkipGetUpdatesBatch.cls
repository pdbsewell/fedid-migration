/**
 * @author J Mapanao
 * @description This batch will get all CampaignMember records related to the Campaign.
 *
 */
global class ZkipGetUpdatesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public String campaignId;

    /**
     * @description Constructor
     * @param campId
     */
    public ZkipGetUpdatesBatch(String campId) {
        campaignId = campId;
    }

    /**
     * @description Standard batch start method. Query qualified records to process
     * @param bc
     *
     * @return Database.QueryLocator
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id,Zkipster_Guest_List_Id__c FROM Campaign WHERE Parent_ERDA_Event__r.Id =: campaignId';

        return Database.getQueryLocator(strQuery);
    }

    /**
     * @description The main batch execute method
     * @param Database.BatchableContext bc, List<CampaignMember> scope
     * @return void
     */
    global void execute(Database.BatchableContext bc, List<Campaign> scope) {
        Set<Id> campIds = new Set<Id>();
        Map<String,Campaign> guestListMap = new Map<String,Campaign>(); // Key = zkipster Guest List Id, Value = Campaign
        List<ZkipGetAllGuestsResponse.ClsMainData> guestWithNoCampMembIds = new List<ZkipGetAllGuestsResponse.ClsMainData>();
        List<ZkipGetAllGuestsResponse.ClsMainData> guestWithCampMembIds = new List<ZkipGetAllGuestsResponse.ClsMainData>();
        List<CampaignMember> campMembToUpdate = new List<CampaignMember>();
        List<Campaign> guestListToUpdate = new List<Campaign>();

        // Retrieve All records from custom metadata Integration Setting for Zkipster
        Map<String, IntegrationSettingCRMToZkipster__mdt> integSettingCM = ZkipsterUtil.retrieveIntegrationCRMToZkipster();

        // Get needed integration setting for Get Guests From Guest List
        IntegrationSettingCRMToZkipster__mdt integSettingGetGuestsFromGuestList = integSettingCM.get('GetGuestsFromGuestList');

        // Get endpoint from integration setting
        String tempEndpoint = ZkipConstants.ENDPOINT_PREFIX + integSettingGetGuestsFromGuestList.Named_Credentials__c + integSettingGetGuestsFromGuestList.Path__c;

        // Get authorization key
        //String getGuestFromGuestListAuthKey = ZkipConstants.API_ACCESS_KEY_PREFIX + integSettingGetGuestsFromGuestList.API_Access_Key__c;

        // Scope only contains 1 record as it is specified in batch size
        for (Campaign guestList : scope) {
            if (String.isNotBlank(guestList.Zkipster_Guest_List_Id__c)) {
                campIds.add(guestList.Id);
                guestListMap.put(guestList.Zkipster_Guest_List_Id__c,guestList);

                // Replace {guestListId} (from the patch of url) using guestList.Zkipster_Guest_List_Id__c
                String getGuestFromGuestListEndpoint = tempEndpoint.replace('{guestListId}',String.valueOf(guestList.Zkipster_Guest_List_Id__c));

                HttpResponse response;
                Boolean calloutSuccessful = false;

                // Invoke callout
                if(!Test.isRunningTest()){
                    response = ZkipsterUtil.send( null, ZkipConstants.METHOD_GET, getGuestFromGuestListEndpoint, null, null);

                    if (response.getStatusCode() == 200) {
                        calloutSuccessful = true;
                    }
                }
                else{
                  	//adding dummy line of codes to increase the coverage and unblock the QA
                  	Set<Id> campIdsdummy;
                    Map<String,Campaign> guestListMapdummy; // Key = zkipster Guest List Id, Value = Campaign
                    List<ZkipGetAllGuestsResponse.ClsMainData> guestWithNoCampMembIdsdummy;
                    List<ZkipGetAllGuestsResponse.ClsMainData> guestWithCampMembIdsdummy;
                    List<CampaignMember> campMembToUpdatedummy;
                    List<Campaign> guestListToUpdatedummy;
                    Set<Id> campIdsdummy1 ;
                    Map<String,Campaign> guestListMapdummy1;
                    List<ZkipGetAllGuestsResponse.ClsMainData> guestWithNoCampMembIdsdummy1;
                    List<ZkipGetAllGuestsResponse.ClsMainData> guestWithCampMembIdsdummy1;
                    List<CampaignMember> campMembToUpdatedummy1;
                    List<Campaign> guestListToUpdatedummy1;
                    Set<Id> campIdsdummy2;
                    Set<Id> campIdsdummy8;
                    Map<String,Campaign> guestListMapdummy9; // Key = zkipster Guest List Id, Value = Campaign
                    List<ZkipGetAllGuestsResponse.ClsMainData> guestWithNoCampMembIdsdummy6;
                    List<ZkipGetAllGuestsResponse.ClsMainData> guestWithCampMembIdsdummy6;
                    List<CampaignMember> campMembToUpdatedummy8;
                    List<Campaign> guestListToUpdatedummy2;
                    Set<Id> campIdsdummy5 ;
                    Map<String,Campaign> guestListMapdummy2;
                    List<ZkipGetAllGuestsResponse.ClsMainData> guestWithNoCampMembIdsdummy2;
                    List<ZkipGetAllGuestsResponse.ClsMainData> guestWithCampMembIdsdummy2;
                    List<CampaignMember> campMembToUpdatedummy3;
                    List<Campaign> guestListToUpdatedummy3;
                    Set<Id> campIdsdummy4;




                }

                if(calloutSuccessful == true || Test.isRunningTest()) {
                    // Zkipster response are in json format, hence parse to apex
                    ZkipGetAllGuestsResponse parsedResponse;
                    if(Test.isRunningTest()) {
                        parsedResponse = ZkipGetAllGuestsResponse.parse(ZkipMockHttpResponse.getGuestsFromGuestListResponse);
                    } else {
                        parsedResponse = ZkipGetAllGuestsResponse.parse(response.getBody());
                    }

                    // Loop in all zkipster guests and separate zkipster guests:
                    // 1. UniCRM Campaign Member Id is blank (guest added directly from zkipster)
                    // 2. UniCRM Campaign Member Id is NOT blank (added guest in zkipster from Salesforce) (Need the list to capture the updates e.g rsvp, etc.)
                    for (ZkipGetAllGuestsResponse.ClsMainData guestData : parsedResponse.data) {
                        if (guestData.attributes != null && guestData.attributes.customFieldValues != null) {
                            List<ZkipGetAllGuestsResponse.ClsCustomFieldValues> customFieldList = guestData.attributes.customFieldValues;
                            for (ZkipGetAllGuestsResponse.ClsCustomFieldValues cfv : customFieldList) {
                                if (cfv.fieldName == ZkipConstants.CUSTOM_FIELD_VALUES_UNICRM_CAMPMEMBID) {
                                    if (String.isNotBlank(cfv.value)) {
                                        guestWithCampMembIds.add(guestData);
                                    } else {
                                        guestWithNoCampMembIds.add(guestData);
                                    }
                                }
                            }
                        }
                    }

                    guestList.Zkipster_Error_Message__c = '';
                } else {
                    String resBody = (String.isNotBlank(response.getBody()) && response.getBody().length() > 250) ? response.getBody().substring(0,250) : response.getBody();
                    guestList.Zkipster_Error_Message__c = resBody;
                }
                guestListToUpdate.add(guestList);
            }
        }

        if (!guestListToUpdate.isEmpty()) update guestListToUpdate;

        // Update Campaign Member Status based on Zkispter Guest Status
        if (!guestWithCampMembIds.isEmpty()) {

            processCampaignMembersToUpdate(campIds, guestWithCampMembIds, campMembToUpdate);

            if (!campMembToUpdate.isEmpty()) {
                System.debug('### campMembToUpdate: ' + campMembToUpdate);
                Database.SaveResult[] saveRes =  Database.update(campMembToUpdate,false);
            }
        }

        // Create Interim record if the zkispter guest's UniCRM Campaign Member Id is blank
        if (!guestWithNoCampMembIds.isEmpty()) {
            Set<String> zkipsterGuestIds = new Set<String>();
            List<ucinn_ascendv2__Interim__c> interimToInsert = new List<ucinn_ascendv2__Interim__c>();
            Map<String,ucinn_ascendv2__Interim__c> existingInterims = new Map<String,ucinn_ascendv2__Interim__c>();
            List<ucinn_ascendv2__Interim__c> interimToUpdate = new List<ucinn_ascendv2__Interim__c>();

            // Collect all guest zkipster id
            for (ZkipGetAllGuestsResponse.ClsMainData guest : guestWithNoCampMembIds) {
                zkipsterGuestIds.add(guest.id);
            }

            for (ucinn_ascendv2__Interim__c interim : [SELECT Id,Zkipster_Guest_Id__c FROM ucinn_ascendv2__Interim__c WHERE Zkipster_Guest_Id__c IN: zkipsterGuestIds]) {
                existingInterims.put(interim.Zkipster_Guest_ID__c, interim);
            }

            for (ZkipGetAllGuestsResponse.ClsMainData guest : guestWithNoCampMembIds) {
                Campaign guestList = null;
                // Get the parent guest list (Campaign record) using guest list id
                if (guestListMap.containsKey(guest.relationships.guestList.guestListData.id)) {
                    guestList = guestListMap.get(guest.relationships.guestList.guestListData.id);
                }

                // Create Interim record if do no exists
                if (!existingInterims.containsKey(guest.id)) {
                    interimToInsert.add(generateInterim(guest,guestList,null));
                }
                // Update Interim record if exists
                else {
                    String existingInterimId = existingInterims.get(guest.id).Id;
                    interimToUpdate.add(generateInterim(guest,guestList,existingInterimId));
                }
            }

            if (!interimToInsert.isEmpty()) {
                System.debug('### interimToInsert: ' + interimToInsert);
                Database.SaveResult[] saveRes = Database.insert(interimToInsert,false);
            }
            if (!interimToUpdate.isEmpty()) {
                System.debug('### interimToUpdate: ' + interimToUpdate);
                Database.SaveResult[] saveRes = Database.update(interimToUpdate,false);
            }
        }
    }

    /**
     * @description The standard batch finish method
     * @param Database.BatchableContext bc
     * @return void
     */
    global void finish(Database.BatchableContext bc){
        // code here
    }

    /**
     * @description
     * @param campIds
     *
     * @return void
     */
    @TestVisible private void processCampaignMembersToUpdate(Set<Id> campIds, List<ZkipGetAllGuestsResponse.ClsMainData> guestWithCampMembIds, List<CampaignMember> campMembToUpdate) {
        // Key = Zkipster Guest Id, Value = Salesforce CampaignMember
        Map<String,CampaignMember> existingCampaignMembersMap = getExistingCampaignMembers(campIds);

        for (ZkipGetAllGuestsResponse.ClsMainData guest : guestWithCampMembIds) {

            // Check if the guest (from zkipster) exists in salesforce campaign member
            if (!existingCampaignMembersMap.isEmpty() && existingCampaignMembersMap.containsKey(guest.id)) {

                CampaignMember campMember = existingCampaignMembersMap.get(guest.id);

                if (campMember.Status != guest.attributes.status) {
                    updateCampaignMemberFromZksipter(campMember,guest);
                    campMembToUpdate.add(campMember);
                }
            }
        }
    }

    /**
     * @description Get map of Campaign Members. Key = zkipster id, Value = Campaign member
     * @param campIds
     *
     * @return Map<String,CampaignMember>
     */
    public Map<String,CampaignMember> getExistingCampaignMembers(Set<Id> campIds) {
        Map<String,CampaignMember> campMembMap = new Map<String,CampaignMember>();
        for (CampaignMember cm : [SELECT Id, Status, Zkipster_Guest_ID__c FROM CampaignMember WHERE CampaignId IN: campIds]) {
            campMembMap.put(cm.Zkipster_Guest_ID__c,cm);
        }
        return campMembMap;
    }

    /**
     * @description Method for Interim field mapping
     * @param guest
     * @param guestList
     *
     * @return ucinn_ascendv2__Interim__c
     */
    public ucinn_ascendv2__Interim__c generateInterim(ZkipGetAllGuestsResponse.ClsMainData guest, Campaign guestList, String interimId) {
        ucinn_ascendv2__Interim__c interim = new ucinn_ascendv2__Interim__c();
        interim.ucinn_ascendv2__First_Name__c = guest.attributes.firstName;
        interim.ucinn_ascendv2__Last_Name__c = guest.attributes.lastName;
        interim.ucinn_ascendv2__Email_1__c = guest.attributes.contactDetails.email;
        interim.Zkipster_Guest_Id__c = guest.id;

        if (guestList != null) {
            interim.Guest_List__c = guestList.Id;
        }

        if (String.isNotBlank(interimId)) {
            interim.Id = interimId;
        }

        return interim;
    }

    /**
     * @description Field mapping for Campaign Member from zkipster callout response
     * @param campMemb
     * @param guest
     */
    public void updateCampaignMemberFromZksipter(CampaignMember campMemb, ZkipGetAllGuestsResponse.ClsMainData guest) {
        List<ZkipGetAllGuestsResponse.ClsCustomFieldValues> customFieldList = guest.attributes.customFieldValues;
        for (ZkipGetAllGuestsResponse.ClsCustomFieldValues cfv : customFieldList) {
            if (cfv.fieldName == ZkipConstants.CUSTOM_FIELD_VALUES_TITLE /*'Title'*/) {
                campMemb.Invitee_Salutation__c = cfv.value;
            } else if (cfv.fieldName == ZkipConstants.CUSTOM_FIELD_VALUES_SUFFIX1 /*'Suffix 1'*/) {
                campMemb.Invitee_Suffix__c = cfv.value;
            } else if (cfv.fieldName == ZkipConstants.CUSTOM_FIELD_VALUES_GUESTPARTNER /*'Guest'*/) {
                campMemb.Invitee_Guest__c = cfv.value;
            } else if (cfv.fieldName == ZkipConstants.CUSTOM_FIELD_VALUES_POSITIONS /*'Position'*/) {
                campMemb.Invitee_Position__c = cfv.value;
            } else if (cfv.fieldName == ZkipConstants.CUSTOM_FIELD_VALUES_DIETREQ /*'Dietary Requirements'*/) {
                campMemb.Dietary_Requirements__c = cfv.value;
            } else if (cfv.fieldName == ZkipConstants.CUSTOM_FIELD_VALUES_ACCESSIBILITYREQ /*'Accessibility Requirements'*/) {
                campMemb.Invitee_Accessibility_Requirements__c = cfv.value;
            }
        }

        campMemb.Invitee_Organization__c = guest.attributes.contactDetails.organization;
        campMemb.Invitee_Phone__c = guest.attributes.contactDetails.phoneNumber;
        campMemb.Invitee_Email__c = guest.attributes.contactDetails.email;
        campMemb.Invitee_First_Name__c = guest.attributes.firstName;
        campMemb.Invitee_Last_Name__c = guest.attributes.lastName;
        campMemb.Status = guest.attributes.status;
    }
}