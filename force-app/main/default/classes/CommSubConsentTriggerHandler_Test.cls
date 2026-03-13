/**
 * @author       : Ibrahim Rumi
 * @date         : 15-02-2023
 * @group        : Consent Management
 * @description Trigger handler for CommSubscriptionConsent object
 * @revision
 *   15-02-2023  Ibrahim Rumi    - EPBBS-0000 added GenerateUuidIfMissing to Generate UUID if they don't already have it on record creation
**/

@isTest
private class CommSubConsentTriggerHandler_Test {
    
    @testSetup
    static void setup() {
        
        EngagementChannelType ect = new EngagementChannelType();
        ect.Name = 'Email';

        insert ect;

        CommSubscription cs = new CommSubscription();
        cs.Name = 'Test CommSubscription';

        insert cs;

        CommSubscriptionChannelType csct = new CommSubscriptionChannelType();
        csct.CommunicationSubscriptionId = cs.Id;
        csct.EngagementChannelTypeId = ect.Id;
        csct.Name = ect.Name + ' - ' + cs.Name;

        insert csct;
        
        ContactPointEmail cpe = new ContactPointEmail();
        cpe.EmailAddress = 'Test@testmail.com';

        insert cpe;

    }
    
    /*
	 * @author:			Ibrahim Rumi
	 * @description:	Test Generate UUID if they don't already have it on record creation.
	 */
	@isTest
    static void testGenerateUuidIfMissing() {
        //GIVEN

        List<ContactPointEmail> cpeList = new List<ContactPointEmail>();
        List<CommSubscriptionChannelType> csctList = new List<CommSubscriptionChannelType>();


        cpeList = [SELECT id FROM ContactPointEmail LIMIT 1];
        csctList = [SELECT id FROM CommSubscriptionChannelType LIMIT 1];
        
        List<CommSubscriptionConsent> CommSubscriptionConsentList = new List<CommSubscriptionConsent>();
        
        CommSubscriptionConsent csc = new CommSubscriptionConsent();

        //WHEN
        csc.Name = 'test CommSubscriptionConsent';
        csc.ContactPointId = cpeList[0].id;
        csc.EffectiveFromDate = System.today();
        csc.CommSubscriptionChannelTypeId = csctList[0].id;

        CommSubscriptionConsentList.add(csc);
        
        insert CommSubscriptionConsentList;
        
        Test.startTest();
        
        //THEN

        csc = [SELECT Id, UUID__c FROM CommSubscriptionConsent LIMIT 1];
        
        Test.stopTest();
        
        Assert.isNotNull(csc.UUID__c, 'GenerateUuidIfMissing is not working.');
    }
    
}