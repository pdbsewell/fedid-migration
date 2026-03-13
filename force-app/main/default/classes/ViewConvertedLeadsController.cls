/**
 * @description       : Service class for ViewLeadsFromAccount LWC
 * @author            : Davey Yu
 * @date              : 2024-03-21
 * @group             : Enterprise
**/
public without sharing class ViewConvertedLeadsController {
    /*
    * Method Name: getEntityData
    * @param  objectId record id to query
    * @return List<LeadWrapper> list of leads related to the same account
    * Description: invoked from ViewLeadsFromAccount LWC to retrieve the list of lead records
    */
    @AuraEnabled
    public static List<LeadWrapper> getEntityData(Id objectId) {
        
        List<LeadWrapper> o_LeadWrapperList = new List<LeadWrapper>();   
        List<Lead> leadList = new List<Lead>();
        Id enterpriseRecordTypeId = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
        //check if record id is lead or account before querying the related lead records
        if(objectId !=  null){
            if(objectId.getSobjectType().getDescribe().getName() == 'Lead'){
                Lead primaryLead = [Select id, Account__c from Lead where Id =: objectId];
                
                if(primaryLead.Account__c != null){
                    leadList = [SELECT Id, Name, Status, Company, CreatedDate, Account__c, LeadSource
                                FROM Lead 
                                WHERE Account__c =: primaryLead.Account__c and RecordTypeId =: enterpriseRecordTypeId 
                                ORDER BY CreatedDate DESC LIMIT 200];
                }else{
                    return null;
                }
            }else if(objectId.getSobjectType().getDescribe().getName() == 'Account'){
                leadList = [SELECT Id, Name, Status, Company, CreatedDate, Account__c, LeadSource
                            FROM Lead 
                            WHERE Account__c =: objectId and RecordTypeId =: enterpriseRecordTypeId 
                            ORDER BY CreatedDate DESC LIMIT 200];
            }
        }else{
            return null;
        }
            
        if(leadList.size() > 0){
            for(Lead ld : leadList){ 
                LeadWrapper leadWrap = new LeadWrapper();
                leadWrap.id = ld.Id;
                leadWrap.name = ld.name;
                leadWrap.companyName = ld.Company;
                leadWrap.createdDate = Date.ValueOf(ld.CreatedDate);
                leadWrap.status = ld.Status;
                leadWrap.leadSource = ld.LeadSource;
                leadWrap.accountId = ld.Account__c;
                o_LeadWrapperList.add(leadWrap);
            }
        }else{
            return null;
        }
        return o_LeadWrapperList;
    }

    //lead wrapper
    public class LeadWrapper{
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String companyName;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Date createdDate;
        @AuraEnabled
        public String leadSource;
        @AuraEnabled
        public Id accountId;
    }
}