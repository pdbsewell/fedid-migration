/**************************************************************************************************   
Apex Class Name      :  LightningArticleDetailController_Test
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is test class for LightningArticleDetailController.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    19/05/2017                        Created.
***************************************************************************************************/
@isTest(isParallel=true)
public class LightningArticleDetailController_Test{
    @testSetup
    public static void createData() {
        TestUtil.createArticles();
        TestUtil.createCustomSettings();
    }
    
    public static testmethod void LightningArticleDetailControllerTest() {
        Knowledge_Article__kav faq = [SELECT Id, RecordType.Name, Australia_Staff__c, Australia_Student__c, Question__c, Answer__c, Title,
                                             UrlName, ArticleNumber 
                                      FROM Knowledge_Article__kav 
                                      WHERE UrlName='test454365' 
                                            AND RecordType.Name = 'FAQ' 
                                            AND PublishStatus = 'Online' 
                                            AND language = 'en_US'];
        Knowledge_Article__kav hrfaq = [SELECT Id, RecordType.Name, Australia_Staff__c, Australia_Student__c, Question__c, Answer__c, Title,
                                               UrlName, ArticleNumber 
                                        FROM Knowledge_Article__kav 
                                        WHERE UrlName='test123' 
                                            AND RecordType.Name = 'HR FAQ' 
                                            AND PublishStatus = 'Online' 
                                            AND language = 'en_US'];
        
        //Retrieve permission set for the ask.monash community
        PermissionSet testPermissionSet;
        for(PermissionSet loopPermissionSet : [SELECT Id
                                               FROM PermissionSet
                                               WHERE Name = :Label.Community_Staff_Permissions_Name]){
            testPermissionSet = loopPermissionSet;
        }
        
        //Check if the current user have the permission set already assigned then assign if not  
        if(testPermissionSet != null){
            PermissionSetAssignment userAssignment;
            for(PermissionSetAssignment loopAssignmentSet : [SELECT Id
                                                             FROM PermissionSetAssignment
                                                             WHERE AssigneeId = :UserInfo.getUserId()
                                                                AND PermissionSetId = :testPermissionSet.Id]){
                userAssignment = loopAssignmentSet;
            }
            
            if(userAssignment == null){         
                //Assign Community_Staff_Permissions_Name permission set to the current user
                PermissionSetAssignment permSetAssignment = new PermissionSetAssignment();
                permSetAssignment.AssigneeId = UserInfo.getUserId();
                permSetAssignment.PermissionSetId = testPermissionSet.Id;
                insert permSetAssignment;
            }
        }
        
        //Start Test
        Test.startTest();            
            //Start test of knowledge article data page
            LightningArticleDetailController.getArticleDetail(faq.Id);   
        Test.stopTest();
    }
    
    public static testmethod void LightningArticleDetailControllerTestAsCommunityUser() {
        Knowledge_Article__kav faq = [SELECT Id, RecordType.Name, Australia_Staff__c, Australia_Student__c, Question__c, Answer__c, Title,
                                             UrlName, ArticleNumber 
                                      FROM Knowledge_Article__kav 
                                      WHERE UrlName='test454365' 
                                            AND RecordType.Name = 'FAQ' 
                                            AND PublishStatus = 'Online' 
                                            AND language = 'en_US'];
        Knowledge_Article__kav hrfaq = [SELECT Id, RecordType.Name, Australia_Staff__c, Australia_Student__c, Question__c, Answer__c, Title,
                                               UrlName, ArticleNumber 
                                        FROM Knowledge_Article__kav 
                                        WHERE UrlName='test123' 
                                            AND RecordType.Name = 'HR FAQ' 
                                            AND PublishStatus = 'Online' 
                                            AND language = 'en_US'];
                                            
        //Retrieve sample community user
        User communityUser =  [SELECT Id 
                               FROM User 
                               WHERE Profile.Name = 'Ask.Monash Profile' 
                                    AND IsActive = true 
                               LIMIT 1];
                               
        //Retrieve permission set for the ask.monash community
        PermissionSet testPermissionSet;
        for(PermissionSet loopPermissionSet : [SELECT Id
                                               FROM PermissionSet
                                               WHERE Name = :Label.Community_Staff_Permissions_Name]){
            testPermissionSet = loopPermissionSet;
        }
        
        //Check if the current user have the permission set already assigned then assign if not        
        if(testPermissionSet != null){
            PermissionSetAssignment userAssignment;
            for(PermissionSetAssignment loopAssignmentSet : [SELECT Id
                                                             FROM PermissionSetAssignment
                                                             WHERE AssigneeId = :communityUser.Id
                                                                AND PermissionSetId = :testPermissionSet.Id]){
                userAssignment = loopAssignmentSet;
            }
            
            if(userAssignment == null){
                //Assign Community_Staff_Permissions_Name permission set to the current user
                PermissionSetAssignment permSetAssignment = new PermissionSetAssignment();
                permSetAssignment.AssigneeId = communityUser.Id;
                permSetAssignment.PermissionSetId = testPermissionSet.Id;
                insert permSetAssignment;
            }
        }
            
        //Start Test
        Test.startTest();
            system.runAs(communityUser) {
                //Start test of knowledge article data page
                LightningArticleDetailController.getArticleDetail(hrfaq.Id);
            }
        Test.stopTest();
    }
}