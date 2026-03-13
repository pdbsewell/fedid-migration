/**
 * @description       : Trigger Helper to manage all DML and events on Account
 * @author            : Inderpal Dhanoa
 * @group             : Account Trigger Helper
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.1   2021-11-29 - Inderpal Dhanoa -- BugFix resolved ENGAGEIE-1254 as SOQL Query was extracting too many records
 * 1.0   2021-11-08 - Inderpal Dhanoa -- Added syncHierarchyLevel to show the Hierarchy of the related School/Faculty
 **/
public with sharing class AccountHelper { 

    /*
    * Method Name:  createPayload
     * @param       Id of Account Object
     * Description: Create the Payload 
    */
    public static Async_Process__e createPayload(Id accountId) {
        Async_Process__e evt;

        if(accountId != null) {
            AsyncProcessPayload payload = new AsyncProcessPayload();
            payload.put ('accountId', new Set<Id> {accountId});
            evt = new Async_Process__e (
                Process_Name__c = 'AccountHelper.UpdateHierarchy',
                Parameter__c = payload.serialize() 
                );
        }
        return evt; 
    }
	
    /**
    * @author Inderpal Dhanoa
    * @date 11.08.2021
    *
    * @group Enterprise Engage
    *
    * @description Service class to update the Hierarchy
    */
    public class UpdateHierarchy implements IPlatformEventInvocable {
    
        private Set<Id> s_accountIDs = new Set<Id>();

        public void execute(List<AsyncProcessPayload> payload) {
			try {
				initialize(payload);
				run();
			} catch(Exception e) {
				LogUtilityException.logException(e, this.s_accountIDs);
			} finally {
				LogUtilityException.getLimits();
			}
		}

		private void initialize(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {
				for(AsyncProcessPayload payload : payloads) {
					//first, cast the get return of List<Object> into List<Id>
					List<Object> objList = (List<Object>) payload.get('accountId');
					//then, instantiate a Set out of it
					for(Object io : objList) {
						//parse object to ID
						this.s_accountIDs.add(Id.valueOf(io.toString()));
					}
				}
			}
		}

        public void run() {
            updateHierarchy(s_accountIDs);
        }
    }

    /*
    * Method Name:  updateHierarchy
     * @param       Set Id of Accounts
     * Description: Calculate the related Account on the specified Hierarchy Level (currently 4) 
    */
    public static void updateHierarchy(Set<Id> s_accountIDs){
        if(!s_accountIDs.isEmpty()){
            Integer iMinimumHierarchyLevel = Integer.valueOf(Label.MinimumHierarchyLevel);
            Map<Id, Account> m_IdRelatedOrg;
            String sNoHierarchyLabel = String.valueOf(Label.NoHierarchyLabel);
            Set<Id> s_OrgsWithoutOther = new Set<Id>();
            Map<String, Account> s_OrgsMinLevel = new Map<String, Account>();
            List<Account> l_updateOrg = new List<Account>();
            for(Account accRec : [SELECT Id, Name, Monash_Faculty_Area_Id__c, Monash_Faculty_Area_Name__c, Hierarchy_Level__c FROM Account WHERE Id in :s_accountIDs]){
                if(accRec.Hierarchy_Level__c == sNoHierarchyLabel){
                    l_updateOrg.add(new Account(Id = accRec.Id, Monash_Faculty_Area_Name__c = ''));         
                }else{
                    if(Integer.valueOf(accRec.Hierarchy_Level__c) < iMinimumHierarchyLevel){
                        s_OrgsWithoutOther.add(accRec.Id);
                    }else{
                        Id iFacultyAreaId = accRec.Monash_Faculty_Area_Id__c;
                        s_OrgsWithoutOther.add(iFacultyAreaId);
                    }
                }   
            }
            // The Set will have the Id of the Min Level (currently Level 4) for updations above level 4 and below Level 4
            if(!s_OrgsWithoutOther.isEmpty()){
                Map<String,Account> m_MinLevelOrgsForFacultyOrgs = getOrgsAtMinLevel(s_OrgsWithoutOther, iMinimumHierarchyLevel, sNoHierarchyLabel);
                if(!s_OrgsWithoutOther.isEmpty() || !l_updateOrg.isEmpty()){
                    updateOrgsAtMinLevelAndBelow(m_MinLevelOrgsForFacultyOrgs, l_updateOrg, iMinimumHierarchyLevel, sNoHierarchyLabel); 
                }
            }
                           
        }
    }

    /*
    * Method Name:  updateOrgsAtMinLevelAndBelow
    * @param       Set String of Accounts
    * @param       List of Accounts to be updated
    * @param       Integer capturing the Minimum Hierarchy Level
    * @param       String capturing no Hierarchy Level (e.g Other)
    * Description: Update the related Account on the specified Hierarchy Level (currently 4) 
    */
    public static void updateOrgsAtMinLevelAndBelow(Map<String,Account> s_OrgsMinLevel, List<Account> l_updateOrg, Integer iMinimumHierarchyLevel, String sNoHierarchyLabel){
        if(!s_OrgsMinLevel.isEmpty()){
            Id monashOrgRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();
            Id facultyRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Faculty').getRecordTypeId();
             for(Account relAcc :   [SELECT Id, Name, Monash_Faculty_Area_Id__c, Monash_Faculty_Area_Name__c, Hierarchy_Level__c 
                                    FROM Account 
                                    WHERE (RecordTypeId = :monashOrgRecTypeId OR RecordTypeId = :facultyRecTypeId) AND Monash_Faculty_Area_Id__c IN :s_OrgsMinLevel.keySet()]){
                if(relAcc.Hierarchy_Level__c != sNoHierarchyLabel && Integer.valueOf(relAcc.Hierarchy_Level__c) >= iMinimumHierarchyLevel && 
                   s_OrgsMinLevel.containsKey(relAcc.Monash_Faculty_Area_Id__c)){
                    // Check records at Min Level && Check records below Min Level
                    Account minLevelAccount = s_OrgsMinLevel.get(relAcc.Monash_Faculty_Area_Id__c);
                    if(relAcc.Monash_Faculty_Area_Name__c != minLevelAccount.Name){
                        l_updateOrg.add(new Account(Id = relAcc.Id, Monash_Faculty_Area_Name__c = minLevelAccount.Name)); 
                    }
                      
                }   
            }
        }        
        if(!l_updateOrg.isEmpty()){
            Boolean hasLockRow = false;
            try{ 
                update l_updateOrg;
            }catch(Exception ex){
                LogUtilityException.LogException(ex);
                hasLockRow = ex.getMessage().contains('UNABLE_TO_LOCK_ROW');
                if(hasLockRow == false) {
                    throw ex; 
                }else{
                    //Implement a retry as possible for Locking due to same parent roll up  delays
                    // UPdate the Account 
                    update l_updateOrg;
                }
            }
        }
    }

    /*
    * Method Name:  getOrgsAtMinLevel
    * @param       Set Id of Accounts which are at or above the Minimum Hierarchy Level
    * @param       Integer capturing the Minimum Hierarchy Level
    * @param       String capturing no Hierarchy Level (e.g Other) 
    * Description: Calculate the related Account on the specified Hierarchy Level (currently 4) and updates the Org above the Minimum Level 
    */
    @SuppressWarnings('PMD.OperationWithLimitsInLoop') // no alternative than looping up to 3 times (it's a controlled and limited approach) to traverse account hierarchies.
    public static Map<String,Account> getOrgsAtMinLevel(Set<Id> s_OrgsWithoutOther, Integer iMinimumHierarchyLevel, String sNoHierarchyLabel){
        Map<String, Account> m_MinLevelOrgs = new Map<String, Account>();
        Map<Id, Account> m_UnSyncedOrgsAboveMinLevel = new Map<Id, Account>();
        List<Account> relAccount; 
        // Check if more Queries are needed, If an Org is re-parented at Level 3 and the minimum Level is Level 9, 
        // First Query is needed to get Orgs from Level 3 - level 7, Re-Query is needed to get Orgs from Level 7 to get Level 9 
        for(Integer i = 0; i < 3 ; i++){
            relAccount = [SELECT Id, Name, Monash_Faculty_Area_Id__c, Monash_Faculty_Area_Name__c, Hierarchy_Level__c 
                          FROM Account 
                          WHERE Hierarchy_Level__c != :sNoHierarchyLabel AND
                          (Id IN :s_OrgsWithoutOther OR ParentId IN :s_OrgsWithoutOther
                          OR Parent.ParentId IN :s_OrgsWithoutOther OR Parent.Parent.ParentId IN :s_OrgsWithoutOther
                          OR Parent.Parent.Parent.ParentId IN :s_OrgsWithoutOther OR Parent.Parent.Parent.Parent.ParentId IN :s_OrgsWithoutOther)];
            for(Account relAcc : relAccount){
                // Check records at Min Level
                if(Integer.valueOf(relAcc.Hierarchy_Level__c) == iMinimumHierarchyLevel){
                    String s_recId = String.valueOf(relAcc.Id);
                    m_MinLevelOrgs.put(s_recId.substring(0,15), relAcc);       
                } else if(Integer.valueOf(relAcc.Hierarchy_Level__c) < iMinimumHierarchyLevel && relAcc.Name != relAcc.Monash_Faculty_Area_Name__c){
                    m_UnSyncedOrgsAboveMinLevel.put(relAcc.Id, relAcc);
                }
            }
            // All the Orgs have been added to the Map then further re-Querying is not needed
            // If there are more Orgs exist below 
            if(!newOrgsAdded(relAccount, s_OrgsWithoutOther)){ 
                break;
            }else{
                for(Account acc : relAccount){
                    s_OrgsWithoutOther.add(acc.Id);
                }
            }
        }
        // If there are Orgs above the Minimum Level where the Name and the Faculty Name do not match then they are to be synced
        if(!m_UnSyncedOrgsAboveMinLevel.isEmpty()){
            List<Account> l_UnSyncedOrgs = new List<Account>();
            for(Account unSyncedOrgsAboveMinLevel : m_UnSyncedOrgsAboveMinLevel.values()){
                l_UnSyncedOrgs.add(New Account(Id = unSyncedOrgsAboveMinLevel.Id, Monash_Faculty_Area_Name__c = unSyncedOrgsAboveMinLevel.Name));
            } 
            try{
                update l_UnSyncedOrgs;
            }catch(Exception ex){
                LogUtilityException.LogException(ex);
            }
        }     
        return m_MinLevelOrgs;
    }

    /*
    * Method Name:  newOrgsAdded
    * @param       List Account List of parent Accounts retrieved 
    * @param       Set Id for the Orgs at Above Minimum Level 
    * Description: To check if new Orgs have been added while Querying the Parents, 
                   If new Orgs have been added then Re-Query is needed otherwise Re-Query is not needed 
    */
    public static Boolean newOrgsAdded(List<Account> relAccount, Set<Id> s_OrgsWithoutOther){
        for(Account relAcc : relAccount){
            if(!s_OrgsWithoutOther.contains(relAcc.Id)){
                return true;
            }
        }
        return false;
    }
}