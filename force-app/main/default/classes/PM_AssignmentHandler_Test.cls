/**
 * Assignment Test class.
 *
 * @author:  Mark Johnson
 * @since:   12/1/2020
 */

@isTest
private class PM_AssignmentHandler_Test {

    static final string PRM = 'Primary Relationship Manager - Development';


    @testSetup static void methodName() {
        ucinn_ascendv2__Trigger_Handler__c ascendAssignmentTriggerHandler = new ucinn_ascendv2__Trigger_Handler__c( Name = 'Assignment Handler', 
                                                                                    ucinn_ascendv2__Is_Active__c = true, 
                                                                                    ucinn_ascendv2__Is_Asynchronous__c = false,
                                                                                    ucinn_ascendv2__Class__c = 'ascend_TRIG_AssignmentHandler', 
                                                                                    ucinn_ascendv2__Load_Order__c = 1.00, 
                                                                                    ucinn_ascendv2__Object__c = new ucinn_ascendv2__Assignment__c().getSObjectType().getDescribe().getName(),
                                                                                    ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete');
        
        ucinn_ascendv2__Trigger_Handler__c customAssignmentTriggerHandler = new ucinn_ascendv2__Trigger_Handler__c( Name = 'Custom Assignment Handler', 
                                                                                    ucinn_ascendv2__Is_Active__c = true, 
                                                                                    ucinn_ascendv2__Is_Asynchronous__c = false,
                                                                                    ucinn_ascendv2__Class__c = 'PM_AssignmentHandler', 
                                                                                    ucinn_ascendv2__Load_Order__c = 2.00, 
                                                                                    ucinn_ascendv2__Object__c = new ucinn_ascendv2__Assignment__c().getSObjectType().getDescribe().getName(),
                                                                                    ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete');
        
        insert new List<ucinn_ascendv2__Trigger_Handler__c> {ascendAssignmentTriggerHandler, customAssignmentTriggerHandler};
    }

    /**
    *   Test method for PRM Rollup.
    *
    *   @since      12/1/2020
    */
    static testMethod void testPRMRollup() {

        Account acct1 = new Account(name = 'ABC Corp');
        insert acct1;
        contact con1 = new contact(lastname = 'Jones');
        insert con1;

        Id userId = UserInfo.getUserId();

        // Insert assignment for both contact and account
        ucinn_ascendv2__Assignment__c a1 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Account__c = acct1.id, 
                                                ucinn_ascendv2__Contact__c = con1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                                ucinn_ascendv2__Assignment_Start_Date__c = Date.today(), 
                                                ucinn_ascendv2__Assignment_End_Date__c = null);
        insert a1;

        test.startTest();
        
        //Assignment should be current
        Account acct = [select ucinn_ascendv2__PRM__c from account where id = :acct1.id];
        System.assertEquals(userId, acct.ucinn_ascendv2__PRM__c, 'The assignment is current and the account should be updated.');
        Contact con = [select ucinn_ascendv2__PRM__c from contact where id = :con1.id];
        System.assertEquals(userId, con.ucinn_ascendv2__PRM__c, 'The assignment is current and the contact should be updated.');

        //Increment Start Date
        a1.ucinn_ascendv2__Assignment_Start_Date__c = Date.today() + 1;
        update a1;
        
        //Assignment should no longer be current
        acct = [select ucinn_ascendv2__PRM__c from Account where id = :acct1.id];
        System.assertEquals(null, acct.ucinn_ascendv2__PRM__c, 'The assignment for this account is no longer current.');
        con = [select ucinn_ascendv2__PRM__c from contact where id = :con1.id];
        System.assertEquals(null, con.ucinn_ascendv2__PRM__c, 'The assignment for this contact is no longer current.');

        // Insert assignment for both contact and account
        ucinn_ascendv2__Assignment__c a2 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Account__c = acct1.id, 
                                                ucinn_ascendv2__Contact__c = con1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = 'Secondary Relationship Manager',
                                                ucinn_ascendv2__Assignment_Start_Date__c = Date.today() - 1, 
                                                ucinn_ascendv2__Assignment_End_Date__c = null);
        insert a2;
        
        //Verify that Secondary Relationship Manager does not roll up to PRM
        acct = [select ucinn_ascendv2__PRM__c from Account where id = :acct1.id];
        system.assertEquals(null, acct.ucinn_ascendv2__PRM__c, 'Secondary Relationship Manager does not update the account.');
        con = [select ucinn_ascendv2__PRM__c from contact where id = :con1.id];
        system.assertEquals(null, con.ucinn_ascendv2__PRM__c, 'Secondary Relationship Manager does not update the contact.');

        // Insert an assignment for only the contact
        ucinn_ascendv2__Assignment__c a3 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Contact__c = con1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                                ucinn_ascendv2__Assignment_Start_Date__c = Date.today(), ucinn_ascendv2__Assignment_End_Date__c = null);
        
        // Should not allow two primary PRMs
        try{
            insert a3;
        }
        catch(System.DmlException e){
            system.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0), 'Two PRM cannot be active at the same time.');
        }
        
        // Confirm the exception was caught and the record not inserted
        system.assertEquals(null, a3.id);

        a3.ucinn_ascendv2__Assignment_Start_Date__c = Date.today() - 10;
        a3.ucinn_ascendv2__Assignment_End_Date__c = Date.today();
        
        insert a3;
        
        con = [select ucinn_ascendv2__PRM__c from contact where id = :con1.id];
        system.assertEquals(userId, con.ucinn_ascendv2__PRM__c, 'This PRM is current and does not overlap.');

        Test.stopTest();
    }

    
    /**
    *   Test method for PRM Rollup when assignment is moved.
    *
    *   @since      12/1/2020
    */
    static testMethod void testPRMRollupWhenMovingAssignmentBetweenContacts() {
        
        List<User> l_testUsers = new List<User>();
        User user1 = (User)TestDataFactory.createSObject(new User(alias = 'user1', email='user1@me.com', communityNickname='45890000',
                                                emailencodingkey='UTF-8', lastname='user1', languagelocalekey='en_US',
                                                localesidkey='en_US', profileid = UserInfo.getProfileId(), department = 'Unit1',
                                                timezonesidkey='America/Los_Angeles', username='MyTestUser784@test.com'),false);

        User user2 = (User)TestDataFactory.createSObject(new User(alias = 'user2', email='user2@me.com', communityNickname='45897887',
                                                emailencodingkey='UTF-8', lastname='user2', languagelocalekey='en_US',
                                                localesidkey='en_US', profileid = UserInfo.getProfileId(), department = 'Unit2',
                                                timezonesidkey='America/Los_Angeles', username='MyTestUser783@test.com'),false);
        l_testUsers.add(user1);
        l_testUsers.add(user2);

        insert l_testUsers;

        
        
        //Workaround to avoid MIXED DML EXCEPTION: 
        //https://stackoverflow.com/questions/2387475/how-to-avoid-mixed-dml-operation-error-in-salesforce-tests-that-create-users
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];

        System.runAs ( thisUser ) {
            
            // Contact
            List<Contact> l_testContacts = new List<Contact>();
            Contact con1 = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'firstName', lastName = 'Jones'), false); 
            Contact con2 = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'firstName', lastName = 'Smith'), false); 
            l_testContacts.add(con1);
            l_testContacts.add(con2);

            insert l_testContacts;
    
            Id userId = UserInfo.getUserId();
            Date todaysDate = Date.today();
    
            // given : Insert assignments where one ends the same day the other starts
            ucinn_ascendv2__Assignment__c a1 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Contact__c = con1.id, 
                                                    ucinn_ascendv2__Assigned_Relationship_Manager_User__c = user1.id, 
                                                    ucinn_ascendv2__Assignment_Type__c = PRM,
                                                    ucinn_ascendv2__Assignment_Start_Date__c = todaysDate - 10,
                                                    ucinn_ascendv2__Assignment_End_Date__c = todaysDate);
    
            ucinn_ascendv2__Assignment__c a2 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Contact__c = con1.id, 
                                                    ucinn_ascendv2__Assigned_Relationship_Manager_User__c = user2.id, 
                                                    ucinn_ascendv2__Assignment_Type__c = PRM,
                                                    ucinn_ascendv2__Assignment_Start_Date__c = todaysDate, 
                                                    ucinn_ascendv2__Assignment_End_Date__c = null);
    
            insert a2;
            insert a1;
    
            Contact con = [select ucinn_ascendv2__PRM__c from contact where id = :con1.id];
            system.assertEquals(user2.id, con.ucinn_ascendv2__PRM__c, 'The current assignment starting today should be selected.');

            test.startTest();
    
            // When: Move the second assignment to a new contact
            ucinn_ascendv2__Assignment__c a2Upd = new ucinn_ascendv2__Assignment__c(id = a2.id, ucinn_ascendv2__contact__c = con2.id);
            update a2Upd;
    
            con = [select ucinn_ascendv2__PRM__c from contact where id = :con1.id];
            system.assertEquals(user1.id, con.ucinn_ascendv2__PRM__c, 'The PRM for the old contact should be for the first assignment ending today.');
    
            con = [select ucinn_ascendv2__PRM__c from contact where id = :con2.id];
            system.assertEquals(user2.Id, con.ucinn_ascendv2__PRM__c, 'The PRM for the new contact should be for the second assignment starting today.');
    
            ucinn_ascendv2__Assignment__c a1Upd = new ucinn_ascendv2__Assignment__c(id = a1.id, ucinn_ascendv2__contact__c = con2.id);
            update a1Upd;

            Test.stopTest();

            //then: Now move the first assignment
    
            con = [select ucinn_ascendv2__PRM__c from contact where id = :con1.id];
            system.assertEquals(null, con.ucinn_ascendv2__PRM__c, 'The PRM for the old contact should be removed.');

        }
        
        
    }

    /**
    *   Test method for assignments with time overlaps
    *
    *   @since      12/1/2020
    */
    static testmethod void testTimeOverlaps() {

        Date todaysDate = Date.today();
        Id userId = UserInfo.getUserId();
        contact con1 = new contact(lastname = 'Jones');
        insert con1;

        list<ucinn_ascendv2__Assignment__c> assigns = new list<ucinn_ascendv2__Assignment__c>();


        // Test overlapping assignments
        // Assignments cannot be entered with an end date in the future.
        // Assignments with an end date in the past are ignored.
        ucinn_ascendv2__Assignment__c a1 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Contact__c = con1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                                ucinn_ascendv2__Assignment_Start_Date__c = todaysDate - 8, 
                                                ucinn_ascendv2__Assignment_End_Date__c = todaysDate);
        insert a1;

        ucinn_ascendv2__Assignment__c a2 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Contact__c = con1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                                ucinn_ascendv2__Assignment_Start_Date__c = todaysDate - 4, 
                                                ucinn_ascendv2__Assignment_End_Date__c = todaysDate);

        try {
            insert a2;
        }
        catch(System.DmlException e){
            system.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0), 'Two PRM cannot be active at the same time.');
        }

        list<ucinn_ascendv2__Assignment__c> assignments = [select id from ucinn_ascendv2__Assignment__c where ucinn_ascendv2__contact__c = :con1.Id];
        system.assertEquals(1, assignments.size(), 'Only one assignment should have been inserted since the second was a time overlap.');

        // Test an assignment that starts on the same day the other ends
        a2.ucinn_ascendv2__Assignment_Start_Date__c = todaysDate;
        a2.ucinn_ascendv2__Assignment_End_Date__c = null;
        insert a2;
        assignments = [select id from ucinn_ascendv2__Assignment__c where ucinn_ascendv2__contact__c = :con1.Id];
        system.assertEquals(2, assignments.size(), 'The second assignment should be inserted since it started the day the other assignment ended.');

        // Test an expired assignment
        ucinn_ascendv2__Assignment__c a3 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Contact__c = con1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                                ucinn_ascendv2__Assignment_Start_Date__c = todaysDate - 8, 
                                                ucinn_ascendv2__Assignment_End_Date__c = todaysDate - 1);
        insert a3;
        assignments = [select id from ucinn_ascendv2__Assignment__c where ucinn_ascendv2__contact__c = :con1.Id];
        system.assertEquals(3, assignments.size(), 'The third assignment should be inserted since assignments ending before today are ignored.');

    }

    /**
    *   Test method for assignments with time overlaps and no end dates
    *
    *   @since      12/1/2020
    */
    static testmethod void testTimeOverlapWithNoEndDatesForContacts(){

        contact con1 = new contact(lastname = 'Jones');
        insert con1;

        Id userId = UserInfo.getUserId();

        // Insert assignments
        list<ucinn_ascendv2__Assignment__c> assigns = new list<ucinn_ascendv2__Assignment__c>();

        // Create assignments with a sequential data range
        ucinn_ascendv2__Assignment__c a1 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Contact__c = con1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                                ucinn_ascendv2__Assignment_Start_Date__c = Date.newInstance(2013, 6, 15), 
                                                ucinn_ascendv2__Assignment_End_Date__c = null);
        assigns.add(a1);
        
        ucinn_ascendv2__Assignment__c a2 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Contact__c = con1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                                ucinn_ascendv2__Assignment_Start_Date__c = Date.newInstance(2013, 6, 1), 
                                                ucinn_ascendv2__Assignment_End_Date__c = null);
        assigns.add(a2);

        test.startTest();

        // Test a time overlap in the same batch
        try {
            insert assigns;
        }
        catch(System.DmlException e){
            system.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0), 'Two PRM cannot be active at the same time.');
        }

        // Confirm the exception was thrown
        list<Contact> contacts = [select ucinn_ascendv2__prm__c from contact where id = :con1.id];
        system.assertEquals(1, contacts.size(), 'Only one PRM record should be inserted since there was a time overlap on the second one.');

        // Test a time overlap in a separate batch.
        a2 = new ucinn_ascendv2__Assignment__c( ucinn_ascendv2__Contact__c = con1.id, 
                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                ucinn_ascendv2__Assignment_Start_Date__c = Date.newInstance(2013, 6, 1), 
                                ucinn_ascendv2__Assignment_End_Date__c = null);
        
        try{
            insert a2;
        }
        catch(System.DmlException e){
            system.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0), 'Two PRM cannot be active at the same time.');
        }
        contacts = [select ucinn_ascendv2__prm__c from contact where id = :con1.id];
        system.assertEquals(1, contacts.size(), 'Confirm only one PRM record was inserted since there was a time overlap');
        Test.stopTest();
    }

    /**
    *   Test method for assignments with time overlaps for accounts
    *
    *   @since      12/1/2020
    */
    static testmethod void testTimeOverlapWithNoEndDatesForAccounts(){

        Account acct1 = new Account(name = 'Best Sell Inc');
        insert acct1;

        Id userId = UserInfo.getUserId();

        // Insert assignments
        list<ucinn_ascendv2__Assignment__c> assigns = new list<ucinn_ascendv2__Assignment__c>();

        // Create assignments with a sequential data range
        ucinn_ascendv2__Assignment__c a1 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Account__c = acct1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                                ucinn_ascendv2__Assignment_Start_Date__c = Date.newInstance(2013, 6, 15), 
                                                ucinn_ascendv2__Assignment_End_Date__c = null);
        assigns.add(a1);
        
        ucinn_ascendv2__Assignment__c a2 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Account__c = acct1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                                ucinn_ascendv2__Assignment_Start_Date__c = Date.newInstance(2013, 6, 1), 
                                                ucinn_ascendv2__Assignment_End_Date__c = null);
        assigns.add(a2);

        test.startTest();

        // Test a time overlap in the same batch
        try {
            insert assigns;
        }
        catch(System.DmlException e){
            system.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0), 'Two PRM cannot be active at the same time.');
        }

        // Confirm the exception was thrown
        list<Account> Accounts = [select ucinn_ascendv2__PRM__c from Account where id = :acct1.id];
        system.assertEquals(1, Accounts.size(), 'Only one PRM record should be inserted since there was a time overlap on the second one.');

        // Test a time overlap in a separate batch.
        a2 = new ucinn_ascendv2__Assignment__c( ucinn_ascendv2__Account__c = acct1.id, 
                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                ucinn_ascendv2__Assignment_Start_Date__c = Date.newInstance(2013, 6, 1), 
                                ucinn_ascendv2__Assignment_End_Date__c = null);
        try{
            insert a2;
        }
        catch(System.DmlException e){
            system.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, e.getDmlType(0), 'Two PRM cannot be active at the same time.');
        }
        Accounts = [select ucinn_ascendv2__PRM__c from Account where id = :acct1.id];
        system.assertEquals(1, Accounts.size(), 'Confirm only one PRM record was inserted since there was a time overlap');
        Test.stopTest();
    }
    
    
    /**
    *   Test method deleting PRM Assignments
    *
    *   @since      12/1/2020
    */
    static testmethod void testPRMAssignmentDeletion(){

        Account acct1 = new Account(name = 'ABC Corp');
        insert acct1;
        contact con1 = new contact(lastname = 'Jones');
        insert con1;

        Id userId = UserInfo.getUserId();

        // Insert assignment for both contact and account
        ucinn_ascendv2__Assignment__c a1 = new ucinn_ascendv2__Assignment__c(   ucinn_ascendv2__Account__c = acct1.id, 
                                                ucinn_ascendv2__Contact__c = con1.id, 
                                                ucinn_ascendv2__Assigned_Relationship_Manager_User__c = userId, 
                                                ucinn_ascendv2__Assignment_Type__c = PRM,
                                                ucinn_ascendv2__Assignment_Start_Date__c = Date.today(), 
                                                ucinn_ascendv2__Assignment_End_Date__c = null);
        insert a1;

        test.startTest();
        
        //Assignment should be current
        Account acct = [select ucinn_ascendv2__PRM__c from account where id = :acct1.id];
        System.assertEquals(userId, acct.ucinn_ascendv2__PRM__c, 'The assignment is current and the account should be updated.');
        Contact con = [select ucinn_ascendv2__PRM__c from contact where id = :con1.id];
        System.assertEquals(userId, con.ucinn_ascendv2__PRM__c, 'The assignment is current and the contact should be updated.');
        
        delete a1;
        
        //PRM should be cleared
        Account acct2 = [select ucinn_ascendv2__PRM__c from account where id = :acct1.id];
        System.assertEquals(null, acct2.ucinn_ascendv2__PRM__c, 'PRM should be null when the PRM assignment has been deleted.');
        Contact con2 = [select ucinn_ascendv2__PRM__c from contact where id = :con1.id];
        System.assertEquals(null, con2.ucinn_ascendv2__PRM__c, 'PRM should be null when the PRM assignment has been deleted.');

        Test.stopTest();
    }

}