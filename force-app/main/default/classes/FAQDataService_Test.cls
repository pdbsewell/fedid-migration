/**
 * @author                      Kristian Vegerano
 * @created                     February 02, 2018
 * @description                 Test class for FAQDataService class
 */
@isTest (SeeAllData=false)
private class FAQDataService_Test {
    
    /**
     * @author                      Kristian Vegerano
     * @created                     February 02, 2018
     * @description                 Method that sets up data to be used on all test methods in this class
     */
    @testSetup 
    static void setupArticles() {
        //With answer for staff
        Knowledge_Article__kav testFaqArticleStaff = new Knowledge_Article__kav(Authorised_by__c = 'TestAuthorisedBy1',
                                                    Owning_Org_Unit__c = 'TestOwningOrgUnit1',
                                                    Title = 'TestTitle1',
                                                    Australia_Staff__c = 'TestAnswer /FAQ-1',
                                                    Legacy_Keywords__c = 'TestLegacyKeywords1',
                                                    CreatedDate = System.NOW(),
                                                    LastModifiedDate = System.NOW(),
                                                    Category_One__c = 'TestCategoryOne1',
                                                    Category_Two__c = 'TestCategoryTwo1',
                                                    UrlName = 'TestUrlName1',
                                                    Planned_Publication_Date__c = System.TODAY().addDays(-1),
                                                    IsVisibleInPkb = true);
        insert testFaqArticleStaff;
        
        //With answer for students
        Knowledge_Article__kav testFaqArticleStudent = new Knowledge_Article__kav(Authorised_by__c = 'TestAuthorisedBy2',
                                                      Owning_Org_Unit__c = 'TestOwningOrgUnit2',
                                                      Title = 'TestTitle2',
                                                      Australia_Student__c = 'TestAnswer /FAQ-2',
                                                      Legacy_Keywords__c = 'TestLegacyKeywords2',
                                                      CreatedDate = System.NOW(),
                                                      LastModifiedDate = System.NOW(),
                                                      Category_One__c = 'TestCategoryOne2',
                                                      Category_Two__c = 'TestCategoryTwo2',
                                                      UrlName = 'TestUrlName2',
                                                      Planned_Publication_Date__c = System.TODAY().addDays(-1),
                                                      IsVisibleInPkb = true);
        insert testFaqArticleStudent;
        
        //With answer for staff and student
        Knowledge_Article__kav testFaqArticleAnswer = new Knowledge_Article__kav(Authorised_by__c = 'TestAuthorisedBy3',
                                                     Owning_Org_Unit__c = 'TestOwningOrgUnit3',
                                                     Title = 'TestTitle3',
                                                     Answer__c = 'TestAnswer /FAQ-3',
                                                     Legacy_Keywords__c = 'TestLegacyKeywords3',
                                                     CreatedDate = System.NOW(),
                                                     LastModifiedDate = System.NOW(),
                                                     Category_One__c = 'TestCategoryOne3',
                                                     Category_Two__c = 'TestCategoryTwo3',
                                                     UrlName = 'TestUrlName3',
                                                     Planned_Publication_Date__c = System.TODAY().addDays(-1),
                                                     IsVisibleInCsp = true);
        insert testFaqArticleAnswer;
        
        //Publish Articles
        for(Knowledge_Article__ka loopFaq : [SELECT Id FROM Knowledge_Article__ka]){
            KbManagement.PublishingService.publishArticle(loopFaq.Id, true);
        }
    }
    
    /**
     * @author                      Kristian Vegerano
     * @created                     February 02, 2018
     * @description                 Test for retrieving customer and public articles using the rest service. Tests if the method returns the correct JSON format
     */
    private static testMethod void testGetCallout() {
        //Initialize Variables
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        //Setup endpoint
        req.requestURI = '/services/apexrest/FAQDataService';
        
        //Setup action
        req.httpMethod = 'GET';
        
        //Setup callout
        RestContext.request = req;
        RestContext.response = res;
        
        //Start Test
        Test.startTest();
        FAQDataService.doGet();
        Test.stopTest();
        
        //Retrieve reference articles
        Map<String, Knowledge_Article__kav> referenceFaqMap = new Map<String, Knowledge_Article__kav>();
        for(Knowledge_Article__kav loopArticle : [SELECT Id,RecordType.Name,PublishStatus, Authorised_by__c, Owning_Org_Unit__c,
                                            Summary, Title, Australia_Student__c, Legacy_Keywords__c, 
                                            CreatedDate, LastModifiedDate, Category_One__c,
                                            Category_Two__c, UrlName, Answer__c, Australia_Staff__c
                                    FROM Knowledge_Article__kav 
                                    WHERE RecordType.Name = 'FAQ']){
            referenceFaqMap.put(loopArticle.UrlName, loopArticle);
        }
        
        //Retrieve createwrapper for articles
        List<FAQData.ArticleData> articleDataList = new List<FAQData.ArticleData>();
        for(Knowledge_Article__kav loopArticle : [SELECT Id, RecordType.Name,PublishStatus, Authorised_by__c, Owning_Org_Unit__c,
                                            Summary, Title, Australia_Student__c, Legacy_Keywords__c, 
                                            CreatedDate, LastModifiedDate, Category_One__c,
                                            Category_Two__c, UrlName, Answer__c, Australia_Staff__c
                                    FROM Knowledge_Article__kav 
                                    WHERE PublishStatus = 'Online'
                                        AND RecordType.Name = 'FAQ'   
                                        AND (IsVisibleInPkb = true OR IsVisibleInCsp = true) 
                                    ORDER BY UrlName DESC]){
            if(loopArticle.Answer__c != null || loopArticle.Australia_Student__c != null){                          
                articleDataList.add(new FAQData.ArticleData(loopArticle, referenceFaqMap));
            }
        }
        
        //Set response for assertion
        Blob responseJSON = res.responseBody;
        
        //Test response
        System.assertEquals(FAQData.generateArticleJSONContent(articleDataList), 
                            responseJSON.toString());
    }

}