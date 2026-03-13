/**
 * @description       : Trigger Handler to manage all DML and events on Affiliation__c
 * @author            : Peter Sewell
 * @group             : Trigger Handler
 * @last modified on  : 19-08-2023
 * @last modified by  : Nick Guia
 * Modifications Log 
 * Date         Author          Modification
 * 2023-03-08 - Peter Sewell - Initial Version
 * 2024-10-01 - Nick G.      - Added INFO logs when ContactShare cannot be created for an Agency
 *                           - Wrapped ContactShare insert/delete in a try-catch and added Exception Logging
 **/
public without sharing class AffiliationTriggerHandler {

    public static final String READ_SHARE = 'Read';
    public static final String EDIT_SHARE = 'Edit';
    public static final String NO_SHARE = 'No Sharing';
    public static Map<Id,Schema.RecordTypeInfo> rtMap {
       get {
           if (rtMap == null) {
               rtMap = Affiliation__c.sobjectType.getDescribe().getRecordTypeInfosById();
           }
           return rtMap;
       }
       set;
    }

    /*******************************************************************************
     * @author       Peter Sewell
     * @date         2023-03-08
     * @description  If the Share_Contact_to_Account_Role__c is set to R or E
     *               then create a ContactShare to share the contact 
     *               with lowest role in partner account hierarchy
     * @revision     2023-03-08 - Peter Sewell - Initial version
     *******************************************************************************/
    public class CreateContactShares extends TriggerAbstract {

        /**
        * Filter INSERTED Affiliation records for only those where the
        * Share_Contact_to_Account_Role__c field indicates a ContactShare is required
        */
        public override void process(SObject newRecord) {
            Affiliation__c newAffiliation = (Affiliation__c) newRecord;
            if (affiliationHasSharingSignificance(newAffiliation)) {
                records.add(newAffiliation);
            }
        }

        /**
        * Share Contact records to Affiliated partner account users by inserting ContactShares
        */
        public override void execute() {   
            if (!records.isEmpty()) {
                doCreateContactShares((List<Affiliation__c>) records);
            }
        }
    }

    /*******************************************************************************
     * @author       Peter Sewell
     * @date         2023-03-08
     * @description  When a contact is no longer affiliated to a partner account,
     *               this class ensures we delete any related ContactShare      
     * @revision     2023-03-08 - Peter Sewell - Initial version
     *******************************************************************************/
    public class DeleteContactShares extends TriggerAbstract {

        /**
        * Filter DELETED records for only those Affiliation records where the
        * Share_Contact_to_Account_Role__c field indicates a related ContactShare needs to be deleted
        */
        public override void process(SObject oldRecord) {
            Affiliation__c oldAffiliation = (Affiliation__c) oldRecord;
            if (affiliationHasSharingSignificance(oldAffiliation)) {
                records.add(oldAffiliation);
            }
        }

        /**
        * Unshare Contact records to Affiliated partner account users by deleting ContactShares
        */
        public override void execute() {   
            if (!records.isEmpty()) {
                doDeleteContactShares((List<Affiliation__c>) records);        
            }
        }
    }

    /*******************************************************************************
     * @author       Peter Sewell
     * @date         2023-03-08
     * @description  When an affiliation changes, this class updates the related ContactShare. 
     *               Essentially, the old affiliation record results in a share deletion
     *               and the updated record results in a new ContactShare
     * @revision     2023-03-08 - Peter Sewell - Initial version
     *******************************************************************************/
    public class UpdateContactShares extends TriggerAbstract {

        List<Affiliation__c> affs2Delete = new List<Affiliation__c>();
        List<Affiliation__c> affs2DeleteFiltered = new List<Affiliation__c>();
        List<Affiliation__c> affs2Create = new List<Affiliation__c>();

        /**
        * Filter UPDATED records for only records where there are changes to 
        * Account, Contact OR Sharing fields
        * i.e. Affiliation record changes that actually impact sharing
        */
        public override void process(SObject newRecord, SObject oldRecord) {
            Affiliation__c oldAffiliation = (Affiliation__c) oldRecord;
            Affiliation__c newAffiliation = (Affiliation__c) newRecord;
            if (changeOfSharingSignificance(oldAffiliation, newAffiliation)) {
                if (affiliationHasSharingSignificance(oldAffiliation)) {affs2Delete.add(oldAffiliation);}
                if (affiliationHasSharingSignificance(newAffiliation)) {affs2Create.add(newAffiliation);}
            }
        }

        /**
        * Run functionality logic
        * An update is logically a delete then an insert
        */
        public override void execute() { 

            // Dont delete what we are going to create
            for (Affiliation__c affil : affs2Delete) {
                if (!deepContains(affil, affs2Create)) {
                    affs2DeleteFiltered.add(affil);
                }
            }

            if (!affs2DeleteFiltered.isEmpty()) {
                doDeleteContactShares(affs2DeleteFiltered); 
            }
            if (!affs2Create.isEmpty()) {
                doCreateContactShares(affs2Create);   
            }    
        }
    }

    /*******************************************************************************
     * @author       Peter Sewell
     * @date         2023-03-08
     * @description  Set or clear Sharing_Composite_Key field on the Affiliation record. 
     *               This is unique field, and ensures there can be only one sharing-significant affilation 
     *               record for the same contact-account combination. 
     *               Which could otherwise lead to sharing ambiguities / issues
     * @revision     2023-03-08 - Peter Sewell - Initial version
     *******************************************************************************/
    public class UpdateSharingCompositeKey extends TriggerAbstract {

        // Add all INSERTED records
        public override void process(SObject newRecord) {
            Affiliation__c newAffiliation = (Affiliation__c) newRecord;
            records.add(newAffiliation);
        }

        // Add all UPDATED records
        public override void process(SObject newRecord, SObject oldRecord) {
            Affiliation__c newAffiliation = (Affiliation__c) newRecord;
            records.add(newAffiliation);
        }

        // Now update the composite key on inserted or updated records
        public override void execute() {   
            if (!records.isEmpty()) {
                doUpdateSharingCompositeKey((List<Affiliation__c>) records);
            }
        }
    }

    /*******************************************************************************
     * @author       Mac Domingo
     * @date         2023-24-11
     * @description  Sets the default values for the Affiliation object on Creation of record
     * @revision     2023-24-11 - Mac Domingo - Initial version
     *******************************************************************************/
    public class SetDefaultValues extends TriggerAbstract {
        // Add all INSERTED records
        public override void process(SObject newRecord) {
            Affiliation__c newAffiliation = (Affiliation__c) newRecord;
            records.add(newAffiliation);
        }
        // Now upsert the composite key on inserted or updated records
        public override void execute() {   
            if (!records.isEmpty()) {
                AffiliationService aflService = new AffiliationService();
                for (Affiliation__c affl : (List<Affiliation__c>)records) {
                    aflService.setDefaults(affl);
                }
            }
        }        
    }

    /*******************************************************************************
     * @author       Mac Domingo
     * @date         2023-24-11
     * @description  Generates values for the Composite Key if the Affiliation changes Account/Contact/RecordTypeId values
     * @revision     2023-24-11 - Mac Domingo - Initial version
     *******************************************************************************/
    public class RegenerateCompositeKey extends TriggerAbstract {
        // Add all UPDATED records
        public override void process(SObject newRecord, SObject oldRecord) {
            Affiliation__c newAffiliation = (Affiliation__c) newRecord;
            Affiliation__c oldAffiliation = (Affiliation__c)oldRecord;
            //Check if Account/Contact/RecordType was changed
            if(oldAffiliation.Account__c != newAffiliation.Account__c ||
                oldAffiliation.Contact__c != newAffiliation.Contact__c ||
                oldAffiliation.RecordTypeId != newAffiliation.RecordTypeId){
            records.add(newAffiliation);
            }
        }
        // Now upsert the composite key on inserted or updated records
        public override void execute() {   
            if (!records.isEmpty()) {
                AffiliationService aflService = new AffiliationService();
                for (Affiliation__c affl : (List<Affiliation__c>)records) {
                    aflService.generateNewCompositeKey(affl);
                }
            }
        }        
    }

    /*******************************************************************************
     * @author       Seeva Singh
     * @date         2023-06-07
     * @description  update Contact and its corresponding Account's owner to system data owner when an 
     *               affiliation is created
     * @param        affiliations 
     * @revision     2023-06-07 - Seeva Singh - Initial version
     *******************************************************************************/
    public class updateOwnerToSystemDataOwner extends TriggerAbstract {
        
        /**
        * Filter INSERTED Affiliation records 
        */
        public override void process(SObject newRecord) {
            Affiliation__c newAffiliation = (Affiliation__c) newRecord;   
            SystemDataOwnersSetting__c  systemownerDetail = SystemDataOwnersSetting__c.getValues('SystemOwnerDetail');
            //FILTER THE RECORD TO RUN THE UPDATE OWNER LOGIC ONLY FOR THE APPLICANT RECORD TYPES
            if(systemownerDetail!= null && newAffiliation.CreatedById!=systemownerDetail.ByPassUser__c && systemownerDetail.ValidRecordTypes__c != null &&  systemownerDetail.ValidRecordTypes__c.contains(rtMap.get(newAffiliation.RecordTypeId).getDeveloperName().toLowercase())){     
                records.add(newAffiliation);              
            }    
        }
            
        /**
        * Update Contact Ownership
        */
        public override void execute() {   
            if (!records.isEmpty()) {
                updateOwnership((List<Affiliation__c>) records);                
            }
        }
    }
    
    /*******************************************************************************
     * @author       Peter Sewell
     * @date         2023-03-08
     * @description  Returns list of Affiliaton records of sharing significance for
     *               for the given list of contact ids, if any
     * @param        contactIds - set of contacts to check for Affiliations of sharing significance
     * @revision     2023-03-08 - Peter Sewell - Initial version
     *******************************************************************************/
    public static List<Affiliation__c> getAffiliationsOfSharingSignificance(List<String> contactIds) {
        List<Affiliation__c> affiliationsOfSharingSignificance = new List<Affiliation__c>();

        Set<String> queryFields = Schema.describeSObjects(new List<String> { 'Affiliation__c' })[0].fields
                                    .getMap()
                                    .keySet();

        String strWHERE = '';
        strWHERE += ' Contact__c IN :contactIds ';
        strWHERE += ' AND (Share_Contact_to_Account_Role__c = :READ_SHARE OR Share_Contact_to_Account_Role__c = :EDIT_SHARE) ';
        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(false)
                .querySObject('Affiliation__c')
                .queryFields(queryFields)
                .getQuery(strWHERE);
        affiliationsOfSharingSignificance = Database.Query(dynamicSOQL);

        return affiliationsOfSharingSignificance;
    }

    /*******************************************************************************
     * @author       Peter Sewell
     * @date         2023-03-08
     * @description  Recreates ContactShare records for the passed in Affiliation records
     * @param        affiliations - list of affiliation records to re-establish sharing for
     * @revision     2023-03-08 - Peter Sewell - Initial version
     *******************************************************************************/
    public static void reestablishSharing(List<Affiliation__c> affiliations) {
        doCreateContactShares(affiliations);
    }

    //
    // PRIVATE METHODS
    //

    /**
    * Create ContactShare records to reflect the contact->account affiliations
    */
    @TestVisible
    private static void doCreateContactShares(List<Affiliation__c> affiliations) {
        /**
         * ContactShare records to be inserted, this is a map of Contact ID + Account ID => ContactShare tp ensure uniqueness
         * Affiliations can have similar Contact and Account but different record types 
         */
        Map<String, ContactShare> ctcShrs2CreateByContactAndAccountIds = new Map<String, ContactShare>();
        Map<String, String> acct2Group = new Map<String, String>();     // Maps partner account ids to their associated public groups (roles)
        Set<String> acctIds = new Set<String>();                        // Ids of accounts in-scope of this trigger

        // Firstly get the ids of accounts affiliated to contacts
        for (Affiliation__c affl : affiliations) {
            acctIds.add(affl.Account__c);
        }

        // Create map of Account Ids to the Groups associated to their Account Role
        // We ultimately need to share the contacts to these groups
        acct2Group = createMapAccount2Group(acctIds);

        // Now create the ContactShares
        for(Affiliation__c affl : affiliations) {
            // get unique sharing key
            String sharingKey = ContactPointUtility.getAffiliationSharingKey(affl);

            if(!ctcShrs2CreateByContactAndAccountIds.containsKey(sharingKey) &&  // create shares based on unique contact and account only
                acct2Group.containsKey(affl.Account__c)) // Create shares only for affiliations where the account has an associated role/group
            {
                ContactShare ctcShr = new ContactShare();
                ctcShr.ContactId  = affl.Contact__c;
                ctcShr.ContactAccessLevel = affl.Share_Contact_to_Account_Role__c == EDIT_SHARE ? 'Edit' : 'Read';
                ctcShr.UserOrGroupId = acct2Group.get(affl.Account__c);
                ctcShrs2CreateByContactAndAccountIds.put(sharingKey, ctcShr);
            } else if(!acct2Group.containsKey(affl.Account__c) || acct2Group.get(affl.Account__c) == null) 
            {
                /**
                 * If the system attempts to share a Contact record to partner accounts that don't have
                 * an active role/group yet - log it so we are aware that the attempt did happen but was
                 * not successful due to missing data
                 */
                nebula.logger.warn('Unable to share ' + affl.Contact__c + ' to Agency ' + affl.Account__c + ' because the Public Group does not exist',affl);
            }
        }

        if (!ctcShrs2CreateByContactAndAccountIds.isEmpty()) {
            try {
                insert ctcShrs2CreateByContactAndAccountIds.values();
            } catch(Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
            }
        }

        nebula.logger.saveLog();
    }

    /**
    * Delete ContactShare records related to the deleted contact->account affiliations
    */
    @TestVisible
    private static void doDeleteContactShares(List<Affiliation__c> affiliations) {
            
        Map<Id, ContactShare> ctcShrs2DeleteById = new Map<Id, ContactShare>();
        Map<String, String> acct2Group = new Map<String, String>();
        Set<String> acctIds = new Set<String>();
        Set<String> ctcIds = new Set<String>();

        // Firstly create the set of ids of accounts and contacts for which matching ContactShares must be deleted
        for(Affiliation__c affl : affiliations) {
            acctIds.add(affl.Account__c);
            ctcIds.add(affl.Contact__c);
        }
    
        // Create map of Account Ids to Groups associated to their Account Role
        // We need to delete any ContactShares of contacts to these groups
        acct2Group = createMapAccount2Group(acctIds);
        
        // Now iterate through list of all ContactShares shared to the in-scope Groups
        for(ContactShare ctcShr : [select id, ContactId, ContactAccessLevel, UserOrGroupId, RowCause from ContactShare where rowcause = 'manual' and ContactId IN :ctcIds and UserOrGroupId IN :acct2Group.values()]) {
            
            for(Affiliation__c affl : affiliations) {
                /**
                 * If a deleted affiliation has an associated contactshare, then add contactshare to our deletion list
                 * we store them in a map because there could be multiple affiliations linked with the same contact
                 * and account combination but different record types.
                 */
                if (affiliationMatchesContactShare(affl, ctcShr, acct2Group)) {
                    ctcShrs2DeleteById.put(ctcShr.Id, ctcShr);
                }
            }
        }

        if (!ctcShrs2DeleteById.isEmpty()) {
            try {
                delete ctcShrs2DeleteById.values();
            } catch(Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();                
            }
        }
    }

    /* 
    * Return a map of accountid to their associated public groups 
    * where the account is partner enabled account and the group is the one created by  
    * the platform to represent users assigned to the lowest partner role in its hierarchy
    */
    @TestVisible
    private static Map<String, String> createMapAccount2Group(Set<String> acctIds) {

        Map<String, String> acct2Group = new Map<String, String>();

        Map<String, String> acct2Role = new Map<String, String>();
        Map<String, String> role2Group = new Map<String, String>();

        // Create a map of Account Ids to their associated Partner Role Id (where such exist)
        for (UserRole ur : [select id, Name, PortalAccountId from UserRole where PortalAccountId IN :acctIds and name like '% Partner User']) {
            if (!String.isBlank(ur.PortalAccountId)) {
                acct2Role.put(ur.PortalAccountId, ur.id);
            }
        }
        // Now create a map of Partner Role Ids to their associated Groups
        for (Group gr : [select id, Name, RelatedId, Type from group where RelatedId IN :acct2Role.values() and type='Role']) {
            role2Group.put(gr.RelatedId, gr.Id);
        }

        // Finally populate the map of account ids to groups
        for (String acct : acctIds) {
            if (acct2Role.containsKey(acct) && role2Group.containsKey(acct2Role.get(acct))) {
                acct2Group.put(acct, role2Group.get(acct2Role.get(acct)));
            }
        }

        return acct2Group;
    }

    /*
    * Returns true if Affiliation record "matches" the ContactShare
    */
    @TestVisible
    private static Boolean affiliationMatchesContactShare(Affiliation__c affl, ContactShare ctcShr, Map<String, String> acct2Group) {

        Boolean isMatch = false;

        String accessLevel = affl.Share_Contact_to_Account_Role__c == EDIT_SHARE ? 'Edit' : 'Read';
        if ((affl.Contact__c == ctcShr.ContactId) && // Same contact
                (acct2Group.get(affl.Account__c) == ctcShr.UserOrGroupId) && // same account->group
                (accessLevel == ctcShr.ContactAccessLevel)) { // same level of access
            isMatch = true;
        }

        return isMatch;
    }

    /*
    * Returns true if changes to the Affiliation record impact ContactSharing
    */
    @TestVisible
    private static Boolean changeOfSharingSignificance(Affiliation__c oldAffiliation, Affiliation__c newAffiliation) {

        Boolean isChangeOfSignificance = false;

        if ((oldAffiliation.Contact__c != newAffiliation.Contact__c) ||
                (oldAffiliation.Account__c != newAffiliation.Account__c) || 
                (oldAffiliation.Share_Contact_to_Account_Role__c != newAffiliation.Share_Contact_to_Account_Role__c) ||
                (oldAffiliation.Share_Force_Recalculation__c != newAffiliation.Share_Force_Recalculation__c)) { 
            isChangeOfSignificance = true;
        }

        return isChangeOfSignificance;
    }

    /**
    * Set or clear composite key
    */
    @TestVisible
    private static void doUpdateSharingCompositeKey(List<Affiliation__c> affiliations) {
        for (Affiliation__c affl : affiliations) {
            // Set the key if the Affifliation is sharing significant otherwise clear
            affl.Sharing_Composite_Key__c = affiliationHasSharingSignificance(affl) ? ContactPointUtility.getAffiliationSharingKey(affl) : '';
        }
    }

    /**
    * Returns true if the Affiliation has sharing sigificance
    */
    @TestVisible
    private static Boolean affiliationHasSharingSignificance(Affiliation__c affl) {
        return (affl.Share_Contact_to_Account_Role__c	== READ_SHARE ||
                affl.Share_Contact_to_Account_Role__c	== EDIT_SHARE); 
    }

    /**
    * Returns true if the src Affiliation is deep-contained in the dest Affiliation list
    * i.e. Same contact, account and sharing mode
    */
    @TestVisible
    private static Boolean deepContains(Affiliation__c srcAffl, List<Affiliation__c> destAffls) {
        Boolean deepContains = false;
        for (Affiliation__c destAffl : destAffls) {
            if ((srcAffl.Account__c == destAffl.Account__c) &&
                (srcAffl.Contact__c == destAffl.Contact__c) && 
                (srcAffl.Share_Contact_to_Account_Role__c == destAffl.Share_Contact_to_Account_Role__c)) {
                    deepContains = true;
                    break;
                }
        }
        return deepContains;
    }

    /**
    ** Main logic goes here
    */
    @TestVisible
    private static void updateOwnership(List<Affiliation__c> affiliations)
    {

        Set<ID> contactForOwnerUpdate = new Set<ID>();
        for(Affiliation__c affl : affiliations) {
        // CHECK IF THE CONTACT OWNER IS THE SYSTEM DATA OWNER, IF NOT THEN UPDATE THE OWNER TO SYSTEM DATA OWNER
            contactForOwnerUpdate.add(affl.Contact__c); //ADD CONTACT RECORD IN LIST FOR OWNER UPDATE   
        }
        //IF THE OWNER IS NOT SYSTEM DATA OWNER
        if(!contactForOwnerUpdate.isEmpty())
        {
            updateOwner(contactForOwnerUpdate);
        }
    }

    /**
    ** Update owner to System Data Owner on account and contact
    */
    @TestVisible
    @future
    private static void updateOwner(Set<Id> ContactIdSet)
    {
        List<Contact> contactToUpdateOwnerList = new List<Contact>();
        Map<ID,Account> accountToUpdateOwnerMap = new Map<ID,Account>();
        SystemDataOwnersSetting__c  accDataOwner = SystemDataOwnersSetting__c.getValues('Account System Data Owner');
        SystemDataOwnersSetting__c  contactDataOwner = SystemDataOwnersSetting__c.getValues('Contact System Data Owner');
        Set<string> fedIdSet = new Set<String>();
        if(accDataOwner != null)
            fedIdSet.add(accDataOwner.FederationId__c);
        if(contactDataOwner != null)
            fedIdSet.add(contactDataOwner.FederationId__c);
        Map<String,ID> userNamemap = new Map<string,ID>();
        Set<Id> accIdSet = new set<ID>();
        try{
            if(!fedIdSet.isempty())
            {
                for(User u:[Select id,federationIdentifier from user where federationIdentifier in: fedIdSet])
                {
                    userNamemap.put(u.federationIdentifier, u.Id);
                }
            } 
            if(!ContactIdSet.isempty() && !userNamemap.isempty())
            {
                for(contact con:[Select id,ownerId,accountID,account.ownerId from contact where id In:ContactIdSet])
                {
                    if(con.ownerId != userNamemap.get(contactDataOwner.FederationId__c))
                    {
                        con.ownerID = userNamemap.get(contactDataOwner.FederationId__c ); //System Data Owner
                        contactToUpdateOwnerList.add(con);  
                    }
                    if(con.account.ownerId!=userNamemap.get(accDataOwner.FederationId__c ))
                    {
                        accIdSet.add(con.accountID);
                    }
                }
            }
            //ACCOUNT ID SET TO UPDATE IT'S OWNER IF THE OWNER IS NOT ACCOUNT SYSTEM DATA OWNER
            if(!accIdSet.isEmpty() && !userNamemap.isempty())
            {
                for(Account acc:[Select id,ownerId from account where id in:accIdSet])
                {
                    acc.ownerId= userNamemap.get(accDataOwner.FederationId__c ); //System Data Owner
                    accountToUpdateOwnerMap.put(acc.id,acc);
                }
            }
            
            if(!contactToUpdateOwnerList.isEmpty())
            {
                update contactToUpdateOwnerList;
            }
            if(!accountToUpdateOwnerMap.isEmpty())
            {
                update accountToUpdateOwnerMap.values();
            }
        } catch(Exception ex) {
            nebula.logger.exception(ex.getMessage(), ex);
        } finally {
            nebula.logger.saveLog();                
        }
    }

     /*******************************************************************************
     * @author       SMendu
     * @date         2024-02-26
     * @description  Auto create CPAs when Affiliation is created
     *******************************************************************************/
    public class CreateCPAs extends TriggerAbstract {
        Set<Id> affiliationIds = new Set<Id>();
        /**
        * Filter INSERTED Affiliation records for only those where the
        * RecordType is Applicant
        */
        public override void process(SObject newRecord) {
            Affiliation__c newAffiliation = (Affiliation__c) newRecord;
            if (isApplicantRecordType(newAffiliation)) {
                affiliationIds.add(newAffiliation.Id);
            }
        }

        /**
        * Create CPAs from the Affiliation record
        */
        public override void execute() { 
            if (!affiliationIds.isEmpty()) {
                CPAGenerator.createCPAs(new List<Id>(affiliationIds));
            }
        }

    /**
    * Returns true if the Affiliation is of Applicant record type
    */
    @TestVisible
    private  Boolean isApplicantRecordType(Affiliation__c affl) {
        return (affl.RecordTypeId == AffiliationManageService.AFFILIATION_RECORDTYPE_APPLICANT); 
    }
}
}