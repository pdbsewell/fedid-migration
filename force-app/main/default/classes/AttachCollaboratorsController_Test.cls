/**
*  @author idha0002
*  @date (13-07-2021)
*  @group Enterprise Engage
*  @description Used to test Apex class AttachCollaboratorsController
*  Modifications Log
*  Ver   Date         Author          Modification
*  1.0   2021-07-13 - Inderpal Dhanoa - Initial Creation
**/
@isTest//(isParallel=true) System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests
public class AttachCollaboratorsController_Test {
    /*
     * Method Name: testSaveCollaborator
     * Description: test the collaborator creation
    */
    @IsTest
    static void testSaveCollaborator() {
        RecordType recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Faculty' LIMIT 1][0];
        Account acct1 = new Account(Name='Acct1', RecordTypeId = recType.Id);
        insert acct1;

        Account acct2 = new Account(Name='Acct2', RecordTypeId = recType.Id);
        insert acct2;

        recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'External_Organisation' LIMIT 1][0];
        Account acct3 = new Account(Name='Acct3', RecordTypeId = recType.Id);
        insert acct3;

        recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Enterprise' LIMIT 1][0];
        // GIVEN: An oppty are associated to it
        Opportunity oppty1 = new Opportunity();
        oppty1.AccountId = acct1.Id;
        oppty1.RecordTypeId = recType.Id;
        oppty1.Name = 'Oppty1';
        oppty1.Amount = 1000.00;
        oppty1.CloseDate = Date.today()+1;
        oppty1.StageName = 'Open';
        insert oppty1;
        
        Test.startTest();
		
        String opportunityId;
        String opportunityRecord = '{"collaboratorType":"Group", "amount":"123", "opportunityId":"' + oppty1.Id + '", "orgId":"' + acct3.Id + '", "lead":true}';
        opportunityId = AttachCollaboratorsController.saveCollaborator(opportunityRecord);
        system.assertEquals(opportunityId, oppty1.Id);

        opportunityRecord = '{"collaboratorType":"Opportunity", "amount":"123", "opportunityId":"' + oppty1.Id + '", "orgId":"' + acct2.Id + '", "lead":true}';
        opportunityId = AttachCollaboratorsController.saveCollaborator(opportunityRecord);
        system.assertEquals(opportunityId, oppty1.Id);
        
        Test.stopTest();
    }
}