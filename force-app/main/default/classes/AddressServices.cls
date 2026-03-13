/**
 * @description Apex class containing Address logic services
 * 
 * J.Mapanao 15.JUN.2020 - Added logic to not deselect primary when user previously selected manually
 * 95.JUL.2020 J.Mapanao - Updated logic to when the "is student" indicator is true, the address with the highest priority (as per Callista roll-up rank)
 *                         is rolled up to the Contact. This can deviate from the latest (by start date) address record.
 * 05/07/2024 Martin Cadman - Remove redundant updates of address records and included analysis logging
 *
 * */
public class AddressServices {

    private static final String ADDRESS_CLASSIFICATION_PRIVATE = 'Private';
    private static final String SCENARIO = 'Analysis';
    private static final String TAG      = 'Address Primary Analysis';
    private static String msgfmt = '[Active Student: {0}] [Override: {1}] [Class Selected: {2}] [Personal #: {3}] [Callista #: {4}] [Already Primary: {5}]';
    
    @TestVisible
    private static final Set<String> validSystemUserUsingUserNameSet = new Set<String>{
        'autoproc@'
    };

    /**
	 * Method to calculate Primary Phone for each Contact for every new record or an existing Phone record is updated
	 */
    public static void calculatePrimary(Set<Id> contactIds){
        List<SObject> recordsToUpdate = new List<SObject>();
        nebula.LogMessage logMsg;
        nebula.logger.setScenario(SCENARIO);
        
        /**
         * Try to find new Primary Private Address for each Contact
         * by querying all their child Address records, sorted by
         * LATEST Is_Active__c, Start_Date__c AND CreatedDate
         * 
         * Classification__c =: ADDRESS_CLASSIFICATION_PRIVATE
                                    AND 
         */
        for (Contact contact : [SELECT Id, Is_Student__c,
                                    (SELECT Id, Is_Primary__c, Name, Primary_set_by__c, Source__c, Callista_rollup_rank__c, contact__c
                                    FROM Addresses__r
                                    WHERE Is_Deleted__c = FALSE
                                    AND Is_Active__c = TRUE
                                    ORDER BY Start_Date__c DESC, CreatedDate DESC)
                                FROM Contact
                                WHERE Id IN: contactIds]){

            nebula.logger.fine('Calculating primary address',contact).addTag(TAG);
            nebula.logger.fine('There are '+ contact.Addresses__r.size() + ' addresses are under consideration',contact.Addresses__r).addTag(TAG);
                                    
			if (((contact.Addresses__r.size()==1) && (contact.Addresses__r[0].is_Primary__c)) 
            	|| (contact.Addresses__r.size()==0)) {
                break;
            }
                                    
            Boolean anyOtherPrimaryWhereSetByUser = false;
            List<Person360RollUpServices.ContactPointRecord> callistaSourceCustomList = new List<Person360RollUpServices.ContactPointRecord>();
            List<Address__c> nonCallistaList = new List<Address__c>();
            List<Address__c> allAddressList = new List<Address__c>();
			Address__c orRec;

            for (Address__c iAddress : contact.Addresses__r) {
                if (iAddress.Is_Primary__c && iAddress.Primary_set_by__c == 'user') {
                    anyOtherPrimaryWhereSetByUser = true;
                    orRec = iAddress;
                }

                allAddressList.add(iAddress);
                if (iAddress.Source__c == 'Callista' && String.isNotBlank(iAddress.Callista_rollup_rank__c)) {
                    callistaSourceCustomList.add(new Person360RollUpServices.ContactPointRecord(iAddress.Callista_rollup_rank__c, iAddress));
                } else {
                    nonCallistaList.add(iAddress);
                }
            }
              
			Address__c iAddress;
            if (contact.Is_Student__c) {
                if (!callistaSourceCustomList.isEmpty()) {
                    if ( callistaSourceCustomList.size() > 1) {
                        callistaSourceCustomList.sort();
					}
                    iAddress = (Address__c) callistaSourceCustomList[0].record;
                    logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No',anyOtherPrimaryWhereSetByUser==True?'Yes':'No','Callista - Lowest rank',''+nonCallistaList.size(), ''+callistaSourceCustomList.size(),iAddress.is_primary__c==true?'Yes':'No'}); 
                    nebula.logger.fine(logMsg,iAddress).addTag(TAG);

                    if (!iAddress.Is_Primary__c ) {
                        iAddress.Is_Primary__c = true;
                        recordsToUpdate.add(iAddress);
                    }
                } else {
                    if (!nonCallistaList.isEmpty()) {
                        iAddress = nonCallistaList[0];
                        logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No',anyOtherPrimaryWhereSetByUser==True?'Yes':'No','Personal - latest start date',''+nonCallistaList.size(), ''+callistaSourceCustomList.size(),iAddress.is_primary__c==true?'Yes':'No'}); 
                        nebula.logger.fine(logMsg,iAddress).addTag(TAG);
                        if (!iAddress.is_primary__c) {
                            iAddress.Is_Primary__c = true;
                            recordsToUpdate.add(iAddress);
                        }
                    }
                }
            } else {
                if (!anyOtherPrimaryWhereSetByUser) {
                    if (!allAddressList.isEmpty()) {
                        iAddress = allAddressList[0];
                        logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No',anyOtherPrimaryWhereSetByUser==True?'Yes':'No','Latest start date',''+nonCallistaList.size(), ''+callistaSourceCustomList.size(),iAddress.is_primary__c==true?'Yes':'No'}); 
                        nebula.logger.fine(logMsg,iAddress).addTag(TAG);
                        if (!iAddress.Is_Primary__c) {
                            iAddress.Is_Primary__c = true;
                            recordsToUpdate.add(iAddress);
                        }
                    }
                } else {
                    logMsg = new nebula.LogMessage(msgfmt,new List<String>{contact.Is_Student__c==true?'Yes':'No','Yes','Override',''+nonCallistaList.size(), ''+callistaSourceCustomList.size(),'-'}); 
                    nebula.logger.fine(logMsg,contact.id).addTag(TAG);
                }
            }
        }

        // Update address records
        if (!recordsToUpdate.isEmpty()) {

            nebula.logger.fine('Updating the address primary field (new primaries)',recordsToUpdate).addTag(TAG);
            Triggers.bypass('FindNewPrimary');
            List<Database.SaveResult> saveResults = Database.update(recordsToUpdate, false);
            List<Database.SaveResult> failedRecordsErrors = new List<Database.SaveResult>();
            for (Database.SaveResult saveResult : saveResults) {
                if (!saveResult.isSuccess()) {
                    failedRecordsErrors.add(saveResult);
                }
            }
            
            if (!failedRecordsErrors.isEmpty()) {
                nebula.logger.error('Address find new primary database errors',failedRecordsErrors);
            }
            Triggers.clearBypass('FindNewPrimary');
        }

        nebula.logger.endScenario(scenario);
        nebula.logger.saveLog();
    }
}