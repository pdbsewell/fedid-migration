/**
 * @description Name Trigger Handler
 *
 * @author P.Victoriano
 * @date 03/14/19
 *
 * @revision
 *  2020-01-28 - Nick Guia - encapsulated everything with try-catch, added Exception and Current Limits Logging
 *  2020-06-15 - J.Mapanao - Added EvaluateIfCanSetPrimary
 *  2020-06-23 - J.Mapanao - Changed using Person360RollUpUtility to new Person360RollUpServices.PerformRollUp().run
 *  2020-07-20 - Stefan Scheit - Added 'is active' field changes into scope for triggering of a roll-up
 *  2022-05-12 - Tom Gangemi - SA-1477 - Add AllocatePrimaryRecord to move primary calculation into before trigger
 *  2024-09-11 - Martin Cadman - Added additional criteria for primary calculation
 *  2024-10-09 - Martin Cadman - RollUpLogic moved to CommonUtilities.valueDiff rather than a direct comparison
 **/
public class NameTriggerHandler {

    /**
     * @description Recalculate the mononymous name flag 
     */
    public class Mononymous extends TriggerAbstract {
        list<Name__c> names = new list<Name__c>();

        /**
         * @description Insert handling
         */
        public override void process(SObject record) {
            Name__c nn = (Name__c)record;
            
            if (String.isBlank(nn.first_name__c)) {
                nn.Is_Mononymous_Name__c = true;
            }
        }

        /*
         * @description Update handling
         */
        public override void process(SObject record, SObject oldRec) {
            Name__c nn = (Name__c)record;
            
            if (String.isBlank(nn.first_name__c) && nn.Is_Mononymous_Name__c == false) {
                nn.Is_Mononymous_Name__c = true;
            } else {
                if (String.isNotBlank(nn.first_name__c) && nn.Is_Mononymous_Name__c == true) {
                    nn.Is_Mononymous_Name__c = false;
                }
            }
        }
    }

    /*
     * @description Roll up the primary name details to the contact parent
     */
    public class RollUpLogic extends TriggerAbstract {
        @TestVisible
        private Boolean isRollUpEnabled = Person360Muting__c.getInstance().Enable_Roll_Up__c;
        private Boolean forceRollup     = Person360Muting__c.getInstance().Enable_Force_Rollup__c;
        private Boolean forceRollupPFN  = Person360Muting__c.getInstance().Enable_Force_Rollup_PFN__c;
        Set<String> contactIds = new Set<String>();

        /*
         * @description Blank constructor
         */
        public RollUpLogic() {}

        /*
         * @description Constructor to initialise the contact id set for processing
         */
        public RollUpLogic(Set<Id> contactIds) {
            for(Id cid :contactIds) {
                this.contactIds.add(cid);
            }
        }

        /*
         * @description Insert handling
         */
        public override void process(SObject record) {
            if (isRollUpEnabled != null && isRollUpEnabled) {
                if (record.get('Contact__c') != null) {
                    contactIds.add((String)record.get('Contact__c'));
                }
            }
        }
        
        /*
         * @description Update handling
         */
        public override void process(SObject record, SObject oldRec) {
            if (isRollUpEnabled != null && isRollUpEnabled) {
                Name__c nRec = (Name__c) record;
                Name__c oRec = (Name__c) oldRec;
                //Name Roll up logic compare
                //todo - Use the custom metadata fields
                if (   (forceRollup) 
                    || (nRec.Preferred_First_Name__c != null && forceRollupPFN)
                    || (   CommonUtilities.valueDiff(nRec.Prefix__c, oRec.Prefix__c) 
                        || CommonUtilities.valueDiff(nRec.Salutation__c, oRec.Salutation__c)
                        || CommonUtilities.valueDiff(nRec.Suffix__c, oRec.Suffix__c)
                        || CommonUtilities.valueDiff(nRec.First_Name__c, oRec.First_Name__c)
                        || CommonUtilities.valueDiff(nRec.Last_Name__c, oRec.Last_Name__c)
                        || CommonUtilities.valueDiff(nRec.Middle_Name__c, oRec.Middle_Name__c)
                        || CommonUtilities.valueDiff(nRec.Preferred_First_Name__c, oRec.Preferred_First_Name__c)
                        || CommonUtilities.valueDiff(nRec.Start_Date__c, oRec.Start_Date__c)
                        || CommonUtilities.valueDiff(nRec.End_Date__c, oRec.End_Date__c)
                        || CommonUtilities.valueDiff(nRec.Is_Primary__c, oRec.Is_Primary__c)
                        || CommonUtilities.valueDiff(nRec.Is_Active__c, oRec.Is_Active__c)
                        || CommonUtilities.valueDiff(nRec.Type__c, oRec.Type__c)
                        || CommonUtilities.valueDiff(nRec.Key_UID__c, oRec.Key_UID__c))
                    )
                {
                    if (record.get('Contact__c') != null) {
                        contactIds.add((String)record.get('Contact__c'));
                    }
                }
            }
        }

        /*
         * @description Invoke rollup for records identified
         */
        public override void execute() {
            try {
                if (isRollUpEnabled != null && isRollUpEnabled && contactIds != null && !contactIds.isEmpty()) {
                    //Invoke rollup logic
                    Person360RollUpServices.invokeRollUp(contactIds, new List<String>{'Name__c'});
                }
            } catch(Exception ex) {
                nebula.logger.Exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }
    
    /*
     * @description Defaults the Start Date if Blank
     */
    public class DefaultStartDate extends TriggerAbstract {

        /*
         * @description Before insert process for Start Date
         */
        public override void process(SObject record) {
            Person360Helper.setDefaultDate(Name__c.Start_Date__c, record);
        }
    }

    // to be revisited
    @TestVisible
    private static Boolean maintainUserPrimary = false; // functionality disabled to match existing code

    @TestVisible
    private static Integer allocatePrimaryRecordRunCount = 0; // used for unit test validation of trigger run count

    /**
     * @description Combine trigger records with existing records retrieved via SOQL to determine a primary Name__c record
     * When maintainUserPrimary is true: do not not allow an automatically calculated primary to override a manually set one
     */
    public class AllocatePrimaryRecord extends TriggerAbstract {

        Map<Id,Name__c[]> recordsByContactId = new Map<Id,Name__c[]>();
        Map<Id,Name__c> oldRecords = new Map<Id,Name__c>();

        /*
         * @description Blank constructor
         */
        public AllocatePrimaryRecord() {}

        /*
         * @description Constructor to initialise the the contact/name map
         */
        public AllocatePrimaryRecord(Set<Id> contactIds) {
            // for calling from outside of trigger framework
            for(Id cid :contactIds) {
                recordsByContactId.put(cid, new Name__c[0]);
            }
        }

        /*
         * @description Insert Handling
         */
        public override void process(SObject record) {
            // record is new or changed
            Name__c name = (Name__c)record;
            Name__c[] names = recordsByContactId.get(name.Contact__c);
            if(names == null) {
                names = new Name__c[0];
                recordsByContactId.put(name.Contact__c, names);
            }
            if(!(Trigger.isExecuting && Trigger.isDelete)) {
                // don't process deleted name records
                names.add(name);
                if(name.Is_Primary__c) {
                    Person360Helper.setUserOrSystemToPrimarySetBy(name);
                }
            }
        }

        /*
         * @description Update Handling
         * Added start date and the type of name
         */
        public override void process(SObject record, SObject oldRec) {
            Name__c name = (Name__c)record;
            Name__c oldName = (Name__c)oldRec;
            if (name.Is_Primary__c != oldName.Is_Primary__c 
            || name.Is_Active__c != oldName.Is_Active__c
            || name.Start_Date__c != oldName.Start_Date__c 
            || name.type__c != oldName.type__c) {
                process(record);
                oldRecords.put(oldName.Id, oldName);
            }
        }

        /*
         * @description Process all records identified for processing
         */
        public override void execute() {
            if(recordsByContactId.isEmpty()) {
                return;
            }
            allocatePrimaryRecordRunCount++;

            // retrieve all existing related Name records
            Contact[] contacts = [
                SELECT Is_Student__c,
                    (SELECT Is_Primary__c, Primary_set_by__c, Type__c, Start_Date__c, CreatedDate, First_Name__c
                    FROM Names__r WHERE Is_Active__c = TRUE)
                FROM Contact
                WHERE Id IN :recordsByContactId.keySet()
            ];

            Name__c[] recordsToUpdate = new Name__c[0];

            for(Contact con :contacts) {
                Map<Id,Name__c> updateTriggerRecords = new Map<Id,Name__c>();
                Map<Id,Name__c> queriedRecords = new Map<Id,Name__c>(con.Names__r);
                Map<Id,Name__c> originalQueriedRecords = queriedRecords.deepClone();
                Name__c[] activeRecords = new Name__c[0];

                for(Name__c n :recordsByContactId.get(con.Id)) {
                    if(n.Id != null) {
                        // records from trigger isUpdate context
                        updateTriggerRecords.put(n.Id, n);
                    }
                    if(n.Is_Active__c) {
                        // active records from trigger
                        activeRecords.add(n);
                    } else {
                        n.Is_Primary__c = false;
                        n.Primary_set_by__c = null;
                    }
                }

                // combine contacts active records from trigger and queried records
                for(Name__c qr :con.Names__r) {
                    if(updateTriggerRecords.containsKey(qr.Id)) {
                        // only retain queried records that are not in trigger
                        queriedRecords.remove(qr.Id);
                    }
                }
                activeRecords.addAll(queriedRecords.values());

                if(activeRecords.isEmpty()) {
                    // no active records, do nothing
                    continue;
                }

                if(!con.Is_Student__c && maintainUserPrimary) {
                    // if a non-student's record is primary and was manually set, don't change it
                    Boolean hasPrimarySetByUser = false;
                    for(Name__c n :activeRecords) {
                        if(n.Is_Primary__c && n.Primary_set_by__c == 'user') {
                            hasPrimarySetByUser = true;
                            break;
                        }
                    }
                    if(hasPrimarySetByUser) {
                        continue;
                    }
                }

                Name__c primaryRecord = NameServices.findPrimary(activeRecords, con.Is_Student__c);

                for(Name__c n :activeRecords) {
                    // reset all Is_Primary__c flags
                    n.Is_Primary__c = false;
                    n.Primary_set_by__c = null;
                }

                primaryRecord.Is_Primary__c = true;
                primaryRecord.Primary_set_by__c = 'system';

                for(Name__c n :activeRecords) {
                    // collect queried records that have changed and require DML to persist changes
                    if(queriedRecords.containsKey(n.Id)) {
                        Name__c originalQueriedRecord = originalQueriedRecords.get(n.Id);
                        if(originalQueriedRecord != null && originalQueriedRecord.Is_Primary__c != n.Is_Primary__c) {
                            recordsToUpdate.add(n);
                        }
                    }
                }
            }

            if(recordsToUpdate.size() > 0) {
                TriggerCommon.disableTrigger('Name__c');
                update recordsToUpdate;
                TriggerCommon.enableTrigger('Name__c');
            }
        }
    }

    /*
     * @description Calculates the active status of the name record
     */
    public class ToggleIsActive extends TriggerAbstract {

        // Processing Is_Active__c Functionality Class
        Person360ToggleIsActiveHelper helper = new Person360ToggleIsActiveHelper();

        /*
         * @description Insert handling
         */
        public override void process(SObject record) {
            helper.init(record);
            helper.evaluateIsActiveFieldValue(record);
        }

        /*
         * @description Update handling
         */
        public override void process(SObject record, SObject oldRec) {
            Name__c name = (Name__c)record;
            Name__c oldName = (Name__c)oldRec;
            // Check if new value is different from old value
            if (name.Start_Date__c != oldName.Start_Date__c ||
                    name.End_Date__c != oldName.End_Date__c ||
                    name.Is_Active__c != oldName.Is_Active__c) {
                helper.init(name);
                helper.evaluateIsActiveFieldValue(name, oldRec);
            }
        }
    }
    
    /**
     * @description Calculates the end date
     */
    public class SetIsActiveEndDate extends TriggerAbstract {

        /*
         * @description Update handling
         */
        public override void process(SObject record, SObject oldRec) {
            Name__c name = (Name__c)record;
            Name__c oldName = (Name__c)oldRec;
            // Check if new value is different from old value
            if (name.Is_Active__c &&
                    name.End_Date__c != null &&
                    name.Is_Active__c != oldName.Is_Active__c) {
                name.End_Date__c = null;
            } else if (name.Is_Active__c == false &&
                       name.End_Date__c != null &&
                       name.Is_Active__c != oldName.Is_Active__c) {
                name.End_Date__c = Date.today().addDays(-1);
            }
        }
    }
    
   /*
    * @description Processes the Hash generation of Name__c
    */
    public class PopulateHash extends TriggerAbstract {
        
        /**
         * @description Insert handling
         */
        public override void process(SObject record) {
            Name__c recItm = (Name__c)record;
            //Populate Hash Id
            recItm.Key_UID__c = NameServices.generateKeyUID(recItm);
        }

        /**
         * @description Update handling
         */
        public override void process(SObject record, SObject oldRec) {
            Name__c recItm = (Name__c)record;
            Name__c oldrecItm = (Name__c)oldRec;

            // generate new Full Name
            String fullName = NameServices.generateFullName(recItm);
            String fullNameOld = NameServices.generateFullName(oldrecItm);

            if (String.isNotBlank(fullName)
                && (recItm.Contact__c != oldrecItm.Contact__c)
                || (fullName != fullNameOld)
                || (recItm.Type__c != oldrecItm.Type__c)) {
                //Replace the Hash with new values
                recItm.Key_UID__c = NameServices.generateKeyUID(recItm);
            }
        }
    }

    /**
     * @description Keep ERDA Saluations aligned
	 */
    public class UpdateSalutations extends TriggerAbstract {
        private Set<Id> contactIdSet = new Set<Id>();

        EngageSalutationHelper helper = new EngageSalutationHelper();
        SalutationDuplicateCheck salutationDupCheck = new SalutationDuplicateCheck();

        /**
         * @description Insert handling
         */
        public override void process(SObject record) {
            contactIdSet.add((Id) record.get('Contact__c'));
        }

        /**
         * @description Update handling
         */
        public override void process(SObject record, SObject oldRecord) {
            if (helper.shouldProcessNameRecord((Name__c) record, (Name__c) oldRecord)) {
                contactIdSet.add((Id) record.get('Contact__c'));
            }
        }

        /**
         * @description Process the identified record
         */
        public override void execute() {
            if (contactIdSet.isEmpty()) {
                return;
            }

            helper.createOrUpdateSalutationRecords(contactIdSet);
            //remove duplicate salutation records
            salutationDupCheck.removeDuplicateSalutations(contactIdSet);
        }
    }

    /**
     * @description Check Record Is Active and perform necessary defaults
     */
    public class CheckIsActive extends TriggerAbstract {

        /**
         * @description Insert handling
         */
        public override void process(SObject record) {
            Name__c name = (Name__c) record;
            resetPrimary(name);
        }

        /**
         * @description Update handling
         */
        public override void process(SObject record, SObject oldRecord) {
            Name__c name = (Name__c) record;
            resetPrimary(name);
        }

        /**
         * @description Set the primary flag back to false
         */
        private void resetPrimary(Name__c nameRecord){
            if(!nameRecord.Is_Active__c && nameRecord.Is_Primary__c){
                nameRecord.Is_Primary__c = false;
            }
        }
    }

    /**
     * @description Before upsert context to initialise or validate fields
	 */
    public class initialiseFields extends TriggerAbstract {

        /**
         * @description Before insert field initialisation
         * Initialises the prefix and salutation 
         * Applies the middlename 
         */
        public override void process(SObject record) {
			name__c n = (name__c) record;
            try {
                n = initialiseTitle (n);
                
                if (Person360Helper.nameCanBeSplit(n.First_Name__c)) {
                    Person360Helper.splitLegalFirstNameIntoFirstAndMiddle(n.First_Name__c,n);
                }
            } catch(Exception ex) {
                nebula.logger.Exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }

        /**
         * @description Before update field initialisation
         */
        public override void process(SObject record, SObject oldRec) {
			name__c n = (name__c) record;
            try {
                n = initialiseTitle (n);
    
                if (Person360Helper.nameCanBeSplit(n.First_Name__c)) {
                    Person360Helper.splitLegalFirstNameIntoFirstAndMiddle(n.First_Name__c,n);
                }

				n.prefix__c = contactServices.toProperCase(n.prefix__c);
				n.first_name__c = contactServices.toProperCase(n.first_name__c);
				n.middle_name__c = contactServices.toProperCase(n.middle_name__c);
				n.last_name__c = contactServices.toProperCase(n.last_name__c);
				n.preferred_first_name__c = contactServices.toProperCase(n.preferred_first_name__c);

            } catch(Exception ex) {
                nebula.logger.Exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
   }
    
	/**
	 * @description 
	 * Default salutation and prefix field if either is null. Still allows the fields to be different.
	 * Removes trailing . from the same fields as well.
	 */
    public static name__c initialiseTitle (name__c name) {
		name__c n = name;

        // We won't default the fields for the time being as changes will be made in this area soon.
        //if (n.Prefix__c == null && n.Salutation__c != null) {
        //    n.Prefix__c = n.Salutation__c;
        //}            
        
        //if (n.Prefix__c != null && n.Salutation__c == null) {
        //    n.Salutation__c = n.Prefix__c;
        //}   
        
        if (n.Salutation__c != null && n.Salutation__c.endsWith('.')) {
            n.Salutation__c = n.Salutation__c.removeEnd('.');
        }
        
        if (n.Prefix__c != null && n.Prefix__c.endsWith('.')) {
            n.Prefix__c = n.Prefix__c.removeEnd('.');
        }

        return n;
    }
}