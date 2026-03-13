/**
 * @description       : Merges two different Affiliation records using the field survivorship rules.
 *                      Primarily used for Contact merge (person 360) operations
 *                      The class assumes that the Affiliations being merged have the same Record Type ID.
 *                      No RecordTypeId checking is being done here to eliminate the need of including the field in a query.
 *                      If you end up merging Affiliations with different record types, there is a risk of assigning restricted
 *                      picklist values.
 * @author            : Nick Guia
 * @last modified on  : 16-08-2023
 * @last modified by  : Nick Guia
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/265585021/Affiliation+Field+Survivorship
 * @revision
 *  04-09-2023  Nick Guia   - Moved the population of Share_Force_Recalculation__c from ContactMergeBaseClass to make sure that all Affiliations
 *                            being merged gets "sharing-recalculated" everytime a merge happens
**/
public inherited sharing class AffiliationMergeUtility {

    @TestVisible
    private static AffiliationMergeUtility myself;

    // these are the fields whose survivor will be determined by pickNewestStartDateOrNotNull()
    @TestVisible
    private final Set<SObjectField> fieldsFromNewestAndNotNull = new Set<SObjectField>{
        Affiliation__c.Account_Communications__c,
        Affiliation__c.Department__c,
        Affiliation__c.Description__c,
        Affiliation__c.Position__c,
        Affiliation__c.Position_Level__c,
        Affiliation__c.Program__c
    };

    public static AffiliationMergeUtility getInstance() {
        if(myself == null) {
            myself = new AffiliationMergeUtility();
        }
        return myself;
    }

    /**
    * @description merge a survivor affiliation with a victim affiliation record.
    *   This is primarily used in ContactMerge.
    * @author Nick Guia | 10-08-2023 
    * @param Affiliation__c survivor 
    * @param Affiliation__c victim 
    * @return Affiliation__c 
    **/
    public Affiliation__c mergeFields(Affiliation__c survivor, Affiliation__c victim) {
        try {
            // for most fields, we pick the value from the newest start date,
            // or pick the ones that is not null
            for(SObjectField iField : this.fieldsFromNewestAndNotNull) {
                Object survivingValue = pickNewestStartDateOrNotNull(iField, survivor, victim);
                survivor.put(iField, survivingValue);
            }
            
            // these are the fields that follow a specific rule
            survivor.Start_Date__c = mergeStartDateFields(survivor, victim);
            survivor.End_Date__c = mergeEndDateFields(survivor, victim);
            survivor.Roles__c = mergeRolesFields(survivor, victim);
            survivor.Share_Contact_to_Account_Role__c = mergeSharingFields(survivor, victim);
            survivor.Share_Force_Recalculation__c = System.now(); // force sharing recalculation after merge

            // survivor.Engagement_Scoring_Applied__c = // TODO
        } catch(Exception e) {
            throw new AffiliationMergeUtilityException(e.getMessage());
        }
        return survivor;
    }

    /**
    * @description  picks the value from the record with the newest (start date) non-null value
    *   Start Dates are assumed to always be not null
    * @author Nick Guia | 10-08-2023 
    * @param SObjectField field 
    * @return Object 
    **/
    @TestVisible
    private Object pickNewestStartDateOrNotNull(SObjectField field, Affiliation__c survivor, Affiliation__c victim) {
        
        Object returnVal;
        Object survivorFieldVal = survivor.get(field);
        Object victimFieldVal = victim.get(field);

        // if one value is null, return the other
        if(survivorFieldVal == null) return victimFieldVal;
        if(victimFieldVal == null) return survivorFieldVal;

        // if start dates are equal, and both values are not null, return survivorFieldVal
        if(survivor.Start_date__c == victim.Start_date__c) return survivorFieldVal;

        // otherwise, pick the one from the newest start date
        returnVal = (survivor.Start_date__c > victim.Start_date__c) ? survivorFieldVal : victimFieldVal;

        return returnVal;
    }

    /**
    * @description pick the newest start date
    * @author Nick Guia | 10-08-2023 
    * @param Affiliation__c survivor 
    * @param Affiliation__c victim 
    * @return Date 
    **/
    @TestVisible
    private Date mergeStartDateFields(Affiliation__c survivor, Affiliation__c victim) {
        return (survivor.Start_date__c > victim.Start_date__c) ? survivor.Start_date__c : victim.Start_date__c;
    }

    /**
    * @description 
    *   - if only one is active, pick the End Date of the active ones.
    *   - if both are either active or inactive, pick the latest end date
    * @author Nick Guia | 10-08-2023 
    * @param Affiliation__c survivor 
    * @param Affiliation__c victim 
    * @return Date 
    **/
    @TestVisible
    private Date mergeEndDateFields(Affiliation__c survivor, Affiliation__c victim) {
        Date returnVal;

        // if only one of them is active
        if(survivor.IsActive__c && !victim.IsActive__c) return survivor.End_Date__c;
        if(!survivor.IsActive__c && victim.IsActive__c) return victim.End_Date__c;

        // otherwise, if both are active or both are inactive, pick the latest
        returnVal = (survivor.End_Date__c > victim.End_Date__c) ? survivor.End_Date__c : victim.End_Date__c;

        return returnVal;
    }

    /**
    * @description joins the two multi-picklist values from Roles, but only if the affiliation is active.
    *   if both are active, or both are inactive - combine the two sets.
    *   this way we won't lose any data as opposed to not merging anything if both are inactive
    * @author Nick Guia | 10-08-2023 
    * @param Affiliation__c survivor 
    * @param Affiliation__c victim 
    * @return Date 
    **/
    @TestVisible
    private String mergeRolesFields(Affiliation__c survivor, Affiliation__c victim) {

        // create a set of unique roles
        Set<String> result = new Set<String>();
        Set<String> survivorRoles = new Set<String>();
        Set<String> victimRoles = new Set<String>();
        
        if(String.isNotBlank(survivor.Roles__c)) {
            survivorRoles.addAll(survivor.Roles__c.split(';'));
        }
        if(String.isNotBlank(victim.Roles__c)) {
            victimRoles.addAll(victim.Roles__c.split(';'));
        }

        if(survivor.IsActive__c == victim.IsActive__c) {
            // combine the two sets
            result.addAll(survivorRoles); 
            result.addAll(victimRoles);
        } else {
            // otherwise, only pick the active ones
            if(survivor.IsActive__c) result.addAll(survivorRoles);
            if(victim.IsActive__c) result.addAll(victimRoles);
        }
        
        return String.join(new List<String>(result), ';'); // create a new multi-picklist value set
    }

    /**
    * @description follow principle of least-privilege
    * @author Nick Guia | 10-08-2023 
    * @param Affiliation__c survivor 
    * @param Affiliation__c victim 
    * @return Date 
    **/
    @TestVisible
    private String mergeSharingFields(Affiliation__c survivor, Affiliation__c victim) {

        String returnVal = AffiliationTriggerHandler.NO_SHARE; // default to least privilege;

        // if equal, get any of the two - this is the only scenario where we can return an 'Edit' sharing
        if(survivor.Share_Contact_to_Account_Role__c == victim.Share_Contact_to_Account_Role__c) {
            // any or leave blank if both are null
            return String.isNotBlank(survivor.Share_Contact_to_Account_Role__c) ? survivor.Share_Contact_to_Account_Role__c : '';  
        }

        // if one of them is null, return 'No Sharing'
        if((String.isNotBlank(survivor.Share_Contact_to_Account_Role__c) && String.isBlank(victim.Share_Contact_to_Account_Role__c)) ||
            (String.isNotBlank(victim.Share_Contact_to_Account_Role__c) && String.isBlank(survivor.Share_Contact_to_Account_Role__c)))
        {
            return AffiliationTriggerHandler.NO_SHARE; // do not proceed
        }

        // if any of the two is equal to No Share, return no share
        if(survivor.Share_Contact_to_Account_Role__c.equalsIgnoreCase(AffiliationTriggerHandler.NO_SHARE) || 
            victim.Share_Contact_to_Account_Role__c.equalsIgnoreCase(AffiliationTriggerHandler.NO_SHARE)) 
        {
            return AffiliationTriggerHandler.NO_SHARE;
        }

        // if any of the two is equal to read, return read
        if(survivor.Share_Contact_to_Account_Role__c.equalsIgnoreCase(AffiliationTriggerHandler.READ_SHARE) || 
            victim.Share_Contact_to_Account_Role__c.equalsIgnoreCase(AffiliationTriggerHandler.READ_SHARE)) 
        {
            return AffiliationTriggerHandler.READ_SHARE;
        }
        
        return returnVal;
    }
    
    private AffiliationMergeUtility() { }

    public class AffiliationMergeUtilityException extends Exception { }
}