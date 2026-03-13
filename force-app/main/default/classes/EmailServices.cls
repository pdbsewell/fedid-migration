/**
 * @description Apex class containing Email logic services
 *
 * @revision
 *  2020-01-22 Nick Guia     - added implementation of IPlatformEventInvocable for CalculatePrimary()
 *  2020-06-15 J.Mapanao     - Added logic to not deselect primary when user previously selected manually
 *  2020-07-06 Stefan Scheit - updated isMonashEmail() to be case insensitive
 *  06/07/2024 Martin Cadman - Remove redundant updates of address records and included analysis logging
 *  03/10/2024 Martin Cadman - Added debug logging
 * 
 *
 **/
public class EmailServices {

    public static  final String EMAIL_CLASSIFICATION_MONASH = 'Monash';
    private static final String SCENARIO = 'Analysis';
    private static final String TAG      = 'Email Primary Analysis';
    private static String msgfmt = '[Active Student: {0}] [Override: {1}] [Class Selected: {2}] [Personal #: {3}] [Monash #: {4}] [Already Primary: {5}]';

	public static final Set<String> MONASH_DOMAINS = new Set<String> {
		'monash.edu',
		'monash.edu.au',
		'student.monash.edu',
		'student.monash.edu.au',
		'monashcollege.edu.au',
		'jmss.vic.edu.au',
		'iitbmonash.org',
		'monsu.org',
		'climateworksaustralia.org',
		'hudson.org.au'
	};

    public final String automatedProcessUserName = 'autoproc@';

    /**
     * @description Method to calculate Primary Email for each Contact
     *  for every new record or an existing Email record is updated.
     *  This class is invocable via the generic platform event
     */
    public class CalculatePrimary implements IPlatformEventInvocable {

        private Set<Id> contactIds = new Set<Id>();

        public void execute(List<AsyncProcessPayload> payload) {
            try {
                initialize(payload);
                run(this.contactIds, true);
            } catch(Exception ex) {
                nebula.logger.error(ex.getMessage(), ex).addTag(TAG);
            } finally {
                nebula.logger.saveLog();
            }
        }

        public void run(Set<Id> conIds, Boolean byPassRollDown) {
            nebula.LogMessage logMsg;
            nebula.logger.setScenario(SCENARIO);

            if(conIds != null) {
                List<Email__c> recordsToUpdate = new List<Email__c>();

                /**
                 * Try to find new Primary email for each Contact by querying all their child Email records, sorted by Start_Date__c AND CreatedDate
                 */
                for (Contact contact : [SELECT Id, IT_account_disabled__c, Is_Student__c,
                                        (SELECT Id, Is_Primary__c, Name, Classification__c, Primary_set_by__c
                                         FROM Emails__r
                                         WHERE Is_Deleted__c = FALSE
                                         AND Is_Active__c = TRUE
                                         ORDER BY Start_Date__c DESC, CreatedDate DESC)
                                        FROM Contact
                                        WHERE Id IN :conIds]) {

                    nebula.logger.debug('Calculating primary email',contact).addTag(TAG);
					if (contact.emails__r.size()==0) {
                    	nebula.logger.debug('There are no emails are under consideration',contact).addTag(TAG);
                        break;
                    }
                                            
					if (contact.emails__r.size()==1 && contact.emails__r[0].is_Primary__c) {
    	                nebula.logger.debug('There is 1 email and it is already primary',contact.emails__r[0]).addTag(TAG);
                        break;
                    }
                 
					if (contact.emails__r.size()>1) {
    	                nebula.logger.debug('There is are '+ contact.emails__r.size() + ' emails under consideration',contact.emails__r).addTag(TAG);
                    }
                                            
					// list of emails classified as Monash
                    List<Email__c> monashEmails = new List<Email__c>();
                    // list of emails of any classification aside from Monash
                    List<Email__c> nonMonashEmails = new List<Email__c>();
 					Email__c orRec;
                    Boolean anyOtherPrimaryWhereSetByUser = false;
                    
                    // for each contact
                    for(Email__c iEmail : contact.Emails__r) {
                        // get the list of monash email addresses sorted by start date
                        if(iEmail.Classification__c == EMAIL_CLASSIFICATION_MONASH) {
                            monashEmails.add(iEmail);
                        }
                        // and get the list of non monash addresses sorted by start date
                        else {
                            nonMonashEmails.add(iEmail);
                        }
                        if (iEmail.Is_Primary__c && iEmail.Primary_set_by__c == 'user') {
                            nebula.logger.debug('User override record found',iEmail).addTag(TAG);
                            anyOtherPrimaryWhereSetByUser = true;
                            orRec = iEmail;
                        }
                    }
					
                    nebula.logger.debug('Monash Emails  : ' + monashEmails.size()).addTag(TAG);
                    nebula.logger.debug('Personal Emails: ' + nonMonashEmails.size()).addTag(TAG);

                    Email__c iEmail;
                    if(contact.Is_Student__c) {
	                    nebula.logger.debug('Contact is a student', contact).addTag(TAG);
                        // Attempt to set the (latest) monash email as primary
                        if(!monashEmails.isEmpty()) { 
                            iEmail = monashEmails[0];
                            logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No','Ignored','Monash - Latest start date',''+nonMonashEmails.size(), ''+monashEmails.size(),iEmail.is_primary__c==true?'Yes':'No'}); 
                            nebula.logger.debug(logMsg,iEmail).addTag(TAG);
                            if (!iEmail.is_primary__c) {
                                iEmail.is_primary__c = true;
                                recordsToUpdate.add(iEmail);
                            }
                        } else { // Attempt to set the (lastest) non-monash email as primary
                            if(!nonMonashEmails.isEmpty()) {
			                    iEmail = nonMonashEmails[0];
                                logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No','Ignored','Personal - Latest start date',''+nonMonashEmails.size(), ''+monashEmails.size(),iEmail.is_primary__c==true?'Yes':'No'}); 
                                nebula.logger.debug(logMsg,iEmail).addTag(TAG);
                                if (!iEmail.is_primary__c) {
                                    iEmail.is_primary__c = true;
                                    recordsToUpdate.add(iEmail);
                                }
                            }
                        }
                    } else { // the contact is NOT considered a student
	                    nebula.logger.debug('Contact is not an active student', contact).addTag(TAG);
                        if (!anyOtherPrimaryWhereSetByUser) {
                            // Attempt to set the (latest) non-monash email address as primary
                            if(!nonMonashEmails.isEmpty()) {
			                    iEmail = nonMonashEmails[0];
                                logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No',anyOtherPrimaryWhereSetByUser==true?'Yes':'No','Personal - Latest start date',''+nonMonashEmails.size(), ''+monashEmails.size(),iEmail.is_primary__c==true?'Yes':'No'}); 
                                nebula.logger.debug(logMsg,iEmail).addTag(TAG);
                                if (!iEmail.is_primary__c) {
                                    iEmail.is_primary__c = true;
                                    recordsToUpdate.add(iEmail);
                                }
                            } else { // Attempt to set the (latest) non-monash email address as primary (as fallback)
                                if(!monashEmails.isEmpty()) { 
				                    iEmail = monashEmails[0];
                                    logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No',anyOtherPrimaryWhereSetByUser==true?'Yes':'No','Monash - Latest start date',''+nonMonashEmails.size(), ''+monashEmails.size(),iEmail.is_primary__c==true?'Yes':'No'}); 
                                    nebula.logger.debug(logMsg,iEmail).addTag(TAG);
                                    if (!iEmail.is_primary__c) {
                                        iEmail.is_primary__c = true;
                                        recordsToUpdate.add(iEmail);
                                    }
                                }
                            }
                        } else {
                            logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No','Yes','-',''+nonMonashEmails.size(), ''+monashEmails.size(),'-'}); 
                            nebula.logger.debug(logMsg,orRec).addTag(TAG);
		                }
		            }
                }

                // Update email records
                if (!recordsToUpdate.isEmpty()) {
                    if(byPassRollDown) {
                        Triggers.bypass('Person360RollDown');
                    }

		            nebula.logger.debug('Updating the email primary field (new primaries)',recordsToUpdate).addTag(TAG);
                    //force roll up on Email records in this context
                    Set<Id> emailIds = (new Map<Id, Email__c>(recordsToUpdate)).keySet();
                    EmailTriggerHandler.rollUpEmailIds = emailIds;
                    //
		            Triggers.bypass('FindNewPrimary');
                    List<Database.SaveResult> saveResults = Database.update(recordsToUpdate, false);
					List<Database.SaveResult> failedRecordsErrors = new List<Database.SaveResult>();
                    for (Database.SaveResult saveResult : saveResults) {
                        if (!saveResult.isSuccess()) {
                            failedRecordsErrors.add(saveResult);
                        }
                	}
                    
                    if (!failedRecordsErrors.isEmpty()) {
						nebula.logger.error('Email find new primary database errors',failedRecordsErrors);
                    }
		            Triggers.clearBypass('FindNewPrimary');
                    Triggers.clearBypass('Person360RollDown');
                }
            }
            nebula.logger.endScenario(scenario);
        }

        /**
         * @description initialize process by extracting the method
         *  parameters from the platform event payload
         */
        private void initialize(List<AsyncProcessPayload> payloads) {
            if(payloads != null) {
                for(AsyncProcessPayload payload : payloads) {
                    //first, cast the get return of List<Object> into List<Id>
                    List<Object> objList = (List<Object>) payload.get('contactIds');
                    //then, instantiate a Set out of it
                    for(Object io : objList) {
                        //parse object to ID
                        this.contactIds.add(Id.valueOf(io.toString()));
                    }
                }
            }
        }
    }

    /**
     * @description checks if the provided String email is from
     *  a known Monash domain
     */
    public static Boolean isMonashEmail(String sEmail) {
        Boolean isMonash = false;

        if(String.isNotBlank(sEmail)) {
            //split string by @
            List<String> splitEmail = sEmail.split('@');
            //make sure we have more than 1 result from split
            if(splitEmail.size() > 1) {
                //get the second part of string (domain) and compare case-insenstive
                String domain = splitEmail[1].toLowerCase();
                if(MONASH_DOMAINS.contains(domain)) {
                    isMonash = true;
                }
            }
        }
        return isMonash;
    }
}