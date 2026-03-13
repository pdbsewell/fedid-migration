/**
 * @author			Ayush Agrawal (ayush.agrawal@monash.edu)
 * @group			Retention (Monash Connect) - BabyShark
 * @description		RW2-427 Controller to generate Contact references dynamically in App Builder.
 * @revision		RW2-470 Support for the Contact Object itself.
 */

global class ContactDataSourceController extends VisualEditor.DynamicPickList {
    
    VisualEditor.DesignTimePageContext context;
    
    global ContactDataSourceController(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }
    
    global override VisualEditor.DataRow getDefaultValue() {
        return null;
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        Schema.DescribeSObjectResult describeSObjectResult = Schema.describeSObjects(new String[]{
            this.context.entityName
        })[0];
        
        Map<String, Schema.SObjectField> fieldMap = describeSObjectResult.fields.getMap();
        
        VisualEditor.DynamicPickListRows dynamicPickListRows = new VisualEditor.DynamicPickListRows();
        
        if(this.context.entityName == 'Contact') {
            dynamicPickListRows.addRow(new VisualEditor.DataRow('Use This Contact', 'Id'));
        }
        
        for(String field : fieldMap.keySet()) {
            Schema.DescribeFieldResult describeFieldResult = fieldMap.get(field).getDescribe();
            
            if(
            	(describeFieldResult.getType() != Schema.DisplayType.REFERENCE)
                ||
                (describeFieldResult.isNamePointing() == true)
                ||
                (describeFieldResult.getReferenceTo()[0].getDescribe().getName() != 'Contact')
            ) {
                continue;
            }
            
            dynamicPickListRows.addRow(new VisualEditor.DataRow(describeFieldResult.getLabel(), describeFieldResult.getName()));
        }
        
        return dynamicPickListRows;
    }
    
}