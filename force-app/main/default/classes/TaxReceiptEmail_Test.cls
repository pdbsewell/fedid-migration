/**
 * This class contains unit tests for validating the behavior of automatically
 * assigning a Tax Receipt Email address based on Affiliations
 *  @REVISION HISTORY:
 *  05/04/2022  JLCOOK@AttainPartners.com - First created
 */
@isTest
private class TaxReceiptEmail_Test {
    
    /*******************************************************************************
    * @author       JLCOOK@AttainPartners.com
    * @date         05/04/2022
    * @description  tests that tax receipt email is correctly set when a single 
    *               affiliation is updated     
    *******************************************************************************/    
    static testMethod void singleTestTaxReceipt() {
        Account testAccnt = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact testCntct = (Contact)TestDataFactory.createSObject(new Contact(), true);

        testCntct.email = 'testEmail@test.test';
        update testCntct;

        Affiliation__c testAffil = new Affiliation__c(Contact__c = testCntct.Id, Account__c = testAccnt.Id, Start_Date__c = date.today(), Account_Communications__c = 'Tax Receipt');

        Test.startTest();
            insert testAffil;
        Test.stopTest();

        List<Account> resultAccnts = [SELECT Id, Name, ucinn_ascendv2__Email__c FROM Account WHERE ucinn_ascendv2__Email__c = 'testEmail@test.test'];
        System.assertEquals(resultAccnts.size(),1);
    }

    /*******************************************************************************
    * @author       JLCOOK@AttainPartners.com
    * @date         05/04/2022
    * @description  tests that tax receipt email is not set when a single 
    *               affiliation is updated with the wrong account communication
    *******************************************************************************/    
    static testMethod void singleTestNotTaxReceipt() {
        Account testAccnt = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact testCntct = (Contact)TestDataFactory.createSObject(new Contact(), true);

        testCntct.email = 'testEmail@test.test';
        update testCntct;

        Affiliation__c testAffil = new Affiliation__c(Contact__c = testCntct.Id, Account__c = testAccnt.Id, Start_Date__c = date.today(), Account_Communications__c = 'Stewardship');

        Test.startTest();
            insert testAffil;
        Test.stopTest();

        List<Account> resultAccnts = [SELECT Id, Name, ucinn_ascendv2__Email__c FROM Account WHERE ucinn_ascendv2__Email__c = 'testEmail@test.test'];
        System.assertEquals(resultAccnts.size(),0);
    }
    
    /*******************************************************************************
    * @author       JLCOOK@AttainPartners.com
    * @date         05/04/2022
    * @description  tests that tax receipt email is correctly set when multiple 
    *               affiliations are updated
    *******************************************************************************/    
    static testMethod void bulkTestTaxReceipt() {
        List<Account> testAccnts = (List<Account>)TestDataFactory.createSObjectList(new Account(), 2, true);
        List<Contact> testCntcts = (List<Contact>)TestDataFactory.createSObjectList(new Contact(), 2, true);
        List<Affiliation__c> testAffils = new List<Affiliation__c>();

        for(integer i=0; i<testCntcts.size(); i++){
            testCntcts[i].email = 'testEmail@test.test' + i;
            testAffils.add(new Affiliation__c(Contact__c = testCntcts[i].Id, Account__c = testAccnts[i].Id, Start_Date__c = date.today(), Account_Communications__c = 'Tax Receipt'));
        }
        update testCntcts;

        Test.startTest();
            insert testAffils;
        Test.stopTest();

        List<Account> resultAccnts = [SELECT Id, Name, ucinn_ascendv2__Email__c FROM Account WHERE ucinn_ascendv2__Email__c LIKE 'testEmail@test.test%'];
        System.assertEquals(resultAccnts.size(),2);
    }
}