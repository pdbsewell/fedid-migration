/**
* @description       : Contains all the trigger handlers for Course Attempt
* @author            : Stefan Scheit
* @group             : Trigger Handler
* Modifications Log 
* 2018-04-24   Gabriel Ludik   Initial Version
* 2018-05-13   Stefan Scheit   Added null check for field Course_Attempt_Status__c, otherwise trigger can error out
* 2018-05-18   Stefan Scheit   Added UpdateFieldsHandler
* 2019-04-02   Nick Guia       Added PopulateCourseAttemptName, getUniqueName(), updated UpdateFieldsHandler()
* 2020-02-25   Martin Cadman   Added the deleted_in_source__c filter to the SQL to exclude these records from the roll-up.
* 2020-03-11   Martin Cadman   Re-wrote rollup logic
* 2020-05-26   JM Mapanao      Added 'is student' (on contact) roll-up logic
* 2020-08-02   Stefan Scheit   Fixed a bug in 'is student' processing
* 2020-11-09   Martin Cadman   Added ACPLookup
* 2020-12-03   Martin Cadman   Interium version stopping the contact triggers firing during primary course attempt calculation
* 2020-12-07   Martin Cadman   Reworked. Removed methods that were called from the CDC trgger services class. This better aligns test classes and coverage.
*                              Moved trigger framework.
* 2021-04-26   Martin Cadman   Updated Name handling.
* 02/08/2024   Inderpal Dhanoa - Auto close linked OCR MCT-440
*/
public class CourseAttemptServices {
    
    // A contact remains flagged as a student (is_student__c = true) for 12 weeks (84 days) post course completion date of ANY (completed) of their course attempts
    public static final Date IS_STUDENT_TRANSITION_DATE = Date.today().addDays(-84);
    
    /**
* @author           Stefan Scheit
* @description      Handler implementation to set fields.
*                   On Before Insert : if Course__c != null, populate Course_Code_Dup__c with Course_Code__c
*                   On Before Update : if Course__c is updated, re-evaluate Course_Code_Dup__c
* @revision         17/05/2018 - Stefan Scheit	- Handler logic added
*                   02/04/2019 - Nick Guia		- Modify logic to refer to Course_Code__c when populating Course_Code_Dup__c
* 					01/07/2020 - Martin Cadman	- Added intermission date
*/
    public class UpdateFieldsHandler extends TriggerAbstract {
        
        public override void execute() {
            
            try {
                if(Trigger.isDelete) {
                    return; // no action required, avoid null pointer for delete trigger
                } else {
                    for (Course_Attempt__c iCourseAttempt : (List<Course_Attempt__c>) Trigger.new) {
						
                        if (Trigger.isInsert) {
                            if (String.isNotBlank(iCourseAttempt.Course__c)) {
                                iCourseAttempt.Course_Code_Dup__c = iCourseAttempt.Course_Code__c;
                            }
                            // Intermission dates are a moving window. We track a current and future date range, as well as when intermission was originally requested.
                            // Intermission initial processing date
                            if (iCourseAttempt.int_start_date__c != null) { 
                                iCourseAttempt.initial_intermit_start_date__c = date.today()<=iCourseAttempt.int_start_date__c?date.today():iCourseAttempt.int_start_date__c;
                            }         
                            
                            if (iCourseAttempt.int_start_date__c == null && iCourseAttempt.Int_Future_Start_Date__c != null) { 
                                iCourseAttempt.initial_intermit_start_date__c = date.today()<=iCourseAttempt.Int_Future_Start_Date__c?date.today():iCourseAttempt.Int_Future_Start_Date__c;
                            }           

                            if ((iCourseAttempt.WAM__c != null && iCourseAttempt.WAM__c != 0) || (iCourseAttempt.GPA__c != null && iCourseAttempt.GPA__c != 0)) {
                                iCourseAttempt.WAM_GPA_Last_Refresh_Date__c = date.today();
                            }
                        }
                        
                        if(Trigger.isUpdate) {
                            Course_Attempt__c oldRec = (Course_Attempt__c) Trigger.oldMap.get(iCourseAttempt.Id);
                            if (CommonUtilities.fieldHasChanged('Course__c', iCourseAttempt, oldRec)) {
                                iCourseAttempt.Course_Code_Dup__c = iCourseAttempt.Course_Code__c;
                            }
                           
                            // Intermission initial processing date - only update if the date is null on the 'old' record
                            if (oldRec.initial_intermit_start_date__c == null && iCourseAttempt.int_start_date__c != null) { 
                                iCourseAttempt.initial_intermit_start_date__c = date.today()<=iCourseAttempt.int_start_date__c?date.today():iCourseAttempt.int_start_date__c;
                            }         
                            
                            if (oldRec.initial_intermit_start_date__c == null && iCourseAttempt.int_start_date__c == null && iCourseAttempt.Int_Future_Start_Date__c != null) { 
                                iCourseAttempt.initial_intermit_start_date__c = date.today()<=iCourseAttempt.Int_Future_Start_Date__c?date.today():iCourseAttempt.Int_Future_Start_Date__c;
                            }                    
                            
                            // Clear the field if all intermissions are in the past - we won't recieve these from Callista
                            if (iCourseAttempt.int_start_date__c == null && iCourseAttempt.Int_Future_Start_Date__c == null) { 
                                iCourseAttempt.initial_intermit_start_date__c = null;
                            }                 

							if (iCourseAttempt.WAM__c != oldRec.WAM__c || iCourseAttempt.GPA__c != oldRec.GPA__c) {
                                iCourseAttempt.WAM_GPA_Last_Refresh_Date__c = date.today();
                            }
                          
                            if (iCourseAttempt.WAM__c == null && iCourseAttempt.GPA__c == null) {
                                iCourseAttempt.WAM_GPA_Last_Refresh_Date__c = null;
                            }

                        }
                    }
                }
            } catch (Exception ex){
                LogUtilityException.logException(ex, 'CourseAttemptServices');
            }
        }
    }
    
    /**
	 * @description Prepopulates the Name field with a unique name
	 */
    public class PopulateCourseAttemptName extends TriggerAbstract {
        
        public override void execute() {
            if(Trigger.isInsert || Trigger.isUpdate) {
                for(Course_Attempt__c iSCA : (List<Course_Attempt__c>) Trigger.new) {
                    iSCA.Name = getUniqueName(iSCA);
                }
            }
        }
    }

    /**
	 * @description Auto Close Linked Monash Connect OCR
	 */
    public class AutoCloseLinkedMonConOCR extends TriggerAbstract {
        Set<Id> contactId = new Set<Id>();

        public override void process(SObject record, SObject oldRec) {
            // before update logic here
            Course_Attempt__c newCoursAttmpt = (Course_Attempt__c)record;
            Course_Attempt__c oldCoursAttmpt = (Course_Attempt__c)oldRec;
            if(oldCoursAttmpt.Course_Attempt_Status__c != newCoursAttmpt.Course_Attempt_Status__c && newCoursAttmpt.Course_Attempt_Status__c == 'Enrolled' &&
               (oldCoursAttmpt.Course_Attempt_Status__c == 'Inactive' || oldCoursAttmpt.Course_Attempt_Status__c == 'Unconfirm') && newCoursAttmpt.Contact__c != null) {
                contactId.add(newCoursAttmpt.Contact__c);
            }
        }
        
        public override void execute() {
            if(!contactId.isEmpty()){
                CourseAttemptUtility.closeLinkedOCRS(contactId);
            }
        }
    }
    
    /**
    * @description returns a formatted Course Attempt Name value
    * @param sca : Course Attempt record
    */
    public static String getUniqueName(Course_Attempt__c sca) {
        return getUniqueName(sca.Contact_Person_Id__c, 
                             sca.Course_Code__c, 
                             sca.Deleted_In_Source__c);
    }
    
    /**
    * @description returns a formatted Course Attempt Name value
    * @param personId : Person ID of related contact
    * @param courseCd : Course Code
    * @param dis: deleted in source flag
    */
    public static String getUniqueName(String personId, String courseCd, Boolean dis) {
        String name;
        if (dis) {
            name = '[Pending Delete] ' + personId + '/' + courseCd;
        } else {
            name = personId + '/' + courseCd;
        }
        
        return name;
    }
}