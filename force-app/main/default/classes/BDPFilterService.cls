/**
 * Filter service class used in trigger evaluation for Bulk Data Processing object.  
 * @author David Browaeys
 * @group Bulk Data Processing
 */
public inherited sharing class BDPFilterService {
    @TestVisible private BDPFilterService(){}
    /**
     * Evaluate if record meet BDPFieldUpdateService criteria
     * @param  newRec new bdp state record
     * @param  oldRec old bdp state record
     * @return        true if meet criteria
     */
    public static Boolean meetBDPFieldUpdateService(Bulk_Data_Processing__c newRec,  Bulk_Data_Processing__c oldRec){
        return 	newRec.Calendar__c == null || newRec.Applicant__c == null || 
                    (oldRec != null && newRec.Person_ID__c != oldRec.Person_ID__c) || 
                    (oldRec != null && newRec.Transfer_Calendar__c != oldRec.Transfer_Calendar__c);
    }
    /**
     * Evaluate if record meet BDPCourseOfferingMatchingService criteria
     * @param  newRec new bdp state record
     * @param  oldRec old bdp state record
     * @return        true if meet criteria
     */
    public static Boolean meetBDPCourseOfferingMatchingService(Bulk_Data_Processing__c newRec,  Bulk_Data_Processing__c oldRec){
        return (newRec.Status__c == BDPConstants.BDP_NEW || newRec.Status__c == BDPConstants.REVIEW_REQUIRED) && newRec.Transfer_To__c == null &&
                        (oldRec == null || 
                        newRec.Transfer_Course_Code__c != oldRec.Transfer_Course_Code__c || 
                        newRec.Transfer_Course_Campus__c != oldRec.Transfer_Course_Campus__c ||
                        newRec.Transfer_Admission_Category__c != oldRec.Transfer_Admission_Category__c ||
                        newRec.Transfer_Calendar__c != oldRec.Transfer_Calendar__c ||
                        newRec.Transfer_Unit_Set__c != oldRec.Transfer_Unit_Set__c);
    }
    /**
     * Evaluate if record meet ACPMatchingService criteria
     * @param  newRec new bdp state record
     * @param  oldRec old bdp state record
     * @return        true if meet criteria
     */
    public static Boolean meetACPMatchingService(Bulk_Data_Processing__c newRec,  Bulk_Data_Processing__c oldRec){
        return newRec.Transfer_To__c != null && newRec.Transfer_To__c != oldRec.Transfer_To__c;
    }
    /**
     * Evaluate if record meet OfferTemplate criteria
     * @param  newRec new bdp state record
     * @param  oldRec old bdp state record
     * @return        true if meet criteria
     */
    public static Boolean meetOfferTemplateMatchingService(Bulk_Data_Processing__c newRec,  Bulk_Data_Processing__c oldRec){
        return newRec.Offer_Template__c != oldRec.Offer_Template__c;
    }
    /**
     * Evaluate if record meet BDPFetchOldACPService crtieria
     * @param  newRec new bdp state record
     * @param  oldRec old bdp state record
     * @return        true if meet criteria
     */
    public static Boolean meetBDPFetchOldACPService(Bulk_Data_Processing__c newRec,  Bulk_Data_Processing__c oldRec){
        return  (newRec.Status__c == BDPConstants.BDP_NEW || newRec.Status__c == BDPConstants.REVIEW_REQUIRED) && newRec.Current_Course_Code__c != null  && 
                    (oldRec == null || 
                    newRec.Applicant__c != oldRec.Applicant__c ||
                    newRec.Person_ID__c != oldRec.Person_ID__c || 
                    newRec.Current_Course_Code__c != oldRec.Current_Course_Code__c ||
                    newRec.Current_Course_Campus__c != oldRec.Current_Course_Campus__c);
    }

    /**
     * Evaluate if BDP's offer condition value has been changed
     * @param  newRec new bdp state record
     * @param  oldRec old bdp state record
     * @return Returns true if the offer condition has been changed
     */
    public static Boolean isOfferConditionChanged(Bulk_Data_Processing__c newRec,  Bulk_Data_Processing__c oldRec) {
        return (oldRec.Offer_Condition__c != newRec.Offer_Condition__c);
    }

    /**
     * Evaluate if BDP has a transfer to ACP
     * @param  bdp The Bulk Data Processing record
     * @return Returns true if the BDP record has a transfer to ACP
     */
    public static Boolean hasTransferToAcp(Bulk_Data_Processing__c bdp) {
        return bdp.Transfer_To__c != null;
    }
}