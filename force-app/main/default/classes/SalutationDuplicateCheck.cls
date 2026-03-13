/**
 * @author      Mac Domingo
 * @description Class that will handle the deduplication of Salutation records
 * @revision    17/07/2023 - Mac Domingo - Created
 */
public with sharing class SalutationDuplicateCheck {
    @TestVisible private SalutationSelector salutationSelector = new SalutationSelector();

    /*******************************************************************************
	* @author       Mac Domingo
	* @date         17/07/2023         
	* @description  Handles the actual deduplication of Salution records
    * @param        idSet - list of constituentIds that has potential duplicate salutation records
	* @revision     17/07/2023 - Mac Domingo - Created
	*******************************************************************************/
    public void removeDuplicateSalutations(Set<Id> idSet){
        List<Id> salutationIdsToDelete = new List<Id>();
        Map<String, List<ucinn_ascendv2__Salutation__c>> deDupeSalutationMap = new Map<String, List<ucinn_ascendv2__Salutation__c>>();        
        //generate unique key for all salutation records
        deDupeSalutationMap = generateUniqueKey(idSet);

        for(String sKey : deDupeSalutationMap.keySet()){
            List<ucinn_ascendv2__Salutation__c> salutationList = deDupeSalutationMap.get(sKey);
            //If there are more than 1 record on the list, means ther are duplicate salutations with the same uniqueKey
            if(salutationList.size() > 1){
                //Get Latest Date, this record will be retained and the rest will be deleted
                DateTime latestModifiedDate = getLatestLastModifiedDate(salutationList);
                for(ucinn_ascendv2__Salutation__c salutationRecord : salutationList){                
                    if(salutationRecord.LastModifiedDate != latestModifiedDate){
                        salutationIdsToDelete.add(salutationRecord.Id);
                    }               
                }   
            }                 
        }
        //Delete duplicate salutation records
        if(!salutationIdsToDelete.isEmpty()){
            deleteDuplicateSalutations(salutationIdsToDelete);
        }
    }

    /*******************************************************************************
	* @author       Mac Domingo
	* @date         17/07/2023         
	* @description  Handles the actual deduplication of Salution records
    * @param        recordId - contactId that has potential duplicate salutation records
	* @revision     17/07/2023 - Mac Domingo - Created
	*******************************************************************************/
    public void removeDuplicateSalutations(Id recordId){
        Set<Id> idSet = new Set<Id>();
        idSet.add(recordId);
        removeDuplicateSalutations(idSet);
    }

    /*******************************************************************************
	* @author       Mac Domingo
	* @date         17/07/2023         
	* @description  Generates a unique key for all Salutation records based on a combination of fields
    * @param        contactIdSet - list of constituentIds that has potential duplicate salutation records
	* @revision     17/07/2023 - Mac Domingo - Created
	*******************************************************************************/
    private Map<String, List<ucinn_ascendv2__Salutation__c>> generateUniqueKey (Set<Id> contactIdSet){
        Map<String, List<ucinn_ascendv2__Salutation__c>> salutationMap = new Map<String, List<ucinn_ascendv2__Salutation__c>>();
        List<ucinn_ascendv2__Salutation__c> salutationList = new List<ucinn_ascendv2__Salutation__c>();
        salutationList = salutationSelector.selectByConstituentId(contactIdSet);

        for(ucinn_ascendv2__Salutation__c salRecord : salutationList){
            String salutationKey;
            //build unique key by combining the values of these fields
            salutationKey = convertToLowerCase(salRecord.ucinn_ascendv2__Addressee_Line_1__c) + 
                            convertToLowerCase(salRecord.ucinn_ascendv2__Addressee_Line_2__c) + 
                            salRecord.ucinn_ascendv2__Contact_2__c +
                            salRecord.ucinn_ascendv2__Contact__c +
                            convertToLowerCase(salRecord.ucinn_ascendv2__Inside_Salutation__c) +
                            salRecord.ucinn_ascendv2__Salutation_Author__c + 	
                            salRecord.ucinn_ascendv2__Salutation_Record_Type_Formula__c + 	
                            salRecord.ucinn_ascendv2__Salutation_Type__c; 
            LogUtilityException.debug('Salutation Key ' + salutationKey);
            if(salutationMap.containsKey(salutationKey)){
                salutationMap.get(salutationKey).add(salRecord);
            } else{
                salutationMap.put(salutationKey, new List<ucinn_ascendv2__Salutation__c> {salRecord});
            }
        }
        return salutationMap;
    }

    /*******************************************************************************
	* @author       Mac Domingo
	* @date         17/07/2023         
	* @description  Gets the latest lastmodifieddate from the list of duplicate salutation records. This will determine which salutation record will by deleted
    * @param        salList - list of salutation record with the same uniqueKey
	* @revision     17/07/2023 - Mac Domingo - Created
	*******************************************************************************/
    private DateTime getLatestLastModifiedDate(List<ucinn_ascendv2__Salutation__c> salList){
        DateTime latestLastModifiedDate = null;
        for (ucinn_ascendv2__Salutation__c salutationRecord : salList) {
            if (latestLastModifiedDate == null || salutationRecord.LastModifiedDate > latestLastModifiedDate) {
                latestLastModifiedDate = salutationRecord.LastModifiedDate;
            }
        }
        return latestLastModifiedDate;
    }

    /*******************************************************************************
	* @author       Mac Domingo
	* @date         17/07/2023         
	* @description  Deletes the Salutation records
    * @param        salutationIds - list of salutation record ids to be deleted
	* @revision     17/07/2023 - Mac Domingo - Created
	*******************************************************************************/
    private void deleteDuplicateSalutations(List<Id> salutationIds){
        Database.DeleteResult[] deleteSalutationResults = Database.delete(salutationIds,false);
        for(Database.DeleteResult dr : deleteSalutationResults){
            if(!dr.isSuccess()){
                for(Database.error err : dr.getErrors()){
                    LogUtilityException.logExceptionMSG('Salutation', 'deleteDuplicateSalutations', err.getMessage());                    
                }
            }
        }
    }

    /*******************************************************************************
	* @author       Mac Domingo
	* @date         17/07/2023         
	* @description  Converts field value to lowercase
    * @param        field - field value to convert to lower case
	* @revision     124/07/2023 - Mac Domingo - Created
	*******************************************************************************/
    private string convertToLowerCase(String fieldValue){
        if(String.isNotEmpty(fieldValue) && fieldValue != null){
            return fieldValue.toLowerCase();
        }
        return fieldValue;
    }
}