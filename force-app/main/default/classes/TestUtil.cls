/**************************************************************************************************   
Apex Class Name      :  TestUtil
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is test class to create Data.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    03/07/2017                        Created.
***************************************************************************************************/
@isTest
public class TestUtil
{
    public static void createArticles() {
        Knowledge_Article__kav faq=new Knowledge_Article__kav();
        faq.question__c='hi';
        faq.answer__c='there';
        faq.Title='How';
        faq.RecordTypeId = Schema.SObjectType.Knowledge_Article__kav.getRecordTypeInfosByName().get('FAQ').getRecordTypeId();
        faq.UrlName='test454365';        
        faq.Proposed_Removal_Date__c=system.today().addDays(-1);
        faq.Proposed_Removal_Status__c='Archive';
        faq.Review_Date__c=system.today().addDays(15);
        faq.ValidationStatus='Draft';
        faq.Automatically_Publish_On_Approval__c=true;
        faq.Owning_Org_Unit__c='Access HR';
        faq.Australia_Staff__c='test data';       
        faq.IsVisibleInCsp = true;
        faq.IsVisibleInPkb = true;
        faq.IsVisibleInPrm = true;
        insert faq;

        Knowledge_Article__kav hrfaq=new Knowledge_Article__kav ();
        hrfaq.question__c='hi';
        hrfaq.answer__c='there';
        hrfaq.Title='How';
        hrfaq.RecordTypeId = Schema.SObjectType.Knowledge_Article__kav.getRecordTypeInfosByName().get('HR FAQ').getRecordTypeId();
        hrfaq.UrlName='test123';
        hrfaq.Proposed_Removal_Date__c=system.today().addDays(-1);
        hrfaq.Proposed_Removal_Status__c='Archive';
        hrfaq.Review_Date__c=system.today().addDays(15);
        hrfaq.ValidationStatus='Draft';
        hrfaq.Automatically_Publish_On_Approval__c=true;
        hrfaq.Owning_Org_Unit__c='Access HR';
        hrfaq.IsVisibleInCsp = true;
        hrfaq.IsVisibleInPkb = true;
        hrfaq.IsVisibleInPrm = true;
        insert hrfaq;       
        
        faq=[select id,RecordType.Name, KnowledgeArticleId from Knowledge_Article__kav where id=:faq.Id];
        hrfaq=[select id,RecordType.Name, KnowledgeArticleId from Knowledge_Article__kav where id=:hrfaq.Id];
        
        KbManagement.PublishingService.publishArticle(String.valueOf(faq.KnowledgeArticleId),true);
        KbManagement.PublishingService.publishArticle(String.valueOf(hrfaq.KnowledgeArticleId),true); 
    }
    
    public static void createCustomSettings() {
        CustomURLs__c customURL=new CustomURLs__c();
        customURL.EmailToCase__c='a@a.com';
        customURL.Exclude_Token__c='?tabset-fe996=2';
        customURL.Help_URL__c='http://login-qa.monash.edu/adfs/services/trust';
        customURL.PageSizeTopicDetail__c=3;
        customURL.Pagination_Size__c=3;
        customURL.SearchResultsPageSize__c=3;
        customURL.SSO_URL__c='http://login-qa.monash.edu/adfs/services/trust';
        customURL.Community_Home_Page__c ='www.homepageURL.com';
        customURL.standard_url_suffix__c='/articles/';
        customURL.replacement_url_suffix__c='/s/article/';
        customURL.Email_Body_Seperator__c='--Original--';
        customURL.Available_Object_for_Review_Batch__c='Standard_Text__kav,FAQ__kav,Knowledge_Article__kav,HR_Standard_Text__kav';
        insert customURL;
        Community_Topics__c topic=new Community_Topics__c();
        topic.Default_Color_Code__c='#996b6a';
        topic.topic_1__c='Payment Summary';
        topic.Topic_1_Color__c='#996b6a';
        topic.topic_2__c='Timesheets';
        topic.Topic_2_Color__c='#996b6a';
        topic.topic_3__c='Working At Monash';
        topic.Topic_3_Color__c='#996b6a';
        topic.topic_4__c='Staff Training';
        topic.Topic_4_Color__c='#996b6a';
        topic.topic_5__c='My Pay';
        topic.Topic_5_Color__c='#996b6a';
        topic.topic_6__c='Performance Supervisor';
        topic.Topic_6_Color__c='#996b6a';
        topic.topic_7__c='Academic Appointment';        
        topic.Topic_7_Color__c='#996b6a';
        topic.topic_8__c='Using Social Media';
        topic.Topic_8_Color__c='#996b6a';
        topic.topic_9__c='Employee Self Service (ESS)';
        topic.Topic_9_Color__c='#996b6a';
        topic.Topic_Field_API__c='topic_1__c,topic_2__c,topic_3__c,topic_4__c,topic_5__c,topic_6__c,topic_7__c,topic_8__c,topic_9__c';
        insert topic;
    }
    
    public static topic createTopic(String name) {
        topic t=new topic();
        t.name=name;
        t.description='xyz';
        insert t;
        return t;
    }
    
    public Static TopicAssignment createTopicAssignment(Id topicId,Id articleId) {
        TopicAssignment ta=new TopicAssignment();
        ta.TopicId=topicId;
        ta.EntityId=articleId;
        return ta;
    }
    
    public Static Community_Case_Creation_Settings__c createCommunityCaseCreationSettings(string name, string caseEnquiryType, string category, string channel, string enquirytype, string origin,string reasonOfenquiry,
                                                                                         string recordtype, string status, string tier) {
        Community_Case_Creation_Settings__c cs = new Community_Case_Creation_Settings__c();
        cs.Name = name;
        cs.Case_Enquiry_Type__c = caseEnquiryType;
        cs.category__c= category;
        cs.Channel__c = channel;
        cs.enquiryType__c = enquirytype;
        cs.Origin__c = origin;
        cs.reason_of_enquiry__c = reasonOfenquiry;
        cs.Record_Type_Name__c = recordtype;
        cs.Status__c = status;
        cs.Tier__c =tier;
        return cs;
    }
}