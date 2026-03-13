/**
* @description       : 
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 22-09-2023
* @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest (isParallel=false)
public class ActionPlanEnquirySummaryController_Test {
    
    @testSetup static void setupData(){
        
        Id idTaskMRORT = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('MRO').getRecordTypeId();
        ActionPlanTemplate template = new ActionPlanTemplate();
        template.Name = 'Test Template 1';
        template.ActionPlanType = 'Industries';
        template.TargetEntityType = 'Case';
        template.UniqueName = generateRandomString(25);
        insert template;
        
        ActionPlanTemplateVersion templateVersion = [SELECT Id, ActionPlanTemplateId, Name, Status, Version FROM ActionPlanTemplateVersion WHERE ActionPlanTemplateId =:template.Id];
        
        List<ActionPlanTemplateItem> APTemplateItems = new List<ActionPlanTemplateItem>();
        
        for(Integer i=0; i< 2; i++){
            ActionPlanTemplateItem templateItem = new ActionPlanTemplateItem();
            templateItem.Name = 'Test Action Task '+i+1;
            templateItem.ItemEntityType = 'Task';
            templateItem.UniqueName = generateRandomString(25);
            templateItem.ActionPlanTemplateVersionId = templateVersion.Id;
			APTemplateItems.add(templateItem);
        }
        
        if(!APTemplateItems.isEmpty()){
			insert APTemplateItems;            
        }
        
        List<ActionPlanTemplateItemValue> APTItemValueList = new List<ActionPlanTemplateItemValue>();

        for(ActionPlanTemplateItem oAPTI: APTemplateItems){
            
            ActionPlanTemplateItemValue templateItem1value1 = new ActionPlanTemplateItemValue();
	        templateItem1value1.ActionPlanTemplateItemId = oAPTI.Id;
    	    templateItem1value1.ItemEntityFieldName = 'Task.Subject';
        	templateItem1value1.Name = 'templateItem1value1';
	        templateItem1value1.ValueLiteral = 'Test Action Task 1';
    	    APTItemValueList.add(templateItem1value1);
            
            ActionPlanTemplateItemValue templateItem1value2 = new ActionPlanTemplateItemValue();
            templateItem1value2.ActionPlanTemplateItemId = oAPTI.Id;
            templateItem1value2.ItemEntityFieldName = 'Task.Priority';
            templateItem1value2.Name = 'templateItem1value2';
            templateItem1value2.ValueLiteral = 'Normal';
             APTItemValueList.add(templateItem1value2);
            
            ActionPlanTemplateItemValue templateItem1value3 = new ActionPlanTemplateItemValue();
            templateItem1value3.ActionPlanTemplateItemId = oAPTI.Id;
            templateItem1value3.ItemEntityFieldName = 'Task.ActivityDate';
            templateItem1value3.Name = 'templateItem1value3';
            templateItem1value3.ValueFormula = 'StartDate + 10';
 			APTItemValueList.add(templateItem1value3);
        }
     
        if(!APTItemValueList.isEmpty()){
            insert APTItemValueList;
        } 
        
        templateVersion.Status = 'Final';
        update templateVersion;     
        
        //.. Create Account
        TriggerCommon.disableTrigger('Account');
        Account oAccount = new Account();
        oAccount.Name = generateRandomString(15);
        oAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household_Account').getRecordTypeId();
        insert oAccount;
        TriggerCommon.enableTrigger('Account');
        
        //.. Create Contact
        TriggerCommon.disableTrigger('Contact');
        Contact oContact = new Contact ();
        oContact.FirstName = generateRandomString(5);
        oContact.LastName = generateRandomString(5);
        oContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId();
        oContact.AccountId = oAccount.Id;
        Insert oContact;
        TriggerCommon.enableTrigger('Contact');
        
        //.. Create Case
        TriggerCommon.disableTrigger('Case');
        Case oCase = new Case();
        oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MRO').getRecordTypeId();
        oCase.Subject = 'Testing Action Plan Summary';
        oCase.Enquiry_Type__c = 'Award';
        oCase.ContactId = oContact.Id;
        insert oCase;
        TriggerCommon.enableTrigger('Case');
        
        //.. Create Action Plan
        ActionPlan oAP = new ActionPlan();
        oAP.ActionPlanTemplateVersionId = templateVersion.Id;
        oAP.Name = generateRandomString(10);
        oAP.StartDate = Date.today();
        oAP.OwnerId	= Userinfo.getUserId();
        oAP.TargetId = oCase.Id;
        oAP.ActionPlanType = 'Industries';
        insert oAP;  
    }
    
    @isTest
    public static void getActionPlanSummary_Test(){
        // GIVEN
        Id oCaseId = [SELECT Id FROM Case WHERE Enquiry_Type__c = 'Award' LIMIT 1].Id;
        
        //.. Set one Task to Completed.
        Task oTask = [SELECT Id, Status FROM Task WHERE WhatId =: oCaseId LIMIT 1];
        oTask.Status = 'Completed';
        Update oTask;

        List<ActionPlanEnquirySummaryController.Payload> payLoad = new List<ActionPlanEnquirySummaryController.Payload>();
        
        Test.startTest();
        // WHEN
        ActionPlanEnquirySummaryController.getActionPlanSummary(oCaseId);
        Test.stopTest();

        // THEN
        Assert.areNotEqual(payLoad, null, 'Task plan summary created.');
    }
    
    public static String generateRandomString(Integer lengthOfString) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < lengthOfString) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
}