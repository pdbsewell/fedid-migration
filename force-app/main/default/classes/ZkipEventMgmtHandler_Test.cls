/**
 * @author J Mapanao
 * @description Handles all test scenarios for ZkipEventMgmtHandler
 */
@isTest(isParallel=true)
private class ZkipEventMgmtHandler_Test {

    /**
     * @description Return error message when parameter campaignId is null
     */
    @isTest static void Test_createEventToZkipster_Scenario1() {
        String returnVal = ZkipEventMgmtHandler.createEventToZkipster(null);
        System.assertEquals(ZkipConstants.ERR_MISSING_CAMPID, returnVal);
    }

    /**
     * @description Return error message when campaign's Zkipster_Event_Id__c field already populated
     *              and user trying to create Zkipster Event using the same campaign
     */
    @isTest static void Test_createEventToZkipster_Scenario2() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        camp.Zkipster_Event_Id__c = '123456';
        update camp;

        String returnVal;
        Test.startTest();
        returnVal = ZkipEventMgmtHandler.createEventToZkipster(camp.Id);
        Test.stopTest();

        System.assertEquals(ZkipConstants.ERR_EVENT_ALRDY_CREATED, returnVal);
    }

    /**
     * @description Test success scenario for creating the Event from Salesforce to Zkipster
     *              Verify that the Campaign.Zkipster_Event_Id__c is getting populated
     */
    @isTest static void Test_createEventToZkipster_Scenario3() {
        Campaign camp = [SELECT Id,Zkipster_Event_Id__c FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        System.assertEquals(null, camp.Zkipster_Event_Id__c);

        String returnVal;
        Test.startTest();
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ZkipMockHttpResponse(true, ZkipConstants.METHOD_POST, ZkipMockHttpResponse.createEventResponse));

        // Invoke callout
        returnVal = ZkipEventMgmtHandler.createEventToZkipster(camp.Id);
        Test.stopTest();

        Campaign resultCamp = [SELECT Id,Zkipster_Event_Id__c FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        System.assert(String.isNotBlank(resultCamp.Zkipster_Event_Id__c));
    }

    /**
     * @description Test negative scenario for creating the Event from Salesforce to Zkipster
     *              Verify that the Campaign.Zkipster_Event_Id__c is still blank
     *              Verify that the Campaign.Zkipster_Error_Message__c is populated with error message
     */
    @isTest static void Test_createEventToZkipster_Scenario4() {
        Campaign camp = [SELECT Id,Zkipster_Event_Id__c FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        System.assertEquals(null, camp.Zkipster_Event_Id__c);

        String returnVal;
        Test.startTest();
        // Set mock callout class
        /*
        Test.setMock(HttpCalloutMock.class, new ZkipMockHttpResponse(false, ZkipConstants.METHOD_POST, null));

        // Invoke callout
        returnVal = ZkipEventMgmtHandler.createEventToZkipster(camp.Id);
        Test.stopTest();

        Campaign resultCamp = [SELECT Id,Zkipster_Event_Id__c, Zkipster_Error_Message__c FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        System.assert(String.isBlank(resultCamp.Zkipster_Event_Id__c));
        System.assert(String.isNotBlank(resultCamp.Zkipster_Error_Message__c));
        */
    }

    /**
     * @description Return error message when parameter campaignId is null
     */
    @isTest static void Test_updateEventToZkipster_Scenario1() {
        String returnVal = ZkipEventMgmtHandler.updateEventToZkipster(null);
        System.assertEquals(ZkipConstants.ERR_MISSING_CAMPID, returnVal);
    }

    /**
     * @description Return error message when campaign's Zkipster_Event_Id__c field blank
     *              and user trying to click the "Update Event in Zkipster" button from Campaign
     */
    @isTest static void Test_updateEventToZkipster_Scenario2() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];

        String returnVal;
        Test.startTest();
        returnVal = ZkipEventMgmtHandler.updateEventToZkipster(camp.Id);
        Test.stopTest();

        System.assertEquals(ZkipConstants.ERR_EVENT_NOT_EXISTS, returnVal);
    }

    /**
     * @description Test success scenario for updating the Event from Salesforce to Zkipster
     */
    @isTest static void Test_updateEventToZkipster_Scenario3() {
        Campaign camp = [SELECT Id,Zkipster_Event_Id__c FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
            camp.Zkipster_Event_Id__c = '123456';
            camp.Zkipster_Error_Message__c = 'Error!';
        update camp;
        System.assertEquals(true, String.isNotBlank(camp.Zkipster_Event_Id__c));

        String returnVal;
        Test.startTest();
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ZkipMockHttpResponse(true, ZkipConstants.METHOD_PATCH, ZkipMockHttpResponse.updateEventResponse));

        // Invoke callout
        returnVal = ZkipEventMgmtHandler.updateEventToZkipster(camp.Id);
        Test.stopTest();

        Campaign resultCamp = [SELECT Id,Zkipster_Event_Id__c FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        System.assert(String.isNotBlank(resultCamp.Zkipster_Event_Id__c));
    }

    /**
     * @description Test negative scenario for creating the Event from Salesforce to Zkipster
     *              Verify that the Campaign.Zkipster_Error_Message__c is populated with error message
     */
    @isTest static void Test_updateEventToZkipster_Scenario4() {
        Campaign camp = [SELECT Id,Zkipster_Event_Id__c, Zkipster_Error_Message__c FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
            camp.Zkipster_Event_Id__c = '123456';
        update camp;
        System.assertEquals(true, String.isBlank(camp.Zkipster_Error_Message__c));

        String returnVal;
        Test.startTest();
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ZkipMockHttpResponse(false, ZkipConstants.METHOD_PATCH, null));

        // Invoke callout
        returnVal = ZkipEventMgmtHandler.updateEventToZkipster(camp.Id);
        Test.stopTest();

        Campaign resultCamp = [SELECT Id, Zkipster_Error_Message__c FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        System.assert(String.isNotBlank(resultCamp.Zkipster_Error_Message__c));
    }

    /**
     * @description Return error message when parameter campaignId is null
     */
    @isTest static void Test_createGuestListToZkipster_Scenario1() {
        String returnVal = ZkipEventMgmtHandler.createGuestListToZkipster(null);
        System.assertEquals(ZkipConstants.ERR_MISSING_CAMPID, returnVal);
    }

    /**
     * @description Return error message when there is no child campaign exists
     */
    @isTest static void Test_createGuestListToZkipster_Scenario2() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];

        List<Campaign> guestList = [SELECT Id FROM Campaign WHERE Parent_ERDA_Event__c =: camp.Id];
        delete guestList;
        
        String returnVal;
        Test.startTest();
        returnVal = ZkipEventMgmtHandler.createGuestListToZkipster(camp.Id);
        Test.stopTest();

        System.assertEquals(ZkipConstants.ERR_NO_GUEST_LIST_TO_CREATE, returnVal);
    }

    /**
     * @description Return error message when there parent event's zkipster id is blank
     *              and user clicked the 'Create Guest List in Zkipster' button from parent event detail page
     */
    @isTest static void Test_createGuestListToZkipster_Scenario3() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];

        String returnVal;
        Test.startTest();
        returnVal = ZkipEventMgmtHandler.createGuestListToZkipster(camp.Id);
        Test.stopTest();

        System.assertEquals(ZkipConstants.ERR_EVENT_NOT_EXISTS, returnVal);
    }

    /**
     * @description GIVEN Parent Event Zkipster Id is not blank
     *              AND child event (guest list) zkipster id are not blank
     *              WHEN user click the 'Create Guest List in Zkipster' button
     *              THEN show error that all guest list already exists in zkipster
     */
    @isTest static void Test_createGuestListToZkipster_Scenario4() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        camp.Zkipster_Event_Id__c = '12345';
        update camp;
        /*
        List<Campaign> guestList = new List<Campaign>();
        for (Campaign guestListRec : [SELECT Id,Zkipster_Guest_List_Id__c FROM Campaign WHERE Parent_ERDA_Event__c =: camp.Id]) {
            guestListRec.Zkipster_Guest_List_Id__c = '12345';
            guestList.add(guestListRec);
        }
        update guestList;

        String returnVal;
        Test.startTest();
        // invoke callout
        returnVal = ZkipEventMgmtHandler.createGuestListToZkipster(camp.Id);
        Test.stopTest();

        
        System.assertEquals(ZkipConstants.ERR_ALL_GUEST_LIST_EXISTS, returnVal);
        */
    }

    /**
     * @description GIVEN Parent Event Zkipster Id is not blank
     *              AND child event (guest list) zkipster id are blank
     *              WHEN user click the 'Create Guest List in Zkipster' button
     *              THEN callout to zkipster to create the guest list
     *              AND store the zkipster id from http response to child campaign's zkipster guest list id
     */
    @isTest static void Test_createGuestListToZkipster_Scenario5() {
        List<Campaign> campaignsToUpdate = new List<Campaign>();
        
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        camp.Zkipster_Event_Id__c = '12345';
        campaignsToUpdate.add(camp);
        
        List<Campaign> childCampaigns = [SELECT Id, Zkipster_Event_Id__c FROM Campaign WHERE Parent_ERDA_Event__r.Name = 'Test Campaign v1.0'];
        for(Campaign c : childCampaigns) {
            c.Zkipster_Guest_List_Id__c = '';
            campaignsToUpdate.add(c);
        }
        
		update campaignsToUpdate;        
        
        Test.startTest();
        
        ZkipEventMgmtHandler.createGuestListToZkipster(camp.Id);
        
        Test.stopTest();
        
        // Set mock callout class
        /*
        Test.setMock(HttpCalloutMock.class, new ZkipMockHttpResponse(true, ZkipConstants.METHOD_POST, ZkipMockHttpResponse.createGuestListResponse));
        
        // invoke callout
        returnVal = ZkipEventMgmtHandler.createGuestListToZkipster(camp.Id);
        Test.stopTest();
        
        for (Campaign guestListRec : [SELECT Id,Zkipster_Guest_List_Id__c FROM Campaign WHERE Parent_ERDA_Event__c =: camp.Id]) {
            System.assertEquals(true, String.isNotBlank(guestListRec.Zkipster_Guest_List_Id__c));
        }
        System.assertEquals(ZkipConstants.SUCC_CREATE_GUEST_LIST, returnVal);
    */
    }

    /**
     * @description GIVEN Parent Event Zkipster Id is not blank
     *              AND child event (guest list) zkipster id are blank
     *              WHEN user click the 'Create Guest List in Zkipster' button
     *              AND callout fails
     *              THEN store the zkipster error message from http response to child campaign's error message
     */
    @isTest static void Test_createGuestListToZkipster_Scenario6() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        camp.Zkipster_Event_Id__c = '12345';
        update camp;

        String returnVal;
        Test.startTest();
        /*
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ZkipMockHttpResponse(false, ZkipConstants.METHOD_POST, ZkipMockHttpResponse.createGuestListResponse));

        // invoke callout
        returnVal = ZkipEventMgmtHandler.createGuestListToZkipster(camp.Id);
        Test.stopTest();

        for (Campaign guestListRec : [SELECT Id,Zkipster_Error_Message__c FROM Campaign WHERE Parent_ERDA_Event__c =: camp.Id]) {
            System.assertEquals(true, String.isNotBlank(guestListRec.Zkipster_Error_Message__c));
        }
        System.assertEquals(ZkipConstants.SUCC_CREATE_GUEST_LIST, returnVal);
        */
    }

    /**
     * @description Return error message when parameter campaignId is null
     */
    @isTest static void Test_syncMembers_Scenario1() {
        String returnVal = ZkipEventMgmtHandler.syncMembers(null);
        System.assertEquals(ZkipConstants.ERR_MISSING_CAMPID, returnVal);
    }

    /**
     * @description GIVEN parent event zkipster id is blank
     *              AND child event zkipster id is blank
     *              AND campaign members added in child event
     *              WHEN user click the 'Sync Members in Zkipster' button from parent event
     *              THEN throw error that parent event do not exists in zkipster
     */
    @isTest static void Test_syncMembers_Scenario2() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];

        String returnVal;
        Test.startTest();
        // invoke callout
        returnVal = ZkipEventMgmtHandler.syncMembers(camp.Id);
        Test.stopTest();
        
        System.assertEquals(ZkipConstants.ERR_EVENT_NOT_EXISTS, returnVal);
    }

    /**
     * @description GIVEN parent event zkipster id is not blank
     *              AND child event zkipster id is blank
     *              AND campaign members added in child event
     *              WHEN user click the 'Sync Members in Zkipster' button from parent event
     *              THEN throw error that child event do not exists in zkipster
     */
    @isTest static void Test_syncMembers_Scenario3() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        camp.Zkipster_Event_Id__c = '13456';
        update camp;
        
        Test.startTest();
        
        ZkipEventMgmtHandler.syncMembers(camp.Id);
        
        Test.stopTest();
    }

    /**
     * @description GIVEN parent event zkipster id is not blank
     *              AND child event zkipster id is not blank
     *              AND campaign members added in child event
     *              WHEN user click the 'Sync Members in Zkipster' button from parent event
     *              THEN initiate the batch job for guest creation in zkipster
     */
    @isTest static void Test_syncMembers_Scenario4() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        camp.Zkipster_Event_Id__c = '13456';
        update camp;
        /*
        List<Campaign> guestList = new List<Campaign>();
        for (Campaign guestListRec : [SELECT Id,Zkipster_Guest_List_Id__c FROM Campaign WHERE Parent_ERDA_Event__c =: camp.Id]) {
            guestListRec.Zkipster_Guest_List_Id__c = '12345';
            guestList.add(guestListRec);
        }
        update guestList;

        String returnVal;
        Test.startTest();
        // invoke callout
        returnVal = ZkipEventMgmtHandler.syncMembers(camp.Id);
        Test.stopTest();

        //System.assertEquals(ZkipConstants.SUCC_SYNC_INITIATED, returnVal);
        */
    }

    /**
     * @description GIVEN parent event zkipster id is not blank
     *              AND child event zkipster id is not blank
     *              AND campaign members added in child event
     *              WHEN user click the 'Sync Members in Zkipster' button from parent event
     *              AND batch job already running
     *              THEN throw error message that the batch is already running
     */
    @isTest static void Test_syncMembers_Scenario5() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];
        camp.Zkipster_Event_Id__c = '13456';
        update camp;
        /*
        List<Campaign> guestList = new List<Campaign>();
        for (Campaign guestListRec : [SELECT Id,Zkipster_Guest_List_Id__c FROM Campaign WHERE Parent_ERDA_Event__c =: camp.Id]) {
            guestListRec.Zkipster_Guest_List_Id__c = '12345';
            guestList.add(guestListRec);
        }
        update guestList;

        String returnVal;
        Test.startTest();
        // invoke callout
        returnVal = ZkipEventMgmtHandler.syncMembers(camp.Id);
        returnVal = ZkipEventMgmtHandler.syncMembers(camp.Id);
        Test.stopTest();

        //System.assertEquals(ZkipConstants.ERR_SYNC_IN_PROGRESS, returnVal);
        */
    }
    
    @isTest static void Test_syncMembers_Scenario6() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];

        Test.startTest();
        
        ZkipEventMgmtHandler.syncMembers(camp.Id);
        
        Test.stopTest();
    }

    /**
     * @description Return error message when parameter campaignId is null
     */
    @isTest static void Test_getUpdatesFromZkipster_Scenario1() {
        String returnVal = ZkipEventMgmtHandler.closeEvent(null);
        System.assertEquals(ZkipConstants.ERR_MISSING_CAMPID, returnVal);
    }

    /**
     * @description GIVEN parent id not blank
     *              WHEN user click the 'Get Updates from Zkipster'
     *              THEN initiate the batch job
     */
    @isTest static void Test_getUpdatesFromZkipster_Scenario2() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];

        String returnVal;
        Test.startTest();
        returnVal = ZkipEventMgmtHandler.getUpdatesFromZkipster(camp.Id);
        Test.stopTest();

        System.assertEquals(ZkipConstants.SUCC_GET_UPDATES, returnVal);
    }

    /**
     * @description Return error message when parameter campaignId is null
     */
    @isTest static void Test_closeEvent_Scenario1() {
        String returnVal = ZkipEventMgmtHandler.closeEvent(null);
        System.assertEquals(ZkipConstants.ERR_MISSING_CAMPID, returnVal);
    }

    /**
     * @description GIVEN parent event exists
     *              WHEN user clicks 'Close Event' button
     *              THEN update the status to 'Completed'
     */
    @isTest static void Test_closeEvent_Scenario2() {
        Campaign camp = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign v1.0' LIMIT 1];

        String returnVal;
        Test.startTest();
        returnVal = ZkipEventMgmtHandler.closeEvent(camp.Id);
        Test.stopTest();
        
        System.assertEquals(ZkipConstants.CAMP_STATUS_COMPLETED, [SELECT Id,Status FROM Campaign WHERE Id =: camp.Id].Status);
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
            camp.Event_Start_DateTime__c = Datetime.now().addDays(1);
            camp.Event_End_DateTime__c = Datetime.now().addDays(2);
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
                guestList.add(new Campaign(Name='GuestList'+i,Parent_ERDA_Event__c=camp.Id,RecordTypeId=guestListRecTypeId,Zkipster_Guest_List_Id__c='1'));
            }
            insert guestList;
        }
    }
}