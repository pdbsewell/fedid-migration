/**
 * @File Name          : CourseOfferingSelector_Test.cls
 * @Description        : Test class for Course Offering selector class
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 6/5/2020, 10:05:10 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/5/2020   jasmin.rudio@monash.edu     Initial Version
**/
@isTest(isParallel=true)
public with sharing class CourseOfferingSelector_Test {
    
    @isTest
    private static void shouldReturnACourseOfferingWhenCriteriaForSelectCourseOfferingByAcpMatches(){

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'C2001';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-IS';
        courseOffering.Unit_Set_Code__c = '';
        courseOffering.Citizenship_Type__c = 'INT-TEP';
        courseOffering.Start_Date__c = Date.today().addMonths(3);   
        // three months into the future, e.g. student applying for course for 
        // next semester
        courseOffering.Override_Reviewed__c = true;
        courseOffering.Active__c = true;
        
        TriggerCommon.disableTrigger('Course_Offering__c');
        insert courseOffering;
        
        Map<String, Set<String>> queryFields = new Map<String, Set<String>>();

        queryFields.put('CourseCodes', new Set<String>{'C2001'});
        queryFields.put('LocationCodes', new Set<String>{'CLAYTON'});
        queryFields.put('AttendanceTypes', new Set<String>{'FT'});
        queryFields.put('AttendanceModes', new Set<String>{'IN'});
        queryFields.put('AdmissionCategory', new Set<String>{'UG-IS'});
        queryFields.put('CitizenshipTypes', new Set<String>{'INT-TEP'});


        Test.startTest();
        CourseOfferingSelector co = new CourseOfferingSelector(true);
        new CourseOfferingSelector().selectById(new Set<Id>()); 
        new CourseOfferingSelector().selectMapById(new Set<Id>());
        List<Course_Offering__c> courseOfferings = new CourseOfferingSelector().selectCourseOfferingByAcp(queryFields);
        System.assertEquals(
            1, courseOfferings.size(), 
            'Expected one matching course offering as all criteria matches.');
        Test.stopTest();
    }

    @isTest
    private static void shouldReturnACourseOfferingWhenCriteriaForSelectCourseOfferingByAcpMatchesForOneOfTwo(){

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'C2001';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-IS';
        courseOffering.Unit_Set_Code__c = '';
        courseOffering.Citizenship_Type__c = 'INT-TEP';
        courseOffering.Start_Date__c = Date.today().addMonths(3);   
        // three months into the future, e.g. student applying for course for 
        // next semester
        courseOffering.Override_Reviewed__c = true;
        courseOffering.Active__c = true;
        
        TriggerCommon.disableTrigger('Course_Offering__c');
        insert courseOffering;
        
        Map<String, Set<String>> queryFields = new Map<String, Set<String>>();
        // Second entries in set is a course which doesn't exist in the database
        // for the test scenario
        queryFields.put('CourseCodes', new Set<String>{'C2001', 'E6001'});
        queryFields.put('LocationCodes', new Set<String>{'CLAYTON'});
        queryFields.put('AttendanceTypes', new Set<String>{'FT', 'PT'});
        queryFields.put('AttendanceModes', new Set<String>{'IN', 'DOM'});
        queryFields.put('AdmissionCategory', new Set<String>{'UG-IS'});
        queryFields.put('CitizenshipTypes', new Set<String>{'INT-TEP'});


        Test.startTest();
        CourseOfferingSelector co = new CourseOfferingSelector(true);
        new CourseOfferingSelector().selectById(new Set<Id>()); 
        new CourseOfferingSelector().selectMapById(new Set<Id>());
        List<Course_Offering__c> courseOfferings = new CourseOfferingSelector().selectCourseOfferingByAcp(queryFields);
        System.assertEquals(
            1, courseOfferings.size(), 
            'Expected one matching course offering as only one course offering has criteria matching.'
        );
        Test.stopTest();
    }

    @isTest
    private static void shouldReturnNoCourseOfferWhenCriteriaForSelectCourseOfferingByAcpNotMatch(){

        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'C2001';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'PT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-IS';
        courseOffering.Unit_Set_Code__c = '';
        courseOffering.Citizenship_Type__c = 'INT-TEP';
        courseOffering.Start_Date__c = Date.today().addMonths(3);   
        // three months into the future, e.g. student applying for course for 
        // next semester
        courseOffering.Override_Reviewed__c = true;
        courseOffering.Active__c = true;
        
        TriggerCommon.disableTrigger('Course_Offering__c');
        insert courseOffering;
        
        Map<String, Set<String>> queryFields = new Map<String, Set<String>>();

        queryFields.put('CourseCodes', new Set<String>{'C2001'});
        queryFields.put('LocationCodes', new Set<String>{'CLAYTON'});
        queryFields.put('AttendanceTypes', new Set<String>{'FT'});
        queryFields.put('AttendanceModes', new Set<String>{'IN'});
        queryFields.put('AdmissionCategory', new Set<String>{'UG-IS'});
        queryFields.put('UnitSetCodes', new Set<String>());
        queryFields.put('CitizenshipTypes', new Set<String>{'INT-TEP'});


        Test.startTest();
        CourseOfferingSelector co = new CourseOfferingSelector(true);
        new CourseOfferingSelector().selectById(new Set<Id>()); 
        new CourseOfferingSelector().selectMapById(new Set<Id>());
        List<Course_Offering__c> courseOfferings = new CourseOfferingSelector().selectCourseOfferingByAcp(queryFields);
        System.assertEquals(
            new List<Course_Offering__c>(), courseOfferings, 
            'Expected an empty list because 1 critiera did not match.');
        Test.stopTest();
    }

    @isTest
    private static void shouldReturnNoValuesWhenCriteriaForSelectCourseOfferingByAcpIsBlank(){
        Map<String, Set<String>> queryFields = new Map<String, Set<String>>();
        List<String> queryKeys = new List<String>{'CourseCodes', 'LocationCodes', 'AttendanceTypes', 'AttendanceModes',
                                                    'AdmissionCategory', 'UnitSetCodes', 'CitizenshipTypes'};                    
        for (String key : queryKeys) {
            queryFields.put(key, new Set<String>());
        }
        Test.startTest();
        CourseOfferingSelector co = new CourseOfferingSelector(true);
        new CourseOfferingSelector().selectById(new Set<Id>()); 
        new CourseOfferingSelector().selectMapById(new Set<Id>());
        List<Course_Offering__c> courseOfferings = new CourseOfferingSelector().selectCourseOfferingByAcp(queryFields);
        System.assertEquals(
            new List<Course_Offering__c>(), courseOfferings, 
            'Expected an empty list when all criterias are blank.');
        Test.stopTest();
    }

    @isTest
    static void shouldReturnASObjectType() {
        CourseOfferingSelector courseOfferingSelector = 
            new CourseOfferingSelector();
        Test.startTest();
        System.assertNotEquals(null, courseOfferingSelector.getSObjectType(), 
            'Expected an sobject type to be defined.');
        Test.stopTest();
    }

    @isTest
    static void shouldReturnOneMatchingRecordWhenIdExistsForSelectById() {
        
        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course_Code__c = 'TEST1';
        TriggerCommon.disableTrigger('Course_Offering__c');
        insert courseOffering;
        
        Test.startTest();
        CourseOfferingSelector courseOfferingSelector = 
            new CourseOfferingSelector();
        System.assertEquals(
            1, 
            courseOfferingSelector.selectById(
                new Set<Id> {courseOffering.Id}
            ).size(), 
            'Expected one record to be returned for the matching Id.');
        
        Test.stopTest();
    }

    @isTest
    static void shouldReturnOrderByValue() {
        Test.startTest();
        CourseOfferingSelector courseOfferingSelector = 
            new CourseOfferingSelector();
        System.assertNotEquals(null, courseOfferingSelector.getOrderBy(),
            'Expected order by string to be defined in selector');
        Test.stopTest();
    }
}