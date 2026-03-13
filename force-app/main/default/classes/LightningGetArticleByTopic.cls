/**************************************************************************************************   
Apex Controller Name :  LightningGetArticleByTopic
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This controller is to show list of articles linked to topic.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    21/06/2017                        Created.
***************************************************************************************************/
public with sharing class LightningGetArticleByTopic
{
    /**
    * @Method Name     : getArticleByTopic
    * @Input Parameters: topic Id
    * @Return Type     : faqWrapper 
    * @Description     : Fetch articles related to topic. 
    **/ 
    @AuraEnabled
    public static List<KnowledgeArticleVersion> getArticleByTopic(Id topicId)
    {
        list<TopicAssignment> topicAssignmentList = [SELECT EntityId FROM TopicAssignment where topicId=:topicId limit 1000];
        list<string> idList = new list<String>();
        for(TopicAssignment ts: topicAssignmentList){
            idList.add(ts.EntityId);
        }
        return [SELECT id,KnowledgeArticleId,sourceId,title,summary,ArticleNumber FROM KnowledgeArticleVersion where language='en_US' and publishstatus='Online' and id in :idList Limit 1000];        
    }  
    /**
    * @Method Name     : getPageSize
    * @Input Parameters: none
    * @Return Type     : Integer 
    * @Description     : Fetch page size from custom setting. 
    **/  
    @AuraEnabled
    public static Integer getPageSize()
    {
        CustomURLs__c setting=CustomURLs__c.getInstance();
        return Integer.valueOf(setting.PageSizeTopicDetail__c);
    }
    /**
    * @Method Name     : getTopicLabelMap
    * @Input Parameters: topicId
    * @Return Type     : Integer 
    * @Description     : Fetch overridden label for corresponding FAQ. 
    **/ 
    @AuraEnabled
    public static String getTopicLabelMap(Id topicId) {
       Map<String,TopicLabel__c> topicLabelMap=TopicLabel__c.getAll();
       Map<String,String> topicLabelMapToCompare=new Map<String,String>();
       for(String key: topicLabelMap.keySet())
       {
           topicLabelMapToCompare.put(key.toUpperCase(),topicLabelMap.get(key).Label__c);
       }
       List<Topic> topicList=[select id,name from topic where id=:topicId];
       if(topicList.size()>0) {
           return Label.Topic_Label + ' ' + topicList[0].name;           
       }
       return null;
    }
}