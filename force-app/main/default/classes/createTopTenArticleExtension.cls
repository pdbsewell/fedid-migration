/**************************************************************************************************   
Apex Controller Name :  createTopTenArticleExtension
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This class will set a article as TopTen.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    17/05/2017                        Created.
***************************************************************************************************/
public without sharing class createTopTenArticleExtension {
    public TopTenArticle__c topTen{get;set;}
    public Id FAQId;
    public String faqType{get;set;}
    public String questionText {get;set;}
    public String answerText {get;set;}
    /**
    * @Method Name     : createTopTenArticleExtension
    * @Input Parameters: ApexPages.StandardController
    * @Return Type     : none
    * @Description     : This constructor fetches the data from article record to display on page. 
    **/
    public createTopTenArticleExtension(ApexPages.StandardController caseController) {
        try{
            topTen=(TopTenArticle__c)caseController.getRecord();  
            FAQId=ApexPages.currentPage().getParameters().get('FAQId').escapeHtml4();
            String articleNumber=ApexPages.currentPage().getParameters().get('articleNumber').escapeHtml4();
            String FAQIdString=String.valueOf(FAQId).subString(0,15);
            List<TopTenArticle__c> topTenList=[select id,Name,Title__c,Student__c,Student_Order__c,Staff__c,Staff_Order__c,External__c,External_Order__c,StartDate__c,EndDate__c from TopTenArticle__c where ArticleNumber__c=:articleNumber];
            
            if(topTenList.size()>0){
                topTen=topTenList[0];
            }
                
            system.debug('topTen is '+topTen);
            faqType=FAQId.getSobjectType().getDescribe().getName();
            String query='select id,Title,ArticleNumber,question__c,answer__c,UrlName from '+faqType+' where id=\''+FAQId+'\'';
            List<SObject> objectList=Database.query(query);            
            if(objectList.size()>0) {
                topTen.Name=((String)objectList[0].get('Title')).length()>80?((String)objectList[0].get('Title')).substring(0,80):(String)objectList[0].get('Title');  
                topTen.Title__c=(String)objectList[0].get('Title');  
                topTen.ArticleNumber__c=(String)objectList[0].get('ArticleNumber');   
                topTen.Article_UrlName__c=(String)objectList[0].get('UrlName'); 
                questionText=(String)objectList[0].get('question__c');  
                answerText=(String)objectList[0].get('answer__c');           
            }   
            topTen.ArticleType__c=FAQIdString;            
        }
        catch(Exception ex) {
            ExLog.add('Set As Top Ten','createTopTenArticleExtension','createTopTenArticleExtension', ex);
            return;
        }
    }
    
    /**
    * @Method Name     : save
    * @Input Parameters: none
    * @Return Type     : PageReference 
    * @Description     : upsert topTen article 
    **/
    
    public PageReference save()
    {
        try {
            upsert topTen;
        } catch(Exception ex) {
            ExLog.add('Set As Top Ten','createTopTenArticleExtension','save', ex);
            return null;
        }
        
        return new PageReference('/'+topTen.Id);
    }    
}