/**
*  @author idha0002
*  @date (13-07-2021)
*  @group Enterprise Engage
*  @description Used to test Apex class AttachIntrlExtrlCollabController
*  Modifications Log
*  Ver   Date         Author          Modification
*  1.0   2021-07-13 - Inderpal Dhanoa - Initial Creation
**/
@isTest//(isParallel=true) System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests
public class AttachIntrlExtrlCollabController_Test {
	/*
     * Method Name: testValidateAccess
     * Description: test the access to records
    */
    @IsTest
    static void testValidateAccess() {
        Account acct1 = new Account(Name='Acct1');
        insert acct1;

        RecordType recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Enterprise' LIMIT 1][0];
        // GIVEN: An oppty are associated to it
        Opportunity oppty1 = new Opportunity();
        oppty1.AccountId = acct1.Id;
        oppty1.RecordTypeId = recType.Id;
        oppty1.Name = 'Oppty1';
        oppty1.Amount = 1.00;
        oppty1.CloseDate = Date.today()+1;
        oppty1.StageName = 'Open';
        insert oppty1;

        Test.startTest();
        Boolean editAccess = AttachIntrlExtrlCollabController.validateAccess((String)oppty1.Id);
        system.assertEquals(editAccess,true);
        Test.stopTest();
    }
}