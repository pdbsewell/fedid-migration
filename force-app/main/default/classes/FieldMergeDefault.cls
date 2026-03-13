/**
 * @description FieldMergeAnd for comparing Fields
 * @group Enterprise Engage
 */
public inherited sharing class FieldMergeDefault implements IFieldMerge{
    /**
     * mapCompareAccount Merge Field Values from Account
     * @param  fieldDesc field description
     * @param  masterRecord masterAcc description
     * @param  duplicateRecord  childAcc description
     */
    public Object mergeField(Schema.DescribeFieldResult fieldDesc, SObject masterRecord, SObject duplicateRecord){
        String sfieldName = fieldDesc.getName();
        if(sfieldName != 'Id' && fieldDesc.getType() == Schema.DisplayType.BOOLEAN){
            if (Boolean.valueOf(masterRecord.get(sfieldName)) || Boolean.valueOf(duplicateRecord.get(sfieldName))) {
                // apply Boolean AND positive logic
                masterRecord.put(sfieldName, true);
            } else {
                // apply Boolean AND negative logic
                masterRecord.put(sfieldName, false);
            }
        }// No Null for Multi Select 
        else if (sfieldName != 'Id' && fieldDesc.getType() == Schema.DisplayType.MULTIPICKLIST) {   
            //Merge All Multi PickList Values Together
            Set<String> strCombined = new Set<String>();
            if(masterRecord.get(sfieldName) != null) {
                String strm = (String)masterRecord.get(sfieldName);
                strCombined.addAll(strm.split(';')); 
            }
            if(duplicateRecord.get(sfieldName) != null) {
                String strc = (String)duplicateRecord.get(sfieldName);
                strCombined.addAll(strc.split(';'));
            }
            String scomNew = String.join(new List<String>(strCombined),';');
            masterRecord.put(sfieldName, scomNew);
        }
        // No Null for All the remaining 
        else {
            //Replaces Null check on Master before replacing with child
            if (masterRecord.get(sfieldName) == null && duplicateRecord.get(sfieldName) != null){
                masterRecord.put(sfieldName, duplicateRecord.get(sfieldName));
            }
        }
        return (Object)masterRecord;
    }    
}