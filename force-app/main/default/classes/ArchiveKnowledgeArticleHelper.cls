/*******************************************************************************
* @author       Russell Cadapan
* @date         09/11/2021
* @description  Batch Class helper for Knowledge Article Archiving
* @revision     1.0 - Russell   09/11/2021 - Created
*******************************************************************************/

public with sharing class ArchiveKnowledgeArticleHelper {
    public static void archiveArticles(){
        // a map of article record type and its article numbers
        Map<String,Set<String>> articleTypeArticleNumberMap=new Map<String,Set<String>>();

        // a list of KAV objects for review
        List<String> articleObjectList = CustomURLs__c.getInstance().Available_Object_for_Review_Batch__c.split(',');

        Set<String> articleObjectSet = new Set<String>();

        articleObjectSet.addAll(articleObjectList);

        String articleRecordType;

        for(Knowledge_Article__kav kav: [SELECT Id, RecordTypeId, ArticleNumber FROM Knowledge_Article__kav WHERE language ='en_US' AND PublishStatus = 'Online']) {
            // get the sobjecttype of the article version's record type id
            articleRecordType = RecordTypeSObjectMap.get(kav.RecordTypeId).SobjectType;

            // if the sobjectype is for review, then skip. else, continue.
            if(!articleObjectSet.contains(articleRecordType)) {
                continue;
            }

            // map the recordtypeid and its published article numbers
            if(articleTypeArticleNumberMap.containsKey(kav.RecordTypeId)) {
                articleTypeArticleNumberMap.get(kav.RecordTypeId).add(kav.ArticleNumber);
            }
            else {
                articleTypeArticleNumberMap.put(kav.RecordTypeId,new Set<String> {kav.ArticleNumber});
            }

        }
        try {
            for(Id RecordType : articleTypeArticleNumberMap.keySet()) {
                // get the linked article type from the record type id
                articleRecordType = RecordTypeSObjectMap.get(RecordType).SObjectType;

                // initialise the batch
                ArchiveKnowledgeArticlesBatch batchObj = new  ArchiveKnowledgeArticlesBatch();

                // set constructor variable articleNumberSet
                batchObj.articleNumberSet=articleTypeArticleNumberMap.get(RecordType);

                // set constructor variable query (Get all published articles related to the articletype where removal date is older than or equal today
                batchObj.query='SELECT Id, KnowledgeArticleId, Proposed_Removal_Date__c, Proposed_Removal_Status__c FROM ' +articleRecordType+ ' WHERE ArticleNumber IN: articleNumberSet AND Proposed_Removal_Date__c <= TODAY AND Language =\'en_US\' AND PublishStatus=\'Online\'';

                // execute the batch
                Id batchprocessidOpp = Database.executeBatch(batchObj,1);
            }
        }
        catch(Exception e) {
            LogUtilityException.logException(e);
        }
    }

    private static Map<Id, RecordType> RecordTypeSObjectMap{
        get{
            if(RecordTypeSObjectMap == null){
                RecordTypeSObjectMap = new Map<Id, RecordType>([SELECT Id, SObjectType FROM RecordType]);
            }
            return RecordTypeSObjectMap;
        }
        set;
    }
}