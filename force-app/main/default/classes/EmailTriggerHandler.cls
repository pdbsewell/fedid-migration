/**
 * @description Email Trigger Handler
 *
 * @author P.Victoriano
 * @date 03/14/19
 *
 *
 * @revision
 * 	2020-01-20 - Nick Guia - Refined the FindNewPrimary logic
 * 	2020-01-22 - Russell Cadapan - refined filter criteria of updated records
 * 	2020-01-28 - Nick Guia - encapsulated everything with try-catch, added Exception and Current Limits Logging
 * 	2020-02-04 - Nick Guia - Added FindNewParentChannel
 *  2020-06-15 - J.Mapanao - Added EvaluateIfCanSetPrimary
 *  2020-06-23 - J.Mapanao - Changed using Person360RollUpUtility to new Person360RollUpServices.PerformRollUp().run
 *  2020-07-19 - J.Mapanao - Updated FindNewParentChannel class to allow end dating callista source when contact is non student
 *  2020-07-20 - Stefan Scheit - Added 'is active' field changes into scope for triggering of a roll-up
 *  2022-05-20 - Stefan Scheit - Added 'unreachable' field handler to blank out unreachable reason
 *  2022-11-02 - Martin Cadman - Stopped recacluation of primary for when deleting non-primary records
 *  2023-03-13 - Martin Cadman - Added a check to ensure the channel is active in FindNewParentChannel
 *  2024-09-20 - Martin Cadman - Check for empty keyUID when recalulating the primary
 *  2024-10-03 - Martin Cadman - Logging
 **/
public class EmailTriggerHandler {

    public static Set<Id> rollUpEmailIds = new Set<Id>();

    /**
     * @description Processes the Rollup Logic
     */
    public class RollUpLogic extends TriggerAbstract {
        @TestVisible
        private Boolean isRollUpEnabled = Person360Muting__c.getInstance().Enable_Roll_Up__c;
        private Boolean forceRollup     = Person360Muting__c.getInstance().Enable_Force_Rollup__c;
        Set<String> contactIds = new Set<String>();

        /**
         * @description Retrieves individual records
         */
        public override void process(SObject record) {
            if (isRollUpEnabled != null && isRollUpEnabled) {
                if (record.get('Contact__c') != null) {
                    contactIds.add((String)record.get('Contact__c'));
                }
            }
        }
        /**
         * @description Process records on After Update event
         */
        public override void process(SObject record, SObject oldRec) {
            if (isRollUpEnabled != null && isRollUpEnabled) {
                Email__c email = (Email__c) record;
                Email__c oldEmail = (Email__c) oldRec;
                //Name Roll up logic compare
                if ((forceRollup)
                    || (commonUtilities.fieldHasChanged('Key_UID__c', email, oldEmail) 
						|| commonUtilities.fieldHasChanged('Name', email, oldEmail) 
                        || commonUtilities.fieldHasChanged('Start_Date__c', email, oldEmail) 
                        || commonUtilities.fieldHasChanged('Classification__c', email, oldEmail) 
                        || commonUtilities.fieldHasChanged('Is_Primary__c', email, oldEmail) 
                        || commonUtilities.fieldHasChanged('Is_Active__c', email, oldEmail) 
                        || EmailTriggerHandler.rollUpEmailIds.contains(email.Id))
                   ) {
                    if (record.get('Contact__c') != null) {
                        contactIds.add((String)record.get('Contact__c'));
                    }
                }
            }
        }
        /**
         * @description Post Processing Logic
         */
        public override void execute() {
            try {
                if (isRollUpEnabled != null 
                    && isRollUpEnabled 
                    && contactIds != null 
                    && !contactIds.isEmpty()) {
					Person360RollUpServices.invokeRollUp(contactIds, new List<String>{'Email__c'});
				}
            } catch(Exception ex) {
                nebula.logger.error(ex.getMessage(), ex);
            }
            finally {
                nebula.logger.saveLog();
            }
        }
    }
    /**
     * @description Defaults the Start Date if Blank
     */
    public class DefaultStartDate extends TriggerAbstract {
        /**
         * @description Before insert process for Start Date
         */
        public override void process(SObject record) {
            Person360Helper.setDefaultDate(Email__c.Start_Date__c, record);
        }
    }

    /**
     * @description Untoggles Is Primary flag to other records
     */
    public class TogglePrimary extends TriggerAbstract {
        @TestVisible
        private Set<Id> contactIds = new Set<Id>();
        @TestVisible
        private Set<Id> recordIds = new Set<Id>();
        private String SCENARIO = 'Analysis';
        private String TAG      = 'Email Primary Analysis';

        public TogglePrimary() {}

        public TogglePrimary(Set<Id> pConIds) {
            contactIds = (pConIds != null) ? pConIds : new Set<Id>();
        }

        /**
         * @description Collects Contact Ids on After Insert
         */
        public override void process(SObject record) {
            Email__c email = (Email__c)record;
            if (email.Is_Primary__c == true) {
                contactIds.add(email.Contact__c);
                recordIds.add(email.Id);
            }
        }
        /**
         * @description Collect Contact Ids on After Update
         */
        public override void process(SObject record, SObject oldRec) {
            Email__c email = (Email__c)record;
            Email__c oldEmail = (Email__c)oldRec;
            if (email.Is_Primary__c == true &&
                    email.Is_Primary__c != oldEmail.Is_Primary__c) {
                contactIds.add(email.Contact__c);
                recordIds.add(email.Id);
            }
        }
        /**
         * @description Perform Post Processing logic
         * Untoggles Primary flag to false on other records
         */
        public override void execute() {
            nebula.logger.setScenario(SCENARIO);
            try {
                if (!contactIds.isEmpty()) {
                    //Get All Primary excluding Current Records
                    List<Email__c> emails = [SELECT Id, Is_Primary__c FROM Email__c
                                              WHERE Contact__c IN:contactIds
                                                AND Id NOT IN:recordIds
                                                AND Is_Primary__c = true];
                    if (!emails.isEmpty()) {
                        //Toggle Primary to False
                        for (Email__c rec : emails) {
			                nebula.logger.debug('Toggling email primary flag off', rec);
                            rec.Is_Primary__c = false;
                        }
                        //Put skip on FindnewPrimary to prevent recursion
                        Triggers.bypass('FindNewPrimary');
                        List<Database.SaveResult> srList = Database.update(emails, false);
                        Triggers.clearBypass('FindNewPrimary');
                        for(Database.SaveResult iSr : srList) {
                            if(!iSr.isSuccess()) { 
                                Database.Error err = iSr.getErrors()[0];
                                nebula.logger.error('Unable to remove primary flag\r' + err.getStatusCode() + ' ' + err.getMessage(), iSr.getId()).addTag(TAG);
                            }
                        }
                    }
                }
	            nebula.logger.endScenario(SCENARIO);
            } catch(Exception ex) {
                nebula.logger.error(ex.getMessage(),ex).addTag(TAG);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }

    /**
     * @description Processes the Is_Active__c logic
     */
    public class ToggleIsActive extends TriggerAbstract {
        // Processing Is_Active__c Functionality Class
        Person360ToggleIsActiveHelper helper = new Person360ToggleIsActiveHelper();
        /**
         * @description Process record on BEFORE INSERT event
         */
        public override void process(SObject record) {
            helper.init(record);
            helper.evaluateIsActiveFieldValue(record);
        }
        /**
         * @description Process records on BEFORE UPDATE event
         */
        public override void process(SObject record, SObject oldRec) {
            Email__c email = (Email__c)record;
            Email__c oldEmail = (Email__c)oldRec;
            // Check if new value is different from old value
            if (email.Start_Date__c != oldEmail.Start_Date__c ||
                    email.End_Date__c != oldEmail.End_Date__c ||
                    email.Is_Active__c != oldEmail.Is_Active__c ||
                    email.Is_Deleted__c != oldEmail.Is_Deleted__c ||
                    email.Unreachable__c != oldEmail.Unreachable__c) {
                helper.init(email);
                helper.evaluateIsActiveFieldValue(email, oldEmail);
            }
        }
    }

    /**
     * @description GIVEN   Contact record have multiple child email records
     *              AND     Only 1 email record is primary
     *              WHEN    User delete the primary email record
     *              THEN    Select the latest email record
     *              AND     set the Is_Primary__c to true
     * @revision
     * 	JAN.20.2020 Nick Guia 	- refined logic to consider IT_account_disabled__c
     * 							field in Contact when determining primary
     * 							- Refined logic for processing only Contacts that has no
     * 							other Primary email other that that of the modified ones
     * 	JAN.22.2020 Russell Cadapan - refined filter criteria of updated records
     * 								- moved the calculation logic into EmailServices class for re-use purposes
     */
    public class FindNewPrimary extends TriggerAbstract {
        @TestVisible
        private Set<Id> contactIds = new Set<Id>();

        public FindNewPrimary() {}

        public FindNewPrimary(Set<Id> pConIds) {
            contactIds = (pConIds != null) ? pConIds : new Set<Id>();
        }

        /**
         * @description Process records on AFTER INSERT and DELETE event
         */
        public override void process(SObject record) {
            Email__c email = (Email__c)record;
            // Filter out deleted non-primary records. Primary will not change as a result of removing a non-primary.
            if ((!trigger.isDelete) || (trigger.isDelete && email.Is_Primary__c)){
	            contactIds.add(email.Contact__c);
            }
        }

        /**
         * @description Process records on AFTER UPDATE event
         */
        public override void process(SObject record, SObject oldRecord) {
            Email__c email = (Email__c)record;
            Email__c emailOld = (Email__c)oldRecord;
            // Check if new value is different from old value (if IsPrimary has changed, if IsActive has changed, or if the email has been deleted/undeleted)
            if ((email.Is_Primary__c != emailOld.Is_Primary__c) 
                || (email.Is_Active__c != emailOld.Is_Active__c) 
                || (email.Is_Deleted__c != emailOld.Is_Deleted__c) 
                || (email.Start_Date__c != emailOld.Start_Date__c)
                || (email.Key_UID__c == null)) {
                // for every email that has a change in the is primary flag, include the contact Id for re-calculation
                contactIds.add(email.Contact__c);
            }
        }

        /**
         * @description Perform Post Processing logic
         */
        public override void execute() {
            try {
                // execute service method to calculate which Email record should be primary
                if (!contactIds.isEmpty()) {
                    new EmailServices.CalculatePrimary().run(contactIds, false);
                }
            } catch(Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
		}
    }
    
    /**
     * @description Processes the Is_Active__c logic
     */
    public class SetIsActiveEndDate extends TriggerAbstract {
        /**
         * @description Process records on BEFORE UPDATE event
         */
        public override void process(SObject record, SObject oldRec) {
            Email__c rec = (Email__c)record;
            Email__c recOld = (Email__c)oldRec;
            // Check if new value is different from old value
            if (rec.Is_Active__c &&
                    rec.End_Date__c != null &&
                    rec.Is_Active__c != recOld.Is_Active__c) 
                {
                rec.End_Date__c = null;
            } else if (!rec.Is_Active__c &&
                       rec.Is_Active__c != recOld.Is_Active__c) 
                {
                rec.End_Date__c = Date.today();
            }
        }
    }
    /**
     * @description Populates the hash for SObject
     */
    public class PopulateHash extends TriggerAbstract {
        /**
         * @description Process record on BEFORE INSERT event
         */
        public override void process(SObject record) {
            Email__c recItm = (Email__c)record;
            Set<String> keySet = new Set<String> {recItm.Contact__c};
            if (String.isNotBlank(recItm.Name)) {
                keySet.add(recItm.Name);
            }
            //Populate Hash Id
            recItm.Key_UID__c = Person360Helper.generatePerson360Key(keySet);
        }
        /**
         * @description Process records on BEFORE UPDATE event
         */
        public override void process(SObject record, SObject oldRec) {
            Email__c recItm = (Email__c)record;
            Email__c oldrecItm = (Email__c)oldRec;
            Set<String> keySet = new Set<String> {recItm.Contact__c};
            if (String.isNotBlank(recItm.Name) &&
                    (recItm.Contact__c != oldrecItm.Contact__c) ||
                    commonUtilities.fieldHasChanged('Name', recItm, oldrecItm) || // email hash is case sensitive at the moment
                    oldrecItm.Key_UID__c == null) {
                keySet.add(recItm.Name);
                //Replace the Hash with new values
                recItm.Key_UID__c = Person360Helper.generatePerson360Key(keySet);
            }
        }
    }

    /**
     * @description Check Record Is Active and perform necessary defaults
     */
    public class CheckIsActive extends TriggerAbstract {
        /**
         * @description Before insert process
         */
        public override void process(SObject record) {
            Email__c email = (Email__c) record;
            resetPrimary(email);
        }

        /**
         * @description Before update process
         */
        public override void process(SObject record, SObject oldRecord) {
            Email__c email = (Email__c) record;
            resetPrimary(email);
        }

        private void resetPrimary(Email__c emailRecord) {
            if(!emailRecord.Is_Active__c && emailRecord.Is_Primary__c) {
                emailRecord.Is_Primary__c = false;
            }
        }
    }

    /**
     * @description process for re-parenting Email records to a different Channel.
     * 	This is mainly when  Channel record got deleted from source (Callista)
     */
    public class FindNewParentChannel extends TriggerAbstract {

        List<Email__c> emailList = new List<Email__c>();
        List<Email__c> emailToFilterList = new List<Email__c>();
        Set<Id> contactIds = new Set<Id>();

        /**
         * On before insert, find new parent channel if :
         * 	- Email is not Active and
         * 	- Channel is not null (to know the source / original parent channel)
         */
        public override void process(SObject record) {
            Email__c emailRec = (Email__c) record;
            if(!emailRec.Is_Active__c && emailRec.Channel__c != null) {
                emailList.add(emailRec);
            }
        }

        /**
         * @description On before update, find new parent channel if :
         * 	- Email is not Active and
         * 	- Channel is not null and has changed
         */
        public override void process(SObject record, SObject oldRecord) {
            Email__c newEmail = (Email__c) record;
            Email__c oldEmail = (Email__c) oldRecord;
            if(!newEmail.Is_Active__c
                    && CommonUtilities.fieldHasChanged('Is_Active__c', newEmail, oldEmail)
                    && newEmail.channel__c != null)
            {
                if (newEmail.Contact__c != null) {
                    contactIds.add(newEmail.Contact__c);
                }
                emailToFilterList.add(newEmail);
            }
        }

        public override void execute() {
            if (!emailToFilterList.isEmpty() && !contactIds.isEmpty()) {
                Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id, Is_Student__c FROM Contact WHERE Id IN: contactIds]);
	            if (!contactMap.isEmpty()) {
					Map<Id,Email__c> emailMap = new Map<Id,Email__c>([select id from Email__c where id in :EmailToFilterList and channel__r.is_active__c = true]);
                	for (Email__c loopEmail : emailToFilterList) {
                        // Acceptance Criteria:
                        // A contact point of a non-student with source=Callista can be end-dated
                        // and remains end-dated despite an active Channel (lookup) record, i.e. the email remains active in the Channel record.
                        // This is to prevent find new channel when contact point end dated for non-student
                        if (!emailMap.isEmpty()
                            && emailMap.containsKey(loopEmail.id)
                            && contactMap.containsKey(loopEmail.Contact__c)
                            && contactMap.get(loopEmail.Contact__c).Is_Student__c == false
                            && loopEmail.Source__c == 'Callista') {
                                continue;
                        } else {
                            emailList.add(loopEmail);
                        }
                    }
                    if(!emailList.isEmpty()) {
                        Set<String> channelSourceFields = new Set<String> {'Email__c'};
                        ChannelEventUtility.findNewContactPointChannel(emailList, channelSourceFields);
                    }
                }
            }
        }
    }

    /**
     * @description If an email is of a Monash owned domain and the 
     *  currently inserted or updated record has a classification of "personal" (Private) OR 
     *  is empty/null, then automatically set the Classification__c to "Monash" 
     *  before the record is saved.
     */
	public class CheckMonashEmail extends TriggerAbstract {

		public override void process(SObject record) {
			Email__c emailRec = (Email__c) record;
			if(isUpdateToMonashClassification(emailRec)) {
				emailRec.Classification__c = 'Monash';
            }
		}

		public override void process(SObject record, SObject oldRecord) {
			Email__c newEmail = (Email__c) record;

			if(isUpdateToMonashClassification(newEmail)) {
				newEmail.Classification__c = 'Monash';
			}
		}

		private Boolean isUpdateToMonashClassification(Email__c emailRec) {
			Boolean isUpdateToMonashEmail = false;

            // classification of "business" is ok to be used for an email of a Monash domain, eg. for an alumni that is also Monash staff
			if((emailRec.Classification__c == null || emailRec.Classification__c == 'Private') &&
			   EmailServices.isMonashEmail(emailRec.Name))
			{
				isUpdateToMonashEmail = true;
			}
			return isUpdateToMonashEmail;
        }
    }

    /**
     * @description When Contact is not a student and when user selected a primary, do not deselect
     */
    public class EvaluateIfCanSetPrimary extends TriggerAbstract {

        Set<Id> contactIds = new Set<Id>();
        Map<Id, Email__c> emailRecords = new Map<Id, Email__c>();
        Map<Id, List<Email__c>> conIdAndRecordsMap = new  Map<Id, List<Email__c>>();
        /**
         * @description Process record on BEFORE INSERT event
         */
        public override void process(SObject record) {
            Email__c newEmail = (Email__c) record;
            if (newEmail.Is_Primary__c == true) {
                Person360Helper.setUserOrSystemToPrimarySetBy(newEmail);
                contactIds.add(newEmail.Contact__c);
                if (!conIdAndRecordsMap.containsKey(newEmail.Contact__c)) {
                    conIdAndRecordsMap.put(newEmail.Contact__c, new List<Email__c>{newEmail});
                } else {
                    conIdAndRecordsMap.get(newEmail.Contact__c).add(newEmail);
                }
            }
        }
        /**
         * @description Process records on BEFORE UPDATE event
         */
        public override void process(SObject record, SObject oldRecord) {
            Email__c newEmail = (Email__c) record;
            Email__c oldEmail = (Email__c) oldRecord;
            if (newEmail.Is_Primary__c != oldEmail.Is_Primary__c && newEmail.Is_Primary__c == true) {
                Person360Helper.setUserOrSystemToPrimarySetBy(newEmail);
                contactIds.add(newEmail.Contact__c);
                emailRecords.put(newEmail.Id, newEmail);
                if (!conIdAndRecordsMap.containsKey(newEmail.Contact__c)) {
                    conIdAndRecordsMap.put(newEmail.Contact__c, new List<Email__c>{newEmail});
                } else {
                    conIdAndRecordsMap.get(newEmail.Contact__c).add(newEmail);
                }
            }
            // Always set newEmail.Primary_set_by__c to blank when newEmail.Is_Primary__c == false
            else if (newEmail.Is_Primary__c == false) {
                newEmail.Primary_set_by__c = '';
            }
        }

        public override void execute() {
            if(!contactIds.isEmpty() && !emailRecords.isEmpty()) {
                for (Contact con : [SELECT Id, Is_Student__c,
                                    (SELECT Id, Is_Primary__c, Primary_set_by__c FROM Emails__r WHERE Is_Active__c = true AND Is_Primary__c = true AND Id NOT IN: emailRecords.keySet())
                                    FROM Contact WHERE Id IN: contactIds]) {
                    Boolean isPrimarySetByUser = false;
                    for(Email__c iEmail : con.Emails__r) {
                        if (iEmail.Primary_set_by__c == 'user') {
                            isPrimarySetByUser = true;
                            break;
                        }
                    }
                    for (Email__c sObj : conIdAndRecordsMap.get(con.Id)) {
                        // prevent setting new primary when contact is not student and there is a previous primary set by user.
                        // allow a manual setting of "any" email if the contact is not a student.
                        if ((!con.Is_Student__c && isPrimarySetByUser && UserInfo.getUserName().toLowerCase().contains(Person360Helper.automatedProcessUserName))) {
                            sObj.Is_Primary__c = false;
                            sObj.Primary_set_by__c = '';
                        }
                    }
                }
            }
        }
    }
    
    /**
     * @description Check whether to blank out the unreachable reason if unreachable flag is set to false. 
     */
    public class BlankoutUnreachableReason extends TriggerAbstract {
        /**
         * @description Before insert process
         */
        public override void process(SObject record) {
            Email__c email = (Email__c) record;
            evaluate(email);
        }

        /**
         * @description Before update process
         */
        public override void process(SObject record, SObject oldRecord) {
            Email__c email = (Email__c) record;
            evaluate(email);
        }

        private void evaluate(Email__c emailRecord) {
            if(!emailRecord.Unreachable__c && String.isNotBlank(emailRecord.Unreachable_Reason__c)) {
                emailRecord.Unreachable_Reason__c = '';
            }
        }
    }
}