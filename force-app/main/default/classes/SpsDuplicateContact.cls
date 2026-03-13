/**
 * @description       : Wrapper class for SPS records with related (dupe) Contact(s)
 * @author            : Nick Guia
 * @date              : 14-09-2020
 * @group             : Lead Management
 * @last modified on  : 03-07-2023
 * @last modified by  : Nick Guia
**/
public virtual inherited sharing class SpsDuplicateContact extends DuplicateContact {

    public List<Staged_Prospective_Student__c> spsList {get; set;}
    private Staged_Prospective_Student__c mergedSps;

    public SpsDuplicateContact(Staged_Prospective_Student__c spsRec) {
        super();
        this.spsList = new List<Staged_Prospective_Student__c> { spsRec };
    }

    public SpsDuplicateContact(List<Staged_Prospective_Student__c> spsRecs) {
        super();
        this.spsList = spsRecs;
    }

    /**
     * @description merge the SPS records
     */
    public Staged_Prospective_Student__c getMergedSps() {
        if(this.mergedSps == null) {
            this.mergedSps = (Staged_Prospective_Student__c) CommonUtilities.mergeRecordList(this.spsList);
        }
        return mergedSps;
    }

    /**
     * @description link back the inserted/updated Contact record to the SPS
     * if Contact has no ID, assumption is that there was a failure on the DML
     * operation, hence update SPS status to Fatal Error
     */
    public void propagateContactIds() {
        for(Staged_Prospective_Student__c iSps : this.spsList) {
            if(super.con != null && super.con.Id != null) {
                iSps.Exploded_Target__c = super.con.Id;
            } else {
                //on failure to insert/link Contact
                iSps.Status__c = Label.SPS_Status_Fatal_Error;
            }
        }
    }
}