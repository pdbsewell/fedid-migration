/**
 * @author      Jasmin Joy Rudio
 * @description Test class for BDPBeforeInsertHandler class
 * @group       Bulk Data Processing 
 * @revision    07/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest
public with sharing class BDPBeforeInsertHandler_Test {
    @testSetup static void setup() {
        //Account Createion
        Account acc = (Account)TestDataFactory.createSObject(new Account(Callista_Org_Unit_Code__c = 'DIRECT'), true);
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id, Person_ID_unique__c = '123456'), true);
        Country_Attribute__c country = (Country_Attribute__c)TestDataFactory.createSObject(new Country_Attribute__c(Name = 'MALAYSIA'), true);
        //Calendar creation
        Calendar__c calendar = (Calendar__c)TestDataFactory.createSObject(new Calendar__c(), 'TestDataFactorySettings.CalendarDefaults', false);
        insert calendar;
    }
    
    @isTest
    private static void execute(){
        Contact con = [SELECT Id FROM Contact WHERE Person_ID_unique__c = '123456' LIMIT 1];
        Test.startTest();
            //Bulk Data Processing Creation
            Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
            bdp.Applicant__c = con.Id;
            bdp.Offer_Template__c = 'Domestic Coursework - Australia';
            insert bdp;
        Test.stopTest();
        Bulk_Data_Processing__c updatedBdp = [SELECT Credit_Duration_Value__c, Template_Type__c FROM Bulk_Data_Processing__c WHERE Id =: bdp.Id];
        System.assert(updatedBdp.Credit_Duration_Value__c == 2.00);
        System.assert('Domestic Coursework Australia' == updatedBdp.Template_Type__c, 'Expected is Domestic Coursework Australia'); // SFTG-2150 Added Offer Template ID and Type Handling to BDP Records
    }

}