@IsTest
public class OffersEmailService_Test {


	@testSetup
	private static void generateData()
    {
         User u = [select id from user where id =: userInfo.getUserId() limit 1];
        system.runAs(u)
        {
            EmailTemplate validEmailTemplate = new EmailTemplate();
            validEmailTemplate.isActive = true;
            validEmailTemplate.Name = 'name';
            validEmailTemplate.DeveloperName = 'unique_apex_empailTemplate';
            validEmailTemplate.TemplateType = 'text';
            validEmailTemplate.FolderId = UserInfo.getUserId();
            
            insert validEmailTemplate;            
        }       
    }
    @isTest
    private static void shouldSendEmail()
    {
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact mycontact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id), true);
 
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test'),
            IsMajorVersion = true
        );
        insert contentVersion_1;
        List<OffersEmailService.OffersEmailRequest> requests = new List<OffersEmailService.OffersEmailRequest>();
        OffersEmailService.OffersEmailRequest requestAlpha = new OffersEmailService.OffersEmailRequest();       
        OffersEmailService.OffersEmailRequest requestBeta = new OffersEmailService.OffersEmailRequest();
        
        requestAlpha.sendToAddress = 'fake@monash.edu';
        requestAlpha.oweDisplayName = 'Do not Reply';
        requestAlpha.emailDeveloperName = 'unique_apex_empailTemplate';
        requestAlpha.recordId = acc.Id;
        requestAlpha.contentVersionId = contentVersion_1.Id; // does apex testing check for type?
        
        
        requestBeta.sendToAddress = 'fake2@monash.edu';
        requestBeta.oweDisplayName = 'Do not Reply';
        requestBeta.emailDeveloperName = 'unique_apex_empailTemplate';   
        requestBeta.recordId = acc.Id;
        
        requests.add(requestAlpha);
        requests.add(requestBeta);
        
        Test.startTest();
        OffersEmailService.emailOffer(requests);
        // needs to be in same context
        system.assertEquals(1, Limits.getEmailInvocations(), 'it should send once for all emails');
        Test.stopTest();
        
        OffersEmailService.emailOffer(requests);
        system.assertEquals(0, Limits.getEmailInvocations(), 'it should not run twice');
    }
    
    @isTest
    private static void shouldThrowExceptionWhenBadId()
    {
        List<OffersEmailService.OffersEmailRequest> requests = new List<OffersEmailService.OffersEmailRequest>();
        OffersEmailService.OffersEmailRequest requestAlpha = new OffersEmailService.OffersEmailRequest();      
        
        requestAlpha.sendToAddress = 'INVALID_EMAIL';
        requestAlpha.oweDisplayName = 'Do not Reply';
        requestAlpha.emailDeveloperName = 'unique_apex_empailTemplate';
        requestAlpha.recordId = null;
        requests.add(requestAlpha);
        try {
            OffersEmailService.emailOffer(requests);
        } catch(LogUtilityException ex ) {
            system.assert(true, 'it should throw exception');
            return;
        }
         system.assert(false, 'it should throw exception');
        
    }
    @isTest
    private static void shoulSendToContactId()
    {
        Account acc = (Account)TestDataFactory.createSObject(new Account(), true);
        Contact mycontact = (Contact)TestDataFactory.createSObject(new Contact(AccountId = acc.Id, Email='fake@monash.edu'), true);
        
        List<OffersEmailService.OffersEmailRequest> requests = new List<OffersEmailService.OffersEmailRequest>();
        OffersEmailService.OffersEmailRequest requestAlpha = new OffersEmailService.OffersEmailRequest();      
        
        
        requestAlpha.oweDisplayName = 'Do not Reply';
        requestAlpha.emailDeveloperName = 'unique_apex_empailTemplate';
        requestAlpha.recordId = acc.Id;
        requestAlpha.sendToId = mycontact.Id;
        requests.add(requestAlpha);
        OffersEmailService.emailOffer(requests);
        system.assertEquals(1, Limits.getEmailInvocations(), 'it should send send to contact');
        
    }    
}