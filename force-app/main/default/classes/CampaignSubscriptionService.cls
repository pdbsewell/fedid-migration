/**
 * @author Nick Guia
 * @date 10-08-2020
 * @group Consent Management
 * @description Service class for subscribing Contacts into Subscription List Campaigns
 **/
public with sharing class CampaignSubscriptionService implements IPlatformEventInvocable {

    @TestVisible
    private Set<Id> campaignIds;
    @TestVisible
    private Set<Id> contactIds;
    @TestVisible
    private Boolean isAsync = false;
    @TestVisible
    private Boolean isEmail = false;
    @TestVisible
    private Boolean isSMS = false;
    @TestVisible
    private String subscriptionSource; //simple use case - same subscription source for all campaign members
    @TestVisible
    private Map<Id, String> campaignSourceByContactId; //if different sources for each campaign member
    @TestVisible
    private Map<String, CampaignMember> existingMembers = new Map<String, CampaignMember>();
    @TestVisible
    private List<CampaignMember> memberInsertList = new List<CampaignMember>();
    @TestVisible
    private List<CampaignMember> memberUpdateList = new List<CampaignMember>();

    /**
     * @description default - subscribes Contact to all Subscription List
     *  Campaigns indicated in the parameter
     * @param campIds : Set of Campaign Subscription List to override the default
     */
    public CampaignSubscriptionService(Set<Id> campIds) {
        this.campaignIds = campIds;
    }

    /**
     * @description default - subscribes Contact to all Subscription List
     *  Campaigns indicated in Custom Setting
     */
    public CampaignSubscriptionService() {
        //default - susbscribe to all
        this.campaignIds = CommonUtilities.MARKETING_SUB_LISTS;
    }

    /**
     * @description subscribe to Emails only
     */
    public void subscribeToEmail() {
        this.isEmail = true;
    }

    /**
     * @description subscribe to SMS only
     */
    public void subscribeToSMS() {
        this.isSMS = true;
    }

    /**
     * @description for creating campaign members with their subscription source.
     * @param conIds : contacts to be added as campaign members
     * @param source : could either be a campaign ID or a string literal
     */
    public void setMembers(Set<Id> conIds, String source) {
        this.contactIds = conIds;
        this.subscriptionSource = source;
    }

    /**
     * @description for setting a different campaign subscription source
     * for each contact ID
     * @param conWithSource : map of contact ID (key) and campaign source (value). 
     *  The source could be an ID or a string literal
     */
    public void setMembersWithSource(Map<Id, String> conWithSource) {
        if(conWithSource != null) {
            this.campaignSourceByContactId = conWithSource;
            this.contactIds = conWithSource.keySet();
        }
    }

    /**
     * @description sets process as asynchronous via Platform Event
     */
    public void runAsync() {
        this.isAsync = true;
    }

    /**
     * @description run subscribe to campaign logic. If set to async,
     *  dispatches an Async Process platform Event. Otherwise, run
     *  synchronously
     */
    public void execute() {
        try {
            if(this.campaignIds != null && this.contactIds != null) {
                //query campaigns to identify channel type
                Map<Id, Campaign> campMap = new Map<Id, Campaign>([
                    SELECT Id, Channel_Type__c 
                    FROM Campaign 
                    WHERE Id IN :this.campaignIds
                ]);

                //query if campaign member already exists
                generateExistingMembersMap();
                
                for(Id iConId : this.contactIds) {
                    for(Id iCampId : this.campaignIds) {
                        createSubMember(campMap.get(iCampId), iConId);
                    }
                }
            }

            if(!this.memberInsertList.isEmpty() || !this.memberUpdateList.isEmpty()) {
                if(this.isAsync) {
                    dispatchAsync();
                } else {
                    commitRecords();
                }
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            throw new CampaignSubscriptionServiceException('Unable to execute CampaignSubscriptionService : ' + e.getMessage());
        }
    }

    /**
     * @description handler method from async process. Upserts Campaign Members
     *  from the payload
     * @param payload : payload from async process
     */
    public void execute(List<AsyncProcessPayload> payload) {
        //extract payload
        try {
            for(AsyncProcessPayload ap : payload) {
                String memberInsertListJson = (String) ap.get('memberInsertList');
                String memberUpdateListJson = (String) ap.get('memberUpdateList');
                this.memberInsertList = (List<CampaignMember>) JSON.deserialize(memberInsertListJson, List<CampaignMember>.class);
                this.memberUpdateList = (List<CampaignMember>) JSON.deserialize(memberUpdateListJson, List<CampaignMember>.class);
            }
            commitRecords();
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            throw new CampaignSubscriptionServiceException('Unable to execute CampaignSubscriptionService : ' + e.getMessage());
        }
    }

    /**
     * @description creates an async process payload and dispatches the event
     * @param campMemList : pre-built (on memory) campaign member records
     */
    @TestVisible
    private void dispatchAsync() {
        //build payload
        AsyncProcessPayload payload = new AsyncProcessPayload();
        payload.put('memberInsertList', JSON.serialize(this.memberInsertList));
        payload.put('memberUpdateList', JSON.serialize(this.memberUpdateList));

        //dispatch event
        Async_Process__e ap = new Async_Process__e(
            Process_Name__c = 'CampaignSubscriptionService',
            Parameter__c = payload.serialize()
        );
        EventBus.publish(ap);
    }

    /**
     * @description insert new records, and update existing ones 
     *  (re-activate those that unsubscribed before)
     */
    private void commitRecords() {
        if(!this.memberInsertList.isEmpty()) {
            insert this.memberInsertList;
        }

        if(!this.memberUpdateList.isEmpty()) {
            update this.memberUpdateList;
        }
    }

    /**
     * create a subscription member for the campaign
     * @param camp : Parent Campaign record
     * @param conId : Contact ID
     */
    @TestVisible
    private void createSubMember(Campaign camp, Id conId) {
        //check first if campaign member already exists
        CampaignMember cm;
        Boolean isNew = false;
        String key = generateCMKey(conId, camp.Id);
        cm = this.existingMembers.get(key);

        //if it doesn't exist, create a new instance
        if(cm == null) {
            cm = new CampaignMember(
                CampaignId = camp.Id,
                ContactId = conId,
                Active__c = true
            );
            isNew = true;
        }

        String source = getSource(conId);

        //if not explicitly set, default is subscribe to all
        if(!this.isEmail && !this.isSMS) {
            cm = CampaignMemberServices.subscribeToEmail(camp, cm, source);
            cm = CampaignMemberServices.subscribeToSMS(camp, cm, source);
        } else {
            if(this.isEmail) {
                cm = CampaignMemberServices.subscribeToEmail(camp, cm, source);
            }
            if(this.isSMS) {
                cm = CampaignMemberServices.subscribeToSMS(camp, cm, source);
            }
        }

        //add to list of insert / update
        if(isNew) {
            this.memberInsertList.add(cm);
        } else {
            this.memberUpdateList.add(cm);
        }
    }

    /**
     * @description creates a custom mapping of campaign member
     *  based on unique key generated
     */
    @TestVisible
    private void generateExistingMembersMap() {
        for(CampaignMember iCm : getExistingMembers()) {
            String key = generateCMKey(iCm.ContactId, iCm.CampaignId);
            this.existingMembers.put(key, iCm);
        }
    }

    /**
     * @description identifies the campaign subscription source
     */
    private String getSource(Id contactId) {
        String source;
        if(this.campaignSourceByContactId != null && !this.campaignSourceByContactId.isEmpty()) {
            source = campaignSourceByContactId.get(contactId);
        } else {
            source = this.subscriptionSource;
        }
        return source;
    }

    /**
     * @description query all existing campaign members
     */
    private List<CampaignMember> getExistingMembers() {
        return [SELECT Id, ContactId, CampaignId, Active__c, Email_Subscription_Source__c, 
                Email_Subscription_Source_Campaign__c, ChannelEmail__c, Email_Subscribed_Date__c, 
                SMS_Subscription_Source__c, SMS_Subscription_Source_Campaign__c, ChannelSMS__c, 
                SMS_Subscribed_Date__c
                FROM CampaignMember
                WHERE ContactId IN :this.contactIds
                AND CampaignId IN :this.campaignIds];
    }

    /**
     * @description generate a unique campaign member identifier
     *  "contactId-campaignId"
     */
    private String generateCMKey(Id contactId, Id campaignId) {
        return contactId + '-' + campaignId;
    }

    public class CampaignSubscriptionServiceException extends Exception { }
}