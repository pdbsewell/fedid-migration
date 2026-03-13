/**
* @author Inderpal Dhanoa
* @date 25 03 2021
* @description Test class for OpportunityRelatedCasesController
**/
@IsTest// Unable to add isParallel=true 
public class OpportunityRelatedCasesController_Test {
     /**
     * @description Inserts records required for test methods
     * @revision Initial version 25 March 2021
     */
    @testSetup
    static void setup(){
        Account accountRecord = new Account(name ='AccountTest') ;
        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId();
        insert accountRecord;

        // An oppties are associated to it
        Opportunity oppty1 = new Opportunity();
        oppty1.AccountId = accountRecord.Id; 
        oppty1.Name = 'Oppty1';
        oppty1.Amount = 1.00;
        oppty1.CloseDate = Date.today()+1;
        oppty1.StageName = 'Open';
        insert oppty1;

        Case testCase = new Case(AccountId = accountRecord.Id, RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(),
                                 Opportunity__c = oppty1.Id);
        insert testCase;

    }
     /**
     * @author Inderpal Dhanoa
     * @description retrieves Related Enquiries on an Opportunity
     */
    @IsTest
    public static void getRelatedCasesTest(){
        
        Test.startTest();
        
        Opportunity oppty1 = [SELECT Id FROM Opportunity];
        List<Case> relatedCases = OpportunityRelatedCasesController.getRelatedCases(oppty1.Id);
        system.assertEquals(relatedCases.size(), 1);
        Test.stopTest();
        
    }
}