/**
 * @author          Mark Johnson: UC Innovation
 * @description    	In progress Interim batch. Specific logic for RE record type.
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

global class EngageDedupeProcessInProgressRE extends ucinn_ascendv2.ascend_DEDUPE_ProcessInProgressBase {
    global EngageDedupeProcessInProgressRE() {
        super();
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Query for all interims that are of status "In Progress" and are of Raiser's Edge record type.
	*******************************************************************************/
    global override Database.QueryLocator batchStart(Database.BatchableContext BC) {
        List<String> objectFields = new List<String>(ucinn_ascendv2__Interim__c.getSobjectType().getDescribe().fields.getMap().keySet());

        String query =  'SELECT ' + String.join(objectFields, ', ') + ', RecordType.Name, RecordType.DeveloperName, RecordType.NamespacePrefix ' +
                        'FROM ' + 'ucinn_ascendv2__Interim__c ' +
                        'WHERE ucinn_ascendv2__Status__c = \'In Progress\' ' +
                        'AND ucinn_ascendv2__Contact__c != null ' +
                        'AND RecordType.NamespacePrefix = null ' +
                        'AND RecordType.DeveloperName = \'Raisers_Edge_Interface\' ';
        
        return Database.getQueryLocator(query);
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Query for all interims that are of status "In Progress" and are of Raiser's Edge record type.
	*******************************************************************************/
    global override void batchExecute(Database.BatchableContext BC, List<sObject> interimsToProcessList) {
        Map<String, Object> params = new Map<String, Object>();

        // Clean up the interims before processing. Gets cleanup info from custom metadata type.
        EngageDedupeInterimCleanUpExtension cleanUp = new EngageDedupeInterimCleanUpExtension();
        interimsToProcessList = cleanUp.cleanListOfInterims(interimsToProcessList, null);

        Map<Boolean, List<sObject>> goodAndBadInterims = MONASH_validateInterimData(interimsToProcessList);

        if (goodAndBadInterims.get(false) != null && goodAndBadInterims.get(false).size() > 0) {
            update goodAndBadInterims.get(false);
        }
        if (goodAndBadInterims.get(true) != null && goodAndBadInterims.get(true).size() > 0) {
            params.put('interimsToProcessList', goodAndBadInterims.get(true));

            // Initialize lists to store data.
            MONASH_setupVariablesToStoreData(params);

            // Process interims to get contact
            MONASH_processInterims(params);

            // query for contact record
            MONASH_getContactFromInterims(params);

            // process each contact record
            MONASH_processEachContactRecord(params);

			//DML on lists created above.
            MONASH_runAddressDMLStatements(params);
            MONASH_runEmailDMLStatements(params);
            MONASH_runPhoneDMLStatements(params);
            MONASH_runInterimDMLStatements(params);
        }
        else {
            params.put('interimsToProcessList', new List<sObject>());
        }
    }


    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description 	Validations of Interim data pre-processing.
	*******************************************************************************/
    private Map<Boolean, List<sObject>> MONASH_validateInterimData(List<sObject> interimsToProcessList) {
        
        Map<Boolean, List<sObject>> goodAndBadInterims = new Map<Boolean, List<sObject>>();

        List<sObject> goodInterims = new List<sObject>();
        List<sObject> badInterims = new List<sObject>();

        goodAndBadInterims.put(true, goodInterims);
        goodAndBadInterims.put(false, badInterims);

        for (SObject interim : interimsToProcessList) {
            Ucinn_ascendv2__Interim__c interimRec = (Ucinn_ascendv2__Interim__c) interim;
				//PENDING VALIDATIONS HERE
				//Note: No longer perform validations in here for RE specifically. We leverage individual classes to perform validations now. Such as EngageDedupeMonashPhoneHandler.
                goodInterims.add(interimRec);
        }
        
        return goodAndBadInterims;
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description 	Set up lists to store data that we will perform DML on.
	*******************************************************************************/
    private void MONASH_setupVariablesToStoreData(Map<String, Object> params) {
        List<Contact> constituentUpdateList = new List<Contact>();
        params.put('constituentUpdateList', constituentUpdateList);

        //ADDRESS VARS
        List<Address__c> addressesToInsert = new List<Address__c>();
        List<Address__c> addressesToUpdate = new List<Address__c>();

        params.put('addressesToInsert', addressesToInsert);
        params.put('addressesToUpdate', addressesToUpdate);

        //EMAIL VARS
        List<Email__c> emailsToInsert = new List<Email__c>();
        List<Email__c> emailsToUpdate = new List<Email__c>();

        params.put('emailsToInsert', emailsToInsert);
        params.put('emailsToUpdate', emailsToUpdate);

        //PHONE VARS
        List<Phone__c> phonesToInsert = new List<Phone__c>();
        List<Phone__c> phonesToUpdate = new List<Phone__c>();

        params.put('phonesToInsert', phonesToInsert);
        params.put('phonesToUpdate', phonesToUpdate);

        //INTERIM VAR
        List<ucinn_ascendv2__Interim__c> finalInterimUpdateList = new List<ucinn_ascendv2__Interim__c>();
        params.put('finalInterimUpdateList', finalInterimUpdateList);
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description 	Process interims using base ascend logic. Can override if necessary.
	*******************************************************************************/
    private void MONASH_processInterims(Map<String, Object> params) {
        // perform default ascend logic 
        super.processInterims(params);
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description 	Query for contacts related to interims.
	*******************************************************************************/
    private void MONASH_getContactFromInterims(Map<String, Object> params) {

        Map<Id, ucinn_ascendv2__Interim__c> contactIdToInterimMap = (Map<Id, ucinn_ascendv2__Interim__c>) params.get('contactIdToInterimMap');

        //Query for contact data for contacts that are related to the interims in this Batch.
        List<Contact> constituents = [SELECT Id, ucinn_ascendv2__Donor_ID__c, ucinn_ascendv2__Contact_Type__c, AccountId,
                                        (SELECT Id,Is_Active__c,End_date__c, First_Name__c, Last_Name__c, Middle_Name__c, Prefix__c, Salutation__c, Type__c, Suffix__c, Is_Primary__c
                                         FROM Names__r ),
                                        (SELECT Id,Is_Active__c,End_date__c, Name, Classification__c, Is_Primary__c
                                         FROM Emails__r),
                                        (SELECT Id,Is_Active__c,End_date__c, Name, Type__c, Classification__c, Is_Primary__c
                                         FROM Phones__r),
                                        (SELECT Id,Is_Active__c,End_date__c, Name, Type__c, Classification__c, Is_Primary__c, State__c, Post_Code__c, City__c, Country2__c, Street_Name__c
                                         FROM Addresses__r)
                                     FROM Contact WHERE Id IN :contactIdToInterimMap.keySet()];

        params.put('constituents', constituents);
    }

     /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description 	Create address/phone/email lists for each contact.
	*******************************************************************************/
    private void MONASH_processEachContactRecord(Map<String, Object> params) {
        Map<Id, ucinn_ascendv2__Interim__c> contactIdToInterimMap = (Map<Id, ucinn_ascendv2__Interim__c>)params.get('contactIdToInterimMap');
        List<Contact> constituents = (List<Contact>)params.get('constituents');

        List<ucinn_ascendv2__Interim__c> finalInterimUpdateList = (List<ucinn_ascendv2__Interim__c>)params.get('finalInterimUpdateList');

        for (Contact curContact : constituents) {
            params.put('currentContact', curContact);
            params.put('currentInterim', contactIdToInterimMap.get(((Contact) curContact).Id));

            MONASH_createAddressListToUpdateAndInsert(params);
            MONASH_createEmailListsToUpdateAndInsert(params);
            MONASH_createPhoneListsToUpdateAndInsert(params);

            ucinn_ascendv2__Interim__c currentInterim = MONASH_updateInterimStatus(contactIdToInterimMap.get(((Contact) curContact).Id));

            finalInterimUpdateList.add(currentInterim);
        }
    }


     /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description 	Create address lists for each contact.
	*******************************************************************************/
    private void MONASH_createAddressListToUpdateAndInsert(Map<String, Object> params) {
        EngageDedupeMonashAddressHandler addressHandler = new EngageDedupeMonashAddressHandler();
        addressHandler.createAddressListToUpdateAndInsert(params);
    }

     /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description 	Create email lists for each contact.
	*******************************************************************************/
    private void MONASH_createEmailListsToUpdateAndInsert(Map<String, Object> params) {
        EngageDedupeMonashEmailHandler emailHandler = new EngageDedupeMonashEmailHandler();
        emailHandler.createEmailListToUpdateAndInsert(params);
    }

     /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description 	Create phone lists for each contact.
	*******************************************************************************/
    private void MONASH_createPhoneListsToUpdateAndInsert(Map<String, Object> params) {
        EngageDedupeMonashPhoneHandler phoneHandler = new EngageDedupeMonashPhoneHandler();
        phoneHandler.createPhoneListToUpdateAndInsert(params);
    }


     /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description 	Update status of interim for next batch process
	*******************************************************************************/
    private ucinn_ascendv2__Interim__c MONASH_updateInterimStatus(ucinn_ascendv2__Interim__c interim) {
        if (interim.ucinn_ascendv2__status__c != 'Manual Review') {
            if (interim.ucinn_ascendv2__status__c == 'Guarantor Not Processed') {
                interim.ucinn_ascendv2__status__c = 'In Progress';
                interim.ucinn_ascendv2__Manual_Review_Reason__c = 'Guarantor Not Processed';
            } else {
                interim.ucinn_ascendv2__status__c = 'Completed';
                interim.ucinn_ascendv2__Manual_Review_Reason__c = null;
            }
        }
        return interim;
    }

    /**********************************************************************************************
                                      START DML STATEMENTS
    **********************************************************************************************/


    // ADDRESS RELATION DML ******************************
    private void MONASH_runAddressDMLStatements(Map<String, Object> params) {
        List<Address__c> addressesToInsert = (List<Address__c>)params.get('addressesToInsert');
        List<Address__c> addressesToUpdate = (List<Address__c>)params.get('addressesToUpdate');
        System.debug(addressesToInsert);
        if (!addressesToUpdate.isEmpty()) {
            update addressesToUpdate;
        }
        if (!addressesToInsert.isEmpty()) {
            insert addressesToInsert;
        }
    }

    // EMAIL DML ******************************
    private void MONASH_runEmailDMLStatements(Map<String, Object> params) {
        List<Email__c> emailsToInsert = (List<Email__c>)params.get('emailsToInsert');
        List<Email__c> emailsToUpdate = (List<Email__c>)params.get('emailsToUpdate');

        if (!emailsToUpdate.isEmpty()) {
            update emailsToUpdate;
        }

        if (!emailsToInsert.isEmpty()) {
            insert emailsToInsert;
        }
    }

    //PHONE DML ******************************
    private void MONASH_runPhoneDMLStatements(Map<String, Object> params) {
        List<Phone__c> phonesToInsert = (List<Phone__c>)params.get('phonesToInsert');
        List<Phone__c> phonesToUpdate = (List<Phone__c>)params.get('phonesToUpdate');

        if (!phonesToUpdate.isEmpty()) {
            update phonesToUpdate;
        }

        if (!phonesToInsert.isEmpty()) {
            insert phonesToInsert;
        }
    }


    // CONSTITUENT DML ******************************
    private void MONASH_runConstituentDMLStatements(Map<String, Object> params) {
        List<Contact> constituentUpdateList = (List<Contact>)params.get('constituentUpdateList');

        if (!constituentUpdateList.isEmpty()) {
            update constituentUpdateList;
        }
    }

    // INTERIM DML ******************************
    private void MONASH_runInterimDMLStatements(Map<String, Object> params) {
        List<ucinn_ascendv2__Interim__c> finalInterimUpdateList = (List<ucinn_ascendv2__Interim__c>)params.get('finalInterimUpdateList');

        if (!finalInterimUpdateList.isEmpty()) {
            update finalInterimUpdateList;
        }
    }
}