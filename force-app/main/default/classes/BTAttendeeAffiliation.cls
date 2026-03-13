/**
 * @author Nick Guia
 * @date 15-02-2021
 * @group Event Management
 * @description abstract class for Blackthorn Attendee with Affiliation
 **/
public virtual inherited sharing class BTAttendeeAffiliation {

    @TestVisible
    protected Contact con;
    @TestVisible
    protected conference360__Attendee__c attendee;
    @TestVisible
    protected Person360 p360;

    public BTAttendeeAffiliation(Contact conRec, conference360__Attendee__c attendeeRec) {
        this.con = conRec;
        this.attendee = attendeeRec;
    }

    public virtual void createAttendeePerson360() {
        //PLACEHOLDER FOR OTHER AFFILIATIONS
        // Person360.Person360Builder builder =
        //     new Person360.Person360Builder(this.con)
        //         .withAffiliation('Industry', 'Private', Date.today());
    }

    public virtual void pushRecords(BaseClass bc) {
        //PLACEHOLDER FOR OTHER AFFILIATIONS
        // bc = new Person360BuilderDirector(bc).resolveDependencies(this.p360).getBaseClass();
    }
}