/**
 * @description       : Test Class for FundingTriggerHandler
 * @author            : Angelo Rivera
 * @group             : Engage Enterprise
 * @version           : Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   04-10-2023     Angelo Rivera       Initial Creation
**/

@IsTest(IsParallel=false) // System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests
private class FundingTriggerHandler_Test {

    /*
     * @description     This is to setup the data for the test class
     */
@TestSetup
static void setupData(){

    String random = String.valueOf(System.currentTimeMillis());
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Insert a new User

    System.runAs(thisUser) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Enterprise Base Profile' LIMIT 1];
        User user = new User(
                Username = random + 'testusername@testemail.com',
                FirstName = 'TestFirstName',
                LastName = 'TestLast',
                Alias = 'ssoxtst8',
                Email = random + 'testusername@testemail.com',
                ProfileId = profile.Id,
                IsActive = true,
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'Australia/Sydney',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
        );

        Database.insert(user); // Avoid mixed DML error

        PermissionSet enterpUserPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Enterprise_Base'];

        PermissionSetAssignment permSet1 = new PermissionSetAssignment(AssigneeId=user.Id,PermissionSetId=enterpUserPermSet.Id);
        insert permSet1;
    }
}

/*
 * @description     This method will verify the External ID field in Funding record will be populated correctly during creation
 *  Expected result: UID__c field will be populated
 *
 * GIVEN an enterprise opportunity
 * WHEN Enterprise user creates a funding record
 * THEN UID__c field will be populated
 */
    @IsTest
    static void testBehavior() {
        User enterpriseUser = [SELECT Id, IsActive, Profile.Name FROM User WHERE Profile.Name = 'Enterprise Base Profile' AND IsActive = TRUE LIMIT 1];

        System.runAs(enterpriseUser){
            String testname= 'name '+String.valueOf(System.now());
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId();

            List<Account> listAccounts = new List<Account>{new Account(Name='testname2',RecordTypeId=recordTypeId), new Account(Name=testname,RecordTypeId=recordTypeId) };
            insert listAccounts;
            Contact contact = (Contact)TestDataFactory.createSObject(new Contact(LastName='Con1',AccountId = listAccounts.get(0).Id), true);

            Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = listAccounts.get(0).Id, PrimaryContact__c = contact.Id) ,false);
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
            insert opp;

            Test.startTest();
            Funding__c newFunding = new Funding__c();
            newFunding.Opportunity__c = opp.Id;
            newFunding.Funder__c = listAccounts.get(1).Id;
            newFunding.PURE_Application_ID__c = '1234568';
            newFunding.Applied_Amount__c = 0;
            newFunding.Discount_Amount__c = 100;
            newFunding.Discount__c = 10;
            newFunding.Awarded_Amount__c = 0;
            newFunding.Funding_Description__c = 'Test Description';
            newFunding.Primary_Funder__c = false;
            newFunding.Funding_Type__c = 'Financial';
            upsert newFunding;
            Test.stopTest();

            List<Funding__c> opcList =[SELECT Id, Funder__c, Opportunity__c, UID__c FROM Funding__c WHERE PURE_Application_ID__c = '1234568' LIMIT 1];
            System.assertEquals(opcList[0].UID__c, opcList[0].Opportunity__c + '' + opcList[0].Funder__c + 'Financialfalse', 'Updating External Id failed.');
        }

    }
}