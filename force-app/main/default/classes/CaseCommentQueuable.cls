/**
 * @description       : Updating Case Comments and Inbound Flag.
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 30-08-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
public with sharing class CaseCommentQueuable implements Queueable{
    public Map<Id, String> mEnquiryLatestComment = new Map<Id, String>();
    public Set<Id> setCaseIds = new Set<Id>();
       
    public CaseCommentQueuable(Map<Id, String> mapEnquiryLatestComment, Set<Id> sCaseIds) {
        this.mEnquiryLatestComment = mapEnquiryLatestComment;
        this.setCaseIds = sCaseIds;
    }
    
    public void execute(QueueableContext context) {
        try{
            List<Case> lstUpdateEnquiry = new List<Case>();
            Id enterCaseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
            
            for(Case updateEnqComment : [SELECT Id, Latest_Comment__c, RecordTypeId FROM Case WHERE Id IN :mEnquiryLatestComment.keySet()]){
                //.. added logic to reset latest email flag.
                if(mEnquiryLatestComment.containsKey(updateEnqComment.Id) && updateEnqComment.RecordTypeId == enterCaseRecTypeId && setCaseIds.contains(updateEnqComment.Id)){
                    Case updateEnq = new Case(Id=updateEnqComment.Id, Latest_Comment__c=mEnquiryLatestComment.get(updateEnqComment.Id), Latest_Inbound_Email__c=null);
                    lstUpdateEnquiry.add(updateEnq);
                }
                else if(mEnquiryLatestComment.containsKey(updateEnqComment.Id) && updateEnqComment.RecordTypeId == enterCaseRecTypeId && !setCaseIds.contains(updateEnqComment.Id)){
                    Case updateEnq = new Case(Id=updateEnqComment.Id, Latest_Comment__c=mEnquiryLatestComment.get(updateEnqComment.Id));
                    lstUpdateEnquiry.add(updateEnq);                        
                }
                else if(setCaseIds.contains(updateEnqComment.Id)){
                    Case updateEnq = new Case (Id=updateEnqComment.Id, Latest_Inbound_Email__c=null);
                    lstUpdateEnquiry.add(updateEnq);
                }
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