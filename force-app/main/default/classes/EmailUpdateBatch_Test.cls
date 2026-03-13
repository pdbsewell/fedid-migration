/**
 * @author          P. Victoriano
 * @description     Test class to sanitise the email fields on Email__c records
 * @group			Sandbox Refresh  
 * @revision        20/08/2019 - P. Victoriano - Initial version 
 *                  03/01/2024 - Maritn Cadman - Check fields for monash and non-monash address handling
 */
@isTest(isParallel=true)
public class EmailUpdateBatch_Test {

    @isTest
    static void testGeneralEmail() {
        contact testContact = new Contact(lastname='Smith');
        insert testContact;
        
    	email__c testEmail = new Email__c(name='general@email.com', classification__c='Private', contact__c=testContact.id);
        
        insert testEmail;
        Assert.isNotNull(testEmail.id, 'Test Email could not be inserted.');

        Test.startTest();
        EmailUpdateBatch bch = new EmailUpdateBatch();
        Database.executeBatch(bch);
        Test.stopTest();
        
        email__c e = [SELECT Id, name from email__c where id=:testEmail.id];
        Assert.isTrue(null==e.name || e.name.startsWithIgnoreCase(EmailUpdateBatch.MASKED_EMAIL_PREFIX), 'Email__c.name field was not sanitised. The value is: '+e.name);
    }

    @isTest
    static void testMonashEmail() {
        contact testContact = new Contact(lastname='Smith');
        insert testContact;

    	email__c testEmail = new Email__c(name='school@monash.edu', classification__c='Monash', contact__c=testContact.id);
        
        insert testEmail;
        Assert.isNotNull(testEmail.id, 'Test Email could not be inserted.');
        
        Test.startTest();
        EmailUpdateBatch bch = new EmailUpdateBatch();
        Database.executeBatch(bch);
        Test.stopTest();

        email__c e = [SELECT Id, name from email__c where id=:testEmail.id];
        Assert.isTrue(null==e.name || e.name.endsWithIgnoreCase(EmailUpdateBatch.MASKED_EMAIL_MONASH), 'Email__c.name field was not sanitised. The value is: '+e.name);
    }
}