/*******************************************************************************
* @author:      Shalini Mendu
* @date:        24.June.2020
* @description: Wrapper class to capture Teaching period and the Unit attempt data
* @revision:	ASN4.1 enhancement - SFR capping logic + onload validation against Course Code and Time Limit Rule
*******************************************************************************/
public without sharing class TeachingPeriod {
    @AuraEnabled
    public String teachingPeriodName{get; set;}
    @AuraEnabled
    public String teachingPeriodType{get; set;}
    @AuraEnabled
    public Boolean studentUpdated{get; set;}
    @AuraEnabled
    public String userFlowNumber{get; set;}
    @AuraEnabled
    public Boolean hasCompletedUnitAttempt{get;set;}
    @AuraEnabled
    public List<TeachingPeriod.UnitAttempt> unitAttemptList {get; set;}
    //Props for setting userFlowNumber
    @TestVisible
    private Set<String> userFlow1Label = new Set<String>(((String)System.Label.ASN_UserFlow_1).split(','));
    //userFlow3 = You have a withheld, supplementary or deferred result for a unit/units in this teaching period
    @TestVisible
    private Set<String> userFlow3Label = new Set<String>(((String)System.Label.ASN_UserFlow_3).split(','));
    @TestVisible
    private Set<String> userFlow3AllGradesLabel = new Set<String>(((String)System.Label.ASN_UserFlow3_Filter).split(','));

    //No Units with Passed
    @TestVisible
    private Set<String> userFlow2Label = new Set<String>(((String)System.Label.ASN_UserFlow_2).split(','));
    @TestVisible
    private Boolean hasRecordsResponded = false;
    @TestVisible
    private Boolean hasRecordsWithDrawn = false;
    //For Catching Flow 3 if There is Passed
    @TestVisible
    private Boolean hasPassedRecords = false;
    @TestVisible
    private Integer failedRecIndex = null;
    @TestVisible
    private Id failedRecId = null;
    @TestVisible
    private Set<String> unitAttemptIdsAdded {get; set;}
    @AuraEnabled
    public Integer totalCreditPoints {get;set;}
    @AuraEnabled
    public Integer totalSFRConverted {get;set;}
    public DateTime latestUpdatedUA;
    @AuraEnabled
    public Boolean hasSpecialCourse {get;set;}

    public TeachingPeriod() {
        this.studentUpdated = false;
        this.hasRecordsResponded = false;
        this.hasRecordsWithDrawn = false;
        this.hasPassedRecords = false;
        this.hasCompletedUnitAttempt = false;
        this.userFlowNumber = null;
        unitAttemptList = new List<TeachingPeriod.UnitAttempt>();
        unitAttemptIdsAdded = new Set<String>();
        this.totalCreditPoints = 0;
        this.totalSFRConverted = 0;
        this.hasSpecialCourse = false;
    }

    //Overloaded constructor taking teachingPeriodName as a parameter
    public TeachingPeriod(String teachingPeriodName) {
        this.teachingPeriodName = teachingPeriodName;
        this.studentUpdated = false;
        this.hasRecordsResponded = false;
        this.hasRecordsWithDrawn = false;
        this.hasPassedRecords = false;
        this.hasCompletedUnitAttempt = false;
        this.userFlowNumber = null;
        unitAttemptList = new List<TeachingPeriod.UnitAttempt>();
        unitAttemptIdsAdded = new Set<String>();
        this.totalCreditPoints = 0;
        this.totalSFRConverted = 0;
        this.hasSpecialCourse = false;
    }
    /**
     * addUnitAttempt Processed added Unit Attempts to set User Flow
     */
    public void addUnitAttempt(TeachingPeriod.UnitAttempt ua) {
        if(this.unitAttemptList != null && this.unitAttemptIdsAdded.contains(ua.unitAttemptId) == false) {

            //Begin compute of userLFlows
            if(UNIT_ATTEMPT_STATUS_FILTER.contains(ua.status) || this.userFlowNumber == 'UserFlow7'){
                // count all creditpoints under each teaching period only for completed/enrolled unit attempts
                if(UNIT_ATTEMPT_STATUS_FILTER.contains(ua.status)){
                    if(!CAP_LIMIT_LOCATION_EXCLUSIONS.contains(ua.location)){
                        this.totalCreditPoints += ua.acvdCreditPoints;
                        if(ua.convertToSFR){
                            this.totalSFRConverted += ua.acvdCreditPoints;
                        }
                    }
                    if(SPECIAL_COURSE_CODES.contains(ua.courseCode)){
                        this.hasSpecialCourse = true;
                    }
                }
				
				// USER FLOW 6 - manual process of SFR conversion for DDE/ADE Education and also the DVCE
                if(ONE_YEAR_HONOURS.contains(ua.courseLevel) && UNIT_ATTEMPT_STATUS_FILTER.contains(ua.status)){
                    this.userFlowNumber = 'UserFlow6';
                    this.unitAttemptList.add(ua);
                    this.unitAttemptIdsAdded.add(ua.unitAttemptId);
                }
                else{
					if(this.hasRecordsResponded ||
							(ua.studentResponseDate != null)) {
						//You have already submitted your changes for this teaching period
						this.userFlowNumber = 'UserFlow4';
						this.hasRecordsResponded = true;
						this.unitAttemptList.add(ua);
						this.unitAttemptIdsAdded.add(ua.unitAttemptId);
					} 
					else if(this.latestUpdatedUA != null && this.latestUpdatedUA.addDays(28) < Date.today()){
						this.userFlowNumber = 'UserFlow7';
						if(UNIT_ATTEMPT_STATUS_FILTER.contains(ua.status)){
                            this.unitAttemptList.add(ua);
                            this.unitAttemptIdsAdded.add(ua.unitAttemptId);
                        }   
					}else if((this.hasRecordsWithDrawn || String.isBlank(ua.grade) || userFlow3Label.contains(ua.grade)) && UNIT_ATTEMPT_STATUS_FILTER.contains(ua.status)) {
						//You have a withheld, supplementary or deferred result for a unit/units in this teaching period
						this.userFlowNumber = 'UserFlow3';
						this.hasRecordsWithDrawn = true;
						if(this.failedRecIndex != null) {
							this.unitAttemptList.remove(this.failedRecIndex);
							this.unitAttemptIdsAdded.remove(this.failedRecId);
							this.failedRecId = null;
							this.failedRecIndex = null;
						}
						if(userFlow3AllGradesLabel.contains(ua.grade) || String.isBlank(ua.grade)) {
							this.unitAttemptList.add(ua);
							this.unitAttemptIdsAdded.add(ua.unitAttemptId);
						}
					} else if(this.hasPassedRecords == false
							&& userFlow2Label.contains(ua.grade) && UNIT_ATTEMPT_STATUS_FILTER.contains(ua.status)) {
						//If Unit has Passed Records
						this.userFlowNumber = 'UserFlow2';
						//Check index to remove
						this.failedRecIndex = this.unitAttemptList.size();
						this.failedRecId = ua.unitAttemptId;
						//
						this.unitAttemptList.add(ua);
						this.unitAttemptIdsAdded.add(ua.unitAttemptId);

					} else if(this.hasPassedRecords == true ||
							(!userFlow3Label.contains(ua.grade)
									&& !userFlow2Label.contains(ua.grade))
							) {
						//Even if process has failed grades as long as some passed
						this.userFlowNumber = 'UserFlow1';
						this.hasPassedRecords = true;
						if(userFlow1Label.contains(ua.grade)) {
							this.unitAttemptList.add(ua);
							this.unitAttemptIdsAdded.add(ua.unitAttemptId);
						}
						if(this.failedRecIndex != null) {
							this.unitAttemptList.remove(this.failedRecIndex);
							this.unitAttemptIdsAdded.remove(this.failedRecId);
							this.failedRecId = null;
							this.failedRecIndex = null;
						}
					}
                }
            }
        }

        if(this.hasCompletedUnitAttempt== false && ua.status == 'Completed'){
            this.hasCompletedUnitAttempt = true;
        }
    }

    public void validateTimeLimitRule(TeachingPeriod.UnitAttempt ua){
        if(this.latestUpdatedUA != null && this.latestUpdatedUA.addDays(28) < Date.today()){
            this.userFlowNumber = 'UserFlow7';
        }
    }
    //Inner Wrapper class to capture UnitAttempt data
    public class UnitAttempt {

        @AuraEnabled
        public String personId{get; set;}
        @AuraEnabled
        public Id unitAttemptId{get; set;}
        @AuraEnabled
        public String cISequenceNumber{get; set;}
        @AuraEnabled
        public String unitCode{get; set;}
        @AuraEnabled
        public String unitTitle{get; set;}
        @AuraEnabled
        public String UnitMode{get; set;}
        @AuraEnabled
        public Integer acvdCreditPoints{get; set;}
        @AuraEnabled
        public Integer mark{get; set;}
        @AuraEnabled
        public String grade{get; set;}
        @AuraEnabled
        public String teachingPeriodKey{get; set;}
        @AuraEnabled
        public Boolean withDraw{get; set;}
        @AuraEnabled
        public Boolean convertToSFR{get; set;}
        //Stores changes
        @AuraEnabled
        public String newoutcome{get; set;}
        @AuraEnabled
        public String status{get;set;}
        //Tracks if Student Response Is captured
        public Date studentResponseDate {get; set;}
        public String courseLevel {get;set;}
        public DateTime lastUpdatedDate {get;set;}
        public String location {get;set;}
        public String courseCode {get;set;}
    }

    private List<String> SPECIAL_COURSE_CODES{
        get{
            if(SPECIAL_COURSE_CODES == null){
                SPECIAL_COURSE_CODES = String.valueOf(Label.ASN_Special_Courses).toLowerCase().split(',');
            }
            return SPECIAL_COURSE_CODES;
        }
        set;
    }

    private List<String> ONE_YEAR_HONOURS{
        get{
            if(ONE_YEAR_HONOURS == null){
                ONE_YEAR_HONOURS = String.valueOf(Label.ASN_One_Year_Honour_Codes).toLowerCase().split(',');
            }
            return ONE_YEAR_HONOURS;
        }
        set;
    }

    private List<String> CAP_LIMIT_LOCATION_EXCLUSIONS{
        get{
            if(CAP_LIMIT_LOCATION_EXCLUSIONS == null){
                CAP_LIMIT_LOCATION_EXCLUSIONS = String.valueOf(Label.ASN_Cap_Limit_Exclusion).toLowerCase().split(',');
            }
            return CAP_LIMIT_LOCATION_EXCLUSIONS;
        }
        set;
    }

    private static List<String> UNIT_ATTEMPT_STATUS_FILTER{
        get{
            return String.valueOf(Label.ASN_UA_Status).toLowerCase().split(',');
        }
        set;
    }
}