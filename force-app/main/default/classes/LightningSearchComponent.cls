/**************************************************************************************************   
Apex Controller Name :  LightningSearchComponent 
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  Auto Complete functionality for community search component.                                                                             
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Veera G                       3.July.2017                        Created.
***************************************************************************************************/
public with sharing class LightningSearchComponent {

    Public Static Integer LIMITROWS=6;

    /*******************************************************************************
    * @author       Veera G, PwC
    * @date         3.July.2017       
    * @description  this method takes search Keyword as input from community search component on KEYUP and return a list of Knowledge Articles.
    * @Input Parameters: String
    * @return type  list<KnowledgeArticleVersion>
    * @revision         
    *******************************************************************************/
    @AuraEnabled
    public static list<Sobject> getSearchArticles(string searchText) {
        list<Sobject> articleSuggestions = new list<Sobject>();
        List<String> searchableObjects=Label.Searchable_Article_Types.split(',');
        system.debug('searchText is '+searchText);

        system.debug('articleSuggestions is '+articleSuggestions);
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
            subQuery=subQuery==null?'':subQuery+',';
            subQuery=subQuery+articleType+'(Title, Id,Answer__c,Australia_Student__c,Australia_Staff__c,Legacy_Keywords__c WHERE PublishStatus=\'online\' AND RecordType.Name IN '  + articleRecordTypeFilter + ' AND language=\'en_US\' limit 6)';
        }
        searchquery=searchquery+subQuery;
        system.debug('searchquery is '+searchquery);
        List<List<SObject>> results = search.query(searchquery);
        for(List<SObject> SObjList : results) {
            for(SObject SObj: SObjList) {
                system.debug('SObj is '+SObj);
                //if(SObj.get('Answer__c')!=null && ((String)SObj.get('Answer__c')).toLowerCase().contains(searchText.toLowerCase()) ||
                //        SObj.get('Australia_Student__c')!=null && ((String)SObj.get('Australia_Student__c')).toLowerCase().contains(searchText.toLowerCase()) ||
                //        SObj.get('Australia_Staff__c')!=null && ((String)SObj.get('Australia_Staff__c')).toLowerCase().contains(searchText.toLowerCase()) ||
                //        SObj.get('Legacy_Keywords__c')!=null && ((String)SObj.get('Legacy_Keywords__c')).toLowerCase().contains(searchText.toLowerCase())) {
                    articleSuggestions.add(SObj);
                //}
            }
        }
        System.debug('articleSuggestions'+articleSuggestions);
        return articleSuggestions;
    }

    /*******************************************************************************
    * @author       Veera, PwC
    * @date         10.August.2017
    * @descriptLightningSearchComponentv2ion  method returns custom settings which store external urls
    * @Input Parameters: 
    * @return type: CustomURLs__c
    * @revision         
    *******************************************************************************/
    @AuraEnabled
    public static string getSearchPageUrl()
    {
        string searchPage = CustomURLs__c.getInstance().Monash_Search_URL__c != null?CustomURLs__c.getInstance().Monash_Search_URL__c:'https://http://www.monash.edu/';
        return searchPage;
    }

}