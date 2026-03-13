/**
 * @description       : Test class for ArchivingBatch
 * @author            : Mac Domingo
 * @group             : Platforms
 * @last modified on  : 2023-18-08
 * @last modified by  : Mac Domingo
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2023-18-08 - Mac Domingo - Added test for ArchivingBatch
 * 2.0 	 2025-12-03 - Jackie Ho - Added tests for "Ready to Archive" fields and SObjects
**/
@IsTest(IsParallel=true) 
private class ArchivingBatch_Test {
    /*******************************************************************************
     * @author       Mac Domingo
     * @date         2023-18-08
     * @description  Tests the ArchivingBatch 
    *******************************************************************************/ 
    static testmethod void testArchivingBatch() {
        String enquiryRecordTypeDevName = 'Monash_Connect_Enquiry';
        // Get the record type ID using the Schema class
        Id enquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(enquiryRecordTypeDevName).getRecordTypeId();

        // Create a test case 
        Case testCase = new Case();  
        testCase.Subject = 'Test Case';
        testCase.RecordTypeId = enquiryRecordTypeId;
        testCase.Status = 'Solved';
        insert testCase; 
        
        // Create a test Role 
        Roles__c testRole = new Roles__c(); 
        testRole.Status__c  = 'Accepted '; 
        insert testRole; 
        
        // Create a test Channel 
        Channel__c testChannel = new Channel__c(); 
        testChannel.Type__c = 'Mailing'; 
        insert testChannel; 

        //WHEN the case and metadata record are assigned to the wrapper
        List<IterableWrapper> wrapperRecords = new List<IterableWrapper>();
        
        // Create a new Case IterableWrapper object 
        IterableWrapper caseWrapper = new IterableWrapper();
        caseWrapper.objRecord = testCase; 
        caseWrapper.objectName = 'Case'; 
        caseWrapper.yrsToArchive = 1; 
        caseWrapper.yrsToPurge = 2; 
        caseWrapper.readyToArchive = true;
        wrapperRecords.add(caseWrapper);
        
        // Create a new Role IterableWrapper object 
        IterableWrapper roleWrapper = new IterableWrapper();
        roleWrapper.objRecord = testRole; 
        roleWrapper.objectName = 'Role'; 
        roleWrapper.readyToArchive = true; 
        wrapperRecords.add(roleWrapper);
        
        // Create a new Channel IterableWrapper object 
        IterableWrapper channelWrapper = new IterableWrapper();
        channelWrapper.objRecord = testChannel; 
        channelWrapper.objectName = 'Channel'; 
		channelWrapper.readyToArchive = true; 
        wrapperRecords.add(channelWrapper);
        
        // Start the batch
        ArchivingBatch arcbatch = new ArchivingBatch();
        Test.startTest();
        // Instantiate the batch class
        Id jobId = Database.executeBatch(arcbatch, 200);
        Nebula.Logger.info(jobId);
        Test.stopTest();
        
        //Then the values should be correctly assigned
        // Assert that the object was created correctly 
        Assert.areEqual(testCase, caseWrapper.objRecord); 
        Assert.areEqual('Case', caseWrapper.objectName); 
        Assert.areEqual(1, caseWrapper.yrsToArchive); 
        Assert.areEqual(2, caseWrapper.yrsToPurge);   
		Assert.areEqual(true, caseWrapper.readyToArchive);
        
        Assert.areEqual(testRole, roleWrapper.objRecord); 
        Assert.areEqual('Role', roleWrapper.objectName); 
        Assert.areEqual(true, roleWrapper.readyToArchive); 
        
        Assert.areEqual(testChannel, channelWrapper.objRecord); 
        Assert.areEqual('Channel', channelWrapper.objectName); 
        Assert.areEqual(true, channelWrapper.readyToArchive); 
        
    }
}