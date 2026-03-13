/**
* @author Herman Castano
* @description Apex test class for EnableCCUsersForOfferAcceptanceTest class
* @group SF Offers
*
**/
@isTest
public with sharing class EnableCCUsersForOfferAcceptance_Test {

    @testSetup static void setup() {
        //insert myapp custom setting
        insert new MyApp_Settings__c(Permission_Sets__c = 'SteelBrickCPQCustomerUser', Permission_Set_Licenses__c= 'SalesforceCPQ_CPQStandardPerm');

        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        
        //Contact Creation
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(
            AccountId = acc.Id,
            Email='contact1@email.com',
            Firstname='firstname',
            LastName='lastname'
        ), true);
    }    
    
    /**
    * @author Herman Castano
    * @date 22/01/2020
    * @group SF Offer
    * @description Test method to test when a quote is created without portal user
    **/
    @isTest
    private static void createQuoteWithoutUser(){
        Test.startTest();
        Contact contact1 = [SELECT ID FROM Contact LIMIT 1];
        //Opportunity Creation,
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__PrimaryContact__c = contact1.Id),true);
        
        System.enqueueJob(new EnableCCUsersForOfferAcceptance(new List<SBQQ__Quote__c>{quote}, new Set<ID>{contact1.Id})); 

        Test.stopTest();

        List<User> quoteUser = new List<User> ([
            SELECT id, username, ProfileId, Profile.Name, Profile.UserLicense.Name ,ContactId
            FROM User
            WHERE ContactId = :quote.SBQQ__PrimaryContact__c
            AND IsActive = TRUE 
            LIMIT 1]);
        
        System.assertEquals(quoteUser.size(), 1);      
        System.assertEquals(quoteUser[0].ContactId, quote.SBQQ__PrimaryContact__c);
        System.assertEquals(quoteUser[0].Profile.Name, Constants.PORTAL_PROFILE_NAME); 
        System.assertEquals(1, [SELECT AssigneeId FROM PermissionSetLicenseAssign WHERE AssigneeId= :quoteUser[0].Id].size());
    }      

    @isTest 
    static void test_duplicateuser(){
        Contact contact1 = [SELECT ID, AccountId FROM Contact LIMIT 1];        
        TriggerCommon.disableTrigger('User');
        TestDataFactory.createSObject(new User(CommunityNickname = 'helloworld', Username ='contact1@email.com', ContactId = contact1.Id, ProfileId = [select Id from Profile where name =: Constants.PORTAL_PROFILE_NAME Limit 1].Id),true);

        Test.startTest();
        //Opportunity Creation,
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('Contact');

        //Create dup contact Creation
        Contact contact2 = (Contact)TestDataFactory.createSObject(new Contact(
            AccountId = contact1.AccountId,
            Email='contact1@email.com',
            Firstname='john',
            LastName='test'
        ), true);
        SBQQ__Quote__c quote2 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__PrimaryContact__c = contact2.Id),true);
        System.enqueueJob(new EnableCCUsersForOfferAcceptance(new List<SBQQ__Quote__c>{quote2}, new Set<ID>{contact1.Id,contact2.Id})); 

        Test.stopTest();
    }
}