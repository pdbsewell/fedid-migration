/**
 * Bulk Data Processing service class for custom business processes
 * @author Jasmin Joy Rudio
 * @group Bulk Data Processing
 */
public with sharing class BulkDataProcessingService {
    public BulkDataProcessingService(){}
    /**
     * Class the returns a list of Manual Clauses (by Course Code) and selected Bulk Processing Data records
     * @param  bdpIds selected BDP record Ids
     * @return JSON string of the wrapper with available Manual Clauses and selected BDP
     */
    public class BDPManualClauseMatcher{
        Set<Id> BDPIdSet;
        Map<Id, Bulk_Data_Processing__c> bdpMap;
        @TestVisible MirrorClauseSelector mirrorClausesSelector;
        @TestVisible BulkDataProcessingSelector BDPSelector;

        public BDPManualClauseMatcher(String bdpIds){
            this.BDPIdSet = (Set<Id>)JSON.deserialize(bdpIds, Set<Id>.class);
            this.mirrorClausesSelector = new MirrorClauseSelector();
            this.BDPSelector = new BulkDataProcessingSelector();
            this.bdpMap = new Map<Id, Bulk_Data_Processing__c>();
        }

        public String execute(){
            BDPManualClauseWrapper wrapper = new BDPManualClauseWrapper();
            Set<String> courseCodes = new Set<String>();
            List<MirrorClauseServices.MirrorClauseWrapper> clauseWrapperList = new List<MirrorClauseServices.MirrorClauseWrapper>();
            this.bdpMap = new Map<Id, Bulk_Data_Processing__c>(this.BDPSelector.selectByIdOrderByCourseCode(this.BDPIdSet));

            for(Bulk_Data_Processing__c bdp: this.bdpMap.values()){     
                if(!courseCodes.contains(bdp.Transfer_Course_Code__c)){
                    courseCodes.add(bdp.Transfer_Course_Code__c);
                    MirrorClauseServices.MirrorClauseWrapper mirrorClause = new MirrorClauseServices.MirrorClauseWrapper();
                    mirrorClause.clauses = new List<Mirror_Clause__c>();
                    
                    for(Mirror_Clause__c clause: this.mirrorClausesSelector.selectActiveClauses()){
                        if(clause.Keywords__c <> null && clause.Keywords__c.contains(bdp.Transfer_Course_Code__c)){
                            mirrorClause.parentId = bdp.Id;
                            mirrorClause.parentObject = bdp;
                            mirrorClause.clauses.add(clause);
                        }
                    }
                    mirrorClause.parentName = bdp.Transfer_Course_Code__c;
                    clauseWrapperList.add(mirrorClause);
                }
            }
            wrapper.bulkDataProcessingMap = this.bdpMap;
            wrapper.manualClausesWrapper = clauseWrapperList;
            return JSON.serialize(wrapper);
        }

    }

    /**
     * Static method that inserts Associated (Manual) Clauses related to the selected Bulk Data Processing records
     * @param  BDPSelectedManualCLauses JSON string of BDPManualClauseWrapper from LWC
     * @return N/A
     */
    public static String saveBDPmanualClauses(String BDPSelectedManualCLauses){
        List<Associated_Clause__c> associatedClauses = new List<Associated_Clause__c>();
        if(!String.isEmpty(BDPSelectedManualCLauses)){
            BDPManualClauseWrapper wrapper = (BDPManualClauseWrapper) JSON.deserialize(BDPSelectedManualCLauses, BDPManualClauseWrapper.class);
            for(Bulk_Data_Processing__c bdp: wrapper.bulkDataProcessingMap.values()){
                //Associated Clauses
                List<Mirror_Clause__c> clauses = wrapper.clauseListMapByCourseCode.get(bdp.Transfer_Course_Code__c);
                associatedClauses.addAll(AssociatedClauseService.createBDPAssociatedClause(bdp, clauses));
            }

            if(!associatedClauses.isEmpty()){
                insert associatedClauses;
            }
        }
        
        return JSON.serialize(associatedClauses);
    }

    /**
     * Static method that updates Bulk Data Processing record status
     * @param  bdp Bulk Data Processing record
     * @param  status Status string to be set
     * @return JSON serialized string of the updated BDP record
     */
    @AuraEnabled
    public static String updateBDPStatus(String bdpId, String status){
        Bulk_Data_Processing__c toUpdateBDP = new Bulk_Data_Processing__c();
        toUpdateBDP.Id = bdpId;
        toUpdateBDP.Status__c = status;
        toUpdateBDP.isLocked__c = true;
        update toUpdateBDP;
        return JSON.serialize(toUpdateBDP);
    }




    public class BDPManualClauseWrapper{
        public Map<Id, Bulk_Data_Processing__c> bulkDataProcessingMap;
        List<MirrorClauseServices.MirrorClauseWrapper> manualClausesWrapper;
        //key: course code, value: list of selected manual clauses with the same course codes
        public Map<String, List<Mirror_Clause__c>> clauseListMapByCourseCode; 
        public BDPManualClauseWrapper(){
            this.bulkDataProcessingMap = new Map<Id, Bulk_Data_Processing__c>();
            this.manualClausesWrapper = new List<MirrorClauseServices.MirrorClauseWrapper>();
            this.clauseListMapByCourseCode = new Map<String, List<Mirror_Clause__c>>();
        }
    }

}