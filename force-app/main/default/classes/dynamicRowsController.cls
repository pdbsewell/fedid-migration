/**
 * @author          Steffi Narang
 * @description     This class is ceate.update and delete the LWc data table fo multiple row
 * @ Create         22/Dec/2020 This class is used for creating the row in Account Team members... 
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.1   2023-09-20   Davey Yu 	   ENGAGEIE-1745 Save rating field
 **/
public with sharing class dynamicRowsController {
        
    @AuraEnabled
     public static string saveAccountTeamMember(List<AccountTeamMember> records){
        string errorMessage;
         try{
             if(records.size()>0 && records != null){
                 List<AccountTeamMember> accOldLst = new List<AccountTeamMember>();
                 List<AccountTeamMember> accNewLst = new List<AccountTeamMember>();
                 for(integer i = 0; i < records.size(); i++){
                    AccountTeamMember acc = new AccountTeamMember();
                    if(records[i].Id != null){
                         acc.Id = records[i].Id;
                         if(records[i].TeamMemberRole != AccountTeamConstants.PRM && records[i].TeamMemberRole!= null && records[i].TeamMemberRole !=''){
                             acc.TeamMemberRole = records[i].TeamMemberRole;   
                             //ENGAGEIE-1745 save rating field
                             acc.Rating__c = records[i].Rating__c;
                             acc.AccountAccessLevel = AccountTeamConstants.READ;
                             acc.CaseAccessLevel    = AccountTeamConstants.CASE_PRIVATE;
                             acc.ContactAccessLevel = AccountTeamConstants.CASE_PRIVATE;
                             acc.OpportunityAccessLevel  = AccountTeamConstants.CASE_PRIVATE;                    
                             accOldLst.add(acc);
                             errorMessage ='SUCCESS';
                         }else{
                            errorMessage ='Please complete all the fields before clicking on Save';
                        }
                     }
                     if(records[i].Id == null){
                         if(records[i].TeamMemberRole != AccountTeamConstants.PRM && records[i].TeamMemberRole!= null && records[i].TeamMemberRole !=''){
                             acc.Id = records[i].Id;
                             acc.AccountAccessLevel = AccountTeamConstants.READ;
                             acc.CaseAccessLevel    = AccountTeamConstants.CASE_PRIVATE;
                             acc.ContactAccessLevel = AccountTeamConstants.CASE_PRIVATE;
                             acc.OpportunityAccessLevel  = AccountTeamConstants.CASE_PRIVATE;
                             acc.UserId = records[i].UserId;
                             acc.AccountID =records[i].AccountId;
                             acc.TeamMemberRole = records[i].TeamMemberRole;
                             acc.Rating__c = records[i].Rating__c;
                             accNewLst.add(acc);
                             errorMessage ='SUCCESS';
                             
                         }else{
                            errorMessage ='Please complete all the fields before clicking on Save';
                        }
                     }
                 }
                 if(errorMessage =='SUCCESS'){
                     if(!accOldLst.isEmpty())
                      update accOldLst;
                     if(!accNewLst.isEmpty())
                      insert accNewLst;
                 }                   
            }else{
                errorMessage ='Please add members to the Account Team or click on Cancel to proceed';
            }
         }catch(Exception e){
             string message= e.getMessage();
             if(message.contains('REQUIRED_FIELD_MISSING, Required fields are missing: [User]: [User]')){
                 errorMessage = 'Please complete all the fields before clicking on Save';
             }else{
                 errorMessage = 'An access issue was encountered for your user. Please contact your System Administrator';
             }
         }
         return errorMessage;
     }
     
     // get all the acocunt team members
     @AuraEnabled
     public static List<AccountTeamMember> getAccountTeam(string accId){
         return [SELECT Id, User.Name,TeamMemberRole,AccountId, Rating__c FROM AccountTeamMember where AccountId =:accId ORDER BY createddate ASC];
                 
     }
     // method is used to delete the account team members
     @AuraEnabled
     public static String deleteAccountTeam(String toDeleteId){
            string message;
            List<AccountTeamMember> acc = new List<AccountTeamMember>();
            AccountTeamMember a = new AccountTeamMember();
            a.Id = toDeleteId;
            acc.add(a);    
            Database.DeleteResult[] drList = Database.delete(acc, false);
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
     // get picklist values from meta data types 
    @AuraEnabled
 	public static List <String> getselectOptions() {
          List < String > allOpts = new list < String > ();
          // Get the object type of the SObject.
          Schema.sObjectType objType = AccountTeamRole__mdt.getSObjectType();
         
          // Describe the SObject using its object type.
          Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
         
          // Get a map of fields for the SObject
          map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
         
          // Get the list of picklist values for this field.
          list < Schema.PicklistEntry > values =
           fieldMap.get('AccountTeamRole__c').getDescribe().getPickListValues();

        
          // Add these values to the selectoption list.
          for (Schema.PicklistEntry a: values) {
           allOpts.add(a.getValue());
          }
          system.debug('allOpts ---->' + allOpts);
          allOpts.sort();
          return allOpts;
    }
    
     @AuraEnabled
 	public static List <String> getselectOptionsRating() {
          List < String > allOpts = new list < String > ();
          // Get the object type of the SObject.
          Schema.sObjectType objType = AccountTeamMember.getSObjectType();
         
          // Describe the SObject using its object type.
          Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
         
          // Get a map of fields for the SObject
          map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
         
          // Get the list of picklist values for this field.
          list < Schema.PicklistEntry > values =
           fieldMap.get('Rating__c').getDescribe().getPickListValues();

        
          // Add these values to the selectoption list.
          for (Schema.PicklistEntry a: values) {
           allOpts.add(a.getValue());
          }
          system.debug('allOpts ---->' + allOpts);
          allOpts.sort();
          return allOpts;
    }


 }