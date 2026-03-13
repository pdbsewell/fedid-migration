/**************************************************************************************************   
Apex Class Name      :  createTopTenArticleExtension_Test
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is test class for CreateTopTenArticleExtension.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    19/05/2017                        Created.
    Angelo R                     17/07/2018                        Added limit on SOQL due to 'too mary query rows error'
***************************************************************************************************/
@isTest(isParallel=true)
public class createTopTenArticleExtension_Test{
    
    @testSetup
    public static void createData() {
        TestUtil.createArticles();
        TestUtil.createCustomSettings();
    }
    
    public static testmethod void testTopTenExtension() {
        List<User> userList= TestHelper.createTestUsers('System Administrator',1);
        system.assertEquals(userList.size(),1);
        User u=userList[0];
        u.isactive=true;
        update u;
        List<UserRole> roleList=[select id from UserRole where developerName='Monash_Connect_Officer'];
        
        if(roleList.size()>0) {
            u.userroleId=roleList[0].Id;
            update u;
        }  
        
        Knowledge_Article__kav faq=[select id,question__c,answer__c,title,UrlName,articleNumber from Knowledge_Article__kav where UrlName='test454365' and PublishStatus='Online' and language='en_US'];
        Knowledge_Article__kav hrfaq=[select id,question__c,answer__c,title,UrlName,articleNumber  from Knowledge_Article__kav where UrlName='test123' and PublishStatus='Online' and language='en_US'];
        test.startTest();
        system.runAs(u) {
            List<case> caseList=TestHelper.webToCaseForms(1);
            system.assertEquals(caseList.size(),1);            
            
            TopTenArticle__c topTen=new TopTenArticle__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(topTen);                     
            PageReference pageRef = Page.createNewTopTenArticle;
            pageRef.getParameters().put('FAQId', faq.Id);
            pageRef.getParameters().put('articleNumber', faq.articleNumber);
            Test.setCurrentPage(pageRef);      
            createTopTenArticleExtension testTopTen= new createTopTenArticleExtension(sc);        
            testTopTen.save();
            system.assertnotEquals(topTen.Id,null);
            topTen=new TopTenArticle__c();
            testTopTen= new createTopTenArticleExtension(sc);
            pageRef.getParameters().put('FAQId', hrfaq.Id);
            pageRef.getParameters().put('articleNumber', hrfaq.articleNumber );
            testTopTen= new createTopTenArticleExtension(sc); 
            pageRef.getParameters().put('FAQId', null);  
            testTopTen= new createTopTenArticleExtension(sc); 
            testTopTen.save();
            system.assertEquals(topTen.Id,null);
            
        }
        
        List<TopTenArticle__c> articleListAsAdmin=LightningTopTenController.getTopTenArticles();
        
        userList=[select id from user where profile.name='ASK Monash Profile' and isactive=true limit 1];
        if(userList.size()>0) {
            system.runAs(userList[0]) {
                List<TopTenArticle__c> articleList=LightningTopTenController.getTopTenArticles();
            }            
        }
        
        userList=[select id from user where profile.name='Customer Community Student User' and isactive=true limit 1];
        
        if(userList.size()>0) {
            system.runAs(userList[0]) {
                List<TopTenArticle__c> articleList=LightningTopTenController.getTopTenArticles();
            }            
        }
        
        userList=[select id from user where profile.name='Customer Community Staff User' and isactive=true limit 1];
        if(userList.size()>0) {
            system.runAs(userList[0]) {
                List<TopTenArticle__c> articleList=LightningTopTenController.getTopTenArticles();                
            }            
        }
        
        test.stopTest();
    }    
}