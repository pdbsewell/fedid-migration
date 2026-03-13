/**
 * @description       : Test class for FC_SessionController
 * @author            : Inderpal Dhanoa
 * @group             : Test Class
 * @last modified on  : 2023-04-13
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   2023-04-13 - Inderpal Dhanoa  - Initial Creation 
**/

@isTest(isParallel=true)
private class FC_SessionController_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         2023-04-13
    * @description  Test setup
    *******************************************************************************/
    @TestSetup
    static void setupData(){
        
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // Insert a new User 
        
        System.runAs(thisUser) {
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Base Profile' LIMIT 1];
        
            User user = (User)TestDataFactory.createSObject(new User(UserName = random + 'testusername@testemail.com',FirstName = 'TestFirstName',LastName = 'TestLast',Alias = 'ssoxtst8', email = random + 'testusername@testemail.com',ProfileId = profile.Id,IsActive = true,EmailEncodingKey = 'UTF-8',TimeZoneSidKey = 'Australia/Sydney',LocaleSidKey = 'en_US',LanguageLocaleKey = 'en_US'), true);
            
            PermissionSet baseUserPermSet = [SELECT Id, name FROM permissionSet where name = :Label.Extend_Session];
            
            PermissionSetAssignment permSet1 = (PermissionSetAssignment)TestDataFactory.createSObject(new PermissionSetAssignment(AssigneeId=user.Id,PermissionSetId=baseUserPermSet.Id), true);
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         2023-04-13
    * @description  Test method for getUserStatus postive scenario
    *******************************************************************************/
    @IsTest
    static void getUserStatus_Test_Positive() {
        // GIVEN: User has the Permission set assigned to him
        User runningUser = [SELECT Id FROM User WHERE Email like '%testusername@testemail.com%' ORDER By CreatedDate DESC LIMIT 1];
        Boolean status;
        test.startTest();
        // WHEN: user status is checked
        System.runAs(runningUser) {
            status = FC_SessionController.getUserStatus();
        }        
        test.stopTest();

        // THEN: Status should appear as True
        system.assertEquals(status, true);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         2023-04-13
    * @description  Test method for getUserStatus Negative scenario
    *******************************************************************************/
    @IsTest
    static void getUserStatus_Test_Negative() {
        // GIVEN:  User does not have the Permission set assigned to him
        Boolean status;
        test.startTest();
        // WHEN: user status is checked
        status = FC_SessionController.getUserStatus();       
        test.stopTest();

        // THEN: Status should appear as False
        system.assertEquals(status, false);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         2023-04-13
    * @description  Test method for get Session Status
    *******************************************************************************/
    @IsTest
    static void getSessionStatus_Test() {
        // GIVEN: User's session is ongoing
        test.startTest();
        // WHEN: Users session status is checked
        FC_SessionController.SessionStatus wrapperClass = FC_SessionController.getSessionStatus();      
        Boolean busnHrs = FC_SessionController.isBusinessHours();
        test.stopTest();

        // THEN: Based on the Business Hours the response would be true or False
        if(FC_SessionController.getSessionSecondsRemaining() < Integer.ValueOf(Label.Session_Pending_Interval) && busnHrs){
            system.assertEquals(wrapperClass.inactiveForOneHour, true);
        }else{
            system.assertEquals(wrapperClass.inactiveForOneHour, false);
        }  
    }
}