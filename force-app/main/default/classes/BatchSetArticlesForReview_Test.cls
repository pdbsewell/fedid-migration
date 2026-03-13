/**************************************************************************************************   
Apex Class Name      :  TestBatchSetArticlesForReview_Test
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is test class for BatchSetArticlesForReview.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    17/07/2017                        Created.
***************************************************************************************************/
@isTest(isParallel=true)
public class BatchSetArticlesForReview_Test{
    /*@testSetup
    public static void createData() {
        TestUtil.createArticles();
        TestUtil.createCustomSettings();
        faq__kav faq=new faq__kav();
        faq.question__c='hi';
        faq.answer__c='there';
        faq.Title='How';
        faq.UrlName='test45436556';        
        faq.Automatically_Publish_On_Approval__c=true;
        faq.Proposed_Removal_Date__c=system.today().addDays(-1);
        faq.Proposed_Removal_Status__c='Archive';
        faq.Review_Date__c=system.today().addDays(30);
        faq.ValidationStatus='Published';
        faq.Owning_Org_Unit__c='Information';
        insert faq;
        faq=[select id,KnowledgeArticleId from faq__kav where id=:faq.Id];
        KbManagement.PublishingService.publishArticle(String.valueOf(faq.KnowledgeArticleId),true);
    }
    public static testmethod void testTopTenExtension() {
        test.startTest();
        BatchSetArticlesForReview sh1 = new BatchSetArticlesForReview();
        system.schedule('Test Archive article','0 0 23 * * ?', sh1);
        test.stopTest();
    }    */
}