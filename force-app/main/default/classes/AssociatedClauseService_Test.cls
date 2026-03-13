/**
 * @File Name          : AssociatedClauseService_Test.cls
 * @Description        : Apex test class for Associated Clause Service class
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 5/21/2020, 9:39:47 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/20/2020   jasmin.rudio@monash.edu     Initial Version
**/
@isTest
private class AssociatedClauseService_Test {

    @testSetup static void setup() {
        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(Callista_Org_Unit_Code__c = 'DIRECT'), true);
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id, Person_ID_unique__c = '123456'), true);
        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(Active__c = true, External_Id__c='12345',APXT_Redlining__Text__c='test clause 1',Location_in_Offer__c='Cover Letter', Selection_Type__c='Manual'), true);
        
        Country_Attribute__c country = (Country_Attribute__c)TestDataFactory.createSObject(new Country_Attribute__c(Name = 'MALAYSIA'), true); 
        //Application Creation
        Application__c app = (Application__c)TestDataFactory.createSObject(new Application__c(Applicant__c = contact.Id), true);

        //ACP Creation
        insert new Application_Course_Preference__c[]{
               (Application_Course_Preference__c)TestDataFactory.createSObject(
                   new Application_Course_Preference__c(
                        Course_Code__c = 'CO-09287',
                        Course_Code_Unique__c = 'CO-09287',
                        Application__c = app.Id), false)
                };

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
    private static void createAssociatedClause(){
        APXT_Redlining__Clause__c clause = [SELECT Id FROM APXT_Redlining__Clause__c LIMIT 1];
        Application_Course_Preference__c[] acps = [SELECT ID, Course_Code__c FROM Application_Course_Preference__c ORDER BY Course__r.Name LIMIT 1];
        string acpListJson = JSON.serialize(acps);
        Mirror_Clause__c mirrorClause = new Mirror_Clause__c(Clause__c = clause.Id, Keywords__c = acps[0].Course_Code__c);
        insert mirrorClause;
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity());

        String selectedManualClausesJson = MirrorClauseServices.getManualClauses(acpListJson);
        List<MirrorClauseServices.MirrorClauseWrapper> selectedClauses = (List<MirrorClauseServices.MirrorClauseWrapper>) JSON.deserialize(selectedManualClausesJson, List<MirrorClauseServices.MirrorClauseWrapper>.class);
        test.startTest();
            AssociatedClauseService serviceClass = new AssociatedClauseService();
            List<Associated_Clause__c> associatedClauseList = AssociatedClauseService.createAssociatedClause(opp, selectedClauses);
        test.stopTest();
        System.assert(associatedClauseList.size() > 0); 
    }

    @isTest
    private static void createBDPAssociatedClause(){
        APXT_Redlining__Clause__c clause = [SELECT Id FROM APXT_Redlining__Clause__c LIMIT 1];
        Application_Course_Preference__c[] acps = [SELECT ID, Course_Code__c FROM Application_Course_Preference__c ORDER BY Course__r.Name LIMIT 1];
        List<Mirror_Clause__c> mirrorList = new List<Mirror_Clause__c>();
        Mirror_Clause__c mirrorClause = new Mirror_Clause__c(Clause__c = clause.Id, Keywords__c = acps[0].Course_Code__c);
        mirrorList.add(mirrorClause);
        insert mirrorList;
        Bulk_Data_Processing__c bdp = [SELECT id, (SELECT Id, Mirror_Clause__c, Clause__c FROM Associated_Clauses__r) FROM Bulk_Data_Processing__c LIMIT 1];
        test.startTest();
            List<Associated_Clause__c> associatedClauseList = AssociatedClauseService.createBDPAssociatedClause(bdp, mirrorList);
            List<Associated_Clause__c> assocClauseByParent = AssociatedClauseService.getAssocClauseByParentId('Offer_Request__c', bdp.Id);
        test.stopTest();
        System.assert(associatedClauseList.size() > 0); 
    }


}