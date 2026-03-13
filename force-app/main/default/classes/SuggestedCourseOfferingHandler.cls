/**
 * Trigger Handler for Suggested Course Offering. By making a suggested course offering primary it will create relevant acp for that bulk data process and selected course offering. 
 * @author David Browaeys
 * @group Bulk Data Processing
 *  17.04.2023 Ken McGuire: Changed Comments__c (255 characters) to LongComments__c (4000 characters)
 */
public with sharing class SuggestedCourseOfferingHandler extends TriggerAbstract { 
    Map<String, Application_Course_Preference__c> acps;
    Map<ID, Bulk_Data_Processing__c> courseTransfers;
    @TestVisible Map<ID, Course_Offering__c> courseOfferings;
    @TestVisible BulkDataProcessingSelector bdpSelector; 
    @TestVisible CourseOfferingSelector coSelector;
    @TestVisible Dao sobjectDao;
    /**
     * SuggestedCourseOfferingHandler constructor
     */
    public SuggestedCourseOfferingHandler(){
        super();
        this.acps = new Map<String, Application_Course_Preference__c>();
        this.courseTransfers = new Map<ID, Bulk_Data_Processing__c>();
        this.courseOfferings = new Map<ID, Course_Offering__c>();
        this.bdpSelector = new BulkDataProcessingSelector();
        this.coSelector = new CourseOfferingSelector();
        this.sobjectDao = new SObjectDao();
    }
    /**
     * Override process method for new record
     * @param rec new sobject record
     */
	public override void process(SObject rec) {
        process(rec,null);
    }
    /**
     * override process method for existing record
     * @param rec new sobject record
     * @param oldRec old sobject record
     */
    public override void process(SObject rec, SObject oldRec) {
        Suggested_Course_Offering__c sco = (Suggested_Course_Offering__c) rec;
        Suggested_Course_Offering__c scoOld = (Suggested_Course_Offering__c) oldRec;
        if (sco.Primary__c == true && (oldRec == null || sco.Primary__c != scoOld.Primary__c)){
            this.courseTransfers.put(sco.Bulk_Data_Processing__c,null);
            this.courseOfferings.put(sco.Course_Offering__c, null);
            this.records.add(sco);
        }
    }
    /**
     * Main execute method to kick off the the process. 
     */
    public override void execute() {
        this.courseTransfers = new Map<ID,Bulk_Data_Processing__c>(this.bdpSelector.selectByIdWithACPDetails(this.courseTransfers.keySet()));
        this.courseOfferings = this.coSelector.selectMapById(this.courseOfferings.keySet());
        for (Suggested_Course_Offering__c sco : (Suggested_Course_Offering__c[]) this.records){
            if (courseTransfers.get(sco.Bulk_Data_Processing__c) != null){
                this.acps.put(sco.Bulk_Data_Processing__c, createACP(courseTransfers.get(sco.Bulk_Data_Processing__c), this.courseOfferings.get(sco.Course_Offering__c)));
            }
        }
        commitAll();
    }
    /**
     * @description Individudal field mappings for the ACP
     * @param bdp bulk data processing record
     * @param courseOfferingId id of selected course offering
    */
    private Application_Course_Preference__c createACP(Bulk_Data_Processing__c bdp, Course_Offering__c co){
        Application_Course_Preference__c aACP = new Application_Course_Preference__c();
        System.debug('@@@ bdp.Transfer_To_Application__c : '+ bdp.Transfer_To_Application__c);
        aACP.Bulk_Data_Processing__c = bdp.Id;
        aACP.Application__c = bdp.Transfer_To_Application__c;
        aACP.Applicant__c = bdp.Applicant__c;
        aACP.Course_Offering__c = co.Id;
        aACP.Name = bdp.Transfer_Course_Code__c + '/' + bdp.Transfer_Course_Campus__c;
        aACP.Preference_Number__c = bdp.Preference__c != null ? bdp.Preference__c : '1';
        aACP.Offer_Date__c = Date.today();
        aACP.Course_Admission_Status__c = 'Full Offer';
        //Changing the Recruitment_Reference_Code__c to refer Current course campus and adding indonesia
        if (bdp.Current_Course_Campus__c.equalsIgnoreCase('malaysia') ||bdp.Current_Course_Campus__c.equalsIgnoreCase('south africa')|| bdp.Current_Course_Campus__c.equalsIgnoreCase('indonesia'))
        {
            aACP.Recruitment_Reference_Code__c = 'MU-OFSHR-T';
        }else{
            aACP.Recruitment_Reference_Code__c = 'MU-ON-SH-T'; //AUSTRALIA
        }
        aACP.LongComments__c = 'English - LOI';
        aACP.Status__c = 'PENDING';
        aACP.Offer_Condition__c = bdp.Student_Notes__c != null && bdp.Student_Notes__c.length() > 2000 ? bdp.Student_Notes__c.substring(0,2000) : bdp.Student_Notes__c;
        aACP.Basis_For_Adminssion_Type__c = '311';
        aACP.Admissions_Assessment_Status__c = 'Not Started';
        aACP.Admissions_Process_Type__c  = 'TRANSFER';
        aACp.Admission_Category__c = co.Admission_Category__c;
        aACP.Intake_Period__c = co.Commencement_Period__c;
        aACP.Location_Code__c = co.Location_Code__c;
        aACP.Outcome_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'OFFER-PROV-ADM_OUTCOME_STATUS');
        aACP.Offer_Response_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'PENDING-ADM_OFFER_RESP_STATUS');
        aACP.Conditional_Offer_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'PENDING-ADM_CNDTNL_OFFER_STATUS');
        aACP.Deferment_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'NOT-APPLIC-ADM_OFFER_DFRMNT_STATUS');
        aACP.Documentation_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'SATISFIED-ADM_DOC_STATUS');
        aACP.Entry_Qualification_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'QUALIFIED-ADM_ENTRY_QUAL_STATUS');
        aACP.Offer_Response_Date__c = bdp.Offer_Lapsed_Date__c;
        aACP.Approved_Credit_Points__c = bdp.Credit_Points__c;
        aACP.Agreed_Start_Date__c = co.Start_Date__c;
        aACP.Offer_Condition__c = bdp.Offer_Condition__c;
        if (aACP.Approved_Credit_Points__c != null && bdp.Credit_Duration_Value__c != null && aACP.Agreed_Start_Date__c != null){
	        setDurationBaseCredit(aACP, bdp);
        }else{
            aACP.Revised_End_Date__c = co.End_Date__c;
        }
        isOnShoreMUCourseTransfer(bdp, aACP, co);
        return aACP;
    }

    /**
     * Set credit duration and revised end date base on credit info. 
     * @param  aACP aACP target application course pref record
     * @param  bdp  source bulk data processing
     */
    public void setDurationBaseCredit(Application_Course_Preference__c aACP, Bulk_Data_Processing__c bdp){
        switch on bdp.Credit_Duration_Unit__c {
            when  'Trimesters' {    //At monash trimester is most likely a period of 4 months, we are assuming CO will have a override in months
                aACP.Credit_Adjusted_Course_Duration__c = bdp.Credit_Duration_Value__c * 4;             
                aACP.Revised_End_Date__c = aACP.Agreed_Start_Date__c.addMonths(Integer.valueOf(bdp.Credit_Duration_Value__c * 4));
            }when  'Semesters' {    //At monash semester is most likely a period of 6 months, we are assuming CO will have a override in years
                aACP.Credit_Adjusted_Course_Duration__c = bdp.Credit_Duration_Value__c * 0.5;
                aACP.Revised_End_Date__c = aACP.Agreed_Start_Date__c.addMonths(Integer.valueOf(bdp.Credit_Duration_Value__c * 6));
            }
            when else {
                aACP.Credit_Adjusted_Course_Duration__c = bdp.Credit_Duration_Value__c;
                aACP.Revised_End_Date__c = aACP.Agreed_Start_Date__c.addMonths(Integer.valueOf(aACP.Credit_Adjusted_Course_Duration__c * 12));
            }
        }
    }

    public final String[] monashUniFacultyCodes = new String[]{'50000561','50000562','50000563','50000564','50000565','50000566','50000567','50000568','50000569','50000570'};
    public void isOnShoreMUCourseTransfer(Bulk_Data_Processing__c bdp , Application_Course_Preference__c acp, Course_Offering__c co){
        bdp.Onshore_MU_Transfer__c = bdp.Is_Onshore__c == true && 
                                        monashUniFacultyCodes.contains(co.Faculty_Code__c) == true;
    }
    /**
     * @author David Browaeys 
     * @description Commit all object records to database for this transaction
     */
    public void commitAll(){
        Triggers.bypass('ApplicationCoursePreferenceServices.generateCourseAdmissionStatus');
        this.sobjectDao.upsertRecords(this.acps.values());
        Application_Course_Preference__c[] acpsUpdate = new Application_Course_Preference__c[0];
        for (String bdpId : this.acps.keySet()) {
            if (this.acps.get(bdpId) != null) {
                this.courseTransfers.get(bdpId).Transfer_To__c = this.acps.get(bdpId).Id;
                if (this.courseTransfers.get(bdpId).Credit_Duration_Unit__c != 'Trimesters' && this.courseTransfers.get(bdpId).Credit_Duration_Unit__c != 'Semesters'){
                    this.courseTransfers.get(bdpId).Status__c = BDPConstants.READY_STATUS;
                    this.courseTransfers.get(bdpId).Log__c = null;
                }else{
                    this.courseTransfers.get(bdpId).Status__c = BDPConstants.REVIEW_REQUIRED;
                    this.courseTransfers.get(bdpId).Log__c = BDPConstants.CREDIT_DURATION_WARNING;
                }
            }
            acpsUpdate.add(new Application_Course_Preference__c( Id = this.acps.get(bdpId).Id, Added_by_Course_Transfer__c = true));
        }
        TriggerCommon.disableTrigger('Bulk_Data_Processing__c');
        this.sobjectDao.updateRecords(this.courseTransfers.values());
        TriggerCommon.enableTrigger('Bulk_Data_Processing__c');
        this.sobjectDao.updateRecords(acpsUpdate);
    }
}