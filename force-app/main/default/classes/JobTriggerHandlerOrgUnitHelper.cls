/*
 *  @author       Inderpal Dhanoa
 *  @description  Handler class for job trigger. Creates or updates target object records from staging object.
 *
 * IMPORTANT
 * This trigger will process only 2000 records at a time, to handle the CPU timeout limit. 
 * If we have more than 2000 records, need to manually update the job control table and process the records.
 * @revisions
 * 11-09-2024 Martin Cadman - Added nebula logging
 * 							- Stopped more recent start dates from being reverted by the load (EPCP-3880)
* 03/10/2024               - Stopped updating start date altogether - reconciliation script will do this from Callista (EPCP-3915)
 */
public class JobTriggerHandlerOrgUnitHelper { 
    
    private static final String EVENTTAG = 'Org Unit Load';

    /**
     * @description Check for if the Account and Staging records have different value for Account Name, Parent Name, Start Date or End Date 
     * @param       jobId job Id of the Job Control Object
     * @param       targetObjectName record from the Account Object
     * @return      Boolean 
     */
    public static void processJobControlRecord(String jobId, String targetObjectName, String type){
        Map<String, Account> m_existingOrgUnits = new Map<String, Account>();
        Map<String, Org_Unit__c> m_stagingOrgUnits = new Map<String, Org_Unit__c>();
        Map<String, String> m_unlinkedChildParentOrgIds = new Map<String, String>();

        Set<String> s_activeOrgs = new Set<String>();
        Set<String> s_stagingOrgs = new Set<String>();

        try {
            Id monashOrgRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();
            Id facultyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Faculty').getRecordTypeId();
            // Check for the existing & new Staging Orgs 
            for(Org_Unit__c stagingOrg : [SELECT Id, Name, Org_Id__c, Owner_Organisation_Id__c, Organisation_Name__c, Start_Date__c, End_Date__c 
                                            FROM Org_Unit__c
                                            WHERE Job_Code__c = :jobId
                                            ORDER BY Org_Id__c DESC]) {
                m_stagingOrgUnits.put(stagingOrg.Org_Id__c, stagingOrg);
                s_stagingOrgs.add(stagingOrg.Org_Id__c);
                s_stagingOrgs.add(stagingOrg.Owner_Organisation_Id__c);                                
            }
            // Check for the existing Orgs 
            for(Account existingOrg : [SELECT Id, Callista_Org_Unit_Code__c, Organisation_Unit_Name__c, AccountNumber, ParentId, Parent.Callista_Org_Unit_Code__c, 
                                        Monash_AM_Start_Date__c, Monash_AM_End_Date__c 
                                        FROM Account 
                                        WHERE RecordTypeId = :facultyRecordTypeId OR RecordTypeId = :monashOrgRecordTypeId]) {
                m_existingOrgUnits.put(existingOrg.Callista_Org_Unit_Code__c, existingOrg);                                
            } 
            List<Org_Unit__c> l_stagingOrgUnits = new List<Org_Unit__c>();
            List<Account> l_newOrgUnits = new List<Account>();
            List<Account> l_updateOrgDetails = new List<Account>();
            List<Account> l_updateParentDetails;
            
            for(String orgId : m_stagingOrgUnits.keySet()){
                Org_Unit__c stagingOrg = m_stagingOrgUnits.get(orgId);
                // Org Exists in Staging and exists in Account
                if(m_existingOrgUnits.containsKey(orgId)){
                    Account existingOrg = m_existingOrgUnits.get(orgId);
                    // Check if the Account needs to be updated
                    if(validateAccountChange(stagingOrg, existingOrg)){
                        stagingOrg.Status__c = 'PROCESSED';
                        // Update the Account 
                        existingOrg = mapFieldsFromStagingToAccount(stagingOrg, existingOrg, m_existingOrgUnits, m_stagingOrgUnits);
                        if(existingOrg.ParentId == null){
                            m_unlinkedChildParentOrgIds.put(stagingOrg.Org_Id__c, stagingOrg.Owner_Organisation_Id__c);
                        }
                        l_updateOrgDetails.add(existingOrg);
                    } else {
                        // No change between Account and Staging Org, so no updation needed on Account
                        stagingOrg.Status__c = 'IGNORED';
                    }
                    // Since the existing Account is in the Payload so it is Active, the set will capture all the existing Orgs
                    s_activeOrgs.add(orgId);
                } else {
                    // Org Exists in Staging and not in Account so Insert new Org in Account
                    stagingOrg.Status__c = 'PROCESSED'; 
                    Account newIncomingOrg = new Account(RecordTypeId = monashOrgRecordTypeId, Callista_Org_Unit_Code__c = stagingOrg.Org_Id__c, Name = stagingOrg.Name);
                    newIncomingOrg = mapFieldsFromStagingToAccount(stagingOrg, newIncomingOrg, m_existingOrgUnits, m_stagingOrgUnits);
                    l_newOrgUnits.add(newIncomingOrg);
                    // Check if the new Account is linked to a new Parent (Id is NULL)
                    if(newIncomingOrg.ParentId == null){
                        m_unlinkedChildParentOrgIds.put(stagingOrg.Org_Id__c, stagingOrg.Owner_Organisation_Id__c);
                    }
                }
                l_stagingOrgUnits.add(stagingOrg); 
            }
            
            // The Existing Map now only has InActive Orgs, so we need to set the End Date as Today for the In Active Orgs
            for(String orgId : m_existingOrgUnits.keySet()){
                if(!s_activeOrgs.contains(orgId)){
                    Account existingInActiveOrg = m_existingOrgUnits.get(orgId); 
                    existingInActiveOrg.Monash_AM_End_Date__c = Date.Today();
                    l_updateOrgDetails.add(existingInActiveOrg);
                }   
            }
        
            Database.SaveResult[] saveResults;
            // Insert the New Org recds into Account
            if(!l_newOrgUnits.isEmpty()) {
                saveResults = Database.insert(l_newOrgUnits, false);
                for (Database.SaveResult result : SaveResults) {
                    if (!result.isSuccess()) {
                        for (Database.Error err : result.getErrors()) {
                            nebula.logger.error(err.getMessage(), result).addTag(EVENTTAG);
                        }
                    } 
                }
            }

            // Update the existing Org into Account recds
            if(!l_updateOrgDetails.isEmpty()){
                saveResults = Database.update(l_updateOrgDetails, false);
                for (Database.SaveResult result : SaveResults) {
                    if (!result.isSuccess()) {
                        for (Database.Error err : result.getErrors()) {
                            nebula.logger.error(err.getMessage(), result).addTag(EVENTTAG);
                        }
                    } 
                }
            }

            // Link the Unlinked Orgs
            if(!m_unlinkedChildParentOrgIds.isEmpty()){
                l_updateParentDetails = linkedNewChildNewParentOrgs(m_unlinkedChildParentOrgIds);
                if(!l_updateParentDetails.isEmpty()){
	                saveResults = Database.update(l_updateParentDetails, false);
                    for (Database.SaveResult result : SaveResults) {
                        if (!result.isSuccess()) {
                            for (Database.Error err : result.getErrors()) {
                                nebula.logger.error(err.getMessage(), result).addTag(EVENTTAG);
                            }
                        } 
                    }
                }    
            } 

            // Upsert the Staging Org recds with PROCESSED or IGNORED
            if(!l_stagingOrgUnits.isEmpty()){
                saveResults = Database.update(l_stagingOrgUnits, false);
                for (Database.SaveResult result : SaveResults) {
                    if (!result.isSuccess()) {
                        for (Database.Error err : result.getErrors()) {
                            nebula.logger.error(err.getMessage(), result).addTag(EVENTTAG);
                        }
                    } 
                }
            }
            
            // updating the job control table record after the processing of records is complete
            List<Job_Control__c> l_jobList = new List<Job_Control__c>();
            for(Job_Control__c  obj : [SELECT Id,Processing_Status__c, Record_Update_Count__c, Number_of_Records_Processed__c 
                                       FROM Job_Control__c 
                                       WHERE Job_Code__c = :jobId]) {
				obj.Number_of_Records_Processed__c = obj.Number_of_Records_Processed__c==null?0:obj.Number_of_Records_Processed__c;
                obj.Processing_Status__c = 'Target Load Completed' ; 
                obj.Number_of_Records_Processed__c = l_stagingOrgUnits.size();
                obj.Record_Update_Count__c = l_updateOrgDetails.size(); 
                l_jobList.add(obj);
            
                if(!l_jobList.isEmpty()){
                    update l_jobList;
                }
			}
            
        } catch(Exception ex) {
            nebula.logger.error(ex.getMessage(), ex).addTag(EVENTTAG);
        } finally {
            nebula.logger.saveLog();
        }
    }

    /*
     * @Description linked New Child and New Parent Orgs Recds to Account  
     * @param       m_unlinkedChildParentOrgIds Map of unlinked Child Callista Org Id with Parent Callista Org Id
     * @return      List Account returned with the updated Parent values
    */
    public static List<Account> linkedNewChildNewParentOrgs(Map<String, String> m_unlinkedChildParentOrgIds){
		// If new Orgs and child Orgs are inserted in the same Transaction then the reference to the Parent gets lost
		// The method is requerying all the inserted Accounts
        Set<String> s_allOrgs = new Set<String>();
        Map<String,Account> m_unlinkedOrgs = new Map<String,Account>(); 
        List<Account> l_updateParentDetails = new List<Account>();
        for(String orgId : m_unlinkedChildParentOrgIds.keySet()){
            s_allOrgs.add(orgId);
            s_allOrgs.add(m_unlinkedChildParentOrgIds.get(orgId));
        } 

        for(Account unLinkedOrg : [SELECT Id, Name, ParentId, Callista_Org_Unit_Code__c FROM Account WHERE Callista_Org_Unit_Code__c in :s_allOrgs]){
            m_unlinkedOrgs.put(unLinkedOrg.Callista_Org_Unit_Code__c, unLinkedOrg);
        }

        for(Account unLinkedOrg : m_unlinkedOrgs.values()){
            if(unLinkedOrg.ParentId == null && s_allOrgs.contains(unLinkedOrg.Callista_Org_Unit_Code__c)){
                String s_unLinkedParentOrgId = m_unlinkedChildParentOrgIds.get(unLinkedOrg.Callista_Org_Unit_Code__c);
                if(m_unlinkedOrgs.containsKey(s_unLinkedParentOrgId)){
                    Account unLinkedParentOrg = m_unlinkedOrgs.get(s_unLinkedParentOrgId);
                    l_updateParentDetails.add(new Account(Id = unLinkedOrg.Id, Parentid = unLinkedParentOrg.Id));
                }
            }
        }
        return l_updateParentDetails;
    }

    /*
     * @Description Map field values from Staging Recds to Account  
     * @param       stagingOrg record from the staging Org Unit Object
     * @param       existingOrg record from the Account Object
     * @param       Map of Callista Org Id with the Account record
     * @return      Account returned with the updated field values
     */
    public static Account mapFieldsFromStagingToAccount(Org_Unit__c stagingOrg, Account existingOrg, Map<String, Account> m_existingOrgUnits, 
                                                        Map<String, Org_Unit__c> m_stagingOrgUnits) {
        // Update the Account 
        existingOrg.AccountNumber = stagingOrg.Org_Id__c;
        existingOrg.Organisation_Unit_Name__c = stagingOrg.Name;
		
        // Check for Start Date
        if(stagingOrg.Start_Date__c != null && stagingOrg.Start_Date__c.year() > 4000) {
            existingOrg.Monash_AM_Start_Date__c = Date.newInstance(4000,12,31);
        } else {
            if (existingOrg.Monash_AM_Start_Date__c == null ) { 
                // The start date is managed via the reconciliation scripts
            	existingOrg.Monash_AM_Start_Date__c = stagingOrg.Start_Date__c;   
            }
        }
                                                            
        // Check for End Date
        if(stagingOrg.End_Date__c != null && stagingOrg.End_Date__c.year() > 4000) {
            existingOrg.Monash_AM_End_Date__c = Date.newInstance(4000,12,31);
        } else {
            existingOrg.Monash_AM_End_Date__c = stagingOrg.End_Date__c;  
        }
                                                            
        // Check if the correct parent is linked
        if(String.isNotBlank(stagingOrg.Owner_Organisation_Id__c)){
            // The Parent Org exists and needs to be linked 
            if(m_existingOrgUnits.containsKey(stagingOrg.Owner_Organisation_Id__c)){
                Account linkedParentOrg = m_existingOrgUnits.get(stagingOrg.Owner_Organisation_Id__c);
                existingOrg.ParentId = linkedParentOrg.Id;
            }
        }  
        return existingOrg;
    }

    /*
     * @Description Check for if the Account and Staging records have different value for Account Name, Parent Name, Start Date or End Date      
     * @param       stagingOrg record from the staging Org Unit Object
     * @param       existingOrg record from the Account Object
     * @return      Boolean that indicates if the records are matched 
    */
    public static Boolean validateAccountChange(Org_Unit__c stagingOrg, Account existingOrg){
        Boolean bUpdateAccount = false;
        String sParentOrgId = existingOrg.ParentId == null ? '' : existingOrg.Parent.Callista_Org_Unit_Code__c;
        if((stagingOrg.Name != existingOrg.Organisation_Unit_Name__c) || (stagingOrg.Owner_Organisation_Id__c != sParentOrgId) || 
            (existingOrg.Monash_AM_Start_Date__c != stagingOrg.Start_Date__c) || (existingOrg.Monash_AM_End_Date__c != stagingOrg.End_Date__c) ){
                bUpdateAccount = true;
        }
        return bUpdateAccount; 
    }
}