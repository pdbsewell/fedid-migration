/**************************************************************************************************
Apex Class Name      :  LightningSearchPageController_Test
Version              :  1.0
Created Date         :
Function             :  This is test class for LightningSearchPageController & LightningSearchComponent.
Story                :
Work Task            :
Modification Log     :
*--------------------------------------------------------------------------------------------------
    Developer                        Date                        Description
    Veera Gandi                    03/07/2017                        Created.
    P.Victoriano 					05/06/19 				Fixed Long running Test
    @rajeshpunjabi 					03-AUG-2022					Updating API Version. 
***************************************************************************************************/
@isTest(isParallel=true)
private class LightningSearchPageController_Test {
    static List<Id> soslResult {get; set;}
    @testSetup static void setupData() {
        TestUtil.createCustomSettings();
    }
    static testMethod void getSearchResults() {
        String topicName = dataSetup();
        //P.Victoriano 05/06/19 - Add Fixed Search Results
        Test.startTest();
        System.assertNotEquals(null, soslResult, 'SOSL Fixed result Error');
        Test.setFixedSearchResults(soslResult);
        list<sobject> sObjectList = LightningSearchPageController.getSearchResults(topicName);
        system.assertEquals(2, sObjectList.size());
        Test.stopTest();
    }
    static testMethod void getSearchResults1() {
        String topicName = dataSetup();
        //P.Victoriano 05/06/19 - Add Fixed Search Results
        Test.startTest();
        System.assertNotEquals(null, soslResult, 'SOSL Fixed result Error');
        Test.setFixedSearchResults(soslResult);
        integer PageSize = LightningSearchPageController.getPageSize();
        system.assertEquals(3, PageSize);
        Test.stopTest();
    }
    static testMethod void getSearchResults2() {
        String topicName = dataSetup();
        //P.Victoriano 05/06/19 - Add Fixed Search Results
        Test.startTest();
        System.assertNotEquals(null, soslResult, 'SOSL Fixed result Error');
        Test.setFixedSearchResults(soslResult);
        string searchText = LightningSearchPageController.getSearchToken(topicName+'?tabset-fe996=2');
        system.assertEquals(searchText, '"'+topicName.toUpperCase()+'"');
        LightningSearchComponent.getSearchPageUrl();
        Test.stopTest();
    }
    static testMethod void getSearchResults3() {
        String topicName = dataSetup();
        //P.Victoriano 05/06/19 - Add Fixed Search Results
        Test.startTest();
        System.assertNotEquals(null, soslResult, 'SOSL Fixed result Error');
        Test.setFixedSearchResults(soslResult);
        LightningSearchComponent.getSearchArticles('test');
        Test.stopTest();
    }
    static testMethod void getSearchResults4() {
        String topicName = dataSetup();
        //P.Victoriano 05/06/19 - Add Fixed Search Results
        Test.startTest();
        System.assertNotEquals(null, soslResult, 'SOSL Fixed result Error');
        Test.setFixedSearchResults(soslResult);
        LightningSearchComponent.getSearchArticles(topicName);
        Test.stopTest();
    }
    private static String dataSetup() {
        String topicName = '';
        Knowledge_Article__kav faq1 = new Knowledge_Article__kav();
        faq1.question__c = 'hi';
        faq1.answer__c = 'test there';
        faq1.Title = 'test';
        faq1.Australia_Staff__c = 'test article test';
        faq1.UrlName = 'test454365';
        faq1.RecordTypeId = Schema.SObjectType.Knowledge_Article__kav.getRecordTypeInfosByName().get('FAQ').getRecordTypeId();
        faq1.Automatically_Publish_On_Approval__c = true;
        faq1.Owning_Org_Unit__c = 'Information';
        insert faq1;
        Knowledge_Article__kav faq = [select id, RecordType.Name, KnowledgeArticleId, ArticleNumber, Title from Knowledge_Article__kav where id = :faq1.Id];
        KbManagement.PublishingService.publishArticle(String.valueOf(faq.KnowledgeArticleId), true);
        Knowledge_Article__kav faq2 = new Knowledge_Article__kav();
        faq2.question__c = 'hi';
        faq2.answer__c = 'test there';
        faq2.Title = 'title';
        faq2.RecordTypeId = Schema.SObjectType.Knowledge_Article__kav.getRecordTypeInfosByName().get('FAQ').getRecordTypeId();
        faq2.Australia_Staff__c = 'test article test';
        faq2.UrlName = 'test45436safadf5';
        faq2.Automatically_Publish_On_Approval__c = true;
        faq2.Owning_Org_Unit__c = 'Information';
        insert faq2;
        faq = [select id, KnowledgeArticleId, ArticleNumber, Title from Knowledge_Article__kav where id = :faq2.Id];
        KbManagement.PublishingService.publishArticle(String.valueOf(faq.KnowledgeArticleId), true);
        topic t = new topic();
        String sfx = EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, 4);
        topicName = 'testTopic'+sfx;
        t.name = topicName;
        t.description = 'xyz';
        insert t;
        TopicAssignment ta = new TopicAssignment();
        ta.TopicId = t.id;
        ta.EntityId = faq.Id;
        insert ta;
        soslResult = new List<Id> {faq1.Id, faq2.Id};
        return topicName;
    }
}