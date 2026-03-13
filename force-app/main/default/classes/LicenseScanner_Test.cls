/*******************************************************************************
* @author       Russell Cadapan
* @date         30/04/2020
* @description  Managed Package License Scanner Test
* @revision     1.0
*******************************************************************************/
@IsTest(IsParallel=true)
private class LicenseScanner_Test {

    /*
    * Method Name: test_check_all_packages
    * Description: test method to check all installed packages status
    * Assert: Assert that no exception log is created from sending the email
    */
    @IsTest
    static void test_check_all_packages() {
        User systemAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND LastName = 'Admin' LIMIT 1];

        System.runAs(systemAdmin){

            Test.startTest();
                LicenseScanner scanner = new LicenseScanner(true);
                scanner.scan();
            Test.stopTest();
        }
        
        List<Exception_Log__c> logs = [SELECT Id FROM Exception_log__c];
        System.assert(logs.isEmpty(), 'Exception log recorded');
    }

    /*
    * Method Name: test_check_all_packages
    * Description: test method to check the active installed packages status
    * Assert: Assert that no exception log is created from sending the email
    */
    @IsTest
    static void test_check_active_packages() {
        User systemAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND LastName = 'Admin' LIMIT 1];

        System.runAs(systemAdmin){

            Test.startTest();
                LicenseScanner scanner = new LicenseScanner(false);
                scanner.scan();
            Test.stopTest();
        }
        
        List<Exception_Log__c> logs = [SELECT Id FROM Exception_log__c];
        System.assert(logs.isEmpty(), 'Exception log recorded');
    }
}