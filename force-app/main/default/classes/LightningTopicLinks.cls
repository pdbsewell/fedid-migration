/**************************************************************************************************   
Apex Controller Name :  LightningTopicLinks 
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  this class is built for customizing Topic Related component.                                                                             
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Veera G                       3.July.2017                        Created.
***************************************************************************************************/
public class LightningTopicLinks {
    
    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017       
    * @description  method will take Article Id as input from the Article detail component and returns all the topics related to that article.
    * @InputParameter: Id
	* @return type  list<topic>
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static list<topic> getTopics(string ArticleId){
        list<topic> topicList = new list<topic>();
        set<id> topicIdSet = new set<id>();
        
        for(topicAssignment topicAssign:[Select id,topicId from TopicAssignment where entityId= :ArticleId]) {
            topicIdSet.add(topicAssign.topicId);
        }
        
        if(!topicIdSet.isEmpty()) {
            for(topic topicDetail:[select id,Name from topic where id in :topicIdSet]){
               topicList.add(topicDetail);
            }
        }
        return topicList;
    }

}