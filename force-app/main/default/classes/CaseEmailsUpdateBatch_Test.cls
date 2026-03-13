/**
 * @author          Martin Cadman
 * @description     Test class to sanitise the email fields on Case records
 * @group			Sandbox Refresh  
 * @revision        01/12/2023 - Martin Cadman - Initial version 
 *                  03/01/2024 - Maritn Cadman - Check fields for monash and non-monash address handling
 */
@isTest(isParallel=true)
public class CaseEmailsUpdateBatch_Test {

    // Test that non-monash addresses are obfiscated
    @isTest
    static void testGeneralEmail()
    {
        
        Case testCase = new Case (SuppliedEmail = 'stefan.email.test@test.com'
                                  , Supplied_Supervisors_Email__c= 'stefan.email.test@test.com'
                                  , Faculty_Email__c= 'stefan.email.test@test.com'
                                  , External_Stakeholder_Email__c= 'stefan.email.test@test.com'
                                  , Email_To__c= 'stefan.email.test@test.com'
                                  , Default_AskMonash_Email__c= 'stefan.email.test@test.com'
                                 );
        
        insert testCase;
        Assert.isNotNull(testCase.id, 'Test case could not be inserted.');

        Test.startTest();
        CaseEmailsUpdateBatch caseBatch = new CaseEmailsUpdateBatch();
        Database.executeBatch(caseBatch);
        Test.stopTest();

        Case c = [SELECT Id, SuppliedEmail, Supplied_Supervisors_Email__c, Faculty_Email__c, External_Stakeholder_Email__c, Email_To__c, Default_AskMonash_Email__c from case where id=:testcase.id];
        Assert.isTrue(null==c.SuppliedEmail || c.SuppliedEmail.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.SuppliedEmail.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.SuppliedEmail field was not sanitised. The value is: '+c.SuppliedEmail);
        Assert.isTrue(null==c.Supplied_Supervisors_Email__c || c.Supplied_Supervisors_Email__c.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.Supplied_Supervisors_Email__c.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.Supplied_Supervisors_Email__c field was not sanitised. The value is: '+c.SuppliedEmail);
        Assert.isTrue(null==c.Faculty_Email__c || c.Faculty_Email__c.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.Faculty_Email__c.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.Faculty_Email__c field was not sanitised. The value is: '+c.SuppliedEmail);
        Assert.isTrue(null==c.External_Stakeholder_Email__c || c.External_Stakeholder_Email__c.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.External_Stakeholder_Email__c.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.External_Stakeholder_Email__c field was not sanitised. The value is: '+c.SuppliedEmail);
        Assert.isTrue(null==c.Email_To__c || c.Email_To__c.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.Email_To__c.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.Email_To__c field was not sanitised. The value is: '+c.SuppliedEmail);
        Assert.isTrue(null==c.Default_AskMonash_Email__c || c.Default_AskMonash_Email__c.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.Default_AskMonash_Email__c.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.Default_AskMonash_Email__c field was not sanitised. The value is: '+c.SuppliedEmail);

    }

    // Test that monash addresses are obfiscated
    @isTest
    static void testMonashEmail()
    {
        
        Case testCase = new Case (SuppliedEmail = 'stefan.email.test@monash.edu'
                                  , Supplied_Supervisors_Email__c= 'stefan.email.test@monash.edu'
                                  , Faculty_Email__c= 'stefan.email.test@monash.edu'
                                  , External_Stakeholder_Email__c= 'stefan.email.test@monash.edu'
                                  , Email_To__c= 'stefan.email.test@monash.edu'
                                  , Default_AskMonash_Email__c= 'stefan.email.test@monash.edu'
                                 );
        
        insert testCase;
        Assert.isNotNull(testCase.id, 'Test case could not be inserted.');

        Test.startTest();
        CaseEmailsUpdateBatch caseBatch = new CaseEmailsUpdateBatch();
        Database.executeBatch(caseBatch);
        Test.stopTest();

        Case c = [SELECT Id, SuppliedEmail, Supplied_Supervisors_Email__c, Faculty_Email__c, External_Stakeholder_Email__c, Email_To__c, Default_AskMonash_Email__c from case where id=:testcase.id];
        Assert.isTrue(null==c.SuppliedEmail || c.SuppliedEmail.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.SuppliedEmail.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.SuppliedEmail field was not sanitised. The value is: '+c.SuppliedEmail);
        Assert.isTrue(null==c.Supplied_Supervisors_Email__c || c.Supplied_Supervisors_Email__c.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.Supplied_Supervisors_Email__c.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.Supplied_Supervisors_Email__c field was not sanitised. The value is: '+c.SuppliedEmail);
        Assert.isTrue(null==c.Faculty_Email__c || c.Faculty_Email__c.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.Faculty_Email__c.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.Faculty_Email__c field was not sanitised. The value is: '+c.SuppliedEmail);
        Assert.isTrue(null==c.External_Stakeholder_Email__c || c.External_Stakeholder_Email__c.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.External_Stakeholder_Email__c.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.External_Stakeholder_Email__c field was not sanitised. The value is: '+c.SuppliedEmail);
        Assert.isTrue(null==c.Email_To__c || c.Email_To__c.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.Email_To__c.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.Email_To__c field was not sanitised. The value is: '+c.SuppliedEmail);
        Assert.isTrue(null==c.Default_AskMonash_Email__c || c.Default_AskMonash_Email__c.startsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || c.Default_AskMonash_Email__c.endsWithIgnoreCase(CaseEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Case.Default_AskMonash_Email__c field was not sanitised. The value is: '+c.SuppliedEmail);
    }
}