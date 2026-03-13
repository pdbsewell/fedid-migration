/**
 * @description       : A services class specific to the Lead sObject.
 * @author            : Stefan Scheit
 * @group             : Commons
 * @last modified on  : 13-10-2022
 * @last modified by  : NG
 * @revision
 *  10.OCT.2022     Nick Guia   - refactored and moved logic to LeadTriggerHandler
 *  OCT.13.2022     Nick Guia   - Deleted ComputeForcastedStartDate. This will now be populated through the Lead Grading integration 
**/
public inherited sharing class LeadServices {

    // Lead Status values which set lead nurturing status to Active
    public static final Set<String> ACTIVE_LEAD_STATUS = new Set<String>{'Open','Contacted'};

    public static Id LEAD_PROSPECTIVESTUDENT_REC_TYPE {
        get {
            if(LEAD_PROSPECTIVESTUDENT_REC_TYPE == null) {
                LEAD_PROSPECTIVESTUDENT_REC_TYPE = Schema.SObjectType.Lead
                                                    .getRecordTypeInfosByDeveloperName()
                                                    .get('Prospective_Student')
                                                    .getRecordTypeId();
            }
            return LEAD_PROSPECTIVESTUDENT_REC_TYPE;
        }
        set;
    }

    /**
    * @description populate Active_Lead_Contact_Id__c if Lead Status is considered "active"
    * //TODO: this business logic needs to be revisited once Lead stages have been defined
    * @author NG | 10-10-2022 
    * @param Lead rec 
    * @return Lead 
    **/
    public Lead toggleActiveLead(Lead rec) {
        if(rec != null) {
            if (ACTIVE_LEAD_STATUS.contains(rec.Status)) {
                rec.Active_Lead_Contact_Id__c = rec.Contact__c;
            } else {
                rec.Active_Lead_Contact_Id__c = null;
            }
        } else {
            throw new LeadServicesException('Invalid null argument for Lead record');
        }
        return rec;
    }

    public class LeadServicesException extends Exception { }
}