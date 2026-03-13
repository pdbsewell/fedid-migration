/**
 * Test class for the Console_MyInformation_CCv2 custom controller class.
 * These methods are part of the testing framework implemented throughout UniCRM
 */
@isTest(isParallel=true)
private class Console_MyInformation_CCv2_Test {

    static testMethod void checkController(){
        
        List<User> users = TestHelper.createTestUsers('Monash Connect Officer', 1);
        
        Test.setCurrentPage(Page.Console_MyInformation_v2);
        
        System.runAs(users[0]){
            Console_MyInformation_CCv2 con = new Console_MyInformation_CCv2();
            List<selectOption> opts = new List<selectOption>();
            
            //Set location
            opts = con.locations;
            con.newUser.Location__c = opts[1].getValue();
            
            //Set queue
            opts = con.queues;
            con.newUser.Queue__c = opts[1].getValue();
            
            //Set role
            opts = con.enquiryroles;
            con.newUser.Enquiry_Role__c = opts[1].getValue();
            
            //Assert that the user has no my information field updated
            System.assertEquals(1, [select count() from User where My_Information_LastUpdate__c = null and id =:users[0].id], 'User updated with incomplete data');	
            Test.startTest();
                con.storeInputs();
            Test.stopTest();
            //Assert that the user has my information field updated
            System.assertEquals(0, [select count() from User where My_Information_LastUpdate__c = null and id =:users[0].id], 'User not updated as expected');
        }
    }
}