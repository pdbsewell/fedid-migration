/**
 * @author Sulung Chandra, UC Innovation
 * @date 8/29/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Dynamic picklist values for Listing__c.Category__c
 */
global class PORTAL_UCIN_ListingCategoryPickList extends VisualEditor.DynamicPickList {
    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DataRow dv = new VisualEditor.DataRow('', '');
        return dv;
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
        Schema.DescribeFieldResult fr = Listing__c.Category__c.getDescribe();
        for (Schema.PicklistEntry pe : fr.getPicklistValues()) {
            VisualEditor.DataRow dr = new VisualEditor.DataRow(pe.getLabel(), pe.getValue());
            values.addRow(dr);
        }
        return values;
    }
}