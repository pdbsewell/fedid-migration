/**
 * @author          Stefan Scheit
 * @description     Test class to sanitise the email fields on Channel__c records
 * @group			Sandbox Refresh
 * @revision        13/12/2018 - Stefan Scheit - Initial version
 *                  03/01/2024 - Maritn cadman - Check fields for monash and non-monash address handling
 */
@isTest(isParallel=true)
public class ChannelEmailsUpdateBatch_Test
{
    @isTest
    static void testExecute()
    {
        // parent record
        Contact testContact = new Contact(Firstname='Stefan', Lastname='Test', Email='stefan.email.test@test.com', Personal_Email__c='stefan.email.personal@test.com', Monash_Email_Address__c='stefan.email.monash@monash.edu');
        insert testContact;
        Assert.isNotNull(testContact.id, 'Test contact could not be inserted.');

        // actual record
        Channel__c testChannel = new Channel__c(email__c='stefan.test.channel@test.com', contact__c=testContact.id, type__c='POSTAL');
        insert testChannel;
        Assert.isNotNull(testContact.id, 'Test channel could not be inserted.');

        Test.startTest();
        ChannelEmailsUpdateBatch channelBatch = new ChannelEmailsUpdateBatch();
        Database.executeBatch(channelBatch);
        Test.stopTest();

        Channel__c chan = [SELECT email__c FROM Channel__c WHERE Id=:testChannel.Id];
        Assert.isTrue(chan.email__c.startsWithIgnoreCase(ChannelEmailsUpdateBatch.MASKED_EMAIL_PREFIX), 'Channel__c.email__c field was not sanitised. The value is: '+chan.email__c);
    }
}