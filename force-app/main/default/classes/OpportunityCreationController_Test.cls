/**
* @author       idha0002
* @date         12 Mar 2021
* @group Test Class
* @description  Test class to cover Opportunity Creation Class
* @revision
* 10.03.2021 Inderpal Dhanoa - Initial version<br/>
* 04.11.2021 Inderpal Dhanoa - ENGAGEIE-1173 Adding Default Opportunity Team members
*/
@isTest//(isParallel=true) Insert failed. First exception on row 0; first error: CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, SBQQ.OpportunityBefore: execution of BeforeInsert caused by: System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests
public class OpportunityCreationController_Test {

    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        Account accountRecord = new Account(name ='AccountTest') ;
        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId();
        insert accountRecord;

        // System.TypeException: DML not allowed on UserTeamMember

    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         04.Nov.2021
     * @description  Tests the submission of Opportunity record creation with Internal Collaborator
    *******************************************************************************/
    @isTest
    static void testSaveOpportunityAndCollaborators(){
        // GIVEN: An account is present
        Account accountRecord = [SELECT Id FROM Account WHERE name ='AccountTest'];
        
        // WHEN: Save method is Invoked from Express Opportunity creation
        String opportunityRecord = '{"VisibilityCategory":"Default", "CloseDate":"2021-06-11T19:48:39.829Z","IsPrivate":false,"TeamMember":true,"Name":"Account_Role_PRM","AccountId":"' + accountRecord.Id + '","Amount":"122112121"}';
        String collaborator = '{"collaboratorName":"AccountTest","collaboratorId":"' + accountRecord.Id + '","relationShipType":"Internal Organisation","allocatedAmount":"122112121","Lead":true}';

         // THEN: Opportunity is created
        Id newOpportunityId = OpportunityCreationController.SaveOpportunityAndCollaborators(opportunityRecord, collaborator);
        system.assertNotEquals(newOpportunityId, null);
    }
}