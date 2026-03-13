/**
* @author Inderpal Dhanoa
* @description Trigger on Case Comment Object.
* @date 2021-07-30
* @revision 1.0
* @modfieid rajeshpunjabi 30-AUG-2022 Removed PB (Clears Inbound Email Date on Comment Add) and move logic to trigger.

**/
public class CaseCommentTriggerHandler{
    /**
    * @description Syncing the latest enquiry comment on the Enquiry.
    * @author Inderpal Dhanoa
    * @date 2021-07-30
    * @revision 1.0
    **/
    public class SyncEnquiryWithLatestComment extends TriggerAbstract { 
        public Map<Id, String> m_EnquiryLatestComment = new Map<Id, String>();
        public Set<Id> setCaseIds = new Set<Id>();
        
        public override void process(SObject record) {
            CaseComment caseCommentRecord = (CaseComment)record;
            m_EnquiryLatestComment.put(caseCommentRecord.ParentId, caseCommentRecord.CommentBody);
            if(!caseCommentRecord.CommentBody.contains('acknowledged')){
                setCaseIds.add(caseCommentRecord.ParentId);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            CaseComment caseCommentRecord = (CaseComment)record;
            CaseComment oldCaseCommentRecord = (CaseComment)oldRec;
            if(caseCommentRecord.CommentBody != oldCaseCommentRecord.CommentBody){
                m_EnquiryLatestComment.put(caseCommentRecord.ParentId, caseCommentRecord.CommentBody);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed 
            if(!m_EnquiryLatestComment.isEmpty()){
                System.enqueueJob(new CaseCommentQueuable(m_EnquiryLatestComment, setCaseIds));
            }
            LogUtilityException.getLimits();
        }
    }
}