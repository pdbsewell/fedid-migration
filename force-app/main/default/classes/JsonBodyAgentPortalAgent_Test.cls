/*******************************************************************************
* @author:      K Liew
* @date:        03.DEC.2019
* @group:       Agent Management
* @description: Sibling Test Class for InvokeAgentPortalAgentInsert.  The API-chaining 
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
*               InvokeAgentPortalAgentInsert
*               AgentPortalCreateAgentInterface
*               JsonBodyAgentPortalAgent (this one)
* @revision:
*               03.DEC.2019 KL  >   Initial class creation.
*******************************************************************************/
@isTest
public with sharing class JsonBodyAgentPortalAgent_Test {


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
        multimock.setStaticResource(ncMiX.Endpoint + '/v1/admissions/agencies', 'AgentMgmtCallistaAgencyCreateMockResp');
        multimock.setStaticResource(ncMiX.Endpoint + '/v1/admissions/agencies/AG1000/agents', 'AgentMgmtCallistaAgentCreateMockResp');
        multimock.setStaticResource(ncMiX.Endpoint + '/v1/admissions/agencies/AG1002/agents', 'AgentMgmtCallistaAgentCreateMockResp');
        multimock.setStaticResource(ncGGL.Endpoint + '/v1/agency', 'AgentMgmtGoogleAppsAgencyCreateMockResp');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);

        // Invoke class being tested
        Test.startTest();
        AgentMgmtTestUtil.loadHQTestData();
        Test.stopTest();
        AgentMgmtTestUtil.loadBranchTestData();

        Account assertHQ = [
            SELECT 
                Id
                , Name
                , Callista_Integration_Status__c
            FROM Account
            WHERE Callista_Org_Unit_Code__c= 'AG1000'
        ];

        Contact assetContact = [
            SELECT Id
                , Google_Integration_Status__c
            FROM Contact
            WHERE AccountId = :assertHQ.Id
                AND Person_ID_unique__c = '12345678'
        ];

        System.assertEquals('Inserted', assetContact.Google_Integration_Status__c);
    }


}