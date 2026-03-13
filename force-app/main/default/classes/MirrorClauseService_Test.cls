/**
 * @File Name          : MirrorClauseService_Test.cls
 * @Description        : Apex test class for Mirror Clause Service class
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 5/21/2020, 9:39:36 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/20/2020   jasmin.rudio@monash.edu     Initial Version
**/
@isTest
private class MirrorClauseService_Test {

    @testSetup static void setup() {
        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id), true);
        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(new APXT_Redlining__Clause__c(Active__c = true, External_Id__c='12345',APXT_Redlining__Text__c='test clause 1',Location_in_Offer__c='Cover Letter', Selection_Type__c='Manual'), true);
        
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
    }
    
    @isTest
    private static void getManualClauses(){
        APXT_Redlining__Clause__c clause = [SELECT Id FROM APXT_Redlining__Clause__c LIMIT 1];
        Application_Course_Preference__c[] acps = [SELECT ID, Course_Code__c FROM Application_Course_Preference__c ORDER BY Course__r.Name LIMIT 1];
        string acpListJson = JSON.serialize(acps);
        Mirror_Clause__c mirrorClause = new Mirror_Clause__c(Clause__c = clause.Id, Keywords__c = acps[0].Course_Code__c);
        insert mirrorClause;
        test.startTest();
            MirrorClauseServices serviceClass = new MirrorClauseServices();
            String mirrorClauses = MirrorClauseServices.getManualClauses(acpListJson);
        test.stopTest();
        System.assert(!String.isEmpty(mirrorClauses));
    }
}