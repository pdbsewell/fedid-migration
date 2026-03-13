/**
 * @description       : Test class for CustomIterable
 * @author            : Mac Domingo
 * @group             : Platforms
 * @last modified on  : 2023-18-08
 * @last modified by  : Mac Domingo
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2023-18-08 - Mac Domingo - Added test for CustomIterable
**/
@IsTest(IsParallel=true) 
private class CustomIterable_Test {
    @IsTest
    static void testCustomIterable() {
        // Get the record type developer name 
        String enquiryRecordTypeDevName = 'Monash_Connect_Enquiry'; 
        //GIVEN
        // Get the record type ID using the Schema class 
        Id enquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(enquiryRecordTypeDevName).getRecordTypeId(); 
        // Create test data
        Case caseRecord = new Case();
        caseRecord.Subject = 'Test Case';
        caseRecord.Status = 'Solved';
        caseRecord.RecordTypeId = enquiryRecordTypeId;
        insert caseRecord;
        
        Task taskRecord = new Task();
        taskRecord.Subject = 'Test Task';
        taskRecord.Status = 'Completed';
        insert taskRecord;
        
        //WHEN
        // Instantiate CustomIterable and iterate over the records
        CustomIterable customIterable = new CustomIterable();
        while (customIterable.hasNext()) {
            IterableWrapper wrapper = customIterable.next();            
            // Perform assertions
            //THEN
            System.assertEquals('Case', wrapper.objectName);
            System.assertEquals(1, wrapper.yrsToArchive);
            System.assertEquals(1, wrapper.yrsToPurge);
            System.assertEquals(caseRecord.Id, wrapper.objRecord.Id);
        }
    }
}