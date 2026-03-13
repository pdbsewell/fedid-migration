/**
* @author Angelo Rivera
* @date 05.09.19
* @group Test Class
* @description Test Class of attachmentWrapper
* @revision 10.12.19 - Initial Create <br/>
*/

@isTest(isParallel=true)
public class attachmentWrapper_Test {
	@isTest
	static void testAttachmentWrapper() {
		Test.startTest();
			Contact con = new Contact(LastName='TestContact');
			insert con;
			Attachment attch = new Attachment(Name='TestAttach', Body=Blob.valueOf('This is a sample attachment'),
					ParentId=con.Id, CreatedDate=System.now());
			insert attch;
			Attachment attch2 = new Attachment(Name='ThisIsATestAttachmentThisIsATestAttachment.txt',
					Body=Blob.valueOf('This is a sample attachment'), ParentId=con.Id, CreatedDate=System.now());
			insert attch2;
			attachmentWrapper attachWrapper = new attachmentWrapper(attch);
			attachmentWrapper attachWrapper2 = new attachmentWrapper(attch2);
		Test.stopTest();
		System.assert(attachWrapper.truncatedName == 'TestAttach');
		integer available=38;
		integer lastindexname=attch2.name.lastIndexOf('.');
		System.assert(attachWrapper2.truncatedName == attch2.name.subString(0,available-(attch2.name.length()-lastindexname)-2)+'~1'+attch2.name.subString(lastindexname,attch2.name.length()));
	}
}