/**
* @author Angelo Rivera
* @date 15.Jan.2020
* @group Test Class
* @description   This is test class for LightningCaseDetailController.
* @revision     Vaibhav B - 03/07/2017   - Created. <br/>
*               APRivera - 15.01.2020   - Renamed Test Class. <br/>
*               APRivera - 21.01.2020   - Increased code coverage <br/>
*/

@isTest(isParallel=true)
public class LightningCaseDetailController_Test{
	public static final String MONASH_CONNECT_OFFICER='Monash_Connect_Officer';
	public static final String STANDARD_ENQUIRY='Monash_Connect_Enquiry';
	@testSetup
	public static void createData() {
		TestUtil.createArticles();
		TestUtil.createCustomSettings();
	}
	public static testmethod void updateEnquiry() {
		List<User> userList =  TestHelper.createTestUsers('System Administrator',1);
		system.assertEquals(userList.size(),1,'Unable to create user');
		User u = userList[0];
		List<UserRole> roleList = [SELECT id FROM UserRole WHERE developerName = :MONASH_CONNECT_OFFICER];
		if(roleList.size()>0) {
			u.userroleId = roleList[0].Id;
			u.FederationIdentifier = 'abc123xyzpqr2';
			update u;

		}
		Knowledge_Article__kav faq = [SELECT id,question__c,answer__c,title,UrlName FROM Knowledge_Article__kav WHERE UrlName = 'test454365' and PublishStatus = 'Online' and RecordType.Name = 'FAQ' and language = 'en_US'];
		Knowledge_Article__kav hrfaq = [SELECT id,question__c,answer__c,title,UrlName FROM Knowledge_Article__kav WHERE UrlName = 'test123' and PublishStatus = 'Online' and RecordType.Name = 'HR FAQ' and language = 'en_US'];
		system.runAs(u) {
			list<Contact> testContacts  =  TestHelper.createOrphanContactRecords(1);
			testContacts[0].Authcate__c = 'abc123xyzpqr2';
			testContacts[0].Email_Addresses__c = 'a@a.com;b@b.com;'+u.email;
			insert testContacts;
			List<case> caseList = TestHelper.webToCaseForms(1);
			system.assertEquals(caseList.size(),1,'Unable to create case');
			caseList[0].status = 'Awaiting Customer Feedback';
			upsert caseList;
			test.startTest();
			LightningCaseDetailController.updateEnq('adding new comment',caseList[0].Id,false);
			case c = [SELECT id,status FROM case WHERE id = :caseList[0].Id];
			system.assertequals(c.status,'Open','Unable to open case');
			LightningCaseDetailController.getCaseDetails(caseList[0].Id);
			test.stopTest();
		}
	}
	public static testmethod void updateEnquiry2() {
		List<User> userList =  TestHelper.createTestUsers('System Administrator',1);
		system.assertEquals(userList.size(),1,'Unable to create user');
		User u = userList[0];
		u.FederationIdentifier = 'abc123xyzpqr';
		update u;
		system.runAs(u) {
			list<Contact> testContacts  =  TestHelper.createOrphanContactRecords(1);
			testContacts[0].Authcate__c = 'abc123xyzpqr';
			testContacts[0].Email_Addresses__c = 'a@a.com;b@b.com;'+u.email;
			insert testContacts;
			Knowledge_Article__kav faq = [SELECT id,question__c,answer__c,title,UrlName FROM Knowledge_Article__kav WHERE UrlName = 'test454365' and PublishStatus = 'Online' and language = 'en_US'];
			Knowledge_Article__kav hrfaq = [SELECT id,question__c,answer__c,title,UrlName FROM Knowledge_Article__kav WHERE UrlName = 'test123' and PublishStatus = 'Online' and language = 'en_US'];

			List<case> caseList = TestHelper.webToCaseForms(1);
			system.assertEquals(caseList.size(),1,'Unable to create case');
			caseList[0].status = 'Awaiting Customer Feedback';
			caseList[0].recordtypeid = [SELECT id FROM recordtype WHERE developername = :STANDARD_ENQUIRY and SobjectType = 'Case'].Id;
			upsert caseList;
			EmailMessage newEmail  =  new EmailMessage();

			newEmail.FROMAddress  =  UserInfo.getUserEmail();
			newEmail.FROMName  =  'abc';
			newEmail.ToAddress  =  UserInfo.getUserEmail();
			newEmail.Subject  =  'test';
			newEmail.TextBody  =  'body';
			newEmail.HtmlBody  =  'body';
			newEmail.ParentId  =  caseList[0].Id;
			newEmail.Status  =  '0';   // (newCase and newTask are the newly created case and task FROM earlier code)
			insert newEmail;
			Attachment attachment  =  new Attachment();
			attachment.Body  =  Blob.valueOf('abc');
			attachment.Name  =  String.valueOf('test.txt');
			attachment.ParentId  =  newEmail.Id;
			insert attachment;
			Attachment attachment2  =  new Attachment();
			attachment2.Body  =  Blob.valueOf('abc');
			attachment2.Name  =  String.valueOf('testsdfdsgdsgsdgasrgtrwgsrgfsagsf.txt');
			attachment2.ParentId  =  newEmail.Id;
			insert attachment2;

			test.startTest();
			Id fileId = LightningCaseDetailController.saveTheFile(caseList[0].Id, 'abc.txt', 'xyz', '.txt',null);
			LightningCaseDetailController.saveTheFile(caseList[0].Id, 'abc.txt', 'xyz', '.txt',fileId);
			LightningCaseDetailController.updateEnq('adding new comment',caseList[0].Id,false);
			case c = [SELECT id,status FROM case WHERE id = :caseList[0].Id];
			system.assertequals(c.status,'Open','Unable to open case');
			LightningCaseDetailController.updateEnq(null,caseList[0].Id,true);
			c = [SELECT id,status FROM case WHERE id = :caseList[0].Id];
			LightningCaseDetailController.getCaseDetails(caseList[0].Id);
			LightningCaseDetailController.getAllowedFileTypes();
			try {
				LightningCaseDetailController.closeEnq(caseList[0].Id);
			}
			catch(Exception ex) {
			}
			test.stopTest();
		}
	}
}