/**
 * @author      Kristian Vegerano
 * @description Test class for AccountSelector class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=true)
private class AccountsSelector_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        Account testAccount = new Account(Name = 'TestAccountName');
        insert testAccount;
    }

    /**
     * @description Test select accounts by Id
     */
    @isTest 
    static void test_SelectById() {
        //Initialize variables
        Set<Id> accountIds = new Set<Id>();
        List<Account> testAccountList = new List<Account>();

        //Retrieve existing account ids
        for(Account loopAccount : [SELECT Id FROM Account LIMIT 10]){
            accountIds.add(loopAccount.Id);
        }

        //Start test process
	 	Test.startTest();
            testAccountList.addAll(new AccountsSelector().selectById(accountIds));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(1, testAccountList.size());
    }    

    /**
     * @description Test select accounts by Id
     */
    @isTest 
    static void test_SelectByIdOverridePermissions() {
        //Initialize variables
        Set<Id> accountIds = new Set<Id>();
        List<Account> testAccountList = new List<Account>();

        //Retrieve existing account ids
        for(Account loopAccount : [SELECT Id FROM Account LIMIT 10]){
            accountIds.add(loopAccount.Id);
        }

        //Start test process
	 	Test.startTest();
            testAccountList.addAll(new AccountsSelector(true).selectById(accountIds));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(1, testAccountList.size());
    }    
}