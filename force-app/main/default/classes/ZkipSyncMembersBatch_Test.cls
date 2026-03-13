/**
 * @author J Mapanao
 * @description Handles all test scenarios for ZkipSyncMembersBatch
 */
@isTest(isParallel=true)
private class ZkipSyncMembersBatch_Test
{
    @isTest static void Test_AddMembersToZkipster_Scenario1()
    {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];

        Test.startTest();
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ZkipMockHttpResponse(true, ZkipConstants.METHOD_POST, ZkipMockHttpResponse.addGuestResponse));
        Database.executeBatch(new ZkipSyncMembersBatch(camp.Id));
        Test.stopTest();
      
        for (CampaignMember campaignMemberRec : [SELECT Zkipster_Guest_Id__c FROM CampaignMember]) {
            System.assertEquals(false, String.isNotBlank(campaignMemberRec.Zkipster_Guest_Id__c));
        }
    }

    @isTest static void Test_AddMembersToZkipster_Scenario2()
    {
        //Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
         Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Test.startTest();
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ZkipMockHttpResponse(false, ZkipConstants.METHOD_POST, ZkipMockHttpResponse.addGuestResponse));

        Database.executeBatch(new ZkipSyncMembersBatch(camp.Id));
        Test.stopTest();

        for (CampaignMember campaignMemberRec : [SELECT Zkipster_Guest_Id__c FROM CampaignMember]) {
            System.assertEquals(true, String.isBlank(campaignMemberRec.Zkipster_Guest_Id__c));
        }
    }

    @TestSetup
    static void setup() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name='ascend Admin User'];

        User u2 = new User( Alias = 'newUser', 
                            Email='newuser@testorg.com',
                            EmailEncodingKey='UTF-8', 
                            LastName='Testing', 
                            LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', 
                            ProfileId = p.Id,
                            TimeZoneSidKey='America/Los_Angeles', 
                            UserName='newuser@testorg.com123');

        insert u2;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ascend_Event_Admin'];
    
        insert new PermissionSetAssignment(AssigneeId = u2.id, PermissionSetId = ps.Id);

        System.runAs(u2) {        

            Id eventRecTypeId = Campaign.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('ERDA_Zkipster_Event').getRecordTypeId();
            Id guestListRecTypeId = Campaign.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('ERDA_Guest_List').getRecordTypeId();
    
            // Create Event
            Campaign camp = new Campaign();
            camp.Name = 'Test Campaign v1.0';
            camp.Type = 'Corporate';
            camp.Event_Start_DateTime__c = Datetime.now().addHours(1);
            camp.Event_End_DateTime__c = Datetime.now().addHours(2);
            camp.Event_Street__c = 'Bourke Street';
            camp.Event_City__c = 'Melbourne';
            camp.Event_State__c = 'VIC';
            camp.Event_Zip__c = '3000';
            camp.Event_Country__c = 'Australia';
            camp.RecordTypeId = eventRecTypeId;
            insert camp;
    
            // Create guest list
            List<Campaign> guestList = new List<Campaign>();
            for(Integer i = 1 ; i <= 10 ; i++) {
                guestList.add(new Campaign(Name='GuestList'+i,Parent_ERDA_Event__c=camp.Id,RecordTypeId=guestListRecTypeId));
            }
            insert guestList;
    
            // Create account
            Account accRec = new Account();
            accRec.Name = 'Test Account Name';
            insert accRec;
    
            // Create contact
            List<Contact> contactList = new List<Contact>();
            for (Integer i = 1 ; i <= 10 ; i++) {
                contactList.add(new Contact(FirstName='FirstName'+i,LastName='LastName'+i,AccountId=accRec.Id));
            }
            insert contactList;
            
            // Create Campaign Members
            List<CampaignMember> campaignMemberList = new List<CampaignMember>();
            for (Contact contactRec : contactList) {
                campaignMemberList.add(new CampaignMember(ContactId=contactRec.Id,CampaignId=guestList.get(0).Id));
            }
            insert campaignMemberList;
        }
    }
}