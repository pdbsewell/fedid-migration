/*******************************************************************************
* @author:      K Liew
* @date:        27.NOV.2019
* @group:       Agent Management
* @description: Sibling Test Class for InvokeCallistaAgencyInsert.  The API-chaining 
*               pattern / solution design applied in the Agent Management solution 
*               naturally results in multiple classes being executed in straight 
*               succession during a single record level CRUD operation.  This means that
*               "testing each class by itself" in separate sibling test classes
*               (repeating test class logic) doesn't really make sense and will  
*               result in higher test class code maintenance effort in future if 
*               replicated across.  Wherever feasible, common test code will 
*               consolidated and applied or used.
*
*               Classes in the chain are (they will very similar test class logic in
*               general):
*               InvokeCallistaAgencyInsert
*               AgencyCreateInterface (this one)
*               JsonBodyAgency
* @revision:
*               27.NOV.2019 KL  >   Initial class creation.
*               15.MAR.2024 VV > EPCP-3306 Update Mule4 endpoints.
*******************************************************************************/
@isTest
public with sharing class InvokeCallistaAgencyInsert_Test {


    /*******************************************************************************
    * @description: Invoke the AgentMgmtTestUtil.loadHQTestData method and assert
    *               the outcome of that method.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    static void positiveTest() {

        // set up API mock calls prior to Agency creation
        NamedCredential ncMiX = [SELECT Id 
                                , DeveloperName
                                , Endpoint 
                                FROM NamedCredential 
                                WHERE DeveloperName = 'Monash_MiX_APIs'];

        NamedCredential ncGGL = [SELECT Id 
                                , DeveloperName
                                , Endpoint 
                                FROM NamedCredential 
                                WHERE DeveloperName = 'Monash_Google_APIs'];
        
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(ncMiX.Endpoint + '/la/admissions/v1/agencies', 'AgentMgmtCallistaAgencyCreateMockResp');
        multimock.setStaticResource(ncMiX.Endpoint + '/la/admissions/v1/agencies/AG1000/agents', 'AgentMgmtCallistaAgentCreateMockResp');
        multimock.setStaticResource(ncMiX.Endpoint + '/la/admissions/v1/agencies/AG1002/agents', 'AgentMgmtCallistaAgentCreateMockResp');
        multimock.setStaticResource(ncGGL.Endpoint + '/v1/agency', 'AgentMgmtGoogleAppsAgencyCreateMockResp');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);

        // Invoke class being tested
        Test.startTest();
        AgentMgmtTestUtil.loadHQTestData();
        Test.stopTest();
        AgentMgmtTestUtil.loadBranchTestData();

        // Assert results.  Class "InvokeCallistaAgencyInsert" is merely a wrapper that exposes functionality within
        // class "AgencyCreateInterface" to Process Builder in the form of an Invocable.  Assert outcome of "AgencyCreateInterface"
        Account assertHQ = [
            SELECT 
                Id
                , Name
                , Callista_Integration_Status__c
            FROM Account
            WHERE Callista_Org_Unit_Code__c= 'AG1000'
        ];
        System.assertEquals('Inserted', assertHQ.Callista_Integration_Status__c);
    }

    /*******************************************************************************
    * @description: Invoke the "InvokeCallistaAgencyInsert" class directly, passing
    *               in invalid parameter(s)
    *               the outcome of that method.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    static void negativeTestHittingExceptionBlock() {
        Test.startTest();
        List<sObject> amSettings = test.loadData(Agent_Onboarding_Settings__c.sObjectType, 'AgentMgmtCustomSetting');
        InvokeCallistaAgencyInsert.createAgencyInCallista(null);
        Test.stopTest();

        //System.assertEquals(expected, actual);
        List<Exception_Log__c> exList = [
            SELECT 
                Id
            FROM Exception_Log__c
            WHERE Source_Type__c = 'InvokeCallistaAgencyInsert'
            AND Object_Name__c = 'Account / Agent Management Integration'
            AND Function_Name__c = 'createAgencyInCallista'
        ];
        
        System.assertNotEquals(0, exList.size());
    }
}