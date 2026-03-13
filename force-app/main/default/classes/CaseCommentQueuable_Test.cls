/**
 * @description       : Test Class
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 30-08-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest
public with sharing class CaseCommentQueuable_Test {

    @testSetup
    static void setup() {
        Contact oContact = new Contact();
        oContact.FirstName = 'Test'+CommonUtilityERDA.generateRandomString(5);
        oContact.LastName = 'CaseComments'+CommonUtilityERDA.generateRandomString(5);
        oContact.Email = CommonUtilityERDA.generateRandomString(5) + 'CaseComments@enquiries.edu';
        insert oContact;
        
		Case oCase1 = new Case();
        oCase1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
		oCase1.ContactId = oContact.Id;
        oCase1.Subject = 'Case1';
        oCase1.Description = 'CaseComments1';
        insert oCase1;

        Case oCase2 = new Case();
        oCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
		oCase2.ContactId = oContact.Id;
        oCase2.Subject = 'Case2';
        oCase2.Description = 'CaseComments2';
        oCase2.Latest_Inbound_Email__c = System.now();
        insert oCase2;
        
		Case oCase3 = new Case();
        oCase3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
		oCase3.ContactId = oContact.Id;
        oCase3.Subject = 'Case3';
        oCase3.Description = 'CaseComments3';
        insert oCase3;
    }

    @IsTest
    public static void testSyncEnquiryWithLatestCommentInsert(){
        Map<Id, String> mEnquiryLatestComment = new Map<Id, String>();
        Set<Id> setCaseIds = new Set<Id>();

        Case caseRec = [SELECT Id, Latest_Comment__c FROM Case WHERE Subject = 'Case1'];
        CaseComment caseComm = new CaseComment(CommentBody='test Comment', ParentId=caseRec.Id);
        insert caseComm;
        
        mEnquiryLatestComment.put(caseComm.ParentId, caseComm.CommentBody);

        Test.startTest();
        System.enqueueJob(new CaseCommentQueuable(mEnquiryLatestComment, setCaseIds));
        Test.stopTest();
        
		Case oUpdatedCase = [SELECT Id, Latest_Comment__c FROM Case WHERE Id=: caseRec.Id];
        System.assertEquals(oUpdatedCase.Latest_Comment__c, 'test Comment', 'Comments added to Case');
    }

    @IsTest
    public static void testSyncEnquiryWithLatestCommentUpdate(){
        Map<Id, String> mEnquiryLatestComment = new Map<Id, String>();
        Set<Id> setCaseIds = new Set<Id>();

        Case caseRec = [SELECT Id, Latest_Comment__c FROM Case WHERE Subject = 'Case1'];
        CaseComment caseComm = new CaseComment(CommentBody='test Comment', ParentId=caseRec.Id);
        insert caseComm;
        
        caseComm.CommentBody = 'Updated with new comments';
        update caseComm;

        mEnquiryLatestComment.put(caseComm.ParentId, caseComm.CommentBody);

        Test.startTest();
        System.enqueueJob(new CaseCommentQueuable(mEnquiryLatestComment, setCaseIds));
        Test.stopTest();
        
		Case oUpdatedCase = [SELECT Id, Latest_Comment__c FROM Case WHERE Id=: caseRec.Id];
        System.assertEquals(oUpdatedCase.Latest_Comment__c, 'Updated with new comments', 'Comments updated to Case');
    }
    
    @isTest
    public static void testLatestInboundEmailFlagToNull(){
        Map<Id, String> mEnquiryLatestComment = new Map<Id, String>();
        Set<Id> setCaseIds = new Set<Id>();

        Case caseRec = [SELECT Id, Latest_Comment__c FROM Case WHERE Subject = 'Case2'];
        CaseComment caseComm = new CaseComment(CommentBody='test Comment', ParentId=caseRec.Id);
        insert caseComm;
        
        mEnquiryLatestComment.put(caseComm.ParentId, caseComm.CommentBody);
        setCaseIds.add(caseComm.ParentId);
        
        Test.startTest();
        System.enqueueJob(new CaseCommentQueuable(mEnquiryLatestComment, setCaseIds));
        Test.stopTest();
        
        Case oUpdatedCase = [SELECT Id, Latest_Inbound_Email__c FROM Case WHERE Subject = 'Case2'];
        System.assertEquals(oUpdatedCase.Latest_Inbound_Email__c, null, 'Latest Inbound Email Flag set to null');
    }
    

    @isTest
    public static void testLatestInboundEmailFlagNoChange(){
        Map<Id, String> mEnquiryLatestComment = new Map<Id, String>();
        Set<Id> setCaseIds = new Set<Id>();

        Case caseRec = [SELECT Id, Latest_Comment__c FROM Case WHERE Subject = 'Case2'];
        CaseComment caseComm = new CaseComment(CommentBody='acknowledged', ParentId=caseRec.Id);
        insert caseComm;
        
        mEnquiryLatestComment.put(caseComm.ParentId, caseComm.CommentBody);

        Test.startTest();
        System.enqueueJob(new CaseCommentQueuable(mEnquiryLatestComment, setCaseIds));
        Test.stopTest();
        
		Case oUpdatedCase = [SELECT Id, Latest_Inbound_Email__c FROM Case WHERE Subject = 'Case2'];
        System.assertNotEquals(oUpdatedCase.Latest_Inbound_Email__c, null, 'No change to Latest Inbound Email Flag');
    }
}