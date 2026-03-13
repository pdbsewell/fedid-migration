/**
 * @description       : Test class for OpptyContactRoleController
 * @author            : Inderpal Dhanoa
 * @group             : Enterprise Engage
 * @last modified on  : 2022-12-02
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2022-12-02 - Inderpal Dhanoa - Added test for Opportunity COntact Role
**/
@isTest(isParallel=false) // System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests
public with sharing class OpptyContactRoleController_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         12.Feb.2022
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {
        // RecordType 
        RecordType conrecType = [SELECt Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'Student'];
        // Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(Callista_Org_Unit_Code__c = 'DIRECT'), true);
        // Contact Creation
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(name='Opp1',StageName='Identify Opportunity', AccountId = acc.Id), true);
        // Contact Creation
        Contact contact1 = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1', RecordtypeId = conrecType.Id, AccountId = acc.Id), true);
        // Contact Creation
        Contact contact2 = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con2',AccountId = acc.Id), true);
         // OpportunityContactRole Creation
         OpportunityContactRole contTeam = (OpportunityContactRole)TestDataFactory.createSObject(new OpportunityContactRole(ContactId = contact1.Id, OpportunityId=opp.Id), true);
    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         12.Feb.2022
     * @description  Tests regarding to Get the OpportunityContactRole
    *******************************************************************************/ 
	@isTest 
    static void testGetOpportunityContactRole() {
        // given a Oppty Team member already is linked  
        Opportunity opp = [SELECT Id FROM Opportunity WHERE name='Opp1' LIMIT 1];

        List<Contact> con = [SELECT Id FROM Contact WHERE Lastname='Con1'];

        // when : contact team member is retrieved 
        test.startTest();
        OpptyContactRoleController.OpptyContactRoleWrapper o_OpptyContactRoleWrapper = OpptyContactRoleController.getOpportunityContactRole(String.valueOf(opp.Id), 'ROLE');
        test.stopTest();

        // then : contact team member is retrieved  
        system.assertEquals(o_OpptyContactRoleWrapper.relatedOpptyRoleRecords.size(), con.size());
        
    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         12.Feb.2022
     * @description  Tests regarding to Get the ContRole RecordType Mapping
    *******************************************************************************/ 
	@isTest 
    static void testGetContRoleRecordTypeMapping() {
        // given a Oppty Team member already is linked  
        Opportunity opp = [SELECT Id FROM Opportunity WHERE name='Opp1' LIMIT 1];

        List<Contact> con = [SELECT Id FROM Contact WHERE Lastname='Con1'];
 
        // when : contact team member record mapping is retrieved 
        test.startTest();
        Map<String, List<String>> o_ContactFieldMapping = OpptyContactRoleController.getContRoleRecordTypeMapping('Contact', 'ROLE');
        // then : the oppty role member mapping should not be empty
        system.assertNotEquals(o_ContactFieldMapping.size(), 0);
        test.stopTest();
          
    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         12.Feb.2022
     * @description  Tests regarding to Get the ContRole RecordType Mapping
    *******************************************************************************/ 
	@isTest 
    static void testGetContactRecordTypeName() {
        // given a Contact Record exists
        List<Contact> con = [SELECT Id, recordType.DeveloperName FROM Contact WHERE Lastname='Con1'];
 
        // when : contact team member record mapping is retrieved 
        test.startTest();
        String recTypeDevName = OpptyContactRoleController.getContactRecordTypeName(con[0].Id);
        test.stopTest();
        // then : the string and DeveloperName should match
        system.assertEquals(recTypeDevName, con[0].recordType.DeveloperName);
          
    }

     /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         12.Feb.2022
     * @description  Tests regarding to save the ContRole RecordType Mapping
    *******************************************************************************/ 
	@isTest 
    static void testSaveOpportunityContactRole() {
         // given a contact Team member already is linked  
        Opportunity opp = [SELECT Id FROM Opportunity WHERE name='Opp1' LIMIT 1];

        Contact con2 = [SELECT Id FROM Contact WHERE Lastname='Con2' LIMIT 1];
        
        List<OpportunityContactRole> opptyContRoleList = [SELECT Id, Role, ContactId, OpportunityId FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];

        opptyContRoleList.add(new OpportunityContactRole(ContactId = con2.Id, OpportunityId = opp.Id));
        opptyContRoleList.add(new OpportunityContactRole(ContactId = con2.Id, OpportunityId = opp.Id));
 
        // when : contact team member is saved 
        test.startTest();
        String errorMessage = OpptyContactRoleController.saveOpportunityContactRole(opptyContRoleList);
        test.stopTest(); 

        // then : the contact team member should not be inserted and should get an Out of the box Validation Error
        system.assertEquals(errorMessage, 'SUCCESS');
        opptyContRoleList = [SELECT Id, Role, ContactId, OpportunityId FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        system.assertEquals(opptyContRoleList.size(), 2);         
    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         12.Feb.2022
     * @description  Tests regarding deleting the ContRole Record
    *******************************************************************************/ 
	@isTest 
    static void testDeleteOpportunityContactRole() {
        // given a contact Team member already is linked  
        Opportunity opp = [SELECT Id FROM Opportunity WHERE name='Opp1' LIMIT 1];

        List<OpportunityContactRole> opptyContRoleList = [SELECT Id, Role, ContactId, OpportunityId FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
 
        // when : contact team member is deleted 
        test.startTest();
        String errorMessage = OpptyContactRoleController.deleteOpportunityContactRole(String.valueOf(opptyContRoleList[0].Id));
        test.stopTest(); 

        // then : the contact team member should not be inserted and should get an Out of the box Validation Error
        system.assertEquals(errorMessage, 'SUCCESS');
        opptyContRoleList = [SELECT Id, Role, ContactId, OpportunityId FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        system.assertEquals(opptyContRoleList.size(), 0);         
    }
}