/**
 * Test class for the Console_OffSystemEmail_CE custom controller extension class.
 * These methods are part of the testing framework implemented throughout UniCRM
 */
@isTest(isParallel=true)
private class Console_OffSystemEmail_CE_Test {

    static testMethod void verifyControllerExtensionLogic(){
        TestHelper.calabrioSetUp();
        List<Contact> testContacts = TestHelper.createStudentContacts(1, null);
	    insert testContacts;
	        
        List<Case> webToCaseForms = TestHelper.webToCaseForms(1);
        webToCaseForms[0].contactId = testContacts[0].id;
        insert webToCaseForms;
        
        
        
        // add some attachments, activity history and email messages
        	
        insert TestHelper.createAttachments(10, webToCaseForms[0].id);

        insert TestHelper.createdFiles(10, webToCaseForms[0].id);
        	
        insert TestHelper.createTasks(10, testContacts[0].id, webToCaseForms[0].id);
        
        insert TestHelper.createEmailMessages( 6,webToCaseForms[0].id,'Test Monash', 'test@f.e.monash.edu','testonly@monash.edu');
	        
	    Test.startTest();
        
        	PageReference pg = Page.Console_OffSystemEmail;
        	Test.setCurrentPage(pg);
        	ApexPages.currentPage().getParameters().put('Id',webToCaseForms[0].id);
        	ApexPages.StandardController stdCase = new ApexPages.StandardController(webToCaseForms[0]);
        
        	Console_OffSystemEmail_CE con = new Console_OffSystemEmail_CE(stdCase);	
        
        	String attIds = '';
            for(attachment a : [select id from attachment]) attIds += (a.id + ';');
        	ApexPages.currentPage().getParameters().put('attIds',attIds);
        	ApexPages.currentPage().getParameters().put('msg',EncodingUtil.urlEncode('this test message','UTF-8'));
        	
        	list<selectOption> options = con.facultyOptions;
 			      
        	con.sendPreviewEmail();
        	
        	con.ToEmailAddress = 'testuser.testing@monash.edu';
        	con.sendEmail();
        
        con.dummyAction(); // just to cover a null method
        Test.stopTest();
        
    }
    
}