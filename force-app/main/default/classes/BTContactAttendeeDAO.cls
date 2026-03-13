/**
* @author Nick Guia
* @date 19.01.2021
* @group Event Management
* @description DAO class Blackthorn Contact -> Attendee -> Event relationship
*/
public virtual inherited sharing class BTContactAttendeeDAO {

    public List<BTEventAttendeeDAO> eventAttendeeDAO {get; set;}
    @TestVisible
    private Contact conRecord;
    @TestVisible
    private Map<String, Affiliation__c> affiliationMapByRecordType;
    @TestVisible
    private Set<String> newAffiliations;

    public BTContactAttendeeDAO(Contact con) {
        this.eventAttendeeDAO = new List<BTEventAttendeeDAO>();
        this.newAffiliations = new Set<String>();
        this.conRecord = con;
    }

    /**
     * @description add new instance of BTEventAttendeeDaO within the structure
     */
    public void addEventAttendee(conference360__Event__c ev, conference360__Attendee__c at) {
        //create new instance of DAO
        //[EPBBS-2030] - analyseAudienceType() method is not reuired as Winning Affiliation can be read from Event Object
        BTEventAttendeeDAO evAtDAO = new BTEventAttendeeDAO(ev, at);
        this.eventAttendeeDAO.add(evAtDAO);
    }

    /**
     * @description checks the affiliation has already been created on the fly
     * to prevent any duplicates.
     */
    public Boolean shouldCreateNewAffiliation(BTEventAttendeeDAO evAtDAO) {
        Boolean shouldCreate = false;
        //[EPBBS-2030] - analyseAudienceType() method is not reuired as Winning Affiliation can be read from Event Object
        String affiliationName = evAtDAO.getEvent().Winning_Affiliation__c;
        if(!this.newAffiliations.contains(affiliationName)) {
            shouldCreate = true;
            this.newAffiliations.add(affiliationName);
        }
        return shouldCreate;
    }

    public Contact getContact() {
        return this.conRecord;
    }
}