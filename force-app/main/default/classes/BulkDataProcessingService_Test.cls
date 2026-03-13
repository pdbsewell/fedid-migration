/**
 * @author      Jasmin Joy Rudio
 * @description Test class for BulkDataProcessingService class
 * @group       Bulk Data Processing 
 * @revision    10/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest
public with sharing class BulkDataProcessingService_Test {
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

        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(Active__c = true, External_Id__c='12345',APXT_Redlining__Text__c='test clause 1',Location_in_Offer__c='Cover Letter', Selection_Type__c='Manual'), true);
        Mirror_Clause__c mirrorClause = (Mirror_Clause__c)TestDataFactory.createSObject(new Mirror_Clause__c(Clause__c = clause.Id, Keywords__c = 'C2000'), true);
        
    }

    @isTest
    private static void execute(){
        Test.startTest();
            BulkDataProcessingService service = new BulkDataProcessingService();
            BulkDataProcessingService.BDPManualClauseMatcher matcher = new BulkDataProcessingService.BDPManualClauseMatcher(JSON.serialize(new String[]{'a1z4Y0000001cLKQAY'}));
            matcher.BDPSelector = (BulkDataProcessingSelector) Test.createStub(BulkDataProcessingSelector.class, new BulkDataProcessingSelectorMock());
            matcher.mirrorClausesSelector = (MirrorClauseSelector) Test.createStub(MirrorClauseSelector.class, new MirrorClauseSelectorMock());
            String exec = matcher.execute();
        Test.stopTest();
        System.assert(!String.isEmpty(exec));
    }

    @isTest
    private static void saveBDPmanualClauses(){
        List<Mirror_Clause__c> clauses = [SELECT Id FROM Mirror_Clause__c];
        Bulk_Data_Processing__c bdp = [SELECT Id FROM Bulk_Data_Processing__c LIMIT 1];
        BulkDataProcessingService.BDPManualClauseWrapper wrapper = getWrapperValues();
        Map<String, List<Mirror_Clause__c>> clauseMap = new Map<String, List<Mirror_Clause__c>>();
        clauseMap.put('E6001', clauses);
        wrapper.clauseListMapByCourseCode = clauseMap;
        Test.startTest();
            String updateBDPstatus = BulkDataProcessingService.updateBDPStatus(bdp.Id, 'Processing Offer');
            String associatedClauses = BulkDataProcessingService.saveBDPmanualClauses(JSON.serialize(wrapper));
        Test.stopTest();
        System.assert(!String.isEmpty(associatedClauses));
    }

    @isTest
    private static void saveBDPmanualClausesException(){
        BulkDataProcessingService.BDPManualClauseWrapper wrapper = getWrapperValues();
        Test.startTest();
            try{
                String associatedClauses = BulkDataProcessingService.saveBDPmanualClauses(JSON.serialize(wrapper));
            }catch(Exception e){
                //because List<Mirror_Clause__c> is empty
                System.assert(e.getMessage().contains('Attempt to de-reference a null object'));
            }
        Test.stopTest();
    }


    private static BulkDataProcessingService.BDPManualClauseWrapper getWrapperValues(){
        Map<Id, Bulk_Data_Processing__c> bdpMap = new Map<Id, Bulk_Data_Processing__c>([SELECT Id, Transfer_Course_Code__c FROM Bulk_Data_Processing__c]);
        Map<String, List<Mirror_Clause__c>> clauseMap = new Map<String, List<Mirror_Clause__c>>();
        clauseMap.put('C2000', new List<Mirror_Clause__c>());
        BulkDataProcessingService.BDPManualClauseWrapper wrapper = new BulkDataProcessingService.BDPManualClauseWrapper();
        wrapper.bulkDataProcessingMap = bdpMap;
        wrapper.clauseListMapByCourseCode = clauseMap;
        return wrapper;
    }

    private class BulkDataProcessingSelectorMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            if ('selectByIdOrderByCourseCode'.equals(stubbedMethodName)) {
                return (Bulk_Data_Processing__c[]) JSON.deserialize('[{"attributes":{"type":"Bulk_Data_Processing__c","url":"/services/data/v49.0/sobjects/Bulk_Data_Processing__c/a1z4Y0000001cLKQAY"},"Id":"a1z4Y0000001cLKQAY","Name":"O-0003175","Transfer_Course_Code__c":"C2000","Person_ID__c":"28115120","Transfer_To__c":"a204Y000000A4MuQAK","RecordTypeId":"0124Y0000004t87QAA"}]', List<Bulk_Data_Processing__c>.class);
            }
            return null;
        }

    }

    private class MirrorClauseSelectorMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            if ('selectActiveClauses'.equals(stubbedMethodName)) {
                return (Mirror_Clause__c[]) JSON.deserialize('[{"attributes":{"type":"Mirror_Clause__c","url":"/services/data/v49.0/sobjects/Mirror_Clause__c/aAG4Y00000000HdWAI"},"Id":"aAG4Y00000000HdWAI","Name":"Jean Moulin University Lyon III Course Duration","Keywords__c":"C2000","Clause__c":"a0n4Y0000005HoPQAU","Active__c":true}]', List<Mirror_Clause__c>.class);
            }
            return null;
        }

    }
}