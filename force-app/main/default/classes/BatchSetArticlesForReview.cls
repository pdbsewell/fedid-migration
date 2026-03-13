@isTest
global class BatchSetArticlesForReview implements Database.Batchable<sObject>, Schedulable{
    public String query;
    public Set<String> articleNumberSet;
    public String articleType;
    global database.querylocator start(Database.BatchableContext BC)
    {
        try {
            return Database.getQueryLocator(query);
        }
        catch(Exception e) {
            return null;
        }
    }    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
          /*Set<Id> articleIdSet=new Set<Id>();
          for(sObject obj: scope) {
              system.debug('article being edited is '+obj.get('KnowledgeArticleId'));
              articleIdSet.add(KbManagement.PublishingService.editOnlineArticle(String.valueOf(obj.get('KnowledgeArticleId')), true));                  
          }
          List<Sobject> objList=database.query('select id,ValidationStatus,KnowledgeArticleId from '+articleType+' where id in :articleIdSet and language=\'en_US\' and publishstatus=\'Draft\'');
          for(Sobject obj: objList) {
              obj.put('ValidationStatus','Due for Review');
          }
          update objList;
          for(sObject obj: objList) {
              KbManagement.PublishingService.publishArticle(String.valueOf(obj.get('KnowledgeArticleId')),true);
              system.debug('New article version is '+obj.get('KnowledgeArticleId'));
          }*/
    }   
    global void finish(Database.BatchableContext BC) {
    }
    global void execute(SchedulableContext sc) {
        /*Map<String,Set<String>> articleTypeArticleNumberMap=new Map<String,Set<String>>();
        List<knowledgearticleversion> knowledgearticleversionList=[select id,ArticleType,ArticleNumber from knowledgearticleversion where language='en_US' and publishstatus='Online'];
        List<String> articleObjectList=CustomURLs__c.getInstance().Available_Object_for_Review_Batch__c.split(',');
        Set<String> articleObjectSet=new Set<String>();
        articleObjectSet.addAll(articleObjectList);
        for(knowledgearticleversion kav: knowledgearticleversionList) {
            if(!articleObjectSet.contains(kav.ArticleType)) {
                continue;
            }
            if(articleTypeArticleNumberMap.containsKey(kav.ArticleType)) {
                articleTypeArticleNumberMap.get(kav.ArticleType).add(kav.ArticleNumber);
            }
            else {
                articleTypeArticleNumberMap.put(kav.ArticleType,new Set<String> {kav.ArticleNumber});
            }
        }
        try {
            for(String articleType : articleTypeArticleNumberMap.keySet()) {
                BatchSetArticlesForReview batchObj = new  BatchSetArticlesForReview ();  
                batchObj.articleNumberSet=articleTypeArticleNumberMap.get(articleType);     
                batchObj.articleType=articleType;   
                batchObj.query='select id,KnowledgeArticleId,Review_Date__c,ValidationStatus from '+articleType+' where ArticleNumber in :articleNumberSet and Review_Date__c<=Next_N_Days:30 and language=\'en_US\' and publishstatus=\'Online\' and ValidationStatus=\'Published\'';
                ID batchprocessidOpp = Database.executeBatch(batchObj,1);
            }
        }
        catch(Exception e) {
            
        }*/
    }
}