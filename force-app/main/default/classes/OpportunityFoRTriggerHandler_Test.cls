/**
* @description       : Test class for OpportunityFoRTriggerHandler
* @author            : Inderpal Dhanoa
* @date              : 2022-05-18
* @group             : Enterprise
**/
@isTest(isParallel=false) // Test.getStandardPricebookId() cannot be called from parallel Apex tests
public with sharing class OpportunityFoRTriggerHandler_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         18/05/2022
    * @description  Test Setup Method for SyncRefreshPureOpportunityController
    * @revision     1.0
    *******************************************************************************/
    @testSetup
    static void setup() {
        List<Account> relatedAccounts = new List<Account>();
        List<Opportunity> relatedOpportunity = new List<Opportunity>();
        List<Fields_of_Research__c> relatedFoRList = new List<Fields_of_Research__c>();

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId();

        Account accountRecord = (Account)TestDataFactory.createSObject(new Account(Name = 'AccountTest', NumberOfEmployees = 1, RecordTypeId = recordTypeId), false);
        relatedAccounts.add(accountRecord); 
        
        insert relatedAccounts;

        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
        Opportunity opportunityRecord = (Opportunity)TestDataFactory.createSObject(new Opportunity(name ='OpportunityTest', RecordTypeId = oppRecordTypeId, AccountId = accountRecord.Id, Source__c = 'PURE', StageName = 'Identification', CloseDate = Date.today().addDays(10)),true);

        Fields_of_Research__c testFoR1 = (Fields_of_Research__c)TestDataFactory.createSObject(new Fields_of_Research__c(name ='Test FoR', FoR_Code__c = '123456', ERA_Cluster_Name__c = '123456', ERA_Cluster__c = '01 Mathematical Sciences', FoR_Name__c = '123456'),false);
        Fields_of_Research__c testFoR2 = (Fields_of_Research__c)TestDataFactory.createSObject(new Fields_of_Research__c(name ='Test FoR2', FoR_Code__c = '234567', ERA_Cluster_Name__c = '234567', ERA_Cluster__c = '01 Mathematical Sciences', FoR_Name__c = '234567'),false);

        relatedFoRList.add(testFoR1);
        relatedFoRList.add(testFoR2);

        insert relatedFoRList;

        Opportunity_FoR__c relOpptyFoR = (Opportunity_FoR__c)TestDataFactory.createSObject(new Opportunity_FoR__c(Opportunity__c = opportunityRecord.Id, Fields_of_Research__c = testFoR1.Id, Percentage__c = 10),true);

    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         18/05/2022
    * @description  Test Method for ValidateOwnership Method Failure 
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void ValidateOwnership_Failure_Test(){

        // given : We are inserting the new FoR linked to the Oppty 
        Opportunity linkedOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest' LIMIT 1];

        Fields_of_Research__c linkedFoR2 = [SELECT Id FROM Fields_of_Research__c WHERE name ='Test FoR2' LIMIT 1];
        
        Test.startTest();
        // when: the get Oppty method is initiated 
        try{
            Opportunity_FoR__c relOpptyFoR2 = (Opportunity_FoR__c)TestDataFactory.createSObject(new Opportunity_FoR__c(Opportunity__c = linkedOppty.Id, Fields_of_Research__c = linkedFoR2.Id, Percentage__c = 100),true);
        }catch(Exception ex){
            //then: Get a Validation Error
            string message = ex.getMessage();
            String error = Label.ResearchCollaboratorsExceeded;
         	system.assert(message.contains(error));
        }
        Test.stopTest(); 
    }


    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         18/05/2022
    * @description  Test Method for ValidateOwnership Method Success 
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void ValidateOwnership_Success_Test(){

        // given : The Surviving and target delete Opportunities exist 
        Opportunity linkedOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest' LIMIT 1];

        Fields_of_Research__c linkedFoR2 = [SELECT Id FROM Fields_of_Research__c WHERE name ='Test FoR2' LIMIT 1];
        
        Test.startTest();
        // when: the get Oppty method is initiated 
        Opportunity_FoR__c relOpptyFoR2 = (Opportunity_FoR__c)TestDataFactory.createSObject(new Opportunity_FoR__c(Opportunity__c = linkedOppty.Id, Fields_of_Research__c = linkedFoR2.Id, Percentage__c =90),true);

        Test.stopTest(); 

        Decimal totalPerc = 0;

        for(Opportunity_FoR__c lnkFoR : [SELECT Id, Percentage__c FROM Opportunity_FoR__c]){
            totalPerc = totalPerc + lnkFoR.Percentage__c;
        }
        // then : the total percentage gets added
        system.assertEquals(100.00, totalPerc);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         18/05/2022
    * @description  Test Method for setupUID Method 
    * @revision     1.0
    *******************************************************************************/
    @isTest 
    public static void setupUID_Test(){

        // given : The linked Opportunities and FoR's exist 
        Opportunity linkedOppty = [SELECT Id FROM Opportunity WHERE name ='OpportunityTest' LIMIT 1];

        Fields_of_Research__c linkedFoR2 = [SELECT Id FROM Fields_of_Research__c WHERE name ='Test FoR2' LIMIT 1]; 
        
        Test.startTest();
        // when: the get Oppty method is initiated 
        Opportunity_FoR__c relOpptyFoR2 = (Opportunity_FoR__c)TestDataFactory.createSObject(new Opportunity_FoR__c(Opportunity__c = linkedOppty.Id, Fields_of_Research__c = linkedFoR2.Id, Percentage__c =90),true);
        Test.stopTest(); 

        Opportunity_FoR__c lnkFoR = [SELECT Id, UID__c FROM Opportunity_FoR__c WHERE Opportunity__c = :linkedOppty.Id AND Fields_of_Research__c = :linkedFoR2.Id LIMIT 1];

        // then : the total percentage gets added
        system.assertEquals(lnkFoR.UID__c, String.Valueof(linkedFoR2.Id)+String.Valueof(linkedOppty.Id));
    } 
}