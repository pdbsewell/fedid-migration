/**
 * @author Sulung Chandra, UC Innovation
 * @date 8/29/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Dynamic picklist values for sorting Listing__c records
 */
global class PORTAL_UCIN_ListingSortPickList extends VisualEditor.DynamicPickList {
    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DataRow dv = new VisualEditor.DataRow('Newest', 'CreatedDate Desc');
        return dv;
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
        VisualEditor.DataRow dr1 = new VisualEditor.DataRow('Newest', 'CreatedDate Desc');
        VisualEditor.DataRow dr2 = new VisualEditor.DataRow('Oldest', 'CreatedDate');
        VisualEditor.DataRow dr3 = new VisualEditor.DataRow('Last Updated', 'LastModifiedDate Desc');
        values.addRow(dr1);
        values.addRow(dr2);
        values.addRow(dr3);
        
        return values;
    }
}