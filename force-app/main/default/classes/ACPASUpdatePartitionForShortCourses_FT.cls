/**
 * @description       : Test class for ACP: AS: Update Partition For Short Courses
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 04-07-2025
 */
@isTest(isParallel=true)
public with sharing class ACPASUpdatePartitionForShortCourses_FT {
    
    @testSetup
    // Create common test data
    static void setupTestData() {
        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=false);
    }
    
    @isTest
    // Test Insert Partition For Short Courses
    static void testInsertPartitionForShortCourses() {
        // Given: Create a new Application_Course_Preference record
        Application_Course_Preference__c ACP = new Application_Course_Preference__c();
        
        // When: Insert Application_Course_Preference record
        Test.startTest();
        insert ACP;
        Test.stopTest();
        
        // Then: Validate Course Type Text and Managing Faculty Text
        Application_Course_Preference__c insertedACP = [
            SELECT Id, Course_Type_Text__c, Managing_Faculty_Text__c 
            FROM Application_Course_Preference__c 
            WHERE Id = :ACP.Id
            LIMIT 1
        ];
        
        Assert.areEqual('Short_Course', insertedACP.Course_Type_Text__c, 'Course Type Text should be Short_Course');
        Assert.isNull(insertedACP.Managing_Faculty_Text__c, 'Managing Faculty Text should be null');
    }
    
    @isTest
    // Test Update Partition For Short Courses
    static void testUpdatePartitionForShortCourses() {
        // Given: Create a new Application_Course_Preference record
        Application_Course_Preference__c ACP = new Application_Course_Preference__c();
        insert ACP;
        
        // When: Update Application_Course_Preference record
        Test.startTest();
        update ACP;
        Test.stopTest();
        
        // Then: Validate Course Type Text and Managing Faculty Text
        Application_Course_Preference__c updatedACP = [
            SELECT Id, Course_Type_Text__c, Managing_Faculty_Text__c 
            FROM Application_Course_Preference__c 
            WHERE Id = :ACP.Id
            LIMIT 1
        ];
        
        Assert.areEqual('Short_Course', updatedACP.Course_Type_Text__c, 'Course Type Text should be Short_Course after update');
        Assert.isNull(updatedACP.Managing_Faculty_Text__c, 'Managing Faculty Text should be null after update');
    }
}