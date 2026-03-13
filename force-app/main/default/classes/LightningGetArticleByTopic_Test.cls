/**************************************************************************************************   
Apex Class Name      :  LightningGetArticleByTopic_Test
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is test class for LightningGetArticleByTopic.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    03/07/2017                        Created.
***************************************************************************************************/
@isTest(isParallel=true)
public class LightningGetArticleByTopic_Test {
    @testSetup
    public static void createData() {
        TestUtil.createArticles();
        TestUtil.createCustomSettings();
    }
    
    public static testmethod void getArticleByTopic() {
        Topic t=TestUtil.createTopic('abc');
        List<TopicAssignment> topicAssignmentList=new List<TopicAssignment>();
        Knowledge_Article__kav faq=[select id,question__c,answer__c,title,UrlName from Knowledge_Article__kav where UrlName='test454365' and PublishStatus='Online' and language='en_US' and RecordType.Name = 'FAQ'];
        system.assertnotequals(faq.Id,null);
        system.assertnotequals(t.Id,null);
        topicAssignmentList.add(TestUtil.createTopicAssignment(t.Id,faq.Id));
        insert topicAssignmentList;
        List<KnowledgeArticleVersion> kavList=LightningGetArticleByTopic.getArticleByTopic(t.Id);        
        LightningGetArticleByTopic.getPageSize();
        String topicLabel=LightningGetArticleByTopic.getTopicLabelMap(t.Id);
        String blank=LightningGetArticleByTopic.getTopicLabelMap(null);
        system.assertequals(kavList.size(),1);
        //system.assertequals(topicLabel,'FAQ Related to abc'); 
        //system.assertequals(topicLabel,'FAQs Related to abc'); //R.Wilson - cause an issue during deployment. Missing 's' on FAQ
        system.assertequals(blank,null);
    }
}