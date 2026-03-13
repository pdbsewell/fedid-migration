/**
 * @author      Jasmin Joy Rudio
 * @description Test class for BDPBeforeUpdateHandler class
 * @group       Bulk Data Processing 
 * @revision    07/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest
public with sharing class BDPBeforeUpdateHandler_Test {
    @testSetup static void setup() {
        //Account Createion
        Account acc = (Account)TestDataFactory.createSObject(new Account(Callista_Org_Unit_Code__c = 'DIRECT'), true);
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id, Person_ID_unique__c='123456'), true);
        Country_Attribute__c country = (Country_Attribute__c)TestDataFactory.createSObject(new Country_Attribute__c(Name = 'MALAYSIA'), true); 
        //Application Creation
        Application__c app = (Application__c)TestDataFactory.createSObject(new Application__c(Applicant__c = contact.Id), true);
        //ACP Creation
        insert new Application_Course_Preference__c[]{
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                        Course_Code__c = 'E6001',
                        Course_Code_Unique__c = 'E60017',
                        Application__c = app.Id), false)
                };
        //disable trigger execution
        SBQQ.TriggerControl.disable();
        //Calendar creation
        Calendar__c calendar = (Calendar__c)TestDataFactory.createSObject(new Calendar__c(), 'TestDataFactorySettings.CalendarDefaults', false);
        insert calendar;
        //Bulk Data Processing Creation
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
        bdp.Applicant__c = contact.Id;
        insert bdp;
    }

    @isTest
    private static void execute(){
        Application_Course_Preference__c acp = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];
        Bulk_Data_Processing__c bdpToUpdate = [SELECT Id, Applicant__c, Current_Course_Code__c, Transfer_To__c, Type__c, Status__c,
                                            Credit_Duration__c, Credit_Duration_Value__c, Credit_Duration_Unit__c, Person_ID__c,
                                            Transfer_Calendar__c FROM Bulk_Data_Processing__c LIMIT 1];
        Test.startTest();
            bdpToUpdate.Current_Course_Code__c = 'C01234';
            bdpToUpdate.Transfer_To__c = acp.Id;
            update bdpToUpdate;
        Test.stopTest();
        Bulk_Data_Processing__c bdp = [SELECT Status__c FROM Bulk_Data_Processing__c WHERE Id =: bdpToUpdate.Id];
        System.assert(bdp.Status__c == BDPConstants.REVIEW_REQUIRED);
        
    }

    /**
     * Test Method to check whether Offer Template Type is populated correctly during BDP Record updation
     */
    @isTest
    private static void execute_testOfferTemplate(){
        Application_Course_Preference__c acp = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];
        Bulk_Data_Processing__c bdpToUpdate = [SELECT Id, Applicant__c, Current_Course_Code__c, Transfer_To__c, Type__c, Status__c,
                                            Credit_Duration__c, Credit_Duration_Value__c, Credit_Duration_Unit__c, Person_ID__c,
                                            Transfer_Calendar__c, Offer_Template__c, Template_Type__c  FROM Bulk_Data_Processing__c LIMIT 1];
        Test.startTest();
            bdpToUpdate.Offer_Template__c = 'Domestic Monash College - Australia';
            update bdpToUpdate;
        Test.stopTest();
        Bulk_Data_Processing__c bdp = [SELECT Template_Type__c FROM Bulk_Data_Processing__c WHERE Id =: bdpToUpdate.Id];
        System.assert(bdp.Template_Type__c == 'Domestic Monash College Australia', 'Offer Template not updated during BDP Update');
        
    }
}