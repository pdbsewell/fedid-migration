/**
 * Test class for the Console_ContactSearch_CC custom controller class.
 * These methods are part of the testing framework implemented throughout UniCRM
 */
@isTest(isParallel=true)
private class Console_ContactSearch_CC_Test {

    static testMethod void testPageLogic(){
        TestHelper.calabrioSetUp();
        list<contact> contacts = TestHelper.createOrphanContactRecords(40);
        for(contact c : contacts){
            c.lastname = 'lastname';
        }
        insert contacts;
        system.debug(contacts);
        
        PageReference pg = Page.Console_ContactSearch;
        Test.setCurrentPage(pg);
        
        Console_ContactSearch_CC con = new Console_ContactSearch_CC();
        
        system.assertEquals('{"tooManyResults":false,"results":[]}',
                            con.testGetResults('','name'),
                           'unexpected result returned');
        
        system.assertEquals(true,
                            con.testGetResults('','lastname').indexOf('tooManyResults":true') != -1,
                           'expected to get too many results back');
        
        system.assertEquals(true,
                            con.testAddEnquiry('fn','ln','testingmonash@testemail.com.nz').startsWith('500'),
                           'should have returned a case record id');
        
        system.assertEquals(false,
                            con.testAddEnquiry('fn','ln','estemail.com.nz').startsWith('500'),
                           'should not have returned a case record id');
    }
    
}