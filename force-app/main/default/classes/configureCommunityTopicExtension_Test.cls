@isTest(isParallel=true)
public class configureCommunityTopicExtension_Test {
    static testmethod void testconfigureCommunityTopicExtension(){
        ConfigureCommunityTopic__c topic=new ConfigureCommunityTopic__c ();
        topic.name='xyz';
        topic.ColorCode__c='123';
        topic.ProfileId__c=String.valueOf(UserInfo.getOrganizationId()).subString(0,15);
        topic.order__c=1;
        insert topic;
        ApexPages.StandardController sc = new ApexPages.StandardController(topic);
        configureCommunityTopicExtension obj = new configureCommunityTopicExtension(sc);        
        PageReference pageRef = Page.ConfigureCommunityTopics;        
        Test.setCurrentPage(pageRef);
        obj.addTopic();
        obj.communityTopicsByProfile[0].Name='abc';
        obj.colorCode='pqr';
        obj.setColor();  
        obj.setValue();           
        obj.topicName='xyz';
        obj.deleteRec();       
        obj.save();
        obj.addTopic();
        obj.communityTopicsByProfile[0].Name='abc';
        obj.colorCode='pqr';
        obj.setColor();   
        obj.validateData();  
        obj.addTopic();
        obj.communityTopicsByProfile[0].Name='abcd';
        obj.colorCode='pqrs';
        obj.setColor();        
        obj.save();        
    }
}