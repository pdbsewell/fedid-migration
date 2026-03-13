/**
 * @author Nick Guia
 * @date 13-08-2020
 * @group Consent Management
 * @description Test class for CampaignSubscriptionService.
 **/
@IsTest(isParallel=true)
private class CampaignSubscriptionService_Test {

    @TestSetup
	static void setup(){
        //create test records
        Campaign mie = new Campaign();
        mie.Name = 'The Monash Info and Events for Prospective Students';
        mie.RecordTypeId = CampaignServices.SUB_LIST_RECTYPE;
        mie.Channel_Type__c = 'SMS;Email';
        mie.IsActive = true; 

        Campaign mr = new Campaign();
        mr.Name = 'The Market research participation';
        mr.RecordTypeId = CampaignServices.SUB_LIST_RECTYPE;
        mr.Channel_Type__c = 'SMS;Email';
        mr.IsActive = true;

        List<Campaign> campList = new List<Campaign>();
        campList.add(mie);
        campList.add(mr);
        insert campList;

        Marketing_Subscription_List__c setting = new Marketing_Subscription_List__c();
        setting.MIE__c = mie.Id;
        setting.MR__c = mr.Id;
        insert setting;

        //create contacts
        List<Contact> cons = TestHelper.createProspectiveStudentContact(10);
        insert cons;
    }

    /**
     * @description test creation of subscription members
     *  for email communications
     */
    @IsTest
    static void subscribeToEmailOnly() {

        //given 
        CampaignSubscriptionService service = new CampaignSubscriptionService();
        Set<Id> conIds = (new Map<Id, Contact>([SELECT Id FROM Contact])).keySet();
        
        Test.startTest();

        //when
        service.subscribeToEmail();
        service.setMembers(conIds, 'Web');
        service.execute();

        Test.stopTest();

        //then
        for(CampaignMember cm : [SELECT Id, ChannelEmail__c 
                                FROM CampaignMember 
                                WHERE Campaign.RecordTypeId = :CampaignServices.SUB_LIST_RECTYPE]) 
        {
            System.assert(cm.ChannelEmail__c, 'Unable to subscribe campaign member to Emails');
        }
    }

    /**
     * @description test creation of subscription members
     *  for SMS communications
     */
    @IsTest
    static void subscribeToSMSOnly() {
        
        //given
        CampaignSubscriptionService service = new CampaignSubscriptionService();
        Set<Id> conIds = (new Map<Id, Contact>([SELECT Id FROM Contact])).keySet();
        
        Test.startTest();

        //when
        service.subscribeToSMS();
        service.setMembers(conIds, 'Web');
        service.execute();

        Test.stopTest();

        //then
        for(CampaignMember cm : [SELECT Id, ChannelSMS__c 
                                FROM CampaignMember 
                                WHERE Campaign.RecordTypeId = :CampaignServices.SUB_LIST_RECTYPE]) 
        {
            System.assert(cm.ChannelSMS__c, 'Unable to subscribe campaign member to SMS');
        }
    }

    /**
     * @description test creation of subscription members with
     *  similar subscription source for all
     */
    @IsTest
    static void setMembersTest() {

        //given

        CampaignSubscriptionService service = new CampaignSubscriptionService();
        Set<Id> conIds = (new Map<Id, Contact>([SELECT Id FROM Contact])).keySet();
        String subscriptionSource = 'Web';
        
        Test.startTest();

        //when

        service.setMembers(conIds, subscriptionSource);
        service.execute();

        Test.stopTest();

        //then

        //subscription source should be the same for all campaign members
        for(CampaignMember cm : [SELECT Id, SMS_Subscription_Source__c, Email_Subscription_Source__c
                                FROM CampaignMember 
                                WHERE Campaign.RecordTypeId = :CampaignServices.SUB_LIST_RECTYPE]) 
        {
            System.assertEquals(
                subscriptionSource, 
                cm.SMS_Subscription_Source__c, 
                'Unexpected subscription source for campaign member : ' + cm.SMS_Subscription_Source__c);
            System.assertEquals(
                subscriptionSource, 
                cm.Email_Subscription_Source__c, 
                'Unexpected subscription source for campaign member : ' + cm.Email_Subscription_Source__c);
        }
    }

    /**
     * @description test creation of subscription members with
     *  different subscription sources
     */
    @IsTest
    static void setMembersWithSourceTest() {
        
        //given
        
        CampaignSubscriptionService service = new CampaignSubscriptionService();

        //create a map of contact ID and it's corresponding subscription source
        Map<Id, String> conWithSource = new Map<Id, String>();
        List<String> subSource = new List<String>{'Source1', 'Source2', 'Source3'};
        Integer i = 0;
        for(Contact iCon : [SELECT Id FROM Contact]) {
            conWithSource.put(iCon.Id, subSource[i]);
            if(i == 2) {
                //reset
                i = 0;
            } else {
                i++;
            }
        }
        
        Test.startTest();

        //when

        service.setMembersWithSource(conWithSource);
        service.execute();

        Test.stopTest();

        //then

        //subscription source should be the same as how it was indicated in the map
        for(CampaignMember cm : [SELECT Id, ContactId, SMS_Subscription_Source__c, Email_Subscription_Source__c
                                FROM CampaignMember 
                                WHERE Campaign.RecordTypeId = :CampaignServices.SUB_LIST_RECTYPE]) 
        {
            String subscriptionSource = conWithSource.get(cm.ContactId);
            System.assertEquals(
                subscriptionSource, 
                cm.SMS_Subscription_Source__c, 
                'Unexpected subscription source for campaign member : ' + cm.SMS_Subscription_Source__c);
            System.assertEquals(
                subscriptionSource, 
                cm.Email_Subscription_Source__c, 
                'Unexpected subscription source for campaign member : ' + cm.Email_Subscription_Source__c);
        }
    }

    /**
     * @description test asynchronous creation of subscription members
     */
    @IsTest
    static void runAsyncTest() {
        
        //given
        
        Set<Id> conIds = (new Map<Id, Contact>([SELECT Id FROM Contact])).keySet();
        
        Test.startTest();

        //when

        CampaignSubscriptionService service = new CampaignSubscriptionService();
        service.setMembers(conIds, 'Web');
        service.runAsync();

        //mock async process payload, to work around issue on test class:
        //insufficient accress rights on cross-reference ID

        Map<Id, Campaign> campMap = new Map<Id, Campaign>([
            SELECT Id, Channel_Type__c 
            FROM Campaign 
            WHERE Id IN :service.campaignIds
        ]);
        service.generateExistingMembersMap();
        for(Id iConId : service.contactIds) {
            for(Id iCampId : service.campaignIds) {
                service.createSubMember(campMap.get(iCampId), iConId);
            }
        }
        AsyncProcessPayload payload = new AsyncProcessPayload();
        payload.put('memberInsertList', JSON.serialize(service.memberInsertList));
        payload.put('memberUpdateList', JSON.serialize(service.memberUpdateList));

        service.execute(new List<AsyncProcessPayload>{payload});

        Test.stopTest();

        //then

        List<CampaignMember> cmList = [SELECT Id, ChannelSMS__c 
                                    FROM CampaignMember 
                                    WHERE Campaign.RecordTypeId = :CampaignServices.SUB_LIST_RECTYPE];
        // verify that campaign members were created
        System.assert(!cmList.isEmpty(), 'Unable to create Campaign Members asynchronously');
    }

    /**
     * @description test synchronous creation of subscription members
     */
    @IsTest
    static void executeTest() {
        
        //given
        Set<Id> conIds = (new Map<Id, Contact>([SELECT Id FROM Contact])).keySet();
        
        Test.startTest();

        //when

        CampaignSubscriptionService service = new CampaignSubscriptionService();
        service.setMembers(conIds, 'Web');
        service.execute();

        Test.stopTest();

        //then

        List<CampaignMember> cmList = [SELECT Id 
                                    FROM CampaignMember 
                                    WHERE Campaign.RecordTypeId = :CampaignServices.SUB_LIST_RECTYPE];
        // verify that campaign members were created
        System.assert(!cmList.isEmpty(), 'Unable to create Campaign Members synchronously');
    }

    /**
     * @description for coverage only. Creation of Campaign Members via
     * Platform Events encounters an issue:
     *  insufficient accress rights on cross-reference ID
     */
    @IsTest
    static void dispatchAsyncTest() {
        
        //given
        Set<Id> conIds = (new Map<Id, Contact>([SELECT Id FROM Contact])).keySet();
        
        Test.startTest();

        //when

        CampaignSubscriptionService service = new CampaignSubscriptionService();
        service.setMembers(conIds, 'Web');
        service.runAsync();
        service.execute();

        Test.stopTest();
    }
}