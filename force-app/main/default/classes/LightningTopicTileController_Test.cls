/**************************************************************************************************   
Apex Class Name      :  LightningTopicTileController_Test
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is test class for LightningTopicTileController.
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    9/08/2017                        Created.
    Russell C                    22/06/2021                       Mofified - Updated the createTopics parameter values to avoid matching with actual records in the system
***************************************************************************************************/
@isTest(isParallel=true)
public class LightningTopicTileController_Test {
    @testSetup
    public static void createData() {        
        TestUtil.createCustomSettings();
    }
    public static testmethod void testTileController() {
        ConfigureCommunityTopic__c topic=new ConfigureCommunityTopic__c ();
        topic.name='Payment Summary Test Only';
        topic.ColorCode__c='123';
        topic.ProfileId__c=String.valueOf(UserInfo.getOrganizationId()).subString(0,15);
        topic.order__c=1;
        insert topic;
        TestUtil.createTopic('Payment Summary Test Only');     
        TestUtil.createTopic('Staff Training Test Only');
        TestUtil.createTopic('My Pay Test Only');
        TestUtil.createTopic('Performance Supervisor Test Only');
        TestUtil.createTopic('Academic Appointment Test Only Test Only');
        TestUtil.createTopic('Using Social Media Test Only');
        LightningTopicTileController.getTopicList();
    }
}