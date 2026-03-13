/**
 * @author          J.Mapanao
 * @date            05.MAR.2020
 * @description     Class handles the recalculation of the Primary Leads based on the contact Id parameter
 * @revision        
 *                  05.MAR.2020 - J.Mapanao - Initial Created
 */
public without sharing class RecalculatePrimaryLeadServices {

    /**
     * @description     constructor
     */
    public RecalculatePrimaryLeadServices() {}

    /**
     * @description     Query all leads per contact sort by last modified date DESC
     * @param           Id contactId
     * @return          Map<Id, List<Lead>>
     */
    public static Map<Id, List<Lead>> getContactAndLeadMap(Id contactId) {
        Map<Id, List<Lead>> contactIdListLeadMap = new Map<Id, List<Lead>>();
        for (Lead loop_Lead : [SELECT Id, Contact__c, Active_Lead_Contact_Id__c, Status FROM Lead WHERE Contact__c =: contactId AND Active_Lead_Contact_Id__c != null ORDER BY CreatedDate DESC]) {
            if (!contactIdListLeadMap.containsKey(loop_Lead.Contact__c)) {
                contactIdListLeadMap.put(loop_Lead.Contact__c, new List<Lead>());
            }
            contactIdListLeadMap.get(loop_Lead.Contact__c).add(loop_Lead);
        }
        return contactIdListLeadMap;
    }

    /**
     * @description     Method handle the recalculating the lead
     * @param           Map<Id, List<Lead>> contactIdListLeadMap
     * @return          void
     */
    public static void reCalculate(Map<Id, List<Lead>> contactIdListLeadMap) {
        Boolean foundPrimaryLead = false;
        List<Lead> leadNonPrimaryToupdate = new List<Lead>();
        List<Lead> leadPrimaryToUpdate = new List<Lead>();
        System.debug('### reCalculate:' + JSON.serializePretty(contactIdListLeadMap));
        for (Id contactId : contactIdListLeadMap.keySet()) {
            String conId = (String) contactId;
            Id foundPrimaryLeadId = null;

            // Get the First Lead in the List. It has been sorted already from the query
            for (Lead loop_Lead : contactIdListLeadMap.get(conId)) {
                if (foundPrimaryLeadId == null) {
                    foundPrimaryLeadId = loop_Lead.Id;
                } else {
                    break;
                }
            }

            // Once new primary lead is found. Do the following.
            // 1. Primary Lead: Update the Active_Lead_Contact_Id__c value to have the contact Id
            // 2. Non-Primary Lead: Update the Status value to 'Closed (De-dup)'
            if (foundPrimaryLeadId != null) {
                for (Lead loop_Lead : contactIdListLeadMap.get(conId)) {
                    if (loop_Lead.Id == foundPrimaryLeadId) {
                        loop_Lead.Active_Lead_Contact_Id__c = conId;
                        leadPrimaryToUpdate.add(loop_Lead);
                    } else {
                        loop_Lead.Active_Lead_Contact_Id__c = null;
                        loop_Lead.Status = 'Closed (De-dup)';
                        leadNonPrimaryToupdate.add(loop_Lead);
                    }
                }
            }
        }
        
        // Do DML logic here
        try {
            TriggerCommon.disableTrigger('Lead');
            
            if (!leadNonPrimaryToupdate.isEmpty()) {
                // Update the Non Primary Leads first to avoid to hit the Duplicate Rules for Lead object
                update leadNonPrimaryToupdate;
            }
            if (!leadPrimaryToUpdate.isEmpty()) {
                // Then update the primary lead
                update leadPrimaryToUpdate;
            }

            TriggerCommon.enableTrigger('Lead');
        } catch (Exception ex) {
            // Log error: Param1: String (nature of error), Param2: String (object name), String : funcName (function name), Param4: String (exception error message)
            ExLog.add(RecalculatePrimaryLeadServices.class.getName(), Lead.class.getName(), 'reCalculate', ex.getMessage());
        }
    }
}