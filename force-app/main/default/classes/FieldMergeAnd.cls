/**
 * @description FieldMergeAnd for comparing Fields
 * @group Enterprise Engage
 */
public inherited sharing class FieldMergeAnd implements IFieldMerge{
    /**
     * mapCompareAccount Merge Field Values from Account
     * @param  fieldDesc field description
     * @param  masterRecord masterAcc description
     * @param  duplicateRecord  childAcc description
     */
    public Object mergeField(Schema.DescribeFieldResult fieldDesc, SObject masterRecord, SObject duplicateRecord){
        String fieldName = fieldDesc.getName();
        if(fieldName != 'Id' && fieldDesc.getType() == Schema.DisplayType.BOOLEAN){
            if (Boolean.valueOf(masterRecord.get(fieldName)) && Boolean.valueOf(duplicateRecord.get(fieldName))) {
                // apply Boolean AND positive logic
                masterRecord.put(fieldName, true);
            } else {
                // apply Boolean AND negative logic
                masterRecord.put(fieldName, false);
            }
        }// No Null for Multi Select 
        else if (fieldName != 'Id' && fieldDesc.getType() == Schema.DisplayType.MULTIPICKLIST) {   
            // TO be implemented
        }
        // No Null for All the remaining 
        else {
            //Replaces Null check on Master before replacing with child
            if (masterRecord.get(fieldName) == null && duplicateRecord.get(fieldName) != null) {
                masterRecord.put(fieldName, duplicateRecord.get(fieldName));
            }
        }
        return (Object)masterRecord;
    }
}