/**
 * @author J Mapanao
 * @description This batch will get all CampaignMember records related to the Campaign.
 *              This will handles all the logic for creating Guests in Zkipster
 */
global class ZkipSyncMembersBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public String campaignId;

    /**
     * @param campId
     * @description Constructor
     */
    public ZkipSyncMembersBatch(String campId) {
        campaignId = campId;
    }

    /**
     * @param bc
     * @description Standard batch start method. Query qualified records to process
     * @return Database.QueryLocator
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id,Zkipster_Guest_Id__c,Zkipster_Error_Message__c,Campaign.Zkipster_Guest_List_Id__c,'
                            + 'Invitee_Title__c,Invitee_First_Name__c,Invitee_Last_Name__c,'
                            + 'Invitee_Suffix__c,Invitee_Guest__c,Invitee_Position__c,Dietary_Requirements__c,'
                            + 'Invitee_Accessibility_Requirements__c,Invitee_Organization__c,Invitee_Phone__c,'
                            + 'Invitee_Email__c,Invitee_Salutation__c FROM CampaignMember';

        if (String.isNotBlank(campaignId)) {
            strQuery += ' WHERE Campaign.Parent_ERDA_Event__r.Id =: campaignId';
        }

        return Database.getQueryLocator(strQuery);
    }

    /**
     * @param Database.BatchableContext bc, List<CampaignMember> scope
     * @description The main batch execute method
     * @return void
     */
    global void execute(Database.BatchableContext bc, List<CampaignMember> scope){

        Map<String, IntegrationSettingCRMToZkipster__mdt> integSettingCM = ZkipsterUtil.retrieveIntegrationCRMToZkipster();
        IntegrationSettingCRMToZkipster__mdt integSettingAddGuest = integSettingCM.get('AddGuest');

        // Get endpoint
        String addGuestEndpoint = ZkipConstants.ENDPOINT_PREFIX + integSettingAddGuest.Named_Credentials__c + integSettingAddGuest.Path__c;

        // Get authorization key
        //String amAuthKey = ZkipConstants.API_ACCESS_KEY_PREFIX + integSettingAddGuest.API_Access_Key__c;

        List<CampaignMember> cmListToUpdate = new List<CampaignMember>();
        for (CampaignMember cm : scope) {
            if (String.isBlank(cm.Zkipster_Guest_Id__c)) {

                // Create payload
                String payload = ZkipAddGuestRequest.addGuestPayload(cm);
                if(!Test.isRunningTest()){
                    HttpResponse result = ZkipsterUtil.send(ZkipConstants.CONTENT_TYPE_JSON, integSettingAddGuest.Method__c, addGuestEndpoint, payload, null);
                    
                    system.debug('reess '+result);
                    if (result.getStatusCode() == 201) {
                        ZkipAddGuestResponse desResponse = ZkipAddGuestResponse.parse(result.getBody());
                        cm.Zkipster_Guest_Id__c = desResponse.data.id;
                        cm.Zkipster_Error_Message__c = '';
                    }
                    else {
                        cm.Zkipster_Error_Message__c = result.getBody();
                    }
                }
                cmListToUpdate.add(cm);
            }
        }

        if (!cmListToUpdate.isEmpty()) {
            update cmListToUpdate;
        }
    }

    /**
     * @param Database.BatchableContext bc
     * @description The standard batch finish method
     * @return void
     */
    global void finish(Database.BatchableContext bc){
        // code here
    }
}