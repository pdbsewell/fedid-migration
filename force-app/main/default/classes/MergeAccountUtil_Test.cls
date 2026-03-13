/**
 * @description     Test class for MergeAccountUtil.cls
 * @author          J.Mapanao
 * @date            25.FEB.2020
 * 
 * @revision
 */
@isTest(isParallel=true)
private class MergeAccountUtil_Test {
    static testMethod void test_mergeAccount() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        Account testAccount_1 = new Account(
            Name = 'Test Account 1'
        );Account testAccount_2 = new Account(
            Name = 'Test Account 2'
        );
        accounts.add(testAccount_1);
        accounts.add(testAccount_2);
        insert accounts;
        System.assert(accounts != null, '### Insert Test Account Failed.');

        Test.startTest();
        MergeAccountUtil mergeAccountUtilHandler = new MergeAccountUtil(accounts[0].Id, accounts[1].Id);
        mergeAccountUtilHandler.mergeAccount();
        Test.stopTest();
        List<Account> result_Accounts = [SELECT Id FROM Account];
        System.assert(result_Accounts.size() == 1, '### Account merge failed.');
    }
}