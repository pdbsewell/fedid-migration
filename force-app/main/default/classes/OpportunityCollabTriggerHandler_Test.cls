/**
 * Opportunity COllaborator Trigger Handler test Class
 * 
 * Modifications Log 
 * Ver   Date         Author          	Modification
 * 1.1   08-11-2023   Davey Yu   		ENGAGEIE-1812 Set Opportunity Collaborator Lead
 * 1.2.  07-03-2024   Davey Yu			ENGAGEIE-1908 Updated the test methods to reference the monash faculty area name 
 * 										instead of the organisation name for the opportunity related faculties
 * @author Inderpal Dhanoa idha0002
 */

@isTest(isParallel=false) // Tests on Opportunity leverage Test.getStandardPricebookId() which cannot be called from parallel Apex tests
public class OpportunityCollabTriggerHandler_Test {
    @testSetup static void setupData(){
        List<Account> relatedAccounts = new List<Account>();
		
        Account accountRecord = new Account(name ='AccountTest') ;
        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId();
        relatedAccounts.add(accountRecord);

        Account collaboratorOrg = new Account(name ='collaboratorOrgTest', Monash_Faculty_Area_Name__c = 'Test') ;
        collaboratorOrg.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId();
        relatedAccounts.add(collaboratorOrg);

        Account collaboratorOrg1 = new Account(name ='collaboratorOrgTest1', Monash_Faculty_Area_Name__c = 'Test1') ;
        collaboratorOrg1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId();
        relatedAccounts.add(collaboratorOrg1);

        Account collaboratorOrg2 = new Account(name ='collaboratorOrgTest2', Monash_Faculty_Area_Name__c = 'Test2') ;
        collaboratorOrg2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId();
        relatedAccounts.add(collaboratorOrg2);
        
        insert relatedAccounts;

        Opportunity opportunityRecord = new Opportunity(name ='OpportunityTest', AccountId = accountRecord.Id);
        opportunityRecord.StageName = 'Identification';
        opportunityRecord.CloseDate = date.today() + 10;
        OpportunityRecord.Lead_Collaborator__c = 'Monash Led';
        opportunityRecord.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
        insert opportunityRecord;
        
    }
    

    @isTest 
    static void testUpdateOpportunityFaculities(){
        //GIVEN Account and Opportunity Record is already created with internal organisation
        Account collaborator = [SELECT Id, Name, Monash_Faculty_Area_Name__c FROM Account WHERE name = 'collaboratorOrgTest' LIMIT 1];
        Account collaborator1 = [SELECT Id, Name, Monash_Faculty_Area_Name__c FROM Account WHERE name = 'collaboratorOrgTest1' LIMIT 1];
        
        List<Opportunity_Collaborator__c> l_collaborators = new List<Opportunity_Collaborator__c>();
        Opportunity insertedOpportunity = [SELECT Id, Related_Faculties__c FROM Opportunity WHERE name = 'OpportunityTest' LIMIT 1];
        system.assertEquals(insertedOpportunity.Related_Faculties__c, null);

        //start tests
        Test.startTest();
        Opportunity_Collaborator__c collaboratorRecord = new Opportunity_Collaborator__c(Opportunity__c = insertedOpportunity.Id, 
                                                                                         Organisation__c = collaborator.Id, Relationship_Type__c = 'Internal Organisation');

        Opportunity_Collaborator__c collaboratorRecord1 = new Opportunity_Collaborator__c(Opportunity__c = insertedOpportunity.Id, 
                                                                                         Organisation__c = collaborator1.Id, Relationship_Type__c = 'Internal Organisation');
        l_collaborators.add(collaboratorRecord);
        l_collaborators.add(collaboratorRecord1);
        insert l_collaborators;

        insertedOpportunity = [SELECT Id, Related_Faculties__c FROM Opportunity LIMIT 1]; 
        system.assertEquals(insertedOpportunity.Related_Faculties__c, 'Test;Test1'); 

        Account collaborator2 = [SELECT Id, Name FROM Account WHERE name = 'collaboratorOrgTest2' LIMIT 1];
		
        //WHEN Opportunity collaborator organisation is updated 
        collaboratorRecord = [SELECT Id, Organisation__c FROM Opportunity_Collaborator__c WHERE Organisation__c = :collaborator1.Id];
        collaboratorRecord.Organisation__c = collaborator2.Id;
        update collaboratorRecord;

        Test.stopTest();
		
        //THEN Opportunity collaborator related faculties should be updated with the new collaborator organisation's monash faculty area bame
        insertedOpportunity = [SELECT Id, Related_Faculties__c FROM Opportunity WHERE name = 'OpportunityTest' LIMIT 1];
        system.assertEquals(insertedOpportunity.Related_Faculties__c, 'Test;Test2');
    }
	

    @isTest 
    static void testDeleteOpportunityFaculities(){
        //GIVEN Account and Opportunity Record is already created with internal organisation
        Account collaborator = [SELECT Id, Name, Monash_Faculty_Area_Name__c FROM Account WHERE name = 'collaboratorOrgTest' LIMIT 1];
        Account collaborator1 = [SELECT Id, Name, Monash_Faculty_Area_Name__c FROM Account WHERE name = 'collaboratorOrgTest1' LIMIT 1];
        
        List<Opportunity_Collaborator__c> l_collaborators = new List<Opportunity_Collaborator__c>();
        Opportunity insertedOpportunity = [SELECT Id, Related_Faculties__c FROM Opportunity WHERE name = 'OpportunityTest' LIMIT 1];
        system.assertEquals(insertedOpportunity.Related_Faculties__c, null);

        //start tests
        Test.startTest();
        
        Opportunity_Collaborator__c collaboratorRecord = new Opportunity_Collaborator__c(Opportunity__c = insertedOpportunity.Id, 
                                                                                         Organisation__c = collaborator.Id, Relationship_Type__c = 'Internal Organisation');

        Opportunity_Collaborator__c collaboratorRecord1 = new Opportunity_Collaborator__c(Opportunity__c = insertedOpportunity.Id, 
                                                                                         Organisation__c = collaborator1.Id, Relationship_Type__c = 'Internal Organisation');
        l_collaborators.add(collaboratorRecord);
        l_collaborators.add(collaboratorRecord1);
        insert l_collaborators;
      
        		
        //WHEN Opportunity collaborator organisation is deleted
        collaboratorRecord = [SELECT Id FROM Opportunity_Collaborator__c WHERE Organisation__c = :collaborator1.Id];
        delete collaboratorRecord;

        Test.stopTest();
		
        //THEN Opportunity related collaborators should only have monash faculty area name of the remaining collaborator 
        Opportunity opp = [SELECT Id, Related_Faculties__c FROM Opportunity WHERE name = 'OpportunityTest' LIMIT 1]; 
        system.assertEquals(opp.Related_Faculties__c , 'Test');
    }
	
	
    @isTest 
    static void testSetOpportunityCollaboratorUniqueId_Insert(){
        // given : when the Account and Opportunity is already created
        Account accountRec = [SELECT Id FROM Account WHERE name = 'collaboratorOrgTest' LIMIT 1];

        Opportunity oppRec = [SELECT Id FROM Opportunity WHERE name = 'OpportunityTest' LIMIT 1];

        //start tests
        Test.startTest();

        // when : the Oppty Collab record is created
        Opportunity_Collaborator__c opportunityCollabRecord = new Opportunity_Collaborator__c(Opportunity__c = oppRec.Id, Organisation__c = accountRec.Id, Relationship_Type__c = 'Internal Organisation');
        insert opportunityCollabRecord;

        Test.stopTest();

        // then : the Oppty Collab record's UID is set
        opportunityCollabRecord = [SELECT Id, UID__c FROM Opportunity_Collaborator__c LIMIT 1];
        system.assertEquals(opportunityCollabRecord.UID__c, String.valueof(oppRec.Id) + String.valueof(accountRec.Id));
    }

    @isTest 
    static void testSetOpportunityCollaboratorUniqueId_Update(){
        // given : when the Account and Opportunity is already created
        Account accountRec = [SELECT Id FROM Account WHERE name = 'collaboratorOrgTest' LIMIT 1];

        Opportunity oppRec = [SELECT Id FROM Opportunity WHERE name = 'OpportunityTest' LIMIT 1];

        Opportunity_Collaborator__c opportunityCollabRecord = new Opportunity_Collaborator__c(Opportunity__c = oppRec.Id, Organisation__c = accountRec.Id, Relationship_Type__c = 'Internal Organisation');
        insert opportunityCollabRecord;

        accountRec = [SELECT Id FROM Account WHERE name = 'collaboratorOrgTest1' LIMIT 1];

        opportunityCollabRecord = [SELECT Id, UID__c, Organisation__c FROM Opportunity_Collaborator__c LIMIT 1];

        //start tests
        Test.startTest();

        // when : the Oppty Collab record is updated
        opportunityCollabRecord.Organisation__c = accountRec.Id;

        update opportunityCollabRecord;

        Test.stopTest();

        // then : the Oppty Collab record's UID is updated
        opportunityCollabRecord = [SELECT Id, UID__c FROM Opportunity_Collaborator__c LIMIT 1];
        system.assertEquals(opportunityCollabRecord.UID__c, String.valueof(oppRec.Id) + String.valueof(accountRec.Id));  
    }
    
    /*
     * @description     This method will test the if the opportunity collaborator lead is set to true 
     * 					for a monash led opportunity for an internal organisation
     * Expected result: Opportunity Collaborator Lead field is set as true after insert if relationship type is internal organisation
     *
    */
    @isTest
    public static void testSetCollaboratorLeadForInsert(){
        //GIVEN Account and Opportunity Record is already created where lead collaborator is monash led
        Account accountRec = [SELECT Id FROM Account WHERE name = 'collaboratorOrgTest' LIMIT 1];

        Opportunity oppRec = [SELECT Id FROM Opportunity WHERE name = 'OpportunityTest' LIMIT 1];

        Test.startTest();
        //WHEN Opportunity collaborator is created where relationship type is internal organisation and lead is false
		Opportunity_Collaborator__c opportunityCollabRecord = new Opportunity_Collaborator__c(Opportunity__c = oppRec.Id, Organisation__c = accountRec.Id, Relationship_Type__c = 'Internal Organisation');
        insert opportunityCollabRecord;        
        Test.stopTest();
        
        //THEN Opportunity collaborator lead field is set to true
        System.assert( [select Lead__c from Opportunity_Collaborator__c where id=: opportunityCollabRecord.Id].Lead__c == true );
    }
}