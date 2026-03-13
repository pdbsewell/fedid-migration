/**************************************************************************************************   
Apex Class Name      :  LightningUpdateEnquiryController_Test 
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is test class for LightningUpdateEnquiryController.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    19/05/2017                        Created.
***************************************************************************************************/
@isTest(isParallel=true)
public class LightningUpdateEnquiryController_Test {
    @testSetup
    public static void createData() {
        TestUtil.createArticles();
        TestUtil.createCustomSettings();
    }
    public static testmethod void testupdateEnquiry2() {
        boolean isLoggedIn=LightningUpdateEnquiryController.isUserLoggedIn();
        CustomURLs__c urls=LightningUpdateEnquiryController.getSSOURL(); 
        system.assertequals(isLoggedIn,true);
        system.assertNotequals(urls,null);
    }
    public static testmethod void testUpdateEnquiry() {
        List<User> userList= TestHelper.createTestUsers('System Administrator',1);
        system.assertEquals(userList.size(),1);
        User u=userList[0];
        List<UserRole> roleList=[select id from UserRole where developerName='Monash_Connect_Officer'];
        if(roleList.size()>0) {
            u.userroleId=roleList[0].Id;
            update u;
        }
        Knowledge_Article__kav faq=[select id,RecordType.Name, question__c,answer__c,title,UrlName from Knowledge_Article__kav where UrlName='test454365' and PublishStatus='Online' and language='en_US' and RecordType.Name = 'FAQ'];
        Knowledge_Article__kav hrfaq=[select id,RecordType.Name, question__c,answer__c,title,UrlName from Knowledge_Article__kav where UrlName='test123' and PublishStatus='Online' and language='en_US' and RecordType.Name = 'HR FAQ'];
        system.runAs(u) {
            List<case> caseList=TestHelper.webToCaseForms(1);
            system.assertEquals(caseList.size(),1);
            caseList[0].status='Awaiting Customer Feedback';
            upsert caseList;            
            test.startTest();
            LightningUpdateEnquiryController.updateEnq('adding new comment',caseList[0].Id,false);
            case c=[select id,status from case where id=:caseList[0].Id];
            system.assertequals(c.status,'Open');
            test.stopTest();
        }
    }
    public static testmethod void testUpdateEnquiry3() {
        List<User> userList= TestHelper.createTestUsers('System Administrator',1);
        system.assertEquals(userList.size(),1);
        User u=userList[0];
        List<UserRole> roleList=[select id from UserRole where developerName='Monash_Connect_Leader'];
        if(roleList.size()>0) {
            u.userroleId=roleList[0].Id;
            update u;
        }
        system.runAs(u){
            List<case> caseList=TestHelper.webToCaseForms(1);
            system.assertEquals(caseList.size(),1);
            caseList[0].status='Awaiting Customer Feedback';
            upsert caseList;
            test.startTest();
            LightningUpdateEnquiryController.updateEnq('adding new comment',caseList[0].Id,true);
            LightningUpdateEnquiryController.updateEnq('adding new comment',null,false);
            case c=[select id,status from case where id=:caseList[0].Id];
            system.assertequals(c.status,'Closed');
            test.stopTest();
        }
    }
}