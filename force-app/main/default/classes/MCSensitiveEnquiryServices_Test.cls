@isTest(isParallel=true)
public class MCSensitiveEnquiryServices_Test{
    /**
     * @author          Russell Cadapan
     * @description     Setup data
     * @revision        05/08/2019 - Created
     */
    @testSetup
    static void setupData(){
        
        // retrieve public group Id for to indetify users with decryption access
        Id mcpublicgroupId = [SELECT Id FROM Group WHERE DeveloperName = 'MC_Decryption_Users' LIMIT 1].Id;
        
        // create the encryption settings
        MC_Encryption_Settings__c settings = new MC_Encryption_Settings__c(
            SetupOwnerId=UserInfo.getOrganizationId(),
            Algorithm__c='AES256',
            Key__c = '12341234123412341234123412341234',
            Mask_Format__c = 'XXXXXXXXX',
            Decryption_Group_Id__c = mcpublicgroupId);
        insert settings;
        
        // create a parent enquiry
        List<Case> enquiries = TestHelper.webToCaseForms(1);
        enquiries[0].Description = 'This has sensitive data 123 456 789';
        insert enquiries;
        
        // create the email message
        List<EmailMessage> emailMessages = TestHelper.createEmailMessages(1, enquiries[0].Id, 'encryption_Test', 'connect@f.e.monash.edu','testrecipient@testemailonly.com');
        emailMessages[0].TextBody = enquiries[0].Description;
        emailMessages[0].HtmlBody = '<p>'+enquiries[0].Description+'</p>';
        emailMessages[0].Sensitive_Information__c = '123 456 789';
        insert emailMessages;
        
    }
    /**
     * @author          Russell Cadapan
     * @description     Encryption test method
     * @revision        05/08/2019 - Created
     */
    @isTest static void encryption_Test(){
        
        // retrieve the email message
        List<EmailMessage> listEmailMessages = new List<EmailMessage>([SELECT Id FROM EmailMessage LIMIT 1]);
        
        // initialise the wrapper
        MCSensitiveEnquiryServices.thisWrapper responseWrapper;
        
        // perform the button execution
        if(!listEmailMessages.isEmpty()){
            Test.startTest();
                responseWrapper = MCSensitiveEnquiryServices.manageSensitiveData(listEmailMessages[0].Id);
            Test.stopTest();
        }
        
        // retrieve the updated email emssage
        EmailMessage updatedEmailMessage = [SELECT Id, ParentId, Is_Encrypted__c, TextBody, HtmlBody FROM EmailMessage LIMIT 1];
        
        // assert that the email is already encrypted
        System.assert(updatedEmailMessage.Is_Encrypted__c);

    }
    
    /**
     * @author          Russell Cadapan
     * @description     Encryption and Decryption Test
     * @revision        05/08/2019 - Created
     */
    @isTest static void decryption_Test(){
        
        List<EmailMessage> listEmailMessages = new List<EmailMessage>([SELECT Id FROM EmailMessage LIMIT 1]);
        MCSensitiveEnquiryServices.thisWrapper responseWrapper;
        
        if(!listEmailMessages.isEmpty()){
            responseWrapper = MCSensitiveEnquiryServices.manageSensitiveData(listEmailMessages[0].Id);
        }
        
        EmailMessage updatedEmailMessage = [SELECT Id, Is_Encrypted__c, TextBody, HtmlBody, ParentId FROM EmailMessage LIMIT 1];
        
        // assert that the email is already encrypted
        System.assert(updatedEmailMessage.Is_Encrypted__c);
        
        Test.startTest();
            responseWrapper = MCSensitiveEnquiryServices.manageSensitiveData(updatedEmailMessage.Id);
        Test.stopTest();
        
        // assert that the response states that the enquiry is encrypted
        System.assertEquals(responseWrapper.isEncrypted, true, 'Email is already encrypted');
        // assert that the email message is not re-created
        System.assertEquals(responseWrapper.emailMessageId, updatedEmailMessage.Id);
        
    }
}