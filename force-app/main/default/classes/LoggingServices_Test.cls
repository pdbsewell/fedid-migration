/**
* @author KL
* @date 29.07.2020
*
* @group Duplicate Management
*
* @description Sibling test class for service class providing features needed for Duplicate Management
*
* @revision
*           29.07.2020 - KL: Initial Create
*/
@isTest(isParallel=true)
public class LoggingServices_Test {

    @testSetup static void setup() {

        //Create test contact 1
        Contact testContact = new Contact();
        testContact.FirstName = 'Test FirstName';
        testContact.LastName = 'Test LastName';
        testContact.MobilePhone = '0481977625';
        testContact.Email = 'testemail001@monash.edu';
        testContact.Monash_Email_Address__c = 'testemailmonash@monash.edu';
        testContact.Birthdate = Date.today().addYears(-11);
        testContact.SAP_Staff_Id__c = '';
        insert testContact;
        System.debug('testContact.Id = ' + testContact.Id);
        System.assert(testContact.Id != null, '### Insert Test Contact Failed.');

        //Create test contact 2
        Contact testContactDup = new Contact();
        testContactDup.FirstName = 'Test FirstName';
        testContactDup.LastName = 'Test LastName';
        testContactDup.MobilePhone = '0481977625';
        testContactDup.Email = 'testemail001@monash.edu';
        testContactDup.Birthdate = Date.today().addYears(-11);
        testContactDup.SAP_Staff_Id__c = '';
        insert testContactDup;
        System.debug('testContactDup.Id = ' + testContactDup.Id);
        System.assert(testContactDup.Id != null, '### Insert Test Contact Dup Failed.');

    }

    static testMethod void testLogAccountPreMerge() {

        Test.startTest();

        Contact masterCon = [
            SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, AccountId
            FROM Contact 
            WHERE Email = 'testemail001@monash.edu' 
            AND Monash_Email_Address__c = 'testemailmonash@monash.edu'
            LIMIT 1];

        Contact contact = [
            SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, AccountId
            FROM Contact 
            WHERE Email = 'testemail001@monash.edu' 
            AND Monash_Email_Address__c = null
            LIMIT 1];

        Account masterAccount = [
            SELECT Id, Name 
            FROM Account 
            WHERE Id = :masterCon.AccountId
            LIMIT 1];

        Account accountToMerge = [
            SELECT Id, Name 
            FROM Account 
            WHERE Id = :contact.AccountId
            LIMIT 1];

        List<Async_Process__e> accountMergeEventsToPub = new List<Async_Process__e>();
        Async_Process__e accountMergeEvt = TaskDupCheckHelper.createAccountMergePayload(masterAccount, accountToMerge);
        accountMergeEventsToPub.add(accountMergeEvt);
        EventBus.publish(accountMergeEventsToPub);

        Test.stopTest();
        
        List<Exception_Log__c> exRecs = [
            SELECT Id, Exception_Type__c, Function_Name__c, Source_Type__c 
            FROM Exception_Log__c
            WHERE Exception_Type__c = 'INFO'
            AND Function_Name__c = 'TaskDupCheckHelper.init'
            AND Source_Type__c = 'Account Merge'];
        System.debug('exRecs.size() = ' + exRecs.size());
        System.assertNotEquals(0, exRecs.size(), 'No Account pre-merge INFO exception record found, functionality failed...');

    }

    static testMethod void testLogContactPreMerge() {

        Test.startTest();

        Contact masterCon = [
            SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, AccountId
            FROM Contact 
            WHERE Email = 'testemail001@monash.edu' 
            AND Monash_Email_Address__c = 'testemailmonash@monash.edu'
            LIMIT 1];

        Contact contact = [
            SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, AccountId
            FROM Contact 
            WHERE Email = 'testemail001@monash.edu' 
            AND Monash_Email_Address__c = null
            LIMIT 1];

        List<Async_Process__e> contactMergeEventsToPub = new List<Async_Process__e>();
        Async_Process__e contactMergeEvt = TaskDupCheckHelper.createContactMergePayload(masterCon, contact);
        contactMergeEventsToPub.add(contactMergeEvt);
        EventBus.publish(contactMergeEventsToPub);

        Test.stopTest();

        List<Exception_Log__c> exRecs = [
            SELECT Id, Exception_Type__c, Function_Name__c, Source_Type__c 
            FROM Exception_Log__c
            WHERE Exception_Type__c = 'INFO'
            AND Function_Name__c = 'TaskDupCheckHelper.init'
            AND Source_Type__c = 'Contact Merge'];
        System.debug('exRecs.size() = ' + exRecs.size());
        System.assertNotEquals(0, exRecs.size(), 'No Contact pre-merge INFO exception record found, functionality failed...');

    }

}