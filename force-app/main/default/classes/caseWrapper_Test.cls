/**
* @author Angelo Rivera
* @date 07.01.2020
* @group Test Class
* @description  Test Class to test the functionality of caseWrapper
* @revision     APRivera, 07.January.2019 - Created <br/>
*/

@isTest(isParallel=true)
private class caseWrapper_Test {
	@IsTest
	static void testBehavior() {
		Test.startTest();
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
		cse.CreatedDate = System.now();
		insert cse;
		Attachment attach = new Attachment(Name='TestAttachment', ParentId=cse.Id, Body=Blob.valueOf('TestBody'), CreatedDate=System.now());
		insert attach;
		attachmentWrapper attachmentWrapper = new attachmentWrapper(attach);
		List<attachmentWrapper> attachmentList = new List<attachmentWrapper>();
		attachmentList.add(attachmentWrapper);

		EmailMessage message = new EmailMessage(Subject='Test',ParentId=cse.Id, HtmlBody='<html><head>Testing---Testing</head></html>',CreatedDate=System.now());
		insert message;
		emailWrapper emailWrapper = (new emailWrapper(message.Id,message.Subject,message.FromName,message.TextBody,message.CreatedDate,attachmentList,true,'',message.HtmlBody,'-',true));
		List<emailWrapper> emailWrapperList = new List<emailWrapper>();
		emailWrapperList.add(emailWrapper);

		List<fieldWrapper> fieldList = new List<fieldWrapper>();
		fieldList.add(new fieldWrapper('fieldLabel', Schema.DisplayType.DATETIME, Datetime.valueOf('2013-08-01 12:00:00'),'DateCreated'));
		caseWrapper caseWrapper = new caseWrapper(cse, attachmentList, emailWrapperList, 1, fieldList, '<html><head>Testing---Testing</head></html>','ToName', 'FromName', 'AttachmentLink');

		Test.stopTest();
		System.assertNotEquals(null, caseWrapper);
	}
}