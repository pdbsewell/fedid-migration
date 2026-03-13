/*******************************************************************************
* @author:      K Liew
* @date:        27.NOV.2019
* @group:       Agent Management
* @description: Sibling Test Class for AgentMgmtTestUtil.  All this class needs
*               to do is to ensure records + fields are properly loaded from CSV.
* @revision:
*               27.NOV.2019 KL  >   Initial class creation.
*               15.MAR.2024 VV > EPCP-3306 Update Mule4 endpoints.
*******************************************************************************/
@isTest
public with sharing class AgentMgmtTestUtil_Test {


    /*******************************************************************************
    * @description: Invoke the AgentMgmtTestUtil.loadHQTestData method and assert
    *               the outcome of that method.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    static void testLoadingOfHQsAndBranches() {

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

        // Fetched test being setup
        List<Country_Attribute__c> countryList = [
            SELECT 
                Name 
            FROM Country_Attribute__c 
            WHERE COUNTRY__C = 'Australia'];

        List<Account> hqList = [    
            SELECT 
                Name 
            FROM Account 
            WHERE Callista_Org_Unit_Code__c = 'AG1000'];

        List<Account> branchList = [
            SELECT 
                Name 
            FROM Account 
            WHERE Callista_Org_Unit_Code__c = 'AG1002'];

        // Assert results
        System.assertEquals(countryList.isEmpty(), false);
        System.debug('!@# countryList.isEmpty() = ' + countryList.isEmpty());

        System.assertEquals(hqList.isEmpty(), false);
        System.debug('!@# hqList.isEmpty() = ' + hqList.isEmpty());

        System.assertEquals(branchList.isEmpty(), false);
        System.debug('!@# branchList.isEmpty() = ' + countryList.isEmpty());

    }

    /*******************************************************************************
    * @description: Invoke the AgentMgmtTestUtil.loadAgenciesTestDataNoIntegration
    *               method and assert the outcome of that method.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    static void testLoadingOfAgentDBTestRecords() {

        AgentMgmtTestUtil.loadAgenciesTestDataNoIntegration();

        // Fetched test agency being setup
        List<Account> agency1 = [    
            SELECT 
                Id
                , Name 
                , Monash_AM_Web_Status__c
            FROM Account 
            WHERE Callista_Org_Unit_Code__c = 'TAG1000'];

        System.assertEquals(agency1.isEmpty(), false);
        Account a1 = (Account)agency1[0];
        System.assertEquals(a1.Monash_AM_Web_Status__c, true);
        System.debug('!@# agency1.isEmpty() = ' + agency1.isEmpty());

        List<Account> agency2 = [    
            SELECT 
                Name 
                , Monash_AM_Web_Status__c
            FROM Account 
            WHERE Callista_Org_Unit_Code__c = 'TAG2000'];

        System.assertEquals(agency2.isEmpty(), false);
        Account a2 = (Account)agency2[0];
        System.assertEquals(a2.Monash_AM_Web_Status__c, true);
        System.debug('!@# agency2.isEmpty() = ' + agency2.isEmpty());

        List<Account> agency3 = [    
            SELECT 
                Name 
            FROM Account 
            WHERE Name = 'test org'];

        System.assertEquals(agency3.isEmpty(), false);
        System.debug('!@# agency3.isEmpty() = ' + agency3.isEmpty());

        List<Application__c> apps = [
            select id, name from Application__c where Agent__c = :agency1[0].Id
        ];
        System.assertEquals(apps.isEmpty(), false);

    }

}