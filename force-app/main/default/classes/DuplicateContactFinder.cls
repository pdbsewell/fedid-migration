/**
 * @description       : Extensible classs for finding exact, potential, or loose match for Contacts. 
 *                      This class is dependent on the existing configured duplicate and matching rules.
 * @author            : Nick Guia
 * @date              : 08-07-2019
 * @group             : Commons
 * @last modified on  : 04-07-2023
 * @last modified by  : Nick Guia
 * @deprecated
 * @see ContactMatcher.cls instead
**/
public virtual without sharing class DuplicateContactFinder {

    @TestVisible
    protected Contact conRecord; //Contact input
    @TestVisible
    private List<Contact> matchedContacts; //duplicates found
    @TestVisible
    private Map<Id, Contact> matchedContactsById; //duplicates found mapped by ID
    @TestVisible
    private String duplicateRuleName; //duplicate rule name
    @TestVisible
    private Boolean isExplodingLeads;
    
    /**
     * @param con : uninserted Contact which we're going to find duplicates for
     */
    public DuplicateContactFinder(Contact con) {
        init(con);
        this.duplicateRuleName = Environment_Settings__c.getInstance().Contact_Loose_Match_Duplicate_Rule_Name__c;
    }
    
    /**
     * @param con : uninserted Contact which we're going to find duplicates for
     * @param duplicateRuleAPI : API name of the duplicate rule which where we specifically
     *  want to find duplicate results from.
     */
    public DuplicateContactFinder(Contact con, String duplicateRuleAPI) {
        init(con);
        this.duplicateRuleName = duplicateRuleAPI;
    }

    public void enableExplodingLeads() {
        this.isExplodingLeads = true;
    }

    /**
     * @description optionally mock the contact's email fields (Personal_Email__c, and Monash_Email_Address__c).
     *  This is so that "loose" matching rule would also check on these email fields by populating it from the standard
     *  Email field.
     */
    public virtual void mockEmailFields() {
        this.conRecord.Monash_Email_Address__c = this.conRecord.Email;
        this.conRecord.Personal_Email__c = this.conRecord.Email;
    }

    /**
     * @description clear the email fields that has been mocked to kick
     *  off a "Loose Contact Matching"
     */
    public virtual void clearEmailFields() {
        this.conRecord.Monash_Email_Address__c = null;
        this.conRecord.Personal_Email__c = null;
    }

    /**
     * @description main method for collecting duplicate records
     */
    public virtual void findDuplicates() {
        List<Datacloud.FindDuplicatesResult> fdupResults = 
            Datacloud.FindDuplicates.findDuplicates(new List<Contact>{this.conRecord});

        for(Datacloud.FindDuplicatesResult fdr : fdupResults) {
            for (Datacloud.DuplicateResult dr : fdr.getDuplicateResults()) {
                /**
                 * only collect duplicate record if it was found 
                 * by the duplicate rule indicated
                 */
                if(dr.getDuplicateRule().equals(this.duplicateRuleName)) {
                    List<Datacloud.MatchResult> mrList = dr.getMatchResults();
                    if(!mrList.isEmpty()) {
                        for(Datacloud.MatchRecord mRecord : mrList[0].getMatchRecords()) {
                            this.matchedContacts.add((Contact) mRecord.getRecord());
                        }
                    }
                }
            }
        }
        //cast List in map to easily access IDs, then retrieve other fields that we need 
        if(this.matchedContacts.size() > 0) {
            this.matchedContactsById = new Map<Id, Contact>(this.matchedContacts);
            //retrieve contact fields that we need to determine the "latest greatest"
            retrieveContactFields();
        }
    }

    public Boolean isDuplicatesFound() {
        return (getDuplicatesCount() > 0);
    }

    /**
     * @description get duplicate record count
     * @return Integer : count of duplicate records
     */
    public Integer getDuplicatesCount() {
        return this.matchedContacts.size();
    }

    /**
     * @description get the list of found duplicates
     * @return List<Contact> : list of found duplicates
     */
    public List<Contact> getMatchedRecordList() {
        return this.matchedContacts;
    }

    /**
     * @description get the map of found duplicates
     * @return Map<Id, Contact> : map st of found duplicates (by ID)
     */
    public Map<Id, Contact> getMatchedRecordMap() {
        return this.matchedContactsById;
    }

    /**
     * @description determine the "latest greatest" contact based on pre-defined business rule:
     *  1. if no match found, return the original Contact input (from constructor)
     *  2. if only 1 match found, return that record
     *  3. if multiple matches found, get the latest LastModifiedDate
     *  4. if multiple latest LastModifiedDate was found, get the latest CreatedDate
     *  5. if multiple latest CreatedDate was found, return the first index
     * @return Contact : latest Contact record
     */
    public Contact getLatestContact() {
        Contact greatest;
        Integer dupeCount = getDuplicatesCount();
        if(dupeCount == 0) {
            //if no match found, return the original Contact input
            clearEmailFields();
            greatest = this.conRecord;
        } else if(dupeCount == 1) {
            //otherwise return the only result
            greatest = this.matchedContacts[0];
        } else {
            //get the "latest greatest"
            List<Contact> latestGreatest = getLatestLastModified(this.matchedContacts);
            if(latestGreatest.size() > 1) {
                latestGreatest = getLatestCreatedDate(latestGreatest);
            }
            greatest = latestGreatest[0];
        }
        return greatest;
    }

    /**
     * @description get the list of contacts with max LastModifiedDate
     * @param conList : list of contacts to be processed
     * @return List<Contact> : contacts with latest, and similar LastModifiedDate 
     */
    @TestVisible
    private List<Contact> getLatestLastModified(List<Contact> conList) {
        return getMaxByDate(conList, 'LastModifiedDate');
    }

    /**
     * @description get the list of contacts with max CreatedDate
     * @param conList : list of contacts to be processed
     * @return List<Contact> : contacts with latest, and similar CreatedDate 
     */
    @TestVisible
    private List<Contact> getLatestCreatedDate(List<Contact> conList) {
        return getMaxByDate(conList, 'CreatedDate');
    }

    /**
     * @description get the list of contacts with max CreatedDate
     * @param conList : list of contacts to be processed
     * @param dateField : String value of API name of date field to be checked
     * @return List<Contact> : contacts with latest, and similar dateTime 
     */
    @TestVisible
    private List<Contact> getMaxByDate(List<Contact> conList, String dateField) {
        Map<Datetime, List<Contact>> contactsByDate = new Map<Datetime, List<Contact>>();
        Datetime latestDT;
        for (Contact con : conList) {
            Datetime conDate = (DateTime) con.get(dateField);
            if (latestDT == null) {
                latestDT = conDate;
            }
            //add contact to map of DateTime and contact List
            List<Contact> lCon = contactsByDate.get(conDate);
            if (lCon == null) {
                lCon = new List<Contact>();
            }
            lCon.add(con);
            contactsByDate.put(conDate, lCon);

            //check max date
            if (conDate > latestDT) {
                latestDT = conDate;
            }
        }
        return contactsByDate.get(latestDT);
    }

    //initialise variables
    @TestVisible
    private void init(Contact con) {
        this.conRecord = con;
        this.matchedContacts = new List<Contact>();
        this.matchedContactsById = new Map<Id, Contact>();
        this.isExplodingLeads = false;
    }
    
    /**
     * @description retrieve all the contact fields that are requried for
     *  determining the "latest greatest".
     */
    @TestVisible
    private void retrieveContactFields() {
        if(this.isExplodingLeads) {
            //query fields that exploding leads need
            this.matchedContacts = [SELECT Id, FirstName, LastName, Email, Monash_Email_Address__c, Nationality__c,
                                    Personal_Email__c, Birthdate, AccountId, Gender__c, Country_of_Residence__c, 
                                    LastModifiedDate, CreatedDate, Birth_year__c
                                    FROM Contact 
                                    WHERE Id IN :this.matchedContactsById.keySet()];
        } else {
            //if exploding leads is not running, limit the number of fields to save resources
            this.matchedContacts = [SELECT Id, LastModifiedDate, CreatedDate 
                                    FROM Contact 
                                    WHERE Id IN :this.matchedContactsById.keySet()];
        }
        this.matchedContactsById = new Map<Id, Contact>(this.matchedContacts);
    }
}