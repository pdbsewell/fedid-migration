/**
* @author Angelo Rivera
* @date 13.01.2020
* @group Test Class
* @description  Test Class to test the functionality of emailWrapper
* @revision     APRivera, 13.January.2019 - Created <br/>
*/

@isTest(isParallel=true)
private class emailWrapper_Test {


	@IsTest
	static void testBehavior() {
		Test.startTest();
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case(), true);
		Attachment attach = new Attachment(Name='TestAttachment', ParentId=cse.Id, Body=Blob.valueOf('TestBody'), CreatedDate=System.now());
		insert attach;
		attachmentWrapper attachmentWrapper = new attachmentWrapper(attach);
		List<attachmentWrapper> attachmentList = new List<attachmentWrapper>();
		attachmentList.add(attachmentWrapper);

		EmailMessage message = new EmailMessage(Subject='Test',ParentId=cse.Id, HtmlBody='<html><head>Testing---Testing</head></html>',CreatedDate=System.now());
		insert message;

		// test email message HTML body with reply
		emailWrapper emailWrapper1 = (new emailWrapper(message.Id,message.Subject,message.FromName,message.TextBody,message.CreatedDate,attachmentList,true,'',message.HtmlBody,'-',true));

		// test email message HTML body's original message
		emailWrapper emailWrapper2 = (new emailWrapper(message.Id,message.Subject,message.FromName,message.TextBody,message.CreatedDate,attachmentList,true,'','<html><head>Testing</head></html>','-',true));
		Test.stopTest();
		System.assertNotEquals(null, emailWrapper1);
		System.assertNotEquals(null, emailWrapper2);
	}
}