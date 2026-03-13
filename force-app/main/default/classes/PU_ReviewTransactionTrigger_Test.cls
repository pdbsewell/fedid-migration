/**
 * @author          Jackie Ho
 * @description     Test class for PORTAL_UCIN_ReviewTransactionTrigger
 * @group           Test Class
 * @last modified on  : 12-08-2025
 * @last modified by  : Jackie Ho
 */

// PEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, 
// DML operations aren't permitted on this type of object: User
@isTest(isParallel=false) 
private class PU_ReviewTransactionTrigger_Test {
    
    @TestSetup
    /**
     * @description     Setup test data for review transactions
     * @param           None
     * @return          None
     */
    static void setupData() {
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        // GIVEN: Create a community user profile
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1];
        
        // GIVEN: Create an account for the community user
        Account testAccount = new Account(Name = 'Test Community Account');
        insert testAccount;
        
        // GIVEN: Create a contact for the community user
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Community User',
            AccountId = testAccount.Id,
            Email = 'test.community.user@example.com'
        );
        insert testContact;
        
        // GIVEN: Create a community user
        String uniqueUserName = 'community.user' + DateTime.now().getTime() + '@testorg.com';
        User communityUser = new User(
            Alias = 'comUser',
            Email = 'test.community.user@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = communityProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName,
            ContactId = testContact.Id
        );
        insert communityUser;
        
        // GIVEN: Create test data needed for review transactions
        // This part can be similar to the original test class
        String guid = String.valueOf(Datetime.now().hour()) + String.valueOf(Datetime.now().minute()) + String.valueOf(Datetime.now().second());
        
        // GIVEN: Create Constituents
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.Firstname = 'Contact';
        con1.Lastname = guid;
        con1.ucinn_ascendv2__Preferred_Address_Line_1__c = '888 Test Street';
        con1.ucinn_ascendv2__Preferred_Address_City__c = 'Test City';
        con1.ucinn_ascendv2__Preferred_Address_State__c = 'CA';
        con1.ucinn_ascendv2__Preferred_Address_Postal_Code__c = '99999';
        conList.add(con1);
        insert conList;
        
        // GIVEN: Create Appeal Codes
        List<Campaign> cmpList = new List<Campaign>();
        Campaign cmp = new Campaign();
        cmp.Name = 'A-'+guid;
        cmp.IsActive = true;
        cmp.Status = 'Planned';
        cmp.ucinn_ascendv2__Motivation_Code__c = 'A-'+guid;
        cmpList.add(cmp);
        insert cmpList;

        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
    }
    
    @isTest
    /**
     * @description     Test community user insert
     * @param           None
     * @return          None
     */
    static void testCommunityUserInsert() {
        String sample = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());
        
        // Get the community user
        User communityUser = [SELECT Id FROM User WHERE Email = 'test.community.user@example.com' LIMIT 1];
        
        // Get test data
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Test' LIMIT 1];
        
        // Create test review transaction
        ucinn_ascendv2__Review_Transaction__c testRT = new ucinn_ascendv2__Review_Transaction__c(
            ucinn_ascendv2__External_System_ID__c = 'PRAX' + sample,
            ucinn_ascendv2__Contact__c = testContact.Id,
            ucinn_ascendv2__Amount_1__c = 100,
            ucinn_ascendv2__Transaction_Date__c = Date.today()
        );
        
        Test.startTest();
        // WHEN: Run as community user
        System.runAs(communityUser) {
            // This will trigger the PORTAL_UCIN_ReviewTransactionTrigger
            insert testRT;
        }
        Test.stopTest();
        
        List<ucinn_ascendv2__Review_Transaction__c> createdRTs = [
            SELECT Id, ucinn_ascendv2__Amount_1__c 
            FROM ucinn_ascendv2__Review_Transaction__c 
            WHERE Id = :testRT.Id
        ];
        
        // THEN: Verify the record was created
        Assert.areEqual(1, createdRTs.size(), 'Review Transaction should be created');
        Assert.areEqual(100, createdRTs[0].ucinn_ascendv2__Amount_1__c, 'Transaction amount should match');
    }
    
    @isTest
    /**
     * @description     Test community user update
     * @param           None
     * @return          None
     */
    static void testCommunityUserUpdate() {
        String sample = String.valueOf(Datetime.now().hour())+String.valueOf(Datetime.now().minute())+String.valueOf(Datetime.now().second());

        // Get the community user
        User communityUser = [SELECT Id FROM User WHERE Email = 'test.community.user@example.com' LIMIT 1];
        
        // Get test data
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Test' LIMIT 1];
        
        Test.startTest();
        // WHEN: Run as community user
        System.runAs(communityUser) {
            // Create test review transaction as community user
            ucinn_ascendv2__Review_Transaction__c testRT = new ucinn_ascendv2__Review_Transaction__c(
                ucinn_ascendv2__External_System_ID__c = 'PRAX' + sample,
                ucinn_ascendv2__Contact__c = testContact.Id,
                ucinn_ascendv2__Amount_1__c = 100,
                ucinn_ascendv2__Transaction_Date__c = Date.today()
            );
            insert testRT;
            // Update the record to trigger the before update
            testRT.ucinn_ascendv2__Amount_1__c = 200;
            update testRT;
        }
        Test.stopTest();

        String sampleId = 'PRAX' + sample;
        
        // Verify the record was updated
        ucinn_ascendv2__Review_Transaction__c updatedRT = [
            SELECT Id, ucinn_ascendv2__Amount_1__c 
            FROM ucinn_ascendv2__Review_Transaction__c 
            WHERE ucinn_ascendv2__External_System_ID__c = :sampleId
            LIMIT 1
        ];
        
        // THEN: Assert the record was updated with the trigger handler
        Assert.areEqual(200, updatedRT.ucinn_ascendv2__Amount_1__c, 'Transaction amount should be updated');
    }
    
    @isTest
    /**
     * @description     Test standard user does not trigger handler
     * @param           None
     * @return          None
     */
    static void testStandardUserDoesNotTriggerHandler() {
        Database.SaveResult result;

        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');

        String sample = String.valueOf(Datetime.now().getTime());
        
        // Create a standard user profile (not community)
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create an account for the standard user
        Account testAccount = new Account(Name = 'Test Standard Account');
        insert testAccount;
        
        // Create a contact for the standard user
        Contact testContact = new Contact(
            FirstName = 'Standard',
            LastName = 'User Contact',
            AccountId = testAccount.Id,
            Email = 'standard.contact@example.com'
        );
        insert testContact;
        
        // WHEN: Create a standard user
        String uniqueUserName = 'standard.user' + sample + '@testorg.com';
        User standardUser = new User(
            Alias = 'stdUser',
            Email = 'standard.user@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Standard',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        insert standardUser;
        
        Test.startTest();
        // WHEN: Run as standard user
        System.runAs(standardUser) {
            // Create test review transaction
            ucinn_ascendv2__Review_Transaction__c testRT = new ucinn_ascendv2__Review_Transaction__c(
                ucinn_ascendv2__External_System_ID__c = 'PRAX' + sample,
                ucinn_ascendv2__Contact__c = testContact.Id,
                ucinn_ascendv2__Amount_1__c = 100,
                ucinn_ascendv2__Transaction_Date__c = Date.today()
            );
            // Use Database.insert with allOrNone=false to prevent exceptions
            result = Database.insert(testRT, false);    
        }
        Test.stopTest();

        // THEN: Assert that the insert was not successful
        Assert.isTrue(!result.isSuccess(), 'Standard user should not be able to insert Review Transaction');
        Assert.isTrue(result.getErrors().size() > 0, 'Should have validation errors');

        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
    }
}