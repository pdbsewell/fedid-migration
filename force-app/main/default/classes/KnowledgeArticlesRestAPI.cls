/**
 * @description       : Get list of KB article for Research FAQ - REST API for Squiz
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 31-10-2023
 * @last modified by  : rajesh.punjabi@monash.edu
**/


//TODO: Add readable exceptionmessage.

@RestResource(urlMapping='/KBArticlesForResearch')
global with sharing class KnowledgeArticlesRestAPI {
    /**
    * @description : returns the list of KB Article for Research FAQ.
    * @author rajesh.punjabi@monash.edu | 31-10-2023 
    **/
    @HttpGet
    global static void getArticlesWithTopics() {
        try{
        //.. Get the record type id for Research 
        Id idKBArticle_ReseachFAQRT = Schema.SObjectType.Knowledge_Article__kav.getRecordTypeInfosByDeveloperName().get('Research_FAQ').getRecordTypeId();
        
        List<KnowledgeArticlesRestAPI.ResearchArticlesWithTopics> lstPayload = new List<KnowledgeArticlesRestAPI.ResearchArticlesWithTopics>();
        Map<Id, List<String>> mapEntityIdTopic = new Map<Id, List<String>>();

        Map<Id, Knowledge_Article__kav> mapArticles = new Map<Id, Knowledge_Article__kav> ([SELECT Id, RecordTypeId, RecordType.DeveloperName, KnowledgeArticleId, Title, Question__c, Summary, Australia_Staff__c, LastModifiedDate, LastPublishedDate 
                                                                                            FROM Knowledge_Article__kav
                                                                                            WHERE RecordTypeId =: idKBArticle_ReseachFAQRT
                                                                                            AND PublishStatus = 'Online' 
                                                                                            AND IsVisibleInCsp = true]);


        List<TopicAssignment> lstTopicAssignments = [SELECT Id, EntityId, EntityKeyPrefix, TopicId
                                                        FROM TopicAssignment
                                                        WHERE EntityId IN : mapArticles.keySet()
                                                        AND EntityKeyPrefix = 'ka7'];

        
        for(TopicAssignment oTA:lstTopicAssignments){

            if(mapEntityIdTopic.containsKey(oTA.EntityId)){
                mapEntityIdTopic.get(oTA.EntityId).add(oTA.TopicId);
            }
            else{
                mapEntityIdTopic.put(oTA.EntityId, new List<String>{oTA.TopicId});
            }

        }

        for(Knowledge_Article__kav oKak :mapArticles.values()){
            
            ResearchArticlesWithTopics oRAT = new ResearchArticlesWithTopics();
            oRAT.recordId = oKak.Id;
            oRAT.Australia_Staff = oKak.Australia_Staff__c;
            oRAT.KnowledgeArticleId = oKak.KnowledgeArticleId;
            oRAT.Title = oKak.Title;
            oRAT.Question = oKak.Question__c;
            oRAT.Summary = oKak.Summary;
            oRAT.LastModifiedDate = oKak.LastModifiedDate;
            oRAT.LastPublishedDate = oKak.LastPublishedDate;
            if(lstTopicAssignments.size() > 0 && mapEntityIdTopic.containsKey(oKak.Id)){
				oRAT.Topics = String.join(mapEntityIdTopic.get(oKak.Id), ',');
            }
            
			lstPayload.add(oRAT);
        }
        
         //Set return type to JSON
		RestContext.response.addHeader('Content-Type', 'application/json');

        //Return FAQ data
        String responseJSON = JSON.serializePretty (lstPayload);
        
        //Set return type to JSON
        RestContext.response.responseBody = Blob.valueOf(responseJSON);
        }
        catch(Exception e){
            LogUtilityException.logException(e);
        }
    }

    /**
    * @description : Return request custom wrapper.
    * @author rajesh.punjabi@monash.edu | 31-10-2023 
    **/
    public class ResearchArticlesWithTopics{
        public Id recordId {get; set;}
        public String KnowledgeArticleId {get; set;}
        public String Title {get; set;}
        public String Question {get; set;}
        public String Summary {get; set;}
        public String Australia_Staff {get; set;}
        public DateTime LastModifiedDate {get; set;}
        public Datetime LastPublishedDate {get; set;}
        public String Topics {get; set;}

    }
}