/**
 * @author          Martin Cadman
 * @description     Test class to sanitise the email fields on Lead records
 * @group			Sandbox Refresh  
 * @revision        28/05/2024 - Martin Cadman - Initial version 
 */
@isTest(isParallel=true)
public class LeadEmailsUpdateBatch_Test {

    // Test that non-monash addresses are obfiscated
    @isTest
    static void testGeneralLead() {
        Lead aLead = new Lead (email = 'lead@email.com', Parent_Guardian_Email__c = 'parentlead@monash.edu', lastname = 'Smith', company = '3s a crowd');
        insert aLead;
		Assert.isNotNull(aLead.id, 'Test case could not be inserted');

        Test.startTest();
        LeadEmailsUpdateBatch leadBatch = new LeadEmailsUpdateBatch();
        Database.executeBatch(leadBatch);
        Test.stopTest();

        aLead = [Select email, Parent_Guardian_Email__c from lead where id = :aLead.id];
        Assert.isTrue(null==aLead.email || aLead.email.startsWithIgnoreCase(LeadEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || aLead.email.endsWithIgnoreCase(LeadEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Lead.Email field was not sanitised. The value is: '+aLead.Email);
        Assert.isTrue(null==aLead.Parent_Guardian_Email__c || aLead.Parent_Guardian_Email__c.startsWithIgnoreCase(LeadEmailsUpdateBatch.MASKED_EMAIL_PREFIX) || aLead.Parent_Guardian_Email__c.endsWithIgnoreCase(LeadEmailsUpdateBatch.MASKED_EMAIL_MONASH), 'Lead.Parent_Guardian_Email__c field was not sanitised. The value is: '+aLead.Parent_Guardian_Email__c);
       
    }

}