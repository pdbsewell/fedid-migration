/**
* @author Inderpal Dhanoa
* @description test Class on Case Comment Trigger.
* @date 2021-07-30
* @revision 1.0
**/
@IsTest (isParallel=true)
public class CaseCommentTriggerHandlerTest {
    /**
    * @description test method for Syncing the latest enquiry comment on the Enquiry.
    * @author Inderpal Dhanoa
    * @date 2021-07-30
    * @revision 1.0
    **/
    @IsTest
    public static void testSyncEnquiryWithLatestCommentInsert(){
        
        Id rtEnterprise  = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
        Contact cont = new Contact(Lastname = 'test');
        insert cont;

        Case caseRec = new  Case(SuppliedName='testName',
                                Status='Open',
                                ContactId=cont.Id,
                                Latest_Comment__c=null,
                                RecordTypeId=rtEnterprise);
        insert caseRec;

        Test.startTest();
        CaseComment caseComm = new CaseComment(CommentBody='test Comment', ParentId=caseRec.Id);
        insert caseComm;
        Test.stopTest();
        
		Case oUpdatedCase = [SELECT Id, Latest_Comment__c, RecordTypeId FROM Case WHERE Id=: caseRec.Id];
        System.assertEquals(oUpdatedCase.Latest_Comment__c, 'test Comment');
    }

    @IsTest
    public static void testSyncEnquiryWithLatestCommentUpdate(){
        
        Id rtEnterprise  = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
        Contact cont = new Contact(Lastname = 'test');
        insert cont;
        
        Case caseRec = new  Case(SuppliedName='testName',
                                 Status='Open',
                                 ContactId=cont.Id,
                                 Latest_Comment__c='test Comment',
                                 RecordTypeId=rtEnterprise);
        insert caseRec;
        CaseComment caseComm = new CaseComment(CommentBody='test Comment', ParentId=caseRec.Id);
        insert caseComm;
        
        Test.startTest();
        caseComm.CommentBody = 'New comments added.';
        update caseComm;
        Test.stopTest();
        
        Case oUpdatedCase = [SELECT Id, Latest_Comment__c, RecordTypeId FROM Case WHERE Id=: caseRec.Id];
        System.assertEquals(oUpdatedCase.Latest_Comment__c, 'New comments added.');
    }
    
    @isTest
    public static void testLatestInboundEmailFlagToNull(){
        Id rtStandardEnquiry = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
        
        Contact oContact = new Contact(Lastname = 'test');
        insert oContact;
        
        Case oCase = new  Case(SuppliedName='testName',
                               Status='Open',
                               ContactId=oContact.id,
                               Latest_Inbound_Email__c=System.Now(),
                               RecordTypeId=rtStandardEnquiry);
        insert oCase;
        
        Test.startTest();
        CaseComment oCaseComment = new CaseComment(CommentBody='LatestInboundEmailFlagToNull', ParentId=oCase.Id);
        insert oCaseComment;
        Test.stopTest();
        
        Case oUpdatedCase = [SELECT Id, Latest_Inbound_Email__c FROM Case WHERE Id=:oCase.Id];
        System.assertEquals(oUpdatedCase.Latest_Inbound_Email__c, null);
    }
    

    @isTest
    public static void testLatestInboundEmailFlagNoChange(){
        Id rtStandardEnquiry = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
        
        Contact oContact = new Contact(Lastname = 'test');
        insert oContact;
        
        Case oCase = new  Case(SuppliedName='testName',
                               Status='Open',
                               ContactId=oContact.id,
                               Latest_Inbound_Email__c=System.Now(),
                               RecordTypeId=rtStandardEnquiry);
        insert oCase;
        
        Test.startTest();
        CaseComment oCaseComment = new CaseComment(CommentBody='acknowledged', ParentId=oCase.Id);
        insert oCaseComment;
        Test.stopTest();
        
		Case oUpdatedCase = [SELECT Id, Latest_Inbound_Email__c FROM Case WHERE Id=:oCase.Id];
        System.assertNotEquals(oUpdatedCase.Latest_Inbound_Email__c, null);
    }
}