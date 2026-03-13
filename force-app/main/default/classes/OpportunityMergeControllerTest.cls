/**
 * @description       : Test class OpportunityMergeController
 * @author            : Davey Yu
 * @date              : 2024-02-27
 * @group             : Test
 * @group             : Enterprise
**/
@isTest(isParallel=false) //Parallel false due to restrictions for tests can’t call the Test.getStandardPricebookId() method
public without sharing class OpportunityMergeControllerTest {

    private final static String TEST_SETUP_NAME = 'OpportunityMergeControllerTest';
    /*******************************************************************************
    * @author       Davey Yu
    * @date         26/02/2024
    * @description  Test Setup Method for OpportunityMergeController 
    * @revision     1.0
    *******************************************************************************/
    @testSetup
    static void setup() {
        List<Opportunity> relatedOpportunity = new List<Opportunity>();
		
        Account accountRecord = (Account)TestDataFactory.createSObject(new Account(Name = 'AccountTest', NumberOfEmployees = 1, 
                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId()), true);

        Contact testContact = (Contact)TestDataFactory.createSObject(new Contact(firstName= 'TestFirstName' , LastName = 'TestLastName', AccountId = accountRecord.Id, 
                            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Not known to Monash systems').getRecordTypeId()), true);

		
        Account accountRecord2 = (Account)TestDataFactory.createSObject(new Account(Name = 'AccountTest2', NumberOfEmployees = 1, 
                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('External Organisation').getRecordTypeId()), true);

        Contact testContact2 = (Contact)TestDataFactory.createSObject(new Contact(firstName= 'TestFirstName2' , LastName = 'TestLastName2', AccountId = accountRecord.Id, 
                            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Not known to Monash systems').getRecordTypeId()), true);

        Opportunity opportunityRecord = (Opportunity)TestDataFactory.createSObject(new Opportunity(name ='OpportunityTest', AccountId = accountRecord.Id, Source__c = 'PURE', StageName = 'Identification',
                                        CloseDate = date.today() + 10, RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId()), false);

        Opportunity opportunityRecord2 = (Opportunity)TestDataFactory.createSObject(new Opportunity(name ='OpportunityTest2', AccountId = accountRecord.Id, Source__c = 'PURE', PURE_Application_ID__c = '123456', PURE_Award_ID__c = '98765', 
                                        StageName = 'Identification', CloseDate = date.today() + 10, RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId()), false);

        relatedOpportunity.add(opportunityRecord);
        relatedOpportunity.add(opportunityRecord2);
        insert relatedOpportunity;

        opportunityRecord2 = [SELECT Id, name FROM Opportunity WHERE name ='OpportunityTest2'];

        Topic tpc = TestUtil.createTopic('abc');
        List<TopicAssignment> topicAssignmentList = new List<TopicAssignment>();
        topicAssignmentList.add(TestUtil.createTopicAssignment(tpc.Id,opportunityRecord2.Id)); 
        insert topicAssignmentList;

        Task task = (Task)TestDataFactory.createSObject(new Task(Subject = 'test', WhatId = opportunityRecord2.Id, 
                                                                    RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Enquiry').getRecordTypeId()), true);


        Event testEvent = (Event)TestDataFactory.createSObject(new Event(WhatId = opportunityRecord2.Id, DurationInMinutes = 60, ActivityDateTime = Datetime.newInstance(Date.today() - 2, Time.newInstance(12, 0, 0, 0))), true);

        // Create Affiliation
        Affiliation__c affRec = (Affiliation__c)TestDataFactory.createSObject(new Affiliation__c(Account__c = accountRecord.Id, Contact__c = testContact.Id, 
                                                    Opportunity__c = opportunityRecord2.Id, Start_Date__c = Date.today() - 3, End_Date__c = Date.today() + 3,
                                                    RecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByDeveloperName().get('Industry_Contact').getRecordTypeId()), true);

        //Answers of IP Check/GE Check
        Opportunity_Question__c ge_answer = (Opportunity_Question__c)TestDataFactory.createSObject(new Opportunity_Question__c(Name = 'test', Opportunity__c = opportunityRecord2.Id, Outcome__c = 'AMBER'), true);
        

        // reate Oppoty COntact Role
        OpportunityContactRole oppConRole = (OpportunityContactRole)TestDataFactory.createSObject(new OpportunityContactRole(ContactId = testContact.Id, OpportunityId = opportunityRecord2.Id), true);
        

        //Create Related Feed Item Record
        FeedItem fi = (FeedItem)TestDataFactory.createSObject(new FeedItem(ParentId = opportunityRecord2.Id, Body = 'Test Body'), true);
        
        //Create Feed Comment Record
        FeedComment fc = (FeedComment)TestDataFactory.createSObject(new FeedComment(FeedItemId = fi.Id, CommentBody = 'Test Comment'), true);

        ContentVersion contentVersion = (ContentVersion)TestDataFactory.createSObject(new ContentVersion(Title = 'Penguins', PathOnClient = 'Penguins.jpg', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true), true);

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = (ContentDocumentLink)TestDataFactory.createSObject(new ContentDocumentLink(LinkedEntityId = opportunityRecord2.id, ContentDocumentId = documents[0].Id, shareType = 'V'), true);

        //create funding record
        Funding__c fundingPrimary = (Funding__c)TestDataFactory.createSObject(new Funding__c(Opportunity__c = opportunityRecord.id, Funder__c = accountRecord.id, Applied_Amount__c = 1000, Primary_Funder__c = true), true);
        Funding__c fundingDuplicate = (Funding__c)TestDataFactory.createSObject(new Funding__c(Opportunity__c = opportunityRecord2.id, Funder__c = accountRecord2.id, Applied_Amount__c = 100, Primary_Funder__c = false), true);
        
        //create collaborator
        Opportunity_Collaborator__c collaboratorPrimary = (Opportunity_Collaborator__c)TestDataFactory.createSObject(new Opportunity_Collaborator__c(Opportunity__c = opportunityRecord.id, Organisation__c = accountRecord2.id), true);
		Opportunity_Collaborator__c collaboratorDuplicate = (Opportunity_Collaborator__c)TestDataFactory.createSObject(new Opportunity_Collaborator__c(Opportunity__c = opportunityRecord2.id, Organisation__c = accountRecord2.id), true);
        
        //create enquiry
        Id enterpriseRecordTypeCase = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
		Case caseDuplicate = (Case)TestDataFactory.createSObject(new Case(Opportunity__c = opportunityRecord2.id), true);

        
        //create campaign and campaign influence
        CampaignInfluenceModel model = [select id from campaignInfluenceModel where developerName = 'Campaign_Influence_Model' limit 1];
        Id enterpriseRecordTypeId = Schema.getGlobalDescribe().get('Campaign').getDescribe().getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
        Campaign enterpriseCampaign = (Campaign)TestDataFactory.createSObject(new Campaign(Name = 'Enterprise Campaign', RecordTypeId = enterpriseRecordTypeId), true);
        CampaignInfluence enterpriseCampaignInfluence = (CampaignInfluence)TestDataFactory.createSObject(new CampaignInfluence(OpportunityId = opportunityRecord2.id, CampaignId=enterpriseCampaign.Id, ModelId= model.id), true);

    
        //create opportunity team
        OpportunityTeamMember teamMemberPrimary = (OpportunityTeamMember)TestDataFactory.createSObject(new OpportunityTeamMember(OpportunityId = opportunityRecord.id, TeamMemberRole = 'Test', UserId = UserInfo.getUserId()), true);
		OpportunityTeamMember teamMemberDuplicate = (OpportunityTeamMember)TestDataFactory.createSObject(new OpportunityTeamMember(OpportunityId = opportunityRecord2.id, TeamMemberRole = 'Test2', UserId = UserInfo.getUserId()), true);
    }
    
    /*******************************************************************************
    * @author       Davey Yu
    * @date         27/02/2024
    * @description  Test Method to retrieve duplicate opportunities
    * GIVEN user view duplicates from the opportunity merge tool
    * WHEN duplicates are displayed
    * THEN primary opportunity and its duplicates should display in the opportunity merge tool
    * @revision     1.0
    *******************************************************************************/
    @isTest
    @SuppressWarnings('PMD.AvoidDebugStatements')
    public static void getEntityDataTest(){   
        Test.startTest(); 
      	List<Opportunity> primaryOpp = [SELECT Id FROM Opportunity]; 
        Exception exc = null;
        try{
            OpportunityMergeController.OpportunityMergeWrapper linkedOpportunitues = OpportunityMergeController.getEntityData(primaryOpp[0].Id);
        }catch (Exception myExc) {
            exc = myExc;
        }
        if(exc instanceof System.HandledException) {
            //ignore, can happen if duplication rules are not active or defined
            System.debug(LoggingLevel.DEBUG, 'System.HandledException is ignored as there are not any active duplication rules.');
        } else {
            System.assertEquals(null, exc, 'An exception occured when it should not.');
        }
        Test.stopTest();
    }



   
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Test Method for getOpportunities Method switchPureIds 
    * GIVEN user selects the primary and included opportunity record
    * WHEN user clicks Merge button
    * THEN included opportunity should be merge including its related records
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void switchPureIds_Test(){

        // given : The Surviving and target delete Opportunities exist
        Opportunity survOppty = [SELECT Id, accountId FROM Opportunity WHERE name ='OpportunityTest' LIMIT 1];
        Opportunity delOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest2' LIMIT 1];
        
        Test.startTest();
        // when: the get switch Pure Ids method is initiated 
        String result = OpportunityMergeController.switchPureIds(String.valueof(survOppty.Id), String.valueof(delOppty.Id), false);
        Test.stopTest(); 

        //then: Out of 2 opptys, 1 should be deleted
        List<Opportunity> survivyingOpptys = [SELECT Id FROM Opportunity WHERE name LIKE 'OpportunityTest%'];
        system.assertEquals(survivyingOpptys.size(), 1);
    }
}