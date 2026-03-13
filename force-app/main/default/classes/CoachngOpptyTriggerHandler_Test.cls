/**
 * @description       : Test class for Coachng Oppty Trigger Handler
 * @author            : Inderpal Dhanoa
 * @group             : Monash Connect
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2023-12-18 - Inderpal Dhanoa - Initial Version
**/
@isTest(isParallel=true)
public class CoachngOpptyTriggerHandler_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         2023-12-18
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {
        List<Case> l_enqList = new List<Case>();
        List<Survey__c> l_surveyList = new List<Survey__c>();
        Id recType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
        
        Case enquiry_old = (Case)TestDataFactory.createSObject(new Case(SuppliedName = 'Old Enq', RecordTypeId = recType), false);
        l_enqList.add(enquiry_old);
        Case enquiry_new = (Case)TestDataFactory.createSObject(new Case(SuppliedName = 'New Enq', RecordTypeId = recType), false);
        l_enqList.add(enquiry_new);
        insert l_enqList;
        
        Survey__c oldSurvey = (Survey__c)TestDataFactory.createSObject(new Survey__c(Enquiry__c = enquiry_old.Id, Process_owned_by__c = 'Test 1', Action_Taken__c = 'Action 1'), false);
        l_surveyList.add(oldSurvey);
        Survey__c newSurvey = (Survey__c)TestDataFactory.createSObject(new Survey__c(Enquiry__c = enquiry_new.Id, Process_owned_by__c = 'Test 2', Action_Taken__c = 'Action 2'), false);
        l_surveyList.add(newSurvey);
        insert l_surveyList;
    }
    
    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         2023-12-18
     * @description  Tests regarding to capturing the Survey Details
    *******************************************************************************/ 
	@isTest 
    static void LinkSurveyDetails_Test() {
        // GIVEN: An Enquiry exists
        Case linkedEnq = [SELECT Id, OwnerId FROM CASE WHERE SuppliedName = 'Old Enq' ORDER BY CreatedDate DESC LIMIT 1];
        Survey__c newSurvey = [SELECT Id, OwnerId FROM Survey__c WHERE Enquiry__c = :linkedEnq.Id ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.startTest();
        // WHEN: A Coaching Oppyt recd is created
        Coaching_Opportunities__c coachOppty = (Coaching_Opportunities__c)TestDataFactory.createSObject(new Coaching_Opportunities__c(Survey__c = newSurvey.Id, Team_Coordinator__c = UserInfo.getUserId(),  
                                                                                                                                      Error_type__c = 'Monash failed to meet an obligation', TC_TL_feedback_assigned_to__c = UserInfo.getUserId(),
                                                                                                                                      Error_Reason__c = 'Staff provided incorrect or incomplete information'), true);
        
        Test.stopTest();
        // THEN: An Enquiry will be linked
        coachOppty = [SELECT Id, Officer_TC_Faculty_Other_Sources__c,Process_Owner__c, Enquiry_Number__c FROM Coaching_Opportunities__c WHERE Enquiry_Number__c = :linkedEnq.Id LIMIT 1];
        System.assertEquals(coachOppty.Officer_TC_Faculty_Other_Sources__c, linkedEnq.OwnerId, 'Enquiry not linked');
        System.assertEquals(coachOppty.Enquiry_Number__c, linkedEnq.Id, 'Enquiry not linked');
        System.assertEquals(coachOppty.Process_Owner__c, 'Test 1', 'Survey not linked');
    }
    
    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         2023-12-18
     * @description  Tests regarding to capturing the Survey Details
    *******************************************************************************/ 
	@isTest 
    static void LinkSurveyDetailsUpdate_Test() {
        // GIVEN: An Enquiry exists
        Case linkedEnq = [SELECT Id, OwnerId FROM CASE WHERE SuppliedName = 'Old Enq' ORDER BY CreatedDate DESC LIMIT 1];
        Survey__c newSurvey = [SELECT Id, OwnerId, Process_owned_by__c FROM Survey__c WHERE Enquiry__c = :linkedEnq.Id ORDER BY CreatedDate DESC LIMIT 1];
        
        Coaching_Opportunities__c coachOppty = (Coaching_Opportunities__c)TestDataFactory.createSObject(new Coaching_Opportunities__c(Survey__c = newSurvey.Id, Team_Coordinator__c = UserInfo.getUserId(),  
                                                                                                                                      Error_type__c = 'Monash failed to meet an obligation', TC_TL_feedback_assigned_to__c = UserInfo.getUserId(),
                                                                                                                                      Error_Reason__c = 'Staff provided incorrect or incomplete information'), true);
        coachOppty = [SELECT Id, Survey__c, Enquiry_Number__c, Officer_TC_Faculty_Other_Sources__c,Process_Owner__c FROM Coaching_Opportunities__c WHERE Enquiry_Number__c = :linkedEnq.Id LIMIT 1];
        linkedEnq = [SELECT Id, OwnerId FROM CASE WHERE SuppliedName = 'New Enq' ORDER BY CreatedDate DESC LIMIT 1];
        newSurvey = [SELECT Id, OwnerId, Process_owned_by__c FROM Survey__c WHERE Enquiry__c = :linkedEnq.Id ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.startTest();
        // WHEN: A Coaching Oppyt recd is updated
		coachOppty.Survey__c = newSurvey.Id;
        update coachOppty;
        
        Test.stopTest();
        // THEN: An Enquiry will be linked
        coachOppty = [SELECT Id, Officer_TC_Faculty_Other_Sources__c,Enquiry_Number__c,Process_Owner__c FROM Coaching_Opportunities__c WHERE Id = :coachOppty.Id LIMIT 1];
        System.assertEquals(coachOppty.Enquiry_Number__c, linkedEnq.Id, 'Enquiry not linked');
        System.assertEquals(coachOppty.Process_Owner__c, 'Test 2', 'Survey not linked');
    }
    
    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         2023-12-18
     * @description  Tests regarding notifying the Owner
    *******************************************************************************/ 
	@isTest 
    static void NotifyOwner_Test() {
        // GIVEN: An Enquiry exists
        Case linkedEnq = [SELECT Id, OwnerId FROM CASE WHERE SuppliedName = 'Old Enq' ORDER BY CreatedDate DESC LIMIT 1];
        Survey__c newSurvey = [SELECT Id, OwnerId FROM Survey__c WHERE Enquiry__c = :linkedEnq.Id ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.startTest();
        // WHEN: A Coaching Oppyt recd is created
        Coaching_Opportunities__c coachOppty = (Coaching_Opportunities__c)TestDataFactory.createSObject(new Coaching_Opportunities__c(Survey__c = newSurvey.Id, Team_Coordinator__c = UserInfo.getUserId(),  
                                                                                                                                      Error_type__c = 'Monash failed to meet an obligation', TC_TL_feedback_assigned_to__c = UserInfo.getUserId(),
                                                                                                                                      Error_Reason__c = 'Staff provided incorrect or incomplete information'), true);
        
        Test.stopTest();
        // THEN: An Owner will be linked
        coachOppty = [SELECT Id, Officer_TC_Faculty_Other_Sources__c,Process_Owner__c, Enquiry_Number__c FROM Coaching_Opportunities__c WHERE Enquiry_Number__c = :linkedEnq.Id LIMIT 1];
        System.assertEquals(coachOppty.Officer_TC_Faculty_Other_Sources__c, linkedEnq.OwnerId, UserInfo.getUserId());
    }
}