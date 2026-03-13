/*******************************************************************************
* @author       Inderpal Dhanoa
* @date         02/02/2022
* @description  Controller class for ContactTeamdataTable LWC
* @revision     1.0
*******************************************************************************/
public with sharing class ContactTeamDataTableController {
    
    /*
     * Method Name: saveContactTeamMember
     * @param  records records of Contact Team members to be updated or saved
     * @return String message of the Error/Success 
     * Description: method to save/update Contact Team members
    */
    @AuraEnabled
    public static string saveContactTeamMember(List<ContactTeam__c> records){
       string errorMessage;
        try{
            if(records.size()>0 && records != null){
                List<ContactTeam__c> contTeamOldLst = new List<ContactTeam__c>();
                List<ContactTeam__c> contTeamNewLst = new List<ContactTeam__c>();
                List<ContactTeam__c> contTeamDelLst = new List<ContactTeam__c>();
                for(Integer i = 0; i < records.size(); i++){
                    ContactTeam__c contTeam = new ContactTeam__c();
                   if(records[i].Id != null){
                        contTeam.Id = records[i].Id;
                        if(records[i].Role__c != null && records[i].Role__c !=''){  
                            Id duplicateId = validateDuplicateContactTeamMembers(contTeamOldLst, records[i]);
                            if(duplicateId == null){
                                contTeam.Role__c = records[i].Role__c;    
                                contTeam.Team_Member__c = records[i].Team_Member__c;                
                                contTeamOldLst.add(contTeam); 
                            }else{
                                contTeam.Id = duplicateId;
                                contTeamDelLst.add(contTeam);     
                            }                            
                            errorMessage ='SUCCESS';
                        }else{
                           errorMessage ='Please complete all the fields before clicking on Save';
                       }
                    }
                    if(records[i].Id == null){
                        if(records[i].Role__c != AccountTeamConstants.PRM && records[i].Role__c!= null && records[i].Role__c !=''){
                            Id duplicateId = validateDuplicateContactTeamMembers(contTeamNewLst, records[i]);
                            if(duplicateId == null){
                                contTeam.Id = records[i].Id;
                                contTeam.Contact__c = records[i].Contact__c;
                                contTeam.Team_Member__c = records[i].Team_Member__c;
                                contTeam.Role__c = records[i].Role__c;
                                contTeamNewLst.add(contTeam);
                            }
                            errorMessage ='SUCCESS';    
                        }else{
                           errorMessage ='Please complete all the fields before clicking on Save';
                       }
                    }
                }
                if(errorMessage =='SUCCESS'){
                    // Check for Duplicates among the NEW and Existing records
                    for(ContactTeam__c newContTeam : contTeamNewLst){
                        for(Integer i = 0; i < contTeamOldLst.size(); i++){
                            if(contTeamOldLst[i].Team_Member__c == newContTeam.Team_Member__c){ 
                                contTeamDelLst.add(contTeamOldLst[i]);   
                                contTeamOldLst.remove(i);  
                            }
                        }            
                    }

                    if(!contTeamDelLst.isEmpty()){
                        delete contTeamDelLst;
                    }
                    if(!contTeamOldLst.isEmpty())
                        update contTeamOldLst;
                    if(!contTeamNewLst.isEmpty())
                        insert contTeamNewLst;
                }                   
           }else{
               errorMessage ='Please add members to the Account Team or click on Cancel to proceed';
           }
        }catch(Exception e){
            string message= e.getMessage();
            if(message.contains('REQUIRED_FIELD_MISSING, Required fields are missing: [User]: [User]')){
                errorMessage = 'Please complete all the fields before clicking on Save';
            }else if(message.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                errorMessage = e.getMessage();
            }else{
                errorMessage = 'An access issue was encountered for your user. Please contact your System Administrator';
            }
        }
        return errorMessage;
    }

    /*
     * Method Name: validateDuplicateContactTeamMembers
     * @param  contTeamLst records of Contact Team members to be validated
     * @param  contTeam record of Contact Team members to be compared
     * @return Id Id of the duplicate Record 
     * Description: method to compare Contact Team members for duplicate records
    */
    public static Id validateDuplicateContactTeamMembers(List<ContactTeam__c> contTeamLst, ContactTeam__c contTeam){
        Id duplicateId;
        for(ContactTeam__c contTeamMemb : contTeamLst){
            if(contTeam.Team_Member__c == contTeamMemb.Team_Member__c){
                duplicateId = contTeamMemb.Id; 
                return duplicateId;   
            }
        }
        return duplicateId;           
    }

    
    /* Method Name: getContactTeam
     * @param  conId primary Account ID description
     * @return List<ContactTeam__c> retrieved related Contact Team members
     * Description: method to retrieve related Accounts based on the Contact Id
    */
    @AuraEnabled
    public static List<ContactTeam__c> getContactTeam(string conId){
        return [SELECT Id, Team_Member__c, Team_Member__r.Id, Team_Member__r.Name, Role__c, Contact__c, Contact__r.Name FROM ContactTeam__c WHERE Contact__c =:conId ORDER BY createddate ASC];            
    }

    /*
    * Method Name: deleteContactTeam
     * @param  toDeleteId Id of the Account tot be deleted
     * @return String message of the Error/Success 
     * Description: method to merge 2 Accounts
    */
    @AuraEnabled
    public static String deleteContactTeam(String toDeleteId){
        string message;
        List<ContactTeam__c> contTeamList = new List<ContactTeam__c>();
        ContactTeam__c contTeam = new ContactTeam__c();
        contTeam.Id = toDeleteId;
        contTeamList.add(contTeam);    
        Database.DeleteResult[] drList = Database.delete(contTeamList, false);
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