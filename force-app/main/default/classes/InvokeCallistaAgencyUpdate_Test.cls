/*******************************************************************************
* @author:      K Liew
* @date:        03.DEC.2019
* @group:       Agent Management
* @description: Sibling Test Class for InvokeCallistaAgencyUpdate.  The API-chaining 
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
*               InvokeCallistaAgencyUpdate (this one)
*               AgencyUpdateInterface
*               JsonBodyAgency
* @revision:
*               03.DEC.2019 KL  >   Initial class creation.
*               15.MAR.2024 VV > EPCP-3306 Update Mule4 endpoints.
*******************************************************************************/
@isTest
public with sharing class InvokeCallistaAgencyUpdate_Test {


    /*******************************************************************************
    * @description: Invoke the AgentMgmtTestUtil.loadHQTestData method to set the
    *               test data needed.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @testSetup
    static void insertAgencies() {

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

        Test.startTest();
        AgentMgmtTestUtil.loadHQTestData();
        Test.stopTest();
    }

    /*******************************************************************************
    * @description: Perform the actual Agency update and assert results.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    static void positiveTestUpdate() {

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

        // Insert CRUD operation's mocks
        multimock.setStaticResource(ncMiX.Endpoint + '/la/admissions/v1/agencies', 'AgentMgmtCallistaAgencyCreateMockResp');
        multimock.setStaticResource(ncMiX.Endpoint + '/la/admissions/v1/agencies/AG1000/agents', 'AgentMgmtCallistaAgentCreateMockResp');
        multimock.setStaticResource(ncGGL.Endpoint + '/v1/agency', 'AgentMgmtGoogleAppsAgencyCreateMockResp');
        // Update CRUD operation's mocks
        multimock.setStaticResource(ncMiX.Endpoint + '/la/admissions/v1/agencies/AG1000', 'AgentMgmtCallistaAgencyUpdateMockResp');
        multimock.setStaticResource(ncMiX.Endpoint + '/la/admissions/v1/agencies/AG1000/agents/12345678', 'AgentMgmtCallistaAgentCreateMockResp');
        multimock.setStatusCode(200);

        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);

        Test.startTest();
        Account hqToUpdate = [
            SELECT 
                Id
                , Name
                , Callista_Integration_Status__c
                , Street__c
                , City__c
                , State__c
                , Post_Code__c
            FROM Account
            WHERE Callista_Org_Unit_Code__c= 'AG1000'
        ];

        // Update Agency's address "City" field, this triggers a chain of technical components including process builders,
        // invocable classes, queueable integration classes with callouts + inherited functionality from virtual class.
        // Functionally, updating City also updates Role Account Contact
        hqToUpdate.City__c = 'MELBOURNE';
        hqToUpdate.Post_Code__c = '3001';
        update hqToUpdate;
        Test.stopTest(); // this might need to move to after "update" CRUD op below...

        Account updatedHQ = [
            SELECT 
                Id
                , Name
                , Callista_Integration_Status__c
                , Street__c
                , City__c
                , State__c
                , Post_Code__c
            FROM Account
            WHERE Callista_Org_Unit_Code__c= 'AG1000'
        ];
        
        System.assertEquals('Updated', updatedHQ.Callista_Integration_Status__c);
    }

    /*******************************************************************************
    * @description: Invoke the "InvokeCallistaAgencyUpdate" class directly, passing
    *               in invalid parameter(s)
    *               the outcome of that method.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    static void negativeTestHittingExceptionBlock() {
        Test.startTest();
        InvokeCallistaAgencyUpdate.updateAgencyInCallista(null);
        Test.stopTest();

        //System.assertEquals(expected, actual);
        List<Exception_Log__c> exList = [
            SELECT 
                Id
            FROM Exception_Log__c
            WHERE Source_Type__c = 'InvokeCallistaAgencyUpdate'
            AND Object_Name__c = 'Account / Agent Management Integration'
            AND Function_Name__c = 'updateAgencyInCallista'
        ];
        
        System.assertNotEquals(0, exList.size());
    }
}