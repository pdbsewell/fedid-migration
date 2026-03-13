/**
 * @description Test class for SObjectMockBuilder
 */
@isTest(isParallel=true)
public class SObjectMockBuilderTest {

    /*
    This test class uses only standard Salesforce object/fields to ensure the 
    unit tests can run regardless of the org settings/licenses/permissions.
    */

    @isTest
    static void shouldBeAbleToCreateAccountRecordWithTextField() {
        SObjectMockBuilder accountBuilder = new SObjectMockBuilder(Account.class);
        Account accountCreated = (Account) accountBuilder
            .with(Account.Name, 'Test Account')
            .create();
        System.assertEquals(
            'Test Account', 
            accountCreated.Name, 
            'Expected Account name to be set correctly.'
        );
    }

    @isTest
    static void shouldBeAbleToCreateAccountRecordWithTwoTextField() {
        SObjectMockBuilder accountBuilder = new SObjectMockBuilder(Account.class);
        Account accountCreated = (Account) accountBuilder
            .with(Account.Name, 'Test Account')
            .with(Account.SicDesc, 'SIC')
            .create();
        System.assertEquals(
            'Test Account', 
            accountCreated.Name, 
            'Expected Account name to be set correctly.'
        );
        System.assertEquals(
            'SIC', 
            accountCreated.SicDesc, 
            'Expected Account SicDesc to be set correctly.'
        );
    }

    @isTest
    static void shouldBeAbleToCreateAccountRecordWithNumberField() {
        SObjectMockBuilder accountBuilder = new SObjectMockBuilder(Account.class);
        Account accountCreated = (Account) accountBuilder
            .with(Account.NumberOfEmployees, 25)
            .create();
        System.assertEquals(
            25, 
            accountCreated.NumberOfEmployees, 
            'Expected Account NumberOfEmployees to be set correctly.'
        );
    }

    @isTest
    static void shouldBeAbleToCreateAccountRecordWithPicklistField() {
        SObjectMockBuilder accountBuilder = new SObjectMockBuilder(Account.class);
        Account accountCreated = (Account) accountBuilder
            .with(Account.Industry, 'Aerospace')
            .create();
        System.assertEquals(
            'Aerospace', 
            accountCreated.Industry, 
            'Expected Account Industry to be set correctly.'
        );
    }

    @isTest
    static void shouldBeAbleToCreateAccountRecordWithCheckboxField() {
        SObjectMockBuilder accountBuilder = new SObjectMockBuilder(Account.class);
        Account accountCreated = (Account) accountBuilder
            .with(Account.IsCustomerPortal, true)
            .create();
        System.assertEquals(
            true, 
            accountCreated.IsCustomerPortal, 
            'Expected Account IsCustomerPortal checkbox to be set correctly.'
        );
    }

    @isTest
    static void shouldBeAbleToCreateAccountRecordWithId() {
        Id accountId = FakeRecordIdGenerator.generateId(Account.getSObjectType());
        
        SObjectMockBuilder accountBuilder = new SObjectMockBuilder(Account.class);
        Account accountCreated = (Account) accountBuilder
            .with(Account.Id, accountId)
            .create();
        System.assertEquals(
            accountId, 
            accountCreated.Id, 
            'Expected Id to to be set correctly on Account record.'
        );
    }

    @isTest
    static void shouldBeAbleToCreateContactRecordWithAccountId() {
        Id accountId = FakeRecordIdGenerator.generateId(Account.getSObjectType());
        
        SObjectMockBuilder contactBuilder = new SObjectMockBuilder(Contact.class);
        Contact contactCreated = (Contact) contactBuilder
            .with(Contact.AccountId, accountId)
            .create();
        System.assertEquals(
            accountId, 
            contactCreated.AccountId, 
            'Expected Contact AccountId to be set correctly.'
        );
    }

    @isTest
    static void shouldBeAbleToCreateRecordWithParentLookupWithParentSObjectMockBuilder() {
        SObjectMockBuilder contactBuilder = new SObjectMockBuilder(Contact.class);
        Contact contactCreated = (Contact) contactBuilder
            .withParentRelationship(
                Contact.AccountId, 
                new SObjectMockBuilder(Account.class)
                    .with(Account.Name, 'Test Account')
                    .create()
            )
            .create();
        System.assertEquals(
            'Test Account', 
            contactCreated.Account.Name, 
            'Expected Contact parent account name to be retrieved'
        );
    }

    @isTest
    static void shouldBeAbleToCreateRecordWithParentLookup() {
        SObjectMockBuilder contactBuilder = new SObjectMockBuilder(Contact.class);
        Contact contactCreated = (Contact) contactBuilder
            .withParentRelationship(
                Contact.AccountId, 
                new Account(
                    name = 'Test Account'
                )
            )
            .create();
        System.assertEquals(
            'Test Account', 
            contactCreated.Account.Name, 
            'Expected Contact parent account name to be retrieved'
        );
    }

    @isTest
    static void shouldBeAbleToCreateRecordWithParentLookupWithParentFieldAndRefId() {
        Id accountId = FakeRecordIdGenerator.generateId(Account.getSObjectType());
        
        SObjectMockBuilder contactBuilder = new SObjectMockBuilder(Contact.class);
        Contact contactCreated = (Contact) contactBuilder
            .withParentRelationship(
                Contact.AccountId, 
                new SObjectMockBuilder(Account.class)
                    .with(Account.Id, accountId)
                    .with(Account.Name, 'Test Account')
                    .create()
            )
            .with(Contact.AccountId, accountId)
            .create();
        System.assertEquals(
            'Test Account', 
            contactCreated.Account.Name, 
            'Expected Contact parent account name to be retrieved'
        );
        System.assertEquals(
            accountId, 
            contactCreated.AccountId, 
            'Expected Contact account Id to be retrieved'
        );
    }

}