/**
 * @description       : Test class for SyncRefreshPureOpportunityController
 * @author            : Inderpal Dhanoa
 * @date              : 2021-04-10
 * @group             : Enterprise
**/
@isTest(isParallel=false) // Test.getStandardPricebookId() cannot be called from parallel Apex tests
public without sharing class SyncRefreshPureOpportunityContrller_Test {

    private final static String TEST_SETUP_NAME = 'SyncRefreshPureOpportunityControllerTest';
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Test Setup Method for AccountMergeControllerTest LWC
    * @revision     1.0
    *******************************************************************************/
    @testSetup
    static void setup() {
        List<Opportunity> relatedOpportunity = new List<Opportunity>();
		
        Account accountRecord = (Account)TestDataFactory.createSObject(new Account(Name = 'AccountTest', NumberOfEmployees = 1, 
                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId()), true);

        Contact testContact = (Contact)TestDataFactory.createSObject(new Contact(firstName= 'TestFirstName' , LastName = 'TestLastName', AccountId = accountRecord.Id, 
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

        //Affiliation
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

        // Create linked Enquiry   

    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         20/06/2021
    * @description  Test Method for SyncRefreshPureOpportunityController Method generateScope  
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void generateScope_Test(){

        // given : The Surviving Opportunities exist 
        Opportunity survOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest2' LIMIT 1]; 

        Test.startTest();
        // when: the get Oppty scope generation method is initiated 
        String scope = SyncRefreshPureOpportunityController.generateScope(String.valueOf(survOppty.Id), true);

        Test.stopTest();  

        //then:the correct scope parameter should be generated
        system.assertEquals(scope, 'awards');
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Test Method for SyncRefreshPureOpportunityController Method validateAccess 
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void validateAccess_Success_Test(){

        // given : The Surviving and target delete Opportunities exist 
        Opportunity survOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest' LIMIT 1];
        
        Test.startTest();
        // when: the get Oppty method is initiated 
        SyncRefreshPureOpportunityController.OpportunityWrapper accessResult =  SyncRefreshPureOpportunityController.validateAccess(survOppty.Id);
        
        Test.stopTest();  

        //then: 1 Oppty should be retrieved
        system.assertEquals(accessResult.hasEditAccess, true);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Test Method for SyncRefreshPureOpportunityController Method validateAccess 
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void validateAccess_Failure_Test(){

        User enterpUser = TestHelper.createTestUsers('Enterprise Base Profile', 1)[0];
		
        // given : The Surviving and target delete Opportunities exist 
        Opportunity survOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest' LIMIT 1];
        
        system.runAs(enterpUser){
            Test.startTest();
            // when: the get Oppty method is initiated 
            SyncRefreshPureOpportunityController.OpportunityWrapper accessResult =  SyncRefreshPureOpportunityController.validateAccess(survOppty.Id);
            
            Test.stopTest(); 
    
            //then: 1 Oppty should be retrieved
            system.assertEquals(accessResult.hasEditAccess, false);
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Test Method for SyncRefreshPureOpportunityController Method getOpportunities 
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void getOpportunities_Test(){

        // given : The Surviving and target delete Opportunities exist 
        Opportunity survOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest' LIMIT 1];
        
        Test.startTest();
        // when: the get Oppty method is initiated 
        List<SyncRefreshPureOpportunityController.OpportunityWrapper> result =  SyncRefreshPureOpportunityController.getOpportunities('123456', survOppty.Id);
        Test.stopTest(); 

        //then: 1 Oppty should be retrieved
        system.assertEquals(result.size(), 1);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Test Method for SyncRefreshPureOpportunityController Method switchPureIds 
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void switchPureIds_Test(){

        // given : The Surviving and target delete Opportunities exist
        Opportunity survOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest' LIMIT 1];
        Opportunity delOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest2' LIMIT 1];
        
        Test.startTest();
        // when: the get switch Pure Ids method is initiated 
        String result = SyncRefreshPureOpportunityController.switchPureIds('123456', String.valueof(survOppty.Id), String.valueof(delOppty.Id));
        Test.stopTest(); 

        //then: Out of 2 opptys, 1 should be deleted
        List<Opportunity> survivyingOpptys = [SELECT Id FROM Opportunity WHERE name LIKE 'OpportunityTest%'];
        system.assertEquals(survivyingOpptys.size(), 1);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Test Method for SyncRefreshPureOpportunityController Method initiateSync
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void initiateSync_Test_PURE(){

        // given : The Surviving and target delete Opportunities exist
        Opportunity survOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest' LIMIT 1];
        Opportunity delOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest2' LIMIT 1];
        
        Test.startTest();

        SingleRequestMock fakeResponse = new SingleRequestMock(200,
				'Complete',
				'{"id": 89301,"startTime": 1481672239000,"callDuration": 205000,"agent": {"lastName": "Eaton","firstName": "Alexandra","username": "aeaton"},"recordingUrl": "/api/rest/recording/contact/89301/recording","hasScreen": false,"hasVoice": true}',
				null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
        // when: the initiate Sync method is initiated 
        String result = SyncRefreshPureOpportunityController.initiateSync(survOppty.Id, '123456', true);
        Test.stopTest(); 

        //then: the response should be Success
        system.assertEquals(result,'Success'); 
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Test Method for SyncRefreshPureOpportunityController Method initiateSync
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void initiateSync_Test_NotPURE(){

        // given : The Surviving and target delete Opportunities exist
        Opportunity survOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest' LIMIT 1];
        Opportunity delOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest2' LIMIT 1];
        
        Test.startTest();

        SingleRequestMock fakeResponse = new SingleRequestMock(200,
				'Complete',
				'{"id": 89301,"startTime": 1481672239000,"callDuration": 205000,"agent": {"lastName": "Eaton","firstName": "Alexandra","username": "aeaton"},"recordingUrl": "/api/rest/recording/contact/89301/recording","hasScreen": false,"hasVoice": true}',
				null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
        // when: the initiate Sync method is initiated 
        String result = SyncRefreshPureOpportunityController.initiateSync(survOppty.Id, '123456', false);
        Test.stopTest(); 

        //then: the response should be Success
        system.assertEquals(result,'Success'); 
    }
}