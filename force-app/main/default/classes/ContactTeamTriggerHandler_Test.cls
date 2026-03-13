/**
 * @description       : Test class for the trigger handler 
 * @author            : Inderpal Dhanoa
 * @group             : Test
 * Modifications Log 
 * Ver   Date         Author             Modification
 * 1.0   2022-02-03   Inderpal Dhanoa    Initial Version
**/
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: [] 
public class ContactTeamTriggerHandler_Test {

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03.Feb.2022
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
        }
    }


    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         1.Feb.2022
    * @description  Method to test the method PopulateUniqueField  
    *******************************************************************************/
    @isTest
    static  void PopulateUniqueFieldInsert_Test() {
        // given a contact Team member already is linked  
        Contact con = [SELECT Id FROM Contact WHERE Lastname='Con1' LIMIT 1];

        User user1 = [SELECT Id FROM User WHERE Username='tester@noemail12.com' LIMIT 1];
        
        List<ContactTeam__c> contTeam = new List<ContactTeam__c>();

        contTeam.add(new ContactTeam__c(Contact__c = con.Id, Team_Member__c = user1.Id, Role__c = 'MSDI Lead' ));
        contTeam.add(new ContactTeam__c(Contact__c = con.Id, Team_Member__c = user1.Id, Role__c = 'MSDI Lead' ));

        // when : contact team member is saved 
        Exception expectedException = null;
        
        try{
            test.startTest();
            insert contTeam;
            test.stopTest();
        }catch(Exception ex){
            // then : the contact team member should not be inserted and should get an Out of the box Validation Error
            expectedException = ex;
            System.assert(ex.getMessage().contains('duplicate value found') == true);
        }
		// then : the contact team member exception should be thrown
		System.assertNotEquals(expectedException, null);
    }
	
	/*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         1.Feb.2022
    * @description  Method to test the method PopulateUniqueField  
    *******************************************************************************/
    @isTest
    static  void PopulateUniqueFieldUpdate_Test() {
        // given a contact Team member already is linked  
        Contact con = [SELECT Id FROM Contact WHERE Lastname='Con1' LIMIT 1];

        User user1 = [SELECT Id FROM User WHERE Username='tester@noemail12.com' LIMIT 1];
        
        User user2 = [SELECT Id FROM User WHERE Username='tester@noemail123.com' LIMIT 1];
        
        List<ContactTeam__c> contTeam = new List<ContactTeam__c>();

        contTeam.add(new ContactTeam__c(Contact__c = con.Id, Team_Member__c = user1.Id, Role__c = 'MSDI Lead' ));
        contTeam.add(new ContactTeam__c(Contact__c = con.Id, Team_Member__c = user2.Id, Role__c = 'MSDI Lead' ));
        
        insert contTeam;
        
        contTeam = [SELECT Id, Role__c FROM ContactTeam__c WHERE Contact__c = :con.Id AND Team_Member__c = :user2.Id];
        contTeam[0].Team_Member__c = user1.Id;

        // when : contact team member is saved 
		Exception expectedException = null;
		
        
        try{
			test.startTest();
            update contTeam;
			test.stopTest();
        }catch(Exception ex){
            // then : the contact team member should not be inserted and should get an Out of the box Validation Error
			expectedException = ex;
            System.assert(ex.getMessage().contains('duplicate value found') == true);
        }
		// then : the contact team member exception should be thrown
		System.assertNotEquals(expectedException, null);
         
    }
}