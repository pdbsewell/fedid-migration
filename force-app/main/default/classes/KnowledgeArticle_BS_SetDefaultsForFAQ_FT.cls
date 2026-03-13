/*
* @description     :   Test class for KnowledgeArticle : BS : Set Defaults For FAQ Flow
* @author          :   Vinothraja
* @date            :   02-07-2025
* @group           :   Platforms
* @revision
*  02-07-2025      Vinothraja - EPCP-4545  created
*/
@isTest(isParallel=true)
public with sharing class KnowledgeArticle_BS_SetDefaultsForFAQ_FT {
    /**
     * @description Test method to verify that the Knowledge Article defaults are set correctly for FAQ articles.
     * @author Vinothraja
     * @date 02-07-2025
     * @group Platforms
     * @revision
     * 02-07-2025 Vinothraja - EPCP-4545 created
     */
    @isTest
    static void testSetDefaultsForFAQ() {
        // GIVEN
        // A new Knowledge Article instance
        Knowledge_Article__kav article = new Knowledge_Article__kav(
            Title = 'Test FAQ Article',
            Summary = 'This is a test FAQ article.',
            Planned_Publication_Date__c = System.today(),
            UrlName = 'test-faq-article',
            recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Knowledge_Article__kav' AND DeveloperName = 'FAQ' LIMIT 1].Id
        );      
        // WHEN
        // The Knowledge Article is created
        Test.startTest();
            insert article;
        Test.stopTest();    

        // THEN
        // Verify that the defaults are set correctly
        article = [SELECT IsVisibleInCsp, IsVisibleInPkb FROM Knowledge_Article__kav WHERE Id = :article.Id LIMIT 1];
        Assert.isTrue(article.IsVisibleInCsp, 'Visible to Customer should be true for FAQ articles.');
        Assert.isTrue(article.IsVisibleInPkb, 'Visible In Public Knowledge Base should be true for FAQ articles.');
    }
}