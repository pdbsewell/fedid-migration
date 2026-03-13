/**
 * @description       : Queuable class to update Keydate on Enquiries.
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 07-11-2023
 * @last modified by  : rajesh.punjabi@monash.edu
**/
public with sharing class KeyDateEnquiryQueuable  implements Queueable{

    Id keyDateId;
    Date keyDateDueDate;
    
    /**
    * @description 
    * @author rajesh.punjabi@monash.edu | 07-11-2023 
    * @param keyDateId 
    * @param keyDateDueDate 
    **/
    public KeyDateEnquiryQueuable(Id keyDateId, Date keyDateDueDate) {
        this.keyDateId = keyDateId;
        this.keyDateDueDate = keyDateDueDate;
    }
    
    /**
    * @description Process the update.
    * @author rajesh.punjabi@monash.edu | 07-11-2023 
    * @param context 
    **/
    public void execute(QueueableContext context) {
        try{
            List<Case> lstUpdateEnquiry = new List<Case>();
            Id caseMRORecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MRO').getRecordTypeId();
            for(Case updateKeyDate : [SELECT Id, KeyDate_Date__c, RecordTypeId, On_Hold_Date__c FROM Case WHERE Enquiry_Key_Date__c =:keyDateId AND Enquiry_Key_Date__c != null AND RecordTypeId =:caseMRORecTypeId]){
                updateKeyDate.KeyDate_Date__c = keyDateDueDate;
                lstUpdateEnquiry.add(updateKeyDate);
            }
            if(!lstUpdateEnquiry.isEmpty()){
                TriggerCommon.disableTrigger('Case');
                update lstUpdateEnquiry;
                TriggerCommon.enableTrigger('Case');
            }    
        }
        catch(Exception ex){
            LogUtilityException.logException(ex);
        }
    }
}