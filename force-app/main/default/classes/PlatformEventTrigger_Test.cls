/**
 * @description       : Test class for the Platform Event Trigger (framework) class
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2020-10-22
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-10-15   Stefan Scheit   Initial Version with comments
**/
@isTest(isParallel=true)
private class PlatformEventTrigger_Test {
    static Channel_Event__e channelEvent;
    static Channel__c channelRecord;

    /**
     * Test disable / enable the batch size control
     */
    @isTest
    static void testBindInsert() {
        // GIVEN: The trigger handler is initialised (for a particular type)
        PlatformEventTrigger trg = new PlatformEventTrigger();
        
        // WHEN: Batch size control is disabled
        Test.startTest();
        trg.disablePlatformEventControl();
        // THEN: It's flagged as disabled
        Assert.isFalse(trg.applyBatchSize, 'Disabling the batch-size failed.');

        // WHEN: Batch size control is enabled
        trg.enablePlatformEventControl();
        // THEN: It's flagged as re-enabled
        Assert.isTrue(trg.applyBatchSize, 'Re-enable the batch-size failed.');
        Test.stopTest();
    }
    /**
     * Dispatch platform event and validate execution of trigger handler.
     */
    @isTest
    static void testDispatchEvent() {
        // GIVEN: Data is present in the system (Contact, Channel)
        setupTestData();
        
        // WHEN: Platform event is inserted and published
        Test.startTest();
        Channel_Event__e v1 = channelEvent;
        EventBus.publish(v1);
        Test.getEventBus().deliver();
        
        // THEN: The Channel records is marked as processed
        Test.stopTest();
        Channel__c chTest = [SELECT Id, Is_Processed__c FROM Channel__c WHERE Id =: channelRecord.Id LIMIT 1].get(0);
        Assert.isTrue(chTest.Is_Processed__c, 'Channel platform event did not process.');
    }
    /**
     * Set up test data (Contact, Channel, Contact Point event)
     */
    private static void setupTestData() {
        // Create Comtact
        Contact contactRecord = new Contact();
        contactRecord.Person_ID_unique__c = '12345';
        contactRecord.Birthdate = Date.today().addYears(- 20);
        contactRecord.Citizenship__c = 'INTERNATIONAL';
        contactRecord.Citizenship_Code__c = '4';
        contactRecord.Residency_Status__c = 'Australian Permanent Resident';
        contactRecord.Email = 'test@test.com';
        contactRecord.Personal_Email__c = 'test@test.com';
        contactRecord.Monash_Email_Address__c = 'test@test.com';
        contactRecord.Business_Email_Address__c = 'test@test.com';
        contactRecord.Title = 'OAM';
        contactRecord.Salutation = 'Mr.';
        contactRecord.FirstName = 'testFirstName';
        contactRecord.MiddleName = 'testMiddleName';
        contactRecord.LastName = 'testLastName';
        contactRecord.Suffix = 'testSuffix';
        contactRecord.Gender__c = 'None';
        contactRecord.Phone = '+61390008000';
        contactRecord.MobilePhone = '+61400111222';
        contactRecord.HomePhone = '+61390008001';
        contactRecord.OtherPhone = '+61390008002';
        contactRecord.AssistantPhone = '+61390008003';
        contactRecord.Fax = '+61390008999';
        contactRecord.MailingStreet = '350 Bourke Street';
        contactRecord.MailingCity = 'Melbourne';
        contactRecord.MailingState = 'Victoria';
        contactRecord.MailingPostalCode = '3000';
        contactRecord.MailingCountry = 'Australia';
        contactRecord.OtherStreet = '111 Bourke Street';
        contactRecord.OtherCity = 'Melbourne';
        contactRecord.OtherState = 'Victoria';
        contactRecord.OtherPostalCode = '3000';
        contactRecord.OtherCountry = 'Australia';
        insert contactRecord;
        Assert.isNotNull(contactRecord.Id, 'Contact Record Insert Failed');

        // Create Channel
        channelRecord = new Channel__c(
            type__c = 'POSTAL',
            Contact__c = contactRecord.Id,
            Street__c = '55 Collin St',
            Post_Code__c = '3000',
            State__c = 'Vic',
            City__c = 'Melbourne',
            email__c='postal@email.com.au',
            Country__c = 'Australia');
        insert channelRecord;

        // Create contact point (but don't insert (yet))
        channelEvent = new Channel_Event__e();
        channelEvent.Channel_Id__c = channelRecord.Id;
        channelEvent.Contact_id__c = contactRecord.Id;
    }
}