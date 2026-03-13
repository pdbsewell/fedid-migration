/**
 * @author          Mark Johnson: UC Innovation
 * @description    	In progress Interim batch. This batch is responsible for creation of sobjects related to the contact.
 * 					For example, when loading Interims with Address fields populated, the interim batches will create addresses on the corresponding contact.
 * 					This class allows us to specify logic specific to Monash.
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

public class EngageDedupeProcessInProgressBatch implements Database.Batchable<SObject>, Database.Stateful {
    ucinn_ascendv2.ascend_DEDUPE_ProcessInProgressBase base = new ucinn_ascendv2.ascend_DEDUPE_ProcessInProgressBase();
    String recordType = '';

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Default constructor. Will run with default logic.
	*******************************************************************************/
    public EngageDedupeProcessInProgressBatch() {
        base.additionalVariables.put('recordTypeName', recordType);
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Constructor with record type specified. Will only run on the specified interim record type.
	*******************************************************************************/
    public EngageDedupeProcessInProgressBatch(String recordType) {
        this.recordType = recordType;
        base.additionalVariables.put('recordTypeName', recordType);
    }

   	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Constructor with recordtype and override. Will run on a specific record type and a specified base class.
	*******************************************************************************/
    public EngageDedupeProcessInProgressBatch(String recordType, ucinn_ascendv2.ascend_DEDUPE_ProcessInProgressBase base) {
        this.recordType = recordType;
        this.base = base;
        base.additionalVariables.put('recordTypeName', recordType);
    }
    
   	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Kick off batch. Returns list of Interims with status 'In Progress' and with corresponding Contacts already existing.
	*******************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return base.batchStart(BC);
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Execute batch. Create related records for the contact.
	*******************************************************************************/
    public void execute(Database.BatchableContext BC, List<sObject> interimsToProcessList){
        base.batchExecute(BC, interimsToProcessList);
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Batch finish.
	*******************************************************************************/
    public void finish(Database.BatchableContext BC) {
        base.batchFinish(BC);
    }
}