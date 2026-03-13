/**
 * @author David Browaeys
 * @description This service class fetch course offering base on transfer information using duplicate management
 * @group Bulk Data Processing
 * @revision
 *  AUG.31.2022     Nick Guia   - Renamed Promise interface to IPromise 
 */
public inherited sharing class BDPCourseOfferingMatchingService implements IPromise {
    Map<String, Application__c> apps;
    @TestVisible Map<String, Bulk_Data_Processing__c> bdpsUpdate;
    @TestVisible private Suggested_Course_Offering__c[] suggestedCourseOfferings;
    @TestVisible private Dao sobjectDao;

	/**
     * Inittialise process, act as constructor
     * @return   IPromise
     */
	public IPromise init(){
        this.suggestedCourseOfferings = new Suggested_Course_Offering__c[0];
        this.apps = new Map<String, Application__c>();
        this.bdpsUpdate = new Map<String, Bulk_Data_Processing__c> ();
        this.sobjectDao = new SObjectDao();
        return this;
    }

    /**
     * Main execite method of the BDP CourseOffering Matching Service
     * @param  records list of BDP record to fetch data
    */
    public void execute(SObject[] records){
        Integer counter = 0;
        Bulk_Data_Processing__c[] buff = new Bulk_Data_Processing__c[0];
        for (Bulk_Data_Processing__c bdp : (Bulk_Data_Processing__c[])records){
            if (bdp.Transfer_From__c != null) { 
                if (bdp.Transfer_To_Application__c == null) this.apps.put(bdp.Id, createApplication(bdp));
                Bulk_Data_Processing__c b = bdp.clone(true, true);
                b.Fetch_Course_Offering__c = true;
                buff.add(b);
                counter++;
                if (counter == 50){
                    findCourseOffering(buff);
                    buff.clear();
                    counter = 0;
                }
            }
        }
        if (buff.isEmpty() == false) findCourseOffering(buff);
        commitAll();
    }

    /**
     * Kick off data cloud find duplicate logic, this method can only accept a maximum of 50 records
     * @param  buff list of BDP record to find duplicate
     */
    @TestVisible private void findCourseOffering(Bulk_Data_Processing__c[] buff){
        Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(buff);
        for (Integer i = 0; i < buff.size(); i++) {
            for (Datacloud.DuplicateResult dr : results[i].getDuplicateResults()) {
                if(dr.duplicateRule == BDPConstants.BDP_COURSE_OFFERING_DUPLICATE_RULE){
                    Suggested_Course_Offering__c[] sco = new Suggested_Course_Offering__c[0];
                    if (dr.matchResults.size() > 0 && dr.getMatchResults()[0].matchRecords.size() > 0) {
                        for (Datacloud.MatchRecord matchRecord : dr.getMatchResults()[0].getMatchRecords()) {
                            Suggested_Course_Offering__c s = createSuggestedCourseOffering(buff[i], (Course_Offering__c) matchRecord.getRecord());
                            if (s != null) sco.add(s);
                        }  
                    }
                    handleDuplicateResults(buff[i], sco);
                }
            }
        }
    }
    /**
     * Callback method for bdp update from duplicate result scenarios. 
     * @param  bdp bulk data process record 
     * @param  sco list of suggested course offering found 
     */
    @TestVisible void handleDuplicateResults(Bulk_Data_Processing__c bdp, Suggested_Course_Offering__c[] sco){
        if(sco.isEmpty() == true) {
            this.bdpsUpdate.put(bdp.Id, 
                new Bulk_Data_Processing__c(
                    Id = bdp.Id, 
                    Status__c = BDPConstants.REVIEW_REQUIRED,
                    Log__c = BDPConstants.CO_NOT_FOUND_MSG));
        } else if (sco.size() == 1){
            sco[0].Primary__c = true;
            this.bdpsUpdate.put(bdp.Id, 
                new Bulk_Data_Processing__c(
                    Id = bdp.Id, 
                    Log__c = null));
        }else if (sco.size() > 1){
            this.bdpsUpdate.put(bdp.Id, 
                new Bulk_Data_Processing__c(
                    Id = bdp.Id, 
                    Status__c = BDPConstants.REVIEW_REQUIRED,
                    Log__c = BDPConstants.MULTI_CO_FOUND_MSG));
        }
    }
    /**
     * Create Suggested Course Offering for BDP record
     * @param  bdp bulk data process record 
     * @param  co  ccourse offering to evaluate
     * @return     created suggested course offering
     */
    public Suggested_Course_Offering__c createSuggestedCourseOffering(Bulk_Data_Processing__c bdp, Course_Offering__c co) {
        if (co.Citizenship_Type__c == BDPConstants.DEFAULT_CITIZENSHIP && co.Active__c == true) {
            Suggested_Course_Offering__c s = new Suggested_Course_Offering__c(
                Name = co.Course_Title__c,
                Primary__c = false,
                Bulk_Data_Processing__c = bdp.Id,
                Course_Offering__c = co.Id);
            this.suggestedCourseOfferings.add(s);
            return s;
        }
        return null;
    }

    /**
    * @description Create new instance of an Application from bulk data processing
    * @param bdp bulk data processing record
    */
    private Application__c createApplication(Bulk_Data_Processing__c bdp) {
        Application__c aa = new Application__c();
        if (Test.isRunningTest() == false ) aa.Agent__r = new Account(Callista_Org_Unit_Code__c = 'DIRECT');
        aa.Agent_Org_Unit_Code__c = 'DIRECT';
        aa.Status__c = 'Submitted'; //default to Submission on Hold (Duplicate Contact) and change to "Sent for Submission"
        aa.Transfer_Type__c = bdp.Type__c;
        aa.Applicant__c = bdp.Applicant__c;
        aa.Person_ID__c = bdp.Person_ID__c;
        aa.Source_System__c = 'CCT';
        aa.Campus__c = bdp.Transfer_Course_Campus__c;
        aa.Campus_Location__c = 'Australia';
        if (bdp.Current_Course_Campus__c.toLowerCase() == 'malaysia')aa.Submission_Location_Country__r = new Country_Attribute__c(Name = 'MALAYSIA');
        else if (bdp.Current_Course_Campus__c.toLowerCase() == 'south africa') aa.Submission_Location_Country__r = new Country_Attribute__c(Name = 'SOUTH AFRICA');
        else aa.Submission_Location_Country__r = new Country_Attribute__c(Name = 'AUSTRALIA');  //VICTORIA ? 
        aa.Submitted_Date__c = Date.today();        //is that in the spreadsheet ? 
        aa.Citizenship_Country__c = bdp.Transfer_Citizenship_Country__c;
        aa.Residency_Status__c = 'INTRNTNL';
        aa.English_Entry_Mode__c =  'English Language Instruction in secondary school / university';
        aa.Meets_Minimum_English__c = 'YES';
        return aa;
    }

    /**
     * Insert all sobject records to database
     */
    public void commitAll(){
        this.sobjectDao.upsertRecords(this.apps.values());
        Bulk_Data_Processing__c[] tmp = new Bulk_Data_Processing__c[0];
        for (String bdpId : this.apps.keySet()) {
            Bulk_Data_Processing__c bdp = this.bdpsUpdate.get(bdpId);
            if (bdp == null){
                bdp = new Bulk_Data_Processing__c(Id = bdpId);
            }
            bdp.Transfer_To_Application__c = this.apps.get(bdpId).Id;
        }

        TriggerCommon.disableTrigger('Bulk_Data_Processing__c');
        this.sobjectDao.updateRecords(this.bdpsUpdate.values());
        TriggerCommon.enableTrigger('Bulk_Data_Processing__c');
        
        this.sobjectDao.insertRecords(this.suggestedCourseOfferings);
    }
}