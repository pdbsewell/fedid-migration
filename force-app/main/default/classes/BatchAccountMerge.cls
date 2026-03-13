/*******************************************************************************
* @author       Angelo Rivera
* @date         18/1/2024
* @description  Batch class for bulk account merge
*               Calls the AccountMergeController and processes it by bulk
* @revision    	18/1/2024 - Initial Version
                2024-04-17 - Sachin Shetty   - Update to point to DBConnect fields
*******************************************************************************/
global class  BatchAccountMerge implements Database.Batchable<SObject>,Schedulable{

    // query all external organisation accounts
    public String strQuery = 'SELECT Id, Name, RecordType.DeveloperName, Account_PRM_Name__c, PURE_Organisation_ID__c, Organisation_Identifier__c, ' +
                            'Organisation_Identifier_Alternative__c, Organisation_Identifier_Type__c, Organisation_Identifier_Type_Alternative__c,' +
                            'DBC_DUNS_Number__c, ParentId, BillingAddress, Website, SicDesc, Owner.Name, LastModifiedDate ' +
                            'FROM Account WHERE RecordType.DeveloperName = \'External_Organisation\' ' +
                            'ORDER BY LastModifiedDate DESC, DBC_DUNS_Number__c NULLS LAST, Account_PRM_Name__c NULLS LAST ';

    static final String DUPLICATE_PERFECT_MATCH_NAME = 'Enterprise_Account_Dup';
    static final String DUPLICATE_PERFECT_MATCH_RULE_NAME = 'Enterprise_Account_Dup_matching_rule';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {

        // get the duplicates of the account
        List<Account> l_Accounts = (List<Account>)scope;
        List<Account> listChildAccountsToUpdate = new List<Account>();
        Map<Id, Set<Id>> mapDupAccountIdsByPrimaryAccountId = new  Map<Id, Set<Id>>();
        Map<Id, Account> mapAccountsByIds = new Map<Id, Account>();
        Map<Id, Account> mapDupAccountsByIds = new Map<Id, Account>();
        Map<Id, List<Account>> mapChildAccountsByParentIds = new Map<Id, List<Account>>();
        Set<Id> acctIdToUpdate = new Set<Id>();
        Set<Id> setMergedAccountIds = new Set<Id>();

        for(Account primaryAccount : l_Accounts){
            mapAccountsByIds.put(primaryAccount.Id, primaryAccount);
            Set<Id> s_AccountIds = new Set<Id>();
            s_AccountIds.add(primaryAccount.Id);

            // Find if there are Perfect Match result
            Set<Id> perfectMatchAcctIds = new Set<Id>();
            perfectMatchAcctIds = findDuplicateAccounts(s_AccountIds, DUPLICATE_PERFECT_MATCH_NAME, DUPLICATE_PERFECT_MATCH_RULE_NAME);
            if (!perfectMatchAcctIds.isEmpty()) {
                // if there are duplicates, consolidate in a map by primary account
                if(!mapDupAccountIdsByPrimaryAccountId.containsKey(primaryAccount.Id)){
                    mapDupAccountIdsByPrimaryAccountId.put(primaryAccount.Id,perfectMatchAcctIds);
                }
            }
        }

        if(!mapDupAccountIdsByPrimaryAccountId.isEmpty()){
            Nebula.Logger.info('Map of Duplicate Account Ids: \n' + JSON.serializePretty(mapDupAccountIdsByPrimaryAccountId));
            Set<Id> setAccountIds = new Set<Id>();
            for(Id primaryAcctId : mapDupAccountIdsByPrimaryAccountId.keySet()){
                setAccountIds.add(primaryAcctId);
                for(Id dupAcctId : mapDupAccountIdsByPrimaryAccountId.get(primaryAcctId)){
                    setAccountIds.add(dupAcctId);
                }
            }
            for(Account acc : [SELECT Id, Name, DBC_DUNS_Number__c, ParentId, PURE_Organisation_ID__c,
                                    Organisation_Identifier__c, Organisation_Identifier_Alternative__c,
                                        Organisation_Identifier_Type__c, Organisation_Identifier_Type_Alternative__c, LastModifiedDate,
                                    (SELECT Id, Name, ParentId FROM ChildAccounts)
                                    FROM Account
                                        WHERE Id IN: setAccountIds
                                            ORDER BY LastModifiedDate DESC, Account_PRM_Name__c NULLS LAST ]){
                mapDupAccountsByIds.put(acc.Id, acc);

                List<Account> lstAccounts = new List<Account>();
                lstAccounts.addAll(acc.ChildAccounts);
                mapChildAccountsByParentIds.put(acc.Id, lstAccounts);
            }

            try {
                Id survivingAccountId;

                for(Id primaryAcctId : mapDupAccountIdsByPrimaryAccountId.keySet()){
                    if(!setMergedAccountIds.contains(primaryAcctId)) {
                        Account primaryAccount = new Account();
                        primaryAccount = mapAccountsByIds.get(primaryAcctId);
                        List<Account> listPrimChildAccounts = new List<Account>();
                        listPrimChildAccounts = mapChildAccountsByParentIds.get(primaryAccount.Id);
                        for (Id dupAcctId : mapDupAccountIdsByPrimaryAccountId.get(primaryAcctId)) {
                            if(!setMergedAccountIds.contains(dupAcctId)) {
                                Account duplicateAccount = new Account();
                                duplicateAccount = mapDupAccountsByIds.get(dupAcctId);
                                List<Account> listDupChildAccounts = new List<Account>();
                                listDupChildAccounts = mapChildAccountsByParentIds.get(duplicateAccount.Id);
                                // check if neither accounts have parent account
                                if(String.isBlank(primaryAccount.ParentId) && String.isBlank(duplicateAccount.ParentId)) {
                                    String strLogMessage = '';
                                    // check if Duns are both populated and matching
                                    if(String.isNotBlank(primaryAccount.DBC_DUNS_Number__c) && String.isNotBlank(duplicateAccount.DBC_DUNS_Number__c)
                                            && (primaryAccount.DBC_DUNS_Number__c.equalsIgnoreCase(duplicateAccount.DBC_DUNS_Number__c))) {
                                        // check if both accounts dont have or same PURE_Organisation_ID__c
                                        if ((String.isBlank(primaryAccount.PURE_Organisation_ID__c) && String.isBlank(duplicateAccount.PURE_Organisation_ID__c)) ||
                                                (String.isNotBlank(primaryAccount.PURE_Organisation_ID__c) && String.isNotBlank(duplicateAccount.PURE_Organisation_ID__c)
                                                        && primaryAccount.PURE_Organisation_ID__c.equalsIgnoreCase(duplicateAccount.PURE_Organisation_ID__c))) {
                                            // check which has child account and set that as the primary account
                                            if (!listPrimChildAccounts.isEmpty() && listDupChildAccounts.isEmpty()) {
                                                // if the primary account has child accounts
                                                survivingAccountId = mergeAccounts(primaryAcctId, dupAcctId);
                                                strLogMessage = 'Parent Account';
                                            } else if (listPrimChildAccounts.isEmpty() && !listDupChildAccounts.isEmpty()) {
                                                // if the duplicate account has child accounts
                                                survivingAccountId = mergeAccounts(dupAcctId, primaryAcctId);
                                                strLogMessage = 'Parent Account';
                                            } else {
                                                // if both accounts have child account
                                                survivingAccountId = mergeAccounts(primaryAcctId, dupAcctId);
                                                strLogMessage = 'Last Modified Date';
                                            }
                                        } // check which account has the Pure Org ID
                                        else if (String.isBlank(primaryAccount.PURE_Organisation_ID__c) || String.isBlank(duplicateAccount.PURE_Organisation_ID__c)) {
                                            // check which one has the pure org id, and set that as the primary account
                                            if (String.isNotBlank(primaryAccount.PURE_Organisation_ID__c) && String.isBlank(duplicateAccount.PURE_Organisation_ID__c)) {
                                                // if primary account has Pure Org id
                                                survivingAccountId = mergeAccounts(primaryAcctId, dupAcctId);
                                                strLogMessage = 'Pure Organisation Id';
                                            } else if (String.isBlank(primaryAccount.PURE_Organisation_ID__c) && String.isNotBlank(duplicateAccount.PURE_Organisation_ID__c)) {
                                                // if duplicate account has Pure Org id
                                                survivingAccountId = mergeAccounts(dupAcctId, primaryAcctId);
                                                strLogMessage = 'Pure Organisation Id';
                                            }
                                        }
                                        if(survivingAccountId!= null){
                                        Nebula.Logger.info('Surviving Primary Account - Matched by DUNS Number'
                                                + '\n Account hierarchy: ' + strLogMessage
                                                + '\n\n Matching Accounts: '
                                                + '\n' + primaryAccount.Name
                                                + '\n\t Duns: ' + primaryAccount.DBC_DUNS_Number__c
                                                + '\n\t Pure Org Id: ' + primaryAccount.PURE_Organisation_ID__c
                                                + '\n\t Last Modified: ' + primaryAccount.LastModifiedDate
                                                + '\n\n' + duplicateAccount.Name
                                                + '\n\t Duns: ' + duplicateAccount.DBC_DUNS_Number__c
                                                + '\n\t Pure Org Id: ' + duplicateAccount.PURE_Organisation_ID__c
                                                + '\n\t Last Modified: ' + duplicateAccount.LastModifiedDate,
                                                survivingAccountId);
                                            }
                                    } else { // This means account has matching Org Id, Org Type, Org Alt Id, Org ID Type Alt

                                        // additional check to make sure that only same duns with same org identifiers get merged
                                        if(String.isNotBlank(primaryAccount.DBC_DUNS_Number__c) && String.isNotBlank(duplicateAccount.DBC_DUNS_Number__c)
                                                && (!primaryAccount.DBC_DUNS_Number__c.equalsIgnoreCase(duplicateAccount.DBC_DUNS_Number__c))){
                                            // do nothing
                                        } else if(String.isNotBlank(primaryAccount.PURE_Organisation_ID__c) && String.isNotBlank(duplicateAccount.PURE_Organisation_ID__c)
                                                && (!primaryAccount.PURE_Organisation_ID__c.equalsIgnoreCase(duplicateAccount.PURE_Organisation_ID__c))){
                                            // do nothing
                                        }
                                        else {
                                            // if both dont have child accounts
                                            if (listPrimChildAccounts.isEmpty() && listDupChildAccounts.isEmpty()) {
                                                // check which account has the Duns Number or Pure Id, and set that as the primary account
                                                if (String.isNotBlank(primaryAccount.DBC_DUNS_Number__c) && String.isBlank(duplicateAccount.DBC_DUNS_Number__c)) {
                                                    survivingAccountId = mergeAccounts(primaryAcctId, dupAcctId);
                                                    strLogMessage = 'Duns Number';
                                                } else if (String.isNotBlank(duplicateAccount.DBC_DUNS_Number__c)) {
                                                    survivingAccountId = mergeAccounts(dupAcctId, primaryAcctId);
                                                    strLogMessage = 'Duns Number';
                                                } else if (String.isNotBlank(primaryAccount.PURE_Organisation_ID__c) && String.isBlank(duplicateAccount.PURE_Organisation_ID__c)) {
                                                    survivingAccountId = mergeAccounts(primaryAcctId, dupAcctId);
                                                    strLogMessage = 'Pure Organisation Id';
                                                } else if (String.isNotBlank(duplicateAccount.PURE_Organisation_ID__c)) {
                                                    survivingAccountId = mergeAccounts(dupAcctId, primaryAcctId);
                                                    strLogMessage = 'Pure Organisation Id';
                                                } else {
                                                    survivingAccountId = mergeAccounts(primaryAcctId, dupAcctId);
                                                    strLogMessage = 'Last Modified';
                                                }
                                            } else {
                                                // check which has child account and set that as the primary account
                                                if (!listPrimChildAccounts.isEmpty() && listDupChildAccounts.isEmpty()) {
                                                    // if the primary account has child accounts
                                                    survivingAccountId = mergeAccounts(primaryAcctId, dupAcctId);
                                                    strLogMessage = 'Parent Account';
                                                } else if (listPrimChildAccounts.isEmpty() && !listDupChildAccounts.isEmpty()) {
                                                    // if the duplicate account has child accounts
                                                    survivingAccountId = mergeAccounts(dupAcctId, primaryAcctId);
                                                    strLogMessage = 'Parent Account';
                                                } else {
                                                    // if both accounts have child account
                                                    survivingAccountId = mergeAccounts(primaryAcctId, dupAcctId);
                                                    strLogMessage = 'Last Modified Date';
                                                }
                                            }
                                            if(survivingAccountId!= null){
                                                Nebula.Logger.info('Surviving Primary Account - Matched by Org Identifiers'
                                                        + '\n Account hierarchy: ' + strLogMessage
                                                        + '\n\n Matching Accounts: '
                                                        + '\n' + primaryAccount.Name
                                                        + '\n\t Org Identifier: ' + primaryAccount.Organisation_Identifier__c
                                                        + '\n\t Org Identifier Type: ' + primaryAccount.Organisation_Identifier_Type__c
                                                        + '\n\t Org Identifier Alternative: ' + primaryAccount.Organisation_Identifier_Alternative__c
                                                        + '\n\t Org Identifier Type Alternative: ' + primaryAccount.Organisation_Identifier_Type_Alternative__c
                                                        + '\n\t Duns: ' + primaryAccount.DBC_DUNS_Number__c
                                                        + '\n\t Pure Org Id: ' + primaryAccount.PURE_Organisation_ID__c
                                                        + '\n\t Last Modified: ' + primaryAccount.LastModifiedDate
                                                        + '\n\n ' + duplicateAccount.Name
                                                        + '\n\t Org Identifier: ' + duplicateAccount.Organisation_Identifier__c
                                                        + '\n\t Org Identifier Type: ' + duplicateAccount.Organisation_Identifier_Type__c
                                                        + '\n\t Org Identifier Alternative: ' + duplicateAccount.Organisation_Identifier_Alternative__c
                                                        + '\n\t Org Identifier Type Alternative: ' + duplicateAccount.Organisation_Identifier_Type_Alternative__c
                                                        + '\n\t Duns: ' + duplicateAccount.DBC_DUNS_Number__c
                                                        + '\n\t Pure Org Id: ' + duplicateAccount.PURE_Organisation_ID__c
                                                        + '\n\t Last Modified: ' + duplicateAccount.LastModifiedDate,
                                                        survivingAccountId);
                                            }
                                        }
                                    }
                                    // collate account thar are already merged to the surviving account
                                    if (!primaryAcctId.equals(survivingAccountId)) {
                                        setMergedAccountIds.add(primaryAcctId);
                                    }
                                    if (!dupAcctId.equals(survivingAccountId)) {
                                        setMergedAccountIds.add(dupAcctId);
                                    }
                                }

                                // reparent child accounts
                                if(survivingAccountId != null){
                                    for (Account acct : reparentChildAccounts(survivingAccountId, listDupChildAccounts)) {
                                        if (!acctIdToUpdate.contains(acct.Id)) {
                                            listChildAccountsToUpdate.add(acct);
                                            acctIdToUpdate.add(acct.Id);
                                        }
                                    }
                                }
                            }
                        }
                        // reparent child accounts
                        if(survivingAccountId != null) {
                            for (Account acct : reparentChildAccounts(survivingAccountId, listPrimChildAccounts)) {
                                if (!acctIdToUpdate.contains(acct.Id)) {
                                    listChildAccountsToUpdate.add(acct);
                                    acctIdToUpdate.add(acct.Id);
                                }
                            }
                        }
                    }
                }
                if(!listChildAccountsToUpdate.isEmpty()){
                    Database.update(listChildAccountsToUpdate);
                }
            }catch(Exception e) {
                Nebula.Logger.error('Line number ' + e.getLineNumber() + ' - ' + e.getMessage() + ' - ' + e.getStackTraceString());
            }
            // Log the exceptions
            Nebula.Logger.saveLog();
        }
    }

    /**
    * @description reparent child accounts
    * @param survivingAccountId merged primary account id
    * @param listChildAccounts List of child accounts
    * @return  List<Account> listChildAccountsToUpdate
    * @revision     20/3/2024     Angelo Rivera       Initial Creation
    */
    public static List<Account> reparentChildAccounts(Id survivingAccountId, List<Account> listChildAccounts){
        List<Account> listChildAccountsToUpdate = new List<Account>();
        List<Account> listTempChildAccounts = new List<Account>();
        Set<Id> acctId = new Set<Id>();

        if(!listChildAccounts.isEmpty()){
            for(Account acc : listChildAccounts){
                if(!acctId.contains(acc.Id)) {
                    if (acc.ParentId != survivingAccountId || acc.ParentId == null) {
                        acc.ParentId = survivingAccountId;
                        Nebula.Logger.info('Re-parenting Child Account - Surviving Account: ' + survivingAccountId, acc.Id);
                        listChildAccountsToUpdate.add(acc);
                        acctId.add(acc.Id);
                    }
                }
            }
        }
        return listChildAccountsToUpdate;
    }

    /**
    * @description Merge Accounts
    * @param primaryAccountId primary account id
    * @param duplicateAccountId duplicate Account id
    * @return primaryAccountId
    * @revision     1/2/2024     Angelo Rivera       Initial Creation
    */
    public static Id mergeAccounts(Id primaryAccountId, Id duplicateAccountId) {
        Boolean hasLockRow = false;
        Boolean ownerUpdated= false;
        Id previousOwnerId;
        Account primaryAccount = new Account();
        Account duplicateAccount = new Account();
        Set<Id> s_allAccountIds = new Set<Id>{primaryAccountId, duplicateAccountId};
        Map<Id, Account> accountMap;

        accountMap = new Map<Id, Account>((List<Account>) AccountMergeController.queryAllObjectFields(s_allAccountIds));
        try{
            primaryAccount = accountMap.get(primaryAccountId);
            if(primaryAccount != null) {
                previousOwnerId = primaryAccount.OwnerId;
                duplicateAccount = accountMap.get(duplicateAccountId);
                if (duplicateAccount != null) {
                    // Before merging, perform mapping of surviving fields through iteration of custom metadata
                    primaryAccount = AccountMergeController.mapCompareAccount(primaryAccount, duplicateAccount);
                    if (previousOwnerId != primaryAccount.OwnerId) {
                        ownerUpdated = true;
                    } else {
                        previousOwnerId = duplicateAccount.OwnerId;
                    }
                    performMerge(primaryAccount, duplicateAccount, ownerUpdated, primaryAccount.OwnerId, previousOwnerId);
                }
            }
        }catch(Exception e) {
            hasLockRow = e.getMessage().contains('UNABLE_TO_LOCK_ROW');
            if(hasLockRow == false){
                Nebula.Logger.error(e.getMessage());
            }else{
                //Implement a retry as possible for Locking due to same parent roll up  delays
                Nebula.Logger.error('Has Lock Row Error:' + primaryAccount + ' - ' + duplicateAccount + '. Running merge again.');
                // Merge the Account
                performMerge(primaryAccount, duplicateAccount, ownerUpdated, primaryAccount.OwnerId, previousOwnerId);
            }
        }
        Nebula.Logger.saveLog();
        return primaryAccountId;
    }

    /**
    * @description performs merge
    * @param primaryObj Set<Id>  set of account ids
    * @param dupObj String duplicate rule name
    * @param ownerUpdated String duplicate match rule name
    * @param newOwnerId String duplicate match rule name
    * @param previousOwnerId String duplicate match rule name
    * @revision     1/2/2024     Angelo Rivera       Initial Creation
    */
    private static void performMerge(SObject primaryObj, SObject dupObj, Boolean ownerUpdated, Id newOwnerId, Id previousOwnerId) {
        try {
            if(primaryObj != null && dupObj != null) {
                Id pId = primaryObj?.Id;
                Id dId = dupObj?.Id;
                Map<Id, List<AccountTeamMember>> m_relatedTeamMembers = AccountMergeController.getTeamMembers(pId, dId);
                Map<Id, List<TopicAssignment>> m_relatedTopicAssignments = AccountMergeController.getRelatedTopics(pId, dId);
                if(pId != dId && pId != null && dId != null) {
                    Database.merge(primaryObj, new List<SObject> {dupObj}, true);
                    // Upsert on Account Team members based on Scenarios (Owner update, no Owner Update)
                    if(!m_relatedTeamMembers.isEmpty()){
                        if(ownerUpdated){
                            // If owner is updated then the Members get Deleted and need to be re-Inserted
                            AccountMergeController.checkAndReInsertAccountTeamMembers(pId, dId, m_relatedTeamMembers, newOwnerId, previousOwnerId);
                        }else{
                            // If owner is not-updated , the losing Owner of the Duplicate record needs to be added as a Team member
                            AccountMergeController.updateSecondaryAccountTeamMembers(pId, dId, m_relatedTeamMembers, newOwnerId, previousOwnerId);
                        }
                    }
                    // Insert on Topic Assignments
                    if(!m_relatedTopicAssignments.isEmpty()){
                        // After merge the TopicAssignments are to be re-linked to Surviving Account
                        AccountMergeController.checkAndReInsertTopicAssignments(pId, dId, m_relatedTopicAssignments, newOwnerId, previousOwnerId);
                    }
                }
            }
        } catch(Exception e) {
            Nebula.Logger.error(e.getMessage());
            Nebula.Logger.saveLog();
        }
    }

    /**
    * @description Finds duplicate accounts
    * @param set_acctIds Set<Id>  set of account ids
    * @param duplicateRuleName String duplicate rule name
    * @param duplicateMatchRuleName String duplicate match rule name
    * @return set_duplicateResultContactIds
    * @revision     1/2/2024     Angelo Rivera       Initial Creation
    */
    public static Set<Id> findDuplicateAccounts(Set<Id> set_acctIds, String duplicateRuleName, String duplicateMatchRuleName ) {
        List<Id> list_acctIds = new List<Id>(set_acctIds);
        Set<Id> set_duplicateResultAcctIds = new Set<Id>();
        // Check for Perfect Match
        Datacloud.FindDuplicatesResult[] perfectMatchResults = Datacloud.FindDuplicatesByIds.findDuplicatesByIds(list_acctIds);

        for (Datacloud.FindDuplicatesResult findDupeResult : perfectMatchResults) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                if (dupeResult.getDuplicateRule().equals(duplicateRuleName)) {
                    for (Datacloud.MatchResult matResults : dupeResult.getMatchResults()) {
                        if (matResults.getRule().equals(duplicateMatchRuleName) && matResults.getMatchRecords() != null && matResults.getMatchRecords().size() > 0) {
                            for (Datacloud.MatchRecord matchRec : matResults.getMatchRecords()) {
                                Account acct = (Account) matchRec.getRecord();
                                if (acct != null && acct.Id != null) {
                                    set_duplicateResultAcctIds.add(acct.Id);
                                }
                            }
                        }
                    }
                }
            }
        }
        return set_duplicateResultAcctIds;
    }

    global void finish(Database.BatchableContext BC) {
    }

    global void execute(SchedulableContext sc) {
        Id batchJobId = Database.executeBatch(new BatchAccountMerge(), 10);
    }

}