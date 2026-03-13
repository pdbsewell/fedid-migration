/*******************************************************************************
* @author       Inderpal Dhanoa
* @date         02/02/2022
* @description  Test class for ContactTeamDataTableController
* @revision     1.0
*******************************************************************************/           
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
public with sharing class ContactTeamDataTableController_Test {

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         1.Feb.2022
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {
        Profile enterpBaseProf = [SELECT Id FROM Profile WHERE Name='Enterprise Base Profile' Limit 1];
        List<User> l_userList = new List<User>();
        User user1 = new User(alias = 'test123', email='test123@noemail.com',
                            emailencodingkey='UTF-8',firstname='ascendportal', lastname='Site Guest User', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = enterpBaseProf.Id, country='United States',IsActive =true,
                            timezonesidkey='America/Los_Angeles', username='tester@noemail12.com');

        User user2 = new User(alias = 'test1234', email='test123@noemail.com',
                            emailencodingkey='UTF-8',firstname='ascendportal', lastname='Site Guest User', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = enterpBaseProf.Id, country='United States',IsActive =true,
                            timezonesidkey='America/Los_Angeles', username='tester@noemail123.com');
        l_userList.add(user1);
        l_userList.add(user2);

        insert l_userList;
        user1 = [SELECT Id FROM User WHERE Username='tester@noemail12.com' LIMIT 1];
        system.runAs(user1){
            // Account Creation
            Account acc = (Account)TestDataFactory.createSObject(new Account(Callista_Org_Unit_Code__c = 'DIRECT'), true);
            // Contact Creation
            Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id), true);
            // Contact Team Creation
            ContactTeam__c contTeam = (ContactTeam__c)TestDataFactory.createSObject(new ContactTeam__c(Role__c='MSDI Lead',Contact__c = contact.Id, Team_Member__c=user2.Id), true);
        }           
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         1.Feb.2022
    * @description  Method to test the method saveContactTeamMember  
    *******************************************************************************/
    @isTest
    static  void saveContactTeamMember_Test() {
        // given a contact Team member already is linked  
        Contact con = [SELECT Id FROM Contact WHERE Lastname='Con1' LIMIT 1];

        User user1 = [SELECT Id FROM User WHERE Username='tester@noemail12.com' LIMIT 1];

        User user2 = [SELECT Id FROM User WHERE Username='tester@noemail123.com' LIMIT 1];
        
        List<ContactTeam__c> contTeam = ContactTeamDataTableController.getContactTeam(String.valueOf(con.Id));

        contTeam.add(new ContactTeam__c(Contact__c = con.Id, Team_Member__c = user1.Id, Role__c = 'MSDI Lead' ));
        contTeam.add(new ContactTeam__c(Contact__c = con.Id, Team_Member__c = user2.Id, Role__c = 'MSDI Lead' ));

        // when : contact team member is saved 
        test.startTest();

        String response = ContactTeamDataTableController.saveContactTeamMember(contTeam);
        test.stopTest();

        // then : the contact team member should match the count
        system.assertEquals(response, 'SUCCESS');  
        contTeam = [SELECT Id FROM ContactTeam__c WHERE Contact__c = :con.Id]; 
        system.assertEquals(contTeam.size(), 2);  
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         1.Feb.2022
    * @description  Method to test the method getContactTeam  
    *******************************************************************************/
    @isTest
    static  void getContactTeam_Test() {
        // given a contact Team member already is linked  
        Contact con = [SELECT Id FROM Contact WHERE Lastname='Con1' LIMIT 1];
        // when : contact team member is retrieved 
        test.startTest();
        
        List<ContactTeam__c> contTeam = ContactTeamDataTableController.getContactTeam(String.valueOf(con.Id));
        test.stopTest();
        // then : the contact team member should match the count
        system.assertEquals(contTeam.size(), 1);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         1.Feb.2022
    * @description  Method to test the method deleteContactTeam  
    *******************************************************************************/
    @isTest
    static  void deleteContactTeam_Test() {
         // given a contact Team member already is linked  
         Contact con = [SELECT Id FROM Contact WHERE Lastname='Con1' LIMIT 1];
         List<ContactTeam__c> contTeam = [SELECT Id FROM ContactTeam__c WHERE Contact__c = :con.Id]; 
         
         // when : contact team member is retrieved 
         test.startTest();
         String response = ContactTeamDataTableController.deleteContactTeam(String.valueOf(contTeam[0].Id));
         test.stopTest();
         
         // then : the contact team member should match the count
         contTeam = [SELECT Id FROM ContactTeam__c WHERE Contact__c = :con.Id];
         system.assertEquals(contTeam.size(), 0);
         system.assertEquals(response, 'SUCCESS');
    }
}