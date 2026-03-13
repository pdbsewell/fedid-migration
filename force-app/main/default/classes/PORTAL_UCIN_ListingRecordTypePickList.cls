/**
 * @author Sulung Chandra, UC Innovation
 * @date 8/29/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Dynamic picklist values for Listing__c.RecordType
 */
global class PORTAL_UCIN_ListingRecordTypePickList extends VisualEditor.DynamicPickList {
    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DataRow dv = new VisualEditor.DataRow('', '');
        return dv;
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
        for (RecordType rt : [Select Name, DeveloperName From RecordType Where SObjectType='Listing__c']) {
            VisualEditor.DataRow dr = new VisualEditor.DataRow(rt.Name, rt.DeveloperName);
            values.addRow(dr);
        }
        return values;
    }
}