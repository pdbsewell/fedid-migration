/**
 * @description       : Handler to manage all RPA Bot Platfomr events
 * @author            : Inderpal Dhanoa
 * @group             : RPA Bot Handler
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2023-06-14 - Inderpal Dhanoa -- Added a Handler to manage Enquiry updates from RPA to UniCRM
 * 1.1   2023-07-07 - Inderpal Dhanoa -- Added a condition to manage Enquiry updates MCT-138
 **/
public with sharing class MonashConnectRPABotHandler { 

    private static String S_CASESTATUSSOLVED = 'SOLVED';
	
    /**
    * @author Inderpal Dhanoa
    * @date 2023-06-14
    *
    * @group Monash Connect
    *
    * @description Service class to manage Enquiry updates from RPA to UniCRM
    */
    public class UpdateEnquiryStatus implements IPlatformEventInvocable {
    
        private Map<Id, String> m_mapCaseCaseComment = new Map<Id, String>();
        private Map<Id, String> m_mapCaseCaseStatus = new Map<Id, String>();

        public void execute(List<AsyncProcessPayload> payload) {
			try {
				initialize(payload);
				run();
			} catch(Exception e) {
				LogUtilityException.logException(e, payload);
			} finally {
				LogUtilityException.getLimits();
			}
		}

		private void initialize(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {
                Object caseId, commentBody, caseStatus;
				for(AsyncProcessPayload payload : payloads) {
                    caseId = payload.get('CaseId');
                    caseStatus = payload.get('CaseStatus');
                    commentBody = payload.get('CommentBody');
                    m_mapCaseCaseComment.put(Id.Valueof(caseId.toString()), String.valueOf(commentBody.toString()));
                    m_mapCaseCaseStatus.put(Id.Valueof(caseId.toString()), String.valueOf(caseStatus.toString()));
				}
			}
		}

        public void run() {
            updateCaseStatusAndInsertComment(m_mapCaseCaseComment, m_mapCaseCaseStatus);
        }
    }

    /*
    * Method Name:  updateCaseStatusAndInsertComment
     * @param       Map Id, String for CaseId an Status
     * @param       Map Id, String for CaseId an Case Coment Body 
     * Description: update Case Status And Insert Comment 
    */
    public static void updateCaseStatusAndInsertComment(Map<Id, String> m_mapCaseCaseComment, Map<Id, String> m_mapCaseCaseStatus){
        try{
            List<Case> l_updateCase = new List<Case>();
            List<CaseComment> l_newCaseComment = new List<CaseComment>();
            Case updateCase;
            CaseComment newCaseComment;
            for(Id caseId : m_mapCaseCaseStatus.keySet()){
                if(m_mapCaseCaseStatus.get(caseId) == S_CASESTATUSSOLVED){
                    updateCase = new Case();
                    updateCase.Id = caseId;
                    updateCase.Status = m_mapCaseCaseStatus.get(caseId);
                    l_updateCase.add(updateCase);
                }                
            }
            for(Id caseId : m_mapCaseCaseComment.keySet()){
                newCaseComment = new CaseComment();
                newCaseComment.ParentId = caseId;
                newCaseComment.CommentBody = m_mapCaseCaseComment.get(caseId);
                l_newCaseComment.add(newCaseComment);
            }

            Database.SaveResult [] srUpdateList = Database.update(l_updateCase, false);
            for (Database.SaveResult sr : srUpdateList) {
                if (!sr.isSuccess()) {
                    LogUtilityException.debug('Error from MonashConnectRPABotHandler UpdateEnquiryStatus to update Case Status :: ' + l_updateCase);
                }
            }
            // Insert Case Comment
            Database.SaveResult [] srInsertList = Database.insert(l_newCaseComment, false);
            for (Database.SaveResult sr : srInsertList) {
                if (!sr.isSuccess()) {
                    for(database.Error err: sr.getErrors()){
                        system.debug('Exception Occured ::'+err.getMessage()+'::'+err.getfields());
                    }
                    LogUtilityException.debug('Error from MonashConnectRPABotHandler UpdateEnquiryStatus to Insert Case comment :: ' + l_newCaseComment);
                }
            }
        }catch(Exception ex){
            LogUtilityException.debug('Error from MonashConnectRPABotHandler updateStatusAndInsertComment :: ' + m_mapCaseCaseStatus);
        }
    }
}