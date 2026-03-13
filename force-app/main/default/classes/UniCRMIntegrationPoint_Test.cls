/*
 * @author:      K Liew
 * @date:        11.DEC.2019
 * @group:       Agent Management
 * @description: Sibling Test Class for UniCRMIntegrationPoint.  The UniCRMIntegrationPoint
 *               "virtual" class is to provide a set of "generic" functionalities
 *               to be automatically inherited by interfaces "extending" this 
 *               class.  An "interface" in this instance would be a REST-based 
 *               API integration built on the platform to enable Salesforce to 
 *               consume a REST-based API.  Generic features includes logging,
 *                reading of integration settings or configuration from a
 *               defined set of custom metadata based "intgeration point" data 
 *               model, performing actual callout, handling response, etc.
 *
 *               "Functional" testing of the virtual class in isolation would not make sense
 *               as it should be the extending class that needs to be functionally
 *               tested.  
 * @revision:
 *               11.DEC.2019 KL  >   Initial class creation.
 *  17.04.2023 Ken McGuire: Changed Comments__c (255 characters) to LongComments__c (4000 characters)
 */
@isTest
public with sharing class UniCRMIntegrationPoint_Test {

   /*
    * @description: Invoke the AgentMgmtTestUtil.loadHQTestData method to set the
    *               test data needed.
    * @param:       n/a
    * @return:      n/a
    */
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
        multimock.setStaticResource(ncMiX.Endpoint + '/v1/admissions/agencies', 'AgentMgmtCallistaAgencyCreateMockResp');
        multimock.setStaticResource(ncMiX.Endpoint + '/v1/admissions/agencies/AG1000/agents', 'AgentMgmtCallistaAgentCreateMockResp');
        multimock.setStaticResource(ncMiX.Endpoint + '/v1/admissions/agencies/AG1002/agents', 'AgentMgmtCallistaAgentCreateMockResp');
        multimock.setStaticResource(ncGGL.Endpoint + '/v1/agency', 'AgentMgmtGoogleAppsAgencyCreateMockResp');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);

        Test.startTest();
        AgentMgmtTestUtil.loadHQTestData();
        Test.stopTest();
        
        Account hqToUpdate = [
            SELECT 
                Id
                , Name
                , Google_Integration_Status__c
                , Street__c
                , City__c
                , State__c
                , Post_Code__c
            FROM Account
            WHERE Callista_Org_Unit_Code__c= 'AG1000'
        ];
    }

    /*******************************************************************************
    * @description: Perform the actual Agency update so that an "Interface" class
    *               that extends UniCRMIntegrationPoint is instantiated, put to
    *               exection as quueueable, and handle response logic is invoked.
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
        multimock.setStaticResource(ncMiX.Endpoint + '/v1/admissions/agencies', 'AgentMgmtCallistaAgencyCreateMockResp');
        multimock.setStaticResource(ncMiX.Endpoint + '/v1/admissions/agencies/AG1000/agents', 'AgentMgmtCallistaAgentCreateMockResp');
        multimock.setStaticResource(ncGGL.Endpoint + '/v1/agency', 'AgentMgmtGoogleAppsAgencyCreateMockResp');
        // Update CRUD operation's mocks
        multimock.setStaticResource(ncMiX.Endpoint + '/v1/admissions/agencies/AG1000', 'AgentMgmtCallistaAgencyUpdateMockResp');
        multimock.setStaticResource(ncMiX.Endpoint + '/v1/admissions/agencies/AG1000/agents/12345678', 'AgentMgmtCallistaAgentCreateMockResp');
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
        Test.stopTest();

        // retrieve HQ record, and assert the account record is updated accordingly
        Account updatedHQ = [
            SELECT 
                Id
                , Name
                , Google_Integration_Status__c
                , Street__c
                , City__c
                , State__c
                , Post_Code__c
            FROM Account
            WHERE Callista_Org_Unit_Code__c= 'AG1000'
        ];

        Contact assertContact = [
            SELECT Id
                , Google_Integration_Status__c
            FROM Contact
            WHERE AccountId = :updatedHQ.Id
                AND Person_ID_unique__c = '12345678'
        ];

        System.assertEquals('Updated', assertContact.Google_Integration_Status__c);
    }

    /*******************************************************************************
    * @description: Invoke the "UniCRMIntegrationPoint" class directly, passing
    *               in invalid parameter(s)
    *               the outcome of that method.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    static void negativeTestHittingExceptionBlock1() {
        UniCRMIntegrationPoint obj = new UniCRMIntegrationPoint();
        obj.doInit('InvalidIntegrationPoint');

        List<Exception_Log__c> exList = [
            SELECT 
                Id
            FROM Exception_Log__c
            WHERE Source_Type__c = 'UniCRMIntegrationPoint'
            AND Object_Name__c = 'Account / Agent Management Integration'
            AND Function_Name__c = 'doInit'
        ];
        
        System.assertNotEquals(0, exList.size());
    }
    /*******************************************************************************
    * @description: Invoke the "UniCRMIntegrationPoint" class through ObdACPImplementation class
    * @author: Suman Gunaganti
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    static void positiveTestACPInsertUpdateStatic(){
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Person_ID_unique__c = '1111111';
        insert c;
        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Application_Course_Preference__c acp_A = new Application_Course_Preference__c();
        acp_A.Applicant__c = c.Id;
        acp_A.LongComments__c = 'ObdACPImplementationTest';
        acp_A.Precedent_ID__c = 12345;
        acp_A.Requirement_Satisfied_Code__c = 'ENGLISH';
        acp_A.Recruitment_Reference_Code__c='VCE-DIRECT';
        acp_A.Callista_Sync_Successful__c = false;
        acp_A.Application__c = app.Id;
        insert acp_A;

        Test.startTest();
        ObdACPImplementation_Mock mock = new ObdACPImplementation_Mock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        ObdACPImplementation.fireCallistaOutboundRequest(new List<Id>{acp_A.Id});
        
        Test.stopTest();

    }
}