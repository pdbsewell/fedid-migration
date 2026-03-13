/**************************************************************************************************   
Apex Class Name      :  LightningTopicLinks_Test
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is test class for LightningTopicLinks.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Veera Gandi                    03/07/2017                        Created.
***************************************************************************************************/
@isTest(isParallel=true)
public class LightningTopicLinks_Test {
    
    @testSetup
    public static void createData() {
        TestUtil.createArticles();
        TestUtil.createCustomSettings();
    }
    
    @istest
    public static void getTopicLinks()
    {
        Topic t=TestUtil.createTopic('TestTopic');
        List<TopicAssignment> topicAssignmentList=new List<TopicAssignment>();
        Knowledge_Article__kav faq=[select id,RecordType.Name,question__c,answer__c,title,UrlName from Knowledge_Article__kav where UrlName='test454365' and RecordType.Name = 'FAQ' and PublishStatus='Online' and language='en_US'];
        topicAssignmentList.add(TestUtil.createTopicAssignment(t.Id,faq.Id));
        insert topicAssignmentList;
        List<Topic> topicList=LightningTopicLinks.getTopics(faq.Id);        
        system.assertequals(topicList.size(),1);
    }
    
}