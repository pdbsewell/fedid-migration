/**
 * @author          Kristian Vegerano
 * @description     Test class for ViewEnquiryDraftService class
 * @history         08/11/2018
 */
 @isTest(isParallel=true)
public class ViewEnquiryDraftService_Test {
	@IsTest
    static void testRetrieveEmailMessageBody() {
        Id standardEnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Standard Enquiry').getRecordTypeId();
        Case testCase = new Case(RecordTypeId = standardEnquiryRecordTypeId);
        insert testCase;
        
        Test.startTest();
        	EmailMessage newEmailDraft = new EmailMessage(ParentId=testCase.Id, Subject='Test Draft', FromAddress = 'test@test.com', ToAddress = 'test@test.com', Status = '5');
        	insert newEmailDraft;
        	ViewEnquiryDraftService.retrieveOwnerDraftEmailMessageHtmlBody(testCase.Id, UserInfo.getUserId());
        Test.stopTest();
    }
    
    @IsTest
    static void testRetrieveEmailComposer() {
        Id standardEnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Standard Enquiry').getRecordTypeId();
        Case testCase = new Case(RecordTypeId = standardEnquiryRecordTypeId);
        insert testCase;
        
        String enquiryRecordType;
        for(Case loopCase : [SELECT Id, RecordType.Name FROM Case WHERE Id = :testCase.Id]){
            enquiryRecordType = loopCase.RecordType.Name;
        }
        
        Test.startTest();
        	EmailMessage newEmailDraft = new EmailMessage(ParentId=testCase.Id, Subject='Test Draft', FromAddress = 'test@test.com', ToAddress = 'test@test.com', Status = '5');
        	insert newEmailDraft;            
        	ViewEnquiryDraftService.retrieveRelevantEmailComposer(enquiryRecordType);
        Test.stopTest();
    }
}