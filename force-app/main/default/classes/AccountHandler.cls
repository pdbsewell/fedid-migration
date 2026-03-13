/**
 * @description       : Trigger Handler to manage all DML and events on Account
 * @author            : Kristian Vegerano
 * @group             : Trigger Handler
 * @last modified on  : 2024-04-17
 * @last modified by  : Sachin Shetty
 * Modifications Log 
 * Date         Author          Modification
 * 2023-04-30 - Seeva Singh - Added PopulateAccountRecordTypeNameOnContact logic to populate account recordtype name on contact if the account record type changes
 * 2022-06-30 - Stefan Scheit - Added HandleDunBradstreetElements handler logic
 * 2021-11-08 - Inderpal Dhanoa -- Added syncHierarchyLevel to show the Hierarchy of the related School/Faculty
 * 2021-04-08 - Stefan Scheit - Updated HandleExternalOrganisation handler to include Industry classification field population
 * 2021-03-09 - Stefan Scheit - Updated HandleExternalOrganisation handler to exclude Accounts of type "Estate" from DnB
 * 2021-03-02 - Kristian Vegerano - Automate partner agreement creation on partner account insert
 * 2021-02-12 - Kristian Vegerano - Move the account owners of the applicant's account owner to the owner of the running partner user whenever an application is initiated by a partner
 * 2021-02-10 - Stefan Scheit - Bulkified UpdateAccountTeamMemberForPRM, simplified code, and removed potential null pointer exception
 * 2021-02-02 - Steffi Narang - Added createAccountTeamMemberforPRM to create a Account Team Member if Account PRM is updated ENGAGEIE-621
 * 2021-01-21 - Stefan Scheit - Updated HandleExternalOrganisation handler to default DnB Optimizer field for "External Organisation" Account records
 * 2020-09-21 - Stefan Scheit - Updated HandleExternalOrganisation handler to only include changed records
 * 2019-05-17 - Kristian Vegerano - Added UpdateSubmissionLocationCountry that will update all the agency's applications on shipping country change
 * 2024-04-10 - Sachin Shetty - Added UpdatePhoneWithDialingCode that updates Phone field with International Dialing Code and other phone
 * 2024-04-17 - Sachin Shetty - Update to point to DBConnect fields
**/
public with sharing class AccountHandler {

    public static Map<Id,Schema.RecordTypeInfo> rtMap {
       get {
           if (rtMap == null) {
               rtMap = Account.sobjectType.getDescribe().getRecordTypeInfosById();
           }
           return rtMap;
       }
       set;
    }
    public static boolean RecordtypeUpdatedByAccountTrigger = false;
    /**
     * @author      Kristian Vegerano
     * @description Move the account owners of the applicant's account owner to the owner of the running partner user whenever an application is initiated by a partner
     * @revision    03/02/2021 - Kristian Vegerano - Created
     */
    public class CorrectPartnerOwner extends TriggerAbstract {

        /**
        * Handle after update event checking and filtering
        */
        public override void process(SObject record, SObject oldRec) {
            //Process all accounts
            records.add(record);
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
            Set<Id> accountOwnerIds = new Set<Id>();
            for(Account contextAccount : (List<Account>)records){
                accountOwnerIds.add(contextAccount.OwnerId);
            }

            //reassociate account's owner
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Profile.Name, Contact.Account.OwnerId FROM User WHERE Id IN :accountOwnerIds]);
            for(Account contextAccount : (List<Account>)records){
                if(userMap.containsKey(contextAccount.OwnerId)){
                    if(userMap.get(contextAccount.OwnerId).Profile.Name == Constants.PARTNER_USER_PROFILE){
                        if(!Test.isRunningTest()){
                            contextAccount.OwnerId = userMap.get(contextAccount.OwnerId).Contact.Account.OwnerId;
                        }
                    }
                }
            }
        }
    }
	
	/*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         8.Sep.2021
     * @description  Update related application's Pure Id based on DUNS Number
     * @Revision     2024-04-17 - Sachin Shetty - Update to point to DBConnect fields
     *******************************************************************************/
    public class SyncDUNSNumbrToOppty extends TriggerAbstract {
        /**
        * Handle after update event checking and filtering
        */
       
        Set<Id> s_accountIds = new Set<Id>();

        public override void process(SObject record) {
            //Start process
            Account contextAccount = (Account)record;
            if((rtMap.get(contextAccount.RecordTypeId).getDeveloperName() == 'Monash_Organisation' || rtMap.get(contextAccount.RecordTypeId).getDeveloperName() == 'External_Organisation') && 
            String.isNotBlank(contextAccount.DBC_DUNS_Number__c)){
                records.add(record);
                s_accountIds.add(contextAccount.Id);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            //Start process
            Account contextAccount = (Account)record;
            Account contextOldAccount = (Account)oldRec;
            //Check account's recordtype if agency
            if((rtMap.get(contextAccount.RecordTypeId).getDeveloperName() == 'Monash_Organisation' || rtMap.get(contextAccount.RecordTypeId).getDeveloperName() == 'External_Organisation') &&
                contextAccount.DBC_DUNS_Number__c != contextOldAccount.DBC_DUNS_Number__c){

                records.add(record);
                s_accountIds.add(contextAccount.Id);
            }
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                Map<Id,List<Opportunity>> m_AccountIdRelatedOppty = linkOppWithAccount(s_accountIds);
                List<Opportunity> l_syncRelatedOppty = new List<Opportunity>();
                for(SOBJECT record : records){
                    Account contextAccount = (Account)record;
                    if(m_AccountIdRelatedOppty != null && m_AccountIdRelatedOppty.containsKey(contextAccount.Id)){
                        for(Opportunity opp : m_AccountIdRelatedOppty.get(contextAccount.Id)){
                            // If the updated Account has DUNS number then update the Oppty's Pure Id else Reset the Pure Id
                            if(String.isNotBlank(contextAccount.DBC_DUNS_Number__c)){
                                opp.Pure_ID__c = opp.PURE_Application_ID__c + contextAccount.DBC_DUNS_Number__c;
                            }else{
                                opp.Pure_ID__c = '';
                            }                            
                            l_syncRelatedOppty.add(opp);
                        }
                    }
                }
                if(!l_syncRelatedOppty.isEmpty()){
                    try {
                        update l_syncRelatedOppty;
                    } catch (Exception e) {
                        LogUtilityException.logException(e,'AccountHandler.SyncDUNSNumbrToOppty');
                    }
                }
            }
        }

        public Map<Id,List<Opportunity>> linkOppWithAccount(Set<Id> s_accountIds){
            Id enterpriseRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
            Map<Id,List<Opportunity>> m_AccountIdRelatedOppty = new Map<Id,List<Opportunity>>();
            for(Opportunity oppty : [SELECT Id, PURE_Application_ID__c, AccountId, Pure_ID__c 
                                    FROM Opportunity 
                                    WHERE RecordTypeId = :enterpriseRecordTypeId AND AccountId in :s_accountIds AND 
                                    (PURE_Application_ID__c != null OR PURE_Application_ID__c != '')]){
                List<Opportunity> l_relatedOppty;
                if(m_AccountIdRelatedOppty.containsKey(oppty.AccountId)){
                    l_relatedOppty = m_AccountIdRelatedOppty.get(oppty.AccountId);
                }else{
                    l_relatedOppty = new List<Opportunity>();    
                }
                l_relatedOppty.add(oppty);
                m_AccountIdRelatedOppty.put(oppty.AccountId,l_relatedOppty);
            }
            return m_AccountIdRelatedOppty;
        }
    }
	
	/**
     * @author      Inderpal Dhanoa
     * @description Added syncHierarchyLevel to show the Hierarchy of the related School/Faculty based on syncing from SAP, 
     *              This Handler cannot cater to scenarios where New Parent and New child Accounts are added in the same transaction 
     * @revision    08/11/2021 - Inderpal Dhanoa - Created
     */
    public class SyncHierarchyLevel extends TriggerAbstract {

        /**
        * Handle after update event checking and filtering
        */

        Map<Id, Account> m_idLinkedAccount = new Map<Id, Account>();
        List<Account> lAllOrgs = new List<Account>();

        public override void process(SObject record) {
            //Start process
            Account contextAccount = (Account)record;
            if((rtMap.get(contextAccount.RecordTypeId).getDeveloperName() == 'Monash_Organisation' || rtMap.get(contextAccount.RecordTypeId).getDeveloperName() == 'Faculty') && 
                contextAccount.ParentId != null){     
                records.add(record);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            Account contextNewAccount = (Account)record;
            Account contextOldAccount = (Account)oldRec;
            if((rtMap.get(contextNewAccount.RecordTypeId).getDeveloperName() == 'Monash_Organisation' || rtMap.get(contextNewAccount.RecordTypeId).getDeveloperName() == 'Faculty') && 
                contextNewAccount.ParentId != contextOldAccount.ParentId){     
                records.add(record);
            }
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                List<Async_Process__e> eventsToPublish = new List<Async_Process__e>();
                for(Account accRec : (List<Account>)records){
                    Async_Process__e evt = AccountHelper.createPayload(accRec.Id);
                    eventsToPublish.add(evt);
                }
                if(!eventsToPublish.isEmpty()) {
                    EventBus.publish(eventsToPublish);
                }
            }
        }
    }


    /**
     * @author      Kristian Vegerano
     * @description Create a single partner agreement whenever a partner account is created
     * @revision    03/02/2021 - Kristian Vegerano - Created
     */
    public class CreatePartnerAgreement extends TriggerAbstract {

        /**
         * Handle after update event checking and filtering
         */
        public override void process(SObject record, SObject oldRec) {            
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

            // Filter out partner accounts
            for(Account contextAccount : (List<Account>)records){                
                // Create a partner agreement for partner accounts
                if(contextAccount.RecordTypeId == partnerRecordTypeId){
                    records.add(record);
                }
            }            
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
            List<Partner_Agreement__c> partnerAgreementList = new List<Partner_Agreement__c>();
            
            for(Account contextAccount : (List<Account>)records){   
                partnerAgreementList.add(new Partner_Agreement__c(Partner_Account__c = contextAccount.Id));
            }

            // Insert partner agreements if there are 
            if(!partnerAgreementList.isEmpty()){
                insert partnerAgreementList;
            }
        }
    }
    
    /*******************************************************************************
     * @author       Steffi
     * @date         2021-02-02
     * @description  Update Account Team Member when Account PRM is set or updated (ENGAGEIE-621)
     *******************************************************************************/
    public class UpdateAccountTeamMemberForPRM extends TriggerAbstract {

        public override void process(SObject record, SObject oldRec) {
            Account newAccountRec = (Account)record;
            Account oldAccountRec = (Account)oldRec;
            // check if PRM field is changed
            if(newAccountRec.ucinn_ascendv2__PRM__c != oldAccountRec.ucinn_ascendv2__PRM__c){
                records.add(record);
            }
        }
        /**
        * Run functionality logic
        */
        public override void execute() {   
            Account acct = null;
            Map<Id, Account> oldAccountMap = (Map<Id, Account>)Trigger.oldMap;
            List<AccountTeamMember> accMemberLst = new List<AccountTeamMember>();
            List<AccountTeamMember> accDeleteLst  = new List<AccountTeamMember>();
            set<Id>  accountIdsforDeletion = new set<Id>();
            try{
                for(sObject loopRecord : records) {
                    acct = (Account)loopRecord;
                    // new Account has a PRM set, need to create a new (PRM) Account Team Member record
                    if(acct.ucinn_ascendv2__PRM__c != null) {
                        accMemberLst.add(createAccountTeamPRM(acct.ucinn_ascendv2__PRM__c, acct.id)); 
                    }
                    // old Account had a (different) PRM set, condition from process(), need to delete old (PRM) Account Team Member record
                    if(oldAccountMap != null && oldAccountMap.get(acct.Id)?.ucinn_ascendv2__PRM__c != null) {
                        accountIdsforDeletion.add(acct.id);
                    }
                }
                // delete old (PRM) account members first
                if(!accountIdsforDeletion.isEmpty()){
                    accDeleteLst.addAll(getAccountTeamPRM(accountIdsforDeletion));
                    if(!accDeleteLst.isEmpty()){
                      delete accDeleteLst;
                    }
                }
                // then, create new (PRM) account team members
                if(!accMemberLst.isEmpty()){
                    insert accMemberLst;
                }
            }catch(exception e){
                LogUtilityException.LogException(e);
            }
        }
        // Create the AccountTeamMember record if Account PRM field
        private AccountTeamMember createAccountTeamPRM(Id UserId, Id accId) {
               AccountTeamMember acc = new AccountTeamMember();
           try{
               acc.AccountAccessLevel =AccountTeamConstants.EDIT;
               acc.CaseAccessLevel= AccountTeamConstants.CASE_PRIVATE;
               acc.ContactAccessLevel = AccountTeamConstants.EDIT;
               acc.OpportunityAccessLevel  = AccountTeamConstants.READ;
               acc.UserId = UserId;
               acc.AccountId = accId;
               acc.TeamMemberRole =AccountTeamConstants.PRM;
            }catch(exception e){
                LogUtilityException.LogException(e);
            }
            return acc;
        }
        // Method to return a list of (PRM) AccountTeamMember records for a set of Account Ids
        private List<AccountTeamMember> getAccountTeamPRM(Set<Id> accIds) {
            List<AccountTeamMember> acctTeamMemberDeleteList = new List<AccountTeamMember>();
            try{
                acctTeamMemberDeleteList = [SELECT id,accountId,TeamMemberRole FROM AccountTeamMember WHERE accountId IN :accIds AND TeamMemberRole = :AccountTeamConstants.PRM];
            }catch(Exception e){
                LogUtilityException.LogException(e);
            }
            return acctTeamMemberDeleteList;
        }
    }
    
    /*******************************************************************************
     * @author       Kristian Vegerano
     * @date         17.May.2019
     * @description  Update agency's related application's submission location country when the agency's shipping country is changed
     *******************************************************************************/
    public class UpdateSubmissionLocationCountry extends TriggerAbstract {

        /**
        * Handle after update event checking and filtering
        */
        public override void process(SObject record, SObject oldRec) {
            //Start process
            Account contextAccount = (Account)record;
            Account contextOldAccount = (Account)oldRec;

            //Check account's recordtype if agency
            if(contextAccount.RecordTypeId == AccountUtility.ACCOUNT_AGENCY_REC_TYPE){
                //Check shipping country change
                if(contextAccount.ShippingCountry != contextOldAccount.ShippingCountry){
                    records.add(record);
                }
            }
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                //Retrieve filtered contact ids
                Set<Id> accountIds = new Set<Id>();
                for(SObject loopRecord : records){
                    Account contextAccount = (Account)loopRecord;
                    accountIds.add(contextAccount.Id);
                }

                //Retrieve related applications of the filtered account ids
                Map<Id, Application__c> childApplicationsMap = new Map<Id, Application__c>(new ApplicationsSelector().selectByAgencyId(accountIds));

                ApplicationHelper appHelper = new ApplicationHelper();
                appHelper.executeUpdateSubmissionLocationCountry(childApplicationsMap);
            }
        }
    }

    /*******************************************************************************
     * @author       Ajitabh
     * @date         2020-09-15
     * @description  Prepopulate Account fields based on record type (and its change)
     * @revision     2021-01-20 - Stefan Scheit - added logic for "External Organisation" record type
     *               2021-03-15 - Stefan Scheit - updated logic to handle Accounts of type "Estate"
     *               2021-04-08 - Stefan Scheit - added logic to populate industry classification fields
     *******************************************************************************/
    public class HandleExternalOrganisation extends TriggerAbstract {

        /**
        * No filtering for inserts
        */
        public override void process(SObject newRecord) {
            // new records always have to be processed 
            records.add(newRecord);
        }

        /**
        * Filter updated records, mainly so they aren't processed by other trigger handlers.
        */
        public override void process(SObject newRecord, SObject oldRecord) {
            if(
                // if record type has changed 
                CommonUtilities.fieldHasChanged(String.valueOf(Account.RecordTypeId), newRecord, oldRecord)
                ||
                // OR Account.Type has changed from or to the value 'Estate'
                (CommonUtilities.fieldHasChanged(String.valueOf(Account.Type), newRecord, oldRecord) && (((Account)newRecord).Type == 'Estate' || ((Account)oldRecord).Type == 'Estate'))
                ||
                // OR industry classification field has changed
                CommonUtilities.fieldHasChanged(String.valueOf(Account.Sic), newRecord, oldRecord)
            ) {
                // add records
                records.add(newRecord);
            }
        }

        /**
        * Run functionality logic
        */
        public override void execute() {   
            Account acct = null;
            
            for(Sobject loopRecord : records) {
                acct = (Account)loopRecord;

                // 1. ALWAYS set record type text field (used in matching/duplication rules)
                acct.Record_Type_Dup__c = rtMap.get(acct.RecordTypeId).getDeveloperName();

                // 2. Update the industry classification fields (Industry Division & Industry Major Groups), if Sic field is populated (at least 2 characters)
                if(String.isNotBlank(acct.Sic) && acct.Sic.length()>1) {
                    acct.Industry = acct.Sic.left(2); // assign first 2 characters
                    acct.SIC_Division__c = getSicDivision(acct.Industry);
                } else {
                    // remove the values based on a blank/invalid SIC value
                    acct.SIC_Division__c = '';
                    acct.Industry = '';
                }
                
                // 3. Set field to indicate if DnB Optimizer data integration rules can match the account record (record type is 'Record is an 'External_Organisation' AND not of type 'Estate'
                if(AccountServices.ACCOUNT_EXTERNAL_ORGANISATION.equalsIgnoreCase(acct.Record_Type_Dup__c) && (acct.Type != 'Estate')) {
                    acct.LD_USE_DnB_Optimize__c = true;
                } else {
                    acct.LD_USE_DnB_Optimize__c = false;
                }
            }
        }

        /*******************************************************************************
         * @author       Stefan Scheit
         * @date         2021-04-08
         * @description  Derive the SIC division from the SIC major industry group (2 digit code) as per https://siccode.com/
         *******************************************************************************/
        private String getSicDivision(String sicMajorGroupCode) {
            
            // parse input into integer
            Integer groupCode = 0;
            try {
                groupCode = Integer.valueOf(sicMajorGroupCode);
            } catch(Exception exc) {
                LogUtilityException.logExceptionMSG(String.valueOf(AccountHandler.class), sicMajorGroupCode , 'Cannot convert SIC value of '+sicMajorGroupCode+' into a SIC division due to error: '+exc.getMessage());
                return '';
            }

            // derive division from the SIC major group (2 digit code)
            if(groupCode < 10) {
                return 'A'; // Agriculture, Forestry, And Fishing
            }
            if(groupCode < 15) {
                return 'B'; // Mining
            }
            if(groupCode < 20) {
                return 'C'; // Construction
            }
            if(groupCode < 40) {
                return 'D'; // Manufacturing
            }
            if(groupCode < 50) {
                return 'E'; // Transportation, Communications, Electric, Gas, And Sanitary Services
            }
            if(groupCode < 52) {
                return 'F'; // Wholesale Trade
            }
            if(groupCode < 60) {
                return 'G'; // Retail Trade
            }
            if(groupCode < 70) {
                return 'H'; // Finance, Insurance, And Real Estate
            }
            if(groupCode < 90) {
                return 'I'; // Services
            }
            if(groupCode <= 99) {
                return 'J'; // Public Administration
            }
            return ''; // default return
        }
    }

    /*******************************************************************************
     * @author       Stefan Scheit
     * @date         2022-06-30
     * @description  Set (or unset) fields in relation to Dun & Bradstreet componay information
     * @revision     2022-06-30 - Stefan Scheit - Initial version
     *               2024-04-17 - Sachin Shetty - Update to point to DBConnect fields
     *******************************************************************************/
    public class HandleDunBradstreetElements extends TriggerAbstract {

        /**
        * Filter inserted records
        */
        public override void process(SObject newRecord) {
            // field 'DUNS number' is empty, but 'DnBCompanyRecord' lookup field is not empty (very unlikely) 
            Account newAccount = (Account)newRecord;
            if(String.isBlank(newAccount.DBC_DUNS_Number__c) && newAccount.DNBConnect__D_B_Connect_Company_Profile__c != null) {
                records.add(newRecord);
            }
        }

        /**
        * Filter updated records, mainly so they aren't processed by other trigger handlers.
        */
        public override void process(SObject newRecord, SObject oldRecord) {
            Account newAccount = (Account)newRecord;
            if(
                // field 'DUNS number' is empty, but 'DnBCompanyRecord' lookup field is not empty (very unlikely)
                (String.isBlank(newAccount.DBC_DUNS_Number__c) && newAccount.DNBConnect__D_B_Connect_Company_Profile__c != null)
                ||
                // field 'DUNS number' has changed, but 'DnBCompanyRecord' lookup field has not
                (CommonUtilities.fieldHasChanged(String.valueOf(Account.DBC_DUNS_Number__c), newRecord, oldRecord) 
                    && !CommonUtilities.fieldHasChanged(String.valueOf(Account.DNBConnect__D_B_Connect_Company_Profile__c), newRecord, oldRecord))
            ) {
                // add records
                records.add(newRecord);
            }
        }

        /**
        * Run functionality logic
        */
        public override void execute() {   
            Account acct = null;
            
            for(Sobject loopRecord : records) {
                acct = (Account)loopRecord;

                // blank out DnBCompanyRecord lookup field
                acct.DNBConnect__D_B_Connect_Company_Profile__c = null;
            }
        }
    }
    
    /*******************************************************************************
     * @author       Sachin Shetty
     * @date         2024-04-10
     * @description  Update Phone field with International Dialing Code and Other Phone
     * @revision     2024-04-10 - Sachin Shetty - Initial version
     *******************************************************************************/
    public class UpdatePhoneWithDialingCode extends TriggerAbstract {

        /**
        * Filter updated records, mainly so they aren't processed by other trigger handlers.
        */
        public override void process(SObject newRecord, SObject oldRecord) {
            Account newAccount = (Account)newRecord;
            if(
                // field 'International Dialing Code' or 'Other Phone' has changed
                (CommonUtilities.fieldHasChanged(String.valueOf(Account.international_dialing_code__c), newRecord, oldRecord) ||
                CommonUtilities.fieldHasChanged(String.valueOf(Account.other_phone__c), newRecord, oldRecord))
            ) {
                // add records
                records.add(newRecord);
            }
        }

        /**
        * Run functionality logic
        */
        public override void execute() {   
            Account acct = null;
            
            for(Sobject loopRecord : records) {
                acct = (Account)loopRecord;

                acct.Phone = '';
                if(!String.isBlank(acct.other_phone__c)){
                	acct.Phone = acct.other_phone__c;

                    if(!String.isBlank(acct.international_dialing_code__c)){
                        acct.Phone = '+' + acct.international_dialing_code__c + ' ' + acct.other_phone__c;
                    }
                }
            }
        }
    }
    
/*******************************************************************************
    * @author       Seeva Singh
    * @date         2023-04-30
    * @description  Update Account Record Type Name on Contact
    * @revision     2023-04-30 - Seeva Singh - Initial version
    *******************************************************************************/
    public class PopulateAccountRecordTypeNameOnContact extends TriggerAbstract {
        /**
        * Filter updated records, mainly so they aren't processed by other trigger handlers.
        */
        public override void process(SObject newRecord, SObject oldRecord) {
            Account newAccount = (Account)newRecord;
            Account oldAccount = (Account)oldRecord;           
            if((rtMap.get(newAccount.RecordTypeId).getDeveloperName() == 'Household_Account' && rtMap.get(oldAccount.RecordTypeId).getDeveloperName() != 'Household_Account') || 
            (rtMap.get(newAccount.RecordTypeId).getDeveloperName() != 'Household_Account' && rtMap.get(oldAccount.RecordTypeId).getDeveloperName() == 'Household_Account') ) {
                records.add(newRecord);
            }
        }
        
        /**
        * Run functionality logic
        */
        public override void execute() {
            List<Contact> contactListtoUpdate = new List<Contact>();
            Map<Id,Account> householdAccountMap = new Map<Id,Account>([SELECT id,recordtype.developername FROM account WHERE id IN:records]);
            if(!records.isempty()) {
                List<Contact> contactList = new List<Contact>([SELECT id,accountID,Account_Record_Type_Name__c FROM Contact WHERE accountId IN:records]);
                for(Contact conObj : contactList) {
                    if(householdAccountMap.containsKey(conObj.accountID)) {
                        if(householdAccountMap.get(conObj.accountID).recordtype.developername == 'Household_Account') {
                            conObj.Account_Record_Type_Name__c = householdAccountMap.get(conObj.accountID).recordtype.developername;//populate changed recordtype name  
                            contactListtoUpdate.add(conObj);
                        }
                        else {
                            conObj.Account_Record_Type_Name__c = '';//field is blanked out for non-household account record types
                            contactListtoUpdate.add(conObj);
                        }
                    }
                }
                if(!contactListtoUpdate.isEmpty()) {
                    RecordtypeUpdatedByAccountTrigger = true; // Recursive Check
                    update contactListtoUpdate;
                }
            }
        }
    } 
}