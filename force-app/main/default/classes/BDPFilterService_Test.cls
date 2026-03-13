/**
 * @author      Jasmin Joy Rudio
 * @description Test class for Bulk_Data_Processing__c object selector class
 * @group       
 * @revision    06/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest
public with sharing class BDPFilterService_Test {
    
    @testSetup static void setup() {
        //Account Createion
        TriggerCommon.disableTrigger('Account');
        Account acc = (Account)TestDataFactory.createSObject(new Account(Callista_Org_Unit_Code__c = 'DIRECT'), true);
        //Contact Creation
        TriggerCommon.disableTrigger('Contact');
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id, Person_ID_unique__c='123456'), true);
        TriggerCommon.disableTrigger('Country_Attribute__c');
        Country_Attribute__c country = (Country_Attribute__c)TestDataFactory.createSObject(new Country_Attribute__c(Name = 'MALAYSIA'), true);
        TriggerCommon.disableTrigger('Calendar__c');
        Calendar__c calendar = (Calendar__c)TestDataFactory.createSObject(new Calendar__c(), true);
        //Application Creation
        TriggerCommon.disableTrigger('Application__c');
        Application__c app = (Application__c)TestDataFactory.createSObject(new Application__c(Applicant__c = contact.Id), true);
        //ACP Creation
        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        insert new Application_Course_Preference__c[]{
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                        Course_Code__c = 'E6001',
                        Course_Code_Unique__c = 'E60017',
                        Application__c = app.Id), false)
                };
        //disable trigger execution
        SBQQ.TriggerControl.disable();
        //Bulk Data Processing Creation
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
        bdp.Applicant__c = contact.Id;
        bdp.Person_ID__c = '123456';
        bdp.Transfer_Calendar__c = '2021/1';
        insert bdp;
    }

    @isTest
    private static void meetBDPFieldUpdateService(){
        Bulk_Data_Processing__c oldBdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
        Bulk_Data_Processing__c newBdp = oldBdp.clone(false, false);
        newBdp.Person_ID__c = 'hello';
        newBdp.Transfer_Calendar__c = '2021/1';
        newBDP.Calendar__c = 'a3Y4Y0000000a9fUAA';
        newBDP.Applicant__c = '0034Y0000032707QAA';
        BDPFilterService service = new BDPFilterService();
        Test.startTest();
        Boolean conditionMet = BDPFilterService.meetBDPFieldUpdateService(newBdp, oldBdp);
        Test.stopTest();
        System.assertEquals(conditionMet, true);
    }

    @isTest
    private static void meetACPMatchingService(){
        Application_Course_Preference__c acp = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];
        Bulk_Data_Processing__c bdp = [SELECT Transfer_To__c FROM Bulk_Data_Processing__c LIMIT 1];
        bdp.Transfer_To__c = acp.Id;
        Test.startTest();
            Boolean conditionMet = BDPFilterService.meetACPMatchingService(bdp, bdp);
        Test.stopTest();
        System.assertEquals(conditionMet, false);
    }


    @isTest
    static void shouldDetectNoOfferCondChangeIfNoChangeInOfferConditionValue() {
        Bulk_Data_Processing__c oldBdp = new Bulk_Data_Processing__c();
        oldBdp.Offer_Condition__c = 'The applicant must purchase listed equipment before course starts.';

        Bulk_Data_Processing__c newBdp = oldBdp.clone();
        Boolean hasChanged = BDPFilterService.isOfferConditionChanged(oldBdp, newBdp);
        System.assertEquals(false, hasChanged, 
            'Expected no change since the offer condition should be the same.'
        );
    }

    @isTest
    static void shouldDetectOfferCondChangeIfChangeInOfferConditionValue() {
        Bulk_Data_Processing__c oldBdp = new Bulk_Data_Processing__c();
        oldBdp.Offer_Condition__c = 'The applicant must purchase listed equipment before course starts.';

        Bulk_Data_Processing__c newBdp = new Bulk_Data_Processing__c();
        newBdp.Offer_Condition__c = 'The applicant must purchase listed equipment before course commences.';
        Boolean hasChanged = BDPFilterService.isOfferConditionChanged(oldBdp, newBdp);
        System.assertEquals(true, hasChanged, 
            'Expected change since the offer condition is no longer the same.'
        );
    }

    @isTest
    static void shouldDetectOfferCondChangeIfChangeInOfferConditionValueFromBlank() {
        Bulk_Data_Processing__c oldBdp = new Bulk_Data_Processing__c();
        oldBdp.Offer_Condition__c = '';

        Bulk_Data_Processing__c newBdp = new Bulk_Data_Processing__c();
        newBdp.Offer_Condition__c = 'The applicant must purchase listed equipment before course commences.';
        Boolean hasChanged = BDPFilterService.isOfferConditionChanged(oldBdp, newBdp);
        System.assertEquals(true, hasChanged, 
            'Expected change since the offer condition was changed from blank to a value.'
        );
    }

    @isTest
    static void shouldDetectOfferCondChangeIfChangeInOfferConditionValueToBlank() {
        Bulk_Data_Processing__c oldBdp = new Bulk_Data_Processing__c();
        oldBdp.Offer_Condition__c = 'The applicant must purchase listed equipment before course starts.';

        Bulk_Data_Processing__c newBdp = new Bulk_Data_Processing__c();
        newBdp.Offer_Condition__c = '';
        Boolean hasChanged = BDPFilterService.isOfferConditionChanged(oldBdp, newBdp);
        System.assertEquals(true, hasChanged, 
            'Expected change since the offer condition was changed to blank from a non blank value.'
        );
    }

    @isTest
    static void shouldReturnFalseWhenTransferToAcpIsNotPopulated() {
        Bulk_Data_Processing__c bdp = new Bulk_Data_Processing__c();
        System.assertEquals(false, BDPFilterService.hasTransferToAcp(bdp), 
            'Expected false because the BDP does not have a transfer to ACP'
        );
    }

    @isTest
    static void shouldReturnTrueWhenTransferToAcpIsPopulated() {
        String bdpRecord = 
            '{"attributes":{"type":"Bulk_Data_Processing__c"}, '
            + '"Transfer_To__c":"' + FakeRecordIdGenerator.generateId(
                Application_Course_Preference__c.getSObjectType()) + '"'
            + '}';

        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c) JSON.deserialize(
            bdpRecord, Bulk_Data_Processing__c.class
        );
        
        System.assertEquals(true, BDPFilterService.hasTransferToAcp(bdp), 
            'Expected true because the BDP does have a transfer to ACP'
        );
    }

    /**
     * Test method to check if Offer Template change has been detected
     */
    @isTest
    static void shouldDetectOfferTemplateChange() {
        Bulk_Data_Processing__c oldBdp = new Bulk_Data_Processing__c();
        oldBdp.Offer_Template__c = 'Domestic Monash College - Australia';

        Bulk_Data_Processing__c newBdp = new Bulk_Data_Processing__c();
        newBdp.Offer_Template__c = null;
        Boolean hasChanged = BDPFilterService.meetOfferTemplateMatchingService(oldBdp, newBdp);
        System.assertEquals(true, hasChanged, 'Offer Template change to blank from a non blank value - NOT DETECTED.'
        );
    }

}