/**
 * @description       : DataManager class for DuplicateRecordSet.
 * @author            : Sheeba T
 * @group             : Utility
 * @last modified on  : 2022-02-10
 * @last modified by  : Sheeba T
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   2022-02-10   Sheeba   Initial Version 
**/
public class DM_DuplicateRecordSet {

    /***
    * Method name	: getMapOfDuplicateRecordSet
    * Description	: Handles selection of records
    * Author		: Sheeba
    * Return Type	: Map<Id, DuplicateRecordSet>
    * Parameter		: Set<Id> setOfDuplicateRecordSetIds -  scope
    */
    
    public static Map<Id, DuplicateRecordSet> getMapOfDuplicateRecordSet(
        Set<Id> setOfDuplicateRecordSetIds
    ) {
        // # return var
        Map<Id, DuplicateRecordSet> existingDupRecSetById = new Map<Id, DuplicateRecordSet>([SELECT Id, (Select Id, RecordId from DuplicateRecordItems)
                                                                                FROM DuplicateRecordSet 
                                                                                WHERE Id IN :setOfDuplicateRecordSetIds]);
        return existingDupRecSetById;
    }
}