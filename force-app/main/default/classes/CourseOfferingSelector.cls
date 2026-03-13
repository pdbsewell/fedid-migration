/**
 * @File Name          : CourseOfferingSelector.cls
 * @Description        : Selector class for Course Offering object processes
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 6/1/2020, 1:05:38 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/28/2020   jasmin.rudio@monash.edu     Initial Version
**/
public with sharing class CourseOfferingSelector extends BaseSelector{
    /**
     * Constructors
     */
	public CourseOfferingSelector() {
	    super(false);
	} 
	
    public CourseOfferingSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }

    public override String getOrderBy() {
        return 'Admission_Calendar_Description__c ASC';
    }
	
	public Schema.SObjectType getSObjectType() {
		return Course_Offering__c.sObjectType;
	}

    public List<Course_Offering__c> selectById(Set<Id> idSet) {
		return (List<Course_Offering__c>) selectSObjectsById(idSet);
	}

    public Map<ID,Course_Offering__c> selectMapById(Set<Id> idSet) {
		return new Map<ID, Course_Offering__c>(selectById(idSet));
    }
    
    public List<Course_Offering__c> selectCourseOfferingByAcp(Map<String, Set<String>> queryFields) {      
        return [SELECT Id, Course_Code__c, Admission_Calendar_Type__c, Admission_Calendar_Description__c, Location_Code__c, Attendance_Type__c, Course_Duration__c, Override_Duration__c, 
                Attendance_Mode__c, Admission_Category__c, Unit_Set_Code__c, Commencement_Period__c, Start_Date__c, End_Date__c, Academic_Year__c, Citizenship_Type__c, Admission_CI_Sequence_Number__c,Override_Duration_Unit__c
                FROM Course_Offering__c WHERE Course_Code__c IN: queryFields.get('CourseCodes') 
                AND Location_Code__c IN: queryFields.get('LocationCodes') 
                AND Attendance_Type__c IN: queryFields.get('AttendanceTypes') 
                AND Attendance_Mode__c IN: queryFields.get('AttendanceModes') 
                AND Admission_Category__c IN: queryFields.get('AdmissionCategory') 
                AND Unit_Set_Code__c IN: queryFields.get('UnitSetCodes') 
                AND Citizenship_Type__c IN: queryFields.get('CitizenshipTypes') 
                AND Start_Date__c > TODAY 
                AND  Override_Reviewed__c = true
                AND Active__c = true   
                ORDER BY Admission_Calendar_Description__c ASC];
    }
        
}