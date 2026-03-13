/**
 * @description       : For linking Attendee records with a Contact (match if exists, create new if no match)
 * @author            : Nick Guia
 * @date              : 14-10-2020
 * @group             : Event Management
 * @last modified on  : 03-07-2023
 * @last modified by  : Nick Guia
**/
public virtual without sharing class BTAttendeeContactMatcher extends ContactMatcher implements ILatestPicker 
{

    @TestVisible
    private List<conference360__Attendee__c> attList;
    @TestVisible
    protected List<Contact> newContactList;

    public BTAttendeeContactMatcher(List<conference360__Attendee__c> attendeeRecs) {
        super();
        init();
        this.attList = attendeeRecs;
        
    }

    public BTAttendeeContactMatcher(conference360__Attendee__c attendeeRec) {
        super();
        init();
        this.attList = new List<conference360__Attendee__c> { attendeeRec };
    }

    /**
     * @description run step-by-step procedure for finding duplicate contacts
     */
    public override void run() {
        //STEP 1: build wrapper classes of Contacts and Attendees with the same unique key
        this.buildContactMatchWrapper();
        //STEP 2: Get all matching contacts from the Database
        runDuplicateRules();
        //STEP 3: Re-query records to get the "latest-greatest"
        queryDuplicateContactDetails();
        //STEP 4: determine the "latest-greatest" contact
        this.getLatest();
        //STEP 5: Insert new Contacts (if any), and log exceptions
        saveNewContacts();
        //STEP 6: Propagate latest Contact ID to related Attendee records
        propagateContactIds();
    }

    /**
     * @description build wrapper classes of Contacts and Attendee with the same unique key
     */
    @TestVisible
    protected override void buildContactMatchWrapper() {
        List<BTEventAttendeeDAO> evAtDAO = new BTEventAttendeeDAOHelper(this.attList).generateEventAttendeeDAO();

        for(BTEventAttendeeDAO iDao : evAtDAO) {
            //[EPBBS-2030] - Migrate logic for affiliation calculation from Attendee to Event
            String affiliation = iDao.getEvent().Winning_Affiliation__c;
            conference360__Attendee__c iAtt = iDao.getAttendee();

            if(String.isNotBlank(iAtt.conference360__First_Name2__c) &&
                String.isNotBlank(iAtt.conference360__Last_Name2__c) &&
                String.isNotBlank(iAtt.conference360__Email2__c))
            {
                //build unique key : FirstName ::: LastName ::: Email combination
                String attKey = StagedProspectiveStudentUtil.buildMatchingKey(iAtt.conference360__First_Name2__c, iAtt.conference360__Last_Name2__c, iAtt.conference360__Email2__c);

                //check if wrapper already exists
                BTAttendeeDuplicateContact wrap = (BTAttendeeDuplicateContact) super.contactMatchByKey.get(attKey);

                if(wrap == null) {
                    //if not, create a new instance
                    wrap = new BTAttendeeDuplicateContact(iAtt);
                    super.contactMatchByKey.put(attKey, wrap);
                    if(super.isCheckAllEmailFields) {
                        wrap.con = super.setAllEmailFields(wrap.con);
                    }

                    /**
                     * if winning affiliation is Prospective Student, set new Contact's record type to that.
                     * for existing (matched) Contacts, and non PS record type, do not update record type
                     */
                    if(String.isNotBlank(affiliation) && affiliation.equalsIgnoreCase(BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT)) {
                        wrap.con.RecordTypeId = StagedProspectiveStudentUtil.CONTACT_RECTYPE_PROPECTIVESTUDENT;
                    }
                    super.contactsByKey.put(attKey, wrap.con);
                } else {
                    //otherwise, add sps details to existing instance
                    wrap.attList.add(iAtt);
                }
            }
        }
    }

    /**
     * @description Re-query records to get the "latest-greatest"
     */
    @TestVisible
    private void queryDuplicateContactDetails() {
        if(!super.duplicateContacts.isEmpty()) {
            super.duplicateContacts = new Map<Id, Contact>(
                [SELECT Id, FirstName, LastName, Email, Monash_Email_Address__c, Personal_Email__c,
                LastModifiedDate, CreatedDate
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
            BTAttendeeDuplicateContact dc = (BTAttendeeDuplicateContact) super.contactMatchByKey.get(key);
            Contact latest = dc.con; //if no match, get the original Contact
            if(dc.hasDuplicates()) {
                if(dc.matchedContactRecords.size() == 1) {
                    //if only 1 match found, return that record
                    latest = dc.matchedContactRecords[0];
                } else {
                    //if multiple matches found, get the latest LastModifiedDate
                    List<Contact> matchedContacts = new List<Contact>();
                    for(Contact iCon : dc.matchedContactRecords) {
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
            dc.con = latest;

            if(dc.con.Id == null) {
                this.newContactList.add(dc.con);
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
        }

        for(Database.SaveResult iRes : srList) {
            for(Database.Error iError : iRes.getErrors()) {
                LogUtilityException.addLogEvent(
                    'Blackthorn',
                    iRes.getId(),
                    iError,
                    'BTAttendeeContactMatcher'
                );
            }
        }
        LogUtilityException.publishAll();
    }

    /**
     * @description Propagate latest Contact ID to related Attendee records
     */
    @TestVisible
    private void propagateContactIds() {
        for(String key : super.contactMatchByKey.keySet()) {
            BTAttendeeDuplicateContact dc = (BTAttendeeDuplicateContact) super.contactMatchByKey.get(key);
            dc.propagateContactIds();
        }
    }

    /**
     * @description initialise variables
     */
    private void init() {
        this.newContactList = new List<Contact>();
    }
}