/**
 * @description FieldMergeOr for comparing Fields
 * @group Engage
 */
public inherited sharing class FieldMergeOr implements IFieldMerge{
    /**
     * mergeField Merge Field Values from Account
     * @param  fieldDesc field description
     * @param  masterRecord masterAcc description
     * @param  duplicateRecord  childAcc description
     */
    public Object mergeField(Schema.DescribeFieldResult fieldDesc, SObject masterRecord, SObject duplicateRecord){ 
        String fieldName = fieldDesc.getName();
        // No Null for Boolean
        if (fieldName != 'Id' && fieldDesc.getType() == Schema.DisplayType.BOOLEAN) {
            if (Boolean.valueOf(masterRecord.get(fieldName)) || Boolean.valueOf(duplicateRecord.get(fieldName))) {
                // apply Boolean AND positive logic
                masterRecord.put(fieldName, true);
            } else {
                // apply Boolean AND negative  logic
                masterRecord.put(fieldName, false);
            }
            return (Object)masterRecord;
        }
        // No Null for Multi Select 
        else if (fieldName != 'Id' && fieldDesc.getType() == Schema.DisplayType.MULTIPICKLIST) {
            
            return (Object)masterRecord;
        }
        // No Null for All the remaining 
        else {
            masterRecord.put(fieldName, duplicateRecord.get(fieldName));
            return (Object)masterRecord;
        }
    }
}