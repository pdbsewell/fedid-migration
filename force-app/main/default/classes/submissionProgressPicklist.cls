global class submissionProgressPicklist extends VisualEditor.DynamicPickList{
    
    global static List<VisualEditor.DataRow> getAllOptions()
    {
        Schema.DescribeFieldResult fieldResult = Application__c.Submission_Progress__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<VisualEditor.DataRow> dataRows = new List<VisualEditor.DataRow>();
        
        for( Schema.PicklistEntry f : ple)
        {
            VisualEditor.DataRow option = new VisualEditor.DataRow(f.getLabel(), f.getValue());
            dataRows.add(option);
        }
        return dataRows;
    }
    
    global override VisualEditor.DataRow getDefaultValue(){
        
        List<VisualEditor.DataRow> allOptions = getAllOptions();
        return allOptions[0];        
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        List<VisualEditor.DataRow> allOptions = getAllOptions();        
        VisualEditor.DynamicPickListRows myValues = new VisualEditor.DynamicPickListRows();
        myValues.addAllRows(allOptions);
        return myValues;
    }
}