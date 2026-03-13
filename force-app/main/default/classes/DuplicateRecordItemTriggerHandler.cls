/**
 * @description       : Trigger Handler to manage all DML and events on Duplicate Record Item
 * @author            : Sachin Shetty
 * @group             : Trigger Handler
 **/
public with sharing class DuplicateRecordItemTriggerHandler {
    
    /**
     * @author      Sachin Shetty
     * @description Uncheck 'Process' field on the parent Duplicate Record Set record 
     *              when child a Duplicate Record Item is deleted
     * @revision    2022-06-06 - Sachin Shetty - Created
     */
    public class UpdateDuplicateRecordSet extends TriggerAbstract {

        /**
        * No filtering of records
        */
        public override void process(SObject record) {
            //Process all Duplicate Record Items
            records.add(record);
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
            Set<Id> duplicateRecordSetIds = new Set<Id>();
            //Collect parent record Ids
            for(DuplicateRecordItem itemRecord : (List<DuplicateRecordItem>)records){
                duplicateRecordSetIds.add(itemRecord.DuplicateRecordSetId);
            }

            //Update Duplicate Record Set
            List<DuplicateRecordSet> duplicateRecordSetRecords = [SELECT Id, Process__c 
                                                                    FROM DuplicateRecordSet 
                                                                    WHERE Id IN :duplicateRecordSetIds];
            for(DuplicateRecordSet duplicateRecordSetRecord : duplicateRecordSetRecords){
                duplicateRecordSetRecord.Process__c = false;
            }
            update duplicateRecordSetRecords;
        }
    }
}