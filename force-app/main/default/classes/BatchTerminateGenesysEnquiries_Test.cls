@isTest(isParallel=true)
public class BatchTerminateGenesysEnquiries_Test {
    /*******************************************************************************
    * @description: Setup the Data for the test class.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @TestSetup
    static void setup() {
        // Contact
        Contact relStudent = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'First Student Name', Campus__c = 'Caulfield' ,LastName ='LastName', Email = 'FirstStudentName@test.com'), true);
        
        // Create Enquiry
        Case relEnq = (Case)TestDataFactory.createSObject(new Case(ContactId = relStudent.Id, Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId(), 
                                                                Category_Level_2__c = 'Welfare meetings', Enquiry_Type__c = 'Current Course', Category_Level_1__c = 'Under 18s'), true);
    } 
    
    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         8.Nov.2021
     * @description  Tests regarding to capturing the Hierarchy
    *******************************************************************************/ 
	@isTest 
    static void testExecuteBatch() {

        //GIVEN: Case exists
        Case cse = [SELECT Id FROM Case WHERE Contact.FirstName = 'First Student Name' ORDER BY CreatedDate DESC LIMIT 1];
                
        List<List<String>> input = new List<List<String>>();
        List<Id> l_caseIds = new List<Id>{cse.Id};
        
        //WHEN - Terminate Batch is executed
        //Start test
        Test.startTest();
        Id batchId = Database.executeBatch(new BatchTerminateGenesysEnquiries(l_caseIds, UserInfo.getUserId()));
        
        Test.stopTest();
          
        //THEN - Case is populated with Terminate Flag
        AsyncApexJob batchJob = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :batchId];
        System.assertEquals(true, batchJob!=null, 'Asynchronous Apex job was not created.');
        System.assertEquals(0, batchJob.NumberOfErrors, 'Asynchronous Apex job executed with errors');
        
        cse = [SELECT Id,Terminate_Genesys_Routing__c FROM Case WHERE Contact.FirstName = 'First Student Name' ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(cse.Terminate_Genesys_Routing__c, true, 'Terminate GeneSys Rules not updated');
    }
}