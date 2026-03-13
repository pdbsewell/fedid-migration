/*******************************************************************************
* @author:      K Liew
* @date:        21.AUG.2018
* @group:       Agent Management
* @description: Sibling Test Class for AgentCreateInterface.  The API-chaining 
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
*               InvokeCallistaAgentInsert
*               AgentCreateInterface (this one)
*               JsonBodyAgent
* @revision:
*               21.AUG.2018 KL > Initial class creation.
*               02.DEC.2019 KL > Completely revamping the test class to use the new
*               approach.
*               15.MAR.2024 VV > EPCP-3306 Update Mule4 endpoints.
*******************************************************************************/


@isTest(isParallel=true)
public class AgentCreateInterface_Test {

    /*******************************************************************************
    * @description: Invoke the AgentMgmtTestUtil.loadHQTestData method and assert
    *               the outcome of that method.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest static void positiveTest() {

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

        Contact assetContact = [
            SELECT Id
                , Callista_Integration_Status__c
            FROM Contact
            WHERE AccountId = :assertHQ.Id
                AND Person_ID_unique__c = '12345678'
                AND Callista_Integration_Status__c = 'Inserted'
        ];

        System.assertEquals('Inserted', assetContact.Callista_Integration_Status__c);
    }

}