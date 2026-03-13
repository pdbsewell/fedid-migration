/**
 * @author          Stefan Scheit
 * @description     Batch class to sanitise the name fields on Contact records (e.g in sandbox refreshes)
 * @group			Sandbox Refresh  
 * @revision        12/12/2018 - Stefan Scheit - Initial version
 *                  03/01/2024 - Maritn Cadman - Extended email field coverage and disabled non-UCI automation
 *                  05/01/2024 - Maritn Cadman - Added runIsolated constructor etc
 */
public class ContactEmailsUpdateBatch implements Database.Batchable<sObject>, Database.stateful {

    private Boolean runIsolated = false;
    public static final String MASKED_EMAIL_MONASH = '@idmqat.monash.edu';
    public static final String MASKED_EMAIL_PREFIX = 'test_';

    private String originalTransactionId;
    private integer totalUpdates = 0;
    private integer totalErrors = 0;
    private static final String EVENTTAG = 'Contact Email Obfuscation';
    private static final String SCENARIO = 'Sandbox Refresh';
    
    public ContactEmailsUpdateBatch () {
        this.runIsolated = false;
    }
    
    public ContactEmailsUpdateBatch (Boolean runIsolated) {
        this.runIsolated = runIsolated;
    }

   /**
    * Implement start method (from interface) to create a query and return the QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
		this.originalTransactionId = nebula.Logger.getTransactionId();
        nebula.Logger.setScenario(SCENARIO);       
        nebula.Logger.setAsyncContext(bc);

        // Exclue all empty or already modified email values
        String escapedEmailMonash = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(MASKED_EMAIL_MONASH);
        String escapedEmailPrefix = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(MASKED_EMAIL_PREFIX);
        
        String queryDetail = 'SELECT Id, Monash_Email_Address__c,Email, Personal_Email__c, Parent_Email__c, Previous_Email__c, Applicant_Email_Address__c, Business_Email_Address__c ';
        String queryCount = 'SELECT count() ';
        
        String queryCriteria = '   FROM Contact  ' +
                       '   WHERE (Email!=null AND ((NOT Email LIKE \''+escapedEmailPrefix+'%\') AND (NOT Email LIKE \'%'+escapedEmailMonash+'\'))) ' +
                       '   OR (Personal_Email__c!=null AND (NOT Personal_Email__c LIKE \''+escapedEmailPrefix+'%\')) ' +
                       '   OR (Monash_Email_Address__c!=null AND (NOT Monash_Email_Address__c LIKE \'%'+escapedEmailMonash+'\')) ' +
                       '   OR (Parent_Email__c!=null AND ((NOT Parent_Email__c LIKE \''+escapedEmailPrefix+'%\') AND (NOT Parent_Email__c LIKE \'%'+escapedEmailMonash+'\'))) ' +
                       '   OR (Previous_Email__c!=null AND ((NOT Previous_Email__c LIKE \''+escapedEmailPrefix+'%\') AND (NOT Previous_Email__c LIKE \'%'+escapedEmailMonash+'\'))) ' +
                       '   OR (Applicant_Email_Address__c!=null AND ((NOT Applicant_Email_Address__c LIKE \''+escapedEmailPrefix+'%\') AND (NOT Applicant_Email_Address__c LIKE \'%'+escapedEmailMonash+'\'))) ' +
                       '   OR (Business_Email_Address__c!=null AND ((NOT Business_Email_Address__c LIKE \''+escapedEmailPrefix+'%\') AND (NOT Business_Email_Address__c LIKE \'%'+escapedEmailMonash+'\')))';

        queryCount = queryCount + queryCriteria;
        queryDetail = queryDetail +  + queryCriteria;

        Integer totalRecords = Database.countQuery(queryCount);
		nebula.logger.info('Contact records for processing: ' + totalRecords + ' \r' + queryDetail).addTag(EVENTTAG);
        nebula.logger.saveLog();
        
        //return results to process only if the current instance is a sandbox or a test is running
        Boolean sandbox;
        for(Organization o:[SELECT isSandbox FROM Organization LIMIT 1]) {
            sandbox = o.isSandbox;
        }
        if(sandbox && Test.isRunningTest() == false) {
            return Database.getQueryLocator(queryDetail);
        } else if (Test.isRunningTest()) {
            return Database.getQueryLocator(queryDetail + ' LIMIT 1');
        } else {
            // avoid running in production environment
            return Database.getQueryLocator(queryDetail + ' LIMIT 0');
        }
    }

   /**
    * Implement execute method (from interface) to run the business logic
    */
    public void execute(Database.BatchableContext bc, List<Sobject> scope) {
        nebula.Logger.setAsyncContext(bc);
        nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        nebula.Logger.setScenario(SCENARIO);       
        
        List<Contact> updateContactList = new List<Contact>();
        // evaluate each Contact's email fields and sanitise
        for (Contact iContact : (List<Contact>) scope) {

            if(String.isNotBlank(iContact.Email) 
                && !iContact.Email.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
                && !iContact.Email.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                if (EmailServices.isMonashEmail(iContact.Email)) {
                    iContact.Email = iContact.Email.substringBefore('@') + MASKED_EMAIL_MONASH;
                } else {
                    iContact.Email = MASKED_EMAIL_PREFIX + iContact.Email;
                }
            }

            if(String.isNotBlank(iContact.Personal_Email__c) && !iContact.Personal_Email__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                // prefix email
                iContact.Personal_Email__c = MASKED_EMAIL_PREFIX + iContact.Personal_Email__c;
            }
            
            if(String.isNotBlank(iContact.Monash_Email_Address__c) && !iContact.Monash_Email_Address__c.endsWithIgnoreCase(MASKED_EMAIL_MONASH)) {
                // change email domain
                iContact.Monash_Email_Address__c = iContact.Monash_Email_Address__c.substringBefore('@') + MASKED_EMAIL_MONASH;
            }
            
            if(String.isNotBlank(iContact.Previous_Email__c) 
                && !iContact.Previous_Email__c.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
                && !iContact.Previous_Email__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                if (EmailServices.isMonashEmail(iContact.Previous_Email__c)) {
                    iContact.Previous_Email__c = iContact.Previous_Email__c.substringBefore('@') + MASKED_EMAIL_MONASH;
                } else {
                    iContact.Previous_Email__c = MASKED_EMAIL_PREFIX + iContact.Previous_Email__c;
                }
            }

            if(String.isNotBlank(iContact.Parent_Email__c) 
                && !iContact.Parent_Email__c.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
                && !iContact.Parent_Email__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                if (EmailServices.isMonashEmail(iContact.Parent_Email__c)) {
                    iContact.Parent_Email__c = iContact.Parent_Email__c.substringBefore('@') + MASKED_EMAIL_MONASH;
                } else {
                    iContact.Parent_Email__c = MASKED_EMAIL_PREFIX + iContact.Parent_Email__c;
                }
            }            

            if(String.isNotBlank(iContact.Applicant_Email_Address__c) && !iContact.Applicant_Email_Address__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                // prefix email
                iContact.Applicant_Email_Address__c = MASKED_EMAIL_PREFIX + iContact.Applicant_Email_Address__c;
            }
            
            if(String.isNotBlank(iContact.Business_Email_Address__c) 
                && !iContact.Business_Email_Address__c.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
                && !iContact.Business_Email_Address__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                if (EmailServices.isMonashEmail(iContact.Business_Email_Address__c)) {
                    iContact.Business_Email_Address__c = iContact.Business_Email_Address__c.substringBefore('@') + MASKED_EMAIL_MONASH;
                } else {
                    iContact.Business_Email_Address__c = MASKED_EMAIL_PREFIX + iContact.Business_Email_Address__c;
                }
            } 
           
            // just keeping it simple
            iContact.bulkapi_Email_Addresses__c = iContact.Email;
			iContact.Email_Addresses__c = iContact.Email;
            
            updateContactList.add(iContact);
        }
        
        if(updateContactList.size()>0) {
            Bypass_Mute_Request__c oldCustomSetting = Bypass_Mute_Request__c.getInstance();
            Bypass_Mute_Request__c customSetting = Bypass_Mute_Request__c.getInstance();
            customSetting.Bypass_All_Flows__c = true;
            customSetting.Bypass_All_Process__c = true;
            customSetting.Bypass_All_Validation_Rules__c = true;
            customSetting.Bypass_All_Triggers__c = true;
            upsert customSetting;

            
            TriggerCommon.disableTrigger('Contact');
            List<Database.SaveResult> srList = Database.update(updateContactList, false); // allOrNothing=false
            totalUpdates += updateContactList.size();
            for(Integer i=0; i<srList.size(); i++) {
                Database.SaveResult sr = srList[i];
                if (!sr.isSuccess()) {
					for (Database.Error err : sr.getErrors()) {
						nebula.logger.error(String.valueOf(err.getStatusCode()), sr).addTag(EVENTTAG);
                    }
                    totalErrors++;
                    totalUpdates--;
                }
            }
            
			// return the custom setting back to original values
            customSetting.Bypass_All_Flows__c = oldCustomSetting.Bypass_All_Flows__c;
            customSetting.Bypass_All_Process__c = oldCustomSetting.Bypass_All_Process__c;
            customSetting.Bypass_All_Validation_Rules__c = oldCustomSetting.Bypass_All_Validation_Rules__c;
            customSetting.Bypass_All_Triggers__c = oldCustomSetting.Bypass_All_Triggers__c;
            upsert customSetting;        
        }
	    nebula.logger.saveLog();
    }

   /**
    * Implement finsh method (from interface) to wrap up processing.
    */
    public void finish(Database.BatchableContext bc) {
        nebula.Logger.setAsyncContext(bc);
        nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        nebula.Logger.setScenario(SCENARIO);       
		nebula.logger.info('Total Contact Updated Records: ' + totalUpdates).addTag(EVENTTAG);
		nebula.logger.info('Total Contact Errored Records: ' + totalErrors).addTag(EVENTTAG);
        nebula.logger.saveLog();
                
        // sanitise Channel__c email addresses first, as they roll-up to Contact (in trigger)
        if(!Test.isRunningTest() && !this.runIsolated) {
            Id jobId = Database.executeBatch(new ChannelEmailsUpdateBatch());
        }
    }
}