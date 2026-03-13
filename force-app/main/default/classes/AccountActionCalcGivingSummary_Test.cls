/**
 * @description       : Test class for AccountActionCalcGivingSummary
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2021-04-15
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2021-04-15   Stefan Scheit   Initial Version
**/
@isTest(isParallel=true)
public with sharing class AccountActionCalcGivingSummary_Test {

    @isTest
    public static void test_CalculateGivingSummary() {
        // GIVEN: An account is present
        Account acc = new Account();
        acc.Name = 'Test Account Positive';
        Database.insert(acc);
        System.assert(acc.Id!=null, 'Account record was not inserted successfully.');

        // WHEN: Method is invoked to calculate giving summary with a parameter of list of lists (as required by invocableActions)
        List<List<String>> inputListOfList = new List<List<String>>();
        List<String> accountIdsList = new List<String>();
        accountIdsList.add(acc.Id);
        inputListOfList.add(accountIdsList);
        Exception validateExc = null;
        try {
            AccountActionCalcGivingSummary.calculateGivingSummary(inputListOfList);
        } catch(Exception exc) {
            validateExc = exc; 
        }

        // THEN: No exception occured.
        System.assertEquals(null, validateExc, 'Exception occured when calling the invocable method \'calculateGivingSummary\' for the Account object.');
    }

    /**
     * @description Test method causing an exception (for test coverage)
     */
    @isTest
    public static void test_CalculateGivingSummaryNegative() {
        // GIVEN: An incorrect account id is defined
        String invalidAccountId = 'ErrorId';

        // WHEN: Method is invoked to calculate giving summary with a parameter of list of lists (as required by invocableActions)
        List<List<String>> inputListOfList = new List<List<String>>();
        List<String> accountIdsList = new List<String>();
        accountIdsList.add(invalidAccountId);
        inputListOfList.add(accountIdsList);
        Exception validateExc = null;
        try {
            AccountActionCalcGivingSummary.calculateGivingSummary(inputListOfList);
        } catch(Exception exc) {
            validateExc = exc; 
        }

        // THEN: An exception is expected
        System.assert(validateExc!=null, 'Exception did not occur (as expected) when calling the invocable method \'calculateGivingSummary\' for the Account object.');
    }
}