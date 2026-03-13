/**
 * @author          Stefan Scheit
 * @description     Test class to sanitise the email fields on Contact records
 * @group			Sandbox Refresh  
 * @revision        13/12/2018 - Stefan Scheit - Initial version
 *                  03/01/2024 - Maritn cadman - Check fields for monash and non-monash address handling
 */
@isTest(isParallel=true)
public class ContactEmailsUpdateBatch_Test
{
    @isTest
    static void testGeneralEmail()
    {
        Contact testContact = new Contact(Firstname='Stefan'
                                          , Lastname='Test'
                                          , Email='stefan.email.test@test.com'
                                          , Personal_Email__c='stefan.email.personal@test.com'
                                          , Monash_Email_Address__c='stefan.email.monash@monash.edu'
                                          , Applicant_Email_Address__c = 'stefan.email.personal@test.com'
                                          , previous_email__c = 'stefan.email.personal@test.com'
                                          , bulkapi_Email_Addresses__c = 'stefan.email.personal@test.com;stefan.email.monash@monash.edu;stefan.old.email@personal.com'
                                          , Email_Addresses__c = 'stefan.email.personal@test.com;stefan.email.monash@monash.edu'
                                          , Business_Email_Address__c = 'work@work.com'
                                          , Parent_Email__c = 'mum@home.com');
        insert testContact;
        Assert.isNotNull(testContact.id, 'Test contact could not be inserted.');

        Test.startTest();
        ContactEmailsUpdateBatch contactBatch = new ContactEmailsUpdateBatch();
        Database.executeBatch(contactBatch);
        Test.stopTest();

        Contact con = [SELECT Email, Personal_Email__c, Monash_Email_Address__c, Parent_Email__c, Business_Email_Address__c, Email_Addresses__c,bulkapi_Email_Addresses__c, previous_email__c, Applicant_Email_Address__c FROM Contact WHERE Id=:testContact.Id];
        // Contact.Email can be set (through trigger) by either Personal_Email__c or Monash_Email_Address__c
        Assert.isTrue(null==con.Email || con.Email.startsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || con.Email.endsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Contact.Email field was not sanitised. The value is: '+con.Email);
        Assert.isTrue(null==con.Personal_Email__c || con.Personal_Email__c.startsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_PREFIX), 'Contact.Personal_Email__c field was not sanitised. The value is: '+con.Personal_Email__c);
        Assert.isTrue(null==con.Applicant_Email_Address__c || con.Applicant_Email_Address__c.startsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_PREFIX), 'Contact.Applicant_Email_Address__c field was not sanitised. The value is: '+con.Applicant_Email_Address__c);
        Assert.isTrue(null==con.previous_email__c || con.previous_email__c.startsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_PREFIX), 'Contact.previous_email__c field was not sanitised. The value is: '+con.previous_email__c);
        Assert.isTrue(null==con.Business_Email_Address__c || con.Business_Email_Address__c.startsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_PREFIX), 'Contact.Business_Email_Address__c field was not sanitised. The value is: '+con.Business_Email_Address__c);
        Assert.isTrue(null==con.Parent_Email__c  || con.Parent_Email__c.startsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_PREFIX), 'Contact.Parent_Email__c field was not sanitised. The value is: '+con.Parent_Email__c);
        Assert.isTrue(null==con.Monash_Email_Address__c || con.Monash_Email_Address__c.endsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Contact.Monash_Email_Address__c field was not sanitised. The value is: '+con.Monash_Email_Address__c);

		Assert.isTrue(null==con.bulkapi_Email_Addresses__c || con.Email==con.bulkapi_Email_Addresses__c, 'bulkapi_Email_Addresses__c field was not sanitised. The value is: '+con.bulkapi_Email_Addresses__c);
        Assert.isTrue(null==con.Email_Addresses__c || con.Email==con.Email_Addresses__c, 'Email_Addresses__c field was not sanitised. The value is: '+con.Email_Addresses__c);
    }

    @isTest
    static void testMonashEmail()
    {
        Contact testContact = new Contact(Firstname='Stefan'
                                          , Lastname='Test'
                                          , Email='stefan.email.monash@student.monash.edu'
                                          , Monash_Email_Address__c='stefan.email.monash@student.monash.edu'
                                          , previous_email__c = 'stefan.email.monash@student.monash.edu'
                                          , Business_Email_Address__c = 'stefan.email.monash@student.monash.edu'
                                          , Parent_Email__c = 'mum@monash.edu');
        insert testContact;
        Assert.isNotNull(testContact.id, 'Test contact could not be inserted.');

        Test.startTest();
        ContactEmailsUpdateBatch contactBatch = new ContactEmailsUpdateBatch();
        Database.executeBatch(contactBatch);
        Test.stopTest();

        Contact con = [SELECT Email, Personal_Email__c, Monash_Email_Address__c, Parent_Email__c, Business_Email_Address__c, Email_Addresses__c,bulkapi_Email_Addresses__c, previous_email__c, Applicant_Email_Address__c FROM Contact WHERE Id=:testContact.Id];
        // Contact.Email can be set (through trigger) by either Personal_Email__c or Monash_Email_Address__c
        Assert.isTrue(null==con.Email || con.Email.startsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || con.Email.endsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Contact.Email field was not sanitised. The value is: '+con.Email);
        Assert.isTrue(null==con.previous_email__c || con.previous_email__c.endsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_MONASH) , 'Contact.previous_email__c field was not sanitised. The value is: '+con.previous_email__c);
        Assert.isTrue(null==con.Business_Email_Address__c || con.Business_Email_Address__c.endsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Contact.Business_Email_Address__c field was not sanitised. The value is: '+con.Business_Email_Address__c);
        Assert.isTrue(null==con.Parent_Email__c  || con.Parent_Email__c.endsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Contact.Parent_Email__c field was not sanitised. The value is: '+con.Parent_Email__c);
        Assert.isTrue(null==con.Monash_Email_Address__c || con.Monash_Email_Address__c.endsWithIgnoreCase(ContactEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Contact.Monash_Email_Address__c field was not sanitised. The value is: '+con.Monash_Email_Address__c);
    }
}