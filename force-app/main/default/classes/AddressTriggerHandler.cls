/**
 * @description Address Trigger Handler
 *
 * @author P.Victoriano
 * @date 03/14/19
 *
 * @revision
 *   2019-03-14 - P.Victoriano - link to EPCP-112
 *   2020-06-15 - J.Mapanao - Added EvaluateIfCanSetPrimary
 *   2020-06-25 - Stefan Scheit - Removed logic to populate/format Address__c.Name (as it's been changed to auto-number a while back)
 *   2020-07-19 - J.Mapanao - Updated FindNewParentChannel class to allow end dating callista source when contact is non student
 *   2020-07-20 - Stefan Scheit - Added 'is active' field changes into scope for triggering of a roll-up
 *   2022-11-02 - Martin Cadman - Stopped recacluation of primary for when deleting non-primary records
 *   2022-11-24 - Stephen Liu   - Modified logic to generate Address Key UID, now it converts all the address field values to lower case and remove all the non-alphanumeric before send them for hashing
 *   2023-03-13 - Martin Cadman - Added a check to ensure the channel is active in FindNewParentChannel
 *   2024-09-20 - Martin Cadman - Check for empty keyUID when recalulating the primary
 **/
public class AddressTriggerHandler {

    /**
     * @description Processes the Rollup Logic
     */
    public class RollUpLogic extends TriggerAbstract {
        @TestVisible
        Boolean isRollUpEnabled = Person360Muting__c.getInstance().Enable_Roll_Up__c;
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
                Address__c address = (Address__c) record;
                Address__c oldAddress = (Address__c) oldRec;
                //Name Roll up logic compare
                if ((forceRollup)
                    || (commonUtilities.fieldHasChanged('Key_UID__c', address, oldAddress) 
                        || commonUtilities.fieldHasChanged('Street_Name__c', address, oldAddress) 
                        || commonUtilities.fieldHasChanged('City__c', address, oldAddress) 
                        || commonUtilities.fieldHasChanged('State__c', address, oldAddress) 
                        || commonUtilities.fieldHasChanged('Post_Code__c', address, oldAddress) 
                        || commonUtilities.fieldHasChanged('Country2__c', address, oldAddress) 
                        || commonUtilities.fieldHasChanged('Start_Date__c', address, oldAddress) 
                        || commonUtilities.fieldHasChanged('Classification__c', address, oldAddress) 
                        || commonUtilities.fieldHasChanged('Is_Primary__c', address, oldAddress) 
                        || commonUtilities.fieldHasChanged('Is_Active__c', address, oldAddress)
                       )
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
                if (isRollUpEnabled != null && isRollUpEnabled && contactIds != null && !contactIds.isEmpty()) {
					//Invoke rollup logic
					Person360RollUpServices.invokeRollUp(contactIds, new List<String>{'Address__c'});
				}
            } catch(Exception e) {
                nebula.logger.error('Contact Id data set\r\r + ' + json.serializePretty(contactIds));
                nebula.logger.exception(e.getMessage(), e);
            }
        }
    }

    /**
     * @description Format the address__c.Name
     */
    public class FormatAddressName extends TriggerAbstract {

        /*
         * @description Identify a change significant enough to justify processing
         */ 
        public override void process(SObject record, SObject oldRec) {
            Address__c address = (Address__c)record;
            Address__c oldAddress = (Address__c)oldRec;
            if ((address.Street_Name__c != oldAddress.Street_Name__c) ||
                    (address.City__c != oldAddress.City__c) ||
                    (address.State__c != oldAddress.State__c) ||
                    (address.Country2__c != oldAddress.Country2__c)) {
                defaultAddressName(address);
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
            Person360Helper.setDefaultDate(Address__c.Start_Date__c, record);
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
        @TestVisible
        private Set<String> typesMap = new Set<String>();

        public TogglePrimary() {}
        
        public TogglePrimary(Set<Id> pConIds) {
            contactIds = (pConIds != null) ? pConIds : new Set<Id>();
        }

        /**
         * @description Collects Contact Ids on After Insert
         */
        public override void process(SObject record) {
            Address__c address = (Address__c)record;
            if (address.Is_Primary__c) {
                contactIds.add(address.Contact__c);
                recordIds.add(address.Id);
                typesMap.add(address.Classification__c);
            }
        }
        /**
         * @description Collect Contact Ids on After Update
         */
        public override void process(SObject record, SObject oldRec) {
            Address__c address = (Address__c)record;
            Address__c oldaddress = (Address__c)oldRec;
            if (address.Is_Primary__c && address.Is_Primary__c != oldaddress.Is_Primary__c) {
                contactIds.add(address.Contact__c);
                recordIds.add(address.Id);
                typesMap.add(address.Classification__c);
            }
        }
        /**
         * @description Untoggles Primary flag to false on other records
         */
        public override void execute() {

            try {
                if (!contactIds.isEmpty()) {
                    //Get All Primary excluding Current Records
                    List<Address__c> addresss = [SELECT Id, Is_Primary__c, Classification__c FROM Address__c
                                                  WHERE Contact__c IN:contactIds
                                                    AND Id NOT IN:recordIds
                                                    AND Is_Primary__c = true];
                    if (addresss != null) {
                        //Toggle Primary to False
                        for (Address__c rec : addresss) {
                            rec.Is_Primary__c = false;
                        }

                        //Disable FindNewPrimary as new Primary is set manually
                        Triggers.bypass('FindNewPrimary');
                        update addresss;
                        Triggers.clearBypass('FindNewPrimary');
                    }
                }
            } catch(Exception ex) {
                nebula.logger.error('Contact Id data set\r\r + ' + json.serializePretty(contactIds));
                nebula.logger.error('Address Id data set\r\r + ' + json.serializePretty(recordIds));
                nebula.logger.exception(ex.getMessage(), ex);
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
            Address__c address = (Address__c)record;
            Address__c oldAddress = (Address__c)oldRec;
            // Check if new value is different from old value
            if (address.Start_Date__c != oldAddress.Start_Date__c ||
                    address.End_Date__c != oldAddress.End_Date__c ||
                    address.Is_Deleted__c != oldAddress.Is_Deleted__c ||
                    address.Is_Active__c != oldAddress.Is_Active__c) {
                helper.init(address);
                helper.evaluateIsActiveFieldValue(address, oldAddress);
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
            Address__c rec = (Address__c)record;
            Address__c recOld = (Address__c)oldRec;
            // Check if new value is different from old value
            if (rec.Is_Active__c &&
                    rec.End_Date__c != null &&
                    rec.Is_Active__c != recOld.Is_Active__c) {
                rec.End_Date__c = null;
            } else if (rec.Is_Active__c == false &&
                       rec.Is_Active__c != recOld.Is_Active__c) {
                rec.End_Date__c = Date.today();
            }
        }
    }
    /**
     * @description Populates the hash for SObject
     */
    public class PopulateHash extends TriggerAbstract {

        // Set of fields that defines the uniqueness of an address
        private final Set<String> keyUidFields = new Set<String>{
            String.valueOf(Address__c.Contact__c),
            String.valueOf(Address__c.Street_Name__c),
            String.valueOf(Address__c.City__c),
            String.valueOf(Address__c.State__c),
            String.valueOf(Address__c.Post_Code__c),
            String.valueOf(Address__c.Country2__c)
        };

        /**
         * @description Process record on BEFORE INSERT event
         */
        public override void process(SObject record) {
            Address__c address = (Address__c)record;
            //Populate Hash Id
            address.Key_UID__c = generateAddressKey(address);
        }
        /**
         * @description Process records on BEFORE UPDATE event
         */
        public override void process(SObject record, SObject oldRec) {
            Address__c address = (Address__c)record;
            Address__c oldAddress = (Address__c)oldRec;

            // repopulate hash only if any of the keyUidFields have changed
            boolean bNeedsRecalc = false;
            for(String keyUid : keyUidFields) {
                String newAddressNullSafe = String.valueOf(address.get(keyUid) == null ? '' : address.get(keyUid));
                String oldAddressNullSafe = String.valueOf(oldAddress.get(keyUid) == null ? '' : oldAddress.get(keyUid));
                if(!newAddressNullSafe.equals(oldAddressNullSafe) || oldAddress.Key_UID__c == null) {
                    bNeedsRecalc = true;
                    break;
                }
            }
            //Replace the hash with new values
            if (bNeedsRecalc) {
                address.Key_UID__c = generateAddressKey(address);
            }
        }

        /**
         * @description Generate new Key UID based on record details
         */
        @TestVisible
        private String generateAddressKey(Address__c record) {
            Set<String> keySet = new Set<String>();
            for(String keyUid : keyUidFields) {
                keySet.add(String.valueOf(record.get(keyUid))?.toLowerCase().replaceAll('[^a-zA-Z0-9]',''));
            }
            return Person360Helper.generatePerson360Key(keySet);
        }
    }
    /**
     * @description GIVEN   Contact record have multiple child name records
     *              WHEN    User delete the primary name record
     *              THEN    Select the latest name record
     *              AND     set the Is_Primary__c to true
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
            Address__c address = (Address__c)record;

            // Filter out deleted non-primary records. Primary will not change as a result of removing a non-primary.
            if ((trigger.isDelete != true ) || (trigger.isDelete == true && address.Is_Primary__c == true)){
	            contactIds.add(address.Contact__c);
            }
        }

        /**
         * @description Process records on AFTER UPDATE event
         */
        public override void process(SObject record, SObject oldRec) {
            Address__c add = (Address__c)record;
            Address__c addOld = (Address__c)oldRec;

            // Check if new value is different from old value (if IsPrimary has changed, if IsActive has changed, or if the address has been deleted/undeleted
            if ((add.Is_Primary__c != addOld.Is_Primary__c) 
                || (add.Is_Active__c != addOld.Is_Active__c) 
                || (add.Is_Deleted__c != addOld.Is_Deleted__c) 
                || (add.Start_Date__c != addOld.Start_Date__c)
                || (add.Key_UID__c == null)) {
                contactIds.add(add.Contact__c);
            }
        }
        /**
         * @description Perform Post Processing logic
         */
        public override void execute() {
            try {
                // execute service method to calculate which Address record should be primary
                if (contactIds != null && !contactIds.isEmpty()) {
                    AddressServices.calculatePrimary(contactIds);
                }
            } catch(Exception e) {
                nebula.logger.error('Contact Id data set\r\r + ' + json.serializePretty(contactIds));
                nebula.logger.exception(e.getMessage(), e);
            }
        }
    }
    
    /**
     * @description Deprecated, to be removed (with all it's dependencies, i.e. Person360Helper.formatAddressName())
     */
    @TestVisible
    public static String defaultAddressName(Address__c address) {
        String strStreetName = String.isNotBlank(address.Street_Name__c) ? (String)address.Street_Name__c : null;
        String strCity = String.isNotBlank(address.City__c) ? (String)address.City__c : null;
        String strState = String.isNotBlank(address.State__c) ? (String)address.State__c : null;
        String strCountry = String.isNotBlank(address.Country2__c) ? (String)address.Country2__c : null;

        String fullAddress = Person360Helper.formatAddressName(strStreetName, strCity, strState, strCountry);
        if (String.isNotBlank(fullAddress)) {
            return fullAddress;
        }
        return '';
    }

    /**
     * @description Check Record Is Active and perform necessary defaults
     */
    public class CheckIsActive extends TriggerAbstract {
        /**
         * @description Before insert process
         */
        public override void process(SObject record) {
            Address__c address = (Address__c) record;
            resetPrimary(address);
        }

        /**
         * @description Before update process
         */
        public override void process(SObject record, SObject oldRecord) {
            Address__c address = (Address__c) record;
            resetPrimary(address);
        }

        private void resetPrimary(Address__c addressRecord) {
            if(!addressRecord.Is_Active__c && addressRecord.Is_Primary__c) {
                addressRecord.Is_Primary__c = false;
            }
        }
    }

    /**
     * @description process for re-parenting Address records to a different Channel.
     * 	This is mainly when Channel record got deleted from source (Callista)
     */
    public class FindNewParentChannel extends TriggerAbstract {

        List<Address__c> addressList = new List<Address__c>();
        List<Address__c> addressToFilterList = new List<Address__c>();
        Set<Id> contactIds = new Set<Id>();

        /**
         * @description On before insert, find new parent channel if :
         * 	- Address is not Active and
         * 	- Channel is not null (to know the source / original parent channel)
         */
        public override void process(SObject record) {
            Address__c addressRec = (Address__c) record;
            if(!addressRec.Is_Active__c && addressRec.Channel__c != null) {
                addressList.add(addressRec);
            }
        }

        /**
         * @description On before update, find new parent channel if :
         * 	- Address is not Active and
         * 	- Channel is not null and has changed
         */
        public override void process(SObject record, SObject oldRecord) {
            Address__c newAddress = (Address__c) record;
            Address__c oldAddress = (Address__c) oldRecord;

            if(!newAddress.Is_Active__c
                    && CommonUtilities.fieldHasChanged('Is_Active__c', newAddress, oldAddress)
                    && newAddress.Channel__c != null)
            {
                if (newAddress.Contact__c != null) {
                    contactIds.add(newAddress.Contact__c);
                }
                addressToFilterList.add(newAddress);
            }
        }

        public override void execute() {
            try {
                if (!addressToFilterList.isEmpty() && !contactIds.isEmpty()) {
                    Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id, Is_Student__c FROM Contact WHERE Id IN: contactIds]);
                    if (!contactMap.isEmpty()) {
                        Map<Id,Address__c> addressMap  = new Map<Id,Address__c>([select id from Address__c where id in :AddressToFilterList and channel__r.is_active__c = true]);
                        for (Address__c loopAddress : addressToFilterList) {
                        // Acceptance Criteria:
                        // A contact point of a non-student with source=Callista can be end-dated
                        // and remains end-dated despite an active Channel (lookup) record, i.e. the email remains active in the Channel record.
                        // This is to prevent find new channel when contact point end dated for non-student
                            if (addressMap.containsKey(loopAddress.id)
                                && contactMap.containsKey(loopAddress.Contact__c)
                                && contactMap.get(loopAddress.Contact__c).Is_Student__c == false
                                && loopAddress.Source__c == 'Callista') {
                                continue;
                            } else {
                                addressList.add(loopAddress);
                            }
                        }
                        if(!addressList.isEmpty()) {
                            Set<String> channelSourceFields = new Set<String> {'Address_Key__c'};
                            ChannelEventUtility.findNewContactPointChannel(addressList, channelSourceFields);
                        }
                    }
                }
            } catch (exception e) {
                nebula.logger.error('Contact Id data set\r\r + ' + json.serializePretty(contactIds));
                nebula.logger.exception(e.getMessage(), e);
            }
        }
    }

    /**
     * @description When Contact is not a student and when user selected a primary, do not deselect
     */
    public class EvaluateIfCanSetPrimary extends TriggerAbstract {

        Set<Id> contactIds = new Set<Id>();
        Map<Id, Address__c> addressRecords = new Map<Id, Address__c>();
        List<SObject> records = new List<SObject>();
        Map<Id, List<Address__c>> conIdAndRecordsMap = new  Map<Id, List<Address__c>>();

        public override void process(SObject record) {
            Address__c newAddress = (Address__c) record;
            if (newAddress.Is_Primary__c == true) {
                Person360Helper.setUserOrSystemToPrimarySetBy(newAddress);
                contactIds.add(newAddress.Contact__c);
                records.add(record);
                if (!conIdAndRecordsMap.containsKey(newAddress.Contact__c)) {
                    conIdAndRecordsMap.put(newAddress.Contact__c, new List<Address__c>{newAddress});
                } else {
                    conIdAndRecordsMap.get(newAddress.Contact__c).add(newAddress);
                }
            }
        }

        public override void process(SObject record, SObject oldRecord) {
            Address__c newAddress = (Address__c) record;
            Address__c oldAddress = (Address__c) oldRecord;
            if (newAddress.Is_Primary__c != oldAddress.Is_Primary__c && newAddress.Is_Primary__c == true) {
                Person360Helper.setUserOrSystemToPrimarySetBy(newAddress);
                contactIds.add(newAddress.Contact__c);
                addressRecords.put(newAddress.Id, newAddress);
                records.add(record);
                if (!conIdAndRecordsMap.containsKey(newAddress.Contact__c)) {
                    conIdAndRecordsMap.put(newAddress.Contact__c, new List<Address__c>{newAddress});
                } else {
                    conIdAndRecordsMap.get(newAddress.Contact__c).add(newAddress);
                }
            }
            // Always set newAddress.Primary_set_by__c to blank when newAddress.Is_Primary__c == false
            else if (newAddress.Is_Primary__c == false) {
                newAddress.Primary_set_by__c = '';
            }
        }

        public override void execute() {
            try {
                if(!contactIds.isEmpty() && !addressRecords.isEmpty()) {
                    for (Contact con : [SELECT Id, Is_Student__c,
                                        (SELECT Id, Is_Primary__c, Primary_set_by__c FROM Addresses__r WHERE Is_Active__c = true AND Is_Primary__c = true AND Id NOT IN: addressRecords.keySet())
                                        FROM Contact WHERE Id IN: contactIds]) {
                        Boolean isPrimarySetByUser = false;
                        for(Address__c iAddress : con.Addresses__r) {
                            if (iAddress.Primary_set_by__c == 'user') {
                                isPrimarySetByUser = true;
                                break;
                            }
                        }
                        for (Address__c sObj : conIdAndRecordsMap.get(con.Id)) {
                            if (!con.Is_Student__c && isPrimarySetByUser && UserInfo.getUserName().toLowerCase().contains(Person360Helper.automatedProcessUserName)) {
                                sObj.Is_Primary__c = false;
                                sObj.Primary_set_by__c = '';
                            }
                        }
                    }
                }
            }  catch(Exception e) {
                nebula.logger.error('Contact Id data set\r\r + ' + json.serializePretty(contactIds));
                nebula.logger.error('Address data set\r\r + ' + json.serializePretty(addressRecords));
                nebula.logger.exception(e.getMessage(), e);
            }
        }
    }
}