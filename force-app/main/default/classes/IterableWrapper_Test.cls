/**
 * @description       : Test class for IterableWrapper
 * @author            : Mac Domingo
 * @group             : Platforms
 * @last modified on  : 2023-18-08
 * @last modified by  : Mac Domingo
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2023-18-08 - Mac Domingo 	- 	Added test for IterableWrapper
 * 2.0	 2025-17-08 - Sachin Shetty	- 	Formatting
**/
@IsTest
public class IterableWrapper_Test {
    /*******************************************************************************
     * @author       Mac Domingo
     * @date         2023-18-08
     * @description  Tests the IterableWrapper 
    *******************************************************************************/ 
    static testMethod void testIterableWrapper() {
        // Get the record type developer name 
        String enquiryRecordTypeDevName = 'Monash_Connect_Enquiry'; 
 
        // Get the record type ID using the Schema class 
        Id enquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(enquiryRecordTypeDevName).getRecordTypeId(); 
        //GIVEN: Test case records are created
        // Create a test case 
        Case testCase = new Case(); 
        testCase.RecordTypeId = enquiryRecordTypeId; 
        testCase.Subject = 'Test Case'; 
        testCase.Description = 'This is a test case'; 
        insert testCase; 

        //WHEN the case and metadata record are assigned to the wrapper
        // Create a new IterableWrapper object 
        IterableWrapper wrapper = new IterableWrapper(); 
        wrapper.objRecord = testCase; 
        wrapper.objectName = 'Case'; 
        wrapper.yrsToArchive = 5; 
        wrapper.yrsToPurge = 10; 

        //Then the values should be correctly assigned
        // Assert that the values were assigned correctly 
        Assert.areEqual(testCase, wrapper.objRecord); 
        Assert.areEqual('Case', wrapper.objectName); 
        Assert.areEqual(5, wrapper.yrsToArchive); 
        Assert.areEqual(10, wrapper.yrsToPurge); 
    } 
}