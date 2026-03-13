/**
 * @description       : Wrapper class for Blackthorn Attendee records with related (dupe) Contact(s)
 * @author            : Nick Guia
 * @date              : 14-09-2020
 * @group             : Event Management
 * @last modified on  : 03-07-2023
 * @last modified by  : Nick Guia
 * @revision
 *  03-07-2023    Nick Guia   - added Account_Record_Type_Name__c = 'Household_Account' on contact match
**/
public virtual inherited sharing class BTAttendeeDuplicateContact extends DuplicateContact {

    public List<conference360__Attendee__c> attList {get; set;}

    public BTAttendeeDuplicateContact(List<conference360__Attendee__c> attRecs) {
        super();
        this.attList = attRecs;
        buildContact();
    }

    public BTAttendeeDuplicateContact(conference360__Attendee__c attRec) {
        super();
        this.attList = new List<conference360__Attendee__c> { attRec };
        buildContact();
    }

    @TestVisible
    private void buildContact() {
        if(this.attList != null && !this.attList.isEmpty()) {
            //assume FN, LN, and Email are the same for all attendees. 
            //This should be filtered by the service logic
            conference360__Attendee__c att = this.attList[0];
            super.con = new Contact(
                FirstName = att.conference360__First_Name2__c,
                LastName = att.conference360__Last_Name2__c,
                Email = att.conference360__Email2__c,
                Account_Record_Type_Name__c = 'Household_Account'
            );
        }
    }

    /**
     * @description link back the inserted/linked Contact record to the Attendee
     * if Contact has no ID, assumption is that there was a failure on the DML
     * operation
     */
    public void propagateContactIds() {
        for(conference360__Attendee__c iAtt : this.attList) {
            if(super.con != null && super.con.Id != null) {
                iAtt.conference360__Contact__c = super.con.Id;
            }
        }
    }
}