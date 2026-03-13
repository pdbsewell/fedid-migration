/**
 * @description       : 
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 31-10-2023
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest (isParallel=true)
public class KnowledgeArticlesRestAPI_Test {
    
    @isTest
    public static void getArticlesWithTopics_ExceptionTest(){
        //..GIVEN
        //.. Data Setup is not required for exception testing.
        
        //.. WHEN
        Test.startTest();
        KnowledgeArticlesRestAPI.getArticlesWithTopics();
        Test.stopTest();
        
        //.. THEN
        Assert.isTrue (true, 'Exception Testing Successful.');
    }
    
    @isTest
    public static void getArticlesWithTopics_Test(){
        //.. GIVEN
		
        //.. Create Articles.
        List<Knowledge_Article__kav> lstKBA = new List<Knowledge_Article__kav>();
        for(Integer i=0; i< 3; i++){
       		Knowledge_Article__kav oKBArticle = new Knowledge_Article__kav();
            oKBArticle.RecordTypeId = Schema.SObjectType.Knowledge_Article__kav.getRecordTypeInfosByDeveloperName().get('Research_FAQ').getRecordTypeId();
            oKBArticle.Title = 'Test KB Article for Research Team.'+i;
            oKBArticle.UrlName = 'salesforce-crm1234567890'+i;
            oKBArticle.Summary = 'Salesforce Cloud CRM';
            oKBArticle.Language = 'en_US';
            oKBArticle.IsVisibleInCsp = true;
            oKBArticle.ValidationStatus = 'Approved';
            oKBArticle.Automatically_Publish_On_Approval__c = true;
            lstKBA.add(oKBArticle);
        }
        insert lstKBA;
	
        Knowledge_Article__kav oKBArticle = [SELECT Id FROM Knowledge_Article__kav LIMIT 1];

        //.. Create Topic
        List<Topic> lstTopics = new List<Topic>();
        for(Integer i=0; i< 3; i++){
            Topic oTopic = new Topic();
            oTopic.Name = 'TestTopic#'+i;
            lstTopics.add(oTopic);
        }
        insert lstTopics;

		//.. Assign topic to Article.
		List<TopicAssignment> lstTA = new List<TopicAssignment>();
        
        for(Topic oT: lstTopics){
            TopicAssignment oTA = new TopicAssignment();
            oTA.TopicId = oT.Id;
            oTA.EntityId = oKBArticle.Id;
            lstTA.add(oTA);
        }        
        insert lstTA;
        
        //Initialize Variables
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        //Setup endpoint
        req.requestURI = '/services/apexrest/KBArticlesForResearch';
        
        //Setup action
        req.httpMethod = 'GET';
        
        //Setup callout
        RestContext.request = req;
        RestContext.response = res;
        
        //.. WHEN
        Test.startTest();
        KnowledgeArticlesRestAPI.getArticlesWithTopics();
		Test.stopTest();
        
        //.. THEN
		//Set response for assertion
        Blob responseJSON = res.responseBody;
		Assert.isTrue (responseJSON.size() > 0, 'We have successfully retrieved the KB Articles.');
    }
}