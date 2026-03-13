/**
 * @description       : Trigger Handler test Class to manage all DML and events on Contact Report
 * @author            : Inderpal Dhanoa
 * @group             : Engage Enterprise 
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   2021-10-18 - Inderpal Dhanoa -   Added a functionality to handle Insert and Delete for Contact Reports
**/
@isTest(isParallel=true)
public class ContactReportTriggerHandler_Test { 
    @testSetup static void dataSetup() {
        Account accountRecord = new Account(name ='AccountTest', RecordTypeId = AccountUtility.ACCOUNT_EXTERNAL_ORG_REC_TYPE) ;
        insert accountRecord;

        Contact testContact = new Contact(LastName = 'TestApplicant', MailingCountry = 'Australia');
        insert testContact;
    }

    /**
     * @author      Inderpal Dhanoa 
     * @description Create the task Linked to the COntact Report if record is created
     * @revision    18/10/2021 - Inderpal Dhanoa - Created
     */
    @isTest
    public static void testInsert() {
		// GIVEN: A Contact & Account are created
        Contact relCont = [SELECT Id FROM CONTACT WHERE Lastname = 'TestApplicant' LIMIT 1];

		// WHEN: Method is invoked to add a Contact Report is created
        ucinn_ascendv2__Contact_Report__c conRep = new ucinn_ascendv2__Contact_Report__c();
        conRep.ucinn_ascendv2__Contact__c = relCont.Id;
        conRep.ucinn_ascendv2__Contact_Method__c = 'Phone';
        conRep.ucinn_ascendv2__Description__c = 'Test';
        conRep.ucinn_ascendv2__Contact_Report_Body__c = 'test';
        conRep.ucinn_ascendv2__Date__c = date.today() - 5;
        insert conRep;

		// THEN: Task is created
        Task linkedTask = [SELECT Id, WhoId FROM TASK WHERE WhoId = :relCont.Id LIMIT 1];
        system.assertEquals(linkedTask.WhoId, relCont.Id);
    }


    /**
     * @author      Inderpal Dhanoa
     * @description Update the task Linked to the COntact Report if record is updated
     * @revision    18/10/2021 - Inderpal Dhanoa - Created
     */
    @isTest
    public static void testUpdate() {
		// GIVEN: A Contact & Account are created
        Contact relCont = [SELECT Id FROM CONTACT WHERE Lastname = 'TestApplicant' LIMIT 1];
		
        ucinn_ascendv2__Contact_Report__c conRep = new ucinn_ascendv2__Contact_Report__c();
        conRep.ucinn_ascendv2__Contact__c = relCont.Id;
        conRep.ucinn_ascendv2__Contact_Method__c = 'Phone';
        conRep.ucinn_ascendv2__Description__c = 'Test';
        conRep.ucinn_ascendv2__Contact_Report_Body__c = 'test'; 
        conRep.ucinn_ascendv2__Date__c = date.today() - 5;
        insert conRep;

        // WHEN: Method is invoked to update the Contact Report 
        conRep = [SELECT Id, ucinn_ascendv2__Description__c FROM ucinn_ascendv2__Contact_Report__c WHERE ucinn_ascendv2__Contact__c = :relCont.Id];
        conRep.ucinn_ascendv2__Description__c = 'Test 1'; 
        update conRep; 

		// THEN: Task is updated
        Task linkedTask = [SELECT Id, Subject FROM TASK WHERE WhoId = :relCont.Id LIMIT 1];
        system.assertEquals(linkedTask.Subject, 'Contact Report Test 1'); 
        
        // GIVEN: task is accidentally deleted
        delete linkedTask;

        //WHEN: Method is invoked to update the Contact Report 
        conRep = [SELECT Id, ucinn_ascendv2__Description__c FROM ucinn_ascendv2__Contact_Report__c WHERE ucinn_ascendv2__Contact__c = :relCont.Id];
        conRep.ucinn_ascendv2__Description__c = 'Test 2'; 
        update conRep; 

		// THEN: Task is re-created
        linkedTask = [SELECT Id, Subject FROM TASK WHERE WhoId = :relCont.Id LIMIT 1];
        system.assertEquals(linkedTask.Subject, 'Contact Report Test 2'); 
    }

    /**
     * @author      Inderpal Dhanoa
     * @description Delete the task Linked to the COntact Report if record is removed
     * @revision    22/06/2021 - Inderpal Dhanoa - Created
     */
    @isTest
    public static void testDelete() {
		// GIVEN: A Contact & Account are created
        Contact relCont = [SELECT Id FROM CONTACT WHERE Lastname = 'TestApplicant' LIMIT 1];

        ucinn_ascendv2__Contact_Report__c conRep = new ucinn_ascendv2__Contact_Report__c();
        conRep.ucinn_ascendv2__Contact__c = relCont.Id;
        conRep.ucinn_ascendv2__Contact_Method__c = 'Phone';
        conRep.ucinn_ascendv2__Description__c = 'Test';
        conRep.ucinn_ascendv2__Contact_Report_Body__c = 'test';
        conRep.ucinn_ascendv2__Date__c = date.today() - 5;
        insert conRep;

        List<Task> linkedTask = [SELECT Id, WhoId FROM TASK WHERE WhoId = :relCont.Id LIMIT 1];
        system.assertEquals(linkedTask[0].WhoId, relCont.Id);

		// WHEN: Method is invoked to add a Contact Report is deleted
        delete conRep;
		
		// THEN: Task is deleted
        linkedTask = [SELECT Id, WhoId FROM TASK WHERE WhoId = :relCont.Id];
        system.assertEquals(linkedTask.size(), 0);
    }
}