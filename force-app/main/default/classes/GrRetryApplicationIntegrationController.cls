/**
 * @description GrRetryApplicationIntegrationController to manually retry the GR integrations
 * @author      Vishal Gupta
 * @since       19.5.2025
 * @revision
 */
public with sharing class GrRetryApplicationIntegrationController {
    /**
     * @description retry Application Integration
     * @param       acpId
     * @return      String
     */
    @AuraEnabled
    public static String retryApplicationIntegration(Id acpId) {        
        List<Application_Course_Preference__c> acp = [SELECT Sync_In_Progress__c, Application__r.Status__c
                                                        FROM Application_Course_Preference__c
                                                        WHERE Id = :acpId LIMIT 1];
        if(!acp.isEmpty()) {
            if(acp[0].Application__r.Status__c != 'Submitted') {
                throw new AuraHandledException('The Application status must be Submitted to proceed');
            } else if(acp[0].Sync_In_Progress__c) {
                throw new AuraHandledException('A process already running in the backgroud. Please try again after 10 minutes.');
            } else {
                acp[0].Sync_In_Progress__c = true;
                try{
                    update acp[0];
                }  
                catch(Exception ex) {
                    logException('GrRetryApplicationIntegrationController.retryApplicationIntegration '+ex.getMessage(), ex);
                    throw new AuraHandledException('Error >> ' + ex.getMessage());
                }
            }
        }    
        return 'Success';                             
    }

    /**
     * @description retry application document integration
     * @param       recordId
     * @return      String
     */
    @AuraEnabled
    public static string retryApplicationDocumentIntegration(Id recordId){
        Map<Id, Contact_Document__c> conDocMap = new Map<Id, Contact_Document__c>();
        List<Contact_Document__c> conDocList = new ContactDocumentsSelector().selectByApplicationIdWithEmptyCallistaDocId(new Set<Id>{recordId});
        if(conDocList.isEmpty()) {
            throw new AuraHandledException('No document to process.');
        }
        for(Contact_Document__c conDocRec : conDocList) {
            if(conDocRec.Sync_In_Progress__c) {
                throw new AuraHandledException('A process already running in the backgroud. Please try again after 10 minutes.');
            }
            conDocRec.Sync_In_Progress__c = true;       
            conDocMap.put(conDocRec.Id, conDocRec);
        }        
        if(!conDocMap.isEmpty()) {                
            try{
                update conDocMap.values();
            }  
            catch(Exception ex) {
                logException('GrRetryApplicationIntegrationController.retryApplicationDocumentIntegration '+ex.getMessage(), ex);
                throw new AuraHandledException('Error >> ' + ex.getMessage());
            }
        }
        return 'Success';
    }

    /**
     * @description to capture any exception logs
     * @param       message
     * @param       ex
     */
    public static void logException(String message, Exception ex) {
        Nebula.Logger.error('GrRetryApplicationIntegrationController.retryApplicationDocumentIntegration '+message, ex);
        Nebula.Logger.saveLog();
    }
}