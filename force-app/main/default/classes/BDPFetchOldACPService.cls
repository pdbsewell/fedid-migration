/**
 * @author      David Browaeys
 * @description Service class for bulk data processing object to fetch related ACP record
 * @group       Bulk Data Processing
 * @revision    
 *  JUL.6.2020      David Browaeys  - Created
 *  AUG.31.2022     Nick Guia       - Renamed Promise interface to IPromise 
 */
public inherited sharing class BDPFetchOldACPService implements IPromise{
    @TestVisible Set<String> contactIds, courseCodes;
    @TestVisible Map<String, Course_Attempt__c> courseAttempts;
    Bulk_Data_Processing__c[] records;
    @TestVisible CourseAttemptsSelector courseAttemptSelector;

    public IPromise init(){
        this.courseAttempts = new Map<String, Course_Attempt__c>();
        this.contactIds = new Set<String>();
        this.courseCodes = new Set<String>();
        this.courseAttemptSelector = new CourseAttemptsSelector();
        return this;
    }

    public void execute(SObject[] records){
        this.records = (Bulk_Data_Processing__c[])records;
        for (Bulk_Data_Processing__c bdp : this.records){
            if (bdp.Applicant__c != null && bdp.Current_Course_Code__c != null){
                contactIds.add(bdp.Applicant__c);
                courseCodes.add(bdp.Current_Course_Code__c);
            }
        }
        getCourseAttempts();
        assignTransferFrom();
    }

	/**
     * @author      David Browaeys
     * @date        06/07/2020
     * @description populate Course Attempt map
     * key: contact id + course name, value: course attempt record
     */
    private void getCourseAttempts(){
        Course_Attempt__c[] tmp = this.courseAttemptSelector.selectActiveByContactIdAndCourseCode(contactIds, courseCodes);
        for (Course_Attempt__c ca : tmp){
            this.courseAttempts.put(ca.Contact__c + '_' + ca.Course__r.Name, ca);
        }
    }

	/**
     * @author      David Browaeys
     * @date        06/07/2020
     * @description update BDP transfer from lookup, and admission category value on insert/update
     */
    private void assignTransferFrom(){
        for (Bulk_Data_Processing__c bdp : this.records){
            if (bdp.Applicant__c != null && bdp.Current_Course_Code__c != null && this.courseAttempts.get(bdp.Applicant__c + '_' + bdp.Current_Course_Code__c) != null){
                Application_Course_Preference__c acp = this.courseAttempts.get(bdp.Applicant__c + '_' + bdp.Current_Course_Code__c).Application_Course_Preference__r;
                if (acp == null) {
                    bdp.Log__c = BDPConstants.ACP_NOT_FOUND_MSG;
                    bdp.Status__c = BDPConstants.REVIEW_REQUIRED;
                }else{
                    bdp.Log__c = null;
                    bdp.Transfer_From__c = acp.id;
                    bdp.Current_Admission_Category__c = acp.Admission_Category__c != null ? acp.Admission_Category__c : acp.Course_Offering__r.Admission_Category__c;
                    bdp.Transfer_Citizenship_Country__c = acp.Application__r.Citizenship_Country__c;
                }
            }else{
                bdp.Log__c = BDPConstants.COURSE_ATTEMPT_NOT_FOUND_MSG;
                bdp.Status__c = BDPConstants.REVIEW_REQUIRED;
            }
        }
    }
}