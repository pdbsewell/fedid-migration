/**
 * @author : [Babyshark]
 * @description : service class to clone form elements from the source form to the target form
 * @group : Abroad Outbound
 * @date : 19/08/2024
 * @rev
 * 
 */
public class FormElementsCloneService {

    public class Inputs {
        @InvocableVariable
        public List<AO_Form_Element__c> formElementsList;
    
        @InvocableVariable
        public id newFormId;
	}
         
    /**
     * @description : Method to clone the form elements and their related records to the new form
     * @param inputs : List of Inputs wrapper
     * @return resultsList : List of Results
     */
    @InvocableMethod(label='Clone Form Elements' description = 'Clones the form elements to the cloned form')
    public static List<String> cloneFormElements(List<Inputs> inputsList) {
        
        //List<AO_Form_Element__c> newFormElementsList = new List<AO_Form_Element__c>();
        //List<sObject> recsToUpdate = new List<sObject>();
        List<String> resultsList = new List<String>();
        // Map to store the relationship between original child records and cloned child records
		Map<Id, Id> originalToClonedChildIdsMap = new Map<Id, Id>();
        try{
            for(Inputs formInput:inputsList){
                
                if(!formInput.formElementsList.isEmpty() && formInput.newFormId != null){
                    list<AO_Form_Element__c> clonedElements = cloneFormElementsWithBlanks(formInput.formElementsList,formInput.newFormId);
                    
                    insert clonedElements;
                    
                    Map<Id, AO_Form_Element__c> clonedElementsMap = new Map<Id, AO_Form_Element__c>(clonedElements);
                    List<AO_Form_Element__c> elementsToUpdate = new List<AO_Form_Element__c>();
                    Boolean isUpdate;
                    // After insert, map original to cloned element IDs
                    originalToClonedChildIdsMap = mapOriginalToClonedIds(formInput.formElementsList, clonedElements);
                    
                    //Update self-relationships
                    for(AO_Form_Element__c fe:formInput.formElementsList){
                        isUpdate = false;
                        
                        Id clonedElementId = originalToClonedChildIdsMap.get(fe.Id);
                        
                        if(clonedElementId != null && clonedElementsMap.containskey(clonedElementId)){
                            AO_Form_Element__c clonedElement = clonedElementsMap.get(clonedElementId);
                            
                            if(fe.Visibility_Rule_Form_Element__c != null && originalToClonedChildIdsMap.containskey(fe.Visibility_Rule_Form_Element__c)){
                                isUpdate = true;
                                clonedElement.Visibility_Rule_Form_Element__c = originalToClonedChildIdsMap.get(fe.Visibility_Rule_Form_Element__c);
                            }
                            
                            if(fe.Parent_Element__c != null && originalToClonedChildIdsMap.containskey(fe.Parent_Element__c)){
                                isUpdate = true;
                                clonedElement.Parent_Element__c = originalToClonedChildIdsMap.get(fe.Parent_Element__c);
                            }
                            
                            if(isUpdate)
                            	elementsToUpdate.add(clonedElement);
                        }
                        
                    }
                
                
                        Update elementsToUpdate;
                    }
                }
            }catch(Exception e){
                    nebula.logger.exception(e.getMessage(), e);
                }
        
    	return resultsList;
    }
    
    /**
     * @description : Method to clone the form elements and set their parent and visibility rules to null 
     * @param formElementsList : List of Form Elements
     * @param newformid : Id of the new form
     * @return clonedElements : List of cloned form elements
     */
    private static List<AO_Form_Element__c> cloneFormElementsWithBlanks(List<AO_Form_Element__c> formElementsList, id newformid){
        List<AO_Form_Element__c> clonedElements = new List<AO_Form_Element__c>();
        
        for(AO_Form_Element__c fe: formElementsList){
            
            AO_Form_Element__c newFormElement = fe.clone(false,false,false,false);
            newFormElement.Form__c = newformid;
            newFormElement.Visibility_Rule_Form_Element__c = null;
            newFormElement.Parent_Element__c = null;
            
            clonedElements.add(newFormElement);
        }
        
        return clonedElements;
    }
    
    /**
     * @description : Method to map the original form elements to the cloned form elements 
     * @param originalformElements : List of original form elements
     * @param clonedformElements : List of cloned form elements
     * @return elementMap :
     */
    private static map<Id,Id> mapOriginalToClonedIds(List<AO_Form_Element__c> originalformElements, List<AO_Form_Element__c> clonedformElements){
        Map<Id, Id> elementMap = new Map<Id, Id>();
        
        for (Integer i = 0; i < originalformElements.size(); i++) {
            AO_Form_Element__c origFormElem = originalformElements[i];
            AO_Form_Element__c clonedElement = clonedformElements[i];
            if(clonedElement.Label__c == origFormElem.Label__c && 
               clonedElement.Name == origFormElem.Name){
                	elementMap.put(origFormElem.Id, clonedElement.Id);
            }
            
        }
        
        return elementMap;
    }
}