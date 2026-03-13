/*******************************************************************************
 * @author       Shalini mendu
 * @date         02 Dec 2019
 * @group        Service class
 * @description  SFTN-364-CRM Applications from channels: Match Duplicate-Service class which the duplicate Contact records matching the Contact_Perfect_Match rule
 *               and either inserts/updates depending on whether the contact was new/existing in CRM.
 * 2023-03-20	Ken McGuire - country of birth replace ISO with SAAC
 * 2023-08-09   Vinothraja - Changed to without sharing mode to accomodate APNG users (Portal users with limited access to only their contacts)
 *                verify whether their Applicant already exists in Monash database
 *******************************************************************************/
public without sharing class PerfectMatchingContactFinder {

    static String DUPLICATE_PERFECT_MATCH_NAME = 'Contact_Perfect_Match';
    static String DUPLICATE_POTENTIAL_MATCH_NAME = 'Contact_Potential_Match';
    Contact conRecord;
    Contact latestConRecord;

    public class TRACELOG_Exception extends Exception {
        public override string getStackTraceString(){
            return '';
        }
    }  
    
    List<Contact> matchedContacts;
    String perfectdupRuleName;
    String potentialdupRuleName;

    /**
     * @description  init method to initialize the variables
     * @param conList : Incoming Contact
     * @return void
     */
    public PerfectMatchingContactFinder(Contact con) {
        this.conRecord = con;
        this.matchedContacts = new List<Contact>();

        this.PerfectdupRuleName = DUPLICATE_PERFECT_MATCH_NAME;
    	this.PotentialdupRuleName = DUPLICATE_POTENTIAL_MATCH_NAME;
    }

    /**
     * @description  Handle matching Contacts
     * @return Id : Id of the Contact which has been inserted/Updated
     */
    public Id handleMatchingContacts() {
        Boolean hasPreviousId = this.conRecord.previous_monash_id__c!=null; // a previous monash id is available for a secondary search if required
		Boolean perfectMatch = false; // a perfect match has yet to be found
        String addStr = '';

        List<Datacloud.FindDuplicatesResult> fdupResults =
                Datacloud.FindDuplicates.findDuplicates(new List<Contact>{
                        this.conRecord
                });

        for (Datacloud.FindDuplicatesResult fdr : fdupResults) {
            for (Datacloud.DuplicateResult dr : fdr.getDuplicateResults()) {

                if (dr.getDuplicateRule().equals(this.perfectdupRuleName)) {
                    List<Datacloud.MatchResult> mrList = dr.getMatchResults();
                    if (!mrList.isEmpty()) {
                        for (Datacloud.MatchRecord mRecord : mrList[0].getMatchRecords()) {
                            this.matchedContacts.add((Contact) mRecord.getRecord());
                            perfectMatch = true;
                        }
                    }
                }  else {
                    if (!perfectMatch && hasPreviousId && dr.getDuplicateRule().equals(this.potentialDupRuleName)) {
                        List<Datacloud.MatchResult> mrList = dr.getMatchResults();
                        if(!mrList.isEmpty()) {
                            for (Datacloud.MatchRecord mRecord : mrList[0].getMatchRecords()) {
								Contact fndCon = (Contact) mRecord.getRecord();
                                if (previousIdMatch(fndCon)){
                                    this.matchedContacts.add(fndCon);
                                    addStr = ' (Elevated)';
                                }
                            }
                        }
                    }
                }
            }
        }

        //If there were pre existing Contacts, then get the latest Contact by LastModified date
        //& update it with the information from the incoming Contact payload.
        if (this.matchedContacts.size() > 0) {
            this.latestConRecord = getLatestContactByLastModifiedDate();
            this.conRecord = updateLatestContact(this.latestConRecord, this.conRecord);
            nebula.logger.info('Contact updated' + addStr,this.conRecord.Id);

            //If there were NO pre existing Contacts, then  insert the Contact
        } else if (this.matchedContacts.size() == 0) {
            insert this.conRecord;
            nebula.logger.info('Contact inserted', this.conRecord.Id);
        }
        
        nebula.logger.saveLog();
        return this.conRecord.Id;
    }
    
    /**
     * @description  Update an existing Contact
     * @param latestConRecord :  Pre existing Contact which has to be updated
     * @param ibConRecord : Incoming Contact record whose details are needed to update from
     * @return Contact :  The updated contact record
     */
    public Contact updateLatestContact(Contact latestConRecord, Contact ibConRecord)
    {
        //UPDATE the latest contact with all the details from the incoming contact
        latestConRecord.LastName = ibConRecord.LastName;
        latestConRecord.Birthdate = ibConRecord.Birthdate;
        latestConRecord.MobilePhone = ibConRecord.MobilePhone;
        latestConRecord.SourceId__c = ibConRecord.SourceId__c;
        latestConRecord.Salutation = ibConRecord.Salutation;
        latestConRecord.Gender__c = ibConRecord.Gender__c;
        latestConRecord.Previous_Monash_ID__c = ibConRecord.Previous_Monash_ID__c;
        latestConRecord.Previously_Studied_at_Monash__c = ibConRecord.Previously_Studied_at_Monash__c;
        latestConRecord.MailingStreet = ibConRecord.MailingStreet;
        latestConRecord.MailingCity = ibConRecord.MailingCity;
        latestConRecord.MailingState = ibConRecord.MailingState;
        latestConRecord.MailingCountry = ibConRecord.MailingCountry;
        latestConRecord.MailingPostalCode = ibConRecord.MailingPostalCode;
        latestConRecord.HomePhone = ibConRecord.HomePhone;
        latestConRecord.Phone = ibConRecord.Phone;
        latestConRecord.Residency_Status__c = ibConRecord.Residency_Status__c;
        latestConRecord.HasDisabilities__c = ibConRecord.HasDisabilities__c;
        latestConRecord.Email = ibConRecord.Email;
        latestConRecord.Personal_Email__c = ibConRecord.Personal_Email__c;
        latestConRecord.Preferred_Name__c = ibConRecord.Preferred_Name__c;
        latestConRecord.Country_Of_Birth__c = ibConRecord.Country_Of_Birth__c;
        latestConRecord.CountryOfBirth__c = ibConRecord.CountryOfBirth__c;
        latestConRecord.Pronouns_v2__c =  ibConRecord.Pronouns_v2__c;
        latestConRecord.Previous_Surname__c =  ibConRecord.Previous_Surname__c;
        
        update latestConRecord;
        return latestConRecord;
    }

    /**
     * @description  Get the latest Contact by LastModified Date
     * @param dupConListSize :  Size of the duplicates found
     * @return Contact :  The latest Contact sorted by  LastModified Date
     */
    public Contact getLatestContactByLastModifiedDate() {
        return [SELECT id, CRM_Id__c, Previous_CRM_Ids__c, LastName,Birthdate,MobilePhone,SourceId__c,Salutation,Gender__c,Previous_Monash_ID__c,Previously_Studied_at_Monash__c,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode,HomePhone,Phone,Residency_Status__c,HasDisabilities__c,Email,Personal_Email__c,Person_ID_unique__c,Account_Record_Type_Name__c 
                from Contact 
                where Id in :this.matchedContacts 
                order by LastModifiedDate desc limit 1];
    }

    /**
     * @description Find matching Contacts
     * @return List<Contact> : Contact records returned from the matching rule
     */
    public List<Contact> findMatchingContacts() {
		Boolean hasPreviousId = this.conRecord.previous_monash_id__c!=null; // a previous monash id is available for a secondary search if required
		Boolean perfectMatch = false; // a perfect match has yet to be found

        //find matching contacts
        List<Datacloud.FindDuplicatesResult> fdupResults = Datacloud.FindDuplicates.findDuplicates(new List<Contact> {
            this.conRecord
        });

        //find matching contact using ootb matching and duplicate rules
        for (Datacloud.FindDuplicatesResult fdr : fdupResults) {
            for (Datacloud.DuplicateResult dr : fdr.getDuplicateResults()) {
                if(dr.getDuplicateRule().equals(this.perfectdupRuleName)) {
                    List<Datacloud.MatchResult> mrList = dr.getMatchResults();
                    if(!mrList.isEmpty()) {
                        for (Datacloud.MatchRecord mRecord : mrList[0].getMatchRecords()) {
                            Contact fndCon = (Contact) mRecord.getRecord();
                            perfectMatch = true;
                            this.matchedContacts.add((Contact) mRecord.getRecord());
                        }
                    }
                } else {
                    if (!perfectMatch && hasPreviousId && dr.getDuplicateRule().equals(this.potentialDupRuleName)) {
                        List<Datacloud.MatchResult> mrList = dr.getMatchResults();
                        if(!mrList.isEmpty()) {
                            for (Datacloud.MatchRecord mRecord : mrList[0].getMatchRecords()) {
								Contact fndCon = (Contact) mRecord.getRecord();
                                if (previousIdMatch(fndCon)){
                                    this.matchedContacts.add(fndCon);
                                }
                            }
                        }
                    }
                }
            }
        }

        return this.matchedContacts;
    }
    
    /*
	 * SOQL in a loop work-around.
	 */    
    public Boolean previousIdMatch (Contact fnd) {
        Contact fndCon = [select person_id__c from contact where id = :fnd.id];      
        return fndCon.person_id__c == this.conRecord.Previous_Monash_ID__c;
    }

    /**
     * @description     Retrieve additional record details
     * @return          Contact : Contact record/s returned from the matching rule
     */
    public Contact retrieveResultContactDetails() {
        Integer firstRecord = 0;
        List<Contact> resultingContact = new ContactsSelector().selectById(new Set<Id>{this.matchedContacts[firstRecord].Id});
        return resultingContact[firstRecord];
    }

    /**
     * @description     Retrieve additional record details
     * @return          Application__c : related application
     */
    public Application__c retrieveResultApplicationDetails() {
        Integer firstRecord = 0;
        Application__c resultingApplication;

        //retrieve related applications
        List<Application__c> resultingApplicationsList = new ApplicationsSelector().selectByApplicantId(new Set<Id>{this.matchedContacts[firstRecord].Id});
        if(!resultingApplicationsList.isEmpty()){
            resultingApplication = resultingApplicationsList[firstRecord];
        }
        
        return resultingApplication;
    }
}