/**************************************************************************************************   
Apex Controller Name :  LightningSearchPageController 
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  this class is display search results in community with pagination.        
                     : This is controller class for component CommunitySearchPageComponent                                                                     
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Veera G                       3.July.2017                        Created.
    Angelo R                      7.May.2019                        Fix fatal error
	Rajesh P. 				      03-AUG-2022	Added escapeSingleQuotes to prevent SOQL injection. 
***************************************************************************************************/
public with sharing class LightningSearchPageController {
    
    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017       
    * @description  method will take search text as input from Search page URL and returns all the articles related to that search string.
    * @InputParameter: string
    * @return type  list<sobject>
    * @revision             Developer       Date             Description
    *                       Angelo R        7.May.2019       Fix fatal error
    *******************************************************************************/
    @AuraEnabled
    public static list<Sobject> getSearchResults(String searchText) {
        List<Sobject> articleSuggestions=new List<Sobject>();
        Map<id,Sobject> articleMap = new Map<Id,Sobject>();
        String excludeString = CustomURLs__c.getInstance().Exclude_Token__c;

        if(String.isNotBlank(excludeString)) {
            searchText = searchText.remove(excludeString);
        }
        List<String> searchableObjects=Label.Searchable_Article_Types.split(',');
        
        if(searchText != '' && searchText.length()>=3) {
            List<string> searchTextList = searchText.split('[\\s]');
            String subQuery=null;
            String soslSearchText=searchText.endsWith('*') ? searchText : searchText+'*';
            String searchquery='FIND :soslSearchText IN Name FIELDS RETURNING ';

            //Access a custom label that used to specify article record types to be returned on the search
            List<String> articleSearchFilterList = Label.AskMonashCommunityArticleSearchFilter.split(';');
            String articleRecordTypeFilter = '(';

            for(String loopFilter : articleSearchFilterList){
                articleRecordTypeFilter += '\'' + loopFilter + '\',';
            }
            
            articleRecordTypeFilter = articleRecordTypeFilter.substring(0, articleRecordTypeFilter.length() - 1);
            articleRecordTypeFilter += ')';

            for(String articleType: searchableObjects){
                subQuery = subQuery == null? '' : subQuery + ',';
                subQuery = subQuery + articleType + '(Title, Id,Answer__c,Australia_Student__c,Australia_Staff__c,Legacy_Keywords__c WHERE PublishStatus=\'online\' AND RecordType.Name IN '  + articleRecordTypeFilter + ' AND language=\'en_US\' limit 6)';
            }

            searchquery = searchquery + subQuery;
            List<List<SObject>> results = search.query(searchquery);

            for(List<SObject> SObjList : results) {
                for(SObject SObj: SObjList) {
                    articleSuggestions.add(SObj);
                }
            }

            List<Sobject> ArticlebyTopic = getSearchArticlesbyTopic(searchTextList);

            if(!articleSuggestions.isEmpty() && !ArticlebyTopic.isEmpty()){
                for(Sobject aSuggestions:articleSuggestions) {
                    articleMap.put(aSuggestions.id, aSuggestions);
                }

                for(Sobject ArticlebyTopicResult : ArticlebyTopic) {
                    ArticlebyTopicResult.id = string.valueof(ArticlebyTopicResult.id).length()==18?string.valueof(ArticlebyTopicResult.id).substring(0, 15):string.valueof(ArticlebyTopicResult.id);
                    articleMap.put(ArticlebyTopicResult.id, ArticlebyTopicResult);
                }

                if(!articleMap.isEmpty()){
                    articleSuggestions.clear();
                    articleSuggestions.addAll(articleMap.values());
                }

            } else if(!ArticlebyTopic.isEmpty()) {
                articleSuggestions.addAll(ArticlebyTopic);
            }

            return articleSuggestions;
        } else {
            articleSuggestions = new list<sobject>();
            return articleSuggestions;
        }
    }
    
    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017       
    * @description  method returns page size from CustomURLs__c custom setting.
    * @InputParameter: 
    * @return type  : Integer
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static integer getPageSize() {
        Integer pageSize = Integer.valueOf(CustomURLs__c.getInstance().SearchResultsPageSize__c)!=NULL?Integer.valueOf(CustomURLs__c.getInstance().SearchResultsPageSize__c):10;
        return pageSize;
    }
    
    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017       
    * @description  method will return a list of articles related to the topic matching the search string.
    * @InputParameter: string
    * @return type  list<sobject>
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static list<Sobject> getSearchArticlesbyTopic(List<String> searchList){
        //Filter by record type
        List<String> articleSearchFilterList = Label.AskMonashCommunityArticleSearchFilter.split(';');
        String articleRecordTypeFilter = '(';
        for(String loopFilter : articleSearchFilterList){
            articleRecordTypeFilter += '\'' + loopFilter + '\',';
        }
        articleRecordTypeFilter = articleRecordTypeFilter.substring(0, articleRecordTypeFilter.length() - 1);
        articleRecordTypeFilter += ')';
            
        Set<String> searchableObjectSet=new Set<String>();
        searchableObjectSet.addAll(Label.Searchable_Article_Types.split(','));
        List<Sobject> searchArticleByTopicList =new List<Sobject>();
        List<Sobject> resultedArticles=new List<Sobject>();
        List<topic> topicList = new List<topic>();
        List<TopicAssignment> topicAssignmentList = new List<TopicAssignment>();
        Map<String,Set<Id>> articleTypeMap=new Map<String, Set<Id>>();
        Set<Id> idSet = new Set<Id>();
        
        String topicQuery = 'SELECT Id, Name FROM topic WHERE';
        for(string searchToken: searchList){
            topicQuery = topicQuery + ' Name Like \'%'+String.escapeSingleQuotes (searchToken)+'%\' OR';
        }
        topicQuery = topicQuery.removeEnd('OR');
        topicList = database.query(topicQuery);
        
        if(!topicList.isEmpty()) {
            String topicAssignmentQuery = 'SELECT EntityId, EntityType, Id, TopicId FROM TopicAssignment WHERE ';
            for(topic topicId:topicList){
                topicAssignmentQuery = topicAssignmentQuery + ' TopicId =\''+topicId.Id+'\' OR';
            }
            topicAssignmentQuery = topicAssignmentQuery.removeEnd('OR');
            topicAssignmentQuery = topicAssignmentQuery +' LIMIT 1000';
            topicAssignmentList = database.query(topicAssignmentQuery);
        }
        
        if(!topicAssignmentList.isEmpty()) {
           for(TopicAssignment assign: topicAssignmentList) {
               idSet.add(assign.EntityId);
            }
            
            String query='SELECT Id, Title FROM Knowledge_Article__kav WHERE language=\'en_US\' AND Publishstatus=\'Online\' AND RecordType.Name IN '  + articleRecordTypeFilter + ' AND Id IN :idSet LIMIT 1000';
            searchArticleByTopicList= Database.query(query);
        }
        
        for(Integer i=0;i<searchArticleByTopicList.size();i++) {   
            if(searchableObjectSet.contains(searchArticleByTopicList[i].Id.getSobjectType().getDescribe().getName())) {
                resultedArticles.add(searchArticleByTopicList[i]);
            }
        }
        return resultedArticles;
    }
    
    /*******************************************************************************
    * @author       Veera, PwC
    * @date         3.July.2017       
    * @description  method returns the search token in UpperCase.
    * @InputParameter: string
    * @return type  string  
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static string getSearchToken(String searchText){
        if(String.valueOf(CustomURLs__c.getInstance().Exclude_Token__c)!='' && String.valueOf(CustomURLs__c.getInstance().Exclude_Token__c)!=NULL) {
            String excludeString = string.valueOf(CustomURLs__c.getInstance().Exclude_Token__c);
            searchText = '"'+searchText.remove(excludeString).toUpperCase()+'"';
        } else {
            searchText = '"'+searchText.toUpperCase()+'"'; 
        }
        
        return searchText;
    }
}