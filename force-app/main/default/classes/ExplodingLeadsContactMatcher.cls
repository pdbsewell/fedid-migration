/**
 * @description       : For linking SPS records into a Contact (match if exists, create new if no match)
 * @author            : Nick Guia
 * @date              : 14-09-2020
 * @group             : Lead Management
 * @last modified on  : 04-07-2023
 * @last modified by  : Nick Guia
**/
public virtual without sharing class ExplodingLeadsContactMatcher extends ContactMatcher implements ILatestPicker {

    @TestVisible
    private List<Staged_Prospective_Student__c> spsList;
    @TestVisible
    protected List<Contact> newContactList;
    @TestVisible
    protected List<Contact> updateContactList;

    public ExplodingLeadsContactMatcher(List<Staged_Prospective_Student__c> spsRecs) {
        super();
        init();
        this.spsList = spsRecs;
    }

    public ExplodingLeadsContactMatcher(Staged_Prospective_Student__c sps) {
        super();
        init();
        this.spsList = new List<Staged_Prospective_Student__c> { sps };
    }

    /**
     * @description initialise variables
     */
    private void init() {
        this.newContactList = new List<Contact>();
        this.updateContactList = new List<Contact>();
    }

    /**
     * @description run step-by-step procedure for finding duplicate contacts
     */
    public override void run() {
        //STEP 1: build wrapper classes of Contacts and SPS with the same unique key
        this.buildContactMatchWrapper();
        //STEP 2: Create a concrete Contact object for each warpper that has been consolidated
        buildContacts();
        //STEP 3: Get all matching contacts from the Database
        runDuplicateRules();
        //STEP 4: Re-query records to get the "latest-greatest"
        queryDuplicateContactDetails();
        //STEP 5: determine the "latest-greatest" contact
        this.getLatest();
        //STEP 6: Insert new Contacts (if any), and log exceptions
        saveNewContacts();
        //STEP 7: Propagate latest Contact ID to related SPS records
        propagateContactIdsToSps();
    }

    /**
     * @description return all SPS records. This is used after propagating Contact IDs
     * into these records
     * @return List<Staged_Prospective_Student__c> sps records with Contact IDs
     */
    public List<Staged_Prospective_Student__c> getSpsRecords() {
        List<Staged_Prospective_Student__c> spsRecords = new List<Staged_Prospective_Student__c>();
        for(String key : super.contactMatchByKey.keySet()) {
            SpsDuplicateContact spsDc = (SpsDuplicateContact) super.contactMatchByKey.get(key);
            spsRecords.addAll(spsDc.spsList);
        }
        return spsRecords;
    }

    /**
     * @description build wrapper classes of Contacts and SPS with the same unique key
     */
    @TestVisible
    protected override void buildContactMatchWrapper() {

        for(Staged_Prospective_Student__c iSps : this.spsList) {
            if(String.isNotBlank(iSps.First_Name__c) &&
                String.isNotBlank(iSps.Last_Name__c) &&
                String.isNotBlank(iSps.Email__c))
            {
                //build unique key : FirstName ::: LastName ::: Email combination
                String spsKey = StagedProspectiveStudentUtil.buildMatchingKey(iSps.First_Name__c, iSps.Last_Name__c, iSps.Email__c);

                //check if wrapper already exists
                SpsDuplicateContact wrap = (SpsDuplicateContact) super.contactMatchByKey.get(spsKey);

                if(wrap == null) {
                    //if not, create a new instance
                    wrap = new SpsDuplicateContact(iSps);
                    super.contactMatchByKey.put(spsKey, wrap);
                } else {
                    //otherwise, add sps details to existing instance
                    wrap.spsList.add(iSps);
                }
            }
        }
    }

    /**
     * @description Create a concrete Contact object for each warpper that has been consolidated
     */
    @TestVisible
    private void buildContacts() {
        for(String key : super.contactMatchByKey.keySet()) {
            SpsDuplicateContact spsDc = (SpsDuplicateContact) super.contactMatchByKey.get(key);
            Staged_Prospective_Student__c mergedSps = spsDc.getMergedSps();
            spsDc.con = new ExplodingLeadsFactoryV2(mergedSps).buildProspectiveContact();
            if(super.isCheckAllEmailFields) {
                spsDc.con = super.setAllEmailFields(spsDc.con);
            }
            super.contactsByKey.put(key, spsDc.con);
        }
    }

    /**
     * @description Re-query records to get the "latest-greatest"
     */
    @TestVisible
    private void queryDuplicateContactDetails() {
        if(!super.duplicateContacts.isEmpty()) {
            super.duplicateContacts = new Map<Id, Contact>(
                [SELECT Id, FirstName, LastName, Email, Monash_Email_Address__c, Nationality__c,
                    Personal_Email__c, Birthdate, AccountId, Gender__c, Country_of_Residence__c, 
                    LastModifiedDate, CreatedDate, Birth_year__c
                    FROM Contact 
                    WHERE Id IN :super.duplicateContacts.keySet()]
            );
        }
    }

    /**
     * @description determine the "latest greatest" contact
     */
    public override void getLatest() {
        for(String key : super.contactMatchByKey.keySet()) {
            SpsDuplicateContact spsDc = (SpsDuplicateContact) super.contactMatchByKey.get(key);
            Contact latest = spsDc.con; //if no match, get the original Contact
            if(spsDc.hasDuplicates()) {
                if(spsDc.matchedContactRecords.size() == 1) {
                    //if only 1 match found, return that record
                    latest = spsDc.matchedContactRecords[0];
                } else {
                    //if multiple matches found, get the latest LastModifiedDate
                    List<Contact> matchedContacts = new List<Contact>();
                    for(Contact iCon : spsDc.matchedContactRecords) {
                        matchedContacts.add(super.duplicateContacts.get(iCon.Id));
                    }

                    List<Contact> latestGreatest = getLatestLastModified(matchedContacts);
                    if(latestGreatest.size() > 1) {
                        //if multiple latest LastModifiedDate was found, get the latest CreatedDate
                        latestGreatest = getLatestCreatedDate(latestGreatest);
                    }
                    //if multiple latest CreatedDate was found, return the first index
                    latest = latestGreatest[0];
                }
            } else if(super.isCheckAllEmailFields) {
                latest = super.clearEmailFields(latest);
            }
            
            if(super.duplicateContacts.containsKey(latest.Id)) {
                latest = super.duplicateContacts.get(latest.Id);
            }
            //add new information to existing contact if the field is blank
            spsDc.con = new ExplodingLeadsFactoryV2().mergeProspectiveContact(latest, spsDc.con);

            if(spsDc.con.Id == null) {
                this.newContactList.add(spsDc.con);
            } else {
                this.updateContactList.add(spsDc.con);
            }
        }
    }

    /**
     * @description Insert new Contacts (if any), and log any exceptions
     */
    @TestVisible
    private void saveNewContacts() {
        List<Database.SaveResult> srList = new List<Database.SaveResult>();
        if(!this.newContactList.isEmpty()) {
            srList.addAll(Database.insert(this.newContactList, false));
        } else if(!this.updateContactList.isEmpty()) {
            srList.addAll(Database.update(this.updateContactList, false));
        }

        for(Database.SaveResult iRes : srList) {
            for(Database.Error iError : iRes.getErrors()) {
                LogUtilityException.addLogEvent(
                    'Exploding Leads',
                    iRes.getId(),
                    iError,
                    'ExplodingLeadsContactMatcher'
                );
            }
        }
        LogUtilityException.publishAll();
    }

    /**
     * @description Propagate latest Contact ID to related SPS records
     */
    @TestVisible
    private void propagateContactIdsToSps() {
        for(String key : super.contactMatchByKey.keySet()) {
            SpsDuplicateContact spsDc = (SpsDuplicateContact) super.contactMatchByKey.get(key);
            spsDc.propagateContactIds();
        }
    }
}