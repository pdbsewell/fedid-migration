/**
 * @description Contains all test for CourseGroupServices
 **/
@isTest(isParallel=true)
public class CourseGroupServices_Test {
    
    @TestSetup
    static void initData(){

        Account faculty = new account (Name= 'School of Fish',callista_org_unit_code__c = 'Fish', recordtypeId=Schema.sObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId());
        insert faculty;
    }

    @isTest
    static void validate_fieldInserts() {

        test.startTest();
        course_group__c cg = new course_group__c (Course_Group__c='ABCD_1234',Type__c='Combined',Responsible_Org_Unit_Code__c='Fish',Is_Active__c=true);
        insert cg;
        test.stopTest();
        
        course_group__c rcg = [select name, Managing_Faculty__r.callista_org_unit_code__c from course_group__c where id = :cg.id];
        Assert.areEqual(cg.Course_Group__c,rcg.name);
        Assert.areEqual(cg.Responsible_Org_Unit_Code__c, rcg.Managing_Faculty__r.callista_org_unit_code__c);
    }
    
    @isTest
    static void validate_fieldUpdates() {

        course_group__c cg = new course_group__c (Course_Group__c='ABCD_1234',Type__c='Combined',Is_Active__c=true);
        insert cg;

        test.startTest();
		cg.Responsible_Org_Unit_Code__c = 'Fish';
        update cg;
        test.stopTest();
        
        course_group__c rcg = [select name, Managing_Faculty__r.callista_org_unit_code__c from course_group__c where id = :cg.id];
        Assert.areEqual(cg.Course_Group__c,rcg.name);
        Assert.areEqual(cg.Responsible_Org_Unit_Code__c, rcg.Managing_Faculty__r.callista_org_unit_code__c);
    }

}