/**
 * @description       : Services class to provide Account sObject centric logical support
 * @author            : Carl Vescovi
 * @group             : Service
 * @last modified on  : 2021-01-21
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.3   2021-10-06   Vinothraja      Added methods & Inner Class to update & remove Partner Team Members
 * 1.2   2021-01-21   Stefan Scheit   Added External_Organisation & Monash_Organisation
 * 1.1   2020-10-16   Stefan Scheit   Updated ACCOUNT_INDIVIDUAL_TYPE to hold value "Household_Account"
 * 1.0   20??-??-??   Carl Vescovi    Initial Version
**/
public with sharing class AccountServices {
    
    /** TODO: rename from ACCOUNT_INDIVIDUAL_TYPE to ACCOUNT_HOUSEHOLD_TYPE */
    public static final String ACCOUNT_INDIVIDUAL_TYPE = 'Household_Account'; // record type (developer name) used for household accounts
    public static final String ACCOUNT_EXTERNAL_ORGANISATION = 'External_Organisation'; // record type (developer name) used for (external) organisations
    public static final String ACCOUNT_MONASH_ORGANISATION = 'Monash_Organisation'; // record type (developer name) used for (internal) Monash organisations or units
    public static final String ACCOUNT_ORGANISATION_TYPE = 'Organization';    // record type (developer name) used for organisations (deprecated)   
    
    /**
     * @description Creates a new Account Team Member with the specified role, or updates his role if he is an existing Team member
     *
     * @param userId (Id): User ID of the Account Team Member
     * @param accountId (Id): Account to which the Team member to be added
     * @param acctTeamRole (String): Team Member's Role
     * @author            : Vinothraja
     * revision 
     * Ver   Date           Author          Modification
     * 1.0   2021-10-04     Vinothraja      Created // SFTG-2170
     */
    @future
    public static void upsertPartnerRole(Id userId, Id accountId, String acctTeamRole) {
        if (String.isNotBlank(userId) && String.isNotBlank(accountId) && String.isNotBlank(acctTeamRole)) {
            Map<Id, AccountTeamMember> updateATM = new Map<Id, AccountTeamMember> ();
            // Update Team Member
            // Demote existing Primary Account Holder (PAH) to Delegated Admin User(DAU), when a new PAH is selected
            for (AccountTeamMember atm : (List<AccountTeamMember>) new CommitQueryRecords().queryRecords('SELECT id, UserId, AccountId, TeamMemberRole' 
                                                                    + ' FROM AccountTeamMember'
                                                                    + ' WHERE AccountId = \'' + accountId +'\'')) {
                if (atm.UserId == userId) {
                    atm.TeamMemberRole = acctTeamRole; // Update Team member role, if user exists
                    updateATM.put(atm.UserId, atm);
                }
                if (acctTeamRole.equalsIgnoreCase(AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER) 
                                && acctTeamRole.equalsIgnoreCase(atm.TeamMemberRole) 
                                && atm.UserId != userId) {
                    atm.TeamMemberRole = AccountTeamConstants.PARTNER_ROLE_DELEGATED_ADMIN; // demote the existing PAH User to DAU    
                    updateATM.put(atm.UserId, atm);
                }
            }
            // Insert Team Member 
            if (!updateATM.containsKey(userId)) {
                updateATM.put(userId, new AccountTeamMember(UserId = userId, AccountId = accountId, TeamMemberRole = acctTeamRole));
            }
            try {
                new CommitQueryRecords().upsertATMRecords(updateATM.values());
            } catch (Exception e) {
                LogUtilityException.LogException(e);
            }
        }

    }
    /**
     * @description Removes a User(Account Team Member) from the Account
     *
     * @param userId (Id): Write the parameter description
     * @param accountId (Id): Write the parameter description
     * @author            : Vinothraja
     * revision 
     * Ver   Date           Author          Modification
     * 1.0   2021-10-04     Vinothraja      Created // SFTG-2170 
     */
    @future
    public static void removePartnerRole(Id userId, Id accountId) {
         if (String.isNotBlank(userId) && String.isNotBlank(accountId)) {
            List<AccountTeamMember> lstATM = (List<AccountTeamMember>) new CommitQueryRecords().queryRecords('SELECT id, UserId, AccountId FROM AccountTeamMember WHERE UserId = \'' + userId + '\' AND AccountId = \'' + accountId +'\' LIMIT 1');
            if (!lstATM.isEmpty()) {
                try {
                    new CommitQueryRecords().deleteATMRecords(lstATM);
                } catch (Exception e) {
                    LogUtilityException.LogException(e);
                }
            }
        }

    }

    /**
     * @description       : Inner class for committing and querying records
     * @author            : Vinothraja
     * revision 
     * Ver   Date           Author          Modification
     * 1.0   2021-10-04     Vinothraja      Created // SFTG-2170
     */
    @TestVisible
    private without sharing class CommitQueryRecords {
        /**
         * @author      Vinothraja
         * @description Method that commits the record to database in without sharing context
         */
        public List<Object> queryRecords(String queryString){
            return Database.query(queryString);
        }

        /**
         * @author      Vinothraja
         * @description Method that commits the record to database in without sharing context
         */
        public void upsertATMRecords(List<AccountTeamMember> commitRecords){
            upsert commitRecords;
        }
        /**
         * @author      Vinothraja
         * @description Method that commits the record to database in without sharing context
         */
        public void deleteATMRecords(List<AccountTeamMember> commitRecords){
            delete commitRecords;
        }
    }
}