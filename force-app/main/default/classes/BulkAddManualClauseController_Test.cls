/**
 * @author      Jasmin Joy Rudio
 * @description Test class for BulkAddManualClauseController class
 * @group       Bulk Data Processing 
 * @revision    10/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest
public with sharing class BulkAddManualClauseController_Test {
    @testSetup static void setup() {
        //Account Createion
        Account acc = (Account)TestDataFactory.createSObject(new Account(Callista_Org_Unit_Code__c = 'DIRECT'), true);
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id, Person_ID_unique__c = '123456'), true);
        Country_Attribute__c country = (Country_Attribute__c)TestDataFactory.createSObject(new Country_Attribute__c(Name = 'MALAYSIA'), true);
        //Calendar creation
        Calendar__c calendar = (Calendar__c)TestDataFactory.createSObject(new Calendar__c(), 'TestDataFactorySettings.CalendarDefaults', false);
        insert calendar;
        //Bulk Data Processing Creation
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
        bdp.Applicant__c = contact.Id;
        insert bdp;
    }

    @isTest
    private static void standardController(){
        Bulk_Data_Processing__c bdp = [SELECT Id FROM Bulk_Data_Processing__c LIMIT 1];
        List<Bulk_Data_Processing__c> bdpList = new List<Bulk_Data_Processing__c>();
        bdpList.add(bdp);
        Test.startTest();
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(bdpList);
            stdSetController.setSelected(bdpList);
            BulkAddManualClauseController ext = new BulkAddManualClauseController(stdSetController);
            
            ApexPages.StandardController standardCtrl = new ApexPages.StandardController(bdp);
            BulkAddManualClauseController ctrl = new BulkAddManualClauseController(standardCtrl);
        Test.stopTest();
        System.assert(!String.isEmpty(ext.selectedRecordIds));
    } 

    @isTest
    private static void runStaticAuraMethods(){
        Bulk_Data_Processing__c bdp = [SELECT Id FROM Bulk_Data_Processing__c LIMIT 1];
        Test.startTest();
            String  manualClauses = BulkAddManualClauseController.getManualClauses(JSON.serialize(new String[]{bdp.Id}));
            String  saveManualClauses = BulkAddManualClauseController.saveBDPmanualClauses(null);
        Test.stopTest();
        System.assert(!String.isEmpty(manualClauses));
    }
}