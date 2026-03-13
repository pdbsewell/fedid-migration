/**
 * @description       : Class for Account Trigger Helper
 * @author            : Inderpal Dhanoa
 * @group             : Enterprise Engage
 * @last modified on  : 2022-02-13
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2022-02-13 - Inderpal Dhanoa - Added class for Opportunity COntact Role Object
**/
public with sharing class OpptyContactRoleController {
    /*
     * Method Name: saveOpportunityContactRole
     * @param  records for OpportunityContactRole
     * Description: method to save OpportunityContactRole
    */
    @AuraEnabled
    public static string saveOpportunityContactRole(List<OpportunityContactRole> records){
       string returnMessage;
        try{
            if(records != null && records.size()>0){
                List<OpportunityContactRole> contTeamOldLst = new List<OpportunityContactRole>();
                List<OpportunityContactRole> contTeamNewLst = new List<OpportunityContactRole>();
                List<OpportunityContactRole> contTeamDelLst = new List<OpportunityContactRole>();
                Id duplicateId;
                OpportunityContactRole contTeam;
                for(Integer i = 0; i < records.size(); i++){
                    contTeam = new OpportunityContactRole();
                    if(records[i].Id != null){
                        contTeam.Id = records[i].Id;
                            duplicateId = validateDuplicateOpportunityContactRoleMembers(contTeamOldLst, records[i]);
                            if(duplicateId == null){
                                contTeam.ContactId = records[i].ContactId;  
                                contTeamOldLst.add(contTeam);      
                            }else{
                                contTeam.Id = duplicateId;
                                contTeamDelLst.add(contTeam);
                            }                            
                            returnMessage ='SUCCESS';
                    }
                    if(records[i].Id == null){
                            contTeam.Id = records[i].Id;
                            contTeam.OpportunityId = records[i].OpportunityId;
                            contTeam.ContactId = records[i].ContactId;
                            contTeam.Role = records[i].Role;
                            contTeam.isPrimary = records[i].isPrimary;
                            contTeamNewLst.add(contTeam);
                            returnMessage ='SUCCESS';  
                    }
                }
                if(returnMessage =='SUCCESS'){
                    // Check Duplicates within the NEW list
                    for(Integer i = 0; i < contTeamNewLst.size(); i++){
                        for(Integer j = i+1; j < contTeamNewLst.size(); j++){
                            if(contTeamNewLst[i].ContactId == contTeamNewLst[j].ContactId){
                                contTeamNewLst.remove(i); 
                            }
                        }
                    }
                    // Check Duplicates in the NEW list with the Existing records and add to delete list
                    for(OpportunityContactRole newContTeam : contTeamNewLst){
                        for(Integer i = 0; i < contTeamOldLst.size(); i++){
                            if(contTeamOldLst[i].ContactId == newContTeam.ContactId){
                                contTeamDelLst.add(contTeamOldLst[i]); 
                            }
                        }            
                    }
                    if(!contTeamDelLst.isEmpty()){
                        delete contTeamDelLst;
                    }
                    if(!contTeamNewLst.isEmpty())
                        insert contTeamNewLst;
                }                   
           }else{
            returnMessage ='Please add members to the Account Team or click on Cancel to proceed';
           }
        }catch(Exception e){
            string message= e.getMessage();
            if(message.contains('REQUIRED_FIELD_MISSING, Required fields are missing: [User]: [User]')){
                returnMessage = 'Please complete all the fields before clicking on Save';
            }else{
                returnMessage = 'An access issue was encountered for your user. Please contact your System Administrator';
            } 
        }
        return returnMessage;
    }

    // validate Duplicates
    /*
    * Method Name: validateDuplicateOpportunityContactRoleMembers
     * @param  OpportunityContactRole for contTeamLst
     * @param  OpportunityContactRole for check for duplicate of contTeam
     * @param Id boolean parameter to check if the record is duplicate
     * Description: method to validate duplicate OpportunityContactRole
    */
    public static Id validateDuplicateOpportunityContactRoleMembers(List<OpportunityContactRole> oppContRoleLst, OpportunityContactRole oppContRole){
        Id duplicateId;
        for(OpportunityContactRole oppContRoleMemb : oppContRoleLst){
            if(oppContRole.ContactId == oppContRoleMemb.ContactId){ 
                duplicateId = oppContRoleMemb.Id; 
                return duplicateId;   
            }
        }
        return duplicateId;           
    }

    /*
    * Method Name: getOpportunityContactRole
     * @param  opptyId primary Opportunity ID description
     * @param  fieldApiName Name of the field to get the picklist values
     * @return OpptyContactRoleWrapper wrapper class of the OpportunityContactRole records and picklist values
     * Description: method to retrieve OpportunityContactRole records and Picklist Values 
    */
    @AuraEnabled
    public static OpptyContactRoleWrapper getOpportunityContactRole(string opptyId, String fieldApiName){
        OpptyContactRoleWrapper o_OpptyContactRoleWrapper = new OpptyContactRoleWrapper();
        List<OpportunityContactRole> relatedOpptyRoleRecords = [SELECT Id,Role,ContactId, Contact.Name,OpportunityId, Opportunity.Name, IsPrimary FROM OpportunityContactRole WHERE OpportunityId =:opptyId ORDER BY createddate ASC];
        o_OpptyContactRoleWrapper.relatedOpptyRoleRecords = relatedOpptyRoleRecords;
        o_OpptyContactRoleWrapper.rolePicklistValues = getOppContRolePickListValues(fieldApiName);
        return o_OpptyContactRoleWrapper;             
    }

    /*
    * Method Name: getOppContRolePickListValues
     * @param  fieldApiName field name
     * @return Map<String, String> map of picklist values
     * Description: method to retrieve OpportunityContactRole Field Picklist Values 
    */
    public static Map<String, String> getOppContRolePickListValues(String fieldApiName){
        Map<String, String> pickListValuesList= new Map<String, String>();
        if(string.isNotBlank(fieldApiName)){
            Map<String, Schema.SObjectField> fieldsMap= OpportunityContactRole.getSobjectType().getDescribe().fields.getMap();
            List<Schema.PicklistEntry> ple = fieldsMap.get(fieldApiName).getDescribe().getPicklistValues();
            for(Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.put(String.Valueof(pickListVal.getValue()),String.Valueof(pickListVal.getLabel()));
            }
        }
        return pickListValuesList; 
    }

    /*
    * Method Name: getContRoleRecordTypeMapping
     * @param  sObjectName name of the Object
     * @param  fieldApiName Name of the field to get the picklist values
     * @return OpptyContactRoleWrapper wrapper class of the OpportunityContactRole records and picklist values
     * Description: method to retrieve OpportunityContactRole records and Picklist Values 
    */
    @AuraEnabled
    public static Map<String, List<String>> getContRoleRecordTypeMapping(String sObjectName, String fieldName){
        Map<String, List<String>> m_recordTypeLinkedValues = new Map<String, List<String>>();
        List<Field_Picklist_RecordType_Mapping__mdt> l_linkedMapping = new List<Field_Picklist_RecordType_Mapping__mdt>();
        for(Field_Picklist_RecordType_Mapping__mdt pick: [SELECT Id, FieldName__c, RecordType__c, SObjectName__c, Value__c 
                                                          FROM Field_Picklist_RecordType_Mapping__mdt 
                                                          WHERE SObjectName__c = :sObjectName AND FieldName__c= :fieldName]){
            List<String> l_linkedFields;
            if(m_recordTypeLinkedValues.containsKey(pick.RecordType__c)){
                l_linkedFields = m_recordTypeLinkedValues.get(pick.RecordType__c);
            }else{
                l_linkedFields = new List<String>();
            }
            l_linkedFields.add(pick.Value__c);
            m_recordTypeLinkedValues.put(pick.RecordType__c, l_linkedFields);
        }
        return m_recordTypeLinkedValues; 
    } 

    /*
    * Method Name: getContactRecordTypeName
     * @param  Id recordId name of the Object
     * @return String Record type Developer name
     * Description: method to retrieve record type develoepr name
    */
    @AuraEnabled
    public static String getContactRecordTypeName(Id recordId){
        String recordTypeName;
        if(String.isNotBlank(recordId)){
            Contact lookupContact = [SELECT Id, RecordType.DeveloperName FROM Contact WHERE Id = :recordId];
            recordTypeName = lookupContact.RecordType.DeveloperName;
        }
        return recordTypeName;
    }


    public class OpptyContactRoleWrapper{
        @AuraEnabled
        public Map<String, String> rolePicklistValues;
        @AuraEnabled
        public List<OpportunityContactRole> relatedOpptyRoleRecords;
        @AuraEnabled
        public Map<String, List<String>> m_recordTypeLinkedValues;
    }

    /*
    * Method Name: deleteOpportunityContactRole
     * @param  toDeleteId Id of the deleteOpportunityContactRole to be deleted
     * Description: method to delete deleteOpportunityContactRole records
    */
    @AuraEnabled
    public static String deleteOpportunityContactRole(String toDeleteId){
        string message;
        List<OpportunityContactRole> oppContRoleList = new List<OpportunityContactRole>();
        OpportunityContactRole oppContRole = new OpportunityContactRole();
        oppContRole.Id = toDeleteId;
        oppContRoleList.add(oppContRole);    
        Database.DeleteResult[] drList = Database.delete(oppContRoleList, false);
        List<String> deletedIds = new List<String>();
        List<String> errorMessages = new List<String>();
            // Iterate through each returned result
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                deletedIds.add(dr.getId());
                message = 'SUCCESS';                
            }else {
                // Operation failed, so get all errors                
                for(Database.Error err : dr.getErrors()) {
                    errorMessages.add(err.getMessage());
                }
                message= 'ERROR';
            }
        }
    return message;
    }
}