/*******************************************************************************
* @author:      K Liew
* @date:        07.SEP.2018
* @group:       Agent Management
* @description: Sibling Test Class for InvokeCallistaAgentUpdate.  The API-chaining 
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
*               InvokeCallistaAgentUpdate (this one)
*               AgentUpdateInterface
*               JsonBodyAgent
* @revision:
*               07.SEP.2018 KL  >   Initial class creation.
*               26.OCT.2018 KL  >   Updated to call new methods with pagination
*									enabled, see AM-160.
*               12.DEC.2019 KL  >   Refactoring test class to use new approach
*                                   used as part of on-demand deployment changes.
*******************************************************************************/


@isTest(isParallel=true)
public class AgencyServerSideCC_Test {

    /*******************************************************************************
    * @description: Invoke the AgentMgmtTestUtil.loadAgenciesTestDataNoIntegration 
    *               method to set the test data needed.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @testSetup
    static void insertAgencies() {

        AgentMgmtTestUtil.loadAgenciesTestDataNoIntegration();

    }

    /*******************************************************************************
    * @description: Invoke the various controller methods and assert
    *               the outcome of that method.
    * @param:       n/a
    * @return:      n/a
    *******************************************************************************/
    @isTest
    static void positiveTest() {

        Id [] fixedSearchResults= new Id[3];
        Account accnt1 = [SELECT Id FROM Account WHERE Callista_Org_Unit_Code__c = 'TAG1000' LIMIT 1];
        fixedSearchResults[0] = accnt1.Id;

        Account accnt2 = [SELECT Id FROM Account WHERE Callista_Org_Unit_Code__c = 'TAG2000' LIMIT 1];
        fixedSearchResults[1] = accnt2.Id;

        Account accnt3 = [SELECT Id FROM Account WHERE Name = 'test org' LIMIT 1];
        fixedSearchResults[2] = accnt3.Id;

        Test.setFixedSearchResults(fixedSearchResults);


        PageResult returnObj = AgencyServerSideCC.getAllAgenciesWithPagination(1);
        // confirm that only account record of agency rt is returned
        System.assertEquals(2, returnObj.total);

        PageResult returnObj5 = AgencyServerSideCC.searchAgenciesWithPagination('--Blank--', 1);
        // confirm that search with 'empty' string is working + escaping the SOSL serach term
        System.assertEquals(2, returnObj5.total);

        PageResult returnObj2 = AgencyServerSideCC.searchAgenciesWithPagination('Test', 1);
        // confirm universal search working
        System.assertEquals(2, returnObj2.total);

        PageResult returnObj3 = AgencyServerSideCC.searchAgenciesByCountryWithPagination('Australia', 1);
        // confirm that search by country is working
        System.assertEquals(1, returnObj3.total);

                PageResult returnObj4 = AgencyServerSideCC.searchAgenciesBy1stAlphabetWithPagination('t', 1);
        // confirm that search by 1st letter is working
        System.assertEquals(2, returnObj4.total);

    }
}