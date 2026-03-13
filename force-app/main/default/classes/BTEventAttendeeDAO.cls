/**
* @author Nick Guia
* @date 19.01.2021
* @group Event Management
* @description DAO class Attendee -> Event relationship
* @revision 
        16.02.2022   RANAND    [EPBBS-2030] removed analyseAudiencetype method for affiliation
*/
public virtual inherited sharing class BTEventAttendeeDAO {

    @TestVisible
    private conference360__Event__c btEvent;
    @TestVisible
    private conference360__Attendee__c btAttendee;
    @TestVisible
    private conference360__Event_Settings__c btEventSetting;
    

    public BTEventAttendeeDAO(conference360__Event__c ev, conference360__Attendee__c at) {
        this.btEvent = ev;
        this.btAttendee = at;
    }

    public BTEventAttendeeDAO(conference360__Event__c ev, conference360__Attendee__c at,conference360__Event_Settings__c evset) {
        this.btEvent = ev;
        this.btAttendee = at;
        this.btEventSetting = evset;
    }

    public conference360__Event__c getEvent() {
        return this.btEvent;
    }

    public conference360__Attendee__c getAttendee() {
        return this.btAttendee;
    }

    public conference360__Event_Settings__c getEventSetting(){
        return this.btEventSetting;
    }
}