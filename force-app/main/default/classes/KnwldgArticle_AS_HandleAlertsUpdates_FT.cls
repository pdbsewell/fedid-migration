/*
* @description     :   Test class for KnowledgeArticle : AS : Handle alerts and updates Flow
* @author          :   Vinothraja
* @date            :   11-08-2025
* @group           :   Platforms
* @revision
*  11-08-2025      Vinothraja - EPCP-4545  approved
*/
@isTest(isParallel=true) 
public with sharing class KnwldgArticle_AS_HandleAlertsUpdates_FT {

    // @description Test method to verify that the FAQ Knowledge Article is Published
    @isTest
    static void testPublishForFAQ() {
        // GIVEN
        // A new Knowledge Article instance
        Knowledge_Article__kav article = new Knowledge_Article__kav(
            Title = 'Test FAQ Article',
            Summary = 'This is a test FAQ article.',
            Planned_Publication_Date__c = System.today(),
            UrlName = 'test-faq-article',
            ValidationStatus = 'Draft',
            Automatically_publish_on_approval__c = true,
            recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Knowledge_Article__kav' AND Name = 'FAQ' LIMIT 1].Id
        );   
        insert article;

        // WHEN
        // The Knowledge Article is approved
        Test.startTest();
            article.ValidationStatus = 'Approved';
            update article;
        Test.stopTest();    

        // THEN
        // Verify that the article is published
        article = [SELECT ValidationStatus FROM Knowledge_Article__kav WHERE Id = :article.Id LIMIT 1];
        Assert.areEqual('Published', article.ValidationStatus, 'FAQ Knowledge Article should be Published.');
    }
    // @description Test method to verify that the FAQ Knowledge Article has Default URL Name set during creation
    @isTest
    static void testDefaultURLNameForFAQ_Create() {
        // GIVEN
        // A new Knowledge Article instance
        Knowledge_Article__kav article = new Knowledge_Article__kav(
            Title = 'Test FAQ Article',
            Summary = 'This is a test FAQ article.',
            Planned_Publication_Date__c = System.today(),
            UrlName = 'test-faq-article',
            ValidationStatus = 'Draft',
            Automatically_publish_on_approval__c = true,
            Owning_Org_Unit__c = 'Monash College',
            recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Knowledge_Article__kav' AND Name = 'FAQ' LIMIT 1].Id
        );   

        // WHEN
        // The Knowledge Article is created
        Test.startTest();
            insert article;
        Test.stopTest();    

        // THEN
        // Verify that the article's URL Name is set to the default value
        article = [SELECT UrlName FROM Knowledge_Article__kav WHERE Id = :article.Id LIMIT 1];
        Assert.isTrue(article.UrlName?.startsWith('FAQ-'), 'Monash College FAQ Knowledge Article should have a URL Name starting with "FAQ-".');
    }
    // @description Test method to verify that the FAQ Knowledge Article has Default URL Name set during update
    @isTest
    static void testDefaultURLNameForFAQ_Update() {
        // GIVEN
        // A new Knowledge Article instance
        Knowledge_Article__kav article = new Knowledge_Article__kav(
            Title = 'Test FAQ Article',
            Summary = 'This is a test FAQ article.',
            Planned_Publication_Date__c = System.today(),
            UrlName = 'test-faq-article',
            ValidationStatus = 'Draft',
            Automatically_publish_on_approval__c = true,
            recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Knowledge_Article__kav' AND Name = 'FAQ' LIMIT 1].Id
        );   
        insert article;

        // WHEN
        // The Knowledge Article is updated
        Test.startTest();
            article.Owning_Org_Unit__c = 'Monash College';
            update article;
        Test.stopTest();    

        // THEN
        // Verify that the article's URL Name is set to the default value
        article = [SELECT UrlName FROM Knowledge_Article__kav WHERE Id = :article.Id LIMIT 1];
        Assert.isTrue(article.UrlName?.startsWith('FAQ-'), 'Monash College FAQ Knowledge Article should have a URL Name starting with "FAQ-".');
    }
    // @description Test method to verify that the HR FAQ Knowledge Article is Published
    @isTest
    static void testPublishForHRFAQ() {
        // GIVEN
        // A new Knowledge Article instance
        Knowledge_Article__kav article = new Knowledge_Article__kav(
            Title = 'Test HR FAQ Article',
            Summary = 'This is a test HR FAQ article.',
            Planned_Publication_Date__c = System.today(),
            UrlName = 'test-hr-faq-article',
            ValidationStatus = 'Draft',
            Automatically_publish_on_approval__c = true,
            Author_Email__c = 'abc@123.com.au',
            recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Knowledge_Article__kav' AND Name = 'HR FAQ' LIMIT 1].Id
        );   
        insert article;

        // WHEN
        // The Knowledge Article is approved
        Test.startTest();
            article.ValidationStatus = 'Approved';
            update article;
        Test.stopTest();    

        // THEN
        // Verify that the article is published
        article = [SELECT ValidationStatus FROM Knowledge_Article__kav WHERE Id = :article.Id LIMIT 1];
        Assert.areEqual('Published', article.ValidationStatus, 'HR FAQ Knowledge Article should be Published.');
    }
    // @description Test method to verify that the Research FAQ Knowledge Article is Published
    @isTest
    static void testPublishForResearchFAQ() {
        // GIVEN
        // A new Knowledge Article instance
        Knowledge_Article__kav article = new Knowledge_Article__kav(
            Title = 'Test Research FAQ Article',
            Summary = 'This is a test ResearchFAQ article.',
            Planned_Publication_Date__c = System.today(),
            UrlName = 'test-research-faq-article',
            ValidationStatus = 'Draft',
            Automatically_publish_on_approval__c = true,
            recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Knowledge_Article__kav' AND Name = 'Research FAQ' LIMIT 1].Id
        );   
        insert article;

        // WHEN
        // The Knowledge Article is approved
        Test.startTest();
            article.ValidationStatus = 'Approved';
            update article;
        Test.stopTest();    

        // THEN
        // Verify that the article is published
        article = [SELECT ValidationStatus FROM Knowledge_Article__kav WHERE Id = :article.Id LIMIT 1];
        Assert.areEqual('Published', article.ValidationStatus, 'Research FAQ Knowledge Article should be Published.');
    }
    // @description Test method to verify that the SR FAQ Knowledge Article is Published
    @isTest
    static void testPublishForSRFAQ() {
        // GIVEN
        // A new Knowledge Article instance
        Knowledge_Article__kav article = new Knowledge_Article__kav(
            Title = 'Test SR FAQ Article',
            Summary = 'This is a test SR FAQ article.',
            Planned_Publication_Date__c = System.today(),
            UrlName = 'test-sr-faq-article',
            ValidationStatus = 'Draft',
            Automatically_publish_on_approval__c = true,
            Author_Email__c = 'abc@123.com.au',
            recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Knowledge_Article__kav' AND Name = 'SR FAQ' LIMIT 1].Id
        );   
        insert article;

        // WHEN
        // The Knowledge Article is approved
        Test.startTest();
            article.ValidationStatus = 'Approved';
            update article;
        Test.stopTest();    

        // THEN
        // Verify that the article is published
        article = [SELECT ValidationStatus FROM Knowledge_Article__kav WHERE Id = :article.Id LIMIT 1];
        Assert.areEqual('Published', article.ValidationStatus, 'SR FAQ Knowledge Article should be Published.');
    }
    // @description Test method to verify that the Standard Text Knowledge Article is Published
    @isTest
    static void testPublishForStdText() {
        // GIVEN
        // A new Knowledge Article instance
        Knowledge_Article__kav article = new Knowledge_Article__kav(
            Title = 'Test Standard Text Article',
            Summary = 'This is a test Standard Text article.',
            Planned_Publication_Date__c = System.today(),
            UrlName = 'test-standard-text-article',
            ValidationStatus = 'Draft',
            Automatically_publish_on_approval__c = true,
            Author_Email__c = 'abc@123.com.au',
            recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Knowledge_Article__kav' AND Name = 'Standard Text' LIMIT 1].Id
        );   
        insert article;

        // WHEN
        // The Knowledge Article is approved
        Test.startTest();
            article.ValidationStatus = 'Approved';
            update article;
        Test.stopTest();    

        // THEN
        // Verify that the article is published
        article = [SELECT ValidationStatus FROM Knowledge_Article__kav WHERE Id = :article.Id LIMIT 1];
        Assert.areEqual('Published', article.ValidationStatus, 'Standard Text Knowledge Article should be Published.');
    }
    // @description Test method to verify that the Standard Text Knowledge Article - Faculty/Business Unit as Monash College is Published
    @isTest
    static void testPublishForStdTextMonashCollegeFaculty() {
        // GIVEN
        // A new Knowledge Article instance
        Knowledge_Article__kav article = new Knowledge_Article__kav(
            Title = 'Test Standard Text Article',
            Summary = 'This is a test Standard Text article.',
            Planned_Publication_Date__c = System.today(),
            UrlName = 'test-standard-text-article',
            ValidationStatus = 'Draft',
            Automatically_publish_on_approval__c = false,
            Author_Email__c = 'abc@123.com.au',
            Faculty_Business_Unit__c = 'Monash College',
            recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Knowledge_Article__kav' AND Name = 'Standard Text' LIMIT 1].Id
        );   
        
        // WHEN
        // The Knowledge Article is approved
        Test.startTest();
            insert article;
        Test.stopTest();    

        // THEN
        // Verify that the article is published
        article = [SELECT ValidationStatus FROM Knowledge_Article__kav WHERE Id = :article.Id LIMIT 1];
        Assert.areEqual('Published', article.ValidationStatus, 'Standard Text Knowledge Article should be Published.');
    }
}