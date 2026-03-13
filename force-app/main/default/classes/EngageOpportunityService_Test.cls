/**
 * Opportunity Service Test class.
 * 
 * @author Mark Johnson - UC Innovation
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0		 27-AUG-2019	 Mark Johson			Initial Creation
 * 2.0       10-JAN-2024     Davey Yu     			ENGAGEIE-1841 Add test class methods to validate enteprise opportunity potential duplicates
 */

@isTest(isParallel=false) // Test.getStandardPricebookId called on Opportunity trigger
public class EngageOpportunityService_Test {
    
	
    @isTest
    public static void testCreateContactProposalWithAnAssignment() {
        
        Contact con = new Contact(LastName = 'testCreateContactProposalWithAnAssignment');
        insert con;
        
        Ucinn_ascendv2__Assignment__c assignment = new Ucinn_ascendv2__Assignment__c(	ucinn_ascendv2__Contact__c = con.Id,
                                                                                    	ucinn_ascendv2__Assigned_Relationship_Manager_User__c = UserInfo.getUserId(),
                                                                                     	ucinn_ascendv2__Assignment_Type__c = 'Primary Relationship Manager - Development',
                                                                                     	ucinn_ascendv2__Assignment_Start_Date__c = Date.today(),
                                                                                    	RecordTypeId = Schema.SObjectType.Ucinn_ascendv2__Assignment__c.getRecordTypeInfosByDeveloperName().get('Contact_Assignment').getRecordTypeId());
        insert assignment;
        
        //We should not encounter an error, as we have a pre-existing assignment.
 
        Opportunity opp = new Opportunity(	Name = 'testCreateContactProposalWithAnAssignment',
            								RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId(),
                                          	StageName = 'Identification',
                                          	CloseDate = Date.today().addDays(1),
                                            ucinn_ascendv2__Contact__c = con.Id);
        
        
        Database.SaveResult saveResult = Database.insert(opp, false);
        
        List<Opportunity> opptyList = [select id,ucinn_ascendv2__Contact__c,PrimaryContact__c from Opportunity where ucinn_ascendv2__Contact__c =: con.Id];
        System.assertEquals(opptyList[0].ucinn_ascendv2__Contact__c,opptyList[0].PrimaryContact__c,'value for Primary contact and Constituent should be same');
        System.assertEquals(saveResult.isSuccess(), true, 'User with assignment should be able to create a proposal.');

    }
    
    @isTest
    public static void testCreateAccountProposalWithAnAssignment() {
        
        Account acc = new Account(	Name = 'testCreateAccountProposalWithAnAssignment',
                                 	RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        
        insert acc;
        
        Ucinn_ascendv2__Assignment__c assignment = new Ucinn_ascendv2__Assignment__c(	ucinn_ascendv2__Account__c = acc.Id,
                                                                                    	ucinn_ascendv2__Assigned_Relationship_Manager_User__c = UserInfo.getUserId(),
                                                                                     	ucinn_ascendv2__Assignment_Type__c = 'Primary Relationship Manager - Development',
                                                                                     	ucinn_ascendv2__Assignment_Start_Date__c = Date.today(),
                                                                                    	RecordTypeId = Schema.SObjectType.Ucinn_ascendv2__Assignment__c.getRecordTypeInfosByDeveloperName().get('Contact_Assignment').getRecordTypeId());
        insert assignment;
        
        //We should not encounter an error, as we have a pre-existing assignment.
 
        Opportunity opp = new Opportunity(	Name = 'testCreateAccountProposalWithAnAssignment',
            								RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId(),
                                          	StageName = 'Identification',
                                          	CloseDate = Date.today().addDays(1),
                                            AccountId = acc.Id);
        
        
        Database.SaveResult saveResult = Database.insert(opp, false);
        
        System.assertEquals(saveResult.isSuccess(), true, 'User with assignment should be able to create a proposal.');

    }
    
    
    @isTest
    public static void testCreateContactProposalWithoutAssignment() {
        
        Contact con = new Contact(LastName = 'testCreateContactProposalWithoutAssignment');
        insert con;
        
        //We should encounter an error, as we have no pre-existing assignment.
 
        Opportunity opp = new Opportunity(	Name = 'testCreateContactProposalWithoutAssignment',
            								RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId(),
                                          	StageName = 'Identification',
                                          	CloseDate = Date.today().addDays(1),
                                            ucinn_ascendv2__Contact__c = con.Id);
        
        
        Database.SaveResult saveResult = Database.insert(opp, false);
        
        System.assertEquals(saveResult.isSuccess(), false, 'User without assignment should not be able to create a proposal.');

    }
    
    @isTest
    public static void testCreateAccountProposalWithNoAssignment() {
        
        Account acc = new Account(	Name = 'testCreateAccountProposalWithNoAssignment',
                                 	RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        insert acc;
        
        //We should encounter an error, as we have no pre-existing assignment.
 
        Opportunity opp = new Opportunity(	Name = 'testCreateAccountProposalWithNoAssignment',
            								RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId(),
                                          	StageName = 'Identification',
                                          	CloseDate = Date.today().addDays(1),
                                            AccountId = acc.Id);
        
        
        Database.SaveResult saveResult = Database.insert(opp, false);
        
        System.assertEquals(saveResult.isSuccess(), false, 'User without assignment should not be able to create a proposal.');

    }
    
    @isTest
    public static void testReassociateOpportunityTeamsInsert() {
        
        Contact con = new Contact(LastName = 'testReassociateOpportunityTeamsInsert');
        insert con;
        
        Ucinn_ascendv2__Assignment__c assignment = new Ucinn_ascendv2__Assignment__c(	ucinn_ascendv2__Contact__c = con.Id,
                                                                                    	ucinn_ascendv2__Assigned_Relationship_Manager_User__c = UserInfo.getUserId(),
                                                                                     	ucinn_ascendv2__Assignment_Type__c = 'Primary Relationship Manager - Development',
                                                                                     	ucinn_ascendv2__Assignment_Start_Date__c = Date.today(),
                                                                                    	RecordTypeId = Schema.SObjectType.Ucinn_ascendv2__Assignment__c.getRecordTypeInfosByDeveloperName().get('Contact_Assignment').getRecordTypeId());
        insert assignment;
        
        //We should not encounter an error, as we have a pre-existing assignment.
 
        Opportunity oppProposal = new Opportunity(	Name = 'testReassociateOpportunityTeamsInsert',
            										RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId(),
                                          			StageName = 'Identification',
                                          			CloseDate = Date.today().addDays(1),
                                            		ucinn_ascendv2__Contact__c = con.Id);
        
        
        Database.SaveResult saveResult = Database.insert(oppProposal, false);
        
        System.assertEquals(saveResult.isSuccess(), true, 'User with assignment should be able to create a proposal.');
        
        OpportunityTeamMember oppTeamMem = new OpportunityTeamMember(	TeamMemberRole = 'Fundraiser',
                                                                    	UserId = UserInfo.getUserId(),
                                                                    	OpportunityAccessLevel = 'Edit',
                                                                    	OpportunityId = oppProposal.Id);
        
        insert oppTeamMem;
        
        Opportunity oppGift = new Opportunity(	Name = 'testReassociateOpportunityTeamsInsert',
            									RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Gift').getRecordTypeId(),
                                          		StageName = 'Funded',
                                          		CloseDate = Date.today().addDays(1),
                                          		Amount = 100,
                                            	ucinn_ascendv2__Contact__c = con.Id,
                                         		ucinn_ascendv2__Proposal__c = oppProposal.Id);
        
       	insert oppGift;
        
        List<OpportunityTeamMember> opportunityTeamMemberList = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId =: oppGift.Id];
        
        System.assert(!opportunityTeamMemberList.isEmpty(), 'Opportunity team members should be transferred from proposal to new opportunity transaction');

    } 
    
    @isTest
    public static void testReassociateOpportunityTeamsUpdate() {
        
        Contact con = new Contact(LastName = 'testReassociateOpportunityTeamsUpdate');
        insert con;
        
        Ucinn_ascendv2__Assignment__c assignment = new Ucinn_ascendv2__Assignment__c(	ucinn_ascendv2__Contact__c = con.Id,
                                                                                    	ucinn_ascendv2__Assigned_Relationship_Manager_User__c = UserInfo.getUserId(),
                                                                                     	ucinn_ascendv2__Assignment_Type__c = 'Primary Relationship Manager - Development',
                                                                                     	ucinn_ascendv2__Assignment_Start_Date__c = Date.today(),
                                                                                    	RecordTypeId = Schema.SObjectType.Ucinn_ascendv2__Assignment__c.getRecordTypeInfosByDeveloperName().get('Contact_Assignment').getRecordTypeId());
        insert assignment;
        
        //We should not encounter an error, as we have a pre-existing assignment.
 
        Opportunity oppProposal = new Opportunity(	Name = 'testReassociateOpportunityTeamsUpdate',
            										RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Proposal').getRecordTypeId(),
                                          			StageName = 'Identification',
                                          			CloseDate = Date.today().addDays(1),
                                            		ucinn_ascendv2__Contact__c = con.Id);
        
        
        Database.SaveResult saveResult = Database.insert(oppProposal, false);
        
        System.assertEquals(saveResult.isSuccess(), true, 'User with assignment should be able to create a proposal.');
        
        OpportunityTeamMember oppTeamMem = new OpportunityTeamMember(	TeamMemberRole = 'Fundraiser',
                                                                    	UserId = UserInfo.getUserId(),
                                                                    	OpportunityAccessLevel = 'Edit',
                                                                    	OpportunityId = oppProposal.Id);
        
        insert oppTeamMem;
        
        Opportunity oppGift = new Opportunity(	Name = 'testReassociateOpportunityTeamsUpdate',
            									RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Gift').getRecordTypeId(),
                                          		StageName = 'Funded',
                                          		CloseDate = Date.today().addDays(1),
                                          		Amount = 100,
                                            	ucinn_ascendv2__Contact__c = con.Id);
        
       	insert oppGift;
        
        oppGift.ucinn_ascendv2__Proposal__c = oppProposal.Id;
        
        update oppGift;
        
        List<OpportunityTeamMember> opportunityTeamMemberList = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId =: oppGift.Id];
        
        System.assert(!opportunityTeamMemberList.isEmpty(), 'Opportunity team members should be transferred from proposal to newly updated opportunity transaction');

    }
    
    @isTest
    public static void testSetAuthorizeAndCharge() {
        RecordType recType = [SELECT Id, Name, Description ,DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'Gift'];

        Account acct = new Account();
        acct.Name = 'Account';
        insert acct;
        
        Contact con = new Contact(LastName = 'Test_Contact',
                          AccountId = acct.Id,
                          Email = 'testCommunityUsermig123@test.com');
        insert con;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Gift';
        opp.StageName = 'Funded';
        opp.Amount = 1000;
        opp.CloseDate = Date.today();
        opp.AccountId = acct.Id;
        opp.RecordTypeId = recType.Id;
        opp.ucinn_ascendv2__Tender_Type_for_Gifts__c = 'Cash';

        test.startTest();
        insert opp; 
        test.stopTest();
        
        Opportunity queriedOpp = [SELECT ID,ucinn_ascendv2__Authorize_and_Charge__c FROM Opportunity WHERE ID =: opp.Id];
        system.assert(queriedOpp.ucinn_ascendv2__Authorize_and_Charge__c == false);
    }
     /*
     * @description     This method test the EngageOpportunityService.validateDuplicateMonashSystemId method to check for potential duplicates on insert
     * Expected result: Throw a custom error message
     *
     * GIVEN A new enterprise opportunity record is created 
     * WHEN A new enterprise opportunity monash system id is populated with already existing opportunity with the same monash system id
     * THEN It will throw a custom error message containing the name and monash system id of the duplicate record
    */
    @isTest
    public static void testValidateEnterpriseOpportunityDuplicates() {
    	RecordType recType = [SELECT Id, Name, Description ,DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'Enterprise'];
		
        List<Account> acctList = new List<Account>();
        Account acct = new Account();
        acct.Name = 'Account';
        acctList.add(acct);
        
        Account acct2 = new Account();
        acct2.Name = 'Account2';
        acctList.add(acct2);
        
        insert acctList;
        
        List<Contact> conList = new List<Contact>();
        Contact con = new Contact(LastName = 'Test_Contact',
                          AccountId = acct.Id,
                          Email = 'testCommunityUsermig123@test.com');
        conList.add(con);
        
        Contact con2 = new Contact(LastName = 'Test_Contact2',
                          AccountId = acct2.Id,
                          Email = 'testCommunityUsermig123@test2.com');
        conList.add(con2);
        
        insert conList;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Prospecting';
        opp.Amount = 1000;
        opp.CloseDate = Date.today();
        opp.AccountId = acct.Id;
        opp.RecordTypeId = recType.Id;
        opp.Monash_System_ID__c = '1234';

        insert opp; 
        
        Opportunity duplicateOpp = new Opportunity();
        duplicateOpp.Name = 'Test Opportunity2';
        duplicateOpp.StageName = 'Prospecting';
        duplicateOpp.Amount = 1000;
        duplicateOpp.CloseDate = Date.today();
        duplicateOpp.AccountId = acct2.Id;
        duplicateOpp.RecordTypeId = recType.Id;
        duplicateOpp.Monash_System_ID__c = '1234';
        try{
        	insert duplicateOpp; 
        }catch(Exception ex){
            Boolean expectedExceptionThrown =  ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? true : false;            
            System.assertEquals(expectedExceptionThrown, true, ex.getMessage());
        }
        
    }
    
    /*
     * @description     This method test the EngageOpportunityService.validateDuplicateMonashSystemId method to check for potential duplicates on update
     * Expected result: Throw a custom error message
     *
     * GIVEN A new enterprise opportunity record is updated
     * WHEN A opportunity monash system id is populated with already existing opportunity with the same monash system id
     * THEN It will throw a custom error message containing the name and monash system id of the duplicate record
    */
    @isTest
    public static void testValidateEnterpriseOpportunityDuplicatesUpdate() {
    	RecordType recType = [SELECT Id, Name, Description ,DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'Enterprise'];
		
        List<Account> acctList = new List<Account>();
        Account acct = new Account();
        acct.Name = 'Account';
        acctList.add(acct);
        
        Account acct2 = new Account();
        acct2.Name = 'Account2';
        acctList.add(acct2);
        
        insert acctList;
        
        List<Contact> conList = new List<Contact>();
        Contact con = new Contact(LastName = 'Test_Contact',
                          AccountId = acct.Id,
                          Email = 'testCommunityUsermig123@test.com');
        conList.add(con);
        
        Contact con2 = new Contact(LastName = 'Test_Contact2',
                          AccountId = acct2.Id,
                          Email = 'testCommunityUsermig123@test2.com');
        conList.add(con2);
        
        insert conList;
        
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Prospecting';
        opp.Amount = 1000;
        opp.CloseDate = Date.today();
        opp.AccountId = acct.Id;
        opp.RecordTypeId = recType.Id;
        opp.Monash_System_ID__c = '1234';
        oppList.add(opp);

        
        Opportunity duplicateOpp = new Opportunity();
        duplicateOpp.Name = 'Test Opportunity2';
        duplicateOpp.StageName = 'Prospecting';
        duplicateOpp.Amount = 1000;
        duplicateOpp.CloseDate = Date.today();
        duplicateOpp.AccountId = acct2.Id;
        duplicateOpp.RecordTypeId = recType.Id;
        duplicateOpp.Monash_System_ID__c = '12345';
        oppList.add(duplicateOpp);
        
        insert oppList;
        
        Opportunity dupOpp = [Select Id, Monash_System_Id__c from Opportunity WHERE Monash_System_Id__c = '12345'];
        dupOpp.Monash_System_ID__c= '1234';
        try{
        	update dupOpp; 
        }catch(Exception ex){
            Boolean expectedExceptionThrown =  ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? true : false;            
            System.assertEquals(expectedExceptionThrown, true, ex.getMessage());
        }
        
    }
    
}