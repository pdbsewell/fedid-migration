/**
* @description       : SS-71 Case Merge, SS-104 
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 01-08-2022
* @last modified by  : rajesh.punjabi@monash.edu
**/
public with sharing class CaseMergeQueuable implements Queueable{
    List<Case> lstMergedCases = new List<Case>();
    
    public CaseMergeQueuable(List<Case> lstCases) {
        this.lstMergedCases = lstCases;
    }
    
    /**
    * @description Process Cases and update the parent id.
    * @author rajesh.punjabi@monash.edu | 22-06-2022 
    * @param context 
    **/
    public void execute(QueueableContext context) {
        try{
            List<Case> lstCase = new List<Case>();

            //.. MasterRecrodId is not a writeable field.
            if(!System.Test.isRunningTest()){
                //.. update parent id.
                for(Case oCase: lstMergedCases){
                    lstCase.add(new Case (Id=oCase.Id, ParentId=oCase.MasterRecordId));
                }
            }
            else {
                for(Case oCase: lstMergedCases){
                    lstCase.add(new Case (Id=oCase.Id, ParentId=oCase.Id));
                }
            }
            
            //.. Disable trigger and update case.
            if(!lstCase.isEmpty()){
                TriggerCommon.disableTrigger('Case');
                update lstCase;
                TriggerCommon.enableTrigger('Case');
            }
        }
        catch(Exception ex){
            LogUtilityException.logException(ex);
        }
    }
}