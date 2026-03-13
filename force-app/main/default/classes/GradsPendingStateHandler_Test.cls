/**
 * @description Test class for GradsPaymentsService.
 * @group       Grads
 * @revision    2025-01-25 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=true)
private class GradsPendingStateHandler_Test {

    final static String awardIntegrationId = 'TEST-AWARD-001';

    @TestSetup
    static void setupTestData() {
        Contact cont = new Contact(
            LastName = 'TestStudent',
            Person_ID_unique__c = '123456'
        );
        insert cont;

        final Integer CALENDAR_CODE = 808;
        Calendar__c cal = new Calendar__c(
            Category__c = 'Graduation',
            Description__c = '2024 (May) Ceremony',
            Type_Description__c = 'SEM 1',
            Type__c = 'GRAD1',
            Type_Alt__c = 'CLAYTON',
            Calendar_Code__c = String.valueOf(CALENDAR_CODE),
            Sequence_Number__c = CALENDAR_CODE,
            Start_Date__c = Date.newInstance(2024, 5, 01),
            End_Date__c = Date.newInstance(2024, 10, 31)
        );
        insert cal;

        // App with valid pending state
        Graduation_Application__c appWithState = new Graduation_Application__c(
            Payment_Pending_State__c = createTestJsonRequests(awardIntegrationId),
            Payment_Pending_State_Expiry__c = Datetime.now().addDays(1),
            Student__c = cont.Id,
            Graduation_Calendar__c = cal.Id,
            Status__c = 'Draft'
        );

        // App with expired pending state
        Graduation_Application__c expiredApp = new Graduation_Application__c(
            Payment_Pending_State__c = createTestJsonRequests(awardIntegrationId),
            Payment_Pending_State_Expiry__c = Datetime.now().addDays(-1),
            Student__c = cont.Id,
            Graduation_Calendar__c = cal.Id,
            Status__c = 'Draft'
        );

        // App with no pending state
        Graduation_Application__c noStateApp = new Graduation_Application__c(
            Payment_Pending_State__c = null,
            Payment_Pending_State_Expiry__c = null,
            Student__c = cont.Id,
            Graduation_Calendar__c = cal.Id,
            Status__c = 'Draft'
        );

        insert new Graduation_Application__c[]{appWithState, expiredApp, noStateApp};

        // Award (can be used to test against any app)
        Graduation_Award__c award = new Graduation_Award__c(
            Graduation_Application__c = appWithState.Id,
            Integration_Id__c = awardIntegrationId,
            Award_Code_1__c = 'AWA808',
            Award_Title_1__c = 'Master of Arts',
            Award_Type__c = 'Alternative Exit',
            Course_Code__c = '0017',
            Award_Course_Code__c = '0017',
            Award_Course_Version__c = 1,
            Award_Course_Title__c = 'Doctor of Philosophy',
            Course_Version_Number__c = 6,
            Course_Title__c = 'Doctor of Philosophy',
            Bypass_Writeback_Trigger__c = true
        );
        insert award;
    }

    /**
     * Test the getAwardImpact method with various scenarios
     * N.B. submissionDate not covered - It's not a mission critical feature and would require mocking the History object
     */
    @IsTest
    static void testGetAwardImpact() {
        // GIVEN - Different graduation applications and an award
        List<Graduation_Application__c> apps = [
            SELECT Id, Payment_Pending_State__c, Payment_Pending_State_Expiry__c
            FROM Graduation_Application__c
        ];

        Graduation_Application__c appWithState;
        Graduation_Application__c expiredApp;
        Graduation_Application__c noStateApp;

        for(Graduation_Application__c app : apps) {
            if(app.Payment_Pending_State__c != null && app.Payment_Pending_State_Expiry__c > Datetime.now()) {
                appWithState = app;
            } else if(app.Payment_Pending_State__c != null && app.Payment_Pending_State_Expiry__c < Datetime.now()) {
                expiredApp = app;
            } else if(app.Payment_Pending_State__c == null) {
                noStateApp = app;
            }
        }

        Graduation_Award__c award = [SELECT Id, Integration_Id__c FROM Graduation_Award__c LIMIT 1];

        // WHEN - The getAwardImpact method is called with the award integration ID and application ID
        GradsPendingStateHandler.PendingAwardImpact impact1 =
            GradsPendingStateHandler.getAwardImpact(award.Integration_Id__c, appWithState);

        // THEN - The method should return a PendingAwardImpact object with hasPendingState=true
        Assert.areEqual(true, impact1.hasPendingState, 'Award should have a pending state');
        Assert.areNotEqual(null, impact1.submitterEmail, 'Submitter email should not be null');

        // WHEN - The getAwardImpact method is called with a non-matching award integration ID
        GradsPendingStateHandler.PendingAwardImpact impact2 =
            GradsPendingStateHandler.getAwardImpact('NON-EXISTENT-AWARD', appWithState);

        // THEN - The method should return a PendingAwardImpact object with hasPendingState=false
        Assert.areEqual(false, impact2.hasPendingState, 'Award should not have a pending state');
        Assert.areEqual(null, impact2.submitterEmail, 'Submitter email should be null');

        // WHEN - The getAwardImpact method is called with an expired pending state
        GradsPendingStateHandler.PendingAwardImpact impact3 =
            GradsPendingStateHandler.getAwardImpact(award.Integration_Id__c, expiredApp);

        // THEN - The method should return a PendingAwardImpact object with hasPendingState=false
        Assert.areEqual(false, impact3.hasPendingState, 'Award should not have a pending state due to expiry');
        Assert.areEqual(null, impact3.submitterEmail, 'Submitter email should be null');

        // WHEN - The getAwardImpact method is called with no pending state
        GradsPendingStateHandler.PendingAwardImpact impact4 =
            GradsPendingStateHandler.getAwardImpact(award.Integration_Id__c, noStateApp);

        // THEN - The method should return a PendingAwardImpact object with hasPendingState=false
        Assert.areEqual(false, impact4.hasPendingState, 'Award should not have a pending state');
        Assert.areEqual(null, impact4.submitterEmail, 'Submitter email should be null');
    }

    /**
     * Test the processRequests method with various JSON inputs
     */
    @IsTest
    static void testProcessRequests() {
        // GIVEN - Various Pending state JSON strings
        Graduation_Award__c award = [SELECT Integration_Id__c FROM Graduation_Award__c LIMIT 1];
        String validJson = createTestJsonRequests(awardIntegrationId);
        String jsonForExistingRecord = createTestJsonRequestsForExistingRecord(award.Integration_Id__c);
        String deleteJson = createDeleteJsonRequest(award.Integration_Id__c);

        // WHEN - The processRequests method is called with a valid JSON string
        GradsPendingStateHandler.PendingStateResponse response1 = GradsPendingStateHandler.parsePendingState(validJson);

        // THEN - The method should return a PendingStateResponse object with the correct values
        Assert.areEqual('test.user@example.com', response1.LastEditedByEmail, 'Last edited by email should match');
        Assert.areEqual(1, response1.AwardStates.size(), 'Should be one award state');
        GradsPendingStateHandler.StateChange res1s1 = response1.AwardStates[0];
        Assert.areEqual(awardIntegrationId, res1s1.integrationId, 'Integration ID should match');
        Assert.areEqual(false, res1s1.isNewRecord, 'Award should be identified as an existing record');
        Assert.areEqual(2, res1s1.changedFields.size(), 'Unexpected number of changed fields');
        Assert.isTrue(
            res1s1.changedFields.keySet().containsAll(new Set<String>{'Award_Code_1__c', 'Award_Title_1__c'}),
            'Changed fields should match the expected values'
        );

        // WHEN - The processRequests method is called with JSON for an existing record
        GradsPendingStateHandler.PendingStateResponse response2 = GradsPendingStateHandler.parsePendingState(jsonForExistingRecord);

        // THEN - The method should identify that this is an existing record
        Assert.areEqual(1, response2.AwardStates.size(), 'Should be one award state');
        Assert.areEqual(false, response2.AwardStates[0].isNewRecord, 'Award should be identified as an existing record');

        // WHEN - The processRequests method is called with a DELETE request
        GradsPendingStateHandler.PendingStateResponse response3 = GradsPendingStateHandler.parsePendingState(deleteJson);

        // THEN - The method should identify that this is a delete request
        Assert.areEqual(1, response3.AwardStates.size(), 'Should be one award state');
        Assert.areEqual(true, response3.AwardStates[0].isDelete, 'Request should be identified as a delete request');
    }

    /**
     * Create test JSON requests for a new award
     */
    private static String createTestJsonRequests(String integrationId) {
        List<Map<String, Object>> requests = new List<Map<String, Object>>();

        // First request - Award update
        Map<String, Object> awardRequest = new Map<String, Object>{
            'method' => 'PATCH',
            'url' => '/services/data/v56.0/sobjects/Graduation_Award__c/Integration_Id__c/' + integrationId,
            'referenceId' => 'refAward1',
            'body' => new Map<String, Object>{
                'Award_Code_1__c' => 'NEW-CODE',
                'Award_Title_1__c' => 'Updated Award Title'
            }
        };

        // Second request - Application update
        Map<String, Object> appRequest = new Map<String, Object>{
            'method' => 'PATCH',
            'url' => '/services/data/v56.0/sobjects/Graduation_Application__c/a0A1h000003XYZ',
            'referenceId' => 'refApp1',
            'body' => new Map<String, Object>{
                'Last_Edited_By_Email__c' => 'test.user@example.com'
            }
        };

        requests.add(awardRequest);
        requests.add(appRequest);

        return JSON.serialize(requests);
    }

    /**
     * Create test JSON requests for an existing award
     */
    private static String createTestJsonRequestsForExistingRecord(String integrationId) {
        List<Map<String, Object>> requests = new List<Map<String, Object>>();

        // First request - Award update
        Map<String, Object> awardRequest = new Map<String, Object>{
            'method' => 'PATCH',
            'url' => '/services/data/v56.0/sobjects/Graduation_Award__c/Integration_Id__c/' + integrationId,
            'referenceId' => 'refAward1',
            'body' => new Map<String, Object>{
                'Award_Code_1__c' => 'UPDATED-CODE',
                'Award_Title_1__c' => 'Very Updated Award Title'
            }
        };

        // Second request - Application update
        Map<String, Object> appRequest = new Map<String, Object>{
            'method' => 'PATCH',
            'url' => '/services/data/v56.0/sobjects/Graduation_Application__c/a0A1h000003XYZ',
            'referenceId' => 'refApp1',
            'body' => new Map<String, Object>{
                'Last_Edited_By_Email__c' => 'test.user@example.com'
            }
        };

        requests.add(awardRequest);
        requests.add(appRequest);

        return JSON.serialize(requests);
    }

    /**
     * Create test JSON requests with a DELETE method
     */
    private static String createDeleteJsonRequest(String integrationId) {
        List<Map<String, Object>> requests = new List<Map<String, Object>>();

        // First request - Award deletion
        Map<String, Object> deleteRequest = new Map<String, Object>{
            'method' => 'DELETE',
            'url' => '/services/data/v56.0/sobjects/Graduation_Award__c/Integration_Id__c/' + integrationId,
            'referenceId' => 'refAward1'
        };

        // Second request - Application update
        Map<String, Object> appRequest = new Map<String, Object>{
            'method' => 'PATCH',
            'url' => '/services/data/v56.0/sobjects/Graduation_Application__c/a0A1h000003XYZ',
            'referenceId' => 'refApp1',
            'body' => new Map<String, Object>{
                'Last_Edited_By_Email__c' => 'test.user@example.com'
            }
        };

        requests.add(deleteRequest);
        requests.add(appRequest);

        return JSON.serialize(requests);
    }
}