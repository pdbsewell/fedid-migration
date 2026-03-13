/*
 * @author:			    JPadda jpad0005
 * @description:	    Services class for Case Team Member sObject
 */
public without sharing class CaseTeamServices {
    private static Map<String, Case_Team_Creation_Rules__mdt> caseTeamCreationRuleMap;

    /*
     * @author:			JPadda jpad0005
     * @date:			11-09-2023
     * @description:	runs Case Team Creation rules and creates Case Team Members for the parent case
     */
    public static void runCaseTeamCreationRules(
        List<SObject> records,
        Map<Id, Case> caseMap,
        String relationshipField
    ) {
        Map<Id, Group> queueMap = getQueueMap();
        Map<String, Id> caseTeamTemplateNameToIdMap = getCaseTeamTemplateNameToIdMap();

        List<CaseTeamTemplateRecord> caseTeamTemplateRecords = new List<CaseTeamTemplateRecord>();
        List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();

        for (SObject record : records) {
            // record belongs to a queue
            if (queueMap.containsKey((Id) record.get('OwnerId'))) {
                Id queueId = (Id) record.get('OwnerId');

                // queue has rule
                if (caseTeamCreationRuleMap.containsKey(queueMap.get(queueId).Name)) {
                    Case_Team_Creation_Rules__mdt caseTeamCreationRule = caseTeamCreationRuleMap.get(
                        queueMap.get(queueId).Name
                    );

                    // 1. Case Record Type - check
                    if (
                        caseTeamCreationRule.Applied_to_Enquiry_Record_Types__c.contains(
                            caseMap.get((Id) record.get(relationshipField)).RecordType.DeveloperName
                        )
                    ) {
                        // create Case Team Template record
                        caseTeamTemplateRecords.add(
                            new CaseTeamTemplateRecord(
                                TeamTemplateId = caseTeamTemplateNameToIdMap.get(
                                    caseTeamCreationRule.Case_Team_Template__c
                                ),
                                ParentId = (Id) record.get(relationshipField)
                            )
                        );

                        // create notification
                        if (caseTeamCreationRule.Email_Notification_to_Queue__c) {
                            createEmailNotifications(
                                record,
                                queueMap.get(queueId).GroupMembers,
                                relationshipField,
                                emailMessageList
                            );
                        }
                    }
                }
            }
        }

        // insert Case Team Template records with partial success - ignoring duplicates
        Database.SaveResult[] saveResults = Database.insert(caseTeamTemplateRecords, false);

        // Send notifications
        if (emailMessageList.isEmpty() == false) {
            Messaging.sendEmail(emailMessageList);
        }

        logExceptions(caseTeamTemplateRecords, saveResults);
    }

    /*
     * @author:			JPadda jpad0005
     * @date:			11-09-2023
     * @description:	logs exceptions for failed Case Team Member records - ignores duplicates
     */
    private static void logExceptions(
        List<CaseTeamTemplateRecord> caseTeamTemplateRecords,
        Database.SaveResult[] saveResults
    ) {
        // ignore duplicates
        LogUtilityException.skippedTypes.add(StatusCode.DUPLICATE_VALUE.name());

        for (Integer i = 0; i < caseTeamTemplateRecords.size(); i++) {
            Database.SaveResult saveResult = saveResults[i];
            if (saveResult.isSuccess() == false) {
                List<Database.Error> errs = saveResult.getErrors();
                if (errs != null && !errs.isEmpty()) {
                    for (Database.Error er : errs) {
                        LogUtilityException.logExceptionMSG(er.getStatusCode(), saveResults[i], er.getMessage());
                    }
                }
            }
        }
    }

    /*
     * @author:			JPadda jpad0005
     * @date:			11-09-2023
     * @description:	query Case Team Creation rules and cache in list
     */
    private static List<Case_Team_Creation_Rules__mdt> getCaseTeamCreationRules() {
        if (caseTeamCreationRuleMap == null) {
            caseTeamCreationRuleMap = new Map<String, Case_Team_Creation_Rules__mdt>();

            for (Case_Team_Creation_Rules__mdt caseTeamCreationRule : [
                SELECT
                    Id,
                    Active__c,
                    Queue__c,
                    Case_Team_Template__c,
                    Applied_to_Enquiry_Record_Types__c,
                    Email_Notification_to_Queue__c
                FROM Case_Team_Creation_Rules__mdt
                WHERE Active__c = TRUE
            ]) {
                String key = caseTeamCreationRule.Queue__c;
                caseTeamCreationRuleMap.put(key, caseTeamCreationRule);
            }
        }

        return caseTeamCreationRuleMap.values();
    }

    /*
     * @author:			JPadda jpad0005
     * @date:			11-09-2023
     * @description:	fetch map of Queues which are defined in Case Team creation rules
     */
    private static Map<Id, Group> getQueueMap() {
        getCaseTeamCreationRules();

        return new Map<Id, Group>(
            [
                SELECT
                    Id,
                    Name,
                    (
                        SELECT UserOrGroupId, GroupId
                        FROM GroupMembers
                    )
                FROM Group
                WHERE Type = 'Queue' AND Name IN :caseTeamCreationRuleMap.keySet()
            ]
        );
    }

    /*
     * @author:			JPadda jpad0005
     * @date:			11-09-2023
     * @description:	fetch map of Case Team Template name to id from Case Team Creation Rules
     */
    private static Map<String, Id> getCaseTeamTemplateNameToIdMap() {
        Map<String, Id> caseTeamTemplateNameToIdMap = new Map<String, Id>();

        for (Case_Team_Creation_Rules__mdt caseTeamCreationRule : getCaseTeamCreationRules()) {
            caseTeamTemplateNameToIdMap.put(caseTeamCreationRule.Case_Team_Template__c, null);
        }

        for (CaseTeamTemplate caseTeamTemplate : [
            SELECT Id, Name
            FROM CaseTeamTemplate
            WHERE Name IN :caseTeamTemplateNameToIdMap.keySet()
        ]) {
            caseTeamTemplateNameToIdMap.put(caseTeamTemplate.Name, caseTeamTemplate.Id);
        }

        return caseTeamTemplateNameToIdMap;
    }

    private static void createEmailNotifications(
        SObject record,
        List<GroupMember> groubMembers,
        String relationshipField,
        List<Messaging.SingleEmailMessage> emailMessageList
    ) {
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

        for (GroupMember groupMember : groubMembers) {
            if (groupMember.UserOrGroupId.getSObjectType() == User.SObjectType) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTargetObjectId(groupMember.UserOrGroupId);
                email.setSaveAsActivity(false);

                email.setSubject('New Task Assigned - ' + record.get('Subject'));
                email.setHTMLBody(
                    '<b>Enquiry</b> - <a href="' +
                        baseUrl +
                        '/' +
                        record.get(relationshipField) +
                        '" target="_blank">' +
                        baseUrl +
                        '/' +
                        record.get(relationshipField) +
                        '</a><br><br>' +
                        '<b>Task</b> - <a href="' +
                        baseUrl +
                        '/' +
                        record.Id +
                        '" target="_blank">' +
                        baseUrl +
                        '/' +
                        record.Id +
                        '</a>'
                );

                emailMessageList.add(email);
            }
        }
    }
}