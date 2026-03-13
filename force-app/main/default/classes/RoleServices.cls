/**
 * Author: Martin Cadman
 * Date: 22.02.2018
 * Description: Contains all the trigger handlers for Roles
 *
 * To keep this code simple there is a lot of duplication of logic and many individual steps that could be combined.
 * If making changes to Account logic, verify if the same change needs to be made for Contact, and vv. 
 */

public without sharing class RoleServices {

    private static final String COO_RECORD_TYPE = 'COO';

    /**
     * Set the "Is COO Contact flag" on Contact if one of the Roles is COO. 
     * If no COO roles are found, make sure all all flags are unset
     * The COO Flag used for filtering list views.
     *
     * Depending on how a role is undeleted, the recalculation may not take place. Triggers only fire for the parent record being undeleted.
     *
     * Same logic is used for Account. Any changes should be considered for both objects.
     */
     public class updateCntCOOFlag implements Triggers.Handler {
        public void run() {
           
            List<Contact> cUpdate = new List<Contact>();
            Set<Id> allContactIDs = new Set<Id>();
            Map<String,String> rtMap;
            ID rt;

            //Collect all contact ids from roles
            //Need to consider roles that are reparented and recalc. their old parent, hence the use of both trigger.new and trigger.old for different senarios
            if (Trigger.isInsert || Trigger.isUpdate  || Trigger.isunDelete) {
            // Dynamically get a list of RecordTypes for current object
                rtMap = getRecordType(string.valueof(Trigger.new.getSObjectType()));
                for (Roles__c role: (List<Roles__c>) Trigger.new)
                    if (role.Contact__c != null) allContactIDs.add(role.Contact__c);
            }
                              
            if (Trigger.isUpdate || Trigger.isDelete) {
               rtMap = getRecordType(string.valueof(Trigger.old.getSObjectType()));
               for (Roles__c role: (List<Roles__c>) Trigger.old)
                   if (role.Contact__c != null) allContactIDs.add(role.Contact__c);
            }
                                   
            //Security issues can make the RT unavailable. No point progressing if that occurs.
            if (!rtMap.isEmpty()) 
               rt = rtMap.get(COO_RECORD_TYPE);

            if (rt == null)
                nebula.logger.warn('Unable to find COO record type. Check user permissions.');
            else {
               if (allContactIDs.size() > 0) { 
                   // All contacts that are not COO but have roles with a COO recordtype     
                   List<Contact> cList = [select id, is_coo_contact__c from contact where id in :allContactIDs and is_coo_contact__c = false and id in (select contact__c from roles__c where contact__C in :allContactIDs and recordtypeid = :rt )]; //to do
                   for (Contact c:cList) {
                       c.is_coo_contact__c = true;
                       cUpdate.add(c);        
                   }            
    
                    // All contacts that are COO but have no roles with a COO recordtype 
                    cList = [select id, is_coo_contact__c from contact where id in :allContactIDs and is_coo_contact__c = true and id not in (select contact__c from roles__c where contact__C in :allContactIDs and recordtypeid = :rt )];
                    for (Contact c:cList) {
                        c.is_coo_contact__c = false;
                        cUpdate.add(c);        
                    }            
                
                    if (cUpdate.size() > 0)
                        update cUpdate;
                }
            }
        }
    }
 
    /**
     * Set the "Is COO Account flag" on Contact if one of the Roles is COO. 
     * If no COO roles are found, make sure all all flags are unset
     * The COO Flag used for filtering list views.
     *
     * Contacts are not examined. An Account may have a COO Contact but not be considered a COO Account.
     * Same logic is used for Contact. Any changes should be considered for both objects.
     *
     * Depending on how a role is undeleted, the recalculation may not take place. Triggers only fire for the parent record being undeleted.
     */
    public class updateAccCOOFlag implements Triggers.Handler {
        public void run() {
        
            List<Account> aUpdate = new List<Account>();
            Set<Id> allAccountIDs = new Set<Id>();
            Map<String,String> rtMap;
            ID rt;

            // Collect all account parent ids from roles - 
            // Need to consider roles that are reparented and recalc. their old parent, hence the use of the trigger.new & .old lists for different senarios
            if (Trigger.isInsert || Trigger.isUpdate || Trigger.isunDelete) {
                rtMap = getRecordType(string.valueof(Trigger.new.getSObjectType()));
                for (Roles__c role: (List<Roles__c>) Trigger.new)
                    if (role.Account__c != null) allAccountIDs.add(role.Account__c);
            }

            if (Trigger.isUpdate || Trigger.isDelete) {
                rtMap = getRecordType(string.valueof(Trigger.old.getSObjectType()));
                for (Roles__c role: (List<Roles__c>) Trigger.old)
                    if (role.Account__c != null) allAccountIDs.add(role.Account__c);
            } 
                
            if (!rtMap.isEmpty()) 
                rt = rtMap.get(COO_RECORD_TYPE);

            if (rt == null)
                nebula.logger.warn('Unable to find COO record type. Check user permissions.');
            else {

                if (allAccountIDs.size() > 0) { 
                    // All accounts that are not COO but have roles with a COO recordtype     
                    List<Account> aList = [select id, is_coo_account__c from account where id in :allAccountIDs and is_coo_account__c = false and id in (select account__c from roles__c where account__c in :allAccountIDs and recordtypeid = :rt )];
                    for (Account a:aList) {
                        a.is_coo_account__c = true;
                        aUpdate.add(a);        
                    }            
       
                    // All accounts that are COO but have no roles with a COO recordtype 
                    aList = [select id, is_coo_account__c from account where id in :allAccountIDs and is_coo_account__c = true and id not in (select account__c from roles__c where account__C in :allAccountIDs and recordtypeid = :rt )];
                    for (Account a:aList) {
                        a.is_coo_account__c = false;
                        aUpdate.add(a);        
                    }            
                    
                    if (aUpdate.size() > 0) {
                        update aUpdate;
                    }
                }
            }
        }
    }
    
    
    /**
     * Generate a map of recordtypes for an object.
     */
    public static Map<String,String> getRecordType (String inObj) {
    
        // Query for the requested object record types
        List<RecordType> rTypes = [Select DeveloperName, Id From RecordType where sObjectType=:inObj and isActive=true];
        
        // Create a map the Record Type developerName and Id for easy retrieval
        Map<String,String> objRecordTypes = new Map<String,String>{};
        for(RecordType rt: rTypes)
           objRecordTypes.put(rt.DeveloperName,rt.Id);
        
        return objRecordTypes;
     } 
    
}