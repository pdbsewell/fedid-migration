/**
* @author idha0002
* @date 12 Mar 2021
* @group Enterprise Engage
* @description Class to retrieve Account Name For Selected Contributor selected
*/
public class OpportunityCollaboratorController {
    @AuraEnabled
    public static Account getAccountDetails(Id accountId){
        try {
            Account relatedAccount = new Account();
            if(!String.IsBlank(accountId)){ 
                relatedAccount = [SELECT Id, Name, RecordType.DeveloperName FROM Account WHERE Id = :accountId];
            }  
            return relatedAccount;          
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());  
        }
    }
}