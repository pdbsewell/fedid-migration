/**
 * @description       : Tests for Flow  ACP:AS:SetExternalId
 * @author            : Ben Greenland
 * @group             : 
 * @last modified on  : 2024-06-24
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-06-24   Ben Greenland   Initial Version
**/

@isTest
private class ACPASSetExternalId_Test {

    /**
    * @description Test when Bypass_All_Flows__c=false
    * @author Ben Greenland | 2024-06-24 
    **/
    @isTest
    static void testFlowWhenCustomSettingActive() {
        //GIVEN
        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=false);
        Contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        insert application;
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;
        //WHEN 
        Application_Course_Preference__c ACP =  StudFirst_TestHelper.createCoursePreferences(application,applicant,courseOffering,course);
        //THEN
        Assert.areEqual(ACP.External_Id__c,ACP.ACP_ID__c, 'Error in flow ACP:AS:SetExternalId');
    }

    /**
    * @description Test when Bypass_All_Flows__c=true
    * @author Ben Greenland | 2024-06-24 
    **/
    @isTest
    static void testFlowWhenCustomSettingInactive() {
        
        //GIVEN
        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=true);
        Contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        insert application;
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;
        //WHEN 
        Application_Course_Preference__c ACP =  StudFirst_TestHelper.createCoursePreferences(application,applicant,courseOffering,course);
        //THEN
        Assert.isTrue(String.isEmpty(ACP.External_Id__c), 'Error in flow ACP:AS:SetExternalId');
    }
}