/**
 * Created by rcad0001 on 9/11/2021.
 */
@IsTest(IsParallel=true)
public class ArchiveKnowledgeArticleHelper_Test {
    @testSetup static void dataSetup() {
        CustomURLs__c customURL=new CustomURLs__c();
        customURL.Available_Object_for_Review_Batch__c='Knowledge_Article__kav';
        insert customURL;
    }

    @isTest
    public static void archiveArticles_test(){
        // GIVEN a published article reaches its proposed removal date
        Knowledge_Article__kav testKnowledgeArticle = new Knowledge_Article__kav();
        testKnowledgeArticle.Title = 'To-be Archived Test Title';
        testKnowledgeArticle.UrlName = 'Test-To-Be-Archived';
        testKnowledgeArticle.Language = 'en_US';
        testKnowledgeArticle.RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Knowledge_Article__kav' AND DeveloperName = 'FAQ' LIMIT 1].Id;
        testKnowledgeArticle.Proposed_Removal_Date__c = Date.today().addDays(-1);
        testKnowledgeArticle.Proposed_Removal_Status__c = 'Archive';
        testKnowledgeArticle.Automatically_Publish_On_Approval__c = true;
        insert testKnowledgeArticle;

        Knowledge_Article__kav newArticle = [SELECT Id, KnowledgeArticleId FROM Knowledge_Article__kav WHERE Id =: testKnowledgeArticle.Id];
        KbManagement.PublishingService.publishArticle(newArticle.KnowledgeArticleId, true);

        // WHEN the scheduled batch picks up the article record
        Test.startTest();
            ArchiveKnowledgeArticleHelper.archiveArticles();
        Test.stopTest();

        // THEN the article must be archived by status
        Knowledge_Article__kav archivedArticle = [SELECT Id, PublishStatus, IsDeleted FROM Knowledge_Article__kav WHERE Id=: testKnowledgeArticle.Id ALL ROWS];

        System.assertEquals(archivedArticle.PublishStatus, 'Archived');
    }
}