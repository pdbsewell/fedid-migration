@isTest(isParallel=true)
public with sharing class CoursesSelector_Test {
    @istest static void test_getSObjectType() {
        System.assert(new CoursesSelector(false).getSObjectType() == Course__c.sObjectType);
	}
    @istest static void test_selectById() {
		System.assert(new CoursesSelector().selectById(new Set<Id>()).isEmpty());
    }    
    @istest static void test_selectMapById() {
		System.assert(new CoursesSelector().selectMapById(new Set<Id>()).isEmpty());
	}
    @istest static void test_selectCourseByExternalId() {
        System.assert(new CoursesSelector().selectCourseByExternalId(new Set<String>(), Course__c.Course_Code__c).isEmpty());
    }
}