/*******************************************************************************
* @author:      K Liew
* @date:        27.NOV.2019
* @group:       Agent Management
* @description: Util Class used to generate test data used by Agent Management
*               test classes from Static Resources / CSVs.  Note that as the 
*               CRUD on Agency records will result in web service callouts, 
*               consuming test classes will need to have Mock, startTest and 
*               stopTest included accordingly.  See this class' sibling test
*               class as an example.
* @revision:
*               27.NOV.2019 KL  >   Initial class creation.
*               18.DEC.2019 KL  >   Additional method loadAgenciesTestDataNoIntegration
*                                   added to create a set of Agencies without 
*                                   triggering AM integration, see SFTT-216.
*******************************************************************************/
public with sharing class AgentMgmtTestUtil {


    /*******************************************************************************
    * @description: Loading of Agency Headquarter record for test classes, includes
    *               AM specific Custom Setting and Country refercence data as well.
    *               Static Resources used are: AgentMgmtCountryList + 
    *               AMCustomSetting + AgentMgmtHQs + AgentMgmtBranches
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    public static void loadHQTestData() {

        // Country records, load a set from static resource
        List<sObject> countriesRefData = test.loadData(Country_Attribute__c.sObjectType, 'AgentMgmtCountryList');
        Country_Attribute__c c1 = (Country_Attribute__c)countriesRefData[0];
        Country_Attribute__c c2 = (Country_Attribute__c)countriesRefData[3];

        // AM custom setting, load from static resource
        List<sObject> amSettings = test.loadData(Agent_Onboarding_Settings__c.sObjectType, 'AgentMgmtCustomSetting');
        Agent_Onboarding_Settings__c amSetting = Agent_Onboarding_Settings__c.getOrgDefaults();

        // load agencies (HQs) for test scenarios that don't require agency inserts
        List<sObject> agencyHQs = test.loadData(Account.sObjectType, 'AgentMgmtHQs');
        Account hq1 = (Account)agencyHQs[0];

    }

    /*******************************************************************************
    * @description: Loading of Agency Branch record for test classes
    *               Static Resource used: branches
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    public static void loadBranchTestData() {

         // load agencies (branches) for test scenarios that don't require agency inserts
        List<sObject> agencyBranches = test.loadData(Account.sObjectType, 'AgentMgmtBranches');
        Account b1 = (Account)agencyBranches[0];

    }

    /*******************************************************************************
    * @description: Loading of multiple Agencies without integration calls, for
    *               testing Agent DB related server-side controllers
    *               Static Resources used are: AgentMgmtCountryList + 
    *               AgentMgmtCSNoIntegration + AgentMgmtAgenciesNoIntegration
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    public static void loadAgenciesTestDataNoIntegration() {

        // Country records, load a set from static resource
        List<sObject> countriesRefData = test.loadData(Country_Attribute__c.sObjectType, 'AgentMgmtCountryList');
        Country_Attribute__c c1 = (Country_Attribute__c)countriesRefData[0];
        Country_Attribute__c c2 = (Country_Attribute__c)countriesRefData[133];
        System.debug('!@# c2.NAME = ' + c2.NAME);

        // AM custom setting, load from static resource
        List<sObject> amSettings = test.loadData(Agent_Onboarding_Settings__c.sObjectType, 'AgentMgmtCSNoIntegration');
        Agent_Onboarding_Settings__c amSetting = Agent_Onboarding_Settings__c.getOrgDefaults();
        System.debug('!@# amSetting.Callista_Integration_Enabled__c: '+ amSetting.Callista_Integration_Enabled__c);
        System.debug('!@# amSetting.Google_AP_Integration_Enabled__c: '+ amSetting.Google_AP_Integration_Enabled__c);

        // load agencies (branches) for test scenarios that don't require agency inserts
        List<sObject> agencyBranches = test.loadData(Account.sObjectType, 'AgentMgmtAgenciesNoIntegration');
        Account b1 = (Account)agencyBranches[0];
        System.debug('!@# b1.Id: '+ b1.Id);
        System.debug('!@# b1.Id: '+ b1.Id);

        // load Applications for AM test scenarios
        List<sObject> agencyApplications = test.loadData(Application__c.sObjectType, 'AgentMgmtTestApplications');
        Application__c app1 = (Application__c)agencyApplications[0];
        System.debug('!@# app1.Name: '+ app1.Name);
        System.debug('!@# app1.Agent__c: '+ app1.Agent__c);
    }
}