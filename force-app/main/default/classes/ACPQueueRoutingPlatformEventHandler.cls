/**
 * @author       Sethu Venna
 * @date         Aug.2025
 * @description  Routes the ACP to the correct queue for Assessment
 */
public without sharing class ACPQueueRoutingPlatformEventHandler implements IPlatformEventInvocable {
    static final String LOG_TAG = 'ACP Routing';

    private static Map<Id, Group> queueIdMap;
    private static Map<String, Group> queueNameMap;
    List<Application_Course_Preference__c> lstACP;
    Set<Id> setACPId;


    /**
     * @description Queueable execute method
     * @param  payloads
     */
    public void execute(List<AsyncProcessPayload> payloads) {
        try {
            Nebula.Logger.setScenario('ACP Queue Routing');
            initialize(payloads);
            if(!setACPId.isEmpty()) {
                lstACP = (List<Application_Course_Preference__c>) new ApplicationCoursePreferenceSelector().selectSObjectsById(setACPId);
                routeACPtoQueues(lstACP);
            }
        } catch (Exception ex) {
            // route failures to unallocated queue & log error
            handleFailures(lstACP, ex.getMessage());
        } finally {
            Nebula.Logger.saveLog();
            Nebula.Logger.endScenario('ACP Queue Routing');
        }
    }

    private void initialize(List<AsyncProcessPayload> payloads) { 
            if(payloads != null) {
                setACPId = new Set<Id>();
                for(AsyncProcessPayload payload : payloads) {
                    Object tmpObj = (Object) payload.get('acpId');
                    setACPId.add(Id.valueof(String.valueOf(tmpObj)));
                }
            }
        }

    /**
     * @description     Check Managing Faculty and route ACPs to correct Queues.
     * @author          rajesh.punjabi@monash.edu | 17-07-2024
     * @param           lstACP
     * @modified
     *                  Jitender Padda | Jul.2024 - Dynamic routing based on config table
     **/
    public void routeACPtoQueues(List<Application_Course_Preference__c> lstACP) {
        List<Application_Course_Preference__c> lstACPtoUpdate = new List<Application_Course_Preference__c>();

        createQueueMaps();
        List<Queue_Routing_Rule_Condition__c> routingRuleConditions = getQueueRoutingRuleConditions();

        for (Application_Course_Preference__c oACP : lstACP) {
            Boolean hasRuleMatched = false;
            Boolean allConditionsMatch = true;

            // set current routing rule - first rule
            Queue_Routing_Rule__c currentRoutingRule = new Queue_Routing_Rule__c();
            setCurrentRoutingRule(currentRoutingRule, routingRuleConditions[0]);

            // NOTE: conditions are ordered by rule
            for (Queue_Routing_Rule_Condition__c routingRuleCondition : routingRuleConditions) {
                // if rule changed
                if (currentRoutingRule.Id != routingRuleCondition.Queue_Routing_Rule__c) {
                    // - check if previous rule conditions matched & set queue
                    if (allConditionsMatch) {
                        hasRuleMatched = evaluateRule(allConditionsMatch, oACP, currentRoutingRule);
                        break;
                    }

                    // - reset currentRoutingRule & allConditionsMatch
                    setCurrentRoutingRule(currentRoutingRule, routingRuleCondition);
                    allConditionsMatch = true;
                }

                if (allConditionsMatch) { // optimisation
                    // - check if rule condition matches
                    if (evaluateRuleCondition(oACP, routingRuleCondition) == false) {
                        allConditionsMatch = false;
                    }
                }

                // if last condition - check last rule
                if (routingRuleCondition.Id == getLastItem(routingRuleConditions).Id) {
                    // - check if conditions matched & set queue
                    hasRuleMatched = evaluateRule(allConditionsMatch, oACP, currentRoutingRule);
                }
            }

            // assign to unallocated as fallback
            if (hasRuleMatched == false) {
                handleUnmatched(oACP);
            }

			//oACP.Assessment_Flag__c = true;
			oACP.Workflow_Status__c = 'Pending';
            
            lstACPtoUpdate.add(oACP);
        }

        if (lstACPtoUpdate.size() > 0) {
            List<Database.SaveResult> saveResults = Database.update(lstACPtoUpdate, false, AccessLevel.SYSTEM_MODE);

            // route failures to unallocated queue
            handleExceptions(saveResults, lstACPtoUpdate);
        }
    }

    private void handleUnmatched(Application_Course_Preference__c oACP) {
        // assign to unallocated as fallback
        routeToUnallocatedQueue(oACP);
        Nebula.Logger.warn('No assignment rules matched', oACP.Id).addtag(LOG_TAG);
    }

    private void routeToUnallocatedQueue(Application_Course_Preference__c oACP) {
        //oACP.Assessment_Flag__c = true;
        oACP.Workflow_Status__c = 'Pending';
        oACP.OwnerId = queueNameMap.get('Unallocated_ACP_Queue').Id;
    }

    private void setCurrentRoutingRule(
        Queue_Routing_Rule__c currentRoutingRule,
        Queue_Routing_Rule_Condition__c routingRuleCondition
    ) {
        currentRoutingRule.Id = routingRuleCondition.Queue_Routing_Rule__c;
        currentRoutingRule.Name = routingRuleCondition.Queue_Routing_Rule__r.Name;
        currentRoutingRule.Queue__c = routingRuleCondition.Queue_Routing_Rule__r.Queue__c;
    }

    private SObject getLastItem(List<SObject> itemList) {
        return itemList[itemList.size() - 1];
    }

    private Boolean evaluateRule(
        Boolean allConditionsMatch,
        Application_Course_Preference__c oACP,
        Queue_Routing_Rule__c currentRoutingRule
    ) {
        if (allConditionsMatch) {
            route(oACP, currentRoutingRule);
            return true;
        }

        return false;
    }

    private void route(Application_Course_Preference__c oACP, Queue_Routing_Rule__c currentRoutingRule) {
        oACP.OwnerId = queueNameMap.get(currentRoutingRule.Queue__c).Id;

        // add logs for successfully routed ACPs
        Nebula.Logger.info('ACP Routing Rule Matched => ' + currentRoutingRule.Name, oACP.Id).addtag(LOG_TAG);
    }

    private Boolean evaluateRuleCondition(
        Application_Course_Preference__c oACP,
        Queue_Routing_Rule_Condition__c routingRuleCondition
    ) {
        String fieldValue = (String) oACP.get(routingRuleCondition.Field__c);
        String comparisonValue = routingRuleCondition.Value__c;

        switch on routingRuleCondition.Operator__c {
            when 'EQUALS' {
                return isEqual(fieldValue, comparisonValue);
            }
            when 'NOT EQUAL TO' {
                return !isEqual(fieldValue, comparisonValue);
            }
        }

        return false;
    }

    @TestVisible
    private Boolean isEqual(String fieldValue, String comparisonValue) {
        fieldValue = fieldValue?.toLowerCase();
        comparisonValue = comparisonValue?.toLowerCase();

        // use set contains if multiple values
        if(comparisonValue != null){
            if (comparisonValue?.contains(';')) {
                return new Set<String>(comparisonValue?.replaceAll('; ', ';')?.split(';'))
                    ?.contains(fieldValue);
            }
        }

        return fieldValue == comparisonValue ? true : false;
    }

    private static void createQueueMaps() {
        if (queueIdMap == null || queueNameMap == null) {
            queueIdMap = new Map<Id, Group>();
            queueNameMap = new Map<String, Group>();

            for (Group queue : [
                SELECT Id, DeveloperName
                FROM Group
                WHERE
                    Type = 'Queue'
                    AND (DeveloperName LIKE 'CENTRAL_ADMISSION_%'
                    OR DeveloperName = 'Unallocated_ACP_Queue'
                        OR DeveloperName LIKE 'FACULTY_%')
            ]) {
               
                queueNameMap.put(queue.DeveloperName, queue);
                queueIdMap.put(queue.Id, queue);
            }
        }
    }

    private static List<Queue_Routing_Rule_Condition__c> getQueueRoutingRuleConditions() {
        return [
            SELECT
                Id,
                Queue_Routing_Rule__r.Name,
                Queue_Routing_Rule__r.Queue__c,
                Queue_Routing_Rule__r.Order__c,
                Field__c,
                Operator__c,
                Value__c
            FROM Queue_Routing_Rule_Condition__c
            WHERE Queue_Routing_Rule__r.Active__c = TRUE
            ORDER BY Queue_Routing_Rule__r.Order__c
        ];
    }

    private void handleExceptions(
        List<Database.SaveResult> saveResults,
        List<Application_Course_Preference__c> lstACPtoUpdate
    ) {
        Database.SaveResult saveResult = null;
        List<Application_Course_Preference__c> failedACPList = new List<Application_Course_Preference__c>();

        for (Integer i = 0; i < saveResults.size(); i++) {
            saveResult = saveResults[i];
            if (!saveResult.isSuccess()) {
                for (Database.Error err : saveResult.getErrors()) {
                    failedACPList.add(lstACPtoUpdate[i]);
                }
            }
        }

        // route failures to unallocated queue
        if (failedACPList.size() > 0) {
            handleFailures(failedACPList, null);
        }
    }

    private void handleFailures(List<Application_Course_Preference__c> lstACP, String errorMsg) {
        for (Application_Course_Preference__c oACP : lstACP) {
            routeToUnallocatedQueue(oACP);

            // add error log
            errorMsg = errorMsg == null ? String.valueOf(oACP.getErrors()) : errorMsg;
            Nebula.Logger.error(errorMsg + '\r' + json.serializePretty(oACP), oACP.id).addtag(LOG_TAG);
        }

        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        update lstACP;
        TriggerCommon.enableTrigger('Application_Course_Preference__c');
    }
}