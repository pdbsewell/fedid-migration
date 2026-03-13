/*******************************************************************************
* @author       Russell Cadapan
* @date         09/11/2021
* @description  Batch Class for Knowledge Article Archiving
* @revision     1.0 - PWC
*               1.1 - Russell   09/11/2021 - Class re-enablement in line to re-structured KAV for Lightning Experience
*******************************************************************************/

global class ArchiveKnowledgeArticlesBatch implements Database.Batchable<sObject>, Schedulable{

    public String query;
    public Set<String> articleNumberSet;

    global database.querylocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        try {
            for(sObject obj: scope) {
                if(String.valueOf(obj.get('Proposed_Removal_Status__c'))=='Archive') {
                    KbManagement.PublishingService.archiveOnlineArticle(String.valueOf(obj.get('KnowledgeArticleId')),null);
                }
                else {
                    KbManagement.PublishingService.editOnlineArticle(String.valueOf(obj.get('KnowledgeArticleId')), true);
                }
            }
        }
        catch (Exception e) {
            LogUtilityException.logException(e);
        }
    }
    global void finish(Database.BatchableContext BC) {

    }

    // schedulable executor
    global void execute(SchedulableContext sc) {
        ArchiveKnowledgeArticleHelper.archiveArticles();
    }
}