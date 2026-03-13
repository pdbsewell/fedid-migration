/**
 * Assignment handler class, contains default logic to populate contact PRM field based on assignment type prefixed with 'Primary Relationship Manager'
 *
 * @author:  Mark Johnson
 * @since:   12/1/2020
 */

global inherited sharing class PM_AssignmentHandler extends ucinn_ascendv2.ascend_TDTM_Runnable {
    
    final string PRM = 'Primary Relationship Manager'; //String denoting the Prefix for the assignment types that we will run our logic on.
    final List<String> prmPicklistValues = getPicklistValuesIntoList(); //Picklist Values with PRM contained.
    
    final Date defaultStartDate = Date.newInstance(1900,1,1);
    final Date defaultEndDate = Date.newInstance(4000,12,31);
    
    
    /**
    *   Global override to extend TDTM structure.
    *
    *   @param      newList: list of records that have had dml operations performed on them.
    *   @param      oldList: list of records before they had dml operations performed on them.
    *   @param      triggerAction: dml action that caused the trigger execution
    *   @param      objResult: sObject describe for the assignment sObject.
    *   @return     dmlWrapper: list of items to perform dml on in bulk
    *   @since      12/1/2020
    */
    global override ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper run(List<SObject> newList, List<SObject> oldList, ucinn_ascendv2.ascend_TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper dmlWrapper = new ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper();

        if (checkForBypassSetting()) {
            return dmlWrapper;
        }
        
        List<ucinn_ascendv2__Assignment__c> triggerNew = (List<ucinn_ascendv2__Assignment__c>) newList;
        List<ucinn_ascendv2__Assignment__c> triggerOld = (List<ucinn_ascendv2__Assignment__c>) oldList;
        
        Map<Id, ucinn_ascendv2__Assignment__c> oldMap = createOldMap(triggerOld);

        if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.BeforeInsert) {
            validateManagerTimeOverlap(triggerNew);
        } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterInsert) {
            rollupPRM(newList, oldList, oldMap, triggerAction);
        } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.BeforeUpdate) {
            validateManagerTimeOverlap(triggerNew);
        } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterUpdate) {
            rollupPRM(newList, oldList, oldMap, triggerAction);
        } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterDelete) {
            rollupPRM(newList, oldList, oldMap, triggerAction);
        }

        return dmlWrapper;
    }
    
    
    /**
     * Returns picklist values where primary relationship manager is contained in the API name. We take this approach because of
     * Salesforce query limitations on using LIKE with picklist API names. LIKE automatically converts to check against picklist LABELS.
     *
     * @return   picklistValues: picklist values for ucinn_ascendv2__Assignment_Type__c where "Primary Relationship Manager" is contained in the API name.
     * @since    12/1/2020
     */
    public List<String> getPickListValuesIntoList() {
        List<String> picklistValues = new List<String>();

        Schema.DescribeFieldResult fieldResult = ucinn_ascendv2__Assignment__c.ucinn_ascendv2__Assignment_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry pickListVal : ple) {
            String value = pickListVal.getValue();
            
            if (value.contains(PRM)) {
                picklistValues.add(pickListVal.getValue());
            }
        }
        return picklistValues;
    }
    
    
    /**
    *   Gets custom setting bypass setting and checks if we should execute this trigger.
    *
    *   @return     Boolean denoting whether we should execute this trigger or bypass it.
    *   @since      12/1/2020
    */
    private Boolean checkForBypassSetting() {
        Boolean isBypassTrig = ucinn_ascendv2__Bypass_Settings__c.getInstance().ucinn_ascendv2__Bypass_Triggers__c;
        
        if (isBypassTrig) {
            return true;
        }
        
        return false;
    }
    
    
    /**
    *   Creates a map out of a trigger list
    *
    *   @param      triggerOld: list of records before they had dml operations performed on them.
    *   @return     Map of Id to assignment record
    *   @since      12/1/2020
    */
    private Map<Id, ucinn_ascendv2__Assignment__c> createOldMap(List<ucinn_ascendv2__Assignment__c> triggerOld) {
        if (triggerOld != null) {
            return new Map<Id, ucinn_ascendv2__Assignment__c>(triggerOld);
        }
        
        return null;
    }
    
    
    /**
    *   Rollup the Primary Relationship Manager to the contact or account record
    *
    *   @param      triggerNew: list of records that have had dml operations performed on them.
    *   @param      triggerOld: list of records before they had dml operations performed on them.
    *   @param      oldMap: map of Id to assignment record for records before they had dml operations performed on them.
    *   @param      triggerAction: dml action that caused the trigger execution
    *   @return     dmlWrapper: list of items to perform dml on in bulk
    *   @since      12/1/2020
    */
    private void rollupPRM( List<ucinn_ascendv2__Assignment__c> triggerNew, 
                            List<ucinn_ascendv2__Assignment__c> triggerOld, 
                            Map<Id, ucinn_ascendv2__Assignment__c> oldMap,
                            ucinn_ascendv2.ascend_TDTM_Runnable.Action triggerAction){

        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        List<Contact> contacts = new List<Contact>();
        List<Account> accounts = new List<Account>();
        List<Contact> contactUpdates = new List<Contact>();
        List<Account> accountUpdates = new List<Account>();

        // Get the list of contacts and accounts
        if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterDelete) {
            for (ucinn_ascendv2__Assignment__c ass : triggerOld) {
                if (ass.ucinn_ascendv2__Contact__c != null) {
                    contactIds.add(ass.ucinn_ascendv2__Contact__c);
                }

                if (ass.ucinn_ascendv2__Account__c != null) {
                    accountIds.add(ass.ucinn_ascendv2__Account__c);
                }
            }
        } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterUpdate || triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterInsert) {
            for (ucinn_ascendv2__Assignment__c ass : triggerNew) {
                if (ass.ucinn_ascendv2__Contact__c != null) {
                    contactIds.add(ass.ucinn_ascendv2__Contact__c);
                }

                if (ass.ucinn_ascendv2__Account__c != null) {
                    accountIds.add(ass.ucinn_ascendv2__Account__c);
                }

                // If the contact or account has changed, the PRM for the old one may have to be updated as well
                if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterUpdate){
                    if ((ass.ucinn_ascendv2__Contact__c != oldMap.get(ass.Id).ucinn_ascendv2__Contact__c)) {
                        contactIds.add(oldMap.get(ass.Id).ucinn_ascendv2__Contact__c);
                    }

                    if ((ass.ucinn_ascendv2__Account__c != oldMap.get(ass.Id).ucinn_ascendv2__Account__c)) {
                        accountIds.add(oldMap.get(ass.Id).ucinn_ascendv2__Account__c);
                    }
                }
            }
        }

                                
        //Query for existing assignments on corresponding contacts and accounts.
        if (!contactIds.isEmpty()) {
            
            contacts = [SELECT Id, ucinn_ascendv2__PRM__c,
                          (SELECT Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Assigned_Relationship_Manager_User__c, ucinn_ascendv2__Assignment_Start_Date__c, ucinn_ascendv2__Assignment_End_Date__c
                           FROM ucinn_ascendv2__Assignments_Contact__r
                           WHERE ucinn_ascendv2__Assignment_Type__c IN: prmPicklistValues)
                       FROM Contact WHERE Id in :contactIds];
            
        }

        if (!accountIds.isEmpty()) {

            accounts = [SELECT Id, ucinn_ascendv2__PRM__c,
                          (SELECT Id, ucinn_ascendv2__Account__c, ucinn_ascendv2__Assigned_Relationship_Manager_User__c, ucinn_ascendv2__Assignment_Start_Date__c, ucinn_ascendv2__Assignment_End_Date__c
                           FROM ucinn_ascendv2__Assignments_Account__r
                           WHERE ucinn_ascendv2__Assignment_Type__c IN: prmPicklistValues)
                        FROM Account WHERE Id in :accountIds];
        }

        //Assign new PRMs to contacts and accounts.
        for (Contact con : contacts){
            id currentPRM = null;

            for (ucinn_ascendv2__Assignment__c ass : con.ucinn_ascendv2__Assignments_Contact__r) {
                if ((ass.ucinn_ascendv2__Assigned_Relationship_Manager_User__c != null) && assignmentIsCurrent(ass)) {
                    currentPRM = ass.ucinn_ascendv2__Assigned_Relationship_Manager_User__c;
                    break;
                }
            }

            if (con.ucinn_ascendv2__PRM__c != currentPRM) {
                contactUpdates.add(new Contact(Id = con.Id, ucinn_ascendv2__PRM__c = currentPRM));
            }
        }

        for (Account acct : accounts){
            Id currentPRM = null;

            for (ucinn_ascendv2__Assignment__c ass : acct.ucinn_ascendv2__Assignments_Account__r) {
                if ((ass.ucinn_ascendv2__Assigned_Relationship_Manager_User__c != null) && assignmentIsCurrent(ass)) {
                    currentPRM = ass.ucinn_ascendv2__Assigned_Relationship_Manager_User__c;
                    break;
                }
            }
            if (acct.ucinn_ascendv2__PRM__c != currentPRM) {
                accountUpdates.add(new Account(Id = acct.Id, ucinn_ascendv2__PRM__c = currentPRM));
            }
        }

        //Perform DML on the contacts and accounts.
        if (contactupdates.size() > 0) {
            update contactupdates;
        }

        if (accountupdates.size() > 0) {
           update accountupdates;
        }
    }
    

    /**
    *   Validate that there is only one Primary Relationship Manager active at any one time. Check both the contact and their spouse
    *
    *   @param      triggerNew: list of records that have had dml operations performed on them.
    *   @param      triggerOld: list of records before they had dml operations performed on them.
    *   @param      oldMap: map of Id to assignment record for records before they had dml operations performed on them.
    *   @param      triggerAction: dml action that caused the trigger execution
    *   @return     dmlWrapper: list of items to perform dml on in bulk
    *   @since      12/1/2020
    */
    public Boolean validateManagerTimeOverlap(List<ucinn_ascendv2__Assignment__c> triggerNew){

        Boolean isValid = true;
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Account> accountUpdates = new Map<Id, Account>();
        Map<Id, Contact> contactUpdates = new Map<Id, Contact>();

        for (ucinn_ascendv2__Assignment__c ass : triggerNew) {
            if ((ass.ucinn_ascendv2__Assigned_Relationship_Mngr_Contact__c == null) && (ass.ucinn_ascendv2__Assigned_Relationship_Manager_User__c == null)) {
                ass.addError('You must specify the Assigned Relationship Manager');
                return false;
            }

            // Check the dates are in order
            Date startDate = ass.ucinn_ascendv2__Assignment_Start_Date__c;
            Date endDate = ass.ucinn_ascendv2__Assignment_End_Date__c;

            if (startDate == null) {
                startDate = defaultStartDate;
            }

            if (endDate == null) {
                endDate = defaultEndDate;
            }

            if (startDate > endDate) {
                ass.addError('The start date must be on or before the end date.');
                return false;
            }

            if ((ass.ucinn_ascendv2__Account__c != null) && (ass.ucinn_ascendv2__Assignment_Type__c != null && ass.ucinn_ascendv2__Assignment_Type__c.contains(PRM))) {
                accountIds.add(ass.ucinn_ascendv2__Account__c);
            }

            if ((ass.ucinn_ascendv2__Contact__c != null) && (ass.ucinn_ascendv2__Assignment_Type__c != null && ass.ucinn_ascendv2__Assignment_Type__c.contains(PRM))) {
                contactIds.add(ass.ucinn_ascendv2__Contact__c);
            }
        }

        if ((contactIds.size() == 0) && (accountIds.size() == 0)) {
            return true;
        }

        Map<Id, Account> accountMap;
        Map<Id, Contact> contactMap;

        if (accountIds.size() > 0) {
            accountMap = new Map<Id, Account>(
                        [SELECT Id,
                            (SELECT Id, ucinn_ascendv2__Is_Primary_Assignment__c, ucinn_ascendv2__Assigned_Relationship_Manager_User__c, ucinn_ascendv2__Assignment_Start_Date__c, ucinn_ascendv2__Assignment_End_Date__c
                             FROM ucinn_ascendv2__Assignments_Account__r
                             WHERE ucinn_ascendv2__Assignment_Type__c IN: prmPicklistValues)
                         FROM Account
                         WHERE Id in :accountIds]);
        }

        if (contactIds.size() > 0) {
            contactMap = new Map<Id, Contact>(
                        [SELECT Id, ucinn_ascendv2__Preferred_Spouse__c,
                            (SELECT Id, ucinn_ascendv2__Is_Primary_Assignment__c, ucinn_ascendv2__Assigned_Relationship_Manager_User__c, ucinn_ascendv2__Assignment_Start_Date__c, ucinn_ascendv2__Assignment_End_Date__c
                             FROM ucinn_ascendv2__Assignments_Contact__r
                             WHERE ucinn_ascendv2__Assignment_Type__c IN: prmPicklistValues)
                         FROM Contact
                         WHERE Id in :contactIds]);
        }

        for (ucinn_ascendv2__Assignment__c ass : triggerNew) {
            if (accountIds.contains(ass.ucinn_ascendv2__Account__c) || contactIds.contains(ass.ucinn_ascendv2__Contact__c)) {
                ucinn_ascendv2__Assignment__c newAss = ass.clone(true, true, false, false);

                // Ignore PRMs with an end date in the past.  This was done because the initial data load from CRS had many PRM time conflicts in the past
                // and there wasn't time to clean up the data.
                if ((newAss.ucinn_ascendv2__Assignment_End_Date__c == null) || ((newAss.ucinn_ascendv2__Assignment_End_Date__c != null) && (newAss.ucinn_ascendv2__Assignment_End_Date__c >= Date.today()))) {
                    // Verify no time overlap for the contact
                    if (accountIds.contains(ass.ucinn_ascendv2__Account__c)) {
                        if (!noMgrTimeOverlap(newAss, accountMap.get(ass.ucinn_ascendv2__Account__c).ucinn_ascendv2__Assignments_Account__r)){
                            ass.addError('An organization can only have one Primary Relationship Manager assigned at any one time.  The PRM for this organization has a time conflict either today or in the future.');
                            isValid = false;
                            continue;
                        }
                    }

                    // Verify no time overlap for the account
                    if (contactIds.contains(ass.ucinn_ascendv2__Contact__c)){
                        if (!noMgrTimeOverlap(newAss, contactMap.get(ass.ucinn_ascendv2__Contact__c).ucinn_ascendv2__Assignments_Contact__r)){
                            ass.addError('A constituent can only have one Primary Relationship Manager assigned at any one time.  The PRM for this constituent has a time conflict either today or in the future.');
                            isValid = false;
                            continue;
                        }
                    }
                }
            }
        }
        return isValid;
    }
    
    
    private Boolean noMgrTimeOverlap(ucinn_ascendv2__Assignment__c ass, List<ucinn_ascendv2__Assignment__c> assignments){

        // Check that this assignment does not overlap with the time period of other assignments
        if (assignments.isEmpty()) {
            return true;
        }

        Date today = Date.today();
        Date newStartDate;
        Date newEndDate;

        // Supply defaults for missing dates
        if (ass.ucinn_ascendv2__Assignment_End_Date__c == null) {
            newEndDate = defaultEndDate;
        } else {
            newEndDate = ass.ucinn_ascendv2__Assignment_End_Date__c;
        }
        // Ignore PRMs with an end date in the past.  This was done becasue the initial data load from CRS had many PRM time conflicts in the past
        // and there wasn't time to clean up the data.
        if (newEndDate < today) {
            return true;
        }

        if (ass.ucinn_ascendv2__Assignment_Start_Date__c == null) {
            newStartDate = defaultStartDate;
        } else {
            newStartDate = ass.ucinn_ascendv2__Assignment_Start_Date__c;
        }

        for (ucinn_ascendv2__Assignment__c oldAss : assignments){

            // Don't compare an updated record to itself
            if (ass.Id == oldAss.Id) {
                continue;
            }

            Date oldStartDate;
            Date oldEndDate;

            // Supply defaults
            if (oldAss.ucinn_ascendv2__Assignment_End_Date__c == null) {
                oldEndDate = defaultEndDate;
            } else {
                oldEndDate = oldAss.ucinn_ascendv2__Assignment_End_Date__c;
            }

            if (oldEndDate < today) {
                continue; // Ignore assignments in the past
            }

            if (oldAss.ucinn_ascendv2__Assignment_Start_Date__c == null) {
                oldStartDate = defaultStartDate;
            } else {
                oldStartDate = oldAss.ucinn_ascendv2__Assignment_Start_Date__c;
            }

            // The new start date falls within the old date range
            // As assignment that ends on the same day another begins is acceptable
            if ((newStartDate < oldEndDate) && (newEndDate > oldStartDate)) {
                return false;
            }

        }
        return true;
    }
    
    
    /**
    *   Returns whether the assignment is current or not
    *
    *   @param      assignment: assignment to check for current PRM
    *   @return     Boolean denoting whether the assignment is current or not
    *   @since      12/1/2020
    */
    private Boolean assignmentIsCurrent(ucinn_ascendv2__Assignment__c assignment){
          if ((assignment.ucinn_ascendv2__Assignment_Start_Date__c == null || assignment.ucinn_ascendv2__Assignment_Start_Date__c <= Date.today())
               && (assignment.ucinn_ascendv2__Assignment_End_Date__c == null || assignment.ucinn_ascendv2__Assignment_End_Date__c >= Date.today())) {
              return true;
          } else {
              return false;
          }
    }
}