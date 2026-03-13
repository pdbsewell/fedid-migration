/**
 * @description     :   Test class for Contact : AS : Update Fields flow
 * @author          :   Sachin Shetty
 * @date            :   10-06-2025
 * @group           :   Platforms
 * @revision
 *  10-06-2025      Sachin Shetty    - EPCP-4497  Created test class to test the Contact : AS : Update Fields flow
 */ 
@isTest (isParallel = true)
public class ContactASUpdateFields_FT1 {
    /**
     * Test method validating a Contact with an empty/null Account lookup creates a new Account of type Individual.
     * Additionally, the Account owner is set to the Contact owner id.
     */
    @isTest
    static void testAssignStudentLayout() {
        
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        TriggerCommon.disableTrigger('Contact');
        
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName', 
                                    Lastname=testLastname,
                                	Person_ID_unique__c = '12345');
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        testContact = [SELECT id, RecordType.DeveloperName FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.isNotNull(testContact.id, 'Test contact has not been inserted successfully');
        Assert.areEqual('Student', testContact.RecordType.DeveloperName, 'Contact record type has to be Student');
    }
    
    /**
     * Test method validating a Contact with an empty/null Account lookup creates a new Account of type Individual.
     * Additionally, the Account owner is set to the Contact owner id.
     */
    @isTest
    static void testAssignNonStudentLayout() {
        
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        TriggerCommon.disableTrigger('Contact');
        
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Role Email Contact').getRecordTypeId());
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        testContact = [SELECT id, RecordType.DeveloperName FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.isNotNull(testContact.id, 'Test contact has not been inserted successfully');
        Assert.areEqual('Non_Student', testContact.RecordType.DeveloperName, 'Contact record type has to be Non Student');
    }
    
    /**
     * Test method validating a Contact with an empty/null Account lookup creates a new Account of type Individual.
     * Additionally, the Account owner is set to the Contact owner id.
     */
    @isTest
    static void testOptContactOutOfMarketing() {
        
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        TriggerCommon.disableTrigger('Contact');
        
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							Deceased__c = true);
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        testContact = [SELECT id, HasOptedOutOfEmail FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.isNotNull(testContact.id, 'Test contact has not been inserted successfully');
        Assert.isTrue(testContact.HasOptedOutOfEmail, 'If Deceased opt contact out of marketing');
    }
    
    /**
     * Test method validating a Contact with an empty/null Account lookup creates a new Account of type Individual.
     * Additionally, the Account owner is set to the Contact owner id.
     */
    /*@isTest
    static void testCorporateContactFalse() {
        
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        
        Id individualRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        Account testAccount = new Account(Name = 'Test Account', RecordTypeId = individualRecordTypeId);
        insert testAccount;
        
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							Deceased__c = true,
        							AccountId = testAccount.Id);
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('Account');
        
        testContact = [SELECT id, Is_Corporate_Contact__c, Is_Corporate_Contact_Result__c FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.isFalse(testContact.Is_Corporate_Contact__c, 'Contact should be Individual');
        Assert.isFalse(testContact.Is_Corporate_Contact_Result__c, 'Corporate Contact Result should be false');
    }*/
    
    @isTest
    static void testCorporateContactTrue() {
        
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        Country_Attribute__c country = new Country_Attribute__c();
        country.name = 'Australia';
        country.Country__c = 'Australia';
        country.callista_code__c = '7777';
        insert country;
        
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        
        //Id individualRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency').getRecordTypeId();
        Account testAccount = new Account
            					( Name = 'TestAgencyAU',
                                 Phone = '12345',
                                 Email__c = 'test@agency.com',
                                 Website = 'www.test-agency-1.com',
                                 Street__c = '123 testing st',
                                 City__c = 'Melbourne',
                                 State__c = 'VIC',
                                 Post_Code__c = '3000',
                                 Country_Lookup__c = country.Id,
                                 ShippingStreet = '123 testing st',
                                 ShippingCity = 'Melbourne',
                                 ShippingState = 'VIC',
                                 ShippingPostalCode = '3000',
                                 ShippingCountry = 'Australia',
                                 Monash_AM_Web_Status__c = true,
                                 Callista_Org_Unit_Code__c = 'TESTAU',
                                 Monash_AM_Campus__c = 'Australia',
                                 RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency').getRecordTypeId(),
                                 Status__c = 'Appointed'
                                );
        insert testAccount;
        
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							Deceased__c = true,
        							AccountId = testAccount.Id);
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('Account');
        
        testContact = [SELECT id, Is_Corporate_Contact__c, Is_Corporate_Contact_Result__c FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.isTrue(testContact.Is_Corporate_Contact__c, 'Contact should not be Individual');
        Assert.isTrue(testContact.Is_Corporate_Contact_Result__c, 'Corporate Contact Result should be true');
    }
    
    /**
     * Test method validating a Contact with an empty/null Account lookup creates a new Account of type Individual.
     * Additionally, the Account owner is set to the Contact owner id.
     */
    @isTest
    static void testMarketingStatusOptedOutDoNotCall() {
        
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        TriggerCommon.disableTrigger('Contact');
        
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							Deceased__c = true,
            						Marketing_Communications_Status__c = 'Opted in',
            						DoNotCall = True);
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.areEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should be Opted Out');
    }
    
    /**
     * Test method validating a Contact with an empty/null Account lookup creates a new Account of type Individual.
     * Additionally, the Account owner is set to the Contact owner id.
     */
    @isTest
    static void testMarketingStatusOptOutedEmailOptOut() {
        
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        TriggerCommon.disableTrigger('Contact');
        
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							Deceased__c = true,
            						Marketing_Communications_Status__c = 'Opted in',
            						HasOptedOutOfEmail = True);
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.areEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should be Opted Out');
    }
    
    /**
     * Test method validating a Contact with an empty/null Account lookup creates a new Account of type Individual.
     * Additionally, the Account owner is set to the Contact owner id.
     */
    @isTest
    static void testMarketingStatusOptedOutDeceased() {
        
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        TriggerCommon.disableTrigger('Contact');
        
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							Deceased__c = true,
            						Marketing_Communications_Status__c = 'Opted in',
            						HasOptedOutOfEmail = True);
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.areEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should be Opted Out');
    }
}