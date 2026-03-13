public class GradsPendingStateHandler {

    public class PendingAwardImpact {
        public Boolean hasPendingState;
        public String submitterEmail;
        public Datetime submissionDate;
        public Datetime expiryDate;
    }

    /**
     * Get the pending state impact for a given award integration ID and application ID
     * @param awardIntegrationId Graduation_Award__c.Integration_Id__c
     * @param appId Graduation_Application__c.Id
     * @return A PendingAwardImpact object containing the impact details
     */
    public static PendingAwardImpact getAwardImpact(String awardIntegrationId, Graduation_Application__c app) {
        PendingAwardImpact impact = new PendingAwardImpact();
        impact.hasPendingState = false;

        String pps = app.Payment_Pending_State__c;

        if (String.isBlank(pps) || app.Payment_Pending_State_Expiry__c < Datetime.now()) {
            return impact;
        }

        PendingStateResponse psr = parsePendingState(pps);

        if (psr != null && psr.AwardStates != null) {
            for (StateChange state : psr.AwardStates) {
                if (state.integrationId == awardIntegrationId) {
                    impact.hasPendingState = true;
                    impact.submitterEmail = psr.LastEditedByEmail;
                    impact.submissionDate = getLastPaymentPendingEdit(app.Id);
                    impact.expiryDate = app.Payment_Pending_State_Expiry__c;
                    break;
                }
            }
        }

        return impact;
    }

    /**
     * Get the last payment pending edit date for a given application ID
     * @param appId The ID of the Graduation_Application__c record
     * @return The last payment pending edit date or null if not found
     */
    public static Datetime getLastPaymentPendingEdit(Id appId) {
        return [
            SELECT CreatedDate
            FROM Graduation_Application__History
            WHERE ParentId = :appId AND Field = 'Payment_Pending_State__c'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ]?.CreatedDate ?? null;
    }

    /**
     * Wrapper class to hold the response structure
     */
    public class PendingStateResponse {
        public String LastEditedByEmail { get; set; }
        public List<StateChange> AwardStates { get; set; }

        public PendingStateResponse() {
            this.AwardStates = new List<StateChange>();
        }
    }

    /**
     * Process a JSON string containing a SF REST API composite request
     * @param pendingStateJson JSON string of composite request
     * @return PendingStateResponse
     */
    public static PendingStateResponse parsePendingState(String pendingStateJson) {
        PendingStateResponse response = new PendingStateResponse();

        // Parse JSON string into a list of requests
        List<Object> requests = (List<Object>)JSON.deserializeUntyped(pendingStateJson);

        // Collect all Graduation_Award__c requests
        List<Map<String, Object>> awardRequests = new List<Map<String, Object>>();

        // Track application requests to extract Last_Edited_By_Email__c
        String lastEditedByEmail = null;

        for (Object req : requests) {
            Map<String, Object> request = (Map<String, Object>)req;
            String url = (String)request.get('url');

            if (String.isBlank(url)) {
                continue;
            }

            if (url.contains('/sobjects/Graduation_Award__c/')) {
                // Collect Graduation_Award__c requests
                awardRequests.add(request);
            }
            else if (url.contains('/sobjects/Graduation_Application__c/')) {
                // Extract Last_Edited_By_Email__c from Graduation_Application__c requests
                Map<String, Object> body = (Map<String, Object>)request.get('body');

                if (body != null && body.containsKey('Last_Edited_By_Email__c')) {
                    lastEditedByEmail = (String)body.get('Last_Edited_By_Email__c');
                }
            }
        }

        // Set the email in the response
        response.LastEditedByEmail = lastEditedByEmail;

        // If we have award requests, analyse them
        if (!awardRequests.isEmpty()) {
            response.AwardStates = buildStateChange(awardRequests);
        }

        return response;
    }

    /**
     * Class to hold analysis result for a Graduation Award request
     */
    public class StateChange {
        public String integrationId;
        public Boolean isNewRecord;
        public Id awardId;
        public Boolean isDelete;
        public Map<String, Object> changedFields;

        public StateChange() {
            isNewRecord = true;
            isDelete = false;
            changedFields = new Map<String, Object>();
        }
    }

    /**
     * Create a list of StateChange objects based on the provided requests
     * @param requests List of request maps (collection representing composite requests)
     * @return List of StateChange results
     */
    private static List<StateChange> buildStateChange(List<Map<String, Object>> requests) {
        List<StateChange> states = new List<StateChange>();
        Set<String> integrationIds = new Set<String>();

        Set<String> changedFieldNames = new Set<String>();

        // First pass: Extract integration IDs and create state change objects
        for (Map<String, Object> req : requests) {
            StateChange sc = new StateChange();
            sc.isDelete = (String)req.get('method') == 'DELETE';

            String url = (String)req.get('url');
            Map<String, Object> body = (Map<String, Object>)req.get('body');

            // Extract integration ID from the URL
            if (!url.contains('Integration_Id__c/')) continue;
            sc.integrationId = url.substringAfter('Integration_Id__c/');

            // Skip requests without an integration ID
            if (String.isBlank(sc.integrationId)) continue;
            integrationIds.add(sc.integrationId);

            // Store request fields for comparison
            sc.changedFields = body;

            // Collect list of all changed fields for dynamic query
            if(body != null) {
                for(String fieldName : body.keySet()) {
                    changedFieldNames.add(fieldName.toLowerCase());
                }
            }
            states.add(sc);
        }

        // Filter out fields that don't exist on Graduation_Award__c
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Graduation_Award__c.fields.getMap();
        changedFieldNames.retainAll(fieldMap.keySet());
        changedFieldNames.add('Integration_Id__c'); // Ensure Integration_Id__c is included

        // Query existing records using the collected integration IDs
        Map<String, Graduation_Award__c> existingRecords = new Map<String, Graduation_Award__c>();

        if (!integrationIds.isEmpty()) {

            String query = 'SELECT ' + String.join(changedFieldNames, ', ') +
                ' FROM Graduation_Award__c WHERE Integration_Id__c IN :integrationIds';

            for(Graduation_Award__c award :Database.query(query)) {
                existingRecords.put(award.Integration_Id__c, award);
            }
        }

        // Second pass: Compare with existing records to find changes
        for (StateChange state : states) {

            Graduation_Award__c existingRecord = existingRecords.get(state.integrationId);
            if (existingRecord != null) {
                state.isNewRecord = false;

                // Find changed fields
                Map<String, Object> existingFields = existingRecord.getPopulatedFieldsAsMap();
                Map<String, Object> changedFields = new Map<String, Object>();

                state.awardId = existingRecord.Id;

                if(state.isDelete || state.isNewRecord) {
                    // If it's a delete request or a new record, we don't need to compare fields
                    continue;
                }

                // Compare each field in the request with existing record
                for (String fieldName : state.changedFields.keySet()) {
                    Object newValue = state.changedFields.get(fieldName);
                    Object existingValue = existingFields.get(fieldName);

                    // Field comparison
                    Boolean isDifferent = false;

                    if (existingValue == null && newValue != null) {
                        isDifferent = true;
                    } else if (existingValue != null && newValue == null) {
                        isDifferent = true;
                    } else if (existingValue != null && newValue != null) {
                        // Convert to strings for comparison
                        String existingStr = String.valueOf(existingValue);
                        String newStr = String.valueOf(newValue);

                        isDifferent = !existingStr.equals(newStr);
                    }

                    if (isDifferent) {
                        changedFields.put(fieldName, newValue);
                    }
                }

                // Update analysis with only the changed fields
                state.changedFields = changedFields;
            }
            // Else, it's a new record and all fields are considered changed (default behavior)
        }

        return states;
    }
}