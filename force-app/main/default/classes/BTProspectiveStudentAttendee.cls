/**
 * @author Nick Guia
 * @date 15-02-2021
 * @group Event Management
 * @description class for integrating Attendee data to Person 360 for Prospective Student affiliation
 * @revision 
 *   21.06.2021   Ibrahim Rumi    - EPBBS-2007 modified method createAttendeePerson360 to set  Do_Not_Create_Acquisition_Camp_Member__c as true. This avoids creation of acquistion campaign member.
 * @revision
 *   21.06.2021  Aref Samad      - EPBBS-1909 Defect fix country of residency and citizenship mapping in contact
 *                                 (modify createAttendeePerson360 and pushRecords to include contact update)
 *   24.05.2022  Ibrahim Rumi    - EPBBS-2657 modify cleanupCountryISOCode method to set Mailing country as null when country
 *                                 ISO values are passed
 **/
public virtual inherited sharing class BTProspectiveStudentAttendee extends BTAttendeeAffiliation {

    @TestVisible
    private conference360__Event__c event;
    @TestVisible
    private Staged_Prospective_Student__c sps;

    public BTProspectiveStudentAttendee(Contact con, conference360__Event__c eventRec, conference360__Attendee__c attendee) {
        super(con, attendee);
        this.event = eventRec;
    }

    /**
     * @description create Person 360 records by creating an SPS records (v2 logic)
     */
    public override void createAttendeePerson360() {
        Nebula.Logger.info('### createAttendeePerson360: ' + this.event);
        this.sps = new Staged_Prospective_Student__c(
            Exploded_Target__c = super.con.Id,
            Exploding_Leads_V2__c = TRUE,
            Lead_Source__c = 'Event',
            Acquisition_Source_Campaign__c = this.event.conference360__Campaign__c,//EPBBS-3452 - Populate Broad_Area_of_Interest_Update_Mode__c from Event on SPS 
            Do_Not_Create_Acquisition_Camp_Member__c = TRUE,
            Broad_Area_of_Interest_Update_Mode__c = this.event.Broad_Area_of_Interest_Update_Mode__c
        );

        for(BT_Attendee_to_SPS_Mapping__mdt mapping : BTAttendeeServices.spsMapping) {
            String attField = String.valueOf(mapping.Attendee_Field__c);
            String spsField = String.valueOf(mapping.SPS_Field__c);

            if(attendee.get(attField) != null) {
                String attVal = String.valueOf(attendee.get(attField));
                this.sps.put(spsField, attVal);
            }
        }

        //Updating Contact with SPS fields
        if (super.con != null && super.con.Id != null)
        {
            ExplodingLeadsFactoryV2 factory = new ExplodingLeadsFactoryV2(this.sps);
            Contact psCon = factory.buildProspectiveContact();
            super.con = factory.mergeProspectiveContact(super.con, psCon);
        }
        cleanupCountryISOCode();
    }

    /**
     * @description INTERIM SOLUTION ONLY. TO BE DEPRECATED ONCE COUNTRY ISSUE
     * HAS BEEN FIXED : https://confluence.apps.monash.edu/display/EPBBS/Country+Field+Issue
     */
    @TestVisible
    private void cleanupCountryISOCode() {
        if(String.isNotBlank(this.sps.Mailing_Country__c) && this.sps.Mailing_Country__c.length() <= 2)
        {
            //if only Mailing Country is populated, and String length is <= 2 (ISO Code), remove value
            this.sps.Mailing_Country__c = null;
        }
    }

    /**
     * @description "stage commit" created records into Base Class instance
     * @param bc instance of BaseClass
     */
    public override void pushRecords(BaseClass bc) {
        if (super.con!=null && super.con.Id!=null)
        {
            bc.push(super.con);
        }
        bc.push(this.sps);
    }
}