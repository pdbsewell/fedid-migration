/**
 * @author      Kristian Vegerano
 * @description Test class for BaseSelector class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=true)
public with sharing class BaseSelector_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        Account testAccount = new Account(Name = 'TestAccountName');
        insert testAccount;
    }
    
    /**
     * @description Test methods
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
     * @description Test methods
     */
    @isTest 
    static void test_GetRelatedFieldListString() {
        //Start test process
	 	Test.startTest();
            String testParentFields = new AccountsSelector().getRelatedFieldListString('Parent');
	 	Test.stopTest();
    }
}