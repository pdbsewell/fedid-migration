/*******************************************************************************
    * @author       Sethu Venna
    * @date         28/03/2025
    * @description  test class for CustomLookupInputController
    * @revision     28/03/2025 - Initial Version
*******************************************************************************/
@isTest(isParallel=true)
private class CustomLookupInputController_Test {

    /*******************************************************************************
    * @author       Sethu Venna
    * @date         28/03/2025
    * @description  test method to search by name
    *******************************************************************************/
    @IsTest
    static void testSearchByName() {
        // GIVEN : There is no Account with Name as 'Test' 
        List<List<SObject>> results;
        Test.startTest();
        // WHEN : Account is Searched
        results = CustomLookupInputController.searchByName('Test', 'Account');
        Test.stopTest();
        // THEN : No Account records are retrieved
        Assert.areEqual(
            results.isEmpty(), 
            false, 
            'No Account records found'
        );
    }

}