/**
 * @author Nick Guia
 * @date 10-02-2021
 * @group Event Management
 * @description Helper class for processing Form Submission records into creating Person 360 records
 **/
public virtual inherited sharing class BTFormSubmissionP360Helper {

    @TestVisible
    private Map<Id, Set<Id> > attendeeIdsByEventId;
    @TestVisible
	private Map<Id, Set<Id> > attendeeIdsByContactId;
    @TestVisible
	private Set<Id> allAttendeeIds;

    @TestVisible
    private Map<Id, conference360__Attendee__c> attendeeMap;
    @TestVisible
    private Map<Id, conference360__Event__c> eventMap;
    @TestVisible
    private Map<Id, Contact> conMap;

    @TestVisible
    private BTAttendeeSelector attendeeSelector;

    public BTFormSubmissionP360Helper() {
        this.attendeeIdsByEventId = new Map<Id, Set<Id> >();
        this.attendeeIdsByContactId = new Map<Id, Set<Id> >();
        this.allAttendeeIds = new Set<Id>();
    }

    /**
     * @description collect attendee, Event, and Contact details from the record
     * @param fs : Form Submission record.
     */
    public void collectFormSubmissionDetails(conference360__Form_Submission__c fs) {
        //collect Attendee ID
        this.allAttendeeIds.add(fs.conference360__Attendee__c);
        
        //collect attendee ID mapped by Event ID
        Set<Id> attendeeIds = this.attendeeIdsByEventId.get(fs.conference360__Event__c);
        if(attendeeIds == null) {
            attendeeIds = new Set<Id>();
        }
        attendeeIds.add(fs.conference360__Attendee__c);
        this.attendeeIdsByEventId.put(fs.conference360__Event__c, attendeeIds);
    }

    /**
     * @description check of form submission record contains custom
     *  form elements. If it doesn't contain any, the "Processed" checkbox
     *  won't update to TRUE, hence, process immediately
     * @param fs : Form Submission record.
     */
    public void collectNoCustomFormElement(conference360__Form_Submission__c fs) {
        if(String.isNotBlank(fs.conference360__Payload__c)) {
            Map<String, Object> payload = 
                (Map<String, Object>) 
                    JSON.deserializeUntyped(fs.conference360__Payload__c);
            if(!payload.containsKey('formElements') || payload.get('formElements') == null) {
                collectFormSubmissionDetails(fs);
            }
        }
    }

    /**
     * @description collect all attendee, events, and contact details,
     *  generate DAO classes for them, then invoke the creation of
     *  SPS / P360
     */
    public void createPerson360() {
        try {
            if(!this.attendeeIdsByEventId.isEmpty()) {
                List<BTContactAttendeeDAO> daoList = selectAttendees()
                                                    .buildContactMap()
                                                    .selectEvents()
                                                    .selectContacts()
                                                    .generateContactAttendeeDAO();
                if(!daoList.isEmpty()) {
                    //TODO : create a queueable class for this
                    BTAttendeeServices service = new BTAttendeeServices();
                    service.createAttendeePerson360(daoList);
                }
            }
        } catch(Exception e) {
            throw new BTFormSubmissionP360HelperException('An error occurred while processing Person 360 records', e);
        }
    }

    /**
     * @description query attendee records
     */
    @TestVisible
    private BTFormSubmissionP360Helper selectAttendees() {
        this.attendeeSelector = new BTAttendeeSelector();
        this.attendeeMap = attendeeSelector.selectMapById(this.allAttendeeIds);
        return this;
    }

    /**
     * @description map all attendees related to the same contact.
     *  this is to be able to create a DAO class for each
     *  Contact record with all it's related Attendee records
     */
    @TestVisible
    private BTFormSubmissionP360Helper buildContactMap() {
        for(conference360__Attendee__c iAtt : this.attendeeMap.values()) {
            if(iAtt.conference360__Contact__c != null) {
                Set<Id> attendeesWithSameContact = this.attendeeIdsByContactId.get(iAtt.conference360__Contact__c);
                if(attendeesWithSameContact == null) {
                    attendeesWithSameContact = new Set<Id>();
                }
                attendeesWithSameContact.add(iAtt.Id);
                this.attendeeIdsByContactId.put(iAtt.conference360__Contact__c, attendeesWithSameContact);
            }
        }
        return this;
    }

    /**
     * @description requery events to get audience type
     */
    @TestVisible
    private BTFormSubmissionP360Helper selectEvents() {
        this.eventMap = new Map<Id, conference360__Event__c>(
            [SELECT Id, Audience_Type__c, conference360__Campaign__c, Winning_Affiliation__c, Broad_Area_of_Interest_Update_Mode__c  
             FROM conference360__Event__c
             WHERE Id IN: this.attendeeIdsByEventId.keySet()]
        );
        return this;
    }

    /**
     * @description requery Contacts and existing active affiliations
     */
    @TestVisible
    private BTFormSubmissionP360Helper selectContacts() {
        this.conMap = new Map<Id, Contact>(
            [SELECT FirstName, LastName, Email, Monash_Email_Address__c, Nationality__c,
                Personal_Email__c, Birthdate, AccountId, Gender__c, Country_of_Residence__c, 
                Birth_year__c,
             (SELECT Id, RecordType.DeveloperName
              FROM Affiliations__r
              WHERE Is_Active__c = TRUE)
             FROM Contact
             WHERE Id IN: this.attendeeIdsByContactId.keySet()]
            );
        return this;
    }

    /**
     * @description create a dao class for each Contact and attendee
     */
    @TestVisible
    private List<BTContactAttendeeDAO> generateContactAttendeeDAO() {
        List<BTContactAttendeeDAO> daoList = new List<BTContactAttendeeDAO>();
        for(Id iConId : this.conMap.keySet()) {
            Contact con = this.conMap.get(iConId);
            BTContactAttendeeDAO dao = new BTContactAttendeeDAO(con);

            for(Id iAttendeeId : this.attendeeIdsByContactId.get(iConId)) {
                conference360__Attendee__c iAtt = this.attendeeMap.get(iAttendeeId);
                conference360__Event__c btEvent = this.eventMap.get(iAtt.conference360__Event__c);
                dao.addEventAttendee(btEvent, iAtt);
            }
            daoList.add(dao);
        }
        return daoList;
    }

    public class BTFormSubmissionP360HelperException extends Exception { }
}