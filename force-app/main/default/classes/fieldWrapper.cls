/**************************************************************************************************   
Apex Class Name      :  fieldWrapper
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is wrapper for storing field label(overriden if applicable) and value to show in enquiry detail page.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    27/06/2017                        Created.
***************************************************************************************************/
public class fieldWrapper
{
    @AuraEnabled
    public String fieldLabel{get;set;}
    @AuraEnabled
    public Object fieldValue{get;set;}
    /**
    * @Constructor     : fieldWrapper
    * @Input Parameters: String, Schema.DisplayType, Object, String
    * @Return Type     : NA
    * @Description     : parameterized constructor for the class to set the variables of class. 
    **/ 
    public fieldWrapper(String fieldLabel,Schema.DisplayType fielddataType,Object fieldValue,String fieldApiName)
    {
        Map<String, OverrideFieldLabel__c> fieldLabels= OverrideFieldLabel__c.getAll();
        this.fieldLabel=fieldLabels.containsKey(fieldApiName)?fieldLabels.get(fieldApiName).Label__c:fieldLabel;
        this.fieldValue=fielddataType==Schema.DisplayType.DateTime?((DateTime)fieldValue).format('dd/MM/yyyy'):(String)fieldValue;        
    }
}