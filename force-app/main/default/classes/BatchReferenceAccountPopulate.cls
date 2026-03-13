/**
 * @author          Steffi
 * @description     Batch Class for update Reference account of Contact for onboarding Alumni PENGAGE-1867
 * @revision   
 */
global class BatchReferenceAccountPopulate implements Database.Batchable < sObject >{


    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        //get Welcome campaign Id from Custom setting
        Id alumniWelcomeCampaignId = Alumni_Welcome_Campaign__c.getOrgDefaults().id__c;
        //get all the contacts from campaignmember
        String query = 'SELECT Id,CreatedDate,ContactId,Contact.Reference_Account__c FROM Campaignmember where Contact.Reference_Account__c =  null and CampaignId =: alumniWelcomeCampaignId';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List < Campaignmember > scope) {
        try{
            // get Alumini account from Custom setting (PENGAGE-1710) to link contact to reference account (for sharing set) 
            Alumni_Community_User_Access__c Alumni_AccountSetting = Alumni_Community_User_Access__c.getInstance();
            
        	set < Id > conIds = new set < Id > ();
            List<Contact> updateContactList = new List<Contact>(); 
            
            //get all the contacts who added in Campiagn
            for (Campaignmember members: scope) {
                //get all contacts having reference account null..
                if(String.isBlank(members.Contact.Reference_Account__c)){
                	conIds.add(members.ContactId);    
                }	
            }
            if(!conIds.isEmpty()){
                // capture contacts to be updated with reference account
                for(Contact con : [select id,Reference_Account__c from Contact where id IN :conIds]){
                    updateContactList.add(new Contact(Id=con.Id, Reference_Account__c=Alumni_AccountSetting.Id__c));  
                }
                // if list is not empty
                if(!updateContactList.isEmpty()) {
                    try {
                        //muting the contact trigger
                        TriggerCommon.disableTrigger('Contact');
                        update updateContactList;
                        TriggerCommon.enableTrigger('Contact');
                    } catch(Exception exc) {
                        LogUtilityException.logExceptionMSG('Contact',exc.getMessage(),'Error');
                    }
                }
        	}
        
        }catch(exception err) {
            LogUtilityException.logExceptionMSG('Contact',err.getMessage(),'Error');
        }
        
    }
    global void finish(Database.BatchableContext BC) {
    
    }

}