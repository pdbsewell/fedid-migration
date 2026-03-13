/**
 * @author          Mark Johnson: UC Innovation
 * @description    	New Interim batch. Base logic. Responsible for finding existing contacts based on external ID's. Checks potential duplicates as well.
 * 
 * 
 * 					Interim batch process is as follows: Key Value -> Find Duplicate -> New -> Pending -> In Progress.
 * 					Much of the logic is contained within ascend package.
 * 					1. Key Value batch: Creates Matching Key Values based on Matching rules on contact and interim. These are basically search tokens that allow us to find duplicate contact matches in the system.
 * 					2. Find Duplicate batch: Finds duplicate contacts using the Matching rules.
 * 					3. New Batch: Creates contacts for the interim if a duplicate is not found, associates contacts if exact match of external id exists. Sets contact to manual review if duplicates are associated with the interim.
 * 					4. Pending: For new contacts, or for contacts that have external id matches. This batch assigns values to the constituent record itself.
 * 					5. In Progress: This batch creates related records associated to the contact.
 * 
 * @revision        10/09/2019 - Mark Johnson - Initial version
 */

global class EngageDedupeProcessNewBase extends ucinn_ascendv2.ascend_DEDUPE_ProcessInterimNewBase {

    public String soql;
    public Set<string> interimFields = new Set<String> {
        'Id',
        'ucinn_ascendv2__Possible_Duplicate_Checked__c',
        'ucinn_ascendv2__Status__c',
        'ucinn_ascendv2__Contact__c',
        'ucinn_ascendv2__Contact__r.ucinn_ascendv2__Is_Trustee_Formula__c',
        'ucinn_ascendv2__First_Name__c',
        'ucinn_ascendv2__Last_Name__c',
        'ucinn_ascendv2__Employee_Type__c',
        'RecordType.Name',
        'ucinn_ascendv2__Master_Interim__c',
        'ucinn_ascendv2__Hospital_Batch_Checked__c',
        'ucinn_ascendv2__Physician_ID__c',
        'RE_Id__c',
        'Person_ID_unique__c'
    };

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Execution of batch that finds duplicate records, and populates contact, or changes status to manual review.
	*******************************************************************************/
    global override void batchExecute(Database.BatchableContext BC, List<sObject> lstOfInterimToProcess) {
        Map<Id, List<ucinn_ascendv2__Interim__c>> interimRecordTypeIdToRecordList = new Map<Id, List<ucinn_ascendv2__Interim__c>>();
        List<ucinn_ascendv2__Interim__c> interimRecList = (List<ucinn_ascendv2__Interim__c>) lstOfInterimToProcess;
        EngageDedupeUtils.populateContactLookupForInterimsByRecordTypeAndSystemIds(interimRecList);
        super.batchExecute(BC, interimRecList);
    }

    /*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         10/9/2019 
    * @description  Override process, to allow for pending processing when the contact is found.
    *******************************************************************************/
/*
    global override void processInterims(Map<String, Object> params) {
        List<sObject> lstOfInterimToProcess = (List<SObject>)params.get('lstOfInterimToProcess');

        Set<Id> interimIdNoContactSet = new Set<Id>();
        List<ucinn_ascendv2__Interim__c> interimListNoContact = new List<ucinn_ascendv2__Interim__c>();
        List<ucinn_ascendv2__Interim__c> updateInterimListToPending = new List<ucinn_ascendv2__Interim__c>();

        // Go though the list if there's no related Contact add the Id to the set, Add the interim to the list
        for (sObject sObj : lstOfInterimToProcess){
            ucinn_ascendv2__Interim__c interim = (ucinn_ascendv2__Interim__c)sObj;

            // Only status empty or new will get processed
            if (interim.ucinn_ascendv2__Status__c == null || interim.ucinn_ascendv2__Status__c == 'New') {
                if (validateDataBeforeUpdatingInterimStatus(interim)) {
                    if (interim.ucinn_ascendv2__Contact__c == null) {
                        if (interim.ucinn_ascendv2__Possible_Duplicate_Checked__c == true) {
                            interimIdNoContactSet.add(interim.Id);
                            interimListNoContact.add(interim);
                        }
                    } else if(interim.ucinn_ascendv2__Status__c == null || interim.ucinn_ascendv2__Status__c == 'New') {
                        interim.ucinn_ascendv2__Status__c = 'Pending';

                        updateInterimListToPending.add(interim);
                    }
                }
            }
        }

        params.put('interimIdNoContactSet', interimIdNoContactSet);
        params.put('interimListNoContact', interimListNoContact);
        params.put('updateInterimListToInProgress', updateInterimListToPending);
    }
*/

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Query for all interims that are of status "In Progress" and are of Raiser's Edge record type.
	*******************************************************************************/
    global override void batchConstructor(String recordTypeName) {
        soql =  'SELECT ' + String.join(new List<String>(interimFields), ',') + ' ' +
                'FROM ucinn_ascendv2__Interim__c ' +
                'WHERE (ucinn_ascendv2__Status__c = null OR ucinn_ascendv2__Status__c = \'New\') and RecordType.Name = \'' + String.escapeSingleQuotes(recordTypeName) + '\'';

        additionalVariables.put('recordTypeName', recordTypeName);
    }
    
    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Batch start. Queries for interims of status New.
	*******************************************************************************/
    global override Database.QueryLocator batchStart(Database.BatchableContext BC) {
        if (String.isEmpty(soql)) {
            System.abortJob(BC.getJobId());
            return null;
        }

        return Database.getQueryLocator(soql);
    }
}