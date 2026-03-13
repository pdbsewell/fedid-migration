/**
 * @author      Jasmin Joy Rudio
 * @description Test class for BDPFieldUpdateService class
 * @group       Bulk Data Processing 
 * @revision    06/07/2020 - Jasmin Joy Rudio - Created
 *              01/05/2023 - MJC API v57.0
 */
@isTest
public with sharing class BDPFieldUpdateService_Test {
    
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
    private static void execute(){
        Bulk_Data_Processing__c[] bdpList = [SELECT Id, Applicant__c, Current_Course_Code__c, Transfer_To__c, Type__c, Status__c,
                                            Credit_Duration__c, Credit_Duration_Value__c, Credit_Duration_Unit__c, Person_ID__c,
                                            Transfer_Calendar__c, Current_Course_Campus__c, Transfer_Admission_Category__c, Manual_ISCA_Edit__c
                                            FROM Bulk_Data_Processing__c];
        Test.startTest();
            BDPFieldUpdateService service = new BDPFieldUpdateService();
            IPromise pro = service.init();
            service.contactSelector = (ContactsSelector) Test.createStub(ContactsSelector.class, new ContactsSelectorMock());
            service.execute((SObject[]) bdpList);
        Test.stopTest();
        System.assert(service.contactPersonIdMap != null);
    }
    
    @isTest static void whenNoPersonIDMatch(){
        test.startTest();
        try{
            Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
            bdp.Person_ID__c = 'googoo';
            insert bdp;
            System.assert(false, 'Should have throw an exception.');
        }catch(Exception e){
            System.assert(true, 'Excpeted an exception as contact not found');
        }
        test.stopTest();
    }

    @isTest static void whenNoCalendarFoundMatch(){
        Contact contact = [SELECT id FROM Contact WHERE Person_ID_Unique__c = '123456' LIMIT 1];
        test.startTest();
        try{
            Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(), 'TestDataFactorySettings.BulkDataProcessingDefaults', false);
            bdp.Person_ID__c = '123456';
            bdp.Transfer_Calendar__c = 'hello';
            insert bdp;
            System.assert(false, 'Should have throw an exception.');
        }catch(Exception e){
            System.assert(true, 'Excpeted an exception as contact not found');
        }
        test.stopTest();
    }

    @isTest
    private static void runStaticMethods(){
        Application_Course_Preference__c acp = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];
        Bulk_Data_Processing__c[] bdpList = [SELECT Id, Applicant__c, Current_Course_Code__c, Transfer_To__c, Type__c, Status__c,
                                            Credit_Duration__c, Credit_Duration_Value__c, Credit_Duration_Unit__c, Person_ID__c,
                                            Transfer_Calendar__c, Current_Course_Campus__c, Transfer_Course_Campus__c, Current_Unit_Set__c,
                                            Transfer_Unit_Set__c, RecordTypeId, Transfer_Course_Code__c
                                            FROM Bulk_Data_Processing__c];
        test.startTest();
            bdpList[0].Transfer_To__c = acp.Id;
            bdpList[0].Credit_Duration__c = '2 Years';
            BDPFieldUpdateService.updateRecordType(bdpList[0]);
            BDPFieldUpdateService.updateStatus(bdpList[0]);
            BDPFieldUpdateService.splitCreditDuration(bdpList[0]);
        test.stopTest();
        System.assert(bdpList[0].Status__c == BDPConstants.READY_STATUS);
        System.assert(bdpList[0].Credit_Duration_Value__c == 2);
        System.assert(bdpList[0].Credit_Duration_Unit__c == 'Years');
    }

    @isTest
    static void shouldSetOnShoreTrueWhenCurrentCourseCampusIsInAustralia() {
        Bulk_Data_Processing__c currentCourseAuBdp = new Bulk_Data_Processing__c();
        currentCourseAuBdp.Current_Course_Campus__c = 'Clayton';
        BDPFieldUpdateService.updateRecordType(currentCourseAuBdp);
        System.assertEquals(true, currentCourseAuBdp.is_Onshore__c, 
            'Expected is onshore to be true because Clayton is in Australia'
        );
    }

    @isTest
    static void shouldSetOnShoreFalseWhenCurrentCourseCampusIsSouthAfrica() {
        Bulk_Data_Processing__c currentCourseAuBdp = new Bulk_Data_Processing__c();
        currentCourseAuBdp.Current_Course_Campus__c = 'South Africa';
        BDPFieldUpdateService.updateRecordType(currentCourseAuBdp);
        System.assertEquals(false, currentCourseAuBdp.is_Onshore__c, 
            'Expected is onshore to be true because South Africa is not in Australia'
        );
    }

    /**
     * Test methods to check whether Offer Template fields are updated correctly -- BEGIN
     */
    @isTest
    static void testUpdateOfferTemplateDMCAu() {
        Bulk_Data_Processing__c bdp = new Bulk_Data_Processing__c();
        bdp.Offer_Template__c = 'Domestic Monash College - Australia';
        BDPFieldUpdateService.updateOfferTemplate(bdp);
        System.assertEquals('Domestic Monash College Australia', bdp.Template_Type__c, 'Expected is Domestic Monash College Australia');
    }
    @isTest
    static void testUpdateOfferTemplateICAu() {
        Bulk_Data_Processing__c bdp = new Bulk_Data_Processing__c();
        bdp.Offer_Template__c = 'International Coursework - Australia';
        BDPFieldUpdateService.updateOfferTemplate(bdp);
        System.assertEquals('International Coursework Australia', bdp.Template_Type__c, 'Expected is International Coursework Australia');
    }
    @isTest
    static void testUpdateOfferTemplateICMA() {
        Bulk_Data_Processing__c bdp = new Bulk_Data_Processing__c();
        bdp.Offer_Template__c = 'International Coursework - Monash Abroad';
        BDPFieldUpdateService.updateOfferTemplate(bdp);
        System.assertEquals('International Monash Abroad Australia', bdp.Template_Type__c, 'Expected is International Monash Abroad Australia');
    }
    @isTest
    static void testUpdateOfferTemplateDCAu() {
        Bulk_Data_Processing__c bdp = new Bulk_Data_Processing__c();
        bdp.Offer_Template__c = 'Domestic Coursework - Australia';
        BDPFieldUpdateService.updateOfferTemplate(bdp);
        System.assertEquals('Domestic Coursework Australia', bdp.Template_Type__c, 'Expected is Domestic Coursework Australia');
    }
    @isTest
    static void testUpdateOfferTemplateNull() {
        Bulk_Data_Processing__c bdp = new Bulk_Data_Processing__c();
        bdp.Offer_Template__c = null;
        bdp.Template_Type__c = 'Domestic Coursework Australia';
        BDPFieldUpdateService.updateOfferTemplate(bdp);
        System.assertEquals('', bdp.Template_Type__c, 'Offer Template Fields not blanked out, when updated with null');
    }
    @isTest
    static void testUpdateOfferTemplateNotNull() {
        Bulk_Data_Processing__c bdp = new Bulk_Data_Processing__c();
        bdp.Offer_Template__c = 'a162O000000ULonQAG';
        bdp.Template_Type__c = 'Domestic Coursework Australia';
        BDPFieldUpdateService.updateOfferTemplate(bdp);
        System.assertEquals('Domestic Coursework Australia', bdp.Template_Type__c, 'Offer Template Fields updated, when other fields are updated.');
    }
    /*Test methods to check whether Offer Template fields are updated correctly -- END */
    private class ContactsSelectorMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
                
            if ('selectByPersonId'.equals(stubbedMethodName)) {
                return (Contact[]) JSON.deserialize('[{"attributes":{"type":"Contact","url":"/services/data/v49.0/sobjects/Contact/0034Y000003CwgNQAS"},"Id":"0034Y000003CwgNQAS","Name":"OffersTest Applicant","Person_ID_unique__c":"123456","Email":"offerstestapplicant11332244@mailinator.com","RecordTypeId":"01228000000Px7XAAS"}]', List<Contact>.class);
            }
            return null;
        }

    }
}