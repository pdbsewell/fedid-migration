/**
 * @description       : Test class for JobTriggerHandlerOrgUnitHelper Class
 * @author            : Inderpal Dhanoa
 * @group             : Enterprise Engage
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2021-10-12 - Inderpal Dhanoa - Added test scenarios for JobTriggerHandlerOrgUnitHelper
 *                  - Martin Cadman   - Moved to Assert class
 */
@isTest(isParallel=true)
public class JobTriggerHandlerOrgUnitHelper_Test { 

    /**
     * @description Data setup
     */ 
    @testSetup
    static void testSetup() {

        Blob bHashSHA256 = Crypto.generateDigest('SHA256', blob.valueOf(String.valueof(Datetime.now())));
        String sJobCode = EncodingUtil.base64encode(bHashSHA256);

        List<Org_Unit__c> l_new_existingOrgs = new List<Org_Unit__c>();
        List<Account> l_existingOrgs = new List<Account>();

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();
        Account parentAcc = new Account(Name='acc0', Callista_Org_Unit_Code__c='50000249',Monash_AM_Start_Date__c=Date.today()-5, recordTypeId=recordTypeId);
        l_existingOrgs.add(parentAcc);

        Account childAcc = new Account(Name='acc1', Callista_Org_Unit_Code__c='50000250',Monash_AM_Start_Date__c=Date.today()-5, recordTypeId=recordTypeId, ParentId=parentAcc.Id);
        l_existingOrgs.add(childAcc);

		// An existing org with a start date that is later that then staging record.
        childAcc = new Account(Name='acc8', Callista_Org_Unit_Code__c='50000248',Monash_AM_Start_Date__c=Date.today(), recordTypeId=recordTypeId, ParentId=parentAcc.Id);
        l_existingOrgs.add(childAcc);
        
        insert l_existingOrgs;

        Org_Unit__c existingOrg = new Org_Unit__c();
        existingOrg.Status__c = 'NEW';
        existingOrg.Org_Id__c = '50000250';
        existingOrg.Level__c = '2';
        existingOrg.Name = 'acc1';
        existingOrg.Short_Name__c = 'test';
        existingOrg.Start_Date__c = Date.today() - 3;
        existingOrg.Job_Code__c = sJobCode;         
        existingOrg.Owner_Organisation_Id__c = '50000249';
        existingOrg.Relationship_Start_Date__c = Date.today()-3;
        existingOrg.Relationship_End_Date__c = Date.newInstance(2025,12,31);
        l_new_existingOrgs.add(existingOrg);

        Org_Unit__c newOrg = new Org_Unit__c();
        newOrg.Status__c = 'NEW';
        newOrg.Org_Id__c = '50000251';
        newOrg.Level__c = '2';
        newOrg.Name = 'acc2';
        newOrg.Short_Name__c = 'test2';
        newOrg.Start_Date__c = Date.today() - 3;
        newOrg.Job_Code__c = sJobCode;         
        newOrg.Owner_Organisation_Id__c = '50000249';
        newOrg.Relationship_Start_Date__c = Date.today()-3;
        newOrg.Relationship_End_Date__c = Date.newInstance(2025,12,31);
        l_new_existingOrgs.add(newOrg);
        
        Org_Unit__c newOrg2 = new Org_Unit__c();
        newOrg2.Status__c = 'NEW';
        newOrg2.Org_Id__c = '50000252';
        newOrg2.Level__c = '2';
        newOrg2.Name = 'acc3';
        newOrg2.Short_Name__c = 'test3';
        newOrg2.Start_Date__c = Date.today() - 3;
        newOrg2.Job_Code__c = sJobCode;         
        newOrg2.Owner_Organisation_Id__c = '50000251';
        newOrg2.Relationship_Start_Date__c = Date.today()-3;
        newOrg2.Relationship_End_Date__c = Date.newInstance(2025,12,31);
        l_new_existingOrgs.add(newOrg2);

        Org_Unit__c newOrg3 = new Org_Unit__c();
        newOrg2.Status__c = 'NEW';
        newOrg2.Org_Id__c = '50000248';
        newOrg2.Level__c = '2';
        newOrg2.Name = 'acc8';
        newOrg2.Short_Name__c = 'test8';
        newOrg2.Start_Date__c = Date.today() - 3;
        newOrg2.Job_Code__c = sJobCode;         
        newOrg2.Owner_Organisation_Id__c = '50000249';
        newOrg2.Relationship_Start_Date__c = Date.today()-3; // This is behind the account record
        newOrg2.Relationship_End_Date__c = null;
        l_new_existingOrgs.add(newOrg3);
        
        
        insert l_new_existingOrgs;

        Job_Control__c jobCtrl = new Job_Control__c();
        jobCtrl.Processing_Status__c = 'Loading Target In Progress';
        jobCtrl.Job_Code__c = sJobCode;
        jobCtrl.Process_Name__c = 'Org_Unit';
        insert jobCtrl;
    }

    /**
     * @author                      Inderpal Dhanoa
     * @created                     2021-09-17
     * @description                 Test for retrieving SAP HR Org Units to be synced with CRM
    */
    @isTest 
	private static void testProcessJobControlRecord() {
        
        /* GIVEN */
        // The Account have diff Start Date
        Account accountSync = [SELECT Id,Monash_AM_Start_Date__c FROM Account WHERE Callista_Org_Unit_Code__c='50000250'];
        Assert.areEqual(accountSync.Monash_AM_Start_Date__c, Date.today() - 5);

        /* THEN */
        // The JOb control is updated for the trigger to compare STG Org Units and Account
        Test.startTest();

        List<Job_Control__c> l_jobList = [Select Id,Processing_Status__c from Job_Control__c];
        for(Job_Control__c  obj : l_jobList){
            obj.Processing_Status__c = 'CRM Ready To Process'; 
        }
        update l_jobList;
        
        Test.stopTest();

        //THEN: Check if the Accounts have been synced
        accountSync = [SELECT Id,Monash_AM_Start_Date__c FROM Account WHERE Callista_Org_Unit_Code__c='50000250'];
        Assert.areEqual(accountSync.Monash_AM_Start_Date__c, Date.today() - 5); // start date should be the same

        l_jobList = [Select Id, Processing_Status__c from Job_Control__c];
        Assert.areEqual(l_jobList[0].Processing_Status__c,'Target Load Completed');

        accountSync = [SELECT Id,Monash_AM_End_Date__c FROM Account WHERE Callista_Org_Unit_Code__c='50000249'];
        Assert.areEqual(accountSync.Monash_AM_End_Date__c, Date.today());

        accountSync = [SELECT Id,Monash_AM_Start_Date__c FROM Account WHERE Callista_Org_Unit_Code__c='50000248'];
        Assert.areEqual(accountSync.Monash_AM_Start_Date__c, Date.today()); // The start date should not have changed (gone backwards)
    }
}