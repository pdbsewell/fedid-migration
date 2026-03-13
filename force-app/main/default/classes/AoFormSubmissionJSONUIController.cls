/**
 * @author : [Babyshark]
 * @description : Controller to display JSON on Submission record page
 * @group : Abroad Outbound
 * @date : 19/03/2024
 * @rev
 * 
 */ 
public with sharing class AoFormSubmissionJSONUIController {
    /**
     * @description - Search Submission record based upon Id and return JSON value
     * @revision    
     */
    @AuraEnabled(cacheable=true)
    public static String getFormSubmissionResponse(String formSubmissionId){
        AO_Form_Submission__c aoSub = [SELECT Id, AO_Response_JSON__c FROM AO_Form_Submission__c WHERE Id=: formSubmissionId];  
        return aoSub.AO_Response_JSON__c;

    }
    /**
     * @description - Search Submission's Admin editable fields only to be updated by Faculty/Admin
     * @revision
     */
    @AuraEnabled(cacheable=true)
    public static List<InputDefinition> getAdminFormSubmissionResponse(String formSubmissionId){
        AO_Form_Submission__c aoSub = [SELECT Id, AO_Response_JSON__c FROM AO_Form_Submission__c WHERE Id=: formSubmissionId];
        List<Object> jsonObjList = (List<Object>) JSON.deserializeUntyped(aoSub.AO_Response_Json__c);
        List<InputDefinition> inputDef = new List<InputDefinition>();
        Map<Id,Object> formElementIds = new Map<Id, Object>();
        for (Object obj : jsonObjList) {
            Map<String, Object> jsonObj = (Map<String, Object>) obj;
            formElementIds.put((Id)jsonObj.get('elementId'),jsonObj.get('value'));
        }
        for(AO_Form_Element__c objFE : [SELECT Id, Name, Parent_Element__c, Label__c,Required__c, Read_Only__c, AO_Type__c,
                        Visibility_Rule_Operator__c, Visibility_Rule_Form_Element__c, Visibility_Rule_Value__c,
                        Element_Column_Width__c, Section_Columns__c, Admin_Only__c,
                        Element_Definition__r.Name, Element_Definition__r.AO_Default_Value__c, Element_Definition__r.AO_Help_Text__c, Element_Definition__r.Display_Text_Value__c,
                        Element_Definition__r.AO_Maps_to_Field__c, Element_Definition__r.AO_Maps_To_Object__c, Element_Definition__r.AO_Picklist_Values__c, Element_Definition__r.AO_Type__c,
                        Element_Definition__r.AO_Prefill_Value_Field__c, Element_Definition__r.AO_Prefill_Value_Object__c, Element_Definition__r.AO_Question__c
                    FROM AO_Form_Element__c
                    WHERE ID IN:formElementIds.keyset() 
                    AND Admin_Only__c = true
                    ORDER BY Element_Sequence__c]){
                        InputDefinition objId = new InputDefinition();
                        objId.readOnly = objFE.Read_Only__c;
                        objId.required = objFE.Required__c;
                        objId.questionLabel = objFE.Label__c;
                        objId.name = objFE.Label__c;
                        objId.type = objFE.Element_Definition__r.AO_Type__c;
                        objId.helpText = objFE.Element_Definition__r.AO_Help_Text__c;
                        objId.elementId = objFE.Id;
                        if(String.isNotBlank(objFE.Element_Definition__r.AO_Picklist_Values__c)) {
                            objId.options = new String[0];
                            for(String opt :objFE.Element_Definition__r.AO_Picklist_Values__c.split('\n')) {
                                objId.options.add(opt.trim());
                            }
                        }
                        if(formElementIds.containsKey(objFE.Id)){
                            objId.value = (String)formElementIds.get(objFE.Id);
                        }
                        inputDef.add(objId);
                    }
        return inputDef;
    }
    /**
     * @description - Update Admin fields on Submission.
     * @revision
     */
    @AuraEnabled
    public static String submitAdminResponse(String formSubmissionId, Object request){
        try{
            AO_Form_Submission__c objSub = new AO_Form_Submission__c(Id=formSubmissionId, AO_Response_JSON__c = JSON.serializePretty(request));
            update objSub;
            return objSub.Id;
        }
        catch(Exception ex){
            nebula.logger.exception(ex.getMessage(), ex);
            return ex.getMessage();
        }

    }
    public class InputDefinition {
        @AuraEnabled public Object defaultValue;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean readOnly;
        @AuraEnabled public String type; // text, textarea, number, date, time, datetime, checkbox, picklist, radio, file upload, checkbox group
        @AuraEnabled public String[] options;
        @AuraEnabled public String helpText;
        @AuraEnabled public String questionLabel;
        @AuraEnabled public String value;
        @AuraEnabled public String elementId;
        @AuraEnabled public String name;
    }
}