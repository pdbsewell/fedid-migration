/**
 * @author      Jasmin Joy Rudio
 * @description Test class for BDPAfterInsertHandler class
 * @group       Bulk Data Processing 
 * @revision    07/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest
public with sharing class BDPAfterInsertHandler_Test {
    @testSetup static void setup() {
        //Account Createion
        Account acc = (Account)TestDataFactory.createSObject(new Account(Callista_Org_Unit_Code__c = 'DIRECT'), true);
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id, Person_ID_unique__c='123456'), true);
        //Application Creation
        Application__c app = (Application__c)TestDataFactory.createSObject(new Application__c(Applicant__c = contact.Id), true);
        Country_Attribute__c country = (Country_Attribute__c)TestDataFactory.createSObject(new Country_Attribute__c(Name = 'MALAYSIA'), true);
        //Calendar creation
        Calendar__c calendar = (Calendar__c)TestDataFactory.createSObject(new Calendar__c(), 'TestDataFactorySettings.CalendarDefaults', false);
        insert calendar; 
    }
    
    @isTest
    private static void execute(){
        Test.startTest();
            //Bulk Data Processing Creation
            Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
            bdp.Transfer_Course_Campus__c = 'CLAYTON';
            bdp.Person_ID__c = '123456';
            insert bdp;
        Test.stopTest();
        Contact con = [SELECT Id FROM Contact WHERE Person_ID_unique__c='123456' LIMIT 1];
        Bulk_Data_Processing__c updatedBdp = [SELECT Applicant__c FROM Bulk_Data_Processing__c WHERE Id =: bdp.Id];
        System.assert(updatedBdp.Applicant__c == con.Id);
    }

}