/*******************************************************************************
* @author:      K Liew
* @date:        07.SEP.2018
* @group:       Agent Management
* @description: Sibling Test Class for AgentDatabaseServerSideCC.
* @revision:
*               07.SEP.2018 KL  >   Initial class creation.
*               12.DEC.2019 KL  >   Refactored to use new test approach applied
*                                   overall when introducing selective testing
*                                   to support on-demand deployment.
*               15.MAR.2024 VV > EPCP-3306 Update Mule4 endpoints.
*******************************************************************************/
@isTest(isParallel=true)
public class AgentDatabaseServerSideCC_Test {


    /*******************************************************************************
    * @description: Invoke the AgentMgmtTestUtil.loadHQTestData method to set the
    *               test data needed, then invoke class tested and assert result
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

        // set up API mock calls prior to Agency creation
        List<AggregateResult> returnValue = AgentDatabaseServerSideCC.getAllCountries();
        // confirm that only account record of agency rt is returned
        System.assertEquals(1, returnValue.size());

    }

    /*******************************************************************************
    * @description: Calling controller method directly, but explicitly null-ing out
    *               custom setting data to force an exception to cover catch block.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    static void negativeTestHittingExceptionBlock() {

        // Invoke class method without any records to return        
        AgentDatabaseServerSideCC.cs = null;
        List<AggregateResult> returnValue = AgentDatabaseServerSideCC.getAllCountries();

        //System.assertEquals(expected, actual);
        List<Exception_Log__c> exList = [
            SELECT 
                Id
            FROM Exception_Log__c
            WHERE Source_Type__c = 'AgentDatabaseServerSideCC'
            AND Object_Name__c = 'Account / Agent Management'
            AND Function_Name__c = 'getAllCountries'
        ];
        
        System.assertNotEquals(0, exList.size());
    }
}