/**
 * @author Nick Guia
 * @date 14-09-2020
 * @group Commons
 * @description for finding exact, potential, or loose match for Contacts. 
 *  This class is dependent on the existing configured duplicate and matching rules.
 **/
public virtual without sharing class ContactMatcher implements ILatestPicker {

    @TestVisible
    protected List<Contact> conInp;
    @TestVisible
    protected Map<String, Contact> contactsByKey;
    @TestVisible
    protected Map<Id, Contact> duplicateContacts;
    @TestVisible
    protected String duplicateRuleName;
    @TestVisible
    protected Map<String, DuplicateContact> contactMatchByKey;
    @TestVisible
    private Set<String> emailFields;
    @TestVisible
    protected Boolean isCheckAllEmailFields = false;

    public ContactMatcher(List<Contact> conRecs) {
        conInp = conRecs;
        initialise();
    }

    public ContactMatcher(Contact conRec) {
        conInp = new List<Contact> { conRec };
        initialise();
    }

    protected ContactMatcher() {
        initialise();
    }

    /**
     * @description "mock" the other email fields with what exists in the
     * standard email field so that the matching rules would pick them up
     */
    public void findAllEmailFields() {
        if(this.conInp != null) {
            for(Contact iCon : this.conInp) {
                iCon = setAllEmailFields(iCon);
            }
        }
        this.isCheckAllEmailFields = true;
    }

    /**
     * @description run the duplicate matching logic and store results
     */
    public virtual void run() {
        //build wrapper classes of Contacts
        buildContactMatchWrapper();
        //Get all matching contacts from the Database
        runDuplicateRules();
        //determine the "latest-greatest" contact
        getLatest();
    }

    /**
     * @description defaults to Loose Contact Matching when not set
     */
    public void setDuplicateRuleName(String dupeRule) {
        this.duplicateRuleName = dupeRule;
    }

    /**
     * @description returns the list of duplicate wrappers
     */
    public List<DuplicateContact> getDuplicateResult() {
        return this.contactMatchByKey.values();
    }

    /**
     * @description returns the map of duplicate wrappers
     */
    public Map<String, DuplicateContact> getDuplicateResultMap() {
        return this.contactMatchByKey;
    }

    /**
     * @description build a wrapper class (DuplicateContact) out of each contact record
     * from input. Minimum details are FN, LN, and Email which are used to build a unique key
     */
    protected virtual void buildContactMatchWrapper() {
        for(Contact iCon : this.conInp) {
            if(String.isNotBlank(iCon.FirstName) &&
               String.isNotBlank(iCon.LastName) &&
               String.isNotBlank(iCon.Email))
            {
                //build unique key : FirstName ::: LastName ::: Email combination
                String uniqueKey = StagedProspectiveStudentUtil.buildMatchingKey(iCon.FirstName, iCon.LastName, iCon.Email);
                DuplicateContact wrap = new DuplicateContact(iCon);
                this.contactMatchByKey.put(uniqueKey, wrap);
                this.contactsByKey.put(uniqueKey, iCon);
            }
        }
    }

    /**
     * @description Get all matching contacts from the Database
     */
    @TestVisible
    protected virtual void runDuplicateRules() {
        //this FindDuplicatesResult list will be in the same order as input
        List<Datacloud.FindDuplicatesResult> fdrList = Datacloud.FindDuplicates.findDuplicates(this.contactsByKey.values());
        List<Contact> dupeContactList = new List<Contact>();
        Integer ctr = 0;

        for(String key : this.contactsByKey.keySet()) {

            DuplicateContact dc = this.contactMatchByKey.get(key);
            Datacloud.FindDuplicatesResult fdr = fdrList[ctr];
            List<Contact> dcMatchedContacts = new List<Contact>();

            for(Datacloud.DuplicateResult dr : fdr.getDuplicateResults()) {
                //only collect duplicate record if it was found  by the duplicate rule indicated
                if(dr.getDuplicateRule().equals(this.duplicateRuleName)) {
                    List<Datacloud.MatchResult> mrList = dr.getMatchResults();
                    if(!mrList.isEmpty()) {
                        for(Datacloud.MatchRecord mRecord : mrList[0].getMatchRecords()) {
                            Contact matchedCon = (Contact) mRecord.getRecord();
                            dcMatchedContacts.add(matchedCon);
                        }
                    }
                }
            }

            dc.matchedContactRecords = dcMatchedContacts;
            dupeContactList.addAll(dcMatchedContacts);
            ctr++;
        }

        if(!dupeContactList.isEmpty()) {
            this.duplicateContacts = new Map<Id, Contact>(dupeContactList);
        }
    }

    /**
     * @description determine the "latest greatest" contact
     */
    public virtual void getLatest() {
        for(String key : this.contactMatchByKey.keySet()) {
            DuplicateContact dc = this.contactMatchByKey.get(key);
            Contact latest = dc.con; //if no match, get the original Contact
            if(dc.hasDuplicates()) {
                //if match found, get the first match
                latest = dc.matchedContactRecords[0];
            } else if(this.isCheckAllEmailFields) {
                //if we mocked the other email fields, clear them before returning the constructed contact
                latest = clearEmailFields(latest);
            }
            dc.con = latest;
        }
    }

    /**
     * @description get the list of contacts with max LastModifiedDate
     * @param conList : list of contacts to be processed
     * @return List<Contact> : contacts with latest, and similar LastModifiedDate 
     */
    @TestVisible
    public List<Contact> getLatestLastModified(List<Contact> conList) {
        return getMaxByDate(conList, 'LastModifiedDate');
    }

    /**
     * @description get the list of contacts with max CreatedDate
     * @param conList : list of contacts to be processed
     * @return List<Contact> : contacts with latest, and similar CreatedDate 
     */
    @TestVisible
    public List<Contact> getLatestCreatedDate(List<Contact> conList) {
        return getMaxByDate(conList, 'CreatedDate');
    }

    /**
     * @description get the list of contacts with max CreatedDate
     * @param conList : list of contacts to be processed
     * @param dateField : String value of API name of date field to be checked
     * @return List<Contact> : contacts with latest, and similar dateTime 
     */
    @TestVisible
    public List<Contact> getMaxByDate(List<Contact> conList, String dateField) {
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

    @TestVisible
    protected Contact setAllEmailFields(Contact con) {
        for(String iEmailField : this.emailFields) {
            con.put(iEmailField, con.Email);
        }
        return con;
    }

    @TestVisible
    protected Contact clearEmailFields(Contact con) {
        for(String iEmailField : this.emailFields) {
            con.put(iEmailField, null);
        }
        return con;
    }

    /**
     * @description initialise properties
     */
    private void initialise() {
        this.contactsByKey = new Map<String, Contact>();
        this.duplicateContacts = new Map<Id, Contact>();
        this.contactMatchByKey = new Map<String, DuplicateContact>();
        this.duplicateRuleName = Environment_Settings__c.getInstance().Contact_Loose_Match_Duplicate_Rule_Name__c;
        this.emailFields = new Set<String> {
            'Personal_Email__c',
            'Monash_Email_Address__c',
            'Business_Email_Address__c'
        };
    }
}