/**
 * @author          P. Victoriano
 * @description     Test class to sanitise the email fields on Email__c records
 * @group			Sandbox Refresh  
 * @revision        20/08/2019 - P. Victoriano - Initial version 
 *                  03/01/2024 - Maritn Cadman - Check fields for monash and non-monash address handling
 */
@isTest(isParallel=true)
private class AgencyEmailUpdateBatch_Test {

    @isTest
    static void testGeneralEmail() {
        Account testAcc = new Account();
        testAcc.Name = 'TestMyAgentEmail';
        testAcc.Email__c = 'my.email.test@test.com';
        testAcc.Email_2__c = 'my.email2.test@test.com';
        testAcc.Email_3__c = 'my.email3.test@test.com';
        insert testAcc;

        Assert.isNotNull(testAcc.Id, 'Test Account could not be inserted.');

        Test.startTest();
            AgencyEmailUpdateBatch bch = new AgencyEmailUpdateBatch();
            Database.executeBatch(bch);
        Test.stopTest();

        account a = [SELECT Email__c,Email_2__c,Email_3__c FROM Account where id=:testAcc.id];
        
        Assert.isTrue(null==a.Email__c || a.email__c.startsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_PREFIX) || a.email__c.endsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_MONASH), 'Failed Cleansing Account Email -' +  + a.email__c);
        Assert.isTrue(null==a.Email_2__c || a.email_2__c.startsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_PREFIX) || a.email_2__c.endsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_MONASH), 'Failed Cleansing Account Email 2 -' + a.email_2__c);
        Assert.isTrue(null==a.Email_3__c || a.email_3__c.startsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_PREFIX) || a.email_3__c.endsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_MONASH), 'Failed Cleansing Account Email 3 -' + a.email_3__c);
    }
    
    @isTest
    static void testMonashEmail() {
        Account testAcc = new Account();
        testAcc.Name = 'TestMyFacultyEmail';
        testAcc.Email__c = 'my.email.test@monash.edu';
        testAcc.Email_2__c = 'my.email2.test@monash.edu';
        testAcc.Email_3__c = 'my.email3.test@monash.edu';
        insert testAcc;

        Assert.isNotNull(testAcc.Id, 'Test Account could not be inserted.');

        Test.startTest();
            AgencyEmailUpdateBatch bch = new AgencyEmailUpdateBatch();
            Database.executeBatch(bch);
        Test.stopTest();

        account a = [SELECT Email__c,Email_2__c,Email_3__c FROM Account where id=:testAcc.id];
        
        Assert.isTrue(null==a.Email__c || a.email__c.startsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_PREFIX) || a.email__c.endsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_MONASH), 'Failed Cleansing Account Email -' +  + a.email__c);
        Assert.isTrue(null==a.Email_2__c || a.email_2__c.startsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_PREFIX) || a.email_2__c.endsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_MONASH), 'Failed Cleansing Account Email 2 -' + a.email_2__c);
        Assert.isTrue(null==a.Email_3__c || a.email_3__c.startsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_PREFIX) || a.email_3__c.endsWithIgnoreCase(AgencyEmailUpdateBatch.MASKED_EMAIL_MONASH), 'Failed Cleansing Account Email 3 -' + a.email_3__c);
    }
}