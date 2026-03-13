/*******************************************************************************  
* @description  Test Class for searchWithDropdownCC Class
* @revision     
* 02/03/2022 - Vinothraja - SFTG-2480 Included logic to handle 'NOT' and 'LIKE' conditions in WHERE Clause
*******************************************************************************/
@isTest(isParallel=true)
public class searchWithDropdownCC_Test {
    /*
    * Data Setup
    */    
    @TestSetup
    static void makeData(){
        // insert test records
    	Contact c = new Contact();
        String fName = 'Test';
        String lName = 'Surname';
        c.FirstName = fName;
        c.LastName = lName;   
        c.email = 'test@invalid.edu';     
        insert c;
    }
    /*
    * Tests Search with = comparisons in the WHERE Clause, while Querying
    */
    @isTest
    public static void Test_getSearchResults()
    {   
        String[] fieldsToReturn = new String[]{'FirstName', 'LastName'};
        String objectApiName = 'Contact';
        String[] whereFields = new String[]{'FirstName', 'IsDeleted', 'Salutation'};
        String[] whereValues = new String[]{'Test', 'false', 'Mr.'};
        String[] optionalWhereFields = new String[]{'AccountId', 'Salutation'};
	    String[] searchFields = new String[]{'LastName', 'FirstName'};
        String searchText = 'Surname';
        Test.startTest();
            List<Object> listResults = searchWithDropdownCC.getSearchResults(fieldsToReturn,
                objectAPIName,
                whereFields,
                whereValues,
                optionalWhereFields,
                searchFields,
                searchText);
        Test.stopTest();
        System.assertEquals(1, listResults.size());
    }

    /*
    * Tests scenario with NOT and LIKE comparisons in the WHERE Clause, while Querying
    */
    @isTest 
    public static void Test_getSearchResults_NOTLIKEScenario()
    {   
    	// Testing both NOT and LIKE symbols
        String[] fieldsToReturn = new String[]{'FirstName', 'LastName'};
        String objectApiName = 'Contact';
        String[] whereFields = new String[]{'FirstName', 'IsDeleted', 'Salutation','!%email'};
        String[] whereValues = new String[]{'Test', 'false', 'Mr.', 'invalid'};
        String[] optionalWhereFields = new String[]{'AccountId', 'Salutation'};
	    String[] searchFields = new String[]{'LastName', 'FirstName'};
        String searchText = 'Surname';
        Test.startTest();
            List<Object> listResults = searchWithDropdownCC.getSearchResults(fieldsToReturn,
                objectAPIName,
                whereFields,
                whereValues,
                optionalWhereFields,
                searchFields,
                searchText);
        Test.stopTest();
        System.assertEquals(0, listResults.size());
    }

    /*
    * Tests scenario with only LIKE comparison in the WHERE Clause, while Querying
    */
    @isTest 
    public static void Test_getSearchResults_LIKEScenario()
    {           
        // Testing LIKE Symbol
        String[] fieldsToReturn = new String[]{'FirstName', 'LastName'};
        String objectApiName = 'Contact';
        String[] whereFields = new String[]{'%email'};
        String[] whereValues = new String[]{'invalid'};
        String[] optionalWhereFields = new String[]{'AccountId', 'Salutation'};
	    String[] searchFields = new String[]{'LastName', 'FirstName'};
        String searchText = 'Surname';
        
        Test.startTest();
            List<Object> listResults = searchWithDropdownCC.getSearchResults(fieldsToReturn,
                objectAPIName,
                whereFields,
                whereValues,
                optionalWhereFields,
                searchFields,
                searchText);
        Test.stopTest();
        System.assertEquals(1, listResults.size());
    }
    /*
    * Tests PrePopulation of values - positive scenario
    */ 
    @isTest 
    static void test_searchForPrepopulation()
    {       
        String[] fieldsToReturn = new String[]{'Id','FirstName'};
        String objectAPIName = 'Contact';
        Contact c = [SELECT id FROM Contact WHERE email = 'test@invalid.edu'];
        Id searchId = c.Id;
        Test.startTest();
            Contact conResult = (Contact) searchWithDropdownCC.searchForPrepopulation(fieldsToReturn, objectAPIName, searchId, new List<String>(), new List<String>());
        Test.stopTest();
        System.assertEquals(c.Id, conResult.Id);
    }
    /*
    * Tests PrePopulation of values - negative scenario
    */     
    @isTest 
    static void test_searchForPrepopulationNull()
    {      
        String[] fieldsToReturn = new String[]{'Id'};
        // error it by searching for the wrong object
        String objectAPIName = 'Account';
        Contact c = [SELECT id FROM Contact WHERE email = 'test@invalid.edu'];
        Id searchId = c.Id;
        Test.startTest();
            Account accResult = (Account) searchWithDropdownCC.searchForPrepopulation(fieldsToReturn, objectAPIName, searchId, new List<String>(), new List<String>());
        Test.stopTest();
        System.assertEquals(Null, accResult);
    }
}